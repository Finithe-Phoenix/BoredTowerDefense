#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 345.45));
  p += dot(p, p + 34.345);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  float t = uTime * 0.5;
  float trail = 0.0;

  for (int i = 0; i < 3; i++) {
    float scale = pow(2.0, float(i));
    vec2 p = uv * scale * 6.0 + vec2(t * 0.7, -t * 0.4);
    trail += noise(p) / scale;
  }

  float glow = smoothstep(0.7, 1.0, trail);
  vec3 color = mix(vec3(0.02, 0.05, 0.08), vec3(0.0, 0.8, 1.0), glow);
  fragColor = vec4(color, glow * 0.6);
}
