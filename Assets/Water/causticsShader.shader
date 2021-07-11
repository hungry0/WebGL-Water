Shader "Unlit/causticsShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        water("water",2D) = "black"{}
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
    
            float3 project(float3 origin, float3 ray, float3 refractedLight)
            {
                float2 tcube = intersectCube(origin, ray, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
                origin += ray * tcube.y;
                float tplane = (-origin.y - 1.0) / refractedLight.y;
                return origin + refractedLight * tplane;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                // r y的位置
                // g 速度
                // ba 法线
                float4 info = tex2Dlod(water, float4(v.uv, 0, 0));
                info.ba *= 0.5;
                float3 normal = float3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a);
                light =  _WorldSpaceLightPos0.xyz;
                v.vertex.z = 0;
                v.vertex.xy = v.uv * 2 - float2(1, 1);
                v.vertex.xy = -v.vertex.xy;
                /* project the vertices along the refracted vertex ray */
                float3 refractedLight = refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
                float3 ray = refract(-light, normal, IOR_AIR / IOR_WATER);
                float3 oldPos = project(v.vertex.xzy, refractedLight, refractedLight);
                float3 newPos = project(v.vertex.xzy + float3(0.0, info.r, 0.0), ray, refractedLight);
                
                o.vertex = float4(0.75 * (newPos.xz + refractedLight.xz / refractedLight.y), 0.0, 1.0);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float4 info = tex2D(water, i.uv);
                info.ba *= 0.5;
                float3 normal = float3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a);
                light = _WorldSpaceLightPos0.xyz;       

                /* project the vertices along the refracted vertex ray */
                float3 refractedLight = refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
                float3 ray = refract(-light, normal, IOR_AIR / IOR_WATER);
                i.vertex.xy =  i.uv * 2 - float2(1, 1);
                i.vertex.xy = -i.vertex.xy;
                i.vertex.z = 0;
                float3 oldPos = project(i.vertex.xzy, refractedLight, refractedLight);
                float3 newPos = project(i.vertex.xzy + float3(0.0, info.r, 0.0), ray, refractedLight);
              
                light = _WorldSpaceLightPos0.xyz;    
                 /* if the triangle gets smaller, it gets brighter, and vice versa */
                float oldArea = length(ddx(oldPos)) * length(ddy(oldPos));
                float newArea = length(ddx(newPos)) * length(ddy(newPos));
                float4 gl_FragColor = float4(oldArea / newArea * 0.5, 1.0, 0.0, 0.0);
                
                refractedLight = refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
                
                /* shadow for the rim of the pool */
                float2 t = intersectCube(newPos, -refractedLight, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
                gl_FragColor.r *= 1.0 / (1.0 + exp(-200.0 / (1.0 + 10.0 * (t.y - t.x)) * (newPos.y - refractedLight.y * t.y - 2.0 / 12.0)));
                
                return gl_FragColor;
            }
            ENDCG
        }
    }
}