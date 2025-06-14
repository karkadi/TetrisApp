//
//  ColoredButtonStyle.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 04/06/2025.
//
import SwiftUI

/// A custom button style that displays a button with different colors based on its enabled state.
///
/// This style allows the user to specify colors for both enabled and disabled states,
/// as well as the ability to change the color when the button is pressed.
///
/// - Parameters:
///   - enabledColor: The color of the button when it is enabled.
///   - disabledColor: The color of the button when it is disabled.
///   - isEnabled: A Boolean value that determines whether the button is enabled or disabled.
///
/// Usage:
/// To use `ColoredButtonStyle`, apply it to a Button in your SwiftUI view:
/// ```swift
/// Button(action: { /* action */ }) {
///     Text("Click Me")
/// }
/// .buttonStyle(ColoredButtonStyle(enabledColor: .blue, disabledColor: .gray, isEnabled: true))
/// ```
struct ColoredButtonStyle: ButtonStyle {
    var enabledColor: Color
    var disabledColor: Color
    var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? (configuration.isPressed ? enabledColor.opacity(0.6) : enabledColor) : disabledColor)
    }
}
