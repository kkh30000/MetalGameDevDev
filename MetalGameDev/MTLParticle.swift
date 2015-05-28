//
//  MTLParticle.swift
//  MetalGameDev
//
//  Created by YiLi on 15/5/22.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//

import Foundation
import Metal




class MTLParticle: NSObject {
    
    var m_initialDirection:[Float]! = nil
    var m_initialDirectionBuffer:MTLBuffer! = nil
    
    var m_birthOffset:[Float]! = nil
    var m_birthOffsetBuffer:MTLBuffer! = nil
    
    
    var m_numOfParticles:Int! = nil
    var m_lifespan:Float! = nil
    
    
    init(device:MTLDevice,numOfParticles:Int,spread:Float,lifeSpan:Float) {
        var initialDirectionDataSize = numOfParticles * 3
        m_initialDirection = [Float](count: initialDirectionDataSize, repeatedValue: 0.0)
        
        
        for var i = 0 ; i < numOfParticles ; ++i{
            var d_0_x = spread * (2.0 * Float(rand()) / Float(RAND_MAX))
            var d_0_y = spread * (Float(rand()) / Float(RAND_MAX))
            var d_0_z = spread * (2.0 * Float(rand()) / Float(RAND_MAX))
            var length = sqrt(d_0_x * d_0_x + d_0_y * d_0_y + d_0_z * d_0_z)
            
            m_initialDirection[i * 3] = d_0_x / length * 500
            m_initialDirection[i * 3 + 1] = d_0_y / length * 1500
            m_initialDirection[i * 3 + 2] = d_0_z / length * 500
        }
        
        
        var birthOffsetDataSize = numOfParticles
        m_birthOffset = [Float](count: birthOffsetDataSize, repeatedValue: 0.0)
        
        
        for var i = 0 ; i < numOfParticles ; ++i{
            m_birthOffset[i] = lifeSpan * (Float(rand()) / Float(RAND_MAX))
            
        }
        
                
        m_numOfParticles = numOfParticles
        m_lifespan = lifeSpan
        
    }
}