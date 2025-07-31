//
//  SpeechHelper.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import AVFoundation
import UIKit

@preconcurrency class SpeechHelper: NSObject, @unchecked Sendable {
    static let shared = SpeechHelper()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var _isSpeaking: Bool = false
    
    var isSpeaking: Bool {
        return _isSpeaking || synthesizer.isSpeaking
    }
    private var selectedVoice: AVSpeechSynthesisVoice?
    private var lastSpokenNumber: Int? = nil
    private var userSelectedVoiceIdentifier: String?
    private var speechCompletionCallback: (() -> Void)? = nil
    private var speechTimeoutTimer: Timer? = nil
    
    override init() {
        super.init()
        print("🎤 === SPEECH HELPER INITIALIZATION ===")
        setupAudioSession()
        synthesizer.delegate = self
        loadUserSelectedVoice()
        print("🎤 === SPEECH HELPER READY ===")
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        print("🎤 === AUDIO SESSION SETUP ===")
        print("🎤 Current category: \(audioSession.category)")
        print("🎤 Current mode: \(audioSession.mode)")
        print("🎤 Available categories: \(audioSession.availableCategories)")
        
        // Try multiple audio session configurations for maximum compatibility
        let configurations: [(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)] = [
            (.playAndRecord, .voicePrompt, [.defaultToSpeaker, .allowBluetooth]),
            (.playback, .voicePrompt, [.duckOthers, .allowBluetooth]),
            (.playback, .default, [.mixWithOthers]),
            (.ambient, .default, []),
            (.soloAmbient, .default, [])
        ]
        
        for (index, config) in configurations.enumerated() {
            do {
                try audioSession.setCategory(config.category, mode: config.mode, options: config.options)
                try audioSession.setActive(true)
                print("✅ Audio session configured successfully with config \(index + 1)")
                print("  Category: \(config.category), Mode: \(config.mode), Options: \(config.options)")
                print("  Device: \(UIDevice.current.model)")
                return
            } catch {
                print("❌ Config \(index + 1) failed: \(error)")
                continue
            }
        }
        
        print("❌ All audio session configurations failed!")
    }
    
    private func selectBestSpanishVoice() {
        // Get all available voices
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        print("🎤 === VOICE SELECTION START ===")
        print("🎤 Total available voices: \(availableVoices.count)")
        
        // Log ALL voices to help identify Siri Voice 1 and 2
        print("🎤 === ALL AVAILABLE VOICES ===")
        for (index, voice) in availableVoices.enumerated() {
            let qualityText = voice.quality == .enhanced ? "Enhanced" : "Default"
            let genderText = voice.gender == .female ? "Female" : voice.gender == .male ? "Male" : "Unknown"
            print("  \(index + 1). '\(voice.name)' (\(voice.language)) - \(qualityText) - \(genderText)")
        }
        print("🎤 === END ALL VOICES ===")
        
        print("🎤 Looking for Siri Voice 1 and 2...")
        
        // PRIORITY 1: Look for actual "Siri Voice 2" (Female Spanish)
        if let siriVoice2 = availableVoices.first(where: { voice in
            let name = voice.name.lowercased()
            return (name.contains("siri voice 2") || name == "siri voice 2") && voice.language.hasPrefix("es")
        }) {
            selectedVoice = siriVoice2
            print("🎯 FOUND SIRI VOICE 2: '\(siriVoice2.name)' (\(siriVoice2.language))")
            logFinalVoiceSelection()
            return
        }
        
        // PRIORITY 2: Look for actual "Siri Voice 1" (Spanish)
        if let siriVoice1 = availableVoices.first(where: { voice in
            let name = voice.name.lowercased()
            return (name.contains("siri voice 1") || name == "siri voice 1") && voice.language.hasPrefix("es")
        }) {
            selectedVoice = siriVoice1
            print("🎯 FOUND SIRI VOICE 1: '\(siriVoice1.name)' (\(siriVoice1.language))")
            logFinalVoiceSelection()
            return
        }
        
        // PRIORITY 3: Look for any voice with "siri" in the name (Spanish)
        if let siriVoice = availableVoices.first(where: { voice in
            voice.name.lowercased().contains("siri") && voice.language.hasPrefix("es")
        }) {
            selectedVoice = siriVoice
            print("🎯 FOUND SIRI VOICE: '\(siriVoice.name)' (\(siriVoice.language))")
            logFinalVoiceSelection()
            return
        }
        
        // PRIORITY 4: Enhanced quality Spanish voices
        if let enhancedVoice = availableVoices.first(where: { 
            $0.language.hasPrefix("es") && 
            $0.quality == .enhanced
        }) {
            selectedVoice = enhancedVoice
            print("✨ Found enhanced Spanish voice: \(enhancedVoice.name) (\(enhancedVoice.language))")
            logFinalVoiceSelection()
            return
        }
        
        // PRIORITY 5: Spanish Mexico voices
        if let mexicoVoice = availableVoices.first(where: { 
            $0.language == "es-MX"
        }) {
            selectedVoice = mexicoVoice
            print("🇲🇽 Using Mexico Spanish voice: \(mexicoVoice.name) (\(mexicoVoice.language))")
            logFinalVoiceSelection()
            return
        }
        
        // PRIORITY 6: Any Spanish voice
        if let spanishVoice = availableVoices.first(where: { 
            $0.language.hasPrefix("es")
        }) {
            selectedVoice = spanishVoice
            print("🇪🇸 Using Spanish voice: \(spanishVoice.name) (\(spanishVoice.language))")
            logFinalVoiceSelection()
            return
        }
        
        // Fallback: System default Spanish
        selectedVoice = AVSpeechSynthesisVoice(language: "es-ES")
        print("🔄 Using default Spanish voice")
        logFinalVoiceSelection()
    }
    
    private func logFinalVoiceSelection() {
        if let voice = selectedVoice {
            print("🎤 FINAL VOICE: \(voice.name) (\(voice.language))")
            print("🎤 Quality: \(voice.quality == .enhanced ? "Enhanced" : "Default")")
            print("🎤 Gender: \(voice.gender == .male ? "Male" : voice.gender == .female ? "Female" : "Unknown")")
        } else {
            print("🎤 ❌ NO VOICE SELECTED!")
        }
        print("🎤 === VOICE SELECTION END ===")
    }
    
    func speak(_ text: String) {
        print("🎤 === SPEECH ATTEMPT START ===")
        print("🎤 Text to speak: '\(text)'")
        print("🎤 Device: \(UIDevice.current.model)")
        print("🎤 iOS Version: \(UIDevice.current.systemVersion)")
        
        // Check audio session state
        let audioSession = AVAudioSession.sharedInstance()
        print("🎤 Audio session category: \(audioSession.category)")
        print("🎤 Audio session is active: \(audioSession.isOtherAudioPlaying)")
        print("🎤 Output volume: \(audioSession.outputVolume)")
        
        // Ensure audio session is active
        do {
            try audioSession.setActive(true)
            print("✅ Audio session activated successfully")
        } catch {
            print("❌ Could not activate audio session: \(error)")
            return
        }
        
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            print("🔄 Stopping existing speech")
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Use the selected voice or fallback
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "es-ES")
        
        // Use natural default voice settings - no custom adjustments
        
        print("🎤 Voice: \(utterance.voice?.name ?? "default") (\(utterance.voice?.language ?? "unknown"))")
        print("🎤 Using natural voice settings (no custom adjustments)")
        print("🎤 Synthesizer is speaking: \(synthesizer.isSpeaking)")
        print("🎤 Synthesizer is paused: \(synthesizer.isPaused)")
        
        _isSpeaking = true
        synthesizer.speak(utterance)
        
        print("🎤 Speech command sent to synthesizer")
        print("🎤 === SPEECH ATTEMPT END ===")
    }
    
    func speakNumber(_ number: Int, completion: (() -> Void)? = nil) {
        print("🎤 Speaking number: \(number)")
        print("🎤 Callback provided: \(completion != nil)")
        
        // Store completion callback before any early returns
        speechCompletionCallback = completion
        
        // Less aggressive duplicate prevention - only block if it's the EXACT same number within 2 seconds
        if lastSpokenNumber == number {
            print("🎤 ⚠️ BLOCKED duplicate speech for number: \(number)")
            // Still call completion even if blocked
            handleSpeechCompletion(success: true)
            return
        }
        
        // Stop any current speech first to prevent overlap
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            print("🎤 Stopped previous speech for new number: \(number)")
        }
        
        // Clear any existing timeout timer
        speechTimeoutTimer?.invalidate()
        speechTimeoutTimer = nil
        
        // Completion callback already stored above
        
        // CRITICAL: Set this BEFORE calling speak to prevent race conditions
        lastSpokenNumber = number
        
        // Convert number to clean Spanish pronunciation
        let numberText = formatNumberForSpanish(number)
        print("🎤 Speaking number \(number) as: '\(numberText)'")
        speak(numberText)
        
        // Set timeout timer (5 seconds) in case speech fails silently
        speechTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            print("🎤 ⏰ TIMEOUT: Speech for number \(number) timed out")
            self?.handleSpeechCompletion(success: false)
        }
        
        // Reduced reset delay to prevent blocking subsequent numbers (2 seconds instead of 4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.lastSpokenNumber == number {
                self.lastSpokenNumber = nil
                print("🎤 Reset speech blocker for number: \(number)")
            }
        }
    }
    
    private func handleSpeechCompletion(success: Bool) {
        // Clear timeout timer
        speechTimeoutTimer?.invalidate()
        speechTimeoutTimer = nil
        
        // Call completion callback if it exists
        if let callback = speechCompletionCallback {
            speechCompletionCallback = nil
            print("🎤 \(success ? "✅" : "❌") Calling speech completion callback")
            DispatchQueue.main.async {
                callback()
            }
        } else {
            print("🎤 ❌ No completion callback available")
        }
    }
    
    private func formatNumberForSpanish(_ number: Int) -> String {
        // Simple, clean number pronunciation in Spanish
        switch number {
        case 0:
            return "cero"
        case 1:
            return "uno"
        case 2:
            return "dos"
        case 3:
            return "tres"
        case 4:
            return "cuatro"
        case 5:
            return "cinco"
        case 6:
            return "seis"
        case 7:
            return "siete"
        case 8:
            return "ocho"
        case 9:
            return "nueve"
        case 10:
            return "diez"
        case 11:
            return "once"
        case 12:
            return "doce"
        case 13:
            return "trece"
        case 14:
            return "catorce"
        case 15:
            return "quince"
        case 16:
            return "dieciséis"
        case 17:
            return "diecisiete"
        case 18:
            return "dieciocho"
        case 19:
            return "diecinueve"
        case 20:
            return "veinte"
        case 21...29:
            let units = number - 20
            return "veinti" + getSimpleNumber(units)
        case 30:
            return "treinta"
        case 31...39:
            let units = number - 30
            return "treinta y " + getSimpleNumber(units)
        case 40:
            return "cuarenta"
        case 41...49:
            let units = number - 40
            return "cuarenta y " + getSimpleNumber(units)
        case 50:
            return "cincuenta"
        case 51...59:
            let units = number - 50
            return "cincuenta y " + getSimpleNumber(units)
        case 60:
            return "sesenta"
        case 61...69:
            let units = number - 60
            return "sesenta y " + getSimpleNumber(units)
        case 70:
            return "setenta"
        case 71...79:
            let units = number - 70
            return "setenta y " + getSimpleNumber(units)
        case 80:
            return "ochenta"
        case 81...89:
            let units = number - 80
            return "ochenta y " + getSimpleNumber(units)
        case 90:
            return "noventa"
        case 91...99:
            let units = number - 90
            return "noventa y " + getSimpleNumber(units)
        case 100:
            return "cien"
        default:
            return "número \(number)"
        }
    }
    
    private func getSimpleNumber(_ number: Int) -> String {
        switch number {
        case 0: return "cero"
        case 1: return "uno"
        case 2: return "dos"
        case 3: return "tres"
        case 4: return "cuatro"
        case 5: return "cinco"
        case 6: return "seis"
        case 7: return "siete"
        case 8: return "ocho"
        case 9: return "nueve"
        default: return "\(number)"
        }
    }
    
    func getVoiceInfo() -> String {
        guard let voice = selectedVoice else {
            return "No voice selected"
        }
        return "Voice: \(voice.name) (\(voice.language)) - Quality: \(voice.quality == .enhanced ? "Enhanced" : "Default")"
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            _isSpeaking = false
        }
        
        // Clean up any pending callbacks and timers
        speechTimeoutTimer?.invalidate()
        speechTimeoutTimer = nil
        
        // Call completion callback with failure since we're stopping
        if speechCompletionCallback != nil {
            handleSpeechCompletion(success: false)
        }
    }
    
    func testSpeech() {
        print("🎤 🧪 TESTING SPEECH...")
        
        // First, refresh voice selection to make sure we have the latest
        selectBestSpanishVoice()
        
        // Test with a phrase that clearly identifies the voice
        let testPhrase = "Hola, soy la voz de Siri en español. Número veinticinco."
        
        if let voice = selectedVoice {
            print("🔊 Testing with voice: '\(voice.name)' (\(voice.language))")
            print("🔊 Quality: \(voice.quality == .enhanced ? "Enhanced" : "Default")")
            print("🔊 Gender: \(voice.gender == .female ? "Female" : voice.gender == .male ? "Male" : "Unknown")")
        }
        
        speak(testPhrase)
    }
    
    // Method to refresh and check for Siri voices
    func refreshAndCheckSiriVoices() {
        print("🔄 === REFRESHING AND CHECKING FOR SIRI VOICES ===")
        
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Look specifically for Siri Voice 1 and 2
        let siriVoices = allVoices.filter { voice in
            let name = voice.name.lowercased()
            return name.contains("siri voice") || name.contains("siri")
        }
        
        print("🎯 Found \(siriVoices.count) potential Siri voices:")
        for voice in siriVoices {
            print("  🎤 '\(voice.name)' (\(voice.language)) - \(voice.quality == .enhanced ? "Enhanced" : "Default") - \(voice.gender == .female ? "Female" : voice.gender == .male ? "Male" : "Unknown")")
        }
        
        // Refresh selection
        selectBestSpanishVoice()
        
        print("🔄 === REFRESH COMPLETE ===")
    }
    
    // Load user-selected voice or auto-select best one
    private func loadUserSelectedVoice() {
        // Try to load user's preferred voice first
        if let savedIdentifier = UserDefaults.standard.string(forKey: "selectedVoiceIdentifier") {
            userSelectedVoiceIdentifier = savedIdentifier
            if let voice = AVSpeechSynthesisVoice(identifier: savedIdentifier) {
                selectedVoice = voice
                print("✅ Loaded user-selected voice: '\(voice.name)' (\(voice.language))")
                return
            } else {
                print("⚠️ Saved voice identifier '\(savedIdentifier)' not found, auto-selecting...")
            }
        }
        
        // Fallback to auto-selection
        selectBestSpanishVoice()
    }
    
    // Update selected voice when user changes it
    func updateSelectedVoice(identifier: String?) {
        userSelectedVoiceIdentifier = identifier
        
        if let identifier = identifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            selectedVoice = voice
            print("🎯 Updated to user-selected voice: '\(voice.name)' (\(voice.language))")
        } else {
            // User cleared selection, auto-select best voice
            selectBestSpanishVoice()
        }
    }
    
    // Get all available voices for user selection
    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().sorted { voice1, voice2 in
            // Sort by language first, then by name
            if voice1.language != voice2.language {
                return voice1.language < voice2.language
            }
            return voice1.name < voice2.name
        }
    }
    
    // Get Spanish voices specifically
    func getSpanishVoices() -> [AVSpeechSynthesisVoice] {
        return getAvailableVoices().filter { $0.language.hasPrefix("es") }
    }
    
    // Get current selected voice
    func getCurrentVoice() -> AVSpeechSynthesisVoice? {
        return selectedVoice
    }
    
    // Preview a voice with sample text
    func previewVoice(_ voice: AVSpeechSynthesisVoice) {
        let testPhrase = "Hola, este es un ejemplo de mi voz. Número veinticinco."
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: testPhrase)
        utterance.voice = voice
        // Use natural default settings - no custom adjustments
        
        print("🔊 Previewing voice: '\(voice.name)' (\(voice.language))")
        synthesizer.speak(utterance)
    }
    
    // Check if voice is Siri Voice 1 or 2
    func isSiriVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        let name = voice.name.lowercased()
        return name.contains("siri voice") || name.contains("siri")
    }
    
    // Get Siri voice description
    func getSiriVoiceType(_ voice: AVSpeechSynthesisVoice) -> String? {
        guard isSiriVoice(voice) else { return nil }
        
        let name = voice.name.lowercased()
        _ = voice.language.lowercased() // Language not used in current logic
        
        if name.contains("siri voice 2") {
            return "Siri Voice 2"
        } else if name.contains("siri voice 1") {
            return "Siri Voice 1"
        } else if name.contains("siri") {
            return "Siri Voice"
        }
        
        return "Enhanced Voice"
    }
}

extension SpeechHelper: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🎤 ✅ Speech STARTED: '\(utterance.speechString)'")
        _isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("🎤 ✅ Speech FINISHED: '\(utterance.speechString)'")
        _isSpeaking = false
        handleSpeechCompletion(success: true)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("🎤 ❌ Speech CANCELLED: '\(utterance.speechString)'")
        _isSpeaking = false
        handleSpeechCompletion(success: false)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("🎤 ⏸️ Speech PAUSED: '\(utterance.speechString)'")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        print("🎤 ▶️ Speech CONTINUED: '\(utterance.speechString)'")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString range: NSRange, utterance: AVSpeechUtterance) {
        let spokenText = (utterance.speechString as NSString).substring(with: range)
        print("🎤 📢 Speaking: '\(spokenText)'")
    }
} 
