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
			#pragma target 3.0

			#include "UnityCG.cginc"
			#include "perlin.cginc"

			uniform sampler2D _MainTex;

			uniform float _MinHeight;
			uniform float _MaxHeight;
			uniform float4 _SunDir;

			uniform float _PerlinPersistance;

			uniform float4x4 _FrustumCornersWS;
			uniform float4 _CameraWS;

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

				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.texcoord.xy;

				o.ray = _FrustumCornersWS[(int)index];
				o.ray.w = index;

				return o;
			}

			void integrate( inout fixed4 sum, in float dif, in float den, in fixed3 bgcol, in float t)
			{
			    // lighting
			    //		   Blue-Gray shadow			 Light Reddish highlight
			    half3 lin = half3(0.65,0.68,0.7)*1.3 + 0.5*half3(0.7, 0.5, 0.3)*dif;
			   	//                    Light Warm Color        Gray
			    half3 c = lerp( 1.15*half3(1.0,0.95,0.8), half3(0.65,0.65,0.65), den );
			    half4 col = half4(c, den);
			    col.xyz *= lin;
			    col.xyz = lerp( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );
			    // front to back blending    
			    col.a *= 0.4;
			    col.rgb *= col.a;

			    sum += col*(1.0-sum.a);
			}

			inline float noise(in float3 pos, in int lod) {
				float ret = octave_perlin(pos,lod,_PerlinPersistance);
				return lerp(1.0,saturate(ret-0.5),saturate((pos.y-_MinHeight)/(_MaxHeight-_MinHeight)));
				//return lerp(ret,0,saturate(1+(pos.y-_MaxHeight)));
			}

			inline void march (inout float t, inout fixed4 sum, in int steps, in float3 cam_origin, in float4 cam_dir, in fixed3 color, in int lod) {
				for(int i = 0; i < steps; i++) {
					float3 pos = cam_origin + cam_dir * t;

					if(pos.y < _MinHeight - 0.001 || pos.y > _MaxHeight+0.001 || sum.a > 0.99 ) {
						t += 0.1;
						continue;
					}

					float den = noise(pos/5, lod);
					if(den > 0.01) {
						float3 difpos = pos/5+3*normalize(_SunDir);
						float den_dif = noise(difpos, lod);
						float dif =  saturate((den - den_dif)/0.6);
						integrate( sum, dif, den, color.rgb, t );
					}

					t += 0.1;
				}
			}

			fixed4 raymarch(float3 cam_origin, float4 cam_dir, fixed3 color) {
				fixed4 sum = fixed4(0.0);

				float t = 0.0;

				march(t, sum, 30, cam_origin, cam_dir, color, 5);
				march(t, sum, 30, cam_origin, cam_dir, color, 4);
				march(t, sum, 30, cam_origin, cam_dir, color, 2);
				march(t, sum, 30, cam_origin, cam_dir, color, 1);

				return clamp(sum, 0.0, 1.0);
			}

			fixed4 frag(v2f i) : SV_Target {
				float3 eyeVec = normalize(i.ray.xyz);

				float3 start = _CameraWS;

				// if(start.y > _MaxHeight+0.001)
				// 	start += eyeVec / abs(eyeVec.y) * abs(start.y - _MaxHeight);
				// else if(start.y < _MinHeight-0.001)
				// 	start += eyeVec / abs(eyeVec.y) * abs(start.y - _MinHeight);

				fixed3 col = tex2D(_MainTex,i.uv);
				fixed4 add = raymarch(start, eyeVec, col);
				return fixed4(col*(1.0-add.w)+add.xyz,1.0);
			}
			ENDCG
		}
	} 
	FallBack Off
}
