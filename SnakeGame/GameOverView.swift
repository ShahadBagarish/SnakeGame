//
//  GameOverView.swift
//  SnakeGame
//
//  Created by Shahad on 17/11/2026.
//

import SwiftUI

struct GameOverView: View {

    let winner: SnakePlayerType
    let humanScore: Int
    let aiScore: Int
    let snakeLength: Int

    let onPlayAgain: () -> Void
    let onHome: () -> Void

    private var humanWon: Bool {
        winner == .human
    }

    private var winnerColor: Color {
        humanWon ? .blue : .red
    }

    var body: some View {
        VStack(spacing: 20) {

            Text("Classic · Normal")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(humanWon ? "You Win" : "AI Wins")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(winnerColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            HStack(spacing: 12) {
                statisticCard(
                    title: "You",
                    value: humanScore,
                    color: .blue
                )

                statisticCard(
                    title: "AI",
                    value: aiScore,
                    color: .red
                )
            }

            HStack(spacing: 12) {
                statisticCard(
                    title: "Length",
                    value: snakeLength,
                    color: .primary
                )
            }

            Button(action: onPlayAgain) {
                Text("Play Again")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(.blue, in: Capsule())

            Button(action: onHome) {
                Text("Home")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: Capsule()
            )
        }
        .padding(28)
        .frame(maxWidth: 420)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: 36)
        )
        .shadow(color: .black.opacity(0.12), radius: 24)
    }

    private func statisticCard(
        title: String,
        value: Int,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            Text("\(value)")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }
}
