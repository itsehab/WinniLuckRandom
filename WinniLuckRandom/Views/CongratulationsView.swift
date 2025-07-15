//
//  CongratulationsView.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI

struct CongratulationsView: View {
    let winners: [WinnerData]
    let gameMode: GameMode
    let onPlayAgain: () -> Void
    let onGoHome: () -> Void
    let onStartNewGame: (GameMode, [Player]) -> Void
    @ObservedObject var settings: SettingsModel
    
    @State private var showConfetti = false
    @State private var animateWinners = false
    @State private var celebrationScale: CGFloat = 0.8
    @StateObject private var gameModesViewModel = GameModesViewModel.shared
    @State private var selectedGameMode: GameMode?
    @State private var showingPlayerEntry = false
    
    var body: some View {
        ZStack {
            // Background
            BackgroundView(image: settings.backgroundImage)
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Winners display
                winnersSection
                
                Spacer()
                
                // Game mode selection and start button
                gameSelectionSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
        }
        .navigationBarHidden(true)
        .onAppear {
            startCelebration()
            // Load game modes when the view appears
            Task {
                await gameModesViewModel.loadGameModesIfNeeded()
            }
        }
        .sheet(isPresented: $showingPlayerEntry) {
            if let selectedMode = selectedGameMode {
                PlayerEntryView(gameMode: selectedMode) { players in
                    showingPlayerEntry = false
                    // Start new game with the selected mode and players
                    onStartNewGame(selectedMode, players)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Celebration title
            Text("🎉 ¡Felicidades! 🎉")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.yellow)
                .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                .scaleEffect(celebrationScale)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: celebrationScale)
            
            // Game mode and prize info
            VStack(spacing: 8) {
                Text(gameMode.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                Text("Ganadores")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Winners Section
    
    private var winnersSection: some View {
        VStack(spacing: 20) {
            ForEach(Array(winners.enumerated()), id: \.element.id) { index, winner in
                WinnerCard(
                    winner: winner,
                    position: index + 1,
                    prize: gameMode.getPrize(for: index + 1),
                    isAnimated: animateWinners
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom)
                        .combined(with: .scale(scale: 0.8))
                        .combined(with: .opacity),
                    removal: .move(edge: .top)
                        .combined(with: .scale(scale: 0.8))
                        .combined(with: .opacity)
                ))
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(Double(index) * 0.2), value: animateWinners)
            }
        }
    }
    
    // MARK: - Game Selection Section
    
    private var gameSelectionSection: some View {
        VStack(spacing: 20) {
            // Game mode dropdown
            Menu {
                ForEach(gameModesViewModel.gameModes, id: \.id) { mode in
                    Button(action: {
                        selectedGameMode = mode
                    }) {
                        HStack {
                            Text(mode.title)
                            Spacer()
                            Text(mode.formattedEntryPrice)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedGameMode?.title ?? "Seleccionar Modo de Juego")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let mode = selectedGameMode {
                            Text("Entrada \(mode.formattedEntryPrice)")
                                .font(.subheadline)
                                .opacity(0.8)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            
            // Start game button
            Button(action: {
                if let selectedMode = selectedGameMode {
                    showingPlayerEntry = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Empezar Juego")
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
                                gradient: Gradient(colors: selectedGameMode != nil ? [.green, Color(red: 0.0, green: 0.7, blue: 0.3)] : [.gray, .gray]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .disabled(selectedGameMode == nil)
            .opacity(selectedGameMode != nil ? 1.0 : 0.6)
            
            // Home button (secondary)
            Button(action: {
                onGoHome()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Inicio")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.bottom, 34)
    }
    
    // MARK: - Animation Functions
    
    private func startCelebration() {
        // Start confetti
        showConfetti = true
        
        // Animate celebration title
        celebrationScale = 1.1
        
        // Animate winners appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateWinners = true
        }
    }
}

// MARK: - Winner Card Component

struct WinnerCard: View {
    let winner: WinnerData
    let position: Int
    let prize: Decimal
    let isAnimated: Bool
    
    @State private var shimmerOffset: CGFloat = -1
    
    private var positionColor: Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.brown
        default: return .orange
        }
    }
    
    private var positionIcon: String {
        switch position {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "star.fill"
        }
    }
    
    private var formattedPrize: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: prize)) ?? "S/. 0.00"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Position indicator
            ZStack {
                Circle()
                    .fill(positionColor)
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: positionIcon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            
            // Player avatar
            AvatarImageView(
                avatarURL: winner.player.avatarURL,
                size: 60
            )
            .overlay(
                Circle()
                    .stroke(positionColor, lineWidth: 3)
                    .shadow(color: positionColor.opacity(0.5), radius: 4, x: 0, y: 2)
            )
            
            // Winner info
            VStack(alignment: .leading, spacing: 4) {
                Text(winner.player.firstName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                HStack {
                    Text("Número:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(winner.number)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                Text(formattedPrize)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                .overlay(
                    // Shimmer effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    positionColor.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset * 300)
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: shimmerOffset)
                )
        )
        .scaleEffect(isAnimated ? 1.0 : 0.8)
        .opacity(isAnimated ? 1.0 : 0.0)
        .onAppear {
            shimmerOffset = 1
        }
    }
}

// MARK: - Winner Data Model

struct WinnerData: Identifiable {
    let id = UUID()
    let player: Player
    let number: Int
    let finalCount: Int
}



// MARK: - Preview

#Preview {
    let sampleWinners = [
        WinnerData(
            player: Player(firstName: "Juan", selectedNumber: 7, avatarURL: AvatarService.generateRandomAvatarURL()),
            number: 7,
            finalCount: 3
        ),
        WinnerData(
            player: Player(firstName: "María", selectedNumber: 15, avatarURL: AvatarService.generateRandomAvatarURL()),
            number: 15,
            finalCount: 3
        ),
        WinnerData(
            player: Player(firstName: "Carlos", selectedNumber: 23, avatarURL: AvatarService.generateRandomAvatarURL()),
            number: 23,
            finalCount: 3
        )
    ]
    
    let gameMode = GameMode(title: "Juego de Prueba", maxPlayers: 50, entryPriceSoles: 10, prizePerWinner: 100, maxWinners: 3, repetitions: 3)
    
    CongratulationsView(
        winners: sampleWinners,
        gameMode: gameMode,
        onPlayAgain: {},
        onGoHome: {},
        onStartNewGame: { _, _ in },
        settings: SettingsModel()
    )
} 