import AVFoundation
import Speech
import SwiftUI

// MARK: - Voice Input View

struct VoiceInputView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var waveAmplitudes: [CGFloat] = Array(repeating: 0.3, count: 10)

    // Speech recognition
    @State private var speechRecognizer: SFSpeechRecognizer?
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    var body: some View {
        ZStack {
            TodoTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                Spacer()

                // Voice area
                voiceAreaView

                Spacer()
            }
        }
        .onAppear {
            setupSpeechRecognition()
        }
        .onDisappear {
            stopRecording()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Voice Input")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    // MARK: - Voice Area

    private var voiceAreaView: some View {
        VStack(spacing: 40) {
            // Wave animation
            waveAnimationView

            // Transcript card
            transcriptCardView

            // AI status
            if !transcribedText.isEmpty {
                aiStatusView
            }

            // Control buttons
            controlButtonsView
        }
    }

    // MARK: - Wave Animation

    private var waveAnimationView: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(TodoTheme.accentGradientVertical)
                    .frame(width: 4, height: isRecording ? waveAmplitudes[index] * 100 : 30)
                    .animation(
                        .easeInOut(duration: 0.3)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.05),
                        value: isRecording
                    )
            }
        }
        .frame(height: 120)
        .onAppear {
            if isRecording {
                animateWaves()
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                animateWaves()
            }
        }
    }

    private func animateWaves() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard isRecording else {
                timer.invalidate()
                return
            }
            for i in 0 ..< waveAmplitudes.count {
                waveAmplitudes[i] = CGFloat.random(in: 0.3 ... 1.0)
            }
        }
    }

    // MARK: - Transcript Card

    private var transcriptCardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isRecording ? "Listening..." : "Tap mic to start")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(TodoTheme.textTertiary)

            Text(transcribedText.isEmpty ? "\"Your task will appear here...\"" : "\"\(transcribedText)\"")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(TodoTheme.textPrimary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(width: 350)
        .glassCard(cornerRadius: 24)
    }

    // MARK: - AI Status

    private var aiStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
            Text("AI is processing your task...")
                .font(.system(size: 14))
        }
        .foregroundStyle(TodoTheme.accentPurple)
    }

    // MARK: - Control Buttons

    private var controlButtonsView: some View {
        HStack(spacing: 24) {
            // Cancel button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }

            // Mic button
            Button {
                toggleRecording()
            } label: {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(TodoTheme.accentGradient)
                    .clipShape(Circle())
                    .shadow(color: TodoTheme.accentPurple.opacity(0.5), radius: 30, y: 8)
            }

            // Send button
            Button {
                submitTask()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(TodoTheme.accentGreen)
                    .clipShape(Circle())
                    .shadow(color: TodoTheme.accentGreen.opacity(0.4), radius: 16, y: 4)
            }
            .opacity(transcribedText.isEmpty ? 0.5 : 1)
            .disabled(transcribedText.isEmpty)
        }
    }

    // MARK: - Speech Recognition

    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    print("Speech recognition not authorized")
                }
            }
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard let speechRecognizer, speechRecognizer.isAvailable else { return }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine failed to start: \(error)")
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result {
                transcribedText = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                stopRecording()
            }
        }
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
    }

    private func submitTask() {
        guard !transcribedText.isEmpty else { return }
        dismiss()
        Task {
            await appModel.processTaskWithAI(input: transcribedText)
        }
    }
}

// MARK: - Preview

#Preview {
    VoiceInputView()
        .environment(AppModel())
}
