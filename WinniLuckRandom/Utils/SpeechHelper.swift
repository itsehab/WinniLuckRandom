//
//  SpeechHelper.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import AVFoundation

class SpeechHelper: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var isSpeaking: Bool = false
    private var selectedVoice: AVSpeechSynthesisVoice?
    
    override init() {
        super.init()
        setupAudioSession()
        synthesizer.delegate = self
        selectBestSpanishVoice()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    private func selectBestSpanishVoice() {
        // Get all available Spanish voices
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        print("🎤 Looking for the best Spanish voice...")
        
        // First priority: Enhanced quality Spanish voices
        if let enhancedVoice = availableVoices.first(where: { 
            $0.language.hasPrefix("es") && 
            $0.quality == .enhanced
        }) {
            selectedVoice = enhancedVoice
            print("✨ Found enhanced Spanish voice: \(enhancedVoice.name) (\(enhancedVoice.language))")
            return
        }
        
        // Second priority: Latin American Spanish voices (more natural for numbers)
        let latinAmericanLanguages = ["es-MX", "es-CO", "es-AR", "es-CL", "es-PE", "es-VE", "es-EC", "es-US"]
        
        for language in latinAmericanLanguages {
            if let voice = availableVoices.first(where: { 
                $0.language == language
            }) {
                selectedVoice = voice
                print("🌎 Using Latin American voice: \(voice.name) (\(voice.language))")
                return
            }
        }
        
        // Third priority: Any Spanish voice
        if let spanishVoice = availableVoices.first(where: { 
            $0.language.hasPrefix("es")
        }) {
            selectedVoice = spanishVoice
            print("🇪🇸 Using Spanish voice: \(spanishVoice.name) (\(spanishVoice.language))")
            return
        }
        
        // Fallback: System default Spanish
        selectedVoice = AVSpeechSynthesisVoice(language: "es-ES")
        print("🔄 Using default Spanish voice")
        
        // Log final voice selection
        if let voice = selectedVoice {
            print("🎤 Final voice: \(voice.name) (\(voice.language)) - Gender: \(voice.gender == .male ? "Male" : voice.gender == .female ? "Female" : "Unknown")")
        }
    }
    
    func speak(_ text: String) {
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Use the selected voice
        utterance.voice = selectedVoice
        
        // Natural human speech parameters
        utterance.rate = 0.55 // Natural speaking pace
        utterance.pitchMultiplier = 1.0 // Natural pitch
        utterance.volume = 0.9 // Clear but not overpowering
        
        // Minimal pauses for natural flow
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    func speakNumber(_ number: Int) {
        // Convert number to clean Spanish pronunciation
        let numberText = formatNumberForSpanish(number)
        speak(numberText)
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
            isSpeaking = false
        }
    }
}

extension SpeechHelper: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
} 
