using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace GLWater
{
    public class Ctrl : MonoBehaviour
    {
        private static readonly int s_Center = Shader.PropertyToID("center");
        private static readonly int s_Radius = Shader.PropertyToID("radius");
        private static readonly int s_Strength = Shader.PropertyToID("strength");
        private RenderTexture m_Iterator;
        private RenderTexture m_Iterator2;
        private RenderTexture m_Caustics;
        public Material m_CalcMat;
        public Material m_CubeMat;
        public Material m_NormalMat;
        public Material m_CausticsMat;
        private float m_TimeAcc = 0;
        private float m_DeltaTime = 0.0167f;
        private static readonly int Water = Shader.PropertyToID("water");
        private MeshRenderer _meshRenderer;
        private static readonly int Delta = Shader.PropertyToID("_Delta");
        private static readonly int CausticTex = Shader.PropertyToID("causticTex");

        int n = 512;

        private void Start()
        {
            m_Iterator = new RenderTexture(n, n, 0)
            {
                format = RenderTextureFormat.ARGBFloat,
                wrapMode = TextureWrapMode.Mirror
            };
            
            _meshRenderer = transform.GetComponent<MeshRenderer>();
            
            m_CalcMat.SetVector(s_Center, Vector4.one * 0.25f);
            m_CalcMat.SetFloat(s_Radius, value: 0.03f);
            m_CalcMat.SetVector(Delta, Vector4.one * (1.0f / n));
            m_Iterator2 = new RenderTexture(m_Iterator);
            m_Caustics = new RenderTexture(m_Iterator);
        }

        private void Update()
        {
            RayCast();

            m_TimeAcc += Time.deltaTime;
            if (m_TimeAcc < m_DeltaTime)
            {
                return;
            }

            m_TimeAcc -= m_DeltaTime;
            for (int i = 0; i < n / 128; i++)
            {
                Graphics.Blit(m_Iterator, m_Iterator2, m_CalcMat);
                (m_Iterator, m_Iterator2) = (m_Iterator2, m_Iterator);
            }
            
            m_NormalMat.SetVector(Delta, Vector4.one * (1.0f / n));
            m_NormalMat.SetTexture(Water, m_Iterator);
            Graphics.Blit(null, m_Iterator2, m_NormalMat);
            (m_Iterator, m_Iterator2) = (m_Iterator2, m_Iterator);
            
            m_CausticsMat.SetTexture(Water, m_Iterator);
            Graphics.Blit(null, m_Caustics, m_CausticsMat);
            
            var material = _meshRenderer.material;
            material.SetVector(Delta, Vector4.one * (1.0f / n));
            material.SetTexture(Water, m_Iterator);
            material.SetTexture(CausticTex, m_Caustics);
            
            m_CubeMat.SetTexture(Water, m_Iterator);
            m_CubeMat.SetTexture(CausticTex, m_Caustics);
        }

        public void RayCast()
        {
            float strength = 0.03f;

            var screenPointToRay = Camera.main.ScreenPointToRay(Input.mousePosition);
            if (Physics.Raycast(screenPointToRay, out var raycastHit, 100) && Input.GetMouseButtonDown(0))
            {
                m_CalcMat.SetFloat(s_Strength, strength);
                
                var localPos = transform.worldToLocalMatrix.MultiplyPoint(raycastHit.point);
                var mesh = transform.GetComponent<MeshFilter>().sharedMesh; 
                var center = new Vector2(-localPos.x / mesh.bounds.extents.x, -localPos.z / mesh.bounds.extents.z);
                m_CalcMat.SetVector(s_Center, center);
            }
            else
            {
                m_CalcMat.SetFloat(s_Strength, 0);
            }
        }
    }
}