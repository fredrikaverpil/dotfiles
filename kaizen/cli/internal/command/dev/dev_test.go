package dev

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gotest.tools/v3/assert"
)

// output is a program's recorded stdout and error.
type output struct {
	Stdout string
	Err    error
}

// seqRunner answers each command line with its recorded outputs in turn,
// repeating the last.
type seqRunner map[string][]output

func (s seqRunner) Run(_ context.Context, name string, args ...string) ([]byte, error) {
	line := strings.Join(append([]string{name}, args...), " ")
	outs := s[line]
	if len(outs) == 0 {
		return nil, fmt.Errorf("unexpected command: %s", line)
	}
	if len(outs) > 1 {
		s[line] = outs[1:]
	}
	return []byte(outs[0].Stdout), outs[0].Err
}

const (
	showLine     = "systemctl --user show kaizen-shell.service -p MainPID,ActiveState,SubState,DropInPaths"
	queryLine    = "qs ipc --pid 4242 call shell status"
	cursorLine   = "journalctl --user --lines 0 --show-cursor --quiet --no-pager"
	journalLine  = "journalctl --user --unit kaizen-shell.service --after-cursor s=1 --output json --no-pager"
	daemonReload = "systemctl --user daemon-reload"
	resetFailed  = "systemctl --user reset-failed kaizen-shell.service"
	restartLine  = "systemctl --user restart kaizen-shell.service"
	worktreeLine = "git -C /home/user/.dotfiles worktree list --porcelain"
	running      = "ActiveState=active\nSubState=running\nDropInPaths=\nMainPID=4242\n"
	stopped      = "ActiveState=inactive\nSubState=dead\nDropInPaths=\nMainPID=0\n"
	mainTree     = "/home/user/.config/quickshell/kaizen"
	loaded       = `{"MESSAGE":"  INFO: Configuration Loaded","PRIORITY":"6"}` + "\n"
	warning      = `{"MESSAGE":"  WARN scene: Binding loop","PRIORITY":"6"}` + "\n"
	loadError    = `{"MESSAGE":" ERROR: Failed to load configuration","PRIORITY":"6"}` + "\n"
)

// answer is the shell's answer to `shell status` while it runs tree.
func answer(tree string, locked bool) output {
	return output{Stdout: fmt.Sprintf(
		`{"tree":%q,"barHeight":40,"lock":{"locked":%t,"requested":false,"secure":false,"passwordPam":true,`+
			`"authenticating":false}}`+"\n",
		tree,
		locked,
	)}
}

// restarted is the runner of a restart that logs journal, with the shell
// answering before until the restart, then after.
func restarted(before, after output, journal string) seqRunner {
	return seqRunner{
		showLine:     {{Stdout: running}},
		queryLine:    {before, after},
		cursorLine:   {{Stdout: "-- cursor: s=1\n"}},
		daemonReload: {{}},
		resetFailed:  {{}},
		restartLine:  {{}},
		journalLine:  {{Stdout: journal}},
	}
}

// result is what Command.Run did, and the drop-in it left.
type result struct {
	Code   int
	Stdout string
	Stderr string
	DropIn string
}

func TestRun(t *testing.T) {
	usage := "usage: kaizen dev [PATH | NAME | off]"
	checkouts, err := filepath.EvalSymlinks(t.TempDir())
	assert.NilError(t, err)
	worktree := filepath.Join(checkouts, "feature")
	dir := filepath.Join(worktree, tree)
	assert.NilError(t, os.MkdirAll(dir, 0o755))
	assert.NilError(t, os.WriteFile(filepath.Join(dir, "shell.qml"), nil, 0o644))
	empty := filepath.Join(checkouts, "empty")
	assert.NilError(t, os.Mkdir(empty, 0o755))
	worktrees := "worktree /home/user/.dotfiles\nHEAD 0\nbranch refs/heads/main\n\n" +
		"worktree " + worktree + "\nHEAD 0\nbranch refs/heads/feature\n"
	dropIn := fmt.Sprintf("[Service]\nExecStart=\nExecStart=/usr/bin/env quickshell -p \"%s\"\n", dir)
	for _, tt := range []struct {
		name         string
		args         []string
		runner       seqRunner
		dropIn       string
		noRuntimeDir bool
		want         result
	}{
		{
			name: "help",
			args: []string{"-h"},
			want: result{Stdout: usage + "    " + Command{}.Summary() + "\n"},
		},
		{
			name: "unknown option",
			args: []string{"--force"},
			want: result{Code: 2, Stderr: "kaizen dev: unknown argument: --force\n" + usage + "\n"},
		},
		{
			name: "two arguments",
			args: []string{"feature", "off"},
			want: result{Code: 2, Stderr: "kaizen dev: unknown argument: off\n" + usage + "\n"},
		},
		{
			name:   "prints the tree",
			runner: seqRunner{showLine: {{Stdout: running}}, queryLine: {answer(mainTree, false)}},
			want:   result{Stdout: mainTree + "\n"},
		},
		{
			name:   "prints the tree of a stopped shell",
			runner: seqRunner{showLine: {{Stdout: stopped}}},
			want:   result{Code: 1, Stderr: "kaizen dev: kaizen-shell.service is not running\n"},
		},
		{
			name:   "prints the tree of a shell that is not ready",
			runner: seqRunner{showLine: {{Stdout: running}}, queryLine: {{Stdout: "Not ready to accept queries yet.\n"}}},
			want: result{
				Code:   1,
				Stderr: "kaizen dev: the tree kaizen-shell.service runs is unknown: not ready to accept queries\n",
			},
		},
		{
			name:   "path",
			args:   []string{worktree},
			runner: restarted(answer(mainTree, false), answer(dir, false), loaded+warning),
			want:   result{Stdout: dir + "\n", Stderr: "WARN scene: Binding loop\n", DropIn: dropIn},
		},
		{
			name: "name",
			args: []string{"feature"},
			runner: func() seqRunner {
				r := restarted(answer(mainTree, false), answer(dir, false), loaded)
				r[worktreeLine] = []output{{Stdout: worktrees}}
				return r
			}(),
			want: result{Stdout: dir + "\n", DropIn: dropIn},
		},
		{
			name:   "unknown name",
			args:   []string{"other"},
			runner: seqRunner{worktreeLine: {{Stdout: worktrees}}},
			want:   result{Code: 1, Stderr: "kaizen dev: no single worktree of ~/.dotfiles named other\n"},
		},
		{
			name: "no shell tree",
			args: []string{empty},
			want: result{
				Code:   1,
				Stderr: "kaizen dev: " + filepath.Join(empty, tree) + "/shell.qml does not exist\n",
			},
		},
		{
			name:   "locked",
			args:   []string{worktree},
			runner: seqRunner{showLine: {{Stdout: running}}, queryLine: {answer(mainTree, true)}},
			want:   result{Code: 1, Stderr: "kaizen dev: the session is locked\n"},
		},
		{
			name:   "fails to load",
			args:   []string{worktree},
			runner: restarted(answer(mainTree, false), answer(mainTree, false), loadError),
			want: result{
				Code: 1,
				Stderr: "ERROR: Failed to load configuration\n" +
					"kaizen dev: the shell failed to load its config; kaizen dev off runs main's\n",
				DropIn: dropIn,
			},
		},
		{
			name:   "runs another tree",
			args:   []string{worktree},
			runner: restarted(answer(mainTree, false), answer(mainTree, false), loaded),
			want: result{
				Code:   1,
				Stderr: "kaizen dev: kaizen-shell.service does not run " + dir + "\n",
				DropIn: dropIn,
			},
		},
		{
			name:         "no runtime dir",
			args:         []string{worktree},
			noRuntimeDir: true,
			want:         result{Code: 1, Stderr: "kaizen dev: XDG_RUNTIME_DIR is not set\n"},
		},
		{
			name:   "off",
			args:   []string{"off"},
			runner: restarted(answer(dir, false), answer(mainTree, false), loaded),
			dropIn: dropIn,
			want:   result{Stdout: mainTree + "\n"},
		},
		{
			name:   "off while locked",
			args:   []string{"off"},
			runner: seqRunner{showLine: {{Stdout: running}}, queryLine: {answer(dir, true)}},
			dropIn: dropIn,
			want:   result{Code: 1, Stderr: "kaizen dev: the session is locked\n", DropIn: dropIn},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			runtimeDir := t.TempDir()
			path := filepath.Join(runtimeDir, "systemd", "user", "kaizen-shell.service.d", "dev.conf")
			if tt.dropIn != "" {
				assert.NilError(t, os.MkdirAll(filepath.Dir(path), 0o755))
				assert.NilError(t, os.WriteFile(path, []byte(tt.dropIn), 0o644))
			}
			c := Command{Runner: tt.runner, Main: "/home/user/.dotfiles", RuntimeDir: runtimeDir}
			if tt.noRuntimeDir {
				c.RuntimeDir = ""
			}
			var stdout, stderr bytes.Buffer
			code := c.Run(t.Context(), tt.args, &stdout, &stderr)
			got := result{Code: code, Stdout: stdout.String(), Stderr: stderr.String()}
			content, err := os.ReadFile(path)
			if !errors.Is(err, os.ErrNotExist) {
				assert.NilError(t, err)
				got.DropIn = string(content)
			}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}
