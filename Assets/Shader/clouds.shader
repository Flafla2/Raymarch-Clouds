Shader "Custom/clouds" {
	Properties {
		_MainTex ("", 2D) = "white" {}
		_Depth ("", 2D) = "white" {}
	}
	SubShader {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma target 3.0

		#include "Unity.cginc"
		#include "perlin.cginc"

		sampler2D _MainTex;
		sampler2D _Depth;

		struct v2f {
			float4 pos : POSITION;
			float4 projPos : TEXCOORD0;
		};

		v2f vert(float4 v:POSITION) : SV_POSITION {
			v2f OUT;

			OUT.pos = mul (UNITY_MATRIX_MVP, v);
			OUT.projPos = ComputeScreenPos(OUT.pos);

		}

		fixed4 frag(v2f IN) : SV_Target {
			float2 wpos = IN.projPos.xy / IN.projPos.w;

			return fixed4(1.0,0.0,0.0,1.0);
		}

		ENDCG
	} 
	FallBack "Diffuse"
}
