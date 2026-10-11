package main

import (
	"bytes"
	"log/slog"
	"testing"

	"gotest.tools/v3/assert"
)

func TestJournalHandler(t *testing.T) {
	for _, tt := range []struct {
		name string
		log  func(*slog.Logger)
		want string
	}{
		{name: "debug", log: func(l *slog.Logger) { l.Debug("m", "k", "v") }, want: "<7>level=DEBUG msg=m k=v\n"},
		{name: "info", log: func(l *slog.Logger) { l.Info("m", "k", "v") }, want: "<6>level=INFO msg=m k=v\n"},
		{name: "warn", log: func(l *slog.Logger) { l.Warn("m", "k", "v") }, want: "<4>level=WARN msg=m k=v\n"},
		{name: "error", log: func(l *slog.Logger) { l.Error("m", "k", "v") }, want: "<3>level=ERROR msg=m k=v\n"},
		{
			name: "above error",
			log:  func(l *slog.Logger) { l.Log(t.Context(), slog.LevelError+4, "m") },
			want: "<3>level=ERROR+4 msg=m\n",
		},
		{name: "with attrs", log: func(l *slog.Logger) { l.With("k", "v").Warn("m") }, want: "<4>level=WARN msg=m k=v\n"},
		{
			name: "with group",
			log:  func(l *slog.Logger) { l.WithGroup("g").Error("m", "k", "v") },
			want: "<3>level=ERROR msg=m g.k=v\n",
		},
		{
			name: "two lines",
			log:  func(l *slog.Logger) { l.Info("a"); l.Warn("b") },
			want: "<6>level=INFO msg=a\n<4>level=WARN msg=b\n",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			// Arrange
			var out bytes.Buffer
			logger := slog.New(newJournalHandler(&out, &slog.HandlerOptions{
				Level: slog.LevelDebug,
				ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
					if len(groups) == 0 && a.Key == slog.TimeKey {
						return slog.Attr{}
					}
					return a
				},
			}))

			// Act
			tt.log(logger)

			// Assert
			assert.DeepEqual(t, out.String(), tt.want)
		})
	}
}
