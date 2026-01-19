#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uColor;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Simple glow effect for particle trails
    float glow = 1.0 - length(uv - vec2(0.5));
    glow = pow(glow, 2.0);

    vec3 color = uColor.rgb * glow;
    fragColor = vec4(color, glow * uColor.a);
}
