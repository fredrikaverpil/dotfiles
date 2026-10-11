// Package dev is `kaizen dev`: run the shell from a checkout's shell tree.
package dev

import (
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"github.com/fredrikaverpil/dotfiles/kaizen/internal/state"
)

// tree is the shell tree in a checkout.
const tree = "stow/kaizen/.config/quickshell/kaizen"

// Command runs the shell from a checkout's tree, or main's again.
type Command struct {
	Runner state.Runner
	// Main is the main checkout, ~/.dotfiles, whose worktrees NAME picks from.
	Main string
	// RuntimeDir is $XDG_RUNTIME_DIR. The drop-in lives under it, so a reboot
	// returns to main's shell.
	RuntimeDir string
}

// Name returns dev.
func (Command) Name() string { return "dev" }

// Usage returns the usage line.
func (Command) Usage() string { return "kaizen dev [PATH | NAME | off]" }

// Summary says what it does.
func (Command) Summary() string {
	return "run the shell from a checkout or a worktree of ~/.dotfiles, or main's again;" +
		" refuses while the session is locked"
}

// Run prints the tree the shell runs, after switching it to arg's when given.
// It prints the warnings and errors the shell logged meanwhile on stderr, and
// exits 1 when it refuses, or when the shell does not run the tree.
func (c Command) Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	var arg string
	for _, a := range args {
		switch {
		case a == "-h", a == "--help":
			fmt.Fprintf(stdout, "usage: %s    %s\n", c.Usage(), c.Summary())
			return 0
		case strings.HasPrefix(a, "-"), arg != "":
			fmt.Fprintf(stderr, "kaizen dev: unknown argument: %s\nusage: %s\n", a, c.Usage())
			return 2
		}
		arg = a
	}
	var dir string
	var err error
	switch arg {
	case "":
		dir, err = shellTree(ctx, c.Runner)
	case "off":
		dir, err = c.off(ctx, stderr)
	default:
		dir, err = c.on(ctx, arg, stderr)
	}
	if err != nil {
		fmt.Fprintf(stderr, "kaizen dev: %v\n", err)
		return 1
	}
	fmt.Fprintln(stdout, dir)
	return 0
}

// on runs the shell from the tree of the checkout at path arg, or of the
// worktree named arg, and returns that tree.
func (c Command) on(ctx context.Context, arg string, stderr io.Writer) (string, error) {
	dropIn, err := c.dropIn()
	if err != nil {
		return "", err
	}
	root, err := c.root(ctx, arg)
	if err != nil {
		return "", err
	}
	dir := filepath.Join(root, tree)
	if _, err := os.Stat(filepath.Join(dir, "shell.qml")); err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return "", fmt.Errorf("%s/shell.qml does not exist", dir)
		}
		return "", err
	}
	// Before the drop-in changes, so a refusal leaves the unit as it was.
	status, err := state.Unlocked(ctx, c.Runner)
	if err != nil {
		return "", err
	}
	if err := os.MkdirAll(filepath.Dir(dropIn), 0o755); err != nil {
		return "", err
	}
	// No fallback: a removed worktree leaves the unit failing, which kaizen
	// doctor reports.
	unit := fmt.Sprintf("[Service]\nExecStart=\nExecStart=/usr/bin/env quickshell -p \"%s\"\n", dir)
	if err := os.WriteFile(dropIn, []byte(unit), 0o644); err != nil {
		return "", err
	}
	if err := c.restart(ctx, status, stderr); err != nil {
		return "", fmt.Errorf("%v; kaizen dev off runs main's", err)
	}
	// Fails rather than leave an agent validating main's shell.
	got, err := shellTree(ctx, c.Runner)
	if err != nil {
		return "", err
	}
	if got != dir {
		return "", fmt.Errorf("%s does not run %s", state.Unit, dir)
	}
	return dir, nil
}

// off runs the shell from main's tree again and returns that tree.
func (c Command) off(ctx context.Context, stderr io.Writer) (string, error) {
	dropIn, err := c.dropIn()
	if err != nil {
		return "", err
	}
	// Before the drop-in changes, so a refusal leaves the unit as it was.
	status, err := state.Unlocked(ctx, c.Runner)
	if err != nil {
		return "", err
	}
	if err := os.Remove(dropIn); err != nil && !errors.Is(err, fs.ErrNotExist) {
		return "", err
	}
	if err := c.restart(ctx, status, stderr); err != nil {
		return "", err
	}
	return shellTree(ctx, c.Runner)
}

// restart restarts the shell and prints the warnings and errors it logged
// meanwhile on stderr.
func (c Command) restart(ctx context.Context, status state.Status, stderr io.Writer) error {
	entries, err := state.Reload(ctx, c.Runner, status, true)
	for _, line := range state.Problems(entries) {
		fmt.Fprintln(stderr, line)
	}
	return err
}

// dropIn returns the path of the unit's drop-in.
func (c Command) dropIn() (string, error) {
	if c.RuntimeDir == "" {
		return "", errors.New("XDG_RUNTIME_DIR is not set")
	}
	return filepath.Join(c.RuntimeDir, "systemd", "user", state.Unit+".d", "dev.conf"), nil
}

// root returns the checkout at path arg, else the worktree of c.Main named arg.
func (c Command) root(ctx context.Context, arg string) (string, error) {
	if info, err := os.Stat(arg); err == nil && info.IsDir() {
		abs, err := filepath.Abs(arg)
		if err != nil {
			return "", err
		}
		return filepath.EvalSymlinks(abs)
	}
	out, err := c.Runner.Run(ctx, "git", "-C", c.Main, "worktree", "list", "--porcelain")
	if err != nil {
		return "", fmt.Errorf("git worktree list: %v", err)
	}
	var roots []string
	for line := range strings.Lines(string(out)) {
		path, ok := strings.CutPrefix(strings.TrimSuffix(line, "\n"), "worktree ")
		if ok && filepath.Base(path) == arg {
			roots = append(roots, path)
		}
	}
	if len(roots) != 1 {
		return "", fmt.Errorf("no single worktree of ~/.dotfiles named %s", arg)
	}
	return roots[0], nil
}

// shellTree returns the tree the shell runs.
func shellTree(ctx context.Context, r state.Runner) (string, error) {
	status, err := state.Read(ctx, r)
	if err != nil {
		return "", err
	}
	if status.PID == 0 {
		return "", fmt.Errorf("%s is not running", state.Unit)
	}
	if status.Tree == nil {
		reason := "shell status has no tree"
		if status.Error != nil {
			reason = *status.Error
		}
		return "", fmt.Errorf("the tree %s runs is unknown: %s", state.Unit, reason)
	}
	return *status.Tree, nil
}
