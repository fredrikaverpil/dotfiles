// Package keys is `kaizen keys`: press keys in a shell surface or a window,
// and only there.
package keys

import (
	"context"
	"encoding/json/v2"
	"errors"
	"fmt"
	"io"
	"os/exec"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/fredrikaverpil/dotfiles/kaizen/internal/state"
)

// sendTimeout bounds one wtype run.
const sendTimeout = 5 * time.Second

// modifiers are the modifier names wtype takes.
var modifiers = []string{"shift", "capslock", "ctrl", "logo", "win", "alt", "altgr"}

// passwordLayers take a password: no key is ever pressed in them.
var passwordLayers = []string{state.CurtainLayer, "kaizen-polkit"}

// Command presses keys in a layer or a window, refusing unless it holds the
// keyboard before each key.
type Command struct {
	Runner state.Runner
	// wait waits for d; nil sleeps.
	wait func(ctx context.Context, d time.Duration) error
}

// Name returns keys.
func (Command) Name() string { return "keys" }

// Usage returns the usage line.
func (Command) Usage() string { return "kaizen keys (--layer NAMESPACE | --window ID) KEY..." }

// Summary says what it does.
func (Command) Summary() string {
	return "press keys (Return, ctrl+k, shift+Tab) in a shell surface or a window, " +
		"each only while it holds the keyboard"
}

// target is where the keys go: a layer namespace, else a window id.
type target struct {
	layer  string
	window int
}

func (t target) String() string {
	if t.layer != "" {
		return "layer " + t.layer
	}
	return fmt.Sprintf("window %d", t.window)
}

// chord is a key and the modifiers held while it is pressed.
type chord struct {
	mods []string
	key  string
}

// usageError is a mistake in the arguments: exit 2.
type usageError string

func (e usageError) Error() string { return string(e) }

// Run presses the keys in args' target and reports whether every key reached
// it.
func (c Command) Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	t, chords, err := c.parse(args)
	switch {
	case errors.Is(err, errHelp):
		fmt.Fprintf(stdout, "usage: %s    %s\n", c.Usage(), c.Summary())
		return 0
	case err != nil:
		fmt.Fprintf(stderr, "kaizen keys: %v\nusage: %s\n", err, c.Usage())
		return 2
	}
	if err := c.press(ctx, t, chords); err != nil {
		fmt.Fprintf(stderr, "kaizen keys: %v\n", err)
		return 1
	}
	return 0
}

// errHelp asks for the usage line.
var errHelp = errors.New("help")

// parse returns the target and the chords args name.
func (c Command) parse(args []string) (target, []chord, error) {
	var t target
	var chords []chord
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch {
		case arg == "-h", arg == "--help":
			return target{}, nil, errHelp
		case (arg == "--layer" || arg == "--window") && (t != target{}):
			return target{}, nil, usageError("--layer and --window exclude each other")
		case (arg == "--layer" || arg == "--window") && i+1 == len(args):
			return target{}, nil, usageError(arg + " needs a value")
		case arg == "--layer":
			i++
			if slices.Contains(passwordLayers, args[i]) {
				return target{}, nil, usageError(args[i] + " takes a password: kaizen keys never presses keys in it")
			}
			t.layer = args[i]
		case arg == "--window":
			i++
			id, err := strconv.Atoi(args[i])
			if err != nil || id <= 0 {
				return target{}, nil, usageError(args[i] + " is not a window id")
			}
			t.window = id
		case strings.HasPrefix(arg, "-"):
			return target{}, nil, usageError("unknown argument: " + arg)
		default:
			k, err := parseChord(arg)
			if err != nil {
				return target{}, nil, err
			}
			chords = append(chords, k)
		}
	}
	switch {
	case t == target{}:
		return target{}, nil, usageError("pass --layer or --window")
	case len(chords) == 0:
		return target{}, nil, usageError("pass the keys to press")
	}
	return t, chords, nil
}

// parseChord parses MOD+...+KEY.
func parseChord(arg string) (chord, error) {
	parts := strings.Split(arg, "+")
	if slices.Contains(parts, "") {
		return chord{}, usageError(arg + " is not a key; + is plus")
	}
	mods, key := parts[:len(parts)-1], parts[len(parts)-1]
	for _, mod := range mods {
		if !slices.Contains(modifiers, mod) {
			return chord{}, usageError(fmt.Sprintf(
				"%s in %s is not a modifier: %s",
				mod,
				arg,
				strings.Join(modifiers, " "),
			))
		}
	}
	return chord{mods: mods, key: key}, nil
}

// press presses chords in t: it lifts the curtain and, for a window, focuses
// it, and puts both back afterwards.
func (c Command) press(ctx context.Context, t target, chords []chord) (err error) {
	status, err := unlocked(ctx, c.Runner)
	if err != nil {
		return err
	}
	restore, err := state.LiftCurtain(ctx, c.Runner, status, c.wait)
	if err != nil {
		return err
	}
	defer func() {
		if restoreErr := restore(context.WithoutCancel(ctx)); restoreErr != nil {
			err = errors.Join(err, restoreErr)
		}
	}()
	if t.window != 0 {
		// Not err: the deferred give-back joins its error into press's.
		giveBack, focusErr := focusWindow(ctx, c.Runner, t.window)
		if focusErr != nil {
			return focusErr
		}
		defer func() {
			if backErr := giveBack(context.WithoutCancel(ctx)); backErr != nil {
				err = errors.Join(err, backErr)
			}
		}()
	}
	for i, k := range chords {
		if err := c.holds(ctx, t); err != nil {
			return sent(i, len(chords), err)
		}
		if err := send(ctx, c.Runner, k); err != nil {
			return sent(i, len(chords), err)
		}
	}
	return nil
}

// sent says how many of the keys were sent before err.
func sent(n, total int, err error) error {
	if n == 0 {
		return err
	}
	return fmt.Errorf("sent %d of %d keys; %w", n, total, err)
}

// unlocked returns the shell's state, failing unless it shows the session
// unlocked: a key pressed while locked goes into the password field.
func unlocked(ctx context.Context, r state.Runner) (state.Status, error) {
	status, err := state.Read(ctx, r)
	if err != nil {
		return state.Status{}, err
	}
	switch {
	case status.Lock == nil && status.PID == 0:
		return state.Status{}, fmt.Errorf("the lock state is unknown: %s is not running", state.Unit)
	case status.Lock == nil && status.Error != nil:
		return state.Status{}, fmt.Errorf("the lock state is unknown: %s", *status.Error)
	case status.Lock == nil:
		return state.Status{}, errors.New("the lock state is unknown: shell status has no lock")
	case status.Lock.Locked:
		return state.Status{}, state.ErrLocked
	}
	return status, nil
}

// holds fails unless t holds the keyboard and the session is unlocked.
func (c Command) holds(ctx context.Context, t target) error {
	if _, err := unlocked(ctx, c.Runner); err != nil {
		return err
	}
	layers, err := state.Layers(ctx, c.Runner)
	if err != nil {
		return err
	}
	// The shell's surfaces that take the keyboard are Exclusive, and niri
	// gives them the keyboard over any window.
	var holders []string
	for _, l := range layers {
		if l.KeyboardInteractivity == "Exclusive" && !slices.Contains(holders, l.Namespace) {
			holders = append(holders, l.Namespace)
		}
	}
	slices.Sort(holders)
	if t.layer != "" {
		if slices.Equal(holders, []string{t.layer}) {
			return nil
		}
		return fmt.Errorf("%v does not hold the keyboard: %s", t, describe(holders))
	}
	if len(holders) > 0 {
		return fmt.Errorf("%v does not hold the keyboard: %s", t, describe(holders))
	}
	w, err := focusedWindow(ctx, c.Runner)
	switch {
	case err != nil:
		return err
	case w == nil:
		return fmt.Errorf("%v does not hold the keyboard: no window has focus", t)
	case w.ID != t.window:
		return fmt.Errorf("%v does not hold the keyboard: window %d (%s) has focus", t, w.ID, w.AppID)
	}
	return nil
}

// describe names the layers holding the keyboard.
func describe(holders []string) string {
	switch len(holders) {
	case 0:
		return "no layer holds it"
	case 1:
		return "layer " + holders[0] + " holds it"
	}
	return "layers " + strings.Join(holders, ", ") + " hold it"
}

// window is a window in `niri msg -j focused-window`.
type window struct {
	ID    int    `json:"id"`
	AppID string `json:"app_id"`
}

// focusedWindow returns the focused window, nil when none is.
func focusedWindow(ctx context.Context, r state.Runner) (*window, error) {
	out, err := r.Run(ctx, "niri", "msg", "-j", "focused-window")
	if err != nil {
		return nil, fmt.Errorf("niri msg focused-window: %v", err)
	}
	var w *window
	if err := json.Unmarshal(out, &w); err != nil {
		return nil, fmt.Errorf("niri msg focused-window: %v", err)
	}
	return w, nil
}

// focusWindow focuses window id and returns the function that gives focus back
// to the window that had it, which does nothing when none or id had it.
func focusWindow(ctx context.Context, r state.Runner, id int) (giveBack func(ctx context.Context) error, err error) {
	previous, err := focusedWindow(ctx, r)
	if err != nil {
		return nil, err
	}
	if err := focus(ctx, r, id); err != nil {
		return nil, err
	}
	if previous == nil || previous.ID == id {
		return func(context.Context) error { return nil }, nil
	}
	return func(ctx context.Context) error { return focus(ctx, r, previous.ID) }, nil
}

// focus focuses window id.
func focus(ctx context.Context, r state.Runner, id int) error {
	if _, err := r.Run(ctx, "niri", "msg", "action", "focus-window", "--id", strconv.Itoa(id)); err != nil {
		return fmt.Errorf("niri msg action focus-window: %v", err)
	}
	return nil
}

// send presses k with wtype.
func send(ctx context.Context, r state.Runner, k chord) error {
	ctx, cancel := context.WithTimeout(ctx, sendTimeout)
	defer cancel()
	var args []string
	for _, mod := range k.mods {
		args = append(args, "-M", mod)
	}
	args = append(args, "-k", k.key)
	for _, mod := range slices.Backward(k.mods) {
		args = append(args, "-m", mod)
	}
	_, err := r.Run(ctx, "wtype", args...)
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) && len(exitErr.Stderr) > 0 {
		return fmt.Errorf("wtype: %v: %s", err, strings.TrimSpace(string(exitErr.Stderr)))
	}
	if err != nil {
		return fmt.Errorf("wtype: %v", err)
	}
	return nil
}
