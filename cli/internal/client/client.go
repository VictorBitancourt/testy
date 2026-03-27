package client

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"net/textproto"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/victorbitancourt/testy-cli/internal/output"
	"github.com/victorbitancourt/testy-cli/internal/version"
)

// Client is an HTTP client for the Testy API.
type Client struct {
	baseURL    string
	token      string
	httpClient *http.Client
}

// New creates a Client.
func New(baseURL, token string) *Client {
	return &Client{
		baseURL: strings.TrimRight(baseURL, "/"),
		token:   token,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// Get performs a GET request.
func (c *Client) Get(path string, params map[string]string) (json.RawMessage, error) {
	url := c.buildURL(path, params)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, output.ErrNetwork(err)
	}
	return c.do(req)
}

// Post performs a POST request with a JSON body.
func (c *Client) Post(path string, body any) (json.RawMessage, error) {
	return c.doJSON("POST", path, body)
}

// Patch performs a PATCH request with a JSON body.
func (c *Client) Patch(path string, body any) (json.RawMessage, error) {
	return c.doJSON("PATCH", path, body)
}

// Delete performs a DELETE request.
func (c *Client) Delete(path string) error {
	url := c.buildURL(path, nil)
	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return output.ErrNetwork(err)
	}
	c.setHeaders(req)
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return output.ErrNetwork(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNoContent || resp.StatusCode == http.StatusOK {
		return nil
	}
	return c.handleErrorResponse(resp)
}

// PostMultipart uploads a file via multipart form.
func (c *Client) PostMultipart(path, fieldName, filePath string, extraFields map[string]string) (json.RawMessage, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("cannot open file: %w", err)
	}
	defer f.Close()

	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)

	baseName := filepath.Base(filePath)
	contentType := mime.TypeByExtension(filepath.Ext(baseName))
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	h := make(textproto.MIMEHeader)
	h.Set("Content-Disposition", fmt.Sprintf(`form-data; name=%q; filename=%q`, fieldName, baseName))
	h.Set("Content-Type", contentType)
	part, err := writer.CreatePart(h)
	if err != nil {
		return nil, err
	}
	if _, err := io.Copy(part, f); err != nil {
		return nil, err
	}

	for k, v := range extraFields {
		_ = writer.WriteField(k, v)
	}
	writer.Close()

	url := c.buildURL(path, nil)
	req, err := http.NewRequest("POST", url, &buf)
	if err != nil {
		return nil, output.ErrNetwork(err)
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}
	req.Header.Set("User-Agent", "testy-cli/"+version.Version)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, output.ErrNetwork(err)
	}
	defer resp.Body.Close()

	data, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return nil, c.parseError(resp.StatusCode, data)
	}
	return json.RawMessage(data), nil
}

func (c *Client) doJSON(method, path string, body any) (json.RawMessage, error) {
	var buf bytes.Buffer
	if body != nil {
		if err := json.NewEncoder(&buf).Encode(body); err != nil {
			return nil, err
		}
	}

	url := c.buildURL(path, nil)
	req, err := http.NewRequest(method, url, &buf)
	if err != nil {
		return nil, output.ErrNetwork(err)
	}
	req.Header.Set("Content-Type", "application/json")
	return c.do(req)
}

func (c *Client) do(req *http.Request) (json.RawMessage, error) {
	c.setHeaders(req)
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, output.ErrNetwork(err)
	}
	defer resp.Body.Close()

	data, _ := io.ReadAll(resp.Body)

	if resp.StatusCode >= 400 {
		return nil, c.parseError(resp.StatusCode, data)
	}

	return json.RawMessage(data), nil
}

func (c *Client) setHeaders(req *http.Request) {
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}
	if req.Header.Get("Content-Type") == "" {
		req.Header.Set("Accept", "application/json")
	}
	req.Header.Set("User-Agent", "testy-cli/"+version.Version)
}

func (c *Client) buildURL(path string, params map[string]string) string {
	url := c.baseURL + path
	if len(params) == 0 {
		return url
	}
	sep := "?"
	for k, v := range params {
		url += sep + k + "=" + v
		sep = "&"
	}
	return url
}

func (c *Client) handleErrorResponse(resp *http.Response) error {
	data, _ := io.ReadAll(resp.Body)
	return c.parseError(resp.StatusCode, data)
}

func (c *Client) parseError(status int, data []byte) error {
	switch status {
	case http.StatusUnauthorized:
		return output.ErrAuth("Authentication failed")
	case http.StatusForbidden:
		return output.ErrForbidden("Access denied")
	case http.StatusNotFound:
		msg := extractErrorMessage(data, "Not found")
		return &output.Error{Code: output.CodeNotFound, Message: msg}
	case http.StatusUnprocessableEntity:
		msgs := extractValidationErrors(data)
		if len(msgs) > 0 {
			return output.ErrValidation(msgs)
		}
		msg := extractErrorMessage(data, "Validation failed")
		return &output.Error{Code: output.CodeValidation, Message: msg}
	case http.StatusTooManyRequests:
		return output.ErrRateLimit()
	default:
		if status >= 500 {
			msg := extractErrorMessage(data, "Internal server error")
			return output.ErrAPI(status, msg)
		}
		msg := extractErrorMessage(data, "Request failed")
		return output.ErrAPI(status, msg)
	}
}

func extractErrorMessage(data []byte, fallback string) string {
	var resp struct {
		Error   string `json:"error"`
		Message string `json:"message"`
	}
	if json.Unmarshal(data, &resp) == nil {
		if resp.Error != "" {
			return resp.Error
		}
		if resp.Message != "" {
			return resp.Message
		}
	}
	return fallback
}

func extractValidationErrors(data []byte) []string {
	var resp struct {
		Errors []string `json:"errors"`
	}
	if json.Unmarshal(data, &resp) == nil {
		return resp.Errors
	}
	return nil
}
