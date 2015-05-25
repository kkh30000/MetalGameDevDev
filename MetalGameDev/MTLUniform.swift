//
//  MTLUniform.swift
//  GameMetal
//
//  Created by liuang on 15/3/30.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Foundation
import Metal


class MTLUniform: NSObject {
    var m_data:[Float]?
    var m_uniform1:MTLBuffer?
    var m_uniform2:MTLBuffer?
    var m_uniform3:MTLBuffer?
    var m_bufferSize:Int?
    var m_device:MTLDevice! = nil
    
    init(size:Int,device:MTLDevice) {
        super.init()
        m_bufferSize = size
        m_uniform1 = device.newBufferWithLength(m_bufferSize!, options: nil)
        m_uniform1!.label = "Buffer1"
        m_uniform2 = device.newBufferWithLength(m_bufferSize!, options: nil)
        m_uniform1!.label = "Buffer2"
        m_uniform3 = device.newBufferWithLength(m_bufferSize!, options: nil)
        m_uniform1!.label = "Buffer3"
        
        m_device = device
    }
    
    init(data:[Float],device:MTLDevice){
        super.init()
        m_data = data
        m_bufferSize = data.count * sizeofValue(data[0])
        m_uniform1 = device.newBufferWithLength(m_bufferSize!, options: nil)
        m_uniform2 = device.newBufferWithLength(m_bufferSize!, options: nil)
        m_uniform3 = device.newBufferWithLength(m_bufferSize!, options: nil)
        m_device = device

    }
    
    subscript (index:Int)->MTLBuffer{
        get{
            if index == 0{
                return m_uniform1!
            }else if index == 1{
                return m_uniform2!
            }else{
                return m_uniform3!
            }
            
        }
    }
    
    func updateDataToUniform(from : UnsafePointer<Void> ,player:MTLGamePlayer){
        memcpy(self[player.m_currentUniform!].contents(), from, m_bufferSize!)
    }
    func updateDataToUniform(from:UnsafePointer<Void>,toUniform:MTLBuffer){
        memcpy(toUniform.contents(), from, m_bufferSize!)
    }
    
    func updata(player:MTLGamePlayer){
        if m_data != nil{
            memcpy(self[player.m_currentUniform!].contents(),m_data!, m_bufferSize!)
        }
    }
}