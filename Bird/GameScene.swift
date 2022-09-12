//
//  GameScene.swift
//  Skateboarder
//
//  Created by Roman Vakulenko on 10.09.2022.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    var monsters = [SKSpriteNode]()//cоздает класс под названием monsters, связывая его с пустым массивом спрайтов (поскольку наши секции будут спрайтами).
    var monsterSize = CGSize.zero
    var scrollSpeed: CGFloat = 5.0//скорость прокрутки бэка, может увеличиваться по мере продвижения
    var gravitySpeed: CGFloat = 1.5
    var lastUpdateTime: TimeInterval?//время последнего вызова для метода обновления (для отслеживания момента, когда произошло последнее обновление) - чтобы птица двигалась плавно
    
    let bird = Bird(imageNamed: "opt_bird1")
    
    override func didMove(to view: SKView) {
        anchorPoint = CGPoint.zero //точка привязки, определяющая, как и где будут позиционироваться в сцене спрайты
        
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
        addChild(bird)
        resetBird()
        
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
//        tapGesture.numberOfTapsRequired = 1
//        tapGesture.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tapGesture)
//        view.isUserInteractionEnabled = true
    }
    
    func resetBird () {
        let birdX = frame.midX / 2.0
        let birdY = bird.frame.height + 64.0
        bird.position = CGPoint(x: birdX, y: birdY)
        bird.zPosition = 10
        bird.baseY = birdY
    }
    
    func spawnMonster (atPosition position: CGPoint) -> SKSpriteNode {
        let monster = SKSpriteNode(imageNamed: "opt_skeleton-fly_00")
        monster.position = position
        monster.zPosition = 8
        addChild(monster)
        monsterSize = monster.size //задаем реальное значание размера картинки монстра
        monsters.append(monster)
        return monster
    }
    
    func updateMonsters(withScrollAmount currentScrollAmount: CGFloat) {//заполнение монстрами
        var farthestRightMonsterX: CGFloat = 0.0
        
        for monster in monsters {
            let newX = monster.position.x - currentScrollAmount
            
            if newX < -monsterSize.width {//если монстр ушел за экран слева, то удалим его
                monster.removeFromParent()
                //находится ли монстр в массиве монстров, ищем его индекс и, если находим - удаляем
                if let monsterIndex = monsters.firstIndex(of: monster) {
                    monsters.remove(at: monsterIndex)
                }
            } else {
                //для монстра, оставшемся на экране, обновим положение
                monster.position = CGPoint(x: newX, y: monster.position.y)
                //для крайнего правого монстра обновляем значение
                if monster.position.x > farthestRightMonsterX {
                    farthestRightMonsterX = monster.position.x
                }
            }
        }
        
        while farthestRightMonsterX < frame.width {
            var monsterX = farthestRightMonsterX + 10 * monsterSize.width //1 - для разрыва
            let monsterY = monsterSize.height + 40
            
            let randomNumber = arc4random_uniform(99)
            if randomNumber < 5 {
                let gap = 20 * scrollSpeed
                monsterX += gap
            }
            
            let newMonster = spawnMonster(atPosition: CGPoint(x: monsterX, y: monsterY))
            farthestRightMonsterX = newMonster.position.x
        }
    }
    
    func updateBird() {
        if !bird.isOnMonsterLine {
            let velocityY = bird.velocity.y - gravitySpeed//взлет начинается с бОльшей положительной скорости. Затем гравитация будет понемногу снижать эту скорость, пока птица не достигнет пика своего взлета. После этого скорость станет отрицательной, и птица начнет снижаться
            bird.velocity = CGPoint(x: bird.velocity.x, y: velocityY)//обновляем скорость
            let newBirdY: CGFloat = bird.position.y + bird.velocity.y//значение скорости добавим кПозY
            bird.position = CGPoint(x: bird.position.x, y: newBirdY)// нов положение птицы
            
            if bird.position.y < bird.baseY - 20 {//как только птица снизилась ниже базовой точки, то:
                bird.position.y = bird.baseY //возвращается к базовой высоте
                bird.velocity = CGPoint.zero//зависает
                bird.isOnMonsterLine = true
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {// Called before each frame is rendered
        //определяем время, прошедшее с момента последнего вызова метода update
        var elapsedTime: TimeInterval = 0.0 // прошедшее в сек
        
        if let lastTimeStamp = lastUpdateTime {//распаковываем опционал, тк в начале игры нет послВремОбновления
            elapsedTime = currentTime - lastTimeStamp
            //корректируем скорость обновления/перемещения
            let expectedElapsedTime: TimeInterval = 1.0 / 80.0 //ожидаем обновление 80 кадров в секунду
            let scrollAdjustment = CGFloat (elapsedTime / expectedElapsedTime)
            let currentScrollAmount = scrollSpeed * scrollAdjustment //скорость перемещения для обновления
            
            updateMonsters(withScrollAmount: currentScrollAmount)
            updateBird()
        }
        lastUpdateTime = currentTime
    }
    
    @objc func handleTap (tapGesture: UITapGestureRecognizer) {
        if bird.isOnMonsterLine {
            bird.velocity = CGPoint(x: 0.0, y: bird.flyUpSpeed)//птица взлетает над монстрами
            bird.isOnMonsterLine = false
        }
    }
}
