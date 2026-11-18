//
//  HomeView.swift
//  SnakeGame
//
//  Created by Shahad on 17/11/2026.
//

import SwiftUI

struct HomeView: View {

    let onStartGame: () -> Void

    var body: some View {
        VStack(spacing: 28) {

            Spacer()

            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            VStack(spacing: 12) {

                Text("Snake vs AI")
                    .font(.system(
                        size: 42,
                        weight: .bold,
                        design: .rounded
                    ))

                Text("Challenge Core AI")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {

                Text("Classic · Normal")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button(action: onStartGame) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Game")
                    }
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.blue, in: Capsule())
            }

            Spacer()
                .frame(height: 40)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

