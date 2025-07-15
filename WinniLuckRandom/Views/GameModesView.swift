import SwiftUI

struct GameModesView: View {
    @StateObject private var viewModel = GameModesViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("game_modes_loading")
                        .padding()
                } else if viewModel.gameModes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("game_modes_empty")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List(viewModel.gameModes) { gameMode in
                        GameModeRow(gameMode: gameMode, 
                                  onEdit: {
                                      viewModel.startEditingGameMode(gameMode)
                                  },
                                  onDelete: {
                                      Task {
                                          await viewModel.deleteGameMode(gameMode)
                                      }
                                  })
                    }
                }
            }
            .navigationTitle("game_modes_title")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common_close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Debug button to reset game modes (remove after testing)
                        Button("Reset") {
                            Task {
                                await viewModel.resetAllGameModes()
                            }
                        }
                        .foregroundColor(.orange)
                        
                        Button {
                            viewModel.showingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                CreateGameModeSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingEditSheet) {
                if let editingMode = viewModel.editingGameMode {
                    EditGameModeSheet(viewModel: viewModel, gameMode: editingMode)
                }
            }
            .refreshable {
                await viewModel.forceRefresh()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadGameModesIfNeeded()
            }
        }
        .alert("common_error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("common_ok") {
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

#Preview {
    GameModesView()
}