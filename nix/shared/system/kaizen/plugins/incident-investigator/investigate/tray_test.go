package main

import (
	"bytes"
	"image/color"
	"image/png"
	"testing"

	"gotest.tools/v3/assert"
)

func TestTrayIcon(t *testing.T) {
	for _, tt := range []struct {
		name    string
		running bool
		want    color.Color
	}{
		{name: "idle", running: false, want: color.NRGBA{}},
		{name: "running", running: true, want: color.NRGBA{R: 0xe0, G: 0x9a, B: 0x30, A: 0xff}},
	} {
		t.Run(tt.name, func(t *testing.T) {
			// Act
			iconPNG, err := trayIcon(tt.running)

			// Assert
			assert.NilError(t, err)
			img, err := png.Decode(bytes.NewReader(iconPNG))
			assert.NilError(t, err)
			assert.DeepEqual(t, color.NRGBAModel.Convert(img.At(27, 4)), tt.want)
		})
	}
}
