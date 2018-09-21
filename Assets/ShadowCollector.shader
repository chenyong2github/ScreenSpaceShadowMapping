// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Kingsoft/CustomShadow/Collector" 
{
	Subshader 
	{
		ZTest off 
		Fog { Mode Off }
		Cull back
		Lighting Off
		ZWrite Off
		
		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			
			uniform sampler2D _CameraDepthTex;
			uniform sampler2D _LightDepthTex;

			uniform float4x4 _inverseVP;
			uniform float4x4 _WorldToShadow;

			struct Input
			{
				float4 texcoord : TEXCOORD0;
				float4 vertex : POSITION;
			};
			
			struct Output 
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			Output vert (Input i)
			{
				Output o;
				o.pos = UnityObjectToClipPos (i.vertex);
				o.uv = i.texcoord;
				
				return o;
			}

			fixed4 frag( Output i ) : SV_TARGET
			{
				fixed4 cameraDepth = tex2D(_CameraDepthTex, i.uv);
				half depth_ = cameraDepth.r;
#if defined (SHADER_TARGET_GLSL) 
				depth_ = depth_ * 2 - 1;	 // (0, 1)-->(-1, 1)
#elif defined (UNITY_REVERSED_Z)
				depth_ = 1 - depth_;       // (0, 1)-->(1, 0)
#endif

				// reconstruct world position by depth;
				float4 clipPos;
				clipPos.xy = i.uv * 2 - 1;
				clipPos.z = depth_;
				clipPos.w = 1;

				float4 posWorld = mul(_inverseVP, clipPos);
				posWorld /= posWorld.w;

				half4 shadowCoord = mul(_WorldToShadow, posWorld);

				half2 uv = shadowCoord.xy;
				uv = uv*0.5 + 0.5; //(-1, 1)-->(0, 1)

				half depth = shadowCoord.z / shadowCoord.w;
#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
				depth = depth*0.5 + 0.5; //(-1, 1)-->(0, 1)
#elif defined (UNITY_REVERSED_Z)
				depth = 1 - depth;       //(1, 0)-->(0, 1)
#endif

				half4 col = tex2D(_LightDepthTex, uv);
				half sampleDepth = col.r;

				half shadow = (sampleDepth < depth - 0.05) ? 0.1 : 1;

				return shadow;
			}
			ENDCG
		}
	}
	Fallback off
}