package output

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
)

// Format specifies the output format.
type Format int

const (
	FormatAuto Format = iota
	FormatJSON
	FormatMarkdown
	FormatQuiet
)

// Response is the success envelope for JSON output.
type Response struct {
	OK      bool           `json:"ok"`
	Data    any            `json:"data,omitempty"`
	Summary string         `json:"summary,omitempty"`
	Meta    map[string]any `json:"meta,omitempty"`
}

// ErrorResponse is the error envelope for JSON output.
type ErrorResponse struct {
	OK    bool   `json:"ok"`
	Error string `json:"error"`
	Code  string `json:"code"`
	Hint  string `json:"hint,omitempty"`
}

// Writer handles output formatting.
type Writer struct {
	format Format
	w      io.Writer
}

// New creates a Writer.
func New(format Format, w io.Writer) *Writer {
	if w == nil {
		w = os.Stdout
	}
	return &Writer{format: format, w: w}
}

// EffectiveFormat returns the resolved format.
// Auto defaults to Markdown (human-readable). Use --json for JSON.
func (w *Writer) EffectiveFormat() Format {
	if w.format == FormatAuto {
		return FormatMarkdown
	}
	return w.format
}

// OK outputs a success response.
func (w *Writer) OK(data any, opts ...ResponseOption) error {
	resp := &Response{OK: true, Data: data}
	for _, opt := range opts {
		opt(resp)
	}

	switch w.EffectiveFormat() {
	case FormatJSON:
		return w.writeJSON(resp)
	case FormatQuiet:
		return w.writeJSON(data)
	case FormatMarkdown:
		return w.writeMarkdown(resp)
	default:
		return w.writeJSON(resp)
	}
}

// Err outputs an error response.
func (w *Writer) Err(err error) error {
	apiErr, ok := err.(*Error)
	if !ok {
		apiErr = &Error{Code: CodeAPI, Message: err.Error()}
	}

	switch w.EffectiveFormat() {
	case FormatJSON, FormatQuiet:
		resp := ErrorResponse{
			OK:    false,
			Error: apiErr.Message,
			Code:  apiErr.Code,
			Hint:  apiErr.Hint,
		}
		return w.writeJSON(resp)
	default:
		fmt.Fprintf(w.w, "Error: %s\n", apiErr.Message)
		if apiErr.Hint != "" {
			fmt.Fprintf(w.w, "Hint: %s\n", apiErr.Hint)
		}
		return nil
	}
}

func (w *Writer) writeJSON(v any) error {
	enc := json.NewEncoder(w.w)
	enc.SetIndent("", "  ")
	return enc.Encode(v)
}

// writeMarkdown renders the response as human-readable text.
func (w *Writer) writeMarkdown(resp *Response) error {
	// Normalize data through JSON round-trip to get consistent types
	data := normalizeData(resp.Data)

	switch items := data.(type) {
	case []any:
		w.writeTable(items, resp.Summary)
	case map[string]any:
		w.writeDetail(items)
	default:
		b, _ := json.MarshalIndent(resp.Data, "", "  ")
		fmt.Fprintln(w.w, string(b))
	}

	if resp.Meta != nil {
		if page, ok := resp.Meta["current_page"]; ok {
			fmt.Fprintf(w.w, "\nPage %v of %v (%v total)\n",
				page, resp.Meta["total_pages"], resp.Meta["total_count"])
		}
	}
	return nil
}

// writeTable renders a list of items as a compact table.
func (w *Writer) writeTable(items []any, summary string) {
	if len(items) == 0 {
		fmt.Fprintln(w.w, "No results.")
		return
	}

	// Detect the entity type from the first item's keys
	first, ok := items[0].(map[string]any)
	if !ok {
		for _, item := range items {
			fmt.Fprintf(w.w, "  %v\n", item)
		}
		return
	}

	// Choose column layout based on entity shape
	cols := detectColumns(first)

	// Calculate column widths
	widths := make([]int, len(cols))
	for i, col := range cols {
		widths[i] = len(col.header)
	}
	rows := make([][]string, 0, len(items))
	for _, item := range items {
		m, ok := item.(map[string]any)
		if !ok {
			continue
		}
		row := make([]string, len(cols))
		for i, col := range cols {
			row[i] = col.extract(m)
			if len(row[i]) > widths[i] {
				widths[i] = len(row[i])
			}
		}
		rows = append(rows, row)
	}

	// Cap name/title column width
	for i, col := range cols {
		if (col.header == "NAME" || col.header == "TITLE") && widths[i] > 45 {
			widths[i] = 45
		}
	}

	// Print header
	header := ""
	for i, col := range cols {
		if i > 0 {
			header += "  "
		}
		header += fmt.Sprintf("%-*s", widths[i], col.header)
	}
	fmt.Fprintln(w.w, header)

	// Print rows
	for _, row := range rows {
		line := ""
		for i := range cols {
			if i > 0 {
				line += "  "
			}
			val := row[i]
			if (cols[i].header == "NAME" || cols[i].header == "TITLE") && len(val) > widths[i] {
				val = val[:widths[i]-1] + "…"
			}
			line += fmt.Sprintf("%-*s", widths[i], val)
		}
		fmt.Fprintln(w.w, line)
	}

	if summary != "" {
		fmt.Fprintf(w.w, "\n%s\n", summary)
	}
}

// column defines a table column.
type column struct {
	header  string
	extract func(map[string]any) string
}

// detectColumns picks the best column layout for the data.
func detectColumns(first map[string]any) []column {
	// Test plans
	if _, hasName := first["name"]; hasName {
		if _, hasQA := first["qa_name"]; hasQA {
			return planColumns()
		}
	}

	// Bugs
	if _, hasTitle := first["title"]; hasTitle {
		if _, hasDesc := first["description"]; hasDesc {
			return bugColumns()
		}
	}

	// Scenarios
	if _, hasGiven := first["given"]; hasGiven {
		return scenarioColumns()
	}

	// Generic: ID + name/title + status
	return genericColumns(first)
}

func planColumns() []column {
	return []column{
		{"ID", func(m map[string]any) string { return fmtVal(m["id"]) }},
		{"NAME", func(m map[string]any) string { return fmtVal(m["name"]) }},
		{"STATUS", func(m map[string]any) string { return statusIcon(fmtVal(m["status"])) }},
		{"SCENARIOS", func(m map[string]any) string {
			return fmt.Sprintf("%v/%v", m["approved_scenarios"], m["total_scenarios"])
		}},
		{"QA", func(m map[string]any) string { return fmtVal(m["qa_name"]) }},
		{"TAGS", func(m map[string]any) string { return fmtTags(m["tags"]) }},
	}
}

func bugColumns() []column {
	return []column{
		{"ID", func(m map[string]any) string { return fmtVal(m["id"]) }},
		{"TITLE", func(m map[string]any) string { return fmtVal(m["title"]) }},
		{"STATUS", func(m map[string]any) string { return statusIcon(fmtVal(m["status"])) }},
		{"FEATURE", func(m map[string]any) string { return fmtVal(m["feature_tag"]) }},
		{"CAUSE", func(m map[string]any) string { return fmtVal(m["cause_tag"]) }},
	}
}

func scenarioColumns() []column {
	return []column{
		{"ID", func(m map[string]any) string { return fmtVal(m["id"]) }},
		{"TITLE", func(m map[string]any) string { return fmtVal(m["title"]) }},
		{"STATUS", func(m map[string]any) string { return statusIcon(fmtVal(m["status"])) }},
		{"EVIDENCE", func(m map[string]any) string { return fmtVal(m["evidence_count"]) }},
	}
}

func genericColumns(first map[string]any) []column {
	cols := []column{
		{"ID", func(m map[string]any) string { return fmtVal(m["id"]) }},
	}
	for _, key := range []string{"name", "title", "username"} {
		if _, ok := first[key]; ok {
			k := key
			cols = append(cols, column{strings.ToUpper(k), func(m map[string]any) string { return fmtVal(m[k]) }})
			break
		}
	}
	if _, ok := first["status"]; ok {
		cols = append(cols, column{"STATUS", func(m map[string]any) string { return statusIcon(fmtVal(m["status"])) }})
	}
	return cols
}

// writeDetail renders a single entity as key-value pairs.
func (w *Writer) writeDetail(m map[string]any) {
	// Detect and print header
	title := ""
	for _, key := range []string{"name", "title", "username"} {
		if v, ok := m[key]; ok {
			title = fmtVal(v)
			break
		}
	}
	if id, ok := m["id"]; ok && title != "" {
		fmt.Fprintf(w.w, "# #%v — %s\n\n", id, title)
	} else if id, ok := m["id"]; ok {
		fmt.Fprintf(w.w, "# #%v\n\n", id)
	} else if title != "" {
		fmt.Fprintf(w.w, "# %s\n\n", title)
	}

	// Key-value fields (ordered)
	orderedKeys := []string{
		"id", "name", "title", "status", "qa_name",
		"description", "steps_to_reproduce", "obtained_result", "expected_result",
		"given", "when_step", "then_step",
		"tags", "feature_tag", "cause_tag", "bug_id",
		"total_scenarios", "approved_scenarios", "evidence_count", "position",
		"user", "created_at", "updated_at",
	}

	printed := map[string]bool{}
	for _, key := range orderedKeys {
		v, ok := m[key]
		if !ok || key == "test_scenarios" {
			continue
		}
		printed[key] = true
		w.writeField(key, v)
	}
	// Print any remaining keys not in the ordered list
	for key, v := range m {
		if printed[key] || key == "test_scenarios" {
			continue
		}
		w.writeField(key, v)
	}

	// Nested scenarios table
	if scenarios, ok := m["test_scenarios"]; ok {
		if items, ok := scenarios.([]any); ok && len(items) > 0 {
			fmt.Fprintf(w.w, "\n## Scenarios (%d)\n\n", len(items))
			w.writeTable(items, "")
		}
	}
}

func (w *Writer) writeField(key string, v any) {
	label := fieldLabel(key)
	switch val := v.(type) {
	case map[string]any:
		// Inline nested objects (e.g. user)
		parts := []string{}
		for k, v := range val {
			parts = append(parts, fmt.Sprintf("%s: %v", k, v))
		}
		fmt.Fprintf(w.w, "%-16s %s\n", label+":", strings.Join(parts, ", "))
	case []any:
		fmt.Fprintf(w.w, "%-16s %s\n", label+":", fmtTags(val))
	default:
		s := fmtVal(v)
		if isStatusField(key) {
			s = statusIcon(s)
		}
		fmt.Fprintf(w.w, "%-16s %s\n", label+":", s)
	}
}

// --- Formatting helpers ---

func fmtVal(v any) string {
	if v == nil {
		return "-"
	}
	return fmt.Sprintf("%v", v)
}

func fmtTags(v any) string {
	tags, ok := v.([]any)
	if !ok || len(tags) == 0 {
		return "-"
	}
	parts := make([]string, len(tags))
	for i, t := range tags {
		parts[i] = fmt.Sprintf("%v", t)
	}
	return strings.Join(parts, ", ")
}

func statusIcon(s string) string {
	switch s {
	case "approved":
		return "approved"
	case "failed":
		return "FAILED"
	case "in_progress":
		return "in_progress"
	case "not_started":
		return "not_started"
	default:
		return s
	}
}

func isStatusField(key string) bool {
	return key == "status"
}

func fieldLabel(key string) string {
	r := strings.NewReplacer("_", " ")
	words := strings.Fields(r.Replace(key))
	for i, w := range words {
		words[i] = strings.ToUpper(w[:1]) + w[1:]
	}
	return strings.Join(words, " ")
}

// normalizeData round-trips through JSON to get consistent Go types.
func normalizeData(data any) any {
	b, err := json.Marshal(data)
	if err != nil {
		return data
	}
	var out any
	if err := json.Unmarshal(b, &out); err != nil {
		return data
	}
	return out
}

// ResponseOption modifies a Response.
type ResponseOption func(*Response)

// WithSummary sets the summary field.
func WithSummary(s string) ResponseOption {
	return func(r *Response) { r.Summary = s }
}

// WithMeta sets the meta field.
func WithMeta(m map[string]any) ResponseOption {
	return func(r *Response) { r.Meta = m }
}
