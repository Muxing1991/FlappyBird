//
//  GameScene.swift
//  MyFlappyBird
//
//  Created by 杨威 on 16/8/17.
//  Copyright (c) 2016年 demo. All rights reserved.
//

import SpriteKit

enum Layer: CGFloat{
  case background, barrier, foreground, bird, ui
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
      scoreLabel.text = "+\(score)s"
    }
  }
  
  //MARK: - Constants & Varibles
  var pipeGap: CGFloat = 0
  var startLevel: CGFloat = 0
  var heightOfGameScale: CGFloat = 0.8
  let barrierSpeed: CGFloat = -150
  let firstDefer = TimeInterval(1.75)
  let perDefer = TimeInterval(1.5)
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
//  let coinSound = SKAction.playSoundFileNamed("coin", waitForCompletion: false)
  let fallingSound = SKAction.playSoundFileNamed("falling", waitForCompletion: false)
  let flappingSound = SKAction.playSoundFileNamed("flapping", waitForCompletion: false)
  let hitGroundSound = SKAction.playSoundFileNamed("hitGround", waitForCompletion: false)
//  let popSound = SKAction.playSoundFileNamed("pop", waitForCompletion: false)
//  let whackSound = SKAction.playSoundFileNamed("whack", waitForCompletion: false)
  
  //MO
  let sjbz = SKAction.playSoundFileNamed("sjbz", waitForCompletion: false)
  let someTimesNaive = SKAction.playSoundFileNamed("someTimesNaive", waitForCompletion: false)
  let naive = SKAction.playSoundFileNamed("naive", waitForCompletion: false)
  let txfs = SKAction.playSoundFileNamed("txfs", waitForCompletion: false)
  let hck = SKAction.playSoundFileNamed("hck", waitForCompletion: false)
  let tooSimple = SKAction.playSoundFileNamed("tooSimple", waitForCompletion: false)
  var mo = [SKAction]()
  //MARK: - Configuration
  
  fileprivate func backgroundConfig(){
    
    mo = [sjbz, someTimesNaive, naive, txfs, hck, tooSimple]
    let skyTextrue = SKTexture(imageNamed: "sky")
    skyTextrue.filteringMode = .nearest
    let groundTextrue = SKTexture(imageNamed: "land")
    groundTextrue.filteringMode = .nearest
    
    startLevel = size.height*(1-heightOfGameScale)
    
    self.backgroundColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    
    //landMoveAnimation
    let landMoveLeft = SKAction.moveBy(x: -groundTextrue.size().width*2, y: 0, duration: TimeInterval(0.01*groundTextrue.size().width*2))
    let restartLand = SKAction.moveBy(x: groundTextrue.size().width*2, y: 0, duration: 0)
    let moveLand = SKAction.repeatForever(SKAction.sequence([landMoveLeft, restartLand]))
    let landNum = 2 + Int(size.width / (groundTextrue.size().width*2))
    for i in 0..<landNum {
     let landSprite = SKSpriteNode(texture: groundTextrue)
      landSprite.setScale(2.0)
      landSprite.position = CGPoint(x: CGFloat(i) * landSprite.size.width , y: startLevel)
      landSprite.zPosition = Layer.foreground.rawValue
      landSprite.anchorPoint = CGPoint(x: 0.5, y: 1)
      landSprite.name = "land"
      landSprite.run(moveLand,withKey: landAnimKey)
      worldNode.addChild(landSprite)
    }
    //skyMoveAnimation
    let skyMoveLeft = SKAction.moveBy(x: -skyTextrue.size().width*2, y: 0, duration: TimeInterval(0.05*skyTextrue.size().width*2))
    let restartSky = SKAction.moveBy(x: skyTextrue.size().width*2, y: 0, duration: 0)
    let moveSky = SKAction.repeatForever(SKAction.sequence([skyMoveLeft, restartSky]))
    let skyNum = 2 + Int(size.width / (skyTextrue.size().width*2))
    for i in 0..<skyNum{
     let skySprite = SKSpriteNode(texture: skyTextrue)
      skySprite.setScale(2.0)
      skySprite.position = CGPoint(x: CGFloat(i) * skySprite.size.width, y: startLevel)
      skySprite.zPosition = Layer.background.rawValue
      skySprite.anchorPoint = CGPoint(x: 0.5, y: 0)
      skySprite.name = "sky"
      skySprite.run(moveSky, withKey: skyMoveAnimKey)
      worldNode.addChild(skySprite)
    }
    //add land physicsBody
    let horizon = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: startLevel), to: CGPoint(x: size.width, y: startLevel))
    worldNode.physicsBody = horizon
    worldNode.physicsBody?.categoryBitMask = landCategory
    worldNode.physicsBody?.collisionBitMask = birdCategory
    worldNode.physicsBody?.contactTestBitMask = birdCategory
    worldNode.physicsBody?.isDynamic = false
    
    scoreLabel = SKLabelNode(fontNamed: "Zapfino")
    scoreLabel.text = "naive"
    scoreLabel.zPosition = Layer.ui.rawValue
    scoreLabel.position = CGPoint(x: size.width / 2, y: 0.75 * size.height)
    worldNode.addChild(scoreLabel)
  }
  
  fileprivate func birdConfig(){
    let birdTexture = SKTexture(imageNamed: "bird-01")
    birdTexture.filteringMode = .nearest
    
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
  
  fileprivate func letBirdFly(){
    bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
    bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
    run(flappingSound)
  }
  
  fileprivate func birdWingFly(){
    var wingArray = [SKTexture]()
    for i in 1...3{
      let wing = SKTexture(imageNamed: "bird-0\(i)")
      wing.filteringMode = .nearest
      wingArray.append(wing)
    }
    wingArray.append(wingArray[1])
    //1.2.3.1
    let wingfly = SKAction.animate(with: wingArray, timePerFrame: 0.07)
    bird.run(SKAction.repeatForever(wingfly), withKey: birdWingAnimKey)
    
    let flyUp = SKAction.moveBy(x: 0, y: 30, duration: 0.3)
    flyUp.timingMode = .easeInEaseOut
    let flyDowm = flyUp.reversed()
    
    let upDowm = SKAction.sequence([flyUp, flyDowm])
    bird.run(SKAction.repeatForever(upDowm), withKey: birdUpDowmAnimKey)
    
  }
  
  fileprivate func barrierConfig(){
    let reborn = SKAction.run{
      self.barrierGenerate()
    }
    let startAnim = SKAction.sequence([
      SKAction.wait(forDuration: firstDefer),
      reborn
      ])
    let anim = SKAction.sequence([
      SKAction.wait(forDuration: perDefer),
      reborn
      ])
    let animForever = SKAction.repeatForever(anim)
    run(SKAction.sequence([startAnim, animForever]),withKey: pipeAnimKey)
  }
  
  fileprivate func barrierGenerate(){
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
    pipeUP.userData!.setValue(NSNumber(value: false as Bool), forKey: "isPassed")
    let distance = -(size.width + pipeDowm.size.width)
    let time = TimeInterval(distance / barrierSpeed)
    let moveLeft = SKAction.moveBy(x: distance, y: 0, duration: time)
    let anim = SKAction.sequence([
      moveLeft,
      SKAction.removeFromParent()
      ])
    pipeUP.run(anim, withKey: pipeAnimKey)
    pipeDowm.run(anim, withKey: pipeAnimKey)
    pipeUP2.run(anim, withKey: pipeAnimKey)
    pipeDowm2.run(anim, withKey: pipeAnimKey)
    worldNode.addChild(pipeDowm)
    worldNode.addChild(pipeUP)
    worldNode.addChild(pipeDowm2)
    worldNode.addChild(pipeUP2)
  }
  
  fileprivate func detactIsPassed(){
    worldNode.enumerateChildNodes(withName: "pipe") { (node, _) in
      
      guard let number = node.userData?["isPassed"] as? NSNumber else { return }
      guard self.gameState != .fall else { return }
      guard number.boolValue == false else { return }
      
      if self.bird.position.x >= node.position.x + node.frame.width/2{
        node.userData?.setValue(NSNumber(value: true as Bool), forKey: "isPassed")
        self.score += 1
        let bigger = SKAction.scale(to: 1.3, duration: 0.3)
        bigger.timingMode = .easeInEaseOut
        let smaller = SKAction.scale(to: 1.0, duration: 0.3)
        smaller.timingMode = .easeInEaseOut
        self.scoreLabel.run(SKAction.sequence([bigger, smaller]))
        self.randomMo()
      }
    }
  }
  
  fileprivate func randomMo(){
    let rnd = Int(CGFloat.random(min: 0, max: 6))
    self.run(mo[rnd])
  }
  
  fileprivate func createPipeNodes(_ texture: SKTexture) -> SKSpriteNode{
    texture.filteringMode = .nearest
    let pipe = SKSpriteNode(texture: texture)
    pipe.setScale(2.0)
    pipe.physicsBody = SKPhysicsBody(rectangleOf: pipe.size)
    pipe.physicsBody?.isDynamic = false
    pipe.zPosition = Layer.barrier.rawValue
    pipe.physicsBody?.categoryBitMask = pipeCategory
    pipe.physicsBody?.collisionBitMask = birdCategory
    pipe.physicsBody?.contactTestBitMask = birdCategory
    pipe.name = "pipe"
    return pipe
  }
  
  //MARK: - GameState
  fileprivate func turnToReadyState(){
    gameState = .ready
    backgroundConfig()
    birdConfig()
  }
  
  fileprivate func turnToGameState(){
    gameState = .game
    bird.removeAction(forKey: birdUpDowmAnimKey)
    physicsWorld.gravity = CGVector(dx: 0, dy: -5)
    letBirdFly()
    barrierConfig()
  }
  
  fileprivate func turn2FallState(){
    gameState = .fall
    run(fallingSound)
    stopAnimation()
    bird.run(SKAction.rotate(byAngle: CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration:1), completion:{self.bird.speed = 0 })
    bird.physicsBody?.collisionBitMask = landCategory
  }
  
  fileprivate func stopAnimation(){
    self.removeAction(forKey: pipeAnimKey)
    bird.removeAction(forKey: birdWingAnimKey)
    worldNode.enumerateChildNodes(withName: "pipe") { (pipes, _) in
      pipes.removeAction(forKey: self.pipeAnimKey)
    }
    worldNode.enumerateChildNodes(withName: "sky") { (sky, _) in
      sky.removeAction(forKey: self.skyMoveAnimKey)
    }
    worldNode.enumerateChildNodes(withName: "land") { (land, _) in
      land.removeAction(forKey: self.landAnimKey)
    }

  }
  
  fileprivate func turn2EndState(){
    stopAnimation()
    run(hitGroundSound)
    gameState = .end
  }
  
  //MARK: - SKScene Method
  //swift3.0 从 didMoveToView  改成了didMove  妈的
  override func didMove(to view: SKView) {
    /* Setup your scene here */
    physicsWorld.gravity = CGVector(dx: 0.0, dy: 0)
    physicsWorld.contactDelegate = self
    addChild(worldNode)
    turnToReadyState()
  }
  
  func didBegin(_ contact: SKPhysicsContact) {
    let beContactObject = contact.bodyA.categoryBitMask == birdCategory ? contact.bodyB : contact.bodyA
    //砸到ground后 不能弹起后 再次撞到pipe 而改变状态
    if beContactObject.categoryBitMask == pipeCategory && gameState != .fall && gameState != .end{
      turn2FallState()
      
    } else if beContactObject.categoryBitMask == landCategory && gameState != .end{
      turn2EndState()
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
  
  fileprivate func restart(){
    let newScene = GameScene.init(size: size)
    newScene.scaleMode = .aspectFill
    let transEffect = SKTransition.fade(with: self.backgroundColor, duration: 0.03)
    view?.presentScene(newScene, transition: transEffect)
  }
  
  override func update(_ currentTime: TimeInterval) {
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
  static func random(min: CGFloat, max: CGFloat) -> CGFloat{
    guard  min < max else { return 0 }
    return CGFloat(arc4random())/CGFloat(UInt32.max) * (max - min) + min
  }
}
