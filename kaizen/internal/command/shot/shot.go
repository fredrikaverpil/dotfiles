// Package shot is `kaizen shot`: capture an output for verification.
package shot

import (
	"context"
	"encoding/json/v2"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/fredrikaverpil/dotfiles/kaizen/internal/state"
)

// maxEdge is the longest edge of a capture, so a 4K output costs no more to
// read than a laptop panel. A region at --full is the way to inspect pixels.
const maxEdge = 1600

// captureTimeout bounds grim: DPMS-off leaves no frames to capture, and grim
// then waits for ever.
const captureTimeout = 10 * time.Second

// maxAge is how long a capture in the cache lives: disposable, so a day
// instead of the cache's 30.
const maxAge = 24 * time.Hour

// regionPattern is a WxH+X+Y region.
var regionPattern = regexp.MustCompile(`^([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)$`)

// Command captures an output, or its bar or a region of it.
type Command struct {
	Runner state.Runner
	// CacheDir is $XDG_CACHE_HOME, else ~/.cache.
	CacheDir string
	// now returns the time; nil is the clock.
	now func() time.Time
	// wait waits for d; nil sleeps.
	wait func(ctx context.Context, d time.Duration) error
}

// Name returns shot.
func (Command) Name() string { return "shot" }

// Usage returns the usage line.
func (Command) Usage() string { return "kaizen shot [--bar | WxH+X+Y] [--full] [-o FILE] [OUTPUT]" }

// Summary says what it does.
func (Command) Summary() string {
	return "capture an output for verification, scaled to 1600 px unless --full; prints the file"
}

// options are the parsed arguments.
type options struct {
	bar    bool
	full   bool
	region string
	file   string
	output string
}

// usageError is a mistake in the arguments: exit 2.
type usageError string

func (e usageError) Error() string { return string(e) }

// Run captures an output and prints the file. It lifts the curtain for the
// capture and puts it back, and refuses while the session is locked.
func (c Command) Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	var opts options
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch {
		case arg == "-h", arg == "--help":
			fmt.Fprintf(stdout, "usage: %s    %s\n", c.Usage(), c.Summary())
			return 0
		case arg == "--bar":
			opts.bar = true
		case arg == "--full":
			opts.full = true
		case arg == "-o" && i+1 < len(args):
			i++
			opts.file = args[i]
		case arg == "-o":
			fmt.Fprintf(stderr, "kaizen shot: -o needs a file\nusage: %s\n", c.Usage())
			return 2
		case strings.HasPrefix(arg, "-"),
			regionPattern.MatchString(arg) && opts.region != "",
			!regionPattern.MatchString(arg) && opts.output != "":
			fmt.Fprintf(stderr, "kaizen shot: unknown argument: %s\nusage: %s\n", arg, c.Usage())
			return 2
		case regionPattern.MatchString(arg):
			opts.region = arg
		default:
			opts.output = arg
		}
	}
	if opts.bar && opts.region != "" {
		fmt.Fprintf(stderr, "kaizen shot: --bar and a region exclude each other\nusage: %s\n", c.Usage())
		return 2
	}
	file, err := c.shoot(ctx, opts, stderr)
	if file != "" {
		fmt.Fprintln(stdout, file)
	}
	var usage usageError
	switch {
	case errors.As(err, &usage):
		fmt.Fprintf(stderr, "kaizen shot: %v\n", err)
		return 2
	case err != nil:
		fmt.Fprintf(stderr, "kaizen shot: %v\n", err)
		return 1
	}
	return 0
}

// shoot captures the output opts names and returns the file. It returns the
// file with an error when the capture succeeded but the curtain stayed down.
func (c Command) shoot(ctx context.Context, opts options, stderr io.Writer) (file string, err error) {
	screen, err := readScreen(ctx, c.Runner)
	if err != nil {
		return "", err
	}
	name, err := screen.pick(opts.output)
	if err != nil {
		return "", err
	}
	status, err := state.Read(ctx, c.Runner)
	if err != nil {
		return "", err
	}
	if status.Lock != nil && status.Lock.Locked {
		return "", state.ErrLocked
	}
	o := screen.outputs[name]
	if o.Logical == nil {
		return "", fmt.Errorf("%s is off", name)
	}
	// x y width height, in the output's logical pixels.
	x, y, w, h := 0, 0, o.Logical.Width, o.Logical.Height
	suffix := ""
	switch {
	case opts.bar:
		// The bar is anchored to the top of each output; niri reports no layer
		// geometry, so take its height from the shell.
		if status.BarHeight == nil {
			return "", fmt.Errorf("the shell did not report the bar's height: %s", unknown(status))
		}
		h = *status.BarHeight
		suffix = "-bar"
	case opts.region != "":
		if w, h, x, y, err = parseRegion(opts.region); err != nil {
			return "", err
		}
		if x+w > o.Logical.Width || y+h > o.Logical.Height {
			return "", usageError(fmt.Sprintf(
				"%s is outside %s, which is %dx%d",
				opts.region,
				name,
				o.Logical.Width,
				o.Logical.Height,
			))
		}
		suffix = "-region"
	}
	// grim's -s sets pixels per logical pixel.
	args := []string{"-g", fmt.Sprintf("%d,%d %dx%d", o.Logical.X+x, o.Logical.Y+y, w, h)}
	size := fmt.Sprintf("%dx%d", w, h)
	if edge := max(w, h); !opts.full && edge > maxEdge {
		// Rounded up, since grim truncates the scaled size.
		factor := fmt.Sprintf("%.6f", float64(maxEdge)/float64(edge)+0.0000005)
		f, err := strconv.ParseFloat(factor, 64)
		if err != nil {
			return "", err
		}
		args = append(args, "-s", factor)
		size = fmt.Sprintf("%dx%d", int(float64(w)*f), int(float64(h)*f))
	}
	file = opts.file
	if file == "" {
		if file, err = c.cacheFile(name + suffix); err != nil {
			return "", err
		}
	}
	// grim cannot capture an output through the curtain. Lift it for the
	// capture and put it back, whatever the capture does.
	restore, err := state.LiftCurtain(ctx, c.Runner, status, c.wait)
	if err != nil {
		return "", err
	}
	defer func() {
		if openErr := restore(context.WithoutCancel(ctx)); openErr != nil {
			err = errors.Join(err, openErr)
		}
	}()
	if err := capture(ctx, c.Runner, append(args, file)); err != nil {
		return "", err
	}
	fmt.Fprintf(stderr, "kaizen shot: captured %s%s at %s\n", name, suffix, size)
	return file, nil
}

// cacheFile returns a new file for a capture of what, under the cache, after
// deleting the captures there older than maxAge.
func (c Command) cacheFile(what string) (string, error) {
	now := time.Now()
	if c.now != nil {
		now = c.now()
	}
	dir := filepath.Join(c.CacheDir, "kaizen-shell", "shots")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return "", err
	}
	entries, err := os.ReadDir(dir)
	if err != nil {
		return "", err
	}
	for _, entry := range entries {
		if ok, _ := filepath.Match("shot-*.png", entry.Name()); !ok || entry.IsDir() {
			continue
		}
		info, err := entry.Info()
		if err != nil {
			return "", err
		}
		if now.Sub(info.ModTime()) > maxAge {
			if err := os.Remove(filepath.Join(dir, entry.Name())); err != nil {
				return "", err
			}
		}
	}
	return filepath.Join(dir, fmt.Sprintf("shot-%s-%s.png", what, now.Format("20060102T150405"))), nil
}

// capture runs grim with args.
func capture(ctx context.Context, r state.Runner, args []string) error {
	ctx, cancel := context.WithTimeout(ctx, captureTimeout)
	defer cancel()
	_, err := r.Run(ctx, "grim", args...)
	if errors.Is(ctx.Err(), context.DeadlineExceeded) {
		return fmt.Errorf("grim: no frame within %v; are the outputs off?", captureTimeout)
	}
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) && len(exitErr.Stderr) > 0 {
		return fmt.Errorf("grim: %v: %s", err, strings.TrimSpace(string(exitErr.Stderr)))
	}
	if err != nil {
		return fmt.Errorf("grim: %v", err)
	}
	return nil
}

// parseRegion returns the width, height, x and y of a WxH+X+Y region.
func parseRegion(region string) (w, h, x, y int, err error) {
	var n [4]int
	for i, s := range regionPattern.FindStringSubmatch(region)[1:] {
		if n[i], err = strconv.Atoi(s); err != nil {
			return 0, 0, 0, 0, usageError(fmt.Sprintf("%s is not a region", region))
		}
	}
	return n[0], n[1], n[2], n[3], nil
}

// unknown says why status lacks the shell's facts.
func unknown(status state.Status) string {
	switch {
	case status.PID == 0:
		return state.Unit + " is not running"
	case status.Error != nil:
		return *status.Error
	}
	return "shell status has no barHeight"
}

// output is an output in `niri msg -j outputs`.
type output struct {
	Name string `json:"name"`
	// Logical is nil while the output is off.
	Logical *logical `json:"logical"`
}

// logical is an output's place and size in the layout, in logical pixels.
type logical struct {
	X      int `json:"x"`
	Y      int `json:"y"`
	Width  int `json:"width"`
	Height int `json:"height"`
}

// screen is what niri shows: its outputs, the focused one, and those holding
// an open panel, menu or launcher.
type screen struct {
	outputs map[string]output
	names   []string
	focused string
	open    []string
}

// readScreen reads the outputs and their surfaces from niri.
func readScreen(ctx context.Context, r state.Runner) (screen, error) {
	out, err := r.Run(ctx, "niri", "msg", "-j", "outputs")
	if err != nil {
		return screen{}, fmt.Errorf("niri msg outputs: %v", err)
	}
	var outputs map[string]output
	if err := json.Unmarshal(out, &outputs); err != nil {
		return screen{}, fmt.Errorf("niri msg outputs: %v", err)
	}
	s := screen{outputs: make(map[string]output, len(outputs))}
	for _, o := range outputs {
		s.outputs[o.Name] = o
		s.names = append(s.names, o.Name)
	}
	slices.Sort(s.names)
	out, err = r.Run(ctx, "niri", "msg", "-j", "focused-output")
	if err != nil {
		return screen{}, fmt.Errorf("niri msg focused-output: %v", err)
	}
	var focused *output
	if err := json.Unmarshal(out, &focused); err != nil {
		return screen{}, fmt.Errorf("niri msg focused-output: %v", err)
	}
	if focused != nil {
		s.focused = focused.Name
	}
	layers, err := state.Layers(ctx, r)
	if err != nil {
		return screen{}, err
	}
	// An open panel, menu or launcher holds exclusive keyboard focus on its
	// output.
	for _, l := range layers {
		if l.KeyboardInteractivity == "Exclusive" && !slices.Contains(s.open, l.Output) {
			s.open = append(s.open, l.Output)
		}
	}
	slices.Sort(s.open)
	return s, nil
}

// pick returns the output to capture: name, else the only output, else the
// only one holding an open surface. The focused output follows the user, not
// the surface under test, so it is never the default.
func (s screen) pick(name string) (string, error) {
	if name == "" {
		switch {
		case len(s.names) == 1:
			name = s.names[0]
		case len(s.open) == 1:
			name = s.open[0]
		}
	}
	if name != "" && slices.Contains(s.names, name) {
		return name, nil
	}
	var b strings.Builder
	if name != "" {
		fmt.Fprintf(&b, "no output named %s; the outputs are:", name)
	} else {
		b.WriteString("pass the output to capture:")
	}
	for _, n := range s.names {
		var notes []string
		if n == s.focused {
			notes = append(notes, "focused")
		}
		if slices.Contains(s.open, n) {
			notes = append(notes, "open surface")
		}
		fmt.Fprintf(&b, "\n  %s", n)
		if len(notes) > 0 {
			fmt.Fprintf(&b, " (%s)", strings.Join(notes, " "))
		}
	}
	return "", usageError(b.String())
}
