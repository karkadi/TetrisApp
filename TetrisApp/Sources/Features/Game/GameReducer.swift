//
//  GameReducer.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import ComposableArchitecture
import Foundation

/// `GameReducer` manages the state and logic for a Tetris game using the Composable Architecture.
///
/// ## State:
/// - `board`: 2D grid representing occupied blocks with `BlockColor`
/// - `currentPiece`: Active falling tetromino
/// - `nextPiece`: Upcoming tetromino piece
/// - `piecePosition`: Current position of active piece
/// - `gameSpeed`: Falling speed (decreases with level increases)
/// - `score`/`highScore`: Current and best recorded scores
/// - `isGameOver`/`isPaused`: Game state flags
/// - `clearingLines`/`animationProgress`: Line-clearing animation state
/// - `level`/`linesCleared`: Current level and cleared line count
/// - `linesToNextLevel`: Lines required to level up
/// - `isLevelTransitioning`: Level-up animation flag
/// - `isMuted`: Audio mute state
///
/// ## Actions:
/// - Game control: `startGame`, `pauseGame`, `resumeGame`, `endGame`
/// - Movement: `moveLeft`, `moveRight`, `moveDown`, `rotate`, `drop`
/// - Game loop: `tick` (triggers periodic downward movement)
/// - Line management: `checkLines`, `startClearingLines`, `animateLineClearing`, `finishClearingLines`
/// - Progression: `checkLevelProgression`, `levelUpComplete`
/// - Audio: `toggleMute`
/// - Scoring: `checkHighScore`
///
/// ## Dependencies:
/// - `mainQueue`: Handles game timing
/// - `gameClient`: Core game logic (movement validation, line clearing)
/// - `audioClient`: Sound effect playback
/// - `highScoreClient`: Persistent score storage
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
        var highScore: Int
        var isGameOver: Bool
        var isPaused: Bool
        var clearingLines: [Int]
        var animationProgress: Double
        var level: Int
        var linesCleared: Int
        var linesToNextLevel: Int
        var isLevelTransitioning: Bool
        var isMuted: Bool
        
        static let emptyBoard: [[BlockColor?]] = Array(
            repeating: Array(repeating: nil, count: 10),
            count: 20
        )
        
        init() {
            self.board = State.emptyBoard
            self.currentPiece = nil
            self.nextPiece = nil
            self.piecePosition = Position(row: 0, column: 4)
            self.gameSpeed = Self.speedForLevel(1)
            self.score = 0
            self.highScore = 0
            self.isGameOver = false
            self.isPaused = false
            self.clearingLines = []
            self.animationProgress = 0
            self.level = 1
            self.linesCleared = 0
            self.linesToNextLevel = 10
            self.isLevelTransitioning = false
            self.isMuted = false
        }
        
        static func speedForLevel(_ level: Int) -> Double {
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
        case toggleMute
        case checkHighScore
    }
    
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.gameClient) var gameClient
    @Dependency(\.audioClient) var audioClient
    @Dependency(\.highScoreClient) var highScoreClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startGame:
                state = State()
                state.highScore = self.highScoreClient.load()
                state.currentPiece = Tetromino.create(gameClient.randomPiece())
                state.nextPiece = Tetromino.create(gameClient.randomPiece())
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
                if gameClient.canMovePiece(state, (0, -1)) {
                    state.piecePosition.column -= 1
                }
                return .none
                
            case .moveRight:
                guard !state.isGameOver, !state.isPaused else { return .none }
                if gameClient.canMovePiece(state, (0, 1)) {
                    state.piecePosition.column += 1
                }
                return .none
                
            case .moveDown:
                guard !state.isGameOver, !state.isPaused else { return .none }
                if gameClient.canMovePiece(state, (1, 0)) {
                    state.piecePosition.row += 1
                    return .none
                } else {
                    return .send(.spawnNewPiece)
                }
                
            case .rotate:
                guard !state.isGameOver, !state.isPaused else { return .none }
                if let rotated = state.currentPiece?.rotated(), gameClient.canPlacePiece(state, rotated) {
                    state.currentPiece = rotated
                }
                return .none
                
            case .drop:
                guard !state.isGameOver, !state.isPaused else { return .none }
                while gameClient.canMovePiece(state, (1, 0)) {
                    state.piecePosition.row += 1
                }
                
                return .run { send in
                    _ = try await audioClient.play("drop")
                }
                
            case .tick:
                guard !state.isGameOver, !state.isPaused else { return .none }
                return .send(.moveDown)
                
            case .checkLines:
                let linesToClear = gameClient.clearLines(&state)
                if !linesToClear.isEmpty {
                    state.clearingLines = linesToClear
                    state.animationProgress = 0
                    
                    return .merge(
                        .send(.startClearingLines(linesToClear)),
                        .run { send in
                            for await _ in self.mainQueue.timer(interval: .seconds(0.02)) {
                                await send(.animateLineClearing)
                            }
                        }
                            .cancellable(id: TimerID.lineClearAnimation)
                    )
                }
                return .send(.checkLevelProgression)
                
            case .startClearingLines:
                return .run { _ in
                    _ = try await audioClient.play("line_clear")
                }
                
            case .animateLineClearing:
                state.animationProgress += 0.05
                if state.animationProgress >= 1 {
                    return .send(.finishClearingLines)
                }
                return .none
                
            case .finishClearingLines:
                gameClient.removeLines(state.clearingLines, &state)
                
                state.clearingLines = []
                state.animationProgress = 0
                return .merge(
                    .cancel(id: TimerID.lineClearAnimation),
                    .send(.checkLevelProgression),
                    .send(.checkHighScore)
                )
                
            case .spawnNewPiece:
                if !gameClient.spawnPiece(&state) {
                    return .send(.endGame)
                }
                return .send(.checkLines)
                
            case .checkLevelProgression:
                if gameClient.checkLevelProgression(&state) {
                    state.isLevelTransitioning = true
                    return .merge(
                        .cancel(id: TimerID.gameTimer),
                        .run { send in
                            _ = try await audioClient.play("level_up")
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
                
            case .toggleMute:
                state.isMuted = audioClient.toggleMute()
                return .none
                
            case .checkHighScore:
                if state.score > state.highScore {
                    state.highScore = state.score
                    highScoreClient.save(state.highScore)
                }
                return .none
            }
        }
    }
    
    private enum TimerID {
        case gameTimer
        case lineClearAnimation
    }
}
