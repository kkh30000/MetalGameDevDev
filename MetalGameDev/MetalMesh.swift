//
//  MTLMesh.swift
//  MetalGameDev
//
//  Created by liuang on 15/3/20.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Foundation
import Metal



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
    var m_blendingEnable:Bool!  = nil
    
    init(meshAsset:MeshAssets?,scene:MTLGameScene,vertexShader:String,fragmentShader:String,drawType:MTLPrimitiveType,depthType:MTLPixelFormat,blendingEnable:Bool) {
        super.init()
        m_meshType = drawType
        m_depthType = depthType
        m_scene = scene
        var device = scene.m_device!
        m_vertexShader = vertexShader
        m_fragmentShader = fragmentShader
        m_meshAssets = meshAsset
        m_blendingEnable = blendingEnable
        if meshAsset != nil{
            m_vertexBuffer = device.newBufferWithBytes(meshAsset!.m_vertexArray!, length: meshAsset!.vertexArrayLength(),     options: nil)
            m_vertexBuffer.label = "Mesh Vertex Buffer"
            if m_meshAssets.m_vertexIndices != nil{
                m_indexBuffer = device.newBufferWithBytes(meshAsset!.m_vertexIndices!, length: meshAsset!.vertexIndicesLength(),  options: nil)
            }
        }
        //prepareRenderPipeLineStateWithShaderName(device, vertexShader: vertexShader, fragmentShader: fragmentShader)
    }
    func prepareRenderPipeLineStateWithShaderName(device:MTLDevice,vertexShader:String,fragmentShader:String,depthPixelFormat:MTLPixelFormat,renderPipelineDesc:MTLRenderPipelineDescriptor){
        let library = device.newDefaultLibrary()
        if library == nil{
            return
        }
        var vertexShader = library!.newFunctionWithName(vertexShader)
        var fragmentShader = library!.newFunctionWithName(fragmentShader)
        //var renderPipeLineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDesc.vertexFunction = vertexShader
        renderPipelineDesc.fragmentFunction = fragmentShader
        renderPipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        if m_blendingEnable == true{
            renderPipelineDesc.colorAttachments[0].blendingEnabled = true
            renderPipelineDesc.colorAttachments[0].writeMask = MTLColorWriteMask.All
            renderPipelineDesc.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.Add
            renderPipelineDesc.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.Add
            //renderPipelineDesc.colorAttachments[0]
            renderPipelineDesc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.SourceAlpha
            renderPipelineDesc.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.SourceAlpha
            renderPipelineDesc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.OneMinusBlendAlpha;
            renderPipelineDesc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.OneMinusBlendAlpha;
        }
        renderPipelineDesc.depthAttachmentPixelFormat = depthPixelFormat
        var error:NSErrorPointer
        renderPipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormat.Stencil8
        m_renderPipeLineState = device.newRenderPipelineStateWithDescriptor(renderPipelineDesc, error: nil)
        renderPipelineDesc.colorAttachments[0].blendingEnabled = false
    }
    
    
    
}