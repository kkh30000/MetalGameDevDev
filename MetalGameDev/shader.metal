//
//  shader.metal
//  GameMetal
//
//  Created by liuang on 15/3/29.
//  Copyright (c) 2015年 liuang. All rights reserved.
//
#include <metal_stdlib>
#include "structure.h"
using namespace metal;


//常量







//*******************************Render Shadow Map*************************************************
vertex float4 shadow_mapping_vertex_shader(const device InVertex* vertex_array [[buffer(0)]],const device uniform_buffer& mvp [[buffer(1)]],const device float4x4* anim_uniform [[buffer(2)]],unsigned int vid [[vertex_id]]){
    //计算骨骼动画
    float4x4 animTranform;
    if(vertex_array[vid].bone1 != -1){
        animTranform =  vertex_array[vid].weight0 * anim_uniform[static_cast<int>(vertex_array[vid].bone0)]+vertex_array[vid].weight1  * anim_uniform[static_cast<int>(vertex_array[vid].bone1)];
    }else{
        animTranform = anim_uniform[static_cast<int>(vertex_array[vid].bone0)];
    }
    float4 pos = mvp.p * mvp.v */* mvp.m **/ animTranform * float4(float3(vertex_array[vid].position),1.0);
   // pos = pos/pos.w;
    return pos;
    
}
//static
vertex float4 shadow_mapping_vertex_shader_static(const device InVertexStatic* vertex_array [[buffer(0)]],const device uniform_buffer& mvp[[buffer(1)]],unsigned int vid [[vertex_id]]){
    float4 pos = mvp.p * mvp.v * mvp.m * float4(float3(vertex_array[vid].position),1.0);
   // pos = pos/pos.w;
    return pos;
}




//*******************************Render To Texture*************************************************

vertex OutVertex vertexShader(const device InVertex* vertex_array [[buffer(0)]],const device uniform_buffer& mvp [[buffer(1)]],const device float4x4* anim_uniform [[buffer(2)]],const device uniform_buffer& light [[buffer(3)]],const device SpotLight* spotlights [[buffer(4)]],unsigned int vid [[vertex_id]]){
    OutVertex vertexOut;
    //计算骨骼动画
    float4x4 animTranform;
    if(vertex_array[vid].bone1 != -1){
        animTranform =  vertex_array[vid].weight0 * anim_uniform[static_cast<int>(vertex_array[vid].bone0)]+vertex_array[vid].weight1  * anim_uniform[static_cast<int>(vertex_array[vid].bone1)];
    }else{
        animTranform = anim_uniform[static_cast<int>(vertex_array[vid].bone0)];
    }
    
    //矩阵计算准备（尽量避免重复计算，Apple的sample中有重复计算）
    float4x4 model_matrix = /*mvp.m **/ animTranform;
    float4x4 view_matrix  = mvp.v;
    float4x4 projection_matrix = mvp.p;
    float4x4 model_view_matrx = mvp.v * model_matrix;
    float4x4 mvp_matrix = mvp.p * model_view_matrx;
    
    //计算坐标（VP中的位置）
    vertexOut.position = mvp_matrix * float4(float3((vertex_array[vid]).position),1.0);
    float4x4 bais;
    bais[0] = float4(0.5,0,0,0);
    bais[1] = float4(0,-0.5,0,0);
    bais[2] = float4(0,0,0.5,0);
    bais[3] = float4(0.5,0.5,0.5,1);
    
    vertexOut.texCoord = vertex_array[vid].texCoord;
    vertexOut.v_shadowcoord = bais * light.p * light.v * float4(float3((vertex_array[vid]).position),1.0);
    //计算发现在camera中的位置
    float3 normal = vertex_array[vid].normal;
    vertexOut.normal_camerasapce = (normalize(model_view_matrx * float4(normal,0.0))).xyz;
    //计算观察向量（V中）
    float3 vertex_position_cameraspace = (model_view_matrx * float4(float3(vertex_array[vid].position),1.0)).xyz;
    vertexOut.eye_direnction_cameraspace = float3(0.0,0.0,0.0) - vertex_position_cameraspace;
    //计算光线方向在(V中)
    float3 light_position_camerasapce = (view_matrix * float4(spotlights[0].pos,1.0f)).xyz;
    vertexOut.light_direction_camerasapce = light_position_camerasapce + vertexOut.eye_direnction_cameraspace;
    vertexOut.lightcolor0 = spotlights[0].color;
    
    return vertexOut;
}
vertex OutVertex vertexShader_Static(const device InVertexStatic* vertex_array [[buffer(0)]],const device uniform_buffer& mvp[[buffer(1)]],const device uniform_buffer& light [[buffer(3)]],const device SpotLight* spotlights [[buffer(4)]],unsigned int vid [[vertex_id]]){
    OutVertex vertexOut;
    float4x4 model_matrix = mvp.m;
    float4x4 view_matrix  = mvp.v;
    float4x4 projection_matrix = mvp.p;
    float4x4 model_view_matrx = mvp.v * model_matrix;
    float4x4 mvp_matrix = mvp.p * model_view_matrx;
    
    vertexOut.texCoord = vertex_array[vid].texCoord;
    
    //计算坐标（VP中的位置）
    vertexOut.position = mvp_matrix * float4(float3((vertex_array[vid]).position),1.0);
    float4x4 bais;
    bais[0] = float4(1,0,0,0);
    bais[1] = float4(0,-1,0,0);
    bais[2] = float4(0,0,0.5,0);
    bais[3] = float4(0.5,0.5,0.5,1);
    
    vertexOut.v_shadowcoord = bais * light.p * light.v *float4(float3((vertex_array[vid]).position),1.0);
    //计算发法线camera中的位置
    float3 normal = vertex_array[vid].normal;
    vertexOut.normal_camerasapce = (normalize(model_view_matrx * float4(normal,0.0))).xyz;
    //计算观察向量（V中）
    float3 vertex_position_cameraspace = (model_view_matrx * float4(float3(vertex_array[vid].position),1.0)).xyz;
    vertexOut.eye_direnction_cameraspace = float3(0.0,0.0,0.0) - vertex_position_cameraspace;
    //计算光线方向在(V中)
    float3 light_position_camerasapce = (view_matrix * float4(spotlights[0].pos,1.0f)).xyz;
    vertexOut.light_direction_camerasapce = light_position_camerasapce + vertexOut.eye_direnction_cameraspace;
    
    vertexOut.lightcolor0 = spotlights[0].color;
    
    return vertexOut;
}


fragment float4 phong_fragment(OutVertex in [[stage_in]],depth2d<float> shadow_texture [[texture(0)]]){
    float4 color;
    
    
    //计算漫反射
    float3 n = normalize(in.normal_camerasapce);
    float3 l = normalize(in.light_direction_camerasapce);
    auto n_dot_l = saturate(dot(n,l));
    float4 diffuse_color = in.lightcolor0 * n_dot_l * materialDiffuseColor;
    
    //计算全反射
    
    float3 e = normalize(in.eye_direnction_cameraspace);
    float3 r = -l + 2.0 * n_dot_l * n;
    float e_dot_r = saturate(dot(e,r));
    float4 specular_color = materialSpecularColor * in.lightcolor0 * pow(e_dot_r,materialShine);
    color = float4(float3(materialAmbientColor.rgb +  (diffuse_color.rgb + specular_color.rgb)),1.0);
    
    
    return color;
}

fragment float4 phong_fragment_static(OutVertex in [[stage_in]],depth2d<float> shadow_texture [[texture(0)]],texture2d<float> modelTexture [[texture(1)]]){
    float4 color;
    float4 modelColor;
    constexpr sampler shadow_sampler(coord::normalized, filter::linear, address::clamp_to_zero, compare_func::less);
    constexpr sampler texture_sampler;
    modelColor = modelTexture.sample(texture_sampler,in.texCoord,0);
    //float shadow = shadow_texture.sample_compare(shadow_sampler, in.v_shadowcoord.xy/in.v_shadowcoord.w, in.v_shadowcoord.z/in.v_shadowcoord.w);
    //计算漫反射
    float3 n = normalize(in.normal_camerasapce);
    float3 l = normalize(in.light_direction_camerasapce);
    auto n_dot_l = saturate(dot(n,l));
    float4 diffuse_color = in.lightcolor0 * n_dot_l * materialDiffuseColor;
    
    //计算全反射
    
    float3 e = normalize(in.eye_direnction_cameraspace);
    float3 r = -l + 2.0 * n_dot_l * n;
    float e_dot_r = saturate(dot(e,r));
    float4 specular_color = materialSpecularColor * in.lightcolor0 * pow(e_dot_r,materialShine);
    color = float4(float3(modelColor.rgb + (diffuse_color.rgb + specular_color.rgb)),0.9);
    //color = half4((half4(0.15,0.85,0.1,1.0) + half4(diffuse_color + specular_color)).xyz,shadow);
    return color;
}







//*******************************Render To Screnn(Final Pass)*************************************************


struct FinalVertexIn{
    packed_float3 position;
    packed_float2 texCoord;
};

struct FinalVertexOut{
    float4 m_Position [[position]];
    float2 m_TexCoord ;
};



//render to texture之后，再final pass中实现 FXAA



//final pass vertex shader
vertex FinalVertexOut render_to_screen_vertex(const device FinalVertexIn* vertex_array [[buffer(0)]],const device uniform_buffer& mvp [[buffer(1)]],unsigned int vid [[vertex_id]]){
    FinalVertexOut vertexOut;
    
    
    
    float4x4 bais;
    bais[0] = float4(0.5,0,0,0);
    bais[1] = float4(0,-0.5,0,0);
    bais[2] = float4(0,0,1,0);
    bais[3] = float4(0.5,0.5,0,1);
    vertexOut.m_Position = mvp.p * mvp.v * mvp.m * float4(float3(vertex_array[vid].position),1.0);
    vertexOut.m_TexCoord = vertex_array[vid].texCoord;
    return vertexOut;
}

//final pass fragment shader
fragment half4 render_to_screen_fragment(FinalVertexOut in [[stage_in]],texture2d<half> tex2D [[texture(0)]]){
    constexpr sampler finalSampler;
    //return half4(tex2D.sample(finalSampler,in.m_TexCoord));
    float3 luma = float3(0.299,0.587,0.114);
    float2 resolution = float2(1.0/1920.0,1.0/1080.0);
    //float2 resoVerse = float2(1024,768);
    //float3 daf= tex2D.sample(finalSampler,in.m_TexCoord.xy,int2(0,-1)).xyz;
    auto lumaNw = dot(luma,float3(tex2D.sample(finalSampler,in.m_TexCoord.xy ,int2(-1,-1)).xyz));
    auto lumaNe = dot(luma,float3(tex2D.sample(finalSampler,in.m_TexCoord.xy,int2( 1,-1)).xyz));
    auto rgbaM = tex2D.sample(finalSampler,in.m_TexCoord.xy);
    auto rgbM = float3(rgbaM.xyz);
    half opacity = half(rgbaM.a);
    auto lumaM = dot(luma,rgbM);
    auto lumaSe = dot(luma,float3(tex2D.sample(finalSampler,in.m_TexCoord.xy,int2(1,1)).xyz));
    auto lumaSw = dot(luma,float3(tex2D.sample(finalSampler,in.m_TexCoord.xy,int2(-1,1)).xyz));
    
    float lumaMin = min(lumaM,min(min(lumaNw,lumaNe),min(lumaSw,lumaSe)));
    float lumaMax = max(lumaM,max(max(lumaNw,lumaNe),max(lumaSw,lumaSe)));
    float range = lumaMax - lumaMin;
    if(range <
       max(1.0/16.0, lumaMax /64.0)) {
        return half4(rgbaM);
    }
    
    
    float2 dir;
    dir.x = -(lumaNw+lumaNe - lumaSw - lumaSe);
    dir.y =  (lumaNw+lumaSw - lumaNe - lumaSe);
    
    
    float dirReduce = max((lumaNw + lumaNe + lumaSw + lumaSe) * (0.25 / 8.0),1.0/256.0);
    float rcpDirMin = 1.0/(min(abs(dir.x),abs(dir.y)) + dirReduce);
    
    dir = min(float2(8.0,8.0),max(float2(-8.0,-8.0),dir * rcpDirMin)) * resolution;
    
    float3 rgbA = 0.5 * float3(tex2D.sample(finalSampler,in.m_TexCoord.xy + dir * (1.0/3.0 - 0.5)).rgb)+
    0.5 * float3(tex2D.sample(finalSampler,in.m_TexCoord.xy + dir * (2.0/3.0 - 0.5)).rgb);
    
    float3 rgbB = 0.25 * float3(tex2D.sample(finalSampler,in.m_TexCoord.xy + dir * (0.0/3.0 - 0.5)).rgb)+
    0.25 * float3(tex2D.sample(finalSampler,in.m_TexCoord.xy + dir * (3.0/3.0 - 0.5)).rgb) + 0.5 * rgbA;
    
    
    
    float lumaB = dot( rgbB, luma );
              
    if ( ( lumaB < lumaMin ) || ( lumaB > lumaMax ) ) {
                  
        return half4(half3(rgbA.rgb),opacity);
                  
    } else {
                  
        return half4(half3(rgbB.rgb),opacity);
        
    }

    
}


//Testing Fragmnet
fragment half4 fragmentShader1(OutVertex inFrag [[stage_in]]){
    return half4(0.1,0.2,0.8,1.0);
}

fragment half4 fragmentShader2(OutVertex inFrag [[stage_in]]){
    return half4(0.1,0.65,0.1,0.4);
}