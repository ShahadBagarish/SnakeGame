//
//  SnakePlayer.swift
//  SnakeGame
//
//  Created by Shahad on 17/11/2026.
//


import Foundation
import CoreGraphics

enum SnakePlayerType {
    case human
    case ai
}

struct SnakePlayer {
    let type: SnakePlayerType

    var body: [CGPoint]
    var direction: SnakeDirection
    var score: Int = 0

    var head: CGPoint? {
        body.first
    }
}
