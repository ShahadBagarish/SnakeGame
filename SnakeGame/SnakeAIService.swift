//
//  SnakeAIService.swift
//  SnakeGame
//
//  Created by Shahad on 16/11/2026.
//


import Foundation
import CoreAI

@MainActor
final class SnakeAIService {

    private var model: AIModel?
    private var inferenceFunction: InferenceFunction?
    
    func loadModel() async throws {

        // Avoid loading the model twice
        guard model == nil else {
            print("✅ Model already loaded")
            return
        }

        guard let modelURL = Bundle.main.url(
            forResource: "SnakeTransformer",
            withExtension: "aimodel"
        ) else {
            throw SnakeAIError.modelNotFound
        }

        model = try await AIModel(contentsOf: modelURL)

        print("✅ SnakeTransformer loaded")
    }
    
    func predictDirection(
        inputValues: [Float]
    ) async throws -> SnakePrediction {

        // 1. Reuse the loaded model
        try await prepareInferenceFunction()

        guard let function = inferenceFunction else {
            throw SnakeAIError.functionNotFound
        }


        // 3. Prepare input [1, 5, 16]
        let input = NDArray(
            scalars: inputValues,
            shape: [1, 5, 16]
        )

        // 4. Run Core AI inference
        
        let clock = ContinuousClock()

        // Start measuring
        let start = clock.now

        // Run Core AI inference
        var outputs = try await function.run(
            inputs: ["x": input]
        )

        // Stop measuring
        let elapsed = start.duration(to: clock.now)

        // Convert the duration to milliseconds
        let components = elapsed.components

        let latencyMs =
            Double(components.seconds) * 1_000 +
            Double(components.attoseconds) / 1_000_000_000_000_000

        print(
            String(
                format: "⏱️ Inference latency: %.2f ms",
                latencyMs
            )
        )

        // 5. Extract the named output
        guard let outputValue = outputs.remove("addmm_9") else {
            throw SnakeAIError.outputNotFound
        }

        // 6. Convert InferenceValue to NDArray
        guard let output = outputValue.ndArray else {
            throw SnakeAIError.outputNotFound
        }

        // 7. Read the four prediction scores
        let scores = output.view(as: Float.self)
            .withUnsafePointer { pointer, _, strides in
                (0..<4).map { index in
                    pointer[index * strides[1]]
                }
            }

        // 8. Find the highest-scoring direction
        guard let bestIndex = scores.indices.max(
            by: { scores[$0] < scores[$1] }
        ) else {
            throw SnakeAIError.outputNotFound
        }

        let directions: [SnakeDirection] = [
            .up, .down, .left, .right
        ]

       
        let prediction = SnakePrediction(scores: scores)

        print("🤖 AI ranked directions:", prediction.rankedDirections)
        print("Scores:", scores)

        return prediction

    }

    
    func prepareInferenceFunction() async throws {

        // Reuse the function if already prepared
        guard inferenceFunction == nil else {
            print("✅ Inference function already cached")
            return
        }

        // Ensure the model exists
        try await loadModel()

        guard let model else {
            throw SnakeAIError.modelNotFound
        }

        // Load the function only once
        guard let function = try model.loadFunction(
            named: "main"
        ) else {
            throw SnakeAIError.functionNotFound
        }

        inferenceFunction = function

        print("✅ Inference function cached")
    }


}


struct SnakePrediction {
    let scores: [Float]

    let directions: [SnakeDirection] = [
        .up, .down, .left, .right
    ]

    var rankedDirections: [SnakeDirection] {
        directions.indices
            .sorted { scores[$0] > scores[$1] }
            .map { directions[$0] }
    }
}


enum SnakeAIError: Error {
    case modelNotFound
    case functionNotFound
    case outputNotFound
}
