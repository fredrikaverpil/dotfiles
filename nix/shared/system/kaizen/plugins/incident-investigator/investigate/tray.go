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
	iconPNG, err := trayIcon(false)
	if err != nil {
		return err
	}
	// Set before start: a tap handler turns off ItemIsMenu, which is read once at export. The icon is set here, not in
	// onReady, which runs on its own goroutine and could undo a running turn's dot.
	systray.SetOnTapped(func() { d.openWindow() })
	systray.SetIcon(iconPNG)
	onReady := func() {
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

// updateTray dots the icon while a turn runs. Call with d.mu held.
func (d *daemon) updateTray() {
	iconPNG, err := trayIcon(len(d.turns) > 0)
	if err != nil {
		d.logger.Warn("draw the tray icon", "error", err)
		return
	}
	systray.SetIcon(iconPNG)
}

// trayIcon draws a magnifying glass as a PNG, mid-grey so it reads on light and dark bars, with an amber dot in
// the top right corner when running.
func trayIcon(running bool) ([]byte, error) {
	const size = 32
	img := image.NewNRGBA(image.Rect(0, 0, size, size))
	for y := range size {
		for x := range size {
			dx, dy := x-13, y-13
			dist := dx*dx + dy*dy
			ring := dist >= 7*7 && dist <= 10*10
			handle := x >= 19 && y >= 19 && x <= 29 && y <= 29 && x-y >= -2 && x-y <= 2
			dotX, dotY := x-27, y-4
			switch {
			case running && dotX*dotX+dotY*dotY <= 4*4:
				img.Set(x, y, color.NRGBA{R: 0xe0, G: 0x9a, B: 0x30, A: 0xff})
			case ring || handle:
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
