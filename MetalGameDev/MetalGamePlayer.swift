//
//  MTLGamePlayer.swift
//  GameMetal
//
//  Created by liuang on 15/3/29.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Metal

class MTLGamePlayer: NSObject{
    var m_scene:MTLGameScene?
    
    var m_actors:[MTLActor]?
    
    var m_renderPipeLineState:MTLRenderPipelineState?
    var m_depthState:MTLDepthStencilState?
    var m_queue:MTLCommandQueue?
    var m_deptPixelFormat:MTLPixelFormat?
    var m_stencilPixelFormat:MTLPixelFormat?
    
    var m_semaphore:dispatch_semaphore_t?
    var m_currentUniform:Int?
    init(scene:MTLGameScene) {
        super.init()
        m_scene = scene
        
        m_deptPixelFormat = MTLPixelFormat.Depth32Float
        m_stencilPixelFormat = MTLPixelFormat.Invalid
        
        scene.m_sampleCount = 1
        scene.m_depthPixelFormat = m_deptPixelFormat
        scene.m_stencilPixelFormat = m_stencilPixelFormat
        var depthDecs = MTLDepthStencilDescriptor()
        depthDecs.depthCompareFunction = MTLCompareFunction.Less
        depthDecs.depthWriteEnabled = true
        m_depthState = scene.m_device!.newDepthStencilStateWithDescriptor(depthDecs)
        m_semaphore = dispatch_semaphore_create(3)
        m_currentUniform = 0
    }
    
    func prepareActors(actors:[MTLActor]){
        m_actors = actors
        for actor in m_actors!{
            actor.m_mesh.prepareRenderPipeLineStateWithShaderName(m_scene!.m_device!, vertexShader: actor.m_mesh.m_vertexShader!, fragmentShader: actor.m_mesh.m_fragmentShader!, depthPixelFormat: m_deptPixelFormat!)
        }
    }
    
    func render(scene:MTLGameScene){
        
        dispatch_semaphore_wait(m_semaphore!, DISPATCH_TIME_FOREVER)
        scene.m_uniform!.updateDataToUniform(scene.m_mvpMatrix, toUniform: scene.m_uniform[m_currentUniform!])
        //scene.m_animUniform!.updateDataToUniform(scene.m_animArray, toUniform: scene.m_animUniform[m_currentUniform!])
        //scene.m_uniform!.updateDataToUniform(m_mvpMatrix, toUniform: m_uniform[(m_player!.m_currentUniform!)])
        var commandBuffer = self.m_scene!.m_commandQueue!.commandBuffer()
        var paraCommanderEncoder = commandBuffer.parallelRenderCommandEncoderWithDescriptor(self.m_scene!.renderPassDescriptor())
        var paraCommandEncoders :[MTLRenderCommandEncoder] = []
        
        for var i = 0 ; i < m_actors!.count ; ++i{
            paraCommandEncoders.append(paraCommanderEncoder!.renderCommandEncoder())
        }
        
        
        
        for var i = 0; i < m_actors!.count ; ++i{
            paraCommandEncoders[i].setCullMode(MTLCullMode.Back)
            if m_actors![i].m_mesh.m_depthType != MTLPixelFormat.Invalid{
                paraCommandEncoders[i].setDepthStencilState(m_depthState!)
            }
            paraCommandEncoders[i].setVertexBuffer(scene.m_uniform![m_currentUniform!], offset: 0, atIndex: 1)
            if m_actors![i].m_animationController != nil{
                paraCommandEncoders[i].setVertexBuffer(m_actors![i].m_animationController!.m_uniformBuffer[m_currentUniform!], offset: 0, atIndex: 2)
            }
            paraCommandEncoders[i].setVertexBuffer(m_actors![i].m_mesh.m_vertexBuffer, offset: 0, atIndex: 0)
            paraCommandEncoders[i].setRenderPipelineState(m_actors![i].m_mesh.m_renderPipeLineState!)
            if m_actors![i].m_mesh.m_meshAssets.m_vertexIndices == nil{
                paraCommandEncoders[i].drawPrimitives(m_actors![i].m_mesh.m_meshType!, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            }else{
                paraCommandEncoders[i].drawIndexedPrimitives(m_actors![i].m_mesh.m_meshType!, indexCount: m_actors![i].m_mesh.m_meshAssets!.m_vertexIndices!.count, indexType: MTLIndexType.UInt16, indexBuffer: m_actors![i].m_mesh.m_indexBuffer!, indexBufferOffset: 0, instanceCount: 1)
            }
            paraCommandEncoders[i].endEncoding()
        }
        
        paraCommanderEncoder!.endEncoding()
        commandBuffer.addCompletedHandler(){
            [weak self] commandBuffer in
            if let strongSelf = self
            {
                dispatch_semaphore_signal(strongSelf.m_semaphore!)
            }
        }
        commandBuffer.presentDrawable(scene.m_drawable!)
        commandBuffer.commit()
        m_currentUniform = (m_currentUniform! + 1) % 3
    }
}