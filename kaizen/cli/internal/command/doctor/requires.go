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
// `env NAME=VALUE`, in the user manager's environment, or `font FAMILY`,
// whose name is the rest of the line and matches any case, then `warn` or
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

// list returns the names split finds in each line name prints with args,
// running it once per what; false when it fails, which it reports once.
func (k *checker) list(
	ctx context.Context,
	what string,
	split func(line string) []string,
	name string,
	args ...string,
) ([]string, bool) {
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
		names = append(names, split(line)...)
	}
	k.lists[what] = listing{names: names, ok: true}
	return names, true
}

// firstField returns the line's first field, if any.
func firstField(line string) []string {
	fields := strings.Fields(line)
	return fields[:min(len(fields), 1)]
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
