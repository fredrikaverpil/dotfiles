package link

import (
	"bytes"
	"context"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"gotest.tools/v3/assert"
)

// output is a program's recorded stdout and error.
type output struct {
	Stdout string
	Err    error
}

// fakeRunner answers each command line with its recorded output.
type fakeRunner map[string]output

func (f fakeRunner) Run(_ context.Context, name string, args ...string) ([]byte, error) {
	line := strings.Join(append([]string{name}, args...), " ")
	out, ok := f[line]
	if !ok {
		return nil, fmt.Errorf("unexpected command: %s", line)
	}
	return []byte(out.Stdout), out.Err
}

const (
	stowLine     = "stow --dir=$REPO/kaizen --target=$HOME --restow --no-folding --adopt stow"
	showEnvLine  = "env XDG_RUNTIME_DIR=/run/user/1000 systemctl --user show-environment"
	reloadLine   = "env XDG_RUNTIME_DIR=/run/user/1000 systemctl --user daemon-reload"
	removedLines = "rm $HOME/.config/niri/old.kdl\nrm $HOME/.local/libexec/kaizen/gone/script\n"
)

// repoFiles are the files in the checkout.
var repoFiles = []string{
	"kaizen/stow/.config/niri/config.kdl",
	"kaizen/stow/.local/libexec/kaizen/run",
	"stow/shared/.zshrc",
}

// homeLinks are the links in $HOME, by path, to their targets. A target in
// $REPO is written relative, as Stow writes it.
var homeLinks = map[string]string{
	".config/niri/config.kdl":           "$REPO/kaizen/stow/.config/niri/config.kdl",
	".config/niri/old.kdl":              "$REPO/kaizen/stow/.config/niri/old.kdl",
	".config/other":                     "/nonexistent/other",
	".config/zsh/old":                   "$REPO/stow/shared/old",
	".local/libexec/kaizen/gone/script": "$REPO/kaizen/stow/.local/libexec/kaizen/gone/script",
}

var (
	// untouched is $HOME as arranged.
	untouched = []string{
		".config",
		".config/niri",
		".config/niri/config.kdl",
		".config/niri/old.kdl",
		".config/other",
		".config/zsh",
		".config/zsh/old",
		".local",
		".local/libexec",
		".local/libexec/kaizen",
		".local/libexec/kaizen/gone",
		".local/libexec/kaizen/gone/script",
	}
	// swept is $HOME without the broken links into kaizen/ and the directories
	// their removal left empty.
	swept = []string{
		".config",
		".config/niri",
		".config/niri/config.kdl",
		".config/other",
		".config/zsh",
		".config/zsh/old",
		".local",
	}
)

// result is what Command.Run did, with $HOME's paths after it.
type result struct {
	Code   int
	Stdout string
	Stderr string
	Home   []string
}

func TestRun(t *testing.T) {
	usage := "usage: kaizen link [DIR]"
	for _, tt := range []struct {
		name   string
		args   []string
		runner fakeRunner
		want   result
	}{
		{
			name: "help",
			args: []string{"-h"},
			want: result{Stdout: usage + "    " + Command{}.Summary() + "\n", Home: untouched},
		},
		{
			name: "unknown flag",
			args: []string{"--force"},
			want: result{Code: 2, Stderr: "kaizen link: unknown argument: --force\n" + usage + "\n", Home: untouched},
		},
		{
			name: "second argument",
			args: []string{"$REPO", "$REPO"},
			want: result{Code: 2, Stderr: "kaizen link: unknown argument: $REPO\n" + usage + "\n", Home: untouched},
		},
		{
			name: "no kaizen dir",
			args: []string{"$HOME"},
			want: result{
				Code:   1,
				Stderr: "kaizen link: lstat $HOME/kaizen: no such file or directory\n",
				Home:   untouched,
			},
		},
		{
			name: "main, with a user manager",
			runner: fakeRunner{
				stowLine:    {},
				showEnvLine: {},
				reloadLine:  {},
			},
			want: result{
				Stdout: removedLines + stowLine + "\nsystemctl --user daemon-reload\n",
				Home:   swept,
			},
		},
		{
			name: "dir, without a user manager",
			args: []string{"$REPO"},
			runner: fakeRunner{
				stowLine:    {},
				showEnvLine: {Err: &exec.ExitError{Stderr: []byte("Failed to connect to bus\n")}},
			},
			want: result{Stdout: removedLines + stowLine + "\n", Home: swept},
		},
		{
			name: "stow fails",
			runner: fakeRunner{
				stowLine: {Err: &exec.ExitError{Stderr: []byte("WARNING! stowing stow would cause conflicts\n")}},
			},
			want: result{
				Code:   1,
				Stdout: removedLines + stowLine + "\n",
				Stderr: "kaizen link: stow: WARNING! stowing stow would cause conflicts\n",
				Home:   swept,
			},
		},
		{
			name: "reload fails",
			runner: fakeRunner{
				stowLine:    {},
				showEnvLine: {},
				reloadLine:  {Err: &exec.ExitError{}},
			},
			want: result{
				Code:   1,
				Stdout: removedLines + stowLine + "\nsystemctl --user daemon-reload\n",
				Stderr: "kaizen link: systemctl --user daemon-reload: <nil>\n",
				Home:   swept,
			},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			tmp, err := filepath.EvalSymlinks(t.TempDir())
			assert.NilError(t, err)
			home := filepath.Join(tmp, "home")
			repo := filepath.Join(tmp, "repo")
			main := filepath.Join(tmp, "dotfiles")
			expand := strings.NewReplacer("$HOME", home, "$REPO", repo)
			arrange(t, home, repo, expand)
			assert.NilError(t, os.Symlink(repo, main))
			runner := fakeRunner{}
			for line, out := range tt.runner {
				runner[expand.Replace(line)] = out
			}
			var args []string
			for _, arg := range tt.args {
				args = append(args, expand.Replace(arg))
			}
			c := Command{Runner: runner, Home: home, Main: main, RuntimeDir: "/run/user/1000"}
			var stdout, stderr bytes.Buffer

			code := c.Run(context.Background(), args, &stdout, &stderr)

			collapse := strings.NewReplacer(home, "$HOME", repo, "$REPO")
			got := result{
				Code:   code,
				Stdout: collapse.Replace(stdout.String()),
				Stderr: collapse.Replace(stderr.String()),
				Home:   paths(t, home),
			}
			assert.DeepEqual(t, got, tt.want)
		})
	}
}

// arrange writes repoFiles into repo and homeLinks into home.
func arrange(t *testing.T, home, repo string, expand *strings.Replacer) {
	t.Helper()
	for _, file := range repoFiles {
		path := filepath.Join(repo, file)
		assert.NilError(t, os.MkdirAll(filepath.Dir(path), 0o755))
		assert.NilError(t, os.WriteFile(path, nil, 0o644))
	}
	for link, target := range homeLinks {
		path := filepath.Join(home, link)
		assert.NilError(t, os.MkdirAll(filepath.Dir(path), 0o755))
		if strings.HasPrefix(target, "$REPO") {
			rel, err := filepath.Rel(filepath.Dir(path), expand.Replace(target))
			assert.NilError(t, err)
			target = rel
		}
		assert.NilError(t, os.Symlink(target, path))
	}
}

// paths returns the paths under dir, relative to it, in lexical order.
func paths(t *testing.T, dir string) []string {
	t.Helper()
	var got []string
	err := filepath.WalkDir(dir, func(path string, _ fs.DirEntry, err error) error {
		if err != nil || path == dir {
			return err
		}
		rel, err := filepath.Rel(dir, path)
		got = append(got, rel)
		return err
	})
	assert.NilError(t, err)
	return got
}
