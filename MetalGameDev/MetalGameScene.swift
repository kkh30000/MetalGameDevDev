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
    //var m_mvpMatrix:[Float]! = nil
    var m_modelMatrix:Matrix! = nil
    //var m_viewMatrix:Matrix! = nil
    var m_uniform:MTLMVPUniform! = nil
    
    var m_cameraProjection:[Float]! = nil
    var m_lightProjection:[Float]! = nil
    var m_textureLoader:AAPLTexture2D! = nil
    
    var m_viewMatrix:Matrix! = nil
    var m_projectionMatrix:Matrix! = nil
    
    var m_camera:MTLCamera! = nil
    var m_temp:Matrix! = nil
    
    
    
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
        
        var mesh = MTLMesh(meshAsset: MeshAssets(filePath: "humanoid"), scene: self,vertexShader:"vertexShader",fragmentShader:"phong_fragment",drawType:MTLPrimitiveType.Triangle,depthType:MTLPixelFormat.Depth32Float)
        var mesh3 = MTLMesh(meshAsset: MeshAssets(filePath: "humanoid"), scene: self,vertexShader:"vertexShader",fragmentShader:"phong_fragment",drawType:MTLPrimitiveType.Triangle,depthType:MTLPixelFormat.Depth32Float)
        var mesh1 = MTLMesh(meshAsset: MeshAssets(vertexArray:  plat_vertex, indices: plat_indices), scene: self,vertexShader:"vertexShader_Static",fragmentShader:"phong_fragment_static_1",drawType:MTLPrimitiveType.Triangle,depthType:MTLPixelFormat.Depth32Float)
        var mesh2 = MTLMesh(meshAsset: MeshAssets(vertexArray:axis_vertex, indices: axis_indices), scene: self,vertexShader:"vertexShader_Static",fragmentShader:"phong_fragment_static",drawType:MTLPrimitiveType.Line,depthType:MTLPixelFormat.Depth32Float)
        var meshCK = MTLMesh(meshAsset: MeshAssets(filePath: "ck"), scene: self, vertexShader: "vertexShader_Static", fragmentShader: "phong_fragment_static", drawType:MTLPrimitiveType.Triangle, depthType: MTLPixelFormat.Depth32Float)
        var actorCK = MTLActor(mesh: meshCK, animationController: nil)
        var actor1 = MTLActor(mesh: mesh, animationController: MTLAnimationController(animationFileName: "animation", scene: self))
        var actor4 = MTLActor(mesh: mesh3, animationController: MTLAnimationController(animationFileName: "animation1", scene: self))
        var actor2 = MTLActor(mesh: mesh1, animationController: nil)
        var actor3 = MTLActor(mesh: mesh2, animationController: nil)
        //var actor1 = MTLActor(mesh: mesh1, animationController: nil)
        m_modelMatrix = Matrix()
        m_player = MTLGamePlayer(scene: self)
        m_uniform = MTLMVPUniform(model: Matrix(), view: MTLCamera(pos: [400,400,400], target: [0,0,0], up: [0,1,0]).viewMatrix(), projection: Matrix.MatrixMakeFrustum_oc(-1.01, right: 1.01, bottom: -1.01, top: 1.01, near: 1.01, far: -1.01), device: m_device!, player: m_player)
        m_player!.prepareActors([actorCK,actor1,actor4,actor2])
        /*m_textureLoader = AAPLPVRTexture(resourceName: "output1", ext:"pvr")
        if m_textureLoader.loadIntoTextureWithDevice(m_device!) == false{
            println("Load Texture Failed")
        }*/
        m_viewMatrix = MTLCamera(pos: [400,400,400], target: [0,0,0], up: [0,1,0]).viewMatrix()
        m_projectionMatrix = Matrix.MatrixMakeFrustum_oc(-1.01, right: 1.01, bottom: -1.01, top: 1.01, near: 1.01, far: -1.01)
        m_textureLoader = AAPLTexture2D(resourceName: "invoker_color", ext: "png")
        m_textureLoader.loadIntoTextureWithDevice(m_device!)
      
        
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
        colorAttachment?.loadAction = MTLLoadAction.Load
        colorAttachment?.clearColor = MTLClearColorMake(0.1, 0.65, 0.65, 1.0)
        
        
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
        //m_player.m_lights.m_raw[0...3] = [Float(sin(viewcontroller.m_gameTime*2)),Float(sin(viewcontroller.m_gameTime*1.4)),Float(sin(viewcontroller.m_gameTime*1.2)),1.0]
        m_modelMatrix.rotate(0.5, r: [0,1,0])
        m_uniform.setModelMatrix(m_modelMatrix.raw())
        m_uniform.updateDataToUniform(m_uniform.m_mvpMatrix, toUniform: m_uniform[m_player!.m_currentUniform!])
        m_player.m_actors![1].m_animationController!.play(viewcontroller.m_gameTime, currentBuffer: m_player.m_currentUniform!)
        m_player.m_actors![2].m_animationController!.play(viewcontroller.m_gameTime * 0.8, currentBuffer: m_player.m_currentUniform!)
        
    }
    
    func pan(viewController: MTLGameViewController, rotateX: Float, rotateY: Float) {
        /*m_modelMatrix.rotate(rotateX/100, r: [0,0,1])
        println("X:\(rotateX)")
        println("Y:\(rotateY)")*/
        //println("Paning ....:\n\(viewController.m_currentPosition.x),\(viewController.m_currentPosition.y)")
        let pos :[Float] = [2 * Float(viewController.m_currentPosition.x/self.frame.size.width) - 1.0,0.0,1 - Float(2 * viewController.m_currentPosition.y/self.frame.size.height),1.0]
        
        
        let posInWorld = m_viewMatrix.inverse()! * m_projectionMatrix.inverse()! * pos
        //println("\(pos[0]),\(pos[1]),\(pos[2])")
        println("Pos: \(posInWorld[0]/posInWorld[3]),\(posInWorld[1]/posInWorld[3]),\(posInWorld[2]/posInWorld[3])")
        
        
        
        
    }
    
    func tap(viewController: MTLGameViewController) {
        let pos :[Float] = [2 * Float(viewController.m_currentPosition.x/self.frame.size.width * UIScreen.mainScreen().scale) - 1.0,0.0,1 - Float(2 * viewController.m_currentPosition.y/self.frame.size.height * UIScreen.mainScreen().scale),1.0]
        
        let pos1 : [Float] = [Float(viewController.m_currentPosition.x),0.0,Float(viewController.m_currentPosition.y),1.0]
        
        
        let posInWorld = m_viewMatrix.inverse()! * m_projectionMatrix.inverse()! * pos1
        println("\(pos1[0]),\(pos1[1]),\(pos1[2])")
        println("Pos: \(posInWorld[0]/posInWorld[3]),\(posInWorld[1]/posInWorld[3]),\(posInWorld[2]/posInWorld[3])")
    }
    
    func pause(viewController: MTLGameViewController, willPause: Bool) {
        if willPause == true{
            println("pause")
        }else{
            println("continue")
        }
    }
    
    
}
