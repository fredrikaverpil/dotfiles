package doctor

import (
	"cmp"
	"context"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

// requires checks the requires file at path for unit: one finding listing
// what it names that is missing, an error unless every missing line ends in
// `warn`. Each line is `cmd NAME`, `bus session|system NAME`, `file PATH` or
// `data PATH`, in the XDG data dirs.
func (k *checker) requires(ctx context.Context, path, unit string) error {
	if !isRegular(path) {
		return nil
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	level := "WARN"
	var missing []string
	for line := range strings.Lines(string(data)) {
		fields := strings.Fields(line)
		if len(fields) == 0 || strings.HasPrefix(fields[0], "#") {
			continue
		}
		kind, a, b := fields[0], field(fields, 1), field(fields, 2)
		c := strings.Join(fields[min(len(fields), 3):], " ")
		name, flag := a, b
		found := false
		switch {
		case kind == "cmd":
			_, found = k.lookPath(a)
		case kind == "bus" && (a == "session" || a == "system"):
			name, flag = a+" "+b, c
			found = slices.Contains(k.busNames(ctx, a), b)
		case kind == "file":
			found = exists(a)
		case kind == "data":
			found = slices.ContainsFunc(k.dataDirs(), func(dir string) bool { return exists(dir + "/" + a) })
		default:
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
		k.add(level, unit, strings.Join(missing, "\n"))
	}
	return nil
}

// field returns fields[i], or "" past the end.
func field(fields []string, i int) string {
	if i < len(fields) {
		return fields[i]
	}
	return ""
}

// busNames returns the names on bus, session or system, owned and activatable
// alike; none when busctl fails.
func (k *checker) busNames(ctx context.Context, bus string) []string {
	if names, ok := k.buses[bus]; ok {
		return names
	}
	flag := "--system"
	if bus == "session" {
		flag = "--user"
	}
	out, _ := k.Runner.Run(ctx, "busctl", flag, "list", "--no-legend")
	var names []string
	for line := range strings.Lines(string(out)) {
		if fields := strings.Fields(line); len(fields) > 0 {
			names = append(names, fields[0])
		}
	}
	k.buses[bus] = names
	return names
}

// dataDirs returns $XDG_DATA_HOME and $XDG_DATA_DIRS, with their defaults.
func (c Command) dataDirs() []string {
	home := cmp.Or(c.Getenv("XDG_DATA_HOME"), filepath.Join(c.Home, ".local", "share"))
	dirs := cmp.Or(c.Getenv("XDG_DATA_DIRS"), "/usr/local/share:/usr/share")
	return strings.Split(home+":"+dirs, ":")
}
