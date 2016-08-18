//
//  GameScene.swift
//  MyFlappyBird
//
//  Created by 杨威 on 16/8/17.
//  Copyright (c) 2016年 demo. All rights reserved.
//

import SpriteKit

enum Layer: CGFloat{
  case background, barrier, foreground, bird, UI
}

enum State{
  case game, ready, displayScore, end, fall
}



class GameScene: SKScene, SKPhysicsContactDelegate {
  //MARK: - model
  let worldNode = SKNode()
  var bird: SKSpriteNode!
  let pipeUpTexture = SKTexture(imageNamed: "PipeUp")
  let pipeDowmTexture = SKTexture(imageNamed: "PipeDown")
  var scoreLabel: SKLabelNode!
  var score: Int = 0{
    didSet{
      scoreLabel.text = "\(score)"
    }
  }
  
  //MARK: - Constants & Varibles
  var pipeGap: CGFloat = 0
  var startLevel: CGFloat = 0
  var heightOfGameScale: CGFloat = 0.8
  let barrierSpeed: CGFloat = -150
  let firstDefer = NSTimeInterval(1.75)
  let perDefer = NSTimeInterval(1.5)
  var gameState: State = .ready
  let landAnimKey = "landAnim"
  let pipeAnimKey = "foreverPipe"
  let birdUpDowmAnimKey = "birdUpDowm"
  let birdWingAnimKey = "birdWing"
  let skyMoveAnimKey = "skyMove"
  
  let birdCategory: UInt32 = 1 << 0
  let pipeCategory: UInt32 = 1 << 1
  let landCategory: UInt32 = 1 << 2
  let scoreLineCategory: UInt32 = 1 << 3
  //Sound
  let coinSound = SKAction.playSoundFileNamed("coin", waitForCompletion: false)
  let fallingSound = SKAction.playSoundFileNamed("falling", waitForCompletion: false)
  let flappingSound = SKAction.playSoundFileNamed("flapping", waitForCompletion: false)
  let hitGroundSound = SKAction.playSoundFileNamed("hitGround", waitForCompletion: false)
  let popSound = SKAction.playSoundFileNamed("pop", waitForCompletion: false)
  let whackSound = SKAction.playSoundFileNamed("whack", waitForCompletion: false)
  //MARK: - Configuration
  
  private func backgroundConfig(){
    
    let skyTextrue = SKTexture(imageNamed: "sky")
    skyTextrue.filteringMode = .Nearest
    let groundTextrue = SKTexture(imageNamed: "land")
    groundTextrue.filteringMode = .Nearest
    
    startLevel = size.height*(1-heightOfGameScale)
    
    self.backgroundColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    
    //landMoveAnimation
    let landMoveLeft = SKAction.moveByX(-groundTextrue.size().width*2, y: 0, duration: NSTimeInterval(0.01*groundTextrue.size().width*2))
    let restartLand = SKAction.moveByX(groundTextrue.size().width*2, y: 0, duration: 0)
    let moveLand = SKAction.repeatActionForever(SKAction.sequence([landMoveLeft, restartLand]))
    let landNum = 2 + Int(size.width / (groundTextrue.size().width*2))
    for i in 0..<landNum {
     let landSprite = SKSpriteNode(texture: groundTextrue)
      landSprite.setScale(2.0)
      landSprite.position = CGPoint(x: CGFloat(i) * landSprite.size.width , y: startLevel)
      landSprite.zPosition = Layer.foreground.rawValue
      landSprite.anchorPoint = CGPoint(x: 0.5, y: 1)
      landSprite.name = "land"
      landSprite.runAction(moveLand,withKey: landAnimKey)
      worldNode.addChild(landSprite)
    }
    //skyMoveAnimation
    let skyMoveLeft = SKAction.moveByX(-skyTextrue.size().width*2, y: 0, duration: NSTimeInterval(0.05*skyTextrue.size().width*2))
    let restartSky = SKAction.moveByX(skyTextrue.size().width*2, y: 0, duration: 0)
    let moveSky = SKAction.repeatActionForever(SKAction.sequence([skyMoveLeft, restartSky]))
    let skyNum = 2 + Int(size.width / (skyTextrue.size().width*2))
    for i in 0..<skyNum{
     let skySprite = SKSpriteNode(texture: skyTextrue)
      skySprite.setScale(2.0)
      skySprite.position = CGPoint(x: CGFloat(i) * skySprite.size.width, y: startLevel)
      skySprite.zPosition = Layer.background.rawValue
      skySprite.anchorPoint = CGPoint(x: 0.5, y: 0)
      skySprite.name = "sky"
      skySprite.runAction(moveSky, withKey: skyMoveAnimKey)
      worldNode.addChild(skySprite)
    }
    //add land physicsBody
    let horizon = SKPhysicsBody(edgeFromPoint: CGPoint(x: 0, y: startLevel), toPoint: CGPoint(x: size.width, y: startLevel))
    worldNode.physicsBody = horizon
    worldNode.physicsBody?.categoryBitMask = landCategory
    worldNode.physicsBody?.collisionBitMask = birdCategory
    worldNode.physicsBody?.contactTestBitMask = birdCategory
    worldNode.physicsBody?.dynamic = false
    
    scoreLabel = SKLabelNode(fontNamed: "Zapfino")
    scoreLabel.text = "fuck"
    scoreLabel.zPosition = Layer.UI.rawValue
    scoreLabel.position = CGPoint(x: size.width / 2, y: 0.75 * size.height)
    worldNode.addChild(scoreLabel)
  }
  
  private func birdConfig(){
    let birdTexture = SKTexture(imageNamed: "bird-01")
    birdTexture.filteringMode = .Nearest
    
    bird = SKSpriteNode(texture: birdTexture)
    bird.setScale(2.0)
    bird.zPosition = Layer.bird.rawValue
    bird.position = CGPoint(x: size.width*0.4, y: size.height*0.6)
    bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2)
    bird.physicsBody?.allowsRotation = false
    bird.physicsBody?.categoryBitMask = birdCategory
    bird.physicsBody?.collisionBitMask = pipeCategory | landCategory
    bird.physicsBody?.contactTestBitMask = pipeCategory | landCategory | scoreLineCategory
    birdWingFly()
    worldNode.addChild(bird)
  }
  
  private func letBirdFly(){
    bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
    bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
    runAction(flappingSound)
  }
  
  private func birdWingFly(){
    var wingArray = [SKTexture]()
    for i in 1...3{
      let wing = SKTexture(imageNamed: "bird-0\(i)")
      wing.filteringMode = .Nearest
      wingArray.append(wing)
    }
    wingArray.append(wingArray[1])
    //1.2.3.2.1
    let wingfly = SKAction.animateWithTextures(wingArray, timePerFrame: 0.07)
    bird.runAction(SKAction.repeatActionForever(wingfly), withKey: birdWingAnimKey)
    
    let flyUp = SKAction.moveByX(0, y: 30, duration: 0.3)
    flyUp.timingMode = .EaseInEaseOut
    let flyDowm = flyUp.reversedAction()
    
    let upDowm = SKAction.sequence([flyUp, flyDowm])
    bird.runAction(SKAction.repeatActionForever(upDowm), withKey: birdUpDowmAnimKey)
    
  }
  
  private func barrierConfig(){
    let reborn = SKAction.runBlock{
      self.barrierGenerate()
    }
    let startAnim = SKAction.sequence([
      SKAction.waitForDuration(firstDefer),
      reborn
      ])
    let anim = SKAction.sequence([
      SKAction.waitForDuration(perDefer),
      reborn
      ])
    let animForever = SKAction.repeatActionForever(anim)
    runAction(SKAction.sequence([startAnim, animForever]),withKey: pipeAnimKey)
  }
  
  private func barrierGenerate(){
    let pipeUP = createPipeNodes(pipeUpTexture)
    let pipeUP2 = createPipeNodes(pipeUpTexture)
    let pipeDowm = createPipeNodes(pipeDowmTexture)
    let pipeDowm2 = createPipeNodes(pipeDowmTexture)
    let minY = startLevel - pipeDowm.size.height/2 + size.height * heightOfGameScale * 0.1
    let maxY = startLevel - pipeDowm.size.height/2 + size.height * heightOfGameScale * 0.7
    //由于素材 管子的长度不够 增加管子接上去
    pipeUP.position = CGPoint(x: size.width + pipeUP.size.width/2, y: CGFloat.random(min: minY, max: maxY))
    pipeDowm2.position = CGPoint(x: pipeUP.position.x, y: pipeUP.position.y - pipeUP.size.height)
    pipeGap = bird.size.height * 3.5
    pipeDowm.position = CGPoint(x: pipeUP.position.x, y: pipeUP.position.y + pipeUP.size.height/2 + pipeGap + pipeDowm.size.height/2)
    pipeUP2.position = CGPoint(x: pipeDowm.position.x, y: pipeDowm.position.y + pipeDowm.size.height)
    pipeUP.userData = NSMutableDictionary()
    pipeUP.userData!.setValue(NSNumber(bool: false), forKey: "isPassed")
    let distance = -(size.width + pipeDowm.size.width)
    let time = NSTimeInterval(distance / barrierSpeed)
    let moveLeft = SKAction.moveByX(distance, y: 0, duration: time)
    let anim = SKAction.sequence([
      moveLeft,
      SKAction.removeFromParent()
      ])
    pipeUP.runAction(anim, withKey: pipeAnimKey)
    pipeDowm.runAction(anim, withKey: pipeAnimKey)
    pipeUP2.runAction(anim, withKey: pipeAnimKey)
    pipeDowm2.runAction(anim, withKey: pipeAnimKey)
    worldNode.addChild(pipeDowm)
    worldNode.addChild(pipeUP)
    worldNode.addChild(pipeDowm2)
    worldNode.addChild(pipeUP2)
  }
  
  private func detactIsPassed(){
    worldNode.enumerateChildNodesWithName("pipe") { (node, _) in
      
      guard let number = node.userData?["isPassed"] as? NSNumber else { return }
      guard self.gameState != .fall else { return }
      guard number.boolValue == false else { return }
      
      if self.bird.position.x >= node.position.x + node.frame.width/2{
        node.userData?.setValue(NSNumber(bool: true), forKey: "isPassed")
        self.score += 1
        let bigger = SKAction.scaleTo(1.3, duration: 0.3)
        bigger.timingMode = .EaseInEaseOut
        let smaller = SKAction.scaleTo(1.0, duration: 0.3)
        smaller.timingMode = .EaseInEaseOut
        self.scoreLabel.runAction(SKAction.sequence([bigger, smaller]))
        self.runAction(self.coinSound)
      }
    }
  }
  
  private func createPipeNodes(texture: SKTexture) -> SKSpriteNode{
    texture.filteringMode = .Nearest
    let pipe = SKSpriteNode(texture: texture)
    pipe.setScale(2.0)
    pipe.physicsBody = SKPhysicsBody(rectangleOfSize: pipe.size)
    pipe.physicsBody?.dynamic = false
    pipe.zPosition = Layer.barrier.rawValue
    pipe.physicsBody?.categoryBitMask = pipeCategory
    pipe.physicsBody?.collisionBitMask = birdCategory
    pipe.physicsBody?.contactTestBitMask = birdCategory
    pipe.name = "pipe"
    return pipe
  }
  
  //MARK: - GameState
  private func turnToReadyState(){
    gameState = .ready
    backgroundConfig()
    birdConfig()
  }
  
  private func turnToGameState(){
    gameState = .game
    bird.removeActionForKey(birdUpDowmAnimKey)
    physicsWorld.gravity = CGVector(dx: 0, dy: -5)
    letBirdFly()
    barrierConfig()
  }
  
  private func turn2FallState(){
    gameState = .fall
    runAction(fallingSound)
    stopAnimation()
    bird.runAction(  SKAction.rotateByAngle(CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration:1), completion:{self.bird.speed = 0 })
    bird.physicsBody?.collisionBitMask = landCategory
  }
  
  private func stopAnimation(){
    self.removeActionForKey(pipeAnimKey)
    bird.removeActionForKey(birdWingAnimKey)
    worldNode.enumerateChildNodesWithName("pipe") { (pipes, _) in
      pipes.removeActionForKey(self.pipeAnimKey)
    }
    worldNode.enumerateChildNodesWithName("sky") { (sky, _) in
      sky.removeActionForKey(self.skyMoveAnimKey)
    }
    worldNode.enumerateChildNodesWithName("land") { (land, _) in
      land.removeActionForKey(self.landAnimKey)
    }

  }
  
  private func turn2EndState(){
    stopAnimation()
    runAction(hitGroundSound)
    gameState = .end
  }
  
  //MARK: - SKScene Method
  override func didMoveToView(view: SKView) {
    /* Setup your scene here */
    physicsWorld.gravity = CGVectorMake(0.0, 0)
    physicsWorld.contactDelegate = self
    addChild(worldNode)
    turnToReadyState()
  }
  
  func didBeginContact(contact: SKPhysicsContact) {
    let beContactObject = contact.bodyA.categoryBitMask == birdCategory ? contact.bodyB : contact.bodyA
    
    if beContactObject.categoryBitMask == pipeCategory && gameState != .fall{
      turn2FallState()
      
    } else if beContactObject.categoryBitMask == landCategory && gameState != .end{
      turn2EndState()
    }
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    /* Called when a touch begins */
    switch gameState{
    case .ready:
      turnToGameState()
    case .game:
      letBirdFly()
    case .displayScore:
      break
    case .end :
      restart()
      break
    case .fall:
      break
    }
    
  }
  
  private func restart(){
    let newScene = GameScene.init(size: size)
    newScene.scaleMode = .AspectFill
    let transEffect = SKTransition.fadeWithColor(self.backgroundColor, duration: 0.03)
    view?.presentScene(newScene, transition: transEffect)
  }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
    //让小鸟rotation 根据y方向上的速度
    //bird.zRotation = self.clamp( -1, max: 0.5, value: bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 ) )
    let value = bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.002 : 0.001)
    
    bird.zRotation = max(min(value, 0.5), -1)
    detactIsPassed()
  }
  
  
}


//MARK: - Extension
extension CGFloat{
  static func random(min min: CGFloat, max: CGFloat) -> CGFloat{
    guard  min < max else { return 0 }
    return CGFloat(arc4random())/CGFloat(UInt32.max) * (max - min) + min
  }
}
