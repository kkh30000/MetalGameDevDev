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
        //panGesture.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGesture)
        
    
        //m_viewHeight = 600
        println(UIScreen.mainScreen().applicationFrame)
        m_viewHeight = Float(UIScreen.mainScreen().applicationFrame.size.height)
        m_viewWidth = Float(UIScreen.mainScreen().applicationFrame.size.width)
        //println(self.frame.width)
        //println(self.frame.height)
        
        m_device = MTLCreateSystemDefaultDevice()
        m_commandQueue = m_device!.newCommandQueue()
        m_metalLayer = self.layer as? CAMetalLayer
       
        m_metalLayer!.pixelFormat = MTLPixelFormat.BGRA8Unorm
        m_metalLayer!.device = m_device

        var mesh = MTLMesh(meshAsset: MeshAssets(filePath: "humanoid"), scene: self,vertexShader:"vertexShader",fragmentShader:"phong_fragment",drawType:MTLPrimitiveType.Triangle,depthType:MTLPixelFormat.Depth32Float,blendingEnable: false)
        var mesh3 = MTLMesh(meshAsset: MeshAssets(filePath: "humanoid"), scene: self,vertexShader:"vertexShader",fragmentShader:"phong_fragment",drawType:MTLPrimitiveType.Triangle,depthType:MTLPixelFormat.Depth32Float,blendingEnable: false)
        var mesh1 = MTLMesh(meshAsset: MeshAssets(vertexArray:  plat_vertex, indices: plat_indices), scene: self,vertexShader:"vertexShader_Static_normal",fragmentShader:"phong_fragment_static_normal",drawType:MTLPrimitiveType.Triangle,depthType:MTLPixelFormat.Depth32Float,blendingEnable: false)
        var mesh2 = MTLMesh(meshAsset: MeshAssets(vertexArray:axis_vertex, indices: axis_indices), scene: self,vertexShader:"vertexShader_Static",fragmentShader:"phong_fragment_static",drawType:MTLPrimitiveType.Line,depthType:MTLPixelFormat.Depth32Float,blendingEnable: false)
        var meshCK = MTLMesh(meshAsset: MeshAssets(filePath: "ck"), scene: self, vertexShader: "vertexShader_Static", fragmentShader: "phong_fragment_static", drawType:MTLPrimitiveType.Triangle, depthType: MTLPixelFormat.Depth32Float,blendingEnable: false)
        var actorCK = MTLActor(mesh: meshCK, animationController: nil,pos: [0,0,0],scene:self,texture:nil,normalmap:nil)
        var actor1 = MTLActor(mesh: mesh, animationController: MTLAnimationController(animationFileName: "animation", scene: self),pos: nil,scene:nil,texture:nil,normalmap:nil)
        var actor4 = MTLActor(mesh: mesh3, animationController: MTLAnimationController(animationFileName: "animation1", scene: self),pos: nil,scene:nil,texture:nil,normalmap:nil)
        var actor2 = MTLActor(mesh: mesh1, animationController: nil,pos: nil,scene:nil,texture:nil,normalmap:nil)
        var actor3 = MTLActor(mesh: mesh2, animationController: nil,pos: nil,scene:nil,texture:nil,normalmap:nil)
                //var actor1 = MTLActor(mesh: mesh1, animationController: nil)
        m_modelMatrix = Matrix()
        m_player = MTLGamePlayer(scene: self)
        m_uniform = MTLMVPUniform(model: Matrix(), view: MTLCamera(pos: [700,700,700], target: [0,0,0], up: [0,1,0]).viewMatrix(), projection: Matrix.MatrixMakeFrustum_oc(-1, right: 1, bottom: -1, top: 1, near: 699, far: -1000), device: m_device!, player: m_player)
        //var sucess : UnsafeMutablePointer<Bool> = UnsafeMutablePointer()
        m_viewMatrix = Matrix.MatrixMakeLookAt([700,700,700], center: [0,0,0], up: [0,1,0])
        m_viewMatrix.inverse()
        //m_viewMatrix.GLKToSwfit(GLKMatrix4MakeLookAt(400, 400, 400, 0, 0, 0, 0, 1, 0))
        
        m_projectionMatrix = Matrix.MatrixMakeFrustum_oc(-1, right: 1, bottom: -1, top: 1, near: 699, far: -1000)
        m_projectionMatrix.inverse()
        
        //println(m_projectionMatrix.raw())
        m_textureLoader = AAPLTexture2D(resourceName: "invoker_color", ext: "png")
        m_textureLoader.loadIntoTextureWithDevice(m_device!)
        actorCK.m_texture = m_textureLoader.texture
        
        //m_textureLoader = AAPLTexture2D(resourceName: "grass", ext: "png")
        //m_textureLoader.loadIntoTextureWithDevice(m_device!)
        //actor2.m_texture = m_textureLoader.texture
        
        m_textureLoader = AAPLTexture2D(resourceName: "NormalMap", ext: "png")
        m_textureLoader.loadIntoTextureWithDevice(m_device!)
        actor2.m_normalMapping = m_textureLoader.texture
        let particle = MTLParticle(device: m_device!, numOfParticles: 100, spread: 1000, lifeSpan: 5)
        let particle1 = MTLParticle(device: m_device!, numOfParticles: 10, spread: 1000, lifeSpan: 10)

        var particleActor = MTLParticleActor(particle: particle, scene: self, vertexShader: "vertexParticle", fragmentShader: "fragmentParticle", drawType: MTLPrimitiveType.Point, deptType: MTLPixelFormat.Depth32Float, blendingEnable: true, actorType: ActorType.PARTICLE,mvpuniform:m_uniform)
        
        var uniform = MTLMVPUniform(uniform: m_uniform, device: m_device!, player: m_player)
        uniform.setModelMatrix(Matrix().raw())
        var particleActor1 = MTLParticleActor(particle: particle1, scene: self, vertexShader: "vertexParticle", fragmentShader: "fragmentParticle", drawType: MTLPrimitiveType.Point, deptType: MTLPixelFormat.Depth32Float, blendingEnable: true, actorType: ActorType.PARTICLE,mvpuniform:uniform)
        
        m_player!.prepareActors([actor2,actor1,actor4,actorCK,actor3,particleActor,particleActor1])
      
        
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
        colorAttachment?.clearColor = MTLClearColorMake(0.1, 0.15, 0.75, 1.0)
        
        
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
        m_player.m_actors![1].m_animationController!.play(viewcontroller.m_gameTime, currentBuffer: m_player.m_currentUniform!)
        m_player.m_actors![2].m_animationController!.play(viewcontroller.m_gameTime * 0.8, currentBuffer: m_player.m_currentUniform!)
        let particle = m_player.m_actors![5] as! MTLParticleActor
        particle.updateParticle(viewcontroller)
        let particle1 = m_player.m_actors![6] as! MTLParticleActor
        particle1.updateParticle(viewcontroller)

        
    }
    
    
    func normalizeTouchPoint(x:CGFloat,y:CGFloat)->(Float,Float){
        var x1:Float = Float(x) / m_viewWidth
        var y1:Float = Float(y) / m_viewHeight
        
        x1 = 2 * (x1 - 0.5)
        y1 = 2 * (0.5 - y1)
        return (x1,y1)
    }
    
    func pan(panGesture:UIPanGestureRecognizer){
        let pos = panGesture.locationInView(self)
        let posInWorld = unproject(normalizeTouchPoint(pos.x, y: pos.y))
        m_player.m_actors![3].translate(posInWorld)
    }
    
    
    func unproject(pos:(Float,Float))->[Float]{
        let posNear = [pos.0,pos.1,699,1]
        let posFar = [pos.0,pos.1,-1000,1]
        let posViewNear = m_projectionMatrix * posNear
        let posWorldNear = m_viewMatrix * posViewNear
        let posViewFar = m_projectionMatrix * posFar
        let posWorldFar = m_viewMatrix * posViewFar
        var dir:[Float] = -1 * [posWorldNear[0]/posWorldNear[3] - posWorldFar[0]/posWorldFar[3],posWorldNear[1]/posWorldNear[3] - posWorldFar[1]/posWorldFar[3],posWorldNear[2]/posWorldNear[3] - posWorldFar[2]/posWorldFar[3]]
        dir =  Matrix.normalize(dir)
        return (-700.0 / dir[1]) * dir + [700,700,700]
        //println(t)
    }
    
    func pause(viewController: MTLGameViewController, willPause: Bool) {
        if willPause == true{
            println("pause")
        }else{
            println("continue")
        }
    }
}
