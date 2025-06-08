//
//  ColoredButtonStyle.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 04/06/2025.
//
import SwiftUI

struct ColoredButtonStyle: ButtonStyle {
    var enabledColor: Color
    var disabledColor: Color
    var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? (configuration.isPressed ? enabledColor.opacity(0.6) : enabledColor) : disabledColor)
    }
}
