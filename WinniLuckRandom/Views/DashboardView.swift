import SwiftUI
import Charts

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDatePicker = false
    @State private var selectedSortOption: SortOption = .profitAsc
    @State private var selectedDate: Date?
    
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
            ZStack {
                // Beautiful gradient background matching main app
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.3, blue: 0.6),
                        Color(red: 0.1, green: 0.1, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                mainContent
                    .navigationTitle("")
                    .navigationBarHidden(true)
            }
        }
        .task {
            await viewModel.loadDashboardData()
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerView(viewModel: viewModel)
        }
    }
    
    // MARK: - Admin Header
    
    private var adminHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mi Estadística")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Panel de Administración")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Stats quick view
                if let stats = viewModel.stats {
                    QuickStatsView(stats: stats)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Time filter pills
            timeFilterPills
        }
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.1),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Quick Stats View
    
    private func QuickStatsView(stats: StatsSummary) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                    .font(.caption)
                Text(formatCurrency(stats.totalProfit))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Text("\(stats.totalGames) juegos")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Time Filter Pills
    
    private var timeFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([TimeFilter.day, .week, .month, .year], id: \.self) { filter in
                    TimeFilterPill(
                        filter: filter,
                        isSelected: viewModel.selectedTimeFilter == filter,
                        onTap: {
                            viewModel.updateTimeFilter(filter)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Time Filter Pill
    
    private func TimeFilterPill(filter: TimeFilter, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(filter.localizedTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Custom header
            adminHeader
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 24) {
                    contentBody
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100) // Extra bottom padding for floating button
            }
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
        profitChartSection
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            EnhancedKPICard(
                title: "Juegos Jugados",
                value: "\(stats.totalGames)",
                icon: "gamecontroller.fill",
                color: .blue,
                subtitle: "Total"
            )
            
            EnhancedKPICard(
                title: "Ingreso Total",
                value: formatCurrency(stats.totalGrossIncome),
                icon: "arrow.down.circle.fill",
                color: .cyan,
                subtitle: "Recaudado"
            )
            
            EnhancedKPICard(
                title: "Mi Ganancia", 
                value: formatCurrency(stats.totalProfit),
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                subtitle: "Neta"
            )
            
            EnhancedKPICard(
                title: "Margen",
                value: "\(String(format: "%.1f", stats.profitMargin * 100))%",
                icon: "percent",
                color: .orange,
                subtitle: "Promedio"
            )
        }
    }
    
    private var profitChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ganancias Diarias (30 días)")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.dailyProfitData.isEmpty {
                Text("No hay datos disponibles")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Chart(viewModel.dailyProfitData) { data in
                    LineMark(
                        x: .value("Fecha", data.date),
                        y: .value("Ganancia", data.profit)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Fecha", data.date),
                        y: .value("Ganancia", data.profit)
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                    
                    // Add point mark for selected date
                    if let selectedDate = selectedDate,
                       let selectedData = viewModel.dailyProfitData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                        PointMark(
                            x: .value("Fecha", selectedData.date),
                            y: .value("Ganancia", selectedData.profit)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(100)
                        
                        PointMark(
                            x: .value("Fecha", selectedData.date),
                            y: .value("Ganancia", selectedData.profit)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(50)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.day().month(.abbreviated))
                            }
                        }
                        AxisGridLine()
                        AxisTick()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        if let profit = value.as(Decimal.self) {
                            AxisValueLabel {
                                Text("S/. \(profit)")
                            }
                        }
                        AxisGridLine()
                        AxisTick()
                    }
                }
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        updateSelectedDate(at: value.location, in: geometry, chartProxy: chartProxy)
                                    }
                                    .onEnded { _ in
                                        selectedDate = nil
                                    }
                            )
                    }
                }
                .padding(.horizontal)
                .overlay(alignment: .topTrailing) {
                    // Tooltip
                    if let selectedDate = selectedDate,
                       let selectedData = viewModel.dailyProfitData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedData.formattedDate)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(selectedData.formattedProfit)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("\(selectedData.sessionCount) sesiones")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 4)
                        )
                        .animation(.easeInOut(duration: 0.2), value: selectedDate)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private func updateSelectedDate(at location: CGPoint, in geometry: GeometryProxy, chartProxy: ChartProxy) {
        let xPosition = location.x - geometry.frame(in: .local).minX
        
        if let date: Date = chartProxy.value(atX: xPosition) {
            // Find the closest data point
            let closestData = viewModel.dailyProfitData.min { data1, data2 in
                abs(data1.date.timeIntervalSince(date)) < abs(data2.date.timeIntervalSince(date))
            }
            
            if let closestData = closestData {
                selectedDate = closestData.date
            }
        }
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
                Text("Ordenar por Ganancia")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(selectedSortOption == .profitAsc ? "Menor a Mayor" : "Mayor a Menor")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                selectedSortOption = selectedSortOption == .profitAsc ? .profitDesc : .profitAsc
            }) {
                HStack(spacing: 6) {
                    Image(systemName: selectedSortOption == .profitAsc ? "arrow.up" : "arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Cambiar")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private var gameHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Historia de Juegos")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if !viewModel.filteredGameSessions.isEmpty {
                        Text("← Desliza para eliminar")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                if !viewModel.filteredGameSessions.isEmpty {
                    Text("\(viewModel.filteredGameSessions.count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                                )
                        )
                }
            }
            
            // Game sessions list
            if viewModel.filteredGameSessions.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.sortedGameSessions(by: selectedSortOption)) { session in
                        SwipeableGameSessionCard(
                            session: session, 
                            viewModel: viewModel,
                            onDelete: {
                                viewModel.deleteGameSession(session)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No hay juegos registrados")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Los juegos aparecerán aquí después de completarlos")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var navigationButtonsSection: some View {
        VStack(spacing: 16) {
            NavigationLink(destination: GameModesView()) {
                EnhancedDashboardButton(
                    title: "Gestionar Modos de Juego",
                    subtitle: "Crear, editar y configurar",
                    icon: "gamecontroller.fill",
                    color: .green
                )
            }
            
            NavigationLink(destination: GameHistoryView()) {
                EnhancedDashboardButton(
                    title: "Historial Completo",
                    subtitle: "Ver todos los juegos",
                    icon: "clock.arrow.circlepath",
                    color: .blue
                )
            }
        }
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

// MARK: - Instagram-Style Swipeable Game Session Card

struct SwipeableGameSessionCard: View {
    let session: GameSession
    let viewModel: DashboardViewModel
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isDeleting = false
    
    private let deleteButtonWidth: CGFloat = 80
    private let deleteThreshold: CGFloat = 150
    
    var body: some View {
        ZStack {
            // Background delete area
            HStack {
                Spacer()
                deleteBackground
            }
            
            // Main card content
            GameSessionCard(session: session, viewModel: viewModel)
                .offset(x: offset)
                .gesture(
                    DragGesture(coordinateSpace: .local)
                        .onChanged { value in
                            // Only allow left swipe (negative translation)
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.width
                            let velocity = value.velocity.width
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if translation < -deleteThreshold || velocity < -1000 {
                                    // Swipe far enough or fast enough - delete
                                    performDelete()
                                } else if translation < -deleteButtonWidth / 2 {
                                    // Show delete button
                                    offset = -deleteButtonWidth
                                } else {
                                    // Return to original position
                                    offset = 0
                                }
                            }
                        }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: offset)
        }
        .clipped()
    }
    
    private var deleteBackground: some View {
        HStack {
            if offset < -deleteButtonWidth / 3 {
                Button(action: performDelete) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Eliminar")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(width: deleteButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12, corners: [.topRight, .bottomRight])
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: offset)
    }
    
    private func performDelete() {
        guard !isDeleting else { return }
        isDeleting = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = -400 // Slide completely off screen
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDelete()
        }
    }
}

// MARK: - Game Session Card (Updated Design)

struct GameSessionCard: View {
    let session: GameSession
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.getGameModeTitle(for: session.modeID))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("\(session.winnerIDs.count) ganadores")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDateTime(session.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                        Text("\(session.playerIDs.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            // Financial info row
            HStack {
                FinancialPill(
                    title: "Ingreso",
                    amount: session.grossIncome,
                    color: .blue,
                    icon: "arrow.down.circle.fill"
                )
                
                Spacer()
                
                FinancialPill(
                    title: "Premio",
                    amount: session.payout,
                    color: .orange,
                    icon: "gift.fill"
                )
                
                Spacer()
                
                FinancialPill(
                    title: "Ganancia",
                    amount: session.profit,
                    color: .green,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

// MARK: - Financial Pill Component

struct FinancialPill: View {
    let title: String
    let amount: Decimal
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(formatCurrency(amount))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "S/. 0"
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

// MARK: - Enhanced Components

struct EnhancedKPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with icon and title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.title3)
                        
                        Text(subtitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            // Value
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct EnhancedDashboardButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - TimeFilter Extension already exists in StatsService.swift

#Preview {
    DashboardView()
} 