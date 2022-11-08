using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace InkChallenge
{
    public class OutlinesPass : ScriptableRenderPass
    {
        private const string OUTLINE_SHADER = "Hidden/OutlineShader";

        private static readonly int DEPTH_THRESHOLD = Shader.PropertyToID("_DepthThreshold");
        private static readonly int NORMAL_THRESHOLD = Shader.PropertyToID("_NormalThreshold");

        private Material m_material;
        private ScriptableRenderer m_renderer;

        public void Setup(ScriptableRenderer renderer, float depthThreshold, float normalThreshold)
        {
            m_renderer = renderer;

            var shader = Shader.Find(OUTLINE_SHADER);
            m_material = new Material(shader);
            m_material.SetFloat(DEPTH_THRESHOLD, depthThreshold);
            m_material.SetFloat(NORMAL_THRESHOLD, normalThreshold);

            renderPassEvent = RenderPassEvent.AfterRenderingSkybox;

            ConfigureInput(ScriptableRenderPassInput.Normal | ScriptableRenderPassInput.Depth);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            // Configure targets and clear color
            ConfigureTarget(m_renderer.cameraColorTargetHandle);
            ConfigureClear(ClearFlag.None, Color.white);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();

            cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, m_material, 0, 0);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}