// Package compositor reads and drives the session's compositor.
package compositor

import (
	"context"
)

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
	// FocusWindow focuses window id.
	FocusWindow(ctx context.Context, id string) error
	// Validate checks the compositor's config, returning its report when
	// it fails.
	Validate(ctx context.Context) error
}

// Layer is a layer surface.
type Layer struct {
	Namespace string
	Output    string
	// Exclusive reports exclusive keyboard interactivity. The shell's
	// surfaces that take the keyboard are exclusive.
	Exclusive bool
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
