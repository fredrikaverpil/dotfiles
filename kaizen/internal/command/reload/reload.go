// Package reload is `kaizen reload`: the one way to apply a change to the
// shell.
package reload

import (
	"context"
	"fmt"
	"io"
	"strings"

	"github.com/fredrikaverpil/dotfiles/kaizen/internal/state"
)

// Command reloads the shell.
type Command struct {
	Runner state.Runner
}

// Name returns reload.
func (Command) Name() string { return "reload" }

// Usage returns the usage line.
func (Command) Usage() string { return "kaizen reload [--restart]" }

// Summary says what it does.
func (Command) Summary() string {
	return "apply the shell's files, restarting it when down or with --restart, and print its warnings and errors;" +
		" refuses while the session is locked"
}

// Run reloads the shell and prints the warnings and errors it logged meanwhile.
// It exits 1 when it refuses, or when the shell does not load its config.
func (c Command) Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	restart := false
	for _, arg := range args {
		switch arg {
		case "-h", "--help":
			fmt.Fprintf(stdout, "usage: %s    %s\n", c.Usage(), c.Summary())
			return 0
		case "--restart":
			restart = true
		default:
			fmt.Fprintf(stderr, "kaizen reload: unknown argument: %s\nusage: %s\n", arg, c.Usage())
			return 2
		}
	}
	status, err := state.Unlocked(ctx, c.Runner)
	if err != nil {
		fmt.Fprintf(stderr, "kaizen reload: %v\n", err)
		return 1
	}
	entries, err := state.Reload(ctx, c.Runner, status, restart)
	for _, line := range problems(entries) {
		fmt.Fprintln(stdout, line)
	}
	if err != nil {
		fmt.Fprintf(stderr, "kaizen reload: %v\n", err)
		return 1
	}
	return 0
}

// problems returns the warnings and errors among entries, one line each,
// starting with its level.
func problems(entries []state.Entry) []string {
	var lines []string
	for _, entry := range entries {
		level := entry.Level()
		switch level {
		case "WARN", "ERROR", "FATAL":
		default:
			continue
		}
		line := strings.TrimSpace(entry.Message)
		if !strings.HasPrefix(line, level) {
			line = level + " " + line
		}
		lines = append(lines, line)
	}
	return lines
}
