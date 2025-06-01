//
//  Tetromino.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import Foundation
import SwiftUI

struct Position: Equatable {
    var row: Int
    var column: Int
}

enum BlockColor: Int, CaseIterable, Equatable {
    case i, o, t, j, l, s, z
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
        }
    }
}

struct Tetromino: Equatable {
    let type: BlockColor
    let blocks: [Position]
    let pivot: Position

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
        }
    }

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
