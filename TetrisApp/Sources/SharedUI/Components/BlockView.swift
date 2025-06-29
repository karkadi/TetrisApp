//
//  BlockView.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import SwiftUI

/// A visual representation of a Tetris block cube.
///
/// This view displays an individual game block with:
/// - A solid foreground color
/// - Simulated 3D lighting effects on the edges
/// - Customizable clearing animations
///
/// ```swift
/// BlockView(
///     color: .blue,
///     blockSize: 30,
///     isClearing: false,
///     animationProgress: 0
/// )
/// ```
///
/// - Parameters:
///   - color: The color variant of the Tetris block (I/O/J/L/S/T/Z)
///   - blockSize: The rendered dimensions of the square block view
///   - isClearing: Whether the block is currently playing its removal animation
///   - animationProgress: The normalized progress (0-1) of block dissolution when cleared
struct BlockView: View {
    let color: BlockColor
    let blockSize: CGFloat
    var isClearing: Bool = false
    var animationProgress: Double = 0

    var body: some View {
        ZStack {
            if isClearing && animationProgress < 0.5 {
                ForEach(0..<5, id: \.self) { _ in
                    ParticleView(color: color.color, progress: animationProgress * 2)
                }
            }

            Image(color.name)
                .resizable()
                .frame(width: blockSize, height: blockSize)
                .scaleEffect(isClearing ? (1 - animationProgress) : 1)
                .opacity(isClearing ? (1 - animationProgress) : 1)
                .animation(isClearing ? .easeOut(duration: 0.3) : .none, value: animationProgress)
        }
    }
}
