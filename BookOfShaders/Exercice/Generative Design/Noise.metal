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

float random( float val) {
	return fract(sin(dot(float2(val),float2(12.9898,78.233)))*43758.5453123);
}


float random( float2 val) {
	return fract(sin(dot(val.xy,float2(12.9898,78.233)))*43758.5453123);
}

float random( float2 val, float2 wrt, float scale) {
	return fract(sin(dot(val, wrt))*scale);
}

float drawSmoothRectanglePerimiter(thread float2 &st, float2 LeftBottom, float2 size, float nudge, float borderThickness, float time ) {
	// project position relaitive to center of rectangle 
	// abs because of symetrie
	
	float2 distanceToRectangleBorder = abs(st - (LeftBottom + size*0.5) + rand(0.1*time)*0.01) - size*0.5;
	
	float distance =  length(max(distanceToRectangleBorder,0)) + min(max(distanceToRectangleBorder.x, distanceToRectangleBorder.y),0.0) ;


	return smoothstep(0, 0.01,abs(distance) - borderThickness);
}

float2 random2(float2 val) {
	// projection to two new random vector 
	float2 proj = float2( dot(val, float2(56,78)), dot(val, float2(125.5,89) ) );
	return -1 + 2*fract(sin(proj)*45688.65);
}


float noise(float2 st) {
	float2 i = floor(st); 		// integer
	float2 f = fract(st); 		// fractionalizes
	float2 u = f * f  * (3-2*f); // cubic interpolation

	return mix( mix( dot( random2(i + float2(0.0,0.0) ), f - float2(0.0,0.0) ),
                     dot( random2(i + float2(1.0,0.0) ), f - float2(1.0,0.0) ), u.x),
                mix( dot( random2(i + float2(0.0,1.0) ), f - float2(0.0,1.0) ),
                     dot( random2(i + float2(1.0,1.0) ), f - float2(1.0,1.0) ), u.x), u.y);
}


float shape(float2 st, float time,  float2 origin, float2 size) {
	// if d <= 0 st.x if st outside of segment on the left 
	float d 	= st.x - origin.x;	
	// if out <= 0 st.x if outside of segment
	float out 	= size.x - d;	

	float linewidth = 0.02;

	float newY  = origin.y;
	newY += sin(st.x*40)*noise(st+time*2)*0.5;

	float mod = abs(fmod(st.x+time, 1*PI) + 1*PI)/3.6; 
	newY += sin(st.x*20)*pow(mod,2.0)*0.05;
	 

	float yd    = st.y - (newY) - linewidth;
	

	return smoothstep(0,0.1,d) * smoothstep(0,0.1,out) * ( step(0, yd)-step(0.05,yd) );
} 

[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
	float3 color(0);
	
	float2 st = in.st;
	st *= 2;

//	color = drawSmoothRectanglePerimiter(st,float2(0.25),0.5,0.001,0.001, uniforms.time);

	color = shape(st, 0.5f*uniforms.time, float2(0,0.25), float(5));
	color += shape(st, uniforms.time, float2(0.0,0.75), float(5));
	color += shape(st, 2*uniforms.time, float2(0.0,1.25), float(5));

	return float4(1-color,1);
}