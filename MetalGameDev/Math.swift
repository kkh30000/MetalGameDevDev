//
//  Math.swift
//  MetalGameDev
//
//  Created by liuang on 15/3/20.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Foundation
import Accelerate

class Matrix:NSObject {
    var m_raw:[[Float]]! = nil
    override init() {
        m_raw = [[Float]](count: 4, repeatedValue: [Float](count: 4, repeatedValue: 0.0))
        m_raw[0][0] = 1.0
        m_raw[1][1] = 1.0
        m_raw[2][2] = 1.0
        m_raw[3][3] = 1.0
    }
    init(matrxBuffer:[Float]){
        m_raw = [[Float]](count: 4, repeatedValue: [Float](count: 4, repeatedValue: 0.0))
        m_raw[0][0] = matrxBuffer[0];m_raw[0][1] = matrxBuffer[1];m_raw[0][2] = matrxBuffer[2];m_raw[0][3] = matrxBuffer[3];
        m_raw[1][0] = matrxBuffer[4];m_raw[1][1] = matrxBuffer[5];m_raw[1][2] = matrxBuffer[6];m_raw[1][3] = matrxBuffer[7];
        m_raw[2][0] = matrxBuffer[8];m_raw[2][1] = matrxBuffer[9];m_raw[2][2] = matrxBuffer[10];m_raw[2][3] = matrxBuffer[11];
        m_raw[3][0] = matrxBuffer[12];m_raw[3][1] = matrxBuffer[13];m_raw[3][2] = matrxBuffer[14];m_raw[3][3] = matrxBuffer[15];
    }
    
    
    
    
    subscript(index:(Int,Int))->Float{
        get{
            return m_raw[index.1][index.0]
        }
        set{
            m_raw[index.1][index.0] = newValue
        }
    }
    
        
    func inverse(){
        //public func inv(x : Matrix<Float>) -> Matrix<Float> {
            //precondition(x.rows == x.columns, "Matrix must be square")
        
            var ipiv = [__CLPK_integer](count: 4 * 4, repeatedValue: 0)
            var lwork = __CLPK_integer(4 * 4)
            var work = [CFloat](count: Int(lwork), repeatedValue: 0.0)
            var error: __CLPK_integer = 0
            var nc = __CLPK_integer(4)
            //reverse(results)
        var data:[Float] =   [
            m_raw[0][0],m_raw[1][0],m_raw[2][0],m_raw[3][0],
            m_raw[0][1],m_raw[1][1],m_raw[2][1],m_raw[3][1],
            m_raw[0][2],m_raw[1][2],m_raw[2][2],m_raw[3][2],
            m_raw[0][3],m_raw[1][3],m_raw[2][3],m_raw[3][3],
        ]

            sgetrf_(&nc, &nc, &(data), &nc, &ipiv, &error)
            sgetri_(&nc, &(data), &nc, &ipiv, &work, &lwork, &error)
            
            assert(error == 0, "Matrix not invertible")
            self.m_raw[0] = [data[0],data[4],data[8],data[12]]
            self.m_raw[1] = [data[1],data[5],data[9],data[13]]
            self.m_raw[2] = [data[2],data[6],data[10],data[14]]
            self.m_raw[3] = [data[3],data[7],data[11],data[15]]

        
    }
    
    class func reverse(matrix:Matrix){
        var temp = Float(0.0)
        
        temp = matrix.m_raw[1][0]
        matrix.m_raw[1][0] = matrix.m_raw[0][1]
        matrix.m_raw[0][1] = temp
        
        temp = matrix.m_raw[2][0]
        matrix.m_raw[2][0] = matrix.m_raw[0][2]
        matrix.m_raw[0][2] = temp
        
        temp = matrix.m_raw[3][0]
        matrix.m_raw[3][0] = matrix.m_raw[0][3]
        matrix.m_raw[0][3] = temp
        
        temp = matrix.m_raw[1][2]
        matrix.m_raw[1][2] = matrix.m_raw[2][1]
        matrix.m_raw[2][1] = temp
        
        temp = matrix.m_raw[1][3]
        matrix.m_raw[1][3] = matrix.m_raw[3][1]
        matrix.m_raw[3][1] = temp
        
        temp = matrix.m_raw[2][3]
        matrix.m_raw[2][3] = matrix.m_raw[3][2]
        matrix.m_raw[3][2] = temp
        
        
    }
    class func MatrixMakeFrustum_oc(left:Float,right:Float,bottom:Float,top:Float,near:Float,far:Float)->Matrix{
        var matrix = Matrix()
        var width:Float = right - left
        var height:Float = top - bottom
        var depth : Float = far - near
        var sDepth :Float = far / depth
        matrix.m_raw[0][0] = width
        matrix.m_raw[0][1] = 0
        matrix.m_raw[0][2] = 0
        matrix.m_raw[0][3] = 0
        
        matrix.m_raw[1][0] = 0
        matrix.m_raw[1][1] = height
        matrix.m_raw[1][2] = 0
        matrix.m_raw[1][3] = 0.0
        
        
        matrix.m_raw[2][0] = 0
        matrix.m_raw[2][1] = 0
        matrix.m_raw[2][2] = sDepth
        matrix.m_raw[2][3] = 1
        
        
        matrix.m_raw[3][0] = 0.0
        matrix.m_raw[3][1] = 0.0
        matrix.m_raw[3][2] = -sDepth * near
        matrix.m_raw[3][3] = 0.0
        return matrix
    }
    
    
    
    
    
    
    
    class func MatrixMakePerpective_fov(fovy:Float,aspect:Float,near:Float,far:Float)->Matrix {
        var matrix = Matrix()
        
        let angle = 0.5 * fovy * Float(M_PI) / 180.0
        let yScale = 1.0 / tan(angle)
        let xScale = yScale / aspect
        let zScale = far / (far - near)
        
        matrix.m_raw[0][0] = xScale
        matrix.m_raw[0][1] = 0
        matrix.m_raw[0][2] = 0
        matrix.m_raw[0][3] = 0
        
        matrix.m_raw[1][0] = 0
        matrix.m_raw[1][1] = yScale
        matrix.m_raw[1][2] = 0
        matrix.m_raw[1][3] = 0.0
        
        
        matrix.m_raw[2][0] = 0
        matrix.m_raw[2][1] = 0
        matrix.m_raw[2][2] = zScale
        matrix.m_raw[2][3] = 1
        
        
        matrix.m_raw[3][0] = 0.0
        matrix.m_raw[3][1] = 0.0
        matrix.m_raw[3][2] = -(near * zScale)
        matrix.m_raw[3][3] = 0.0
        
        return matrix
    }
    
    class func cross(a:[Float],b:[Float])->[Float]{
        let x = a[1] * b[2]-a[2] * b[1]
        let y = a[2] * b[0]-a[0] * b[2]
        let z = a[0] * b[1]-a[1] * b[0]
        return [x,y,z]
    }
    
    class func MatrixMakeLookAt(eye:[Float],center:[Float],up:[Float])->Matrix {
        
        var matrix = Matrix()
        let zAxis = self.normalize([center[0] - eye[0],center[1] - eye[1],center[2] - eye[2]])
        let xAxis = self.normalize(Matrix.cross(up, b: zAxis))
        let yAxis = Matrix.cross(zAxis, b: xAxis)
        
        matrix.m_raw[0][0] = xAxis[0]
        matrix.m_raw[0][1] = yAxis[0]
        matrix.m_raw[0][2] = zAxis[0]
        matrix.m_raw[0][3] = 0
        
        matrix.m_raw[1][0] = xAxis[1]
        matrix.m_raw[1][1] = yAxis[1]
        matrix.m_raw[1][2] = zAxis[1]
        matrix.m_raw[1][3] = 0.0
        
        
        matrix.m_raw[2][0] = xAxis[2]
        matrix.m_raw[2][1] = yAxis[2]
        matrix.m_raw[2][2] = zAxis[2]
        matrix.m_raw[2][3] = 0
        
        
        matrix.m_raw[3][0] = -(xAxis * eye)
        matrix.m_raw[3][1] = -(yAxis * eye)
        matrix.m_raw[3][2] = -(zAxis * eye)
        matrix.m_raw[3][3] = 1.0
        
        return matrix
    }
    
    class func normalize(v:[Float])->[Float]{
        var division = v[0] * v[0] + v[1] * v[1] + v[2] * v[2]
        division = sqrt(division)
        return [v[0] / division , v[1] / division ,v[2] / division]
    }
    
    func rotate(angle:Float,r:[Float]){
        
        let currentPosition = self.m_raw[3]
        self.translate(-currentPosition[0], y: -currentPosition[1], z: -currentPosition[2])
        self.m_raw = (self * Matrix.MatrixMakeRotate(angle, r: r)).m_raw
        self.translate(currentPosition[0], y: currentPosition[1], z: currentPosition[2])
    }
    
    
    
    class func MatrixMakeRotate(angle:Float,r:[Float])->Matrix{
        
        var matrix = Matrix()
        
        var a = angle * Float(M_PI) / 180.0
        var s = sin(a)
        var c = cos(a)
        var k = 1 - c
        let u = self.normalize(r)
        let v = [u[0] * s,u[1] * s,u[2] * s]
        let w = [u[0] * k,u[1] * k,u[2] * k]
        
        matrix.m_raw[0][0] = w[0] * u[0] + c
        matrix.m_raw[0][1] = w[0] * u[1] + v[2]
        matrix.m_raw[0][2] = w[0] * u[2] - v[1]
        matrix.m_raw[0][3] = 0.0
        
        matrix.m_raw[1][0] = w[0] * u[1] - v[2]
        matrix.m_raw[1][1] = w[1] * u[1] + c
        matrix.m_raw[1][2] = w[1] * u[2] + v[0]
        matrix.m_raw[1][3] = 0.0
        
        
        matrix.m_raw[2][0] = w[0] * u[2] + v[1]
        matrix.m_raw[2][1] = w[1] * u[2] - v[0]
        matrix.m_raw[2][2] = w[2] * u[2] + c
        matrix.m_raw[2][3] = 0.0
        
        
        matrix.m_raw[3][0] = 0.0
        matrix.m_raw[3][1] = 0.0
        matrix.m_raw[3][2] = 0.0
        matrix.m_raw[3][3] = 1.0
        
        return matrix
        
    }
    
    
    func scale(x:Float,y:Float,z:Float){
        let currentPosition = self.m_raw[3]
        self.translate(-currentPosition[0], y: -currentPosition[1], z: -currentPosition[2])
        self.m_raw = (self * Matrix.MatrixMakeScale(x, y: y, z: z)).m_raw
        self.translate(currentPosition[0], y: currentPosition[1], z: currentPosition[2])
    }
    class func MatrixMakeScale(x:Float,y:Float,z:Float)->Matrix {
        var matrix = Matrix()
        matrix.m_raw[0][0] = x
        matrix.m_raw[1][1] = y
        matrix.m_raw[2][2] = z
        matrix.m_raw[3][3] = 1.0
        return matrix
    }
    //translate矩阵多次被调用，改进方法，translate不使用矩阵乘法
    func translate(x:Float,y:Float,z:Float){
        //self.m_raw = (self * Matrix.MatrixMakeTranslate(x, y: y, z: z)).m_raw
        self.m_raw[3] = [x + self.m_raw[3][0],y + self.m_raw[3][1],z + self.m_raw[3][2],1.0]
        
    }
    
    class func MatrixMakeTranslate(x:Float,y:Float,z:Float)->Matrix{
        var matrix = Matrix()
        matrix.m_raw[3] = [x,y,z,1.0]
        return matrix
    }
    
    
    
    class func matrixMultiply(left:Matrix,right:Matrix) ->Matrix {
        var matrix = Matrix()
        Matrix.reverse(right)
        
        for var i = 0 ; i < 4 ; ++i{
            for var j = 0; j < 4; ++j{
                matrix.m_raw[i][j] = left.m_raw[i] * right.m_raw[j]
            }
        }
        
        Matrix.reverse(right)
        return matrix
    }
    
    func raw()->[Float]{
        let result : [Float] =  [
            m_raw[0][0],m_raw[0][1],m_raw[0][2],m_raw[0][3],
            m_raw[1][0],m_raw[1][1],m_raw[1][2],m_raw[1][3],
            m_raw[2][0],m_raw[2][1],m_raw[2][2],m_raw[2][3],
            m_raw[3][0],m_raw[3][1],m_raw[3][2],m_raw[3][3],
        ]
        return result
    }
}

func *(left:[Float],right:[Float])->Float{
    
    let size = left.count
    var result :Float = 0.0
    for var i = 0 ; i < size ; ++i{
        result = result + left[i] * right[i]
    }
    
    
    return result
}


func +(left:[Float],right:[Float])->[Float]{
    let size = left.count
    var result:[Float] = [Float](count: size, repeatedValue: 0.0)
    for var i = 0 ; i < size ; ++i{
        result[i] = left[i] + right[i]
    }
    return result
}


func -(left:[Float],right:[Float])->[Float]{
    let size = left.count
    var result:[Float] = [Float](count: size, repeatedValue: 0.0)
    for var i = 0 ; i < size ; ++i{
        result[i] = left[i] - right[i]
    }
    return result
}

func *(left : Float,right:[Float])->[Float]{
    let size = right.count
    var result:[Float] = [Float](count: size, repeatedValue: 0.0)
    for var i = 0 ; i < size ; ++i{
        result[i] *= left
    }
    return result
}

func *(left:Matrix,right:[Float])->[Float]{
    //left.inverse()
    Matrix.reverse(left)
    let x:Float = left.m_raw[0] * right
    let y:Float = left.m_raw[1] * right
    let z:Float = left.m_raw[2] * right
    let w:Float = left.m_raw[3] * right
    Matrix.reverse(left)
    return [x,y,z,w]
    
}




func *(left:Matrix,right:Matrix)->Matrix{
    return Matrix.matrixMultiply(left, right: right)
}

