//
//  MTLAnimationController.swift
//  GameMetal
//
//  Created by liuang on 15/4/19.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Foundation
import Metal


class MTLAnimationController: NSObject{
    var m_frames:[[Float]]! = nil
    var m_frameCount = 0
    var m_uniformBuffer:MTLUniform! = nil
    init(animationFileName:String,scene:MTLGameScene) {
        super.init()
        var animationData = NSData(contentsOfURL: NSBundle.mainBundle().URLForResource(animationFileName, withExtension: "json")!)
        var jsonDict = NSJSONSerialization.JSONObjectWithData(animationData!, options: NSJSONReadingOptions.AllowFragments, error: nil) as! NSDictionary
        var jsonSwift1 = [Int:[Float]]()
        for ele in jsonDict{
            jsonSwift1.updateValue(ele.value as! [(Float)], forKey: (ele.key as! String).toInt()!)
        }
        m_frames = [[Float]]()
        for var i : Int = 0 ; i < jsonSwift1.count ; ++i{
            m_frames.append(jsonSwift1[i]!)
        }
        //m_frames = [[Float]](jsonSwift1.values)
        m_frameCount = m_frames.count
        m_uniformBuffer = MTLUniform(size: sizeofValue(m_frames[0][0]) * m_frames.count * m_frames[0].count, device: scene.m_device!)
        for var i = 0 ; i < 3 ; ++i{
            m_uniformBuffer.updateDataToUniform(m_frames[0], toUniform: m_uniformBuffer[i])
        }
    }
    func play(currentTime:CFTimeInterval,currentBuffer:Int){
        m_uniformBuffer.updateDataToUniform(m_frames[Int(currentTime*30) % m_frames.count], toUniform: m_uniformBuffer[currentBuffer])
    }
}