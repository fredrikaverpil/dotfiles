package state

import (
	"context"
	"encoding/json/v2"
	"fmt"
)

// Layer is a layer surface in `niri msg -j layers`.
type Layer struct {
	Namespace string `json:"namespace"`
	Output    string `json:"output"`
	// KeyboardInteractivity is None, Exclusive or OnDemand. The shell's
	// surfaces that take the keyboard are Exclusive.
	KeyboardInteractivity string `json:"keyboard_interactivity"`
}

// Layers reads the layer surfaces from niri.
func Layers(ctx context.Context, r Runner) ([]Layer, error) {
	out, err := r.Run(ctx, "niri", "msg", "-j", "layers")
	if err != nil {
		return nil, fmt.Errorf("niri msg layers: %v", err)
	}
	var layers []Layer
	if err := json.Unmarshal(out, &layers); err != nil {
		return nil, fmt.Errorf("niri msg layers: %v", err)
	}
	return layers, nil
}
