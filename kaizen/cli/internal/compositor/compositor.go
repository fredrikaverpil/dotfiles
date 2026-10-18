// Package compositor reads and drives the session's compositor.
package compositor

import (
	"context"
	"errors"
	"fmt"
	"maps"
	"slices"
	"strings"
)

// ErrNoCompositor is the error of each call on an Unset compositor.
var ErrNoCompositor = errors.New("no compositor")

// Runner runs a program and returns its stdout.
type Runner interface {
	Run(ctx context.Context, name string, args ...string) ([]byte, error)
}

// Compositor is the session's compositor.
type Compositor interface {
	// Name is the compositor's program name.
	Name() string
	// Layers returns the mapped layer surfaces.
	Layers(ctx context.Context) ([]Layer, error)
	// Outputs returns the outputs.
	Outputs(ctx context.Context) ([]Output, error)
	// FocusedWindow returns the window with keyboard focus, nil when none has
	// it.
	FocusedWindow(ctx context.Context) (*Window, error)
	// Windows returns the windows, the most recently focused first.
	Windows(ctx context.Context) ([]Window, error)
	// FocusWindow focuses window id.
	FocusWindow(ctx context.Context, id string) error
	// Validate checks the compositor's config, returning its report when
	// it fails.
	Validate(ctx context.Context) error
	// Config returns the compositor's config file, resolved in env.
	Config(env Env) Config
}

// Layer is a layer surface.
type Layer struct {
	Namespace string
	Output    string
	// Keyboard reports that the layer holds the keyboard.
	Keyboard bool
}

// Output is an output.
type Output struct {
	Name string
	// Logical is nil while the output is off.
	Logical *Rect
	Focused bool
}

// Rect is an output's place and size in the layout, in logical pixels.
type Rect struct {
	X      int
	Y      int
	Width  int
	Height int
}

// Window is a toplevel window.
type Window struct {
	ID    string
	AppID string
}

// compositors maps the variable each compositor exports to its session, its
// IPC socket, to the compositor.
var compositors = map[string]func(Runner) Compositor{
	"NIRI_SOCKET":    func(r Runner) Compositor { return Niri{Runner: r} },
	"UMBRIEL_SOCKET": func(r Runner) Compositor { return Umbriel{Runner: r} },
}

// FromEnv returns the compositor whose socket variable is set, or an Unset one
// when none is or more than one is.
func FromEnv(getenv func(string) string, r Runner) Compositor {
	vars := slices.Sorted(maps.Keys(compositors))
	set := slices.DeleteFunc(slices.Clone(vars), func(v string) bool { return getenv(v) == "" })
	switch len(set) {
	case 0:
		return Unset{Err: fmt.Errorf("%w: none of %s is set", ErrNoCompositor, strings.Join(vars, ", "))}
	case 1:
		return compositors[set[0]](r)
	}
	return Unset{Err: fmt.Errorf("%w: more than one is set: %s", ErrNoCompositor, strings.Join(set, ", "))}
}

// Unset stands in when no single compositor's socket variable is set: each call
// returns Err.
type Unset struct {
	Err error
}

// Name returns the empty string.
func (Unset) Name() string { return "" }

// Layers returns u.Err.
func (u Unset) Layers(context.Context) ([]Layer, error) { return nil, u.Err }

// Outputs returns u.Err.
func (u Unset) Outputs(context.Context) ([]Output, error) { return nil, u.Err }

// FocusedWindow returns u.Err.
func (u Unset) FocusedWindow(context.Context) (*Window, error) { return nil, u.Err }

// Windows returns u.Err.
func (u Unset) Windows(context.Context) ([]Window, error) { return nil, u.Err }

// FocusWindow returns u.Err.
func (u Unset) FocusWindow(context.Context, string) error { return u.Err }

// Validate returns u.Err.
func (u Unset) Validate(context.Context) error { return u.Err }

// Config returns no config file.
func (Unset) Config(Env) Config { return Config{} }
