package state

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
)

// Unlocked retries a shell that does not answer for about 5 s.
const (
	unlockedAttempts = 25
	unlockedDelay    = 200 * time.Millisecond
)

// Reload waits about 20 s for the shell to load its config.
const (
	loadAttempts = 100
	loadDelay    = 200 * time.Millisecond
)

// Quickshell's lines when it has loaded its config, or failed to.
const (
	loadedLine = "INFO: Configuration Loaded"
	failedLine = "ERROR: Failed to load configuration"
)

// ErrLocked reports that the session is locked. The compositor keeps the lock
// after its client dies, so the shell must not stop while locked.
var ErrLocked = errors.New("the session is locked")

// ErrLoadFailed reports that the shell failed to load its config.
var ErrLoadFailed = errors.New("the shell failed to load its config")

// wait waits for d, or until ctx is done.
type wait func(ctx context.Context, d time.Duration) error

// sleep is a wait on the clock.
func sleep(ctx context.Context, d time.Duration) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-time.After(d):
		return nil
	}
}

// Unlocked returns the shell's state unless it may hold the session lock. It
// fails with ErrLocked while the session is locked, and with an error while the
// lock state stays unknown. A shell that is down holds no lock, nor does one
// that stays not ready: it answers so while it loads its config, and for good
// once that failed, with no lock surface.
func Unlocked(ctx context.Context, r Runner) (Status, error) {
	return unlocked(ctx, r, sleep)
}

func unlocked(ctx context.Context, r Runner, wait wait) (Status, error) {
	status, err := readUnit(ctx, r)
	if err != nil {
		return Status{}, err
	}
	if status.PID == 0 {
		return status, nil
	}
	for attempt := 1; ; attempt++ {
		shell, err := query(ctx, r, status.PID)
		if err == nil {
			status.answered(shell)
			break
		}
		if attempt == unlockedAttempts {
			if !errors.Is(err, ErrNotReady) {
				return Status{}, fmt.Errorf("the lock state is unknown: %v", err)
			}
			status.Error = new(err.Error())
			return status, nil
		}
		if err := wait(ctx, unlockedDelay); err != nil {
			return Status{}, err
		}
	}
	switch {
	case status.Lock == nil:
		return Status{}, errors.New("the lock state is unknown: shell status has no lock")
	case status.Lock.Locked:
		return Status{}, ErrLocked
	}
	return status, nil
}

// Reload applies the shell's files: a hot reload of a shell that answers, else,
// or with restart, a restart of its unit after reloading the user manager. It
// waits until the shell has loaded its config and answers, puts the curtain
// back up if status had it up, and returns what the unit logged meanwhile;
// ErrLoadFailed when the config failed to load. status is the shell's state,
// from Unlocked.
func Reload(ctx context.Context, r Runner, status Status, restart bool) ([]Entry, error) {
	return reload(ctx, r, status, restart, sleep)
}

func reload(ctx context.Context, r Runner, status Status, restart bool, wait wait) ([]Entry, error) {
	cursor, err := Cursor(ctx, r)
	if err != nil {
		return nil, err
	}
	if restart || !status.Ready {
		err = restartUnit(ctx, r)
	} else {
		err = hotReload(ctx, r, status.PID)
	}
	if err != nil {
		return nil, err
	}
	for range loadAttempts {
		entries, err := Journal(ctx, r, cursor)
		if err != nil {
			return nil, err
		}
		loaded, err := lastLoad(entries)
		if err != nil {
			return entries, err
		}
		now, err := Read(ctx, r)
		if err != nil {
			return entries, err
		}
		if loaded && now.Ready {
			if curtainUp(status) && !curtainUp(now) {
				if err := openCurtain(ctx, r, now.PID); err != nil {
					return entries, err
				}
			}
			// With what it logged until it answered.
			return Journal(ctx, r, cursor)
		}
		if now.Active == "failed" {
			return entries, fmt.Errorf("%s failed", Unit)
		}
		if err := wait(ctx, loadDelay); err != nil {
			return entries, err
		}
	}
	entries, err := Journal(ctx, r, cursor)
	if err != nil {
		return nil, err
	}
	return entries, fmt.Errorf("%s did not load its config", Unit)
}

// lastLoad reports whether entries show the shell's config loaded, by their
// last load: ErrLoadFailed when it failed, false while none finished.
func lastLoad(entries []Entry) (bool, error) {
	for i := len(entries) - 1; i >= 0; i-- {
		switch strings.TrimSpace(entries[i].Message) {
		case loadedLine:
			return true, nil
		case failedLine:
			return false, ErrLoadFailed
		}
	}
	return false, nil
}

// restartUnit restarts the shell's unit, after reloading the user manager so
// an edited unit applies. Resetting it first lets a unit that hit its start
// limit start.
func restartUnit(ctx context.Context, r Runner) error {
	for _, args := range [][]string{
		{"--user", "daemon-reload"},
		{"--user", "reset-failed", Unit},
		{"--user", "restart", Unit},
	} {
		if _, err := r.Run(ctx, "systemctl", args...); err != nil {
			return fmt.Errorf("systemctl %s: %v", strings.Join(args[1:], " "), err)
		}
	}
	return nil
}

// curtainUp reports whether status shows the curtain up.
func curtainUp(status Status) bool {
	return status.Curtain != nil && status.Curtain.Active
}

// openCurtain puts the curtain of the shell at pid back up: a reload or a
// restart takes it down, and it hides the desktop while nobody is at it.
func openCurtain(ctx context.Context, r Runner, pid int) error {
	_, answer, err := call(ctx, r, pid, "curtain", "open")
	if err != nil {
		return fmt.Errorf("the curtain is down: %v", err)
	}
	if answer != "shown" {
		return fmt.Errorf("the curtain is down: curtain open: %s", answer)
	}
	return nil
}

// hotReload reloads the config of the shell at pid in place.
func hotReload(ctx context.Context, r Runner, pid int) error {
	_, answer, err := call(ctx, r, pid, "shell", "reload")
	if err != nil {
		return err
	}
	if answer != "" {
		return errors.New(answer)
	}
	return nil
}
