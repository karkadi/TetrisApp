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
}

extension AudioPlayerClient: DependencyKey {
  static let liveValue = Self { name in
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
}

private final class Delegate: NSObject, AVAudioPlayerDelegate, Sendable {
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
  }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    self.didFinishPlaying(flag)
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    self.decodeErrorDidOccur(error)
  }
}

extension DependencyValues {
    var audioClient: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}
