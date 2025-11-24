package platform

import "core:log"
import gl "vendor:OpenGL"

// Get started
// https://learnopengl.com
// Upgrade to 4.6 DSA
// (Direct State Access) and AZDO (Approcahing Zero Driver Overhead)
// https://docs.gl/
// https://antongerdelan.net/opengl/
// https://wikis.khronos.org/opengl/Debug_Output
// SDFs for UI
// https://zed.dev/blog/videogame
// https://hasen.substack.com/p/signed-distance-function-field

Uniforms :: struct {
	mouse:      [2]f32,
	resolution: [2]f32,
	time:       u64,
}

renderer_draw :: proc(program, vao: u32, u: Uniforms = {}) {
	set_uniforms(program, u)
	gl.UseProgram(program)
	gl.BindVertexArray(vao)
	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
	gl.BindVertexArray(0)
}

set_uniforms :: proc(program: u32, u: Uniforms) {
	res := gl.GetUniformLocation(program, "iResolution")
	time := gl.GetUniformLocation(program, "iTime")
	iMouse := gl.GetUniformLocation(program, "iMouse")
	gl.UseProgram(program)
	glUniform(time, f32(u.time))
	glUniform(iMouse, u.mouse.x, u.mouse.y)
	glUniform(res, u.resolution.x, u.resolution.y)
}
glUniform :: proc {
	gl.Uniform1d,
	gl.Uniform1f,
	gl.Uniform2f,
	gl.Uniform3f,
	gl.Uniform4f,
	gl.Uniform1i,
	gl.Uniform2i,
	gl.Uniform3i,
	gl.Uniform4i,
	gl.Uniform1ui,
	gl.Uniform2ui,
	gl.Uniform3ui,
	gl.Uniform4ui,
}

renderer_make_program :: proc() -> (program, vao, vbo: u32, ok: bool) {
	when !ODIN_DEBUG {
		program = create_shader_program(#load("./main.vert"), #load("./main.frag"), true) or_return
	} else {
		program = load_shaders_file("./platform/main.vert", "./platform/main.frag") or_return
	}

	triangle := []f32 {
		// pos           // col
		-0.5, -0.5, 0.0, 1.0, 0.0, 0.0, // BL
		 0.5, -0.5, 0.0, 0.0, 1.0, 0.0, // BR
		 0.0,  0.5, 0.0, 0.0, 0.0, 1.0, // TC
	} 
	
	quad := []f32 {
		 1.0,  1.0, // TR
		 1.0, -1.0, // BR
		-1.0, -1.0, // BL
		-1.0,  1.0, // TL
	}
	indices: []u32 = {
		0, 1, 3,
		1, 2, 3,
	}

	ebo: u32
	gl.CreateVertexArrays(1, &vao)
	gl.CreateBuffers(1, &vbo)
	gl.CreateBuffers(1, &ebo)

	gl.NamedBufferData(vbo, len(quad) * size_of(f32), raw_data(quad), gl.STATIC_DRAW)
	gl.NamedBufferData(ebo, len(indices) * size_of(f32), raw_data(indices), gl.STATIC_DRAW)

	gl.VertexArrayVertexBuffer(vao, 0, vbo, 0, 2 * size_of(f32))
	gl.VertexArrayElementBuffer(vao, ebo)

	gl.EnableVertexArrayAttrib(vao, 0)
	gl.VertexArrayAttribFormat(vao, 0, 2, gl.FLOAT, gl.FALSE, 0)
	gl.VertexArrayAttribBinding(vao, 0, 0)

	return program, vao, vbo, true
}

load_shaders_file :: proc(
	vs_filename, fs_filename: string,
	binary_retrievable := false,
) -> (
	program_id: u32,
	ok: bool,
) {
	vert_data := os.read_entire_file(vs_filename) or_return
	defer delete(vert_data)

	frag_data := os.read_entire_file(fs_filename) or_return
	defer delete(frag_data)

	return create_shader_program(string(vert_data), string(frag_data), binary_retrievable)
}

create_shader_program :: proc(
	vertex_src, fragment_src: string,
	binary_retrievable := false,
) -> (
	shader_program: u32,
	ok: bool,
) {
	vertex_shader := compile_shader(vertex_src, .VERTEX_SHADER) or_return
	defer gl.DeleteShader(vertex_shader)
	fragment_shader := compile_shader(fragment_src, .FRAGMENT_SHADER) or_return
	defer gl.DeleteShader(fragment_shader)

	shader_program = gl.CreateProgram()
	gl.AttachShader(shader_program, vertex_shader)
	gl.AttachShader(shader_program, fragment_shader)
	gl.LinkProgram(shader_program)

	if binary_retrievable {
		gl.ProgramParameteri(shader_program, gl.PROGRAM_BINARY_RETRIEVABLE_HINT, 1)
	}

	success: i32
	gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetProgramInfoLog(shader_program, len(info_log), nil, raw_data(info_log[:]))
		log.errorf("Program linking failed: %s", cstring(raw_data(info_log[:])))
		return 0, false
	}

	return shader_program, true
}

compile_shader :: proc(source: string, shader_type: gl.Shader_Type) -> (shader: u32, ok: bool) {
	shader = gl.CreateShader(u32(shader_type))
	length := i32(len(source))
	copy := cstring(raw_data(source))

	gl.ShaderSource(shader, 1, &copy, &length)
	gl.CompileShader(shader)

	success: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetShaderInfoLog(shader, len(info_log), nil, raw_data(info_log[:]))
		log.errorf("Shader compilation failed: %s", cstring(raw_data(info_log[:])))
		return 0, false
	}
	return shader, true
}

