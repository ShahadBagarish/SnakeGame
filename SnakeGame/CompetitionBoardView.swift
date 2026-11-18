//
//  CompetitionBoardView.swift
//  SnakeGame
//
//  Created by Shahad on 17/11/2026.
//

import SwiftUI

struct CompetitionBoardView: View {

    let game: SnakeGameState

    private let humanColor = Color(
        red: 0.14, green: 0.39, blue: 0.91
    )

    private let aiColor = Color(
        red: 0.87, green: 0.23, blue: 0.17
    )

    var body: some View {
        GeometryReader { geometry in

            let spacing: CGFloat = 3
            let gridSize = game.gridSize

            let cellSize = (
                geometry.size.width -
                CGFloat(gridSize - 1) * spacing
            ) / CGFloat(gridSize)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(
                        .fixed(cellSize),
                        spacing: spacing
                    ),
                    count: gridSize
                ),
                spacing: spacing
            ) {
                ForEach(0..<(gridSize * gridSize), id: \.self) { index in

                    let x = index % gridSize
                    let y = index / gridSize
                    let position = CGPoint(x: x, y: y)

                    RoundedRectangle(cornerRadius: cellSize * 0.22)
                        .fill(colorForCell(at: position))
                        .frame(
                            width: cellSize,
                            height: cellSize
                        )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(16)
        .background(
            Color(red: 0.98, green: 0.98, blue: 0.99)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 32)
        )
    }

    private func colorForCell(at position: CGPoint) -> Color {

        // Human snake (blue)
        if game.humanPlayer.head == position {
            return humanColor
        }

        if game.humanPlayer.body.contains(position) {
            return humanColor.opacity(0.45)
        }

        // AI snake (red)
        if game.aiPlayer.head == position {
            return aiColor
        }

        if game.aiPlayer.body.contains(position) {
            return aiColor.opacity(0.45)
        }

        // Food (dark gray)
        if game.food == position {
            return Color(
                red: 0.43,
                green: 0.43,
                blue: 0.43
            )
        }

        // Empty cell
        return Color(
            red: 0.92,
            green: 0.92,
            blue: 0.93
        )
    }

}
