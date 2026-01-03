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

void rotate(thread float2 &v, float angle) {
	float2x2 rotation = float2x2{ float2(cos(angle), sin(angle)),
								   float2(-sin(angle), cos(angle)) };

	v = rotation * v;
} 

[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
    float2 st = in.st;
	//rotate(st,uniforms.time);
    // Start by shading the background with a horizontal gray gradient
    float3 color = float3(0);

	float2 pos  =  float2(0.5) - st;
	rotate(pos,uniforms.time);

	float r  = length(pos)*2;
	float a  = atan2( pos.y,pos.x);
	
	float f = cos(3*a);
//f = abs(cos(a*3.));
//f = abs(cos(a*2.5))*0.5+0.3;
//f = abs(cos(a*12.)*sin(a*3.))*.8+.1;
f = smoothstep(-.5,1., cos(a*10.))*0.2+0.5;

	color = 1-float3(smoothstep(f-0.02,f,r) - smoothstep(f,f+0.02,r));
    return float4(color, 1.0f);
}
