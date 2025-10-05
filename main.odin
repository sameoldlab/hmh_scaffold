package main
import "core:c"
import "core:fmt"
import "core:mem"
import sdl "vendor:sdl3"

// Constants
BUF_WIDTH :: 1920
BUF_HEIGHT :: 1080
BYTES_PER_PIXEL :: 4

window: ^sdl.Window
renderer: ^sdl.Renderer
texture: ^sdl.Texture
w, h: c.int
fb: [BUF_WIDTH * BUF_HEIGHT * 4]u8
texture_width: i32
texture_pitch: i32
frame_allocator: mem.Allocator
temp_allocator: mem.Allocator

draw :: proc() {
	// col := u8(sdl.GetTicks() % 2) * 255
	sdl.SetRenderDrawColor(renderer, 0, 0, 0, sdl.ALPHA_OPAQUE)
	sdl.RenderClear(renderer)

	sdl.GetWindowSize(window, &w, &h)
	pitch: i32 = 4 * w
	for &p, i in fb {
		c := i % 4
		switch c {
		case 0:
			p = 0 // blue
		case 1:
			p = 0 // green
		case 2:
			p = 255 // red
		case 3:
			p = 255 // alpha
		}
	}

	sdl.UpdateTexture(texture, nil, &fb, pitch)
	sdl.RenderTexture(renderer, texture, nil, nil)
	sdl.Delay(1)

	sdl.RenderPresent(renderer)
}

// Event docs: SDL_EventType.html
handle_event :: proc(event: ^sdl.Event) -> bool {
	pitch: u32

	#partial pix: switch event.type {
	case sdl.EventType.WINDOW_RESIZED:
		sdl.Log("resize (%d, %d)", event.window.data1, event.window.data2)
	// case sdl.EventType.WINDOW_PIXEL_SIZE_CHANGED:
	// sdl.
	case sdl.EventType.KEY_DOWN:
		sdl.Log("key down: %d", event.window.data2)
	case sdl.EventType.KEY_UP:
		sdl.Log("key up: %d", event.window.data2)
	case sdl.EventType.WINDOW_EXPOSED:
		draw()
	case:
		sdl.Log("unhandled event: %d", event.type)
	}
	return true
}

resize_texture :: proc(width, height: i32) -> (ok: bool) {
	if texture != nil do sdl.DestroyTexture(texture)
	// if fb != nil do delete(fb)

	texture = sdl.CreateTexture(
		renderer,
		sdl.PixelFormat.ARGB8888,
		sdl.TextureAccess.STREAMING,
		width,
		height,
	)

	if texture == nil {return false}

	// fb = make([]u32, width * height)
	texture_width = width

	// mem.zero_slice(fb)
	return true
}

init_ui :: proc() -> bool {
	_ignore := sdl.SetAppMetadata("Hero", "1.0", "supply.same.handmade")
	if (!sdl.Init(sdl.INIT_VIDEO)) {
		sdl.Log("Couldn't initialize SDL3: %s", sdl.GetError())
		return false
	}
	if (!sdl.CreateWindowAndRenderer("Hero", 640, 480, sdl.WINDOW_RESIZABLE, &window, &renderer)) {
		sdl.Log("Couldn't create window/renderer: %s", sdl.GetError())
		return false
	}
	return true
}

quit :: proc() {
	sdl.DestroyTexture(texture)
	sdl.DestroyWindow(window)
	sdl.Quit()
}

main :: proc() {
	if !init_ui() do panic("unable to initialize ui")
	defer quit()

	// fb = make([]u32, BUF_WIDTH * BUF_HEIGHT)
	// defer delete(fb)

	resize_texture(BUF_WIDTH, BUF_HEIGHT)
	done := false
	for !done {
		event: sdl.Event
		for sdl.PollEvent(&event) {
			if event.type == sdl.EventType.QUIT {done = true}
			handle_event(&event)
		}
	}

}

