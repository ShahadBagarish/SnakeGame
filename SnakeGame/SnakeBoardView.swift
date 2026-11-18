
import SwiftUI
import CoreAI
import Foundation


struct SnakeBoardView: View {
    
    let game: SnakeGameState
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(
                geometry.size.width,
                geometry.size.height
            ) / CGFloat(game.gridSize)
            
            ZStack(alignment: .topLeading) {
                Color(red: 0.08, green: 0.17, blue: 0.14)
                
                // Draw the grid
                ForEach(0..<game.gridSize, id: \.self) { row in
                    ForEach(0..<game.gridSize, id: \.self) { col in
                        Rectangle()
                            .fill(
                                (row + col).isMultiple(of: 2)
                                ? Color.white.opacity(0.06)
                                : Color.clear
                            )
                            .frame(
                                width: cellSize,
                                height: cellSize
                            )
                            .position(
                                x: (CGFloat(col) + 0.5) * cellSize,
                                y: (CGFloat(row) + 0.5) * cellSize
                            )
                    }
                }
                
                // Draw the snake
                ForEach(game.snake.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(index == 0 ? Color.mint : Color.green)
                        .frame(
                            width: cellSize - 3,
                            height: cellSize - 3
                        )
                        .position(
                            x: (game.snake[index].x + 0.5) * cellSize,
                            y: (game.snake[index].y + 0.5) * cellSize
                        )
                }
                
                // Draw the food
                Circle()
                    .fill(.red)
                    .frame(
                        width: cellSize * 0.65,
                        height: cellSize * 0.65
                    )
                    .position(
                        x: (game.food.x + 0.5) * cellSize,
                        y: (game.food.y + 0.5) * cellSize
                    )
            }
            .frame(
                width: cellSize * CGFloat(game.gridSize),
                height: cellSize * CGFloat(game.gridSize)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    @MainActor
    func runSnakeInference() async {
        guard let modelURL = Bundle.main.url(
            forResource: "SnakeTransformer",
            withExtension: "aimodel"
        ) else {
            print("❌ Model not found")
            return
        }
        
        do {
            // 1. Load the model
            let model = try await AIModel(contentsOf: modelURL)
            
            // 2. Load its inference function
            guard let function = try model.loadFunction(
                named: "main"
            ) else {
                print("❌ Function 'main' not found")
                return
            }
            
            // 3. Prepare the input tensor
            let values = makeTestSnakeInput()
            
            guard values.count == 80 else {
                print("❌ Incorrect input size")
                return
            }
            
            let input = NDArray(
                scalars: values,
                shape: [1, 5, 16]
            )
            
            print("Input shape:", input.shape)
            print("Input type:", input.scalarType)
            
            // 4. Run inference
            print("⏳ Running Core AI inference...")
            
            var outputs = try await function.run(
                inputs: ["x": input]
            )
            
            // 5. Extract the output tensor
            guard let result = outputs.remove("addmm_9"),
                  let prediction = result.ndArray else {
                print("❌ Output 'addmm_9' missing")
                return
            }
            
            print("✅ Inference successful!")
            print("Output shape:", prediction.shape)
            print("Output type:", prediction.scalarType)
            
            
            guard prediction.shape == [1, 4],
                  prediction.scalarType == .float32 else {
                print("❌ Unexpected output format")
                return
            }
            
            let scores: [Float] = prediction.view(
                as: Float.self
            ).withUnsafePointer { pointer, _, strides in
                (0..<4).map { index in
                    pointer[index * strides[1]]
                }
            }
            
            let directions = ["Up", "Down", "Left", "Right"]
            
            for index in 0..<4 {
                print("\(directions[index]): \(scores[index])")
            }
            
            guard let bestIndex = scores.indices.max(
                by: { scores[$0] < scores[$1] }
            ) else {
                print("❌ No prediction scores")
                return
            }
            
            print("🐍 Predicted direction:", directions[bestIndex])
            
            
            
        } catch {
            print("❌ Inference failed:", error)
        }
    }
    
    func makeTestSnakeInput() -> [Float] {
        // Snake at (0.5, 0.5)
        // Food at (0.8, 0.5)
        // Food is to the right.
        
        let state: [Float] = [
            0.5, 0.5,  // Vertical position features
            0.5, 0.5,  // Horizontal position features
            0.3, 0.0,  // Food direction: dx, dy
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0
        ]
        
        let input = Array(
            repeating: state,
            count: 5
        ).flatMap { $0 }
        
        print("Input value count:", input.count)
        
        return input
    }
    
    
}

