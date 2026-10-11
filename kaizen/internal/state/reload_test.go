package state

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"strings"
	"testing"
	"time"

	"gotest.tools/v3/assert"
)

// seqRunner answers each command line with its recorded outputs in turn,
// repeating the last, and records the lines it ran.
type seqRunner struct {
	outputs map[string][]output
	calls   []string
}

func (s *seqRunner) Run(_ context.Context, name string, args ...string) ([]byte, error) {
	line := strings.Join(append([]string{name}, args...), " ")
	s.calls = append(s.calls, line)
	outs := s.outputs[line]
	if len(outs) == 0 {
		return nil, fmt.Errorf("unexpected command: %s", line)
	}
	if len(outs) > 1 {
		s.outputs[line] = outs[1:]
	}
	return []byte(outs[0].Stdout), outs[0].Err
}

// noWait returns at once.
func noWait(context.Context, time.Duration) error { return nil }

const (
	stopped    = "ActiveState=inactive\nSubState=dead\nDropInPaths=\nMainPID=0\n"
	failedUnit = "ActiveState=failed\nSubState=failed\nDropInPaths=\nMainPID=0\n"
	notReadyQs = "Not ready to accept queries yet.\n"
	locked     = `{"tree":"/t","barHeight":40,` +
		`"lock":{"locked":true,"requested":true,"secure":true,"passwordPam":true,"authenticating":false}}` + "\n"
)

// readyStatus is the Status Read returns for running and answer.
func readyStatus() Status {
	tree := "/home/user/.config/quickshell/kaizen"
	barHeight := 40
	return Status{
		Unit:      Unit,
		Active:    "active",
		Sub:       "running",
		PID:       4242,
		Ready:     true,
		Tree:      &tree,
		BarHeight: &barHeight,
		Lock:      &Lock{PasswordPam: true},
		Curtain:   &Curtain{Active: true, PasswordPam: true},
		Idle:      &Idle{Enabled: true, LockAfterSeconds: 300},
	}
}

func TestUnlocked(t *testing.T) {
	type result struct {
		Status Status
		Err    string
		Calls  []string
	}
	for _, tt := range []struct {
		name    string
		outputs map[string][]output
		want    result
	}{
		{
			name:    "down",
			outputs: map[string][]output{showLine: {{Stdout: stopped}}},
			want: result{
				Status: Status{Unit: Unit, Active: "inactive", Sub: "dead"},
				Calls:  []string{showLine},
			},
		},
		{
			name:    "unlocked",
			outputs: map[string][]output{showLine: {{Stdout: running}}, queryLine: {{Stdout: answer}}},
			want:    result{Status: readyStatus(), Calls: []string{showLine, queryLine}},
		},
		{
			name:    "locked",
			outputs: map[string][]output{showLine: {{Stdout: running}}, queryLine: {{Stdout: locked}}},
			want:    result{Err: "the session is locked", Calls: []string{showLine, queryLine}},
		},
		{
			name: "ready after a retry",
			outputs: map[string][]output{
				showLine:  {{Stdout: running}},
				queryLine: {{Stdout: notReadyQs}, {Stdout: answer}},
			},
			want: result{Status: readyStatus(), Calls: []string{showLine, queryLine, queryLine}},
		},
		{
			name:    "stays not ready",
			outputs: map[string][]output{showLine: {{Stdout: running}}, queryLine: {{Stdout: notReadyQs}}},
			want: result{
				Status: Status{
					Unit:   Unit,
					Active: "active",
					Sub:    "running",
					PID:    4242,
					Error:  new("not ready to accept queries"),
				},
				Calls: append([]string{showLine}, slices.Repeat([]string{queryLine}, unlockedAttempts)...),
			},
		},
		{
			name:    "stays unknown",
			outputs: map[string][]output{showLine: {{Stdout: running}}, queryLine: {{Stdout: "Function not found.\n"}}},
			want: result{
				Err:   "the lock state is unknown: Function not found.",
				Calls: append([]string{showLine}, slices.Repeat([]string{queryLine}, unlockedAttempts)...),
			},
		},
		{
			name:    "no lock",
			outputs: map[string][]output{showLine: {{Stdout: running}}, queryLine: {{Stdout: `{"tree":"/t"}` + "\n"}}},
			want: result{
				Err:   "the lock state is unknown: shell status has no lock",
				Calls: []string{showLine, queryLine},
			},
		},
		{
			name:    "systemctl fails",
			outputs: map[string][]output{showLine: {{Err: errors.New("exit status 1")}}},
			want: result{
				Err:   "systemctl show kaizen-shell.service: exit status 1",
				Calls: []string{showLine},
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &seqRunner{outputs: tt.outputs}
			status, err := unlocked(t.Context(), r, noWait)
			got := result{Status: status, Calls: r.calls}
			if err != nil {
				got.Err = err.Error()
			}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

func TestUnlockedLockedIsErrLocked(t *testing.T) {
	r := &seqRunner{outputs: map[string][]output{showLine: {{Stdout: running}}, queryLine: {{Stdout: locked}}}}
	_, err := unlocked(t.Context(), r, noWait)
	assert.Assert(t, errors.Is(err, ErrLocked))
}

const (
	journalLine   = "journalctl --user --unit kaizen-shell.service --after-cursor s=1 --output json --no-pager"
	hotReloadLine = "qs ipc --pid 4242 call shell reload"
	daemonReload  = "systemctl --user daemon-reload"
	resetFailed   = "systemctl --user reset-failed kaizen-shell.service"
	restartLine   = "systemctl --user restart kaizen-shell.service"
)

const (
	reloading = `{"MESSAGE":"  INFO: Reloading configuration...","PRIORITY":"6"}` + "\n"
	loaded    = `{"MESSAGE":"  INFO: Configuration Loaded","PRIORITY":"6"}` + "\n"
	loadError = `{"MESSAGE":" ERROR: Failed to load configuration","PRIORITY":"6"}` + "\n" +
		`{"MESSAGE":" ERROR:   caused by @shell.qml[552:1]: Syntax error","PRIORITY":"6"}` + "\n"
	warning = `{"MESSAGE":"  WARN scene: Binding loop","PRIORITY":"6"}` + "\n"
	exited  = `{"MESSAGE":"kaizen-shell.service: Failed with result 'exit-code'.","PRIORITY":"4"}` + "\n"
)

func TestReload(t *testing.T) {
	type result struct {
		Entries []Entry
		Err     string
		Calls   []string
	}
	reloadingEntry := Entry{Message: "  INFO: Reloading configuration...", Priority: 6}
	loadedEntry := Entry{Message: "  INFO: Configuration Loaded", Priority: 6}
	warningEntry := Entry{Message: "  WARN scene: Binding loop", Priority: 6}
	loadErrorEntries := []Entry{
		{Message: " ERROR: Failed to load configuration", Priority: 6},
		{Message: " ERROR:   caused by @shell.qml[552:1]: Syntax error", Priority: 6},
	}
	down := Status{Unit: Unit, Active: "failed", Sub: "failed"}
	for _, tt := range []struct {
		name    string
		status  Status
		restart bool
		outputs map[string][]output
		want    result
	}{
		{
			name:   "hot reload",
			status: readyStatus(),
			outputs: map[string][]output{
				cursorLine:    {{Stdout: "-- cursor: s=1\n"}},
				hotReloadLine: {{Stdout: "reloading\n"}},
				journalLine:   {{Stdout: reloading + loaded}, {Stdout: reloading + loaded + warning}},
				showLine:      {{Stdout: running}},
				queryLine:     {{Stdout: answer}},
			},
			want: result{
				Entries: []Entry{reloadingEntry, loadedEntry, warningEntry},
				Calls:   []string{cursorLine, hotReloadLine, journalLine, showLine, queryLine, journalLine},
			},
		},
		{
			name:   "hot reload, old config answers until loaded",
			status: readyStatus(),
			outputs: map[string][]output{
				cursorLine:    {{Stdout: "-- cursor: s=1\n"}},
				hotReloadLine: {{Stdout: "reloading\n"}},
				journalLine:   {{Stdout: reloading}, {Stdout: reloading + loaded}},
				showLine:      {{Stdout: running}},
				queryLine:     {{Stdout: answer}},
			},
			want: result{
				Entries: []Entry{reloadingEntry, loadedEntry},
				Calls: []string{
					cursorLine, hotReloadLine,
					journalLine, showLine, queryLine,
					journalLine, showLine, queryLine, journalLine,
				},
			},
		},
		{
			name:   "hot reload fails to load",
			status: readyStatus(),
			outputs: map[string][]output{
				cursorLine:    {{Stdout: "-- cursor: s=1\n"}},
				hotReloadLine: {{Stdout: "reloading\n"}},
				journalLine:   {{Stdout: reloading + loadError}},
			},
			want: result{
				Entries: append([]Entry{reloadingEntry}, loadErrorEntries...),
				Err:     "the shell failed to load its config",
				Calls:   []string{cursorLine, hotReloadLine, journalLine},
			},
		},
		{
			name:   "hot reload, last load wins",
			status: readyStatus(),
			outputs: map[string][]output{
				cursorLine:    {{Stdout: "-- cursor: s=1\n"}},
				hotReloadLine: {{Stdout: "reloading\n"}},
				journalLine:   {{Stdout: reloading + loadError + reloading + loaded}},
				showLine:      {{Stdout: running}},
				queryLine:     {{Stdout: answer}},
			},
			want: result{
				Entries: slices.Concat([]Entry{reloadingEntry}, loadErrorEntries, []Entry{reloadingEntry, loadedEntry}),
				Calls:   []string{cursorLine, hotReloadLine, journalLine, showLine, queryLine, journalLine},
			},
		},
		{
			name:   "hot reload refused",
			status: readyStatus(),
			outputs: map[string][]output{
				cursorLine:    {{Stdout: "-- cursor: s=1\n"}},
				hotReloadLine: {{Stdout: "Function not found.\n"}},
			},
			want: result{Err: "shell reload: Function not found.", Calls: []string{cursorLine, hotReloadLine}},
		},
		{
			name:   "hot reload refused, locked since the guard",
			status: readyStatus(),
			outputs: map[string][]output{
				cursorLine:    {{Stdout: "-- cursor: s=1\n"}},
				hotReloadLine: {{Stdout: "locked\n"}},
			},
			want: result{Err: "the session is locked", Calls: []string{cursorLine, hotReloadLine}},
		},
		{
			name:    "restart asked",
			status:  readyStatus(),
			restart: true,
			outputs: map[string][]output{
				cursorLine:   {{Stdout: "-- cursor: s=1\n"}},
				daemonReload: {{}},
				resetFailed:  {{}},
				restartLine:  {{}},
				journalLine:  {{Stdout: loaded}},
				showLine:     {{Stdout: running}},
				queryLine:    {{Stdout: answer}},
			},
			want: result{
				Entries: []Entry{loadedEntry},
				Calls: []string{
					cursorLine, daemonReload, resetFailed, restartLine,
					journalLine, showLine, queryLine, journalLine,
				},
			},
		},
		{
			name:   "restart of a failed unit",
			status: down,
			outputs: map[string][]output{
				cursorLine:   {{Stdout: "-- cursor: s=1\n"}},
				daemonReload: {{}},
				resetFailed:  {{}},
				restartLine:  {{}},
				journalLine:  {{Stdout: ""}, {Stdout: loaded}},
				showLine:     {{Stdout: running}},
				queryLine:    {{Stdout: notReadyQs}, {Stdout: answer}},
			},
			want: result{
				Entries: []Entry{loadedEntry},
				Calls: []string{
					cursorLine, daemonReload, resetFailed, restartLine,
					journalLine, showLine, queryLine,
					journalLine, showLine, queryLine, journalLine,
				},
			},
		},
		{
			name: "restart of a shell that is not ready",
			status: Status{
				Unit:   Unit,
				Active: "active",
				Sub:    "running",
				PID:    4242,
				Error:  new("not ready to accept queries"),
			},
			outputs: map[string][]output{
				cursorLine:   {{Stdout: "-- cursor: s=1\n"}},
				daemonReload: {{}},
				resetFailed:  {{}},
				restartLine:  {{}},
				journalLine:  {{Stdout: loaded}},
				showLine:     {{Stdout: running}},
				queryLine:    {{Stdout: answer}},
			},
			want: result{
				Entries: []Entry{loadedEntry},
				Calls: []string{
					cursorLine, daemonReload, resetFailed, restartLine,
					journalLine, showLine, queryLine, journalLine,
				},
			},
		},
		{
			name:   "restart fails to load",
			status: down,
			outputs: map[string][]output{
				cursorLine:   {{Stdout: "-- cursor: s=1\n"}},
				daemonReload: {{}},
				resetFailed:  {{}},
				restartLine:  {{}},
				journalLine:  {{Stdout: loadError + exited}},
			},
			want: result{
				Entries: append(loadErrorEntries, Entry{Message: "kaizen-shell.service: Failed with result 'exit-code'.", Priority: 4}),
				Err:     "the shell failed to load its config",
				Calls:   []string{cursorLine, daemonReload, resetFailed, restartLine, journalLine},
			},
		},
		{
			name:   "unit fails without loading",
			status: down,
			outputs: map[string][]output{
				cursorLine:   {{Stdout: "-- cursor: s=1\n"}},
				daemonReload: {{}},
				resetFailed:  {{}},
				restartLine:  {{}},
				journalLine:  {{Stdout: exited}},
				showLine:     {{Stdout: failedUnit}},
			},
			want: result{
				Entries: []Entry{{Message: "kaizen-shell.service: Failed with result 'exit-code'.", Priority: 4}},
				Err:     "kaizen-shell.service failed",
				Calls:   []string{cursorLine, daemonReload, resetFailed, restartLine, journalLine, showLine},
			},
		},
		{
			name:   "restart refused",
			status: down,
			outputs: map[string][]output{
				cursorLine:   {{Stdout: "-- cursor: s=1\n"}},
				daemonReload: {{}},
				resetFailed:  {{}},
				restartLine:  {{Err: errors.New("exit status 1")}},
			},
			want: result{
				Err:   "systemctl restart kaizen-shell.service: exit status 1",
				Calls: []string{cursorLine, daemonReload, resetFailed, restartLine},
			},
		},
		{
			name:   "never loads",
			status: readyStatus(),
			outputs: map[string][]output{
				cursorLine:    {{Stdout: "-- cursor: s=1\n"}},
				hotReloadLine: {{Stdout: "reloading\n"}},
				journalLine:   {{Stdout: reloading}},
				showLine:      {{Stdout: running}},
				queryLine:     {{Stdout: answer}},
			},
			want: result{
				Entries: []Entry{reloadingEntry},
				Err:     "kaizen-shell.service did not load its config",
				Calls: slices.Concat(
					[]string{cursorLine, hotReloadLine},
					slices.Repeat([]string{journalLine, showLine, queryLine}, loadAttempts),
					[]string{journalLine},
				),
			},
		},
		{
			name:    "no cursor",
			status:  readyStatus(),
			outputs: map[string][]output{cursorLine: {{Err: errors.New("exit status 1")}}},
			want:    result{Err: "journalctl: exit status 1", Calls: []string{cursorLine}},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &seqRunner{outputs: tt.outputs}
			entries, err := reload(t.Context(), r, tt.status, tt.restart, noWait)
			got := result{Entries: entries, Calls: r.calls}
			if err != nil {
				got.Err = err.Error()
			}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}
