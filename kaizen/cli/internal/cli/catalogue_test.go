package cli

import (
	"testing"

	"gotest.tools/v3/assert"
)

func TestParseUsage(t *testing.T) {
	for _, tt := range []struct {
		name string
		line string
		want command
	}{
		{
			name: "command",
			line: "usage: kaizen shot [--bar | WxH+X+Y] [OUTPUT]    capture an output",
			want: command{Name: "shot", Usage: "kaizen shot [--bar | WxH+X+Y] [OUTPUT]", Summary: "capture an output"},
		},
		{
			name: "internal command",
			line: "usage: kaizen internal emoji <emoji-test.txt> <emoji.json>    print the shell's emoji data",
			want: command{
				Name:    "emoji",
				Usage:   "kaizen internal emoji <emoji-test.txt> <emoji.json>",
				Summary: "print the shell's emoji data",
			},
		},
		{
			name: "no summary",
			line: "usage: kaizen run",
			want: command{Name: "run", Usage: "kaizen run"},
		},
		{
			name: "no usage prefix",
			line: "kaizen run    start the session",
			want: command{Name: "run", Usage: "kaizen run", Summary: "start the session"},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			got := parseUsage(tt.line)
			assert.DeepEqual(t, got, tt.want)
		})
	}
}
