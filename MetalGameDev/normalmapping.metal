//
//  normalmapping.metal
//  MetalGameDev
//
//  Created by YiLi on 15/5/19.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//

#include <metal_stdlib>
#include "structure.h"
using namespace metal;

struct InVertexNormalMapping{
    packed_float3 position;
    packed_float3 normal;
    packed_float3 tangent;
    packed_float3 bitangent;
    packed_float2 texCoord;
    
};

struct OutVertexNormalMapping{
    float4 position [[position]];
    float2 texCoord;
    float3 light_direction_tangentspace;
    float3 eye_direction_tangentspace;
    float4 v_shadowcoord;
    float4 lightcolor0;
};


vertex OutVertexNormalMapping vertexShader_Static_normal(const device InVertexNormalMapping* vertex_array [[buffer(0)]],const device uniform_buffer& mvp[[buffer(1)]],const device uniform_buffer& light [[buffer(3)]],const device SpotLight* spotlights [[buffer(4)]],unsigned int vid [[vertex_id]]){
    OutVertexNormalMapping vertexOut;
    float4x4 model_matrix = mvp.m;
    float4x4 view_matrix  = mvp.v;
    float4x4 projection_matrix = mvp.p;
    float4x4 model_view_matrx = mvp.v /** model_matrix*/;
    float4x4 mvp_matrix = mvp.p * model_view_matrx;
    
    vertexOut.lightcolor0 = spotlights[0].color;
    vertexOut.texCoord = vertex_array[vid].texCoord;
    
    //计算坐标（VP中的位置）
    vertexOut.position = mvp_matrix * float4(float3((vertex_array[vid]).position),1.0);
    float4x4 bais;
    bais[0] = float4(0.5,0,0,0);
    bais[1] = float4(0,-0.5,0,0);
    bais[2] = float4(0,0,0.5,0);
    bais[3] = float4(0.5,0.5,0.5,1);
    
    vertexOut.v_shadowcoord = bais * light.p * light.v *float4(float3((vertex_array[vid]).position),1.0);
    
    
    float3 vertex_position_cameraspace = (model_view_matrx * float4(float3(vertex_array[vid].position),1.0)).xyz;
    float3 eye_direction_cameraspace = float3(0.0f,0.0f,0.0f) - vertex_position_cameraspace;
    
    // Calculate the direction of the light from the position of the camera
    float3 light_position_camerasapce = (view_matrix * float4(spotlights[0].pos,1.0f)).xyz;
    float3 light_direction_cameraspace = light_position_camerasapce + eye_direction_cameraspace;
    
    vertexOut.texCoord = float2(vertex_array[vid].texCoord);
    
    // Calculate the TBN matrix using the tangent, bitangent, and normal. This is a matrix
    // that can be used to move any vector from camera space to tangent space (where we will
    // be doing all of our lighting calculations). We do this so that we can change the normal
    // based on the texture that is provided.
    float3x3 mv3x3;
    mv3x3[0].xyz = model_view_matrx[0].xyz;
    mv3x3[1].xyz = model_view_matrx[1].xyz;
    mv3x3[2].xyz = model_view_matrx[2].xyz;
    
    float3 tangent_cameraspace = mv3x3 * float3(vertex_array[vid].tangent);//tangents[vid]);
    float3 bitangent_cameraspace = mv3x3 * float3(vertex_array[vid].bitangent);//bitangents[vid]);
    float3 normal_cameraspace = mv3x3 * float3(vertex_array[vid].normal);
    float3x3 tbn = float3x3(tangent_cameraspace, bitangent_cameraspace, normal_cameraspace);
    tbn = transpose(tbn);
    
    // Pass along the light and eye directions in tangent space
    vertexOut.light_direction_tangentspace = tbn * light_direction_cameraspace;
    vertexOut.eye_direction_tangentspace = tbn * eye_direction_cameraspace;
    
    return vertexOut;
}


fragment float4 phong_fragment_static_normal(OutVertexNormalMapping in [[stage_in]],depth2d<float> shadow_texture [[texture(0)]],texture2d<float> modelTexture [[texture(1)]],texture2d<float> normalTexture [[ texture(2) ]]){
    float4 color;
    constexpr sampler shadow_sampler(coord::normalized, filter::linear, address::clamp_to_zero, compare_func::less);
    constexpr sampler sampler2D;
    
    float shadow = 1.0;
    auto shadowCoordNormalized = in.v_shadowcoord.xyz/in.v_shadowcoord.w;
    if (shadowCoordNormalized.x<0.0 || shadowCoordNormalized.x > 1 || shadowCoordNormalized.y<0.0 || shadowCoordNormalized.y > 1 || shadowCoordNormalized.z<0.0 || shadowCoordNormalized.z > 1){
        shadow = 1.0;
    }else{
        shadow = shadow_texture.sample_compare(shadow_sampler, in.v_shadowcoord.xy/in.v_shadowcoord.w, in.v_shadowcoord.z/in.v_shadowcoord.w);
    }
    
    float3 textureNormalValue = (normalTexture.sample(sampler2D, in.texCoord)).xyz;
    float3 textureNormal_tangentspace = normalize(textureNormalValue * 2.0f - 1.0f);
    
    // Calculate the diffuse color
    float3 n = textureNormal_tangentspace;
    float3 l = normalize(in.light_direction_tangentspace);
    float n_dot_l = saturate( dot(n, l) );
    float4 diffuse_color = in.lightcolor0 * n_dot_l * materialDiffuseColor;
    
    // Calculate the specular color
    float3 e = normalize(in.eye_direction_tangentspace);
    float3 r = -l + 2.0f * n_dot_l * n;
    float e_dot_r =  saturate( dot(e, r) );
    
    float4 specular_color = materialSpecularColor * in.lightcolor0 * pow(e_dot_r, materialShine);
    color = float4(float3(float3(0.15,0.15,0.15) + shadow * (diffuse_color.rgb + specular_color.rgb)),1.0);
    return color;
}
