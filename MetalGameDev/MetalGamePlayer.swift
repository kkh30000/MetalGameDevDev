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
    var m_aaRenderPassDsc:MTLRenderPassDescriptor! = nil
    //var m_aaPerspective:[Float]! = nil
    
    var m_renderToScreenPass:MTLRenderPassDescriptor! = nil
    var m_renderToScreenPiplelineState:MTLRenderPipelineState! = nil
    var m_renderToScreenVertex:[Float]! = [
         1.0, 1.0, 1, 1.0,0.0,
        -1.0, 1.0, 1, 0.0,0.0,
        -1.0,-1.0, 1, 0.0,1.0,
         1.0, 1.0, 1, 1.0,0.0,
        -1.0,-1.0, 1, 0.0,1.0,
         1.0,-1.0, 1, 1.0,1.0,
    ]
    var m_renderToVertexBuffer:MTLBuffer! = nil
    var m_renderToScreenUniform:MTLMVPUniform! = nil
    
    //var m_lightProjcetion:[Float]! = nil
    var m_lightUniform:MTLMVPUniform! = nil
    var m_lights:MTLLights! = nil
    init(scene:MTLGameScene) {
        super.init()
        m_scene = scene
        
        m_deptPixelFormat = MTLPixelFormat.Depth32Float
        m_stencilPixelFormat = MTLPixelFormat.Stencil8
        
        scene.m_sampleCount = 1
        scene.m_depthPixelFormat = m_deptPixelFormat
        scene.m_stencilPixelFormat = m_stencilPixelFormat
        var depthDecs = MTLDepthStencilDescriptor()
        //var stencilState = MTLStencilDescriptor()
        
        depthDecs.depthWriteEnabled = true
        depthDecs.depthCompareFunction = MTLCompareFunction.LessEqual
        m_shadowDepthStencilState = m_scene!.m_device!.newDepthStencilStateWithDescriptor(depthDecs)
        
        //Pass2：disable z-write, enable z-test/stencil-write 。渲染 shadow volume, 对于它的 back face ，如果 z-test 的结果是fail, stencil 值加1，如果 z-test 的结果是 pass，stencil 值不变。对于 front face，如果z-test 的结果是 fail，stencil 值减1 ，如果结果是 pass，stencil 值不变。        
        //depthDecs.depthWriteEnabled = true
        m_depthState = scene.m_device!.newDepthStencilStateWithDescriptor(depthDecs)
        m_semaphore = dispatch_semaphore_create(3)
        
        
        m_currentUniform = 0
        
        //初始化light pespetive
        m_lightUniform = MTLMVPUniform(model: Matrix(), view: MTLCamera(pos: [1,800,1], target: [0,0,0], up: [0,1,0]).viewMatrix(), projection:Matrix.MatrixMakePerpective_fov(90, aspect: Float(m_scene!.frame.width)/Float(m_scene!.frame.height), near: 0.1, far: -1000), device: m_scene!.m_device!, player: self)
        var modelView = Matrix()
        modelView.scale(Float(m_scene!.frame.size.width) / Float(m_scene!.frame.size.height), y: 1, z: 1)
        m_renderToScreenUniform = MTLMVPUniform(model: Matrix(), view: MTLCamera(pos: [0,0,0], target: [0,0,1], up: [0,1,0]).viewMatrix(), projection: Matrix.MatrixMakePerpective_fov(90, aspect: Float(m_scene!.frame.size.width)/Float(m_scene!.frame.size.width), near: 0.1, far: 1.00), device: m_scene!.m_device!, player: self)
        var light0 = MTLSpotLight(pos: [1,1000,1], attenuation: 0.0, color: [1.0,1.0,1.0,1.0])
        
        m_lights = MTLLights(lights: [light0], device: m_scene!.m_device!)
        
    }
    func prepareActors(actors:[MTLActor]){
        m_actors = actors
        
        prepareShadowMapPass()
        prepareRenderToScreenPass()
        preparePostAnitAliasingPass()
        
        var renderPipeLineStateDesc = MTLRenderPipelineDescriptor()
        //First Pass :Shadow Mapping
        renderPipeLineStateDesc.label = "Shadow Map"
        renderPipeLineStateDesc.colorAttachments[0] = nil
        renderPipeLineStateDesc.vertexFunction! = m_scene!.m_device!.newDefaultLibrary()!.newFunctionWithName("shadow_mapping_vertex_shader")!
        renderPipeLineStateDesc.fragmentFunction = nil
        renderPipeLineStateDesc.depthAttachmentPixelFormat = m_shadowMap!.pixelFormat
        renderPipeLineStateDesc.stencilAttachmentPixelFormat = MTLPixelFormat.Invalid
        m_shadowRenderPipelineState = m_scene!.m_device!.newRenderPipelineStateWithDescriptor(renderPipeLineStateDesc, error: nil)
        renderPipeLineStateDesc.label = "Shadow Map Static"
        renderPipeLineStateDesc.colorAttachments[0] = nil
                renderPipeLineStateDesc.fragmentFunction = nil
        renderPipeLineStateDesc.depthAttachmentPixelFormat = m_shadowMap!.pixelFormat
        renderPipeLineStateDesc.stencilAttachmentPixelFormat = MTLPixelFormat.Invalid
        renderPipeLineStateDesc.vertexFunction! = m_scene!.m_device!.newDefaultLibrary()!.newFunctionWithName("shadow_mapping_vertex_shader_static")!

        m_shadowRenderPipelineStateStatic = m_scene!.m_device!.newRenderPipelineStateWithDescriptor(renderPipeLineStateDesc, error: nil)
        
        //Second Pass:Render Into Texture
        renderPipeLineStateDesc.label = "Sencond Pass: Render Into Texture"
        for actor in m_actors!{
            actor.m_mesh.prepareRenderPipeLineStateWithShaderName(m_scene!.m_device!, vertexShader: actor.m_mesh.m_vertexShader!, fragmentShader: actor.m_mesh.m_fragmentShader!, depthPixelFormat: m_deptPixelFormat!,renderPipeLineDescriptor: renderPipeLineStateDesc)
        }
        
        //Final Pass: Render Into Screen
        renderPipeLineStateDesc.label = "Final Pass"
        renderPipeLineStateDesc.vertexFunction! = m_scene!.m_device!.newDefaultLibrary()!.newFunctionWithName("render_to_screen_vertex")!
        renderPipeLineStateDesc.fragmentFunction! = m_scene!.m_device!.newDefaultLibrary()!.newFunctionWithName("render_to_screen_fragment")!
        renderPipeLineStateDesc.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        renderPipeLineStateDesc.stencilAttachmentPixelFormat = MTLPixelFormat.Invalid
        renderPipeLineStateDesc.depthAttachmentPixelFormat = MTLPixelFormat.Invalid
        m_renderToScreenPiplelineState = m_scene!.m_device!.newRenderPipelineStateWithDescriptor(renderPipeLineStateDesc, error: nil)
    }
    func prepareShadowMapPass(){
        
        
        let shadowSize = UIScreen.mainScreen().applicationFrame
        var shadowTextureDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.Depth32Float, width:Int(1024), height:Int(1024), mipmapped: false)
        m_shadowMap = m_scene!.m_device!.newTextureWithDescriptor(shadowTextureDesc)
        m_shadowRenderPassDesc = MTLRenderPassDescriptor()
        m_shadowRenderPassDesc.depthAttachment.texture = m_shadowMap!
        m_shadowRenderPassDesc.depthAttachment.loadAction = MTLLoadAction.Clear
        m_shadowRenderPassDesc.depthAttachment.storeAction = MTLStoreAction.Store
        m_shadowRenderPassDesc.depthAttachment.clearDepth = 1.0
        
    
    }
    func renderShadowMap(commandBuffer:MTLCommandBuffer){
        
        m_lightUniform.update()
        //m_lightUniform.updateDataToUniform(m_lightProjcetion, toUniform: m_lightUniform[m_currentUniform!])
        var paraCommanderEncoder = commandBuffer.parallelRenderCommandEncoderWithDescriptor(m_shadowRenderPassDesc)
        //paraCommanderEncoder!.pushDebugGroup("Shadow Mapping")
        var paraCommandEncoders :[MTLRenderCommandEncoder] = []
        
        for var i = 0 ; i < m_actors!.count ; ++i{
            paraCommandEncoders.append(paraCommanderEncoder!.renderCommandEncoder())
        }
        
        
        for var i = 0; i < m_actors!.count ; ++i{
            if m_actors![i].m_animationController != nil{
                paraCommandEncoders[i].setRenderPipelineState(m_shadowRenderPipelineState)
                //paraCommandEncoders[i].setCullMode(MTLCullMode.Back)
            }else{
                paraCommandEncoders[i].setRenderPipelineState(m_shadowRenderPipelineStateStatic)
                paraCommandEncoders[i].setCullMode(MTLCullMode.Back)
            }
            paraCommandEncoders[i].setDepthStencilState(m_shadowDepthStencilState!)
            
            paraCommandEncoders[i].setDepthBias(0.1, slopeScale: 1.0, clamp: 0.1)
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
        paraCommanderEncoder!.endEncoding()
    }
    func preparePostAnitAliasingPass(){
        var aaTextureDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.BGRA8Unorm, width: Int(self.m_scene!.frame.size.width), height:Int(m_scene!.frame.size.height), mipmapped: false)
        m_aaTexture = m_scene!.m_device!.newTextureWithDescriptor(aaTextureDesc)
        m_aaRenderPassDsc = MTLRenderPassDescriptor()
        m_aaRenderPassDsc.colorAttachments[0].texture = m_aaTexture
        m_aaRenderPassDsc.colorAttachments[0].loadAction = MTLLoadAction.Clear
        m_aaRenderPassDsc.colorAttachments[0].storeAction = MTLStoreAction.Store
        m_aaRenderPassDsc.colorAttachments[0].clearColor = MTLClearColorMake(0.65, 0.3, 0.25, 1.0)
        let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
            m_stencilPixelFormat!,
            width: m_aaTexture.width,
            height: m_aaTexture.height,
            mipmapped: false)
        
        desc.textureType = MTLTextureType.Type2D
        var stencilTex = m_scene!.m_device!.newTextureWithDescriptor(desc)
        let stencilAttachment:MTLRenderPassStencilAttachmentDescriptor
        = m_aaRenderPassDsc!.stencilAttachment
        stencilAttachment.texture = stencilTex
        stencilAttachment.loadAction = MTLLoadAction.DontCare
        stencilAttachment.storeAction = MTLStoreAction.DontCare
        stencilAttachment.clearStencil = 0
        
        
        let descDepth = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
            MTLPixelFormat.Depth32Float,
            width: m_aaTexture.width,
            height: m_aaTexture.height,
            mipmapped: false)
        
        descDepth.textureType = MTLTextureType.Type2D
        1
        var depthTex = m_scene!.m_device!.newTextureWithDescriptor(descDepth)
        
        let depthAttachment:MTLRenderPassDepthAttachmentDescriptor
        = m_aaRenderPassDsc!.depthAttachment
        depthAttachment.texture = depthTex
        depthAttachment.loadAction = MTLLoadAction.DontCare
        depthAttachment.storeAction = MTLStoreAction.DontCare
        depthAttachment.clearDepth = 1.0
        
        

    }
    func renderToTexture(commandBuffer:MTLCommandBuffer){
         //m_renderToScreenUniform.update()
        m_lights.updateLight()
        var paraCommanderEncoder = commandBuffer.parallelRenderCommandEncoderWithDescriptor(m_aaRenderPassDsc)
        var paraCommandEncoders :[MTLRenderCommandEncoder] = []
        
        for var i = 0 ; i < m_actors!.count ; ++i{
            paraCommandEncoders.append(paraCommanderEncoder!.renderCommandEncoder())
        }
        for var i = 0; i < m_actors!.count ; ++i{
            //paraCommandEncoders[i].setCullMode(MTLCullMode.)
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
            paraCommandEncoders[i].setFragmentTexture(m_scene!.m_textureLoader.texture, atIndex: 1)
            paraCommandEncoders[i].setVertexBuffer(m_lights.m_uniformBuffer.m_uniform, offset: 0, atIndex: 4)
            //paraCommandEncoders[i].setFragmentBuffer(, offset: <#Int#>, atIndex: <#Int#>)
            paraCommandEncoders[i].setRenderPipelineState(m_actors![i].m_mesh.m_renderPipeLineState!)
            if m_actors![i].m_mesh.m_meshAssets.m_vertexIndices == nil{
                paraCommandEncoders[i].drawPrimitives(m_actors![i].m_mesh.m_meshType!, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            }else{
                paraCommandEncoders[i].drawIndexedPrimitives(m_actors![i].m_mesh.m_meshType!, indexCount: m_actors![i].m_mesh.m_meshAssets!.m_vertexIndices!.count, indexType: MTLIndexType.UInt16, indexBuffer: m_actors![i].m_mesh.m_indexBuffer!, indexBufferOffset: 0, instanceCount: 1)
            }
            paraCommandEncoders[i].endEncoding()
        }
        
        paraCommanderEncoder!.endEncoding()
        // m_scene!.m_uniform!.updateDataToUniform(m_scene!.m_mvpMatrix, toUniform: m_scene!.m_uniform[m_currentUniform!])
    }
    func prepareRenderToScreenPass(){
        m_renderToScreenPass = m_scene!.renderPassDescriptor()
        m_renderToVertexBuffer = m_scene!.m_device!.newBufferWithBytes(m_renderToScreenVertex, length: sizeofValue(m_renderToScreenVertex[0]) * m_renderToScreenVertex.count, options: nil)
        
    }
    func renderToScreen(commandBuffer:MTLCommandBuffer){
        m_renderToScreenUniform!.update()
        m_scene!.m_uniform.update()
        var enCoder = commandBuffer.renderCommandEncoderWithDescriptor(m_scene!.renderPassDescriptor())
        enCoder!.setFragmentTexture(m_aaTexture, atIndex: 0)
        enCoder!.setVertexBuffer(m_renderToVertexBuffer, offset: 0, atIndex: 0)
        enCoder!.setVertexBuffer(m_renderToScreenUniform[m_currentUniform!], offset: 0, atIndex: 1)
        enCoder!.setRenderPipelineState(m_renderToScreenPiplelineState)
        enCoder!.drawPrimitives(MTLPrimitiveType.Triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)
        enCoder!.endEncoding()
        
    }
    
   
    
    func render(scene:MTLGameScene){
        
        dispatch_semaphore_wait(m_semaphore!, DISPATCH_TIME_FOREVER)
        
        var commandBuffer = self.m_scene!.m_commandQueue!.commandBuffer()
        //First Pass Shadow Mapping
        renderShadowMap(commandBuffer)
        //Second Pass Render To Texture
        renderToTexture(commandBuffer)
        //Final Pass Render To Screen
        renderToScreen(commandBuffer)
    
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