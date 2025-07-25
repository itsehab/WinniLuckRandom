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
    @State private var brandingScale: CGFloat = 1.0
    @Environment(\.dismiss) var dismiss
    
    private var prizeTitle: String {
        return "¡Lotería en Vivo!"
    }
    

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                BackgroundView(image: settings.backgroundImage)
                
                VStack(spacing: 0) {
                    // Title and X Button Row
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            // Main title
                            Text(prizeTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                            .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 2)
                            
                            // Prize breakdown with individual elements
                            HStack(spacing: 8) {
                                ForEach(1...min(viewModel.currentGameMode?.maxWinners ?? 1, 5), id: \.self) { position in
                                    PrizeBreakdownItem(
                                        position: position,
                                        prize: viewModel.currentGameMode?.getPrize(for: position) ?? 0
                                    )
                                }
                            }
                        }
                        
                                Spacer()
                        
                        // X Button - top right corner
                        Button(action: {
                            stopTimer()
                            viewModel.goHome()
                            dismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Centered Content
                    VStack(spacing: 40) {
                        // Game Progress Bar - Centered
                        SingleProgressView(
                            currentRepetition: viewModel.currentRepetition,
                            totalRepetitions: viewModel.totalRepetitions,
                            currentNumber: viewModel.currentNumber,
                            currentNumberCount: viewModel.numberCounts[viewModel.currentNumber] ?? 0,
                            numberCounts: viewModel.numberCounts,
                            targetRepetitions: viewModel.currentGameMode?.repetitions ?? Int(viewModel.repetitions) ?? 1,
                            numbersDrawn: viewModel.currentRepetition,
                            totalNumbers: viewModel.totalRepetitions,
                            isCompletingRace: viewModel.isCompletingRace
                        )
                        
                        // Main gold coin with number - Centered
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
                                    startRadius: 8,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 180, height: 180)
                            .shadow(color: .orange.opacity(0.8), radius: 15, x: 0, y: 8)
                        
                        // Coin border
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .yellow, .orange]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 6
                            )
                            .frame(width: 180, height: 180)
                        
                        // Inner circle
                        Circle()
                            .stroke(Color.orange.opacity(0.7), lineWidth: 2)
                            .frame(width: 140, height: 140)
                        
                        // Number display
                        VStack(spacing: 6) {
                            Text("\(displayedNumber)")
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
                            
                            // Player name if available
                            if let player = getPlayerForNumber(displayedNumber) {
                                Text(player.firstName)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.black.opacity(0.3))
                                    )
                            }
                        }
                    }
                    .scaleEffect(coinScale)
                    .rotationEffect(.degrees(coinRotation))
                    .accessibility(label: Text(NSLocalizedString("gold_coin", comment: "")))
                    .accessibility(value: Text("\(viewModel.currentNumber)"))
                    }
                    
                            Spacer()
                    
                    // WinniLuck Branding with smooth scaling animation
                    Text("WinniLuck")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.yellow,
                                    Color.orange,
                                    Color.yellow.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .scaleEffect(brandingScale)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: brandingScale
                        )
                        .padding(.bottom, 40)
                }
            }
        }
        .confetti(trigger: showConfetti)
        .onAppear {
            // Start with randomization for the first number
            startFirstNumberAnimation()
            animateEntrance()
            startAutoAdvanceTimer()
            startBrandingAnimation()
        }
        .onChange(of: viewModel.isNewGameStarting) { _, isStarting in
            // When a new game is starting, restart animations
            if isStarting {
                // Reset animation states
                coinScale = 0.8
                coinRotation = 0
                showConfetti = false
                
                // Clear the flag
                viewModel.isNewGameStarting = false
                
                // Restart the game animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startFirstNumberAnimation()
                    animateEntrance()
                    startAutoAdvanceTimer()
                }
            }
        }
        .onDisappear {
            stopTimer()
            stopRandomizationTimer()
        }
        .fullScreenCover(isPresented: $viewModel.showingWinners) {
            CongratulationsView(
                winners: viewModel.gameWinners,
                gameMode: viewModel.currentGameMode ?? GameMode(title: "Juego", maxPlayers: 50, entryPriceSoles: 10, prizePerWinner: 100, maxWinners: 3, repetitions: 3),
                onPlayAgain: {
                    viewModel.startNewGame()
                },
                onGoHome: {
                    viewModel.goHome()
                    dismiss()
                },
                onStartNewGame: { gameMode, players in
                    // Create a new game session with the selected mode and players
                    let playerCount = players.count
                    let grossIncome = gameMode.calculateGross(for: playerCount)
                    let estimatedWinners = 1
                    let payout = gameMode.calculatePayout(for: estimatedWinners)
                    let profit = gameMode.calculateProfit(for: playerCount, winners: estimatedWinners)
                    
                    let newGameSession = GameSession(
                        id: UUID(),
                        modeID: gameMode.id,
                        startRange: 1,
                        endRange: gameMode.maxPlayers,
                        repetitions: gameMode.repetitions,
                        numWinners: estimatedWinners,
                        playerIDs: players.map { $0.id },
                        winningNumbers: [],
                        winnerIDs: [],
                        date: Date(),
                        grossIncome: grossIncome,
                        profit: profit,
                        payout: payout
                    )
                    
                    // Update the view model with the new game
                    viewModel.currentGameSession = newGameSession
                    viewModel.currentGameMode = gameMode
                    viewModel.currentPlayers = players
                    viewModel.startNumber = "1"
                    viewModel.endNumber = "\(gameMode.maxPlayers)"
                    
                    // Reset game state
                    viewModel.numbers = []
                    viewModel.currentNumber = 0
                    viewModel.currentRepetition = 0
                    viewModel.totalRepetitions = 1
                    viewModel.isGenerating = false
                    viewModel.showingWinners = false
                    
                    // Generate new random numbers and start the game
                    viewModel.generateRandomNumbers()
                },
                settings: settings
            )
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
            
            // Check if we have enough winners at the finish line after this number
            if viewModel.shouldStopGame() {
                stopTimer()
                // Stop any ongoing speech immediately
                speechHelper.stopSpeaking()
                // Start the completion animation - winners have reached finish line
                startCompletionAnimation()
            }
        }
    }
    
    private func startAutoAdvanceTimer() {
        // Start timer after initial entrance animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                // Check if we have enough winners at the finish line
                if viewModel.shouldStopGame() {
                    stopTimer()
                    speechHelper.stopSpeaking()
                    // Start the completion animation - winners have reached finish line
                    startCompletionAnimation()
                } else if viewModel.hasNextNumber {
                    nextNumber()
                } else {
                    stopTimer()
                    speechHelper.stopSpeaking()
                    // Start the completion animation when we naturally reach the end
                    startCompletionAnimation()
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
            
            // Check if we have enough winners at the finish line immediately
            if viewModel.shouldStopGame() {
                speechHelper.stopSpeaking()
                // Start the completion animation - winners have reached finish line
                startCompletionAnimation()
            }
        }
    }
    
    private func startBrandingAnimation() {
        // Start the infinite scaling animation with a slight delay for smooth entry
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                brandingScale = 1.1
            }
        }
    }
    
    private func startCompletionAnimation() {
        // Give 1.5 seconds to see the winners at the finish line and celebrate
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            viewModel.finalizeGame()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getPlayerForNumber(_ number: Int) -> Player? {
        // Use the current players directly from the viewModel
        return viewModel.currentPlayers.first { player in
            player.selectedNumber == number
        }
    }
}

struct WinningNumberCoin: View {
    let number: Int
    let count: Int
    let playerName: String?
    let position: Int
    let prize: Decimal
    
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
            
            // Position label
            Text(positionText)
                .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.7))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Prize amount
            Text(formatPrize(prize))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.6))
                )
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            
            // Player name - enhanced visibility
            if let playerName = playerName {
                Text(playerName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
            }
            
            // Count label
            if count > 1 {
            Text("\(count)×")
                    .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.5))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private var positionText: String {
        switch position {
        case 1:
            return "1er Lugar"
        case 2:
            return "2do Lugar"
        case 3:
            return "3er Lugar"
        default:
            return "\(position)° Lugar"
        }
    }
    
    private func formatPrize(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "S/. 0"
    }
}

struct PrizeBreakdownItem: View {
    let position: Int
    let prize: Decimal
    
    var body: some View {
        HStack(spacing: 4) {
            // Position label
            Text(positionText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.yellow)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.7))
                )
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            // Prize amount
            Text(formatPrize(prize))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.6))
                )
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
    }
    
    private var positionText: String {
        switch position {
        case 1:
            return "1er"
        case 2:
            return "2do"
        case 3:
            return "3er"
        default:
            return "\(position)°"
        }
    }
    
    private func formatPrize(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "S/. 0"
    }
}

struct SingleProgressView: View {
    let currentRepetition: Int
    let totalRepetitions: Int
    let currentNumber: Int
    let currentNumberCount: Int
    let numberCounts: [Int: Int]
    let targetRepetitions: Int
    let numbersDrawn: Int
    let totalNumbers: Int
    let isCompletingRace: Bool
    
    private var remainingNumbers: Int {
        max(0, totalNumbers - numbersDrawn)
    }
    
    private var maxCallCount: Int {
        // Use target repetitions as the max for the progress bar scale
        return targetRepetitions
    }
    
    private var racingNumbers: [RacingNumber] {
        // Get ALL numbers that have been called (not limited to 8)
        return numberCounts
            .filter { $0.value > 0 } // Only numbers that have been called
            .map { (number, count) in
                RacingNumber(
                    number: number,
                    count: count,
                    isCurrentNumber: number == currentNumber
                )
            }
            .sorted { $0.number < $1.number } // Sort by number for consistent display
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                // Racing Progress Bar with numbers ON the bar
                VStack(spacing: 8) {
                    // Progress bar range labels - tracking numbers drawn
                    HStack {
                        Text("\(numbersDrawn)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                            )
                        
                        Spacer()
                        
                        Text("\(max(0, totalNumbers - numbersDrawn))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(remainingNumbers <= 5 ? .red : .white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(remainingNumbers <= 5 ? Color.red.opacity(0.3) : Color.black.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(remainingNumbers <= 5 ? Color.red.opacity(0.6) : Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .scaleEffect(remainingNumbers <= 5 ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: remainingNumbers)
                    }
                    
                    // Racing Progress Bar with numbers positioned on it
                    ZStack {
                        // Progress bar background (full track) - Dark elegant style
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.6),
                                        Color.black.opacity(0.8),
                                        Color.black.opacity(0.9),
                                        Color.black.opacity(0.8),
                                        Color.black.opacity(0.6)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                        
                        // Racing numbers positioned on the progress bar
                        ForEach(racingNumbers, id: \.number) { racingNumber in
                            VStack(spacing: 4) {
                                // Golden coin positioned on progress bar
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: racingNumber.isCurrentNumber ? [
                                                    Color.yellow,
                                                    Color.orange,
                                                    Color.red.opacity(0.8)
                                                ] : [
                                                    Color.yellow.opacity(0.9),
                                                    Color.orange.opacity(0.8),
                                                    Color.yellow.opacity(0.6)
                                                ]),
                                                center: .topLeading,
                                                startRadius: 1,
                                                endRadius: 15
                                            )
                                        )
                                        .frame(width: 30, height: 30)
                                        .shadow(color: .orange.opacity(0.6), radius: 3, x: 0, y: 2)
                                        .scaleEffect(racingNumber.isCurrentNumber ? 1.3 : 1.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: racingNumber.isCurrentNumber)
                                    
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.orange, .yellow, .orange]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                        .frame(width: 30, height: 30)
                                        .scaleEffect(racingNumber.isCurrentNumber ? 1.3 : 1.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: racingNumber.isCurrentNumber)
                                    
                                    Text("\(racingNumber.number)")
                                        .font(.system(size: racingNumber.isCurrentNumber ? 11 : 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
                                        .scaleEffect(racingNumber.isCurrentNumber ? 1.3 : 1.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: racingNumber.isCurrentNumber)
                                }
                                .offset(x: calculatePositionOnBar(for: racingNumber, in: geometry.size.width - 60), y: calculateVerticalOffset(for: racingNumber))
                                .animation(.easeInOut(duration: 0.8), value: racingNumber.count)
                                
                                // Count below the coin - show actual number instead of localized format
                                Text("\(racingNumber.count)x")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.yellow)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.black.opacity(0.8))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.orange.opacity(0.6), lineWidth: 0.5)
                                    )
                                    .offset(x: calculatePositionOnBar(for: racingNumber, in: geometry.size.width - 60), y: calculateVerticalOffset(for: racingNumber) + 25)
                                    .scaleEffect(racingNumber.isCurrentNumber ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.8), value: racingNumber.count)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: racingNumber.isCurrentNumber)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Current Number Display - Removed as requested
            }
        }
        .frame(height: 130)
        .padding(.horizontal, 24)
        .clipped() // Ensures content stays within bounds
    }
    
    private func calculatePositionOnBar(for racingNumber: RacingNumber, in availableWidth: CGFloat) -> CGFloat {
        // Position numbers on the progress bar based on their call count toward target repetitions
        // This creates natural racing progression: 1st call → start, 2nd call → middle, target call → finish
        let progress = Double(racingNumber.count - 1) / Double(max(targetRepetitions - 1, 1))
        let basePosition = CGFloat(progress) * availableWidth - (availableWidth / 2)
        
        // Get all numbers with the same count for better clustering
        let numbersWithSameCount = numberCounts.filter { $0.value == racingNumber.count }.keys.sorted()
        guard let index = numbersWithSameCount.firstIndex(of: racingNumber.number) else { return basePosition }
        
        // Create horizontal clustering with gentle spread
        let clusterOffset = CGFloat(index - numbersWithSameCount.count / 2) * 4.0
        return basePosition + clusterOffset
    }
    
    private func calculateVerticalOffset(for racingNumber: RacingNumber) -> CGFloat {
        // Create more natural vertical stacking
        let numbersWithSameCount = numberCounts.filter { $0.value == racingNumber.count }.keys.sorted()
        guard let index = numbersWithSameCount.firstIndex(of: racingNumber.number) else { return 0 }
        
        // Create a pyramid-like stacking effect
        let totalNumbers = numbersWithSameCount.count
        let centerIndex = totalNumbers / 2
        let distanceFromCenter = abs(index - centerIndex)
        
        // Alternate above and below the center line
        let verticalDirection: CGFloat = (index % 2 == 0) ? -1 : 1
        let stackLevel = CGFloat((distanceFromCenter + 1) / 2)
        
        return verticalDirection * stackLevel * 6 // Reduced offset for gentler stacking
    }
}

struct RacingNumber {
    let number: Int
    let count: Int
    let isCurrentNumber: Bool
}



#Preview {
    let viewModel = RandomNumberViewModel()
    viewModel.currentNumber = 42
    viewModel.currentRepetition = 1
    viewModel.totalRepetitions = 5
    
    return ResultView(viewModel: viewModel, settings: SettingsModel())
} 