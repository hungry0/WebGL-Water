Shader "Unlit/WaterRender"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Delta("Delta",Vector) = (0.02, 0.02, 0)
        _Albedo("Albedo", float)= 1
        _Color("color", Color) = (1,1,1, 0.3)
        _Gloss("Gloss", float) = 1
        _Emission("Emission", Vector)=(1,1,1)
        _Specular("SpecularParam", float)=1
        _SpecColor("_SpecColor", Color)= (1,1,1,1)
        tiles("tiles", 2D) = "white"{}
        water("water", 2D) = "black"{}
        _Skybox("Skybox", Cube) = "white" {}
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" }

        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "HelperFunc.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 vertexObjPos : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            samplerCUBE _Skybox;
            float4 _MainTex_ST;
            float2 _Delta;
            float _Albedo;
            float3 _Emission;
            float _Specular;
            float _Gloss;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float2 info = tex2Dlod(water, float4(o.uv, 0, 0));
                o.vertexObjPos = v.vertex;
                v.vertex.y += info.r;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
            
            float3 getSurfaceRayColor(float3 origin, float3 ray, float3 waterColor)
            {
                float3 color;
                if (ray.y < 0.0)
                {
                    float2 t = intersectCube(origin, ray, float3(-1, -poolHeight, -1), float3(1, 2.0, 1));
                    color = getWallColor(origin + ray * t.y);
                } 

                if (ray.y < 0.0)
                    color *= waterColor;
                
                return color;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float4 info = tex2D(water, i.uv);
                i.vertexObjPos.y += info.r;
                float4 worldPos = mul(unity_ObjectToWorld, i.vertexObjPos);
                float3 localNorm = float3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a);;
                SurfaceOutput so;
                so.Albedo = _Albedo;
                so.Normal = normalize(UnityObjectToWorldNormal(localNorm));
                so.Emission = _Emission;
                so.Specular = _Specular;
                so.Gloss = _Gloss;
                so.Alpha = 1;
                UnityLight unityLight;
                unityLight.color = _LightColor0.rgb;
                unityLight.dir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed4 lightColor = UnityBlinnPhongLight(so, normalize(UnityWorldSpaceViewDir(worldPos)), unityLight);
                col *= float4(UNITY_LIGHTMODEL_AMBIENT.xyz, 1) + lightColor; 

                half4 reflection = texCUBE(_Skybox, so.Normal);
                
                float3 refractedRay = normalize(refract(-normalize(UnityWorldSpaceViewDir(worldPos)), so.Normal, IOR_AIR / IOR_WATER));
                float4 refractedColor = float4(getSurfaceRayColor(worldPos, refractedRay, abovewaterColor), 1);
                return col * refractedColor + reflection;
            }
            
            ENDCG
        }
    }
}
