//
//  TetrisReducer.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 31/05/2025.
//
import ComposableArchitecture
import Foundation

/// `TetrisReducer` manages the state and logic for a Tetris game using the Composable Architecture.
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
/// - `isDemoMode`: Demo mode flag
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
struct TetrisReducer {
    
    private enum TimerID {
        case gameTimer
        case lineClearAnimation
        case demoTimer
    }
    
    @ObservableState
    struct State: Equatable, Sendable {
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
        var isDemoMode: Bool
        
        static let emptyBoard: [[BlockColor?]] = Array(
            repeating: Array(repeating: nil, count: 10),
            count: 20
        )
        
        init(isMuted: Bool = false, highScore: Int = 0) {
            self.board = State.emptyBoard
            self.currentPiece = nil
            self.nextPiece = nil
            self.piecePosition = Position(row: 0, column: 4)
            self.gameSpeed = Self.speedForLevel(1)
            self.score = 0
            self.highScore = highScore
            self.isGameOver = false
            self.isPaused = false
            self.clearingLines = []
            self.animationProgress = 0
            self.level = 1
            self.linesCleared = 0
            self.linesToNextLevel = 10
            self.isLevelTransitioning = false
            self.isMuted = isMuted
            self.isDemoMode = false
        }
        
        static func speedForLevel(_ level: Int) -> Double {
            let baseSpeed = 1.0
            let speedReduction = min(Double(level - 1) * 0.05, 0.8)
            return baseSpeed - speedReduction
        }
    }
    
    enum Action: ViewAction, Sendable {
        case endGame
        case tick
        case checkLines
        case spawnNewPiece
        case startClearingLines([Int])
        case animateLineClearing
        case finishClearingLines
        case checkLevelProgression
        case levelUpComplete
        case checkHighScore
        // Demo actions
        case startDemo
        case tickDemo
        case stopDemo
        case setIsMuted(Bool)
        case view(View)
        // swiftlint:disable nesting
        enum View: Sendable {
            case onAppear
            case startGame
            case pauseGame
            case resumeGame
            case moveLeft
            case moveRight
            case moveDown
            case rotate
            case toggleMute
            case drop
        }
        // swiftlint:enable nesting
    }
    
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.gameClient) var gameClient
    @Dependency(\.audioClient) var audioClient
    @Dependency(\.settingsClient) var settingsClient
    @Dependency(\.neuralNetworkTrainer) var neuralNetworkTrainer
    @Dependency(\.neuralNetworkTetrisAI) var neuralNetworkTetrisAI
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                switch viewAction {
                case .onAppear:
                    let isMute = self.settingsClient.getIsMute()
                    state = State(isMuted: isMute, highScore: self.settingsClient.getHighScore())
                    state.isGameOver = true
                    state.isDemoMode = true
                    
                    // neuralNetworkTrainer.trainWithSelfPlay(1000)
                    
                    return .run { send in
                        await audioClient.setIsMuted(isMute)
                        await send(.startDemo)
                    }
                    
                case .startGame:
                    state = State()
                    state.highScore = self.settingsClient.getHighScore()
                    state.currentPiece = Tetromino.create(gameClient.randomPiece())
                    state.nextPiece = Tetromino.create(gameClient.randomPiece())
                    
                    return .merge(
                        .send(.stopDemo),
                        .run { [state] send in
                            let isMuted = await audioClient.isMuted()
                            await send(.setIsMuted(isMuted))
                            await audioClient.stop()
                            for await _ in self.mainQueue.timer(interval: .seconds(state.gameSpeed)) {
                                await send(.tick)
                            }
                        }
                            .cancellable(id: TimerID.gameTimer)
                    )
                    
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
                    
                    // Block user controls
                case .moveLeft:
                    guard !state.isPaused else { return .none }
                    if gameClient.canMovePiece(state, (0, -1)) {
                        state.piecePosition.column -= 1
                    }
                    return .none
                    
                case .moveRight:
                    guard !state.isPaused else { return .none }
                    if gameClient.canMovePiece(state, (0, 1)) {
                        state.piecePosition.column += 1
                    }
                    return .none
                    
                case .moveDown:
                    guard !state.isPaused else { return .none }
                    if gameClient.canMovePiece(state, (1, 0)) {
                        state.piecePosition.row += 1
                        return .none
                    } else {
                        return .send(.spawnNewPiece)
                    }
                    
                case .rotate:
                    guard !state.isPaused else { return .none }
                    if let rotated = state.currentPiece?.rotated(), gameClient.canPlacePiece(state, rotated) {
                        state.currentPiece = rotated
                    }
                    return .none
                    
                case .drop:
                    guard !state.isPaused else { return .none }
                    while gameClient.canMovePiece(state, (1, 0)) {
                        state.piecePosition.row += 1
                    }
                    
                    return .run { _ in
                        _ = try await audioClient.play("drop")
                    }
                    
                case .toggleMute:
                    // state.isMuted = await audioClient.toggleMute()
                    //  settingsClient.setIsMute(state.isMuted)
                    return .run { send in
                        let isMuted = await audioClient.toggleMute()
                        settingsClient.setIsMute(isMuted)
                        await send(.setIsMuted(isMuted))
                    }
                }
                
            case let .setIsMuted(muted):
                state.isMuted = muted
                return .none
                
            case .endGame:
                
                state.isGameOver = true
                return .merge(
                    .cancel(id: TimerID.gameTimer),
                    .run { _ in
                        _ = try await audioClient.play("TetrisTheme")
                    })
                
            case .tick:
                guard !state.isGameOver, !state.isPaused else { return .none }
                return .send(.view(.moveDown))
                
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
                    return .merge(
                        .send(.stopDemo),
                        .send(.endGame)
                    )
                }
                return .send(.checkLines)
                
            case .checkLevelProgression:
                if gameClient.checkLevelProgression(&state) {
                    state.isLevelTransitioning = true
                    return .merge(
                        .cancel(id: TimerID.gameTimer),
                        .run { send in
                            _ = try await audioClient.play("NextLevel")
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
                
            case .checkHighScore:
                if state.score > state.highScore && !state.isDemoMode {
                    state.highScore = state.score
                    settingsClient.setHighScore(state.highScore)
                }
                return .none
                
                // Demo related actions
            case .startDemo:
                state.isDemoMode = true
                state.currentPiece = Tetromino.create(gameClient.randomPiece())
                state.nextPiece = Tetromino.create(gameClient.randomPiece())
                return .run { send in
                    for await _ in self.mainQueue.timer(interval: .seconds(0.1)) {
                        await send(.tickDemo)
                    }
                }
                .cancellable(id: TimerID.demoTimer)
                
            case .stopDemo:
                return .merge(
                    .cancel(id: TimerID.demoTimer),
                    .run { _ in
                        await audioClient.stop()
                    })
                
            case .tickDemo:
                return .run { [state] send in
                    if let currentPiece = state.currentPiece {
                        let bestMove = await neuralNetworkTetrisAI.getBestMove(state.board, currentPiece, state.nextPiece)
                        // print("Test move: \(bestMove)")
                        
                        if bestMove.rotation > 0 {
                            await send(.view(.rotate))
                        }
                        if bestMove.x > state.piecePosition.column {
                            await send(.view(.moveRight))
                        } else if bestMove.x < state.piecePosition.column {
                            await send(.view(.moveLeft))
                        }
                    }
                    await send(.view(.moveDown))
                }
            }
        }
    }
}
