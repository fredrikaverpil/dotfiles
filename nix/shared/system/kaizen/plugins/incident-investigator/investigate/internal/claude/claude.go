// Package claude runs headless, read-only Claude Code turns and folds their stream-json output.
package claude

import (
	"cmp"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// DefaultModel and DefaultEffort are what a run uses until another is chosen.
const (
	DefaultModel  = "claude-sonnet-5-5"
	DefaultEffort = "high"
)

// Models and Efforts are the values a run may use.
var (
	Models  = []string{"claude-sonnet-5-5", "claude-opus-5-5"}
	Efforts = []string{"low", "medium", "high", "xhigh", "max"}
)

// Message is one entry of a conversation as the window shows it.
type Message struct {
	// Kind is user, assistant or tools.
	Kind     string   `json:"kind"`
	Text     string   `json:"text,omitempty"`
	Commands []string `json:"commands,omitempty"`
}

// Result is a turn's final event.
type Result struct {
	IsError bool
	Text    string
	CostUSD float64
}

// Command returns a turn in dir that starts sessionID, or continues it when resume is set, with instructions appended
// to the system prompt. Only `gcloud logging read`, `gcloud logging buckets list`, describing and listing Monitoring
// alerts, describing alert policies, describing Cloud Run services, revisions and jobs, Read and Grep are allowed; any other
// tool call is denied. Read and Grep reach only dir, the turn's own saved tool output, sourceDirs and goModCache. With
// sourceDirs, read-only git in the repositories directly under them, `investigate checkout` of one into dir, and LSP
// are allowed too.
func Command(
	dir, pluginDir string, sourceDirs []string, goModCache, model, effort, sessionID, instructions, prompt string,
	resume bool,
) *exec.Cmd {
	session := "--session-id"
	if resume {
		session = "--resume"
	}
	args := []string{
		"-p",
		session, sessionID,
		"--model", model,
		"--effort", effort,
		"--output-format", "stream-json",
		"--verbose",
		"--plugin-dir", pluginDir,
		// Ignores the user's settings, plugins and MCP servers, and confines Read and Grep to dir.
		"--restricted",
		"--strict-mcp-config",
		"--permission-mode", "dontAsk",
		"--max-budget-usd", "5",
	}
	if instructions != "" {
		args = append(args, "--append-system-prompt", instructions)
	}
	tools := "Bash,Read,Grep"
	allowed := []string{
		"Bash(gcloud logging read *)", "Bash(gcloud logging buckets list *)",
		"Bash(gcloud alpha monitoring alerts describe *)", "Bash(gcloud alpha monitoring alerts list *)",
		"Bash(gcloud monitoring policies describe *)",
		"Bash(gcloud run services describe *)", "Bash(gcloud run revisions list *)",
		"Bash(gcloud run revisions describe *)", "Bash(gcloud run jobs describe *)",
		"Read", "Grep",
	}
	var denied []string
	if len(sourceDirs) > 0 {
		for _, sourceDir := range sourceDirs {
			args = append(args, "--add-dir", sourceDir)
			allowed = append(allowed, gitRules(sourceDir)...)
		}
		// diff and show write a file for --output.
		denied = []string{"Bash(git * --output*)"}
		// The plugin's gopls serves LSP.
		tools += ",LSP"
		allowed = append(allowed, "LSP", "Bash(investigate checkout *)")
		if goModCache != "" {
			args = append(args, "--add-dir", goModCache)
		}
	}
	args = append(args, "--tools", tools)
	args = append(args, "--allowedTools")
	args = append(args, allowed...)
	if denied != nil {
		args = append(args, "--disallowedTools")
		args = append(args, denied...)
	}
	cmd := exec.Command("claude", args...)
	cmd.Dir = dir
	// On stdin, so a prompt starting with "-" is not read as a flag.
	cmd.Stdin = strings.NewReader(prompt)
	return cmd
}

// gitRules allows read-only git in each repository directly under sourceDir. Each rule names its repository: a
// wildcard before the subcommand would also approve options there, such as `-c core.fsmonitor=CMD`, which run commands.
func gitRules(sourceDir string) []string {
	entries, err := os.ReadDir(sourceDir)
	if err != nil {
		return nil
	}
	var rules []string
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		for _, sub := range []string{"log", "show", "diff", "merge-base", "rev-parse", "cat-file"} {
			rules = append(rules, fmt.Sprintf("Bash(git -C %s %s *)", filepath.Join(sourceDir, entry.Name()), sub))
		}
	}
	return rules
}

// Fold appends what one stream-json line adds to msgs, and reports whether it added anything. The result is non-nil
// for the final event.
func Fold(msgs []Message, line []byte) ([]Message, bool, *Result, error) {
	var event struct {
		Type         string          `json:"type"`
		Subtype      string          `json:"subtype"`
		Message      json.RawMessage `json:"message"`
		IsError      bool            `json:"is_error"`
		Result       string          `json:"result"`
		TotalCostUSD float64         `json:"total_cost_usd"`
	}
	if err := json.Unmarshal(line, &event); err != nil {
		return msgs, false, nil, fmt.Errorf("parse event: %v", err)
	}
	switch event.Type {
	case "result":
		return msgs, false, &Result{
			IsError: event.IsError || event.Subtype != "success",
			Text:    cmp.Or(event.Result, event.Subtype),
			CostUSD: event.TotalCostUSD,
		}, nil
	case "assistant":
	default:
		return msgs, false, nil, nil
	}
	// A user event's content can be a string; only assistant content is decoded.
	var message struct {
		Content []struct {
			Type  string `json:"type"`
			Text  string `json:"text"`
			Name  string `json:"name"`
			Input input  `json:"input"`
		} `json:"content"`
	}
	if err := json.Unmarshal(event.Message, &message); err != nil {
		return msgs, false, nil, fmt.Errorf("parse assistant message: %v", err)
	}
	changed := false
	for _, block := range message.Content {
		switch block.Type {
		case "text":
			if text := strings.TrimSpace(block.Text); text != "" {
				msgs, changed = appendText(msgs, text), true
			}
		case "tool_use":
			msgs, changed = appendCommand(msgs, command(block.Name, block.Input)), true
		}
	}
	return msgs, changed, nil, nil
}

type input struct {
	Command  string `json:"command"`
	FilePath string `json:"file_path"`
	Pattern  string `json:"pattern"`
}

// Title returns a report's first `#` heading, or "" without one.
func Title(report string) string {
	for line := range strings.Lines(report) {
		if title, ok := strings.CutPrefix(line, "# "); ok {
			return strings.TrimSpace(title)
		}
	}
	return ""
}

// appendText merges consecutive assistant texts into one message.
func appendText(msgs []Message, text string) []Message {
	if len(msgs) > 0 && msgs[len(msgs)-1].Kind == "assistant" {
		msgs[len(msgs)-1].Text += "\n\n" + text
		return msgs
	}
	return append(msgs, Message{Kind: "assistant", Text: text})
}

// appendCommand folds consecutive tool calls into one message.
func appendCommand(msgs []Message, cmd string) []Message {
	if len(msgs) > 0 && msgs[len(msgs)-1].Kind == "tools" {
		msgs[len(msgs)-1].Commands = append(msgs[len(msgs)-1].Commands, cmd)
		return msgs
	}
	return append(msgs, Message{Kind: "tools", Commands: []string{cmd}})
}

// command shows a Bash call as its command line and other tools by name and target.
func command(name string, in input) string {
	switch {
	case in.Command != "":
		return in.Command
	case in.FilePath != "":
		return name + " " + in.FilePath
	case in.Pattern != "":
		return name + " " + in.Pattern
	}
	return name
}
