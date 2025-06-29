//
//  MockAudioPlayerClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 30/09/2025.
//
import Foundation
@testable import TetrisApp

/// A mock implementation of the `AudioPlayerClient` protocol for use in testing.
///
/// `MockAudioPlayerClient` provides configurable closures for each method in the protocol,
/// allowing for flexible testing of audio-related behaviors without requiring actual audio playback.
/// Default implementations return success or "muted" responses, but these can be customized as needed.
///
/// - Note: Methods such as `setIsMuted(_:)` and `stop()` are implemented as no-ops by default.
struct MockAudioPlayerClient: AudioPlayerClient {
    var palyImpl: (String) async throws -> Bool = { _ in true }
    var toggleMuteImpl: () -> Bool = { true }
    var isMutedImpl: () -> Bool = { true }
    
    func play(_ name: String) async throws -> Bool {
        try await palyImpl(name)
    }
    
    func toggleMute() -> Bool {
        toggleMuteImpl()
    }
    
    func isMuted() -> Bool {
        isMutedImpl()
    }
    
    func setIsMuted(_: Bool) {
    }
    
    func stop() {
    }
}
