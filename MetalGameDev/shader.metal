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


struct OutVertex{
    float4 position [[position]];
    //float pointSize [[point_size]];
};

vertex OutVertex vertexShader(const device InVertex* vertex_array [[buffer(0)]],const device uniform_buffer& mvp [[buffer(1)]],const device float4x4* anim_uniform [[buffer(2)]],unsigned int vid [[vertex_id]]){
    OutVertex vertexOut;
    float4x4 animTranform;
    if(vertex_array[vid].bone1 != -1){
        animTranform =  vertex_array[vid].weight0 * anim_uniform[static_cast<int>(vertex_array[vid].bone0)]+vertex_array[vid].weight1  * anim_uniform[static_cast<int>(vertex_array[vid].bone1)];
    }else{
        animTranform = anim_uniform[static_cast<int>(vertex_array[vid].bone0)];
    }
    
    vertexOut.position = mvp.p  * mvp.v * mvp.m *animTranform * float4(float3((vertex_array[vid]).position),1.0);
    //vertexOut.position = float4(float3(vertexOut.position.xyz)/500,1.0)
    //vertexOut.position = vertexOut.position/5;
    return vertexOut;
}
vertex OutVertex vertexShader_Static(const device packed_float3* vertex_array [[buffer(0)]],const device uniform_buffer& mvp[[buffer(1)]],unsigned int vid [[vertex_id]]){
    OutVertex vertexOut;
    vertexOut.position = mvp.p * mvp.v * float4x4(1.0) * float4(float3(vertex_array[vid]),1.0);
    return vertexOut;
}

fragment half4 fragmentShader1(OutVertex inFrag [[stage_in]]){
    return half4(0.1,0.2,0.8,1.0);
}

fragment half4 fragmentShader2(OutVertex inFrag [[stage_in]]){
    return half4(0.3,0.9,0.4,0.5);
}