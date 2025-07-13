//
//  PlayerEntryView.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI

struct PlayerEntryView: View {
    @ObservedObject var viewModel: PlayerEntryViewModel
    @ObservedObject var settings: SettingsModel
    @Environment(\.dismiss) var dismiss
    @State private var newPlayerName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            BackgroundView(image: settings.backgroundImage)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Game mode info
                        gameModeInfoCard
                        
                        // Player entry section
                        playerEntrySection
                        
                        // Players list
                        playersListSection
                        
                        // Start game button
                        startGameButton
                            .padding(.bottom, 100)
                    }
                    .padding(.horizontal, 16)
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
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Title
            Text(NSLocalizedString("player_registration", comment: ""))
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
    
    // MARK: - Game Mode Info Card
    private var gameModeInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text(viewModel.selectedGameMode.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("entry_price", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.selectedGameMode.formattedEntryPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("max_players", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.selectedGameMode.maxPlayers)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Player Entry Section
    private var playerEntrySection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text(NSLocalizedString("add_players", comment: ""))
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
            
            // Add player form
            HStack(spacing: 12) {
                TextField(NSLocalizedString("first_name_placeholder", comment: ""), text: $newPlayerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16))
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        addPlayer()
                    }
                    .disabled(viewModel.isAtMaxCapacity)
                
                Button(action: addPlayer) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(canAddPlayer ? .green : .gray)
                }
                .disabled(!canAddPlayer)
            }
        }
    }
    
    // MARK: - Players List Section
    private var playersListSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text(NSLocalizedString("registered_players", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                Spacer()
            }
            
            // Players grid
            if viewModel.players.isEmpty {
                emptyPlayersView
            } else {
                playersGrid
            }
        }
    }
    
    // MARK: - Empty Players View
    private var emptyPlayersView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(NSLocalizedString("no_players_yet", comment: ""))
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
    
    // MARK: - Players Grid
    private var playersGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                PlayerCard(
                    player: player,
                    assignedNumber: index + 1,
                    onRemove: {
                        removePlayer(player)
                    }
                )
            }
        }
    }
    
    // MARK: - Start Game Button
    private var startGameButton: some View {
        Button(action: {
            startGame()
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                
                Text(NSLocalizedString("start_game", comment: ""))
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(startButtonBackground)
            .cornerRadius(16)
        }
        .disabled(!canStartGame)
        .opacity(canStartGame ? 1.0 : 0.6)
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
        viewModel.players.count >= 2 // Minimum 2 players required
    }
    
    // MARK: - Actions
    private func setupInitialState() {
        // Focus on text field when view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isTextFieldFocused = true
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
        }
    }
    
    private func removePlayer(_ player: Player) {
        viewModel.removePlayer(player)
    }
    
    private func startGame() {
        guard canStartGame else {
            showError(NSLocalizedString("minimum_players_required", comment: ""))
            return
        }
        
        viewModel.startGame()
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Player Card View
struct PlayerCard: View {
    let player: Player
    let assignedNumber: Int
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Assigned number
            Text("\(assignedNumber)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.blue)
                )
            
            // Player name
            VStack(alignment: .leading, spacing: 2) {
                Text(player.firstName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(NSLocalizedString("player_number", comment: "") + " \(assignedNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
#Preview {
    PlayerEntryView(
        viewModel: PlayerEntryViewModel(
            gameMode: GameMode(
                title: "10 players / S/. 5.00 entry",
                maxPlayers: 10,
                entryPriceSoles: 5.00,
                prizePoolSoles: 40.00,
                profitPct: 0.20
            ),
            randomNumberViewModel: RandomNumberViewModel()
        ),
        settings: SettingsModel()
    )
} 