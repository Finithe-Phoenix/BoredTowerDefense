#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uPointer;
uniform float uWaveIntensity;
uniform float uTowerCount;
uniform float uEnemyCount;
uniform float uTowerPositions[20];
uniform float uEnemyPositions[20];

out vec4 fragColor;

float smoothMin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

float entityField(vec2 fragCoord) {
  float fieldValue = 1e5;
  for (int i = 0; i < 10; i++) {
    float towerMask = step(float(i) + 0.5, uTowerCount);
    float enemyMask = step(float(i) + 0.5, uEnemyCount);

    vec2 towerPos = vec2(uTowerPositions[i * 2], uTowerPositions[i * 2 + 1]);
    vec2 enemyPos = vec2(uEnemyPositions[i * 2], uEnemyPositions[i * 2 + 1]);

    float towerRadius = 60.0 * towerMask;
    float enemyRadius = 48.0 * enemyMask;

    float towerDist = length(fragCoord - towerPos) - towerRadius;
    float enemyDist = length(fragCoord - enemyPos) - enemyRadius;

    towerDist += (1.0 - towerMask) * 1e5;
    enemyDist += (1.0 - enemyMask) * 1e5;

    fieldValue = smoothMin(fieldValue, towerDist, 20.0);
    fieldValue = smoothMin(fieldValue, enemyDist, 20.0);
  }
  return fieldValue;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uResolution;

  const float waveBoost = 0.25;
  const float warpStrength = 0.035;
  const float lineFrequency = 45.0;
  const float chromaScale = 0.02;

  vec2 center = clamp(uPointer / uResolution, vec2(0.0), vec2(1.0));
  vec2 delta = uv - center;
  float warp = sin(uTime * 2.0) * 0.01 + uWaveIntensity * warpStrength;
  uv += delta * warp;

  float shimmer = sin(uv.x * 20.0 + uTime * 2.0) * (0.1 + uWaveIntensity * 0.15);
  float grid =
      step(0.49, fract(uv.y * 40.0)) * step(0.49, fract(uv.x * 40.0));
  float pointerDist = length(uv - center);
  float pulse = smoothstep(0.0, 0.25, 0.08 / max(pointerDist, 0.001));
  float lineGlow =
      (sin(fragCoord.x / uResolution.x * lineFrequency + uTime * 5.0) * 0.5 +
              0.5) *
          0.02;

  float glow = grid * 0.3 +
      shimmer * 0.5 +
      pulse * (0.6 + uWaveIntensity * waveBoost) +
      lineGlow;

  float eField = entityField(fragCoord);
  float entityGlow = smoothstep(0.0, 1.0, 1.0 - eField * 0.02);

  vec3 palette =
      mix(vec3(0.02, 0.04, 0.08), vec3(0.0, 0.8, 0.9), uv.y + uWaveIntensity * 0.1);
  vec3 baseColor = clamp(palette + vec3(
    glow * 0.4,
    glow * (0.6 + uWaveIntensity * 0.2),
    glow
  ), vec3(0.0), vec3(1.0));

  vec3 entityColor = mix(vec3(0.0, 0.4, 0.8), vec3(0.9, 0.2, 0.9), entityGlow);

  float chroma = entityGlow * chromaScale;
  vec3 chromaShift = vec3(chroma, -chroma * 0.5, chroma * 0.8);
  vec3 combined = mix(baseColor, entityColor, entityGlow * 0.6);
  combined += chromaShift;
  combined = clamp(combined, vec3(0.0), vec3(1.0));

  fragColor = vec4(combined, 1.0);
}
