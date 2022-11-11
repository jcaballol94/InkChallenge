Shader "Hidden/OutlineShader"
{
    Properties
    {
        _DepthThreshold("Depth Threshold", Range(0.0, 1.0)) = 0.5
        _NormalThreshold("Normal Threshold", Range(0.0, 1.0)) = 0.5
        _NoiseIntensity("Noise Intensity", Float) = 1
        _NoiseScale("Noise Scale", Float) = 1
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
            float _NoiseIntensity;
            float _NoiseScale;

            float SampleLinearSceneDetph(float2 uv, float4 zBufferParam)
            {
                return LinearEyeDepth(SampleSceneDepth(uv), zBufferParam);
            }

            float2 unity_gradientNoise_dir(float2 p)
            {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            float unity_gradientNoise(float2 p)
            {
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(unity_gradientNoise_dir(ip), fp);
                float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
            }

            float Unity_GradientNoise_float(float2 UV, float Scale)
            {
                return unity_gradientNoise(UV * Scale) + 0.5;
            }

            float4 frag(v2f i) : SV_Target
            {
                float sizeX = abs(ddx(i.uv.x));
                float sizeY = abs(ddy(i.uv.y));

                float2 noise = float2(Unity_GradientNoise_float(i.uv, _NoiseScale),
                    Unity_GradientNoise_float(i.uv + float2(1, 1), _NoiseScale)) * _NoiseIntensity;
                noise *= float2(sizeX, sizeY);
                float2 uv = saturate(i.uv + noise);

                float centerDepth = SampleLinearSceneDetph(uv, _ZBufferParams);
                float depthSobel = abs(SampleLinearSceneDetph(uv + float2(sizeX, 0), _ZBufferParams) - centerDepth);
                depthSobel += abs(SampleLinearSceneDetph(uv + float2(0, sizeY), _ZBufferParams) - centerDepth);
                depthSobel += abs(SampleLinearSceneDetph(uv + float2(-sizeX, 0), _ZBufferParams) - centerDepth);
                depthSobel += abs(SampleLinearSceneDetph(uv + float2(0, -sizeY), _ZBufferParams) - centerDepth);

                float3 centerNormal = SampleSceneNormals(uv);
                float3 normalSobel = abs(SampleSceneNormals(uv + float2(sizeX, 0)) - centerNormal);
                normalSobel += abs(SampleSceneNormals(uv + float2(0, sizeY)) - centerNormal);
                normalSobel += abs(SampleSceneNormals(uv + float2(-sizeX, 0)) - centerNormal);
                normalSobel += abs(SampleSceneNormals(uv + float2(0, -sizeY)) - centerNormal);

                float mergedNormalSobel = normalSobel.x + normalSobel.y + normalSobel.z;
                float depthScale = dot(i.viewDir, centerNormal);
                return float4(0,0,0, max(step(_NormalThreshold, mergedNormalSobel), step(_DepthThreshold, depthSobel * depthScale)));
            }
            ENDHLSL
        }
    }
}
