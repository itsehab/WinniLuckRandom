import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var stats: StatsSummary?
    @Published var selectedTimeFilter: TimeFilter = .day
    @Published var customDateRange: DateRange?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var recentGameSessions: [GameSession] = []
    @Published var filteredGameSessions: [GameSession] = []
    @Published var gameModes: [GameMode] = []
    
    private let statsService: StatsService
    private let storageManager: StorageManager
    private var cancellables = Set<AnyCancellable>()
    
    struct DateRange {
        let startDate: Date
        let endDate: Date
    }
    
    nonisolated init(statsService: StatsService? = nil, storageManager: StorageManager? = nil) {
        self.statsService = statsService ?? StatsService.shared
        self.storageManager = storageManager ?? StorageManager.shared
        
        // Move setup to a task to handle main actor properly
        Task { @MainActor in
            setupAutoRefresh()
            refreshData()
        }
    }
    
    func loadDashboardData() async {
        refreshData()
    }
    
    func refreshData() {
        isLoading = true
        error = nil
        
        Task {
            // Load stats based on selected time filter
            let summary = await statsService.calculateStats(
                for: selectedTimeFilter,
                startDate: customDateRange?.startDate,
                endDate: customDateRange?.endDate
            )
            
            // Load all game sessions and modes
            let allSessions = await storageManager.fetchGameSessions()
            let allGameModes = await storageManager.fetchGameModes()
            
            // Filter sessions based on selected time filter
            let filteredSessions = filterSessionsByTimeFilter(allSessions)
            
            // Update UI on main thread
            await MainActor.run {
                self.stats = summary
                self.recentGameSessions = Array(allSessions.prefix(10))
                self.filteredGameSessions = filteredSessions
                self.gameModes = allGameModes
                self.isLoading = false
                
                // Update error from storage manager if needed
                if let storageError = self.storageManager.errorMessage {
                    self.error = NSError(domain: "StorageError", code: 0, userInfo: [NSLocalizedDescriptionKey: storageError])
                }
            }
        }
    }
    
    private func filterSessionsByTimeFilter(_ sessions: [GameSession]) -> [GameSession] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeFilter {
        case .day:
            return sessions.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case .week:
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            return sessions.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return sessions.filter { $0.date >= monthAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return sessions.filter { $0.date >= yearAgo }
        case .custom:
            guard let dateRange = customDateRange else { return sessions }
            return sessions.filter { $0.date >= dateRange.startDate && $0.date <= dateRange.endDate }
        }
    }
    
    func sortedGameSessions(by sortOption: DashboardView.SortOption) -> [GameSession] {
        switch sortOption {
        case .profitAsc:
            return filteredGameSessions.sorted { $0.profit < $1.profit }
        case .profitDesc:
            return filteredGameSessions.sorted { $0.profit > $1.profit }
        }
    }
    
    func getGameModeTitle(for modeID: UUID) -> String {
        return gameModes.first { $0.id == modeID }?.title ?? "Juego Desconocido"
    }
    
    func updateTimeFilter(_ filter: TimeFilter) {
        selectedTimeFilter = filter
        if filter != .custom {
            customDateRange = nil
        }
        refreshData()
    }
    
    func updateCustomDateRange(_ range: DateRange) {
        customDateRange = range
        selectedTimeFilter = .custom
        refreshData()
    }
    
    private func setupAutoRefresh() {
        // Refresh data every 5 minutes
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Preview Support
extension DashboardViewModel {
    static func preview() -> DashboardViewModel {
        let viewModel = DashboardViewModel()
        
        // Mock data for preview
        Task { @MainActor in
            viewModel.stats = StatsSummary(
                totalGames: 15,
                totalProfit: Decimal(850),
                totalPayout: Decimal(1200),
                totalGrossIncome: Decimal(2050),
                uniquePlayers: 45,
                repeatRate: 0.67,
                averageProfit: Decimal(56.67),
                averagePlayersPerGame: 8.5,
                mostPopularGameMode: "Modo Básico",
                timeFilter: .day,
                startDate: nil,
                endDate: nil
            )
            
            viewModel.recentGameSessions = [
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
                )
            ]
        }
        
        return viewModel
    }
} 