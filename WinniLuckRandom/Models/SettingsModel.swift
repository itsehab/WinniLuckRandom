//
//  SettingsModel.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI
import AVFoundation

class SettingsModel: ObservableObject {
    @Published var backgroundImage: UIImage?
    @Published var voiceEnabled: Bool = true
    @Published var backgroundImageSelected: Bool = false
    @Published var backgroundImageError: String?
    @Published var selectedVoiceIdentifier: String? {
        didSet {
            UserDefaults.standard.set(selectedVoiceIdentifier, forKey: "selectedVoiceIdentifier")
            // Notify SpeechHelper about the voice change
            SpeechHelper.shared.updateSelectedVoice(identifier: selectedVoiceIdentifier)
        }
    }
    
    private let backgroundImageKey = "backgroundImageData"
    private let voiceEnabledKey = "voiceEnabled"
    private let backgroundImageSelectedKey = "backgroundImageSelected"
    
    // Constants for validation
    private let maxImageFileSize: Int = 3_000_000 // 3MB max for storage
    private let compressionQuality: CGFloat = 0.7
    
    init() {
        loadSettings()
        // Load saved voice identifier
        self.selectedVoiceIdentifier = UserDefaults.standard.string(forKey: "selectedVoiceIdentifier")
        debugPrintStoredData()
    }
    
    func saveBackgroundImage(_ image: UIImage) {
        // Clear any previous error
        backgroundImageError = nil
        
        // Validate image before saving
        guard validateImage(image) else {
            handleImageError("Image validation failed")
            return
        }
        
        // Attempt to compress and save
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            handleImageError("Failed to compress image")
            return
        }
        
        // Check final size
        if data.count > maxImageFileSize {
            handleImageError("Image file too large after compression")
            return
        }
        
        // Save to UserDefaults with error handling
        do {
            UserDefaults.standard.set(data, forKey: backgroundImageKey)
            UserDefaults.standard.set(true, forKey: backgroundImageSelectedKey)
            
            // Verify the save was successful
            if let _ = UserDefaults.standard.data(forKey: backgroundImageKey) {
                DispatchQueue.main.async {
                    self.backgroundImageSelected = true
                    self.backgroundImage = image
                    print("✅ Background image saved successfully (\(data.count) bytes)")
                }
            } else {
                throw NSError(domain: "SettingsModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to verify save"])
            }
        } catch {
            handleImageError("Failed to save image: \(error.localizedDescription)")
        }
    }
    
    func loadSettings() {
        // Load voice setting with proper default handling
        if UserDefaults.standard.object(forKey: voiceEnabledKey) != nil {
            voiceEnabled = UserDefaults.standard.bool(forKey: voiceEnabledKey)
        } else {
            voiceEnabled = true // Default value
            UserDefaults.standard.set(true, forKey: voiceEnabledKey)
        }
        
        // Load background image with robust error handling
        loadBackgroundImageSafely()
    }
    
    private func loadBackgroundImageSafely() {
        guard let data = UserDefaults.standard.data(forKey: backgroundImageKey) else {
            // No background image stored - this is normal
            setDefaultBackgroundState()
            print("📱 No background image found - using default gradient")
            return
        }
        
        // Validate data size
        if data.count > maxImageFileSize {
            print("⚠️ Stored image data too large (\(data.count) bytes), resetting to default")
            resetBackgroundToDefault()
            return
        }
        
        // Attempt to create image from data
        guard let image = UIImage(data: data) else {
            print("❌ Failed to create image from stored data, resetting to default")
            resetBackgroundToDefault()
            return
        }
        
        // Validate the loaded image
        if validateImage(image) {
            backgroundImage = image
            backgroundImageSelected = UserDefaults.standard.bool(forKey: backgroundImageSelectedKey)
            print("✅ Background image loaded successfully")
        } else {
            print("❌ Loaded image failed validation, resetting to default")
            resetBackgroundToDefault()
        }
    }
    
    private func validateImage(_ image: UIImage) -> Bool {
        // Check basic image properties
        guard image.size.width > 0 && image.size.height > 0 else {
            print("❌ Invalid image dimensions")
            return false
        }
        
        // Check if image is too small (probably corrupted)
        guard image.size.width >= 100 && image.size.height >= 100 else {
            print("❌ Image too small (possible corruption)")
            return false
        }
        
        // Check if image is reasonable size (not corrupted/too large)
        guard image.size.width <= 10000 && image.size.height <= 10000 else {
            print("❌ Image dimensions too large")
            return false
        }
        
        // Try to get image data to ensure it's valid
        guard let _ = image.jpegData(compressionQuality: compressionQuality) else {
            print("❌ Cannot get image data")
            return false
        }
        
        return true
    }
    
    private func handleImageError(_ message: String) {
        print("❌ \(message)")
        DispatchQueue.main.async {
            self.backgroundImageError = message
            self.resetBackgroundToDefault()
        }
    }
    
    private func setDefaultBackgroundState() {
        backgroundImage = nil
        backgroundImageSelected = false
        backgroundImageError = nil
    }
    
    private func resetBackgroundToDefault() {
        UserDefaults.standard.removeObject(forKey: backgroundImageKey)
        UserDefaults.standard.set(false, forKey: backgroundImageSelectedKey)
        setDefaultBackgroundState()
        print("🔄 Background reset to default gradient")
    }
    
    func resetBackground() {
        backgroundImageError = nil
        resetBackgroundToDefault()
        print("🗑️ Background image manually reset")
    }
    
    func saveVoiceSetting() {
        UserDefaults.standard.set(voiceEnabled, forKey: voiceEnabledKey)
    }
    
    func clearImageError() {
        backgroundImageError = nil
    }
    
    // MARK: - Debug Methods
    
    func debugPrintStoredData() {
        print("\n=== SettingsModel Debug Info ===")
        print("Voice Enabled: \(voiceEnabled)")
        print("Background Image Selected: \(backgroundImageSelected)")
        print("Background Image: \(backgroundImage != nil ? "EXISTS" : "NIL")")
        print("Background Image Error: \(backgroundImageError ?? "NONE")")
        
        if let data = UserDefaults.standard.data(forKey: backgroundImageKey) {
            print("Stored Background Data Size: \(data.count) bytes")
            if data.count > maxImageFileSize {
                print("⚠️ WARNING: Stored data exceeds size limit!")
            }
        } else {
            print("No Background Data Stored")
        }
        print("=================================\n")
    }
    
    func resetAllSettings() {
        print("🔄 Resetting all app settings...")
        UserDefaults.standard.removeObject(forKey: backgroundImageKey)
        UserDefaults.standard.removeObject(forKey: voiceEnabledKey)
        UserDefaults.standard.removeObject(forKey: backgroundImageSelectedKey)
        
        // Reset to defaults
        voiceEnabled = true
        setDefaultBackgroundState()
        
        print("✅ All settings reset to default")
    }
} 