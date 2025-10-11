package main
import "base:intrinsics"
import "core:c"
import "core:fmt"
import "core:math"
import "core:mem"
import sdl "vendor:sdl3"

// Constants
BUF_WIDTH :: 1920
BUF_HEIGHT :: 1080

SDL3_Offscreen_Buffer :: struct {
	window:   ^sdl.Window,
	renderer: ^sdl.Renderer,
	texture:  ^sdl.Texture,
	fb:       []u8,
	w, h:     c.int,
}
SDL3_Sound_Output :: struct {
	wavePeriod, toneHz, tSine:                  f32,
	sampleRate, current_sample, bytesPerSample: i32,
	toneVolume, latency:                        i16,
	stream:                                     ^sdl.AudioStream,
}

play :: proc(sound: ^SDL3_Sound_Output) {
	sound.bytesPerSample = size_of(f32) * 2
	sound.wavePeriod = f32(sound.sampleRate) / sound.toneHz
	bytesToWrite :=
		(i32(sound.latency) * sound.bytesPerSample) - sdl.GetAudioStreamQueued(sound.stream)
	if bytesToWrite <= 0 do return

	buf := make([]f32, bytesToWrite, context.temp_allocator)
	for i in 0 ..< (len(buf) / 2) {
		t: f32 = 2.0 * math.PI * f32(sound.current_sample) / sound.wavePeriod
		sound.tSine += 2.0 * math.PI / sound.wavePeriod
		if sound.tSine >= math.PI * 2 {sound.tSine = 0}
		val := math.sin_f32(sound.tSine) * f32(sound.toneVolume)
		buf[i * 2] = val
		buf[i * 2 + 1] = val
		sound.current_sample += 1
	}

	sound.current_sample %= sound.sampleRate
	res := sdl.PutAudioStreamData(sound.stream, &buf[0], bytesToWrite * 4)
	if !res {
		sdl.Log("failed to put audio %s", sdl.GetError())
	}
}

render_gradient :: proc(fb: []u8, w, h, x_off, y_off: int) {
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

draw :: proc(app: ^SDL3_Offscreen_Buffer) {
	sdl.SetRenderDrawColor(app.renderer, 0, 0, 0, sdl.ALPHA_OPAQUE)
	sdl.RenderClear(app.renderer)

	pitch: i32 = 4 * app.w
	x_off := int(sdl.GetTicks())
	y_off := int(sdl.GetTicks())

	// sdl.Log("resize (%d, %d)", app.w, app.h)
	render_gradient(app.fb, int(app.w), int(app.h), x_off, 0)
	sdl.UpdateTexture(app.texture, nil, raw_data(app.fb), pitch)
	sdl.RenderTexture(app.renderer, app.texture, nil, nil)

	sdl.RenderPresent(app.renderer)
}

// Event docs: SDL_EventType.html
handle_event :: proc(
	app: ^SDL3_Offscreen_Buffer,
	sound: ^SDL3_Sound_Output,
	event: sdl.Event,
) -> bool {
	pitch: u32

	#partial switch event.type {
	case .WINDOW_RESIZED:
		sdl.Log("resize (%d, %d)", event.window.data1, event.window.data2)
	case .WINDOW_PIXEL_SIZE_CHANGED:
		sdl.GetWindowSize(app.window, &app.w, &app.h)
		resize_texture(app, event.window.data1, event.window.data2)
	case .KEY_DOWN, .KEY_UP:
		wasDown := event.key.repeat || event.type == .KEY_UP
		isDown := event.type == .KEY_DOWN
		// if wasDown != isDown {
		// if (isDown) do fmt.print("IsDown")
		// if (wasDown) do fmt.print("wasDown")
		// if event.key.repeat
		#partial switch event.key.scancode {
		case .W, .UP:
			sound.toneHz += 4
		case .A, .LEFT:
		case .S, .DOWN:
			sound.toneHz -= 4
		case .D, .RIGHT:
		case .Q:
		case .E:
		// }
		}
	case .WINDOW_EXPOSED:
		sdl.Log("draw")
		draw(app)
	case .JOYSTICK_ADDED:
		sdl.Log("JOYSTICK_ADDED")
	case .GAMEPAD_ADDED:
		sdl.Log("GAMEPAD_ADDED")
		init_controller()
	case:
	// sdl.Log("unhandled event: %d", event.type)
	}
	return true
}

resize_texture :: proc(app: ^SDL3_Offscreen_Buffer, width, height: i32) -> (ok: bool) {
	if app.texture != nil do sdl.DestroyTexture(app.texture)
	if app.fb != nil do delete(app.fb)

	app.texture = sdl.CreateTexture(
		app.renderer,
		sdl.PixelFormat.ARGB8888,
		sdl.TextureAccess.STREAMING,
		width,
		height,
	)

	if app.texture == nil {return false}
	app.fb = make([]u8, width * height * 4)
	return true
}


init_ui :: proc() -> (app: SDL3_Offscreen_Buffer, err: Maybe(string)) {
	_ignore := sdl.SetAppMetadata("Hero", "1.0", "supply.same.handmade")
	if (!sdl.Init(sdl.INIT_VIDEO)) {
		return app, string(sdl.GetError())
	}


	app.window = sdl.CreateWindow("dbg:Hero", 640, 480, sdl.WINDOW_RESIZABLE)
	if app.window == nil {return app, string(sdl.GetError())}

	app.renderer = sdl.CreateRenderer(app.window, nil)
	if app.renderer == nil {return app, string(sdl.GetError())}

	return app, nil
}

init_sound :: proc(sampleRate: c.int) -> (stream: ^sdl.AudioStream, err: Maybe(string)) {
	if !sdl.InitSubSystem(sdl.INIT_AUDIO) {
		return stream, string(sdl.GetError())
	}
	spec := sdl.AudioSpec{sdl.AudioFormat.F32, 2, sampleRate}
	stream = sdl.OpenAudioDeviceStream(sdl.AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, nil, nil)
	if stream == nil {
		return stream, string(sdl.GetError())
	}

	sdl.ResumeAudioDevice(sdl.GetAudioStreamDevice(stream))

	return stream, nil
}

init_controller :: proc() -> bool {
	if !sdl.InitSubSystem(sdl.INIT_GAMEPAD) {
		return false //, sdl.GetError()
	}
	count: c.int
	gamepadIds := sdl.GetGamepads(&count)
	gamepads := make([]^sdl.Gamepad, count)
	for i in 0 ..< count {
		gamepads[i] = sdl.OpenGamepad(gamepadIds[i])
	}
	return true
}
quit :: proc(app: SDL3_Offscreen_Buffer) {
	if app.fb != nil do delete(app.fb)
	sdl.DestroyTexture(app.texture)
	sdl.DestroyWindow(app.window)
	sdl.Quit()
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p bytes @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
	app, err := init_ui()
	if err != nil do fmt.panicf("unable to initialize ui %s", err)
	defer quit(app)

	SampleRate :: 44100
	stream, stream_err := init_sound(SampleRate)
	if stream_err != nil do sdl.Log("unable to initialize audio", stream_err)
	sound := SDL3_Sound_Output {
		sampleRate = SampleRate,
		toneVolume = 1,
		stream     = stream,
		toneHz     = 256,
		latency    = SampleRate / 12,
	}

	init_controller()
	resize_texture(&app, BUF_WIDTH, BUF_HEIGHT)
	when ODIN_DEBUG {
		perfCountFreq := sdl.GetPerformanceFrequency()
		lastPerfCount := sdl.GetPerformanceCounter()
	}
	done: for {
		event: sdl.Event
		play(&sound)
		for sdl.PollEvent(&event) {
			if event.type == sdl.EventType.QUIT ||
			   (event.type == sdl.EventType.KEY_DOWN &&
					   event.key.scancode == sdl.Scancode.ESCAPE) {
				break done
			}
			handle_event(&app, &sound, event)
		}
		draw(&app)
		when ODIN_DEBUG {
			endPerfCount := sdl.GetPerformanceCounter()
			counterElapsed := endPerfCount - lastPerfCount
			lastPerfCount = endPerfCount

			msPerFrame := (((1000 * counterElapsed) / perfCountFreq))
			fps := perfCountFreq / counterElapsed

			lastCycleCounter := intrinsics.read_cycle_counter()
			elapsed := i64(endPerfCount) - lastCycleCounter
			mcpf := elapsed / (2000)
			fmt.printfln("%d ms/f | %dfps | %d mc/f,", msPerFrame, fps, mcpf)
		}
	}
}

