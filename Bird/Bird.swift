//
//  Flyer.swift
//  Bird
//
//  Created by Roman Vakulenko on 10.09.2022.
//

import SpriteKit

class Bird: SKSpriteNode {
    var velocity = CGPoint.zero
    var baseY: CGFloat = 0.0
    var flyUpSpeed: CGFloat = 28.0
    var isOnPosition = true //Если да, то она может подняться вверх
    
    func setupPhysicsBody() {
        if let birdTexture = texture { //поскольку texture — это опционал SKSpriteNode
            physicsBody = SKPhysicsBody(texture: birdTexture, size: size)
            physicsBody?.isDynamic = true//физДвижок будет управлять движением объекта; false - если не хотим, чтобы объект перемещался саморпоизвольно из-за столкновений/гравитации
            physicsBody?.affectedByGravity = false
            physicsBody?.density = 5.0
            physicsBody?.allowsRotation = false
            physicsBody?.angularDamping = 1.0//насколько сильно объект сопротивляется вращению. Меньшее значение позволяет объекту вращаться свободнее, высокое - напротив - сложнее вращаться
            physicsBody?.categoryBitMask = PhysicsCategory.bird
            physicsBody?.collisionBitMask = PhysicsCategory.monster//чтобы на птицу влияли столкновения с монстрами, и что она должна от них отталкиваться(?)
            physicsBody?.contactTestBitMask = PhysicsCategory.monster | PhysicsCategory.cherry//хотим уведомление, когда будет контакт с тем или иным объектом; пайп | (от pipe — «труба»), позволяет сохранить сразу множество значений в одном свойстве
        }
    }
    
    func createSparks() {
        let bundle = Bundle.main
        if let sparksPath = bundle.path(forResource: "Spark", ofType: "sks") {
            let sparksNode = NSKeyedUnarchiver.unarchiveObject(withFile: sparksPath) as! SKEmitterNode
            sparksNode.position = CGPoint(x: 0.0, y: 0.0)
            addChild(sparksNode)
            
            let waitAction = SKAction.wait(forDuration: 0.5)
            let removeAction = SKAction.removeFromParent()
            let waitThenRemove = SKAction.sequence([waitAction,removeAction])
            sparksNode.run(waitThenRemove)
        }
    }
}
