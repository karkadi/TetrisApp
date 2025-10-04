//
//  SettingsClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 02/06/2025.
//

import Foundation
import ComposableArchitecture

struct SettingsClient: Sendable {
    var getIsMute: @Sendable () -> Bool
    var setIsMute: @Sendable (Bool) -> Void
    var getHighScore: @Sendable () -> Int
    var setHighScore: @Sendable (Int) -> Void
}

struct SettingsClientKey: DependencyKey {
    static let liveValue = SettingsClient(
        getIsMute: {
            @Shared(.appStorage("tetrisIsMute")) var mute = false
            return mute
        },
        setIsMute: { newValue in
            @Shared(.appStorage("tetrisIsMute")) var mute = false
            $mute.withLock { $0 = newValue }
        },
        getHighScore: {
            @Shared(.appStorage("tetrisHighScore")) var score = 0
            return score
        },
        setHighScore: { newValue in
            @Shared(.appStorage("tetrisHighScore")) var score = 0
            $score.withLock { $0 = newValue }
        }
    )
}

// MARK: - Dependency Registration
extension DependencyValues {
    var settingsClient: SettingsClient {
        get { self[SettingsClientKey.self] }
        set { self[SettingsClientKey.self] = newValue }
    }
}
