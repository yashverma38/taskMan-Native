# TaskMan Native 🎙️✨

**TaskMan Native** is a smart, voice-first to-do list application for iOS. It uses **Apple's Native Speech Recognition** for real-time transcription and **Google Gemini 2.5 Flash** to intelligently extract actionable tasks from your voice commands.

## Features

-   **🗣️ Voice-to-Task**: Just speak naturally. "Buy milk, call the bank, and email John."
-   **🤖 Multi-Task Intelligence**: Powered by Gemini, the app automatically detects multiple distinct tasks from a single sentence and adds them instantly.
-   **🌊 Waveform Visualizer**: Beautiful, Apple-style animated waveform feedback while recording.
-   **🕰️ Auto-Archive**: Completed tasks hang around for 30 seconds (in case of mistakes) before automatically moving to the History tab.
-   **🍎 Native Feel**: Built with SwiftUI, Haptics, and Dynamic Type to feel right at home on iOS.

## Tech Stack

-   **Language**: Swift 6.0
-   **UI**: SwiftUI
-   **AI Model**: Google Gemini 2.5 Flash (via API)
-   **Speech**: `SFSpeechRecognizer` (On-device transcription)
-   **Architecture**: MVVM

## Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/yashverma38/taskMan-Native.git
cd taskMan-Native
```

### 2. Add API Key (Important!)
For security reasons, the API Key file is **not** included in this repository. You must create it manually.

1.  Get a free API Key from [Google AI Studio](https://aistudio.google.com/).
2.  Open the project in Xcode (`TaskManNative.xcodeproj`).
3.  Create a new file named `GeminiService.swift` inside the `TaskManNative` folder.
4.  Paste the following code:

```swift
import Foundation

// REPLACE WITH YOUR KEY
let GEMINI_API_KEY = "PASTE_YOUR_AIza_KEY_HERE"

class GeminiService {
    
    func processText(_ text: String) async throws -> [String] {
        // Endpoint for Gemini 2.5 Flash
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(GEMINI_API_KEY)"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        // Construct Text Prompt
        let prompt = """
        Analyze the following text and extract actionable tasks.
        Return the result ONLY as a raw JSON array of strings.
        Example output: ["Buy milk", "Call John"]
        Do not use Markdown formatting.
        Text: "\(text)"
        """
        
        let json: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Send Request
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = jsonResponse["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            
            let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
            
            if let arrayData = cleanText.data(using: .utf8),
               let tasks = try? JSONDecoder().decode([String].self, from: arrayData) {
                return tasks
            }
            return [cleanText]
        }
        
        throw URLError(.cannotParseResponse)
    }
}
```

### 3. Run
Select your simulator (e.g., iPhone 16 Pro) and press **Cmd+R** to build and run.

## License
MIT
