#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uOutlineWidth;
uniform vec4 uOutlineColor;
uniform float uTime;
uniform vec2 uRippleCenterUv;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
	vec2 uv = FlutterFragCoord().xy / uSize;

	vec4 center = texture(uTexture, uv);
	float alpha = center.a;

	vec2 px = vec2(1.0 / uSize.x, 1.0 / uSize.y) * uOutlineWidth;

	float neighborAlpha = 0.0;
	neighborAlpha = max(neighborAlpha, texture(uTexture, uv + vec2(px.x, 0.0)).a);
	neighborAlpha = max(neighborAlpha, texture(uTexture, uv + vec2(-px.x, 0.0)).a);
	neighborAlpha = max(neighborAlpha, texture(uTexture, uv + vec2(0.0, px.y)).a);
	neighborAlpha = max(neighborAlpha, texture(uTexture, uv + vec2(0.0, -px.y)).a);
	neighborAlpha = max(neighborAlpha, texture(uTexture, uv + vec2(px.x, px.y)).a);
	neighborAlpha = max(neighborAlpha, texture(uTexture, uv + vec2(px.x, -px.y)).a);
	neighborAlpha = max(neighborAlpha, texture(uTexture, uv + vec2(-px.x, px.y)).a);
	neighborAlpha = max(neighborAlpha, texture(uTexture, uv + vec2(-px.x, -px.y)).a);

	float outlineMask = (1.0 - alpha) * step(0.01, neighborAlpha);
	vec2 centerUv = uRippleCenterUv;
	float distToCenter = distance(uv, centerUv);

	float cycle = fract(uTime * 1.2);
	float waveRadius = cycle * 0.75;
	float ringDistance = abs(distToCenter - waveRadius);
	float ring = 1.0 - smoothstep(0.0, 0.06, ringDistance);
	float rippleAlpha = ring * (1.0 - cycle);

	vec4 outlined = mix(
		center,
		uOutlineColor,
		outlineMask * uOutlineColor.a * rippleAlpha
	);

	fragColor = outlined;
}
