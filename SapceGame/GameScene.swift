//
//  GameScene.swift
//  SapceGame
//
//  Created by Michele Manniello on 28/02/21.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene,SKPhysicsContactDelegate {
    var starfield : SKEmitterNode!
    var player : SKSpriteNode!
    var socoreLabel : SKLabelNode!
    var score : Int = 0{
        didSet{
            socoreLabel.text = "Score \(score)"
        }
    }
    var gameTimer : Timer!
    var possbileAliens = ["alien","alien2","alien3"]
    let allienCategory: UInt32 = 0x1 << 1
    let photonTorpedCategory : UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat =  0
    
    override func didMove(to view: SKView) {
//        Assegnamo lo sfondo
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0, y: self.frame.height)
        starfield.advanceSimulationTime(10)
        addChild(starfield)
//        per farlo stare sotto 
        starfield.zPosition = -1
//        inizializzamo il player
        player = SKSpriteNode(imageNamed: "shuttle")
        print(self.frame.height)
        player.position = CGPoint(x: 0, y: self.frame.height / 2 * -1  + 30)
        addChild(player)
//        togliamo la gravità
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        socoreLabel = SKLabelNode(text: "Score 0")
        print("alteza \(self.frame.size.height / 2 - 60)")
        socoreLabel.position = CGPoint(x: -(self.size.width / 3), y: (self.frame.size.height/2)-60)
        socoreLabel.fontName = "AmericanTypewriter-Bold"
        socoreLabel.fontSize = 36
        socoreLabel.fontColor = UIColor.white
        score = 0
        addChild(socoreLabel)
        
//        Creamo i nemici
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
//        movimento
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, err) in
            if let acceloerometerData = data{
                let acceleration = acceloerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
                
            }
        }
        
    }
    @objc func addAlien() {
//        Devo trovare la metà per la posizone x
        let metà = self.size.width / 2
        print("metà = \(metà)")
        possbileAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possbileAliens) as! [String]
        let alien = SKSpriteNode(imageNamed: possbileAliens[0])
//        diffrenti posizoni
        let randomAllienPosition = GKRandomDistribution(lowestValue: -Int(metà), highestValue: Int(metà))
        let position = CGFloat(randomAllienPosition.nextInt())
        print("posizione \(position)")
//
        alien.position = CGPoint(x:   position , y:  self.frame.size.height + alien.size.height)
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        alien.physicsBody?.categoryBitMask = allienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedCategory
        alien.physicsBody?.collisionBitMask = 0
        self.addChild(alien)
        let animationDuration : TimeInterval = 6
        var actionArray = [SKAction]()
//        -alien.size.height
        actionArray.append(SKAction.move(to: CGPoint(x: position,y: -self.frame.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(actionArray))
        
        
        
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    func fireTorpedo(){
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedCategory
        torpedoNode.physicsBody?.contactTestBitMask = allienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        self.addChild(torpedoNode)
        let animationDuration : TimeInterval = 0.3
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x ,y: self.frame.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        torpedoNode.run(SKAction.sequence(actionArray))
    }
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody : SKPhysicsBody
        var secondBody : SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & photonTorpedCategory) != 0 && (secondBody.categoryBitMask & allienCategory) != 0{
            torpedoDidCollideWithAllien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    func torpedoDidCollideWithAllien(torpedoNode: SKSpriteNode, alienNode: SKSpriteNode){
        let explosion = SKEmitterNode(fileNamed: "Explosion")
        explosion?.position = alienNode.position
        self.addChild(explosion!)
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion?.removeFromParent()
        }
        score += 5
        
    }
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 50
        if player.position.x < -(self.size.width / 2){
            player.position = CGPoint(x: self.size.width + 20 , y: player.position.y)
        }else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
