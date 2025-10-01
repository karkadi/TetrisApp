//
//  NeuralNetworkTetrisAI.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//

import Dependencies
var sharedNeuralNetwork = TetrisNeuralNetwork()
var sharedFeatureExtractor = TetrisFeatureExtractor()

struct NeuralNetworkTetrisAI: Sendable {
    var loadPretrainedModel: @Sendable (_ path: String) -> Void
    var getBestMove: @Sendable (_ board: [[BlockColor?]], _ currentPiece: Tetromino, _ nextPiece: Tetromino?) -> (x: Int, rotation: Int)
}

/// `NeuralNetworkTetrisAI` encapsulates the logic for a Tetris AI powered by a neural network.
///
/// This structure defines an interface for interacting with a neural network-based artificial intelligence
/// designed to play Tetris. It provides two key operations:
///
/// - Loading a pretrained neural network model from a given file path.
/// - Determining the best move (column and rotation) for the current tetromino, given the current board state
///   and optionally, the next tetromino piece.
///
/// `NeuralNetworkTetrisAI` is integrated with the dependency injection system, allowing for easy testability
/// and substitution within the app's architecture. The structure itself is `Sendable`, supporting use in
/// concurrent code.
///
/// - Properties:
///   - loadPretrainedModel: Loads a neural network model from the specified path.
///   - getBestMove: Given the current board, the current piece, and optionally the next piece, returns the
///     optimal (x, rotation) pair representing the best move identified by the neural network.
///
/// ### Usage Example
///
/// ```swift
/// let ai = DependencyValues().neuralNetworkTetrisAI
/// ai.loadPretrainedModel("MyModelFile.nn")
/// let bestMove = ai.getBestMove(board, piece, nextPiece)
/// print("Best move at column: \(bestMove.x), rotation: \(bestMove.rotation)")
/// ```
///
/// This type is exposed to dependency injection via `DependencyKey` and accessible through
/// `DependencyValues.neuralNetworkTetrisAI`.
extension NeuralNetworkTetrisAI: DependencyKey {
    static let liveValue: NeuralNetworkTetrisAI = {
        return NeuralNetworkTetrisAI(
            loadPretrainedModel: { path in
                sharedNeuralNetwork.load(from: path)
            },
            getBestMove: { board, currentPiece, _ in
                var bestScore = -Double.infinity
                var bestX = 0
                var bestRot = 0
                let rows = board.count
                let cols = board[0].count
                for rot in 0..<4 {
                    let rotated = currentPiece.rotated(rot)
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
                return (bestX, bestRot)
            }
        )
    }()
}

extension DependencyValues {
    var neuralNetworkTetrisAI: NeuralNetworkTetrisAI {
        get { self[NeuralNetworkTetrisAI.self] }
        set { self[NeuralNetworkTetrisAI.self] = newValue }
    }
}
