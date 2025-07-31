import SwiftUI
import LocalAuthentication

struct AdminUnlockView: View {
    @StateObject private var authManager = AdminAuthManager.shared
    @State private var pinInput = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isShaking = false
    @FocusState private var isPinFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    let onSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("admin_access")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("admin_unlock_description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Authentication content
                    VStack(spacing: 25) {
                        // Face ID/Touch ID Button
                        if authManager.isFaceIDAvailable {
                            Button(action: authenticateWithBiometrics) {
                                HStack {
                                    Image(systemName: biometricIcon)
                                        .font(.title2)
                                    Text(biometricText)
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(authManager.isLockedOut)
                        }
                        
                        // PIN Input Section
                        VStack(spacing: 15) {
                            Text("admin_or_enter_pin")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // PIN Input Field
                            VStack(spacing: 10) {
                            HStack {
                                    SecureField("Enter PIN", text: $pinInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .focused($isPinFieldFocused)
                                    .disabled(authManager.isLockedOut)
                                    .onChange(of: pinInput) { _, newValue in
                                            // Clean input - only allow numbers and limit to 6 digits
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered.count > 6 {
                                                pinInput = String(filtered.prefix(6))
                                            } else {
                                                pinInput = filtered
                                            }
                                    }
                                    .onSubmit {
                                            if pinInput.count >= 4 {
                                        authenticateWithPIN()
                                            }
                                    }
                                
                                Button(action: authenticateWithPIN) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(pinInput.count >= 4 ? .blue : .gray)
                                }
                                .disabled(pinInput.count < 4 || authManager.isLockedOut)
                            }
                            .offset(x: isShaking ? -10 : 0)
                            .animation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true), value: isShaking)
                                
                                // PIN hint
                                Text("PIN: 123456")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Lock status
                        if authManager.isLockedOut {
                            VStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                
                                Text("admin_locked_message")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                
                                if authManager.lockoutTimeRemaining > 0 {
                                    Text("admin_lockout_time \(formatTime(Int(authManager.lockoutTimeRemaining)))")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Attempts remaining
                        if authManager.failedAttempts > 0 && !authManager.isLockedOut {
                            Text("admin_attempts_remaining \(3 - authManager.failedAttempts)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common_cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isPinFieldFocused = false
                    }
                }
            }
            .alert("common_error", isPresented: $showingError) {
                Button("common_ok") { 
                    showingError = false
                }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            // TESTING MODE: Skip PIN authentication for smooth testing
            // TODO: Re-enable PIN authentication for production
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSuccess()
            }
            
            // Production PIN authentication (currently disabled)
            /*
            // Focus on PIN field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPinFieldFocused = true
            }
            */
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isPinFieldFocused = false
        }
    }
    
    private var biometricIcon: String {
        return "faceid"  // Default to Face ID icon
    }
    
    private var biometricText: String {
        return NSLocalizedString("admin_use_face_id", comment: "Use Face ID")
    }
    
    private func authenticateWithBiometrics() {
        isPinFieldFocused = false // Dismiss keyboard
        
        Task {
            await authManager.authenticate()
            
            await MainActor.run {
                if authManager.isAuthenticated {
                    onSuccess()
                } else {
                    handleAuthenticationFailure()
                }
            }
        }
    }
    
    private func authenticateWithPIN() {
        guard !pinInput.isEmpty && pinInput.count >= 4 else { return }
        
        isPinFieldFocused = false // Dismiss keyboard
        
        Task {
            await authManager.authenticateWithPIN(pinInput)
            
            await MainActor.run {
                if authManager.isAuthenticated {
                    onSuccess()
                } else {
                    handleAuthenticationFailure()
                }
            }
        }
    }
    
    private func handleAuthenticationFailure() {
        // Clear PIN and show shake animation
        pinInput = ""
        isShaking = true
        
        // Stop shaking after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShaking = false
        }
        
        // Show error message if needed
        if authManager.failedAttempts >= 3 {
            errorMessage = "Too many failed attempts. Please try again later."
            showingError = true
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    AdminUnlockView {
        print("Authentication successful!")
    }
} 