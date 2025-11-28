#version 460 core
out vec4 FragColor;
uniform vec2 iMouse;
uniform vec2 iResolution;
uniform float iTime;

// https://iquilezles.org/articles/distfunctions2d/
float sd_circle(in vec2 p, in float r)
{
    return length(p) - r;
}
float sd_rounded_rect(in vec2 p, in vec2 b, in vec4 r)
{
    r.xy = (p.x > 0.0) ? r.xy : r.zw;
    r.x = (p.y > 0.0) ? r.x : r.y;
    vec2 q = abs(p) - b + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

void main() {
    vec2 nMouse = (iMouse / iResolution) * 2. - 1.;
    nMouse.y *= -1;
    nMouse.x *= iResolution.x / iResolution.y;
    vec2 uv = (gl_FragCoord.xy / iResolution) * 2. - 1.;
    uv.x *= iResolution.x / iResolution.y;

    vec4 bg = vec4(0.09, 0.09, 0.14, 0.) * 2.;

    float d = sd_circle(nMouse - uv, 0.5);
    d = sd_rounded_rect(vec2(0, .98) - uv, vec2(1.5, .04), vec4(0.0));

    float d2 = sd_circle(nMouse - uv, (0.25));

    vec4 fill = vec4(1.53, .7, 0.97, 1.0);

    vec4 col = mix(bg, fill, fill.a * smoothstep(-.005, .005, d * d2));

    // col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)));

    // FragColor = vec4(iMouse/400., .2, .2);
    FragColor = col;
}
