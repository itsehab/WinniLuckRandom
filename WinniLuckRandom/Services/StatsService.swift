//
//  StatsService.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI

// MARK: - Time Filter Types
enum TimeFilter: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case custom = "Custom"
    
    var localizedTitle: String {
        switch self {
        case .day:
            return NSLocalizedString("day", comment: "")
        case .week:
            return NSLocalizedString("week", comment: "")
        case .month:
            return NSLocalizedString("month", comment: "")
        case .year:
            return NSLocalizedString("year", comment: "")
        case .custom:
            return NSLocalizedString("custom", comment: "")
        }
    }
}

// MARK: - Statistics Summary
struct StatsSummary {
    let totalGames: Int
    let totalProfit: Decimal
    let totalPayout: Decimal
    let totalGrossIncome: Decimal
    let uniquePlayers: Int
    let repeatRate: Double
    let averageProfit: Decimal
    let averagePlayersPerGame: Double
    let mostPopularGameMode: String?
    let timeFilter: TimeFilter
    let startDate: Date?
    let endDate: Date?
    
    // MARK: - Computed Properties
    var profitMargin: Double {
        guard totalGrossIncome > 0 else { return 0 }
        return Double(totalProfit / totalGrossIncome)
    }
    
    var averageGameValue: Decimal {
        guard totalGames > 0 else { return 0 }
        return totalGrossIncome / Decimal(totalGames)
    }
}

// MARK: - Stats Service
@MainActor
class StatsService: ObservableObject {
    static let shared = StatsService()
    
    @Published var currentStats: StatsSummary?
    @Published var isLoading = false
    
    private let cloudKitService = CloudKitService.shared
    private let calendar = Calendar.current
    
    init() {}
    
    // MARK: - Main Statistics Calculation
    func calculateStats(
        for filter: TimeFilter,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async -> StatsSummary {
        
        await MainActor.run {
            isLoading = true
        }
        
        let sessions = getFilteredSessions(for: filter, startDate: startDate, endDate: endDate)
        
        let stats = StatsSummary(
            totalGames: sessions.count,
            totalProfit: sessions.reduce(0) { $0 + $1.profit },
            totalPayout: sessions.reduce(0) { $0 + $1.payout },
            totalGrossIncome: sessions.reduce(0) { $0 + $1.grossIncome },
            uniquePlayers: calculateUniquePlayers(from: sessions),
            repeatRate: calculateRepeatRate(from: sessions),
            averageProfit: calculateAverageProfit(from: sessions),
            averagePlayersPerGame: calculateAveragePlayersPerGame(from: sessions),
            mostPopularGameMode: findMostPopularGameMode(from: sessions),
            timeFilter: filter,
            startDate: getFilterStartDate(for: filter, customStart: startDate),
            endDate: getFilterEndDate(for: filter, customEnd: endDate)
        )
        
        await MainActor.run {
            currentStats = stats
            isLoading = false
        }
        
        return stats
    }
    
    // MARK: - Session Filtering
    private func getFilteredSessions(
        for filter: TimeFilter,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [GameSession] {
        
        let sessions = cloudKitService.gameSessions
        
        switch filter {
        case .day:
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            return sessions.filter { $0.date >= today && $0.date < tomorrow }
            
        case .week:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            return sessions.filter { $0.date >= weekStart && $0.date < weekEnd }
            
        case .month:
            let monthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            return sessions.filter { $0.date >= monthStart && $0.date < monthEnd }
            
        case .year:
            let yearStart = calendar.dateInterval(of: .year, for: Date())?.start ?? Date()
            let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)!
            return sessions.filter { $0.date >= yearStart && $0.date < yearEnd }
            
        case .custom:
            guard let start = startDate, let end = endDate else { return sessions }
            return sessions.filter { $0.date >= start && $0.date <= end }
        }
    }
    
    // MARK: - Statistics Calculations
    private func calculateUniquePlayers(from sessions: [GameSession]) -> Int {
        let allPlayerIDs = Set(sessions.flatMap { $0.playerIDs })
        return allPlayerIDs.count
    }
    
    private func calculateRepeatRate(from sessions: [GameSession]) -> Double {
        let allPlayerIDs = sessions.flatMap { $0.playerIDs }
        let uniquePlayerIDs = Set(allPlayerIDs)
        
        guard uniquePlayerIDs.count > 0 else { return 0 }
        
        let totalParticipations = allPlayerIDs.count
        let repeatPlayers = totalParticipations - uniquePlayerIDs.count
        
        return Double(repeatPlayers) / Double(totalParticipations)
    }
    
    private func calculateAverageProfit(from sessions: [GameSession]) -> Decimal {
        guard sessions.count > 0 else { return 0 }
        let totalProfit = sessions.reduce(0) { $0 + $1.profit }
        return totalProfit / Decimal(sessions.count)
    }
    
    private func calculateAveragePlayersPerGame(from sessions: [GameSession]) -> Double {
        guard sessions.count > 0 else { return 0 }
        let totalPlayers = sessions.reduce(0) { $0 + $1.totalPlayers }
        return Double(totalPlayers) / Double(sessions.count)
    }
    
    private func findMostPopularGameMode(from sessions: [GameSession]) -> String? {
        let modeFrequency = Dictionary(grouping: sessions, by: { $0.modeID })
            .mapValues { $0.count }
        
        guard let mostFrequentModeID = modeFrequency.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        return cloudKitService.getGameMode(by: mostFrequentModeID)?.title
    }
    
    // MARK: - Date Helpers
    private func getFilterStartDate(for filter: TimeFilter, customStart: Date?) -> Date? {
        switch filter {
        case .day:
            return calendar.startOfDay(for: Date())
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: Date())?.start
        case .month:
            return calendar.dateInterval(of: .month, for: Date())?.start
        case .year:
            return calendar.dateInterval(of: .year, for: Date())?.start
        case .custom:
            return customStart
        }
    }
    
    private func getFilterEndDate(for filter: TimeFilter, customEnd: Date?) -> Date? {
        switch filter {
        case .day:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))
        case .week:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            return calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)
        case .month:
            let monthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            return calendar.date(byAdding: .month, value: 1, to: monthStart)
        case .year:
            let yearStart = calendar.dateInterval(of: .year, for: Date())?.start ?? Date()
            return calendar.date(byAdding: .year, value: 1, to: yearStart)
        case .custom:
            return customEnd
        }
    }
    
    // MARK: - Additional Analytics
    func getTopWinners(limit: Int = 5) -> [(Player, Int)] {
        let allWinnerIDs = cloudKitService.gameSessions.flatMap { $0.winnerIDs }
        let winnerFrequency = Dictionary(grouping: allWinnerIDs, by: { $0 })
            .mapValues { $0.count }
        
        let topWinners = winnerFrequency
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .compactMap { (id, count) in
                guard let player = cloudKitService.getPlayer(by: id) else { return nil }
                return (player, count)
            }
        
        return Array(topWinners)
    }
    
    func getRevenueByGameMode() -> [(GameMode, Decimal)] {
        let sessionsByMode = Dictionary(grouping: cloudKitService.gameSessions, by: { $0.modeID })
        
        return sessionsByMode
            .compactMap { (modeID, sessions) in
                guard let mode = cloudKitService.getGameMode(by: modeID) else { return nil }
                let revenue = sessions.reduce(0) { $0 + $1.grossIncome }
                return (mode, revenue)
            }
            .sorted { $0.1 > $1.1 }
    }
    
    func getGameFrequencyByDayOfWeek() -> [String: Int] {
        let sessions = cloudKitService.gameSessions
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "es_ES")
        
        let dayFrequency = Dictionary(grouping: sessions, by: { formatter.string(from: $0.date) })
            .mapValues { $0.count }
        
        return dayFrequency
    }
    
    func getMonthlyTrend() -> [(String, Decimal)] {
        let sessions = cloudKitService.gameSessions
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        
        let monthlyRevenue = Dictionary(grouping: sessions, by: { formatter.string(from: $0.date) })
            .mapValues { sessions in
                sessions.reduce(0) { $0 + $1.grossIncome }
            }
        
        return monthlyRevenue
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }
}

// MARK: - Display Helpers
extension StatsSummary {
    
    func formattedProfit() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: totalProfit as NSDecimalNumber) ?? "S/. \(totalProfit)"
    }
    
    func formattedPayout() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: totalPayout as NSDecimalNumber) ?? "S/. \(totalPayout)"
    }
    
    func formattedGrossIncome() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: totalGrossIncome as NSDecimalNumber) ?? "S/. \(totalGrossIncome)"
    }
    
    func formattedRepeatRate() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        
        return formatter.string(from: NSNumber(value: repeatRate)) ?? "\(Int(repeatRate * 100))%"
    }
    
    func formattedProfitMargin() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        
        return formatter.string(from: NSNumber(value: profitMargin)) ?? "\(Int(profitMargin * 100))%"
    }
    
    func formattedAverageProfit() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: averageProfit as NSDecimalNumber) ?? "S/. \(averageProfit)"
    }
} 