//
//  HomeView.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = RandomNumberViewModel()
    @StateObject private var settings = SettingsModel()
    @State private var showingSettings = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingResult = false
    @State private var coinRotation: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                
                VStack(spacing: 0) {
                    // Main content area - takes most of the space
                    ScrollView {
                        VStack(spacing: 30) {
                            // Gold coin section
                            goldCoinSection
                                .padding(.top, 40)
                            
                            // Input fields
                            inputFields
                                .padding(.horizontal, 16)
                            
                            // Start button
                            startButton
                                .padding(.horizontal, 16)
                            
                            // Extra bottom padding for bottom controls
                            Color.clear
                                .frame(height: 80)
                        }
                    }
                    
                    // Bottom controls bar
                    bottomControlsBar
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings)
        }
        .fullScreenCover(isPresented: $showingResult) {
            ResultView(viewModel: viewModel, settings: settings)
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Background Image Error", isPresented: .constant(settings.backgroundImageError != nil)) {
            Button("OK") {
                settings.clearImageError()
            }
            Button("Reset to Default") {
                settings.resetBackground()
                settings.clearImageError()
            }
        } message: {
            Text(settings.backgroundImageError ?? "Unknown error occurred with background image. The app will use the default gradient background.")
        }
        .onAppear {
            settings.loadSettings()
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        BackgroundView(image: settings.backgroundImage)
    }
    
    // MARK: - Input Fields Layout
    private var inputFields: some View {
        VStack(spacing: 16) {
            startNumberField
            endNumberField
            repetitionsField
            winnersCountField
        }
    }
    
        // MARK: - Settings Button
    private var settingsButton: some View {
        Button(action: {
            showingSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
    }
    
    // MARK: - Bottom Controls Bar
    private var bottomControlsBar: some View {
        HStack {
            Spacer()
            
            // Settings button with label  
            VStack(spacing: 4) {
                settingsButton
                Text(NSLocalizedString("settings", comment: ""))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
    }
    

    
    // MARK: - Gold Coin Section
    private var goldCoinSection: some View {
        VStack(spacing: 16) {
            goldCoinIcon
            titleText
        }
    }
    
    // MARK: - Gold Coin Icon
    private var goldCoinIcon: some View {
        ZStack {
            // Front side of coin
            coinSide
                .opacity(abs(sin(coinRotation * .pi / 180)) < 0.5 ? 1 : 0)
            
            // Back side of coin (flipped)
            coinSide
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(abs(sin(coinRotation * .pi / 180)) >= 0.5 ? 1 : 0)
        }
        .rotation3DEffect(.degrees(coinRotation), axis: (x: 0, y: 1, z: 0))
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                coinRotation = 360
            }
        }
    }
    
    // MARK: - Coin Side
    private var coinSide: some View {
        Button(action: {}) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.1))
                .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
                .background(goldCoinBackground)
        }
        .disabled(true)
    }
    
    // MARK: - Gold Coin Background
    private var goldCoinBackground: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [.yellow, .orange]),
                    center: .center,
                    startRadius: 10,
                    endRadius: 50
                )
            )
            .frame(width: 90, height: 90)
    }
    
    // MARK: - Title Text
    private var titleText: some View {
        Text(NSLocalizedString("generate_numbers", comment: ""))
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .shadow(color: .black, radius: 2, x: 1, y: 1)
    }
    

    
    // MARK: - Start Number Field
    private var startNumberField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("start_number", comment: ""))
                .font(.headline)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            TextField("1", text: $viewModel.startNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .font(.title2)
                .frame(height: 48)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
        }
    }
    
    // MARK: - End Number Field
    private var endNumberField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("end_number", comment: ""))
                .font(.headline)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            TextField("100", text: $viewModel.endNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .font(.title2)
                .frame(height: 48)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Repetitions Field
    private var repetitionsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("repeat_times", comment: ""))
                .font(.headline)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            TextField("1", text: $viewModel.repetitions)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .font(.title2)
                .frame(height: 48)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button(action: {
            if viewModel.inputsValid {
                viewModel.generateRandomNumbers()
                showingResult = true
            }
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                Text(NSLocalizedString("start", comment: ""))
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(startButtonBackground)
            .cornerRadius(16)
        }
        .disabled(!viewModel.inputsValid)
        .opacity(viewModel.inputsValid ? 1.0 : 0.6)
    }
    
    // MARK: - Start Button Background
    private var startButtonBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [.green, Color(red: 0.0, green: 0.7, blue: 0.3)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Winners Count Field
    private var winnersCountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("winners_count", comment: ""))
                .font(.headline)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            TextField("3", text: $viewModel.winnersCount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .font(.title2)
                .frame(height: 48)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
        }
    }
    

}

// MARK: - Background View
struct BackgroundView: View {
    let image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                // Try to display the custom background image
                ZStack {
                    // Fallback gradient in case image fails
                    defaultGradient
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .overlay(
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                        )
                        .onAppear {
                            print("✅ Custom background image displayed")
                        }
                }
            } else {
                defaultGradient
            }
        }
    }
    
    private var defaultGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.blue, .purple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    HomeView()
} 