package status

import (
	"bytes"
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
	running   = "ActiveState=active\nSubState=running\nDropInPaths=\nMainPID=4242\n"
	answer    = `{"tree":"/home/user/.config/quickshell/kaizen","barHeight":40,` +
		`"lock":{"locked":false,"requested":false,"secure":false,"passwordPam":true,"authenticating":false},` +
		`"curtain":{"active":false,"awake":false,"passwordPam":true,"authenticating":false},` +
		`"idle":{"enabled":true,"idle":false,"lockAfterSeconds":300}}` + "\n"
)

// result is what Command.Run did.
type result struct {
	Code   int
	Stdout string
	Stderr string
}

func TestRun(t *testing.T) {
	ready := fakeRunner{showLine: {Stdout: running}, queryLine: {Stdout: answer}}
	usage := "usage: kaizen status [--json]"
	for _, tt := range []struct {
		name   string
		args   []string
		runner fakeRunner
		want   result
	}{
		{
			name:   "plain",
			runner: ready,
			want: result{Stdout: `unit                   kaizen-shell.service
active                 active
sub                    running
pid                    4242
dev                    false
ready                  true
error                  null
tree                   /home/user/.config/quickshell/kaizen
barHeight              40
lock.locked            false
lock.requested         false
lock.secure            false
lock.passwordPam       true
lock.authenticating    false
curtain.active         false
curtain.awake          false
curtain.passwordPam    true
curtain.authenticating false
idle.enabled           true
idle.idle              false
idle.lockAfterSeconds  300
`},
		},
		{
			name:   "json",
			args:   []string{"--json"},
			runner: ready,
			want: result{Stdout: `{
  "unit": "kaizen-shell.service",
  "active": "active",
  "sub": "running",
  "pid": 4242,
  "dev": false,
  "ready": true,
  "error": null,
  "tree": "/home/user/.config/quickshell/kaizen",
  "barHeight": 40,
  "lock": {
    "locked": false,
    "requested": false,
    "secure": false,
    "passwordPam": true,
    "authenticating": false
  },
  "curtain": {
    "active": false,
    "awake": false,
    "passwordPam": true,
    "authenticating": false
  },
  "idle": {
    "enabled": true,
    "idle": false,
    "lockAfterSeconds": 300
  }
}
`},
		},
		{
			name:   "stopped",
			runner: fakeRunner{showLine: {Stdout: "ActiveState=inactive\nSubState=dead\nDropInPaths=\nMainPID=0\n"}},
			want: result{Stdout: `unit      kaizen-shell.service
active    inactive
sub       dead
pid       0
dev       false
ready     false
error     null
tree      null
barHeight null
lock      null
curtain   null
idle      null
`},
		},
		{
			name: "not ready",
			args: []string{"--json"},
			runner: fakeRunner{
				showLine:  {Stdout: running},
				queryLine: {Stdout: "Not ready to accept queries yet.\n"},
			},
			want: result{Stdout: `{
  "unit": "kaizen-shell.service",
  "active": "active",
  "sub": "running",
  "pid": 4242,
  "dev": false,
  "ready": false,
  "error": "not ready to accept queries",
  "tree": null,
  "barHeight": null,
  "lock": null,
  "curtain": null,
  "idle": null
}
`},
		},
		{
			name: "help",
			args: []string{"-h"},
			want: result{
				Stdout: usage + "    print the shell's state: its unit, process, tree, readiness, lock, curtain and idle\n",
			},
		},
		{
			name: "unknown argument",
			args: []string{"--plain"},
			want: result{Code: 2, Stderr: "kaizen status: unknown argument: --plain\n" + usage + "\n"},
		},
		{
			name:   "systemctl fails",
			runner: fakeRunner{showLine: {Err: errors.New("exit status 1")}},
			want:   result{Code: 1, Stderr: "kaizen status: systemctl show kaizen-shell.service: exit status 1\n"},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			var got result
			got.Code = Command{Runner: tt.runner}.Run(t.Context(), tt.args, &stdout, &stderr)
			got.Stdout = stdout.String()
			got.Stderr = stderr.String()
			assert.DeepEqual(t, got, tt.want)
		})
	}
}
