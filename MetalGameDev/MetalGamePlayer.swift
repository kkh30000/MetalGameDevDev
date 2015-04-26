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
    
    var m_shadowMap:MTLTexture?
    var m_shadowRenderPassDesc:MTLRenderPassDescriptor! = nil
    var m_shadowRenderPipelineState:MTLRenderPipelineState! = nil
    var m_shadowRenderPipelineStateStatic:MTLRenderPipelineState! = nil
    var m_shadowDepthStencilState:MTLDepthStencilState! = nil
    
    var m_aaTexture:MTLTexture! = nil
    
    var m_lightProjcetion:[Float]! = nil
    var m_lightUniform:MTLUniform! = nil
    init(scene:MTLGameScene) {
        super.init()
        m_scene = scene
        
        m_deptPixelFormat = MTLPixelFormat.Depth32Float
        m_stencilPixelFormat = MTLPixelFormat.Stencil8
        
        scene.m_sampleCount = 1
        scene.m_depthPixelFormat = m_deptPixelFormat
        scene.m_stencilPixelFormat = m_stencilPixelFormat
        var depthDecs = MTLDepthStencilDescriptor()
        var stencilState = MTLStencilDescriptor()
        
        depthDecs.depthWriteEnabled = true
        depthDecs.depthCompareFunction = MTLCompareFunction.LessEqual
        m_shadowDepthStencilState = m_scene!.m_device!.newDepthStencilStateWithDescriptor(depthDecs)
        
        depthDecs.depthWriteEnabled = true
        stencilState.stencilCompareFunction = MTLCompareFunction.Always
        stencilState.stencilFailureOperation = MTLStencilOperation.Keep
        stencilState.depthFailureOperation  = MTLStencilOperation.Keep
        stencilState.depthStencilPassOperation = MTLStencilOperation.Replace
        stencilState.readMask = 0xFF;
        stencilState.writeMask = 0xFF;
        depthDecs.depthCompareFunction = MTLCompareFunction.LessEqual;
        depthDecs.frontFaceStencil = stencilState;
        depthDecs.backFaceStencil = stencilState;
        m_depthState = scene.m_device!.newDepthStencilStateWithDescriptor(depthDecs)
        m_semaphore = dispatch_semaphore_create(3)
        
        
        m_currentUniform = 0
        m_lightProjcetion = [Float](count: 48, repeatedValue: 0.0)
        var modelMatrix = Matrix()
        //m_modelMatrix.translate(0, y: -300, z: 0)
        m_lightProjcetion[0...15] = modelMatrix.raw()[0...15]
        var light = MTLCamera(pos: [200,300,-200], target: [0,0,0], up: [0,1,0])
        m_lightProjcetion[16...31] = light.viewMatrix().raw()[0...15]
        //light.viewMatrix().translate(0.5, y: 0.5, z: 0.0)
        //light.viewMatrix().scale(0.5, y: -0.5, z: 1.0)
        //light.viewMatrix().scale(0.001, y: 0.001, z: 0.001)
        m_lightProjcetion[32...47] = Matrix.MatrixMakeFrustum_oc(-1.01, right: 1.01, bottom: -1.01 , top: +1.01 , near: 1.01, far:-2000.01).raw()[0...15]
        m_lightUniform = MTLUniform(size: sizeofValue(m_lightProjcetion[0]) * m_lightProjcetion.count, device: m_scene!.m_device!)
        
        
        for var i = 0 ; i < 3 ; ++i{
            m_lightUniform.updateDataToUniform(m_lightProjcetion , toUniform: m_lightUniform[i])
        }

    
    }
    
    func prepareShadowMap(){
        
        

        var shadowTextureDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.Depth32Float, width: 1024, height: 1024, mipmapped: false)
        m_shadowMap = m_scene!.m_device!.newTextureWithDescriptor(shadowTextureDesc)
        m_shadowRenderPassDesc = MTLRenderPassDescriptor()
        m_shadowRenderPassDesc.depthAttachment.texture = m_shadowMap!
        m_shadowRenderPassDesc.depthAttachment.loadAction = MTLLoadAction.Clear
        m_shadowRenderPassDesc.depthAttachment.storeAction = MTLStoreAction.Store
        m_shadowRenderPassDesc.depthAttachment.clearDepth = 1.0
        
    
    }
    
    func preparePostAnitAliasingPass(){
        var aaTextureDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.BGRA8Unorm, width: Int(self.m_scene!.frame.size.width), height:Int(m_scene!.frame.size.height), mipmapped: false)
        m_aaTexture = m_scene!.m_device!.newTextureWithDescriptor(aaTextureDesc)
        var aaRenderPass = m_scene!.renderPassDescriptor()
        aaRenderPass.colorAttachments[0].texture = m_aaTexture
        
    }
    func renderShadowMap(commandBuffer:MTLCommandBuffer){
        
       
        //m_scene!.m_uniform.updateDataToUniform(m_lightProjcetion, toUniform: m_lightUniform[m_currentUniform!])
        
        var paraCommanderEncoder = commandBuffer.parallelRenderCommandEncoderWithDescriptor(m_shadowRenderPassDesc)
        paraCommanderEncoder!.pushDebugGroup("Shadow Mapping")
        var paraCommandEncoders :[MTLRenderCommandEncoder] = []
        
        for var i = 0 ; i < m_actors!.count ; ++i{
            paraCommandEncoders.append(paraCommanderEncoder!.renderCommandEncoder())
        }
        
        
        for var i = 0; i < m_actors!.count ; ++i{
            if m_actors![i].m_animationController != nil{
                paraCommandEncoders[i].setRenderPipelineState(m_shadowRenderPipelineState)
            }else{
                paraCommandEncoders[i].setRenderPipelineState(m_shadowRenderPipelineStateStatic)
            }
            paraCommandEncoders[i].setDepthStencilState(m_shadowDepthStencilState!)
            paraCommandEncoders[i].setCullMode(MTLCullMode.Back)
            paraCommandEncoders[i].setDepthBias(0.01, slopeScale: 1.0, clamp: 0.01)
            paraCommandEncoders[i].setVertexBuffer(m_lightUniform[m_currentUniform!], offset: 0, atIndex: 1)
            if m_actors![i].m_animationController != nil{
                paraCommandEncoders[i].setVertexBuffer(m_actors![i].m_animationController!.m_uniformBuffer[m_currentUniform!], offset: 0, atIndex: 2)
            }
            paraCommandEncoders[i].setVertexBuffer(m_actors![i].m_mesh.m_vertexBuffer, offset: 0, atIndex: 0)
            
            if m_actors![i].m_mesh.m_meshAssets.m_vertexIndices == nil{
                paraCommandEncoders[i].drawPrimitives(m_actors![i].m_mesh.m_meshType!, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            }else{
                paraCommandEncoders[i].drawIndexedPrimitives(m_actors![i].m_mesh.m_meshType!, indexCount: m_actors![i].m_mesh.m_meshAssets!.m_vertexIndices!.count, indexType: MTLIndexType.UInt16, indexBuffer: m_actors![i].m_mesh.m_indexBuffer!, indexBufferOffset: 0, instanceCount: 1)
            }
            paraCommandEncoders[i].endEncoding()
        }
        paraCommanderEncoder!.popDebugGroup()
        paraCommanderEncoder!.endEncoding()
    }
    
    
    
    func prepareActors(actors:[MTLActor]){
        m_actors = actors
        
        prepareShadowMap()
        var renderPipeLineStateDesc = MTLRenderPipelineDescriptor()
        renderPipeLineStateDesc.label = "Shadow Map"
        renderPipeLineStateDesc.colorAttachments[0] = nil
        renderPipeLineStateDesc.vertexFunction! = m_scene!.m_device!.newDefaultLibrary()!.newFunctionWithName("shadow_mapping_vertex_shader")!
        renderPipeLineStateDesc.fragmentFunction = nil
        renderPipeLineStateDesc.depthAttachmentPixelFormat = m_shadowMap!.pixelFormat
        m_shadowRenderPipelineState = m_scene!.m_device!.newRenderPipelineStateWithDescriptor(renderPipeLineStateDesc, error: nil)
        renderPipeLineStateDesc.vertexFunction! = m_scene!.m_device!.newDefaultLibrary()!.newFunctionWithName("shadow_mapping_vertex_shader_static")!
        m_shadowRenderPipelineStateStatic = m_scene!.m_device!.newRenderPipelineStateWithDescriptor(renderPipeLineStateDesc, error: nil)
        renderPipeLineStateDesc.label = "Second Pass"
        for actor in m_actors!{
            actor.m_mesh.prepareRenderPipeLineStateWithShaderName(m_scene!.m_device!, vertexShader: actor.m_mesh.m_vertexShader!, fragmentShader: actor.m_mesh.m_fragmentShader!, depthPixelFormat: m_deptPixelFormat!,renderPipeLineDescriptor: renderPipeLineStateDesc)
        }
    }
    
    func renderToScreen(commandBuffer:MTLCommandBuffer){
        m_scene!.m_uniform!.updateDataToUniform(m_scene!.m_mvpMatrix, toUniform: m_scene!.m_uniform[m_currentUniform!])
        
        var paraCommanderEncoder = commandBuffer.parallelRenderCommandEncoderWithDescriptor(self.m_scene!.renderPassDescriptor())
        var paraCommandEncoders :[MTLRenderCommandEncoder] = []
        
        for var i = 0 ; i < m_actors!.count ; ++i{
            paraCommandEncoders.append(paraCommanderEncoder!.renderCommandEncoder())
        }
        
        
        
        for var i = 0; i < m_actors!.count ; ++i{
            paraCommandEncoders[i].setCullMode(MTLCullMode.Front)
            if m_actors![i].m_mesh.m_depthType != MTLPixelFormat.Invalid{
                paraCommandEncoders[i].setDepthStencilState(m_depthState!)
            }
            paraCommandEncoders[i].setVertexBuffer(m_scene!.m_uniform![m_currentUniform!], offset: 0, atIndex: 1)
            if m_actors![i].m_animationController != nil{
                paraCommandEncoders[i].setVertexBuffer(m_actors![i].m_animationController!.m_uniformBuffer[m_currentUniform!], offset: 0, atIndex: 2)
            }
            paraCommandEncoders[i].setVertexBuffer(m_lightUniform[m_currentUniform!], offset: 0, atIndex: 3)
            paraCommandEncoders[i].setVertexBuffer(m_actors![i].m_mesh.m_vertexBuffer, offset: 0, atIndex: 0)
            paraCommandEncoders[i].setFragmentTexture(m_shadowMap!, atIndex: 0)
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
        }    }
    
    func render(scene:MTLGameScene){
        
        dispatch_semaphore_wait(m_semaphore!, DISPATCH_TIME_FOREVER)
        
        var commandBuffer = self.m_scene!.m_commandQueue!.commandBuffer()
        //First Pass Shadow Mapping
        renderShadowMap(commandBuffer)
        //Second Pass FXAA
        
        //Final Pass Render To Screen
        renderToScreen(commandBuffer)
    
        
        commandBuffer.presentDrawable(scene.m_drawable!)
        commandBuffer.commit()
        m_currentUniform = (m_currentUniform! + 1) % 3
    }
}