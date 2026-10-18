package compositor

import (
	"context"
	"errors"
	"fmt"
	"os/exec"
	"strings"
	"testing"

	"gotest.tools/v3/assert"
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

// result is what a call returned, and the lines it ran.
type result struct {
	Value any
	Err   string
	Calls []string
}

// record returns what a call returned and the lines r ran.
func record(r *fakeRunner, value any, err error) result {
	got := result{Value: value, Calls: r.calls}
	if err != nil {
		got.Err = err.Error()
	}
	return got
}

func TestFromEnv(t *testing.T) {
	// named is a compositor's name and, for an Unset one, its error.
	type named struct {
		Name         string
		Err          string
		NoCompositor bool
	}
	for _, tt := range []struct {
		name string
		env  map[string]string
		want named
	}{
		{name: "niri", env: map[string]string{"KAIZEN_COMPOSITOR": "niri"}, want: named{Name: "niri"}},
		{name: "umbriel", env: map[string]string{"KAIZEN_COMPOSITOR": "umbriel"}, want: named{Name: "umbriel"}},
		{
			name: "unset",
			env:  map[string]string{"NIRI_SOCKET": "/run/user/1000/niri.sock"},
			want: named{Err: "KAIZEN_COMPOSITOR names no compositor: it is unset", NoCompositor: true},
		},
		{
			name: "unknown",
			env:  map[string]string{"KAIZEN_COMPOSITOR": "sway"},
			want: named{Err: `KAIZEN_COMPOSITOR names no compositor: "sway"`, NoCompositor: true},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			c := FromEnv(func(key string) string { return tt.env[key] }, &fakeRunner{})

			got := named{Name: c.Name()}
			if u, ok := c.(Unset); ok {
				got.Err = u.Err.Error()
				got.NoCompositor = errors.Is(u.Err, ErrNoCompositor)
			}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

func TestLayers(t *testing.T) {
	for _, tt := range []struct {
		name       string
		compositor func(r Runner) Compositor
		outputs    map[string]recorded
		want       result
	}{
		{
			name:       "niri",
			compositor: func(r Runner) Compositor { return Niri{Runner: r} },
			outputs: map[string]recorded{"niri msg -j layers": {Stdout: `[
				{"namespace":"kaizen-bar","output":"eDP-1","keyboard_interactivity":"None"},
				{"namespace":"kaizen-panel","output":"DP-1","keyboard_interactivity":"Exclusive"}
			]`}},
			want: result{
				Value: []Layer{
					{Namespace: "kaizen-bar", Output: "eDP-1"},
					{Namespace: "kaizen-panel", Output: "DP-1", Keyboard: true},
				},
				Calls: []string{"niri msg -j layers"},
			},
		},
		{
			name:       "niri fails",
			compositor: func(r Runner) Compositor { return Niri{Runner: r} },
			outputs:    map[string]recorded{"niri msg -j layers": {Err: errors.New("exit status 1")}},
			want: result{
				Value: []Layer(nil),
				Err:   "niri msg layers: exit status 1",
				Calls: []string{"niri msg -j layers"},
			},
		},
		{
			name:       "umbriel, unmapped left out, focus over interactivity",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			outputs: map[string]recorded{"umbriel layers --json": {Stdout: `[
				{"namespace":"kaizen-bar","output":"eDP-1","mapped":true,"keyboard_interactivity":"none","focused":false},
				{"namespace":"kaizen-curtain","output":"eDP-1","mapped":false,"keyboard_interactivity":"exclusive","focused":false},
				{"namespace":"kaizen-osd","output":"eDP-1","mapped":true,"keyboard_interactivity":"exclusive","focused":false},
				{"namespace":"kaizen-panel","output":"DP-1","mapped":true,"keyboard_interactivity":"on_demand","focused":true}
			]`}},
			want: result{
				Value: []Layer{
					{Namespace: "kaizen-bar", Output: "eDP-1"},
					{Namespace: "kaizen-osd", Output: "eDP-1"},
					{Namespace: "kaizen-panel", Output: "DP-1", Keyboard: true},
				},
				Calls: []string{"umbriel layers --json"},
			},
		},
		{
			name:       "umbriel answers otherwise",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			outputs:    map[string]recorded{"umbriel layers --json": {Stdout: "error: no socket"}},
			want: result{
				Value: []Layer(nil),
				Err:   "umbriel layers: jsontext: invalid character 'e' at start of value",
				Calls: []string{"umbriel layers --json"},
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &fakeRunner{outputs: tt.outputs}

			layers, err := tt.compositor(r).Layers(t.Context())

			assert.DeepEqual(t, record(r, layers, err), tt.want)
		})
	}
}

func TestOutputs(t *testing.T) {
	for _, tt := range []struct {
		name       string
		compositor func(r Runner) Compositor
		outputs    map[string]recorded
		want       result
	}{
		{
			name:       "niri",
			compositor: func(r Runner) Compositor { return Niri{Runner: r} },
			outputs: map[string]recorded{
				"niri msg -j outputs": {Stdout: `{
					"eDP-1":{"name":"eDP-1","logical":{"x":0,"y":0,"width":1920,"height":1200}},
					"DP-1":{"name":"DP-1","logical":{"x":1920,"y":0,"width":2560,"height":1440}},
					"HDMI-A-1":{"name":"HDMI-A-1","logical":null}
				}`},
				"niri msg -j focused-output": {Stdout: `{"name":"DP-1"}`},
			},
			want: result{
				Value: []Output{
					{Name: "DP-1", Logical: &Rect{X: 1920, Width: 2560, Height: 1440}, Focused: true},
					{Name: "HDMI-A-1"},
					{Name: "eDP-1", Logical: &Rect{Width: 1920, Height: 1200}},
				},
				Calls: []string{"niri msg -j outputs", "niri msg -j focused-output"},
			},
		},
		{
			name:       "niri, none focused",
			compositor: func(r Runner) Compositor { return Niri{Runner: r} },
			outputs: map[string]recorded{
				"niri msg -j outputs": {Stdout: `{
					"eDP-1":{"name":"eDP-1","logical":{"x":0,"y":0,"width":1920,"height":1200}}
				}`},
				"niri msg -j focused-output": {Stdout: "null"},
			},
			want: result{
				Value: []Output{{Name: "eDP-1", Logical: &Rect{Width: 1920, Height: 1200}}},
				Calls: []string{"niri msg -j outputs", "niri msg -j focused-output"},
			},
		},
		{
			name:       "umbriel",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			outputs: map[string]recorded{"umbriel outputs --json": {Stdout: `[
				{"name":"eDP-1","enabled":true,"powered":false,"focused":false,
				 "position":{"x":0,"y":0},"logical_size":{"width":1920,"height":1200}},
				{"name":"DP-1","enabled":true,"powered":true,"focused":true,
				 "position":{"x":1920,"y":0},"logical_size":{"width":2560,"height":1440}},
				{"name":"HDMI-A-1","enabled":false,"powered":false,"focused":false,
				 "position":{"x":0,"y":0},"logical_size":{"width":0,"height":0}}
			]`}},
			want: result{
				Value: []Output{
					{Name: "eDP-1", Logical: &Rect{Width: 1920, Height: 1200}},
					{Name: "DP-1", Logical: &Rect{X: 1920, Width: 2560, Height: 1440}, Focused: true},
					{Name: "HDMI-A-1"},
				},
				Calls: []string{"umbriel outputs --json"},
			},
		},
		{
			name:       "umbriel fails",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			outputs:    map[string]recorded{"umbriel outputs --json": {Err: errors.New("exit status 1")}},
			want: result{
				Value: []Output(nil),
				Err:   "umbriel outputs: exit status 1",
				Calls: []string{"umbriel outputs --json"},
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &fakeRunner{outputs: tt.outputs}

			outputs, err := tt.compositor(r).Outputs(t.Context())

			assert.DeepEqual(t, record(r, outputs, err), tt.want)
		})
	}
}

func TestFocusedWindow(t *testing.T) {
	for _, tt := range []struct {
		name       string
		compositor func(r Runner) Compositor
		outputs    map[string]recorded
		want       result
	}{
		{
			name:       "niri",
			compositor: func(r Runner) Compositor { return Niri{Runner: r} },
			outputs: map[string]recorded{
				"niri msg -j focused-window": {Stdout: `{"id":7,"app_id":"com.mitchellh.ghostty"}`},
			},
			want: result{
				Value: &Window{ID: "7", AppID: "com.mitchellh.ghostty"},
				Calls: []string{"niri msg -j focused-window"},
			},
		},
		{
			name:       "niri, none",
			compositor: func(r Runner) Compositor { return Niri{Runner: r} },
			outputs:    map[string]recorded{"niri msg -j focused-window": {Stdout: "null"}},
			want:       result{Value: (*Window)(nil), Calls: []string{"niri msg -j focused-window"}},
		},
		{
			name:       "umbriel",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			outputs: map[string]recorded{"umbriel windows --json": {Stdout: `[
				{"id":"a1","app_id":"firefox","active":false,"focused":true},
				{"id":"b2","app_id":"com.mitchellh.ghostty","active":true,"focused":true}
			]`}},
			want: result{
				Value: &Window{ID: "b2", AppID: "com.mitchellh.ghostty"},
				Calls: []string{"umbriel windows --json"},
			},
		},
		{
			name:       "umbriel, none active",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			outputs: map[string]recorded{
				"umbriel windows --json": {Stdout: `[{"id":"a1","app_id":"firefox","active":false,"focused":true}]`},
			},
			want: result{Value: (*Window)(nil), Calls: []string{"umbriel windows --json"}},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &fakeRunner{outputs: tt.outputs}

			w, err := tt.compositor(r).FocusedWindow(t.Context())

			assert.DeepEqual(t, record(r, w, err), tt.want)
		})
	}
}

func TestFocusWindow(t *testing.T) {
	for _, tt := range []struct {
		name       string
		compositor func(r Runner) Compositor
		id         string
		outputs    map[string]recorded
		want       result
	}{
		{
			name:       "niri",
			compositor: func(r Runner) Compositor { return Niri{Runner: r} },
			id:         "7",
			outputs:    map[string]recorded{"niri msg action focus-window --id 7": {}},
			want:       result{Calls: []string{"niri msg action focus-window --id 7"}},
		},
		{
			name:       "umbriel",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			id:         "b2",
			outputs:    map[string]recorded{"umbriel msg window-focus:b2": {}},
			want:       result{Calls: []string{"umbriel msg window-focus:b2"}},
		},
		{
			name:       "umbriel fails",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			id:         "b2",
			outputs:    map[string]recorded{"umbriel msg window-focus:b2": {Err: errors.New("exit status 1")}},
			want: result{
				Err:   "umbriel msg window-focus: exit status 1",
				Calls: []string{"umbriel msg window-focus:b2"},
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &fakeRunner{outputs: tt.outputs}

			err := tt.compositor(r).FocusWindow(t.Context(), tt.id)

			assert.DeepEqual(t, record(r, nil, err), tt.want)
		})
	}
}

func TestValidate(t *testing.T) {
	for _, tt := range []struct {
		name       string
		compositor func(r Runner) Compositor
		outputs    map[string]recorded
		want       result
	}{
		{
			name:       "niri",
			compositor: func(r Runner) Compositor { return Niri{Runner: r} },
			outputs:    map[string]recorded{"env NO_COLOR=1 niri validate": {}},
			want:       result{Calls: []string{"env NO_COLOR=1 niri validate"}},
		},
		{
			name:       "niri invalid, tracing left out",
			compositor: func(r Runner) Compositor { return Niri{Runner: r} },
			outputs: map[string]recorded{"env NO_COLOR=1 niri validate": {Err: &exec.ExitError{
				Stderr: []byte("2026-10-11T11:00:00.000Z  INFO niri: loading\nError: bad config\n"),
			}}},
			want: result{
				Err:   "niri validate:\nError: bad config",
				Calls: []string{"env NO_COLOR=1 niri validate"},
			},
		},
		{
			name:       "umbriel",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			outputs:    map[string]recorded{"umbriel config validate": {Stdout: "config: ok (/home/u/.config/umbriel)\n"}},
			want:       result{Calls: []string{"umbriel config validate"}},
		},
		{
			name:       "umbriel invalid",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			outputs: map[string]recorded{"umbriel config validate": {Err: &exec.ExitError{
				Stderr: []byte("warning: config.toml:3: unknown key 'gaps'\nconfiguration invalid\n"),
			}}},
			want: result{
				Err:   "umbriel config validate:\nwarning: config.toml:3: unknown key 'gaps'\nconfiguration invalid",
				Calls: []string{"umbriel config validate"},
			},
		},
		{
			name:       "umbriel missing",
			compositor: func(r Runner) Compositor { return Umbriel{Runner: r} },
			outputs: map[string]recorded{
				"umbriel config validate": {Err: errors.New(`exec: "umbriel": executable file not found in $PATH`)},
			},
			want: result{
				Err:   "umbriel config validate:\nexec: \"umbriel\": executable file not found in $PATH",
				Calls: []string{"umbriel config validate"},
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &fakeRunner{outputs: tt.outputs}

			err := tt.compositor(r).Validate(t.Context())

			assert.DeepEqual(t, record(r, nil, err), tt.want)
		})
	}
}
