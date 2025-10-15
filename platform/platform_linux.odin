package platform
import app "../app"
import "core:fmt"

start :: proc() {
	fmt.println("linux ", app.TITLE)
	sdl_start()
}

