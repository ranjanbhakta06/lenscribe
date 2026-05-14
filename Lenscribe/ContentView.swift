//  ContentView.swift
//  Lenscribe
//
//  Created by Ranjan Bhakta on 27/03/26.
//

import SwiftUI
import PhotosUI
import Vision

struct ContentView: View {
    @State private var pickerItem: PhotosPickerItem?
    
    @StateObject private var vm = ContentViewModel()
    
    @State private var selectedTab: Int = 0
    
    @State private var isPickerButtonAnimating = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    selectedImageSection
                    
                    if vm.selectedUIImage != nil {
                        stylePanel
                    }
                    
                    if vm.selectedUIImage != nil {
                        Picker("", selection: $selectedTab) {
                            Text("Description").tag(0)
                            Text("Caption").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    if selectedTab == 0 {
                        descriptionSection
                    } else {
                        captionSection
                    }
                    photoPickerSection
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .animation(.easeInOut(duration: 0.3), value: vm.selectedUIImage)
            }
            .background(Color(.systemGray5))
            .onChange(of: pickerItem) {
                Task {
                    if let data = try await pickerItem?.loadTransferable(type: Data.self) {
                        await vm.handleImageSelection(data: data)
                    }
                }
            }
            .sheet(isPresented: $vm.showSettings) {
                Settings_View(vm: vm)
            }
            .navigationTitle("Lenscribe")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let image = renderImage(),
                       let imageURL = renderedImageURL(for: image) {
                        ShareLink(
                            item: imageURL,
                            preview: SharePreview(
                                "Lenscribe Photo",
                                image: Image(uiImage: image)
                            )
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vm.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                }
            }
        }
    }
    
    private var stylePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Style")
                .font(.caption)
                .foregroundStyle(.black.opacity(0.8))
            
            moodSelector
            fontSelector
            customPromptField
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var selectedImageSection: some View {
        if let image = vm.selectedUIImage {
            shareCardView(for: image)
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .scale))
        }
    }
    
    private var customPromptField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Prompt")
                .font(.caption)
                .foregroundStyle(.black.opacity(0.8))
                .padding(.horizontal)
            
            TextField("Make it poetic, emotional, dramatic...", text: $vm.customPrompt)
                .padding()
                .background(.white)
                .tint(.black)
                .foregroundColor(.black)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
                .padding(.horizontal)
                .submitLabel(.done)
                .onChange(of: vm.customPrompt) { _, newValue in
                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        vm.selectedMood = nil
                    }
                }
            
            Button {
                Task {
                    await vm.regenrateContent()
                }
            } label: {
                Text("Generate")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(.horizontal)
            }
            .disabled(vm.selectedUIImage == nil)
            .opacity(vm.customPrompt.isEmpty ? 0.8 : 1)
        }
    }
    
    private var moodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(vm.moods) { mood in
                    Text(mood.name)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            vm.selectedMood == mood
                            ? Color.indigo
                            : Color.white
                        )
                        .foregroundStyle(
                            vm.selectedMood == mood ? .white : .black
                        )
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.05), radius: 4)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                vm.customPrompt = ""
                                vm.selectedMood = mood
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if vm.isGeneratingDescription {
            VStack(spacing: 16) {
                FloatingLettersView()
                    .frame(height: 80)
                
                Text("Generating...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4)
            .padding(.horizontal)
            .padding(.top, 8)
        } else if !vm.imageDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(vm.imageDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .background(.white)
                .foregroundStyle(.black)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var captionSection: some View {
        if vm.isGeneratingCaption {
            VStack(spacing: 12) {
                FloatingLettersView()
                    .frame(height: 80)
                
                Text("Generating caption...")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4)
            .padding(.horizontal)
            .padding(.top, 8)
        } else if !vm.imageCaption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(vm.imageCaption)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .background(.white)
                .foregroundStyle(.black)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private var fontSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Font")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.8))
                
                HStack(spacing: 12) {
                    ForEach(FontStyle.allCases) { style in
                        Text(style.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                vm.selectedFont == style
                                ? Color.indigo
                                : Color.white
                            )
                            .foregroundStyle(
                                vm.selectedFont == style ? .white : .black
                            )
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.05), radius: 4)
                            .onTapGesture {
                                vm.selectedFont = style
                            }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var photoPickerSection: some View {
        if vm.selectedUIImage != nil {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose another photo", systemImage: "arrow.triangle.2.circlepath")
            }
            .padding(10)
            .background(.indigo)
            .foregroundStyle(.white)
            .clipShape(.capsule)
        } else {
            ZStack {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 300))
                    .foregroundStyle(.indigo.opacity(0.5))
                    .blur(radius: 40)
                    .offset(y: -50)
            VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 48))
                            .foregroundStyle(.indigo)
                    }
                    
                    Text("Add captions, metadata, and style to your photos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 28))
                                
                                Text("Create Your Frame")
                                    .font(.headline)
                                
                                Text("Tap to choose a photo")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.indigo, Color.indigo.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 32)
                            .scaleEffect(isPickerButtonAnimating ? 1.03 : 1)
                            .onAppear {
                                guard !isPickerButtonAnimating else { return }
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    isPickerButtonAnimating = true
                                }
                            }
                            .onDisappear {
                                isPickerButtonAnimating = false
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    private func metadataSection(_ metadata: PhotoMetaData, isRendered: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(metadataSummaryText(for: metadata))
                .font(vm.fontForStyle(vm.selectedFont, size: isRendered ? 18 : 12))

            if !vm.locationName.isEmpty {
                Label(vm.locationName, systemImage: "location.fill")
                    .font(vm.fontForStyle(vm.selectedFont, size: isRendered ? 16 : 10))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(isRendered ? 24 : 16)
        .background(.white)
        .foregroundColor(.black)
    }

    private func shareCardView(for image: UIImage, renderWidth: CGFloat? = nil) -> some View {
        let isRendered = renderWidth != nil

        return VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(.white)

            if let metadata = vm.metadata {
                metadataSection(metadata, isRendered: isRendered)
            }
        }
        .frame(width: renderWidth)
        .padding(isRendered ? 24 : 8)
        .background(.white)
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.18), lineWidth: isRendered ? 6 : 1)
        )
        .shadow(color: .black.opacity(0.08), radius: isRendered ? 12 : 4)
    }

    private func metadataSummaryText(for metadata: PhotoMetaData) -> String {
        var components: [String] = []

        if let deviceModel = metadata.deviceModel, !deviceModel.isEmpty {
            components.append("Shot on \(deviceModel)")
        }

        if let aperture = metadata.aperture {
            components.append("f/\(formattedNumber(aperture))")
        }

        if let shutterSpeed = metadata.shutterSpeed {
            components.append(formattedShutterSpeed(shutterSpeed))
        }

        if let iso = metadata.iso {
            components.append("ISO \(iso)")
        }

        return components.isEmpty ? "No metadata available" : components.joined(separator: " • ")
    }

    private func formattedNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }

    private func formattedShutterSpeed(_ value: Double) -> String {
        guard value > 0 else { return "" }

        if value >= 1 {
            return "\(formattedNumber(value))s"
        }

        let denominator = Int((1 / value).rounded())
        return "1/\(denominator)s"
    }
    
    
    
    func renderImage() -> UIImage? {
        guard let image = vm.selectedUIImage else { return nil }

        let renderWidth: CGFloat = 1080
        let content = shareCardView(for: image, renderWidth: renderWidth)
            .background(.white)

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: renderWidth, height: nil)
        renderer.scale = 1
        
        return renderer.uiImage
    }

    private func renderedImageURL(for image: UIImage) -> URL? {
        guard let imageData = image.pngData() else { return nil }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("lenscribe-share.png")

        do {
            try imageData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }
}

#Preview {
    ContentView()
}
