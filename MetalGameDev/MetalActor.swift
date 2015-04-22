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
    
    init(mesh:MTLMesh,animationController:MTLAnimationController?) {
        super.init()
        m_mesh = mesh
        m_animationController = animationController
        
    }
}