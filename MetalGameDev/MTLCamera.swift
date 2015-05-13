//
//  MTLCamera.swift
//  GameMetal
//
//  Created by liuang on 15/3/31.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Foundation


class MTLCamera:NSObject {
    var m_pos:[Float]! = nil
    var m_target:[Float]! = nil
    let m_up:[Float] = [0,1,0]
    var m_viewMatrix:Matrix?
    init(pos:[Float],target:[Float],up:[Float]) {
        super.init()
        m_pos = pos
        m_target = target
        m_viewMatrix = Matrix.MatrixMakeLookAt(m_pos, center: m_target, up: m_up)
        //m_up = up
    }
    init(matrix:Matrix) {
        m_viewMatrix = matrix
    }
    
    func viewMatrix()->Matrix{
        return m_viewMatrix!
    }
    
    func lookUpDown(forward:Float){
        var up = Matrix.cross(m_target - m_pos, b: m_up)
        m_viewMatrix!.rotate(forward,r: up)
        m_pos = m_pos + forward * (Matrix.normalize(up))
        
    }
    
    func lookLeftRight(forward:Float){
        m_viewMatrix!.rotate(forward, r: m_up)
    }
    
}