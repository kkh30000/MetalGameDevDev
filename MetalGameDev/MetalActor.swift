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
        var toVector = Matrix.normalize([target[0],0,target[2]] - [m_pos[0],0,m_pos[2]])
        let angleCos:Float = toVector * Matrix.normalize(m_lookAt)
        let  angleToTarget:Float =  acos(angleCos) * 180 / 3.1415
        let rotateUp = Matrix.cross(m_lookAt, b: toVector)
        
        //var matrix = Matrix.MatrixMakeRotate(angleToTarget, r: rotateUp)
        m_lookAt = [target[0],0,target[2]] - [m_pos[0],0,m_pos[2]]

        //println(angleToTarget)
        m_scene.m_uniform.m_modelMatrix.rotate(angleToTarget, r: rotateUp)
        //println(m_scene!.m_uniform.m_modelMatrix.raw())
        //m_scene.m_uniform.setModelMatrix()
        m_scene.m_player.m_lightUniform.m_modelMatrix.rotate(angleToTarget, r: rotateUp)
        //m_scene.m_player.m_lightUniform.setModelMatrix()
        //return matrix
    }
    
    /*func lookAtPoint(target:[Float]){
    var toVectorProjection = [target[0],0,target[2]]
    let angleCos = Matrix.normalize(toVectorProjection)[2]
    let angleToTarget =  acos(angleCos) * 180 / 3.1415
    let rotateUp = Matrix.cross(m_lookAt, b: toVectorProjection)
    var matrix = Matrix.MatrixMakeRotate(angleToTarget, r: rotateUp)
    m_scene.m_player.m_lightUniform.setModelMatrix(matrix.raw())
    
    var toVector = [target[0],target[1],target[2]]
    let rotateRight = Matrix.cross(toVectorProjection, b: toVector)
    let angleCos1 = Matrix.normalize(toVector)[2]
    let angleToTarget1 =  acos(angleCos1) * 180 / 3.1415
    
    //println(rotateRight,angleToTarget1)
    matrix.rotate(angleToTarget1, r: rotateRight)
    m_scene.m_uniform.setModelMatrix(matrix.raw())
    }*/
    
    func translate(target:[Float]){
        let delta = target - m_pos
        
        
        lookAtAxis(target)
        m_scene.m_uniform.modelMatrix().translate(delta[0], y: 0, z: delta[2])
        m_scene.m_uniform.setModelMatrix()
        m_scene.m_player.m_lightUniform.modelMatrix().translate(delta[0], y: 0, z: delta[2])
        m_scene.m_player.m_lightUniform.setModelMatrix()
        m_pos = target
        
        
    }
    
    
}