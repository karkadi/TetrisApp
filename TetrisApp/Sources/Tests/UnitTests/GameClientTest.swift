//
//  GameClientTest.swift
//  TetrisAppTests
//
//  Created by Arkadiy KAZAZYAN on 08/06/2025.
//
import Testing
@testable import TetrisApp

/// Test suite for GameClient functionality in Tetris game.
///
/// Covers core game mechanics including:
/// - Random piece generation
/// - Piece placement validation
/// - Piece movement mechanics
/// - Piece spawning and game-over conditions
/// - Line clearing detection
/// - Score/level progression
@MainActor
struct GameClientTest {

    // MARK: Random Piece Tests

    /// Validates random piece generation logic
    ///
    /// Ensures:
    /// - Generated pieces use valid colors
    /// - Gray color is never returned (reserved for special states)
    @Test("Random Piece Generation")
    func testRandomPiece() async {
        let client = GameClient.liveValue
        let piece = client.randomPiece()

        #expect(BlockColor.allCases.dropLast().contains(piece), "Random piece should be a valid BlockColor except gray")
    }

    // MARK: Piece Placement Tests

    /// Verifies piece placement validation logic
    ///
    /// Tests:
    /// - Placement in empty space validity
    /// - Collision with boundaries
    /// - Block collision scenarios
    @Test("Can Place Piece")
    func testCanPlacePiece() async {
        let client = GameClient.liveValue
        var state = TetrisReducer.State()
        let piece = Tetromino.create(.iBlock)

        // Test valid placement
        state.piecePosition = Position(row: 0, column: 4)
        #expect(client.canPlacePiece(state, piece), "Piece should be placeable in empty space")

        // Test invalid placement (out of bounds)
        state.piecePosition = Position(row: 0, column: 8)
        #expect(!client.canPlacePiece(state, piece), "Piece should not be placeable out of bounds")

        // Test invalid placement (collision)
        state.board[0][4] = .oBlock
        state.piecePosition = Position(row: 0, column: 4)
        #expect(!client.canPlacePiece(state, piece), "Piece should not be placeable on occupied space")
    }
    // MARK: Movement Tests

    /// Tests piece movement validation
    ///
    /// Covers:
    /// - Valid movements within playable area
    /// - Boundary collision detection
    /// - Movement collision with placed blocks
    @Test("Can Move Piece")
    func testCanMovePiece() async {
        let client = GameClient.liveValue
        var state = TetrisReducer.State()
        state.currentPiece = Tetromino.create(.iBlock)
        state.piecePosition = Position(row: 5, column: 5)

        // Test valid move
        #expect(client.canMovePiece(state, (0, 1)), "Piece should move right")
        #expect(client.canMovePiece(state, (1, 0)), "Piece should move down")

        // Test invalid move (out of bounds)
        state.piecePosition = Position(row: 5, column: 8)
        #expect(!client.canMovePiece(state, (0, 1)), "Piece should not move right out of bounds")

        // Test invalid move (collision)
        state.board[5][6] = .oBlock
        state.piecePosition = Position(row: 5, column: 5)
        #expect(!client.canMovePiece(state, (0, 1)), "Piece should not move into occupied space")
    }

    // MARK: Spawn Mechanic Tests

    /// Validates piece spawning mechanics
    ///
    /// Checks:
    /// - Successful spawn positioning and state updates
    /// - Piece cycling (next piece becomes current)
    /// - Game-over condition when immediate collision occurs
    @Test("Spawn Piece")
    func testSpawnPiece() async {
        let client = GameClient.liveValue
        var state = TetrisReducer.State()
        state.currentPiece = Tetromino.create(.iBlock)
        state.nextPiece = Tetromino.create(.oBlock)
        state.piecePosition = Position(row: 5, column: 4)

        // Test successful spawn
        let result = client.spawnPiece(&state)
        #expect(result, "Piece should spawn successfully")
        #expect(state.piecePosition == Position(row: 0, column: 4), "Piece position should reset")
        #expect(state.currentPiece != nil, "Current piece should be set")
        #expect(state.nextPiece != nil, "Next piece should be set")

        // Test game over
        state.piecePosition = Position(row: 0, column: 4)
        state.board[0][4] = .oBlock
        let gameOverResult = client.spawnPiece(&state)
        #expect(!gameOverResult, "Should return false for game over")
    }

    // MARK: Line Management Tests

    /// Tests filled line detection
    ///
    /// Verifies:
    /// - Detection of fully filled rows
    /// - Proper identification of clearable lines
    /// - Handling of non-clearable boards
    @Test("Clear Lines")
    func testClearLines() async {
        let client = GameClient.liveValue
        var state = TetrisReducer.State()

        // Fill a row
        state.board[19] = Array(repeating: .oBlock, count: 10)

        let linesToClear = client.clearLines(&state)
        #expect(linesToClear == [19], "Should detect full row at index 19")

        // Test empty board
        state.board = TetrisReducer.State.emptyBoard
        let noLines = client.clearLines(&state)
        #expect(noLines.isEmpty, "Should detect no lines to clear")
    }

    /// Tests line removal and state updates
    ///
    /// Confirms:
    /// - Score calculation based on lines cleared
    /// - Board reorganization after line removal
    /// - Proper state resetting in cleared areas
    @Test("Remove Lines")
    func testRemoveLines() async {
        let client = GameClient.liveValue
        var state = TetrisReducer.State()
        state.score = 0
        state.level = 1
        state.linesCleared = 0

        // Fill two rows
        state.board[18] = Array(repeating: .oBlock, count: 10)
        state.board[19] = Array(repeating: .oBlock, count: 10)

        client.removeLines([18, 19], &state)

        #expect(state.linesCleared == 2, "Should have cleared 2 lines")
        #expect(state.score == 200, "Score should increase by 200 for 2 lines at level 1")
        #expect(state.board[0][0] == nil, "Top rows should be empty after clearing")
    }

    // MARK: Progression Tests

    /// Validates level progression mechanics
    ///
    /// Ensures:
    /// - Level advancement when clearing threshold lines
    /// - Score multipliers based on level
    /// - Game speed adjustments per level
    @Test("Check Level Progression")
    func testCheckLevelProgression() async {
        let client = GameClient.liveValue
        var state = TetrisReducer.State()
        state.level = 1
        state.linesCleared = 10
        state.linesToNextLevel = 10

        let didLevelUp = client.checkLevelProgression(&state)

        #expect(didLevelUp, "Should level up when lines cleared meets threshold")
        #expect(state.level == 2, "Level should increase to 2")
        #expect(state.linesToNextLevel == 20, "Lines to next level should increase")
        #expect(state.gameSpeed == TetrisReducer.State.speedForLevel(2), "Game speed should update")

        // Test no level up
        state.linesCleared = 5
        let noLevelUp = client.checkLevelProgression(&state)
        #expect(!noLevelUp, "Should not level up when lines cleared is below threshold")
    }
}
