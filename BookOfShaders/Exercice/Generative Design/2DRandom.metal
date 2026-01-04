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

#define PI 		3.14159265359
#define TWO_PI  6.28318530718

float plot(float2 st, float f, float halfWidth) {
    float d = f - st.y;
    return smoothstep(-halfWidth, 0.0f, d) -
           smoothstep(0.0f, halfWidth, d);
}

float rand( float val) {
	return fract(sin(val)*100000);
}

float random( float2 val) {
	return fract(sin(dot(val.xy,float2(12.9898,78.233)))*43758.5453123);
}

float random( float2 val, float2 wrt, float scale) {
	return fract(sin(dot(val, wrt))*scale);
}


[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
	float3 color(0);
//	float2 st = in.st*float2(2,1) - float2(1,0);
//	st *= float2(4,2);

//	float y = rand(st.x) * rand(st.x);
//	float y = rand(st.x);

//	color = float3(plot(st, y, 0.02));

//	color = float3(random(in.st));
//	color = float3(random(in.st, uniforms.mouse,43758.5453123));
	color = float3(random(in.st, uniforms.mouse,uniforms.time));

	return float4(color,1);
}