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




float distanceToCircle(float2 p, float2 center, float radius) {
	float2 delta = abs(p-center);
	float distance =1 - length(delta)/radius;
	return distance;
}

float drawCircle(float2 p, float2 center, float radius) {
	float distance = distanceToCircle(p, center, radius);

	return step(0,distance);
}

float drawCirclePerimeter(float2 p, float2 center, float radius, float borderThickness) {
	float distance = distanceToCircle(p, center, radius);

	return step(0,distance) - step(borderThickness, distance);
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
//    color = float3(drawSmoothRectanglePerimeter(st, float2(0.2, 0.2), float2(0.15), 0.01));
//	color = float3(drawCircle(st, float2(0.5), 0.49));
	color = float3(drawCirclePerimeter(st, float2(0.5), 0.49, 0.01));


    return float4(color, 1.0f);
}

