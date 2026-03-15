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

vec4 _mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float _mod289f(float x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 _permute(vec4 x) {
  return _mod289(((x * 34.0) + 1.0) * x);
}

vec4 _taylorInvSqrt(vec4 r) {
  return 1.79284291400159 - 0.85373472095314 * r;
}

float simplexNoise3D(vec3 v) {
  const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

  vec3 i = floor(v + dot(v, C.yyy));
  vec3 x0 = v - i + dot(i, C.xxx);

  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);

  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy;
  vec3 x3 = x0 - D.yyy;

  i = vec3(_mod289f(i.x), _mod289f(i.y), _mod289f(i.z));
  vec4 p = _permute(
    _permute(_permute(
      vec4(i.z, i.z + i1.z, i.z + i2.z, i.z + 1.0)
    ) + vec4(i.y, i.y + i1.y, i.y + i2.y, i.y + 1.0))
    + vec4(i.x, i.x + i1.x, i.x + i2.x, i.x + 1.0)
  );

  float n_ = 1.0 / 7.0;
  vec3 ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_);

  vec4 x = x_ * ns.x + ns.yyyy;
  vec4 y = y_ * ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);

  vec4 s0 = floor(b0) * 2.0 + 1.0;
  vec4 s1 = floor(b1) * 2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
  vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);

  vec4 norm = _taylorInvSqrt(
    vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3))
  );
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

  vec4 m = max(
    0.5 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)),
    0.0
  );
  m = m * m;

  return 105.0 * dot(
    m * m,
    vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3))
  );
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

    // Layer 2: simplex-noise warp — organic turbulent distortion.
      float noiseScale = minExtent * 0.035;
      vec3 simplexCoord = vec3(world * 0.006, uTime * 0.4);
    vec2 noiseWarp = vec2(
      simplexNoise3D(simplexCoord + vec3(phase, 0.0, 0.0)),
      simplexNoise3D(simplexCoord + vec3(0.0, phase, 17.0))
    ) * noiseScale;

    vec2 warpedWorld = world + noiseWarp;

    // Re-compute inset on the warped position for distorted ring shapes.
    float warpedInset = min(
      min(warpedWorld.x - puddle.x, puddle.z - warpedWorld.x),
      min(warpedWorld.y - puddle.y, puddle.w - warpedWorld.y)
    );

    // Thin rings traveling inward from the edge.
    float wave = pow(max(0.0, sin(
      warpedInset * 0.07 + -uTime * 1.1 + phase * 6.2831853
    )), 24.0);

    // Fade steeply as rings travel away from the edge.
    float fade = exp(-insetDist * 0.1);

    ripple = max(ripple, wave * fade);
  }

  return ripple;
}

float edgeMudShadowAtWorld(vec2 world) {
  int count = int(uPuddleCount);
  float shadow = 0.0;

  for (int i = 0; i < 32; i++) {
    if (i >= count) {
      break;
    }

    vec4 puddle = uPuddles[i];
    float minExtent = min(puddle.z - puddle.x, puddle.w - puddle.y);

    float insetDist = min(
      min(world.x - puddle.x, puddle.z - world.x),
      min(world.y - puddle.y, puddle.w - world.y)
    );
    if (insetDist < 0.0) {
      continue;
    }

    // Very thin border shadow at puddle extremities.
    float edgeWidth = max(1.2, minExtent * 0.06);
    float edgeMask = 1.0 - smoothstep(0.0, edgeWidth, insetDist);
    float breakup = 0.1 + 0.9 * valueNoise(
      world * 0.05 + vec2(float(i) * 2.17, uTime * 0.015)
    );

    shadow = max(shadow, edgeMask * breakup);
  }

  return shadow;
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
    noiseUv * 0.55 + vec2(-uTime * 0.02, uTime * 0.035) + 59.7
  );

  float mixedField = mix(largeField, broaderField, 0.76);

  float contrastField = smoothstep(0.1, 0.8, mixedField);

  vec3 darkerTint = base_color * vec3(.85, .9, .85);
  vec4 texture_color = vec4(mix(base_color, darkerTint, contrastField), 1.0);

  // Fine tune effect movement here
  vec4 k = vec4(uTime)*0.8;

  k.xy = world * 0.05;

  float val1 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.4));
  float val2 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.2));
  float val3 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.5));

  vec4 color = vec4(pow(min(min(val1, val2), val3), 8.0) * 1.0) + texture_color;

  float mudShadow = edgeMudShadowAtWorld(world);
  color.rgb = mix(color.rgb, color.rgb * vec3(0.92, 0.4, 0.34), mudShadow * 0.35);

  float ripple = rippleStrengthAtWorld(world);

  color.rgb = clamp(
    color.rgb + vec3(0.25, 0.9, 1.0) * ripple * 1.3,
    0.0,
    1.0
  );

  fragColor = color;
}
