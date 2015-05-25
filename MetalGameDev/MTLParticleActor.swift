//
//  MTLParticleActor.swift
//  MetalGameDev
//
//  Created by YiLi on 15/5/22.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//

import Foundation
import Metal




class MTLParticleActor: MTLActor {
    var m_particle:MTLParticle! = nil
    var m_isParticle = true
    var m_startTime:NSDate! = nil
    var m_currentTime:NSDate! = nil
    var m_modelMatrix:Matrix! = nil
    
    
    //Buffers
    var m_initialDirectionBuffer:MTLBuffer! = nil
    var m_mvp:MTLMVPUniform! = nil
    var m_birthOffsetBuffer:MTLBuffer! = nil
    var m_particleUniform:MTLUniform! = nil
    var m_particleProperty:[Float]! = nil
    
    init(particle:MTLParticle,scene:MTLGameScene,vertexShader:String,fragmentShader:String,drawType:MTLPrimitiveType,deptType:MTLPixelFormat,blendingEnable:Bool,actorType:ActorType,mvpuniform:MTLMVPUniform){
        super.init(mesh: MTLMesh(meshAsset: nil, scene: scene, vertexShader: vertexShader, fragmentShader: fragmentShader, drawType: drawType, depthType: deptType, blendingEnable: blendingEnable), animationController: nil, pos: nil, scene: scene, texture: nil, normalmap: nil)
        m_particle = particle
        m_actorType = ActorType.PARTICLE
        m_startTime = NSDate()
        
        m_initialDirectionBuffer = scene.m_device!.newBufferWithLength(sizeof(Float) * m_particle.m_initialDirection.count, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        memcpy(m_initialDirectionBuffer.contents(),m_particle.m_initialDirection,  (sizeof(Float) * m_particle.m_initialDirection.count))
        m_initialDirectionBuffer.label = "initial direction buffer"
        
        m_birthOffsetBuffer = scene.m_device!.newBufferWithLength(sizeof(Float) * m_particle.m_birthOffset.count, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        memcpy(m_birthOffsetBuffer.contents(),m_particle.m_birthOffset,  (sizeof(Float) * m_particle.m_initialDirection.count))
        m_birthOffsetBuffer.label = "birthoffset buffer"
        m_mvp = mvpuniform
        //m_mvp = MTLMVPUniform(uniform: scene.m_uniform, device: scene.m_device!, player: scene.m_player)
        //m_modelMatrix = Matrix()
        //m_mvp.setModelMatrix(m_modelMatrix.raw())
        m_particleProperty = [Float](count: 2, repeatedValue: 0.0)
        m_particleProperty[0] = m_particle.m_lifespan
        m_particleUniform = MTLUniform(data: m_particleProperty, device: scene.m_device!)
    }
    
    
    func updateParticle(viewcontroller:MTLGameViewController){
        m_particleUniform.m_data![1] = Float(NSDate().timeIntervalSinceDate(m_startTime))
        let scene = viewcontroller.view as! MTLGameScene
        m_particleUniform.updata(scene.m_player)
        //m_modelMatrix = m_modelMatrix * viewcontroller.m_me
        m_mvp.update()
        
    }
    
}