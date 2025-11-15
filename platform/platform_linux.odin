package platform
import app "../app"
import "core:fmt"
import "core:sys/linux"
import wl "wayland_2"

start :: proc() {
	// fmt.println("linux ", app.TITLE)
	if wl.start() == .NoWayland {
		sdl_start()
	}
}

