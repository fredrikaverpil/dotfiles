// Package link is `kaizen link`: link a checkout's kaizen/stow/ into $HOME.
package link

import (
	"bytes"
	"cmp"
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/state"
)

// Command links kaizen/stow/ into $HOME with Stow and reloads the user units.
type Command struct {
	Runner state.Runner
	Home   string
	// Main is the main checkout, ~/.dotfiles, linked when no DIR is given.
	Main string
	// RuntimeDir is the user manager's $XDG_RUNTIME_DIR.
	RuntimeDir string
}

// Name returns link.
func (Command) Name() string { return "link" }

// Usage returns the usage line.
func (Command) Usage() string { return "kaizen link [DIR]" }

// Summary says what it does.
func (Command) Summary() string {
	return "link kaizen/stow/ of checkout DIR (default ~/.dotfiles) into $HOME, removing broken links into its kaizen/," +
		" and reload the user units"
}

// Run links the checkout's kaizen/stow/ into $HOME, printing each change.
// It exits 1 when a step fails.
func (c Command) Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	var arg string
	for _, a := range args {
		switch {
		case a == "-h", a == "--help":
			fmt.Fprintf(stdout, "usage: %s    %s\n", c.Usage(), c.Summary())
			return 0
		case strings.HasPrefix(a, "-"), arg != "":
			fmt.Fprintf(stderr, "kaizen link: unknown argument: %s\nusage: %s\n", a, c.Usage())
			return 2
		}
		arg = a
	}
	if err := c.link(ctx, cmp.Or(arg, c.Main), stdout); err != nil {
		fmt.Fprintf(stderr, "kaizen link: %v\n", err)
		return 1
	}
	return 0
}

// link links dir's kaizen/stow/ into c.Home and reloads the user units.
func (c Command) link(ctx context.Context, dir string, stdout io.Writer) error {
	abs, err := filepath.Abs(dir)
	if err != nil {
		return err
	}
	// Stow writes relative links to the physical path.
	kaizen, err := filepath.EvalSymlinks(filepath.Join(abs, "kaizen"))
	if err != nil {
		return err
	}
	tops, err := os.ReadDir(filepath.Join(kaizen, "stow"))
	if err != nil {
		return err
	}
	// Before stowing: stow refuses to replace a link it does not own, such as
	// one into a file that moved.
	for _, top := range tops {
		if err := sweep(filepath.Join(c.Home, top.Name()), kaizen, stdout); err != nil {
			return err
		}
	}
	// --adopt absorbs a real file that replaced a managed link into the repo;
	// --no-folding links files, not dirs, so other tools can write siblings.
	stow := []string{"--dir=" + kaizen, "--target=" + c.Home, "--restow", "--no-folding", "--adopt", "stow"}
	fmt.Fprintln(stdout, "stow "+strings.Join(stow, " "))
	if _, err := c.Runner.Run(ctx, "stow", stow...); err != nil {
		return failed("stow", err)
	}
	// Stowed units take effect on a reload, when a user manager runs.
	env := "XDG_RUNTIME_DIR=" + c.RuntimeDir
	if _, err := c.Runner.Run(ctx, "env", env, "systemctl", "--user", "show-environment"); err != nil {
		return nil
	}
	fmt.Fprintln(stdout, "systemctl --user daemon-reload")
	if _, err := c.Runner.Run(ctx, "env", env, "systemctl", "--user", "daemon-reload"); err != nil {
		return failed("systemctl --user daemon-reload", err)
	}
	return nil
}

// sweep removes each broken link under top that points into dir, printing it,
// and the directories a removal leaves empty, up to top.
func sweep(top, dir string, stdout io.Writer) error {
	if _, err := os.Lstat(top); errors.Is(err, fs.ErrNotExist) {
		return nil
	}
	return filepath.WalkDir(top, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			if path == top {
				return err
			}
			// An unreadable directory holds no link Stow wrote.
			return nil
		}
		if d.Type()&fs.ModeSymlink == 0 {
			return nil
		}
		if _, err := os.Stat(path); err == nil {
			return nil
		}
		target, err := os.Readlink(path)
		if err != nil {
			return err
		}
		if !filepath.IsAbs(target) {
			target = filepath.Join(filepath.Dir(path), target)
		}
		if !within(resolve(target), dir) {
			return nil
		}
		fmt.Fprintf(stdout, "rm %s\n", path)
		if err := os.Remove(path); err != nil {
			return err
		}
		parent := filepath.Dir(path)
		for parent != top && os.Remove(parent) == nil {
			parent = filepath.Dir(parent)
		}
		return nil
	})
}

// resolve returns path with the symlinks in its longest existing prefix
// resolved.
func resolve(path string) string {
	var rest string
	for prefix := path; ; prefix = filepath.Dir(prefix) {
		if real, err := filepath.EvalSymlinks(prefix); err == nil {
			return filepath.Join(real, rest)
		}
		if prefix == filepath.Dir(prefix) {
			return path
		}
		rest = filepath.Join(filepath.Base(prefix), rest)
	}
}

// within reports whether path is dir or under it.
func within(path, dir string) bool {
	return path == dir || strings.HasPrefix(path, dir+string(filepath.Separator))
}

// failed describes name's failure by what it printed on stderr, if anything.
func failed(name string, err error) error {
	if exit, ok := errors.AsType[*exec.ExitError](err); ok {
		if msg := bytes.TrimSpace(exit.Stderr); len(msg) > 0 {
			return fmt.Errorf("%s: %s", name, msg)
		}
	}
	return fmt.Errorf("%s: %v", name, err)
}
