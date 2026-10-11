package state

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"gotest.tools/v3/assert"
)

// output is a program's recorded stdout and error.
type output struct {
	Stdout string
	Err    error
}

// fakeRunner answers each command line with its recorded output.
type fakeRunner map[string]output

func (f fakeRunner) Run(_ context.Context, name string, args ...string) ([]byte, error) {
	line := strings.Join(append([]string{name}, args...), " ")
	out, ok := f[line]
	if !ok {
		return nil, fmt.Errorf("unexpected command: %s", line)
	}
	return []byte(out.Stdout), out.Err
}

const (
	showLine  = "systemctl --user show kaizen-shell.service -p MainPID,ActiveState,SubState,DropInPaths"
	queryLine = "qs ipc --pid 4242 call shell status"
)

const (
	running = "ActiveState=active\nSubState=running\nDropInPaths=\nMainPID=4242\n"
	answer  = `{"tree":"/home/user/.config/quickshell/kaizen","barHeight":40,` +
		`"lock":{"locked":false,"requested":false,"secure":false,"passwordPam":true,"authenticating":false},` +
		`"curtain":{"active":true,"awake":false,"passwordPam":true,"authenticating":false},` +
		`"idle":{"enabled":true,"idle":false,"lockAfterSeconds":300}}` + "\n"
)

func TestRead(t *testing.T) {
	tree := "/home/user/.config/quickshell/kaizen"
	devTree := "/home/user/.dotfiles/.claude/worktrees/x/stow/kaizen/.config/quickshell/kaizen"
	barHeight := 40
	curtain := &Curtain{Active: true, PasswordPam: true}
	idle := &Idle{Enabled: true, LockAfterSeconds: 300}
	for _, tt := range []struct {
		name    string
		runner  fakeRunner
		want    Status
		wantErr string
	}{
		{
			name:   "running",
			runner: fakeRunner{showLine: {Stdout: running}, queryLine: {Stdout: answer}},
			want: Status{
				Unit:      Unit,
				Active:    "active",
				Sub:       "running",
				PID:       4242,
				Ready:     true,
				Tree:      &tree,
				BarHeight: &barHeight,
				Lock:      &Lock{PasswordPam: true},
				Curtain:   curtain,
				Idle:      idle,
			},
		},
		{
			name: "locked",
			runner: fakeRunner{
				showLine: {Stdout: running},
				queryLine: {Stdout: `{"tree":"` + tree + `","barHeight":40,` +
					`"lock":{"locked":true,"requested":true,"secure":true,"passwordPam":true,"authenticating":false},` +
					`"curtain":{"active":true,"awake":false,"passwordPam":true,"authenticating":false},` +
					`"idle":{"enabled":true,"idle":false,"lockAfterSeconds":300}}` + "\n"},
			},
			want: Status{
				Unit:      Unit,
				Active:    "active",
				Sub:       "running",
				PID:       4242,
				Ready:     true,
				Tree:      &tree,
				BarHeight: &barHeight,
				Lock:      &Lock{Locked: true, Requested: true, Secure: true, PasswordPam: true},
				Curtain:   curtain,
				Idle:      idle,
			},
		},
		{
			name: "dev drop-in",
			runner: fakeRunner{
				showLine: {Stdout: "ActiveState=active\nSubState=running\n" +
					"DropInPaths=/etc/systemd/user/kaizen-shell.service.d/env.conf " +
					"/run/user/1000/systemd/user/kaizen-shell.service.d/dev.conf\nMainPID=4242\n"},
				queryLine: {Stdout: `{"tree":"` + devTree + `","barHeight":40}` + "\n"},
			},
			want: Status{
				Unit:      Unit,
				Active:    "active",
				Sub:       "running",
				PID:       4242,
				Dev:       true,
				Ready:     true,
				Tree:      &devTree,
				BarHeight: &barHeight,
			},
		},
		{
			name:   "stopped",
			runner: fakeRunner{showLine: {Stdout: "ActiveState=inactive\nSubState=dead\nDropInPaths=\nMainPID=0\n"}},
			want:   Status{Unit: Unit, Active: "inactive", Sub: "dead"},
		},
		{
			name:   "failed",
			runner: fakeRunner{showLine: {Stdout: "ActiveState=failed\nSubState=failed\nDropInPaths=\nMainPID=0\n"}},
			want:   Status{Unit: Unit, Active: "failed", Sub: "failed"},
		},
		{
			name: "not ready",
			runner: fakeRunner{
				showLine:  {Stdout: running},
				queryLine: {Stdout: "Not ready to accept queries yet.\n"},
			},
			want: Status{Unit: Unit, Active: "active", Sub: "running", PID: 4242, Error: new("not ready to accept queries")},
		},
		{
			name: "shell without status",
			runner: fakeRunner{
				showLine:  {Stdout: running},
				queryLine: {Stdout: "Function not found.\n"},
			},
			want: Status{Unit: Unit, Active: "active", Sub: "running", PID: 4242, Error: new("Function not found.")},
		},
		{
			name:    "systemctl fails",
			runner:  fakeRunner{showLine: {Err: errors.New("exit status 1")}},
			wantErr: "systemctl show kaizen-shell.service: exit status 1",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			got, err := Read(t.Context(), tt.runner)
			if tt.wantErr != "" {
				assert.Error(t, err, tt.wantErr)
				return
			}
			assert.NilError(t, err)
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

func TestQuery(t *testing.T) {
	barHeight := 40
	for _, tt := range []struct {
		name    string
		out     output
		want    shellStatus
		wantErr string
	}{
		{
			name: "answer",
			out:  output{Stdout: `{"barHeight":40,"extra":1}` + "\n"},
			want: shellStatus{BarHeight: &barHeight},
		},
		{
			name:    "not ready",
			out:     output{Stdout: "Not ready to accept queries yet.\n"},
			wantErr: "not ready to accept queries",
		},
		{
			name:    "target not found",
			out:     output{Stdout: "Target not found.\n"},
			wantErr: "Target not found.",
		},
		{
			name:    "function not found",
			out:     output{Stdout: "Function not found.\n"},
			wantErr: "Function not found.",
		},
		{
			name:    "no response",
			out:     output{Stdout: "Error occurred while waiting for response.\n"},
			wantErr: "Error occurred while waiting for response.",
		},
		{
			name:    "invalid response",
			out:     output{Stdout: "Received invalid IPC response from qs\n"},
			wantErr: "Received invalid IPC response from qs",
		},
		{
			name:    "no instance",
			out:     output{Stdout: "No instance found for pid 4242\n", Err: errors.New("exit status 255")},
			wantErr: "No instance found for pid 4242",
		},
		{
			name:    "qs fails silently",
			out:     output{Err: errors.New("signal: killed")},
			wantErr: "qs ipc: signal: killed",
		},
		{
			name:    "invalid JSON",
			out:     output{Stdout: "{\"barHeight\":\n"},
			wantErr: `shell status: jsontext: unexpected EOF within "/barHeight" after offset 14`,
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			got, err := query(t.Context(), fakeRunner{queryLine: tt.out}, 4242)
			if tt.wantErr != "" {
				assert.Error(t, err, tt.wantErr)
				assert.Equal(t, errors.Is(err, ErrNotReady), tt.wantErr == ErrNotReady.Error())
				return
			}
			assert.NilError(t, err)
			assert.DeepEqual(t, got, tt.want)
		})
	}
}
