package compositor

import (
	"context"
	"encoding/json/v2"
	"errors"
	"fmt"
	"os/exec"
	"regexp"
	"slices"
	"strconv"
	"strings"
)

// tracing matches niri's tracing lines, which precede `niri validate`'s report.
var tracing = regexp.MustCompile(`^[0-9]{4}-[0-9]{2}-[0-9]{2}T[^ ]+ +[A-Z]+ `)

// Niri is niri, driven with `niri msg`.
type Niri struct {
	Runner Runner
}

// Name returns niri.
func (Niri) Name() string { return "niri" }

// niriLayer is a layer surface in `niri msg -j layers`.
type niriLayer struct {
	Namespace string `json:"namespace"`
	Output    string `json:"output"`
	// KeyboardInteractivity is None, Exclusive or OnDemand.
	KeyboardInteractivity string `json:"keyboard_interactivity"`
}

// Layers reads the layer surfaces from `niri msg -j layers`.
func (n Niri) Layers(ctx context.Context) ([]Layer, error) {
	var layers []niriLayer
	if err := n.query(ctx, &layers, "layers"); err != nil {
		return nil, err
	}
	result := make([]Layer, 0, len(layers))
	for _, l := range layers {
		result = append(result, Layer{
			Namespace: l.Namespace,
			Output:    l.Output,
			Exclusive: l.KeyboardInteractivity == "Exclusive",
		})
	}
	return result, nil
}

// niriOutput is an output in `niri msg -j outputs`.
type niriOutput struct {
	Name string `json:"name"`
	// Logical is nil while the output is off.
	Logical *struct {
		X      int `json:"x"`
		Y      int `json:"y"`
		Width  int `json:"width"`
		Height int `json:"height"`
	} `json:"logical"`
}

// Outputs reads the outputs from `niri msg -j outputs`, and the focused one
// from `niri msg -j focused-output`.
func (n Niri) Outputs(ctx context.Context) ([]Output, error) {
	var outputs map[string]niriOutput
	if err := n.query(ctx, &outputs, "outputs"); err != nil {
		return nil, err
	}
	var focused *niriOutput
	if err := n.query(ctx, &focused, "focused-output"); err != nil {
		return nil, err
	}
	result := make([]Output, 0, len(outputs))
	for _, o := range outputs {
		output := Output{Name: o.Name, Focused: focused != nil && focused.Name == o.Name}
		if o.Logical != nil {
			output.Logical = &Rect{X: o.Logical.X, Y: o.Logical.Y, Width: o.Logical.Width, Height: o.Logical.Height}
		}
		result = append(result, output)
	}
	slices.SortFunc(result, func(a, b Output) int { return strings.Compare(a.Name, b.Name) })
	return result, nil
}

// niriWindow is a window in `niri msg -j focused-window`.
type niriWindow struct {
	ID    int    `json:"id"`
	AppID string `json:"app_id"`
}

// FocusedWindow reads the focused window from `niri msg -j focused-window`.
func (n Niri) FocusedWindow(ctx context.Context) (*Window, error) {
	var w *niriWindow
	if err := n.query(ctx, &w, "focused-window"); err != nil {
		return nil, err
	}
	if w == nil {
		return nil, nil
	}
	return &Window{ID: strconv.Itoa(w.ID), AppID: w.AppID}, nil
}

// FocusWindow focuses window id.
func (n Niri) FocusWindow(ctx context.Context, id string) error {
	if _, err := n.Runner.Run(ctx, "niri", "msg", "action", "focus-window", "--id", id); err != nil {
		return fmt.Errorf("niri msg action focus-window: %v", err)
	}
	return nil
}

// Validate runs `niri validate`, failing with its report without the tracing
// lines.
func (n Niri) Validate(ctx context.Context) error {
	_, err := n.Runner.Run(ctx, "env", "NO_COLOR=1", "niri", "validate")
	if err == nil {
		return nil
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
	return errors.New("niri validate:\n" + strings.Join(lines, "\n"))
}

// query decodes `niri msg -j <what>` into v.
func (n Niri) query(ctx context.Context, v any, what string) error {
	out, err := n.Runner.Run(ctx, "niri", "msg", "-j", what)
	if err != nil {
		return fmt.Errorf("niri msg %s: %v", what, err)
	}
	if err := json.Unmarshal(out, v); err != nil {
		return fmt.Errorf("niri msg %s: %v", what, err)
	}
	return nil
}
