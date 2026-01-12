import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false
    @Published var lastRecordingURL: URL?
    
    func checkPermissions() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = docPath.appendingPathComponent("recording.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        lastRecordingURL = audioRecorder?.url
    }
}
