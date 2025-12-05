//
//  AudioPlaybackManager.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/4/25.
//


//
//  AudioPlaybackManager.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created on 12/2/25.
//

import Foundation
import AVFoundation

class AudioPlaybackManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    private var player: AVAudioPlayer?

    func play(url: URL) {
        // Stop any existing playback
        stop()

        do {
            // Configure audio session for speaker playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            try session.overrideOutputAudioPort(.speaker)

            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            print("Audio playback error: (error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying( player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        self.player = nil
    }

    func audioPlayerDecodeErrorDidOccur( player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: (error?.localizedDescription)")
        isPlaying = false
        self.player = nil
    }
}
