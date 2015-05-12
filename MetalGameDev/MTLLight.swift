//
//  MTLLight.swift
//  MetalGameDev
//
//  Created by YiLi on 15/5/7.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//

import Foundation
import Metal

class MTLSpotLight: NSObject {
    var m_pos:[Float] = [0,0,0]
    var m_attenuation:Float = 0.0
    var m_color:[Float] = [0,0,0,0]
    
    init(pos:[Float],attenuation:Float,color:[Float]) {
        super.init()
        m_pos = pos
        m_attenuation = attenuation
        m_color = color
        
    }
}



class MTLLights: NSObject {
    var m_lights:[MTLSpotLight]! = nil
    var m_raw:[Float]! = nil
    var m_uniformBuffer:MTLReadOnlyUniform! = nil
    init(lights:[MTLSpotLight],device:MTLDevice) {
        super.init()
        m_lights = lights
        var bufferSize = m_lights.count * (m_lights[0].m_pos.count + m_lights[0].m_color.count + 1) * sizeofValue(m_lights[0].m_attenuation)
        m_raw = [Float](count: bufferSize, repeatedValue: 0.0)
        var i = 0
        for ele in m_lights{
            m_raw[0+i...3+i] = ele.m_color[0...3]
            m_raw[4+i...6+i] = ele.m_pos[0...2]
            m_raw[7+i] = ele.m_attenuation
            i += 8
        }
        m_uniformBuffer = MTLReadOnlyUniform(size: bufferSize, device: device)
        m_uniformBuffer.updateDataToUniform(m_raw)
    }
    
    func updateLight(){
        m_uniformBuffer.updateDataToUniform(m_raw)
    }
    
    
}
