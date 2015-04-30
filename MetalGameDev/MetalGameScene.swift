//
//  MTLGameScene.swift
//  GameMetal
//
//  Created by liuang on 15/3/28.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Metal
import UIKit

class MTLGameScene:UIView,MTLGameViewControllerDelegate{
    
    var m_metalLayer:CAMetalLayer?
    var m_device:MTLDevice?
    var m_commandQueue:MTLCommandQueue?
    
    var m_depthPixelFormat:MTLPixelFormat?
    var m_stencilPixelFormat:MTLPixelFormat?
    var m_sampleCount:Int?
    
    var m_depthTex:MTLTexture?
    var m_stencilTex:MTLTexture?
    var m_msaaTex:MTLTexture?
    
    var m_renderPassDesc:MTLRenderPassDescriptor?
    var m_drawable:CAMetalDrawable?
    
    var m_player:MTLGamePlayer! = nil
    var m_mvpMatrix:[Float]! = nil
    var m_modelMatrix:Matrix! = nil
    var m_viewMatrix:Matrix! = nil
    var m_uniform:MTLUniform! = nil
    
    var m_cameraProjection:[Float]! = nil
    var m_lightProjection:[Float]! = nil
    
    
    var m_camera:MTLCamera! = nil
    
    
    
    override class func layerClass()->AnyClass{
        return CAMetalLayer.self
    }
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initCommon()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initCommon()
    }
    
    func initCommon(){
        self.opaque = true
        self.backgroundColor = nil
        
        m_device = MTLCreateSystemDefaultDevice()
        m_commandQueue = m_device!.newCommandQueue()
        m_metalLayer = self.layer as? CAMetalLayer
        m_metalLayer!.pixelFormat = MTLPixelFormat.BGRA8Unorm
        m_metalLayer!.device = m_device
        //m_metalLayer!.drawsAsynchronously = true
        //m_metalLayer!.presentsWithTransaction = false
        
        var mesh = MTLMesh(meshAsset: MeshAssets(vertexArray:please_work2, indices: humandroid_indices), scene: self,vertexShader:"vertexShader",fragmentShader:"phong_fragment",drawType:MTLPrimitiveType.Triangle,depthType:MTLPixelFormat.Depth32Float)
        var mesh3 = MTLMesh(meshAsset: MeshAssets(vertexArray:please_work2, indices: humandroid_indices), scene: self,vertexShader:"vertexShader",fragmentShader:"phong_fragment",drawType:MTLPrimitiveType.Triangle,depthType:MTLPixelFormat.Depth32Float)
        var mesh1 = MTLMesh(meshAsset: MeshAssets(vertexArray:  plat_vertex, indices: plat_indices), scene: self,vertexShader:"vertexShader_Static",fragmentShader:"phong_fragment_static",drawType:MTLPrimitiveType.Triangle,depthType:MTLPixelFormat.Depth32Float)
        var mesh2 = MTLMesh(meshAsset: MeshAssets(vertexArray:axis_vertex, indices: axis_indices), scene: self,vertexShader:"vertexShader_Static",fragmentShader:"phong_fragment_static",drawType:MTLPrimitiveType.Line,depthType:MTLPixelFormat.Depth32Float)
        var meshCK = MTLMesh(meshAsset: MeshAssets(filePath: "ck"), scene: self, vertexShader: "vertexShader_Static", fragmentShader: "phong_fragment_static_1", drawType:MTLPrimitiveType.Triangle, depthType: MTLPixelFormat.Depth32Float)
        var actorCK = MTLActor(mesh: meshCK, animationController: nil)
        var actor1 = MTLActor(mesh: mesh, animationController: MTLAnimationController(animationFileName: "animation", scene: self))
        var actor4 = MTLActor(mesh: mesh3, animationController: MTLAnimationController(animationFileName: "animation1", scene: self))
        var actor2 = MTLActor(mesh: mesh1, animationController: nil)
        var actor3 = MTLActor(mesh: mesh2, animationController: nil)
        //var actor1 = MTLActor(mesh: mesh1, animationController: nil)
        
        m_mvpMatrix = [Float](count: 48, repeatedValue: 0.0)
        m_modelMatrix = Matrix()
        m_modelMatrix.translate(0, y: -50, z: 0)
        m_mvpMatrix[0...15] = m_modelMatrix.raw()[0...15]
        m_camera = MTLCamera(pos: [400,400,400], target: [0,0,0], up: [0,1,0])
        m_mvpMatrix[16...31] = m_camera.viewMatrix().raw()[0...15]
        m_mvpMatrix[32...47] = Matrix.MatrixMakeFrustum_oc(-1.01, right: 1.01, bottom: -1.01 , top: +1.01 , near: 1.01, far:-1.01).raw()[0...15]
        m_cameraProjection = m_mvpMatrix
        //m_animUniform = MTLUniform(size: sizeofValue(m_animArray[0]) * m_animArray.count , device: m_device!)
        m_uniform = MTLUniform(size: sizeofValue(m_mvpMatrix[0]) * m_mvpMatrix.count, device: m_device!)
        for var i = 0 ; i < 3 ; ++i{
            m_uniform.updateDataToUniform(m_mvpMatrix, toUniform: m_uniform[i])
        }
        /*for var i = 0 ; i < 3 ; ++i{
        m_animUniform.updateDataToUniform(m_animArray, toUniform: m_animUniform[i])
        }*/
        
        m_player = MTLGamePlayer(scene: self)
        m_player!.prepareActors([actor2,actor1,actor4])
        
    }
    func currentDrawable()->CAMetalDrawable{
        while m_drawable == nil{
            m_drawable = m_metalLayer!.nextDrawable()
        }
        return m_drawable!
    }
    func setRenderPassDescriptorWithTexture(texture:MTLTexture)->MTLRenderPassDescriptor{
        // create lazily
        if (m_renderPassDesc == nil)
        {
            m_renderPassDesc = MTLRenderPassDescriptor()
        }
        
        // create a color attachment every frame since we have to
        // recreate the texture every frame
        let colorAttachment:MTLRenderPassColorAttachmentDescriptor?
        = m_renderPassDesc!.colorAttachments[0]!
        colorAttachment?.texture = texture
        
        // make sure to clear every frame for best performance
        colorAttachment?.loadAction = MTLLoadAction.Clear
        colorAttachment?.clearColor = MTLClearColorMake(0.1, 0.65, 0.65, 1.0)
        
        // if sample count is greater than 1, render into using MSAA,
        // then resolve into our color texture
        /*if (m_sampleCount > 1)
        {
            var doUpdate:Bool = false
            if (m_msaaTex == nil)
            {
                doUpdate = true
            }
            else
            {
                doUpdate = (m_msaaTex!.width != texture.width ||
                    m_msaaTex!.height != texture.height ||
                    m_msaaTex!.sampleCount != m_sampleCount)
            }
            if (doUpdate)
            {
                let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
                    MTLPixelFormat.BGRA8Unorm,
                    width: texture.width,
                    height: texture.height,
                    mipmapped: false)
                
                desc.textureType = MTLTextureType.Type2DMultisample
                
                // sample count was specified to the view by the renderer.
                // this must match the sample count given to any pipeline
                // state using this render pass descriptor
                desc.sampleCount = m_sampleCount!
                
                m_msaaTex = m_device!.newTextureWithDescriptor(desc)
            }
            
            // When multisampling, perform rendering to _msaaTex, then resolve
            // to 'texture' at the end of the scene
            colorAttachment?.texture = m_msaaTex
            colorAttachment?.resolveTexture = texture
            
            // set store action to resolve in this case
            colorAttachment?.storeAction = MTLStoreAction.MultisampleResolve
        }
        else
        {
            // store only attachments that will be presented to the screen, as in this case
            colorAttachment?.storeAction = MTLStoreAction.Store
        }   // color0
        
        // Now create the depth and stencil attachments
        if (m_depthPixelFormat != MTLPixelFormat.Invalid)
        {
            var doUpdate:Bool = false
            if (m_depthTex == nil)
            {
                doUpdate = true
            }
            else
            {
                doUpdate = (m_depthTex!.width != texture.width ||
                    m_depthTex!.height != texture.height ||
                    m_depthTex!.sampleCount != m_sampleCount)
            }
            
            if (doUpdate)
            {
                // If we need a depth texture and don't have one,
                // or if the depth texture we have is the wrong size
                // Then allocate one of the proper size
                let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
                    m_depthPixelFormat!,
                    width: texture.width,
                    height: texture.height,
                    mipmapped: false)
                
                desc.textureType = (m_sampleCount > 1) ?
                    MTLTextureType.Type2DMultisample : MTLTextureType.Type2D
                
                desc.sampleCount = m_sampleCount!
                
                m_depthTex = m_device!.newTextureWithDescriptor(desc)
                
                let depthAttachment:MTLRenderPassDepthAttachmentDescriptor
                = m_renderPassDesc!.depthAttachment
                depthAttachment.texture = m_depthTex
                depthAttachment.loadAction = MTLLoadAction.DontCare
                depthAttachment.storeAction = MTLStoreAction.DontCare
                depthAttachment.clearDepth = 1.0
            }
        } // depth
        
        if (m_stencilPixelFormat != MTLPixelFormat.Invalid)
        {
            var doUpdate:Bool = false
            if (m_stencilTex == nil)
            {
                doUpdate = true
            }
            else
            {
                doUpdate = (m_stencilTex!.width != texture.width ||
                    m_stencilTex!.height != texture.height ||
                    m_stencilTex!.sampleCount != m_sampleCount)
            }
            
            if (m_stencilTex  == nil || doUpdate)
            {
                //  If we need a stencil texture and don't have one,
                //  or if the depth texture we have is the wrong size
                //  Then allocate one of the proper size
                let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
                    m_stencilPixelFormat!,
                    width: texture.width,
                    height: texture.height,
                    mipmapped: false)
                
                desc.textureType = (m_sampleCount > 1) ?
                    MTLTextureType.Type2DMultisample : MTLTextureType.Type2D
                
                desc.sampleCount = m_sampleCount!
                
                m_stencilTex = m_device!.newTextureWithDescriptor(desc)
                
                let stencilAttachment:MTLRenderPassStencilAttachmentDescriptor
                = m_renderPassDesc!.stencilAttachment
                
                stencilAttachment.texture = m_stencilTex
                stencilAttachment.loadAction = MTLLoadAction.Clear
                stencilAttachment.storeAction = MTLStoreAction.DontCare
                stencilAttachment.clearStencil = 0
            }
        }
        //stencil*/
        return m_renderPassDesc!
    }
    
    
    func releaseTexture(){
        m_depthTex = nil
        m_stencilTex = nil
        m_msaaTex = nil
    }
    
    
    
    func renderPassDescriptor()->MTLRenderPassDescriptor{
        let drawable = self.currentDrawable()
        setRenderPassDescriptorWithTexture(drawable.texture)
        return m_renderPassDesc!
    }
    
    
    
    func display(){
        autoreleasepool{
            self.m_player!.render(self)
        }
        self.m_drawable = nil
    }
    
    func updatePerFrame(viewcontroller: MTLGameViewController) {
        m_modelMatrix.rotate(0.5, r: [0,1,0])
        m_mvpMatrix[0...15] = m_modelMatrix.raw()[0...15]
        m_uniform.updateDataToUniform(m_mvpMatrix, toUniform: m_uniform[m_player!.m_currentUniform!])
        m_player.m_actors![1].m_animationController!.play(viewcontroller.m_gameTime, currentBuffer: m_player.m_currentUniform!)
        m_player.m_actors![2].m_animationController!.play(viewcontroller.m_gameTime * 0.8, currentBuffer: m_player.m_currentUniform!)
        
    }
    
    func rotate(viewController: MTLGameViewController, rotateX: Float, rotateY: Float) {
        m_modelMatrix.rotate(rotateX/100, r: [0,0,1])
        println("X:\(rotateX)")
        println("Y:\(rotateY)")
        
        m_player.m_aaPerspective[0...15] = m_modelMatrix.raw()[0...15]
        m_player.m_renderToScreenUniform.updateDataToUniform(m_player.m_aaPerspective, toUniform: m_player.m_renderToScreenUniform[m_player!.m_currentUniform!])
    }
    
    func pause(viewController: MTLGameViewController, willPause: Bool) {
        if willPause == true{
            println("pause")
        }else{
            println("continue")
        }
    }
    
    
}
