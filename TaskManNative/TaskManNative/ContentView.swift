import SwiftUI
import Speech
import Combine

struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @StateObject private var audioRecorder = AudioRecorder()
    
    @State private var taskText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var isPulsing: Bool = false
    
    private let geminiService = GeminiService()
    
    var body: some View {
        TabView {
            // MARK: - Tab 1: Current Tasks
            NavigationView {
                ZStack {
                    Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        if viewModel.currentTasks.isEmpty {
                            EmptyStateView(title: "No Active Tasks", icon: "checklist")
                        } else {
                            List {
                                ForEach(viewModel.currentTasks) { task in
                                    TaskRowView(task: task) {
                                        viewModel.toggleTask(task)
                                    }
                                }
                                .onDelete(perform: viewModel.deleteTask)
                            }
                            .listStyle(InsetGroupedListStyle())
                        }
                    }
                    
                    if isLoading { ProcessingOverlay() }
                    
                    // Input Bar (Floating)
                    VStack {
                        Spacer()
                        InputBar(
                            text: $taskText,
                            isRecording: audioRecorder.isRecording,
                            isPulsing: isPulsing,
                            onRecord: toggleRecording,
                            onAdd: addTask
                        )
                    }
                }
                .navigationTitle("Current")
            }
            .tabItem {
                Label("Current", systemImage: "list.bullet.circle.fill")
            }
            
            // MARK: - Tab 2: History
            NavigationView {
                List {
                    ForEach(viewModel.historyTasks) { task in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(task.text)
                                .strikethrough()
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("History")
                .toolbar {
                    if !viewModel.historyTasks.isEmpty {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Clear") {
                                viewModel.clearHistory()
                            }
                        }
                    }
                }
                .overlay(
                    Group {
                        if viewModel.historyTasks.isEmpty {
                            EmptyStateView(title: "No History Yet", icon: "clock.arrow.circlepath")
                        }
                    }
                )
            }
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
        }
        .onAppear {
            Task {
                await audioRecorder.checkPermissions()
                requestSpeechPermission()
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown Error"), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Logic
    
    func toggleRecording() {
        if audioRecorder.isRecording {
            stopandProcessAudio()
            withAnimation { isPulsing = false }
        } else {
            startRecording()
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
    
    func addTask() {
        guard !taskText.isEmpty else { return }
        withAnimation {
            viewModel.addTask(text: taskText)
        }
        taskText = ""
        HapticManager.shared.notification(type: .success)
    }
    
    func startRecording() {
        audioRecorder.startRecording()
        HapticManager.shared.impact(style: .medium)
    }
    
    func stopandProcessAudio() {
        audioRecorder.stopRecording()
        HapticManager.shared.impact(style: .medium)
        
        guard let url = audioRecorder.lastRecordingURL else { return }
        withAnimation { isLoading = true }
        
        Task {
            do {
                let spokenText = try await transcribeAudio(url: url)
                let tasks = try await geminiService.processText(spokenText)
                
                DispatchQueue.main.async {
                    withAnimation {
                        for task in tasks {
                            self.viewModel.addTask(text: task)
                        }
                        self.isLoading = false
                    }
                    HapticManager.shared.notification(type: .success)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    func transcribeAudio(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            let request = SFSpeechURLRecognitionRequest(url: url)
            
            recognizer?.recognitionTask(with: request) { (result, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}

// MARK: - Subviews

struct InputBar: View {
    @Binding var text: String
    var isRecording: Bool
    var isPulsing: Bool
    var onRecord: () -> Void
    var onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if isRecording {
                // Recording State
                HStack {
                    Text("Listening...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    WaveformView(color: .red, barCount: 7)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                // Text Input
                TextField("New Task", text: $text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            // Record Button
            Button(action: onRecord) {
                ZStack {
                    if isRecording {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .scaleEffect(isPulsing ? 1.2 : 1.0)
                    }
                    
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(isRecording ? Color.red : Color.blue)
                        .clipShape(Circle())
                        .shadow(color: isRecording ? Color.red.opacity(0.4) : Color.blue.opacity(0.4), radius: 5, x: 0, y: 3)
                }
            }
            
            // Add Button (Only show if text exists)
            if !text.isEmpty {
                Button(action: onAdd) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        .padding(.top, 10)
        .background(
            VisualEffectBlur(blurStyle: .systemChromeMaterial)
                .ignoresSafeArea()
        )
    }
}

struct EmptyStateView: View {
    var title: String
    var icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Material.ultraThin)
            .cornerRadius(20)
        }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

#Preview {
    ContentView()
}
