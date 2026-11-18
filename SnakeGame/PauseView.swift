//
//  PauseView.swift
//  SnakeGame
//
//  Created by Shahad on 17/11/2026.
//


import SwiftUI

struct PauseView: View {

    let humanScore: Int
    let aiScore: Int

    let onResume: () -> Void
    let onRestart: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 20) {

            Text("Paused")
                .font(.system(
                    size: 42,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                scoreCard(
                    title: "You",
                    score: humanScore,
                    color: .blue,
                    background: Color.blue.opacity(0.14)
                )

                scoreCard(
                    title: "AI",
                    score: aiScore,
                    color: .red,
                    background: Color.red.opacity(0.14)
                )
            }

            Button(action: onResume) {
                Text("Resume")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(.blue, in: Capsule())

            Button(action: onRestart) {
                Text("Restart")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: Capsule()
            )

            Button(action: onQuit) {
                Text("Quit")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: Capsule()
            )
        }
        .font(.system(
            size: 22,
            weight: .bold,
            design: .rounded
        ))
        .padding(28)
        .frame(maxWidth: 420)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: 36)
        )
        .shadow(
            color: .black.opacity(0.12),
            radius: 24
        )
    }

    private func scoreCard(
        title: String,
        score: Int,
        color: Color,
        background: Color
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.title3.bold())

            Text("\(score)")
                .font(.system(
                    size: 38,
                    weight: .bold,
                    design: .rounded
                ))
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            background,
            in: RoundedRectangle(cornerRadius: 24)
        )
    }
}
