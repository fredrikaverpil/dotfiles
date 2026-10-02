package main

import (
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gotest.tools/v3/assert"

	"investigate/internal/claude"
)

func TestCombine(t *testing.T) {
	items := func() map[string]*Investigation {
		return map[string]*Investigation{
			"aaaaaa": {
				ID: "aaaaaa", Status: "done", Projects: []string{"p-prod"}, Title: "Spanner abort", Tag: "prod",
				Messages: []claude.Message{
					{Kind: "user", Text: "Investigate."},
					{Kind: "assistant", Text: "# Spanner abort\n\nRoot cause A."},
					{Kind: "user", Text: "Why?"},
				},
				Entities: []claude.Entity{{Kind: "user", ID: "alice", Count: 2}, {Kind: "organization", ID: "org1", Count: 1}},
			},
			"bbbbbb": {
				ID: "bbbbbb", Status: "failed", Projects: []string{"q-prod", "p-prod"}, TraceID: "t1", Tag: "dev",
				Messages: []claude.Message{{Kind: "assistant", Text: "Root cause B."}},
				Entities: []claude.Entity{{Kind: "user", ID: "alice", Count: 1}, {Kind: "user", ID: "bob", Count: 5}},
			},
			"cccccc": {ID: "cccccc", Status: "running"},
		}
	}
	for _, tt := range []struct {
		name    string
		ids     []string
		want    *Investigation
		wantErr string
	}{
		{
			name: "alerts and reports become the notes, the first tag and the entities are kept",
			ids:  []string{"aaaaaa", "bbbbbb"},
			want: &Investigation{
				Status:   "draft",
				Tag:      "prod",
				Projects: []string{"p-prod", "q-prod"},
				Notes: "Combine these earlier investigations of projects p-prod, q-prod and investigate further: " +
					"find what connects them, and what the earlier ones missed.\n\n" +
					"### Investigation aaaaaa: Spanner abort\n\nProjects: p-prod\n\n" +
					"Report:\n# Spanner abort\n\nRoot cause A.\n\n\n" +
					"### Investigation bbbbbb: \n\nProjects: q-prod, p-prod\nTrace id: t1\n\nReport:\nRoot cause B.\n",
				Messages: []claude.Message{},
				Entities: []claude.Entity{
					{Kind: "user", ID: "bob", Count: 5},
					{Kind: "user", ID: "alice", Count: 3},
					{Kind: "organization", ID: "org1", Count: 1},
				},
			},
		},
		{name: "one", ids: []string{"aaaaaa"}, wantErr: "at least two"},
		{name: "a running one", ids: []string{"aaaaaa", "cccccc"}, wantErr: "running"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			d := &daemon{logger: slog.New(slog.NewTextHandler(io.Discard, nil)), state: t.TempDir(), items: items()}

			id, err := d.combine(tt.ids)

			if tt.wantErr != "" {
				assert.ErrorContains(t, err, tt.wantErr)
				return
			}
			assert.NilError(t, err)
			got := d.items[id]
			got.ID, got.CreatedAt = "", 0
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

func TestDraft(t *testing.T) {
	const link = "https://console.cloud.google.com/monitoring/alerting/alerts/0.abc?project=p-dev"
	for _, tt := range []struct {
		name    string
		req     request
		want    *Investigation
		wantErr string
	}{
		{
			name: "an alert's link becomes the notes and its project the project",
			req:  request{Verb: "draft", Tag: "dev", Alert: &Alert{App: "Slack", Body: "<" + link + "|View alert>"}},
			want: &Investigation{
				Status: "draft", Tag: "dev", Projects: []string{"p-dev"}, Notes: link,
				Alert:    &Alert{App: "Slack", Body: "<" + link + "|View alert>"},
				Messages: []claude.Message{}, Entities: []claude.Entity{},
			},
		},
		{
			name: "empty",
			req:  request{Verb: "draft"},
			want: &Investigation{
				Status: "draft", Projects: []string{}, Messages: []claude.Message{}, Entities: []claude.Entity{},
			},
		},
		{
			name:    "a tag that is not configured",
			req:     request{Verb: "draft", Tag: "staging"},
			wantErr: `tag "staging": want one of dev`,
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			d := &daemon{tags: []Tag{{"dev", "water"}}, state: t.TempDir(), items: map[string]*Investigation{}}

			id, err := d.draft(tt.req)

			if tt.wantErr != "" {
				assert.ErrorContains(t, err, tt.wantErr)
				return
			}
			assert.NilError(t, err)
			got := d.items[id]
			got.ID, got.CreatedAt = "", 0
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

func TestEdit(t *testing.T) {
	for _, tt := range []struct {
		name    string
		req     request
		want    *Investigation
		wantErr string
	}{
		{
			name: "fields are stored as typed, projects cleaned",
			req:  request{Tag: "prod", Projects: []string{" a ", "", "a", "b"}, TraceID: " t ", Notes: "n"},
			want: &Investigation{
				ID: "aaaaaa", Status: "draft", Tag: "prod", Projects: []string{"a", "b"}, TraceID: " t ", Notes: "n",
			},
		},
		{
			name: "no tag",
			req:  request{Projects: []string{"a"}},
			want: &Investigation{ID: "aaaaaa", Status: "draft", Projects: []string{"a"}},
		},
		{
			name:    "a tag that is not configured",
			req:     request{Tag: "staging"},
			want:    &Investigation{ID: "aaaaaa", Status: "draft", Tag: "dev"},
			wantErr: "want one of dev, prod",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			d := &daemon{
				tags:  []Tag{{"dev", "water"}, {"prod", "rose"}},
				state: t.TempDir(),
				items: map[string]*Investigation{"aaaaaa": {ID: "aaaaaa", Status: "draft", Tag: "dev"}},
			}

			err := d.edit(d.items["aaaaaa"], tt.req)

			if tt.wantErr != "" {
				assert.ErrorContains(t, err, tt.wantErr)
			} else {
				assert.NilError(t, err)
			}
			assert.DeepEqual(t, d.items["aaaaaa"], tt.want)
		})
	}
}

func TestLoad(t *testing.T) {
	for _, tt := range []struct {
		name         string
		files        map[string]any
		want         map[string]*Investigation
		wantSettings settings
	}{
		{
			name: "older fields move to the current ones",
			files: map[string]any{
				"aaaaaa/investigation.json": map[string]any{
					"id": "aaaaaa", "status": "done", "project": "p-prod", "envHint": "prod",
				},
				"bbbbbb/investigation.json": map[string]any{"id": "bbbbbb", "status": "draft"},
			},
			want: map[string]*Investigation{
				"aaaaaa": {ID: "aaaaaa", Status: "done", Projects: []string{"p-prod"}, Tag: "prod"},
				"bbbbbb": {ID: "bbbbbb", Status: "draft", Projects: []string{}},
			},
			wantSettings: settings{"claude-sonnet-5-5", "high", []Tag{{"prod", "rose"}}},
		},
		{
			name: "runs before models were recorded used the defaults, and settings keep what is set",
			files: map[string]any{
				"settings.json":             map[string]any{"model": "claude-opus-5-5", "tags": []Tag{{"old", "leaf"}}},
				"aaaaaa/investigation.json": map[string]any{"id": "aaaaaa", "status": "done", "sessionId": "s"},
			},
			want: map[string]*Investigation{
				"aaaaaa": {
					ID: "aaaaaa", Status: "done", SessionID: "s", Projects: []string{},
					Model: "claude-sonnet-5-5", Effort: "high",
				},
			},
			wantSettings: settings{"claude-opus-5-5", "high", []Tag{{"prod", "rose"}}},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			state := t.TempDir()
			for path, v := range tt.files {
				assert.NilError(t, writeJSON(filepath.Join(state, path), v))
			}
			d := &daemon{
				tags:   []Tag{{"prod", "rose"}},
				logger: slog.New(slog.NewTextHandler(io.Discard, nil)),
				state:  state,
				items:  map[string]*Investigation{},
			}

			err := d.load()

			assert.NilError(t, err)
			assert.DeepEqual(t, d.items, tt.want)
			assert.DeepEqual(t, d.settings, tt.wantSettings)
			var written settings
			assert.NilError(t, readJSON(filepath.Join(state, "settings.json"), &written))
			assert.DeepEqual(t, written, tt.wantSettings)
		})
	}
}

func TestSetSettings(t *testing.T) {
	tags := []Tag{{"prod", "rose"}}
	for _, tt := range []struct {
		name    string
		req     request
		want    settings
		wantErr string
	}{
		{name: "both", req: request{Model: "claude-opus-5-5", Effort: "max"}, want: settings{"claude-opus-5-5", "max", tags}},
		{name: "omitted ones are kept", req: request{Effort: "low"}, want: settings{"claude-sonnet-5-5", "low", tags}},
		{
			name:    "unknown model",
			req:     request{Model: "gpt"},
			want:    settings{"claude-sonnet-5-5", "high", tags},
			wantErr: "want one of",
		},
		{
			name:    "unknown effort",
			req:     request{Effort: "ultra"},
			want:    settings{"claude-sonnet-5-5", "high", tags},
			wantErr: "want one of",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			d := &daemon{state: t.TempDir(), settings: settings{"claude-sonnet-5-5", "high", tags}}

			err := d.setSettings(tt.req)

			if tt.wantErr != "" {
				assert.ErrorContains(t, err, tt.wantErr)
			} else {
				assert.NilError(t, err)
			}
			assert.DeepEqual(t, d.settings, tt.want)
		})
	}
}

func TestSourcesNote(t *testing.T) {
	for _, tt := range []struct {
		name       string
		sourceDirs []string
		want       string
	}{
		{name: "none", want: ""},
		{name: "one", sourceDirs: []string{"/src/a"}, want: "\n\nSource repositories are cloned under `/src/a`."},
		{
			name:       "several",
			sourceDirs: []string{"/src/a", "/src/b"},
			want:       "\n\nSource repositories are cloned under `/src/a`, `/src/b`.",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			d := &daemon{sourceDirs: tt.sourceDirs}

			got := d.sourcesNote()

			assert.Equal(t, got, tt.want)
		})
	}
}

func TestInstructions(t *testing.T) {
	dir := t.TempDir()
	assert.NilError(t, os.WriteFile(filepath.Join(dir, "base.md"), []byte("# Base\n\nRead only.\n"), 0o600))
	assert.NilError(t, os.WriteFile(filepath.Join(dir, "org.md"), []byte("\nImages are ours.\n"), 0o600))
	for _, tt := range []struct {
		name    string
		files   []string
		want    string
		wantErr string
	}{
		{name: "none", want: ""},
		{name: "joined in order", files: []string{"base.md", "org.md"}, want: "# Base\n\nRead only.\n\nImages are ours."},
		{name: "a missing file", files: []string{"base.md", "gone.md"}, wantErr: "gone.md"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			var files []string
			for _, f := range tt.files {
				files = append(files, filepath.Join(dir, f))
			}
			d := &daemon{instructionFiles: files}

			got, err := d.instructions()

			if tt.wantErr != "" {
				assert.ErrorContains(t, err, tt.wantErr)
			} else {
				assert.NilError(t, err)
			}
			assert.Equal(t, got, tt.want)
		})
	}
}

func TestReadConfig(t *testing.T) {
	type pattern struct{ Kind, Regex string }
	type result struct {
		Tags     []Tag
		Patterns []pattern
	}
	builtIn := []pattern{
		{"user", `\busers/([A-Za-z0-9][A-Za-z0-9_.|@~-]*)`},
		{"organization", `\borganizations/([A-Za-z0-9][A-Za-z0-9_.|~-]*)`},
	}
	for _, tt := range []struct {
		name    string
		file    string
		want    result
		wantErr string
	}{
		{
			name: "tags and patterns",
			file: `{"tags":[{"name":"prod","color":"rose"}],"entityPatterns":[{"kind":"user","regex":"member_id=(\\w+)"}]}`,
			want: result{[]Tag{{"prod", "rose"}}, append(builtIn, pattern{"user", `member_id=(\w+)`})},
		},
		{name: "empty", file: `{}`, want: result{[]Tag{}, builtIn}},
		{
			name:    "a pattern without a group",
			file:    `{"entityPatterns":[{"kind":"user","regex":"id"}]}`,
			wantErr: "want a group",
		},
		{name: "an invalid pattern", file: `{"entityPatterns":[{"kind":"user","regex":"("}]}`, wantErr: "entity pattern"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "config.json")
			assert.NilError(t, os.WriteFile(path, []byte(tt.file), 0o600))

			tags, patterns, err := readConfig(path)

			if tt.wantErr != "" {
				assert.ErrorContains(t, err, tt.wantErr)
				return
			}
			assert.NilError(t, err)
			got := result{Tags: tags}
			for _, p := range patterns {
				got.Patterns = append(got.Patterns, pattern{p.Kind, p.Regexp.String()})
			}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

func TestGCPAlertLink(t *testing.T) {
	const link = "https://console.cloud.google.com/monitoring/alerting/alerts/0.abc?channelType=slack&project=my-project"
	type result struct{ Link, Project string }
	for _, tt := range []struct {
		name string
		text string
		want result
	}{
		{name: "plain", text: "Alert fired " + link + " now", want: result{link, "my-project"}},
		{name: "slack markup", text: "<" + link + "|View alert>", want: result{link, "my-project"}},
		{name: "escaped ampersand", text: strings.ReplaceAll(link, "&", "&amp;"), want: result{link, "my-project"}},
		{
			name: "incident",
			text: "https://console.cloud.google.com/monitoring/alerting/incidents/0.abc?project=p-prod",
			want: result{"https://console.cloud.google.com/monitoring/alerting/incidents/0.abc?project=p-prod", "p-prod"},
		},
		{
			name: "no project",
			text: "https://console.cloud.google.com/monitoring/alerting/alerts/0.abc",
			want: result{"https://console.cloud.google.com/monitoring/alerting/alerts/0.abc", ""},
		},
		{name: "no link", text: "CPU high", want: result{}},
	} {
		t.Run(tt.name, func(t *testing.T) {
			gotLink, gotProject := gcpAlertLink(tt.text)

			assert.DeepEqual(t, result{gotLink, gotProject}, tt.want)
		})
	}
}
