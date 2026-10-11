package main

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
)

var commitRE = regexp.MustCompile(`^[0-9a-f]{7,40}$`)

// checkout unpacks src, a repository directly under one of sourceDirs, at commit into runDir/src/REPO@SHA unless it is
// there already, and returns that directory. It reads only the repository's objects: the clone's branch, working tree,
// index and worktrees are untouched.
func checkout(sourceDirs []string, runDir, src, commit string) (string, error) {
	if len(sourceDirs) == 0 || runDir == "" {
		return "", errors.New("checkout runs inside an investigation with source directories")
	}
	src = filepath.Clean(src)
	repo := filepath.Base(src)
	under := func(dir string) bool { return filepath.Clean(dir) == filepath.Dir(src) }
	if !slices.ContainsFunc(sourceDirs, under) || repo == "." || repo == ".." || repo == "/" {
		return "", fmt.Errorf("repository %q: want a directory directly under one of %s", src,
			strings.Join(sourceDirs, ", "))
	}
	if !commitRE.MatchString(commit) {
		return "", fmt.Errorf("commit %q: want a hex commit id", commit)
	}
	out, err := exec.Command("git", "-C", src, "rev-parse", "--verify", "--quiet", commit+"^{commit}").Output()
	if err != nil {
		return "", fmt.Errorf("%s has no commit %s", src, commit)
	}
	sha := strings.TrimSpace(string(out))
	dest := filepath.Join(runDir, "src", repo+"@"+sha)
	if _, err := os.Stat(dest); err == nil {
		return dest, nil
	}
	if err := os.MkdirAll(filepath.Dir(dest), 0o700); err != nil {
		return "", err
	}
	// Unpacked beside dest and renamed, so an interrupted checkout never looks complete.
	tmp, err := os.MkdirTemp(filepath.Dir(dest), ".checkout-")
	if err != nil {
		return "", err
	}
	defer func() { _ = os.RemoveAll(tmp) }()
	// ponytail: the archive is held in memory; stream it into tar if a repository outgrows that.
	tarball, err := exec.Command("git", "-C", src, "archive", sha).Output()
	if err != nil {
		return "", fmt.Errorf("git archive: %v", err)
	}
	extract := exec.Command("tar", "-x", "-C", tmp)
	extract.Stdin = bytes.NewReader(tarball)
	if msg, err := extract.CombinedOutput(); err != nil {
		return "", fmt.Errorf("tar: %v: %s", err, msg)
	}
	if err := os.Rename(tmp, dest); err != nil {
		return "", err
	}
	return dest, nil
}
