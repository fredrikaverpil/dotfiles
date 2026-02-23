package main

import (
	"github.com/fredrikaverpil/pocket/pk"
	"github.com/fredrikaverpil/pocket/tasks/claude"
	"github.com/fredrikaverpil/pocket/tasks/github"
	"github.com/fredrikaverpil/pocket/tasks/golang"
	"github.com/fredrikaverpil/pocket/tasks/lua"
	"github.com/fredrikaverpil/pocket/tasks/markdown"
)

// Config is the Pocket configuration for this project.
var Config = &pk.Config{
	Auto: pk.Parallel(
		claude.Tasks(),
		pk.WithOptions(
			golang.Tasks(),
			pk.WithDetect(golang.Detect()),
		),
		lua.Tasks(),
		markdown.Format,
		github.Tasks(),
	),

	// Plan configuration: shims, directories, and CI settings.
	Plan: &pk.PlanConfig{
		Shims: &pk.ShimConfig{
			Posix:      true,
			PowerShell: true,
		},
	},
}
