package app

// 
// Constants
// 
TITLE :: "dbg: Hero"
APP_ID :: "supply.same.handmade"
VERSION :: "1.0"
BUF_WIDTH :: 1920
BUF_HEIGHT :: 1080

Input :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}
FrameBuffer :: struct {
	fb:   []u8,
	w, h: i32,
}

SampleBuffer :: struct {
	sampleRate:  i32,
	sampleCount: i32,
	samples:     []f32,
}

