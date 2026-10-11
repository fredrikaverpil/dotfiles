package keys

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"slices"
	"strings"
	"testing"
	"time"

	"gotest.tools/v3/assert"
)

// recorded is a program's recorded stdout and error.
type recorded struct {
	Stdout string
	Err    error
}

// seqRunner answers each command line with its recorded outputs in turn,
// repeating the last, and records the lines it ran.
type seqRunner struct {
	outputs map[string][]recorded
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
	showLine    = "systemctl --user show kaizen-shell.service -p MainPID,ActiveState,SubState,DropInPaths"
	queryLine   = "qs ipc --pid 4242 call shell status"
	closeLine   = "qs ipc --pid 4242 call curtain close"
	openLine    = "qs ipc --pid 4242 call curtain open"
	layersLine  = "niri msg -j layers"
	focusedLine = "niri msg -j focused-window"
	focus3Line  = "niri msg action focus-window --id 3"
	focus7Line  = "niri msg action focus-window --id 7"
	ctrlKLine   = "wtype -M ctrl -k k -m ctrl"
	returnLine  = "wtype -k Return"
	running     = "ActiveState=active\nSubState=running\nDropInPaths=\nMainPID=4242\n"
	stopped     = "ActiveState=inactive\nSubState=dead\nDropInPaths=\nMainPID=0\n"
	noLayers    = `[{"namespace":"quickshell","output":"DP-1","keyboard_interactivity":"None"}]`
	panel       = `[{"namespace":"quickshell","output":"DP-1","keyboard_interactivity":"None"},` +
		`{"namespace":"kaizen-panel","output":"DP-1","keyboard_interactivity":"Exclusive"}]`
	panelAndMenu = `[{"namespace":"kaizen-panel","output":"DP-1","keyboard_interactivity":"Exclusive"},` +
		`{"namespace":"kaizen-menu","output":"DP-1","keyboard_interactivity":"Exclusive"}]`
	curtain = `[{"namespace":"kaizen-curtain","output":"DP-1","keyboard_interactivity":"Exclusive"},` +
		`{"namespace":"kaizen-panel","output":"DP-1","keyboard_interactivity":"Exclusive"}]`
	terminal = `{"id":3,"app_id":"com.mitchellh.ghostty"}`
	app      = `{"id":7,"app_id":"kaizen-investigator"}`
)

// answer is the shell's answer to `shell status`.
func answer(locked, curtain bool) recorded {
	return recorded{Stdout: fmt.Sprintf(
		`{"tree":"/t","barHeight":40,`+
			`"lock":{"locked":%t,"requested":false,"secure":false,"passwordPam":true,"authenticating":false},`+
			`"curtain":{"active":%t,"awake":false,"passwordPam":true,"authenticating":false}}`+"\n",
		locked,
		curtain,
	)}
}

// result is what Command.Run did, and the lines it ran.
type result struct {
	Code   int
	Stdout string
	Stderr string
	Calls  []string
}

func TestRun(t *testing.T) {
	usage := "usage: kaizen keys (--layer NAMESPACE | --window ID) KEY..."
	read := []string{showLine, queryLine}
	// The reads before each key to a layer, and to a window.
	layerCheck := []string{showLine, queryLine, layersLine}
	windowCheck := []string{showLine, queryLine, layersLine, focusedLine}
	for _, tt := range []struct {
		name    string
		args    []string
		outputs map[string][]recorded
		want    result
	}{
		{
			name: "help",
			args: []string{"--layer", "kaizen-panel", "-h"},
			want: result{Stdout: usage + "    " + Command{}.Summary() + "\n"},
		},
		{
			name: "no target",
			args: []string{"Return"},
			want: result{Code: 2, Stderr: "kaizen keys: pass --layer or --window\n" + usage + "\n"},
		},
		{
			name: "no keys",
			args: []string{"--window", "7"},
			want: result{Code: 2, Stderr: "kaizen keys: pass the keys to press\n" + usage + "\n"},
		},
		{
			name: "two targets",
			args: []string{"--window", "7", "--layer", "kaizen-panel", "Return"},
			want: result{Code: 2, Stderr: "kaizen keys: --layer and --window exclude each other\n" + usage + "\n"},
		},
		{
			name: "--layer without a value",
			args: []string{"--layer"},
			want: result{Code: 2, Stderr: "kaizen keys: --layer needs a value\n" + usage + "\n"},
		},
		{
			name: "a password layer",
			args: []string{"--layer", "kaizen-polkit", "Return"},
			want: result{
				Code:   2,
				Stderr: "kaizen keys: kaizen-polkit takes a password: kaizen keys never presses keys in it\n" + usage + "\n",
			},
		},
		{
			name: "the curtain",
			args: []string{"--layer", "kaizen-curtain", "Return"},
			want: result{
				Code:   2,
				Stderr: "kaizen keys: kaizen-curtain takes a password: kaizen keys never presses keys in it\n" + usage + "\n",
			},
		},
		{
			name: "not a window id",
			args: []string{"--window", "x", "Return"},
			want: result{Code: 2, Stderr: "kaizen keys: x is not a window id\n" + usage + "\n"},
		},
		{
			name: "unknown option",
			args: []string{"--window", "7", "--force"},
			want: result{Code: 2, Stderr: "kaizen keys: unknown argument: --force\n" + usage + "\n"},
		},
		{
			name: "unknown modifier",
			args: []string{"--window", "7", "hyper+k"},
			want: result{
				Code: 2,
				Stderr: "kaizen keys: hyper in hyper+k is not a modifier: shift capslock ctrl logo win alt altgr\n" +
					usage + "\n",
			},
		},
		{
			name: "an empty part",
			args: []string{"--window", "7", "ctrl+"},
			want: result{Code: 2, Stderr: "kaizen keys: ctrl+ is not a key; + is plus\n" + usage + "\n"},
		},
		{
			name: "locked",
			args: []string{"--layer", "kaizen-panel", "Return"},
			outputs: map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {answer(true, false)},
			},
			want: result{Code: 1, Stderr: "kaizen keys: the session is locked\n", Calls: read},
		},
		{
			name:    "the shell is down",
			args:    []string{"--layer", "kaizen-panel", "Return"},
			outputs: map[string][]recorded{showLine: {{Stdout: stopped}}},
			want: result{
				Code:   1,
				Stderr: "kaizen keys: the lock state is unknown: kaizen-shell.service is not running\n",
				Calls:  []string{showLine},
			},
		},
		{
			name: "the shell is not ready",
			args: []string{"--layer", "kaizen-panel", "Return"},
			outputs: map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {{Stdout: "Not ready to accept queries yet.\n"}},
			},
			want: result{
				Code:   1,
				Stderr: "kaizen keys: the lock state is unknown: not ready to accept queries\n",
				Calls:  read,
			},
		},
		{
			name: "layer",
			args: []string{"--layer", "kaizen-panel", "ctrl+k", "Return"},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: running}},
				queryLine:  {answer(false, false)},
				layersLine: {{Stdout: panel}},
				ctrlKLine:  {{}},
				returnLine: {{}},
			},
			want: result{Calls: slices.Concat(read, layerCheck, []string{ctrlKLine}, layerCheck, []string{returnLine})},
		},
		{
			name: "layer closes after the first key",
			args: []string{"--layer", "kaizen-panel", "ctrl+k", "Return"},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: running}},
				queryLine:  {answer(false, false)},
				layersLine: {{Stdout: panel}, {Stdout: noLayers}},
				ctrlKLine:  {{}},
			},
			want: result{
				Code:   1,
				Stderr: "kaizen keys: sent 1 of 2 keys; layer kaizen-panel does not hold the keyboard: no layer holds it\n",
				Calls:  slices.Concat(read, layerCheck, []string{ctrlKLine}, layerCheck),
			},
		},
		{
			name: "layer shares the keyboard",
			args: []string{"--layer", "kaizen-panel", "Return"},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: running}},
				queryLine:  {answer(false, false)},
				layersLine: {{Stdout: panelAndMenu}},
			},
			want: result{
				Code: 1,
				Stderr: "kaizen keys: layer kaizen-panel does not hold the keyboard: " +
					"layers kaizen-menu, kaizen-panel hold it\n",
				Calls: slices.Concat(read, layerCheck),
			},
		},
		{
			name: "layer, curtain up",
			args: []string{"--layer", "kaizen-panel", "Return"},
			outputs: map[string][]recorded{
				showLine:   {{Stdout: running}},
				queryLine:  {answer(false, true), answer(false, false)},
				closeLine:  {{Stdout: "hidden\n"}},
				layersLine: {{Stdout: curtain}, {Stdout: panel}},
				returnLine: {{}},
				openLine:   {{Stdout: "shown\n"}},
			},
			want: result{
				Calls: slices.Concat(read, []string{closeLine, layersLine, layersLine}, layerCheck, []string{returnLine, openLine}),
			},
		},
		{
			name: "layer, wtype fails",
			args: []string{"--layer", "kaizen-panel", "Return", "Nope"},
			outputs: map[string][]recorded{
				showLine:        {{Stdout: running}},
				queryLine:       {answer(false, false)},
				layersLine:      {{Stdout: panel}},
				returnLine:      {{}},
				"wtype -k Nope": {{Err: errors.New("exit status 1")}},
			},
			want: result{
				Code:   1,
				Stderr: "kaizen keys: sent 1 of 2 keys; wtype: exit status 1\n",
				Calls:  slices.Concat(read, layerCheck, []string{returnLine}, layerCheck, []string{"wtype -k Nope"}),
			},
		},
		{
			name: "window",
			args: []string{"--window", "7", "ctrl+k", "Return"},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: running}},
				queryLine:   {answer(false, false)},
				focusedLine: {{Stdout: terminal}, {Stdout: app}},
				focus7Line:  {{}},
				layersLine:  {{Stdout: noLayers}},
				ctrlKLine:   {{}},
				returnLine:  {{}},
				focus3Line:  {{}},
			},
			want: result{
				Calls: slices.Concat(
					read,
					[]string{focusedLine, focus7Line},
					windowCheck,
					[]string{ctrlKLine},
					windowCheck,
					[]string{returnLine, focus3Line},
				),
			},
		},
		{
			name: "window already focused",
			args: []string{"--window", "7", "Return"},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: running}},
				queryLine:   {answer(false, false)},
				focusedLine: {{Stdout: app}},
				focus7Line:  {{}},
				layersLine:  {{Stdout: noLayers}},
				returnLine:  {{}},
			},
			want: result{Calls: slices.Concat(read, []string{focusedLine, focus7Line}, windowCheck, []string{returnLine})},
		},
		{
			name: "window, none focused before",
			args: []string{"--window", "7", "Return"},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: running}},
				queryLine:   {answer(false, false)},
				focusedLine: {{Stdout: "null"}, {Stdout: app}},
				focus7Line:  {{}},
				layersLine:  {{Stdout: noLayers}},
				returnLine:  {{}},
			},
			want: result{Calls: slices.Concat(read, []string{focusedLine, focus7Line}, windowCheck, []string{returnLine})},
		},
		{
			name: "window under a layer",
			args: []string{"--window", "7", "Return"},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: running}},
				queryLine:   {answer(false, false)},
				focusedLine: {{Stdout: terminal}},
				focus7Line:  {{}},
				layersLine:  {{Stdout: panel}},
				focus3Line:  {{}},
			},
			want: result{
				Code:   1,
				Stderr: "kaizen keys: window 7 does not hold the keyboard: layer kaizen-panel holds it\n",
				Calls:  slices.Concat(read, []string{focusedLine, focus7Line}, layerCheck, []string{focus3Line}),
			},
		},
		{
			name: "window does not take focus",
			args: []string{"--window", "7", "Return"},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: running}},
				queryLine:   {answer(false, false)},
				focusedLine: {{Stdout: terminal}},
				focus7Line:  {{}},
				layersLine:  {{Stdout: noLayers}},
				focus3Line:  {{}},
			},
			want: result{
				Code:   1,
				Stderr: "kaizen keys: window 7 does not hold the keyboard: window 3 (com.mitchellh.ghostty) has focus\n",
				Calls:  slices.Concat(read, []string{focusedLine, focus7Line}, windowCheck, []string{focus3Line}),
			},
		},
		{
			name: "window, locked after the first key",
			args: []string{"--window", "7", "ctrl+k", "Return"},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: running}},
				queryLine:   {answer(false, false), answer(false, false), answer(true, false)},
				focusedLine: {{Stdout: terminal}, {Stdout: app}},
				focus7Line:  {{}},
				layersLine:  {{Stdout: noLayers}},
				ctrlKLine:   {{}},
				focus3Line:  {{}},
			},
			want: result{
				Code:   1,
				Stderr: "kaizen keys: sent 1 of 2 keys; the session is locked\n",
				Calls: slices.Concat(
					read,
					[]string{focusedLine, focus7Line},
					windowCheck,
					[]string{ctrlKLine},
					read,
					[]string{focus3Line},
				),
			},
		},
		{
			name: "window, focus not given back",
			args: []string{"--window", "7", "Return"},
			outputs: map[string][]recorded{
				showLine:    {{Stdout: running}},
				queryLine:   {answer(false, false)},
				focusedLine: {{Stdout: terminal}, {Stdout: app}},
				focus7Line:  {{}},
				layersLine:  {{Stdout: noLayers}},
				returnLine:  {{}},
				focus3Line:  {{Err: errors.New("exit status 1")}},
			},
			want: result{
				Code:   1,
				Stderr: "kaizen keys: niri msg action focus-window: exit status 1\n",
				Calls: slices.Concat(
					read,
					[]string{focusedLine, focus7Line},
					windowCheck,
					[]string{returnLine, focus3Line},
				),
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &seqRunner{outputs: tt.outputs}
			c := Command{Runner: r, wait: noWait}
			var stdout, stderr bytes.Buffer

			code := c.Run(t.Context(), tt.args, &stdout, &stderr)

			got := result{Code: code, Stdout: stdout.String(), Stderr: stderr.String(), Calls: r.calls}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}
