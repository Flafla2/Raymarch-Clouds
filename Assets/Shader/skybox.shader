// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/skybox" {
	Properties {
		_SunDir ("Sun Direction", Vector) = (-1.0, -1.0, 0.0, 1.0)
	}
	SubShader {
		Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
		

		CGINCLUDE
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		uniform float4 _SunDir;

		struct v2f {
			float4 pos : SV_POSITION;
			float3 worldPos : TEXCOORD0;
		};

		v2f vert(float4 pos : POSITION) {
			v2f ret;
			ret.pos = UnityObjectToClipPos(pos);

			#if UNITY_UV_STARTS_AT_TOP
			ret.pos.y = 1 - ret.pos.y;
			#endif

			ret.worldPos = mul(unity_ObjectToWorld,pos);
			return ret;
		}

		half4 frag(v2f i) : COLOR {
			half3 rd = normalize(i.worldPos.xyz);

			float sun = clamp( dot((float3)_SunDir,rd), 0.0, 1.0 );

			half3 col = half3(0.6,0.71,0.75) - rd.y*0.2*half3(1.0,0.5,1.0) + 0.15*0.5;
			col += 0.2*half3(1.0,.6,0.1)*pow( sun, 8.0 );

			return half4(col,0);
		}
		ENDCG

		Pass {
			ZWrite Off
            Cull Off
            Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			ENDCG

		}
	} 
	FallBack Off
}
