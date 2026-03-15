#include <flutter/runtime_effect.glsl>

uniform vec2 uTileSize;
uniform float uTime;
uniform vec2 uWorldOrigin;

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

void main() {
	vec2 uv = FlutterFragCoord().xy;
	vec2 world = uv + uWorldOrigin;

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

  vec3 darkerTint = base_color * vec3(1., .98, 1.02);
  vec4 texture_color = vec4(mix(base_color, darkerTint, contrastField), 1.0);

  // Fine tune effect movement here
  vec4 k = vec4(uTime)*0.8;

  k.xy = world * .005;

  float val1 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.5));
  float val2 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.2));
  float val3 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.5));

  vec4 color = vec4(pow(min(min(val1, val2), val3), 7.0) * 3.0) + texture_color;

  fragColor = color;
}
