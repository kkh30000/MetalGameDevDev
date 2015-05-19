//
//  structure.h
//  MetalGameDev
//
//  Created by YiLi on 15/5/19.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//

#ifndef MetalGameDev_structure_h
#define MetalGameDev_structure_h
#include <metal_stdlib>
#include "structure.h"
using namespace metal;



struct uniform_buffer{
    float4x4 m;
    float4x4 v;
    float4x4 p;
};
struct SpotLight{
    packed_float4 color;
    packed_float3 pos;
    float attenuation;
    
};

struct InVertex{
    packed_float3 position;
    packed_float3 normal;
    packed_float2 texCoord;
    float bone0;
    float weight0;
    float bone1;
    float weight1;
};
struct InVertexStatic{
    packed_float3 position;
    packed_float3 normal;
    packed_float2 texCoord;
    
};



struct OutVertex{
    float4 position [[position]];
    //float pointSize [[point_size]];
    float2 texCoord;
    float3 normal_camerasapce;
    float3 eye_direnction_cameraspace;
    float3 light_direction_camerasapce;
    float4 v_shadowcoord;
    float4 lightcolor0;
};

constant float4 materialAmbientColor = float4(0.15, 0.65, 0.15, 1.0);
constant float4 materialDiffuseColor = float4(0.4, 0.4, 0.4, 1.0);
//constant float4 light_color = float4(0.0, 1.0, 1.0, 1.0);
constant float4 materialSpecularColor = float4(1.0, 1.0, 1.0, 1.0);
//constant float4 platMaterialSpecularColor = float4(0.5,0.5,0.5,1.0);
constant float materialShine = 500.0;
//constant float4x4 bais = float4x4(float4(0.5,0,0,0),float4(0,0.5,0,0),float4(0,0,0.5,0),float4(0.5,0.5,0.5,1));



#endif
