package compositor

import (
	"cmp"
	"os"
	"path/filepath"
	"strings"
)

// Env is the environment a compositor resolves its config in.
type Env struct {
	Getenv func(string) string
	Home   string
}

// configDir returns $XDG_CONFIG_HOME, else ~/.config.
func (e Env) configDir() string {
	return cmp.Or(e.Getenv("XDG_CONFIG_HOME"), filepath.Join(e.Home, ".config"))
}

// Config is a compositor's config file and how it includes kaizen's file.
type Config struct {
	// Path is the config file the compositor reads.
	Path string
	// Kaizen is the name of kaizen's file for the compositor.
	Kaizen string
	// Hint says how to include Kaizen in Path.
	Hint string
	// includes returns the paths a config file's text includes.
	includes func(data string) []string
	home     string
}

// IncludesKaizen reports whether Path, or a file it includes, includes a
// regular file named Kaizen.
func (c Config) IncludesKaizen() bool {
	return c.reaches(c.Path, 0)
}

// reaches reports whether file, or a file it includes, includes a regular file
// named c.Kaizen. ~ is home, other relative paths are relative to the including
// file, and nesting stops at 10 levels, which also ends a cycle.
func (c Config) reaches(file string, depth int) bool {
	if depth >= 10 {
		return false
	}
	data, err := os.ReadFile(file)
	if err != nil {
		return false
	}
	for _, path := range c.includes(string(data)) {
		switch {
		case path == "~" || strings.HasPrefix(path, "~/"):
			path = c.home + path[1:]
		case !filepath.IsAbs(path):
			path = filepath.Join(filepath.Dir(file), path)
		}
		if filepath.Base(path) == c.Kaizen && isRegular(path) || c.reaches(path, depth+1) {
			return true
		}
	}
	return false
}

// isRegular reports whether path is a regular file, following links.
func isRegular(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.Mode().IsRegular()
}
