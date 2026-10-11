package state

import (
	"context"
	"errors"
	"slices"
	"testing"

	"gotest.tools/v3/assert"
)

func TestCurtain(t *testing.T) {
	type result struct {
		Err   string
		Calls []string
	}
	for _, tt := range []struct {
		name    string
		move    func(ctx context.Context, r Runner, pid int) error
		outputs map[string][]output
		want    result
	}{
		{
			name:    "close",
			move:    CloseCurtain,
			outputs: map[string][]output{"qs ipc --pid 4242 call curtain close": {{Stdout: "hidden\n"}}},
			want:    result{Calls: []string{"qs ipc --pid 4242 call curtain close"}},
		},
		{
			name:    "close answers otherwise",
			move:    CloseCurtain,
			outputs: map[string][]output{"qs ipc --pid 4242 call curtain close": {{Stdout: "Target not found.\n"}}},
			want: result{
				Err:   "the curtain is up: curtain close: Target not found.",
				Calls: []string{"qs ipc --pid 4242 call curtain close"},
			},
		},
		{
			name: "close fails",
			move: CloseCurtain,
			outputs: map[string][]output{
				"qs ipc --pid 4242 call curtain close": {{Err: errors.New("exit status 1")}},
			},
			want: result{
				Err:   "the curtain is up: qs ipc: exit status 1",
				Calls: []string{"qs ipc --pid 4242 call curtain close"},
			},
		},
		{
			name:    "open",
			move:    OpenCurtain,
			outputs: map[string][]output{"qs ipc --pid 4242 call curtain open": {{Stdout: "shown\n"}}},
			want:    result{Calls: []string{"qs ipc --pid 4242 call curtain open"}},
		},
		{
			name:    "open answers otherwise",
			move:    OpenCurtain,
			outputs: map[string][]output{"qs ipc --pid 4242 call curtain open": {{Stdout: "missing-pam\n"}}},
			want: result{
				Err:   "the curtain is down: curtain open: missing-pam",
				Calls: []string{"qs ipc --pid 4242 call curtain open"},
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &seqRunner{outputs: tt.outputs}

			err := tt.move(t.Context(), r, 4242)

			got := result{Calls: r.calls}
			if err != nil {
				got.Err = err.Error()
			}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

func TestLiftCurtain(t *testing.T) {
	const (
		closeLine  = "qs ipc --pid 4242 call curtain close"
		openLine   = "qs ipc --pid 4242 call curtain open"
		layersLine = "niri msg -j layers"
		curtain    = `[{"namespace":"kaizen-curtain","output":"DP-1","keyboard_interactivity":"Exclusive"}]`
	)
	up := Status{PID: 4242, Curtain: &Curtain{Active: true}}
	type result struct {
		Err        string
		RestoreErr string
		Calls      []string
	}
	for _, tt := range []struct {
		name    string
		status  Status
		outputs map[string][]output
		want    result
	}{
		{
			name:   "down",
			status: Status{PID: 4242, Curtain: &Curtain{}},
		},
		{
			name:   "up",
			status: up,
			outputs: map[string][]output{
				closeLine:  {{Stdout: "hidden\n"}},
				layersLine: {{Stdout: curtain}, {Stdout: "[]"}},
				openLine:   {{Stdout: "shown\n"}},
			},
			want: result{Calls: []string{closeLine, layersLine, layersLine, openLine}},
		},
		{
			name:    "does not lift",
			status:  up,
			outputs: map[string][]output{closeLine: {{Stdout: "Function not found.\n"}}},
			want: result{
				Err:   "the curtain is up: curtain close: Function not found.",
				Calls: []string{closeLine},
			},
		},
		{
			name:   "its surface stays",
			status: up,
			outputs: map[string][]output{
				closeLine:  {{Stdout: "hidden\n"}},
				layersLine: {{Stdout: curtain}},
				openLine:   {{Stdout: "shown\n"}},
			},
			want: result{
				Err: "the curtain's surface did not leave the outputs",
				Calls: append(
					append([]string{closeLine}, slices.Repeat([]string{layersLine}, curtainAttempts)...),
					openLine,
				),
			},
		},
		{
			name:   "does not come back",
			status: up,
			outputs: map[string][]output{
				closeLine:  {{Stdout: "hidden\n"}},
				layersLine: {{Stdout: "[]"}},
				openLine:   {{Stdout: "missing-pam\n"}},
			},
			want: result{
				RestoreErr: "the curtain is down: curtain open: missing-pam",
				Calls:      []string{closeLine, layersLine, openLine},
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			r := &seqRunner{outputs: tt.outputs}

			restore, err := LiftCurtain(t.Context(), r, tt.status, noWait)

			var got result
			if err != nil {
				got.Err = err.Error()
			} else if restoreErr := restore(t.Context()); restoreErr != nil {
				got.RestoreErr = restoreErr.Error()
			}
			got.Calls = r.calls
			assert.DeepEqual(t, got, tt.want)
		})
	}
}
