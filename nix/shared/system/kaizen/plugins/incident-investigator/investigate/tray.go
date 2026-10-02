package main

import (
	"bytes"
	"context"
	"fmt"
	"image"
	"image/color"
	"image/png"

	"fyne.io/systray"
)

// showTray puts the daemon's icon in the bar's tray until ctx is done. Left-click opens the window;
// the menu opens it too, or starts a new investigation.
func (d *daemon) showTray(ctx context.Context) error {
	iconPNG, err := trayIcon()
	if err != nil {
		return err
	}
	// Set before start: a tap handler turns off ItemIsMenu, which is read once at export.
	systray.SetOnTapped(func() { d.openWindow() })
	onReady := func() {
		systray.SetIcon(iconPNG)
		systray.SetTitle("Incident investigator")
		systray.SetTooltip("Incident investigator")
		open := systray.AddMenuItem("Open", "Open the window")
		draft := systray.AddMenuItem("New investigation", "Start from an empty draft")
		// onReady must return: the menu waits on it.
		go func() {
			for {
				select {
				case <-open.ClickedCh:
					d.openWindow()
				case <-draft.ClickedCh:
					d.newDraft()
				case <-ctx.Done():
					return
				}
			}
		}()
	}
	// The item goes away with the process's bus connection, so the returned end function is not called.
	start, _ := systray.RunWithExternalLoop(onReady, nil)
	start()
	return nil
}

func (d *daemon) openWindow() {
	if err := callWindow("open"); err != nil {
		d.logger.Warn("open the window", "error", err)
	}
}

func (d *daemon) newDraft() {
	d.mu.Lock()
	id, err := d.draft(request{})
	d.mu.Unlock()
	if err != nil {
		d.logger.Warn("create a draft", "error", err)
		return
	}
	if err := show(id); err != nil {
		d.logger.Warn("show the draft", "error", err)
	}
}

// trayIcon draws a magnifying glass as a PNG, mid-grey so it reads on light and dark bars.
func trayIcon() ([]byte, error) {
	const size = 32
	img := image.NewNRGBA(image.Rect(0, 0, size, size))
	for y := range size {
		for x := range size {
			dx, dy := x-13, y-13
			dist := dx*dx + dy*dy
			ring := dist >= 7*7 && dist <= 10*10
			handle := x >= 19 && y >= 19 && x <= 29 && y <= 29 && x-y >= -2 && x-y <= 2
			if ring || handle {
				img.Set(x, y, color.Gray{Y: 0x88})
			}
		}
	}
	var buf bytes.Buffer
	if err := png.Encode(&buf, img); err != nil {
		return nil, fmt.Errorf("encode tray icon: %v", err)
	}
	return buf.Bytes(), nil
}
