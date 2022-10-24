Shader "Custom/RectangularFog"
{
    Properties
    {
        _FogColor("Fog Colour", Color) = (1,1,1,1)
        _InnerRatio("Inner Ratio", Range(0.0, 0.9)) = 0.5
        _Density("Density", Range(0.0, 1.0)) = 0.5 
        _Radius("Radius", Range(0.5, 3)) = 0.5
        _MinX("Min X", Range(-5, 0)) = -0.5 
        _MaxX("Max X", Range(0, 5)) = 0.5
        _MinY("Min Y", Range(-5, 0)) = -0.5
        _MaxY("Max Y", Range(0, 5)) = 0.5
        _MinZ("Min Z", Range(-5, 0)) = -0.5
        _MaxZ("Max Z", Range(0, 5)) = 0.5
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off Lighting Off ZWrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float CalculateFogDensity(
                float minX,
                float maxX,
                float minY,
                float maxY,
                float minZ,
                float maxZ,
                float sphereRadius,
                float innerRatio,
                float density,
                float3 cameraPosition,
                float3 viewDirection
                ) 
                {
                     float s_Max = 0;
                     float t_Min = 10000;

                     float xs, xt;
                     float recipX = 1 / viewDirection.x;
                     if (recipX >= 0) 
                     {
                         xs = (minX - viewDirection.x) * recipX;
                         xt = (maxX - viewDirection.x) * recipX;
                     }
                     else
                     {
                         xs = (maxX - viewDirection.x) * recipX;
                         xt = (minX - viewDirection.x) * recipX;
                     }
                     if (xs > s_Max)
                         s_Max = xs;
                     if (xt < t_Min)
                         t_Min = xt;
                     if (s_Max > t_Min)
                         return 0;

                     float ys, yt;
                     float recipY = 1 / viewDirection.y;
                     if (recipY >= 0)
                     {
                         ys = (minY - viewDirection.y) * recipY;
                         yt = (maxY - viewDirection.y) * recipY;
                     }
                     else
                     {
                         ys = (maxY - viewDirection.y) * recipY;
                         yt = (minY - viewDirection.y) * recipY;
                     }
                     if (ys > s_Max)
                         s_Max = ys;
                     if (yt < t_Min)
                         t_Min = yt;
                     if (s_Max > t_Min)
                         return 0;

                     float zs, zt;
                     float recipZ = 1 / viewDirection.z;
                     if (recipZ >= 0)
                     {
                         zs = (minZ - viewDirection.z) * recipZ;
                         zt = (maxZ - viewDirection.z) * recipZ;
                     }
                     else
                     {
                         zs = (maxZ - viewDirection.z) * recipZ;
                         zt = (minZ - viewDirection.z) * recipZ;
                     }
                     if (zs > s_Max)
                         s_Max = zs;
                     if (zt < t_Min)
                         t_Min = zt;
                     if (s_Max > t_Min)
                         return 0;

                     float sample = s_Max;
                     float step_distance = (t_Min - s_Max) / 15;
                     float centerValue = 1 / (1 - innerRatio);

                     float fog_amount;
                     for (int seg = 0; seg < 15; seg++)
                     {
                         float3 position = cameraPosition + viewDirection * sample;
                         float val = saturate(centerValue * (1 - length(position) / sphereRadius));
                         fog_amount = saturate(val * density);
                         sample += step_distance;
                     }
                     return fog_amount;
                }

                struct v2f
                {
                    float3 view : TEXCOORD0;
                    float4 pos : SV_POSITION;
                    float4 projPos : TEXCOORD1;
                };

                v2f vert(appdata_base v)
                {
                    v2f o;
                    float4 wPos = mul(unity_ObjectToWorld, v.vertex);
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.view = wPos.xyz - _WorldSpaceCameraPos;
                    o.projPos = ComputeScreenPos(o.pos);
                    return o;
                }

                fixed4 _FogColor;
                float _InnerRatio;
                float _Density;
                float _Radius;
                float _MinX;
                float _MaxX;
                float _MinY;
                float _MaxY;
                float _MinZ;
                float _MaxZ;
                fixed4 frag(v2f i) : SV_Target
                {
                    half4 color = half4 (1,1,1,1);
                    float3 viewDir = normalize(i.view);
                    float fog = CalculateFogDensity(_MinX, _MaxX, _MinY, _MaxY, _MinZ, _MaxZ, _Radius, _InnerRatio, _Density, _WorldSpaceCameraPos, viewDir);

                    color.rgb = _FogColor.rgb;
                    color.a = fog;
                    return color;
                }
            ENDCG
        }
    }
}
