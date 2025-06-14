//
//  Tetromino.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import Foundation
import SwiftUI
#if canImport(Playgrounds)
import Playgrounds
#endif

/// A structure representing the position of a block in a two-dimensional grid.
///
/// The `Position` type consists of two integer properties: `row` and `column`
/// which indicate the respective coordinates in the grid. This is commonly used
/// to track the location of individual blocks within a tetromino in a Tetris game.
struct Position: Equatable {
    var row: Int
    var column: Int
}

/// The color and type of a tetromino block.
///
/// Each case represents a specific tetromino shape with an associated display color.
/// - i: I-shaped tetromino (cyan)
/// - o: O-shaped tetromino (yellow)
/// - t: T-shaped tetromino (purple)
/// - j: J-shaped tetromino (blue)
/// - l: L-shaped tetromino (orange)
/// - s: S-shaped tetromino (green)
/// - z: Z-shaped tetromino (red)
/// - gray: Special single block (gray)
///
/// - color: SwiftUI color representation for this block type.
enum BlockColor: Int, CaseIterable, Equatable {
    case i, o, t, j, l, s, z, gray
}

extension BlockColor {
    var color: Color {
        switch self {
        case .i: return .cyan
        case .o: return .yellow
        case .t: return .purple
        case .j: return .blue
        case .l: return .orange
        case .s: return .green
        case .z: return .red
        case .gray: return .gray
        }
    }
}

/// A structure representing a tetromino in the Tetris game.
///
/// The `Tetromino` type consists of a tetromino's `type`, an array of `blocks` 
/// that represent its position in a two-dimensional grid, and a `pivot` point 
/// around which the tetromino can be rotated. Each tetromino shape has a unique 
/// configuration of blocks and is associated with a specific color.
///
/// Properties:
/// - `type`: The color and shape of the tetromino, represented by the `BlockColor` enum.
/// - `blocks`: An array of `Position` representing the coordinates of each block in the tetromino.
/// - `pivot`: A `Position` representing the pivot point for rotation.
///
/// Methods:
/// - `create(_ type: BlockColor) -> Tetromino`: Creates a new tetromino of the specified type with its initial block positions and pivot.
/// - `rotated() -> Tetromino`: Returns a new `Tetromino` instance that is rotated 90 degrees clockwise around its pivot point.
struct Tetromino: Equatable {
    let type: BlockColor
    let blocks: [Position]
    let pivot: Position

    /// Creates a new tetromino of the specified type with its initial block positions and pivot.
    ///
    /// - Parameter type: The `BlockColor` representing the type of tetromino to create.
    /// - Returns: A `Tetromino` instance initialized with the block positions and pivot 
    ///            associated with the specified `BlockColor` type. Each type has a unique 
    ///            configuration of blocks and a designated pivot point for rotation.
    static func create(_ type: BlockColor) -> Tetromino {
        switch type {
        case .i:
            return Tetromino(
                type: .i,
                blocks: [Position(row: 0, column: 0), Position(row: 0, column: 1),
                         Position(row: 0, column: 2), Position(row: 0, column: 3)],
                pivot: Position(row: 0, column: 1)
            )
        case .o:
            return Tetromino(
                type: .o,
                blocks: [Position(row: 0, column: 0), Position(row: 0, column: 1),
                         Position(row: 1, column: 0), Position(row: 1, column: 1)],
                pivot: Position(row: 0, column: 0)
            )
        case .t:
            return Tetromino(
                type: .t,
                blocks: [Position(row: 0, column: 1), Position(row: 1, column: 0),
                         Position(row: 1, column: 1), Position(row: 1, column: 2)],
                pivot: Position(row: 1, column: 1)
            )
        case .j:
            return Tetromino(
                type: .j,
                blocks: [Position(row: 0, column: 0), Position(row: 1, column: 0),
                         Position(row: 1, column: 1), Position(row: 1, column: 2)],
                pivot: Position(row: 1, column: 1)
            )
        case .l:
            return Tetromino(
                type: .l,
                blocks: [Position(row: 0, column: 2), Position(row: 1, column: 0),
                         Position(row: 1, column: 1), Position(row: 1, column: 2)],
                pivot: Position(row: 1, column: 1)
            )
        case .s:
            return Tetromino(
                type: .s,
                blocks: [Position(row: 0, column: 1), Position(row: 0, column: 2),
                         Position(row: 1, column: 0), Position(row: 1, column: 1)],
                pivot: Position(row: 1, column: 1)
            )
        case .z:
            return Tetromino(
                type: .z,
                blocks: [Position(row: 0, column: 0), Position(row: 0, column: 1),
                         Position(row: 1, column: 1), Position(row: 1, column: 2)],
                pivot: Position(row: 1, column: 1)
            )
        case .gray:
            return Tetromino(
                type: .o,
                blocks: [Position(row: 0, column: 0)],
                pivot: Position(row: 0, column: 0)
            )
        }
    }

    /// Returns a new `Tetromino` that is rotated 90 degrees clockwise around its pivot.
    ///
    /// The rotation is performed by recalculating the position of each block 
    /// relative to the tetromino's pivot point.
    ///
    /// - Returns: A new `Tetromino` instance with all block positions rotated.
    func rotated() -> Tetromino {
        var newBlocks = [Position]()
        for block in blocks {
            let row = pivot.row - (block.column - pivot.column)
            let column = pivot.column + (block.row - pivot.row)
            newBlocks.append(Position(row: row, column: column))
        }
        return Tetromino(type: type, blocks: newBlocks, pivot: pivot)
    }
}

#if canImport(Playgrounds)
#Playground {
    let tetromino = Tetromino.create(.t)
    let rotatedTetromino = tetromino.rotated()
}
#endif
