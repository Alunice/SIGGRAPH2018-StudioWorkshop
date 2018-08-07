Shader "SIGGRAPH Studio/DeferredLighting"
{
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "LightweightPipeline" "IgnoreProjector" = "True"}

        Pass
        {
            Name "DeferredLighting"

            Blend One One
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles d3d11_9x

            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "LWRP/ShaderLibrary/Lighting.hlsl"

            UNITY_DECLARE_FRAMEBUFFER_INPUT_FLOAT(0); // Diffuse
            UNITY_DECLARE_FRAMEBUFFER_INPUT_FLOAT(1); // SpecRough
            UNITY_DECLARE_FRAMEBUFFER_INPUT_FLOAT(2); // Normal
            UNITY_DECLARE_FRAMEBUFFER_INPUT_FLOAT(3); // Depth

            float4 Vertex(float4 vertexPosition : POSITION) : SV_POSITION
            {
                return vertexPosition;
            }

            half4 Fragment(float4 pos : SV_POSITION) : SV_Target
            {
                half4 albedoOcclusion = UNITY_READ_FRAMEBUFFER_INPUT(0, pos);
                half4 specRoughness = UNITY_READ_FRAMEBUFFER_INPUT(1, pos);
                half3 normalWS = normalize((UNITY_READ_FRAMEBUFFER_INPUT(2, pos).rgb * 2.0h - 1.0h));
                float depth = UNITY_READ_FRAMEBUFFER_INPUT(3, pos).r;

                float2 positionNDC = pos.xy * _ScreenSize.zw;
                float3 positionWS = ComputeWorldSpacePosition(positionNDC, depth, UNITY_MATRIX_I_VP);

                half3 viewDirection = half3(normalize(GetCameraPositionWS() - positionWS));

                Light mainLight = GetMainLight();
                BRDFData brdfData = (BRDFData)0;
                brdfData.diffuse = albedoOcclusion.rgb;
                brdfData.specular = specRoughness.rgb;
                brdfData.normalizationTerm = specRoughness.a * 4.0h + 2.0h;
                brdfData.roughness2 = specRoughness.a * specRoughness.a;
                brdfData.roughness2MinusOne = brdfData.roughness2 - 1.0h;

                return half4(LightingPhysicallyBased(brdfData, mainLight, normalWS, viewDirection), 1.0);
            }
            ENDHLSL
        }
    }
}
