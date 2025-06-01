//
//  GameReducer.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import ComposableArchitecture
import Foundation

@Reducer
struct GameReducer {
    @ObservableState
    struct State: Equatable {
        var board: [[BlockColor?]]
        var currentPiece: Tetromino?
        var nextPiece: Tetromino?
        var piecePosition: Position
        var gameSpeed: Double
        var score: Int
        var isGameOver: Bool
        var isPaused: Bool
        var clearingLines: [Int] = []
        var animationProgress: Double = 0
        var level: Int = 1
        var linesCleared: Int = 0
        var linesToNextLevel: Int = 10
        var isLevelTransitioning: Bool = false
        
        static let emptyBoard: [[BlockColor?]] = Array(
            repeating: Array(repeating: nil, count: 10),
            count: 20
        )
        
        init() {
            self.board = State.emptyBoard
            self.currentPiece = nil
            self.nextPiece = nil
            self.piecePosition = Position(row: 0, column: 4)
            self.gameSpeed = Self.speedForLevel(1) // level 1 speed
            self.score = 0
            self.isGameOver = false
            self.isPaused = false
            self.level = 1
            self.clearingLines = []
            self.animationProgress = 0
            self.linesCleared = 0
            self.linesToNextLevel = 10
        }
        
        // Helper to calculate speed for each level
        static func speedForLevel(_ level: Int) -> Double {
            // Classic Tetris speed progression (faster as level increases)
            let baseSpeed = 1.0
            let speedReduction = min(Double(level - 1) * 0.05, 0.8)
            return baseSpeed - speedReduction
        }
    }
    
    enum Action {
        case startGame
        case pauseGame
        case resumeGame
        case endGame
        case moveLeft
        case moveRight
        case moveDown
        case rotate
        case drop
        case tick
        case checkLines
        case spawnNewPiece
        
        case startClearingLines([Int])
        case animateLineClearing
        case finishClearingLines
        
        case checkLevelProgression
        case levelUpComplete
    }
    
    @Dependency(\.mainQueue) var mainQueue
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startGame:
                state = State()
                state.currentPiece = Tetromino.create(randomPiece())
                state.nextPiece = Tetromino.create(randomPiece())
                return .run { [state] send in
                    for await _ in self.mainQueue.timer(interval: .seconds(state.gameSpeed)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: TimerID.gameTimer)
                
            case .pauseGame:
                state.isPaused = true
                return .cancel(id: TimerID.gameTimer)
                
            case .resumeGame:
                state.isPaused = false
                return .run { [state] send in
                    for await _ in self.mainQueue.timer(interval: .seconds(state.gameSpeed)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: TimerID.gameTimer)
                
            case .endGame:
                state.isGameOver = true
                return .cancel(id: TimerID.gameTimer)
                
            case .moveLeft:
                guard !state.isGameOver, !state.isPaused else { return .none }
                if canMovePiece(state, offset: (0, -1)) {
                    state.piecePosition.column -= 1
                }
                return .none
                
            case .moveRight:
                guard !state.isGameOver, !state.isPaused else { return .none }
                if canMovePiece(state, offset: (0, 1)) {
                    state.piecePosition.column += 1
                }
                return .none
                
            case .moveDown:
                guard !state.isGameOver, !state.isPaused else { return .none }
                if canMovePiece(state, offset: (1, 0)) {
                    state.piecePosition.row += 1
                    return .none
                } else {
                    return .send(.spawnNewPiece)
                }
                
            case .rotate:
                guard !state.isGameOver, !state.isPaused else { return .none }
                if let rotated = state.currentPiece?.rotated(), canPlacePiece(state, piece: rotated) {
                    state.currentPiece = rotated
                }
                return .none
                
            case .drop:
                guard !state.isGameOver, !state.isPaused else { return .none }
                while canMovePiece(state, offset: (1, 0)) {
                    state.piecePosition.row += 1
                }
                return .send(.spawnNewPiece)
                
            case .tick:
                guard !state.isGameOver, !state.isPaused else { return .none }
                return .send(.moveDown)
                
            case .checkLines:
                var linesToClear = [Int]()
                for row in (0..<state.board.count).reversed() {
                    if state.board[row].allSatisfy({ $0 != nil }) {
                        linesToClear.append(row)
                    }
                }
                if !linesToClear.isEmpty {
                    state.clearingLines = linesToClear
                    state.animationProgress = 0
                    return .merge(
                        .send(.startClearingLines(linesToClear)),
                        .run { send in
                            for await _ in self.mainQueue.timer(interval: .seconds(0.016)) {
                                await send(.animateLineClearing)
                            }
                        }
                            .cancellable(id: TimerID.lineClearAnimation)
                    )
                }
                return .none
                
            case .startClearingLines:
                return .none
                
            case .animateLineClearing:
                state.animationProgress += 0.05
                if state.animationProgress >= 1 {
                    return .send(.finishClearingLines)
                }
                return .none
                
            case .finishClearingLines:
                var newBoard = state.board
                var linesCleared = 0
                for row in state.clearingLines.sorted(by: >) {
                    newBoard.remove(at: row)
                    linesCleared += 1
                }
                
                for _ in 0..<linesCleared {
                    newBoard.insert(Array(repeating: nil, count: state.board[0].count), at: 0)
                }
                state.board = newBoard
                state.linesCleared += linesCleared
                state.score += linesCleared * 100 * state.level // Score multiplier based on level
                
                state.clearingLines = []
                state.animationProgress = 0
                if linesCleared == 4 {
                    state.score += 400 // Bonus for Tetris
                }
                return .run { send in
                    await send(.checkLevelProgression)
                }
                .cancellable(id: TimerID.lineClearAnimation)
                
            case .spawnNewPiece:
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
                    return .send(.endGame)
                }
                state.currentPiece = state.nextPiece
                state.nextPiece = Tetromino.create(randomPiece())
                state.piecePosition = Position(row: 0, column: 4)
                if !canPlacePiece(state, piece: state.currentPiece!) {
                    return .send(.endGame)
                }
                return .send(.checkLines)
                
            case .checkLevelProgression:
                if state.linesCleared >= state.linesToNextLevel {
                    state.isLevelTransitioning = true
                    state.level += 1
                    state.linesToNextLevel += 10 // Standard Tetris: level up every 10 lines
                    state.gameSpeed = State.speedForLevel(state.level)
                    
                    
                    return .merge(.cancel(id: TimerID.gameTimer),
                                  .run { send in
                                      try await Task.sleep(for: .seconds(1))
                                      await send(.levelUpComplete)
                                  }
                        .cancellable(id: TimerID.gameTimer)
                    )
                }
                return .none
            case .levelUpComplete:
                state.isLevelTransitioning = false
                if !state.isPaused && !state.isGameOver {
                    return .run { [state] send in
                        for await _ in self.mainQueue.timer(interval: .seconds(state.gameSpeed)) {
                            await send(.tick)
                        }
                    }
                    .cancellable(id: TimerID.gameTimer)
                }
                return .none
            }
        }
    }
    
    private enum TimerID {
        case gameTimer
        case lineClearAnimation
    }
    
    private func randomPiece() -> BlockColor {
        BlockColor.allCases.randomElement() ?? .i
    }
    
    private func canPlacePiece(_ state: State, piece: Tetromino) -> Bool {
        for block in piece.blocks {
            let row = state.piecePosition.row + block.row
            let column = state.piecePosition.column + block.column
            
            if row >= state.board.count || column < 0 || column >= state.board[0].count {
                return false
            }
            
            if row >= 0 && state.board[row][column] != nil {
                return false
            }
        }
        return true
    }
    
    private func canMovePiece(_ state: State, offset: (row: Int, column: Int)) -> Bool {
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
}
