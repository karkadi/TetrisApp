//
//  NeuralNetworkTrainer.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//

import Dependencies

struct NeuralNetworkTrainer: Sendable {
    var trainWithSelfPlay: @Sendable (_ episodes: Int) -> Void
    var loadPretrainedModel: @Sendable (_ path: String) -> Void
}

/// `NeuralNetworkTrainer` provides neural network training and model loading functionality for the Tetris game AI.
///
/// This dependency exposes two main operations:
/// - `trainWithSelfPlay`: Conducts evolutionary training of the neural network through self-play over a specified number of episodes.
///   The training evolves a population of neural network weights, evaluating each by simulating games and optimizing them with crossover and mutation.
/// - `loadPretrainedModel`: Loads neural network weights from a persisted file at the given path, allowing the use of external or previously trained models.
///
/// The type is designed to be used as a dependency key, making it easy to inject in other parts of the application using the dependency system.
///
/// Typical usage:
/// ```swift
/// dependencies.neuralNetworkTrainer.trainWithSelfPlay(100)
/// dependencies.neuralNetworkTrainer.loadPretrainedModel("modelPath")
/// ```
///
/// - Note: The implementation relies on game simulation and feature extraction to guide the evolutionary algorithm.
/// - SeeAlso: `DependencyKey`, `DependencyValues`
extension NeuralNetworkTrainer: DependencyKey {
    static let liveValue: NeuralNetworkTrainer = {
        @Sendable func playGame(with weights: [Double]) -> Double {
            sharedNeuralNetwork.weights = weights
            let gameClient = GameClientKey.liveValue
            var state = TetrisReducer.State()
            state.nextPiece = Tetromino.create(gameClient.randomPiece())
            if !gameClient.spawnPiece(&state) {
                return 0
            }
            while true {
                var bestScore = -Double.infinity
                var bestX = 0
                var bestRot = 0
                let current = state.currentPiece!
                let board = state.board
                let rows = board.count
                let cols = board[0].count
                for rot in 0..<4 {
                    let rotated = current.rotated(rot)
                    let blockColumns = rotated.blocks.map { $0.column }
                    let minBlockCol = blockColumns.min()!
                    let maxBlockCol = blockColumns.max()!
                    let minC = -minBlockCol
                    let maxC = cols - 1 - maxBlockCol
                    for col in minC...maxC {
                        var dropRow = 0
                        while rotated.canPlace(board: board, pos: Position(row: dropRow + 1, column: col)) {
                            dropRow += 1
                        }
                        let pos = Position(row: dropRow, column: col)
                        if rotated.canPlace(board: board, pos: pos) {
                            let features = sharedFeatureExtractor.extractFeatures(board: board, afterPlacing: rotated, at: pos)
                            let score = sharedNeuralNetwork.evaluate(features)
                            if score > bestScore {
                                bestScore = score
                                bestX = col
                                bestRot = rot
                            }
                        }
                    }
                }
                state.currentPiece = state.currentPiece!.rotated(bestRot)
                state.piecePosition.column = bestX
                while gameClient.canMovePiece(state, (row: 1, column: 0)) {
                    state.piecePosition.row += 1
                }
                if !gameClient.spawnPiece(&state) {
                    break
                }
                let lines = gameClient.clearLines(&state)
                gameClient.removeLines(lines, &state)
                _ = gameClient.checkLevelProgression(&state)
            }
            return Double(state.linesCleared)
        }
        
        return NeuralNetworkTrainer(
            trainWithSelfPlay: { episodes  in
                let populationSize = 20
                let mutationRate = 0.1
                let crossoverRate = 0.7
                var population: [[Double]] = (0..<populationSize).map { _ in
                    (0..<4).map { _ in Double.random(in: -1...1) }
                }
                for _ in 0..<episodes {
                    var fitness: [Double] = []
                    for weights in population {
                        fitness.append(playGame(with: weights))
                    }
                    let sortedIndices = fitness.indices.sorted { fitness[$0] > fitness[$1] }
                    var newPopulation: [[Double]] = []
                    for index in stride(from: 0, to: populationSize, by: 2) {
                        let p1Index = sortedIndices[index % sortedIndices.count]
                        let p2Index = sortedIndices[(index + 1) % sortedIndices.count]
                        let popul1 = population[p1Index]
                        let popul2 = population[p2Index]
                        var child1 = popul1
                        var child2 = popul2
                        if Double.random(in: 0..<1) < crossoverRate {
                            let point = Int.random(in: 1..<4)
                            child1 = Array(popul1[0..<point] + popul2[point..<4])
                            child2 = Array(popul2[0..<point] + popul1[point..<4])
                        }
                        child1 = child1.map { value in
                            Double.random(in: 0..<1) < mutationRate ? value + Double.random(in: -0.5..<0.5) : value
                        }
                        child2 = child2.map { value in
                            Double.random(in: 0..<1) < mutationRate ? value + Double.random(in: -0.5..<0.5) : value
                        }
                        newPopulation.append(child1)
                        if newPopulation.count < populationSize {
                            newPopulation.append(child2)
                        }
                    }
                    population = newPopulation
                }
                var bestFitness = -Double.infinity
                var bestWeights: [Double] = []
                for weights in population {
                    let fitness = playGame(with: weights)
                    if fitness > bestFitness {
                        bestFitness = fitness
                        bestWeights = weights
                    }
                }
                sharedNeuralNetwork.weights = bestWeights
            },
            loadPretrainedModel: { path in
                sharedNeuralNetwork.load(from: path)
            }
        )
    }()
}

extension DependencyValues {
    var neuralNetworkTrainer: NeuralNetworkTrainer {
        get { self[NeuralNetworkTrainer.self] }
        set { self[NeuralNetworkTrainer.self] = newValue }
    }
}
