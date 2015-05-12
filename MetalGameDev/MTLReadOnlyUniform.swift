//
//  MTLReadOnlyUniform.swift
//  MetalGameDev
//
//  Created by YiLi on 15/5/7.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//

import Foundation


class MTLReadOnlyUniform: NSObject {
    var m_uniform:MTLBuffer! = nil
    var m_bufferSize:Int?
    
    init(size:Int,device:MTLDevice) {
        
        m_bufferSize = size
        m_uniform = device.newBufferWithLength(size, options: nil)
    }
    
    
    func updateDataToUniform(from:UnsafePointer<Void>){
        memcpy(m_uniform.contents(), from, m_bufferSize!)
    }
}