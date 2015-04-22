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
    var m_uniform1:MTLBuffer?
    var m_uniform2:MTLBuffer?
    var m_uniform3:MTLBuffer?
    var m_bufferSize:Int?
    
    init(size:Int,device:MTLDevice) {
        super.init()
        m_bufferSize = size
        m_uniform1 = device.newBufferWithLength(size, options: nil)
        m_uniform2 = device.newBufferWithLength(size, options: nil)
        m_uniform3 = device.newBufferWithLength(size, options: nil)
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
    
    func updateDataToUniform(from : UnsafePointer<Void> ,toUniform:MTLBuffer){
        memcpy(toUniform.contents(), from, m_bufferSize!)
    }
}