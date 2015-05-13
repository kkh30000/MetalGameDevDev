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
    
    var m_viewMatrix:Matrix! = Matrix()
    var m_projectionMatrix:Matrix! = Matrix()
    
    var m_camera:MTLCamera! = nil
    var m_temp:Matrix! = nil
    
    var m_viewWidth :Float! = nil
    var m_viewHeight:Float! = nil

    
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
        
        
        var panGesture = UIPanGestureRecognizer(target: self, action: "pan:")
        panGesture.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGesture)
        
        m_viewWidth = Float(self.frame.width)
        m_viewHeight = Float(self.frame.height) * 0.9
        //println(self.frame.width)
        //println(self.frame.height)
        
        m_device = MTLCreateSystemDefaultDevice()
        m_commandQueue = m_device!.newCommandQueue()
        m_metalLayer = self.layer as? CAMetalLayer
       
        m_metalLayer!.pixelFormat = MTLPixelFormat.BGRA8Unorm
        m_metalLayer!.device = m_device

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
        m_uniform = MTLMVPUniform(model: Matrix(), view: MTLCamera(pos: [400,400,400], target: [0,0,0], up: [0,1,0]).viewMatrix(), projection: Matrix.MatrixMakeFrustum_oc(-1.01, right: 1.01, bottom: -1.01, top: 1.01, near: 1.01, far: 1000.01), device: m_device!, player: m_player)
        m_player!.prepareActors([actorCK,actor1,actor4,actor2,actor3])
        //var sucess : UnsafeMutablePointer<Bool> = UnsafeMutablePointer()
        m_viewMatrix = Matrix.MatrixMakeLookAt([400,400,400], center: [0,0,0], up: [0,1,0])
        m_viewMatrix.inverse()
        //m_viewMatrix.GLKToSwfit(GLKMatrix4MakeLookAt(400, 400, 400, 0, 0, 0, 0, 1, 0))
        
        m_projectionMatrix = Matrix.MatrixMakeFrustum_oc(-1, right: 1, bottom: -1, top: 1, near: 1, far: 1000)
        m_projectionMatrix.inverse()
        
        //println(m_projectionMatrix.raw())
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
        //m_modelMatrix.rotate(0.5, r: [0,1,0])
        //m_uniform.setModelMatrix(m_modelMatrix.raw())
        //m_uniform.updateDataToUniform(m_uniform.m_mvpMatrix, toUniform: m_uniform[m_player!.m_currentUniform!])
        m_player.m_actors![1].m_animationController!.play(viewcontroller.m_gameTime, currentBuffer: m_player.m_currentUniform!)
        m_player.m_actors![2].m_animationController!.play(viewcontroller.m_gameTime * 0.8, currentBuffer: m_player.m_currentUniform!)
        
    }
    
    
    func normalizeTouchPoint(x:CGFloat,y:CGFloat)->(Float,Float){
        var x1:Float = Float(x) / m_viewHeight
        var y1:Float = Float(y) / m_viewWidth
        
        x1 = 2 * (x1 - 0.5)
        y1 = 2 * (0.5 - y1)
        //println("\(x1),\(y1)")
        return (x1,y1)
    }
    
    func pan(panGesture:UIPanGestureRecognizer){
        let pos = panGesture.locationInView(self)
        unproject(normalizeTouchPoint(pos.x, y: pos.y))
    }
    
    
    func unproject(pos:(Float,Float)){
        let posNear = [pos.0,pos.1,1,1]
        //let posFar = [pos.0,pos.1,-1,1]
        let posViewNear = m_projectionMatrix * posNear
        let posWorldNear = m_viewMatrix * posViewNear
        //let posViewFar = m_projectionMatrix * posFar
        //let posWorldFar = m_viewMatrix * posViewFar
        //let end:[Float] = [posWorld[0],posWorld[1],posWorld[2]]
        var dir:[Float] = [posWorldNear[0] - 400,posWorldNear[1] - 400,posWorldNear[2] - 400]
        dir =  Matrix.normalize(dir)
        
        //let t = -400 / dir[1] * dir + [400,400,400]
        //println(t)
        println(dir)
        ///println(-400.0 / dir[1])
        //println("Position : \(posWorld[0]),\(posWorld[1]),\(posWorld[2]),\(posWorld[3]),Coming From: \(pos.0),\(pos.1)")
        
    }
    
    func pause(viewController: MTLGameViewController, willPause: Bool) {
        if willPause == true{
            println("pause")
        }else{
            println("continue")
        }
    }
}
