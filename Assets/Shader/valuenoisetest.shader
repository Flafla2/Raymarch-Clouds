// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/valuenoisetest" {
	Properties{
		_ValueNoise("Noise Lookup", 2D) = "white" {}
		_Scale ("Scale", Float) = 0.0
	}
		SubShader{
		Pass{
			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 3.0

#include "UnityCG.cginc"

			uniform sampler2D _ValueNoise;
			uniform float _Scale;

			struct vertexInput {
				float4 vertex : POSITION;
				float4 texcoord0 : TEXCOORD0;
			};

			struct fragmentInput{
				float4 position : SV_POSITION;
				float4 texcoord0 : TEXCOORD0;
			};

			float noise(in float3 x) {
				float3 p = floor(x);
				float3 f = frac(x);
				f = f*f*(3.0 - 2.0*f);
				float2 uv = (p.xy + float2(37.0, -17.0)*p.z) + f.xy;
				float2 rg = tex2D(_ValueNoise, (uv + 0.5) / 256.0).rg;
				return lerp(rg.g, rg.r, f.z);
			}

			float map5(in float3 q)
			{
				float f;
				f = 0.50000*noise(q); q = q*2.02;
				f += 0.25000*noise(q); q = q*2.03;
				f += 0.12500*noise(q); q = q*2.01;
				f += 0.06250*noise(q); q = q*2.02;
				f += 0.03125*noise(q);
				return f;
			}

			fragmentInput vert(vertexInput i){
				fragmentInput o;
				o.position = UnityObjectToClipPos(i.vertex);
				o.texcoord0 = i.texcoord0;
				return o;
			}
			fixed4 frag(fragmentInput i) : SV_Target{
				float p = map5(float3(i.texcoord0.xy * _Scale, _Time.y/2));
				return fixed4(p, p, p, 1);
			}
				ENDCG
		}
	}
}
