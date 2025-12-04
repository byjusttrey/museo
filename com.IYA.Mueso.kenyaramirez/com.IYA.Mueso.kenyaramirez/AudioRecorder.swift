//
//  AudioRecorder.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//

import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var currentTime: TimeInterval = 0
    @Published var recordingDuration: TimeInterval = 0
    @Published var averagePower: Float = -160.0 // dB, typically ranges from -160 to 0
    
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var meterTimer: Timer?

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
            recorder?.isMeteringEnabled = true // Enable metering for level visualization
            recorder?.record()
            isRecording = true
            recordingDuration = 0
            startTimer()
            startMeterTimer()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() -> URL? {
        guard let recorder = recorder else { return nil }
        recorder.stop()
        isRecording = false
        stopTimer()
        stopMeterTimer()
        let url = recorder.url
        let finalDuration = recordingDuration // Capture duration before resetting
        self.recorder = nil
        recordingDuration = 0
        averagePower = -160.0
        return url
    }
    
    // Get the current recording URL (if recording) or nil
    var currentRecordingURL: URL? {
        return recorder?.url
    }
    
    // Get the final duration when stopping (call before stopRecording)
    var finalDuration: TimeInterval {
        return recordingDuration
    }

    private func recordingURL() -> URL {
        let filename = "audio-\(UUID().uuidString).m4a"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(filename)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            self.recordingDuration += 1.0
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startMeterTimer() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.recorder, self.isRecording else { return }
            recorder.updateMeters()
            self.averagePower = recorder.averagePower(forChannel: 0)
        }
    }
    
    private func stopMeterTimer() {
        meterTimer?.invalidate()
        meterTimer = nil
    }
    
    // MARK: - Formatted Duration
    
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
