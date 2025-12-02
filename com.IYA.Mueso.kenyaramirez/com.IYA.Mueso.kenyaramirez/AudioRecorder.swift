//
//  AudioRecorder.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// AudioRecorder.swift

import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var currentTime: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            session.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self?.beginRecording()
                    }
                }
            }
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func beginRecording() {
        let url = recordingURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
            startTimer()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        isRecording = false
        stopTimer()
        let url = recorder?.url
        recorder = nil
        return url
    }

    private func recordingURL() -> URL {
        let filename = "audio-\(UUID().uuidString).m4a"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(filename)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.currentTime = self?.recorder?.currentTime ?? 0
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
