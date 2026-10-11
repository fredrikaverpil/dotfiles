package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log/slog"
	"sync"
)

// journalHandler writes slog's text lines, each prefixed with its syslog priority (`<4>`), which journald reads from a
// unit's output as the line's PRIORITY.
type journalHandler struct {
	text slog.Handler
	out  io.Writer
	buf  *bytes.Buffer
	mu   *sync.Mutex
}

func newJournalHandler(out io.Writer, opts *slog.HandlerOptions) *journalHandler {
	var buf bytes.Buffer
	return &journalHandler{text: slog.NewTextHandler(&buf, opts), out: out, buf: &buf, mu: &sync.Mutex{}}
}

func (h *journalHandler) Enabled(ctx context.Context, level slog.Level) bool {
	return h.text.Enabled(ctx, level)
}

// Handle writes the prefix and the line in one write, so that other writes to out cannot split them.
func (h *journalHandler) Handle(ctx context.Context, r slog.Record) error {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.buf.Reset()
	fmt.Fprintf(h.buf, "<%d>", priority(r.Level))
	if err := h.text.Handle(ctx, r); err != nil {
		return err
	}
	_, err := h.out.Write(h.buf.Bytes())
	return err
}

func (h *journalHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	return &journalHandler{text: h.text.WithAttrs(attrs), out: h.out, buf: h.buf, mu: h.mu}
}

func (h *journalHandler) WithGroup(name string) slog.Handler {
	return &journalHandler{text: h.text.WithGroup(name), out: h.out, buf: h.buf, mu: h.mu}
}

// priority maps a level to the syslog priority debug, info, warning or err.
func priority(level slog.Level) int {
	switch {
	case level < slog.LevelInfo:
		return 7
	case level < slog.LevelWarn:
		return 6
	case level < slog.LevelError:
		return 4
	default:
		return 3
	}
}
