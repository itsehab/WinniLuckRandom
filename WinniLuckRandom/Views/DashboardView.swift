import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDatePicker = false
    @State private var selectedSortOption: SortOption = .profitAsc
    
    enum SortOption: String, CaseIterable {
        case profitAsc = "profitAsc"
        case profitDesc = "profitDesc"
        
        var localizedTitle: String {
            switch self {
            case .profitAsc:
                return NSLocalizedString("lowest_to_highest", comment: "")
            case .profitDesc:
                return NSLocalizedString("highest_to_lowest", comment: "")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Mi estadistica")
                .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadDashboardData()
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerView(viewModel: viewModel)
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                contentBody
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private var contentBody: some View {
        if viewModel.isLoading {
            loadingView
        } else if let stats = viewModel.stats {
            statsContent(stats: stats)
        } else {
            errorView
        }
    }
    
    @ViewBuilder
    private func statsContent(stats: StatsSummary) -> some View {
        kpiCardsSection(stats: stats)
        timeFilterSection
        sortBySection
        gameHistorySection
        navigationButtonsSection
    }
    
    // MARK: - Toolbar removed as requested
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        ProgressView("dashboard_loading_stats")
            .padding()
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("dashboard_error_loading")
                .font(.headline)
            
            Button("common_retry") {
                Task {
                    await viewModel.loadDashboardData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func kpiCardsSection(stats: StatsSummary) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
            KPICard(
                title: "Juegos",
                value: "\(stats.totalGames)",
                icon: "gamecontroller.fill",
                color: .blue
            )
            
            KPICard(
                title: "Ingreso",
                value: formatCurrency(stats.totalGrossIncome),
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            KPICard(
                title: "Ganancia", 
                value: formatCurrency(stats.totalProfit),
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
            
            KPICard(
                title: "Margen",
                value: "\(String(format: "%.1f", stats.profitMargin * 100))%",
                icon: "percent",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
    
    private var timeFilterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Historia De Los Juegos")
                .font(.headline)
                .padding(.horizontal)
            
            HStack {
                // Day/Week always shown
                Picker("Time Filter", selection: $viewModel.selectedTimeFilter) {
                    Text(TimeFilter.day.localizedTitle).tag(TimeFilter.day)
                    Text(TimeFilter.week.localizedTitle).tag(TimeFilter.week)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Date picker button
                Button(action: {
                    showDatePicker = true
                }) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }
    
    private var sortBySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ordenar por Margen")
                    .font(.headline)
                
                Text(selectedSortOption == .profitAsc ? "Menor a Mayor" : "Mayor a Menor")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                selectedSortOption = selectedSortOption == .profitAsc ? .profitDesc : .profitAsc
            }) {
                Image(systemName: selectedSortOption == .profitAsc ? "arrow.up" : "arrow.down")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    private var gameHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.filteredGameSessions.isEmpty {
                Text("No hay sesiones de juego")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.sortedGameSessions(by: selectedSortOption)) { session in
                    GameSessionCard(session: session, viewModel: viewModel)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var navigationButtonsSection: some View {
        VStack(spacing: 15) {
            NavigationLink(destination: GameModesView()) {
                DashboardButton(
                    title: "Crear Juegos",
                    icon: "gamecontroller.fill",
                    color: .green
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "S/. 0.00"
    }
}

// MARK: - Supporting Views

struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GameSessionCard: View {
    let session: GameSession
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.getGameModeTitle(for: session.modeID))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(session.winnerIDs.count) ganadores")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(formatDateTime(session.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Premio: \(formatCurrency(session.payout))")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text("Mi Ganancia: \(formatCurrency(session.profit))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "S/. 0.00"
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DashboardButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Spacer()
            
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title2)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(color)
        .cornerRadius(12)
    }
}

// MARK: - Date Picker View

struct DatePickerView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: DateOption = .month
    @State private var selectedMonth = Date()
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    enum DateOption: String, CaseIterable {
        case month = "month"
        case custom = "custom"
        
        var localizedTitle: String {
            switch self {
            case .month:
                return NSLocalizedString("month", comment: "")
            case .custom:
                return NSLocalizedString("custom", comment: "")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Picker("Date Option", selection: $selectedOption) {
                    ForEach(DateOption.allCases, id: \.self) { option in
                        Text(option.localizedTitle).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if selectedOption == .month {
                    DatePicker(
                        "Seleccionar Mes",
                        selection: $selectedMonth,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                } else {
                    VStack(spacing: 16) {
                        DatePicker(
                            "Fecha de Inicio",
                            selection: $startDate,
                            displayedComponents: [.date]
                        )
                        
                        DatePicker(
                            "Fecha de Fin",
                            selection: $endDate,
                            displayedComponents: [.date]
                        )
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Seleccionar Fecha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        applyDateFilter()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applyDateFilter() {
        if selectedOption == .month {
            let calendar = Calendar.current
            let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
            let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
            
            viewModel.updateCustomDateRange(DashboardViewModel.DateRange(
                startDate: startOfMonth,
                endDate: endOfMonth
            ))
        } else {
            viewModel.updateCustomDateRange(DashboardViewModel.DateRange(
                startDate: startDate,
                endDate: endDate
            ))
        }
    }
}

// MARK: - TimeFilter Extension already exists in StatsService.swift

#Preview {
    DashboardView()
} 