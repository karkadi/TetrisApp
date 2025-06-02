//
//  HighScoreClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 02/06/2025.
//


import Foundation
import ComposableArchitecture

struct HighScoreClient {
    var load: () -> Int
    var save: (Int) -> Void
}

extension HighScoreClient {
    static let live = HighScoreClient(
        load: {
            UserDefaults.standard.integer(forKey: "tetrisHighScore")
        },
        save: { score in
            UserDefaults.standard.set(score, forKey: "tetrisHighScore")
        }
    )
}

extension DependencyValues {
    var highScoreClient: HighScoreClient {
        get { self[HighScoreClientKey.self] }
        set { self[HighScoreClientKey.self] = newValue }
    }
    
    private enum HighScoreClientKey: DependencyKey {
        static let liveValue = HighScoreClient.live
    }
}
