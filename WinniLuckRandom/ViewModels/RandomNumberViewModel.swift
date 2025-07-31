//
//  RandomNumberViewModel.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI

class RandomNumberViewModel: ObservableObject {
    @Published var startNumber: String = "1"
    @Published var endNumber: String = "100"
    @Published var repetitions: String = "1"
    @Published var winnersCount: String = "3"
    @Published var currentNumber: Int = 0
    @Published var isGenerating: Bool = false
    @Published var currentRepetition: Int = 0
    @Published var totalRepetitions: Int = 0
    @Published var numbers: [Int] = []
    @Published var showingResult: Bool = false
    @Published var showingCongrats: Bool = false
    @Published var showingWinners: Bool = false
    @Published var showingCountdown = false // Add countdown state
    @Published var isNewGameStarting = false
    @Published var isCompletingRace = false
    @Published var gameIsReady = false // NEW: Signal when game is ready for timer
    @Published var totalNumbersToGenerate: Int = 0
    @Published var rangeSize: Int = 0
    @Published var currentGameMode: GameMode?
    @Published var currentGameSession: GameSession?
    @Published var currentPlayers: [Player] = []
    @Published var gameWinners: [WinnerData] = []
    @Published var confirmedNumbersCount: Int = 0 // NEW: Track actual announced numbers for progress bar
    @Published var numberCounts: [Int: Int] = [:] // Track current count for each number (shown on progress bar)
    private var pendingNumber: Int? = nil // Number waiting to be announced by voice
    
    // Debugging access
    var currentIndex: Int { _currentIndex }
    var generatedNumbers: [Int] { _generatedNumbers }
    
    // Private actual storage
    private var _currentIndex = 0
    private var _generatedNumbers: [Int] = []
    private var liveGameNumbers: [Int] = [] // Track numbers as they appear during live gameplay
    private var winnerOrder: [Int] = [] // Track order of numbers that reached target repetitions
    
    init() {
        print("🚀 RandomNumberViewModel INIT - showingResult: \(showingResult)")
        print("🚀 RandomNumberViewModel INIT - currentPlayers: \(currentPlayers.count)")
        print("🚀 RandomNumberViewModel INIT - currentGameMode: \(currentGameMode?.title ?? "nil")")
    }
    
    var inputsValid: Bool {
        guard let start = Int(startNumber),
              let end = Int(endNumber),
              let reps = Int(repetitions),
              let winners = Int(winnersCount),
              start <= end,
              reps > 0,
              winners > 0,
              winners <= (end - start + 1) else {
            return false
        }
        return true
    }
    
    var hasNextNumber: Bool {
        return _currentIndex < _generatedNumbers.count - 1
    }
    
    var progress: Double {
        guard totalRepetitions > 0 else { return 0.0 }
        return Double(currentRepetition) / Double(totalRepetitions)
    }
    
    var generationPreview: String {
        guard inputsValid,
              let start = Int(startNumber),
              let end = Int(endNumber),
              let reps = Int(repetitions),
              let winners = Int(winnersCount) else {
            return ""
        }
        
        let range = end - start + 1
        let total = range * reps
        return String(format: NSLocalizedString("generation_preview_with_winners", comment: "Range: %d numbers × %d repetitions = %d total numbers, %d winners"), range, reps, total, winners)
    }
    
    var finalNumbersWithCounts: [(number: Int, count: Int)] {
        guard let winners = Int(winnersCount) else { return [] }
        
        // Winners are numbers that reached the target repetition count, in order of achievement
        let winnerNumbers = Array(winnerOrder.prefix(winners))
        
        return winnerNumbers.map { number in
            let finalCount = numberCounts[number] ?? 0
            return (number: number, count: finalCount)
        }
    }
    
    func generateRandomNumbers() {
        print("🎮 GENERATE RANDOM NUMBERS CALLED")
        print("📊 Validation check:")
        print("  - Current players: \(currentPlayers.count)")
        print("  - Current game mode: \(currentGameMode?.title ?? "nil")")
        print("  - Old inputsValid: \(inputsValid)")
        
        // NEW: Use game mode validation instead of old input validation
        guard !currentPlayers.isEmpty, let gameMode = currentGameMode else {
            print("❌ ERROR: Missing players or game mode - cannot start countdown")
            return
        }
        
        print("✅ Game mode validation passed - showing countdown")
        // Show countdown first instead of immediately starting
        showingCountdown = true
    }
    
    func startGameAfterCountdown() {
        print("🚀🚀🚀 FUNCTION CALLED: startGameAfterCountdown() 🚀🚀🚀")
        print("🚀 STARTING GAME AFTER COUNTDOWN")
        print("📊 Current state check:")
        print("  - Current players: \(currentPlayers.count)")
        print("  - Current game mode: \(currentGameMode?.title ?? "nil")")
        print("  - Winners required: \(currentGameMode?.maxWinners ?? 0)")
        print("  - Repetitions required: \(currentGameMode?.repetitions ?? 0)")
        
        guard !currentPlayers.isEmpty, let gameMode = currentGameMode else {
            print("❌ ERROR: Missing players or game mode for generation")
            return
        }
        
        print("🎮 Initializing game generation...")
        isGenerating = true
        
        // Get the range of selected numbers from players
        let selectedNumbers = currentPlayers.compactMap { $0.selectedNumber }
        let start = selectedNumbers.min() ?? 1
        let end = selectedNumbers.max() ?? 10
        let reps = gameMode.repetitions
        
        print("📊 Game parameters:")
        print("  - Range: \(start) to \(end)")
        print("  - Repetitions: \(reps)")
        print("  - Players: \(currentPlayers.count)")
        
        // Clear any previous game state
        liveGameNumbers.removeAll()
        winnerOrder.removeAll()
        numberCounts.removeAll()
        gameWinners.removeAll()
        _currentIndex = 0
        currentNumber = 0
        pendingNumber = nil
        confirmedNumbersCount = 0
        isCompletingRace = false
        
        print("🧹 Cleared previous game state")
        
        // Calculate range size and total numbers to generate
        rangeSize = end - start + 1
        
        // Generate balanced numbers with fair distribution
        _generatedNumbers = generateBalancedNumbers(start: start, end: end, repetitions: reps)
        
        // IMPORTANT: Set totalRepetitions to actual generated count, not theoretical maximum
        totalNumbersToGenerate = _generatedNumbers.count
        totalRepetitions = _generatedNumbers.count
        currentRepetition = 0
        confirmedNumbersCount = 0
        
        print("🎯 Generated \(generatedNumbers.count) total calls")
        print("🎯 First 10 numbers: \(Array(generatedNumbers.prefix(10)))")
        print("🎯 Generated numbers array: \(generatedNumbers)")
        print("🎯 Selected numbers from players: \(selectedNumbers)")
        print("🎯 Range start: \(start), end: \(end)")
        
        // Check initial state before starting
        let requiredWinners = gameMode.maxWinners
        let targetReps = getTargetRepetitions()
        print("🎯 Target reps: \(targetReps), Required winners: \(requiredWinners)")
        
        let initialCheck = shouldStopGame()
        print("🚨 Initial shouldStopGame check: \(initialCheck)")
        
        if initialCheck {
            print("❌ CRITICAL: Game wants to stop IMMEDIATELY! This is a bug!")
            print("📊 Debug state:")
            print("  - winnerOrder: \(winnerOrder)")
            print("  - numberCounts: \(numberCounts)")
            print("  - currentRepetition: \(currentRepetition)")
            print("  - winnersAtFinishLine count: \(winnerOrder.filter { numberCounts[$0] ?? 0 >= targetReps }.count)")
        }
        
        // Show first number and set it as pending (will be tracked after voice speaks)
        if !_generatedNumbers.isEmpty {
            print("🎯 Setting first number from generatedNumbers[0]: \(_generatedNumbers[0])")
            currentNumber = _generatedNumbers[0]
            currentRepetition = 1
            
            // IMPORTANT: Set as pending instead of immediate tracking
            pendingNumber = currentNumber
            print("🔥 CRITICAL: pendingNumber set to \(pendingNumber ?? -999)")
            print("🔥 CRITICAL: currentNumber is \(currentNumber)")
            
            print("🎲 Starting with number: \(currentNumber)")
            print("🎲 Pending number: \(pendingNumber ?? -999)")
            print("🎲 hasNextNumber: \(hasNextNumber)")
            
            // Close countdown and show result
            showingCountdown = false
            showingResult = true
            
            // IMPORTANT: Signal that game is ready for timer to start
            gameIsReady = true
            print("✅ GAME READY - Timer can now start")
        } else {
            print("❌ CRITICAL ERROR: Generated numbers array is EMPTY!")
            print("❌ Debug info:")
            print("  - Start: \(start), End: \(end), Reps: \(reps)")
            print("  - Selected numbers: \(selectedNumbers)")
            print("  - Players: \(currentPlayers.map { "[\($0.firstName): \($0.selectedNumber ?? -1)]" })")
            gameIsReady = false
        }
        
        isGenerating = false
        print("🚀 GAME GENERATION COMPLETE")
    }
    
    func nextNumber() {
        print("🎯 nextNumber() CALLED")
        print("  - Current index: \(_currentIndex)")
        print("  - Generated numbers count: \(_generatedNumbers.count)")
        print("  - hasNextNumber: \(hasNextNumber)")
        
        guard hasNextNumber else {
            print("❌ No next number available - finalizing game")
            finalizeGame()
            return
        }
        
        _currentIndex += 1
        currentNumber = _generatedNumbers[_currentIndex]
        currentRepetition = _currentIndex + 1
        
        print("  - NEW current index: \(_currentIndex)")
        print("  - NEW current number: \(currentNumber)")
        print("  - NEW current repetition: \(currentRepetition)")
        
        // IMPORTANT: Don't track immediately - wait for voice confirmation
        pendingNumber = currentNumber
        print("🎯 Number \(currentNumber) is now PENDING voice announcement")
        
        // Note: trackLiveNumber() will be called AFTER voice speaks via confirmPendingNumber()
    }
    
    // Call this function AFTER the voice has spoken the number
    func confirmPendingNumber() {
        print("🔥 Confirming number: \(currentNumber)")
        print("🔥 Confirmed count: \(confirmedNumbersCount) -> \(confirmedNumbersCount + 1)")
        
        // ALWAYS use currentNumber - this is the number that should be confirmed
        let numberToConfirm = currentNumber
        
        guard numberToConfirm > 0 else { 
            print("⚠️ ERROR: No valid number to confirm (currentNumber is 0)")
            return 
        }
        
        // Clear pendingNumber since we're confirming currentNumber
        if pendingNumber != nil && pendingNumber != currentNumber {
            print("⚠️ WARNING: pendingNumber (\(pendingNumber!)) differs from currentNumber (\(currentNumber))")
        }
        
        // Increment confirmed numbers count for progress bar
        confirmedNumbersCount += 1
        
        // Now track the number on progress bar since voice has announced it
        trackLiveNumber(numberToConfirm)
        pendingNumber = nil
        
        print("✅ Number \(numberToConfirm) confirmed (\(confirmedNumbersCount)/\(totalRepetitions))")
    }
    
    func reset() {
        print("🔥 RESET() CALLED - clearing pendingNumber!")
        // Stop any ongoing processes first
        isGenerating = false
        isCompletingRace = false
        
        // Clear all game data
        _generatedNumbers.removeAll()
        liveGameNumbers.removeAll()
        winnerOrder.removeAll()
        numberCounts.removeAll()
        gameWinners.removeAll()
        _currentIndex = 0
        currentNumber = 0
        pendingNumber = nil // This might be clearing it inappropriately!
        confirmedNumbersCount = 0
        currentRepetition = 0
        totalRepetitions = 0
        totalNumbersToGenerate = 0
        rangeSize = 0
        
        // Reset all UI states
        showingResult = false
        showingCongrats = false
        showingWinners = false
        showingCountdown = false
        isNewGameStarting = false
        gameIsReady = false // Reset timer ready state
        
        // Clear game session data but keep players for potential restart
        
        print("🔄 Game state completely reset")
    }
    
    func hardReset() {
        // Complete reset including players and game session
        reset()
        currentPlayers.removeAll()
        currentGameMode = nil
        currentGameSession = nil
        
        print("🔄 Complete hard reset performed")
    }
    
    func goHome() {
        reset()
    }
    
    // MARK: - Public Helper Methods
    
    func getTargetRepetitions() -> Int {
        return currentGameMode?.repetitions ?? Int(repetitions) ?? 1
    }
    
    func setPendingNumber(_ number: Int) {
        pendingNumber = number
        print("🔥 setPendingNumber called with \(number) - pendingNumber is now: \(pendingNumber ?? -999)")
    }
    
    // MARK: - Private Helper Methods
    
    private func generateBalancedNumbers(start: Int, end: Int, repetitions: Int) -> [Int] {
        print("🔢 generateBalancedNumbers() CALLED")
        print("  - Start: \(start), End: \(end), Repetitions: \(repetitions)")
        
        let range = Array(start...end)
        let requiredWinners = currentGameMode?.maxWinners ?? Int(winnersCount) ?? 1
        
        print("  - Range: \(range)")
        print("  - Required winners: \(requiredWinners)")
        
        // Calculate total calls needed
        let totalCallsNeeded = range.count * repetitions
        print("  - Total calls needed: \(totalCallsNeeded)")
        
        // Prepare arrays for different phases
        var allNumbers: [Int] = []
        
        // Choose winners randomly
        let winners = Array(range.shuffled().prefix(requiredWinners))
        let nonWinners = range.filter { !winners.contains($0) }
        
        print("  - Winners: \(winners)")
        print("  - Non-winners: \(nonWinners)")
        
        // PHASE 1: Introduction round - all numbers appear once
        let introductionRound = range.shuffled()
        allNumbers.append(contentsOf: introductionRound)
        print("  - Introduction round: \(introductionRound)")
        
        // PHASE 2: Competition round
        var competitionNumbers: [Int] = []
        
        // Winners get additional calls to reach target repetitions
        for winner in winners {
            let additionalCalls = repetitions - 1 // -1 because they already appeared once in introduction
            for _ in 0..<additionalCalls {
                competitionNumbers.append(winner)
            }
        }
        
        // Non-winners get limited additional calls (but not enough to win)
        let maxCallsForNonWinners = max(0, repetitions - 2)  // Ensure they can't accidentally win
        let remainingCalls = totalCallsNeeded - allNumbers.count - competitionNumbers.count
        
        print("  - Competition numbers for winners: \(competitionNumbers)")
        print("  - Max calls for non-winners: \(maxCallsForNonWinners)")
        print("  - Remaining calls: \(remainingCalls)")
        
        if remainingCalls > 0 && maxCallsForNonWinners > 0 {
            for _ in 0..<remainingCalls {
                if let randomNonWinner = nonWinners.randomElement() {
                    competitionNumbers.append(randomNonWinner)
                }
            }
        }
        
        // Shuffle competition numbers and add basic duplicate prevention
        competitionNumbers.shuffle()
        
        // Basic consecutive duplicate removal
        for i in 1..<competitionNumbers.count {
            if competitionNumbers[i] == competitionNumbers[i-1] {
                // Try to swap with a different number nearby
                for j in stride(from: i+1, to: min(i+5, competitionNumbers.count), by: 1) {
                    if competitionNumbers[j] != competitionNumbers[i] {
                        competitionNumbers.swapAt(i, j)
                        break
                    }
                }
            }
        }
        
        allNumbers.append(contentsOf: competitionNumbers)
        
        print("  - Final sequence length: \(allNumbers.count)")
        print("  - Final sequence preview: \(Array(allNumbers.prefix(20)))")
        
        return allNumbers
    }
    
    private func trackLiveNumber(_ number: Int) {
        let targetReps = getTargetRepetitions()
        let currentCount = numberCounts[number, default: 0]
        
        if currentCount >= targetReps { 
            print("📊 Number \(number) already at target - skipping")
            return 
        }
        
        numberCounts[number] = currentCount + 1
        let newCount = numberCounts[number]!
        print("📊 Number \(number): \(currentCount) -> \(newCount)/\(targetReps)")
        
        // Track in order for position calculation
        if !liveGameNumbers.contains(number) {
            liveGameNumbers.append(number)
        }
        
        // Check if this number has reached the target and becomes a winner
        if newCount >= targetReps {
            if !winnerOrder.contains(number) {
                winnerOrder.append(number)
                print("🏆 NEW WINNER! Number \(number) reached finish line! (\(winnerOrder.count) total winners)")
            }
        }
    }
    
    func shouldStopGame() -> Bool {
        // Get the required number of winners from the game mode
        let requiredWinners = currentGameMode?.maxWinners ?? Int(winnersCount) ?? 1
        let targetReps = getTargetRepetitions()
        
        // Check if we have enough winners who have reached the finish line (target repetitions)
        let winnersAtFinishLine = winnerOrder.filter { number in
            let count = numberCounts[number] ?? 0
            return count >= targetReps
        }
        
        print("🏁 Game check: \(winnersAtFinishLine.count)/\(requiredWinners) winners at finish line")
        
        // PRIMARY CONDITION: Stop ONLY when we have EXACTLY the required number of winners
        if winnersAtFinishLine.count >= requiredWinners {
            isCompletingRace = true
            print("🏁 GAME OVER: All \(requiredWinners) required winners achieved!")
            return true
        }
        
        // SAFETY CONDITION: Only check sequence completion in extreme cases
        if currentRepetition > 0 {
            let hasUsedAllNumbers = _currentIndex >= _generatedNumbers.count - 1
            if hasUsedAllNumbers {
                print("⚠️ SEQUENCE COMPLETE: Only \(winnersAtFinishLine.count)/\(requiredWinners) winners achieved")
                
                if winnersAtFinishLine.count > 0 {
                    isCompletingRace = true
                    return true
                } else {
                    return false
                }
            }
        }
        
        return false
    }

    
    func finalizeGame() {
        print("🎉 GAME FINALIZED - \(winnerOrder.count) winners achieved")
        
        // Generate winner data
        gameWinners = generateWinnerData()
        
        // Save the completed game session with final results
        saveCompletedGameSession()
        
        // Show winners screen
        showingWinners = true
        showingCongrats = false
    }
    
    private func saveCompletedGameSession() {
        guard let gameMode = currentGameMode else {
            print("❌ Cannot save game session: No game mode")
            return
        }
        
        // Get final winning numbers and winner player IDs
        let requiredWinners = gameMode.maxWinners
        let finalWinningNumbers = Array(winnerOrder.prefix(requiredWinners))
        let winnerPlayerIDs = finalWinningNumbers.compactMap { number in
            currentPlayers.first(where: { $0.selectedNumber == number })?.id
        }
        
        // Calculate final financial data
        let playerCount = currentPlayers.count
        let grossIncome = gameMode.calculateGross(for: playerCount)
        let actualWinners = winnerPlayerIDs.count
        let payout = gameMode.calculatePayout(for: actualWinners)
        let profit = gameMode.calculateProfit(for: playerCount, winners: actualWinners)
        
        // Create the final game session with complete data
        let completedSession = GameSession(
            id: currentGameSession?.id ?? UUID(), // Preserve original ID if exists
            modeID: gameMode.id,
            startRange: 1,
            endRange: gameMode.maxPlayers,
            repetitions: gameMode.repetitions,
            numWinners: actualWinners,
            playerIDs: currentPlayers.map { $0.id },
            winningNumbers: finalWinningNumbers,
            winnerIDs: winnerPlayerIDs,
            date: currentGameSession?.date ?? Date(), // Preserve original date
            grossIncome: grossIncome,
            profit: profit,
            payout: payout
        )
        
        // Save to storage
        Task {
            let success = await StorageManager.shared.saveGameSession(completedSession)
            if success {
                print("✅ Game session saved successfully: \(completedSession.id)")
                print("📊 Final results: \(actualWinners) winners, profit: \(profit), gross: \(grossIncome)")
            } else {
                print("❌ Failed to save game session")
            }
        }
    }
    
    func generateWinnerData() -> [WinnerData] {
        let requiredWinners = currentGameMode?.maxWinners ?? Int(winnersCount) ?? 1
        let winnerNumbers = Array(winnerOrder.prefix(requiredWinners))
        
        return winnerNumbers.compactMap { number in
            // Find the player with this number
            if let player = currentPlayers.first(where: { $0.selectedNumber == number }) {
                let finalCount = numberCounts[number] ?? 0
                return WinnerData(
                    player: player,
                    number: number,
                    finalCount: finalCount
                )
            }
            return nil
        }
    }
    
    func startNewGame() {
        // Reset game state but keep current players
        let playersToKeep = currentPlayers
        reset()
        currentPlayers = playersToKeep
        
        // Generate new numbers
        generateRandomNumbers()
    }
} 