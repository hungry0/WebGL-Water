Shader "Unlit/VelocityIterator"
{
    Properties
    {
        _MainTex ("_IteratorRT", 2D) = "white" {}
        _Delta("Delta",Vector) = (0.02, 0.02, 0)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
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

            sampler2D _MainTex;
            uniform float2 center;
            uniform float radius;
            uniform float strength;
            float4 _MainTex_ST;
            float2 _Delta;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            
            float4 frag (v2f i) : SV_Target
            {
                /* get vertex info */
                float4 info = tex2D(_MainTex, i.uv);
                /* calculate average neighbor height */
                float2 dx = float2(_Delta.x, 0.0);
                float2 dy = float2(0.0, _Delta.y);
                
                float average = (
                    tex2D(_MainTex, i.uv - dx).r +
                    tex2D(_MainTex, i.uv - dy).r +
                    tex2D(_MainTex, i.uv + dx).r +
                    tex2D(_MainTex, i.uv + dy).r
                ) * 0.25;

                /* change the velocity to move toward the average */
                info.g += (average - info.r) * 2;

                /* attenuate the velocity a little so waves do not last forever */
                info.g *= 0.998;

                /* move the vertex along the velocity */
                info.r += info.g;

                /* add the drop to the height */
                float drop = max(0.0, 1.0 - length(center * 0.5 + 0.5 - i.uv) / radius);
                drop = 0.5 - cos(drop * UNITY_PI) * 0.5;
                info.r += drop * strength;
                
                return info;
            }
            ENDCG
        }
    }
}
