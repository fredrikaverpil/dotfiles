package state

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"time"

	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/compositor"
)

// CurtainLayer is the curtain's layer namespace.
const CurtainLayer = "kaizen-curtain"

// The curtain's surface leaves with the next frame, which its status does not
// show: wait up to 2.5 s for the compositor to drop it.
const (
	curtainAttempts = 25
	curtainDelay    = 100 * time.Millisecond
)

// CurtainUp reports whether s shows the curtain up.
func (s Status) CurtainUp() bool {
	return s.Curtain != nil && s.Curtain.Active
}

// OpenCurtain puts the curtain of the shell at pid back up after a capture: it
// hides the desktop while nobody is at it.
func OpenCurtain(ctx context.Context, r Runner, pid int) error {
	_, answer, err := call(ctx, r, pid, "curtain", "open")
	if err != nil {
		return fmt.Errorf("the curtain is down: %v", err)
	}
	if answer != "shown" {
		return fmt.Errorf("the curtain is down: curtain open: %s", answer)
	}
	return nil
}

// CloseCurtain lifts the curtain of the shell at pid, which hides the outputs
// from a capture.
func CloseCurtain(ctx context.Context, r Runner, pid int) error {
	_, answer, err := call(ctx, r, pid, "curtain", "close")
	if err != nil {
		return fmt.Errorf("the curtain is up: %v", err)
	}
	if answer != "hidden" {
		return fmt.Errorf("the curtain is up: curtain close: %s", answer)
	}
	return nil
}

// LiftCurtain lifts the curtain when status shows it up, and waits until c
// shows no curtain surface: it hides the outputs from a capture and takes
// every key. It returns the function that puts the curtain back, which does
// nothing when it was down. When the surface stays, it puts the curtain back
// itself. A nil wait sleeps.
func LiftCurtain(
	ctx context.Context,
	r Runner,
	c compositor.Compositor,
	status Status,
	wait func(ctx context.Context, d time.Duration) error,
) (restore func(ctx context.Context) error, err error) {
	if !status.CurtainUp() {
		return func(context.Context) error { return nil }, nil
	}
	if wait == nil {
		wait = sleep
	}
	if err := CloseCurtain(ctx, r, status.PID); err != nil {
		return nil, err
	}
	restore = func(ctx context.Context) error { return OpenCurtain(ctx, r, status.PID) }
	if err := awaitCurtainGone(ctx, c, wait); err != nil {
		return nil, errors.Join(err, restore(context.WithoutCancel(ctx)))
	}
	return restore, nil
}

// awaitCurtainGone waits until c shows no curtain surface, failing when it
// stays.
func awaitCurtainGone(ctx context.Context, c compositor.Compositor, wait wait) error {
	for attempt := 1; ; attempt++ {
		layers, err := c.Layers(ctx)
		if err != nil {
			return err
		}
		if !slices.ContainsFunc(layers, func(l compositor.Layer) bool { return l.Namespace == CurtainLayer }) {
			return nil
		}
		if attempt == curtainAttempts {
			return errors.New("the curtain's surface did not leave the outputs")
		}
		if err := wait(ctx, curtainDelay); err != nil {
			return err
		}
	}
}
