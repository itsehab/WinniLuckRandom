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
    init(gameMode: GameMode) {
        self.selectedGameMode = gameMode
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
        
        // Show the game view
        showingGameView = true
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
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
        return player.selectedNumber
    }
    
    func getPlayerForNumber(_ number: Int) -> Player? {
        return players.first { $0.selectedNumber == number }
    }
    
    // MARK: - Manual Number Selection
    func assignNumber(_ number: Int, to player: Player) {
        guard let index = players.firstIndex(where: { $0.id == player.id }) else { return }
        
        // Check if number is already taken by another player
        if players.contains(where: { $0.selectedNumber == number && $0.id != player.id }) {
            errorMessage = String(format: NSLocalizedString("number_already_taken", comment: ""), number)
            return
        }
        
        // Check if number is within valid range
        guard number >= 1 && number <= selectedGameMode.maxPlayers else {
            errorMessage = String(format: NSLocalizedString("number_out_of_range", comment: ""), 1, selectedGameMode.maxPlayers)
            return
        }
        
        // Create updated player with selected number
        let updatedPlayer = Player(id: player.id, firstName: player.firstName, selectedNumber: number)
        players[index] = updatedPlayer
        
        clearErrorMessage()
        
        // Save updated player to CloudKit
        Task {
            await savePlayer(updatedPlayer)
        }
    }
    
    func clearNumber(for player: Player) {
        guard let index = players.firstIndex(where: { $0.id == player.id }) else { return }
        
        let updatedPlayer = Player(id: player.id, firstName: player.firstName, selectedNumber: nil)
        players[index] = updatedPlayer
        
        // Save updated player to CloudKit
        Task {
            await savePlayer(updatedPlayer)
        }
    }
    
    func isNumberAvailable(_ number: Int) -> Bool {
        return !players.contains { $0.selectedNumber == number }
    }
    
    func getAvailableNumbers() -> [Int] {
        let allNumbers = Array(1...selectedGameMode.maxPlayers)
        let takenNumbers = Set(players.compactMap { $0.selectedNumber })
        return allNumbers.filter { !takenNumbers.contains($0) }
    }
    
    func hasAllPlayersSelectedNumbers() -> Bool {
        return players.allSatisfy { $0.selectedNumber != nil }
    }
    
    func getPlayersWithoutNumbers() -> [Player] {
        return players.filter { $0.selectedNumber == nil }
    }
    
    // MARK: - Convenience Methods
    func updatePlayerNumber(_ player: Player, to number: Int) {
        assignNumber(number, to: player)
    }
    
    func clearPlayerNumber(_ player: Player) {
        clearNumber(for: player)
    }
    
    func isNumberSelected(_ number: Int) -> Bool {
        return players.contains { $0.selectedNumber == number }
    }
    
    // MARK: - Financial Calculations
    func calculateTotalRevenue() -> Decimal {
        return selectedGameMode.calculateGross(for: players.count)
    }
    
    func calculateExpectedProfit() -> Decimal {
        // Estimate profit with 1 winner as default
        return selectedGameMode.calculateProfit(for: players.count, winners: 1)
    }
    
    func calculatePayout() -> Decimal {
        // Calculate payout for 1 winner as default
        return selectedGameMode.calculatePayout(for: 1)
    }
    
    // MARK: - Analytics Support
    func generateGameSession(winningNumbers: [Int], winnerPlayerIDs: [UUID]) -> GameSession {
        let playerCount = players.count
        let grossIncome = selectedGameMode.calculateGross(for: playerCount)
        let actualWinners = winnerPlayerIDs.count
        let payout = selectedGameMode.calculatePayout(for: actualWinners)
        let profit = selectedGameMode.calculateProfit(for: playerCount, winners: actualWinners)
        
        let session = GameSession(
            id: UUID(),
            modeID: selectedGameMode.id,
            startRange: 1,
            endRange: selectedGameMode.maxPlayers,
            repetitions: selectedGameMode.repetitions,
            numWinners: winnerPlayerIDs.count,
            playerIDs: players.map { $0.id },
            winningNumbers: winningNumbers,
            winnerIDs: winnerPlayerIDs,
            date: Date(),
            grossIncome: grossIncome,
            profit: profit,
            payout: payout
        )
        
        return session
    }
    
    // MARK: - Game Session Creation
    func createGameSession() -> GameSession {
        let playerCount = players.count
        let grossIncome = selectedGameMode.calculateGross(for: playerCount)
        // Start with 1 winner as default, will be updated later
        let estimatedWinners = 1
        let payout = selectedGameMode.calculatePayout(for: estimatedWinners)
        let profit = selectedGameMode.calculateProfit(for: playerCount, winners: estimatedWinners)
        
        let session = GameSession(
            id: UUID(),
            modeID: selectedGameMode.id,
            startRange: 1,
            endRange: selectedGameMode.maxPlayers,
            repetitions: selectedGameMode.repetitions,
            numWinners: 0,
            playerIDs: players.map { $0.id },
            winningNumbers: [],
            winnerIDs: [],
            date: Date(),
            grossIncome: grossIncome,
            profit: profit,
            payout: payout
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
                      selectedGameMode.formattedPrizePerWinner)
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
            title: "Modo Premium",
            maxPlayers: 10,
            entryPriceSoles: Decimal(5.00),
            prizePerWinner: Decimal(30.00),
            maxWinners: 2
        )
        
        let viewModel = PlayerEntryViewModel(gameMode: gameMode)
        
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