package compositor

import (
	"context"
	"encoding/json/v2"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
)

// TOML, as far as umbriel's includes need it: a table header, naming the
// table; a string; a line's text before its comment; an array of files.
var (
	tomlHeader  = regexp.MustCompile(`^\s*\[\[?\s*([^\[\]]+?)\s*\]\]?\s*(#.*)?$`)
	tomlDot     = regexp.MustCompile(`\s*\.\s*`)
	tomlString  = regexp.MustCompile(`"(?:[^"\\]|\\.)*"|'[^']*'`)
	tomlComment = regexp.MustCompile(`^((?:[^#"']|"(?:[^"\\]|\\.)*"|'[^']*')*)#.*$`)
	tomlFiles   = regexp.MustCompile(`(?m)^\s*files\s*=\s*\[([^\]]*)\]`)
)

// Umbriel is umbriel, driven with its CLI over $UMBRIEL_SOCKET.
type Umbriel struct {
	Runner Runner
}

// Name returns umbriel.
func (Umbriel) Name() string { return "umbriel" }

// umbrielLayer is a layer surface in `umbriel layers --json`.
type umbrielLayer struct {
	Namespace string `json:"namespace"`
	Output    string `json:"output"`
	Mapped    bool   `json:"mapped"`
	// Focused reports keyboard focus. A primed panel keeps it on demand
	// (releaseExclusiveFocus), so interactivity alone does not tell.
	Focused bool `json:"focused"`
}

// Layers reads the mapped layer surfaces from `umbriel layers --json`, which
// also lists unmapped ones.
func (u Umbriel) Layers(ctx context.Context) ([]Layer, error) {
	var layers []umbrielLayer
	if err := u.query(ctx, &layers, "layers"); err != nil {
		return nil, err
	}
	var result []Layer
	for _, l := range layers {
		if !l.Mapped {
			continue
		}
		result = append(result, Layer{
			Namespace: l.Namespace,
			Output:    l.Output,
			Keyboard:  l.Focused,
		})
	}
	return result, nil
}

// umbrielOutput is an output in `umbriel outputs --json`.
type umbrielOutput struct {
	Name string `json:"name"`
	// Enabled is false while the output is off; DPMS-off keeps it enabled.
	Enabled  bool `json:"enabled"`
	Focused  bool `json:"focused"`
	Position struct {
		X int `json:"x"`
		Y int `json:"y"`
	} `json:"position"`
	LogicalSize struct {
		Width  int `json:"width"`
		Height int `json:"height"`
	} `json:"logical_size"`
}

// Outputs reads the outputs from `umbriel outputs --json`.
func (u Umbriel) Outputs(ctx context.Context) ([]Output, error) {
	var outputs []umbrielOutput
	if err := u.query(ctx, &outputs, "outputs"); err != nil {
		return nil, err
	}
	result := make([]Output, 0, len(outputs))
	for _, o := range outputs {
		output := Output{Name: o.Name, Focused: o.Focused}
		if o.Enabled {
			output.Logical = &Rect{
				X:      o.Position.X,
				Y:      o.Position.Y,
				Width:  o.LogicalSize.Width,
				Height: o.LogicalSize.Height,
			}
		}
		result = append(result, output)
	}
	return result, nil
}

// umbrielWindow is a window in `umbriel windows --json`.
type umbrielWindow struct {
	ID    string `json:"id"`
	AppID string `json:"app_id"`
	// Active is seat focus, false while a layer holds the keyboard.
	Active bool `json:"active"`
}

// FocusedWindow reads the active window from `umbriel windows --json`.
func (u Umbriel) FocusedWindow(ctx context.Context) (*Window, error) {
	var windows []umbrielWindow
	if err := u.query(ctx, &windows, "windows"); err != nil {
		return nil, err
	}
	for _, w := range windows {
		if w.Active {
			return &Window{ID: w.ID, AppID: w.AppID}, nil
		}
	}
	return nil, nil
}

// Windows reads the windows from `umbriel windows --json`. umbriel keeps no
// focus timestamp: the active window comes first, the rest in its order.
func (u Umbriel) Windows(ctx context.Context) ([]Window, error) {
	var windows []umbrielWindow
	if err := u.query(ctx, &windows, "windows"); err != nil {
		return nil, err
	}
	slices.SortStableFunc(windows, func(a, b umbrielWindow) int {
		switch {
		case a.Active == b.Active:
			return 0
		case a.Active:
			return -1
		}
		return 1
	})
	result := make([]Window, 0, len(windows))
	for _, w := range windows {
		result = append(result, Window{ID: w.ID, AppID: w.AppID})
	}
	return result, nil
}

// FocusWindow focuses window id.
func (u Umbriel) FocusWindow(ctx context.Context, id string) error {
	if _, err := u.Runner.Run(ctx, "umbriel", "msg", "window-focus:"+id); err != nil {
		return fmt.Errorf("umbriel msg window-focus: %v", err)
	}
	return nil
}

// Validate runs `umbriel config validate`, failing with its report.
func (u Umbriel) Validate(ctx context.Context) error {
	_, err := u.Runner.Run(ctx, "umbriel", "config", "validate")
	if err == nil {
		return nil
	}
	report := err.Error()
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		report = string(exitErr.Stderr)
	}
	return errors.New("umbriel config validate:\n" + strings.TrimRight(report, "\n"))
}

// Config returns umbriel/config.toml in the config dir.
func (Umbriel) Config(env Env) Config {
	path := filepath.Join(env.configDir(), "umbriel", "config.toml")
	return Config{
		Path:     path,
		Kaizen:   "kaizen.toml",
		Hint:     `add "kaizen.toml" to [include] files in ` + path,
		includes: func(data string) []string { return umbrielIncludes(data, env.Getenv) },
		home:     env.Home,
	}
}

// umbrielIncludes returns the paths an umbriel config's [include] and then
// [include.optional] tables list in files, with $VAR and ${VAR} expanded, as
// umbriel does.
func umbrielIncludes(data string, getenv func(string) string) []string {
	tables := map[string][]string{}
	header := ""
	for line := range strings.SplitSeq(data, "\n") {
		if m := tomlHeader.FindStringSubmatch(line); m != nil {
			header = tomlDot.ReplaceAllString(m[1], ".")
			continue
		}
		tables[header] = append(tables[header], tomlComment.ReplaceAllString(line, "$1"))
	}
	var paths []string
	for _, name := range []string{"include", "include.optional"} {
		m := tomlFiles.FindStringSubmatch(strings.Join(tables[name], "\n"))
		if m == nil {
			continue
		}
		for _, quoted := range tomlString.FindAllString(m[1], -1) {
			path := quoted[1 : len(quoted)-1]
			if quoted[0] == '"' {
				if unquoted, err := strconv.Unquote(quoted); err == nil {
					path = unquoted
				}
			}
			paths = append(paths, os.Expand(path, getenv))
		}
	}
	return paths
}

// query decodes `umbriel <what> --json` into v.
func (u Umbriel) query(ctx context.Context, v any, what string) error {
	out, err := u.Runner.Run(ctx, "umbriel", what, "--json")
	if err != nil {
		return fmt.Errorf("umbriel %s: %v", what, err)
	}
	if err := json.Unmarshal(out, v); err != nil {
		return fmt.Errorf("umbriel %s: %v", what, err)
	}
	return nil
}
