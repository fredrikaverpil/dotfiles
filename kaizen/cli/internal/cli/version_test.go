package cli

import (
	"runtime/debug"
	"testing"

	"gotest.tools/v3/assert"
)

func TestVersion(t *testing.T) {
	revision := debug.BuildSetting{Key: "vcs.revision", Value: "4f1c2a9e0b7d3c5a1e8f6b2d9c4a7e0f1b3d5c8a"}
	for _, tt := range []struct {
		name string
		info *debug.BuildInfo
		want string
	}{
		{
			name: "clean",
			info: &debug.BuildInfo{Settings: []debug.BuildSetting{revision, {Key: "vcs.modified", Value: "false"}}},
			want: "4f1c2a9e0b7d",
		},
		{
			name: "modified",
			info: &debug.BuildInfo{Settings: []debug.BuildSetting{revision, {Key: "vcs.modified", Value: "true"}}},
			want: "4f1c2a9e0b7d+modified",
		},
		{
			name: "short revision",
			info: &debug.BuildInfo{Settings: []debug.BuildSetting{{Key: "vcs.revision", Value: "4f1c"}}},
			want: "4f1c",
		},
		{
			name: "no vcs",
			info: &debug.BuildInfo{Settings: []debug.BuildSetting{{Key: "-trimpath", Value: "true"}}},
			want: "unknown",
		},
		{
			name: "no build info",
			want: "unknown",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			got := Version(tt.info)
			assert.Equal(t, got, tt.want)
		})
	}
}
