//
//  GameScene.swift
//  Skateboarder
//
//  Created by Roman Vakulenko on 10.09.2022.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let bird: UInt32 = 0x1 << 0
    static let monster: UInt32 = 0x1 << 1
    static let cherry: UInt32 = 0x1 << 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    enum GameState {
        case notRunning
        case running
    }
    var gameState = GameState.notRunning
    
    var score: Int = 0
    var highScore: Int = 0
    var lastScoreUpdateTime: TimeInterval = 0.0
    
    var cherries = [SKSpriteNode]()
    var monsters = [SKSpriteNode]()//cоздает класс под названием monsters, связывая его с пустым массивом спрайтов (поскольку наши секции будут спрайтами).
    var monsterSize = CGSize.zero
    var scrollSpeed: CGFloat = 5.0//скорость прокрутки бэка, может увеличиваться по мере продвижения
    let startingScrollSpeed: CGFloat = 5.0
    var gravitySpeed: CGFloat = 1.5
    var lastUpdateTime: TimeInterval?//время последнего вызова для метода обновления (для отслеживания момента, когда произошло последнее обновление) - чтобы птица двигалась плавно
    
    var bird = Bird(imageNamed: "opt_bird1")
    let birdGameOver = Bird(imageNamed: "broken2")
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)//комбинация величины и направления(тянет вниз по-мультяшному на -6, когда гравитация земли -9.8)
        physicsWorld.contactDelegate = self//в этом классе будет отражаться информация обо всех контактах
        anchorPoint = CGPoint.zero //точка привязки, определяющая, как и где будут позиционироваться в сцене спрайты
        
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
        addChild(bird)
        
        setupLabels()
        bird.setupPhysicsBody()
        
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        menuLayer.position = CGPoint(x: 0.0, y: 0.0)
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Press to play", score: nil)
        addChild(menuLayer)
    }
    
    func resetBird () {
        let birdX = frame.midX / 2.0
        let birdY = bird.frame.height + 45.0
        bird.position = CGPoint(x: birdX, y: birdY)
        bird.zPosition = 10
        bird.baseY = birdY
        
        bird.zRotation = 0.0
        bird.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        bird.physicsBody?.angularVelocity = 0.0
    }
    
    func setupLabels() {
        let scoreTextLabel: SKLabelNode = SKLabelNode(text: "очки")
        scoreTextLabel.position = CGPoint(x: 14.0, y: frame.size.height - 20.0)
        scoreTextLabel.horizontalAlignmentMode = .left //выравнивание
        scoreTextLabel.fontName = "Courier-Bold"
        scoreTextLabel.fontSize = 14.0
        scoreTextLabel.zPosition = 20
        addChild(scoreTextLabel)
        
        let scoreLabel: SKLabelNode = SKLabelNode(text: "0")
        scoreLabel.position = CGPoint(x: 14.0, y: frame.size.height - 40.0)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontName = "Courier-Bold"
        scoreLabel.fontSize = 18.0
        scoreLabel.name = "scoreLabel" //имя для обращения далее в приложении
        scoreLabel.zPosition = 20
        addChild(scoreLabel)
        
        let highScoreTextLabel: SKLabelNode = SKLabelNode(text: "лучший результат")
        highScoreTextLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 20.0)
        highScoreTextLabel.horizontalAlignmentMode = .right
        highScoreTextLabel.fontName = "Courier-Bold"
        highScoreTextLabel.fontSize = 14.0
        highScoreTextLabel.zPosition = 20
        addChild(highScoreTextLabel)
        
        let highScoreLabel: SKLabelNode = SKLabelNode(text: "0")
        highScoreLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 40.0)
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.fontName = "Courier-Bold"
        highScoreLabel.fontSize = 18.0
        highScoreLabel.name = "highScoreLabel"
        highScoreLabel.zPosition = 20
        addChild(highScoreLabel)
    }
    
    func updateScoreLabelText() {
        if let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode {//находим дочерний узел сцены с именем "scoreLabel"
            scoreLabel.text = String(format: "%04d", score)// % показывает, что мы добавляем переменную, 04 уточняет, что мы хотим видеть в строке четыре цифры с нулями в начале, а d — что выводимая переменная имеет тип целого числа
        }
    }
    
    func updateHighScoreLabelText() {
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            highScoreLabel.text = String(format: "%04d", highScore)
        }
    }
    
    func startGame() {
        gameState = .running
        resetBird()
        score = 0
        scrollSpeed = startingScrollSpeed
        lastUpdateTime = nil
        
        for monster in monsters {
            monster.removeFromParent()
        }
        monsters.removeAll(keepingCapacity: true)
        
        for cherry in cherries {
            removeCherry(cherry)
        }
    }
    
    func gameOver() {
        gameState = .notRunning
        
        if score > highScore {
            highScore = score
            updateHighScoreLabelText()
        }
        
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor,size: frame.size)
        menuLayer.anchorPoint = CGPoint.zero
        menuLayer.position = CGPoint.zero
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Game over, press for new game", score: score)
        addChild(menuLayer)
    }
    
    func spawnMonster (atPosition position: CGPoint) -> SKSpriteNode {
        let monster = SKSpriteNode(imageNamed: "opt_skeleton-fly_00")
        monster.position = position
        monster.zPosition = 8
        addChild(monster)
        monsterSize = monster.size //задаем реальное значание размера картинки монстра
        monsters.append(monster)
        //настройка физТела монстра
        let center = monster.centerRect.origin
        monster.physicsBody = SKPhysicsBody(circleOfRadius: 15, center: center)//создает физТело и присоединяет его к спрайту monster
        monster.physicsBody?.affectedByGravity = false
        monster.physicsBody?.categoryBitMask = PhysicsCategory.monster
        monster.physicsBody?.collisionBitMask = 0//0 сообщает SpriteKit, что монстры не должны сталкиваться с чем-либо еще
        return monster
    }
    
    func spawnCherry(atPosition position: CGPoint) {
        let cherry = SKSpriteNode(imageNamed: "cherry")
        cherry.position = position
        cherry.zPosition = 9
        addChild(cherry)
        cherry.physicsBody = SKPhysicsBody(rectangleOf: cherry.size, center: cherry.centerRect.origin)
        cherry.physicsBody?.categoryBitMask = PhysicsCategory.cherry
        cherry.physicsBody?.affectedByGravity = false
        cherries.append(cherry)
    }
    
    func removeCherry (_ cherry: SKSpriteNode) {
        cherry.removeFromParent() //вишня исчезает с экрана, но остается в массиве
        if let cherryIndex = cherries.firstIndex(of: cherry) { //найдем индекс и удалим вишню
            cherries.remove(at: cherryIndex)
        }
    }
    
    func updateMonsters(withScrollAmount currentScrollAmount: CGFloat) {//заполнение монстрами
        var farthestRightMonsterX: CGFloat = 0.0
        
        for monster in monsters {
            let newX = monster.position.x - currentScrollAmount
            
            if newX < -0.0 {//если монстр ушел за экран слева, то удалим его
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
            var monsterX = farthestRightMonsterX + 10 * monsterSize.width
            let monsterY = CGFloat(arc4random_uniform(400))
            
            let randomNumber = arc4random_uniform(99)
            if randomNumber < 50 {
                let gap = 20 * scrollSpeed
                monsterX += gap
                
                let newCherryY = CGFloat(arc4random_uniform(300))
                let newCherryX = monsterX - gap
                
                spawnCherry(atPosition: CGPoint(x: newCherryX, y: newCherryY))
            }
            
            let newMonster = spawnMonster(atPosition: CGPoint(x: monsterX, y: monsterY))
            farthestRightMonsterX = newMonster.position.x
        }
    }
    
    func updateCherries (withScrollAmount currentScrollAmount: CGFloat) {
        for cherry in cherries {
            //обновляем положение каждой вишни
            let thisCherryX = cherry.position.x - currentScrollAmount
            cherry.position = CGPoint(x: thisCherryX, y: cherry.position.y)
            
            if cherry.position.x < 0.0 {//удаляем вишни, ушедшие с экрана
                removeCherry(cherry)
            }
        }
    }
    
    func updateBird() {
        if !bird.isOnPosition {
            let velocityY = bird.velocity.y - gravitySpeed//взлет начинается с бОльшей положительной скорости. Затем гравитация будет понемногу снижать эту скорость, пока птица не достигнет пика своего взлета. После этого скорость станет отрицательной, и птица начнет снижаться
            bird.velocity = CGPoint(x: bird.velocity.x, y: velocityY)//обновляем скорость
            let newBirdY: CGFloat = bird.position.y + bird.velocity.y//значение скорости добавим кПозY
            bird.position = CGPoint(x: bird.position.x, y: newBirdY)// нов положение птицы
            
            if bird.position.y < bird.baseY - 10 {//как только птица снизилась ниже базовой точки, то:
                bird.position.y = bird.baseY //возвращается к базовой высоте
                bird.velocity = CGPoint.zero//зависает
                bird.isOnPosition = true
            }
        }
    }
    
    func updateScore(withCurrentTime currentTime: TimeInterval) {
        let elapsedTime = currentTime - lastScoreUpdateTime
        if elapsedTime > 5.0 {
            score += 1
            lastScoreUpdateTime = currentTime
            updateScoreLabelText()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {// Called before each frame is rendered
        if gameState != .running {
            return
        }
        //определяем время, прошедшее с момента последнего вызова метода update
        var elapsedTime: TimeInterval = 0.0 // прошедшее в сек
        scrollSpeed += 0.005//увеличиваем с каждым вызовом update
        if let lastTimeStamp = lastUpdateTime {//распаковываем опционал, тк в начале игры нет послВремОбновления
            elapsedTime = currentTime - lastTimeStamp
            //корректируем скорость обновления/перемещения
            let expectedElapsedTime: TimeInterval = 1.0 / 60.0 //ожидаем обновление 60 кадров в секунду
            let scrollAdjustment = CGFloat (elapsedTime / expectedElapsedTime)
            let currentScrollAmount = scrollSpeed * scrollAdjustment //скорость перемещения для обновления
            
            updateMonsters(withScrollAmount: currentScrollAmount)
            updateBird()
            updateCherries(withScrollAmount: currentScrollAmount)
            updateScore(withCurrentTime: currentTime)
        }
        lastUpdateTime = currentTime
    }
    
    @objc func handleTap (tapGesture: UITapGestureRecognizer) {
        if gameState == .running {
            if bird.isOnPosition {
                bird.velocity = CGPoint(x: 0.0, y: bird.flyUpSpeed)
                run(SKAction.playSoundFileNamed("mario_doublejump.wav", waitForCompletion: false))
                bird.isOnPosition = false
            }
        } else {
            if let menuLayer: SKSpriteNode = childNode(withName: "menuLayer") as? SKSpriteNode {
                menuLayer.removeFromParent()
            }
            startGame()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == PhysicsCategory.bird && contact.bodyB.categoryBitMask == PhysicsCategory.monster {
//            addChild(birdGameOver)
//            birdGameOver.removeFromParent()
            gameOver()
        }
        else if contact.bodyA.categoryBitMask == PhysicsCategory.bird && contact.bodyB.categoryBitMask == PhysicsCategory.cherry {
            if let cherry = contact.bodyB.node as? SKSpriteNode {
                run(SKAction.playSoundFileNamed("collect.wav", waitForCompletion: false))
                removeCherry(cherry)
                score += 20
                updateScoreLabelText()
                bird.createSparks()
            }
        }
    }
}

