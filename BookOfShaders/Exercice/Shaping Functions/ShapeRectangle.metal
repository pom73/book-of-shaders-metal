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

float drawRectangle(thread float2 &st, float2 LeftBottom, float2 size ) {
	float2 top = step( LeftBottom, st);
	float2 top2= 1 - step( LeftBottom + size, st); 	

	return top.x*top.y*top2.x*top2.y;
}

float drawSmoothRectangle(thread float2 &st, float2 LeftBottom, float2 size, float nudge ) {
	float2 top = smoothstep(LeftBottom-nudge, LeftBottom, st);
	float2 top2= 1 - smoothstep( LeftBottom + size, LeftBottom + size+ nudge, st); 
	return top.x*top.y*top2.x*top2.y;
}

float drawSmoothRectanglePerimiter(thread float2 &st, float2 LeftBottom, float2 size, float nudge, float borderThickness ) {

	// project position relaitive to center of rectangle 
	// abs because of simlitude
	
	float2 distanceToRectangleBorder = abs(st - (LeftBottom + size*0.5)) - size*0.5;

	
	float distance =  length(max(distanceToRectangleBorder,0)) + min(max(distanceToRectangleBorder.x, distanceToRectangleBorder.y),0.0);

	return smoothstep(0, 0.01,abs(distance) - borderThickness);
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

float drawSmoothRectanglePerimeter(thread float2 &st, float2 leftBottom, float2 size, float nudge ) {

	float distance = distanceToRect(st, leftBottom, size);
	return smoothstep(0, nudge, abs(distance));
}


[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
    float2 st = in.st;
    float3 color = float3(0);

//		color = float3(drawRectangle(st, float2(abs(1-cos(uniforms.time))*0.5, abs(sin(uniforms.time))*0.5), float2(0.5) ));
//		color = float3(drawSmoothRectangle(st, float2(abs(1-cos(uniforms.time))*0.5, abs(sin(uniforms.time))*0.5), float2(0.5) ));
//    	color = float3(drawRectangle(st, float2(0.25, 0.25), float2(0.5) ));
//    	color = float3(drawSmoothRectangle(st, float2(0.25, 0.25), float2(0.5), 0 ));
//    	color = float3(drawSmoothRectanglePerimiter(st, float2(0.1, 0.1), float2(0.15), 0 , 0.01));
//    	color = float3(drawSmoothRectangle(st, float2(0, 0), float2(0.1), 0 ));
//    color = float3(drawSmoothRectangleFull(st, float2(0.2, 0.2), float2(0.15), 0));
    color = float3(drawSmoothRectanglePerimeter(st, float2(0.2, 0.2), float2(0.15), 0.01));



    return float4(color, 1.0f);
}

