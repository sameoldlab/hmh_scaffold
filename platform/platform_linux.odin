package platform
import app "../app"
import "core:fmt"
import "core:sys/linux"
import wl "wayland"

start :: proc() {
	// fmt.println("linux ", app.TITLE)
	wl_connection, err := wl.connect_display()
	if err == linux.Errno.NONE {
		fmt.println("Error: ", wl.run(&wl_connection))
	} else {
		sdl_start()
	}
}

