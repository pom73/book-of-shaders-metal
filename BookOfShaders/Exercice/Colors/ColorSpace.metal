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


constant float3x3 yuv2rgb = float3x3(	1.0, 0.0, 1.13983,
                    		1.0, -0.39465, -0.58060,
                    		1.0, 2.03211, 0.0);

constant float3x3 rgb2yuv = float3x3(	0.2126, 0.7152, 0.0722,
                    		-0.09991, -0.33609, 0.43600,
                    		0.615, -0.5586, -0.05639);



[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]]) {

	float3 color(0);
	float2 st = in.st;

	st -= 0.5;
	st *= 2;

	color = yuv2rgb * float3(0.5, st.x,st.y);

	return float4(color, 1.0f);
}