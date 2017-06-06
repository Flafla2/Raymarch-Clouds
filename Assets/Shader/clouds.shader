// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/clouds" {
	Properties {
		_MainTex("", 2D) = "white" {}
	}
	SubShader {

		Pass {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0

			#include "UnityCG.cginc"

			uniform sampler2D _CameraDepthTexture;

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform sampler2D _ValueNoise;

			uniform float _MinHeight;
			uniform float _MaxHeight;
			uniform float _FadeDist;
			uniform float _Scale;
			uniform float4 _SunDir;

			uniform float4x4 _FrustumCornersWS;
			uniform float4 _CameraWS;

			uniform float4x4 _CameraInvViewMatrix;

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 ray : TEXCOORD1;
			};

			v2f vert(appdata_img v) {
				v2f o;

				// Vertex.z is populated by Clouds.cs (companion script) with the current frustum corner
				half index = v.vertex.z;
				v.vertex.z = 0.1;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;

#if UNITY_UV_STARTS_AT_TOP
				if(_MainTex_TexelSize.y < 0)
					o.uv.y = 1 - o.uv.y;
#endif

				o.ray = _FrustumCornersWS[(int)index];
				o.ray /= abs(o.ray.z);
				o.ray = mul(_CameraInvViewMatrix, o.ray);

				return o;
			}

			float noise(in float3 x) {
				x *= _Scale;
				float3 p = floor(x);
				float3 f = frac(x);
				f = f*f*(3.0 - 2.0*f);
				float2 uv = (p.xy + float2(37.0, -17.0)*p.z) + f.xy;
				float2 rg = tex2Dlod(_ValueNoise, float4((uv + 0.5) / 256.0, 0, 0)).rg;
				return -1.0 + 2.0*lerp(rg.g, rg.r, f.z);
			}

			#define NOISEPROC(N, P) 1.75 * N * saturate((_MaxHeight-P.y) / _FadeDist)

			float map5(in float3 q)
			{
				float3 p = q;
				float f;
				f = 0.50000*noise(q); q = q*2.02;
				f += 0.25000*noise(q); q = q*2.03;
				f += 0.12500*noise(q); q = q*2.01;
				f += 0.06250*noise(q); q = q*2.02;
				f += 0.03125*noise(q);
				return NOISEPROC(f, p);
			}
			
			float map4(in float3 q)
			{
				float3 p = q;
				float f;
				f = 0.50000*noise(q); q = q*2.02;
				f += 0.25000*noise(q); q = q*2.03;
				f += 0.12500*noise(q); q = q*2.01;
				f += 0.06250*noise(q);
				return NOISEPROC(f, p);
			}

			float map3(in float3 q)
			{
				float3 p = q;
					float f;
				f = 0.50000*noise(q); q = q*2.02;
				f += 0.25000*noise(q); q = q*2.03;
				f += 0.12500*noise(q);
				return NOISEPROC(f, p);
			}
			
			float map2(in float3 q)
			{
				float3 p = q;
					float f;
				f = 0.50000*noise(q); q = q*2.02;
				f += 0.25000*noise(q);;
				return NOISEPROC(f, p);
			}

			fixed4 integrate(in fixed4 sum, in float dif, in float den, in fixed3 bgcol, in float t)
			{
				// lighting
				fixed3 lin = fixed3(0.65, 0.68, 0.7)*1.3 + 0.5*fixed3(0.7, 0.5, 0.3)*dif;

				fixed3 colrgb = lerp(1.15*fixed3(1.0, 0.95, 0.8), fixed3(0.65, 0.65, 0.65), den);
				fixed4 col = fixed4(colrgb.r, colrgb.g, colrgb.b, (fixed)den);
				col.xyz *= lin;
				col.xyz = lerp(col.xyz, bgcol, 1.0 - exp(-0.003*t*t));
				// front to back blending    
				col.a *= 0.4;
				col.rgb *= col.a;
				return sum + col*(1.0 - sum.a);
			}

			#define MARCH(steps, map, ro, rd, bgcol, sum, depth, t) { \
				for (int i = 0; i<steps; i++) { \
				    if(t > depth) \
						break; \
					float3 pos = ro + t*rd; \
					if (pos.y<_MinHeight || pos.y>_MaxHeight || sum.a > 0.99) { \
						t += max(0.1, 0.02*t); \
						continue; \
					} \
					float den = map(pos); \
					if (den>0.01) \
					{ \
						float dif = clamp((den - map(pos + 0.3*_SunDir)) / 0.6, 0.0, 1.0); \
						sum = integrate(sum, dif, den, bgcol, t); \
					} \
					t += max(0.1, 0.02*t); \
				} \
			}

			fixed4 raymarch(in float3 ro, in float3 rd, in fixed3 bgcol, in float depth)
			{
				fixed4 sum = fixed4(0.0, 0.0, 0.0, 0.0);

				float ct = 0.0;

				MARCH(30, map5, ro, rd, bgcol, sum, depth, ct)
				MARCH(30, map4, ro, rd, bgcol, sum, depth, ct)
				MARCH(30, map3, ro, rd, bgcol, sum, depth, ct)
				MARCH(30, map2, ro, rd, bgcol, sum, depth, ct)

				return clamp(sum, 0.0, 1.0);
			}

			fixed4 frag(v2f i) : SV_Target {
				float3 eyeVec = normalize(i.ray.xyz);

				float3 start = _CameraWS;

				float2 duv = i.uv;
				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					duv.y = 1 - duv.y;
				#endif

				// if(start.y > _MaxHeight+0.001)
				// 	start += eyeVec / abs(eyeVec.y) * abs(start.y - _MaxHeight);
				// else if(start.y < _MinHeight-0.001)
				// 	start += eyeVec / abs(eyeVec.y) * abs(start.y - _MinHeight);

				float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, duv).r);
				depth *= length(i.ray);

				fixed3 col = tex2D(_MainTex,i.uv);
				fixed4 add = raymarch(start, eyeVec, col, depth);
				return fixed4(col*(1.0-add.w)+add.xyz,1.0);
			}
			ENDCG
		}
	} 
	FallBack Off
}
