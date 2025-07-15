//
//  PlayerEntryView.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI

struct PlayerEntryView: View {
    let gameMode: GameMode
    let onGameStart: ([Player]) -> Void
    
    @StateObject private var viewModel: PlayerEntryViewModel
    @StateObject private var settings = SettingsModel()
    @Environment(\.dismiss) var dismiss
    @State private var newPlayerName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(gameMode: GameMode, onGameStart: @escaping ([Player]) -> Void) {
        self.gameMode = gameMode
        self.onGameStart = onGameStart
        self._viewModel = StateObject(wrappedValue: PlayerEntryViewModel(gameMode: gameMode))
    }
    
    var body: some View {
        ZStack {
            // Background
            BackgroundView(image: settings.backgroundImage)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content with fixed bottom button
                ZStack {
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Game mode info - more compact
                            compactGameModeCard
                                .padding(.top, 16)
                            
                            // Player entry section
                            playerEntrySection
                            
                            // Players list
                            playersListSection
                            
                            // Bottom spacing for potential button
                            Color.clear
                                .frame(height: 50)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Fixed start game button at bottom
                    VStack {
                        Spacer()
                        fixedStartGameButton
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            setupInitialState()
        }
        .onDisappear {
            // Clear focus when view disappears to prevent keyboard issues
            isTextFieldFocused = false
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                dismissKeyboard()
                isTextFieldFocused = false
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Title - now shows game mode name
            Text(viewModel.selectedGameMode.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
            
            Spacer()
            
            // Spacer for balance
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Compact Game Mode Card
    private var compactGameModeCard: some View {
        HStack(spacing: 32) {
            // Entry price - label and value next to each other
            HStack(spacing: 8) {
                Text("Precio")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text(viewModel.selectedGameMode.formattedEntryPrice)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Max players - label and value next to each other
            HStack(spacing: 8) {
                Text("Máx Jugadores")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(viewModel.selectedGameMode.maxPlayers)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Player Entry Section
    private var playerEntrySection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Jugadores")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                // Progress indicator
                Text("\(viewModel.players.count)/\(viewModel.selectedGameMode.maxPlayers)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.3))
                    )
            }
            
            // Add player form with inline plus button
            HStack(spacing: 0) {
                TextField("Nombre de Jugador", text: $newPlayerName)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        addPlayer()
                    }
                    .disabled(viewModel.isAtMaxCapacity)
                    .padding(.leading, 16)
                    .padding(.trailing, 50) // Space for plus button
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(inputBackgroundColor)
                            .stroke(inputBorderColor, lineWidth: inputBorderWidth)
                    )
                    .overlay(
                        // Plus button inside the input
                        HStack {
                            Spacer()
                            Button(action: addPlayer) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(plusButtonColor)
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 26, height: 26)
                                    )
                            }
                            .disabled(!canAddPlayer)
                            .padding(.trailing, 8)
                        }
                    )
            }
        }
    }
    
    // MARK: - Players List Section
    private var playersListSection: some View {
        VStack(spacing: 16) {
            // Section header - always shown
            HStack {
                Text("Jugadores Agregados")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                Spacer()
            }
            
            // Smart flowing layout for all players
            if !viewModel.players.isEmpty {
                VStack(spacing: 12) {
                    FlowingPlayerLayout(
                        players: viewModel.players,
                        gameMode: viewModel.selectedGameMode,
                        onRemove: { player in
                            removePlayer(player)
                        },
                        onNumberSelect: { player, number in
                            updatePlayerNumber(player, to: number)
                        },
                        onNumberDeselect: { player in
                            clearPlayerNumber(player)
                        },
                        isNumberAvailable: { number in
                            !viewModel.isNumberSelected(number)
                        }
                    )
                }
                .animation(.easeInOut(duration: 0.4), value: viewModel.players.map { "\($0.id)-\($0.selectedNumber?.description ?? "nil")" })
            }
        }
    }
    
    // MARK: - Fixed Start Game Button
    private var fixedStartGameButton: some View {
        VStack {
            Spacer()
            
            // Only show button when all players have numbers assigned
            if canStartGame {
                Button(action: {
                    startGame()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                        
                        Text("Empezar")
                            .foregroundColor(.white)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(startButtonBackground)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 34) // Safe area bottom
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom)
                        .combined(with: .scale(scale: 0.8))
                        .combined(with: .opacity),
                    removal: .move(edge: .bottom)
                        .combined(with: .scale(scale: 0.8))
                        .combined(with: .opacity)
                ))
            }
        }
        .animation(.easeOut(duration: 0.4), value: canStartGame)
    }
    
    // MARK: - Input Styling Properties
    private var inputBackgroundColor: Color {
        newPlayerName.isEmpty ? Color.white.opacity(0.9) : Color.yellow.opacity(0.1)
    }
    
    private var inputBorderColor: Color {
        newPlayerName.isEmpty ? Color.gray.opacity(0.3) : Color.yellow
    }
    
    private var inputBorderWidth: CGFloat {
        newPlayerName.isEmpty ? 1.0 : 2.0
    }
    
    private var plusButtonColor: Color {
        canAddPlayer ? (newPlayerName.isEmpty ? Color.gray.opacity(0.6) : Color.yellow) : Color.gray.opacity(0.3)
    }
    
    // MARK: - Start Button Background
    private var startButtonBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: canStartGame ? [.green, Color(red: 0.0, green: 0.7, blue: 0.3)] : [.gray, .gray.opacity(0.8)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Computed Properties
    private var canAddPlayer: Bool {
        !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !viewModel.isAtMaxCapacity
    }
    
    private var canStartGame: Bool {
        viewModel.isAtMaxCapacity && // Must have all max players
        viewModel.hasAllPlayersSelectedNumbers() // All players must have selected numbers
    }
    
    // MARK: - Actions
    private func setupInitialState() {
        // Focus on text field when view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !viewModel.isAtMaxCapacity {
                isTextFieldFocused = true
            }
        }
    }
    
    private func addPlayer() {
        let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showError(NSLocalizedString("please_enter_player_name", comment: ""))
            return
        }
        
        guard !viewModel.isAtMaxCapacity else {
            showError(NSLocalizedString("max_players_reached", comment: ""))
            return
        }
        
        let player = Player(firstName: trimmedName)
        viewModel.addPlayer(player)
        
        // Clear the text field
        newPlayerName = ""
        
        // Keep focus on text field if not at max capacity
        if !viewModel.isAtMaxCapacity {
            isTextFieldFocused = true
        } else {
            // Dismiss keyboard when at max capacity
            dismissKeyboard()
            isTextFieldFocused = false
        }
    }
    
    private func removePlayer(_ player: Player) {
        viewModel.removePlayer(player)
    }
    
    private func updatePlayerNumber(_ player: Player, to number: Int) {
        viewModel.assignNumber(number, to: player)
    }
    
    private func clearPlayerNumber(_ player: Player) {
        viewModel.clearPlayerNumber(player)
    }
    
    private func startGame() {
        guard viewModel.players.count >= 2 else {
            showError(NSLocalizedString("minimum_players_required", comment: ""))
            return
        }
        
        guard viewModel.hasAllPlayersSelectedNumbers() else {
            showError(NSLocalizedString("all_players_must_select_numbers", comment: ""))
            return
        }
        
        // Dismiss keyboard and clear focus
        dismissKeyboard()
        isTextFieldFocused = false
        
        // Add small delay to ensure keyboard is properly dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
            onGameStart(viewModel.players)
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Flowing Player Layout
struct FlowingPlayerLayout: View {
    let players: [Player]
    let gameMode: GameMode
    let onRemove: (Player) -> Void
    let onNumberSelect: (Player, Int) -> Void
    let onNumberDeselect: (Player) -> Void
    let isNumberAvailable: (Int) -> Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(layoutRows, id: \.id) { row in
                row.view
            }
        }
    }
    
    private var layoutRows: [LayoutRow] {
        var rows: [LayoutRow] = []
        var compactBuffer: [Player] = []
        
        for player in players {
            let isCompact = player.selectedNumber != nil
            
            if isCompact {
                // Add to compact buffer
                compactBuffer.append(player)
                
                // If buffer has 2 cards, create a row
                if compactBuffer.count == 2 {
                    rows.append(LayoutRow(
                        id: "\(compactBuffer[0].id)-\(compactBuffer[1].id)",
                        view: AnyView(createCompactRow(compactBuffer))
                    ))
                    compactBuffer.removeAll()
                }
            } else {
                // Flush any remaining compact cards first
                if !compactBuffer.isEmpty {
                    rows.append(LayoutRow(
                        id: compactBuffer.map { $0.id.uuidString }.joined(separator: "-"),
                        view: AnyView(createCompactRow(compactBuffer))
                    ))
                    compactBuffer.removeAll()
                }
                
                // Add expanded card with context of its original position
                let cardPosition = determineCardPosition(for: player)
                rows.append(LayoutRow(
                    id: player.id.uuidString,
                    view: AnyView(createExpandedCard(player, position: cardPosition))
                ))
            }
        }
        
        // Handle any remaining compact cards
        if !compactBuffer.isEmpty {
            rows.append(LayoutRow(
                id: compactBuffer.map { $0.id.uuidString }.joined(separator: "-"),
                view: AnyView(createCompactRow(compactBuffer))
            ))
        }
        
        return rows
    }
    
    private func determineCardPosition(for player: Player) -> CardPosition {
        // Find the player's index in the overall list
        let playerIndex = players.firstIndex(where: { $0.id == player.id }) ?? 0
        
        // Count how many assigned players come before this one in the list
        var assignedPlayersBefore = 0
        for i in 0..<playerIndex {
            if players[i].selectedNumber != nil {
                assignedPlayersBefore += 1
            }
        }
        
        // Determine position based on how the compact layout would arrange them
        // Even indices (0, 2, 4...) go to left, odd indices (1, 3, 5...) go to right
        return assignedPlayersBefore % 2 == 0 ? .left : .right
    }
    
    private func createCompactRow(_ players: [Player]) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                let position: CardPosition = index == 0 ? .left : .right
                SimplifiedPlayerCard(
                    player: player,
                    gameMode: gameMode,
                    isCompactMode: true,
                    onRemove: {
                        onRemove(player)
                    },
                    onNumberSelect: { number in
                        onNumberSelect(player, number)
                    },
                    onNumberDeselect: {
                        onNumberDeselect(player)
                    },
                    isNumberAvailable: { number in
                        isNumberAvailable(number) || player.selectedNumber == number
                    }
                )
                .frame(maxWidth: .infinity)
                .transition(transitionForPosition(position, isCompact: true))
            }
            
            // Fill remaining space if only one card
            if players.count == 1 {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func createExpandedCard(_ player: Player, position: CardPosition) -> some View {
        SimplifiedPlayerCard(
            player: player,
            gameMode: gameMode,
            isCompactMode: false,
            onRemove: {
                onRemove(player)
            },
            onNumberSelect: { number in
                onNumberSelect(player, number)
            },
            onNumberDeselect: {
                onNumberDeselect(player)
            },
            isNumberAvailable: { number in
                isNumberAvailable(number) || player.selectedNumber == number
            }
        )
        .transition(transitionForPosition(position, isCompact: false))
    }
    
    private func transitionForPosition(_ position: CardPosition, isCompact: Bool) -> AnyTransition {
        if isCompact {
            // Compact cards use gentle scale and opacity
            return .asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            )
        } else {
            // Expanded cards use position-aware animations that grow from their original position
            switch position {
            case .left:
                // Cards expanding from left position grow naturally from their leading edge
                return .asymmetric(
                    insertion: .scale(scale: 0.85, anchor: .leading).combined(with: .opacity),
                    removal: .scale(scale: 0.85, anchor: .leading).combined(with: .opacity)
                )
            case .right:
                // Cards expanding from right position grow naturally from their trailing edge  
                return .asymmetric(
                    insertion: .scale(scale: 0.85, anchor: .trailing).combined(with: .opacity),
                    removal: .scale(scale: 0.85, anchor: .trailing).combined(with: .opacity)
                )
            case .center:
                // Cards already centered expand symmetrically from center
                return .asymmetric(
                    insertion: .scale(scale: 0.85, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 0.85, anchor: .center).combined(with: .opacity)
                )
            }
        }
    }
}

enum CardPosition {
    case left
    case right
    case center
}

struct LayoutRow {
    let id: String
    let view: AnyView
}

// MARK: - Simplified Player Card View
struct SimplifiedPlayerCard: View {
    let player: Player
    let gameMode: GameMode
    let isCompactMode: Bool
    let onRemove: () -> Void
    let onNumberSelect: (Int) -> Void
    let onNumberDeselect: () -> Void // New callback for deselecting numbers
    let isNumberAvailable: (Int) -> Bool
    
    @State private var isExpanded: Bool = true
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
    
    var body: some View {
        VStack(spacing: 16) {
            // Player info row
            HStack(spacing: 12) {
                // Player avatar
                AvatarImageView(
                    avatarURL: player.avatarURL,
                    size: isCompactMode ? 32 : 40
                )
                
                // Player name
                Text(player.firstName)
                    .font(isCompactMode ? .subheadline : .headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                // Selected number (if any) - for compact mode or when collapsed
                if let selectedNumber = player.selectedNumber, (isCompactMode || !isExpanded) {
                    Button(action: {
                        if !isCompactMode {
                            expandCard()
                        }
                    }) {
                        GoldenCoinNumberButton(
                            number: selectedNumber,
                            isSelected: true,
                            isAvailable: true,
                            size: isCompactMode ? 32 : 40,
                            onTap: {
                                if !isCompactMode {
                                    expandCard()
                                }
                            }
                        )
                    }
                    .onTapGesture(count: 2) {
                        // Double-click to deselect number and expand card
                        onNumberDeselect()
                        if !isCompactMode {
                            expandCard()
                        }
                    }
                }
                
                // Remove button - lighter red for dark theme
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: isCompactMode ? 18 : 22))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4)) // Lighter red for dark theme
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            
            // Number selection grid - only visible when expanded and not in compact mode
            if !isCompactMode && isExpanded {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(1...gameMode.maxPlayers, id: \.self) { number in
                        GoldenCoinNumberButton(
                            number: number,
                            isSelected: player.selectedNumber == number,
                            isAvailable: isNumberAvailable(number),
                            size: 40,
                            onTap: {
                                if player.selectedNumber == number {
                                    // Already selected, don't clear (as per requirements)
                                    return
                                } else if isNumberAvailable(number) {
                                    onNumberSelect(number)
                                    // Auto-collapse after selection with smooth animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        collapseCard()
                                    }
                                }
                            }
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
            }
        }
        .frame(maxWidth: isCompactMode ? nil : .infinity)
        .padding(isCompactMode ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: isCompactMode ? 12 : 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: isCompactMode ? 4 : 8, x: 0, y: isCompactMode ? 2 : 4)
        )
        .onChange(of: player.selectedNumber) { _, newValue in
            // Start in expanded mode if no number is selected and not in compact mode
            if newValue == nil && !isCompactMode {
                expandCard()
            }
        }
        .onAppear {
            // Start expanded if no number is selected and not in compact mode
            isExpanded = player.selectedNumber == nil && !isCompactMode
        }
    }
    
    // MARK: - Animation Functions
    private func expandCard() {
        withAnimation(.easeInOut(duration: 0.4)) {
            isExpanded = true
        }
    }
    
    private func collapseCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded = false
        }
    }
}

// MARK: - Golden Coin Number Button
struct GoldenCoinNumberButton: View {
    let number: Int
    let isSelected: Bool
    let isAvailable: Bool
    let size: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Coin background
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: coinColors),
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
                
                // Coin border
                Circle()
                    .stroke(borderGradient, lineWidth: borderWidth)
                    .frame(width: size, height: size)
                
                // Number
                Text("\(number)")
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
            }
        }
        .disabled(!isAvailable)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .opacity(coinOpacity)
        .animation(.easeInOut(duration: 0.25), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isAvailable)
    }
    
    // MARK: - Styling Properties
    private var fontSize: CGFloat {
        size * 0.4 // Proportional to coin size
    }
    
    private var coinColors: [Color] {
        if isSelected {
            return [Color.yellow, Color.orange, Color.yellow.opacity(0.8)]
        } else if isAvailable {
            return [Color.yellow.opacity(0.7), Color.orange.opacity(0.6), Color.yellow.opacity(0.5)]
        } else {
            return [Color.gray.opacity(0.4), Color.gray.opacity(0.3)]
        }
    }
    
    private var borderGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                gradient: Gradient(colors: [.black, .black.opacity(0.8), .black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [.orange, .yellow, .orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var borderWidth: CGFloat {
        let baseWidth = size / 20 // Proportional border width
        return isSelected ? baseWidth * 1.5 : baseWidth
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isAvailable {
            return .white // Changed from dark gold to white for better contrast
        } else {
            return .gray
        }
    }
    
    private var shadowColor: Color {
        if isSelected {
            return .orange.opacity(0.8)
        } else if isAvailable {
            return .orange.opacity(0.4)
        } else {
            return .gray.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        let baseRadius = size / 8 // Proportional shadow
        return isSelected ? baseRadius * 1.5 : baseRadius
    }
    
    private var coinOpacity: Double {
        if isSelected {
            return 1.0
        } else if isAvailable {
            return 1.0 // Changed from reduced opacity to full opacity for better contrast
        } else {
            return 0.4 // Less opacity for unavailable numbers
        }
    }
}

// MARK: - Legacy Components (Kept for compatibility)
struct PlayerCard: View {
    let player: Player
    let gameMode: GameMode
    let onRemove: () -> Void
    let onNumberSelect: (Int) -> Void
    let onNumberClear: () -> Void
    let isNumberAvailable: (Int) -> Bool
    
    @State private var showingNumberGrid = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    
    var body: some View {
        // Use the new simplified card
        SimplifiedPlayerCard(
            player: player,
            gameMode: gameMode,
            isCompactMode: false, // Default to false for legacy compatibility
            onRemove: onRemove,
            onNumberSelect: onNumberSelect,
            onNumberDeselect: {}, // Legacy does not support deselecting
            isNumberAvailable: isNumberAvailable
        )
    }
}

// MARK: - Number Button (Legacy - for compatibility)
struct NumberButton: View {
    let number: Int
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void
    
    var body: some View {
        GoldenCoinNumberButton(
            number: number,
            isSelected: isSelected,
            isAvailable: isAvailable,
            size: 40, // Default size for legacy compatibility
            onTap: onTap
        )
    }
}

// MARK: - Preview
#Preview {
    PlayerEntryView(gameMode: GameMode(
        title: "Modo Premium",
        maxPlayers: 10,
        entryPriceSoles: Decimal(5.00),
        prizePerWinner: Decimal(30.00),
        maxWinners: 2,
        repetitions: 3
    )) { players in
        print("Game started with players: \(players)")
    }
} 