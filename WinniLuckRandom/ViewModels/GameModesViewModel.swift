//
//  GameModesViewModel.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI

@MainActor
class GameModesViewModel: ObservableObject {
    static let shared = GameModesViewModel()
    
    @Published var gameModes: [GameMode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddSheet = false
    @Published var showingEditSheet = false
    @Published var editingGameMode: GameMode?
    
    // Form fields
    @Published var formTitle = ""
    @Published var maxPlayers = 10
    @Published var entryFee: Decimal = 0.50
    @Published var maxWinners = 1
    @Published var repetitions = 1 // How many times each number needs to be called to win
    @Published var prizeTiers: [Decimal] = [1.00] // Individual prizes for each winner position
    @Published var useCustomTitle = false
    @Published var order = 0 // Order for home page display
    
    // Caching
    private var lastLoadTime: Date?
    private let cacheExpiration: TimeInterval = 30 // 30 seconds cache
    
    // Computed properties
    var totalPrizePool: Decimal {
        return prizeTiers.reduce(0, +)
    }
    
    var estimatedProfit: Decimal {
        let totalRevenue = entryFee * Decimal(maxPlayers)
        return totalRevenue - totalPrizePool
    }
    
    var profitMargin: Double {
        let totalRevenue = entryFee * Decimal(maxPlayers)
        guard totalRevenue > 0 else { return 0 }
        return Double(truncating: NSDecimalNumber(decimal: estimatedProfit / totalRevenue))
    }
    
    var isFormValid: Bool {
        return !formTitle.isEmpty && 
               maxPlayers > 0 && 
               entryFee > 0 && 
               maxWinners > 0 && 
               maxWinners <= maxPlayers &&
               !prizeTiers.isEmpty &&
               prizeTiers.allSatisfy { $0 >= 0 }
    }
    
    private init() {
        print("📋 GameModesViewModel initialized")
    }
    
    func loadGameModesIfNeeded() async {
        // Check if we have cached data that's still valid
        if let lastLoadTime = lastLoadTime,
           Date().timeIntervalSince(lastLoadTime) < cacheExpiration,
           !gameModes.isEmpty {
            print("📋 Using cached game modes")
            return
        }
        
        await loadGameModes()
    }
    
    func forceRefresh() async {
        await loadGameModes()
    }
    
    // Debug/Testing function to reset all game modes
    func resetAllGameModes() async {
        print("🔄 Resetting all game modes...")
        isLoading = true
        
        // Clear local cache
        gameModes = []
        lastLoadTime = nil
        
        // Delete all game modes from storage
        let currentModes = await StorageManager.shared.fetchGameModes()
        for mode in currentModes {
            await StorageManager.shared.deleteGameMode(mode)
        }
        
        // Force reload which will create new defaults with proper order
        await loadGameModes()
        
        print("✅ Game modes reset complete")
    }
    
    private func loadGameModes() async {
        isLoading = true
        errorMessage = nil
        
        print("📋 Loading game modes...")
        
        do {
            let modes = await StorageManager.shared.fetchGameModes()
            
            await MainActor.run {
                let sortedModes = modes.sorted { $0.order < $1.order }
                
                // Debug logging
                print("📋 Raw game modes loaded:")
                for mode in modes {
                    print("  - \(mode.title): order = \(mode.order)")
                }
                print("📋 Sorted game modes:")
                for mode in sortedModes {
                    print("  - \(mode.title): order = \(mode.order)")
                }
                
                self.gameModes = sortedModes
                self.lastLoadTime = Date()
                self.isLoading = false
            }
            
            print("📋 Loaded \(modes.count) game modes successfully")
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load game modes: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("📋 Failed to load game modes: \(error)")
        }
    }
    
    func saveGameMode() async {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields correctly"
            return
        }
        
        // Auto-assign order if not specified (add to end)
        let finalOrder = order == 0 ? (gameModes.map(\.order).max() ?? 0) + 1 : order
        
        let newGameMode = GameMode(
            title: formTitle,
            maxPlayers: maxPlayers,
            entryPriceSoles: entryFee,
            prizeTiers: prizeTiers,
            maxWinners: maxWinners,
            repetitions: repetitions,
            order: finalOrder
        )
        
        print("🔄 Saving new game mode: \(newGameMode.title)")
        
        let success = await StorageManager.shared.saveGameMode(newGameMode)
        
        if success {
            print("✅ Game mode saved successfully")
            // Invalidate cache and reload
            lastLoadTime = nil
            await loadGameModes()
            resetForm()
        } else {
            print("❌ Failed to save game mode")
            errorMessage = "Failed to save game mode. Please try again."
        }
    }
    
    func startEditingGameMode(_ gameMode: GameMode) {
        editingGameMode = gameMode
        
        // Populate form with existing values
        formTitle = gameMode.title
        maxPlayers = gameMode.maxPlayers
        entryFee = gameMode.entryPriceSoles
        maxWinners = gameMode.maxWinners
        repetitions = gameMode.repetitions
        prizeTiers = gameMode.prizeTiers
        useCustomTitle = true
        order = gameMode.order
        
        showingEditSheet = true
    }
    
    func updateGameMode() async {
        guard let originalGameMode = editingGameMode else { 
            errorMessage = "No game mode selected for editing"
            return 
        }
        
        guard isFormValid else {
            errorMessage = "Please fill in all required fields correctly"
            return
        }
        
        let updatedGameMode = GameMode(
            id: originalGameMode.id, // Keep the same ID
            title: formTitle,
            maxPlayers: maxPlayers,
            entryPriceSoles: entryFee,
            prizeTiers: prizeTiers,
            maxWinners: maxWinners,
            repetitions: repetitions,
            order: order
        )
        
        print("🔄 Updating game mode: \(updatedGameMode.title)")
        
        let success = await StorageManager.shared.updateGameMode(updatedGameMode)
        
        if success {
            print("✅ Game mode updated successfully")
            // Invalidate cache and reload
            lastLoadTime = nil
            await loadGameModes()
            resetForm()
            editingGameMode = nil
        } else {
            print("❌ Failed to update game mode")
            errorMessage = "Failed to update game mode. Please try again."
        }
    }
    
    func deleteGameMode(_ gameMode: GameMode) async {
        print("🔄 Deleting game mode: \(gameMode.title)")
        
        let success = await StorageManager.shared.deleteGameMode(gameMode)
        
        if success {
            print("✅ Game mode deleted successfully")
            // Invalidate cache and reload
            lastLoadTime = nil
            await loadGameModes()
        } else {
            print("❌ Failed to delete game mode")
            errorMessage = "Failed to delete game mode. Please try again."
        }
    }
    
    func resetForm() {
        formTitle = ""
        maxPlayers = 10
        entryFee = 0.50
        maxWinners = 1
        repetitions = 1
        prizeTiers = [1.00]
        useCustomTitle = false
        order = 0
    }
    
    func updatePrizeTiers(for winnerCount: Int) {
        if winnerCount > prizeTiers.count {
            // Add more prize tiers
            let additionalTiers = winnerCount - prizeTiers.count
            for _ in 0..<additionalTiers {
                prizeTiers.append(0.50)
            }
        } else if winnerCount < prizeTiers.count {
            // Remove excess prize tiers
            prizeTiers = Array(prizeTiers.prefix(winnerCount))
        }
    }
    
    func updatePrize(at index: Int, to amount: Decimal) {
        guard index >= 0 && index < prizeTiers.count else { return }
        prizeTiers[index] = amount
    }
    
    func generateTitle() -> String {
        let playersText = maxPlayers == 1 ? "player" : "players"
        let winnersText = maxWinners == 1 ? "winner" : "winners"
        return "\(maxPlayers) \(playersText) / \(formatCurrency(entryFee)) entry / \(maxWinners) \(winnersText)"
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "S/. 0.00"
    }
} 