//
//  MTLViewController.swift
//  MetalGameDev
//
//  Created by liuang on 15/3/20.
//  Copyright (c) 2015年 liuang. All rights reserved.
//


//ViewController  设置时间线，分配代理，管理MTLView


import UIKit
import QuartzCore


protocol MTLGameViewControllerDelegate{
    func rotate(viewController:MTLGameViewController,rotateX:Float,rotateY:Float)
    func pause(viewController:MTLGameViewController,willPause:Bool)
    func updatePerFrame(viewcontroller:MTLGameViewController)
}

class MTLGameViewController: UIViewController {
    var m_timer:CADisplayLink! = nil
    var m_isFirstDraw:Bool = true
    var m_timeSinceLastDraw:CFTimeInterval = 0
    var m_timeSinceLastDrawPrevious:CFTimeInterval = 0
    var m_gameTime:CFTimeInterval = 0
    var m_isGamePaused:Bool = false
    var m_delegate:MTLGameViewControllerDelegate! = nil
    var m_metalGameScene : MTLGameScene! = nil
    
    
    //手势
    var lastPanLocation:CGPoint! = nil
    var panSensitity:Float = 500.0
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initCommon()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initCommon()
    }
    
    //通知view游戏停止
    
    func initCommon(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "AppDidEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "AppWillEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func viewDidLoad() {
        // println("humandroid count:\(humandroid_vertices.count / 3)")
        super.viewDidLoad()
        m_metalGameScene = MTLGameScene(frame: self.view.frame)
        m_metalGameScene.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "pan:"))
        self.view = m_metalGameScene
        
        self.m_delegate = m_metalGameScene
        
    }
    
    
    
    func pan(panGesture:UIPanGestureRecognizer){
        if panGesture.state == UIGestureRecognizerState.Changed{
            let currentPanPos = panGesture.locationInView(self.view)
            let deltaX = Float((currentPanPos.x - lastPanLocation.x)) / Float((self.view.bounds.size.width)) * panSensitity
            let deltaY = Float((currentPanPos.y - lastPanLocation.y)) / Float((self.view.bounds.size.height)) * panSensitity
            self.lastPanLocation = currentPanPos
            self.m_delegate.rotate(self, rotateX: deltaX, rotateY: deltaY)
        }else if panGesture.state == UIGestureRecognizerState.Began{
            self.lastPanLocation = panGesture.locationInView(self.view)
        }
    }
    
    
    
    func AppDidEnterBackground(){
        setGamePaused(true)
    }
    
    func AppWillEnterForeground(){
        setGamePaused(false)
    }
    //游戏停止
    func setGamePaused(willPause:Bool){
        if m_isGamePaused == willPause{
            return
        }else{
            self.m_delegate.pause(self, willPause: willPause)
            if willPause == true{
                m_timer.paused = true
                m_isGamePaused = true
                (self.view as! MTLGameScene).releaseTexture()
                
            }else{
                m_timer.paused = false
                m_isGamePaused = false
                m_timeSinceLastDrawPrevious = CACurrentMediaTime()
            }
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dispatchGame()
        
    }
    
    
    
    
    
    func dispatchGame(){
        //设置计时器
        
        m_timer = CADisplayLink(target: self, selector: "gameLoop")
        
        //设置fps   1:60fps  2:30fps
        
        m_timer.frameInterval = 2
        
        m_timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    //每一帧都会调用
    
    func gameLoop(){
        //println(m_gameTime)
        if m_isFirstDraw == true{
            m_timeSinceLastDrawPrevious = CACurrentMediaTime()
            m_timeSinceLastDraw = 0
            m_isFirstDraw = false
        }else{
            m_timeSinceLastDraw = CACurrentMediaTime() - m_timeSinceLastDrawPrevious
            m_timeSinceLastDrawPrevious = CACurrentMediaTime()
        }
        
        m_gameTime += m_timeSinceLastDraw
        //println("Game Time : \(m_gameTime)")
        self.m_delegate.updatePerFrame(self)
        (self.view as! MTLGameScene).display()
        
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
}
