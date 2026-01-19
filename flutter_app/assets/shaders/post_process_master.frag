#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D uTexture;
uniform float uBloomIntensity;
uniform float uVignetteIntensity;
uniform float uScanlineIntensity;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Sample the texture
    vec4 color = texture(uTexture, uv);

    // Vignette effect
    vec2 vignetteUV = uv * (1.0 - uv.yx);
    float vignette = vignetteUV.x * vignetteUV.y * 15.0;
    vignette = pow(vignette, uVignetteIntensity * 0.5);
    color.rgb *= vignette;

    // Scanlines
    float scanline = sin(uv.y * uResolution.y * 2.0) * 0.5 + 0.5;
    color.rgb -= scanline * uScanlineIntensity * 0.1;

    // Simple bloom approximation
    color.rgb += color.rgb * uBloomIntensity * 0.2;

    fragColor = color;
}
