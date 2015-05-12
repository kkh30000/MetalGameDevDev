//
//  Math.swift
//  MetalGameDev
//
//  Created by liuang on 15/3/20.
//  Copyright (c) 2015年 liuang. All rights reserved.
//

import Foundation

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
    
    
    func inverse()->Matrix?{
        var iis:[Int] = [Int](count: 4, repeatedValue: 0)
        var jjs:[Int] = [Int](count: 4, repeatedValue: 0)
        
        var fDet:Float = 1.0
        var f:Int = 1
        
        for var k = 0 ; k < 4 ; ++k{
            var fMax:Float = 0.0
            for  var i = k ; i < 4; ++i{
                for var j = k ; j < 4; ++j{
                    let temp:Float = abs(self[(i,j)])
                    if temp > fMax{
                        fMax = temp
                        iis[k] = i
                        jjs[k] = j
                    }
                }
            }
            if abs(fMax) < 0.0001{
                return self
            }
            if iis[k] != k {
                f = -f
                swap(&self[(k,0)], &self[(iis[k],0)])
                swap(&self[(k,1)], &self[(iis[k],1)])
                swap(&self[(k,2)], &self[(iis[k],2)])
                swap(&self[(k,3)], &self[(iis[k],3)])
                
                
            }
            if jjs[k] != k {
                f = -f
                swap(&self[(0,k)], &self[(0,jjs[k])])
                swap(&self[(1,k)], &self[(1,jjs[k])])
                swap(&self[(2,k)], &self[(2,jjs[k])])
                swap(&self[(3,k)], &self[(3,jjs[k])])
            }
            fDet *= self[(k,k)]
            
            self[(k,k)] = 1.0/self[(k,k)]
            for var j = 0 ; j < 4 ; ++j{
                if j != k{
                    self[(k,j)] *= self[(k,k)]
                }
            }
            for var i = 0 ; i < 4 ; ++i{
                if i != k {
                    for var j = 0 ; j < 4 ; ++j{
                        if j != k{
                            self[(i,j)] -= self[(i,k)] * self[(k,j)]
                        }
                    }
                }
            }
            for var i = 0 ; i < 4 ; ++i{
                if i != k{
                    self[(i,k)] *= -self[(k,k)]
                }
            }
        }
        for var k = 3 ; k >= 0; --k{
            if jjs[k] != k{
                swap(&self[(k,0)], &self[(jjs[k],0)])
                swap(&self[(k,1)], &self[(jjs[k],1)])
                swap(&self[(k,2)], &self[(jjs[k],2)])
                swap(&self[(k,3)], &self[(jjs[k],3)])
                
            }
            if iis[k] != k{
                swap(&self[(0,k)], &self[(0,iis[k])])
                swap(&self[(1,k)], &self[(1,iis[k])])
                swap(&self[(2,k)], &self[(2,iis[k])])
                swap(&self[(3,k)], &self[(3,iis[k])])
                
            }
        }
        return self
        
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
    let x = left.m_raw[0] * right
    let y = left.m_raw[1] * right
    let z = left.m_raw[2] * right
    let w = left.m_raw[3] * right
    return [x,y,z,w]
    
}




func *(left:Matrix,right:Matrix)->Matrix{
    return Matrix.matrixMultiply(left, right: right)
}

