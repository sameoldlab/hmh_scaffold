package app

draw :: proc(fb: []u8, w, h, x_off, y_off: int) {
	i := 0
	for y in 0 ..< h {
		for x in 0 ..< w {
			fb[i] = u8(x + x_off)
			i += 1
			fb[i] = u8(y + y_off)
			i += 1
			fb[i] = 000
			i += 1
			fb[i] = 255
			i += 1
		}
	}
}

