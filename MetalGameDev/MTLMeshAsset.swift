//
//  MTLMeshAsset.swift
//  MetalGameDev
//
//  Created by YiLi on 15/5/22.
//  Copyright (c) 2015年 YiLi. All rights reserved.
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
        var vertexIndices = jsonDict.objectForKey("index") as? [Float]
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

