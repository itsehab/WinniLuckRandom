//
//  SettingsView.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct SettingsView: View {
    @ObservedObject var settings: SettingsModel
    @StateObject private var storageManager = StorageManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingResetAlert = false
    @State private var showingMigrationAlert = false
    @State private var isMigrating = false
    @State private var showingVoiceSelection = false
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []
    
    var body: some View {
        NavigationView {
            Form {
                // Storage Settings Section
                storageSection
                
                // Sound Settings Section
                Section(header: Text("Sound Settings")) {
                    Toggle("Voice Enabled", isOn: $settings.voiceEnabled)
                        .onChange(of: settings.voiceEnabled) { _, _ in
                            settings.saveVoiceSetting()
                        }
                    
                    // Voice Selection
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Selected Voice")
                                .font(.body)
                            Text(currentVoiceDisplayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Change") {
                            loadAvailableVoices()
                            showingVoiceSelection = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showingVoiceSelection) {
                        voiceSelectionSheet
                    }
                    
                    // Test speech button
                    Button(action: {
                        SpeechHelper.shared.testSpeech()
                    }) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                            Text("Test Voice")
                            Spacer()
                        }
                    }
                    .disabled(!settings.voiceEnabled)
                    
                    // Refresh Siri voices button
                    Button(action: {
                        SpeechHelper.shared.refreshAndCheckSiriVoices()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.green)
                            Text("Refresh & Check Siri Voices")
                            Spacer()
                        }
                    }
                    .disabled(!settings.voiceEnabled)
                }
                            
                // Background Settings Section
                Section(header: Text("Background Settings")) {
                    HStack {
                        Text("Current Background")
                        Spacer()
                        
                        if settings.backgroundImage != nil {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.green)
                                Text("Custom Image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Image(systemName: "paintbrush")
                                    .foregroundColor(.blue)
                                Text("Default Gradient")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                                .foregroundColor(.blue)
                            Text("Select Background Image")
                                }
                            }
                            
                    if settings.backgroundImage != nil {
                        Button("Reset to Default Background") {
                            showingResetAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            if let newValue = newValue {
                loadSelectedImage(newValue)
                }
            }
            .alert("Reset Background", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings.resetBackground()
                }
            } message: {
                Text("Are you sure you want to reset the background to default?")
            }
        .alert("Migrate to CloudKit", isPresented: $showingMigrationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Migrate") {
                Task {
                    isMigrating = true
                    do {
                        try await storageManager.migrateLocalDataToCloudKit()
                        // Migration completed successfully
                        await MainActor.run {
                            storageManager.switchToCloudKit()
                        }
                    } catch {
                        print("Migration failed: \(error)")
                    }
                    isMigrating = false
                }
                }
            } message: {
            Text("This will copy all your local data to CloudKit. Your local data will remain unchanged.")
        }
    }
    
    // MARK: - Storage Section
    
    @ViewBuilder
    private var storageSection: some View {
        Section(header: Text("💾 Storage Settings")) {
            HStack {
                Image(systemName: storageManager.currentStorageType == .local ? "iphone" : "icloud")
                    .foregroundColor(storageManager.currentStorageType == .local ? .blue : .green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Storage")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(storageManager.storageDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if storageManager.isOnline {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
            }
            }
            
                        // CloudKit Switch (only show if CloudKit is available)
            if canUseCloudKit {
                Button("Switch to CloudKit") {
                    storageManager.switchToCloudKit()
                }
                .disabled(isMigrating)
                
                // Migration button (only show when on local storage)
                if storageManager.currentStorageType == .local {
                    Button("Migrate Data to CloudKit") {
                        showingMigrationAlert = true
                    }
                    .disabled(isMigrating)
                }
            }
            
            // Local Storage Switch
            Button("Switch to Local Storage") {
                storageManager.switchToLocalStorage()
            }
            .disabled(storageManager.currentStorageType == .local || isMigrating)
            
            // Storage Info
            if storageManager.currentStorageType == .local {
                NavigationLink("Storage Details") {
                    StorageInfoView()
                }
            }
            
            if isMigrating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Migrating data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Voice Selection Methods
    
    private var currentVoiceDisplayName: String {
        if let currentVoice = SpeechHelper.shared.getCurrentVoice() {
            return "\(currentVoice.name) (\(currentVoice.language))"
        }
        return "Auto-selected"
    }
    
    private func loadAvailableVoices() {
        availableVoices = SpeechHelper.shared.getAvailableVoices()
    }
    
    @ViewBuilder
    private var voiceSelectionSheet: some View {
        NavigationView {
            List {
                // Auto-select option
                Section(header: Text("Automatic Selection")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-select Best Spanish Voice")
                                .font(.body)
                            Text("Let the app choose the best Spanish voice (prioritizes Siri Voice 1 & 2)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if settings.selectedVoiceIdentifier == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.selectedVoiceIdentifier = nil
                        showingVoiceSelection = false
                    }
                }
                
                // Siri Voices (Any language)
                let siriVoices = availableVoices.filter { SpeechHelper.shared.isSiriVoice($0) }
                if !siriVoices.isEmpty {
                    Section(header: Text("🎤 Siri Voices")) {
                        ForEach(siriVoices, id: \.identifier) { voice in
                            voiceSelectionRow(voice: voice, isSiriVoice: true)
                        }
                    }
                }
                
                // Spanish voices (non-Siri)
                let spanishVoices = availableVoices.filter { 
                    $0.language.hasPrefix("es") && !SpeechHelper.shared.isSiriVoice($0)
                }
                if !spanishVoices.isEmpty {
                    Section(header: Text("🇪🇸 Spanish Voices")) {
                        ForEach(spanishVoices, id: \.identifier) { voice in
                            voiceSelectionRow(voice: voice, isSiriVoice: false)
                        }
                    }
                }
                
                // Other voices
                let otherVoices = availableVoices.filter { 
                    !$0.language.hasPrefix("es") && !SpeechHelper.shared.isSiriVoice($0)
                }
                if !otherVoices.isEmpty {
                    Section(header: Text("🌍 Other Languages")) {
                        ForEach(otherVoices, id: \.identifier) { voice in
                            voiceSelectionRow(voice: voice, isSiriVoice: false)
                        }
                    }
                }
            }
            .navigationTitle("Select Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingVoiceSelection = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func voiceSelectionRow(voice: AVSpeechSynthesisVoice, isSiriVoice: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(voice.name)
                        .font(.body)
                        .fontWeight(isSiriVoice ? .semibold : .regular)
                    
                    if isSiriVoice {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                if let siriType = SpeechHelper.shared.getSiriVoiceType(voice) {
                    Text(siriType)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 8) {
                    Text(voice.language.uppercased())
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    if voice.quality == .enhanced {
                        Text("Enhanced")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if voice.gender == .female {
                        Text("Female")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.pink.opacity(0.2))
                            .cornerRadius(4)
                    } else if voice.gender == .male {
                        Text("Male")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Preview button
                Button(action: {
                    SpeechHelper.shared.previewVoice(voice)
                }) {
                    Image(systemName: "play.circle")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                
                // Selection checkmark
                if settings.selectedVoiceIdentifier == voice.identifier {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            settings.selectedVoiceIdentifier = voice.identifier
            showingVoiceSelection = false
        }
    }
    
    // MARK: - Computed Properties
    
    private var canUseCloudKit: Bool {
        // Add logic here to check if CloudKit is available
        // For now, always return true - you can add proper CloudKit availability check later
        return true
    }
    
    // MARK: - Helper Methods
    
    private func loadSelectedImage(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    settings.saveBackgroundImage(uiImage)
                }
            }
        }
    }
}

// MARK: - Storage Info View

struct StorageInfoView: View {
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(storageManager.getStorageInfo())
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                if storageManager.currentStorageType == .local {
                    Button("Clear All Local Data") {
                        _ = LocalStorageService.shared.clearAllData()
                    }
                    .foregroundColor(.red)
                    .padding()
                }
            
            Spacer()
        }
            .padding()
        }
        .navigationTitle("Storage Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView(settings: SettingsModel())
} 