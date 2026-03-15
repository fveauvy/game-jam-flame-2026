#include <flutter/runtime_effect.glsl>

uniform vec2 uTileSize;
uniform float uTime;
uniform vec2 uWorldOrigin;
uniform float uRectCount;
uniform vec4 uRects[32];
uniform float uPuddleCount;
uniform vec4 uPuddles[32];

out vec4 fragColor;

float hash12(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float valueNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);

  float a = hash12(i + vec2(0.0, 0.0));
  float b = hash12(i + vec2(1.0, 0.0));
  float c = hash12(i + vec2(0.0, 1.0));
  float d = hash12(i + vec2(1.0, 1.0));

  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

bool isInsideWater(vec2 world) {
  int count = int(uRectCount);
  for (int i = 0; i < 32; i++) {
    if (i >= count) {
      break;
    }

    vec4 rect = uRects[i];
    bool insideX = world.x >= rect.x && world.x < rect.z;
    bool insideY = world.y >= rect.y && world.y < rect.w;
    if (insideX && insideY) {
      return true;
    }
  }
  return false;
}

float rippleStrengthAtWorld(vec2 world) {
  int count = int(uPuddleCount);
  float ripple = 0.0;

  for (int i = 0; i < 32; i++) {
    if (i >= count) {
      break;
    }

    // uPuddles stores (left, top, right, bottom) of the puddle bounding box.
    vec4 puddle = uPuddles[i];
    float phase = hash12(puddle.xy);
    float minExtent = min(puddle.z - puddle.x, puddle.w - puddle.y);

    // Inset distance: positive inside the bbox, negative outside.
    float insetDist = min(
      min(world.x - puddle.x, puddle.z - world.x),
      min(world.y - puddle.y, puddle.w - world.y)
    );
    if (insetDist < 0.0) {
      continue;
    }

    // Layer 1: sin-based warp — smooth directional waves.
    float warpScale = minExtent * 0.01;
    vec2 sinWarp = vec2(
      sin(world.y * 0.03 + uTime * 0.7 + phase * 3.14) * warpScale,
      sin(world.x * 0.03 - uTime * 0.5 + phase * 2.71) * warpScale
    );

    // Layer 2: value-noise warp — organic turbulent distortion.
    float noiseScale = minExtent * 0.018;
    vec2 noiseCoord = world * 0.012 + vec2(uTime * 0.08, -uTime * .06);
    vec2 noiseWarp = vec2(
      (valueNoise(noiseCoord + vec2(0.0, phase)) - 0.5) * noiseScale,
      (valueNoise(noiseCoord + vec2(phase, 0.0)) - 0.5) * noiseScale
    );

    vec2 warpedWorld = world + sinWarp + noiseWarp;

    // Re-compute inset on the warped position for distorted ring shapes.
    float warpedInset = min(
      min(warpedWorld.x - puddle.x, puddle.z - warpedWorld.x),
      min(warpedWorld.y - puddle.y, puddle.w - warpedWorld.y)
    );

    // Thin rings traveling inward from the edge.
    float wave = pow(max(0.0, sin(
      warpedInset * 0.07 + -uTime * 2.5 + phase * 6.2831853
    )), 24.0);

    // Fade steeply as rings travel away from the edge.
    float fade = exp(-insetDist * 0.08);

    ripple = max(ripple, wave * fade);
  }

  return ripple;
}

void main() {
	vec2 uv = FlutterFragCoord().xy;
	vec2 world = uv + uWorldOrigin;

  if (!isInsideWater(world)) {
    fragColor = vec4(0.0);
    return;
  }

  vec3 base_color = vec3(0.59215686, 0.78431373, 0.72941177);

  vec2 safeTileSize = max(uTileSize, vec2(1.0, 1.0));
  vec2 noiseUv = world / safeTileSize;

  // Wide smooth fields: low-frequency value noise + smooth contrast mapping.
  float largeField = valueNoise(
    noiseUv * 1.35 + vec2(uTime * 0.045, -uTime * 0.03)
  );

  float broaderField = valueNoise(
    noiseUv * 0.55 + vec2(-uTime * 0.02, uTime * 0.035) + 19.7
  );

  float mixedField = mix(largeField, broaderField, 0.76);

  float contrastField = smoothstep(0.1, 0.8, mixedField);

  vec3 darkerTint = base_color * vec3(.8, .98, 1.02);
   vec4 texture_color = vec4(mix(base_color, darkerTint, contrastField), 1.0);
  // vec4 texture_color = vec4(0.,0.,0., 1.0);

  // Fine tune effect movement here
  vec4 k = vec4(uTime)*0.8;

  k.xy = world * .005;

  float val1 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.5));
  float val2 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.2));
  float val3 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.5));

  vec4 color = vec4(pow(min(min(val1, val2), val3), 7.0) * 3.0) + texture_color;

  float ripple = rippleStrengthAtWorld(world);

  color.rgb = clamp(
    color.rgb + vec3(0.9, 0.95, 1.0) * ripple * 2.5,
    0.0,
    1.0
  );

  fragColor = color;
}
