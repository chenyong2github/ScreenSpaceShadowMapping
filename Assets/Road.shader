Shader "Kingsoft/Scene/Road" {

	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base", 2D) = "white" {}
	}

	CGINCLUDE		
	#include "UnityCG.cginc"
	struct v2f_full
	{
		half4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
		half4 screenPos : TEXCOORD4;	
	};


	half4 _Color;
	sampler2D _MainTex;
	float4 _MainTex_ST;

	uniform sampler2D _ScreenSpceShadowTexture;
			
	ENDCG 

	SubShader {
		Tags { "RenderType"="Opaque" "LIGHTMODE"="ForwardBase" }

		Pass {

			CGPROGRAM
					
			v2f_full vert (appdata_full v) 
			{
				v2f_full o;
				o.pos = UnityObjectToClipPos (v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
				o.screenPos = o.pos;
				return o; 
			}
				
			fixed4 frag (v2f_full i) : COLOR0 
			{						
				fixed4 tex = tex2D (_MainTex, i.uv.xy)*_Color;

				i.screenPos.xy = i.screenPos.xy / i.screenPos.w;
				float2 sceneUVs = i.screenPos.xy*0.5 + 0.5;
#if UNITY_UV_STARTS_AT_TOP
				sceneUVs.y = _ProjectionParams.x < 0 ? 1 - sceneUVs.y : sceneUVs.y;
#endif

				half shadow = tex2D(_ScreenSpceShadowTexture, sceneUVs).r;
				fixed4 c = tex2D(_MainTex, i.uv.xy) * _Color * shadow;

				return c;
			}	
		
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 
	
			ENDCG
		}
	}

	FallBack "Mobile/Diffuse"
}
