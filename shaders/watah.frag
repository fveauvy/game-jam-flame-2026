#include <flutter/runtime_effect.glsl>

uniform vec2 uTileSize;
uniform float uTime;
uniform vec2 uWorldOrigin;

out vec4 fragColor;

void main() {
	vec2 uv = FlutterFragCoord().xy;
	vec2 world = uv + uWorldOrigin;

  vec4 texture_color = vec4(0.59215686, 0.78431373, 0.72941177, 1.0);

  // Fine tune effect movement here
  vec4 k = vec4(uTime)*0.8;

  k.xy = world * .005;

  float val1 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.5));
  float val2 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.2));
  float val3 = length(0.5-fract(k.xyw*=mat3(vec3(-2.0,-1.0,0.0), vec3(3.0,-1.0,1.0), vec3(1.0,-1.0,-1.0))*0.5));

  vec4 color = vec4(pow(min(min(val1, val2), val3), 7.0) * 3.0) + texture_color;

  fragColor = color;
}
