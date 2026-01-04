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

float2 gridSpaceOffset(thread float2& st, float2 gridsize, float offset ) {
	st *= gridsize;

	st.x += step(1, fmod(st.y,2))*offset;
	
    return fract(st);  
}


[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
	float3 color = float3(0);
	float2 _st = in.st;
	
	//float2 st = gridSpaceOffset(_st, float2(5.0,5.0), 0.5);
	// time deformation

	_st *= float2(10.0,10.0);

	float row  = floor(_st.y);
	float col  = floor(_st.x);

	_st.x += max(0.0, step(1,fmod(_st.y,2))*sin(uniforms.time));
    _st.y += min(0.0, step(1,fmod(_st.x,2))*sin(uniforms.time));


	color = float3(drawCircle(fract(_st),float(0.5),0.25));

	
//	float2 st = gridSpaceOffset(_st, float2(5.0,5.0), 0.5);
//	float row  = floor(_st.y);
//	_st.x += (fmod(row,2.0) == 0 ? 1 : -1) *0.25*uniforms.time;
//	color = float3(drawBox(st,float2(0.9)));

    return float4(color,1.0);
}
