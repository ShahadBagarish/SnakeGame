//
//  ContentView.swift
//  SnakeGame
//
//  Created by Shahad on 16/11/2026.
//

import SwiftUI
import CoreAI

struct ContentView: View {
    
    let onGoHome: () -> Void
    @State private var game = SnakeGameState()
    @State private var isPlaying = false
    @State private var isPaused = false
    @State private var gameLoopTask: Task<Void, Never>?
    @State private var aiService = SnakeAIService()
    
    @State private var elapsedSeconds = 0
    
    private let blue = Color(
        red: 0.13, green: 0.35, blue: 0.84
    )
    
    private let red = Color(
        red: 0.66, green: 0.15, blue: 0.11
    )
    
    private let backgroundColor = Color(
        red: 0.96, green: 0.96, blue: 0.98
    )
    
    var body: some View {
        GeometryReader { geometry in
            
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            // Scale the UI to fit the available height
            let compact = screenHeight < 750
            
            let boardSize = min(
                screenWidth - 32,
                screenHeight * (compact ? 0.43 : 0.46)
            )
            
            let controlSize = min(
                76,
                max(48, screenHeight * 0.085)
            )
            
            let controlSpacing = min(
                80,
                max(24, screenWidth * 0.16)
            )
            
            VStack(spacing: 0) {
                
                // MARK: - Header
                
                HStack {
                    scorePill(
                        title: "You",
                        score: game.humanPlayer.score,
                        foreground: blue,
                        background: blue.opacity(0.11)
                    )
                    
                    Spacer()
                    
                    Button {
                        if isPlaying {
                            // Pause the current match
                            stopGameLoop()
                            isPaused = true

                        } else if isPaused {
                            // Resume the paused match
                            isPaused = false
                            startGameLoop()

                        } else if !game.isGameOver {
                            // Start a new match
                            startGameLoop()
                        }
                    } label: {
                        Image(
                            systemName: isPlaying
                            ? "pause.fill"
                            : "play.fill"
                        )
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 54, height: 54)
                        .background(.white)
                        .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    scorePill(
                        title: "AI",
                        score: game.aiPlayer.score,
                        foreground: red,
                        background: red.opacity(0.11)
                    )
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 8)
                
                // MARK: - Board
                
                CompetitionBoardView(game: game)
                    .frame(
                        width: boardSize,
                        height: boardSize
                    )
                
                // MARK: - Snake Labels
                
                HStack {
                    Text("User’s snake")
                        .foregroundStyle(blue)
                    
                    Spacer()
                    
                    Text("AI snake")
                        .foregroundStyle(red)
                }
                .font(.system(
                    size: 16,
                    weight: .bold,
                    design: .rounded
                ))
                .padding(.horizontal, 28)
                .padding(.top, 8)
                
                Spacer(minLength: 12)
                
                // MARK: - Speed and Timer
                
                HStack(spacing: 12) {
                    Text("Speed")
                        .font(.system(
                            size: 19,
                            weight: .bold,
                            design: .rounded
                        ))
                    
                    speedIndicator
                    
                    Spacer()
                    
                    Text(formattedTime)
                        .font(.system(
                            size: 21,
                            weight: .bold,
                            design: .rounded
                        ))
                        .monospacedDigit()
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
                
                Spacer(minLength: 12)
                
                // MARK: - Direction Controls
                
                VStack(spacing: 6) {
                    
                    directionButton(
                        "chevron.up",
                        direction: .up
                    )
                    .frame(
                        width: controlSize,
                        height: controlSize
                    )
                    
                    HStack(spacing: controlSpacing) {
                        directionButton(
                            "chevron.left",
                            direction: .left
                        )
                        .frame(
                            width: controlSize,
                            height: controlSize
                        )
                        
                        directionButton(
                            "chevron.right",
                            direction: .right
                        )
                        .frame(
                            width: controlSize,
                            height: controlSize
                        )
                    }
                    
                    directionButton(
                        "chevron.down",
                        direction: .down
                    )
                    .frame(
                        width: controlSize,
                        height: controlSize
                    )
                }
                
                Spacer(minLength: 8)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .background(backgroundColor)
        }
        .overlay {
            if game.isGameOver, let winner = game.winner {
                ZStack {
                    // Dim the existing game screen
                    Color.black.opacity(0.30)
                        .ignoresSafeArea()
                    
                    // Display the result panel
                    GameOverView(
                        winner: winner,
                        humanScore: game.humanPlayer.score,
                        aiScore: game.aiPlayer.score,
                        snakeLength: winner == .human
                        ? game.humanPlayer.body.count
                        : game.aiPlayer.body.count,
                        onPlayAgain: {
                            stopGameLoop()
                            game.restartCompetition()
                            elapsedSeconds = 0
                        },
                        
                        onHome: {
                            stopGameLoop()
                            onGoHome()
                        }
                    )
                    .padding(.horizontal, 16)
                }
            } else if isPaused {
                ZStack {
                    // Dim and blur the game behind the panel
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()

                    PauseView(
                        humanScore: game.humanPlayer.score,
                        aiScore: game.aiPlayer.score,
                        onResume: {
                            isPaused = false
                            startGameLoop()
                        },
                        onRestart: {
                            stopGameLoop()
                            game.restartCompetition()
                            elapsedSeconds = 0
                            isPaused = false

                            print("🔄 New competition ready")
                        },
                        onQuit: {
                            stopGameLoop()
                            isPaused = false
                            onGoHome()
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }

        }
        
        .background(backgroundColor)
        .onDisappear {
            stopGameLoop()
        }
        
    }
    
    
    // MARK: - Score Pill
    
    private func scorePill(
        title: String,
        score: Int,
        foreground: Color,
        background: Color
    ) -> some View {
        HStack(spacing: 7) {
            Text(title)
            
            Text("\(score)")
                .monospacedDigit()
        }
        .font(
            .system(
                size: 22,
                weight: .bold,
                design: .rounded
            )
        )
        .foregroundStyle(foreground)
        .padding(.horizontal, 22)
        .frame(height: 58)
        .background(background)
        .clipShape(Capsule())
    }
    
    // MARK: - Speed Indicator
    
    private var speedIndicator: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        index < 3
                        ? blue
                        : Color.gray.opacity(0.3)
                    )
                    .frame(
                        width: 7,
                        height: CGFloat(12 + index * 4)
                    )
            }
        }
    }
    
    // MARK: - Direction Button
    
    private func directionButton(
        _ symbol: String,
        direction: SnakeDirection
    ) -> some View {
        Button {
            changeHumanDirection(to: direction)
        } label: {
            GeometryReader { geometry in
                Image(systemName: symbol)
                    .font(.system(
                        size: geometry.size.width * 0.32,
                        weight: .semibold
                    ))
                    .foregroundStyle(.black)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            }
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 22)
            )
            .shadow(
                color: .black.opacity(0.06),
                radius: 12,
                y: 6
            )
        }
        .buttonStyle(.plain)
    }
    
    
    // MARK: - Human Controls
    private func changeHumanDirection(
        to newDirection: SnakeDirection
    ) {
        // 1. Allow movement only while playing
        guard isPlaying, !game.isGameOver else {
            return
        }
        
        // 2. Validate the human snake's own safety
        guard game.isSafeMove(
            newDirection,
            for: game.humanPlayer
        ) else {
            print("🔵 Unsafe human move rejected")
            return
        }
        
        // 3. Detect collision with the AI snake
        if game.wouldHitOpponent(
            newDirection,
            for: game.humanPlayer
        ) {
            game.isGameOver = true
            game.winner = .ai
            print("💥 Human collided with AI!")
            print("🔴 AI wins!")
            
            stopGameLoop()
            return
        }
        
        // 4. Update the direction
        game.humanPlayer.direction = newDirection
        
        // 5. Move exactly one cell
        game.moveHumanOneStep()
        
        print("🎮 Human moved manually:", newDirection)
    }
    
    
    
    
    // MARK: - Timer
    
    private var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        
        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
    
    // MARK: - Core AI Inference
    
    private func runSnakeInference() async {
        do {
            // 1. Encode the red AI snake
            let inputValues = game.makeAIPlayerInput()
            
            guard inputValues.count == 80 else {
                print("❌ Invalid AI input size")
                return
            }
            
            // 2. Run Core AI inference
            let prediction = try await aiService.predictDirection(
                inputValues: inputValues
            )
            
            game.totalPredictions += 1
            
            // 3. Select the highest-ranked safe direction
            
            
            let selectedDirection = prediction.rankedDirections.first { direction in
                let safe = game.isSafeMove(
                    direction,
                    for: game.aiPlayer
                )

                let hitsBlueSnake = game.wouldHitOpponent(
                    direction,
                    for: game.aiPlayer
                )

                let allowed = safe && !hitsBlueSnake

                print(
                    "🤖 Direction: \(direction), " +
                    "Safe: \(safe), " +
                    "Hits blue snake: \(hitsBlueSnake), " +
                    "Allowed: \(allowed)"
                )

                return allowed
            }


            
            
            guard let selectedDirection else {
                print("🚫 AI has no safe moves")
                print("🔵 Human wins!")

                game.isGameOver = true
                game.winner = .human

                stopGameLoop()
                return
            }

            
            // 4. Track safety interventions
            if let preferredDirection = prediction.rankedDirections.first,
               preferredDirection != selectedDirection {
                game.safetyOverrides += 1
                
                print("🛡️ Safety override applied")
                print("AI preferred:", preferredDirection)
                print("Selected:", selectedDirection)
            }
            
            
            // Check whether the AI will collide with the human
            if game.wouldHitOpponent(
                selectedDirection,
                for: game.aiPlayer
            ) {
                game.isGameOver = true
                game.winner = .human
                print("💥 AI collided with human!")
                print("🔵 Human wins!")
                
                stopGameLoop()
                return
            }
            
            // 5. Move the red AI snake
            game.aiPlayer.direction = selectedDirection
            game.moveAIPlayerOneStep()
            
            print("🔴 Core AI selected:", selectedDirection)
            print("🔴 AI head:", game.aiPlayer.head as Any)
            
        } catch {
            print("❌ Core AI inference failed:", error)
        }
    }
    
    
    
    // MARK: - Game Loop
    
    @MainActor
    private func startGameLoop() {
        guard !isPlaying, !game.isGameOver else { return }

        isPlaying = true

        let clock = ContinuousClock()
        let startTime = clock.now
        let previousElapsedSeconds = elapsedSeconds

        gameLoopTask = Task {
            while !Task.isCancelled && isPlaying && !game.isGameOver {
                do {
                    try await Task.sleep(for: .milliseconds(500))
                } catch {
                    break
                }

                guard !Task.isCancelled,
                      isPlaying,
                      !game.isGameOver else {
                    break
                }

                await runSnakeInference()

                let duration = startTime.duration(to: clock.now)

                elapsedSeconds = previousElapsedSeconds
                    + Int(duration.components.seconds)
            }

            isPlaying = false
            gameLoopTask = nil
        }
    }

    
    @MainActor
    private func stopGameLoop() {
        isPlaying = false
        gameLoopTask?.cancel()
        gameLoopTask = nil
    }
}
