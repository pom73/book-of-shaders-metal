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
constant float rotation[4] = {0,PI/2,-PI/2,PI};

void rotate(thread float2 &v, float angle) {
	float2x2 rotation = float2x2{ float2(cos(angle), -sin(angle)),
								   float2(sin(angle), cos(angle)) };

	v = rotation * v;
} 

float2 tile( float2 _st, float _zoom) { _st *= _zoom; return fract(_st);}
float2 rotate2D(float2 _st, float _angle) { _st -= 0.5; _st = float2x2{ float2(cos(_angle), -sin(_angle)),
								   float2(sin(_angle), cos(_angle)) }* _st; _st += 0.5;return _st; }

float2 rotateTilePattern(float2 _st) {
	_st *= 2.0;
	float index = 0;
// compute into which quadrants your are 
	index += step(1, fmod(_st.x,2.0)); 
	index += step(1, fmod(_st.y,2.0))*2.0;
	
	_st = fract(_st); // compute new coordinate inside this 2x2 world

	// rotate according to quadrants 
	_st = rotate2D(_st, rotation[int(index)]);
	return _st;
}



[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
	float3 color = float3(0);
	float2 st = in.st;

	//st *= float2(3); // 3x3 cells
	//st = fract(st);	 // inside that cell what is the coordinnate 

	//st *= 2;			// doubling each cells
	//float index = 0; 	// computing quadrants 

	//      |
    //  2   |   3
    //      |
    //--------------
    //      |
    //  0   |   1
    //      |

	//index += step(1, fmod(st.x,2.0));
	//index += step(1, fmod(st.y,2.0))*2.0;

	//st = fract(st); // recomputing coordinate in this new 2x2 

	//st -= 0.5; // centered 
	//rotate(st, rotation[int(index)]);
	//st += 0.5; // put back where it was 

	//
//	st = tile(st,3.0);
//	st = rotateTilePattern(st);

	 //st = tile(st,2.0);
     st = rotate2D(st,-PI*uniforms.time*0.25);
     st = rotateTilePattern(st*2.);
     st = rotate2D(st,PI*uniforms.time*0.25);


	color = float3(step(st.x,st.y));
    return float4(color,1.0);
}
