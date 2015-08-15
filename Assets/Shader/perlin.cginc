#ifndef PERLIN_LOOKUP_HASH
#define PERLIN_LOOKUP_HASH _PerlinLookupHash
#endif
#ifndef PERLIN_LOOKUP_GRAD
#define PERLIN_LOOKUP_GRAD _PerlinLookupGrad
#endif

uniform sampler2D PERLIN_LOOKUP_GRAD;
uniform sampler2D PERLIN_LOOKUP_HASH;

inline float grad(float x, float3 pt) {
	return dot(round(tex2Dlod(PERLIN_LOOKUP_GRAD, float4(x/256.0f, 0, 0, 0)) * 2 - 1), pt);
}

inline float fade(float t) {
	return t * t * t * (t * (t * 6 - 15) + 10);
}

inline float p(float x) {
	return tex2Dlod(PERLIN_LOOKUP_HASH, float4(x / 256.0f, 0, 0, 0)).r * 256.0f;
}

float perlin(float3 pf) {
	float3 pi = fmod(floor(pf),256.0);
	pf -= floor(pf);
	float3 f = float3(fade(pf.x), fade(pf.y), fade(pf.z));
	
	int a   = p(pi.x) + pi.y;
	int b   = p(pi.x+1) + pi.y;
	int aa  = p(a) + pi.z;
	int ab  = p(a+1) + pi.z;
	int ba  = p(b) + pi.z;
	int bb  = p(b+1) + pi.z;

	float x1, x2, y1, y2;
	x1 = lerp(	grad (p(aa)  , pf),
				grad (p(ba)  , pf+float3(-1,  0,  0)),
				f.x);
	x2 = lerp(	grad (p(ab)  , pf+float3( 0, -1,  0)),
				grad (p(bb)  , pf+float3(-1, -1,  0)),
		        f.x);
	y1 = lerp(x1, x2, f.y);

	x1 = lerp(	grad (p(aa+1), pf+float3( 0,  0, -1)),
				grad (p(ba+1), pf+float3(-1,  0, -1)),
				f.x);
	x2 = lerp(	grad (p(ab+1), pf+float3( 0, -1, -1)),
	          	grad (p(bb+1), pf+float3(-1, -1, -1)),
	          	f.x);
	y2 = lerp (x1, x2, f.y);
	
	return lerp (y1, y2, f.z)/2+0.5;
}

float octave_perlin(float3 pos, int octaves, float persistence) {
	float total = 0;
	float frequency = 1;
	float amplitude = 1;
	float maxValue = 0;
	for(int i=0;i<octaves;i++) {
		total += (perlin(pos * frequency)*2-1) * amplitude;
		
		maxValue += amplitude;
		
		amplitude *= persistence;
		frequency *= 2;
	}
	
	return total/maxValue/2+0.5;
}