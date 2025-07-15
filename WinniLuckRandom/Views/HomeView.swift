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
    @StateObject private var gameModesViewModel = GameModesViewModel.shared
    @State private var showingSettings = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    // Removed local showingResult state - now using viewModel.showingResult
    @State private var coinRotation: Double = 0
    @State private var selectedGameMode: GameMode?
    @State private var showingPlayerEntry = false
    @State private var currentPlayers: [Player] = []
    @State private var showingAdminDashboard = false
    @State private var currentGameModeIndex: Int = 0
    @State private var brandingScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                BackgroundView(image: settings.backgroundImage)
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Main content - restructured for centered layout
                    VStack {
                        Spacer()
                        
                        // Game selection section - centered
                        gameSelectionSection
                        
                        Spacer()
                        
                        // Start button moved to bottom
                            startButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        
                        // Bottom navigation
                        bottomNavigation
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            Task {
                // Force refresh for testing order changes
                await gameModesViewModel.forceRefresh()
                
                // Wait a moment to ensure data is fully loaded and UI is updated
                await MainActor.run {
                    // Auto-select first game mode if available
                    if selectedGameMode == nil, let firstMode = gameModesViewModel.gameModes.first {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedGameMode = firstMode
                            currentGameModeIndex = 0
                        }
                        viewModel.startNumber = "1"
                        viewModel.endNumber = "\(firstMode.maxPlayers)"
                    }
                }
            }
            
            // Start the infinite scaling animation for WinniLuck text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    brandingScale = 1.1
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings)
        }
        .sheet(isPresented: $showingAdminDashboard) {
            DashboardView()
                .onDisappear {
                    // Refresh game modes when coming back from admin dashboard
                    Task {
                        await gameModesViewModel.forceRefresh()
                        
                        // Ensure UI updates on main actor
                        await MainActor.run {
                            // Auto-select first game mode if available
                            if selectedGameMode == nil, let firstMode = gameModesViewModel.gameModes.first {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    selectedGameMode = firstMode
                                }
                                viewModel.startNumber = "1"
                                viewModel.endNumber = "\(firstMode.maxPlayers)"
                            }
                        }
                    }
                }
        }
        .sheet(isPresented: $showingPlayerEntry) {
            if let gameMode = selectedGameMode {
                PlayerEntryView(gameMode: gameMode) { players in
                    currentPlayers = players
                    showingPlayerEntry = false
                    startGame(with: players)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingResult) {
            ResultView(viewModel: viewModel, settings: settings)
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Spacer()
            titleText
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
    }
    
    // MARK: - Title Text
    private var titleText: some View {
        Text("WinniLuck")
            .font(.system(size: 28, weight: .bold, design: .rounded))
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
    }
    
        // MARK: - Game Mode Card Stack
    private struct GameModeCardStack: View {
        let gameModes: [GameMode]
        @Binding var selectedGameMode: GameMode?
        let onGameModeSelected: (GameMode) -> Void
        @Binding var currentIndex: Int
        
        @GestureState private var dragOffset: CGSize = .zero
        @State private var topCardOffset: CGSize = .zero
        @State private var cards: [GameModeCardData] = []
        @State private var currentStartIndex: Int = 0  // Track which part of gameModes we're showing
        
        // adjustable constants
        private let spacing: CGFloat = 15      // vertical gap between cards
        private let scaleStep: CGFloat = 0.06  // smaller cards near back
        private let rotationStep: Double = 2   // degrees
        
        var body: some View {
            ZStack {
                ForEach(cards.indices, id: \.self) { index in
                    card(at: index)
                }
            }
            .frame(height: 380)
            .clipped() // Simple clipping to prevent cards from going beyond the frame
            .onAppear {
                setupCards()
            }
            .onChange(of: gameModes) { _, _ in
                setupCards()
            }
        }
        
        // MARK: - Card builder
        @ViewBuilder
        private func card(at index: Int) -> some View {
            let isTop = index == cards.count - 1
            let cardData = cards[index]
            
            // Calculate the pull-up effect for cards below
            let pullUpOffset = calculatePullUpOffset(for: index, isTop: isTop)
            
            GameModeCard(gameMode: cardData.gameMode)
                .id(cardData.id) // Use stable ID for smooth animations
                .scaleEffect(calculateScale(for: index, isTop: isTop))
                .rotationEffect(.degrees(
                    isTop ? rotation(for: dragOffset) : 0
                ))
                .offset(y: calculateCardOffset(for: index, isTop: isTop) + pullUpOffset)
                .zIndex(Double(index))
                .gesture(
                    isTop ? dragGesture : nil
                )
                .animation(
                    isTop ? .interactiveSpring(response: 0.35,
                                               dampingFraction: 0.75,
                                               blendDuration: 0.25)
                          : .interactiveSpring(response: 0.4,
                                               dampingFraction: 0.8,
                                               blendDuration: 0.15),
                                         value: isTop ? dragOffset.height : pullUpOffset
                )
                .onTapGesture {
                    if isTop {
                        selectCurrentCard()
                    }
                }
        }
        
        // MARK: - Animation Calculations
        private func calculateScale(for index: Int, isTop: Bool) -> CGFloat {
            let baseScale = 1 - CGFloat(cards.count - 1 - index) * scaleStep
            
            // If top card is being dragged up, make cards below slightly larger
            if !isTop && dragOffset.height < 0 {
                let dragProgress = min(abs(dragOffset.height) / 120, 1.0)
                let scaleBoost = dragProgress * 0.03 // Boost scale by up to 3%
                return min(baseScale + scaleBoost, 1.0)
            }
            
            return baseScale
        }
        
        private func calculateCardOffset(for index: Int, isTop: Bool) -> CGFloat {
            let baseOffset = CGFloat(cards.count - 1 - index) * spacing
            let topCardMovement = isTop ? topCardOffset.height + dragOffset.height : 0
            
            return baseOffset + topCardMovement
        }
        
        private func calculatePullUpOffset(for index: Int, isTop: Bool) -> CGFloat {
            guard !isTop && dragOffset.height < 0 else { return 0 }
            
            // Calculate how much to pull up cards below based on drag progress
            let dragProgress = min(abs(dragOffset.height) / 120, 1.0)
            let cardPosition = CGFloat(cards.count - 1 - index) // 0 for second card, 1 for third, etc.
            
            // Pull up with diminishing effect for cards further back
            let pullUpStrength = (spacing * 0.6) * dragProgress // Pull up by 60% of spacing
            let distanceMultiplier = 1.0 / (cardPosition + 1) // Diminishing effect
            
            return -pullUpStrength * distanceMultiplier
        }
        
        // MARK: - Drag gesture
        private var dragGesture: some Gesture {
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    let shouldDismiss = value.translation.height < -120
                    if shouldDismiss {
                        // Check if we're wrapping around from last to first
                        let isWrappingAround = isLastCardToFirstTransition()
                        
                        // Use smoother, faster animation for wrap-around to feel more natural
                        let animationDuration = isWrappingAround ? 0.3 : 0.25
                        let animation: Animation = isWrappingAround 
                            ? .easeInOut(duration: animationDuration)
                            : .spring(response: 0.6, dampingFraction: 0.8)
                        
                        withAnimation(animation) {
                            // Move card off screen (clipping will hide it naturally)
                            topCardOffset = CGSize(width: 0, height: -500)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                            recycleTopCard()
                        }
                    } else {
                        // Snap back with spring animation
                        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.75)) {
                            topCardOffset = .zero
                        }
                    }
                }
        }
        
        // MARK: - Helpers
        private func setupCards() {
            guard !gameModes.isEmpty else {
                cards = []
                currentStartIndex = 0
                return
            }
            
            // Reset to start of the game modes array
            currentStartIndex = 0
            
            // Create initial set of cards (show up to 5 at once for depth)
            // Reverse the game modes so that order 1 appears on top (highest zIndex)
            let reversedGameModes = Array(gameModes.reversed())
            let maxVisible = min(5, reversedGameModes.count)
            cards = (0..<maxVisible).compactMap { index in
                let gameMode = reversedGameModes[index]
                return GameModeCardData(gameMode: gameMode)
            }
            
            // Set initial selection and sync dots indicator
            // The top card is the last in the cards array, but represents the first game mode (lowest order)
            if let topCard = cards.last {
                selectGameMode(topCard.gameMode)
                // Find the correct index in the original gameModes array
                if let originalIndex = gameModes.firstIndex(where: { $0.id == topCard.gameMode.id }) {
                    currentIndex = originalIndex
                }

            }
        }
        
        private func recycleTopCard() {
            guard !cards.isEmpty && !gameModes.isEmpty else { return }
            
            // Check if we're wrapping around from last to first
            let isWrapping = isLastCardToFirstTransition()
            
            if isWrapping {
                // For wrap-around, reset to show the first cards again
                setupCards()
            } else {
                // Normal progression: move to the next position in the sequence
                currentStartIndex = (currentStartIndex + 1) % gameModes.count
                
                // Remove top card
                cards.removeLast()
                
                // Calculate which game mode should be added to the bottom
                // Since we display in reversed order, we need to get the appropriate game mode
                let reversedGameModes = Array(gameModes.reversed())
                let newBottomIndex = (currentStartIndex + cards.count) % reversedGameModes.count
                let newBottomGameMode = reversedGameModes[newBottomIndex]
                
                // Add the new card to bottom
                let newCard = GameModeCardData(gameMode: newBottomGameMode)
                cards.insert(newCard, at: 0)
                
                // Update selection to the new top card and sync dots
                if let newTopCard = cards.last {
                    selectGameMode(newTopCard.gameMode)
                    // Find the correct index in the original gameModes array for the dots indicator
                    if let originalIndex = gameModes.firstIndex(where: { $0.id == newTopCard.gameMode.id }) {
                        currentIndex = originalIndex
                    }
                }
            }
            
            topCardOffset = .zero
        }
        
        private func selectCurrentCard() {
            guard let topCard = cards.last else { return }
            selectGameMode(topCard.gameMode)
            // Find the correct index in the original gameModes array
            if let originalIndex = gameModes.firstIndex(where: { $0.id == topCard.gameMode.id }) {
                currentIndex = originalIndex
            }
        }
        
        private func selectGameMode(_ gameMode: GameMode) {
            selectedGameMode = gameMode
            onGameModeSelected(gameMode)
            // Update the dots indicator state
            updateDotsIndicator(for: gameMode)
        }
        
        private func updateDotsIndicator(for gameMode: GameMode) {
            // Find the correct index in the original gameModes array
            if let originalIndex = gameModes.firstIndex(where: { $0.id == gameMode.id }) {
                currentIndex = originalIndex
            }
        }
        
        private func isLastCardToFirstTransition() -> Bool {
            // Check if the current top card represents the last game mode in the original sorted order
            guard let topCard = cards.last else { return false }
            // Find the original index of the current top card
            if let originalIndex = gameModes.firstIndex(where: { $0.id == topCard.gameMode.id }) {
                // Check if this is the last card in the sequence (highest index)
                return originalIndex == gameModes.count - 1
            }
            return false
        }
        

        
        private func rotation(for offset: CGSize) -> Double {
            let maxDegrees: Double = 8
            return Double(offset.width / 15).clamped(to: -maxDegrees...maxDegrees)
        }
    }
    
    // MARK: - Game Mode Indicator
    private struct GameModeIndicator: View {
        let currentIndex: Int
        let totalCount: Int
        
        var body: some View {
            // Page dots indicator only
            HStack(spacing: 6) {
                ForEach(0..<totalCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Game Mode Card
    private struct GameModeCard: View {
        let gameMode: GameMode
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(gameMode.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Entrada \(formatCurrency(gameMode.entryPriceSoles))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Game mode icon
                    Image(systemName: "gamecontroller.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    // First row: Range information
                    HStack {
                        Text("Desde")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("1")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("Hacia")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(gameMode.maxPlayers)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    // Second row: Player and winner information
                    HStack {
                        Text("Jugadores")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(gameMode.maxPlayers)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("Ganadore(s)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(gameMode.maxWinners)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 180) // Optimized height for 3-card display
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.98),
                                Color.white.opacity(0.92)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            )
            .padding(.horizontal, 16)
        }
        
        private func formatCurrency(_ amount: Decimal) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "PEN"
            formatter.currencySymbol = "S/."
            return formatter.string(from: amount as NSDecimalNumber) ?? "S/. 0.00"
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
    
    // MARK: - Game Selection Section
    private var gameSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nuevo Juego")
                .font(.title2)
            .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .frame(maxWidth: .infinity, alignment: .center)
            
            if gameModesViewModel.isLoading {
                // Loading state
                HStack {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                    Text(NSLocalizedString("game_mode_loading", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 80)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
            } else if gameModesViewModel.gameModes.isEmpty {
                // No game modes available - show create game mode suggestion
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("game_mode_none_available", comment: ""))
                .font(.headline)
                .foregroundColor(.white)
                    
                    Text(NSLocalizedString("game_mode_create_suggestion", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: {
                        showingAdminDashboard = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(NSLocalizedString("game_mode_create_new", comment: ""))
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                .cornerRadius(8)
        }
    }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.orange.opacity(0.8))
                .cornerRadius(12)
            } else {
                // Vertical stacked game mode cards with indicator
                VStack(spacing: 16) {
                    GameModeCardStack(
                        gameModes: gameModesViewModel.gameModes,
                        selectedGameMode: $selectedGameMode,
                        onGameModeSelected: { gameMode in
                            viewModel.startNumber = "1"
                            viewModel.endNumber = "\(gameMode.maxPlayers)"
                        },
                        currentIndex: $currentGameModeIndex
                    )
                    .id(gameModesViewModel.gameModes.map { $0.id }.description)
                    
                    // Page indicator and navigation info
                    GameModeIndicator(
                        currentIndex: currentGameModeIndex,
                        totalCount: gameModesViewModel.gameModes.count
                    )
                }
            }
        }
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button(action: {
                if let gameMode = selectedGameMode {
                    // Set the game mode in the view model
                    viewModel.currentGameMode = gameMode
                    
                    // Show player entry for paid game modes
                    showingPlayerEntry = true
                } else {
                // Show alert to select game mode
                alertMessage = NSLocalizedString("game_mode_select_required", comment: "")
                showingAlert = true
            }
        }) {
            HStack {
                Image(systemName: selectedGameMode != nil ? "person.2.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text(selectedGameMode != nil ? "Empezar" : NSLocalizedString("game_mode_select_first", comment: ""))
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(startButtonBackground)
            .cornerRadius(16)
        }
        .disabled(selectedGameMode == nil)
        .opacity(selectedGameMode != nil ? 1.0 : 0.6)
    }
    
    // MARK: - Start Button Background
    private var startButtonBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: selectedGameMode != nil ? [.green, Color(red: 0.0, green: 0.7, blue: 0.3)] : [.gray, .gray]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack {
            Spacer()
            
            // Admin Dashboard button - directly show dashboard
            Button(action: {
                showingAdminDashboard = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                    Text(NSLocalizedString("admin", comment: ""))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
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
    
    // MARK: - Helper Methods
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "S/. 0.00"
    }
    

    
    private func createBasicGameModes() async {
        let localService = LocalStorageService.shared
        
        let basicGameModes = [
            GameMode(
                title: "Juego Rápido",
                maxPlayers: 5,
                entryPriceSoles: Decimal(2.00),
                prizeTiers: [Decimal(6.00)],
                maxWinners: 1,
                repetitions: 2
            ),
            GameMode(
                title: "Juego Estándar", 
                maxPlayers: 10,
                entryPriceSoles: Decimal(5.00),
                prizeTiers: [Decimal(25.00), Decimal(15.00)],
                maxWinners: 2,
                repetitions: 3
            ),
            GameMode(
                title: "Juego Premium",
                maxPlayers: 20,
                entryPriceSoles: Decimal(10.00),
                prizeTiers: [Decimal(80.00), Decimal(60.00), Decimal(40.00)],
                maxWinners: 3,
                repetitions: 5
            )
        ]
        
        for gameMode in basicGameModes {
            let success = await localService.saveGameMode(gameMode)
            print("💾 Saved game mode '\(gameMode.title)': \(success)")
        }
    }
    
    private func startGame(with players: [Player]) {
        // Create the game session with the actual players
        let playerCount = players.count
        let grossIncome = selectedGameMode?.calculateGross(for: playerCount) ?? 0
        
        // For initial setup, we don't know how many winners yet, so we estimate with 1 winner
        let estimatedWinners = 1
        let payout = selectedGameMode?.calculatePayout(for: estimatedWinners) ?? 0
        let profit = selectedGameMode?.calculateProfit(for: playerCount, winners: estimatedWinners) ?? 0
        
        let gameSession = GameSession(
            id: UUID(),
            modeID: selectedGameMode?.id ?? UUID(),
            startRange: 1,
            endRange: selectedGameMode?.maxPlayers ?? 0,
            repetitions: selectedGameMode?.repetitions ?? 1,
            numWinners: estimatedWinners,
            playerIDs: players.map { $0.id },
            winningNumbers: [],
            winnerIDs: [],
            date: Date(),
            grossIncome: grossIncome,
            profit: profit,
            payout: payout
        )
        
        viewModel.currentGameSession = gameSession
        viewModel.currentPlayers = players
        viewModel.generateRandomNumbers()
    }
    
    private func resetGame() {
        viewModel.currentGameSession = nil
        viewModel.numbers = []
        viewModel.currentNumber = 0
        viewModel.isGenerating = false
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

// MARK: - Extensions
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - Game Mode Card Data
private struct GameModeCardData: Identifiable {
    let id: UUID
    let gameMode: GameMode
    
    init(gameMode: GameMode) {
        self.id = UUID()
        self.gameMode = gameMode
    }
} 