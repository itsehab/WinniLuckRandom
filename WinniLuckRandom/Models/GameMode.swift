//
//  GameMode.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import CloudKit

struct GameMode: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let maxPlayers: Int
    let entryPriceSoles: Decimal
    let prizeTiers: [Decimal] // Array of prizes for each winner position [1st, 2nd, 3rd, ...]
    let maxWinners: Int // Maximum number of winners allowed
    let repetitions: Int // How many times each number needs to be called to win
    let order: Int // Display order in the home page (lower numbers appear first)
    
    // Computed property for backward compatibility
    var prizePerWinner: Decimal {
        return prizeTiers.first ?? 0
    }
    
    // Computed properties for financial calculations
    var totalPrizePool: Decimal {
        return prizeTiers.reduce(0, +)
    }
    
    var estimatedProfit: Decimal {
        let totalRevenue = entryPriceSoles * Decimal(maxPlayers)
        return totalRevenue - totalPrizePool
    }
    
    init(title: String, maxPlayers: Int, entryPriceSoles: Decimal, prizeTiers: [Decimal], maxWinners: Int = 1, repetitions: Int = 1, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.maxPlayers = maxPlayers
        self.entryPriceSoles = entryPriceSoles
        self.prizeTiers = prizeTiers
        self.maxWinners = maxWinners
        self.repetitions = repetitions
        self.order = order
    }
    
    init(id: UUID, title: String, maxPlayers: Int, entryPriceSoles: Decimal, prizeTiers: [Decimal], maxWinners: Int = 1, repetitions: Int = 1, order: Int = 0) {
        self.id = id
        self.title = title
        self.maxPlayers = maxPlayers
        self.entryPriceSoles = entryPriceSoles
        self.prizeTiers = prizeTiers
        self.maxWinners = maxWinners
        self.repetitions = repetitions
        self.order = order
    }
    
    // Convenience init for backward compatibility
    init(title: String, maxPlayers: Int, entryPriceSoles: Decimal, prizePerWinner: Decimal, maxWinners: Int = 1, repetitions: Int = 1, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.maxPlayers = maxPlayers
        self.entryPriceSoles = entryPriceSoles
        self.prizeTiers = Array(repeating: prizePerWinner, count: maxWinners)
        self.maxWinners = maxWinners
        self.repetitions = repetitions
        self.order = order
    }
    
    // Convenience init with ID for backward compatibility
    init(id: UUID, title: String, maxPlayers: Int, entryPriceSoles: Decimal, prizePerWinner: Decimal, maxWinners: Int = 1, repetitions: Int = 1, order: Int = 0) {
        self.id = id
        self.title = title
        self.maxPlayers = maxPlayers
        self.entryPriceSoles = entryPriceSoles
        self.prizeTiers = Array(repeating: prizePerWinner, count: maxWinners)
        self.maxWinners = maxWinners
        self.repetitions = repetitions
        self.order = order
    }
}

// MARK: - Business Logic
extension GameMode {
    
    /// Calculate gross income based on entry price and player count
    func calculateGross(for playerCount: Int) -> Decimal {
        return entryPriceSoles * Decimal(playerCount)
    }
    
    /// Calculate total prize pool based on number of winners
    func calculateTotalPrizePool(for numberOfWinners: Int) -> Decimal {
        var total: Decimal = 0
        for i in 0..<min(numberOfWinners, prizeTiers.count) {
            total += prizeTiers[i]
        }
        return total
    }
    
    /// Calculate profit as the remaining money after paying winners
    func calculateProfit(for playerCount: Int, winners: Int) -> Decimal {
        let gross = calculateGross(for: playerCount)
        let totalPrizePool = calculateTotalPrizePool(for: winners)
        return gross - totalPrizePool
    }
    
    /// Calculate actual payout based on number of winners
    func calculatePayout(for numberOfWinners: Int) -> Decimal {
        return calculateTotalPrizePool(for: numberOfWinners)
    }
    
    /// Get prize for specific winner position (1-indexed)
    func getPrize(for position: Int) -> Decimal {
        guard position > 0 && position <= prizeTiers.count else { return 0 }
        return prizeTiers[position - 1]
    }
    
    /// Auto-generate title based on parameters
    static func generateTitle(maxPlayers: Int, entryPriceSoles: Decimal, prizeTiers: [Decimal], maxWinners: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let priceString = formatter.string(from: entryPriceSoles as NSDecimalNumber) ?? "S/. \(entryPriceSoles)"
        
        if maxWinners == 1 {
            let prizeString = formatter.string(from: prizeTiers.first as NSDecimalNumber? ?? 0) ?? "S/. 0"
            return "\(maxPlayers) players / \(priceString) entry / \(prizeString) prize"
        } else {
            let totalPrizes = prizeTiers.reduce(0, +)
            let totalPrizeString = formatter.string(from: totalPrizes as NSDecimalNumber) ?? "S/. 0"
            return "\(maxPlayers) players / \(priceString) entry / \(totalPrizeString) total prizes"
        }
    }
    
    /// Check if the game mode configuration is valid
    var isValid: Bool {
        return maxPlayers > 0 && 
               maxPlayers <= 999 && // Increased limit from 99 to 999
               entryPriceSoles > 0 && 
               !prizeTiers.isEmpty &&
               prizeTiers.allSatisfy { $0 >= 0 } &&
               maxWinners > 0 &&
               maxWinners <= maxPlayers && // Can't have more winners than players
               prizeTiers.count >= maxWinners && // Must have prizes for all winners
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - CloudKit Support
extension GameMode {
    

    
    /// Initialize GameMode from CloudKit CKRecord
    init?(from record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = record["title"] as? String,
              let maxPlayers = record["maxPlayers"] as? Int,
              let entryPriceNumber = record["entryPriceSoles"] as? NSDecimalNumber else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.maxPlayers = maxPlayers
        self.entryPriceSoles = entryPriceNumber.decimalValue
        self.maxWinners = record["maxWinners"] as? Int ?? 1
        self.repetitions = record["repetitions"] as? Int ?? 1
        self.order = record["order"] as? Int ?? 0
        
        // Handle prize tiers - check new format first, then fall back to old format
        if let prizeNumbers = record["prizeTiers"] as? [NSDecimalNumber] {
            self.prizeTiers = prizeNumbers.map { $0.decimalValue }
        } else if let prizePerWinnerNumber = record["prizePerWinner"] as? NSDecimalNumber {
            // Backward compatibility with old format
            self.prizeTiers = Array(repeating: prizePerWinnerNumber.decimalValue, count: maxWinners)
        } else {
            self.prizeTiers = [0]
        }
    }
    
    /// Convert GameMode to CloudKit CKRecord for saving
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "GameMode", recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["id"] = id.uuidString
        record["title"] = title
        record["maxPlayers"] = maxPlayers
        record["entryPriceSoles"] = NSDecimalNumber(decimal: entryPriceSoles)
        record["maxWinners"] = maxWinners
        record["repetitions"] = repetitions
        record["order"] = order
        record["prizeTiers"] = prizeTiers.map { NSDecimalNumber(decimal: $0) }
        
        return record
    }
}

// MARK: - Display Helpers
extension GameMode {
    
    /// Formatted entry price for display
    var formattedEntryPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: entryPriceSoles as NSDecimalNumber) ?? "S/. \(entryPriceSoles)"
    }
    
    /// Formatted prize for specific position
    func formattedPrize(for position: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let prize = getPrize(for: position)
        return formatter.string(from: prize as NSDecimalNumber) ?? "S/. \(prize)"
    }
    
    /// Formatted prize per winner for display (backward compatibility)
    var formattedPrizePerWinner: String {
        return formattedPrize(for: 1)
    }
    
    /// Formatted total prize pool for display
    var formattedTotalPrizePool: String {
        let totalPrizes = prizeTiers.reduce(0, +)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: totalPrizes as NSDecimalNumber) ?? "S/. \(totalPrizes)"
    }
    
    /// Formatted max winners for display
    var formattedMaxWinners: String {
        if maxWinners == 1 {
            return "1 winner"
        } else {
            return "Up to \(maxWinners) winners"
        }
    }
    
    /// Formatted total prize pool for display given number of winners
    func formattedTotalPrizePool(for numberOfWinners: Int) -> String {
        let totalPrizePool = calculateTotalPrizePool(for: numberOfWinners)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: totalPrizePool as NSDecimalNumber) ?? "S/. \(totalPrizePool)"
    }
    
    /// Formatted profit for display
    func formattedProfit(for playerCount: Int, winners: Int) -> String {
        let profit = calculateProfit(for: playerCount, winners: winners)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: profit as NSDecimalNumber) ?? "S/. \(profit)"
    }
} 