package cli

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
)

// command is a command's entry in the catalogue.
type command struct {
	Name    string `json:"name"`
	Usage   string `json:"usage"`
	Summary string `json:"summary"`
}

// catalogue lists d.Commands and each line the scripts in d.Dir print on -h,
// by name.
func (d Dispatcher) catalogue() ([]command, error) {
	entries, err := os.ReadDir(d.Dir)
	if err != nil {
		return nil, err
	}
	var commands []command
	for _, entry := range entries {
		path := filepath.Join(d.Dir, entry.Name())
		if strings.HasPrefix(entry.Name(), ".") {
			continue
		}
		if info, err := os.Stat(path); err != nil || !info.Mode().IsRegular() {
			continue
		}
		cmd := exec.Command(path, "-h")
		cmd.Env = d.env()
		cmd.Stderr = d.Stderr
		out, err := cmd.Output()
		if err != nil {
			return nil, fmt.Errorf("%s -h: %w", entry.Name(), err)
		}
		for line := range strings.Lines(string(out)) {
			c := parseUsage(strings.TrimSuffix(line, "\n"))
			if !slices.ContainsFunc(d.Commands, func(g Command) bool { return g.Name() == c.Name }) {
				commands = append(commands, c)
			}
		}
	}
	for _, c := range d.Commands {
		commands = append(commands, command{Name: c.Name(), Usage: c.Usage(), Summary: c.Summary()})
	}
	slices.SortStableFunc(commands, func(a, b command) int { return strings.Compare(a.Name, b.Name) })
	return commands, nil
}

// parseUsage parses a script's -h line: "usage: USAGE    SUMMARY". The name is
// USAGE's first word after kaizen and internal.
func parseUsage(line string) command {
	usage, summary, _ := strings.Cut(strings.TrimPrefix(line, "usage: "), "    ")
	var name string
	for field := range strings.FieldsSeq(usage) {
		if field != "kaizen" && field != "internal" {
			name = field
			break
		}
	}
	return command{Name: name, Usage: usage, Summary: summary}
}
