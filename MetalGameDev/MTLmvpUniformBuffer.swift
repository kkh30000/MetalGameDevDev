//
//  MTLmvpUniformBuffer.swift
//  MetalGameDev
//
//  Created by YiLi on 15/4/30.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//

import Foundation
import Metal


class MTLMVPUniform: MTLUniform {
    var m_mvpMatrix:[Float]! = nil
    var m_player:MTLGamePlayer! = nil
    var m_modelMatrix:Matrix! = nil
    
    init(model:Matrix,view:Matrix,projection:Matrix,device:MTLDevice,player:MTLGamePlayer){
        super.init(size: sizeofValue(model.raw()[0]) * 48, device: device)
        m_mvpMatrix = [Float](count: 48, repeatedValue: 0.0)
        m_mvpMatrix[0...15] = model.raw()[0...15]
        m_mvpMatrix[16...31] = view.raw()[0...15]
        m_mvpMatrix[32...47] = projection.raw()[0...15]
        m_modelMatrix = model
        for var i = 0 ; i < 3 ; ++i{
            updateDataToUniform(m_mvpMatrix, toUniform: self[i])
        }
        m_player = player
    }
    
    init(uniform:MTLMVPUniform,device:MTLDevice,player:MTLGamePlayer){
        super.init(size: sizeofValue(uniform.m_data![0]) * 48, device: device)
        m_mvpMatrix = [Float](count: 48, repeatedValue: 0.0)
        m_mvpMatrix = uniform.m_mvpMatrix
        m_modelMatrix = Matrix()
        m_modelMatrix.m_raw = uniform.m_modelMatrix.m_raw
        for var i = 0 ; i < 3 ; ++i{
            updateDataToUniform(m_mvpMatrix, toUniform: self[i])
        }
        m_player = player


    }
    func setModelMatrix(model:[Float]){
        m_mvpMatrix[0...15] = model[0...15]
        //update()
    }
    func setViewMatrix(view:[Float]){
        m_mvpMatrix[16...31] = view[0...15]
        //update()
    }
    func setProjectionMatrix(projection:[Float]){
        m_mvpMatrix[32...47] = projection[0...15]
        //update()
    }
    func modelMatrix()->Matrix{
        return m_modelMatrix
    }
    func setModelMatrix(){
        m_mvpMatrix[0...15] = m_modelMatrix.raw()[0...15]
    }
    
    
    func update() {
        updateDataToUniform(m_mvpMatrix, player: m_player)
    }
    
}