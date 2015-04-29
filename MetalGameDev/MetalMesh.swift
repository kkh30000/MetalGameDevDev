//
//  MTLMesh.swift
//  MetalGameDev
//
//  Created by liuang on 15/3/20.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Foundation
import Metal


class MeshAssets:NSObject {
    var m_vertexArray:[Float]?
    var m_vertexIndices:[UInt16]?
    //var m_jsonDict:NSDictionary! = nil
    
    
    
    init(filePath:String){
        super.init()
        var meshData = NSData(contentsOfURL: NSBundle.mainBundle().URLForResource(filePath, withExtension: "json")!)
        //var error = NSErrorPointer()
        var jsonDict = NSJSONSerialization.JSONObjectWithData(meshData!, options: NSJSONReadingOptions.AllowFragments, error: nil) as! NSDictionary
        m_vertexArray = jsonDict.objectForKey("vertex") as? [Float]
        var vertexIndices = jsonDict.objectForKey("indices") as? [Int]
        m_vertexIndices = [UInt16](count: vertexIndices!.count, repeatedValue: 0)
        for var i = 0 ; i < vertexIndices!.count ; ++i{
            m_vertexIndices![i] = UInt16(vertexIndices![i])
        }
    }
    
    init(vertexArray:[Float],indices:[UInt16]?) {
        super.init()
        m_vertexArray = vertexArray
        if indices != nil{
            m_vertexIndices = indices
        }
        
    }
    
    func arrayLength<T>(array:[T])->Int{
        return sizeofValue(array[0]) * array.count
    }
    
    func vertexArrayLength()->Int{
        return arrayLength(m_vertexArray!)
    }
    
    func vertexIndicesLength()->Int{
        return arrayLength(m_vertexIndices!)
    }
    
}







class MTLMesh:NSObject {
    var m_meshAssets:MeshAssets! = nil
    var m_vertexBuffer:MTLBuffer! = nil
    var m_indexBuffer:MTLBuffer?
    var m_textureCoordBuffer:MTLBuffer?
    
    var m_renderPipeLineState:MTLRenderPipelineState?
    var m_scene:MTLGameScene?
    var m_vertexShader:String?
    var m_fragmentShader:String?
    var m_meshType:MTLPrimitiveType?
    var m_depthType:MTLPixelFormat?
    
    init(meshAsset:MeshAssets,scene:MTLGameScene,vertexShader:String,fragmentShader:String,drawType:MTLPrimitiveType,depthType:MTLPixelFormat) {
        super.init()
        m_meshType = drawType
        m_depthType = depthType
        m_scene = scene
        var device = scene.m_device!
        m_vertexShader = vertexShader
        m_fragmentShader = fragmentShader
        m_meshAssets = meshAsset
        m_vertexBuffer = device.newBufferWithBytes(meshAsset.m_vertexArray!, length: meshAsset.vertexArrayLength(), options: nil)
        if m_meshAssets.m_vertexIndices != nil{
            m_indexBuffer = device.newBufferWithBytes(meshAsset.m_vertexIndices!, length: meshAsset.vertexIndicesLength(), options: nil)
        }
        //prepareRenderPipeLineStateWithShaderName(device, vertexShader: vertexShader, fragmentShader: fragmentShader)
    }
    func prepareRenderPipeLineStateWithShaderName(device:MTLDevice,vertexShader:String,fragmentShader:String,depthPixelFormat:MTLPixelFormat,renderPipeLineDescriptor:MTLRenderPipelineDescriptor){
        let library = device.newDefaultLibrary()
        if library == nil{
            return
        }
        var vertexShader = library!.newFunctionWithName(vertexShader)
        var fragmentShader = library!.newFunctionWithName(fragmentShader)
        //var renderPipeLineDescriptor = MTLRenderPipelineDescriptor()
        renderPipeLineDescriptor.vertexFunction = vertexShader
        renderPipeLineDescriptor.fragmentFunction = fragmentShader
        renderPipeLineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        renderPipeLineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        var error:NSErrorPointer
        renderPipeLineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.Stencil8
        m_renderPipeLineState = device.newRenderPipelineStateWithDescriptor(renderPipeLineDescriptor, error: nil)
    }
    
    
    
}