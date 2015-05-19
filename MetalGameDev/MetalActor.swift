//
//  MTLActor.swift
//  GameMetal
//
//  Created by liuang on 15/4/19.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Metal

class MTLActor:NSObject{
    var m_mesh:MTLMesh! = nil
    var m_animationController:MTLAnimationController?
    var m_pos:[Float]! = nil
    var m_up:[Float]! = nil
    var m_lookAt:[Float]! = nil
    var m_texture:MTLTexture! = nil
    var m_normalMapping:MTLTexture! = nil
    //var m_angleToTarget:Float = 0
    //var m_rotateUp:[Float]! = nil
    var m_scene:MTLGameScene! = nil
    init(mesh:MTLMesh,animationController:MTLAnimationController?,pos:[Float]?,scene:MTLGameScene?,texture:MTLTexture?,normalmap:MTLTexture?) {
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
    
    func lookAtAxis(target:[Float])->Matrix{
        var toVector = [target[0],0,target[2]]
        let angleCos = Matrix.normalize(toVector)[2]
        let  angleToTarget =  acos(angleCos) * 180 / 3.1415
        let rotateUp = Matrix.cross(m_lookAt, b: toVector)
        var matrix = Matrix.MatrixMakeRotate(angleToTarget, r: rotateUp)
        m_scene.m_uniform.setModelMatrix(matrix.raw())
        m_scene.m_player.m_lightUniform.setModelMatrix(matrix.raw())
        return matrix
    }
    
    func lookAtPoint(target:[Float]){
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
    }
    
    func translate(target:[Float]){
        var translateMatrix = lookAtAxis(target)
        translateMatrix.translate(target[0], y: target[1], z:target[2])
        m_scene.m_uniform.setModelMatrix(translateMatrix.raw())
        m_scene.m_player.m_lightUniform.setModelMatrix(translateMatrix.raw())
    }
    
    
}