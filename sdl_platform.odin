package main

import "base:intrinsics"
import "core:c"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:strings"
import sdl "vendor:sdl3"

// Constants
BUF_WIDTH :: 1920
BUF_HEIGHT :: 1080

Offscreen_Buffer :: struct {
	window:   ^sdl.Window,
	renderer: ^sdl.Renderer,
	texture:  ^sdl.Texture,
	fb:       []u8,
	w, h:     c.int,
}
Sound_Output :: struct {
	sampleRate: i32,
	latency:    i16,
	stream:     ^sdl.AudioStream,
}

GameSoundBuffer :: struct {
	sampleRate:  i32,
	sampleCount: i32,
	samples:     []f32,
}

pl_draw :: proc(ctx: ^Offscreen_Buffer) {
	sdl.SetRenderDrawColor(ctx.renderer, 0, 0, 0, sdl.ALPHA_OPAQUE)
	sdl.RenderClear(ctx.renderer)
	x_off := i32(sdl.GetTicks())
	// drawGradient(ctx.fb, ctx.w, ctx.h, x_off, 0)

	pitch: i32 = 4 * ctx.w
	sdl.UpdateTexture(ctx.texture, nil, raw_data(ctx.fb), pitch)
	sdl.RenderTexture(ctx.renderer, ctx.texture, nil, nil)

	sdl.RenderPresent(ctx.renderer)
}

// Event docs: SDL_EventType.html
pl_handle_event :: proc(ctx: ^Offscreen_Buffer, sound: ^Sound_Output, event: sdl.Event) -> bool {
	pitch: u32

	#partial switch event.type {
	case .WINDOW_RESIZED:
		sdl.Log("resize (%d, %d)", event.window.data1, event.window.data2)
	case .WINDOW_PIXEL_SIZE_CHANGED:
		sdl.GetWindowSize(ctx.window, &ctx.w, &ctx.h)
		pl_resize_texture(ctx, event.window.data1, event.window.data2)
	case .KEY_DOWN, .KEY_UP:
		wasDown := event.key.repeat || event.type == .KEY_UP
		isDown := event.type == .KEY_DOWN
		// if wasDown != isDown {
		// if (isDown) do fmt.print("IsDown")
		// if (wasDown) do fmt.print("wasDown")
		// if event.key.repeat
		#partial switch event.key.scancode {
		case .W, .UP:
		// sound.toneHz += 4
		case .A, .LEFT:
		case .S, .DOWN:
		// sound.toneHz -= 4
		case .D, .RIGHT:
		case .Q:
		case .E:
		// }
		}
	case .WINDOW_EXPOSED:
		sdl.Log("draw")
		pl_draw(ctx)
	case .JOYSTICK_ADDED:
		sdl.Log("JOYSTICK_ADDED")
	case .GAMEPAD_ADDED:
		sdl.Log("GAMEPAD_ADDED")
		pl_init_controller()
	case:
	// sdl.Log("unhandled event: %d", event.type)
	}
	return true
}

pl_resize_texture :: proc(ctx: ^Offscreen_Buffer, width, height: i32) -> (ok: bool) {
	if ctx.texture != nil do sdl.DestroyTexture(ctx.texture)
	if ctx.fb != nil do delete(ctx.fb)

	ctx.texture = sdl.CreateTexture(
		ctx.renderer,
		sdl.PixelFormat.ARGB8888,
		sdl.TextureAccess.STREAMING,
		width,
		height,
	)

	if ctx.texture == nil {return false}
	ctx.fb = make([]u8, width * height * 4)
	return true
}


pl_init_ui :: proc(
	title: cstring,
	app_id: cstring = "supply.same.handmade",
	version: cstring = "1.0",
	width: c.int = 640,
	height: c.int = 480,
) -> (
	ctx: Offscreen_Buffer,
	err: Maybe(string),
) {
	_ignore := sdl.SetAppMetadata(title, version, app_id)
	if (!sdl.Init(sdl.INIT_VIDEO)) {
		return ctx, string(sdl.GetError())
	}

	ctx.window = sdl.CreateWindow(title, width, height, sdl.WINDOW_RESIZABLE)
	if ctx.window == nil {return ctx, string(sdl.GetError())}

	ctx.renderer = sdl.CreateRenderer(ctx.window, nil)
	if ctx.renderer == nil {return ctx, string(sdl.GetError())}

	return ctx, nil
}

pl_init_sound :: proc(sampleRate: c.int) -> (stream: ^sdl.AudioStream, err: Maybe(string)) {
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

pl_init_controller :: proc() -> bool {
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
pl_quit :: proc(ctx: Offscreen_Buffer) {
	if ctx.fb != nil do delete(ctx.fb)
	sdl.DestroyTexture(ctx.texture)
	sdl.DestroyWindow(ctx.window)
	sdl.Quit()
}

pl_start :: proc(title: string) {
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
	app, err := pl_init_ui(strings.clone_to_cstring(title, context.temp_allocator))
	if err != nil do fmt.panicf("unable to initialize ui %s", err)
	defer pl_quit(app)

	SampleRate :: 44100
	stream, stream_err := pl_init_sound(SampleRate)
	if stream_err != nil do sdl.Log("unable to initialize audio", stream_err)
	sound := Sound_Output {
		sampleRate = SampleRate,
		stream     = stream,
		latency    = SampleRate / 12,
	}

	pl_init_controller()
	pl_resize_texture(&app, BUF_WIDTH, BUF_HEIGHT)
	when ODIN_DEBUG {
		perfCountFreq := sdl.GetPerformanceFrequency()
		lastPerfCount := sdl.GetPerformanceCounter()
	}
	done: for {
		event: sdl.Event
		for sdl.PollEvent(&event) {
			if event.type == sdl.EventType.QUIT ||
			   (event.type == sdl.EventType.KEY_DOWN &&
					   event.key.scancode == sdl.Scancode.ESCAPE) {
				break done
			}
			pl_handle_event(&app, &sound, event)
		}

		{
			bytesPerSample: i32 = size_of(f32) * 2
			bytesToWrite :=
				(i32(sound.latency) * bytesPerSample) - sdl.GetAudioStreamQueued(sound.stream)
			if bytesToWrite > 0 {
				samples := make([]f32, max(bytesToWrite, 2), context.temp_allocator)

				sound_out := GameSoundBuffer {
					sampleRate  = sound.sampleRate,
					sampleCount = bytesToWrite / bytesPerSample,
					samples     = samples,
				}
				gameOutputSound(&sound_out)
				sdl.PutAudioStreamData(sound.stream, &samples[0], bytesToWrite * 4)
			}
			updateAndRender(&app)
			pl_draw(&app)
			// if !res {
			// 	sdl.Log("failed to put audio %s", sdl.GetError())
			// }
		}
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

