//
//  AINetworkManager.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 05/10/2025.
//

// Global shared state is now an instance of the actor.
let networkManager = AINetworkManager()
// 1. Actor to protect the mutable state of the neural network

actor AINetworkManager {
    // This is the mutable state, now isolated within the actor
    private var neuralNetwork = TetrisNeuralNetwork()

    // Isolated accessors for reading/writing state
    func getWeights() -> [Double] {
        return neuralNetwork.weights
    }
    
    func setWeights(_ weights: [Double]) {
        neuralNetwork.weights = weights
    }
    
    func load(from path: String) {
        neuralNetwork.load(from: path)
    }
    
    // Pass-through functions for evaluation
    func evaluate(features: [Double]) -> Double {
        return neuralNetwork.evaluate(features)
    }

    func bestPlacementScore(for piece: Tetromino, on board: [[BlockColor?]]) -> Double {
        return neuralNetwork.bestPlacementScore(for: piece, on: board)
    }
}
