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
// `bus session|system NAME`, `file PATH` or `data PATH`, in the XDG data
// dirs, then `warn` or nothing.
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
			names, listed := k.busNames(ctx, bus)
			if !listed {
				continue
			}
			found = slices.Contains(names, name)
			name = bus + " " + name
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

// busList is a bus's names, owned and activatable alike.
type busList struct {
	names []string
	// listed is false when busctl failed.
	listed bool
}

// busNames returns the names on bus, session or system, owned and activatable
// alike; false when busctl fails, which it reports once.
func (k *checker) busNames(ctx context.Context, bus string) ([]string, bool) {
	if list, ok := k.buses[bus]; ok {
		return list.names, list.listed
	}
	flag := "--system"
	if bus == "session" {
		flag = "--user"
	}
	out, err := run(ctx, k.Runner, "busctl", flag, "list", "--no-legend")
	if err != nil {
		k.buses[bus] = busList{}
		k.add(check{
			name:    "requires",
			level:   "ERROR",
			unit:    "doctor",
			message: fmt.Sprintf("cannot list the %s bus: %v", bus, err),
		})
		return nil, false
	}
	var names []string
	for line := range strings.Lines(string(out)) {
		if fields := strings.Fields(line); len(fields) > 0 {
			names = append(names, fields[0])
		}
	}
	k.buses[bus] = busList{names: names, listed: true}
	return names, true
}

// dataDirs returns $XDG_DATA_HOME and $XDG_DATA_DIRS, with their defaults.
func (c Command) dataDirs() []string {
	home := cmp.Or(c.Getenv("XDG_DATA_HOME"), filepath.Join(c.Home, ".local", "share"))
	dirs := cmp.Or(c.Getenv("XDG_DATA_DIRS"), "/usr/local/share:/usr/share")
	return strings.Split(home+":"+dirs, ":")
}
