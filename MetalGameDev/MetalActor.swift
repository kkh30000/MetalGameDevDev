//
//  MTLActor.swift
//  GameMetal
//
//  Created by liuang on 15/4/19.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Metal


enum ActorType{
    case DEFAULT
    case PARTICLE
    case FIREPARTICLE
}

class MTLActor:NSObject{
    var m_mesh:MTLMesh! = nil
    var m_animationController:MTLAnimationController?
    var m_pos:[Float]! = [0,0,0]
    var m_up:[Float]! = [0,1,0]
    var m_lookAt:[Float]! = [0,0,1]
    var m_texture:MTLTexture! = nil
    var m_normalMapping:MTLTexture! = nil
    //var m_angleToTarget:Float = 0
    //var m_rotateUp:[Float]! = nil
    var m_scene:MTLGameScene! = nil
    var m_actorType:ActorType! = ActorType.DEFAULT
    
    init(mesh:MTLMesh?,animationController:MTLAnimationController?,pos:[Float]?,scene:MTLGameScene?,texture:MTLTexture?,normalmap:MTLTexture?) {
        super.init()
        m_mesh = mesh
        m_animationController = animationController
        m_pos = pos
        m_up = [0,1,0]
        m_lookAt = [0,0,1]
        m_scene = scene
        m_texture = texture
        m_normalMapping = normalmap
    }
    
    func lookAtAxis(target:[Float]){
        var toVector = [target[0],0,target[2]] - [m_pos[0],0,m_pos[2]]
        let angleCos:Float = Matrix.normalize(toVector) * Matrix.normalize(m_lookAt)
        let  angleToTarget:Float =  acos(angleCos) * 180 / 3.1415
        let rotateUp = Matrix.cross(m_lookAt, b: toVector)
        m_lookAt = toVector
        m_scene.m_uniform.m_modelMatrix.rotate(angleToTarget, r: rotateUp)
        m_scene.m_player.m_lightUniform.m_modelMatrix.rotate(angleToTarget, r: rotateUp)
    }
    
    /*func lookAtPoint(target:[Float]){
        var toVector = [target[0],0,target[2]] - [m_pos[0],0,m_pos[2]]
        let angleCos:Float = Matrix.normalize(toVector) * Matrix.normalize(m_lookAt)
        let  angleToTarget:Float =  acos(angleCos) * 180 / 3.1415
        let rotateUp = Matrix.cross(m_lookAt, b: toVector)
        m_scene.m_uniform.m_modelMatrix.rotate(angleToTarget, r: rotateUp)
        m_scene.m_player.m_lightUniform.m_modelMatrix.rotate(angleToTarget, r: rotateUp)
        toVector = target - m_pos
        let angleCos1:Float = Matrix.normalize(toVector) * Matrix.normalize(m_lookAt)
        let angleToTarget1:Float = acos(angleCos1) * 180 / 3.1415
        let rotateUp1 = Matrix.cross(toVector, b: m_lookAt)
        m_lookAt = toVector
        m_scene.m_uniform.m_modelMatrix.rotate(angleToTarget1, r: rotateUp1)
        m_scene.m_player.m_lightUniform.m_modelMatrix.rotate(angleToTarget1, r: rotateUp1)
        
    }*/
    
    func translate(target:[Float]){
        let delta = target - m_pos
        
        
        lookAtAxis(target)
        //lookAtPoint(target)
        m_scene.m_uniform.modelMatrix().translate(delta[0], y: 0, z: delta[2])
        m_scene.m_uniform.setModelMatrix()
        m_scene.m_player.m_lightUniform.modelMatrix().translate(delta[0], y: 0, z: delta[2])
        m_scene.m_player.m_lightUniform.setModelMatrix()
        m_pos = target
        
        
    }
    
    
}