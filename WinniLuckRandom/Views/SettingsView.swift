//
//  SettingsView.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsModel
    @StateObject private var storageManager = StorageManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingResetAlert = false
    @State private var showingMigrationAlert = false
    @State private var isMigrating = false
    
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