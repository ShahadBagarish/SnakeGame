//
//  SnakeGameState.swift
//  SnakeGame
//
//  Created by Shahad on 16/11/2026.
//


import Foundation
import CoreGraphics

enum SnakeDirection {
    case up
    case down
    case left
    case right
}

@MainActor
@Observable
final class SnakeGameState {
    
    
    var humanPlayer = SnakePlayer(
        type: .human,
        body: [
            CGPoint(x: 3, y: 8),
            CGPoint(x: 2, y: 8),
            CGPoint(x: 1, y: 8)
        ],
        direction: .right
    )

    var aiPlayer = SnakePlayer(
        type: .ai,
        body: [
            CGPoint(x: 7, y: 4),
            CGPoint(x: 7, y: 5),
            CGPoint(x: 7, y: 6)
        ],
        direction: .up
    )


    let gridSize = 10
    
    var  snake = [
        CGPoint(x: 4, y: 5),
        CGPoint(x: 3, y: 5),
        CGPoint(x: 2, y: 5)
    ]


    var food = CGPoint(x: 5, y: 5)

    var direction: SnakeDirection = .right

    var isGameOver = false
    
    var winner: SnakePlayerType? = nil

    var score = 0
    
    
    var totalPredictions = 0
    var safetyOverrides = 0

    var interventionRate: Double {
        guard totalPredictions > 0 else {
            return 0
        }

        return Double(safetyOverrides) /
               Double(totalPredictions) * 100
    }
    
    var safetyEnabled = true
    
    func makeModelInput() -> [Float] {
        let features = encodeGameState()

        guard features.count == 16 else {
            return []
        }

        // Match the Python training representation:
        // [1 batch, 5 repeated states, 16 features]
        
        let input = Array(
            repeating: features,
            count: 5
        ).flatMap { $0 }

        return input
    }

    func makeAIPlayerInput() -> [Float] {

        guard let head = aiPlayer.head else {
            return []
        }

        let scale = Float(gridSize - 1)

        // AI snake head position
        let snakeX = Float(head.x) / scale
        let snakeY = Float(head.y) / scale

        // Shared food position
        let foodX = Float(food.x) / scale
        let foodY = Float(food.y) / scale

        // Relative food direction
        let dx = foodX - snakeX
        let dy = foodY - snakeY

        // Preserve the original 16-feature ordering
        let features: [Float] = [
            snakeY,
            1 - snakeY,
            snakeX,
            1 - snakeX,
            dx,
            dy,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0
        ]

        // Preserve the model's [1, 5, 16] input shape
        return Array(
            repeating: features,
            count: 5
        ).flatMap { $0 }
    }
    
    func encodeGameState() -> [Float] {
        guard let head = snake.first else {
            return []
        }

        let scale = Float(gridSize - 1)

        let snakeX = Float(head.x) / scale
        let snakeY = Float(head.y) / scale

        let foodX = Float(food.x) / scale
        let foodY = Float(food.y) / scale

        let dx = foodX - snakeX
        let dy = foodY - snakeY

        let features: [Float] = [
            snakeY,
            1 - snakeY,
            snakeX,
            1 - snakeX,
            dx,
            dy,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0
        ]

        return features
    }

    func moveOneStep() {
        guard !isGameOver else {
            print("Game is over. Movement blocked.")
            return
        }
        
        guard let head = snake.first else {
            return
        }

        var newHead = head

        switch direction {
        case .up:
            newHead.y -= 1
        case .down:
            newHead.y += 1
        case .left:
            newHead.x -= 1
        case .right:
            newHead.x += 1
        }

        // Temporary behavior:
        // Wrap around board edges.
        newHead.x = (
            newHead.x + CGFloat(gridSize)
        ).truncatingRemainder(
            dividingBy: CGFloat(gridSize)
        )

        newHead.y = (
            newHead.y + CGFloat(gridSize)
        ).truncatingRemainder(
            dividingBy: CGFloat(gridSize)
        )

        
        let willEatFood = newHead == food

        // If the snake is not eating, its tail moves away.
        // Therefore, exclude the tail from collision detection.
        let occupiedBody = willEatFood
            ? Array(snake.dropFirst())
            : Array(snake.dropFirst().dropLast())

        if occupiedBody.contains(newHead) {
            isGameOver = true
            print("💥 Game Over! Snake hit itself.")
            return
        }

        
        snake.insert(newHead, at: 0)

        
        if newHead == food {
            // Increase score when food is eaten
            score += 10

            print("🍎 Food eaten!")
            print("Score:", score)
            print("Snake length:", snake.count)

            spawnFood()
        
        } else {
            // Normal movement: remove the tail.
            snake.removeLast()
        }

        print("Snake head:", newHead)

    }
    
    func spawnFood() {
        var emptyCells: [CGPoint] = []

        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let cell = CGPoint(x: x, y: y)

                // Only include cells not occupied by the snake.
                if !humanPlayer.body.contains(cell) &&
                   !aiPlayer.body.contains(cell) {
                    emptyCells.append(cell)
                }            }
        }

        guard let newFood = emptyCells.randomElement() else {
            print("🏆 Board full! Snake wins!")
            return
        }

        food = newFood

        print("🍎 New food:", food)
    }
    
    
    func restartGame() {
        // Reset snake to its original position
        snake = [
            CGPoint(x: 4, y: 5),
            CGPoint(x: 3, y: 5),
            CGPoint(x: 2, y: 5)
        ]

        // Reset movement direction
        direction = .right

        // Reset Game Over state
        isGameOver = false

        // Generate new food in an empty cell
        spawnFood()
        totalPredictions = 0
        safetyOverrides = 0
        
        print("🔄 Game restarted!")
        print("Snake length:", snake.count)
    }
    
    
    func restartCompetition() {

        // Reset the human snake
        humanPlayer = SnakePlayer(
            type: .human,
            body: [
                CGPoint(x: 3, y: 8),
                CGPoint(x: 2, y: 8),
                CGPoint(x: 1, y: 8)
            ],
            direction: .right
        )

        // Reset the Core AI snake
        aiPlayer = SnakePlayer(
            type: .ai,
            body: [
                CGPoint(x: 7, y: 4),
                CGPoint(x: 7, y: 5),
                CGPoint(x: 7, y: 6)
            ],
            direction: .up
        )

        // Reset game status
        isGameOver = false
        winner = nil

        // Reset inference and safety metrics
        totalPredictions = 0
        safetyOverrides = 0

        // Generate new food
        spawnFood()

        print("🔄 Competition restarted")
        print("🔵 Human score:", humanPlayer.score)
        print("🔴 AI score:", aiPlayer.score)
    }

    
    func isReverseDirection(
        _ proposedDirection: SnakeDirection
    ) -> Bool {

        switch (direction, proposedDirection) {

        case (.up, .down),
             (.down, .up),
             (.left, .right),
             (.right, .left):
            return true

        default:
            return false
        }
    }
    
    func isSafeMove(_ proposedDirection: SnakeDirection) -> Bool {

        guard !isGameOver, let head = snake.first else {
            return false
        }

        // Reject immediate reversal
        if isReverseDirection(proposedDirection) {
            return false
        }

        // Calculate the proposed next position
        var nextHead = head

        switch proposedDirection {
        case .up:
            nextHead.y -= 1
        case .down:
            nextHead.y += 1
        case .left:
            nextHead.x -= 1
        case .right:
            nextHead.x += 1
        }

        // Apply the same wrapping rules as moveOneStep()
        let size = CGFloat(gridSize)

        nextHead.x = (nextHead.x + size)
            .truncatingRemainder(dividingBy: size)

        nextHead.y = (nextHead.y + size)
            .truncatingRemainder(dividingBy: size)

        // The tail moves away unless food is eaten
        let willEatFood = nextHead == food

        let occupiedBody = willEatFood
            ? Array(snake.dropFirst())
            : Array(snake.dropFirst().dropLast())

        // Safe if the destination is not occupied
        return !occupiedBody.contains(nextHead)
    }
    
    func isSafeMove(
        _ proposedDirection: SnakeDirection,
        for player: SnakePlayer
    ) -> Bool {

        guard !isGameOver,
              let head = player.head else {
            return false
        }

        // 1. Prevent immediate reversal
        let isReverse: Bool

        switch (player.direction, proposedDirection) {
        case (.up, .down),
             (.down, .up),
             (.left, .right),
             (.right, .left):
            isReverse = true

        default:
            isReverse = false
        }

        if player.body.count > 1 && isReverse {
            return false
        }

        // 2. Calculate the next head position
        var nextHead = head

        switch proposedDirection {
        case .up:
            nextHead.y -= 1

        case .down:
            nextHead.y += 1

        case .left:
            nextHead.x -= 1

        case .right:
            nextHead.x += 1
        }

        // 3. Apply board wrapping
        let size = CGFloat(gridSize)

        nextHead.x = (nextHead.x + size)
            .truncatingRemainder(dividingBy: size)

        nextHead.y = (nextHead.y + size)
            .truncatingRemainder(dividingBy: size)

        // 4. Account for the moving tail
        let willEatFood = nextHead == food

        let occupiedBody = willEatFood
            ? Array(player.body.dropFirst())
            : Array(player.body.dropFirst().dropLast())

        // 5. Reject self-collision
        return !occupiedBody.contains(nextHead)
    }
    
    
    func wouldHitOpponent(
        _ proposedDirection: SnakeDirection,
        for player: SnakePlayer
    ) -> Bool {

        guard let head = player.head else {
            return false
        }

        // 1. Calculate the proposed next position
        var nextHead = head

        switch proposedDirection {
        case .up:
            nextHead.y -= 1
        case .down:
            nextHead.y += 1
        case .left:
            nextHead.x -= 1
        case .right:
            nextHead.x += 1
        }

        // 2. Apply board wrapping
        let size = CGFloat(gridSize)

        nextHead.x = (nextHead.x + size)
            .truncatingRemainder(dividingBy: size)

        nextHead.y = (nextHead.y + size)
            .truncatingRemainder(dividingBy: size)

        // 3. Identify the opponent
        let opponent: SnakePlayer

        switch player.type {
        case .human:
            opponent = aiPlayer
        case .ai:
            opponent = humanPlayer
        }

        // 4. Check for collision
        return opponent.body.contains(nextHead)
    }


    func printSessionSummary() {

        print("========== AI SESSION SUMMARY ==========")

        print("Final score:", score)
        print("Total predictions:", totalPredictions)
        print("Safety overrides:", safetyOverrides)

        print(
            String(
                format: "Intervention rate: %.1f%%",
                interventionRate
            )
        )

        print("Game over:", isGameOver)

        print("========================================")
    }
    
    func moveHumanOneStep() {

        guard !isGameOver,
              let head = humanPlayer.head else {
            return
        }

        // 1. Calculate the next position
        var nextHead = head

        switch humanPlayer.direction {
        case .up:
            nextHead.y -= 1
        case .down:
            nextHead.y += 1
        case .left:
            nextHead.x -= 1
        case .right:
            nextHead.x += 1
        }

        // 2. Wrap around the board
        let size = CGFloat(gridSize)

        nextHead.x = (nextHead.x + size)
            .truncatingRemainder(dividingBy: size)

        nextHead.y = (nextHead.y + size)
            .truncatingRemainder(dividingBy: size)

        // 3. Check whether the human eats food
        let willEatFood = nextHead == food

        // 4. Move the snake forward
        humanPlayer.body.insert(nextHead, at: 0)

        if willEatFood {

            // Keep the tail so the snake grows
            humanPlayer.score += 10

            print("🔵 Human ate food!")
            print("🔵 Human score:", humanPlayer.score)
            print("🔵 Human length:", humanPlayer.body.count)

            spawnFood()

        } else {

            // Normal movement: remove the tail
            humanPlayer.body.removeLast()
        }

        print("🔵 Human moved to:", nextHead)
    }

    func moveAIPlayerOneStep() {

        guard !isGameOver,
              let head = aiPlayer.head else {
            return
        }

        // 1. Calculate the AI's next position
        var nextHead = head

        switch aiPlayer.direction {
        case .up:
            nextHead.y -= 1
        case .down:
            nextHead.y += 1
        case .left:
            nextHead.x -= 1
        case .right:
            nextHead.x += 1
        }

        // 2. Wrap around board edges
        let size = CGFloat(gridSize)

        nextHead.x = (nextHead.x + size)
            .truncatingRemainder(dividingBy: size)

        nextHead.y = (nextHead.y + size)
            .truncatingRemainder(dividingBy: size)

        // 3. Check whether the AI eats food
        let willEatFood = nextHead == food

        // 4. Move the AI snake forward
        aiPlayer.body.insert(nextHead, at: 0)

        if willEatFood {

            // Keep the tail so the AI snake grows
            aiPlayer.score += 10

            print("🔴 AI ate food!")
            print("🔴 AI score:", aiPlayer.score)
            print("🔴 AI length:", aiPlayer.body.count)

            // Generate new shared food
            spawnFood()

        } else {

            // Normal movement: remove the tail
            aiPlayer.body.removeLast()
        }

        print("🔴 AI moved to:", nextHead)
    }


}
