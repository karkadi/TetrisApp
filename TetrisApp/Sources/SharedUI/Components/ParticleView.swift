//
//  ParticleView.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//
import SwiftUI

/// `ParticleView` is a SwiftUI view that renders a single animated particle, commonly used for visual effects such as explosions or celebratory bursts.
/// 
/// - Parameters:
///   - color: The `Color` used to fill the particle (circle shape).
///   - progress: A `Double` value (typically between 0 and 1) representing the progress of the particle's animation.
///     - At `progress == 0`, the particle is at the origin with full opacity.
///     - As `progress` increases, the particle moves outward and fades out.
///
/// The particle's direction and distance are randomized on each render, giving a natural scattered effect. Its position is offset randomly in both x and y directions, scaled by the `progress`. The opacity smoothly decreases as `progress` increases, simulating the particle fading away.
///
/// Example usage:
/// ```swift
/// ParticleView(color: .red, progress: 0.5)
/// ```
///
/// Designed for integration in particle systems or animation overlays within SwiftUI interfaces.
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
