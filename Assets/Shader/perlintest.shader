Shader "Custom/TextureCoordinates/Base" {
	Properties {
		_PerlinLookupGrad("Perlin Noise Lookup (Gradients)", 2D) = "white" {}
		_PerlinLookupHash("Perlin Noise Lookup (Hash)", 2D) = "white" {}
	}
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "perlin.cginc"

            struct vertexInput {
                float4 vertex : POSITION;
                float4 texcoord0 : TEXCOORD0;
            };

            struct fragmentInput{
                float4 position : SV_POSITION;
                float4 texcoord0 : TEXCOORD0;
            };

            fragmentInput vert(vertexInput i){
                fragmentInput o;
                o.position = mul (UNITY_MATRIX_MVP, i.vertex);
                o.texcoord0 = i.texcoord0;
                return o;
            }
            fixed4 frag(fragmentInput i) : SV_Target {
				float p = octave_perlin(float3(i.texcoord0.xy * 5, _Time.y), ceil((sin(_Time.y) + 1)*2.5), 0.5);
                return fixed4(p,p,p,1);
            }
            ENDCG
        }
    }
}