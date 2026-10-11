package cli

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"testing"

	"gotest.tools/v3/assert"
)

func TestScriptsDir(t *testing.T) {
	checkout := t.TempDir()
	scripts := filepath.Join(checkout, "kaizen", "stow", ".local", "libexec", "kaizen")
	assert.NilError(t, os.MkdirAll(scripts, 0o755))
	home := "/home/user"
	for _, tt := range []struct {
		name string
		exe  string
		want string
	}{
		{
			name: "checkout",
			exe:  filepath.Join(checkout, "kaizen", "kaizen"),
			want: scripts,
		},
		{
			name: "user install",
			exe:  "/home/user/.local/bin/kaizen",
			want: "/home/user/.local/libexec/kaizen",
		},
		{
			name: "nix store",
			exe:  "/nix/store/abc-kaizen-0.1.0/bin/kaizen",
			want: "/home/user/.local/libexec/kaizen",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			got := ScriptsDir(tt.exe, home)
			assert.Equal(t, got, tt.want)
		})
	}
}

func TestEnv(t *testing.T) {
	for _, tt := range []struct {
		name    string
		environ []string
		want    []string
	}{
		{
			name:    "prepends to PATH",
			environ: []string{"HOME=/home/user", "PATH=/usr/bin:/bin"},
			want:    []string{"HOME=/home/user", "PATH=/opt/kaizen/bin:/usr/bin:/bin"},
		},
		{
			name:    "no PATH",
			environ: []string{"HOME=/home/user"},
			want:    []string{"HOME=/home/user", "PATH=/opt/kaizen/bin"},
		},
		{
			name:    "empty PATH",
			environ: []string{"PATH="},
			want:    []string{"PATH=/opt/kaizen/bin"},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			d := Dispatcher{BinDir: "/opt/kaizen/bin", Environ: tt.environ}
			got := d.env()
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

// execCall is a call to Dispatcher.Execve.
type execCall struct {
	Path string
	Argv []string
	Env  []string
}

// result is what Dispatcher.Run did.
type result struct {
	Code   int
	Stdout string
	Stderr string
	Exec   *execCall
}

// fakeCommand is a Go command that prints its name and arguments.
type fakeCommand struct {
	name string
}

func (c fakeCommand) Name() string    { return c.name }
func (c fakeCommand) Usage() string   { return "kaizen " + c.name + " [--go]" }
func (c fakeCommand) Summary() string { return "do " + c.name + " in Go" }

func (c fakeCommand) Run(_ context.Context, args []string, stdout, _ io.Writer) int {
	fmt.Fprintln(stdout, c.name, args)
	return 3
}

func TestRun(t *testing.T) {
	dir := t.TempDir()
	writeScript(t, filepath.Join(dir, "alpha"), "usage: kaizen alpha [X]    do alpha")
	writeScript(t, filepath.Join(dir, "beta"), "usage: kaizen beta    do beta")
	writeScript(t, filepath.Join(dir, "internal", "gamma"), "usage: kaizen internal gamma FILE    do gamma")
	assert.NilError(t, os.WriteFile(filepath.Join(dir, ".hidden"), nil, 0o755))
	assert.NilError(t, os.MkdirAll(filepath.Join(dir, "lib"), 0o755))
	usage := "usage: kaizen COMMAND [ARGS...] | kaizen --json\n" +
		"  kaizen alpha [X]                              do alpha\n" +
		"  kaizen beta [--go]                            do beta in Go\n" +
		"  kaizen delta [--go]                           do delta in Go\n" +
		"  kaizen internal                               list the commands the system runs\n" +
		"  kaizen --version                              print the commit kaizen was built from\n"
	internalUsage := "usage: kaizen internal COMMAND [ARGS...] | kaizen internal --json\n" +
		"  kaizen internal gamma FILE                    do gamma\n"
	env := []string{"HOME=/home/user", "PATH=/opt/kaizen/bin:/usr/bin"}
	for _, tt := range []struct {
		name string
		args []string
		want result
	}{
		{
			name: "no command",
			want: result{Stdout: usage},
		},
		{
			name: "help",
			args: []string{"-h"},
			want: result{Stdout: usage},
		},
		{
			name: "json",
			args: []string{"--json"},
			want: result{Stdout: `[
  {
    "name": "alpha",
    "usage": "kaizen alpha [X]",
    "summary": "do alpha"
  },
  {
    "name": "beta",
    "usage": "kaizen beta [--go]",
    "summary": "do beta in Go"
  },
  {
    "name": "delta",
    "usage": "kaizen delta [--go]",
    "summary": "do delta in Go"
  }
]
`},
		},
		{
			name: "internal",
			args: []string{"internal"},
			want: result{Stdout: internalUsage},
		},
		{
			name: "internal json",
			args: []string{"internal", "--json"},
			want: result{Stdout: `[
  {
    "name": "gamma",
    "usage": "kaizen internal gamma FILE",
    "summary": "do gamma"
  }
]
`},
		},
		{
			name: "version",
			args: []string{"--version"},
			want: result{Stdout: "4f1c2a9e0b7d\n"},
		},
		{
			name: "internal version",
			args: []string{"internal", "--version"},
			want: result{Code: 2, Stderr: "kaizen: unknown command: --version\n" + internalUsage},
		},
		{
			name: "command",
			args: []string{"alpha", "x", "--y"},
			want: result{Exec: &execCall{
				Path: filepath.Join(dir, "alpha"),
				Argv: []string{filepath.Join(dir, "alpha"), "x", "--y"},
				Env:  env,
			}},
		},
		{
			name: "internal command",
			args: []string{"internal", "gamma", "f"},
			want: result{Exec: &execCall{
				Path: filepath.Join(dir, "internal", "gamma"),
				Argv: []string{filepath.Join(dir, "internal", "gamma"), "f"},
				Env:  env,
			}},
		},
		{
			name: "go command",
			args: []string{"delta", "x"},
			want: result{Code: 3, Stdout: "delta [x]\n"},
		},
		{
			name: "go command over a script",
			args: []string{"beta"},
			want: result{Code: 3, Stdout: "beta []\n"},
		},
		{
			name: "go command under internal",
			args: []string{"internal", "delta"},
			want: result{Code: 2, Stderr: "kaizen: unknown command: delta\n" + internalUsage},
		},
		{
			name: "unknown command",
			args: []string{"epsilon"},
			want: result{Code: 2, Stderr: "kaizen: unknown command: epsilon\n" + usage},
		},
		{
			name: "directory",
			args: []string{"lib"},
			want: result{Code: 2, Stderr: "kaizen: unknown command: lib\n" + usage},
		},
		{
			name: "path",
			args: []string{"internal/gamma"},
			want: result{Code: 2, Stderr: "kaizen: unknown command: internal/gamma\n" + usage},
		},
		{
			name: "internal command at the top",
			args: []string{"gamma"},
			want: result{Code: 2, Stderr: "kaizen: unknown command: gamma\n" + usage},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			var got result
			d := Dispatcher{
				Commands: []Command{fakeCommand{name: "delta"}, fakeCommand{name: "beta"}},
				Dir:      dir,
				BinDir:   "/opt/kaizen/bin",
				Version:  "4f1c2a9e0b7d",
				Environ:  []string{"HOME=/home/user", "PATH=/usr/bin"},
				Stdout:   &stdout,
				Stderr:   &stderr,
				Execve: func(path string, argv []string, env []string) error {
					got.Exec = &execCall{Path: path, Argv: argv, Env: env}
					return nil
				},
			}
			got.Code = d.Run(t.Context(), tt.args)
			got.Stdout = stdout.String()
			got.Stderr = stderr.String()
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

// writeScript writes an executable script at path that prints line.
func writeScript(t *testing.T, path, line string) {
	t.Helper()
	assert.NilError(t, os.MkdirAll(filepath.Dir(path), 0o755))
	assert.NilError(t, os.WriteFile(path, []byte("#!/bin/sh\necho '"+line+"'\n"), 0o755))
}
