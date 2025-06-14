//
//  GameClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 01/06/2025.
//

import ComposableArchitecture
import SwiftUI

// MARK: - GameClient
protocol GameClient {
    func randomPiece() -> BlockColor
    func canPlacePiece(_ state: GameReducer.State, _ piece: Tetromino) -> Bool
    func canMovePiece(_ state: GameReducer.State, _ offset: (row: Int, column: Int)) -> Bool
    func spawnPiece( _ state: inout GameReducer.State) -> Bool
    func clearLines( _ state: inout GameReducer.State) -> [Int]
    func removeLines(_ linesToClear: [Int], _ state: inout GameReducer.State)
    func checkLevelProgression( _ state: inout GameReducer.State) -> Bool
}

/// A concrete implementation of `GameClient` providing game logic for Tetris.
/// Handles piece movement, collision detection, line clearing, and game progression.

/// Generates a random Tetromino piece color (excluding the empty/clear state)
/// - Returns: Randomly selected BlockColor value
final class DefaultGameClient: GameClient {
    func randomPiece() -> BlockColor {
        BlockColor.allCases.dropLast().randomElement() ?? .i
    }
    
    /// Determines if a Tetromino piece can be placed at current position
    /// - Parameters:
    ///   - state: Current game state
    ///   - piece: Tetromino piece to check placement for
    /// - Returns: True if piece can be placed without collision or bounds violation, false otherwise
    func canPlacePiece(_ state: GameReducer.State, _ piece: Tetromino) -> Bool {
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
    }
    
    /// Checks if current piece can move by specified offset
    /// - Parameters:
    ///   - state: Current game state
    ///   - offset: Movement delta (row and column) to validate
    /// - Returns: True if piece can move without collision or bounds violation, false otherwise
    func canMovePiece(_ state: GameReducer.State, _ offset: (row: Int, column: Int)) -> Bool {
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
    }
    
    /// Spawns a new piece at the top of the board
    /// - Parameter state: Game state (modified in place)
    /// - Returns: False if game is over (cannot place new piece), true otherwise
    func spawnPiece(_ state: inout GameReducer.State) -> Bool {
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
        /*
         var pieceToRotate = Tetromino.create(randomPiece())
         for _ in 0..<Int.random(in: 0...3) {
         pieceToRotate = pieceToRotate.rotated()
         }
         state.nextPiece = pieceToRotate
         */
        state.nextPiece = Tetromino.create(randomPiece())
        state.piecePosition = Position(row: state.currentPiece?.type == .i ? 2 : 0, column: 4)
        return canPlacePiece(state, state.currentPiece!)
    }
    
    /// Identifies completely filled lines for clearing
    /// - Parameter state: Game state (modified in place)
    /// - Returns: Array of row indices that should be cleared
    func clearLines(_ state: inout GameReducer.State) -> [Int] {
        var linesToClear = [Int]()
        for row in (0..<state.board.count).reversed() {
            if state.board[row].allSatisfy({ $0 != nil }) {
                linesToClear.append(row)
            }
        }
        return linesToClear
    }
    
    /// Removes specified lines and shifts board down
    /// - Parameters:
    ///   - linesToClear: Row indices to remove
    ///   - state: Game state (modified in place)
    func removeLines(_ linesToClear: [Int], _ state: inout GameReducer.State) {
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
                state.score += 400 // Bonus for Tetris
            }
        }
    }
    
    /// Checks if player has reached next level threshold
    /// - Parameter state: Game state (modified in place)
    /// - Returns: True if level progression occurred (game updated), false otherwise
    func checkLevelProgression(_ state: inout GameReducer.State) -> Bool {
        if state.linesCleared >= state.linesToNextLevel {
            state.level += 1
            state.linesToNextLevel += 10
            state.gameSpeed = GameReducer.State.speedForLevel(state.level)
            return true
        }
        return false
    }
    
}

// MARK: - Dependency Keys
enum GameClientKey: DependencyKey {
    static let liveValue: any GameClient = DefaultGameClient()
}

// MARK: - Dependency Registration
extension DependencyValues {
    var gameClient: GameClient {
        get { self[GameClientKey.self] }
        set { self[GameClientKey.self] = newValue }
    }
}
