package cli

import (
	"context"
	"io"
)

// Command is a command written in Go. It wins over a script of the same name.
type Command interface {
	// Name is the word after kaizen that runs it.
	Name() string
	// Usage is its usage line, starting with kaizen.
	Usage() string
	// Summary says what it does, in lower case.
	Summary() string
	// Run runs it with the arguments after its name and returns the exit code.
	Run(ctx context.Context, args []string, stdout, stderr io.Writer) int
}
