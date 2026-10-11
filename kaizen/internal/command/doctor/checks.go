package doctor

import (
	"cmp"
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"

	"github.com/fredrikaverpil/dotfiles/kaizen/internal/state"
)

// tracing matches niri's tracing lines, which precede `niri validate`'s report.
var tracing = regexp.MustCompile(`^[0-9]{4}-[0-9]{2}-[0-9]{2}T[^ ]+ +[A-Z]+ `)

// devExec matches the ExecStart of kaizen dev's drop-in, naming the tree.
var devExec = regexp.MustCompile(`^ExecStart=.* -p "(.*)"$`)

// check is a check's finding.
type check struct {
	level, unit, message string
}

// unit is a kaizen unit as systemd shows it.
type unit struct {
	id, invocationID, activeState, result, mainPID, dropInPaths string
	// nRestarts counts systemd's restarts since the unit was last started by
	// hand.
	nRestarts int
}

// readUnits reads the kaizen units from systemd.
func readUnits(ctx context.Context, r state.Runner) ([]unit, error) {
	args := []string{"--user", "show", "kaizen-*"}
	for _, prop := range []string{"Id", "InvocationID", "NRestarts", "ActiveState", "Result", "MainPID", "DropInPaths"} {
		args = append(args, "-p", prop)
	}
	out, err := run(ctx, r, "systemctl", args...)
	if err != nil {
		return nil, err
	}
	var units []unit
	for block := range strings.SplitSeq(string(out), "\n\n") {
		props := map[string]string{}
		for line := range strings.SplitSeq(block, "\n") {
			if key, value, ok := strings.Cut(line, "="); ok && key != "" {
				props[key] = value
			}
		}
		id, ok := props["Id"]
		if !ok {
			continue
		}
		u := unit{
			id:           id,
			invocationID: props["InvocationID"],
			activeState:  props["ActiveState"],
			result:       props["Result"],
			mainPID:      props["MainPID"],
			dropInPaths:  props["DropInPaths"],
		}
		if n, ok := props["NRestarts"]; ok {
			if u.nRestarts, err = strconv.Atoi(n); err != nil {
				return nil, fmt.Errorf("systemctl show %s: NRestarts: %v", id, err)
			}
		}
		units = append(units, u)
	}
	return units, nil
}

// checker gathers the checks' findings.
type checker struct {
	Command
	checks []check
	// buses holds each bus's names, owned and activatable alike.
	buses map[string][]string
}

// add records a finding.
func (k *checker) add(level, unit, message string) {
	k.checks = append(k.checks, check{level: level, unit: unit, message: message})
}

// check runs the checks.
func (c Command) check(ctx context.Context, units []unit) ([]check, error) {
	k := &checker{Command: c, buses: map[string][]string{}}
	var shell unit
	for _, u := range units {
		name := strings.TrimSuffix(u.id, ".service")
		if u.activeState == "failed" {
			k.add("ERROR", name, fmt.Sprintf("failed (%s)", u.result))
		}
		if u.nRestarts > 0 {
			k.add("WARN", name, fmt.Sprintf("failed and was restarted %s", plural(u.nRestarts, "time")))
		}
		if u.id == state.Unit && shell.id == "" {
			shell = u
		}
	}
	stale, err := k.staleShell(ctx, shell.mainPID)
	if err != nil {
		return nil, err
	}
	if stale {
		k.add(
			"WARN",
			"kaizen-shell",
			"runs a Quickshell that is no longer installed: systemctl --user restart kaizen-shell",
		)
	}
	k.kaizens(ctx)
	k.niri(ctx)
	// kaizen dev's drop-in runs a worktree's tree, whose requires and plugins
	// count.
	tree := filepath.Join(k.configDir(), "quickshell", "kaizen")
	dev, err := devTree(shell.dropInPaths)
	if err != nil {
		return nil, err
	}
	if dev != nil {
		tree = *dev
		k.add("WARN", "kaizen-shell", fmt.Sprintf("runs %s: kaizen dev off", tree))
	}
	if err := k.requires(ctx, filepath.Join(tree, "requires"), "requires"); err != nil {
		return nil, err
	}
	if err := k.plugins(ctx, filepath.Join(tree, "plugins")); err != nil {
		return nil, err
	}
	return k.checks, nil
}

// staleShell reports that the shell at pid runs a Quickshell that is no longer
// installed. Nix replaces the store path a rebuild installs; elsewhere the old
// binary shows as deleted.
func (k *checker) staleShell(ctx context.Context, pid string) (bool, error) {
	if pid == "" || pid == "0" {
		return false, nil
	}
	exe, err := os.Readlink(filepath.Join(cmp.Or(k.proc, "/proc"), pid, "exe"))
	if err != nil {
		return false, nil
	}
	_, hasNixStore := k.lookPath("nix-store")
	installed, hasQuickshell := k.lookPath("quickshell")
	if !hasNixStore || !hasQuickshell {
		return strings.HasSuffix(exe, " (deleted)"), nil
	}
	resolved, err := filepath.EvalSymlinks(installed)
	if err != nil {
		return false, err
	}
	out, err := run(ctx, k.Runner, "nix-store", "-qR", resolved)
	if err != nil {
		return false, err
	}
	// The store path: /nix/store/HASH-NAME.
	parts := strings.SplitN(exe, "/", 5)
	storePath := strings.Join(parts[:min(len(parts), 4)], "/")
	return !slices.Contains(strings.Split(strings.TrimRight(string(out), "\n"), "\n"), storePath), nil
}

// kaizens warns of more than one kaizen on PATH: an agent-built
// ~/.local/bin/kaizen shadows the system profile's until a rebuild deletes it.
func (k *checker) kaizens(ctx context.Context) {
	found := map[string]bool{}
	first := ""
	for dir := range strings.SplitSeq(k.Getenv("PATH"), ":") {
		path := dir + "/kaizen"
		if !isExecutable(path) {
			continue
		}
		resolved, err := filepath.EvalSymlinks(path)
		if err != nil {
			resolved = path
		}
		found[resolved] = true
		if first == "" {
			first = path
		}
	}
	if len(found) <= 1 {
		return
	}
	version := "unknown"
	if out, err := k.Runner.Run(ctx, first, "--version"); err == nil {
		version = strings.TrimRight(string(out), "\n")
	}
	shown := first
	if rest, ok := strings.CutPrefix(first, k.Home); ok && k.Home != "" {
		shown = "~" + rest
	}
	k.add(
		"WARN",
		"kaizen",
		fmt.Sprintf("%d kaizen on PATH; the first, %s, is %s: delete it or rebuild", len(found), shown, version),
	)
}

// niri reports a niri config that fails `niri validate`.
func (k *checker) niri(ctx context.Context) {
	_, err := k.Runner.Run(ctx, "env", "NO_COLOR=1", "niri", "validate")
	if err == nil {
		return
	}
	report := err.Error()
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		report = string(exitErr.Stderr)
	}
	var lines []string
	for line := range strings.SplitSeq(strings.TrimRight(report, "\n"), "\n") {
		if !tracing.MatchString(line) {
			lines = append(lines, line)
		}
	}
	k.add("ERROR", "niri", "niri validate:\n"+strings.Join(lines, "\n"))
}

// devTree returns the tree kaizen dev's drop-in among dropInPaths runs, or nil
// without one.
func devTree(dropInPaths string) (*string, error) {
	for path := range strings.SplitSeq(dropInPaths, " ") {
		if !strings.HasSuffix(path, "/"+state.Unit+".d/dev.conf") {
			continue
		}
		data, err := os.ReadFile(path)
		if err != nil {
			return nil, err
		}
		var trees []string
		for line := range strings.SplitSeq(string(data), "\n") {
			if m := devExec.FindStringSubmatch(line); m != nil {
				trees = append(trees, m[1])
			}
		}
		return new(strings.Join(trees, "\n")), nil
	}
	return nil, nil
}

// plugins checks each enabled plugin. The shell loads a plugin only from the
// one dir that has it, silently.
func (k *checker) plugins(ctx context.Context, shellPlugins string) error {
	hostPlugins := filepath.Join(k.configDir(), "kaizen", "plugins")
	entries, err := os.ReadDir(hostPlugins)
	if err != nil {
		return nil
	}
	for _, entry := range entries {
		name, ok := strings.CutSuffix(entry.Name(), ".jsonc")
		if !ok || strings.HasPrefix(entry.Name(), ".") || !exists(filepath.Join(hostPlugins, entry.Name())) {
			continue
		}
		var dirs []string
		for _, dir := range []string{shellPlugins, hostPlugins} {
			if info, err := os.Stat(filepath.Join(dir, name)); err == nil && info.IsDir() {
				dirs = append(dirs, filepath.Join(dir, name))
			}
		}
		switch len(dirs) {
		case 0:
			k.add("ERROR", "plugins", fmt.Sprintf("%s: no %s/ in %s or %s", name, name, shellPlugins, hostPlugins))
		case 2:
			k.add("ERROR", "plugins", fmt.Sprintf("%s: %s/ in both %s and %s", name, name, shellPlugins, hostPlugins))
		default:
			if !isRegular(filepath.Join(dirs[0], "Plugin.qml")) {
				k.add("ERROR", "plugins", fmt.Sprintf("%s: no Plugin.qml in %s", name, dirs[0]))
			}
			if err := k.requires(ctx, filepath.Join(dirs[0], "requires"), name); err != nil {
				return err
			}
		}
	}
	return nil
}

// configDir returns $XDG_CONFIG_HOME, else ~/.config.
func (c Command) configDir() string {
	return cmp.Or(c.Getenv("XDG_CONFIG_HOME"), filepath.Join(c.Home, ".config"))
}

// lookPath returns where PATH has the program name, as `command -v` does.
func (c Command) lookPath(name string) (string, bool) {
	if name == "" {
		return "", false
	}
	if strings.Contains(name, "/") {
		return name, isExecutable(name)
	}
	for dir := range strings.SplitSeq(c.Getenv("PATH"), ":") {
		path := cmp.Or(dir, ".") + "/" + name
		if isExecutable(path) {
			return path, true
		}
	}
	return "", false
}

// exists reports whether path exists, following links.
func exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// isRegular reports whether path is a regular file, following links.
func isRegular(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.Mode().IsRegular()
}

// isExecutable reports whether path is a regular file with an execute bit.
func isExecutable(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.Mode().IsRegular() && info.Mode().Perm()&0o111 != 0
}
