//
//  SettingsClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 02/06/2025.
//

import Foundation
import ComposableArchitecture

// MARK: - Protocol
protocol SettingsClientProtocol {
    func getIsMute() -> Bool
    func setIsMute(_: Bool)
    func getHighScore() -> Int
    func setHighScore(_: Int)
}

// MARK: - Settings Client
/// `SettingsClient` is a concrete implementation of the `SettingsClientProtocol`.
/// 
/// This class is responsible for persisting and retrieving user-specific settings
/// related to the Tetris app, such as sound muting and the high score. The settings
/// are stored using `@Shared(.appStorage)`, which provides thread-safe access and
/// persistence through UserDefaults. This ensures that the settings are consistent
/// across app launches and accessible from different parts of the app.
///
/// ## Features
/// - Get and set the mute state for app audio.
/// - Get and set the user's high score.
/// - Thread-safe writes using property wrappers and locking.
///
/// ## Usage
/// The recommended way to access an instance of `SettingsClient` is through
/// dependency injection with `DependencyValues` and `SettingsClientKey`.
///
/// - Note: Settings are persisted using app storage keys `"tetrisIsMute"` and `"tetrisHighScore"`.
class SettingsClient: SettingsClientProtocol {
    @Shared(.appStorage("tetrisIsMute")) var tetrisIsMute: Bool = false
    @Shared(.appStorage("tetrisHighScore")) var tetrisHighScore: Int = 0

    func getIsMute() -> Bool {
        tetrisIsMute
    }
    func setIsMute(_ newValue: Bool) {
        $tetrisIsMute.withLock { $0 = newValue }
    }
    func getHighScore() -> Int {
        tetrisHighScore
    }
    func setHighScore(_ newValue: Int) {
        $tetrisHighScore.withLock { $0 = newValue }
    }
}

// MARK: - Dependency Keys
enum SettingsClientKey: DependencyKey {
    static let liveValue: any SettingsClientProtocol = SettingsClient()
}

// MARK: - Dependency Registration
extension DependencyValues {
    var settingsClient: any SettingsClientProtocol {
        get { self[SettingsClientKey.self] }
        set { self[SettingsClientKey.self] = newValue }
    }
}
