import SwiftUI

struct GameModesView: View {
    @StateObject private var viewModel = GameModesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background matching dashboard
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
                    // Custom header
                    gameModesHeader
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            contentView
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingForm) {
            GameModeFormView(viewModel: viewModel)
        }
    }
    
    // MARK: - Game Modes Header
    
    private var gameModesHeader: some View {
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
                
                Button(action: { viewModel.showingForm = true }) {
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
                
                // Game modes count
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
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            modernLoadingView
        } else if viewModel.gameModes.isEmpty {
            modernEmptyStateView
        } else {
            modernGameModesList
        }
    }
    
    private var modernLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Cargando modos de juego...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var modernEmptyStateView: some View {
        VStack(spacing: 20) {
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
            
            Button(action: { viewModel.showingForm = true }) {
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
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var modernGameModesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.gameModes) { gameMode in
                ModernGameModeCard(
                    gameMode: gameMode,
                    onEdit: {
                        viewModel.startEditingGameMode(gameMode)
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteGameMode(gameMode)
                        }
                    }
                )
        }
        .onAppear {
            Task {
                await viewModel.loadGameModesIfNeeded()
            }
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
}

struct GameModeRow: View {
    let gameMode: GameMode
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main game mode info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(gameMode.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("game_mode_max_players \(gameMode.maxPlayers)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(gameMode.entryPriceSoles))
                        .font(.headline)
                        .foregroundColor(.green)
                        .bold()
                    
                    Text("game_mode_entry_fee")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Prize breakdown
            if gameMode.prizeTiers.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prize Breakdown:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    ForEach(Array(gameMode.prizeTiers.enumerated()), id: \.offset) { index, prize in
                        HStack {
                            Text("\(index + 1)\(ordinalSuffix(index + 1)) Place:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatCurrency(prize))
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Financial summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Prizes: \(formatCurrency(gameMode.prizeTiers.reduce(0, +)))")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text("Winners: \(gameMode.maxWinners)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Profit: \(gameMode.formattedProfit(for: gameMode.maxPlayers, winners: gameMode.maxWinners))")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .bold()
                    
                    Text("(Full capacity)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("common_edit") {
                onEdit()
            }
            .tint(.blue)
            
            Button("common_delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "S/. 0.00"
    }
    
    private func ordinalSuffix(_ number: Int) -> String {
        switch number {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

struct CreateGameModeSheet: View {
    @ObservedObject var viewModel: GameModesViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    Toggle("Use Custom Title", isOn: $viewModel.useCustomTitle)
                    
                    if viewModel.useCustomTitle {
                        TextField("Game mode title", text: $viewModel.formTitle)
                            .focused($isTextFieldFocused)
                    } else {
                        Text("Title will be auto-generated")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Max Players:")
                        Spacer()
                        TextField("Players", value: $viewModel.maxPlayers, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                    }
                    
                    HStack {
                        Text("Repetitions:")
                        Spacer()
                        TextField("Repetitions", value: $viewModel.repetitions, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                    }
                    Text("How many times each number needs to be called to win")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Financial Settings") {
                    HStack {
                        Text("Entry Fee:")
                        Spacer()
                        TextField("0.00", value: $viewModel.entryFee, format: .currency(code: "PEN"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isTextFieldFocused)
                    }
                    
                    HStack {
                        Text("Max Winners:")
                        Spacer()
                        TextField("Winners", value: $viewModel.maxWinners, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .onChange(of: viewModel.maxWinners) { _, newValue in
                                viewModel.updatePrizeTiers(for: newValue)
                            }
                    }
                }
                
                Section("Prize Distribution") {
                    ForEach(0..<viewModel.prizeTiers.count, id: \.self) { index in
                        HStack {
                            Text(getPositionLabel(for: index))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            TextField("0.00", value: Binding(
                                get: { viewModel.prizeTiers[index] },
                                set: { viewModel.updatePrize(at: index, to: $0) }
                            ), format: .currency(code: "PEN"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                        }
                    }
                }
                
                Section("Financial Summary") {
                    HStack {
                        Text("Total Entry Fees")
                        Spacer()
                        Text(formatCurrency(viewModel.entryFee * Decimal(viewModel.maxPlayers)))
                            .foregroundColor(.green)
                            .bold()
                    }
                    
                    HStack {
                        Text("Total Prize Pool")
                        Spacer()
                        Text(formatCurrency(viewModel.totalPrizePool))
                            .foregroundColor(.blue)
                            .bold()
                    }
                    
                    HStack {
                        Text("Estimated Profit")
                        Spacer()
                        Text(formatCurrency(viewModel.estimatedProfit))
                            .foregroundColor(viewModel.estimatedProfit >= 0 ? .purple : .red)
                            .bold()
                    }
                    
                    if viewModel.estimatedProfit < 0 {
                        Label("Warning: Prizes exceed entry fees", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section("Display Order") {
                    HStack {
                        Text("Position in Home Page:")
                        Spacer()
                        TextField("Order", value: $viewModel.order, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                    }
                    Text("Lower numbers appear first. Use 0 for auto-assign to end.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Game Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Set title if not using custom title
                        if !viewModel.useCustomTitle {
                            viewModel.formTitle = viewModel.generateTitle()
                        }
                        
                        Task {
                            await viewModel.saveGameMode()
                            
                            // Only dismiss if save was successful (no error message)
                            await MainActor.run {
                                if viewModel.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
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
    
    private func getPositionLabel(for index: Int) -> String {
        switch index {
        case 0: return "1st Place"
        case 1: return "2nd Place"
        case 2: return "3rd Place"
        default: return "\(index + 1)th Place"
        }
    }
}

struct EditGameModeSheet: View {
    @ObservedObject var viewModel: GameModesViewModel
    let gameMode: GameMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    HStack {
                        Text("Title:")
                            .frame(width: 80, alignment: .leading)
                        TextField("Game mode title", text: $viewModel.formTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Max Players:")
                            .frame(width: 80, alignment: .leading)
                        TextField("Max players", value: $viewModel.maxPlayers, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Text("Entry Fee:")
                            .frame(width: 80, alignment: .leading)
                        TextField("Entry fee", value: $viewModel.entryFee, format: .currency(code: "PEN"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Max Winners:")
                            .frame(width: 80, alignment: .leading)
                        TextField("Max winners", value: $viewModel.maxWinners, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: viewModel.maxWinners) { newValue in
                                viewModel.updatePrizeTiers(for: newValue)
                            }
                    }
                    
                    HStack {
                        Text("Repetitions:")
                            .frame(width: 80, alignment: .leading)
                        TextField("Repetitions", value: $viewModel.repetitions, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                Section("Prize Configuration") {
                    ForEach(Array(viewModel.prizeTiers.enumerated()), id: \.offset) { index, prize in
                        HStack {
                            Text("\(index + 1)\(ordinalSuffix(index + 1)) Place:")
                                .frame(width: 80, alignment: .leading)
                            TextField("Prize amount", value: Binding(
                                get: { viewModel.prizeTiers[index] },
                                set: { viewModel.updatePrize(at: index, to: $0) }
                            ), format: .currency(code: "PEN"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                Section("Financial Summary") {
                    HStack {
                        Text("Total Entry Fees:")
                        Spacer()
                        Text(formatCurrency(viewModel.entryFee * Decimal(viewModel.maxPlayers)))
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Total Prize Pool:")
                        Spacer()
                        Text(formatCurrency(viewModel.totalPrizePool))
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Estimated Profit:")
                        Spacer()
                        Text(formatCurrency(viewModel.estimatedProfit))
                            .foregroundColor(viewModel.estimatedProfit >= 0 ? .green : .red)
                            .fontWeight(.bold)
                    }
                    
                    if viewModel.estimatedProfit < 0 {
                        Text("⚠️ Warning: Prize pool exceeds total entry fees!")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section("Display Order") {
                    HStack {
                        Text("Position:")
                            .frame(width: 80, alignment: .leading)
                        TextField("Order", value: $viewModel.order, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    Text("Lower numbers appear first in home page")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Game Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.updateGameMode()
                            
                            // Only dismiss if update was successful (no error message)
                            await MainActor.run {
                                if viewModel.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
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
    
    private func ordinalSuffix(_ number: Int) -> String {
        switch number {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

// MARK: - Modern Game Mode Card

struct ModernGameModeCard: View {
    let gameMode: GameMode
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(gameMode.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(gameMode.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                                    )
                            )
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            
            // Game details
            HStack(spacing: 20) {
                GameDetailPill(
                    icon: "person.3.fill",
                    title: "Jugadores",
                    value: "\(gameMode.maxPlayers)",
                    color: .blue
                )
                
                GameDetailPill(
                    icon: "trophy.fill",
                    title: "Ganadores",
                    value: "\(gameMode.maxWinners)",
                    color: .orange
                )
                
                GameDetailPill(
                    icon: "arrow.clockwise",
                    title: "Repeticiones",
                    value: "\(gameMode.repetitions)",
                    color: .green
                )
            }
            
            // Financial info
            HStack(spacing: 20) {
                FinancialDetailPill(
                    title: "Costo",
                    amount: gameMode.costPerPlayer,
                    color: .cyan
                )
                
                FinancialDetailPill(
                    title: "Premio",
                    amount: gameMode.prizePerWinner,
                    color: .purple
                )
            }
        }
        .padding(20)
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
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Game Detail Pill

struct GameDetailPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(minWidth: 70)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

// MARK: - Financial Detail Pill

struct FinancialDetailPill: View {
    let title: String
    let amount: Decimal
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
            
            Text(formatCurrency(amount))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(minWidth: 100)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
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

#Preview {
    GameModesView()
}