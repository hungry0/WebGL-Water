#define IOR_AIR 1.0
#define IOR_WATER 1.333
#define abovewaterColor float3(0.25, 1.0, 1.25)
#define underwaterColor float3(0.4, 0.9, 1.0)
#define poolHeight 1.0

uniform float3 light;
uniform float3 sphereCenter;
uniform float sphereRadius;
uniform sampler2D tiles;
uniform sampler2D causticTex;
uniform sampler2D water;
  
inline  float2 intersectCube(float3 origin, float3 ray, float3 cubeMin, float3 cubeMax)
{
    float3 tMin = (cubeMin - origin) / ray;
    float3 tMax = (cubeMax - origin) / ray;
    float3 t1 = min(tMin, tMax);
    float3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return float2(tNear, tFar);
}
  
inline  float intersectSphere(float3 origin, float3 ray, float3 sphereCenter, float sphereRadius)
{
    float3 toSphere = origin - sphereCenter;
    float a = dot(ray, ray);
    float b = 2.0 * dot(toSphere, ray);
    float c = dot(toSphere, toSphere) - sphereRadius * sphereRadius;
    float discriminant = b*b - 4.0*a*c;
    if (discriminant > 0.0)
    {
          float t = (-b - sqrt(discriminant)) / (2.0 * a);
          if (t > 0.0) return t;
    }
    
    return 1.0e6;
}
  
inline float3 getSphereColor(float3 pos)
{
    float3 color = float3(0.5,1,1);
    
    /* ambient occlusion with walls */
    color *= 1.0 - 0.9 / pow((1.0 + sphereRadius - abs(pos.x)) / sphereRadius, 3.0);
    color *= 1.0 - 0.9 / pow((1.0 + sphereRadius - abs(pos.z)) / sphereRadius, 3.0);
    color *= 1.0 - 0.9 / pow((pos.y + 1.0 + sphereRadius) / sphereRadius, 3.0);
    
    /* caustics */
    float3 sphereNormal = (pos - sphereCenter) / sphereRadius;
    float3 refractedLight = refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
    float diffuse = max(0.0, dot(-refractedLight, sphereNormal)) * 0.5;
    float4 info = tex2D(water, pos.xz * 0.5 + 0.5);
    if (pos.y < info.r)
    {
          float4 caustic = tex2D(causticTex, 0.75 * (pos.xz - pos.y * refractedLight.xz / refractedLight.y) * 0.5 + 0.5);
          diffuse *= caustic.r * 4.0;
    }
    color += diffuse;
    
    return color;
}
  
inline float3 getWallColor(float3 pos)
{
    float scale = 0.5;
    
    float3 wallColor;
    float3 normal;
    if (abs(pos.x) > 0.999)
    {
        wallColor = tex2D(tiles, pos.yz * 0.5 + float2(1.0, 0.5)).rgb;
        normal = float3(-pos.x, 0.0, 0.0);
    } else if (abs(pos.z) > 0.999)
    {
          wallColor = tex2D(tiles, pos.yx * 0.5 + float2(1.0, 0.5)).rgb;
          normal = float3(0.0, 0.0, -pos.z);
    } else
    {
          wallColor = tex2D(tiles, pos.xz * 0.5 + 0.5).rgb;
          normal = float3(0.0, 1.0, 0.0);
    }
    
    scale /= length(pos); /* pool ambient occlusion */
    scale *= 1.0 - 0.9 / pow(length(pos - sphereCenter) / sphereRadius, 4.0); /* sphere ambient occlusion */
    
    /* caustics */
    float3 refractedLight = -refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
    float diffuse = max(0.0, dot(refractedLight, normal));
    float4 info = tex2D(water, pos.xz * 0.5 + 0.5);
    if (pos.y < info.r)
    {
        float4 caustic = tex2D(causticTex, (0.75 * (pos.xz - pos.y * refractedLight.xz / refractedLight.y) * 0.5 + 0.5));
        scale += diffuse * caustic.r * 2.0 * caustic.g;
    } 
    else
    {
        /* shadow for the rim of the pool */
        float2 t = intersectCube(pos, refractedLight, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
        diffuse *= 1.0 / (1.0 + exp(-200.0 / (1.0 + 10.0 * (t.y - t.x)) * (pos.y + refractedLight.y * t.y - 2.0 / 12.0)));
        
        scale += diffuse * 0.5;
    }
    
    return wallColor * scale;
 }