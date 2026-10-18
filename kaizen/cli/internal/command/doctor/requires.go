package doctor

import (
	"cmp"
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

// requires checks the requires file at path for unit: one finding listing
// what it names that is missing and each line in another form, an error
// unless every missing line ends in `warn`. Each line is `cmd NAME`,
// `bus session|system NAME`, `file PATH`, `data PATH`, in the XDG data dirs,
// `env NAME=VALUE`, in the user manager's environment, `font FAMILY`, whose
// name is the rest of the line and matches any case, `qtplugin PATH`, in
// the running shell's Qt plugin dirs, or `protocol NAME[|NAME...]`, a Wayland
// global the compositor advertises, any one of the names, then `warn` or
// nothing.
func (k *checker) requires(ctx context.Context, path, unit string) {
	data, err := os.ReadFile(path)
	if err != nil {
		k.add(check{
			name:    "requires",
			level:   "ERROR",
			unit:    "doctor",
			message: fmt.Sprintf("cannot check a requires file: %v", err),
		})
		return
	}
	level := "WARN"
	var missing []string
	for line := range strings.Lines(string(data)) {
		fields := strings.Fields(line)
		if len(fields) == 0 || strings.HasPrefix(fields[0], "#") {
			continue
		}
		kind, args := fields[0], fields[1:]
		bus := ""
		if kind == "bus" && len(args) > 0 && (args[0] == "session" || args[0] == "system") {
			bus, args = args[0], args[1:]
		}
		name, flag := field(args, 0), strings.Join(args[min(len(args), 1):], " ")
		if kind == "font" {
			name, flag = strings.Join(args, " "), ""
			if n := len(args); n > 1 && args[n-1] == "warn" {
				name, flag = strings.Join(args[:n-1], " "), "warn"
			}
		}
		found, known := false, name != "" && (flag == "" || flag == "warn")
		switch {
		case !known:
		case kind == "cmd":
			_, found = k.lookPath(name)
		case kind == "bus" && bus != "":
			names, listed := k.list(ctx, "the "+bus+" bus", firstField, "busctl", busFlags[bus], "list", "--no-legend")
			if !listed {
				continue
			}
			found = slices.Contains(names, name)
			name = bus + " " + name
		case kind == "env" && strings.Index(name, "=") > 0:
			names, listed := k.list(ctx, "the user manager's environment", firstField, "systemctl", "--user", "show-environment")
			if !listed {
				continue
			}
			found = slices.Contains(names, name)
		case kind == "font":
			names, listed := k.list(ctx, "the fonts", families, "fc-list", ":", "family")
			if !listed {
				continue
			}
			found = slices.Contains(names, strings.ToLower(name))
		case kind == "qtplugin":
			dirs, listed := k.listed("the shell's Qt plugin dirs", k.qtPluginDirs)
			if !listed {
				continue
			}
			found = slices.ContainsFunc(dirs, func(dir string) bool { return exists(dir + "/" + name) })
		case kind == "protocol":
			globals, listed := k.list(ctx, "the compositor's protocols", interfaceName, "wayland-info")
			if !listed {
				continue
			}
			found = slices.ContainsFunc(strings.Split(name, "|"), func(n string) bool { return slices.Contains(globals, n) })
		case kind == "file":
			found = exists(name)
		case kind == "data":
			found = slices.ContainsFunc(k.dataDirs(), func(dir string) bool { return exists(dir + "/" + name) })
		default:
			known = false
		}
		if !known {
			level = "ERROR"
			missing = append(missing, "unknown line: "+strings.Join(fields, " "))
			continue
		}
		if found {
			continue
		}
		if flag != "warn" {
			level = "ERROR"
		}
		missing = append(missing, "missing "+kind+" "+name)
	}
	if len(missing) > 0 {
		k.add(check{name: "requires", level: level, unit: unit, message: strings.Join(missing, "\n")})
	}
}

// field returns fields[i], or "" past the end.
func field(fields []string, i int) string {
	if i < len(fields) {
		return fields[i]
	}
	return ""
}

// busFlags is busctl's flag for each bus, whose list holds the names owned
// and activatable alike.
var busFlags = map[string]string{"session": "--user", "system": "--system"}

// listing is the names a listing found.
type listing struct {
	names []string
	// ok is false when the listing failed.
	ok bool
}

// list returns the names split finds in each line name prints with args,
// running it once per what; false when it fails, which it reports once.
func (k *checker) list(
	ctx context.Context,
	what string,
	split func(line string) []string,
	name string,
	args ...string,
) ([]string, bool) {
	return k.listed(what, func() ([]string, error) {
		out, err := run(ctx, k.Runner, name, args...)
		if err != nil {
			return nil, err
		}
		var names []string
		for line := range strings.Lines(string(out)) {
			names = append(names, split(line)...)
		}
		return names, nil
	})
}

// listed returns what names returns, calling it once per what; false when it
// fails, which it reports once.
func (k *checker) listed(what string, names func() ([]string, error)) ([]string, bool) {
	if l, ok := k.lists[what]; ok {
		return l.names, l.ok
	}
	got, err := names()
	if err != nil {
		k.lists[what] = listing{}
		k.add(check{
			name:    "requires",
			level:   "ERROR",
			unit:    "doctor",
			message: fmt.Sprintf("cannot list %s: %v", what, err),
		})
		return nil, false
	}
	k.lists[what] = listing{names: got, ok: true}
	return got, true
}

// firstField returns the line's first field, if any.
func firstField(line string) []string {
	fields := strings.Fields(line)
	return fields[:min(len(fields), 1)]
}

// interfaceName returns the global a wayland-info line names
// (`interface: 'wl_shm', version: 2, name: 1`), if it names one.
func interfaceName(line string) []string {
	rest, ok := strings.CutPrefix(line, "interface: '")
	if !ok {
		return nil
	}
	name, _, ok := strings.Cut(rest, "'")
	if !ok {
		return nil
	}
	return []string{name}
}

// families returns the comma-separated family names of an `fc-list : family`
// line, lowercased.
func families(line string) []string {
	var names []string
	for family := range strings.SplitSeq(strings.TrimSpace(line), ",") {
		if family != "" {
			names = append(names, strings.ToLower(family))
		}
	}
	return names
}

// dataDirs returns $XDG_DATA_HOME and $XDG_DATA_DIRS, with their defaults.
func (c Command) dataDirs() []string {
	home := cmp.Or(c.Getenv("XDG_DATA_HOME"), filepath.Join(c.Home, ".local", "share"))
	dirs := cmp.Or(c.Getenv("XDG_DATA_DIRS"), "/usr/local/share:/usr/share")
	return strings.Split(home+":"+dirs, ":")
}

// qtPluginDirs returns where the running shell loads Qt plugins from: its
// QT_PLUGIN_PATH, which Nix's wrapper sets on the process alone, then Qt's own
// plugins dir beside the libQt6Core it mapped, which a distro's Qt uses.
func (k *checker) qtPluginDirs() ([]string, error) {
	if k.shellPID == "" || k.shellPID == "0" {
		return nil, errors.New("kaizen-shell is not running")
	}
	proc := filepath.Join(cmp.Or(k.proc, "/proc"), k.shellPID)
	environ, err := os.ReadFile(filepath.Join(proc, "environ"))
	if err != nil {
		return nil, err
	}
	var dirs []string
	for variable := range strings.SplitSeq(string(environ), "\x00") {
		if path, ok := strings.CutPrefix(variable, "QT_PLUGIN_PATH="); ok {
			for dir := range strings.SplitSeq(path, ":") {
				if dir != "" {
					dirs = append(dirs, dir)
				}
			}
		}
	}
	maps, err := os.ReadFile(filepath.Join(proc, "maps"))
	if err != nil {
		return nil, err
	}
	for line := range strings.Lines(string(maps)) {
		fields := strings.Fields(line)
		if len(fields) == 6 && strings.HasPrefix(filepath.Base(fields[5]), "libQt6Core.so") {
			lib := filepath.Dir(fields[5])
			return append(dirs, lib+"/qt6/plugins", lib+"/qt-6/plugins"), nil
		}
	}
	return dirs, nil
}
