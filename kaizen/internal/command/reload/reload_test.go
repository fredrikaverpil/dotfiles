package reload

import (
	"bytes"
	"context"
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
	showLine    = "systemctl --user show kaizen-shell.service -p MainPID,ActiveState,SubState,DropInPaths"
	queryLine   = "qs ipc --pid 4242 call shell status"
	cursorLine  = "journalctl --user --lines 0 --show-cursor --quiet --no-pager"
	journalLine = "journalctl --user --unit kaizen-shell.service --after-cursor s=1 --output json --no-pager"
	reloadLine  = "qs ipc --pid 4242 call shell reload"
	running     = "ActiveState=active\nSubState=running\nDropInPaths=\nMainPID=4242\n"
	unlocked    = `{"tree":"/t","barHeight":40,` +
		`"lock":{"locked":false,"requested":false,"secure":false,"passwordPam":true,"authenticating":false}}` + "\n"
	locked = `{"tree":"/t","barHeight":40,` +
		`"lock":{"locked":true,"requested":true,"secure":true,"passwordPam":true,"authenticating":false}}` + "\n"
)

// result is what Command.Run did.
type result struct {
	Code   int
	Stdout string
	Stderr string
}

func TestRun(t *testing.T) {
	usage := "usage: kaizen reload [--restart]"
	for _, tt := range []struct {
		name   string
		args   []string
		runner fakeRunner
		want   result
	}{
		{
			name: "help",
			args: []string{"-h"},
			want: result{Stdout: usage + "    " + Command{}.Summary() + "\n"},
		},
		{
			name: "unknown argument",
			args: []string{"--hard"},
			want: result{Code: 2, Stderr: "kaizen reload: unknown argument: --hard\n" + usage + "\n"},
		},
		{
			name:   "locked",
			runner: fakeRunner{showLine: {Stdout: running}, queryLine: {Stdout: locked}},
			want:   result{Code: 1, Stderr: "kaizen reload: the session is locked\n"},
		},
		{
			name: "reloaded with a warning",
			runner: fakeRunner{
				showLine:   {Stdout: running},
				queryLine:  {Stdout: unlocked},
				cursorLine: {Stdout: "-- cursor: s=1\n"},
				reloadLine: {},
				journalLine: {Stdout: `{"MESSAGE":"  INFO: Configuration Loaded","PRIORITY":"6"}` + "\n" +
					`{"MESSAGE":"  WARN scene: Binding loop","PRIORITY":"6"}` + "\n"},
			},
			want: result{Stdout: "WARN scene: Binding loop\n"},
		},
		{
			name: "fails to load",
			runner: fakeRunner{
				showLine:   {Stdout: running},
				queryLine:  {Stdout: unlocked},
				cursorLine: {Stdout: "-- cursor: s=1\n"},
				reloadLine: {},
				journalLine: {Stdout: `{"MESSAGE":" ERROR: Failed to load configuration","PRIORITY":"6"}` + "\n" +
					`{"MESSAGE":" ERROR:   caused by @shell.qml[552:1]: Syntax error","PRIORITY":"6"}` + "\n"},
			},
			want: result{
				Code:   1,
				Stdout: "ERROR: Failed to load configuration\nERROR:   caused by @shell.qml[552:1]: Syntax error\n",
				Stderr: "kaizen reload: the shell failed to load its config\n",
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			code := Command{Runner: tt.runner}.Run(t.Context(), tt.args, &stdout, &stderr)
			assert.DeepEqual(t, result{Code: code, Stdout: stdout.String(), Stderr: stderr.String()}, tt.want)
		})
	}
}
