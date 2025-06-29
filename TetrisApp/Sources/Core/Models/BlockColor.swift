//
//  BlockColor.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//
import Foundation
import SwiftUI

/// The color and type of a tetromino block.
///
/// Each case represents a specific tetromino shape with an associated display color.
/// - iBlock: I-shaped tetromino (cyan)
/// - oBlock: O-shaped tetromino (yellow)
/// - tBlock: T-shaped tetromino (purple)
/// - jBlock: J-shaped tetromino (blue)
/// - lBlock: L-shaped tetromino (orange)
/// - sBlock: S-shaped tetromino (green)
/// - zBlock: Z-shaped tetromino (red)
/// - gray: Special single block (gray)
///
/// - color: SwiftUI color representation for this block type.
enum BlockColor: Int, CaseIterable, Equatable {
    case iBlock, oBlock, tBlock, jBlock, lBlock, sBlock, zBlock, gray
}

extension BlockColor {
    var color: Color {
        switch self {
        case .iBlock: return .cyan
        case .oBlock: return .yellow
        case .tBlock: return .purple
        case .jBlock: return .blue
        case .lBlock: return .orange
        case .sBlock: return .green
        case .zBlock: return .red
        case .gray: return .gray
        }
    }
    
    var name: String {
        switch self {
        case .iBlock: return "block_cyan"
        case .oBlock: return "block_yellow"
        case .tBlock: return "block_purple"
        case .jBlock: return "block_blue"
        case .lBlock: return "block_orange"
        case .sBlock: return "block_green"
        case .zBlock: return "block_red"
        case .gray: return "block_gray"
        }
    }
}
