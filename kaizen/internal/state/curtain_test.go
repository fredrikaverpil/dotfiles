package state

import (
	"context"
	"errors"
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
