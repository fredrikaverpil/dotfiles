// Package focus is `kaizen focus`: focus an app's window, or open the app.
package focus

import (
	"context"
	"fmt"
	"io"
	"os/exec"
	"regexp"

	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/compositor"
)

// Command focuses the most recently focused window whose app id matches, else
// runs the command that opens the app.
type Command struct {
	Compositor compositor.Compositor
	Environ    []string
	// Execve replaces the process with the command; it returns only on failure.
	Execve func(path string, argv []string, env []string) error
	// lookPath finds the command; nil is exec.LookPath.
	lookPath func(file string) (string, error)
}

// Name returns focus.
func (Command) Name() string { return "focus" }

// Usage returns the usage line.
func (Command) Usage() string { return "kaizen focus APP_ID_REGEX COMMAND [ARGS...]" }

// Summary says what it does.
func (Command) Summary() string { return "focus the app, or open it" }

// Run focuses the app args name, or execs its command.
func (c Command) Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	if len(args) > 0 && (args[0] == "-h" || args[0] == "--help") {
		fmt.Fprintf(stdout, "usage: %s    %s\n", c.Usage(), c.Summary())
		return 0
	}
	if len(args) < 2 {
		fmt.Fprintf(stderr, "kaizen focus: pass the app id regex and the command\nusage: %s\n", c.Usage())
		return 2
	}
	re, err := regexp.Compile(args[0])
	if err != nil {
		fmt.Fprintf(stderr, "kaizen focus: %v\nusage: %s\n", err, c.Usage())
		return 2
	}
	windows, err := c.Compositor.Windows(ctx)
	if err != nil {
		fmt.Fprintf(stderr, "kaizen focus: %v\n", err)
		return 1
	}
	for _, w := range windows {
		if !re.MatchString(w.AppID) {
			continue
		}
		if err := c.Compositor.FocusWindow(ctx, w.ID); err != nil {
			fmt.Fprintf(stderr, "kaizen focus: %v\n", err)
			return 1
		}
		return 0
	}
	lookPath := c.lookPath
	if lookPath == nil {
		lookPath = exec.LookPath
	}
	path, err := lookPath(args[1])
	if err != nil {
		fmt.Fprintf(stderr, "kaizen focus: %v\n", err)
		return 1
	}
	if err := c.Execve(path, args[1:], c.Environ); err != nil {
		fmt.Fprintf(stderr, "kaizen focus: %s: %v\n", args[1], err)
		return 1
	}
	return 0
}
