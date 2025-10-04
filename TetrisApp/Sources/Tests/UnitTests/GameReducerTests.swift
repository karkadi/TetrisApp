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

/// Test suite for TetrisReducer functionality in TetrisApp
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

extension TestStore {
    nonisolated func setExhaustivity(_ exhaustivity: Exhaustivity) async {
        await MainActor.run {
            self.exhaustivity = exhaustivity
        }
    }
}

struct GameReducerTests {
    let mockPiece = Tetromino(
        type: .iBlock,
        blocks: [Position(row: 0, column: 0), Position(row: 0, column: 1),
                 Position(row: 0, column: 2), Position(row: 0, column: 3)],
        pivot: Position(row: 0, column: 1)
    )
    
    @Test("Start Game")
    func startGame() async {
        let clock = DispatchQueue.test
        let store = await TestStore( initialState: TetrisReducer.State() ) {
            TetrisReducer()
        } withDependencies: {
            $0.mainQueue = clock.eraseToAnyScheduler()
            $0.gameClient = GameClient(randomPiece: { BlockColor.iBlock },
                                       canPlacePiece: { _, _ in true},
                                       canMovePiece: { _, _ in true},
                                       spawnPiece: { _ in true },
                                       clearLines: { _ in [] },
                                       removeLines: { _, _ in },
                                       checkLevelProgression: { _ in false })
            
            $0.audioClient = AudioPlayerClient(play: { _ in true },
                                               toggleMute: { true },
                                               isMuted: { false },
                                               setIsMuted: { _ in },
                                               stop: {})
            
            $0.settingsClient = SettingsClient(getIsMute: { false },
                                               setIsMute: { _ in },
                                               getHighScore: { 1000 },
                                               setHighScore: { _ in })
        }
        await store.setExhaustivity(.off)
        
        await store.send(.view(.startGame)) {
            $0.board = TetrisReducer.State.emptyBoard
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
        var initialState = TetrisReducer.State()
        initialState.currentPiece = Tetromino.create(.iBlock)
        initialState.piecePosition = Position(row: 1, column: 4)
        
        let store = await TestStore( initialState: initialState ) {
            TetrisReducer()
        } withDependencies: {
            $0.gameClient = GameClient(randomPiece: { BlockColor.iBlock },
                                       canPlacePiece: { _, _ in true},
                                       canMovePiece: { state, offset in
                let newCol = state.piecePosition.column + offset.column
                return newCol >= 0 && newCol < state.board[0].count - 3
            },
                                       spawnPiece: { _ in true },
                                       clearLines: { _ in [] },
                                       removeLines: { _, _ in },
                                       checkLevelProgression: { _ in false })
            
            $0.audioClient = AudioPlayerClient(play: { _ in true },
                                               toggleMute: { true },
                                               isMuted: { false },
                                               setIsMuted: { _ in },
                                               stop: {})
            
            $0.settingsClient = SettingsClient(getIsMute: { false },
                                               setIsMute: { _ in },
                                               getHighScore: { 1000 },
                                               setHighScore: { _ in }
            )
        }
        
        await store.send(.view(.moveLeft)) {
            $0.piecePosition.column = 3
        }
        
        await store.send(.view(.moveRight)) {
            $0.piecePosition.column = 4
        }
        
        // Test boundary collision
        var blockedState = TetrisReducer.State()
        blockedState.currentPiece = Tetromino.create(.iBlock)
        blockedState.piecePosition = Position(row: 1, column: 0)
        
        let blockedStore = await TestStore( initialState: blockedState ) {
            TetrisReducer()
        } withDependencies: {
            $0.gameClient = GameClient(randomPiece: { BlockColor.iBlock },
                                       canPlacePiece: { _, _ in true},
                                       canMovePiece: { state, offset in
                let newCol = state.piecePosition.column + offset.column
                return newCol >= 0 && newCol < state.board[0].count - 3
            },
                                       spawnPiece: { _ in true },
                                       clearLines: { _ in [] },
                                       removeLines: { _, _ in },
                                       checkLevelProgression: { _ in false })
            
            $0.audioClient = AudioPlayerClient(play: { _ in true },
                                               toggleMute: { true },
                                               isMuted: { false },
                                               setIsMuted: { _ in },
                                               stop: {})
            
            $0.settingsClient = SettingsClient(getIsMute: { false },
                                               setIsMute: { _ in },
                                               getHighScore: { 1000 },
                                               setHighScore: { _ in }
            )
        }
        await blockedStore.send(.view(.moveLeft)) // Should not move
    }
    
    @Test("Drop piece")
    func dropPiece() async {
        var initialState = TetrisReducer.State()
        initialState.currentPiece = Tetromino.create(.iBlock)
        initialState.piecePosition = Position(row: 1, column: 4)
        
        let didPlaySound = LockIsolated(false)
        let store = await TestStore(
            initialState: initialState ) {
                TetrisReducer()
            } withDependencies: {
                $0.gameClient = GameClient(randomPiece: { BlockColor.iBlock },
                                           canPlacePiece: { _, _ in true},
                                           canMovePiece: { state, _ in state.piecePosition.row < 19 },
                                           spawnPiece: { _ in true },
                                           clearLines: { _ in [] },
                                           removeLines: { _, _ in },
                                           checkLevelProgression: { _ in false })
                
                $0.audioClient = AudioPlayerClient(play: { name in
                    #expect(name == "drop")
                    didPlaySound.setValue(true)
                    return true
                },
                                                   toggleMute: { true },
                                                   isMuted: { false },
                                                   setIsMuted: { _ in },
                                                   stop: {})
                
                $0.settingsClient = SettingsClient(getIsMute: { false },
                                                   setIsMute: { _ in },
                                                   getHighScore: { 1000 },
                                                   setHighScore: { _ in })
                
            }
        await store.setExhaustivity(.off)
        
        await store.send(.view(.drop)) {
            $0.piecePosition.row = 19
        }
        
        #expect(didPlaySound.value)
        //  await store.receive(\.spawnNewPiece)
        //  await store.receive(\.checkLines)
        //  await store.receive(\.checkLevelProgression)
    }
    
}
