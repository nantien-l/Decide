import AVFAudio
import Foundation
import Speech

@Observable
final class SpeechTranscriber {
    enum State: Equatable {
        case idle
        case listening
        case stopped
        case error(String)

        var isListening: Bool {
            if case .listening = self { true } else { false }
        }
    }

    var state: State = .idle
    var transcript = ""

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var isStarting = false
    private var hasInstalledTap = false

    func start(localeIdentifier: String?) async {
        guard !state.isListening, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }

        let speechStatus = await requestSpeechAuthorization()
        guard speechStatus == .authorized else {
            state = .error("Speech recognition permission is required.")
            return
        }

        guard await AVAudioApplication.requestRecordPermission() else {
            state = .error("Microphone permission is required.")
            return
        }

        let locale = localeIdentifier.map(Locale.init(identifier:)) ?? Locale.current
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            state = .error("Speech recognition is not available for this language.")
            return
        }

        stopAudio()
        speechRecognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            guard let format = validInputFormat(for: inputNode) else {
                stopAudio()
                state = .error("Microphone audio input is unavailable. Check your input device and try again.")
                return
            }

            removeInputTapIfNeeded()
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            hasInstalledTap = true

            audioEngine.prepare()
            try audioEngine.start()
            state = .listening

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        if result.isFinal {
                            self.stop()
                        }
                    }

                    if let error {
                        self.stopAudio()
                        self.state = .error(error.localizedDescription)
                    }
                }
            }
        } catch {
            stopAudio()
            state = .error(error.localizedDescription)
        }
    }

    func stop() {
        stopAudio()
        state = transcript.isEmpty ? .idle : .stopped
    }

    func resetError() {
        if case .error = state {
            state = .idle
        }
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func validInputFormat(for inputNode: AVAudioInputNode) -> AVAudioFormat? {
        let format = inputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            return nil
        }

        return format
    }

    private func removeInputTapIfNeeded() {
        guard hasInstalledTap else { return }

        audioEngine.inputNode.removeTap(onBus: 0)
        hasInstalledTap = false
    }

    private func stopAudio() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        removeInputTapIfNeeded()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
