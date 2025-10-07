//
//  GameReducerContTests.swift
//  TetrisAppTests
//
//  Created by Arkadiy KAZAZYAN on 05/10/2025.
//

import ComposableArchitecture
import Testing
import Foundation
@testable import TetrisApp

struct GameReducerContTests {

    @Test("Clear lines")
    func clearLines() async {
        let clock = DispatchQueue.test
        var board = TetrisReducer.State.emptyBoard
        board[19] = Array(repeating: BlockColor.iBlock, count: 10) // Full row
        
        var initialState = TetrisReducer.State()
        initialState.board = board
        initialState.currentPiece = Tetromino.create(.iBlock)
        initialState.piecePosition = Position(row: 1, column: 4)
        
        let didPlaySound = LockIsolated(false)
        let store = await TestStore(
            initialState: initialState ) {
                TetrisReducer()
            } withDependencies: {
                $0.mainQueue = clock.eraseToAnyScheduler()
                
                $0.gameClient = GameClient(randomPiece: { BlockColor.iBlock },
                                           canPlacePiece: { _, _ in true},
                                           canMovePiece: { _, _ in true},
                                           spawnPiece: { _ in true },
                                           clearLines: { state in
                    var linesToClear = [Int]()
                    for row in (0..<state.board.count).reversed() where state.board[row].allSatisfy({ $0 != nil }) {
                        linesToClear.append(row)
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
                                           removeLines: { lines, state in
                    var newBoard = state.board
                    for row in lines.sorted(by: >) {
                        newBoard.remove(at: row)
                    }
                    for _ in 0..<lines.count {
                        newBoard.insert(Array(repeating: nil, count: state.board[0].count), at: 0)
                    }
                    state.board = newBoard
                },
                                           checkLevelProgression: { _ in false })
                
                $0.audioClient = AudioPlayerClient(play: { name in
                    #expect(name == "line_clear")
                    didPlaySound.setValue(true)
                    return true
                },
                                                   toggleMute: { true },
                                                   isMuted: { false },
                                                   setIsMuted: { _ in },
                                                   stop: {})
                
                $0.settingsClient = SettingsClient(getIsMute: { false },
                                                   setIsMute: { _ in },
                                                   getHighScore: { 100 },
                                                   setHighScore: { _ in })
                
            }
        await store.setExhaustivity(.off)
        await store.send(.checkLines) {
            $0.clearingLines = [19]
            $0.animationProgress = 0
            $0.score = 100
            $0.linesCleared = 1
        }
        
        #expect(didPlaySound.value)
        await store.receive(\.startClearingLines) // ([19]))
        await clock.advance(by: .seconds(0.02))
        await store.receive(\.animateLineClearing) {
            $0.animationProgress = 0.05
        }
        
        await store.setExhaustivity(.off)
        await clock.advance(by: .seconds(0.98))
        //      for _ in 0..<49 {
        //          await store.receive(\.animateLineClearing) {
        //              $0.animationProgress += 0.05
        //           }
        //      }
        
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
        var initialState = TetrisReducer.State()
        initialState.linesCleared = 10
        initialState.linesToNextLevel = 10
        
        let didPlaySound = LockIsolated(false)
        let store = await TestStore(
            initialState: initialState ) {
                TetrisReducer()
            } withDependencies: {
                $0.mainQueue = clock.eraseToAnyScheduler()
                $0.gameClient = GameClient(randomPiece: { BlockColor.iBlock },
                                           canPlacePiece: { _, _ in true},
                                           canMovePiece: { _, _ in true},
                                           spawnPiece: { _ in true },
                                           clearLines: { _ in [] },
                                           removeLines: { _, _ in },
                                           checkLevelProgression: { state in
                    if state.linesCleared >= state.linesToNextLevel {
                        state.level += 1
                        state.linesToNextLevel += 10
                        state.gameSpeed = TetrisReducer.State.speedForLevel(state.level)
                        return true
                    }
                    return false
                })
                
                $0.audioClient = AudioPlayerClient(play: { name in
                    #expect(name == "NextLevel")
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
    
    @Test("Toggle mute should also toggle ")
    func toggleMute() async {
        let store = await TestStore(
            initialState: TetrisReducer.State() ) {
                TetrisReducer()
            } withDependencies: {
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
        
        await store.send(.view(.toggleMute)) {
            $0.isMuted = false
        }
    }
    
    @Test("High score")
    func highScore() async {
        var initialState = TetrisReducer.State()
        initialState.score = 500
        initialState.highScore = 200
        
        let store = await TestStore(
            initialState: initialState ) {
                TetrisReducer()
            } withDependencies: {
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
                                                   getHighScore: { 200 },
                                                   setHighScore: { score in
                    #expect(score == 500)
                })
            }
        
        await store.send(.checkHighScore) {
            $0.highScore = 500
        }

    }
    
}
