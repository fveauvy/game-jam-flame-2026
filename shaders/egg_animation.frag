#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    float wobble = sin(uTime);

    const vec2 kShadowCenter = vec2(0.5, 0.82);
    const vec2 kShadowRadius = vec2(0.3, 0.2);
    float kShadowOpacity = clamp(-wobble, 0.1, 0.16);
    float feather = mix(0.12, 1.0, (wobble + 1.0) * 0.5);
    vec2 shadowRadius = vec2(
        kShadowRadius.x * mix(0.7, 1.5, (wobble + 1.0) * 0.5),
        kShadowRadius.y * mix(0.6, 1.1, (wobble + 1.0) * 0.5)
    );

    // Elliptical bottom shadow anchored in local UV space.
    vec2 shadowOffset = (uv - kShadowCenter) / shadowRadius;
    float shadowMask = clamp(1.0 - dot(shadowOffset, shadowOffset), 0.0, 1.0);
    shadowMask = smoothstep(0.0, feather, shadowMask);

    // Keep the animated offset sample for the egg texture.
    vec4 updatePos = texture(uTexture, uv + vec2(0.01 * wobble, 0.1 * wobble));

    // Shadow only appears where the egg is transparent.
    float backgroundAlpha = 1.0 - updatePos.a;
    float shadowAlpha = kShadowOpacity * shadowMask * backgroundAlpha;

    vec3 color = mix(updatePos.rgb, vec3(0.0), shadowAlpha * backgroundAlpha);
    float alpha = max(updatePos.a, shadowAlpha);

    fragColor = vec4(color, alpha);
}
