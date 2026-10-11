package claude

import (
	"regexp"
	"testing"

	"gotest.tools/v3/assert"
)

func TestFoldEntities(t *testing.T) {
	patterns := append(EntityPatterns,
		EntityPattern{"user", regexp.MustCompile(`(?i)member[_-]?id\W{1,8}([A-Za-z0-9][A-Za-z0-9_.|@~-]*)`)},
		EntityPattern{"organization", regexp.MustCompile(`(?i)tenant[_-]?id\W{1,8}([A-Za-z0-9][A-Za-z0-9_.|~-]*)`)},
	)
	for _, tt := range []struct {
		name      string
		entities  []Entity
		line      string
		want      []Entity
		wantFound bool
	}{
		{
			name: "resource names in a string result",
			line: `{"type":"user","message":{"content":[{"type":"tool_result","content":` +
				`"caller users/alice in organizations/org123, again users/alice"}]}}`,
			want: []Entity{
				{Kind: "user", ID: "alice", Count: 2},
				{Kind: "organization", ID: "org123", Count: 1},
			},
			wantFound: true,
		},
		{
			name: "escaped id fields of configured patterns in a list result",
			line: `{"type":"user","message":{"content":[{"type":"tool_result","content":[{"type":"text","text":` +
				`"{\"member_id\":\"auth0|507f\",\"tenant_id\":\"org_1234\"}"}]}]}}`,
			want: []Entity{
				{Kind: "user", ID: "auth0|507f", Count: 1},
				{Kind: "organization", ID: "org_1234", Count: 1},
			},
			wantFound: true,
		},
		{
			name:     "counts add to earlier ones and the most seen comes first",
			entities: []Entity{{Kind: "user", ID: "alice", Count: 1}, {Kind: "user", ID: "bob", Count: 1}},
			line:     `{"type":"user","message":{"content":[{"type":"tool_result","content":"users/bob"}]}}`,
			want: []Entity{
				{Kind: "user", ID: "bob", Count: 2},
				{Kind: "user", ID: "alice", Count: 1},
			},
			wantFound: true,
		},
		{
			name: "placeholders are not ids",
			line: `{"type":"user","message":{"content":[{"type":"tool_result","content":"users/- and users/{user}"}]}}`,
		},
		{
			name: "the model's own text is not scanned",
			line: `{"type":"assistant","message":{"content":[{"type":"text","text":"users/alice"}]}}`,
		},
		{
			name: "a prompt string is not scanned",
			line: `{"type":"user","message":{"content":"users/alice tool_result"}}`,
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			got, found := FoldEntities(tt.entities, []byte(tt.line), patterns)

			assert.DeepEqual(t, got, tt.want)
			assert.Equal(t, found, tt.wantFound)
		})
	}
}
