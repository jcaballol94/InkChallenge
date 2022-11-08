using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace InkChallenge
{
    internal class OutlinesRendererFeature : ScriptableRendererFeature
    {
        private OutlinesPass m_outlinePass;

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            m_outlinePass.Setup(renderer);
            renderer.EnqueuePass(m_outlinePass);
        }

        public override void Create()
        {
            if (m_outlinePass == null)
                m_outlinePass = new OutlinesPass();
        }
    }
}