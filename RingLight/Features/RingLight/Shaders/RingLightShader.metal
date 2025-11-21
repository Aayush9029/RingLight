#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut ringLightVertex(uint vertexID [[vertex_id]]) {
    constexpr float2 positions[4] = {
        float2(-1.0, -1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(1.0, 1.0)
    };

    constexpr float2 texCoords[4] = {
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = texCoords[vertexID];
    return out;
}

struct RingLightUniforms {
    float2 resolution;
    float ringWidth;
    float feather;
    float intensity;
    float peakLuminance;
    float3 color;
    float safeTopInset;
    float cornerRadius;
};

// Signed distance to a rounded rectangle
float sdRoundedBox(float2 p, float2 halfSize, float radius) {
    float2 q = abs(p) - halfSize + radius;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

fragment half4 ringLightFragment(VertexOut in [[stage_in]],
                                 constant RingLightUniforms& uniforms [[buffer(0)]]) {
    float2 coord = in.uv * uniforms.resolution;
    // Account for ring width to prevent clipping into menu bar
    float effectiveTopInset = uniforms.safeTopInset + uniforms.ringWidth;
    float cappedHeight = uniforms.resolution.y - effectiveTopInset;
    if (cappedHeight <= 0.0) {
        return half4(0.0);
    }

    if (coord.y >= cappedHeight) {
        return half4(0.0);
    }

    // Calculate half-size of the visible area
    float2 halfSize = float2(
        uniforms.resolution.x * 0.5,
        cappedHeight * 0.5
    );

    // Transform coordinate to center origin
    float2 center = float2(uniforms.resolution.x * 0.5, cappedHeight * 0.5);
    float2 p = coord - center;

    // Calculate distance to rounded rectangle edge
    float effectiveRadius = clamp(uniforms.cornerRadius, 0.0, min(halfSize.x, halfSize.y));
    float sdf = sdRoundedBox(p, halfSize, effectiveRadius);

    // Convert signed distance to edge distance (inward from edge)
    float edgeDistance = -sdf;

    // Normalize by ring width
    float normalized = clamp(edgeDistance / max(uniforms.ringWidth, 1.0), 0.0, 1.0);

    float clampedFeather = clamp(uniforms.feather, 0.0, 0.95);
    float falloffPower = mix(6.0, 1.5, clampedFeather);
    float falloff = pow(1.0 - normalized, falloffPower);

    float energy = falloff * uniforms.intensity;
    float3 hdrColor = uniforms.color * (uniforms.peakLuminance * energy);
    float alpha = saturate(energy);

    return half4(half3(hdrColor), half(alpha));
}
