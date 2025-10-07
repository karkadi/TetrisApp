//
//  NeuralNetworkTrainerTest.swift
//  TetrisAppTests
//
//  Created by Arkadiy KAZAZYAN on 07/10/2025.
//

import Testing
@testable import TetrisApp

struct NeuralNetworkTrainerTest {

    @Test func testTrainWithSelfPlay() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let client = NeuralNetworkTrainer.liveValue
        
        client.trainWithSelfPlay(100)
        let weights = await networkManager.getWeights()
        #expect(weights[2] == -0.35663)
        
    }

}
