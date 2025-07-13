//
//  GameSession.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import CloudKit

struct GameSession: Identifiable, Codable, Hashable {
    let id: UUID
    let modeID: UUID
    let startRange: Int
    let endRange: Int
    let repetitions: Int
    let numWinners: Int
    let playerIDs: [UUID]
    let winningNumbers: [Int]
    let winnerIDs: [UUID]
    let date: Date
    
    // Additional fields for analytics
    let grossIncome: Decimal
    let profit: Decimal
    let payout: Decimal
    
    init(modeID: UUID, startRange: Int, endRange: Int, repetitions: Int, numWinners: Int, playerIDs: [UUID], winningNumbers: [Int], winnerIDs: [UUID], grossIncome: Decimal, profit: Decimal, payout: Decimal) {
        self.id = UUID()
        self.modeID = modeID
        self.startRange = startRange
        self.endRange = endRange
        self.repetitions = repetitions
        self.numWinners = numWinners
        self.playerIDs = playerIDs
        self.winningNumbers = winningNumbers
        self.winnerIDs = winnerIDs
        self.date = Date()
        self.grossIncome = grossIncome
        self.profit = profit
        self.payout = payout
    }
    
    init(id: UUID, modeID: UUID, startRange: Int, endRange: Int, repetitions: Int, numWinners: Int, playerIDs: [UUID], winningNumbers: [Int], winnerIDs: [UUID], date: Date, grossIncome: Decimal, profit: Decimal, payout: Decimal) {
        self.id = id
        self.modeID = modeID
        self.startRange = startRange
        self.endRange = endRange
        self.repetitions = repetitions
        self.numWinners = numWinners
        self.playerIDs = playerIDs
        self.winningNumbers = winningNumbers
        self.winnerIDs = winnerIDs
        self.date = date
        self.grossIncome = grossIncome
        self.profit = profit
        self.payout = payout
    }
}

// MARK: - Business Logic
extension GameSession {
    
    /// Get the total number of players who participated
    var totalPlayers: Int {
        return playerIDs.count
    }
    
    /// Get the range size for this session
    var rangeSize: Int {
        return endRange - startRange + 1
    }
    
    /// Get the total numbers generated in this session
    var totalNumbersGenerated: Int {
        return rangeSize * repetitions
    }
    
    /// Check if this session is valid
    var isValid: Bool {
        return startRange <= endRange &&
               repetitions > 0 &&
               numWinners > 0 &&
               numWinners <= winningNumbers.count &&
               winnerIDs.count <= numWinners &&
               grossIncome >= 0 &&
               profit >= 0 &&
               payout >= 0
    }
    
    /// Get formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
    
    /// Get short formatted date for display
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

// MARK: - CloudKit Support
extension GameSession {
    
    /// Convert GameSession to CloudKit CKRecord
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "GameSession")
        record["id"] = id.uuidString
        record["modeID"] = modeID.uuidString
        record["startRange"] = startRange
        record["endRange"] = endRange
        record["repetitions"] = repetitions
        record["numWinners"] = numWinners
        record["playerIDs"] = playerIDs.map { $0.uuidString }
        record["winningNumbers"] = winningNumbers
        record["winnerIDs"] = winnerIDs.map { $0.uuidString }
        record["date"] = date
        record["grossIncome"] = grossIncome as NSDecimalNumber
        record["profit"] = profit as NSDecimalNumber
        record["payout"] = payout as NSDecimalNumber
        return record
    }
    
    /// Initialize GameSession from CloudKit CKRecord
    init?(from record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let modeIDString = record["modeID"] as? String,
              let modeID = UUID(uuidString: modeIDString),
              let startRange = record["startRange"] as? Int,
              let endRange = record["endRange"] as? Int,
              let repetitions = record["repetitions"] as? Int,
              let numWinners = record["numWinners"] as? Int,
              let playerIDStrings = record["playerIDs"] as? [String],
              let winningNumbers = record["winningNumbers"] as? [Int],
              let winnerIDStrings = record["winnerIDs"] as? [String],
              let date = record["date"] as? Date,
              let grossIncomeNumber = record["grossIncome"] as? NSDecimalNumber,
              let profitNumber = record["profit"] as? NSDecimalNumber,
              let payoutNumber = record["payout"] as? NSDecimalNumber else {
            return nil
        }
        
        // Convert string arrays back to UUID arrays
        let playerIDs = playerIDStrings.compactMap { UUID(uuidString: $0) }
        let winnerIDs = winnerIDStrings.compactMap { UUID(uuidString: $0) }
        
        // Ensure we didn't lose any UUIDs in conversion
        guard playerIDs.count == playerIDStrings.count,
              winnerIDs.count == winnerIDStrings.count else {
            return nil
        }
        
        self.id = id
        self.modeID = modeID
        self.startRange = startRange
        self.endRange = endRange
        self.repetitions = repetitions
        self.numWinners = numWinners
        self.playerIDs = playerIDs
        self.winningNumbers = winningNumbers
        self.winnerIDs = winnerIDs
        self.date = date
        self.grossIncome = grossIncomeNumber.decimalValue
        self.profit = profitNumber.decimalValue
        self.payout = payoutNumber.decimalValue
    }
}

// MARK: - Display Helpers
extension GameSession {
    
    /// Formatted gross income for display
    var formattedGrossIncome: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: grossIncome as NSDecimalNumber) ?? "S/. \(grossIncome)"
    }
    
    /// Formatted profit for display
    var formattedProfit: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: profit as NSDecimalNumber) ?? "S/. \(profit)"
    }
    
    /// Formatted payout for display
    var formattedPayout: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: payout as NSDecimalNumber) ?? "S/. \(payout)"
    }
    
    /// Summary description for display
    var summaryDescription: String {
        return "R(\(startRange)-\(endRange)) × \(repetitions) | \(totalPlayers) players | \(winningNumbers.count) winners"
    }
} 