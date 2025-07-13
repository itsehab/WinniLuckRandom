//
//  SettingsView.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsModel
    @Environment(\.dismiss) var dismiss
    @State private var showingResetAlert = false
    @State private var showingResetSuccess = false
    @State private var showingResetAllAlert = false
    @State private var showingImagePicker = false
    @State private var tempBackgroundImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                BackgroundView(image: settings.backgroundImage)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Title
                        VStack(spacing: 10) {
                            Image(systemName: "gear.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                                .shadow(color: .blue.opacity(0.5), radius: 5, x: 2, y: 2)
                            
                            Text(NSLocalizedString("settings", comment: ""))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        // Settings options
                        VStack(spacing: 20) {
                            // Voice toggle
                            SettingsRow(
                                icon: "speaker.wave.2.fill",
                                title: NSLocalizedString("voice_enabled", comment: ""),
                                iconColor: .green
                            ) {
                                Toggle("", isOn: $settings.voiceEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .green))
                            }
                            
                            // Background image selection
                            SettingsRow(
                                icon: "photo.badge.plus",
                                title: "Select Background",
                                iconColor: .blue
                            ) {
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    Text("Choose")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .purple]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(10)
                                }
                            }
                            
                            // Background reset
                            SettingsRow(
                                icon: "photo.fill",
                                title: NSLocalizedString("reset_background", comment: ""),
                                iconColor: .orange
                            ) {
                                Button(action: {
                                    showingResetAlert = true
                                }) {
                                    Text("Reset")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.orange, .red]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(10)
                                }
                                .disabled(!settings.backgroundImageSelected)
                            }
                            
                            // Reset all settings
                            SettingsRow(
                                icon: "arrow.clockwise.circle.fill",
                                title: "Reset All Settings",
                                iconColor: .red
                            ) {
                                Button(action: {
                                    showingResetAllAlert = true
                                }) {
                                    Text("Reset All")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.red, .pink]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(NSLocalizedString("back", comment: ""))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .alert("Reset Background", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings.resetBackground()
                    showingResetSuccess = true
                }
            } message: {
                Text("Are you sure you want to reset the background to default?")
            }
            .alert(NSLocalizedString("background_reset", comment: ""), isPresented: $showingResetSuccess) {
                Button("OK", role: .cancel) { }
            }
            .alert("Reset All Settings", isPresented: $showingResetAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset All", role: .destructive) {
                    settings.resetAllSettings()
                }
            } message: {
                Text("This will reset all app settings including background image and voice settings. This action cannot be undone.")
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $tempBackgroundImage)
            }
            .onChange(of: tempBackgroundImage) { _, newImage in
                if let image = newImage {
                    settings.saveBackgroundImage(image)
                    tempBackgroundImage = nil
                }
            }
        }
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let content: Content
    
    init(icon: String, title: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
            
            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Content
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    SettingsView(settings: SettingsModel())
} 