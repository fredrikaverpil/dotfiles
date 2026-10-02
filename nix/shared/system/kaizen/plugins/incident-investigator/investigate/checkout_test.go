package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"gotest.tools/v3/assert"
)

func TestCheckout(t *testing.T) {
	sourceDir, runDir := t.TempDir(), t.TempDir()
	repo := filepath.Join(sourceDir, "svc")
	git := func(args ...string) string {
		cmd := exec.Command("git", append([]string{"-C", repo}, args...)...)
		cmd.Env = append(os.Environ(), "GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_NOSYSTEM=1",
			"GIT_AUTHOR_NAME=t", "GIT_AUTHOR_EMAIL=t@t", "GIT_COMMITTER_NAME=t", "GIT_COMMITTER_EMAIL=t@t")
		out, err := cmd.CombinedOutput()
		assert.NilError(t, err, string(out))
		return strings.TrimSpace(string(out))
	}
	assert.NilError(t, os.MkdirAll(repo, 0o700))
	git("init", "-q")
	assert.NilError(t, os.WriteFile(filepath.Join(repo, "main.go"), []byte("deployed\n"), 0o600))
	git("add", ".")
	git("commit", "-q", "-m", "deployed")
	sha := git("rev-parse", "HEAD")
	assert.NilError(t, os.WriteFile(filepath.Join(repo, "main.go"), []byte("work in progress\n"), 0o600))

	dir, err := checkout([]string{t.TempDir(), sourceDir + "/"}, runDir, repo, sha[:7])

	assert.NilError(t, err)
	assert.DeepEqual(t, dir, filepath.Join(runDir, "src", "svc@"+sha))
	got, err := os.ReadFile(filepath.Join(dir, "main.go"))
	assert.NilError(t, err)
	assert.DeepEqual(t, string(got), "deployed\n")
	again, err := checkout([]string{sourceDir}, runDir, repo, sha)
	assert.NilError(t, err)
	assert.DeepEqual(t, again, dir)
	assert.DeepEqual(t, git("status", "--porcelain"), "M main.go")
}

func TestCheckoutRejects(t *testing.T) {
	sourceDir := t.TempDir()
	for _, tt := range []struct {
		name, repo, commit, wantErr string
	}{
		{name: "bare name", repo: "svc", commit: "abcdef0", wantErr: "want a directory directly under"},
		{name: "nested repo", repo: sourceDir + "/a/b", commit: "abcdef0", wantErr: "want a directory directly under"},
		{name: "another directory", repo: "/tmp/svc", commit: "abcdef0", wantErr: "want a directory directly under"},
		{name: "parent", repo: sourceDir + "/..", commit: "abcdef0", wantErr: "want a directory directly under"},
		{name: "source dir itself", repo: sourceDir + "/.", commit: "abcdef0", wantErr: "want a directory directly under"},
		{name: "ref", repo: sourceDir + "/svc", commit: "main", wantErr: "want a hex commit id"},
		{name: "option", repo: sourceDir + "/svc", commit: "--all", wantErr: "want a hex commit id"},
		{name: "unknown commit", repo: sourceDir + "/svc", commit: "abcdef0", wantErr: "has no commit"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			_, err := checkout([]string{sourceDir}, t.TempDir(), tt.repo, tt.commit)

			assert.ErrorContains(t, err, tt.wantErr)
		})
	}
}
