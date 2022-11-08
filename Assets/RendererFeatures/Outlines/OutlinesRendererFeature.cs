using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace InkChallenge
{
    internal class OutlinesRendererFeature : ScriptableRendererFeature
    {
        private OutlinesPass m_outlinePass;
        [Range(0,0.01f)][SerializeField] private float m_depthThreshold = 0.01f;
        [Range(0,1f)][SerializeField] private float m_normalThreshold = 0.01f;

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            m_outlinePass.Setup(renderer, m_depthThreshold, m_normalThreshold);
            renderer.EnqueuePass(m_outlinePass);
        }

        public override void Create()
        {
            if (m_outlinePass == null)
                m_outlinePass = new OutlinesPass();
        }
    }
}