//
//  compute_particle_fire.metal
//  MetalGameDev
//
//  Created by YiLi on 15/6/4.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//

#include <metal_stdlib>
#include "structure.h"
using namespace metal;
constant int octaves = 4;
constant float lacunarity = 1.0;
constant float gain = 0.5;
constant float softeningSquared = 0.01;

struct ShaderParams
{
    float4 attractor;
    float damping;
    float invNoiseSize;
    float noiseFreq;
    float noiseStrength;
    float spriteSize;
    float numParticles;
    float tail;
    float tail1;
};

// fractal sum


kernel void compute_particle_fire(texture3d<half,access::sample> noiseTexture [[texture(0)]],device float4* pos [[buffer(0)]],device float4* vel [[buffer(1)]],
    device ShaderParams& params [[buffer(2)]],uint3 gid [[thread_position_in_threadgroup]],uint index [[thread_index_in_threadgroup]]){
    if (index > params.numParticles){
        return;
    }
        constexpr sampler noiseSampler;
        float3 p = float4(pos[index]).xyz;
        float3 v = float4(vel[index]).xyz;
        p *= params.noiseFreq;
        
        float freq = 1.0, amp = 0.5;
        float3 sum = float3(0.0);
        for(int i=0; i<octaves; i++) {
            sum += float3(noiseTexture.sample(noiseSampler,p * params.invNoiseSize).xyz) * amp;
            freq *= lacunarity;
            amp *= gain;
        }
        v += sum * params.noiseStrength;
        auto vector = params.attractor.xyz - p;
        auto r2 = dot(vector,vector);
        r2 += softeningSquared;
        auto invDist = 1.0 / sqrt(r2);
        auto invDistCubed = invDist * invDist * invDist;
        auto attractor1 = vector * invDistCubed;
        
        v += attractor1 * params.attractor.w;
       
        
        // integrate
        p += v;
        v *= params.damping;
        
        // write new values
        pos[index] = float4(p, 1.0);
        vel[index] = float4(v, 0.0);
        
    
}

struct VertexOut{
    float4 pos [[position]];
    float2 texCoord;
    half4 color;
};

vertex VertexOut vertex_particle_fire(device packed_float4* pos [[buffer(0)]],device uniform_buffer& mvp [[buffer(1)]],unsigned int vid [[vertex_id]]){
    int particleID = vid >> 2;
    float4 particlePos = pos[particleID];
    VertexOut out;
    out.color = half4(0.5,0.2,0.1,1.0);
    int2 quadPos = int2(((vid -1) & 2) >> 1,(vid & 2) >> 1);
    
    float4 particlePosEye = mvp.m * mvp.v * particlePos;
    float2 xy = float2(quadPos.x * 2.0 - 1.0,quadPos.y * 2.0 - 1.0);
    float4 vertexPosEye = particlePosEye + float4(xy*0.02,0.0,0.0);
    out.texCoord = float2(quadPos.x,quadPos.y);
    out.pos = mvp.p * vertexPosEye;
    
    return out;
    
    
}

fragment half4 fragment_particle_fire(VertexOut in [[stage_in]]){
    float r = length(in.texCoord*2.0-1.0)*3.0;
    float i = exp(-r*r);
    if (i < 0.01) discard_fragment();
    
    return half4(in.color.rgb, i);
}






