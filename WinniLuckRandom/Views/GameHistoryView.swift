import SwiftUI

struct GameHistoryView: View {
    @StateObject private var viewModel = GameHistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("history_title")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    toolbarContent
                }
                .searchable(text: $viewModel.searchText, prompt: "history_search_placeholder")
        }
        .task {
            // Load sessions on appear - simplified version
        }
        .onChange(of: viewModel.sortOrder) { _, _ in
            // Refresh when sort order changes - simplified version  
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
    
    @ViewBuilder
    private var contentView: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("history_loading")
                    .padding()
            } else if viewModel.gameSessions.isEmpty {
                emptyStateView
            } else {
                sessionsList
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
                            // Delete functionality - simplified version
                        }
                    }
            }
        }
        .refreshable {
            // Refresh functionality - simplified version
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

#Preview {
    GameHistoryView()
} 