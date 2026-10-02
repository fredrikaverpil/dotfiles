package claude

import (
	"bytes"
	"cmp"
	"encoding/json"
	"regexp"
	"slices"
)

// Entity is a user or organization id found in tool output, and how often.
type Entity struct {
	// Kind is user or organization.
	Kind  string `json:"kind"`
	ID    string `json:"id"`
	Count int    `json:"count"`
}

// EntityPattern finds ids of one kind; its first group is the id.
type EntityPattern struct {
	// Kind is user or organization.
	Kind   string
	Regexp *regexp.Regexp
}

// EntityPatterns are the resource names `users/ID` and `organizations/ID`.
var EntityPatterns = []EntityPattern{
	{"user", regexp.MustCompile(`\busers/([A-Za-z0-9][A-Za-z0-9_.|@~-]*)`)},
	{"organization", regexp.MustCompile(`\borganizations/([A-Za-z0-9][A-Za-z0-9_.|~-]*)`)},
}

// FoldEntities adds the ids that patterns find in one stream-json line's tool results to entities, and reports
// whether any were found. The ids come from the output itself and never pass through the model, so they can be
// resolved without it.
func FoldEntities(entities []Entity, line []byte, patterns []EntityPattern) ([]Entity, bool) {
	if !bytes.Contains(line, []byte(`"tool_result"`)) {
		return entities, false
	}
	var event struct {
		Message struct {
			// A user event's content can be a string; only a tool result's is decoded.
			Content json.RawMessage `json:"content"`
		} `json:"message"`
	}
	if json.Unmarshal(line, &event) != nil {
		return entities, false
	}
	var blocks []struct {
		Type    string          `json:"type"`
		Content json.RawMessage `json:"content"`
	}
	if json.Unmarshal(event.Message.Content, &blocks) != nil {
		return entities, false
	}
	found := false
	for _, block := range blocks {
		if block.Type != "tool_result" {
			continue
		}
		for _, text := range resultTexts(block.Content) {
			for _, p := range patterns {
				for _, m := range p.Regexp.FindAllStringSubmatch(text, -1) {
					entities, found = add(entities, p.Kind, m[1]), true
				}
			}
		}
	}
	if found {
		slices.SortStableFunc(entities, func(a, b Entity) int { return cmp.Compare(b.Count, a.Count) })
	}
	return entities, found
}

// resultTexts returns a tool result's text, which is a string or a list of text blocks.
func resultTexts(raw json.RawMessage) []string {
	var text string
	if json.Unmarshal(raw, &text) == nil {
		return []string{text}
	}
	var parts []struct {
		Text string `json:"text"`
	}
	if json.Unmarshal(raw, &parts) != nil {
		return nil
	}
	texts := make([]string, 0, len(parts))
	for _, part := range parts {
		texts = append(texts, part.Text)
	}
	return texts
}

func add(entities []Entity, kind, id string) []Entity {
	for i := range entities {
		if entities[i].Kind == kind && entities[i].ID == id {
			entities[i].Count++
			return entities
		}
	}
	return append(entities, Entity{Kind: kind, ID: id, Count: 1})
}
