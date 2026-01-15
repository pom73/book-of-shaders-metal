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

float OneRandom( float2 val) {
	return random(val, float2(12.95,79.45), 48623.545864);
//	return random(val, float2(12.9898,78.233),43758.5453123);
}




float noise(float2 st) {
	float2 i = floor(st); 		// integer
	float2 f = fract(st); 		// fractionalizes

	/* 
	c -------------- d
	|				  |	
	|	f			  |	
	|				  |
	a -------------- b		
 
	*/
	float a = OneRandom(i);						// left corner 
	float b = OneRandom(i + float2(1,0));		// right corner
	float c = OneRandom(i + float2(0,1));		// top left corner
	float d = OneRandom(i + float2(1,1));		// top right corner


	float2 u = smoothstep(0,1,f);

	return mix(a,b,u.x) + (c-a)*u.y*(1.0-u.x) + (d-b)*u.x*u.y;
}


float2 noiseGradient(float2 st)
{
    float2  i = floor(st);
    float2 f = fract(st);

    // Corner values
    float a = OneRandom(i);
    float b = OneRandom(i + float2(1,0));
    float c = OneRandom(i + float2(0,1));
    float d = OneRandom(i + float2(1,1));

    // Fade and its derivative
    float2 u  = f * f * (3.0 - 2.0 * f);          // fade
    float2 du = 6.0 * f - 6.0 * f * f;            // du/df

    // Differences
    float tx = a - b;   // bottom edge slope (a→b)
    float ty = c - d;   // top edge slope   (c→d)

    // Bottom‑edge = mix(a,b,u.x)  →  a + (b-a)u.x
    // Top‑edge    = mix(c,d,u.x)  →  c + (d-c)u.x
    // Noise = mix(bottom,top,u.y)

    // Derivative wrt f.x
    float dNdx = (1.0 - u.y) * (tx * du.x) + u.y * (ty * du.x);

    // Derivative wrt f.y
    float dNdy = (ty * u.x) - (tx * u.x);         // because N = bottom*(1-u.y)+top*u.y
    dNdy += (1.0 - u.x) * du.y * (a + tx * u.x)   // bottom edge slope
          + u.x * du.y * (c + ty * u.x);          // top edge slope

    return float2(dNdx, dNdy);
}


float3 distanceField( float2 st) {
	float n      = noise(st);                // 0‑1
    float2 gradN   = noiseGradient(st);        // analytic gradient

    // 1) build signed level‑set function Φ
    float phi = n - 0.5;

    // 2) approximate signed distance
    float len = length(gradN);
    float dist = (len > 0.0) ? phi / len : 0.0;   // avoid divide‑by‑0

    // 3) optional normalisation (so that 0..1 maps to colour)
    float dNorm = 0.5 + 0.5 * dist;      // 0 at surface, -1→1 range

    // 4) clamp to a safe range for visualisation
    float dClamped = clamp(dNorm, -1.0, 1.0);

    // 5) colour
    return  mix(float3(0), float3(1,0,0), smoothstep(-0.1,0.2,dClamped));
}



[[fragment]]
float4 fragment_main(FragmentIn in [[stage_in]],
                     constant Uniforms &uniforms [[buffer(0)]])
{
	float3 color(0);
	
	float2 st = in.st;
	//st += float2(0.03,0.5);
//	st *= 5*(1+abs(5*sin(uniforms.time)));
	st *= float2(4,1);

//	color = noise(st);
	color = float3(noiseGradient(st),1);
	color =	distanceField(st);
	return float4(color,1);
}