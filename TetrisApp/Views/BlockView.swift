//
//  BlockView.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import SwiftUI

struct BlockView: View {
    let color: BlockColor
    var isClearing: Bool = false
    var animationProgress: Double = 0

    var body: some View {
        if isClearing && animationProgress < 0.5 {
            ForEach(0..<5, id: \.self) { _ in
                ParticleView(color: color.color, progress: animationProgress * 2)
            }
        }
        Rectangle()
            .fill(color.color)
            .frame(width: 18, height: 18)
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(isClearing ? (1 - animationProgress) : 1)
            .opacity(isClearing ? (1 - animationProgress) : 1)
            .animation(isClearing ? .easeOut(duration: 0.3) : .none, value: animationProgress)
    }
}

struct ParticleView: View {
    let color: Color
    let progress: Double

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 4, height: 4)
            .offset(
                x: CGFloat.random(in: -10...10) * progress,
                y: CGFloat.random(in: -10...10) * progress
            )
            .opacity(1 - progress)
    }
}
