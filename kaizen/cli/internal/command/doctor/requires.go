package doctor

import (
	"cmp"
	"context"
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
// or `env NAME=VALUE`, in the user manager's environment, then `warn` or
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
		found, known := false, name != "" && (flag == "" || flag == "warn")
		switch {
		case !known:
		case kind == "cmd":
			_, found = k.lookPath(name)
		case kind == "bus" && bus != "":
			names, listed := k.list(ctx, "the "+bus+" bus", "busctl", busFlags[bus], "list", "--no-legend")
			if !listed {
				continue
			}
			found = slices.Contains(names, name)
			name = bus + " " + name
		case kind == "env" && strings.Index(name, "=") > 0:
			names, listed := k.list(ctx, "the user manager's environment", "systemctl", "--user", "show-environment")
			if !listed {
				continue
			}
			found = slices.Contains(names, name)
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

// listing is the names a command printed.
type listing struct {
	names []string
	// ok is false when the command failed.
	ok bool
}

// list returns the first field of each line name prints with args, running it
// once per what; false when it fails, which it reports once.
func (k *checker) list(ctx context.Context, what, name string, args ...string) ([]string, bool) {
	if l, ok := k.lists[what]; ok {
		return l.names, l.ok
	}
	out, err := run(ctx, k.Runner, name, args...)
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
	var names []string
	for line := range strings.Lines(string(out)) {
		if fields := strings.Fields(line); len(fields) > 0 {
			names = append(names, fields[0])
		}
	}
	k.lists[what] = listing{names: names, ok: true}
	return names, true
}

// dataDirs returns $XDG_DATA_HOME and $XDG_DATA_DIRS, with their defaults.
func (c Command) dataDirs() []string {
	home := cmp.Or(c.Getenv("XDG_DATA_HOME"), filepath.Join(c.Home, ".local", "share"))
	dirs := cmp.Or(c.Getenv("XDG_DATA_DIRS"), "/usr/local/share:/usr/share")
	return strings.Split(home+":"+dirs, ":")
}
