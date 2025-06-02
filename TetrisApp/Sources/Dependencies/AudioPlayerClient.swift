//
//  Delegate.swift
//  TetrisApp
//
//  Created by Arkadiy KAZAZYAN on 02/06/2025.
//

@preconcurrency import AVFoundation
import ComposableArchitecture
import UIKit

struct AudioPlayerClient {
    var play: @Sendable (String) async throws -> Bool
    var toggleMute: @Sendable () -> Bool
}

extension AudioPlayerClient: DependencyKey {
    static let liveValue = Self(
        play: { name in
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
        },
        toggleMute: {
            Delegate.sharedIsMuted.toggle()
            AVAudioPlayerDelegateWrapper.shared?.player.volume = Delegate.sharedIsMuted ? 0 : 1
            return Delegate.sharedIsMuted
        }
    )
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

extension DependencyValues {
    var audioClient: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}
