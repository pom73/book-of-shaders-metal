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

// let s compute distance to center of the rectangle ( abs because of similitude on axis ) 

float distanceToRect( float2 p, float2 leftBottom, float2 size ) {
	float2 pRelativeToCenter = abs(p - (leftBottom + 0.5*size)) - 0.5*size;
	float outside = length(max(pRelativeToCenter,0.));
	float inside  = min(max(pRelativeToCenter.x, pRelativeToCenter.y),0.);
	return outside + inside;
}


float drawSmoothRectangleFull(thread float2 &st, float2 leftBottom, float2 size, float nudge ) {

	float distance = distanceToRect(st, leftBottom, size);
	return smoothstep(0, nudge, distance);
}


float drawBox(float2 st, float2 size){
    float2 _size = float2(0.5) - size*0.5;
    float2 uv = smoothstep(_size,
                        	_size+float2(0.001),
                        	st);
    uv *= smoothstep(_size,
                    _size+float2(0.001),
                    float2(1.0)-st);
    return uv.x*uv.y;
}

float drawCross(float2 st, float size) {
    return drawBox(st, float2(size, size/4)) + drawBox(st, float2(size/4, size));
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
	float2 translate = float2(cos(uniforms.time), sin(uniforms.time));

	st += translate*0.35;
	// first center to texture
//	st = 2*st - 1; 

	float d = drawPolygone(st, float2(0.1),5);

	d = drawBox(st, float2(0.25, 0.5));

 	d = drawCross(st, 0.25);
    return float4(float3(d), 1.0f);
}
  