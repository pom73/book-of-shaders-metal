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

#define PI 3.14159265359
#define TWO_PI 6.28318530718

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

float drawPolygone( float2 st, float2 center, int NbSide) {

	float2 _st = st - center;

	float a = atan2(_st.x, _st.y)+PI; //let s be careful using the righ. atan ( output to -PI/+PI )
	
	float r = TWO_PI/float(NbSide);

	float d = cos(floor(0.5+a/r)*r-a)*length(_st);

	return d;
} 




[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
    float2 st = in.st;
	// first center to texture
	st = 2*st - 1; 

	float d = drawPolygone(st, float2(0.1),5);

    return float4(float3(1 -smoothstep(0.4,0.41,d)), 1.0f);
}
  