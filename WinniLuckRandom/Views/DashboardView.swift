import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedDate: Date?
    @State private var selectedTimeFilter: TimeFilter = .month
    
    // MARK: - Enums
    
    enum SortOption {
        case profitAsc
        case profitDesc
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        adminHeader
                        
                        // Time Filter Pills
                        timeFilterPills
                        
                        // KPI Cards
                        kpiCardsSection
                        
                        // Chart Section
                        profitChartSection
                        
                        // Game History Section
                        gameHistorySection
                        
                        // Sort By Section
                        sortBySection
                        
                        // Navigation Buttons
                        navigationButtonsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadData()
        }
        .onChange(of: selectedTimeFilter) { _, newFilter in
            Task {
                await viewModel.updateTimeFilter(newFilter)
            }
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
                
                // Quick Stats
                quickStatsView
            }
        }
        .padding(.bottom, 10)
    }
    
    private var quickStatsView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("S/. \(formatCurrency(viewModel.totalProfit))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("\(viewModel.totalGames) juegos")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Time Filter Pills
    
    private var timeFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeFilter.allCases, id: \.self) { filter in
                    TimeFilterPill(
                        filter: filter,
                        isSelected: selectedTimeFilter == filter
                    ) {
                        selectedTimeFilter = filter
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - KPI Cards Section
    
    private var kpiCardsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Resumen Financiero")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                EnhancedKPICard(
                    title: "Juegos Jugados",
                    value: "\(viewModel.totalGames)",
                    subtitle: "Total",
                    icon: "gamecontroller.fill",
                    color: .blue
                )
                
                EnhancedKPICard(
                    title: "Ingreso Total",
                    value: "S/. \(formatCurrency(viewModel.totalRevenue))",
                    subtitle: "Bruto",
                    icon: "dollarsign.circle.fill",
                    color: .cyan
                )
                
                EnhancedKPICard(
                    title: "Mi Ganancia",
                    value: "S/. \(formatCurrency(viewModel.totalProfit))",
                    subtitle: "Neto",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                EnhancedKPICard(
                    title: "Margen",
                    value: "\(Int(viewModel.profitMargin * 100))%",
                    subtitle: "Promedio",
                    icon: "percent",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Profit Chart Section
    
    private var profitChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ganancias Diarias")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Últimos 30 días")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Chart legend
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Ganancia")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Chart container
            if viewModel.dailyProfitData.isEmpty {
                modernEmptyChartView
            } else {
                Chart(viewModel.dailyProfitData) { data in
                    // Modern gradient area
                    AreaMark(
                        x: .value("Fecha", data.date),
                        y: .value("Ganancia", data.profit)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.6),
                                Color.green.opacity(0.2),
                                Color.green.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    // Modern line with gradient
                    LineMark(
                        x: .value("Fecha", data.date),
                        y: .value("Ganancia", data.profit)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.catmullRom)
                    
                    // Modern point marks
                    PointMark(
                        x: .value("Fecha", data.date),
                        y: .value("Ganancia", data.profit)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(60)
                    
                    PointMark(
                        x: .value("Fecha", data.date),
                        y: .value("Ganancia", data.profit)
                    )
                    .foregroundStyle(Color.green)
                    .symbolSize(30)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.day().month(.abbreviated))
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.caption)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let profit = value.as(Decimal.self) {
                            AxisValueLabel {
                                Text("S/. \(profit, specifier: "%.0f")")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.caption)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.vertical)
    }
    
    private var modernEmptyChartView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No hay datos de ganancias")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Las ganancias aparecerán aquí después de completar juegos")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Game History Section
    
    private var gameHistorySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Historia de Juegos")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("← Desliza para eliminar")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if viewModel.recentGames.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.recentGames.prefix(3)) { session in
                        SwipeableGameSessionCard(
                            session: session,
                            viewModel: viewModel
                        ) {
                            Task {
                                await viewModel.deleteGameSession(session)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No hay juegos registrados")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Los juegos aparecerán aquí después de completarlos")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Sort By Section
    
    private var sortBySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ordenar por Ganancia")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(viewModel.isAscending ? "Menor a mayor" : "Mayor a menor")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button("Cambiar") {
                viewModel.toggleSortOrder()
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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
    
    // MARK: - Navigation Buttons Section
    
    private var navigationButtonsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            EnhancedDashboardButton(
                title: "Gestionar Modos de Juegos",
                subtitle: "Configurar tipos de juego",
                icon: "gamecontroller.fill",
                color: .purple
            ) {
                // Navigation handled by NavigationLink in EnhancedDashboardButton
            }
            
            NavigationLink(destination: GameHistoryView()) {
                EnhancedDashboardButton(
                    title: "Historial Completo",
                    subtitle: "Ver todos los juegos",
                    icon: "clock.arrow.circlepath",
                    color: .orange
                ) {
                    // Navigation handled by NavigationLink
                }
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

struct TimeFilterPill: View {
    let filter: TimeFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter.localizedTitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

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

struct GameSessionCard: View {
    let session: GameSession
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Juego #\(session.id.uuidString.prefix(8))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(formatDate(session.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.playerIDs.count) jugadores")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(session.winnerIDs.count) ganadores")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Financial breakdown
            HStack(spacing: 8) {
                FinancialPill(title: "Ingreso", amount: session.grossIncome, color: .cyan)
                FinancialPill(title: "Premio", amount: session.payout, color: .orange)
                FinancialPill(title: "Ganancia", amount: session.profit, color: .green)
            }
        }
        .padding(16)
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
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

struct FinancialPill: View {
    let title: String
    let amount: Decimal
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
            
            Text(formatCurrency(amount))
                .font(.caption)
                .fontWeight(.bold)
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

struct EnhancedKPICard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
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
}

// MARK: - View Extension

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

#Preview {
    DashboardView()
} 