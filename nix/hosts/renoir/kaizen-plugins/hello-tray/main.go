// Command hello-tray is the minimal tray plugin: a StatusNotifierItem with its own menu.
package main

import (
	"bytes"
	"image"
	"image/color"
	"image/png"
	"log/slog"
	"os"

	"fyne.io/systray"
	"github.com/godbus/dbus/v5"
)

func main() {
	// kaizen-log lists the level= field of slog's text output.
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stderr, nil)))
	// Left-click greets, right-click opens the menu. Set before Run: a tap handler
	// turns off ItemIsMenu, which is read once at export.
	systray.SetOnTapped(sayHello)
	systray.Run(onReady, nil)
}

func onReady() {
	systray.SetIcon(icon())
	systray.SetTitle("Hello")
	systray.SetTooltip("Hello tray")
	greet := systray.AddMenuItem("Say hello", "Send a notification")
	quit := systray.AddMenuItem("Quit", "Stop hello-tray")
	go func() {
		for {
			select {
			case <-greet.ClickedCh:
				sayHello()
			case <-quit.ClickedCh:
				systray.Quit()
				return
			}
		}
	}()
}

func sayHello() {
	if err := notify("Hello from a tray plugin"); err != nil {
		slog.Error("notify", "error", err)
	}
}

// notify sends a desktop notification over D-Bus.
func notify(body string) error {
	conn, err := dbus.SessionBus()
	if err != nil {
		return err
	}
	return conn.Object("org.freedesktop.Notifications", "/org/freedesktop/Notifications").Call(
		"org.freedesktop.Notifications.Notify",
		0,
		"hello-tray",
		uint32(0),
		"",
		"Hello",
		body,
		[]string{},
		map[string]dbus.Variant{},
		int32(-1),
	).Err
}

// icon draws a filled circle as a PNG, mid-grey so it reads on light and dark bars.
func icon() []byte {
	const size = 32
	const radius = size/2 - 2
	img := image.NewNRGBA(image.Rect(0, 0, size, size))
	for y := range size {
		for x := range size {
			dx, dy := x-size/2, y-size/2
			if dx*dx+dy*dy <= radius*radius {
				img.Set(x, y, color.Gray{Y: 0x88})
			}
		}
	}
	var buf bytes.Buffer
	if err := png.Encode(&buf, img); err != nil {
		slog.Error("encode the icon", "error", err)
		os.Exit(1)
	}
	return buf.Bytes()
}
