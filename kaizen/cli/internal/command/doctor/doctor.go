// Package doctor is `kaizen doctor`: what is wrong with the desktop that
// nothing on screen shows.
package doctor

import (
	"cmp"
	"context"
	"encoding/json/jsontext"
	"encoding/json/v2"
	"errors"
	"fmt"
	"io"
	"os/exec"
	"regexp"
	"slices"
	"strings"
	"time"
	"unicode"

	"github.com/fredrikaverpil/dotfiles/kaizen/cli/internal/state"
)

// The units log at priority 6 with the level in the text: Quickshell and dcal
// lead with it (`  WARN scene:`), other tools start with it after at most a Go
// log timestamp and a word (`error: …`, `… systray error: …`), and Go's slog
// writes a logfmt field (`time=… level=WARN msg=…`). systemd's own lines about
// the units, and the Go daemons' lines, carry a real priority.
var (
	leadingLevel = regexp.MustCompile(`^\s*(DEBUG|INFO|WARN|ERROR|FATAL)\b`)
	wordLevel    = regexp.MustCompile(
		`(?i)^(\d{4}/\d\d/\d\d \d\d:\d\d:\d\d )?(\S+ )?(?P<level>warn(ing)?|error|fatal|crit(ical)?|panic)\b`,
	)
	fieldLevel = regexp.MustCompile(`(?i)^(time=\S+ )?level=(?P<level>warn(ing)?|error|fatal|crit(ical)?|panic)\b`)
)

// Electron tray items send IconPixmap only and fail a Get of IconName or
// IconThemePath, which Quickshell reads again on each NewIcon. It logs the
// property, then the QDBusError on the next line.
var (
	trayProperty = regexp.MustCompile(`^\s*WARN quickshell\.dbus\.properties: Error updating property ` +
		`org\.freedesktop\.StatusNotifierItem-[0-9]+-[0-9]+/StatusNotifierItem/org\.kde\.StatusNotifierItem:` +
		`(IconName|IconThemePath)$`)
	trayError = regexp.MustCompile(`^\s*WARN quickshell\.dbus\.properties: QDBusError\(`)
)

// timeField is slog's time, which the journal has.
var timeField = regexp.MustCompile(`^time=\S+ `)

// Command reports the kaizen units' warnings and errors, and what is out of
// order.
type Command struct {
	Runner state.Runner
	// Home is the user's home directory.
	Home string
	// Getenv returns an environment variable: PATH and the XDG base
	// directories.
	Getenv func(string) string
	// now returns the time; nil is the clock.
	now func() time.Time
	// location is where the report's times are local to; nil is time.Local.
	location *time.Location
	// proc is where the processes are; empty is /proc.
	proc string
}

// Name returns doctor.
func (Command) Name() string { return "doctor" }

// Usage returns the usage line.
func (Command) Usage() string { return "kaizen doctor [--json] [JOURNALCTL_ARGS...]" }

// Summary says what it does.
func (Command) Summary() string {
	return "report the kaizen units' warnings and errors, and what is out of order"
}

// finding is a check's or a log line's finding.
type finding struct {
	Source string `json:"source"`
	// Name is the check's stable id; log for a log line.
	Name    string `json:"name"`
	Level   string `json:"level"`
	Unit    string `json:"unit"`
	Message string `json:"message"`
	// Hint is the fix, if any.
	Hint  string `json:"hint,omitzero"`
	Count int    `json:"count"`
	// First and Last are milliseconds since the epoch.
	First int64 `json:"first"`
	Last  int64 `json:"last"`
}

// report is the findings, sorted as Text lists them.
type report struct {
	Findings []finding `json:"findings"`
	Text     string    `json:"text"`
}

// Run prints the report. Without journalctl arguments it covers each kaizen
// unit's current run plus the checks; with them (-b -1, --since -1h) it covers
// that part of the journal, without checks. --json prints { findings, text }.
func (c Command) Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	if len(args) > 0 && (args[0] == "-h" || args[0] == "--help") {
		fmt.Fprintf(stdout, "usage: %s    %s\n", c.Usage(), c.Summary())
		return 0
	}
	asJSON := false
	var journalArgs []string
	for _, arg := range args {
		if arg == "--json" {
			asJSON = true
			continue
		}
		journalArgs = append(journalArgs, arg)
	}
	r, err := c.report(ctx, journalArgs)
	if err != nil {
		fmt.Fprintf(stderr, "kaizen doctor: %v\n", err)
		return 1
	}
	if !asJSON {
		fmt.Fprintln(stdout, r.Text)
		return 0
	}
	out, err := json.Marshal(r, jsontext.AllowInvalidUTF8(true))
	if err != nil {
		fmt.Fprintf(stderr, "kaizen doctor: %v\n", err)
		return 1
	}
	fmt.Fprintf(stdout, "%s\n", out)
	return 0
}

// report gathers the findings.
func (c Command) report(ctx context.Context, journalArgs []string) (report, error) {
	now := time.Now()
	if c.now != nil {
		now = c.now()
	}
	var units []unit
	var checks []check
	var out []byte
	var err error
	if len(journalArgs) > 0 {
		args := append(
			[]string{"--user", "--unit", "kaizen-*", "--boot", "--lines", "all", "--output", "json", "--no-pager"},
			journalArgs...,
		)
		if out, err = run(ctx, c.Runner, "journalctl", args...); err != nil {
			return report{}, err
		}
	} else {
		if units, err = readUnits(ctx, c.Runner); err != nil {
			return report{}, err
		}
		checks = c.check(ctx, units)
		ids := make([]string, 0, len(units))
		for _, u := range units {
			ids = append(ids, u.invocationID)
		}
		if out, err = readRuns(ctx, c.Runner, ids); err != nil {
			return report{}, err
		}
	}
	entries, err := parseJournal(out)
	if err != nil {
		return report{}, err
	}
	findings := make([]finding, 0, len(checks))
	for _, ch := range checks {
		findings = append(findings, finding{
			Source:  "check",
			Name:    ch.name,
			Level:   ch.level,
			Unit:    ch.unit,
			Message: strings.TrimRightFunc(ch.message, unicode.IsSpace),
			Hint:    ch.hint,
			Count:   1,
			First:   now.UnixMilli(),
			Last:    now.UnixMilli(),
		})
	}
	findings = append(findings, logFindings(entries, units)...)
	slices.SortStableFunc(findings, func(a, b finding) int {
		return cmp.Or(
			cmp.Compare(rank(a.Level == "ERROR"), rank(b.Level == "ERROR")),
			cmp.Compare(rank(a.Source == "check"), rank(b.Source == "check")),
			cmp.Compare(b.Last, a.Last),
		)
	})
	return report{Findings: findings, Text: c.text(findings)}, nil
}

// rank sorts first what is true.
func rank(first bool) int {
	if first {
		return 0
	}
	return 1
}

// readRuns returns the journal of the runs ids, skipping empty ones. The user
// manager tags its own lines about a run USER_INVOCATION_ID.
func readRuns(ctx context.Context, r state.Runner, ids []string) ([]byte, error) {
	var matches []string
	for _, id := range ids {
		if id == "" {
			continue
		}
		if len(matches) > 0 {
			matches = append(matches, "+")
		}
		matches = append(matches, "_SYSTEMD_INVOCATION_ID="+id, "+", "USER_INVOCATION_ID="+id)
	}
	if len(matches) == 0 {
		return nil, nil
	}
	return run(ctx, r, "journalctl", append([]string{"--user", "--lines", "all", "--output", "json", "--no-pager"}, matches...)...)
}

// logFindings groups the warnings and errors among entries by unit, level and
// message.
func logFindings(entries []state.Entry, units []unit) []finding {
	var failed []string
	for _, u := range units {
		if u.activeState == "failed" {
			failed = append(failed, u.id)
		}
	}
	type key struct{ unit, level, message string }
	groups := map[key]*finding{}
	var keys []key
	for i, e := range entries {
		if skipped(entries, i) {
			continue
		}
		level := severity(e)
		if level == "" {
			continue
		}
		// The failed-unit check reports what systemd says about the failure.
		if e.Identifier == "systemd" && slices.Contains(failed, e.UserUnit) {
			continue
		}
		k := key{
			unit:    strings.TrimSuffix(cmp.Or(e.UserUnit, e.ProcessUnit, e.Identifier, "?"), ".service"),
			level:   level,
			message: trimMessage(e.Message),
		}
		ms := e.Time.UnixMilli()
		f, ok := groups[k]
		if !ok {
			f = &finding{Source: "log", Name: "log", Level: k.level, Unit: k.unit, Message: k.message, First: ms, Last: ms}
			groups[k] = f
			keys = append(keys, k)
		}
		f.Count++
		f.First = min(f.First, ms)
		f.Last = max(f.Last, ms)
	}
	slices.SortFunc(keys, func(a, b key) int {
		return cmp.Or(cmp.Compare(a.unit, b.unit), cmp.Compare(a.level, b.level), cmp.Compare(a.message, b.message))
	})
	findings := make([]finding, 0, len(keys))
	for _, k := range keys {
		findings = append(findings, *groups[k])
	}
	return findings
}

// skipped reports that entries[i] is an Electron tray item's failed property
// read, or the QDBusError its process logs next.
func skipped(entries []state.Entry, i int) bool {
	e := entries[i]
	return ignored(e) || i > 0 && e.PID == entries[i-1].PID && ignored(entries[i-1]) && trayError.MatchString(e.Message)
}

// ignored reports an Electron tray item's failed property read.
func ignored(e state.Entry) bool {
	return trayProperty.MatchString(e.Message)
}

// trimMessage returns a message without leading space and slog's time.
func trimMessage(message string) string {
	return timeField.ReplaceAllString(strings.TrimLeftFunc(message, unicode.IsSpace), "")
}

// severity returns ERROR or WARN for an entry to report, else "".
func severity(e state.Entry) string {
	level := textLevel(e.Message)
	switch {
	case level == "ERROR", level == "FATAL", e.Priority <= 3:
		return "ERROR"
	case level == "WARN", e.Priority == 4:
		return "WARN"
	}
	return ""
}

// textLevel returns the level a message's text names.
func textLevel(message string) string {
	if m := leadingLevel.FindStringSubmatch(message); m != nil {
		return m[1]
	}
	for _, pattern := range []*regexp.Regexp{wordLevel, fieldLevel} {
		m := pattern.FindStringSubmatch(message)
		if m == nil {
			continue
		}
		if strings.HasPrefix(strings.ToUpper(m[pattern.SubexpIndex("level")]), "WARN") {
			return "WARN"
		}
		return "ERROR"
	}
	return "INFO"
}

// text returns the report as text: a summary, then each finding with its
// message indented and its hint under it.
func (c Command) text(findings []finding) string {
	errs := 0
	for _, f := range findings {
		if f.Level == "ERROR" {
			errs++
		}
	}
	var counts []string
	if errs > 0 {
		counts = append(counts, plural(errs, "error"))
	}
	if len(findings) > errs {
		counts = append(counts, plural(len(findings)-errs, "warning"))
	}
	if len(counts) == 0 {
		return "No errors or warnings"
	}
	blocks := make([]string, 0, len(findings))
	for _, f := range findings {
		level := f.Level
		if level == "WARN" {
			level = "WARN "
		}
		when := "check"
		if f.Source != "check" {
			when = c.times(f.Count, f.First, f.Last)
		}
		lines := strings.Split(f.Message, "\n")
		for i, line := range lines {
			if line != "" {
				lines[i] = "  " + line
			}
		}
		if f.Hint != "" {
			lines = append(lines, "  hint: "+f.Hint)
		}
		blocks = append(blocks, level+" "+f.Unit+"  "+when+"\n"+strings.Join(lines, "\n"))
	}
	return strings.Join(counts, ", ") + "\n\n" + strings.Join(blocks, "\n")
}

// times returns ×count when more than one, then the time of day of first and,
// when it differs, of last; first and last are milliseconds since the epoch.
func (c Command) times(count int, first, last int64) string {
	when := ""
	if count > 1 {
		when = fmt.Sprintf("×%d  ", count)
	}
	from, to := c.clock(first), c.clock(last)
	if from == to {
		return when + from
	}
	return when + from + "–" + to
}

// clock returns the time of day of ms milliseconds since the epoch.
func (c Command) clock(ms int64) string {
	return time.UnixMilli(ms).In(cmp.Or(c.location, time.Local)).Format("15:04:05")
}

// plural returns n and word, plural unless n is 1.
func plural(n int, word string) string {
	if n == 1 {
		return fmt.Sprintf("%d %s", n, word)
	}
	return fmt.Sprintf("%d %ss", n, word)
}

// run runs name with args and returns its stdout; an error carries its
// stderr.
func run(ctx context.Context, r state.Runner, name string, args ...string) ([]byte, error) {
	out, err := r.Run(ctx, name, args...)
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) && len(exitErr.Stderr) > 0 {
		return nil, fmt.Errorf("%s: %v: %s", name, err, strings.TrimSpace(string(exitErr.Stderr)))
	}
	if err != nil {
		return nil, fmt.Errorf("%s: %v", name, err)
	}
	return out, nil
}
