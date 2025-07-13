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
    let prizePoolSoles: Decimal
    let profitPct: Double? // Optional - if nil, use (gross - prizePool) calculation
    
    init(title: String, maxPlayers: Int, entryPriceSoles: Decimal, prizePoolSoles: Decimal, profitPct: Double? = nil) {
        self.id = UUID()
        self.title = title
        self.maxPlayers = maxPlayers
        self.entryPriceSoles = entryPriceSoles
        self.prizePoolSoles = prizePoolSoles
        self.profitPct = profitPct
    }
    
    init(id: UUID, title: String, maxPlayers: Int, entryPriceSoles: Decimal, prizePoolSoles: Decimal, profitPct: Double? = nil) {
        self.id = id
        self.title = title
        self.maxPlayers = maxPlayers
        self.entryPriceSoles = entryPriceSoles
        self.prizePoolSoles = prizePoolSoles
        self.profitPct = profitPct
    }
}

// MARK: - Business Logic
extension GameMode {
    
    /// Calculate gross income based on entry price and player count
    func calculateGross(for playerCount: Int) -> Decimal {
        return entryPriceSoles * Decimal(playerCount)
    }
    
    /// Calculate profit based on profit percentage or gross - prize pool
    func calculateProfit(for playerCount: Int) -> Decimal {
        let gross = calculateGross(for: playerCount)
        
        if let profitPct = profitPct {
            return gross * Decimal(profitPct)
        } else {
            return gross - prizePoolSoles
        }
    }
    
    /// Calculate actual payout (always the prize pool)
    func calculatePayout() -> Decimal {
        return prizePoolSoles
    }
    
    /// Auto-generate title based on parameters
    static func generateTitle(maxPlayers: Int, entryPriceSoles: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let priceString = formatter.string(from: entryPriceSoles as NSDecimalNumber) ?? "S/. \(entryPriceSoles)"
        return "\(maxPlayers) players / \(priceString) entry"
    }
    
    /// Check if the game mode configuration is valid
    var isValid: Bool {
        return maxPlayers > 0 && 
               maxPlayers <= 99 && 
               entryPriceSoles > 0 && 
               prizePoolSoles >= 0 && 
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - CloudKit Support
extension GameMode {
    
    /// Convert GameMode to CloudKit CKRecord
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "GameMode")
        record["id"] = id.uuidString
        record["title"] = title
        record["maxPlayers"] = maxPlayers
        record["entryPriceSoles"] = entryPriceSoles as NSDecimalNumber
        record["prizePoolSoles"] = prizePoolSoles as NSDecimalNumber
        record["profitPct"] = profitPct
        return record
    }
    
    /// Initialize GameMode from CloudKit CKRecord
    init?(from record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = record["title"] as? String,
              let maxPlayers = record["maxPlayers"] as? Int,
              let entryPriceNumber = record["entryPriceSoles"] as? NSDecimalNumber,
              let prizePoolNumber = record["prizePoolSoles"] as? NSDecimalNumber else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.maxPlayers = maxPlayers
        self.entryPriceSoles = entryPriceNumber.decimalValue
        self.prizePoolSoles = prizePoolNumber.decimalValue
        self.profitPct = record["profitPct"] as? Double
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
    
    /// Formatted prize pool for display
    var formattedPrizePool: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: prizePoolSoles as NSDecimalNumber) ?? "S/. \(prizePoolSoles)"
    }
    
    /// Formatted profit percentage for display
    var formattedProfitPct: String {
        guard let profitPct = profitPct else { return "N/A" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        
        return formatter.string(from: NSNumber(value: profitPct)) ?? "\(Int(profitPct * 100))%"
    }
} 