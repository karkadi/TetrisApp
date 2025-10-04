//
//  AudioPlayerClient.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 02/06/2025.
//

@preconcurrency import AVFoundation
import ComposableArchitecture
import UIKit

// MARK: - AudioPlayerClient (closure-based)
struct AudioPlayerClient: @unchecked Sendable {
    var play: @Sendable (_ name: String) async throws -> Bool
    // FIX: Changed synchronous functions to async because their live implementation
    // is confined to the @MainActor, requiring an asynchronous hop.
    var toggleMute: @Sendable () async -> Bool
    var isMuted: @Sendable () async -> Bool
    var setIsMuted: @Sendable (_ isMuted: Bool) async -> Void
    var stop: @Sendable () async -> Void
}

// MARK: - Live Implementation
extension AudioPlayerClient: DependencyKey {
    static let liveValue: AudioPlayerClient = {
        // Use the MainActor-isolated singleton for the live implementation
        let impl = DefaultAudioPlayerClient.shared
        return AudioPlayerClient(
            // play is async, so the MainActor hop is handled by the async nature
            play: { name in try await impl.play(name) },
            // FIX: Added 'await' since the closure is now async and impl is @MainActor
            toggleMute: { await impl.toggleMute() },
            isMuted: { await impl.isMuted() },
            setIsMuted: { isMuted in await impl.setIsMuted(isMuted) },
            stop: { await impl.stop() }
        )
    }()
}

// MARK: - Dependency Registration
extension DependencyValues {
    var audioClient: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}

/// The live implementation is now confined to the MainActor, making all access to its
/// methods safe in respect to the shared, mutable state it controls.
@MainActor
final class DefaultAudioPlayerClient {
    // Provide a singleton instance
    static let shared = DefaultAudioPlayerClient()

    // Private initializer to enforce singleton usage
    private init() {}

    func play(_ name: String) async throws -> Bool {
        // Access is safe due to @MainActor confinement on the class/method
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
                
                // FIX: Use nonisolated(unsafe) to capture the non-Sendable 'delegate'
                // in the @Sendable onTermination closure, and wrap the cleanup in a
                // Main Actor Task to ensure thread safety for AVAudioPlayer.
                let delegateToStop = delegate
                continuation.onTermination = { @Sendable [weak delegateToStop] _ in
                    Task { @MainActor in
                        // This line is now safe because Delegate is @unchecked Sendable
                        // and the player access is isolated to the Main Actor.
                        delegateToStop?.player.stop()
                    }
                }
            } catch {
                continuation.finish(throwing: error)
            }
        }
        return try await stream.first(where: { @Sendable _ in true }) ?? false
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

// FIX: Mark Delegate as @unchecked Sendable. This is safe because all access to its
// properties (especially the non-Sendable 'player') is guaranteed to be
// Main Actor-isolated or wrapped in a Main Actor Task.
private final class Delegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    /// WARNING FIXED: Confine the mutable static state to the MainActor.
    @MainActor static var sharedIsMuted = false

    let didFinishPlaying: @Sendable (Bool) -> Void
    let decodeErrorDidOccur: @Sendable (Error?) -> Void
    let player: AVAudioPlayer

    // FIX: Isolate the initializer to the MainActor since it accesses the @MainActor static property sharedIsMuted.
    @MainActor
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
        // This access is now safe because the init is @MainActor
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
    /// WARNING FIXED: Confine the mutable static state to the MainActor.
    @MainActor static var shared: Delegate?
}
