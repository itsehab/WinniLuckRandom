import SwiftUI

struct GameModesView: View {
    @StateObject private var viewModel = GameModesViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
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
            
            VStack(spacing: 0) {
                headerView
                contentSection
                }
            }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await viewModel.loadGameModesIfNeeded()
                }
            }
                    .fullScreenCover(isPresented: $viewModel.showingAddSheet) {
            EnhancedGameModeEditor(viewModel: viewModel, isEditing: false)
        }
        .fullScreenCover(isPresented: $viewModel.showingEditSheet) {
            EnhancedGameModeEditor(viewModel: viewModel, isEditing: true)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Volver")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                Button(action: { 
                    viewModel.resetForm()
                    viewModel.showingAddSheet = true 
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Nuevo")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Modos de Juego")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Gestiona tus configuraciones")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text("\(viewModel.gameModes.count)")
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
            .padding(.horizontal, 20)
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
    
    private var contentSection: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .foregroundColor(.white)
                    .padding()
            } else if viewModel.gameModes.isEmpty {
                EmptyGameModesView {
                    viewModel.resetForm()
                    viewModel.showingAddSheet = true
                }
            } else {
                // Use grid layout on iPad, vertical stack on iPhone
                if UIDevice.isIPad {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2),
                        spacing: 20
                    ) {
                        ForEach(viewModel.gameModes) { gameMode in
                            EnhancedGameModeCard(gameMode: gameMode) {
                                viewModel.startEditingGameMode(gameMode)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.gameModes) { gameMode in
                            EnhancedGameModeCard(gameMode: gameMode) {
                                viewModel.startEditingGameMode(gameMode)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyGameModesView: View {
    let onCreateNew: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No hay modos de juego")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Crea tu primer modo de juego para comenzar")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreateNew) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Crear Modo de Juego")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Enhanced Game Mode Card

struct EnhancedGameModeCard: View {
    let gameMode: GameMode
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            VStack(spacing: 24) {
                // Header with title and edit indicator
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(gameMode.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text("Toca para editar")
                        .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Game details with icons in a responsive grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    
                    IconGameInfoPill(
                        icon: "person.3.fill",
                        title: "Jugadores",
                        value: "\(gameMode.maxPlayers)",
                        color: .blue
                    )
                    
                    IconGameInfoPill(
                        icon: "trophy.fill",
                        title: "Ganadores",
                        value: "\(gameMode.maxWinners)",
                        color: .orange
                    )
                    
                    IconGameInfoPill(
                        icon: "arrow.clockwise",
                        title: "Repeticiones",
                        value: "\(gameMode.repetitions)",
                        color: .green
                    )
                    
                    IconGameInfoPill(
                        icon: "dollarsign.circle.fill",
                        title: "Costo Entrada",
                        value: formatCurrency(gameMode.entryPriceSoles),
                        color: .cyan
                    )
                }
                
                // Financial summary section
                VStack(spacing: 16) {
                    HStack {
                        Text("Resumen Financiero")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                    }
                    
                    // Financial metrics
                    HStack(spacing: 12) {
                        FinancialMetricPill(
                            title: "Ingresos",
                            value: formatCurrency(calculateTotalRevenue(gameMode)),
                            color: .green
                        )
                        
                        FinancialMetricPill(
                            title: "Premios",
                            value: formatCurrency(gameMode.totalPrizePool),
                            color: .red
                        )
                        
                        FinancialMetricPill(
                            title: "Ganancia",
                            value: formatCurrency(gameMode.estimatedProfit),
                            color: gameMode.estimatedProfit >= 0 ? .green : .red
                        )
                    }
                    
                    // Profit margin indicator
                    HStack {
                        Text("Margen de Ganancia:")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(Int(calculateProfitMargin(gameMode) * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(gameMode.estimatedProfit >= 0 ? .green : .red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
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
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func calculateTotalRevenue(_ gameMode: GameMode) -> Decimal {
        return gameMode.entryPriceSoles * Decimal(gameMode.maxPlayers)
    }
    
    private func calculateProfitMargin(_ gameMode: GameMode) -> Double {
        let totalRevenue = calculateTotalRevenue(gameMode)
        guard totalRevenue > 0 else { return 0 }
        return Double(truncating: NSDecimalNumber(decimal: gameMode.estimatedProfit / totalRevenue))
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "S/. 0.00"
    }
}

// MARK: - Icon Game Info Pill

struct IconGameInfoPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Title and value
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Financial Metric Pill

struct FinancialMetricPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Game Mode Editor

struct EnhancedGameModeEditor: View {
    @ObservedObject var viewModel: GameModesViewModel
    let isEditing: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching the app
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
                    VStack(spacing: UIDevice.isIPad ? 40 : 24) {
                        editorContent
                    }
                    .padding(.horizontal, UIDevice.isIPad ? 60 : 20)
                    .padding(.vertical, UIDevice.isIPad ? 40 : 20)
                    .frame(maxWidth: UIDevice.isIPad ? 800 : .infinity) // Limit width on iPad for better readability
                    .frame(maxWidth: .infinity) // Center the constrained content
                }
            }
            .navigationTitle(isEditing ? "Editar Modo" : "Nuevo Modo")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(UIDevice.isIPad ? .title3 : .body)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        Task {
                            if isEditing {
                                await viewModel.updateGameMode()
                            } else {
                            await viewModel.saveGameMode()
                            }
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isFormValid)
                    .foregroundColor(viewModel.isFormValid ? .white : .gray)
                    .font(UIDevice.isIPad ? .title3 : .body)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(.stack) // Force stack style for full screen presentation
        .onDisappear {
            if !isEditing {
                viewModel.resetForm()
            }
        }
    }
    
    private var editorContent: some View {
        VStack(spacing: 24) {
            // Title Section
            EditorSection(title: "Información Básica", icon: "info.circle.fill") {
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "Título del Modo",
                        text: $viewModel.formTitle,
                        placeholder: "Ej: 10 jugadores - 1 ganador"
                    )
                    
                    HStack(spacing: 16) {
                        CustomStepper(
                            title: "Jugadores",
                            value: $viewModel.maxPlayers,
                            range: 1...100,
                            color: .blue
                        )
                        
                        CustomStepper(
                            title: "Ganadores",
                            value: $viewModel.maxWinners,
                            range: 1...viewModel.maxPlayers,
                            color: .orange
                        )
                    }
                    
                    HStack(spacing: 16) {
                        CustomCurrencyField(
                            title: "Costo de Entrada",
                            value: $viewModel.entryFee
                        )
                        
                        CustomStepper(
                            title: "Repeticiones",
                            value: $viewModel.repetitions,
                            range: 1...10,
                            color: .green
                        )
                    }
                }
            }
            
            // Prize Configuration Section
            EditorSection(title: "Configuración de Premios", icon: "gift.fill") {
                VStack(spacing: 16) {
                    ForEach(0..<viewModel.maxWinners, id: \.self) { index in
                        PrizeInputRow(
                            position: index + 1,
                            value: Binding(
                                get: { 
                                    index < viewModel.prizeTiers.count ? viewModel.prizeTiers[index] : 0
                                },
                                set: { newValue in
                                    if index < viewModel.prizeTiers.count {
                                        viewModel.prizeTiers[index] = newValue
                                    }
                                }
                            )
                        )
                    }
                }
            }
            .onChange(of: viewModel.maxWinners) { _, newValue in
                viewModel.updatePrizeTiers(for: newValue)
            }
            
            // Real-time Financial Summary
            EditorSection(title: "Resumen Financiero", icon: "chart.bar.fill") {
                FinancialSummaryCard(viewModel: viewModel)
            }
            
            // Delete button for editing mode
            if isEditing {
                Button(action: {
                    Task {
                        if let gameMode = viewModel.editingGameMode {
                            await viewModel.deleteGameMode(gameMode)
                            dismiss()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                        Text("Eliminar Modo de Juego")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}

// MARK: - Editor Components

struct EditorSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: UIDevice.isIPad ? 24 : 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: UIDevice.isIPad ? 24 : 20, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(UIDevice.isIPad ? .largeTitle : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            content()
        }
        .padding(UIDevice.isIPad ? 32 : 20)
        .background(
            RoundedRectangle(cornerRadius: UIDevice.isIPad ? 24 : 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: UIDevice.isIPad ? 24 : 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(ModernTextFieldStyle())
        }
    }
}

struct CustomStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Button(action: {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value > range.lowerBound ? color : .gray)
                }
                .disabled(value <= range.lowerBound)
                
                Spacer()
                
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
                
                Button(action: {
                    if value < range.upperBound {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value < range.upperBound ? color : .gray)
                }
                .disabled(value >= range.upperBound)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
            )
        }
    }
}

struct CustomCurrencyField: View {
    let title: String
    @Binding var value: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                Text("S/.")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
                
                TextField("0.50", value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(ModernTextFieldStyle())
            }
        }
    }
}

struct PrizeInputRow: View {
    let position: Int
    @Binding var value: Decimal
    
    var body: some View {
        HStack(spacing: 12) {
            // Position indicator
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("\(position)°")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Premio \(position)° lugar")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    Text("S/.")
                        .foregroundColor(.purple)
                        .fontWeight(.semibold)
                    
                    TextField("0.00", value: $value, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ModernTextFieldStyle())
                }
            }
        }
    }
}

struct FinancialSummaryCard: View {
    @ObservedObject var viewModel: GameModesViewModel
    
    var totalRevenue: Decimal {
        return viewModel.entryFee * Decimal(viewModel.maxPlayers)
    }
    
    var profitMargin: Double {
        guard totalRevenue > 0 else { return 0 }
        return Double(truncating: NSDecimalNumber(decimal: viewModel.estimatedProfit / totalRevenue))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Revenue breakdown
            HStack(spacing: 12) {
                RevenueMetric(
                    title: "Ingresos",
                    value: formatCurrency(totalRevenue),
                    color: .green,
                    icon: "arrow.up.circle.fill"
                )
                
                RevenueMetric(
                    title: "Premios",
                    value: formatCurrency(viewModel.totalPrizePool),
                    color: .red,
                    icon: "arrow.down.circle.fill"
                )
            }
            
            // Profit and margin
            VStack(spacing: 12) {
                HStack {
                    Text("Ganancia Neta:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatCurrency(viewModel.estimatedProfit))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.estimatedProfit >= 0 ? .green : .red)
                }
                
                HStack {
                    Text("Margen de Ganancia:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(Int(profitMargin * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.estimatedProfit >= 0 ? .green : .red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.estimatedProfit >= 0 ? Color.green.opacity(0.5) : Color.red.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "S/. 0.00"
    }
}

struct RevenueMetric: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
    }
}

#Preview {
    GameModesView()
} 