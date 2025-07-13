//
//  ResultView.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI

struct ResultView: View {
    @ObservedObject var viewModel: RandomNumberViewModel
    @ObservedObject var settings: SettingsModel
    private let speechHelper = SpeechHelper()
    @State private var showConfetti = false
    @State private var coinScale: CGFloat = 0.8
    @State private var coinRotation: Double = 0
    @State private var autoAdvanceTimer: Timer?
    @State private var isRandomizing = false
    @State private var displayedNumber: Int = 0
    @State private var randomizationTimer: Timer?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                BackgroundView(image: settings.backgroundImage)
                
                VStack(spacing: 40) {
                    // Progress indicator
                    VStack(spacing: 10) {
                        Text(String(format: NSLocalizedString("number_x_of_y", comment: ""), viewModel.currentRepetition, viewModel.totalRepetitions))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.thickMaterial)
                                    .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
                            )
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                        
                        // Progress bar with numbers
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(viewModel.currentRepetition)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(viewModel.totalRepetitions)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            
                            ProgressView(value: viewModel.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                                .padding(.horizontal, 16)
                        }
                        
                        // Auto-advance indicator
                        if viewModel.hasNextNumber {
                            HStack(spacing: 8) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text(NSLocalizedString("auto_advance_info", comment: ""))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Gold coin with number
                    ZStack {
                        // Coin background
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.yellow.opacity(0.9),
                                        Color.orange.opacity(0.8),
                                        Color.yellow.opacity(0.6)
                                    ]),
                                    center: .topLeading,
                                    startRadius: 10,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 250, height: 250)
                            .shadow(color: .orange.opacity(0.8), radius: 20, x: 0, y: 10)
                        
                        // Coin border
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .yellow, .orange]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 250, height: 250)
                        
                        // Inner circle
                        Circle()
                            .stroke(Color.orange.opacity(0.7), lineWidth: 2)
                            .frame(width: 200, height: 200)
                        
                        // Number display
                        Text("\(displayedNumber)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
                    }
                    .scaleEffect(coinScale)
                    .rotationEffect(.degrees(coinRotation))
                    .accessibility(label: Text(NSLocalizedString("gold_coin", comment: "")))
                    .accessibility(value: Text("\(viewModel.currentNumber)"))
                    
                    // Close button - top right corner
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                stopTimer()
                                viewModel.goHome()
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                    )
                            }
                            .padding(.top, 40)
                            .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
        .confetti(trigger: showConfetti)
        .onAppear {
            // Start with randomization for the first number
            startFirstNumberAnimation()
            animateEntrance()
            startAutoAdvanceTimer()
        }
        .onDisappear {
            stopTimer()
            stopRandomizationTimer()
        }
        .fullScreenCover(isPresented: $viewModel.showingCongrats) {
            CongratsView(viewModel: viewModel, settings: settings, parentDismiss: dismiss)
        }
    }
    
    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            coinScale = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.6).delay(0.4)) {
            coinRotation = 360
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showConfetti = true
        }
    }
    
    private func nextNumber() {
        // Reset animations
        coinScale = 0.8
        coinRotation = 0
        showConfetti = false
        
        // Update number in view model
        viewModel.nextNumber()
        
        // Start randomization animation
        startRandomizationAnimation()
        
        // Animate coin
        withAnimation(.easeOut(duration: 0.6)) {
            coinScale = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
            coinRotation = 360
        }
        
        // Show final number after randomization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            displayedNumber = viewModel.currentNumber
            isRandomizing = false
            
            // Trigger confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConfetti = true
            }
            
            // Speak number
            if settings.voiceEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    speechHelper.speakNumber(viewModel.currentNumber)
                }
            }
        }
    }
    
    private func startAutoAdvanceTimer() {
        // Start timer after initial entrance animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                if viewModel.hasNextNumber {
                    nextNumber()
                } else {
                    stopTimer()
                    // Trigger congratulations screen
                    viewModel.showingCongrats = true
                }
            }
        }
    }
    
    private func stopTimer() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
        stopRandomizationTimer()
    }
    
    private func startRandomizationAnimation() {
        guard let start = Int(viewModel.startNumber),
              let end = Int(viewModel.endNumber) else { return }
        
        isRandomizing = true
        
        // Create randomization timer that updates every 50ms for 1 second
        randomizationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            displayedNumber = Int.random(in: start...end)
        }
        
        // Stop randomization after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            stopRandomizationTimer()
        }
    }
    
    private func stopRandomizationTimer() {
        randomizationTimer?.invalidate()
        randomizationTimer = nil
    }
    
    private func startFirstNumberAnimation() {
        guard let start = Int(viewModel.startNumber),
              let end = Int(viewModel.endNumber) else { 
            displayedNumber = viewModel.currentNumber
            return 
        }
        
        isRandomizing = true
        
        // Start randomization animation for first number
        randomizationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            displayedNumber = Int.random(in: start...end)
        }
        
        // Show final number after 1 second and trigger effects
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            stopRandomizationTimer()
            displayedNumber = viewModel.currentNumber
            isRandomizing = false
            
            // Trigger confetti after revealing the number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConfetti = true
            }
            
            // Speak the first number
            if settings.voiceEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    speechHelper.speakNumber(viewModel.currentNumber)
                }
            }
        }
    }
}

struct CongratsView: View {
    @ObservedObject var viewModel: RandomNumberViewModel
    @ObservedObject var settings: SettingsModel
    let parentDismiss: DismissAction
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            BackgroundView(image: settings.backgroundImage)
            
            ScrollView {
                VStack(spacing: 30) {
                    // Congratulations message
                    VStack(spacing: 20) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                            .shadow(color: .orange, radius: 10, x: 0, y: 5)
                        
                        Text(NSLocalizedString("congratulations", comment: ""))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 2)
                        
                        Text(NSLocalizedString("all_numbers_generated", comment: ""))
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    }
                    .padding(.top, 40)
                    
                    // Results summary
                    VStack(spacing: 20) {
                        Text(NSLocalizedString("winning_numbers", comment: ""))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                        
                        // Grid of winning numbers
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 20) {
                            ForEach(viewModel.numberStatistics, id: \.number) { stat in
                                WinningNumberCoin(number: stat.number, count: stat.count)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Back home button
                    Button(action: {
                        // Reset view model first
                        viewModel.goHome()
                        // Dismiss congratulations screen first
                        dismiss()
                        // Then dismiss the parent ResultView to go directly home
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            parentDismiss()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text(NSLocalizedString("back", comment: ""))
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .pink]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .confetti(trigger: true)
    }
}

struct WinningNumberCoin: View {
    let number: Int
    let count: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Gold coin
            ZStack {
                // Coin background
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .orange.opacity(0.6), radius: 8, x: 0, y: 4)
                
                // Coin border
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .yellow, .orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                
                // Number
                Text("\(number)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.1))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
            }
            
            // Count label
            Text("\(count)×")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.4))
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}

#Preview {
    let viewModel = RandomNumberViewModel()
    viewModel.currentNumber = 42
    viewModel.currentRepetition = 1
    viewModel.totalRepetitions = 5
    
    return ResultView(viewModel: viewModel, settings: SettingsModel())
} 