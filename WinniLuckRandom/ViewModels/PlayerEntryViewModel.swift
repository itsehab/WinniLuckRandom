//
//  PlayerEntryViewModel.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI

@MainActor
class PlayerEntryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var players: [Player] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingGameView = false
    
    // MARK: - Private Properties
    private let cloudKitService = CloudKitService.shared
    private let randomNumberViewModel: RandomNumberViewModel
    
    // MARK: - Public Properties
    let selectedGameMode: GameMode
    
    // MARK: - Computed Properties
    var isAtMaxCapacity: Bool {
        return players.count >= selectedGameMode.maxPlayers
    }
    
    var canStartGame: Bool {
        return players.count >= 2 // Minimum 2 players required
    }
    
    var remainingSlots: Int {
        return selectedGameMode.maxPlayers - players.count
    }
    
    // MARK: - Initialization
    init(gameMode: GameMode, randomNumberViewModel: RandomNumberViewModel) {
        self.selectedGameMode = gameMode
        self.randomNumberViewModel = randomNumberViewModel
        
        // Configure the random number view model for this game mode
        setupRandomNumberViewModel()
    }
    
    // MARK: - Player Management
    func addPlayer(_ player: Player) {
        guard !isAtMaxCapacity else {
            errorMessage = NSLocalizedString("max_players_reached", comment: "")
            return
        }
        
        guard player.isValid else {
            errorMessage = NSLocalizedString("invalid_player_name", comment: "")
            return
        }
        
        players.append(player)
        
        // Save player to CloudKit
        Task {
            await savePlayer(player)
        }
        
        clearErrorMessage()
    }
    
    func removePlayer(_ player: Player) {
        players.removeAll { $0.id == player.id }
        
        // Note: We don't delete from CloudKit as players should be persistent
        // for analytics and history purposes
        
        clearErrorMessage()
    }
    
    func clearAllPlayers() {
        players.removeAll()
        clearErrorMessage()
    }
    
    // MARK: - Game Management
    func startGame() {
        guard canStartGame else {
            errorMessage = NSLocalizedString("minimum_players_required", comment: "")
            return
        }
        
        isLoading = true
        
        // Configure the game session
        configureGameSession()
        
        // Start the number generation
        randomNumberViewModel.generateRandomNumbers()
        
        // Show the game view
        showingGameView = true
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func setupRandomNumberViewModel() {
        // The game mode might have specific number ranges, but we'll use the default
        // range from the existing settings. In a future version, we could extend
        // GameMode to include custom number ranges.
        
        // For now, use the existing start/end numbers from RandomNumberViewModel
        // but ensure the winners count doesn't exceed the number of players
        let maxWinners = min(Int(randomNumberViewModel.winnersCount) ?? 3, players.count)
        randomNumberViewModel.winnersCount = String(maxWinners)
    }
    
    private func configureGameSession() {
        // This method prepares the game session data that will be saved
        // after the game completes in the existing ResultView
        
        // The actual GameSession will be created in the ResultView/CongratsView
        // when the game completes, using the financial data from the GameMode
        
        // For now, we'll store the player data in the RandomNumberViewModel
        // so it can be accessed during the game
        
        // We'll extend the RandomNumberViewModel to include player data
        // This is a bridge between the new player system and existing game flow
    }
    
    private func savePlayer(_ player: Player) async {
        let success = await cloudKitService.savePlayer(player)
        
        if !success {
            await MainActor.run {
                errorMessage = NSLocalizedString("failed_to_save_player", comment: "")
            }
        }
    }
    
    private func clearErrorMessage() {
        errorMessage = nil
    }
    
    // MARK: - Validation
    func validatePlayerName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.count <= 30
    }
    
    func isNameTaken(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return players.contains { $0.firstName.lowercased() == trimmedName }
    }
    
    // MARK: - Player Assignment
    func getAssignedNumber(for player: Player) -> Int? {
        guard let index = players.firstIndex(where: { $0.id == player.id }) else {
            return nil
        }
        return index + 1
    }
    
    func getPlayerForNumber(_ number: Int) -> Player? {
        guard number > 0 && number <= players.count else {
            return nil
        }
        return players[number - 1]
    }
    
    // MARK: - Financial Calculations
    func calculateTotalRevenue() -> Decimal {
        return selectedGameMode.calculateGross(for: players.count)
    }
    
    func calculateExpectedProfit() -> Decimal {
        return selectedGameMode.calculateProfit(for: players.count)
    }
    
    func calculatePayout() -> Decimal {
        return selectedGameMode.calculatePayout()
    }
    
    // MARK: - Analytics Support
    func generateGameSession(winningNumbers: [Int], winnerPlayerIDs: [UUID]) -> GameSession {
        let session = GameSession(
            modeID: selectedGameMode.id,
            startRange: Int(randomNumberViewModel.startNumber) ?? 1,
            endRange: Int(randomNumberViewModel.endNumber) ?? 100,
            repetitions: Int(randomNumberViewModel.repetitions) ?? 1,
            numWinners: winningNumbers.count,
            playerIDs: players.map { $0.id },
            winningNumbers: winningNumbers,
            winnerIDs: winnerPlayerIDs,
            grossIncome: calculateTotalRevenue(),
            profit: calculateExpectedProfit(),
            payout: calculatePayout()
        )
        
        return session
    }
    
    // MARK: - Game Flow Integration
    func getWinnerPlayers(for winningNumbers: [Int]) -> [Player] {
        return winningNumbers.compactMap { number in
            getPlayerForNumber(number)
        }
    }
    
    func getWinnerPlayerIDs(for winningNumbers: [Int]) -> [UUID] {
        return getWinnerPlayers(for: winningNumbers).map { $0.id }
    }
    
    // MARK: - Utility Methods
    func reset() {
        players.removeAll()
        showingGameView = false
        isLoading = false
        errorMessage = nil
    }
    
    func getPlayersSummary() -> String {
        let playerNames = players.map { $0.firstName }.joined(separator: ", ")
        return String(format: NSLocalizedString("players_summary", comment: ""), players.count, playerNames)
    }
    
    func getGameModeSummary() -> String {
        return String(format: NSLocalizedString("game_mode_summary", comment: ""), 
                      selectedGameMode.title, 
                      selectedGameMode.formattedEntryPrice,
                      selectedGameMode.formattedPrizePool)
    }
}

// MARK: - Error Handling
extension PlayerEntryViewModel {
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Preview Support
#if DEBUG
extension PlayerEntryViewModel {
    static func preview() -> PlayerEntryViewModel {
        let gameMode = GameMode(
            title: "10 players / S/. 5.00 entry",
            maxPlayers: 10,
            entryPriceSoles: 5.00,
            prizePoolSoles: 40.00,
            profitPct: 0.20
        )
        
        let randomNumberViewModel = RandomNumberViewModel()
        let viewModel = PlayerEntryViewModel(gameMode: gameMode, randomNumberViewModel: randomNumberViewModel)
        
        // Add some sample players
        let samplePlayers = [
            Player(firstName: "Juan"),
            Player(firstName: "María"),
            Player(firstName: "Carlos"),
            Player(firstName: "Ana")
        ]
        
        viewModel.players = samplePlayers
        
        return viewModel
    }
}
#endif 