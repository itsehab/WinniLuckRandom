import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date?
    @State private var isAscending = false // Add sorting state since it's not in ViewModel
    @State private var showingCustomDatePicker = false
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    
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
                VStack(spacing: UIDevice.isIPad ? 30 : 20) {
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
                        
                        // Navigation Buttons
                        navigationButtonsSection
                        
                        Spacer(minLength: UIDevice.isIPad ? 150 : 100)
                    }
                    .adaptivePadding(iPadPadding: 40, iPhonePadding: 20)
                    .padding(.top, UIDevice.isIPad ? 20 : 10)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack) // Use stack navigation on all devices for single-view design
        .task {
            await viewModel.loadDashboardData()
        }
        .onChange(of: viewModel.selectedTimeFilter) { _, newFilter in
            // Time filter changes are handled automatically by the ViewModel
        }
        .sheet(isPresented: $showingCustomDatePicker) {
            customDatePickerSheet
        }
    }
    
    // MARK: - Admin Header
    
    private var adminHeader: some View {
        VStack(spacing: 16) {
            HStack {
                // Back Button
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: UIDevice.isIPad ? 18 : 16, weight: .semibold))
                        Text("Inicio")
                            .font(.system(size: UIDevice.isIPad ? 18 : 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, UIDevice.isIPad ? 20 : 16)
                    .padding(.vertical, UIDevice.isIPad ? 12 : 10)
                    .background(
                        RoundedRectangle(cornerRadius: UIDevice.isIPad ? 25 : 20)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: UIDevice.isIPad ? 25 : 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Mi Estadística")
                        .font(UIDevice.isIPad ? .system(size: 48, weight: .bold) : .largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Panel de Administración")
                        .font(UIDevice.isIPad ? .title3 : .subheadline)
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
            Text("\(formatCurrency(viewModel.stats?.totalProfit ?? 0))")
                .font(UIDevice.isIPad ? .largeTitle : .title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("\(viewModel.stats?.totalGames ?? 0) juegos")
                .font(UIDevice.isIPad ? .body : .caption)
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
                        isSelected: viewModel.selectedTimeFilter == filter
                    ) {
                        if filter == .custom {
                            showingCustomDatePicker = true
                        } else {
                            viewModel.updateTimeFilter(filter)
                        }
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
                    .font(UIDevice.isIPad ? .largeTitle : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: UIDevice.isIPad ? 16 : 12), 
                    count: UIDevice.isIPad ? 4 : 2
                ), 
                spacing: UIDevice.isIPad ? 16 : 12
            ) {
                EnhancedKPICard(
                    title: "Juegos Jugados",
                    value: "\(viewModel.stats?.totalGames ?? 0)",
                    subtitle: "Total",
                    icon: "gamecontroller.fill",
                    color: .blue
                )
                
                EnhancedKPICard(
                    title: "Ingreso Total",
                    value: "\(formatCurrency(viewModel.stats?.totalGrossIncome ?? 0))",
                    subtitle: "Bruto",
                    icon: "dollarsign.circle.fill",
                    color: .cyan
                )
                
                EnhancedKPICard(
                    title: "Mi Ganancia",
                    value: "\(formatCurrency(viewModel.stats?.totalProfit ?? 0))",
                    subtitle: "Neto",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                EnhancedKPICard(
                    title: "Margen",
                    value: "\(Int((viewModel.stats?.profitMargin ?? 0) * 100))%",
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
            chartHeader
            chartContent
        }
        .padding(.vertical)
    }
    
    private var chartHeader: some View {
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
    }
    
    private var chartContent: some View {
        Group {
            if viewModel.dailyProfitData.isEmpty {
                modernEmptyChartView
            } else {
                modernChart
            }
        }
    }
    
    private var modernChart: some View {
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
                        Text("S/. \(NSDecimalNumber(decimal: profit).doubleValue, specifier: "%.0f")")
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
        .background(chartBackground)
    }
    
    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
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
            
            // Sort By Section - moved here to be connected to History
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ordenar por Ganancia")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(isAscending ? "Menor a mayor" : "Mayor a menor")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button("Cambiar") {
                    isAscending.toggle()
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
            
            if viewModel.recentGameSessions.isEmpty {
                emptyStateView
            } else {
                // Use grid layout on iPad, vertical stack on iPhone
                if UIDevice.isIPad {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
                        spacing: 16
                    ) {
                        ForEach(viewModel.recentGameSessions.prefix(4), id: \.id) { session in
                            SwipeableGameSessionCard(
                                session: session,
                                viewModel: viewModel
                            ) {
                                Task {
                                    viewModel.deleteGameSession(session)
                                }
                            }
                        }
                    }
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.recentGameSessions.prefix(3), id: \.id) { session in
                            SwipeableGameSessionCard(
                                session: session,
                                viewModel: viewModel
                            ) {
                                Task {
                                    viewModel.deleteGameSession(session)
                                }
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
    

    
    // MARK: - Navigation Buttons Section
    
    private var navigationButtonsSection: some View {
        Group {
            // Use horizontal layout on iPad, vertical on iPhone
            if UIDevice.isIPad {
                HStack(spacing: 16) {
                    NavigationLink(destination: GameModesView()) {
                        DashboardNavButton(
                            title: "Gestionar Modos de Juegos",
                            subtitle: "Configurar tipos de juego",
                            icon: "gamecontroller.fill",
                            color: .purple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: GameHistoryView()) {
                        DashboardNavButton(
                            title: "Historial Completo",
                            subtitle: "Ver todos los juegos",
                            icon: "clock.arrow.circlepath",
                            color: .orange
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                VStack(spacing: 12) {
                    NavigationLink(destination: GameModesView()) {
                        DashboardNavButton(
                            title: "Gestionar Modos de Juegos",
                            subtitle: "Configurar tipos de juego",
                            icon: "gamecontroller.fill",
                            color: .purple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: GameHistoryView()) {
                        DashboardNavButton(
                            title: "Historial Completo",
                            subtitle: "Ver todos los juegos",
                            icon: "clock.arrow.circlepath",
                            color: .orange
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Custom Date Picker Sheet
    
    private var customDatePickerSheet: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background matching main view
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
                    VStack(spacing: 24) {
                        Text("Seleccionar Período Personalizado")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        VStack(spacing: 20) {
                        // Start Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fecha de Inicio")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            DatePicker("", selection: $customStartDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .accentColor(.blue)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // End Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fecha de Fin")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            DatePicker("", selection: $customEndDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .accentColor(.blue)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Apply Button
                        Button("Aplicar Filtro") {
                            applyCustomDateFilter()
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40) // Extra bottom padding for safe area
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        showingCustomDatePicker = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .presentationDetents([.height(500), .large])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
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
    
    private func applyCustomDateFilter() {
        // Ensure end date is after start date
        if customEndDate < customStartDate {
            customEndDate = customStartDate
        }
        
        // Apply the custom date range filter
        viewModel.applyCustomDateFilter(startDate: customStartDate, endDate: customEndDate)
        viewModel.selectedTimeFilter = .custom
        
        // Close the sheet
        showingCustomDatePicker = false
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
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                .foregroundColor(.white)
            
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

struct DashboardNavButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
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
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
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