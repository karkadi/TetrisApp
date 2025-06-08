//
//  GameClientTest.swift
//  TetrisAppTests
//
//  Created by Arkadiy KAZAZYAN on 08/06/2025.
//
import Testing
@testable import TetrisApp

struct GameClientTest {

    @Test("Random Piece Generation")
    @MainActor
    func testRandomPiece() async {
        let client = DefaultGameClient()
        let piece = client.randomPiece()

        #expect(BlockColor.allCases.dropLast().contains(piece), "Random piece should be a valid BlockColor except gray")
    }

    @Test("Can Place Piece")
    @MainActor
    func testCanPlacePiece() async {
        let client = DefaultGameClient()
        var state = GameReducer.State()
        let piece = Tetromino.create(.i)

        // Test valid placement
        state.piecePosition = Position(row: 0, column: 4)
        #expect(client.canPlacePiece(state, piece), "Piece should be placeable in empty space")

        // Test invalid placement (out of bounds)
        state.piecePosition = Position(row: 0, column: 8)
        #expect(!client.canPlacePiece(state, piece), "Piece should not be placeable out of bounds")

        // Test invalid placement (collision)
        state.board[0][4] = .o
        state.piecePosition = Position(row: 0, column: 4)
        #expect(!client.canPlacePiece(state, piece), "Piece should not be placeable on occupied space")
    }

    @Test("Can Move Piece")
    @MainActor
    func testCanMovePiece() async {
        let client = DefaultGameClient()
        var state = GameReducer.State()
        state.currentPiece = Tetromino.create(.i)
        state.piecePosition = Position(row: 5, column: 5)

        // Test valid move
        #expect(client.canMovePiece(state, (0, 1)), "Piece should move right")
        #expect(client.canMovePiece(state, (1, 0)), "Piece should move down")

        // Test invalid move (out of bounds)
        state.piecePosition = Position(row: 5, column: 8)
        #expect(!client.canMovePiece(state, (0, 1)), "Piece should not move right out of bounds")

        // Test invalid move (collision)
        state.board[5][6] = .o
        state.piecePosition = Position(row: 5, column: 5)
        #expect(!client.canMovePiece(state, (0, 1)), "Piece should not move into occupied space")
    }

    @Test("Spawn Piece")
    @MainActor
    func testSpawnPiece() async {
        let client = DefaultGameClient()
        var state = GameReducer.State()
        state.currentPiece = Tetromino.create(.i)
        state.nextPiece = Tetromino.create(.o)
        state.piecePosition = Position(row: 5, column: 4)

        // Test successful spawn
        let result = client.spawnPiece(&state)
        #expect(result, "Piece should spawn successfully")
        #expect(state.piecePosition == Position(row: 0, column: 4), "Piece position should reset")
        #expect(state.currentPiece != nil, "Current piece should be set")
        #expect(state.nextPiece != nil, "Next piece should be set")

        // Test game over
        state.piecePosition = Position(row: 0, column: 4)
        state.board[0][4] = .o
        let gameOverResult = client.spawnPiece(&state)
        #expect(!gameOverResult, "Should return false for game over")
    }

    @Test("Clear Lines")
    @MainActor
    func testClearLines() async {
        let client = DefaultGameClient()
        var state = GameReducer.State()

        // Fill a row
        state.board[19] = Array(repeating: .o, count: 10)

        let linesToClear = client.clearLines(&state)
        #expect(linesToClear == [19], "Should detect full row at index 19")

        // Test empty board
        state.board = GameReducer.State.emptyBoard
        let noLines = client.clearLines(&state)
        #expect(noLines.isEmpty, "Should detect no lines to clear")
    }

    @Test("Remove Lines")
    @MainActor
    func testRemoveLines() async {
        let client = DefaultGameClient()
        var state = GameReducer.State()
        state.score = 0
        state.level = 1
        state.linesCleared = 0

        // Fill two rows
        state.board[18] = Array(repeating: .o, count: 10)
        state.board[19] = Array(repeating: .o, count: 10)

        client.removeLines([18, 19], &state)

        #expect(state.linesCleared == 2, "Should have cleared 2 lines")
        #expect(state.score == 200, "Score should increase by 200 for 2 lines at level 1")
        #expect(state.board[0][0] == nil, "Top rows should be empty after clearing")
    }

    @Test("Check Level Progression")
    @MainActor
    func testCheckLevelProgression() async {
        let client = DefaultGameClient()
        var state = GameReducer.State()
        state.level = 1
        state.linesCleared = 10
        state.linesToNextLevel = 10

        let didLevelUp = client.checkLevelProgression(&state)

        #expect(didLevelUp, "Should level up when lines cleared meets threshold")
        #expect(state.level == 2, "Level should increase to 2")
        #expect(state.linesToNextLevel == 20, "Lines to next level should increase")
        #expect(state.gameSpeed == GameReducer.State.speedForLevel(2), "Game speed should update")

        // Test no level up
        state.linesCleared = 5
        let noLevelUp = client.checkLevelProgression(&state)
        #expect(!noLevelUp, "Should not level up when lines cleared is below threshold")
    }
}
