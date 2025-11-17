package wayland

WL_EGL_WINDOW_VERSION :: 3
Wl_egl_window :: struct {
	__version:               i32,
	width:                   i32,
	height:                  i32,
	dx:                      i32,
	dy:                      i32,
	attached_width:          i32,
	attached_height:         i32,
	__driver_private:        rawptr,
	resize_callback:         proc "c" (window: ^Wl_egl_window, driver_private: rawptr),
	destroy_window_callback: proc "c" (data: rawptr),
	surface:                 rawptr,
}

Shim_Wl_Surface :: Shim_Wl_Proxy
Shim_Wl_Proxy :: struct {
	object:     struct {
		interface:      rawptr,
		implementation: rawptr,
		id:             u32,
	},
	display:    rawptr,
	queue:      rawptr,
	flags:      u32,
	refcount:   i32,
	user_data:  rawptr,
	dispatcher: rawptr,
	version:    u32,
	tag:        rawptr,
	queue_link: struct {
		prev: rawptr,
		next: rawptr,
	},
}

shim_wl_surface_proxy :: proc(conn: ^Connection, wl_surface: Surface) -> ^Shim_Wl_Proxy {
	proxy := new(Shim_Wl_Proxy)
	proxy.object.id = u32(wl_surface)
	proxy.object.interface = nil
	proxy.object.implementation = nil

	proxy.display = rawptr(conn)
	proxy.queue = nil
	proxy.flags = 0
	proxy.refcount = 1
	proxy.user_data = nil
	proxy.dispatcher = nil
	proxy.version = 4
	proxy.tag = nil

	proxy.queue_link.prev = &proxy.queue_link
	proxy.queue_link.next = &proxy.queue_link

	return proxy
}

wl_egl_window_create :: proc(
	surface: ^Shim_Wl_Surface,
	width, height: i32,
) -> (
	egl_window: ^Wl_egl_window,
	ok: bool,
) {
	if (width <= 0 || height <= 0) do return


	window, err := new(Wl_egl_window)
	assert(err == .None)

	window.__version = WL_EGL_WINDOW_VERSION

	window.surface = surface

	window.width = width
	window.height = height

	return window, true
}

wl_egl_window_destroy :: proc(egl_window: ^Wl_egl_window) {
	if egl_window.destroy_window_callback != {} {
		egl_window.destroy_window_callback(egl_window.__driver_private)
	}
	free(egl_window)
}

wl_egl_window_get_attached_size :: proc(egl_window: ^Wl_egl_window) -> (width, height: i32) {
	return egl_window.attached_width, egl_window.attached_height
}

// Resize the EGL window
//
// \param egl_window A pointer to a struct wl_egl_window
// \param width The new width
// \param height The new height
// \param dx Offset on the X axis
// \param dy Offset on the Y axis
//
// Note that applications should prefer using the wl_surface.offset request if
// the associated wl_surface has the interface version 5 or higher.
//
// If the wl_surface.offset request is used, applications MUST pass 0 to both
// dx and dy.
wl_egl_window_resize :: proc(egl_window: ^Wl_egl_window, width, height, dx, dy: i32) {
	if (width <= 0 || height <= 0) do return

	egl_window.width = width
	egl_window.height = height
	egl_window.dx = dx
	egl_window.dy = dy

	if egl_window.resize_callback != {} {
		egl_window.resize_callback(egl_window, egl_window.__driver_private)
	}
}

