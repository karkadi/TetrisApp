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
        
        static let emptyBoard: [[BlockColor?]] = Array(
            repeating: Array(repeating: nil, count: 10),
            count: 20
        )
        
        init() {
            self.board = State.emptyBoard
            self.currentPiece = nil
            self.nextPiece = nil
            self.piecePosition = Position(row: 0, column: 4)
            self.gameSpeed = 0.5
            self.score = 0
            self.isGameOver = false
            self.isPaused = false
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
                var newBoard = state.board
                var linesCleared = 0
                
                for row in (0..<newBoard.count).reversed() {
                    if newBoard[row].allSatisfy({ $0 != nil }) {
                        newBoard.remove(at: row)
                        linesCleared += 1
                    }
                }
                
                for _ in 0..<linesCleared {
                    newBoard.insert(Array(repeating: nil, count: state.board[0].count), at: 0)
                }
                
                state.board = newBoard
                state.score += linesCleared * 100
                if linesCleared == 4 {
                    state.score += 400 // Bonus for Tetris
                }
                return .none
                
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
            }
        }
    }
    
    private enum TimerID {
        case gameTimer
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
