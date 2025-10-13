package main
import "core:math"
drawGradient :: proc(fb: []u8, w, h, x_off, y_off: i32) {
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

updateAndRender :: proc(buffer: ^Offscreen_Buffer) {
	drawGradient(buffer.fb, buffer.w, buffer.h, 0, 0)
}
current_sample: i32 = 0
tSine: f32 = 0

gameOutputSound :: proc(sound: ^GameSoundBuffer) {
	ToneVolume :: 1
	ToneHz :: 256
	wavePeriod: f32 = f32(sound.sampleRate) / ToneHz

	for i in 0 ..< (len(sound.samples) / 2) {
		t: f32 = 2.0 * math.PI * f32(current_sample) / wavePeriod
		tSine += 2.0 * math.PI / wavePeriod
		if tSine >= math.PI * 2 {tSine = 0}
		val := math.sin_f32(tSine) * ToneVolume
		sound.samples[i * 2] = val
		sound.samples[i * 2 + 1] = val
		current_sample += 1
	}

	current_sample %= sound.sampleRate
}

