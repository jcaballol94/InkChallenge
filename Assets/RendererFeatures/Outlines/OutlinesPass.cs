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

        private Material m_material;
        private ScriptableRenderer m_renderer;

        public void Setup(ScriptableRenderer renderer)
        {
            m_renderer = renderer;

            var shader = Shader.Find(OUTLINE_SHADER);
            m_material = new Material(shader);

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