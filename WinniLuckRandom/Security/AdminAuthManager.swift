//
//  AdminAuthManager.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import LocalAuthentication
import SwiftUI

// MARK: - Authentication State
enum AuthenticationState {
    case notAuthenticated
    case authenticated
    case locked
}

// MARK: - Authentication Error
enum AuthenticationError: Error {
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case passcodeNotSet
    case authenticationFailed
    case userCancel
    case tooManyAttempts
    case systemCancel
    case userFallback
    case invalidCredentials
    case accountLocked
    
    var localizedDescription: String {
        switch self {
        case .biometryNotAvailable:
            return NSLocalizedString("biometry_not_available", comment: "")
        case .biometryNotEnrolled:
            return NSLocalizedString("biometry_not_enrolled", comment: "")
        case .biometryLockout:
            return NSLocalizedString("biometry_lockout", comment: "")
        case .passcodeNotSet:
            return NSLocalizedString("passcode_not_set", comment: "")
        case .authenticationFailed:
            return NSLocalizedString("authentication_failed", comment: "")
        case .userCancel:
            return NSLocalizedString("user_cancelled", comment: "")
        case .tooManyAttempts:
            return NSLocalizedString("too_many_attempts", comment: "")
        case .systemCancel:
            return NSLocalizedString("system_cancelled", comment: "")
        case .userFallback:
            return NSLocalizedString("user_fallback", comment: "")
        case .invalidCredentials:
            return NSLocalizedString("invalid_credentials", comment: "")
        case .accountLocked:
            return NSLocalizedString("account_locked", comment: "")
        }
    }
}

// MARK: - Admin Authentication Manager
@MainActor
class AdminAuthManager: ObservableObject {
    static let shared = AdminAuthManager()
    
    // MARK: - Published Properties
    @Published var authenticationState: AuthenticationState = .notAuthenticated
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var failedAttempts = 0
    @Published var isLockedOut = false
    @Published var lockoutTimeRemaining: TimeInterval = 0
    
    // MARK: - Private Properties
    private let context = LAContext()
    private let maxFailedAttempts = 3
    private let lockoutDuration: TimeInterval = 300 // 5 minutes
    private var lockoutTimer: Timer?
    
    // MARK: - UserDefaults Keys
    private let adminPINKey = "admin_pin"
    private let failedAttemptsKey = "failed_attempts"
    private let lockoutTimeKey = "lockout_time"
    
    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        return authenticationState == .authenticated
    }
    
    var isFaceIDAvailable: Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    var biometryType: LABiometryType {
        return context.biometryType
    }
    
    var biometryDisplayName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometry"
        @unknown default:
            return "Biometry"
        }
    }
    
    // MARK: - Initialization
    init() {
        checkLockoutStatus()
        loadFailedAttempts()
    }
    
    // MARK: - Main Authentication Method
    func authenticate() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Check if locked out
        if isLockedOut {
            await MainActor.run {
                errorMessage = AuthenticationError.accountLocked.localizedDescription
                isLoading = false
            }
            return
        }
        
        // Try Face ID first if available
        if isFaceIDAvailable {
            await authenticateWithBiometry()
        } else {
            // Fallback to PIN if Face ID not available
            await MainActor.run {
                authenticationState = .notAuthenticated
                isLoading = false
            }
        }
    }
    
    // MARK: - Biometric Authentication
    private func authenticateWithBiometry() async {
        do {
            let reason = NSLocalizedString("admin_auth_reason", comment: "")
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            
            if success {
                await MainActor.run {
                    authenticationState = .authenticated
                    resetFailedAttempts()
                    isLoading = false
                }
            }
        } catch {
            await handleBiometryError(error)
        }
    }
    
    // MARK: - PIN Authentication
    func authenticateWithPIN(_ pin: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Check if locked out
        if isLockedOut {
            await MainActor.run {
                errorMessage = AuthenticationError.accountLocked.localizedDescription
                isLoading = false
            }
            return
        }
        
        // Validate PIN
        if validatePIN(pin) {
            await MainActor.run {
                authenticationState = .authenticated
                resetFailedAttempts()
                isLoading = false
            }
        } else {
            await handleFailedPINAttempt()
        }
    }
    
    // MARK: - PIN Management
    func setPIN(_ pin: String) -> Bool {
        guard pin.count == 6 && pin.allSatisfy(\.isNumber) else {
            return false
        }
        
        UserDefaults.standard.set(pin, forKey: adminPINKey)
        return true
    }
    
    func isPINSet() -> Bool {
        return UserDefaults.standard.string(forKey: adminPINKey) != nil
    }
    
    private func validatePIN(_ pin: String) -> Bool {
        guard let savedPIN = UserDefaults.standard.string(forKey: adminPINKey) else {
            return false
        }
        return pin == savedPIN
    }
    
    // MARK: - Session Management
    func logout() {
        authenticationState = .notAuthenticated
        errorMessage = nil
    }
    
    func extendSession() {
        if isAuthenticated {
            // Reset any timeout timers if implemented
        }
    }
    
    // MARK: - Error Handling
    private func handleBiometryError(_ error: Error) async {
        await MainActor.run {
            isLoading = false
            
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotAvailable:
                    errorMessage = AuthenticationError.biometryNotAvailable.localizedDescription
                case .biometryNotEnrolled:
                    errorMessage = AuthenticationError.biometryNotEnrolled.localizedDescription
                case .biometryLockout:
                    errorMessage = AuthenticationError.biometryLockout.localizedDescription
                case .passcodeNotSet:
                    errorMessage = AuthenticationError.passcodeNotSet.localizedDescription
                case .authenticationFailed:
                    errorMessage = AuthenticationError.authenticationFailed.localizedDescription
                case .userCancel:
                    errorMessage = AuthenticationError.userCancel.localizedDescription
                case .systemCancel:
                    errorMessage = AuthenticationError.systemCancel.localizedDescription
                case .userFallback:
                    // User chose to use PIN instead
                    authenticationState = .notAuthenticated
                    return
                default:
                    errorMessage = AuthenticationError.authenticationFailed.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
            
            // Set state to show PIN input
            authenticationState = .notAuthenticated
        }
    }
    
    private func handleFailedPINAttempt() async {
        await MainActor.run {
            failedAttempts += 1
            saveFailedAttempts()
            
            if failedAttempts >= maxFailedAttempts {
                startLockout()
            } else {
                let remainingAttempts = maxFailedAttempts - failedAttempts
                errorMessage = String(format: NSLocalizedString("invalid_pin_attempts_remaining", comment: ""), remainingAttempts)
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Lockout Management
    private func startLockout() {
        isLockedOut = true
        lockoutTimeRemaining = lockoutDuration
        
        let lockoutEndTime = Date().addingTimeInterval(lockoutDuration)
        UserDefaults.standard.set(lockoutEndTime, forKey: lockoutTimeKey)
        
        authenticationState = .locked
        errorMessage = String(format: NSLocalizedString("account_locked_message", comment: ""), Int(lockoutDuration / 60))
        
        startLockoutTimer()
    }
    
    private func startLockoutTimer() {
        lockoutTimer?.invalidate()
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateLockoutTimer()
            }
        }
    }
    
    private func updateLockoutTimer() {
        lockoutTimeRemaining -= 1
        
        if lockoutTimeRemaining <= 0 {
            endLockout()
        }
    }
    
    private func endLockout() {
        lockoutTimer?.invalidate()
        lockoutTimer = nil
        
        isLockedOut = false
        lockoutTimeRemaining = 0
        authenticationState = .notAuthenticated
        resetFailedAttempts()
        
        UserDefaults.standard.removeObject(forKey: lockoutTimeKey)
        errorMessage = nil
    }
    
    private func checkLockoutStatus() {
        if let lockoutEndTime = UserDefaults.standard.object(forKey: lockoutTimeKey) as? Date {
            let now = Date()
            
            if now < lockoutEndTime {
                lockoutTimeRemaining = lockoutEndTime.timeIntervalSince(now)
                isLockedOut = true
                authenticationState = .locked
                startLockoutTimer()
            } else {
                endLockout()
            }
        }
    }
    
    // MARK: - Persistence
    private func saveFailedAttempts() {
        UserDefaults.standard.set(failedAttempts, forKey: failedAttemptsKey)
    }
    
    private func loadFailedAttempts() {
        failedAttempts = UserDefaults.standard.integer(forKey: failedAttemptsKey)
    }
    
    private func resetFailedAttempts() {
        failedAttempts = 0
        UserDefaults.standard.removeObject(forKey: failedAttemptsKey)
    }
    
    // MARK: - Utility Methods
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    func getRemainingLockoutTime() -> String {
        let minutes = Int(lockoutTimeRemaining) / 60
        let seconds = Int(lockoutTimeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        lockoutTimer?.invalidate()
    }
}

// MARK: - Security Utilities
extension AdminAuthManager {
    
    /// Check if device has secure authentication available
    func isSecureAuthenticationAvailable() -> Bool {
        return isFaceIDAvailable || isPINSet()
    }
    
    /// Get security level description
    func getSecurityLevelDescription() -> String {
        if isFaceIDAvailable && isPINSet() {
            return String(format: NSLocalizedString("security_level_biometry_and_pin", comment: ""), biometryDisplayName)
        } else if isFaceIDAvailable {
            return String(format: NSLocalizedString("security_level_biometry_only", comment: ""), biometryDisplayName)
        } else if isPINSet() {
            return NSLocalizedString("security_level_pin_only", comment: "")
        } else {
            return NSLocalizedString("security_level_none", comment: "")
        }
    }
    
    /// Reset all security settings (for testing or emergency access)
    func resetSecuritySettings() {
        UserDefaults.standard.removeObject(forKey: adminPINKey)
        UserDefaults.standard.removeObject(forKey: failedAttemptsKey)
        UserDefaults.standard.removeObject(forKey: lockoutTimeKey)
        
        failedAttempts = 0
        isLockedOut = false
        lockoutTimeRemaining = 0
        authenticationState = .notAuthenticated
        
        lockoutTimer?.invalidate()
        lockoutTimer = nil
    }
} 