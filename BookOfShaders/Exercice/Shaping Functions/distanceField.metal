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



[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
    float2 st = in.st;
    float y = st.x;

	st = 2*st - 1; // switch coordinate from -1 to 1 

	// compute norm and since it s -1 to 1, centered to texture and 
	// fun stuff depending on the offset 
	float d = length(abs(st) - 0.3);
	d = length(min(abs(st)-0.3,0));
	d = length(max(abs(st)-0.3,0));

    // Start by shading the background with a horizontal gray gradient
    float3 color = float3(fract(d*10));

//Other fun distance field visualisation 

	color = float3(step(0.3,d)); // visu of points wehre norm > 0.3.
	color = float3(step(0.3,d)*step(0.6,d)); // visu of points wehre norm > 0.3 & > 0.6.
	color = float3(smoothstep(0.1,0.4,d)); // visu of points wehre norm > 0.3 & > 0.6.


    return float4(color, 1.0f);
}
