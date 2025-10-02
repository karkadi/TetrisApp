//
//  TetrisFeatureExtractor.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//

struct ExtractionResult {
    let features: [Double]
    let boardAfter: [[BlockColor?]]
}

/// `TetrisFeatureExtractor` is responsible for analyzing the Tetris board after placing a tetromino and extracting numerical features.
///
/// This struct provides a method to evaluate a given board state for purposes such as AI decision-making or analytics.
/// The features extracted can help inform algorithms or systems about the structural properties and score opportunities of the board.
///
/// - Features extracted (in order):
///   1. **Aggregate Height:** The sum of the heights of all columns, representing how high the stack is overall.
///   2. **Lines Cleared:** The number of full lines removed as a result of placing the piece.
///   3. **Holes:** The total number of empty spaces beneath placed blocks, indicating how many inaccessible spaces are present.
///   4. **Bumpiness:** The sum of absolute differences between the heights of adjacent columns, measuring how uneven the surface is.
///
/// - Usage:
///     Call `extractFeatures(board:afterPlacing:at:)` with the current board, the tetromino, and placement position to receive an `ExtractionResult` containing these values and the board state after placement and line clearing.
struct TetrisFeatureExtractor {
    func extractFeatures(board: [[BlockColor?]], afterPlacing piece: Tetromino, at position: Position) -> ExtractionResult {
        var tempBoard = board
        for block in piece.blocks {
            let row = position.row + block.row
            let column = position.column + block.column
            if row >= 0 && row < tempBoard.count && column >= 0 && column < tempBoard[0].count {
                tempBoard[row][column] = piece.type
            }
        }
        
        var linesCleared = 0
        var newBoard = tempBoard
        for row in (0..<newBoard.count).reversed() where newBoard[row].allSatisfy({ $0 != nil }) {
            newBoard.remove(at: row)
            linesCleared += 1
        }
        for _ in 0..<linesCleared {
            newBoard.insert(Array(repeating: nil, count: newBoard[0].count), at: 0)
        }
        
        var heights = [Int](repeating: 0, count: newBoard[0].count)
        for column in 0..<newBoard[0].count {
            for row in 0..<newBoard.count where newBoard[row][column] != nil {
                heights[column] = newBoard.count - row
                break
            }
        }
        
        let aggregateHeight = heights.reduce(0, +)
        
        var bumpiness = 0
        for index in 0..<heights.count - 1 {
            bumpiness += abs(heights[index] - heights[index + 1])
        }
        
        var holes = 0
        for column in 0..<newBoard[0].count {
            var seenFilled = false
            for row in 0..<newBoard.count {
                if newBoard[row][column] != nil {
                    seenFilled = true
                } else if seenFilled {
                    holes += 1
                }
            }
        }
        
        let features = [Double(aggregateHeight), Double(linesCleared), Double(holes), Double(bumpiness)]
        return ExtractionResult(features: features, boardAfter: newBoard)
    }
}
