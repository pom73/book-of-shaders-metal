#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float2 resolution;
    float2 mouse;
    float time;
};

struct FragmentIn {
    float4 position [[position]];
    float2 st;
};

float line(float2 st, float halfWidth) {
    // The expression st.y - st.x is exactly 0 on the line y = x.
    // Since a line is infinitely thin, we use smoothstep to blend
    // from  1 along the centerline to 0 a short distance away,
    // thus thickening the line.
    float v = st.y - st.x;
    return smoothstep(-halfWidth, 0.0f, v) -
           smoothstep(0.0f, halfWidth, v);
}

float plot(float2 st, float point, float nudge) {
    return smoothstep(point-nudge, point, st.y) -
           smoothstep(point, point + nudge, st.y);
} 
 
[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
    float2 st = in.st;
    float3 color = float3(0);

//    color = float3(left * bottom);

// bottom-left
    float2 bl = step(float2(0.1),st);
    float pct = bl.x * bl.y;

// top-right
    float2 tr = step(float2(0.1),1.0-st);
    pct *= tr.x * tr.y;

    color = float3(pct);

    return float4(color, 1.0f);
}
