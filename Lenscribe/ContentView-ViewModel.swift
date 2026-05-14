//
//  ContentView-ViewModel.swift
//  Lenscribe
//
//  Created by Ranjan Bhakta on 12/04/26.
//

import Foundation
import SwiftUI
import Combine

struct Mood: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let prompt: String
}

enum FontStyle: String, CaseIterable, Identifiable {
    case system = "Classic"
    case serif = "Serif"
    case italic = "Italic"
    case mono = "Mono"
    
    var id: String { rawValue }
}

@MainActor
class ContentViewModel: ObservableObject {
    private struct AIContent: Decodable {
        let description: String
        let caption: String
    }

    @Published var selectedMood: Mood?
    
    @Published var selectedFont: FontStyle = .system

    let moods: [Mood] = [
        Mood(name: "Cinematic", prompt: "Describe this image in a cinematic, deamatic tone."),
        Mood(name: "Aesthetic", prompt: "Write a soft, aesthetic caption with calm vibes."),
        Mood(name: "Funny", prompt: "Generate a funny caption with humor."),
        Mood(name: "Travel", prompt: "Write a travel-style caption with excitement and exploration."),
        Mood(name: "Minimal", prompt: "Write a short, minimal caption")
    ]

    init() {
        selectedMood = moods.first
    }

    @Published var selectedUIImage: UIImage?
    
    @Published var metadata: PhotoMetaData?
    
    @Published var locationName: String = ""
    
    @Published var imageDescription: String = ""
    @Published var imageCaption: String = ""
    
    @Published var isGeneratingDescription: Bool = false
    @Published var isGeneratingCaption: Bool = false
    @Published var customPrompt: String = ""
    
    @Published var showSettings: Bool = false
    @Published var apiKey: String = ""
 
    func generateContent(for image: UIImage) async {
        isGeneratingDescription = true
        isGeneratingCaption = true

        imageDescription = ""
        imageCaption = ""

        let content = await generateAIContent(from: image)
        imageDescription = content.description
        imageCaption = content.caption

        isGeneratingDescription = false
        isGeneratingCaption = false
    }

    private func convertToBase64(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.5) else { return nil }
        return data.base64EncodedString()
    }

    private func generateAIContent(from image: UIImage) async -> AIContent {
        guard let base64 = convertToBase64(image: image) else {
            return AIContent(
                description: "Unable to process image",
                caption: "Unable to process image"
            )
        }

        let trimmedCustomPrompt = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalPrompt = selectedMood?.prompt
            ?? (!trimmedCustomPrompt.isEmpty ? trimmedCustomPrompt : "Describe this image")
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": """
                            Analyze this image and return valid JSON only with this exact shape:
                            Use this style instruction for both the description and caption: \(finalPrompt)
                            {
                              "description": "A natural, detailed sentence suitable for social media.",
                              "caption": "A short Instagram caption with emojis and 3-5 relevant hashtags."
                            }
                            Do not wrap the JSON in markdown fences.
                            """
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64
                            ]
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("Status code:", httpResponse.statusCode)
            }

            let parsedResponse = try JSONSerialization.jsonObject(with: data)

            if let json = parsedResponse as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String,
               let jsonData = text.data(using: .utf8) {
                return try JSONDecoder().decode(AIContent.self, from: jsonData)
            }
        } catch {
            print(error.localizedDescription)
        }

        return AIContent(
            description: "No description available",
            caption: "No caption available"
        )
    }
    
    func handleImageSelection(data: Data) async {
        guard let image = UIImage(data: data) else { return }
        
        // Image
        selectedUIImage = image
        
        // Metadata
        metadata = extractMetaData(from: data)
        
        // Location
        if let lat = metadata?.latitude,
           let lon = metadata?.longitude {
            getLocationName(lat: lat, lon: lon) { name in
                self.locationName = name
            }
        }
        
        // AI (description + caption)
      //  await generateContent(for: image)
    }
    
    func regenrateContent() async {
        guard let image = selectedUIImage else { return }
        await generateContent(for: image)
    }
    
    func fontForStyle(_ style: FontStyle, size: CGFloat) -> Font {
        switch style {
        case .system:
            return .system(size: size)
        case .serif:
            return .system(size: size, design: .serif)
        case .italic:
            return .system(size: size).italic()
        case .mono:
            return .system(size: size, design: .monospaced)
        }
    }
    
}
