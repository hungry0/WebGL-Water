Shader "Unlit/cube"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        tiles("tiles", 2D) = "white"{}
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Cull Back
			ZTest On
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "HelperFunc.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 position : NORMAL;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.position = mul(unity_ObjectToWorld, v.vertex);
                o.position.y = ((1.0 - o.position.y) * (7.0 / 12.0) - 1.0) * poolHeight;
                o.vertex =  mul(UNITY_MATRIX_VP, o.position);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                light = normalize(UnityWorldSpaceLightDir(i.position));
                float4 gl_FragColor = float4(getWallColor(i.position), 1.0);
                float4 info = tex2D(water, -i.position.xz * 0.5 + 0.5);
                
                if (i.position.y < info.r)
                {
                   gl_FragColor.rgb *= underwaterColor * 1.2;
                }
                
                return gl_FragColor;
            }
            
            ENDCG
        }
    }
}
