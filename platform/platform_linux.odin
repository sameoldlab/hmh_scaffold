package platform

start :: proc() {
	if true {
		sdl_start()
	} else if wl_start() == .NoWayland {
		sdl_start()
	}
}

