package state

import (
	"errors"
	"testing"

	"gotest.tools/v3/assert"
)

const cursorLine = "journalctl --user --lines 0 --show-cursor --quiet --no-pager"

func TestCursor(t *testing.T) {
	for _, tt := range []struct {
		name    string
		out     output
		want    string
		wantErr string
	}{
		{
			name: "cursor",
			out:  output{Stdout: "-- cursor: s=abc;i=1\n"},
			want: "s=abc;i=1",
		},
		{
			name:    "no cursor",
			out:     output{Stdout: "-- No entries --\n"},
			wantErr: "journalctl: no cursor",
		},
		{
			name:    "journalctl fails",
			out:     output{Err: errors.New("exit status 1")},
			wantErr: "journalctl: exit status 1",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			got, err := Cursor(t.Context(), fakeRunner{cursorLine: tt.out})
			if tt.wantErr != "" {
				assert.Error(t, err, tt.wantErr)
				return
			}
			assert.NilError(t, err)
			assert.Equal(t, got, tt.want)
		})
	}
}

func TestParseJournal(t *testing.T) {
	for _, tt := range []struct {
		name    string
		out     string
		want    []Entry
		wantErr string
	}{
		{
			name: "none",
			out:  "",
		},
		{
			name: "string and byte array",
			out: `{"MESSAGE":"Stopping Quickshell desktop shell...","PRIORITY":"6","_PID":"1"}` + "\n" +
				// "\x1b[33m  WARN\x1b[0m: x".
				`{"MESSAGE":[27,91,51,51,109,32,32,87,65,82,78,27,91,48,109,58,32,120],"PRIORITY":"6"}` + "\n",
			want: []Entry{
				{Message: "Stopping Quickshell desktop shell...", Priority: 6},
				{Message: "  WARN: x", Priority: 6},
			},
		},
		{
			name: "no message or priority",
			out:  `{"MESSAGE":null}` + "\n",
			want: []Entry{{Priority: 6}},
		},
		{
			name:    "invalid priority",
			out:     `{"MESSAGE":"x","PRIORITY":"high"}` + "\n",
			wantErr: `PRIORITY: strconv.Atoi: parsing "high": invalid syntax`,
		},
		{
			name:    "invalid JSON",
			out:     `{"MESSAGE":` + "\n",
			wantErr: `jsontext: unexpected EOF within "/MESSAGE" after offset 12`,
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			got, err := parseJournal([]byte(tt.out))
			if tt.wantErr != "" {
				assert.Error(t, err, tt.wantErr)
				return
			}
			assert.NilError(t, err)
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

func TestEntryLevel(t *testing.T) {
	for _, tt := range []struct {
		name  string
		entry Entry
		want  string
	}{
		{name: "quickshell warning", entry: Entry{Message: "  WARN scene: Binding loop", Priority: 6}, want: "WARN"},
		{name: "quickshell error", entry: Entry{Message: " ERROR: Failed to load configuration", Priority: 6}, want: "ERROR"},
		{name: "quickshell info", entry: Entry{Message: "  INFO: Configuration Loaded", Priority: 6}, want: "INFO"},
		{name: "quickshell debug", entry: Entry{Message: " DEBUG qml: registered", Priority: 6}, want: "DEBUG"},
		{name: "level in a word", entry: Entry{Message: "WARNING: x", Priority: 6}, want: "INFO"},
		{name: "systemd warning", entry: Entry{Message: "kaizen-shell.service: Failed with result 'exit-code'.", Priority: 4}, want: "WARN"},
		{name: "systemd error", entry: Entry{Message: "x", Priority: 3}, want: "ERROR"},
		{name: "critical", entry: Entry{Message: "x", Priority: 2}, want: "FATAL"},
		{name: "notice", entry: Entry{Message: "x", Priority: 5}, want: "INFO"},
		{name: "debug", entry: Entry{Message: "x", Priority: 7}, want: "DEBUG"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.entry.Level(), tt.want)
		})
	}
}
