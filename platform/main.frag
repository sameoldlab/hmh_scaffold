#version 460 core
out vec4 FragColor;
uniform vec2 iMouse;
uniform vec2 iResolution;
uniform float iTime;

// https://iquilezles.org/articles/distfunctions2d/
float sdCircle(in vec2 c, in vec2 p, in float r)
{
    return length(c - p) - r;
}

void main() {
    vec2 nMouse = (iMouse / iResolution) * 2. - 1.;
    nMouse.y *= -1;
    nMouse.x *= iResolution.x / iResolution.y;
    vec2 uv = (gl_FragCoord.xy / iResolution) * 2. - 1.;
    uv.x *= iResolution.x / iResolution.y;


    float d = sdCircle(nMouse, uv, 0.5);

    // // coloring
    vec3 col = (d > 0.0) ? vec3(0.09, 0.09, 0.14) : vec3(0.53, .7, 0.97);
    col *= 0.9 - exp(-20.0 * abs(d));
    col *= 0.5 + 0.4 * cos(200.0 * d);
    col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)));

    // FragColor = vec4(iMouse/400., .2, .2);
    FragColor = vec4(col, 1.);
}
