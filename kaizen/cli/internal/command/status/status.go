// Package status is `kaizen status`: the shell's state.
package status

import (
	"bytes"
	"context"
	"encoding/json/jsontext"
	"encoding/json/v2"
	"fmt"
	"io"
	"strconv"

	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/state"
)

// Command prints the shell's state.
type Command struct {
	Runner state.Runner
}

// Name returns status.
func (Command) Name() string { return "status" }

// Usage returns the usage line.
func (Command) Usage() string { return "kaizen status [--json]" }

// Summary says what it does.
func (Command) Summary() string {
	return "print the shell's state: its unit, process, tree, readiness, lock, curtain and idle"
}

// Run prints the state and exits 0 whatever it is, or 1 when systemd cannot
// be read.
func (c Command) Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	asJSON := false
	for _, arg := range args {
		switch arg {
		case "-h", "--help":
			fmt.Fprintf(stdout, "usage: %s    %s\n", c.Usage(), c.Summary())
			return 0
		case "--json":
			asJSON = true
		default:
			fmt.Fprintf(stderr, "kaizen status: unknown argument: %s\nusage: %s\n", arg, c.Usage())
			return 2
		}
	}
	status, err := state.Read(ctx, c.Runner)
	if err != nil {
		fmt.Fprintf(stderr, "kaizen status: %v\n", err)
		return 1
	}
	value, err := json.Marshal(status)
	if err != nil {
		fmt.Fprintf(stderr, "kaizen status: %v\n", err)
		return 1
	}
	if asJSON {
		if err := (*jsontext.Value)(&value).Indent(jsontext.WithIndent("  ")); err != nil {
			fmt.Fprintf(stderr, "kaizen status: %v\n", err)
			return 1
		}
		fmt.Fprintf(stdout, "%s\n", value)
		return 0
	}
	if err := writePlain(stdout, value); err != nil {
		fmt.Fprintf(stderr, "kaizen status: %v\n", err)
		return 1
	}
	return 0
}

// writePlain writes a JSON value as a `key value` line per scalar, keys joined
// by dots and padded to one width.
func writePlain(w io.Writer, value []byte) error {
	var keys, values []string
	dec := jsontext.NewDecoder(bytes.NewReader(value))
	var walk func(key string) error
	walk = func(key string) error {
		tok, err := dec.ReadToken()
		if err != nil {
			return err
		}
		switch tok.Kind() {
		case '{':
			for dec.PeekKind() != '}' {
				name, err := dec.ReadToken()
				if err != nil {
					return err
				}
				if err := walk(join(key, name.String())); err != nil {
					return err
				}
			}
			_, err := dec.ReadToken()
			return err
		case '[':
			for i := 0; dec.PeekKind() != ']'; i++ {
				if err := walk(join(key, strconv.Itoa(i))); err != nil {
					return err
				}
			}
			_, err := dec.ReadToken()
			return err
		}
		keys = append(keys, key)
		values = append(values, tok.String())
		return nil
	}
	if err := walk(""); err != nil {
		return err
	}
	width := 0
	for _, key := range keys {
		width = max(width, len(key))
	}
	for i, key := range keys {
		if _, err := fmt.Fprintf(w, "%-*s %s\n", width, key, values[i]); err != nil {
			return err
		}
	}
	return nil
}

// join joins a parent key and a child's name with a dot.
func join(parent, name string) string {
	if parent == "" {
		return name
	}
	return parent + "." + name
}
