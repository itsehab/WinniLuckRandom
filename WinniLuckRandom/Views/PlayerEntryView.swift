//
//  PlayerEntryView.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI

// MARK: - Int Identifiable Extension
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

struct PlayerEntryView: View {
    let gameMode: GameMode
    let onGameStart: ([Player]) -> Void
    
    @StateObject private var viewModel: PlayerEntryViewModel
    @StateObject private var settings = SettingsModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedNumberForInput: Int?
    @State private var newPlayerName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(gameMode: GameMode, onGameStart: @escaping ([Player]) -> Void) {
        self.gameMode = gameMode
        self.onGameStart = onGameStart
        self._viewModel = StateObject(wrappedValue: PlayerEntryViewModel(gameMode: gameMode))
    }
    
    var body: some View {
        ZStack {
            // Background
            BackgroundView(image: settings.backgroundImage)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content with fixed bottom button
                ZStack {
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Game mode info - more compact
                            compactGameModeCard
                                .padding(.top, 16)
                            
                            // Numbers grid
                            numbersGridSection
                            
                            // Bottom spacing for potential button
                            Color.clear
                                .frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Fixed start game button at bottom
                    VStack {
                        Spacer()
                        fixedStartGameButton
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(item: Binding<Int?>(
            get: { selectedNumberForInput },
            set: { selectedNumberForInput = $0 }
        )) { number in
            playerNameInputSheet(for: number)
        }
        .onDisappear {
            // Clear focus when view disappears to prevent keyboard issues
            isTextFieldFocused = false
            newPlayerName = "" // Reset the text field
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                dismissKeyboard()
                isTextFieldFocused = false
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(
                        size: UIDevice.isIPad ? 26 : 20, 
                        weight: .semibold
                    ))
                    .foregroundColor(.white)
                    .frame(
                        width: AdaptiveSize.minimumTouchTarget(), 
                        height: AdaptiveSize.minimumTouchTarget()
                    )
            }
            
            Spacer()
            
            // Title - now shows game mode name
            Text(viewModel.selectedGameMode.title)
                .font(UIDevice.isIPad ? .largeTitle : .title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 2)
            
            Spacer()
            
            // Player count indicator
            Text("\(viewModel.players.count)/\(gameMode.maxPlayers)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.6))
                )
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .padding(.bottom, 16)
    }
    
    // MARK: - Numbers Grid Section
    private var numbersGridSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Números Disponibles")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                Text("Asignados: \(viewModel.players.count)")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.6))
                    )
            }
            
            // Test generation buttons for easy testing
            testGenerationButtons
            
            let columnCount = UIDevice.isIPad ? 
                (UIScreen.screenWidth > 1000 ? 8 : 6) : 5
            let spacing: CGFloat = UIDevice.isIPad ? 16 : 12
            let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
            
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(1...gameMode.maxPlayers, id: \.self) { number in
                    NumberAssignmentCard(
                        number: number,
                        player: getPlayerForNumber(number),
                        onTap: {
                            numberTapped(number)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Test Generation Buttons
    private var testGenerationButtons: some View {
        HStack(spacing: 12) {
            // Generate test players button
            Button(action: {
                viewModel.generateTestPlayers()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                    Text("Generar Jugadores de Prueba")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.8), lineWidth: 1)
                )
            }
            .disabled(viewModel.remainingSlots == 0)
            .opacity(viewModel.remainingSlots == 0 ? 0.5 : 1.0)
            
            // Generate fewer test players button (for quick testing)
            Button(action: {
                viewModel.generateTestPlayers(count: min(5, viewModel.remainingSlots))
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("5")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyan.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.cyan.opacity(0.8), lineWidth: 1)
                )
            }
            .disabled(viewModel.remainingSlots == 0)
            .opacity(viewModel.remainingSlots == 0 ? 0.5 : 1.0)
            
            Spacer()
            
            // Clear all players button
            if !viewModel.players.isEmpty {
                Button(action: {
                    viewModel.clearAllTestData()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                        Text("Limpiar Todo")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.8), lineWidth: 1)
                )
                }
            }
        }
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.3), value: viewModel.players.isEmpty)
    }
    
    // MARK: - Game Mode Card
    private var compactGameModeCard: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Modo de Juego")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(gameMode.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Entrada")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(gameMode.formattedEntryPrice)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                }
            }
            
            HStack(spacing: 16) {
                InfoPill(
                    icon: "person.3.fill",
                    text: "\(gameMode.maxPlayers) jugadores",
                    color: .blue
                )
                
                InfoPill(
                    icon: "trophy.fill",
                    text: "\(gameMode.maxWinners) ganador\(gameMode.maxWinners > 1 ? "es" : "")",
                    color: .orange
                )
                
                InfoPill(
                    icon: "repeat",
                    text: "\(gameMode.repetitions)x",
                    color: .green
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
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
        )
    }
    
    // MARK: - Player Name Input Sheet
    private func playerNameInputSheet(for number: Int) -> some View {
        ZStack {
            // Background gradient matching main screen
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
                modalHeaderView
                
                // Content
                VStack(spacing: 24) {
                    // Number display with beautiful styling
                    modalNumberDisplayView(number: number)
                    
                    // Name input section
                    modalNameInputView(number: number)
                    
                    Spacer()
                    
                    // Action buttons
                    modalActionButtonsView(number: number)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled(false)
        .onAppear {
            // Initialize with existing player name if any
            if let existingPlayer = getPlayerForNumber(number) {
                newPlayerName = existingPlayer.firstName
            } else {
                newPlayerName = ""
            }
            
            // Force keyboard appearance with multiple strategies
            DispatchQueue.main.async {
                isTextFieldFocused = true
            }
        }
        .task {
            // Additional attempt using task modifier which runs after view appears
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                isTextFieldFocused = true
            }
            
            // Final attempt after longer delay
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds  
            await MainActor.run {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Modal Header
    private var modalHeaderView: some View {
        HStack {
            Button(action: closePlayerInputSheet) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 32, height: 32)
                    )
            }
            
            Spacer()
            
            Text("Asignar Jugador")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            Spacer()
            
            // Balance space
            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Modal Number Display
    private func modalNumberDisplayView(number: Int) -> some View {
        VStack(spacing: 16) {
            // Large number circle with golden gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .yellow.opacity(0.6), radius: 8, x: 0, y: 4)
                
                Text("\(number)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            // Current player info (if exists)
            if let existingPlayer = getPlayerForNumber(number) {
                VStack(spacing: 4) {
                    Text("Jugador Actual")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(existingPlayer.firstName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.3))
                        )
                }
            }
        }
    }
    
    // MARK: - Modal Name Input
    private func modalNameInputView(number: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nombre del Jugador")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ZStack(alignment: .leading) {
                // Custom placeholder text
                if newPlayerName.isEmpty {
                    Text("Ingresa el nombre...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
                
                TextField("", text: $newPlayerName)
                    .font(.body)
                    .foregroundColor(.white)
                    .tint(.white.opacity(0.8)) // Cursor color
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .focused($isTextFieldFocused) // Focus applied directly to TextField
                    .keyboardType(.default)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .onSubmit {
                        if !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            assignPlayerToNumber(number)
                        }
                    }
                    .onTapGesture {
                        // Force focus when tapped
                        isTextFieldFocused = true
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Modal Action Buttons
    private func modalActionButtonsView(number: Int) -> some View {
        VStack(spacing: 12) {
            // Assign/Update button
            if !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: { assignPlayerToNumber(number) }) {
                    HStack(spacing: 8) {
                        Image(systemName: getPlayerForNumber(number) != nil ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text(getPlayerForNumber(number) != nil ? "Actualizar Jugador" : "Asignar Jugador")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, Color(red: 0.0, green: 0.7, blue: 0.3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            
            // Remove button (if player exists)
            if getPlayerForNumber(number) != nil {
                Button(action: { removePlayerFromNumber(number) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Quitar Jugador")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, Color(red: 0.8, green: 0.2, blue: 0.2)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .red.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - Fixed Start Game Button
    private var fixedStartGameButton: some View {
        VStack {
            Spacer()
            
            // Show button only when ALL players are assigned to numbers
            if viewModel.players.count == gameMode.maxPlayers {
                Button(action: {
                    startGame()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(UIDevice.isIPad ? .title2 : .body)
                        
                        Text("Empezar (\(viewModel.players.count) jugadores)")
                            .foregroundColor(.white)
                            .font(UIDevice.isIPad ? .title2 : .headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: UIDevice.isIPad ? 500 : .infinity) // Limit width on iPad like home page
                    .frame(height: AdaptiveSize.buttonHeight())
                    .background(startButtonBackground)
                    .cornerRadius(16)
                }
                .frame(maxWidth: .infinity) // Center the constrained button
                .adaptivePadding(iPadPadding: 32, iPhonePadding: 16)
                .padding(.bottom, UIDevice.isIPad ? 44 : 34) // Safe area bottom
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom)
                        .combined(with: .scale(scale: 0.8))
                        .combined(with: .opacity),
                    removal: .move(edge: .bottom)
                        .combined(with: .scale(scale: 0.8))
                        .combined(with: .opacity)
                ))
            }
        }
        .animation(.easeOut(duration: 0.4), value: viewModel.players.count == gameMode.maxPlayers)
    }
    
    // MARK: - Start Button Background
    private var startButtonBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [.green, Color(red: 0.0, green: 0.7, blue: 0.3)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Actions
    private func numberTapped(_ number: Int) {
        selectedNumberForInput = number
    }
    
    private func assignPlayerToNumber(_ number: Int) {
        
        let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Remove existing player if any
        if let existingPlayer = getPlayerForNumber(number) {
            viewModel.removePlayer(existingPlayer)
        }
        
        // Create new player with selected number
        let player = Player(firstName: trimmedName, selectedNumber: number)
        viewModel.addPlayer(player)
        
        closePlayerInputSheet()
    }
    
    private func removePlayerFromNumber(_ number: Int) {
        guard let player = getPlayerForNumber(number) else { return }
        
        viewModel.removePlayer(player)
        closePlayerInputSheet()
    }
    
    private func closePlayerInputSheet() {
        selectedNumberForInput = nil
        newPlayerName = ""
        isTextFieldFocused = false
    }
    
    private func getPlayerForNumber(_ number: Int) -> Player? {
        return viewModel.players.first { $0.selectedNumber == number }
    }
    
    private func startGame() {
        guard viewModel.players.count == gameMode.maxPlayers else {
            showError("Todos los números deben tener jugadores asignados para empezar")
            return
        }
        
        // Dismiss keyboard and clear focus
        dismissKeyboard()
        isTextFieldFocused = false
        
        // Add small delay to ensure keyboard is properly dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
            onGameStart(viewModel.players)
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Number Assignment Card
struct NumberAssignmentCard: View {
    let number: Int
    let player: Player?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Number circle
                ZStack {
                    let circleSize: CGFloat = UIDevice.isIPad ? 65 : 50
                    
                    Circle()
                        .fill(numberBackgroundGradient)
                        .frame(width: circleSize, height: circleSize)
                        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                    
                    Circle()
                        .stroke(borderColor, lineWidth: 2)
                        .frame(width: circleSize, height: circleSize)
                    
                    Text("\(number)")
                        .font(.system(
                            size: UIDevice.isIPad ? 24 : 18, 
                            weight: .bold, 
                            design: .rounded
                        ))
                        .foregroundColor(.white)
                }
                
                // Player info (name and avatar if assigned)
                if let player = player {
                    VStack(spacing: 6) {
                        // Player name
                        Text(player.firstName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Player avatar
                        AvatarImageView(
                            avatarURL: player.avatarURL,
                            size: UIDevice.isIPad ? 45 : 35
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.yellow.opacity(0.8), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                } else {
                    // Available placeholder
                    VStack(spacing: 6) {
                        Text("Disponible")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        // Placeholder for avatar space
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(
                                width: UIDevice.isIPad ? 45 : 35, 
                                height: UIDevice.isIPad ? 45 : 35
                            )
                            .overlay(
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }
                }
            }
            .frame(height: UIDevice.isIPad ? 150 : 120)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var isAssigned: Bool {
        player != nil
    }
    
    private var numberBackgroundGradient: LinearGradient {
        if isAssigned {
            return LinearGradient(
                gradient: Gradient(colors: [.yellow, .orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var cardBackgroundGradient: LinearGradient {
        if isAssigned {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.3),
                    Color.green.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var borderColor: Color {
        isAssigned ? Color.yellow : Color.gray.opacity(0.4)
    }
    
    private var shadowColor: Color {
        isAssigned ? Color.orange.opacity(0.6) : Color.black.opacity(0.3)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Info Pill
struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

 