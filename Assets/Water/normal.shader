Shader "Unlit/normal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        water("water", 2D) = "black"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform sampler2D water;
            uniform float2 _Delta;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float4 info = tex2D(water, i.uv);
                /* update the normal */
                float3 dx = float3(_Delta.x, tex2D(water, float2(i.uv.x + _Delta.x, i.uv.y)).r - info.r, 0.0);
                float3 dy = float3(0.0, tex2D(water, float2(i.uv.x, i.uv.y + _Delta.y)).r - info.r, _Delta.y);
                info.ba = normalize(cross(dy, dx)).xz;
                return info;
            }
            ENDCG
        }
    }
}