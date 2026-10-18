// Command kaizen runs kaizen's commands: those in internal/command/, and the
// scripts in libexec/kaizen/, each of which prints its usage line on -h.
// `kaizen internal` runs the scripts under internal/, which the system runs and
// a person has no use for.
package main

import (
	"cmp"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"runtime/debug"
	"syscall"

	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/cli"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/command/dev"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/command/doctor"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/command/focus"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/command/keys"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/command/link"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/command/reload"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/command/shot"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/command/status"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/compositor"
	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/state"
)

func main() {
	exe, err := os.Executable()
	if err != nil {
		fmt.Fprintf(os.Stderr, "kaizen: %v\n", err)
		os.Exit(1)
	}
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "kaizen: %v\n", err)
		os.Exit(1)
	}
	cache, err := os.UserCacheDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "kaizen: %v\n", err)
		os.Exit(1)
	}
	info, _ := debug.ReadBuildInfo()
	comp := compositor.FromEnv(os.Getenv, state.Exec{})
	d := cli.Dispatcher{
		Commands: []cli.Command{
			dev.Command{
				Runner:     state.Exec{},
				Main:       filepath.Join(home, ".dotfiles"),
				RuntimeDir: os.Getenv("XDG_RUNTIME_DIR"),
			},
			doctor.Command{Runner: state.Exec{}, Compositor: comp, Home: home, Getenv: os.Getenv},
			focus.Command{Compositor: comp, Environ: os.Environ(), Execve: syscall.Exec},
			keys.Command{Runner: state.Exec{}, Compositor: comp},
			link.Command{
				Runner: state.Exec{},
				Home:   home,
				Main:   filepath.Join(home, ".dotfiles"),
				// Home Manager's activation runs without one.
				RuntimeDir: cmp.Or(os.Getenv("XDG_RUNTIME_DIR"), fmt.Sprintf("/run/user/%d", os.Getuid())),
			},
			reload.Command{Runner: state.Exec{}},
			shot.Command{Runner: state.Exec{}, Compositor: comp, CacheDir: cache},
			status.Command{Runner: state.Exec{}},
		},
		Dir:     cli.ScriptsDir(exe, home),
		BinDir:  filepath.Dir(exe),
		Version: cli.Version(info),
		Environ: os.Environ(),
		Stdout:  os.Stdout,
		Stderr:  os.Stderr,
		Execve:  syscall.Exec,
	}
	os.Exit(d.Run(context.Background(), os.Args[1:]))
}
