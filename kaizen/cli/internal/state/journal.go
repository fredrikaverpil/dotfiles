package state

import (
	"bytes"
	"context"
	"encoding/json/jsontext"
	"encoding/json/v2"
	"errors"
	"fmt"
	"io"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// colour matches a terminal colour sequence, which Quickshell writes around
// its levels.
var colour = regexp.MustCompile(`\x1b\[[0-9;]*m`)

// level matches the level Quickshell writes at the start of a message.
var level = regexp.MustCompile(`^\s*(DEBUG|INFO|WARN|ERROR|FATAL)\b`)

// Entry is a journal entry about a unit: its process's, or systemd's about the
// unit.
type Entry struct {
	// Message is the entry's text without terminal colours.
	Message string
	// Priority is the entry's syslog priority.
	Priority int
	// Time is when it was logged.
	Time time.Time
	// PID is the process that logged it.
	PID string
	// Identifier is its syslog identifier: the program, or systemd.
	Identifier string
	// UserUnit is the unit systemd's entry is about.
	UserUnit string
	// ProcessUnit is the user unit of the process that logged it.
	ProcessUnit string
}

// Level returns the entry's level: DEBUG, INFO, WARN, ERROR or FATAL.
// Quickshell logs at priority 6 with the level in the message; others carry
// it in the priority.
func (e Entry) Level() string {
	if m := level.FindStringSubmatch(e.Message); m != nil {
		return m[1]
	}
	switch {
	case e.Priority <= 2:
		return "FATAL"
	case e.Priority == 3:
		return "ERROR"
	case e.Priority == 4:
		return "WARN"
	case e.Priority == 7:
		return "DEBUG"
	}
	return "INFO"
}

// Problems returns the warnings and errors among entries, one line each,
// starting with its level.
func Problems(entries []Entry) []string {
	var lines []string
	for _, entry := range entries {
		level := entry.Level()
		switch level {
		case "WARN", "ERROR", "FATAL":
		default:
			continue
		}
		line := strings.TrimSpace(entry.Message)
		if !strings.HasPrefix(line, level) {
			line = level + " " + line
		}
		lines = append(lines, line)
	}
	return lines
}

// Cursor returns the journal's current position, to read what follows with
// Journal.
func Cursor(ctx context.Context, r Runner) (string, error) {
	out, err := r.Run(ctx, "journalctl", "--user", "--lines", "0", "--show-cursor", "--quiet", "--no-pager")
	if err != nil {
		return "", fmt.Errorf("journalctl: %v", err)
	}
	for line := range strings.Lines(string(out)) {
		if cursor, ok := strings.CutPrefix(strings.TrimSpace(line), "-- cursor: "); ok {
			return cursor, nil
		}
	}
	return "", errors.New("journalctl: no cursor")
}

// Journal returns the entries about the shell's unit after cursor.
func Journal(ctx context.Context, r Runner, cursor string) ([]Entry, error) {
	out, err := r.Run(ctx, "journalctl", "--user", "--unit", Unit, "--after-cursor", cursor, "--output", "json", "--no-pager")
	if err != nil {
		return nil, fmt.Errorf("journalctl: %v", err)
	}
	entries, err := ParseJournal(out)
	if err != nil {
		return nil, fmt.Errorf("journalctl: %v", err)
	}
	return entries, nil
}

// ParseJournal parses journalctl's JSON output, one object per entry.
func ParseJournal(out []byte) ([]Entry, error) {
	var entries []Entry
	dec := jsontext.NewDecoder(bytes.NewReader(out))
	for {
		var raw struct {
			Message     jsontext.Value `json:"MESSAGE"`
			Priority    string         `json:"PRIORITY"`
			Time        string         `json:"__REALTIME_TIMESTAMP"`
			PID         string         `json:"_PID"`
			Identifier  string         `json:"SYSLOG_IDENTIFIER"`
			UserUnit    string         `json:"USER_UNIT"`
			ProcessUnit string         `json:"_SYSTEMD_USER_UNIT"`
		}
		err := json.UnmarshalDecode(dec, &raw)
		if errors.Is(err, io.EOF) {
			return entries, nil
		}
		if err != nil {
			return nil, err
		}
		message, err := text(raw.Message)
		if err != nil {
			return nil, err
		}
		entry := Entry{
			Message:     colour.ReplaceAllString(message, ""),
			Priority:    6,
			PID:         raw.PID,
			Identifier:  raw.Identifier,
			UserUnit:    raw.UserUnit,
			ProcessUnit: raw.ProcessUnit,
		}
		if raw.Priority != "" {
			if entry.Priority, err = strconv.Atoi(raw.Priority); err != nil {
				return nil, fmt.Errorf("PRIORITY: %v", err)
			}
		}
		if raw.Time != "" {
			usec, err := strconv.ParseInt(raw.Time, 10, 64)
			if err != nil {
				return nil, fmt.Errorf("__REALTIME_TIMESTAMP: %v", err)
			}
			entry.Time = time.UnixMicro(usec)
		}
		entries = append(entries, entry)
	}
}

// text returns a MESSAGE field's text. journalctl writes a message holding
// control bytes, such as terminal colours, as an array of bytes.
func text(value jsontext.Value) (string, error) {
	switch value.Kind() {
	case '"':
		var s string
		err := json.Unmarshal(value, &s)
		return s, err
	case '[':
		var ints []int
		if err := json.Unmarshal(value, &ints); err != nil {
			return "", err
		}
		b := make([]byte, len(ints))
		for i, n := range ints {
			b[i] = byte(n)
		}
		return string(b), nil
	}
	return "", nil
}
