import SwiftUI
import UIKit

struct GameHistoryView: View {
    @StateObject private var viewModel = GameHistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
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
                gameHistoryHeader
                
                // Content
                ScrollView {
                    VStack(spacing: UIDevice.isIPad ? 30 : 20) {
                        contentView
                    }
                    .padding(.horizontal, UIDevice.isIPad ? 40 : 20)
                    .padding(.top, UIDevice.isIPad ? 30 : 20)
                    .padding(.bottom, UIDevice.isIPad ? 120 : 100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            print("🔍 GameHistoryView: Task started, loading game sessions...")
            viewModel.loadGameSessions()
        }
        .onAppear {
            print("🔍 GameHistoryView: View appeared")
            print("🔍 GameHistoryView: Current state - Loading: \(viewModel.isLoading), Sessions count: \(viewModel.gameSessions.count)")
        }
        .onChange(of: viewModel.sortOrder) { _, _ in
            viewModel.loadGameSessions()
        }
        .alert("history_error_title", isPresented: .constant(viewModel.error != nil)) {
            Button("common_ok") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Game History Header
    
    private var gameHistoryHeader: some View {
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
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16))
                    
                    TextField("Buscar juegos...", text: $viewModel.searchText)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .frame(maxWidth: 200)
            }
            .padding(.horizontal, UIDevice.isIPad ? 40 : 20)
            .padding(.top, UIDevice.isIPad ? 15 : 10)
            
            HStack {
                VStack(alignment: .leading, spacing: UIDevice.isIPad ? 8 : 4) {
                    Text("Historial de Juegos")
                        .font(UIDevice.isIPad ? .system(size: 48, weight: .bold) : .largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Todos tus juegos completados")
                        .font(UIDevice.isIPad ? .title3 : .subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Game count
                if !viewModel.gameSessions.isEmpty {
                    Text("\(viewModel.gameSessions.count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, UIDevice.isIPad ? 40 : 20)
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
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            modernLoadingView
        } else if viewModel.gameSessions.isEmpty {
            modernEmptyStateView
        } else {
            modernSessionsList
        }
    }
    
    private var modernLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Cargando historial...")
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
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No hay juegos en el historial")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Los juegos completados aparecerán aquí")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Debug info and manual reload button
            VStack(spacing: 12) {
                Text("Debug: Loading=\(viewModel.isLoading ? "Yes" : "No"), Count=\(viewModel.gameSessions.count)")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Button("Recargar Datos") {
                    print("🔄 Manual reload triggered")
                    viewModel.loadGameSessions()
                }
                
                Button("Generar Datos de Prueba") {
                    print("🧪 Generating test data...")
                    viewModel.generateTestData()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green.opacity(0.5), lineWidth: 1)
                        )
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
    
    @ViewBuilder
    private var modernSessionsList: some View {
        // Use grid layout on iPad, vertical stack on iPhone
        if UIDevice.isIPad {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
                spacing: 16
            ) {
                ForEach(viewModel.gameSessions) { session in
                    ModernHistoryGameSessionCard(session: session, onDelete: {
                        viewModel.deleteGameSession(session)
                    })
                }
            }
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.gameSessions) { session in
                    ModernHistoryGameSessionCard(session: session, onDelete: {
                        viewModel.deleteGameSession(session)
                    })
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("history_no_sessions")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("history_no_sessions_description")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    @ViewBuilder
    private var sessionsList: some View {
        List {
            ForEach(viewModel.filteredSessions) { session in
                GameSessionRow(session: session)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("common_delete", role: .destructive) {
                            viewModel.deleteGameSession(session)
                        }
                    }
            }
        }
        .refreshable {
            viewModel.loadGameSessions()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("common_close") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Picker("history_sort_by", selection: $viewModel.sortOrder) {
                    ForEach(GameHistoryViewModel.SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
    }
}

struct GameSessionRow: View {
    let session: GameSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session \(session.id.uuidString.prefix(8))")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(session.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(session.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(session.grossIncome))
                        .font(.headline)
                        .foregroundColor(.green)
                        .bold()
                    
                    Text("history_profit")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(session.profit))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Label("\(session.playerIDs.count)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(session.winnerIDs.count)", systemImage: "trophy")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Label("S/. \(String(format: "%.2f", NSDecimalNumber(decimal: session.payout).doubleValue))", systemImage: "banknote")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PEN"
        formatter.currencySymbol = "S/."
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "S/. 0.00"
    }
}

// MARK: - Modern History Game Session Card

struct ModernHistoryGameSessionCard: View {
    let session: GameSession
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getGameModeTitle())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(formatDateTime(session.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Delete button
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
            
            // Game details
            HStack(spacing: 16) {
                HistoryDetailPill(
                    icon: "person.3.fill",
                    title: "Jugadores",
                    value: "\(session.playerIDs.count)",
                    color: .blue
                )
                
                HistoryDetailPill(
                    icon: "trophy.fill",
                    title: "Ganadores",
                    value: "\(session.winnerIDs.count)",
                    color: .orange
                )
            }
            
            // Financial summary
            HStack(spacing: 16) {
                HistoryFinancialPill(
                    title: "Ingreso",
                    amount: session.grossIncome,
                    color: .cyan
                )
                
                HistoryFinancialPill(
                    title: "Premio",
                    amount: session.payout,
                    color: .purple
                )
                
                HistoryFinancialPill(
                    title: "Ganancia",
                    amount: session.profit,
                    color: .green
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
    
    private func getGameModeTitle() -> String {
        // You could implement game mode lookup here
        return "Juego de Suerte"
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

// MARK: - History Detail Pill

struct HistoryDetailPill: View {
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
        .frame(minWidth: 80)
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

// MARK: - History Financial Pill

struct HistoryFinancialPill: View {
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
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(minWidth: 90)
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
    GameHistoryView()
} 