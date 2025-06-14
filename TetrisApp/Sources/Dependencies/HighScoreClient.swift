//
//  HighScoreClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 02/06/2025.
//

import Foundation
import ComposableArchitecture

/// An interface for managing the Tetris game's high score persistence
///
/// This client abstracts loading and saving operations for the high score,
/// allowing different implementations (e.g., live, test, preview). The live
/// implementation uses `UserDefaults` with the key "tetrisHighScore".
///
/// - Important: The `save` operation overwrites any previous value immediately.
///   Callers must validate scores before saving to ensure correctness.

/// Loads the current persisted high score
///
/// - Returns: The integer value of the current high score. Returns `0`
///   if no value exists (per `UserDefaults` behavior).

/// Saves a new high score to persistent storage
///
/// Replaces any existing value immediately without validation. The caller
/// must ensure this is called with appropriate values only.
/// - Parameter score: The new high score value to persist
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
