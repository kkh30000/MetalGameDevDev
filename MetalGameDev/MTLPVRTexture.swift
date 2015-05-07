//
//  MTLPVRTexture.swift
//  MetalGameDev
//
//  Created by YiLi on 15/5/5.
//  Copyright (c) 2015年 YiLi. All rights reserved.
//

import Foundation
import Metal
struct PVRTHeader {
    var headerLength:UInt32
    var height:UInt32
    var width:UInt32
    var numMipmaps:UInt32
    var flags:UInt32
    var dataLength:UInt32
    var bpp:UInt32
    var bitmaskRed:UInt32
    var bitmaskGreen:UInt32
    var bitmaskBlue:UInt32
    var bitmaskAlpha:UInt32
    var pvrTag:UInt32
    var numSurfs:UInt32
}

class MTLPVRTexture: NSObject {
    var m_data:NSData! = nil
    var m_imageData:NSMutableArray! = nil
    var m_width:UInt = 0
    var m_height:UInt = 0
    var m_texture:MTLTexture! = nil
    var m_target:MTLTextureType! = nil
    init(name:String,ext:String,pixelFormat:MTLPixelFormat,device:MTLDevice) {
        super.init()
        m_data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: ext)!)
        m_imageData = NSMutableArray(capacity: 10)
        unpack()
        var width = Int(m_width)
        var height = Int(m_height)
        
        var data = NSData()
        var texDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(pixelFormat, width: width, height: height, mipmapped: false)
        self.m_texture = device.newTextureWithDescriptor(texDesc)
        if m_texture == nil{
            println("Failed To Load PVR")
        }
        m_target = m_texture.textureType
        texDesc.mipmapLevelCount = m_imageData.count
        
        for var i = 0 ; i < m_imageData.count ;  ++i{
            data = m_imageData.objectAtIndex(i) as! NSData
            m_texture.replaceRegion(MTLRegionMake2D(0, 0, width, height), mipmapLevel: i, withBytes: data.bytes, bytesPerRow: 0)
            width = max(width >> 1, 1)
            height = max(height >> 1, 1)
        }
        
        m_imageData.removeAllObjects()
       
        
    }
    
    func unpack()->Bool{
        var sucess = false
        var header = UnsafeMutablePointer<PVRTHeader>(m_data.bytes)
        var pvrTag = CFSwapInt32LittleToHost(header.memory.pvrTag).value
        let pvrStr = "PVR!"
        var cstr = pvrStr.cStringUsingEncoding(NSUTF8StringEncoding)
        if cstr == nil{
            println("No C style String")
            return false
        }
        
        
        
        
        
       return sucess
    }
}
