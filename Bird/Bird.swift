//
//  Flyer.swift
//  Bird
//
//  Created by Roman Vakulenko on 10.09.2022.
//

import SpriteKit

class Bird: SKSpriteNode {
    var velocity = CGPoint.zero // тоже что и CGPoint(x: 0.0, y: 0.0)
    var baseY: CGFloat = 0.0
    var flyUpSpeed: CGFloat = 28.0
    var isOnMonsterLine = true //Если да, то она может подняться вверх
}
