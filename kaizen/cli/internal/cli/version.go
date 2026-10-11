package cli

import "runtime/debug"

// Version returns the commit a build was made from, shortened, with +modified
// for uncommitted changes, or unknown when info has no VCS revision.
func Version(info *debug.BuildInfo) string {
	if info == nil {
		return "unknown"
	}
	var revision, modified string
	for _, setting := range info.Settings {
		switch setting.Key {
		case "vcs.revision":
			revision = setting.Value
		case "vcs.modified":
			modified = setting.Value
		}
	}
	if revision == "" {
		return "unknown"
	}
	revision = revision[:min(len(revision), 12)]
	if modified == "true" {
		revision += "+modified"
	}
	return revision
}
