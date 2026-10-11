package shot

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
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
	outputsLine = "niri msg -j outputs"
	focusedLine = "niri msg -j focused-output"
	layersLine  = "niri msg -j layers"
	showLine    = "systemctl --user show kaizen-shell.service -p MainPID,ActiveState,SubState,DropInPaths"
	queryLine   = "qs ipc --pid 4242 call shell status"
	closeLine   = "qs ipc --pid 4242 call curtain close"
	openLine    = "qs ipc --pid 4242 call curtain open"
	running     = "ActiveState=active\nSubState=running\nDropInPaths=\nMainPID=4242\n"
	dp1         = `"DP-1":{"name":"DP-1","logical":{"x":-3840,"y":0,"width":3840,"height":2160,"scale":1.0}}`
	edp1        = `"eDP-1":{"name":"eDP-1","logical":{"x":0,"y":0,"width":1280,"height":800,"scale":1.0}}`
	edp1Off     = `"eDP-1":{"name":"eDP-1","logical":null}`
	twoOutputs  = "{" + dp1 + "," + edp1 + "}"
	oneOutput   = "{" + edp1 + "}"
	noLayers    = "[]"
	panelOnDP1  = `[{"namespace":"quickshell-backdrop","output":"DP-1","keyboard_interactivity":"None"},` +
		`{"namespace":"kaizen-panel","output":"DP-1","keyboard_interactivity":"Exclusive"}]`
	curtainOnBoth = `[{"namespace":"kaizen-curtain","output":"DP-1","keyboard_interactivity":"None"},` +
		`{"namespace":"kaizen-curtain","output":"eDP-1","keyboard_interactivity":"None"}]`
	focusedDP1 = `{"name":"DP-1"}`
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

// niri answers niri's queries with outputs and layers, none focused.
func niri(outputs, layers string) map[string][]recorded {
	return map[string][]recorded{
		outputsLine: {{Stdout: outputs}},
		focusedLine: {{Stdout: "null"}},
		layersLine:  {{Stdout: layers}},
	}
}

// with adds lines to outputs.
func with(outputs map[string][]recorded, lines map[string][]recorded) map[string][]recorded {
	for line, outs := range lines {
		outputs[line] = outs
	}
	return outputs
}

// result is what Command.Run did, and the lines it ran.
type result struct {
	Code   int
	Stdout string
	Stderr string
	Calls  []string
}

func TestRun(t *testing.T) {
	usage := "usage: kaizen shot [--bar | WxH+X+Y] [--full] [-o FILE] [OUTPUT]"
	cache := t.TempDir()
	now := time.Date(2026, 10, 11, 12, 30, 5, 0, time.UTC)
	shots := cache + "/kaizen-shell/shots/"
	reads := []string{outputsLine, focusedLine, layersLine, showLine, queryLine}
	for _, tt := range []struct {
		name    string
		args    []string
		outputs map[string][]recorded
		want    result
	}{
		{
			name: "help",
			args: []string{"--full", "-h"},
			want: result{Stdout: usage + "    " + Command{}.Summary() + "\n"},
		},
		{
			name: "unknown option",
			args: []string{"--force"},
			want: result{Code: 2, Stderr: "kaizen shot: unknown argument: --force\n" + usage + "\n"},
		},
		{
			name: "two outputs",
			args: []string{"DP-1", "eDP-1"},
			want: result{Code: 2, Stderr: "kaizen shot: unknown argument: eDP-1\n" + usage + "\n"},
		},
		{
			name: "two regions",
			args: []string{"1x1+0+0", "2x2+0+0"},
			want: result{Code: 2, Stderr: "kaizen shot: unknown argument: 2x2+0+0\n" + usage + "\n"},
		},
		{
			name: "-o without a file",
			args: []string{"-o"},
			want: result{Code: 2, Stderr: "kaizen shot: -o needs a file\n" + usage + "\n"},
		},
		{
			name: "bar and region",
			args: []string{"--bar", "10x10+0+0"},
			want: result{Code: 2, Stderr: "kaizen shot: --bar and a region exclude each other\n" + usage + "\n"},
		},
		{
			name:    "no output to pick",
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{focusedLine: {{Stdout: focusedDP1}}}),
			want: result{
				Code:   2,
				Stderr: "kaizen shot: pass the output to capture:\n  DP-1 (focused)\n  eDP-1\n",
				Calls:  []string{outputsLine, focusedLine, layersLine},
			},
		},
		{
			name: "unknown output",
			args: []string{"HDMI-A-1"},
			outputs: with(niri(twoOutputs, panelOnDP1), map[string][]recorded{
				focusedLine: {{Stdout: focusedDP1}},
			}),
			want: result{
				Code:   2,
				Stderr: "kaizen shot: no output named HDMI-A-1; the outputs are:\n  DP-1 (focused open surface)\n  eDP-1\n",
				Calls:  []string{outputsLine, focusedLine, layersLine},
			},
		},
		{
			name: "the only output",
			outputs: with(niri(oneOutput, noLayers), map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {answer(false, false)},
				"grim -g 0,0 1280x800 " + shots + "shot-eDP-1-20261011T123005.png": {{}},
			}),
			want: result{
				Stdout: shots + "shot-eDP-1-20261011T123005.png\n",
				Stderr: "kaizen shot: captured eDP-1 at 1280x800\n",
				Calls:  append(slices.Clone(reads), "grim -g 0,0 1280x800 "+shots+"shot-eDP-1-20261011T123005.png"),
			},
		},
		{
			name: "the output with an open surface, scaled",
			args: []string{"-o", "/tmp/a.png"},
			outputs: with(niri(twoOutputs, panelOnDP1), map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {answer(false, false)},
				"grim -g -3840,0 3840x2160 -s 0.416667 /tmp/a.png": {{}},
			}),
			want: result{
				Stdout: "/tmp/a.png\n",
				Stderr: "kaizen shot: captured DP-1 at 1600x900\n",
				Calls:  append(slices.Clone(reads), "grim -g -3840,0 3840x2160 -s 0.416667 /tmp/a.png"),
			},
		},
		{
			name: "full",
			args: []string{"DP-1", "--full", "-o", "/tmp/a.png"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				showLine:                               {{Stdout: running}},
				queryLine:                              {answer(false, false)},
				"grim -g -3840,0 3840x2160 /tmp/a.png": {{}},
			}),
			want: result{
				Stdout: "/tmp/a.png\n",
				Stderr: "kaizen shot: captured DP-1 at 3840x2160\n",
				Calls:  append(slices.Clone(reads), "grim -g -3840,0 3840x2160 /tmp/a.png"),
			},
		},
		{
			name: "bar",
			args: []string{"--bar", "DP-1"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {answer(false, false)},
				"grim -g -3840,0 3840x40 -s 0.416667 " + shots + "shot-DP-1-bar-20261011T123005.png": {{}},
			}),
			want: result{
				Stdout: shots + "shot-DP-1-bar-20261011T123005.png\n",
				Stderr: "kaizen shot: captured DP-1-bar at 1600x16\n",
				Calls: append(
					slices.Clone(reads),
					"grim -g -3840,0 3840x40 -s 0.416667 "+shots+"shot-DP-1-bar-20261011T123005.png",
				),
			},
		},
		{
			name: "bar of a shell that is not ready",
			args: []string{"--bar", "eDP-1"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {{Stdout: "Not ready to accept queries yet.\n"}},
			}),
			want: result{
				Code:   1,
				Stderr: "kaizen shot: the shell did not report the bar's height: not ready to accept queries\n",
				Calls:  reads,
			},
		},
		{
			name: "region",
			args: []string{"200x100+1000+50", "eDP-1", "-o", "/tmp/a.png"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				showLine:                             {{Stdout: running}},
				queryLine:                            {answer(false, false)},
				"grim -g 1000,50 200x100 /tmp/a.png": {{}},
			}),
			want: result{
				Stdout: "/tmp/a.png\n",
				Stderr: "kaizen shot: captured eDP-1-region at 200x100\n",
				Calls:  append(slices.Clone(reads), "grim -g 1000,50 200x100 /tmp/a.png"),
			},
		},
		{
			name: "region outside the output",
			args: []string{"300x100+1000+50", "eDP-1"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {answer(false, false)},
			}),
			want: result{
				Code:   2,
				Stderr: "kaizen shot: 300x100+1000+50 is outside eDP-1, which is 1280x800\n",
				Calls:  reads,
			},
		},
		{
			name: "locked",
			args: []string{"eDP-1"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {answer(true, false)},
			}),
			want: result{Code: 1, Stderr: "kaizen shot: the session is locked\n", Calls: reads},
		},
		{
			name: "output off",
			args: []string{"eDP-1"},
			outputs: with(niri("{"+dp1+","+edp1Off+"}", noLayers), map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {answer(false, false)},
			}),
			want: result{Code: 1, Stderr: "kaizen shot: eDP-1 is off\n", Calls: reads},
		},
		{
			name: "curtain up",
			args: []string{"eDP-1", "-o", "/tmp/a.png"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				layersLine:                        {{Stdout: noLayers}, {Stdout: curtainOnBoth}, {Stdout: noLayers}},
				showLine:                          {{Stdout: running}},
				queryLine:                         {answer(false, true)},
				closeLine:                         {{Stdout: "hidden\n"}},
				openLine:                          {{Stdout: "shown\n"}},
				"grim -g 0,0 1280x800 /tmp/a.png": {{}},
			}),
			want: result{
				Stdout: "/tmp/a.png\n",
				Stderr: "kaizen shot: captured eDP-1 at 1280x800\n",
				Calls: append(
					slices.Clone(reads),
					closeLine, layersLine, layersLine, "grim -g 0,0 1280x800 /tmp/a.png", openLine,
				),
			},
		},
		{
			name: "curtain up, capture fails",
			args: []string{"eDP-1", "-o", "/tmp/a.png"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				showLine:                          {{Stdout: running}},
				queryLine:                         {answer(false, true)},
				closeLine:                         {{Stdout: "hidden\n"}},
				openLine:                          {{Stdout: "shown\n"}},
				"grim -g 0,0 1280x800 /tmp/a.png": {{Err: errors.New("exit status 1")}},
			}),
			want: result{
				Code:   1,
				Stderr: "kaizen shot: grim: exit status 1\n",
				Calls: append(
					slices.Clone(reads),
					closeLine, layersLine, "grim -g 0,0 1280x800 /tmp/a.png", openLine,
				),
			},
		},
		{
			name: "curtain up, does not come back",
			args: []string{"eDP-1", "-o", "/tmp/a.png"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				showLine:                          {{Stdout: running}},
				queryLine:                         {answer(false, true)},
				closeLine:                         {{Stdout: "hidden\n"}},
				openLine:                          {{Stdout: "missing-pam\n"}},
				"grim -g 0,0 1280x800 /tmp/a.png": {{}},
			}),
			want: result{
				Code:   1,
				Stdout: "/tmp/a.png\n",
				Stderr: "kaizen shot: captured eDP-1 at 1280x800\n" +
					"kaizen shot: the curtain is down: curtain open: missing-pam\n",
				Calls: append(
					slices.Clone(reads),
					closeLine, layersLine, "grim -g 0,0 1280x800 /tmp/a.png", openLine,
				),
			},
		},
		{
			name: "curtain up, its surface stays",
			args: []string{"eDP-1", "-o", "/tmp/a.png"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				layersLine: {{Stdout: noLayers}, {Stdout: curtainOnBoth}},
				showLine:   {{Stdout: running}},
				queryLine:  {answer(false, true)},
				closeLine:  {{Stdout: "hidden\n"}},
				openLine:   {{Stdout: "shown\n"}},
			}),
			want: result{
				Code:   1,
				Stderr: "kaizen shot: the curtain's surface did not leave the outputs\n",
				Calls: append(
					append(append(slices.Clone(reads), closeLine), slices.Repeat([]string{layersLine}, 25)...),
					openLine,
				),
			},
		},
		{
			name: "curtain does not lift",
			args: []string{"eDP-1", "-o", "/tmp/a.png"},
			outputs: with(niri(twoOutputs, noLayers), map[string][]recorded{
				showLine:  {{Stdout: running}},
				queryLine: {answer(false, true)},
				closeLine: {{Stdout: "Function not found.\n"}},
			}),
			want: result{
				Code:   1,
				Stderr: "kaizen shot: the curtain is up: curtain close: Function not found.\n",
				Calls:  append(slices.Clone(reads), closeLine),
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &seqRunner{outputs: tt.outputs}
			c := Command{Runner: r, CacheDir: cache, now: func() time.Time { return now }, wait: noWait}
			var stdout, stderr bytes.Buffer
			code := c.Run(t.Context(), tt.args, &stdout, &stderr)
			got := result{Code: code, Stdout: stdout.String(), Stderr: stderr.String(), Calls: r.calls}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

func TestCacheFile(t *testing.T) {
	now := time.Date(2026, 10, 11, 12, 30, 5, 0, time.UTC)
	cache := t.TempDir()
	dir := filepath.Join(cache, "kaizen-shell", "shots")
	assert.NilError(t, os.MkdirAll(dir, 0o755))
	for name, age := range map[string]time.Duration{
		"shot-DP-1-old.png":   25 * time.Hour,
		"shot-DP-1-young.png": 23 * time.Hour,
		"other-old.png":       25 * time.Hour,
	} {
		path := filepath.Join(dir, name)
		assert.NilError(t, os.WriteFile(path, nil, 0o644))
		assert.NilError(t, os.Chtimes(path, now.Add(-age), now.Add(-age)))
	}
	c := Command{CacheDir: cache, now: func() time.Time { return now }}

	file, err := c.cacheFile("DP-1-bar")

	assert.NilError(t, err)
	entries, err := os.ReadDir(dir)
	assert.NilError(t, err)
	var names []string
	for _, entry := range entries {
		names = append(names, entry.Name())
	}
	type result struct {
		File  string
		Names []string
	}
	assert.DeepEqual(
		t,
		result{File: file, Names: names},
		result{
			File:  filepath.Join(dir, "shot-DP-1-bar-20261011T123005.png"),
			Names: []string{"other-old.png", "shot-DP-1-young.png"},
		},
	)
}
