#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uTrauma;
uniform float uWaveIntensity;
uniform float uOpacity;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 center = vec2(0.5, 0.5);
  float dist = distance(uv, center);
  float vignette = smoothstep(0.9, 0.4, dist);

  float scan = sin((uv.y * 800.0) + uTime * 40.0) * 0.04;
  float traumaPulse = uTrauma * (0.6 + 0.4 * sin(uTime * 8.0));
  float wavePulse = uWaveIntensity * (0.3 + 0.2 * sin(uTime * 2.0));

  vec3 color = vec3(0.02, 0.04, 0.06);
  color += vec3(0.0, 0.3, 0.6) * scan;
  color += vec3(0.8, 0.1, 0.6) * traumaPulse;
  color += vec3(0.1, 0.6, 0.9) * wavePulse;

  float alpha = (vignette * 0.2 + scan * 0.1 + traumaPulse * 0.4 + wavePulse * 0.2) * uOpacity;
  alpha = clamp(alpha, 0.0, uOpacity);

  fragColor = vec4(color, alpha);
}
