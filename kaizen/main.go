// Command kaizen runs kaizen's commands: the scripts in libexec/kaizen/, each of
// which prints its usage line on -h. `kaizen internal` runs the ones under
// internal/, which the system runs and a person has no use for.
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime/debug"
	"syscall"

	"github.com/fredrikaverpil/dotfiles/kaizen/internal/cli"
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
	info, _ := debug.ReadBuildInfo()
	d := cli.Dispatcher{
		Dir:     cli.ScriptsDir(exe, home),
		BinDir:  filepath.Dir(exe),
		Version: cli.Version(info),
		Environ: os.Environ(),
		Stdout:  os.Stdout,
		Stderr:  os.Stderr,
		Execve:  syscall.Exec,
	}
	os.Exit(d.Run(os.Args[1:]))
}
