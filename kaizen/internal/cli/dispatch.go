// Package cli is kaizen's command-line plumbing: it runs the scripts in
// libexec/kaizen/ and lists them from their -h lines.
package cli

import (
	"encoding/json/jsontext"
	"encoding/json/v2"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// Dispatcher runs the scripts in Dir, with BinDir first on their PATH.
type Dispatcher struct {
	Dir     string
	BinDir  string
	Environ []string
	Stdout  io.Writer
	Stderr  io.Writer
	// Execve replaces the process with a script; it returns only on failure.
	Execve func(path string, argv []string, env []string) error
}

// ScriptsDir returns the scripts of the checkout exe was built in, when exe is
// <checkout>/kaizen/kaizen, else the stowed ones under home.
func ScriptsDir(exe, home string) string {
	checkout := filepath.Join(exe, "..", "..", "stow", "kaizen", ".local", "libexec", "kaizen")
	if info, err := os.Stat(checkout); err == nil && info.IsDir() {
		return checkout
	}
	return filepath.Join(home, ".local", "libexec", "kaizen")
}

// Run dispatches args and returns the exit code.
func (d Dispatcher) Run(args []string) int {
	internal := len(args) > 0 && args[0] == "internal"
	if internal {
		args = args[1:]
		d.Dir = filepath.Join(d.Dir, "internal")
	}
	var name string
	if len(args) > 0 {
		name = args[0]
	}
	switch name {
	case "", "-h", "--help":
		return d.usage(d.Stdout, internal, 0)
	case "--json":
		commands, err := d.catalogue()
		if err != nil {
			fmt.Fprintf(d.Stderr, "kaizen: %v\n", err)
			return 1
		}
		if err := json.MarshalWrite(d.Stdout, commands, jsontext.WithIndent("  ")); err != nil {
			fmt.Fprintf(d.Stderr, "kaizen: %v\n", err)
			return 1
		}
		fmt.Fprintln(d.Stdout)
		return 0
	}
	path := filepath.Join(d.Dir, name)
	if strings.Contains(name, "/") || !isExecutable(path) {
		fmt.Fprintf(d.Stderr, "kaizen: unknown command: %s\n", name)
		return d.usage(d.Stderr, internal, 2)
	}
	if err := d.Execve(path, append([]string{path}, args[1:]...), d.env()); err != nil {
		fmt.Fprintf(d.Stderr, "kaizen: %s: %v\n", name, err)
		return 1
	}
	return 0
}

// usage writes the usage to w and returns code, or 1 when a script's -h fails.
func (d Dispatcher) usage(w io.Writer, internal bool, code int) int {
	commands, err := d.catalogue()
	if err != nil {
		fmt.Fprintf(d.Stderr, "kaizen: %v\n", err)
		return 1
	}
	prefix := "kaizen"
	if internal {
		prefix = "kaizen internal"
	}
	fmt.Fprintf(w, "usage: %s COMMAND [ARGS...] | %s --json\n", prefix, prefix)
	for _, c := range commands {
		fmt.Fprintf(w, "  %-45s %s\n", c.Usage, c.Summary)
	}
	if !internal {
		fmt.Fprintf(w, "  %-45s %s\n", "kaizen internal", "list the commands the system runs")
	}
	return code
}

// env returns d.Environ with d.BinDir first on PATH, so that a script's
// `kaizen` is this binary.
func (d Dispatcher) env() []string {
	env := make([]string, 0, len(d.Environ)+1)
	path := d.BinDir
	for _, kv := range d.Environ {
		if value, ok := strings.CutPrefix(kv, "PATH="); ok {
			if value != "" {
				path = d.BinDir + string(os.PathListSeparator) + value
			}
			continue
		}
		env = append(env, kv)
	}
	return append(env, "PATH="+path)
}

// isExecutable reports whether path is a regular file with an execute bit.
func isExecutable(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.Mode().IsRegular() && info.Mode().Perm()&0o111 != 0
}
