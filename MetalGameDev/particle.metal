//
//  particle.metal
//  MetalGameDev
//
//  Created by YiLi on 15/5/22.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//


#include <metal_stdlib>
#include <metal_common>
#include <simd/simd.h>
#include "structure.h"

using namespace metal;

struct ColorInOut {
    float4 position [[position]];
    float point_size [[point_size]];
    float t;
    float lifespan;
};

struct ParticleProperty{
    float lifespan;
    float t;
};

// Global constants
constant float POINT_SIZE = 60.0f;
constant float3 a = float3(.0, -18.0f, .0);
constant float3 x_0 = float3(0.0, 0.0, 0.0);
//constant float3 GRAVITITY = float3(0.0,-10,0.0)


// Phong vertex shader function
vertex ColorInOut vertexParticle(device packed_float3* initialDirection [[ buffer(1) ]],
                                  device float* birthOffsets [[ buffer(2) ]],
                                  constant uniform_buffer& uniforms [[ buffer(0) ]],
                                  constant ParticleProperty& particleUniform [[buffer(3)]],
                                  unsigned int vid [[ vertex_id ]]) {
    ColorInOut out;
    
    float4x4 model_matrix = uniforms.m;
    float4x4 view_matrix = uniforms.v;
    float4x4 projection_matrix = uniforms.p;
    float4x4 mvp_matrix = projection_matrix * view_matrix * model_matrix;
    
    // Have the particles repeat their movement by keeping their time between 0 and their
    // lifespan.
    float t = fmod(particleUniform.t + birthOffsets[vid], particleUniform.lifespan);
    
    
    
    // Calculate the position of the particle based on the physics equation for motion:
    // x = x_0 + (v_0 * t) + (1/2)(a * t^2)
    float3 v_0 = float3( initialDirection[vid] );
    float3 vertex_position_modelspace =  x_0 + (v_0 * t) + (0.5f * a * t * t);
    out.position = mvp_matrix * float4(vertex_position_modelspace, 1.0f);
    
    out.point_size = POINT_SIZE;
    out.t = t;
    out.lifespan = particleUniform.lifespan;
    return out;
}

// Phong fragment shader function
fragment half4 fragmentParticle(ColorInOut in [[stage_in]], float2 uv[[point_coord]])
{
    half4 color = half4(1.0f, 0.5f, 0.0f, 1.0f);
    
    // Make the particle fade off as it gets older by multiplying the percentage of life
    // left for the particle by it's color.
    float lifeAlpha = (in.lifespan - in.t) / in.lifespan;
    color *= lifeAlpha;
    
    // Make the particles circular by using the uv coordinate to calculate the distance
    // this fragment is from the center of the particle. We set its color as more
    // transparent the closer it gets to the edge of the circle where the center of the
    // circle is completely opaque and the edge of the circle is completely transparent.
    float2 uvPos = uv;
    
    uvPos.x -= 0.5f;
    uvPos.y -= 0.5f;
    
    uvPos *= 2.0f;
    
    float dist = sqrt(uvPos.x*uvPos.x + uvPos.y*uvPos.y);
    float circleAlpha = saturate(1.0f-dist);
    
    color *= circleAlpha;
    
    return half4(color.r, color.g, color.b, circleAlpha*lifeAlpha);
};