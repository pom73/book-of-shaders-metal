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


float drawCircle(float2 st, float2 center, float radius)
{
	return step(radius, length(center-st));
}

float drawSmoothCircle(float2 st, float2 center, float radius)
{
	return smoothstep(0, radius, length(center-st));
}
 
float drawPerimeterCircle(float2 st, float2 center, float radius)
{
	return smoothstep(radius-0.01, radius, length(center-st)) - 
		   smoothstep(radius, radius+0.01, length(center-st));
}

float drawDisc(float2 _st,float2 center, float _radius){
    float2 dist = _st-center;
	return smoothstep(_radius-(_radius*0.01),
                         _radius+(_radius*0.01),
                         dot(dist,dist)*2);
}

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


// float2 (col , row)
float2 gridSpace(thread float2& st, float2 gridsize ) {
	st *= gridsize;
    return fract(st);  
}


[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
	float3 color = float3(0);
	float2 _st = in.st;
//	rotate(st,PI/4);	

	float2 st = gridSpace(_st, float2(3.0,3.0));

	float row = floor(_st.x);
	float col = floor(_st.y);
	color = float3(st,0);

	color *= (row == 1 && col == 1) ? drawDisc(st, float2(row*0.5, col*0.5), 0.25) : 1;

// from 0 to 3 
//	st *= 3.;

// fract 0 ≤ st < 1 = 0. ... 0.9
// fract 1 ≤ st < 2 = 0. ... 0.9
// fract 2 ≤ st < 3 = 0. ... 0.9

    return float4(color,1.0);
}
