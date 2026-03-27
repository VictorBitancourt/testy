package output

import "fmt"

// Exit codes.
const (
	ExitOK        = 0
	ExitUsage     = 2
	ExitNotFound  = 3
	ExitAuth      = 4
	ExitForbidden = 5
	ExitRateLimit = 6
	ExitNetwork   = 7
	ExitAPI       = 8
)

// Error codes.
const (
	CodeUsage      = "usage_error"
	CodeNotFound   = "not_found"
	CodeAuth       = "auth_error"
	CodeForbidden  = "forbidden"
	CodeRateLimit  = "rate_limit"
	CodeNetwork    = "network_error"
	CodeAPI        = "api_error"
	CodeValidation = "validation_error"
)

// Error is a structured CLI error.
type Error struct {
	Code    string `json:"code"`
	Message string `json:"error"`
	Hint    string `json:"hint,omitempty"`
}

func (e *Error) Error() string {
	if e.Hint != "" {
		return fmt.Sprintf("%s: %s", e.Message, e.Hint)
	}
	return e.Message
}

// ExitCode returns the process exit code for this error.
func (e *Error) ExitCode() int {
	switch e.Code {
	case CodeUsage:
		return ExitUsage
	case CodeNotFound:
		return ExitNotFound
	case CodeAuth:
		return ExitAuth
	case CodeForbidden:
		return ExitForbidden
	case CodeRateLimit:
		return ExitRateLimit
	case CodeNetwork:
		return ExitNetwork
	case CodeAPI, CodeValidation:
		return ExitAPI
	default:
		return 1
	}
}

// Error constructors.

func ErrUsage(msg string) *Error {
	return &Error{Code: CodeUsage, Message: msg}
}

func ErrUsageHint(msg, hint string) *Error {
	return &Error{Code: CodeUsage, Message: msg, Hint: hint}
}

func ErrNotFound(resource, id string) *Error {
	return &Error{
		Code:    CodeNotFound,
		Message: fmt.Sprintf("%s %s not found", resource, id),
	}
}

func ErrAuth(msg string) *Error {
	return &Error{
		Code:    CodeAuth,
		Message: msg,
		Hint:    "Run: testy login <username> <password>",
	}
}

func ErrForbidden(msg string) *Error {
	return &Error{Code: CodeForbidden, Message: msg}
}

func ErrRateLimit() *Error {
	return &Error{
		Code:    CodeRateLimit,
		Message: "Rate limit exceeded",
		Hint:    "Try again later",
	}
}

func ErrNetwork(cause error) *Error {
	return &Error{
		Code:    CodeNetwork,
		Message: fmt.Sprintf("Network error: %s", cause),
	}
}

func ErrAPI(status int, msg string) *Error {
	return &Error{
		Code:    CodeAPI,
		Message: fmt.Sprintf("API error (%d): %s", status, msg),
	}
}

func ErrValidation(messages []string) *Error {
	return &Error{
		Code:    CodeValidation,
		Message: fmt.Sprintf("Validation failed: %s", joinMessages(messages)),
	}
}

func joinMessages(msgs []string) string {
	if len(msgs) == 1 {
		return msgs[0]
	}
	result := ""
	for i, m := range msgs {
		if i > 0 {
			result += "; "
		}
		result += m
	}
	return result
}
