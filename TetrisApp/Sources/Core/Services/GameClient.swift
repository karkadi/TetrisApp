//
//  GameClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 01/06/2025.
//

import Foundation
import ComposableArchitecture
 import SwiftUI

// MARK: - GameClient
struct GameClient: Sendable {
    var randomPiece: @Sendable () -> BlockColor
    var canPlacePiece: @Sendable (_ state: TetrisReducer.State, _ piece: Tetromino) -> Bool
    var canMovePiece: @Sendable (_ state: TetrisReducer.State, _ offset: (row: Int, column: Int)) -> Bool
    var spawnPiece: @Sendable (inout TetrisReducer.State) -> Bool
    var clearLines: @Sendable (inout TetrisReducer.State) -> [Int]
    var removeLines: @Sendable (_ linesToClear: [Int], inout TetrisReducer.State) -> Void
    var checkLevelProgression: @Sendable (inout TetrisReducer.State) -> Bool
}

// MARK: - Live implementation
extension GameClient: DependencyKey {
    static let liveValue: GameClient = GameClient(
        randomPiece: {
            BlockColor.allCases.dropLast().randomElement() ?? .iBlock
        },
        canPlacePiece: { state, piece in
            for block in piece.blocks {
                let row = state.piecePosition.row + block.row
                let column = state.piecePosition.column + block.column
                if row < 0 || row >= state.board.count || column < 0 || column >= state.board[0].count {
                    return false
                }
                if row >= 0 && state.board[row][column] != nil {
                    return false
                }
            }
            return true
        },
        canMovePiece: { state, offset in
            guard let piece = state.currentPiece else { return false }
            let newPosition = Position(
                row: state.piecePosition.row + offset.row,
                column: state.piecePosition.column + offset.column
            )
            for block in piece.blocks {
                let row = newPosition.row + block.row
                let column = newPosition.column + block.column
                if row >= state.board.count || column < 0 || column >= state.board[0].count {
                    return false
                }
                if row >= 0 && state.board[row][column] != nil {
                    return false
                }
            }
            return true
        },
        spawnPiece: { state in
            if let piece = state.currentPiece {
                for block in piece.blocks {
                    let row = state.piecePosition.row + block.row
                    let column = state.piecePosition.column + block.column
                    if row >= 0 && row < state.board.count && column >= 0 && column < state.board[0].count {
                        state.board[row][column] = piece.type
                    }
                }
            }
            if state.piecePosition.row <= 0 {
                return false // Game over
            }
            state.currentPiece = state.nextPiece
            state.nextPiece = Tetromino.create(
                BlockColor.allCases.dropLast().randomElement() ?? .iBlock
            )
            state.piecePosition = Position(
                row: state.currentPiece?.type == .iBlock ? 2 : 0,
                column: 4
            )
            return GameClient.liveValue.canPlacePiece(state, state.currentPiece!)
        },
        clearLines: { state in
            var linesToClear = [Int]()
            for row in (0..<state.board.count).reversed() where state.board[row].allSatisfy({ $0 != nil }) {
                linesToClear.append(row)
            }
            return linesToClear
        },
        removeLines: { linesToClear, state in
            if !linesToClear.isEmpty {
                var newBoard = state.board
                var linesCleared = 0
                for row in linesToClear.sorted(by: >) {
                    newBoard.remove(at: row)
                    linesCleared += 1
                }
                for _ in 0..<linesCleared {
                    newBoard.insert(Array(repeating: nil, count: state.board[0].count), at: 0)
                }
                state.board = newBoard
                state.linesCleared += linesCleared
                state.score += linesCleared * 100 * state.level
                if linesCleared == 4 {
                    state.score += 400 // Tetris bonus
                }
            }
        },
        checkLevelProgression: { state in
            if state.linesCleared >= state.linesToNextLevel {
                state.level += 1
                state.linesToNextLevel += 10
                state.gameSpeed = TetrisReducer.State.speedForLevel(state.level)
                return true
            }
            return false
        }
    )
}

// MARK: - Dependency registration
extension DependencyValues {
    var gameClient: GameClient {
        get { self[GameClient.self] }
        set { self[GameClient.self] = newValue }
    }
}
