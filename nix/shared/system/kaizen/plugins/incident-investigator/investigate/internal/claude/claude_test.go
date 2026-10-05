package claude

import (
	"os"
	"path/filepath"
	"slices"
	"testing"

	"gotest.tools/v3/assert"
)

func TestFold(t *testing.T) {
	const (
		prompt  = `{"type":"user","message":{"role":"user","content":"Investigate trace."}}`
		started = `{"type":"system","subtype":"init","tools":["Bash","Grep","Read"]}`
		think   = `{"type":"assistant","message":{"content":[{"type":"thinking","thinking":"Hmm."}]}}`
		blank   = `{"type":"assistant","message":{"content":[{"type":"text","text":" \n"}]}}`
		text1   = `{"type":"assistant","message":{"content":[{"type":"text","text":"Searching.\n"}]}}`
		text2   = `{"type":"assistant","message":{"content":[{"type":"text","text":"Found 3 entries."}]}}`
		bash1   = `{"type":"assistant","message":{"content":[` +
			`{"type":"tool_use","name":"Bash","input":{"command":"gcloud logging read a","timeout":10000}}]}}`
		bash2 = `{"type":"assistant","message":{"content":[` +
			`{"type":"tool_use","name":"Bash","input":{"command":"gcloud logging read b"}}]}}`
		read   = `{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"/x"}}]}}`
		grep   = `{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Grep","input":{"pattern":"err"}}]}}`
		output = `{"type":"user","message":{"content":[{"type":"tool_result","is_error":true,"content":"Exit code 1"}]}}`
		denied = `{"type":"system","subtype":"permission_denied","tool_name":"Bash"}`
		mixed  = `{"type":"assistant","message":{"content":[` +
			`{"type":"text","text":"Checking."},{"type":"tool_use","name":"Bash","input":{"command":"gcloud logging read c"}}]}}`
		success = `{"type":"result","subtype":"success","is_error":false,"result":"Root cause.","total_cost_usd":0.25}`
		budget  = `{"type":"result","subtype":"error_max_budget_usd","is_error":true,"total_cost_usd":5.01}`
	)
	for _, tt := range []struct {
		name        string
		msgs        []Message
		lines       []string
		want        []Message
		wantChanged bool
		wantResult  *Result
	}{
		{
			name:        "text, tools and text",
			wantChanged: true,
			lines:       []string{started, text1, bash1, output, text2, success},
			want: []Message{
				{Kind: "assistant", Text: "Searching."},
				{Kind: "tools", Commands: []string{"gcloud logging read a"}},
				{Kind: "assistant", Text: "Found 3 entries."},
			},
			wantResult: &Result{Text: "Root cause.", CostUSD: 0.25},
		},
		{
			name:        "consecutive tool calls fold into one message",
			wantChanged: true,
			lines:       []string{bash1, output, bash2, read, grep},
			want: []Message{
				{Kind: "tools", Commands: []string{"gcloud logging read a", "gcloud logging read b", "Read /x", "Grep err"}},
			},
		},
		{
			name:        "consecutive texts merge and thinking is skipped",
			wantChanged: true,
			lines:       []string{text1, think, text2},
			want:        []Message{{Kind: "assistant", Text: "Searching.\n\nFound 3 entries."}},
		},
		{
			name:        "text and tool call in one event",
			wantChanged: true,
			lines:       []string{mixed},
			want: []Message{
				{Kind: "assistant", Text: "Checking."},
				{Kind: "tools", Commands: []string{"gcloud logging read c"}},
			},
		},
		{
			name:  "user and system events add nothing",
			lines: []string{prompt, started, output, denied},
		},
		{
			name:  "thinking and blank text add nothing",
			lines: []string{think, blank},
		},
		{
			name:        "appends to earlier messages",
			wantChanged: true,
			msgs:        []Message{{Kind: "user", Text: "Why?"}},
			lines:       []string{bash1},
			want: []Message{
				{Kind: "user", Text: "Why?"},
				{Kind: "tools", Commands: []string{"gcloud logging read a"}},
			},
		},
		{
			name:       "an error result carries its subtype",
			lines:      []string{budget},
			wantResult: &Result{IsError: true, Text: "error_max_budget_usd", CostUSD: 5.01},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			msgs := tt.msgs
			var gotChanged bool
			var got *Result
			for _, line := range tt.lines {
				var changed bool
				var result *Result
				var err error
				msgs, changed, result, err = Fold(msgs, []byte(line))
				assert.NilError(t, err)
				gotChanged = gotChanged || changed
				if result != nil {
					got = result
				}
			}
			assert.DeepEqual(t, msgs, tt.want)
			assert.Equal(t, gotChanged, tt.wantChanged)
			assert.DeepEqual(t, got, tt.wantResult)
		})
	}
}

func TestTitle(t *testing.T) {
	for _, tt := range []struct {
		name   string
		report string
		want   string
	}{
		{
			name:   "first heading",
			report: "Done.\n\n# Spanner abort on spanner-events \n\n## Likely root cause\n# Later",
			want:   "Spanner abort on spanner-events",
		},
		{name: "no title", report: "## Likely root cause\n#hashtag", want: ""},
	} {
		t.Run(tt.name, func(t *testing.T) {
			got := Title(tt.report)

			assert.Equal(t, got, tt.want)
		})
	}
}

func TestFoldInvalid(t *testing.T) {
	msgs, changed, result, err := Fold(nil, []byte("not json"))
	assert.ErrorContains(t, err, "parse event")
	assert.DeepEqual(t, msgs, []Message(nil))
	assert.Equal(t, changed, false)
	assert.DeepEqual(t, result, (*Result)(nil))
}

func TestGitRules(t *testing.T) {
	sourceDir := t.TempDir()
	assert.NilError(t, os.Mkdir(filepath.Join(sourceDir, "svc"), 0o700))
	assert.NilError(t, os.WriteFile(filepath.Join(sourceDir, "notes.txt"), nil, 0o600))

	got := gitRules(sourceDir)

	repo := filepath.Join(sourceDir, "svc")
	assert.DeepEqual(t, got, []string{
		"Bash(git -C " + repo + " log *)", "Bash(git -C " + repo + " show *)", "Bash(git -C " + repo + " diff *)",
		"Bash(git -C " + repo + " merge-base *)", "Bash(git -C " + repo + " rev-parse *)",
		"Bash(git -C " + repo + " cat-file *)",
	})
}

func TestCommand(t *testing.T) {
	sourceDir := t.TempDir()
	assert.NilError(t, os.Mkdir(filepath.Join(sourceDir, "svc"), 0o700))
	repo := filepath.Join(sourceDir, "svc")
	base := []string{
		"claude", "-p", "--session-id", "s", "--model", "m", "--effort", "e", "--output-format", "stream-json", "--verbose",
		"--plugin-dir", "/plugin", "--restricted", "--strict-mcp-config", "--permission-mode", "dontAsk",
		"--max-budget-usd", "5",
	}
	allowed := []string{
		"--allowedTools", "Bash(gcloud logging read *)", "Bash(gcloud logging buckets list *)",
		"Bash(gcloud alpha monitoring alerts describe *)", "Bash(gcloud alpha monitoring alerts list *)",
		"Bash(gcloud monitoring policies describe *)", "Bash(gcloud run services describe *)",
		"Bash(gcloud run revisions list *)", "Bash(gcloud run revisions describe *)", "Bash(gcloud run jobs describe *)", "Read", "Grep",
	}
	for _, tt := range []struct {
		name         string
		sourceDirs   []string
		instructions string
		want         []string
	}{
		{
			name: "logs only",
			want: slices.Concat(base, []string{"--tools", "Bash,Read,Grep"}, allowed),
		},
		{
			name:         "source dirs and instructions",
			sourceDirs:   []string{sourceDir, "/missing"},
			instructions: "Be brief.",
			want: slices.Concat(
				base,
				[]string{"--append-system-prompt", "Be brief.", "--add-dir", sourceDir, "--add-dir", "/missing"},
				[]string{"--add-dir", "/gomod", "--tools", "Bash,Read,Grep,LSP"},
				allowed,
				[]string{
					"Bash(git -C " + repo + " log *)", "Bash(git -C " + repo + " show *)", "Bash(git -C " + repo + " diff *)",
					"Bash(git -C " + repo + " merge-base *)", "Bash(git -C " + repo + " rev-parse *)",
					"Bash(git -C " + repo + " cat-file *)", "LSP", "Bash(investigate checkout *)",
					"--disallowedTools", "Bash(git * --output*)",
				},
			),
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			cmd := Command("/run", "/plugin", tt.sourceDirs, "/gomod", "m", "e", "s", tt.instructions, "prompt", false)

			assert.DeepEqual(t, cmd.Args, tt.want)
		})
	}
}
