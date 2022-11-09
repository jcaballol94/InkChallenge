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
                float3 viewDir : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
#if UNITY_UV_STARTS_AT_TOP
                o.vertex.y = -o.vertex.y;
#endif
                o.viewDir = mul(UNITY_MATRIX_I_V, float4(0, 0, 1, 0));
                o.uv = v.uv;
                return o;
            }

            float _DepthThreshold;
            float _NormalThreshold;

            float SampleLinearSceneDetph(float2 uv, float4 zBufferParam)
            {
                return LinearEyeDepth(SampleSceneDepth(uv), zBufferParam);
            }

            float4 frag(v2f i) : SV_Target
            {
                float sizeX = abs(ddx(i.uv.x));
                float sizeY = abs(ddy(i.uv.y));

                float centerDepth = SampleLinearSceneDetph(i.uv, _ZBufferParams);
                float depthSobel = abs(SampleLinearSceneDetph(i.uv + float2(sizeX, 0), _ZBufferParams) - centerDepth);
                depthSobel += abs(SampleLinearSceneDetph(i.uv + float2(0, sizeY), _ZBufferParams) - centerDepth);
                depthSobel += abs(SampleLinearSceneDetph(i.uv + float2(-sizeX, 0), _ZBufferParams) - centerDepth);
                depthSobel += abs(SampleLinearSceneDetph(i.uv + float2(0, -sizeY), _ZBufferParams) - centerDepth);

                float3 centerNormal = SampleSceneNormals(i.uv);
                float3 normalSobel = abs(SampleSceneNormals(i.uv + float2(sizeX, 0)) - centerNormal);
                normalSobel += abs(SampleSceneNormals(i.uv + float2(0, sizeY)) - centerNormal);
                normalSobel += abs(SampleSceneNormals(i.uv + float2(-sizeX, 0)) - centerNormal);
                normalSobel += abs(SampleSceneNormals(i.uv + float2(0, -sizeY)) - centerNormal);

                float mergedNormalSobel = normalSobel.x + normalSobel.y + normalSobel.z;
                float depthScale = dot(i.viewDir, centerNormal);
                return float4(0,0,0, max(step(_NormalThreshold, mergedNormalSobel), step(_DepthThreshold, depthSobel * depthScale)));
            }
            ENDHLSL
        }
    }
}
