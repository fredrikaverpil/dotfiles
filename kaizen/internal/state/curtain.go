package state

import (
	"context"
	"fmt"
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
