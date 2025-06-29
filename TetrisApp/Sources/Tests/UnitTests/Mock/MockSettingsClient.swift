//
//  MockSettingsClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//
import Foundation
@testable import TetrisApp

/// `MockSettingsClient` is a mock implementation of the `SettingsClientProtocol` designed for testing purposes.
/// 
/// This struct provides customizable closures for getting and setting the mute state and high score.
/// By default, it returns fixed values (`true` for mute state and `0` for high score), but the behavior
/// can be overridden by assigning new closure implementations to each property.
/// 
/// Usage of this mock allows you to simulate settings interactions in unit tests without modifying
/// the actual persistent storage or user settings.
///
/// - Note: All methods delegate their logic to the underlying closure properties.
/// - SeeAlso: `SettingsClientProtocol`
struct MockSettingsClient: SettingsClientProtocol {
    var getIsMuteImpl: () -> Bool = { true }
    var setIsMuteImpl: (Bool) -> Void = { _ in }
    var getHighScoreImpl: () -> Int = { 0 }
    var setHighScoreImpl: (Int) -> Void = { _ in }
    
    func getIsMute() -> Bool {
        getIsMuteImpl()
    }
    
    func setIsMute(_ muted: Bool) {
        setIsMuteImpl(muted)
    }
    
    func getHighScore() -> Int {
        getHighScoreImpl()
    }
    
    func setHighScore(_ score: Int) {
        setHighScoreImpl(score)
    }
    
}
