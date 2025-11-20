package platform
import app "../app"
import "core:fmt"
import "core:sys/linux"

start :: proc() {
	if false {
		sdl_start()
	} else {

		if wl_start() == .NoWayland {
			sdl_start()
		}
	}
}

