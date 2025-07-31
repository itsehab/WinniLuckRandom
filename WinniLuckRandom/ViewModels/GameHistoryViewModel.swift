import Foundation
import Combine

@MainActor
class GameHistoryViewModel: ObservableObject {
    @Published var gameSessions: [GameSession] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // Filter and sort controls
    @Published var searchText = ""
    @Published var selectedGameMode: GameMode?
    @Published var dateRange: DateInterval?
    @Published var sortOrder: SortOrder = .dateDescending
    
    enum SortOrder: String, CaseIterable {
        case dateAscending = "Date (Oldest)"
        case dateDescending = "Date (Newest)"
        case profitAscending = "Profit (Low to High)"
        case profitDescending = "Profit (High to Low)"
        case revenueAscending = "Revenue (Low to High)"
        case revenueDescending = "Revenue (High to Low)"
        
        var displayName: String {
            switch self {
            case .dateAscending:
                return NSLocalizedString("date_oldest", comment: "Date (Oldest)")
            case .dateDescending:
                return NSLocalizedString("date_newest", comment: "Date (Newest)")
            case .profitAscending:
                return NSLocalizedString("profit_low_to_high", comment: "Profit (Low to High)")
            case .profitDescending:
                return NSLocalizedString("profit_high_to_low", comment: "Profit (High to Low)")
            case .revenueAscending:
                return NSLocalizedString("revenue_low_to_high", comment: "Revenue (Low to High)")
            case .revenueDescending:
                return NSLocalizedString("revenue_high_to_low", comment: "Revenue (High to Low)")
            }
        }
    }
    
    private let storageManager: StorageManager
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor init(storageManager: StorageManager? = nil) {
        self.storageManager = storageManager ?? StorageManager.shared
        setupFilteredSessions()
        // Don't load immediately in init, let the view trigger it
    }
    
    private func setupFilteredSessions() {
        // Combine publishers for real-time filtering
        Publishers.CombineLatest4(
            $searchText.debounce(for: .milliseconds(300), scheduler: RunLoop.main),
            $selectedGameMode,
            $dateRange,
            $sortOrder
        )
        .combineLatest($gameSessions)
        .map { filters, sessions in
            let (searchText, gameMode, dateRange, sortOrder) = filters
            var filtered = sessions
            
            // Filter by search text (if needed, can search by game mode name)
            if !searchText.isEmpty {
                filtered = filtered.filter { session in
                    // For now, just basic filtering - could enhance with game mode name lookup
                    return true
                }
            }
            
            // Filter by game mode
            if let gameMode = gameMode {
                filtered = filtered.filter { $0.modeID == gameMode.id }
            }
            
            // Filter by date range
            if let dateRange = dateRange {
                filtered = filtered.filter { session in
                    dateRange.contains(session.date)
                }
            }
            
            // Sort sessions
            return filtered.sorted { lhs, rhs in
                switch sortOrder {
                case .dateAscending:
                    return lhs.date < rhs.date
                case .dateDescending:
                    return lhs.date > rhs.date
                case .profitAscending:
                    return lhs.profit < rhs.profit
                case .profitDescending:
                    return lhs.profit > rhs.profit
                case .revenueAscending:
                    return lhs.grossIncome < rhs.grossIncome
                case .revenueDescending:
                    return lhs.grossIncome > rhs.grossIncome
                }
            }
        }
        .assign(to: &$filteredSessions)
    }
    
    @Published var filteredSessions: [GameSession] = []
    
    func loadGameSessions() {
        isLoading = true
        error = nil
        
        print("🔍 GameHistoryViewModel: Starting to load game sessions...")
        
        Task {
            let sessions = await storageManager.fetchGameSessions()
            print("🔍 GameHistoryViewModel: Fetched \(sessions.count) sessions from storage")
            
            await MainActor.run {
                self.gameSessions = sessions
                self.isLoading = false
                print("🔍 GameHistoryViewModel: Updated UI with \(sessions.count) sessions")
            }
        }
    }
    
    func generateTestData() {
        print("🧪 GameHistoryViewModel: Generating test data...")
        
        let testSessions = [
            GameSession(
                id: UUID(),
                modeID: UUID(),
                startRange: 1,
                endRange: 10,
                repetitions: 3,
                numWinners: 1,
                playerIDs: [UUID(), UUID(), UUID()],
                winningNumbers: [5],
                winnerIDs: [UUID()],
                date: Date().addingTimeInterval(-86400), // 1 day ago
                grossIncome: Decimal(30.0),
                profit: Decimal(20.0),
                payout: Decimal(10.0)
            ),
            GameSession(
                id: UUID(),
                modeID: UUID(),
                startRange: 1,
                endRange: 20,
                repetitions: 5,
                numWinners: 2,
                playerIDs: [UUID(), UUID(), UUID(), UUID(), UUID()],
                winningNumbers: [3, 15],
                winnerIDs: [UUID(), UUID()],
                date: Date().addingTimeInterval(-172800), // 2 days ago
                grossIncome: Decimal(100.0),
                profit: Decimal(60.0),
                payout: Decimal(40.0)
            ),
            GameSession(
                id: UUID(),
                modeID: UUID(),
                startRange: 1,
                endRange: 5,
                repetitions: 2,
                numWinners: 1,
                playerIDs: [UUID(), UUID()],
                winningNumbers: [2],
                winnerIDs: [UUID()],
                date: Date().addingTimeInterval(-259200), // 3 days ago
                grossIncome: Decimal(10.0),
                profit: Decimal(5.0),
                payout: Decimal(5.0)
            )
        ]
        
        self.gameSessions = testSessions
        self.isLoading = false
        print("🧪 GameHistoryViewModel: Generated \(testSessions.count) test sessions")
    }
    
    func deleteGameSession(_ session: GameSession) {
        isLoading = true
        error = nil
        
        Task {
            let success = await storageManager.deleteGameSession(session)
            
                await MainActor.run {
                if success {
                    self.gameSessions.removeAll { $0.id == session.id }
                    print("✅ Game session deleted successfully")
                } else {
                    self.error = NSError(domain: "DeleteError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to delete game session"])
                    print("❌ Failed to delete game session")
                }
                    self.isLoading = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var totalRevenue: Decimal {
        filteredSessions.reduce(0) { $0 + $1.grossIncome }
    }
    
    var totalProfit: Decimal {
        filteredSessions.reduce(0) { $0 + $1.profit }
    }
    
    var totalGamesCount: Int {
        filteredSessions.count
    }
    
    var averageProfit: Decimal {
        guard totalGamesCount > 0 else { return 0 }
        return totalProfit / Decimal(totalGamesCount)
    }
    
    var profitMargin: Double {
        guard totalRevenue > 0 else { return 0 }
        return NSDecimalNumber(decimal: totalProfit).doubleValue / NSDecimalNumber(decimal: totalRevenue).doubleValue
    }
    
    // MARK: - Helper Methods
    
    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "S/. 0.00"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func clearFilters() {
        searchText = ""
        selectedGameMode = nil
        dateRange = nil
        sortOrder = .dateDescending
    }
}

// MARK: - Preview Support
extension GameHistoryViewModel {
    static func preview() -> GameHistoryViewModel {
        let viewModel = GameHistoryViewModel()
        
        // Mock data for preview
        viewModel.gameSessions = [
            GameSession(
                modeID: UUID(),
                startRange: 1,
                endRange: 100,
                repetitions: 1,
                numWinners: 1,
                playerIDs: [UUID(), UUID(), UUID()],
                winningNumbers: [42],
                winnerIDs: [UUID()],
                grossIncome: Decimal(150),
                profit: Decimal(50),
                payout: Decimal(100)
            ),
            GameSession(
                modeID: UUID(),
                startRange: 1,
                endRange: 100,
                repetitions: 1,
                numWinners: 1,
                playerIDs: [UUID(), UUID(), UUID(), UUID()],
                winningNumbers: [23],
                winnerIDs: [UUID()],
                grossIncome: Decimal(200),
                profit: Decimal(75),
                payout: Decimal(125)
            )
        ]
        
        return viewModel
    }
} 