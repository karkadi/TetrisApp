//
//  Delegate.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 02/06/2025.
//

@preconcurrency import AVFoundation
import ComposableArchitecture
import UIKit

/// A client interface for playing audio assets and managing mute state.
///
/// This client provides a unified interface to:
/// 1. Play audio assets from the app's asset catalog
/// 2. Toggle global mute state affecting all playback
///
/// The implementation uses `AVAudioPlayer` under the hood and conforms to Swift Concurrency requirements.
/// All methods are thread-safe and can be used from any execution context.
///
/// - Note: Audio assets must be added as `NSDataAsset` in the asset catalog.

/// Asynchronously plays an audio asset from the app's bundle.
///
/// - Parameters:
///   - name: The name of the audio asset (without extension) in the asset catalog
/// - Returns: `true` if playback completed successfully, `false` if interrupted
/// - Throws: AudioError when asset is missing or decoding fails
/// - Important: Automatically respects current mute state. Won't play audio when muted.

/// Toggles the global mute state for all audio playback.
///
/// - Returns: The new mute state (`true` = muted, `false` = unmuted)
/// - Note: Immediately affects all player instances and future playback
///   - Sets volume to 0 when muted
///   - Restores volume to 1 when unmuted
protocol AudioPlayerClient {
    func play(_ name: String) async throws -> Bool
    func toggleMute() -> Bool
    func isMuted() -> Bool
    func setIsMuted(_: Bool)
    func stop()
}

class DefaultAudioPlayerClient: AudioPlayerClient {
    func play(_ name: String) async throws -> Bool {
        if Delegate.sharedIsMuted { return false }
        let stream = AsyncThrowingStream<Bool, Error> { continuation in
            do {
                let delegate = try Delegate(
                    name: name,
                    didFinishPlaying: { successful in
                        continuation.yield(successful)
                        continuation.finish()
                    },
                    decodeErrorDidOccur: { error in
                        continuation.finish(throwing: error)
                    }
                )
                delegate.player.play()
                continuation.onTermination = { _ in
                    delegate.player.stop()
                }
            } catch {
                continuation.finish(throwing: error)
            }
        }
        return try await stream.first(where: { _ in true }) ?? false
    }
    func toggleMute() -> Bool {
        Delegate.sharedIsMuted.toggle()
        AVAudioPlayerDelegateWrapper.shared?.player.volume = Delegate.sharedIsMuted ? 0 : 1
        return Delegate.sharedIsMuted
    }
    func isMuted() -> Bool {
        return Delegate.sharedIsMuted
    }
    func setIsMuted(_ isMuted: Bool) {
        AVAudioPlayerDelegateWrapper.shared?.player.volume = isMuted ? 0 : 1
        Delegate.sharedIsMuted = isMuted
    }
    func stop() {
        AVAudioPlayerDelegateWrapper.shared?.player.stop()
    }
}

private final class Delegate: NSObject, AVAudioPlayerDelegate, Sendable {
    static var sharedIsMuted = false

    let didFinishPlaying: @Sendable (Bool) -> Void
    let decodeErrorDidOccur: @Sendable (Error?) -> Void
    let player: AVAudioPlayer

    init(
        name: String,
        didFinishPlaying: @escaping @Sendable (Bool) -> Void,
        decodeErrorDidOccur: @escaping @Sendable (Error?) -> Void
    ) throws {
        self.didFinishPlaying = didFinishPlaying
        self.decodeErrorDidOccur = decodeErrorDidOccur
        guard let soundFile = NSDataAsset(name: name) else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        self.player = try AVAudioPlayer(data: soundFile.data)
        super.init()
        self.player.delegate = self
        self.player.volume = Self.sharedIsMuted ? 0 : 1
        AVAudioPlayerDelegateWrapper.shared = self
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.didFinishPlaying(flag)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.decodeErrorDidOccur(error)
    }
}

// Helper class to maintain reference to the current player delegate
private class AVAudioPlayerDelegateWrapper {
    static var shared: Delegate?
}

// MARK: - Dependency Keys
enum AudioPlayerClientKey: DependencyKey {
    static let liveValue: any AudioPlayerClient = DefaultAudioPlayerClient()
}

// MARK: - Dependency Registration
extension DependencyValues {
    var audioClient: AudioPlayerClient {
        get { self[AudioPlayerClientKey.self] }
        set { self[AudioPlayerClientKey.self] = newValue }
    }
}
