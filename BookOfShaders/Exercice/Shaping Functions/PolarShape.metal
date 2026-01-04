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
	float2x2 rotation = float2x2{ float2(cos(angle), -sin(angle)),
								   float2(sin(angle), cos(angle)) };

	v = rotation * v;
} 


void scale(thread float2 &v, float scalefactor) {
	float2x2 scale = float2x2{ float2(scalefactor, 0),
								float2(0, scalefactor) };

	v = scale * v;
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
	// first center to texture
	st = float2(0.5) - st; 
	rotate(st, sin(uniforms.time));


	float r = length(st)*2;
	float a = atan2(st.y,st.x); //let s be careful using the righ. atan ( output to -PI/+PI )

	float f =  cos(a*3);
	//f = abs(cos(a*2.5))*0.5+0.3; // flower
	//f = abs(cos(a*12.)*sin(a*3.))*.8+.1; //more petals
	//f = smoothstep(-.5,1., cos(a*10.))*0.2+0.5; // let s gear it up

	// plotting the x,y where radius is closed to cos(3*angle)
	float3 color = float3(1-smoothstep(f, f+0.02, r)); 

	color = float3(-smoothstep(f, f+0.02, r)+smoothstep(f-0.02,f,r)); 
	color = float3(plot(st,f,0.10));
    return float4(color, 1.0f);
}
  