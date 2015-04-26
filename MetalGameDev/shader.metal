//
//  shader.metal
//  GameMetal
//
//  Created by liuang on 15/3/29.
//  Copyright (c) 2015年 liuang. All rights reserved.
//
#include <metal_stdlib>
using namespace metal;


struct uniform_buffer{
    float4x4 m;
    float4x4 v;
    float4x4 p;
};

struct InVertex{
    packed_float3 position;
    packed_float3 normal;
    float bone0;
    float weight0;
    float bone1;
    float weight1;
};
struct InVertexStatic{
    packed_float3 position;
    packed_float3 normal;

};
//常量

constant float3 Light_Position = float3(0,400,0);
constant float4 materialAmbientColor = float4(0.15, 0.15, 0.15, 1.0);
constant float4 materialDiffuseColor = float4(0.4, 0.4, 0.4, 1.0);
constant float4 light_color = float4(1.0, 1.0, 1.0, 1.0);
constant float4 materialSpecularColor = float4(1.0, 1.0, 1.0, 1.0);
constant float materialShine = 500.0;
//constant float4x4 bais = float4x4(float4(0.5,0,0,0),float4(0,0.5,0,0),float4(0,0,0.5,0),float4(0.5,0.5,0.5,1));

struct OutVertex{
    float4 position [[position]];
    //float pointSize [[point_size]];
    float3 normal_camerasapce;
    float3 eye_direnction_cameraspace;
    float3 light_direction_camerasapce;
    float4 v_shadowcoord;
};


vertex float4 shadow_mapping_vertex_shader(const device InVertex* vertex_array [[buffer(0)]],const device uniform_buffer& mvp [[buffer(1)]],const device float4x4* anim_uniform [[buffer(2)]],unsigned int vid [[vertex_id]]){
    //计算骨骼动画
    float4x4 animTranform;
    if(vertex_array[vid].bone1 != -1){
        animTranform =  vertex_array[vid].weight0 * anim_uniform[static_cast<int>(vertex_array[vid].bone0)]+vertex_array[vid].weight1  * anim_uniform[static_cast<int>(vertex_array[vid].bone1)];
    }else{
        animTranform = anim_uniform[static_cast<int>(vertex_array[vid].bone0)];
    }
    float4 pos = mvp.p * mvp.v * mvp.m * animTranform * float4(float3(vertex_array[vid].position),1.0);
    pos = pos/pos.w;
    return pos;
    
}

vertex float4 shadow_mapping_vertex_shader_static(const device InVertexStatic* vertex_array [[buffer(0)]],const device uniform_buffer& mvp[[buffer(1)]],unsigned int vid [[vertex_id]]){
    float4 pos = mvp.p * mvp.v * mvp.m * float4(float3(vertex_array[vid].position),1.0);
    pos = pos/pos.w;
    return pos;
}





vertex OutVertex vertexShader(const device InVertex* vertex_array [[buffer(0)]],const device uniform_buffer& mvp [[buffer(1)]],const device float4x4* anim_uniform [[buffer(2)]],const device uniform_buffer& light [[buffer(3)]],unsigned int vid [[vertex_id]]){
    OutVertex vertexOut;
    //计算骨骼动画
    float4x4 animTranform;
    if(vertex_array[vid].bone1 != -1){
        animTranform =  vertex_array[vid].weight0 * anim_uniform[static_cast<int>(vertex_array[vid].bone0)]+vertex_array[vid].weight1  * anim_uniform[static_cast<int>(vertex_array[vid].bone1)];
    }else{
        animTranform = anim_uniform[static_cast<int>(vertex_array[vid].bone0)];
    }
    
    //矩阵计算准备（尽量避免重复计算，Apple的sample中有重复计算）
    float4x4 model_matrix = mvp.m * animTranform;
    float4x4 view_matrix  = mvp.v;
    float4x4 projection_matrix = mvp.p;
    float4x4 model_view_matrx = mvp.v * model_matrix;
    float4x4 mvp_matrix = mvp.p * model_view_matrx;
    
    //计算坐标（VP中的位置）
    vertexOut.position = mvp_matrix * float4(float3((vertex_array[vid]).position),1.0);
    float4x4 bais;
    bais[0] = float4(0.5,0,0,0);
    bais[1] = float4(0,-0.5,0,0);
    bais[2] = float4(0,0,1,0);
    bais[3] = float4(0.5,0.5,0,1);
    

    vertexOut.v_shadowcoord = bais * light.p * light.v * light.m * float4(float3((vertex_array[vid]).position),1.0);
    //计算发现在camera中的位置
    float3 normal = vertex_array[vid].normal;
    vertexOut.normal_camerasapce = (normalize(model_view_matrx * float4(normal,0.0))).xyz;
    //计算观察向量（V中）
    float3 vertex_position_cameraspace = (model_view_matrx * float4(float3(vertex_array[vid].position),1.0)).xyz;
    vertexOut.eye_direnction_cameraspace = float3(0.0,0.0,0.0) - vertex_position_cameraspace;
    //计算光线方向在(V中)
    float3 light_position_camerasapce = (view_matrix * float4(Light_Position,1.0f)).xyz;
    vertexOut.light_direction_camerasapce = light_position_camerasapce + vertexOut.eye_direnction_cameraspace;
    
    return vertexOut;
}
vertex OutVertex vertexShader_Static(const device InVertexStatic* vertex_array [[buffer(0)]],const device uniform_buffer& mvp[[buffer(1)]],const device uniform_buffer& light [[buffer(3)]],unsigned int vid [[vertex_id]]){
    OutVertex vertexOut;
    float4x4 model_matrix = mvp.m;
    float4x4 view_matrix  = mvp.v;
    float4x4 projection_matrix = mvp.p;
    float4x4 model_view_matrx = mvp.v * model_matrix;
    float4x4 mvp_matrix = mvp.p * model_view_matrx;
    
    //计算坐标（VP中的位置）
    vertexOut.position = mvp_matrix * float4(float3((vertex_array[vid]).position),1.0);
    float4x4 bais;
    bais[0] = float4(0.5,0,0,0);
    bais[1] = float4(0,-0.5,0,0);
    bais[2] = float4(0,0,1,0);
    bais[3] = float4(0.5,0.5,0,1);
    
    vertexOut.v_shadowcoord = bais * light.p * light.v * light.m * float4(float3((vertex_array[vid]).position),1.0);
    //计算发现在camera中的位置
    float3 normal = vertex_array[vid].normal;
    vertexOut.normal_camerasapce = (normalize(model_view_matrx * float4(normal,0.0))).xyz;
    //计算观察向量（V中）
    float3 vertex_position_cameraspace = (model_view_matrx * float4(float3(vertex_array[vid].position),1.0)).xyz;
    vertexOut.eye_direnction_cameraspace = float3(0.0,0.0,0.0) - vertex_position_cameraspace;
    //计算光线方向在(V中)
    float3 light_position_camerasapce = (view_matrix * float4(Light_Position,1.0f)).xyz;
    vertexOut.light_direction_camerasapce = light_position_camerasapce + vertexOut.eye_direnction_cameraspace;
    return vertexOut;
}

fragment half4 phong_fragment(OutVertex in [[stage_in]],depth2d<float> shadow_texture [[texture(0)]]){
    half4 color;
    constexpr sampler shadow_sampler(coord::normalized, filter::linear, address::clamp_to_edge, compare_func::less);
    
    float shadow = shadow_texture.sample_compare(shadow_sampler, in.v_shadowcoord.xy/in.v_shadowcoord.w, in.v_shadowcoord.z/in.v_shadowcoord.w);
    
    //计算漫反射
    float3 n = normalize(in.normal_camerasapce);
    float3 l = normalize(in.light_direction_camerasapce);
    auto n_dot_l = saturate(dot(n,l));
    float4 diffuse_color = light_color * n_dot_l * materialDiffuseColor;
    
    //计算全反射
    
    float3 e = normalize(in.eye_direnction_cameraspace);
    float3 r = -l + 2.0 * n_dot_l * n;
    float e_dot_r = saturate(dot(e,r));
    float4 specular_color = materialSpecularColor * light_color * pow(e_dot_r,materialShine);
    color = half4(half3(materialAmbientColor.rgb + shadow * (diffuse_color.rgb + specular_color.rgb)),1.0);

    //color = half4(materialAmbientColor + diffuse_color + specular_color);
    //color.a = shadow;
    return color;
}

fragment half4 phong_fragment_static(OutVertex in [[stage_in]],depth2d<float> shadow_texture [[texture(0)]]){
    half4 color;
    
    constexpr sampler shadow_sampler(coord::normalized, filter::linear, address::clamp_to_edge, compare_func::less);
    
    float shadow = shadow_texture.sample_compare(shadow_sampler, in.v_shadowcoord.xy/in.v_shadowcoord.w, in.v_shadowcoord.z/in.v_shadowcoord.w);
    //计算漫反射
    float3 n = normalize(in.normal_camerasapce);
    float3 l = normalize(in.light_direction_camerasapce);
    auto n_dot_l = saturate(dot(n,l));
    float4 diffuse_color = light_color * n_dot_l * materialDiffuseColor;
    
    //计算全反射
    
    float3 e = normalize(in.eye_direnction_cameraspace);
    float3 r = -l + 2.0 * n_dot_l * n;
    float e_dot_r = saturate(dot(e,r));
    float4 specular_color = materialSpecularColor * light_color * pow(e_dot_r,materialShine);
    color = half4(half3(float3(0.15,0.85,0.1) + shadow * (diffuse_color.rgb + specular_color.rgb)),1.0);
    //color = half4(float4(0.15,0.85,0.1,1.0) + diffuse_color + specular_color);
    return color;
}


fragment half4 fragmentShader1(OutVertex inFrag [[stage_in]]){
    return half4(0.1,0.2,0.8,1.0);
}

fragment half4 fragmentShader2(OutVertex inFrag [[stage_in]]){
    return half4(0.1,0.65,0.1,0.4);
}