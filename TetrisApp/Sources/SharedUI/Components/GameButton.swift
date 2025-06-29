//
//  GameButton.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 12/06/2025.
//
import SwiftUI

/// A customizable button component for game interactions
///
/// `GameButton` provides a reusable SwiftUI button component featuring:
/// - SF Symbol icons
/// - Customizable dimensions
/// - Enabled/disabled state with visual indication
/// - Large tappable area
/// - Consistent styling
///
/// # Usage:
/// ```swift
/// GameButton(
///     systemName: "arrow.up",
///     width: 100,
///     height: 100,
///     isEnabled: true
/// ) {
///     // Button action
/// }
/// ```
///
/// - Parameters:
///   - systemName: SF Symbol name for the button icon
///   - width: Button width (default: 90)
///   - height: Button height (default: 90)
///   - isEnabled: Control enabled state (default: true)
///   - action: Closure to execute on tap
struct GameButton: View {
    let systemName: String
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    let isEnabled: Bool

    init(
        systemName: String,
        width: CGFloat = 90,
        height: CGFloat = 90,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.width = width
        self.height = height
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title)
                .frame(width: width, height: height)
                .contentShape(Rectangle()) // Ensures entire frame is tappable
        }
        .dynamicTypeSize(.medium)
        .buttonStyle(ColoredButtonStyle(
            enabledColor: .primary,
            disabledColor: .gray,
            isEnabled: isEnabled
        ))
        .disabled(!isEnabled)
    }
}
