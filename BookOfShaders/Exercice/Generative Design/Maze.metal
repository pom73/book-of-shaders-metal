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


float2 truchetPattern(float2 _st, float _index){

    _index = fract(((_index-0.5)*2.0));

    if (_index > 0.75) {
        _st = float2(1.0) - _st;
    } else if (_index > 0.5) {
        _st = float2(1.0-_st.x,_st.y);
    } else if (_index > 0.25) {
        _st = 1.0-float2(1.0-_st.x,_st.y);
    }
    return _st;
}


[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
	float3 color(0);
	
	float2 st = in.st;

	st *= 10;
	
	st = (st-float2(5.0))*(abs(sin(uniforms.time*0.2))*5.);
	st.x += uniforms.time;

	float2 iPos = floor(st); 
	float2 fPos = fract(st); 

	float2 tile = truchetPattern(fPos,random(iPos));


	color = smoothstep(tile.x-0.3, tile.x, tile.y) - smoothstep(tile.x, tile.x+0.3, tile.y);
	//color = float3(fPos,0);
	//color = float3(iPos,0);
	
// Circles
    color = (step(length(tile),0.6) -
              step(length(tile),0.4) ) +
             (step(length(tile-float2(1.)),0.6) -
              step(length(tile-float2(1.)),0.4) );

    // Truchet (2 triangles)
    //color = step(tile.x,tile.y);


	return float4(color,1);
}