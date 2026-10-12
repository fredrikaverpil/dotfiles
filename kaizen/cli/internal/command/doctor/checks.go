package doctor

import (
	"cmp"
	"context"
	"encoding/binary"
	"encoding/json/v2"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"syscall"

	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/state"
)

// tracing matches niri's tracing lines, which precede `niri validate`'s report.
var tracing = regexp.MustCompile(`^[0-9]{4}-[0-9]{2}-[0-9]{2}T[^ ]+ +[A-Z]+ `)

// include matches a niri config's include line, capturing its path.
var include = regexp.MustCompile(`(?m)^[ \t]*include[ \t][^"\n]*"([^"]*)"`)

// devExec matches the ExecStart of kaizen dev's drop-in, naming the tree.
var devExec = regexp.MustCompile(`^ExecStart=.* -p "(.*)"$`)

// systemd's catalog ids of its entries about a unit's run.
const (
	// restartScheduled is "Scheduled restart job, restart counter is at N".
	restartScheduled = "5eb03494b6584870a536b337290809b3"
	// processExited is "Main process exited, code=…, status=…".
	processExited = "98e322203f7a4ed290d09fe03c09fe15"
	// failureResult is "Failed with result '…'".
	failureResult = "d9b373ed55a64feb8242e02dbe79a49c"
)

// check is a check's finding. name is the check's stable id; hint is the fix,
// or "".
type check struct {
	name, level, unit, message, hint string
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
	// lists holds each listing's names, by what it lists.
	lists map[string]listing
	// shellPID is the shell's MainPID; "" or "0" when it is not running.
	shellPID string
}

// add records a finding.
func (k *checker) add(c check) {
	k.checks = append(k.checks, c)
}

// check runs the checks. A check that cannot run is an error of unit doctor.
func (c Command) check(ctx context.Context, units []unit) []check {
	k := &checker{Command: c, lists: map[string]listing{}}
	var shell unit
	for _, u := range units {
		name := strings.TrimSuffix(u.id, ".service")
		if u.activeState == "failed" {
			k.add(check{name: "failed", level: "ERROR", unit: name, message: fmt.Sprintf("failed (%s)", u.result)})
		}
		if u.nRestarts > 0 {
			lines := append([]string{"failed and was restarted " + plural(u.nRestarts, "time")}, k.restarts(ctx, u)...)
			k.add(check{name: "restarted", level: "WARN", unit: name, message: strings.Join(lines, "\n")})
		}
		if u.id == state.Unit && shell.id == "" {
			shell = u
		}
	}
	k.shellPID = shell.mainPID
	if k.staleShell(ctx, k.shellPID) {
		k.add(check{
			name:    "stale-shell",
			level:   "WARN",
			unit:    "kaizen-shell",
			message: "runs a Quickshell that is no longer installed",
			hint:    "kaizen reload --restart",
		})
	}
	k.kaizens(ctx)
	k.niri(ctx)
	k.portal(ctx)
	k.kmsServer()
	// kaizen dev's drop-in runs a worktree's tree, whose requires and plugins
	// count.
	tree := filepath.Join(k.configDir(), "quickshell", "kaizen")
	if dev := k.devTree(shell.dropInPaths); dev != "" {
		tree = dev
		k.add(check{name: "dev", level: "WARN", unit: "kaizen-shell", message: "runs " + tree, hint: "kaizen dev off"})
	}
	if core := filepath.Join(tree, "requires"); !isRegular(core) {
		k.add(check{name: "requires", level: "ERROR", unit: "requires", message: "no requires in " + tree})
	} else {
		k.requires(ctx, core, "requires")
	}
	k.plugins(ctx, tree, units)
	return k.checks
}

// restarts returns why each of u's runs since it was last started by hand
// failed: when, how its process exited, then its last warning or error
// indented. Identical causes are counted. systemd logs each automatic restart
// about the run that failed.
func (k *checker) restarts(ctx context.Context, u unit) []string {
	name := strings.TrimSuffix(u.id, ".service")
	out, err := run(ctx, k.Runner, "journalctl", "--user", "--boot", "USER_UNIT="+u.id, "MESSAGE_ID="+restartScheduled,
		"--lines", strconv.Itoa(u.nRestarts), "--output", "json", "--no-pager")
	var scheduled, entries []state.Entry
	if err == nil {
		scheduled, err = parseJournal(out)
	}
	if err == nil {
		ids := make([]string, 0, len(scheduled))
		for _, s := range scheduled {
			ids = append(ids, s.InvocationID)
		}
		out, err = readRuns(ctx, k.Runner, ids)
	}
	if err == nil {
		entries, err = parseJournal(out)
	}
	if err != nil {
		k.add(check{
			name:    "restarted",
			level:   "ERROR",
			unit:    "doctor",
			message: fmt.Sprintf("cannot read why %s was restarted: %v", name, err),
		})
		return nil
	}
	runs := map[string][]state.Entry{}
	for _, e := range entries {
		runs[e.InvocationID] = append(runs[e.InvocationID], e)
	}
	type cause struct{ exit, last string }
	type span struct {
		count       int
		first, last int64
	}
	spans := map[cause]*span{}
	var causes []cause
	for _, s := range scheduled {
		var c cause
		when := s.Time.UnixMilli()
		logged := runs[s.InvocationID]
		for _, e := range logged {
			switch {
			case e.MessageID == processExited:
				c.exit = strings.TrimPrefix(strings.TrimPrefix(e.Message, u.id+": "), "Main process exited, ")
				when = e.Time.UnixMilli()
			case e.MessageID != failureResult && severity(e) != "":
				c.last = trimMessage(e.Message)
			}
		}
		sp, ok := spans[c]
		if !ok {
			sp = &span{first: when, last: when}
			spans[c] = sp
			causes = append(causes, c)
		}
		sp.count++
		sp.first = min(sp.first, when)
		sp.last = max(sp.last, when)
	}
	lines := make([]string, 0, len(causes))
	for _, c := range causes {
		sp := spans[c]
		line := k.times(sp.count, sp.first, sp.last)
		if c.exit != "" {
			line += "  " + c.exit
		}
		if c.last != "" {
			line += "\n  " + strings.ReplaceAll(c.last, "\n", "\n  ")
		}
		lines = append(lines, line)
	}
	return lines
}

// parseJournal parses journalctl's JSON output.
func parseJournal(out []byte) ([]state.Entry, error) {
	entries, err := state.ParseJournal(out)
	if err != nil {
		return nil, fmt.Errorf("journalctl: %v", err)
	}
	return entries, nil
}

// staleShell reports that the shell at pid runs a Quickshell that is no longer
// installed. Nix replaces the store path a rebuild installs; elsewhere the old
// binary shows as deleted.
func (k *checker) staleShell(ctx context.Context, pid string) bool {
	if pid == "" || pid == "0" {
		return false
	}
	exe, err := os.Readlink(filepath.Join(cmp.Or(k.proc, "/proc"), pid, "exe"))
	if err != nil {
		return false
	}
	_, hasNixStore := k.lookPath("nix-store")
	installed, hasQuickshell := k.lookPath("quickshell")
	if !strings.HasPrefix(exe, "/nix/store/") || !hasNixStore || !hasQuickshell {
		return strings.HasSuffix(exe, " (deleted)")
	}
	resolved, err := filepath.EvalSymlinks(installed)
	if err != nil {
		k.add(check{
			name:    "stale-shell",
			level:   "ERROR",
			unit:    "doctor",
			message: fmt.Sprintf("cannot check the shell's Quickshell: %v", err),
		})
		return false
	}
	out, err := run(ctx, k.Runner, "nix-store", "-qR", resolved)
	if err != nil {
		k.add(check{
			name:    "stale-shell",
			level:   "ERROR",
			unit:    "doctor",
			message: fmt.Sprintf("cannot check the shell's Quickshell: %v", err),
		})
		return false
	}
	// The store path: /nix/store/HASH-NAME.
	parts := strings.SplitN(exe, "/", 5)
	storePath := strings.Join(parts[:min(len(parts), 4)], "/")
	return !slices.Contains(strings.Split(strings.TrimRight(string(out), "\n"), "\n"), storePath)
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
	k.add(check{
		name:    "kaizen-path",
		level:   "WARN",
		unit:    "kaizen",
		message: fmt.Sprintf("%d kaizen on PATH; the first, %s, is %s", len(found), shown, version),
		hint:    fmt.Sprintf("delete %s or rebuild", shown),
	})
}

// niri reports a niri config that fails `niri validate`, or else never
// includes kaizen.kdl.
func (k *checker) niri(ctx context.Context) {
	_, err := k.Runner.Run(ctx, "env", "NO_COLOR=1", "niri", "validate")
	if err == nil {
		config := cmp.Or(k.Getenv("NIRI_CONFIG"), filepath.Join(k.configDir(), "niri", "config.kdl"))
		if !k.reaches(config, "kaizen.kdl", 0) {
			k.add(check{
				name:    "niri-include",
				level:   "ERROR",
				unit:    "niri",
				message: config + " does not include kaizen.kdl",
				hint:    `add include "kaizen.kdl" to ` + config,
			})
		}
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
	k.add(check{name: "niri-config", level: "ERROR", unit: "niri", message: "niri validate:\n" + strings.Join(lines, "\n")})
}

// reaches reports whether niri config file, or a file it includes, includes a
// regular file named name. Includes resolve as niri's do: ~ is home, other
// relative paths are relative to the including file, and nesting stops at 10
// levels.
func (k *checker) reaches(file, name string, depth int) bool {
	if depth >= 10 {
		return false
	}
	data, err := os.ReadFile(file)
	if err != nil {
		return false
	}
	for _, m := range include.FindAllStringSubmatch(string(data), -1) {
		path := m[1]
		switch {
		case path == "~" || strings.HasPrefix(path, "~/"):
			path = k.Home + path[1:]
		case !filepath.IsAbs(path):
			path = filepath.Join(filepath.Dir(file), path)
		}
		if filepath.Base(path) == name && isRegular(path) || k.reaches(path, name, depth+1) {
			return true
		}
	}
	return false
}

// portal warns when the portal does not answer the colour scheme, which GTK
// and Qt read through it.
func (k *checker) portal(ctx context.Context) {
	_, err := run(ctx, k.Runner, "busctl", "--user", "--timeout=5", "call", "org.freedesktop.portal.Desktop",
		"/org/freedesktop/portal/desktop", "org.freedesktop.portal.Settings", "ReadOne", "ss",
		"org.freedesktop.appearance", "color-scheme")
	if err != nil {
		k.add(check{
			name:    "portal",
			level:   "WARN",
			unit:    "xdg-desktop-portal",
			message: fmt.Sprintf("cannot read the colour scheme: %v", err),
		})
	}
}

// kmsServer warns when gsr-kms-server, the first on PATH as gpu-screen-recorder
// finds it, lacks cap_sys_admin+ep, which lets monitor capture skip the portal
// dialog. requires reports it missing.
func (k *checker) kmsServer() {
	path, ok := k.lookPath("gsr-kms-server")
	if !ok {
		return
	}
	read := k.getxattr
	if read == nil {
		read = getxattr
	}
	data, err := read(path, "security.capability")
	if err != nil && !errors.Is(err, syscall.ENODATA) {
		k.add(check{
			name:    "gsr-kms-server",
			level:   "ERROR",
			unit:    "doctor",
			message: fmt.Sprintf("cannot read %s's capabilities: %v", path, err),
		})
		return
	}
	if sysAdmin(data) {
		return
	}
	k.add(check{
		name:    "gsr-kms-server",
		level:   "WARN",
		unit:    "gpu-screen-recorder",
		message: path + " lacks cap_sys_admin+ep",
		hint:    "sudo setcap cap_sys_admin+ep " + path,
	})
}

// sysAdmin reports that data, a security.capability attribute (vfs_cap_data:
// little-endian magic_etc, then the permitted set's low word), holds
// cap_sys_admin permitted and effective.
func sysAdmin(data []byte) bool {
	const (
		// effective is VFS_CAP_FLAGS_EFFECTIVE, in magic_etc.
		effective = 1
		// capSysAdmin is CAP_SYS_ADMIN's bit.
		capSysAdmin = 1 << 21
	)
	return len(data) >= 8 &&
		binary.LittleEndian.Uint32(data)&effective != 0 &&
		binary.LittleEndian.Uint32(data[4:])&capSysAdmin != 0
}

// getxattr returns path's extended attribute attr, following links.
func getxattr(path, attr string) ([]byte, error) {
	buf := make([]byte, 64)
	n, err := syscall.Getxattr(path, attr, buf)
	if err != nil {
		return nil, err
	}
	return buf[:n], nil
}

// devTree returns the tree kaizen dev's drop-in among dropInPaths runs, or ""
// without one or when the drop-in does not say.
func (k *checker) devTree(dropInPaths string) string {
	for path := range strings.SplitSeq(dropInPaths, " ") {
		if !strings.HasSuffix(path, "/"+state.Unit+".d/dev.conf") {
			continue
		}
		data, err := os.ReadFile(path)
		if err != nil {
			k.add(check{
				name:    "dev",
				level:   "ERROR",
				unit:    "doctor",
				message: fmt.Sprintf("cannot read kaizen dev's drop-in: %v", err),
			})
			return ""
		}
		var trees []string
		for line := range strings.SplitSeq(string(data), "\n") {
			if m := devExec.FindStringSubmatch(line); m != nil {
				trees = append(trees, m[1])
			}
		}
		if len(trees) == 0 {
			k.add(check{
				name:    "dev",
				level:   "WARN",
				unit:    "kaizen-shell",
				message: fmt.Sprintf("runs a tree %s does not name", path),
				hint:    "kaizen dev off",
			})
		}
		return strings.Join(trees, "\n")
	}
	return ""
}

// manifest is a plugin's plugin.json.
type manifest struct {
	ID      string   `json:"id"`
	Name    string   `json:"name"`
	Version string   `json:"version"`
	API     int      `json:"api"`
	Units   []string `json:"units"`
}

// plugins checks each enabled plugin of the shell in tree. The shell loads a
// plugin only from the one dir that has it, with a plugin.json of its plugin
// API, silently.
func (k *checker) plugins(ctx context.Context, tree string, units []unit) {
	shellPlugins := filepath.Join(tree, "plugins")
	hostPlugins := filepath.Join(k.configDir(), "kaizen", "plugins")
	entries, err := os.ReadDir(hostPlugins)
	if errors.Is(err, fs.ErrNotExist) {
		return
	}
	if err != nil {
		k.add(check{
			name:    "plugins",
			level:   "ERROR",
			unit:    "doctor",
			message: fmt.Sprintf("cannot list the enabled plugins: %v", err),
		})
		return
	}
	api := k.pluginAPI(tree)
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
			k.add(check{
				name:    "plugins",
				level:   "ERROR",
				unit:    "plugins",
				message: fmt.Sprintf("%s: no %s/ in %s or %s", name, name, shellPlugins, hostPlugins),
			})
		case 2:
			k.add(check{
				name:    "plugins",
				level:   "ERROR",
				unit:    "plugins",
				message: fmt.Sprintf("%s: %s/ in both %s and %s", name, name, shellPlugins, hostPlugins),
			})
		default:
			if !isRegular(filepath.Join(dirs[0], "Plugin.qml")) {
				k.add(check{
					name:    "plugins",
					level:   "ERROR",
					unit:    "plugins",
					message: fmt.Sprintf("%s: no Plugin.qml in %s", name, dirs[0]),
				})
			}
			k.manifest(name, dirs[0], api, units)
			if requires := filepath.Join(dirs[0], "requires"); isRegular(requires) {
				k.requires(ctx, requires, name)
			}
		}
	}
}

// pluginAPI returns the plugin API of the shell in tree, its plugin-api; 0
// when it has none.
func (k *checker) pluginAPI(tree string) int {
	path := filepath.Join(tree, "plugin-api")
	data, err := os.ReadFile(path)
	if err != nil {
		k.add(check{
			name:    "plugins",
			level:   "ERROR",
			unit:    "plugins",
			message: fmt.Sprintf("cannot read the shell's plugin API: %v", err),
		})
		return 0
	}
	api, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil || api < 1 {
		k.add(check{
			name:    "plugins",
			level:   "ERROR",
			unit:    "plugins",
			message: fmt.Sprintf("%s holds no plugin API", path),
		})
		return 0
	}
	return api
}

// manifest checks the plugin.json in dir of the plugin name: its id, its
// plugin API against api unless 0, and that its units are loaded and running.
func (k *checker) manifest(name, dir string, api int, units []unit) {
	path := filepath.Join(dir, "plugin.json")
	data, err := os.ReadFile(path)
	if errors.Is(err, fs.ErrNotExist) {
		k.add(check{
			name:    "plugins",
			level:   "ERROR",
			unit:    "plugins",
			message: fmt.Sprintf("%s: no plugin.json in %s", name, dir),
		})
		return
	}
	if err != nil {
		k.add(check{
			name:    "plugins",
			level:   "ERROR",
			unit:    "doctor",
			message: fmt.Sprintf("cannot read a plugin manifest: %v", err),
		})
		return
	}
	var m manifest
	if err := json.Unmarshal(data, &m); err != nil {
		k.add(check{
			name:    "plugins",
			level:   "ERROR",
			unit:    "plugins",
			message: fmt.Sprintf("%s: %s: %v", name, path, err),
		})
		return
	}
	if m.ID != name {
		k.add(check{
			name:    "plugins",
			level:   "ERROR",
			unit:    "plugins",
			message: fmt.Sprintf("%s: %s names id %q", name, path, m.ID),
		})
		return
	}
	if api > 0 && m.API != api {
		k.add(check{
			name:    "plugins",
			level:   "ERROR",
			unit:    "plugins",
			message: fmt.Sprintf("%s: %s %s needs plugin API %d, the shell's is %d", name, m.Name, m.Version, m.API, api),
		})
	}
	for _, id := range m.Units {
		i := slices.IndexFunc(units, func(u unit) bool { return u.id == id })
		switch {
		case i < 0:
			k.add(check{
				name:    "plugins",
				level:   "ERROR",
				unit:    "plugins",
				message: fmt.Sprintf("%s: %s is not loaded", name, id),
				hint:    "kaizen link",
			})
		case units[i].activeState == "inactive":
			k.add(check{
				name:    "plugins",
				level:   "WARN",
				unit:    strings.TrimSuffix(id, ".service"),
				message: "not running, though plugin " + name + " is enabled",
				hint:    "systemctl --user start " + id,
			})
		}
	}
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
