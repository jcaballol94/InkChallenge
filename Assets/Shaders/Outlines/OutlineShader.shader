Shader "Hidden/OutlineShader"
{
    Properties
    {
        _DepthThreshold("Depth Threshold", Range(0.0, 1.0)) = 0.5
        _NormalThreshold("Normal Threshold", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        Cull Off ZWrite Off ZTest Always
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
#if UNITY_UV_STARTS_AT_TOP
                o.vertex.y = -o.vertex.y;
#endif
                o.uv = v.uv;
                return o;
            }

            float _DepthThreshold;
            float _NormalThreshold;

            float SobelDepth(float2 uv)
            {
                float sizeX = abs(ddx(uv.x));
                float sizeY = abs(ddy(uv.y));

                float center = SampleSceneDepth(uv);
                float result = abs(SampleSceneDepth(uv + float2(sizeX, 0)) - center);
                result += abs(SampleSceneDepth(uv + float2(0, sizeY)) - center);
                result += abs(SampleSceneDepth(uv + float2(-sizeX, 0)) - center);
                result += abs(SampleSceneDepth(uv + float2(0, -sizeY)) - center);
                return abs(result);
            }

            float3 SobelNormal(float2 uv)
            {
                float sizeX = abs(ddx(uv.x));
                float sizeY = abs(ddy(uv.y));

                float3 center = SampleSceneNormals(uv);
                float3 result = abs(SampleSceneNormals(uv + float2(sizeX, 0)) - center);
                result += abs(SampleSceneNormals(uv + float2(0, sizeY)) - center);
                result += abs(SampleSceneNormals(uv + float2(-sizeX, 0)) - center);
                result += abs(SampleSceneNormals(uv + float2(0, -sizeY)) - center);
                return abs(result);
            }

            float4 frag(v2f i) : SV_Target
            {
                //float4 col = float4(SampleSceneNormals(i.uv),1);

                float depthSobel = SobelDepth(i.uv);
                float3 normalSobel = SobelNormal(i.uv);
                float mergedNormalSobel = normalSobel.x + normalSobel.y + normalSobel.z;
                //return col;
                //return float4(0,0,0, step(_DepthThreshold, depthSobel));
                return float4(0,0,0, max(step(_NormalThreshold, mergedNormalSobel), step(_DepthThreshold, depthSobel)));
            }
            ENDHLSL
        }
    }
}
