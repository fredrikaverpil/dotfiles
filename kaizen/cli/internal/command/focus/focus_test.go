package focus

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"gotest.tools/v3/assert"

	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/compositor"
)

// recorded is a program's recorded stdout and error.
type recorded struct {
	Stdout string
	Err    error
}

// fakeRunner answers each command line with its recorded output and records
// the lines it ran.
type fakeRunner struct {
	outputs map[string]recorded
	calls   []string
}

func (f *fakeRunner) Run(_ context.Context, name string, args ...string) ([]byte, error) {
	line := strings.Join(append([]string{name}, args...), " ")
	f.calls = append(f.calls, line)
	out, ok := f.outputs[line]
	if !ok {
		return nil, fmt.Errorf("unexpected command: %s", line)
	}
	return []byte(out.Stdout), out.Err
}

// execCall is a call to Command.Execve.
type execCall struct {
	Path string
	Argv []string
	Env  []string
}

// result is what a run returned, wrote, ran and exec'd.
type result struct {
	Code   int
	Stdout string
	Stderr string
	Calls  []string
	Exec   *execCall
}

const (
	niriWindows = `[
		{"id":3,"app_id":"com.mitchellh.ghostty","focus_timestamp":{"secs":100,"nanos":5}},
		{"id":7,"app_id":"com.mitchellh.ghostty","focus_timestamp":{"secs":100,"nanos":9}},
		{"id":9,"app_id":"zen-beta","focus_timestamp":{"secs":200,"nanos":0}}
	]`
	umbrielWindows = `[
		{"id":"a1","app_id":"com.mitchellh.ghostty","active":false},
		{"id":"b2","app_id":"com.mitchellh.ghostty","active":true}
	]`
)

func TestRun(t *testing.T) {
	niri := func(r compositor.Runner) compositor.Compositor { return compositor.Niri{Runner: r} }
	umbriel := func(r compositor.Runner) compositor.Compositor { return compositor.Umbriel{Runner: r} }
	unset := func(compositor.Runner) compositor.Compositor {
		return compositor.Unset{Err: fmt.Errorf("%w: it is unset", compositor.ErrNoCompositor)}
	}
	for _, tt := range []struct {
		name       string
		compositor func(r compositor.Runner) compositor.Compositor
		args       []string
		outputs    map[string]recorded
		lookPath   func(file string) (string, error)
		execErr    error
		want       result
	}{
		{
			name:       "help",
			compositor: niri,
			args:       []string{"-h"},
			want: result{
				Stdout: "usage: kaizen focus APP_ID_REGEX COMMAND [ARGS...]    focus the app, or open it\n",
			},
		},
		{
			name:       "no command",
			compositor: niri,
			args:       []string{"^zen-beta$"},
			want: result{
				Code: 2,
				Stderr: "kaizen focus: pass the app id regex and the command\n" +
					"usage: kaizen focus APP_ID_REGEX COMMAND [ARGS...]\n",
			},
		},
		{
			name:       "invalid regex",
			compositor: niri,
			args:       []string{"(", "zen-beta"},
			want: result{
				Code: 2,
				Stderr: "kaizen focus: error parsing regexp: missing closing ): `(`\n" +
					"usage: kaizen focus APP_ID_REGEX COMMAND [ARGS...]\n",
			},
		},
		{
			name:       "niri, the most recently focused match",
			compositor: niri,
			args:       []string{`^com\.mitchellh\.ghostty$`, "ghostty"},
			outputs: map[string]recorded{
				"niri msg -j windows":                 {Stdout: niriWindows},
				"niri msg action focus-window --id 7": {},
			},
			want: result{Calls: []string{"niri msg -j windows", "niri msg action focus-window --id 7"}},
		},
		{
			name:       "niri, no match opens the app",
			compositor: niri,
			args:       []string{"(?i)^slack$", "slack", "--enable-features=X"},
			outputs:    map[string]recorded{"niri msg -j windows": {Stdout: niriWindows}},
			want: result{
				Calls: []string{"niri msg -j windows"},
				Exec: &execCall{
					Path: "/bin/slack",
					Argv: []string{"slack", "--enable-features=X"},
					Env:  []string{"KAIZEN_COMPOSITOR=niri"},
				},
			},
		},
		{
			name:       "umbriel, the active match",
			compositor: umbriel,
			args:       []string{`^com\.mitchellh\.ghostty$`, "ghostty"},
			outputs: map[string]recorded{
				"umbriel windows --json":      {Stdout: umbrielWindows},
				"umbriel msg window-focus:b2": {},
			},
			want: result{Calls: []string{"umbriel windows --json", "umbriel msg window-focus:b2"}},
		},
		{
			name:       "no compositor",
			compositor: unset,
			args:       []string{"^zen-beta$", "zen-beta"},
			want: result{
				Code:   1,
				Stderr: "kaizen focus: KAIZEN_COMPOSITOR names no compositor: it is unset\n",
			},
		},
		{
			name:       "niri fails",
			compositor: niri,
			args:       []string{"^zen-beta$", "zen-beta"},
			outputs:    map[string]recorded{"niri msg -j windows": {Err: errors.New("exit status 1")}},
			want: result{
				Code:   1,
				Stderr: "kaizen focus: niri msg windows: exit status 1\n",
				Calls:  []string{"niri msg -j windows"},
			},
		},
		{
			name:       "focusing fails",
			compositor: niri,
			args:       []string{"^zen-beta$", "zen-beta"},
			outputs: map[string]recorded{
				"niri msg -j windows":                 {Stdout: niriWindows},
				"niri msg action focus-window --id 9": {Err: errors.New("exit status 1")},
			},
			want: result{
				Code:   1,
				Stderr: "kaizen focus: niri msg action focus-window: exit status 1\n",
				Calls:  []string{"niri msg -j windows", "niri msg action focus-window --id 9"},
			},
		},
		{
			name:       "command not found",
			compositor: niri,
			args:       []string{"(?i)^slack$", "slack"},
			outputs:    map[string]recorded{"niri msg -j windows": {Stdout: niriWindows}},
			lookPath: func(file string) (string, error) {
				return "", fmt.Errorf("exec: %q: executable file not found in $PATH", file)
			},
			want: result{
				Code:   1,
				Stderr: "kaizen focus: exec: \"slack\": executable file not found in $PATH\n",
				Calls:  []string{"niri msg -j windows"},
			},
		},
		{
			name:       "exec fails",
			compositor: niri,
			args:       []string{"(?i)^slack$", "slack"},
			outputs:    map[string]recorded{"niri msg -j windows": {Stdout: niriWindows}},
			execErr:    errors.New("permission denied"),
			want: result{
				Code:   1,
				Stderr: "kaizen focus: slack: permission denied\n",
				Calls:  []string{"niri msg -j windows"},
				Exec:   &execCall{Path: "/bin/slack", Argv: []string{"slack"}, Env: []string{"KAIZEN_COMPOSITOR=niri"}},
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &fakeRunner{outputs: tt.outputs}
			var got result
			c := Command{
				Compositor: tt.compositor(r),
				Environ:    []string{"KAIZEN_COMPOSITOR=niri"},
				Execve: func(path string, argv []string, env []string) error {
					got.Exec = &execCall{Path: path, Argv: argv, Env: env}
					return tt.execErr
				},
				lookPath: tt.lookPath,
			}
			if c.lookPath == nil {
				c.lookPath = func(file string) (string, error) { return "/bin/" + file, nil }
			}
			var stdout, stderr bytes.Buffer

			got.Code = c.Run(t.Context(), tt.args, &stdout, &stderr)

			got.Stdout, got.Stderr, got.Calls = stdout.String(), stderr.String(), r.calls
			assert.DeepEqual(t, got, tt.want)
		})
	}
}
