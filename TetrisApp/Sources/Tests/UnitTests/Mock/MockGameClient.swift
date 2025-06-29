//
//  MockGameClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//
import Foundation
@testable import TetrisApp

// MARK: - Mock Dependencies
/// `MockGameClient` is a test double conforming to the `GameClient` protocol, used to provide controllable test behavior for Tetris game logic.
///
/// This mock enables unit tests to inject custom implementations of core Tetris actions, such as random piece generation, move and placement validation, piece spawning, line clearing, and level progression checks.
///
/// - Properties:
///   - `randomPieceImpl`: Closure producing a mock `BlockColor` representing the next tetromino.
///   - `canPlacePieceImpl`: Closure determining if a given piece can be placed in the current state.
///   - `canMovePieceImpl`: Closure determining if the current piece can be moved by a specified offset.
///   - `spawnPieceImpl`: Closure that attempts to spawn a new piece in the provided state.
///   - `clearLinesImpl`: Closure for clearing completed lines in the game state, returning indices of cleared lines.
///   - `checkLevelProgressionImpl`: Closure for checking if the player should progress to a new level.
///   - `removeLinesImpl`: Closure performing the removal of specified lines from the state.
///
/// - Usage:
///   This type is designed for use in tests, where each closure can be assigned a custom implementation to precisely control system behavior and verify interactions.
///
struct MockGameClient: GameClient {
    var randomPieceImpl: () -> BlockColor
    var canPlacePieceImpl: (_ state: TetrisReducer.State, _ piece: Tetromino) -> Bool
    var canMovePieceImpl: (_ state: TetrisReducer.State, _ offset: (row: Int, column: Int)) -> Bool
    var spawnPieceImpl: (_ state: inout TetrisReducer.State) -> Bool
    var clearLinesImpl: (_ state: inout TetrisReducer.State) -> [Int]
    var checkLevelProgressionImpl: (_ state: inout TetrisReducer.State) -> Bool
    var removeLinesImpl: (_ linesToClear: [Int], _ state: inout TetrisReducer.State) -> Void
    
    func randomPiece() -> BlockColor {
        randomPieceImpl()
    }
    
    func canPlacePiece(_ state: TetrisReducer.State, _ piece: Tetromino) -> Bool {
        canPlacePieceImpl(state, piece)
    }
    
    func canMovePiece(_ state: TetrisReducer.State, _ offset: (row: Int, column: Int)) -> Bool {
        canMovePieceImpl(state, offset)
    }
    
    func spawnPiece(_ state: inout TetrisReducer.State) -> Bool {
        spawnPieceImpl(&state)
    }
    
    func clearLines(_ state: inout TetrisReducer.State) -> [Int] {
        clearLinesImpl(&state)
    }
    
    func removeLines(_ linesToClear: [Int], _ state: inout TetrisReducer.State) {
        removeLinesImpl(linesToClear, &state)
    }
    
    func checkLevelProgression(_ state: inout TetrisReducer.State) -> Bool {
        checkLevelProgressionImpl(&state)
    }
    
}
