//
//  GameReducerTests.swift
//  TetrisAppTests
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import ComposableArchitecture
import Testing
import Foundation
@testable import TetrisApp

/// Test suite for GameReducer functionality in TetrisApp
///
/// Validates core game mechanics including:
/// - Game initialization and state management
/// - Piece movement and collision detection
/// - Piece dropping mechanics
/// - Line clearing animation sequences
/// - Level progression logic
/// - Audio feedback and mute functionality
/// - High score tracking and persistence
///
/// Individual tests include:
/// - `startGame`: Verifies game initialization flow and timer-based piece movement
/// - `movePiece`: Tests horizontal piece movement with collision detection
/// - `dropPiece`: Validates instant drop mechanics and piece spawning flow
/// - `clearLines`: Tests full line detection, animation sequence, and scoring
/// - `levelUp`: Verifies level progression thresholds and game speed adjustments
/// - `toggleMute`: Tests audio mute toggling functionality
/// - `highScore`: Validates high score tracking and persistence
///
/// Uses TestStore from Composable Architecture for state assertions and
/// mock dependencies to isolate game logic from external services.
@MainActor
struct GameReducerTests {
    let mockPiece = Tetromino(
        type: .i,
        blocks: [Position(row: 0, column: 0), Position(row: 0, column: 1),
                 Position(row: 0, column: 2), Position(row: 0, column: 3)],
        pivot: Position(row: 0, column: 1)
    )

    @Test("Start Game")
    func startGame() async {
        let clock = DispatchQueue.test
        let store = TestStore( initialState: GameReducer.State() ) {
            GameReducer()
        } withDependencies: {
            $0.mainQueue = clock.eraseToAnyScheduler()
            $0.gameClient = MockGameClient(
                randomPiece_impl: { .i },
                canPlacePiece_impl: { _, _ in true },
                canMovePiece_impl: { _, _ in true },
                spawnPiece_impl: { _ in true },
                clearLines_impl: { _ in [] },
                checkLevelProgression_impl: { _ in false },
                removeLines_impl: { _, _ in }
            )
            $0.audioClient = AudioPlayerClient(
                play: { _ in true },
                toggleMute: { false }
            )
            $0.highScoreClient = HighScoreClient(
                load: { 1000 },
                save: { _ in }
            )
        }
        store.exhaustivity = .off

        await store.send(.startGame) {
            $0.board = GameReducer.State.emptyBoard
            $0.currentPiece = self.mockPiece
            $0.nextPiece = self.mockPiece
            $0.piecePosition = Position(row: 0, column: 4)
            $0.gameSpeed = 1.0
            $0.score = 0
            $0.highScore = 1000
            $0.isGameOver = false
            $0.isPaused = false
            $0.clearingLines = []
            $0.animationProgress = 0
            $0.level = 1
            $0.linesCleared = 0
            $0.linesToNextLevel = 10
            $0.isLevelTransitioning = false
            $0.isMuted = false
        }

        await clock.advance(by: .seconds(1))
        await store.receive(\.tick) {
            $0.piecePosition.row = 0 // .tick triggers .moveDown
        }
    }

    @Test("Move piece in Game")
    func movePiece() async {
        var initialState = GameReducer.State()
        initialState.currentPiece = Tetromino.create(.i)
        initialState.piecePosition = Position(row: 1, column: 4)

        let store = TestStore( initialState: initialState ) {
            GameReducer()
        } withDependencies: {
            $0.gameClient = MockGameClient(
                randomPiece_impl: { .i },
                canPlacePiece_impl: { _, _ in true },
                canMovePiece_impl: { state, offset in
                    let newCol = state.piecePosition.column + offset.column
                    return newCol >= 0 && newCol < state.board[0].count - 3
                },
                spawnPiece_impl: { _ in true },
                clearLines_impl: { _ in [] },
                checkLevelProgression_impl: { _ in false },
                removeLines_impl: { _, _ in }
            )

            $0.audioClient = AudioPlayerClient(
                play: { _ in true },
                toggleMute: { false }
            )
            $0.highScoreClient = HighScoreClient(
                load: { 0 },
                save: { _ in }
            )
        }

        await store.send(.moveLeft) {
            $0.piecePosition.column = 3
        }

        await store.send(.moveRight) {
            $0.piecePosition.column = 4
        }

        // Test boundary collision
        var blockedState = GameReducer.State()
        blockedState.currentPiece = Tetromino.create(.i)
        blockedState.piecePosition = Position(row: 1, column: 0)

        let blockedStore = TestStore( initialState: blockedState ) {
            GameReducer()
        } withDependencies: {
            $0.gameClient = MockGameClient(
                randomPiece_impl: { .i },
                canPlacePiece_impl: { _, _ in true },
                canMovePiece_impl: { state, offset in
                    let newCol = state.piecePosition.column + offset.column
                    return newCol >= 0 && newCol < state.board[0].count - 3
                },
                spawnPiece_impl: { _ in true },
                clearLines_impl: { _ in [] },
                checkLevelProgression_impl: { _ in false },
                removeLines_impl: { _, _ in }
            )

            $0.audioClient = AudioPlayerClient(
                play: { _ in true },
                toggleMute: { false }
            )
            $0.highScoreClient = HighScoreClient(
                load: { 0 },
                save: { _ in }
            )
        }
        await blockedStore.send(.moveLeft) // Should not move
    }

    @Test("Drop piece")
    func dropPiece() async {
        var initialState = GameReducer.State()
        initialState.currentPiece = Tetromino.create(.i)
        initialState.piecePosition = Position(row: 1, column: 4)

        let didPlaySound = LockIsolated(false)
        let store = TestStore(
            initialState: initialState ){
                GameReducer()
            } withDependencies: {
                $0.gameClient = MockGameClient(
                    randomPiece_impl: { .i },
                    canPlacePiece_impl: { _, _ in true },
                    canMovePiece_impl: { state, _ in state.piecePosition.row < 19 },
                    spawnPiece_impl: { _ in true },
                    clearLines_impl: { _ in [] },
                    checkLevelProgression_impl: { _ in false },
                    removeLines_impl: { _, _ in }
                )

                $0.audioClient = AudioPlayerClient(
                    play: { name in
                        #expect(name == "drop")
                        didPlaySound.setValue(true)
                        return true
                    },
                    toggleMute: { false }
                )
                $0.highScoreClient = HighScoreClient(
                    load: { 0 },
                    save: { _ in }
                )
            }

        await store.send(.drop) {
            $0.piecePosition.row = 19
        }

        #expect(didPlaySound.value)
        await store.receive(\.spawnNewPiece)
        await store.receive(\.checkLines)
        await store.receive(\.checkLevelProgression)
    }

    @Test("Clear lines")
    func clearLines() async {
        let clock = DispatchQueue.test
        var board = GameReducer.State.emptyBoard
        board[19] = Array(repeating: BlockColor.i, count: 10) // Full row

        var initialState = GameReducer.State()
        initialState.board = board
        initialState.currentPiece = Tetromino.create(.i)
        initialState.piecePosition = Position(row: 1, column: 4)

        let didPlaySound = LockIsolated(false)
        let store = TestStore(
            initialState: initialState ) {
                GameReducer()
            } withDependencies: {
                $0.mainQueue = clock.eraseToAnyScheduler()
                $0.gameClient = MockGameClient(
                    randomPiece_impl: { .i },
                    canPlacePiece_impl: { _, _ in true },
                    canMovePiece_impl: { _, _ in true },
                    spawnPiece_impl: { _ in true },
                    clearLines_impl: { state in
                        var linesToClear = [Int]()
                        for row in (0..<state.board.count).reversed() {
                            if state.board[row].allSatisfy({ $0 != nil }) {
                                linesToClear.append(row)
                            }
                        }
                        if !linesToClear.isEmpty {
                            var newBoard = state.board
                            let linesCleared = linesToClear.count
                            for row in linesToClear.sorted(by: >) {
                                newBoard.remove(at: row)
                            }
                            for _ in 0..<linesCleared {
                                newBoard.insert(Array(repeating: nil, count: state.board[0].count), at: 0)
                            }
                            state.board = newBoard
                            state.linesCleared += linesCleared
                            state.score += linesCleared * 100 * state.level
                        }
                        return linesToClear
                    },
                    checkLevelProgression_impl: { _ in false },
                    removeLines_impl: { lines, state in
                        var newBoard = state.board
                        for row in lines.sorted(by: >) {
                            newBoard.remove(at: row)
                        }
                        for _ in 0..<lines.count {
                            newBoard.insert(Array(repeating: nil, count: state.board[0].count), at: 0)
                        }
                        state.board = newBoard
                    }
                )
                $0.audioClient = AudioPlayerClient(
                    play: { name in
                        #expect(name == "line_clear")
                        didPlaySound.setValue(true)
                        return true
                    },
                    toggleMute: { false }
                )
                $0.highScoreClient = HighScoreClient(
                    load: { 0 },
                    save: { _ in }
                )
            }
        store.exhaustivity = .off
        await store.send(.checkLines) {
            $0.clearingLines = [19]
            $0.animationProgress = 0
            $0.score = 100
            $0.linesCleared = 1
        }

        #expect(didPlaySound.value)
        await store.receive(\.startClearingLines) //([19]))
        await clock.advance(by: .seconds(0.02))
        await store.receive(\.animateLineClearing) {
            $0.animationProgress = 0.05
        }

        await clock.advance(by: .seconds(0.98))
        for _ in 0..<49 {
            await store.receive(\.animateLineClearing) {
                $0.animationProgress += 0.05
            }
        }

        await store.receive(\.finishClearingLines) {
            $0.clearingLines = []
            $0.animationProgress = 0
        }
        await store.receive(\.checkLevelProgression)
        await store.receive(\.checkHighScore)
    }

    @Test("Check level up")
    func levelUp() async {
        let clock = DispatchQueue.test
        var initialState = GameReducer.State()
        initialState.linesCleared = 10
        initialState.linesToNextLevel = 10

        let didPlaySound = LockIsolated(false)
        let store = TestStore(
            initialState: initialState ){
                GameReducer()
            } withDependencies: {
                $0.mainQueue = clock.eraseToAnyScheduler()
                $0.gameClient = MockGameClient(
                    randomPiece_impl: { .i },
                    canPlacePiece_impl: { _, _ in true },
                    canMovePiece_impl: { _, _ in true },
                    spawnPiece_impl: { _ in true },
                    clearLines_impl: { _ in [] },
                    checkLevelProgression_impl: { state in
                        if state.linesCleared >= state.linesToNextLevel {
                            state.level += 1
                            state.linesToNextLevel += 10
                            state.gameSpeed = GameReducer.State.speedForLevel(state.level)
                            return true
                        }
                        return false
                    },
                    removeLines_impl: { _, _ in }
                )

                $0.audioClient = AudioPlayerClient(
                    play: { name in
                        #expect(name == "level_up")
                        didPlaySound.setValue(true)
                        return true
                    },
                    toggleMute: { false }
                )
                $0.highScoreClient = HighScoreClient(
                    load: { 0 },
                    save: { _ in }
                )
            }
        store.exhaustivity = .off
        await store.send(.checkLevelProgression) {
            $0.isLevelTransitioning = true
            $0.level = 2
            $0.linesToNextLevel = 20
            $0.gameSpeed = 0.95
        }

        #expect(didPlaySound.value)
        await clock.advance(by: .seconds(1))
        await store.receive(\.levelUpComplete) {
            $0.isLevelTransitioning = false
        }
    }

    @Test
    func toggleMute() async {
        let store = TestStore(
            initialState: GameReducer.State() ) {
                GameReducer()
            } withDependencies: {
                $0.audioClient = AudioPlayerClient(
                    play: { _ in true },
                    toggleMute: { true }
                )
                $0.gameClient = MockGameClient(
                    randomPiece_impl: { .i },
                    canPlacePiece_impl: { _, _ in true },
                    canMovePiece_impl: { _, _ in true },
                    spawnPiece_impl: { _ in true },
                    clearLines_impl: { _ in [] },
                    checkLevelProgression_impl: { _ in false },
                    removeLines_impl: { _, _ in }
                )
                $0.highScoreClient = HighScoreClient(
                    load: { 0 },
                    save: { _ in }
                )
            }

        await store.send(.toggleMute) {
            $0.isMuted = true
        }
    }

    @Test("High score")
    func highScore() async {
        var initialState = GameReducer.State()
        initialState.score = 500
        initialState.highScore = 200

        var didSaveHighScore = false
        let store = TestStore(
            initialState: initialState ){
                GameReducer()
            } withDependencies: {
                $0.gameClient = MockGameClient(
                    randomPiece_impl: { .i },
                    canPlacePiece_impl: { _, _ in true },
                    canMovePiece_impl: { _, _ in true },
                    spawnPiece_impl: { _ in true },
                    clearLines_impl: { _ in [] },
                    checkLevelProgression_impl: { _ in false },
                    removeLines_impl: { _, _ in }
                )
                $0.audioClient = AudioPlayerClient(
                    play: { _ in true },
                    toggleMute: { false }
                )
                $0.highScoreClient = HighScoreClient(
                    load: { 200 },
                    save: { score in
                        #expect(score == 500)
                        didSaveHighScore = true
                    }
                )
            }

        await store.send(.checkHighScore) {
            $0.highScore = 500
        }

        #expect(didSaveHighScore)
    }
}

// MARK: - Mock Dependencies
struct MockGameClient: GameClient {
    var randomPiece_impl: () -> BlockColor
    var canPlacePiece_impl: (_ state: GameReducer.State, _ piece: Tetromino) -> Bool
    var canMovePiece_impl: (_ state: GameReducer.State, _ offset: (row: Int, column: Int)) -> Bool
    var spawnPiece_impl: (_ state: inout GameReducer.State) -> Bool
    var clearLines_impl: (_ state: inout GameReducer.State) -> [Int]
    var checkLevelProgression_impl: (_ state: inout GameReducer.State) -> Bool
    var removeLines_impl: (_ linesToClear: [Int], _ state: inout GameReducer.State) -> Void


    func randomPiece() -> BlockColor {
        randomPiece_impl()
    }

    func canPlacePiece(_ state: GameReducer.State, _ piece: Tetromino) -> Bool {
        canPlacePiece_impl(state, piece)
    }

    func canMovePiece(_ state: GameReducer.State, _ offset: (row: Int, column: Int)) -> Bool {
        canMovePiece_impl(state, offset)
    }

    func spawnPiece(_ state: inout GameReducer.State) -> Bool {
        spawnPiece_impl(&state)
    }

    func clearLines(_ state: inout GameReducer.State) -> [Int] {
        clearLines_impl(&state)
    }

    func removeLines(_ linesToClear: [Int], _ state: inout GameReducer.State) {
        removeLines_impl(linesToClear, &state)
    }

    func checkLevelProgression(_ state: inout GameReducer.State) -> Bool {
        checkLevelProgression_impl(&state)
    }
}
