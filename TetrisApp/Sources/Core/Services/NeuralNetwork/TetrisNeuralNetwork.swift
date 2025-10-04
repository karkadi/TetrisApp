//
//  TetrisNeuralNetwork.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//

import Foundation

/// A simple neural network model for evaluating Tetris board states based on feature weights.
///
/// `TetrisNeuralNetwork` holds a set of weights, commonly derived from Tetris heuristics,
/// and provides a method to evaluate board features to a single score using a linear combination.
/// The default weights are based on a standard Tetris heuristic, but can be customized or loaded as needed.
///
/// - Note: This implementation uses a fixed number of weights and assumes the input features
///         vector matches in length.
///
/// ## Example
/// ```swift
/// let network = TetrisNeuralNetwork()
/// let features = [aggregateHeight, completeLines, holes, bumpiness]
/// let score = network.evaluate(features)
/// ```
///
/// ## Topics
/// - Feature evaluation
/// - Heuristic-based scoring
/// - Neural network weight management
struct TetrisNeuralNetwork: Sendable {
    var weights: [Double]
    
    init() {
        // Initial weights from a standard Tetris heuristic example
        weights = [-0.510066, 0.760666, -0.35663, -0.184483]
    }
    
    func evaluate(_ features: [Double]) -> Double {
        zip(features, weights).reduce(0) { $0 + $1.0 * $1.1 }
    }
    
    func load(from path: String) {
        // Implement file loading if needed (e.g., JSON deserialization)
        // For demo, left as stub
    }
    
    func bestPlacementScore(for piece: Tetromino, on board: [[BlockColor?]]) -> Double {
        var maxScore = -Double.infinity
        let cols = board[0].count
        for rot in 0..<4 {
            let rotated = piece.rotated(rot)
            let minBlockCol = rotated.blocks.map { $0.column }.min()!
            let maxBlockCol = rotated.blocks.map { $0.column }.max()!
            let minC = -minBlockCol
            let maxC = cols - 1 - maxBlockCol
            for col in minC...maxC {
                var dropRow = 0
                while rotated.canPlace(board: board, pos: Position(row: dropRow + 1, column: col)) {
                    dropRow += 1
                }
                let pos = Position(row: dropRow, column: col)
                if rotated.canPlace(board: board, pos: pos) {
                    let result = sharedFeatureExtractor.extractFeatures(board: board, afterPlacing: rotated, at: pos)
                    let score = evaluate(result.features)
                    if score > maxScore {
                        maxScore = score
                    }
                }
            }
        }
        return maxScore
    }
}
