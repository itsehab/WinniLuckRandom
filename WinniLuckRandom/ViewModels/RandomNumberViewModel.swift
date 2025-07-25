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
    @Published var totalNumbersToGenerate: Int = 0
    @Published var rangeSize: Int = 0
    @Published var currentGameMode: GameMode?
    @Published var currentGameSession: GameSession?
    @Published var currentPlayers: [Player] = []
    @Published var isNewGameStarting: Bool = false
    @Published var gameWinners: [WinnerData] = []
    @Published var showingWinners: Bool = false
    @Published var isCompletingRace: Bool = false
    
    private var generatedNumbers: [Int] = []
    private var currentIndex: Int = 0
    private var liveGameNumbers: [Int] = [] // Track numbers as they appear during live gameplay
    private var winnerOrder: [Int] = [] // Track order of numbers that reached target repetitions
    @Published var numberCounts: [Int: Int] = [:] // Track current count for each number
    
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
        currentIndex < generatedNumbers.count - 1
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
    
    var numberStatistics: [(number: Int, count: Int)] {
        guard let winners = Int(winnersCount) else { return [] }
        
        // Use repetitions from current game mode if available, otherwise fall back to input field
        let targetReps = currentGameMode?.repetitions ?? Int(repetitions) ?? 1
        
        // Winners are numbers that reached the target repetition count, in order of achievement
        let winnerNumbers = Array(winnerOrder.prefix(winners))
        
        return winnerNumbers.map { number in
            let finalCount = numberCounts[number] ?? 0
            return (number: number, count: finalCount)
        }
    }
    
    func generateRandomNumbers() {
        guard inputsValid else { return }
        
        guard let start = Int(startNumber),
              let end = Int(endNumber) else {
            return
        }
        
        // Use repetitions from current game mode if available, otherwise fall back to input field
        let reps = currentGameMode?.repetitions ?? Int(repetitions) ?? 1
        
        isGenerating = true
        generatedNumbers.removeAll()
        liveGameNumbers.removeAll()
        winnerOrder.removeAll()
        numberCounts.removeAll()
        currentIndex = 0
        
        // Calculate range size and total numbers to generate
        rangeSize = end - start + 1
        totalNumbersToGenerate = rangeSize * reps
        totalRepetitions = totalNumbersToGenerate
        currentRepetition = 0
        
        // Generate balanced numbers with fair distribution
        generatedNumbers = generateBalancedNumbers(start: start, end: end, repetitions: reps)
        
        // Show first number and track it in live game
        if !generatedNumbers.isEmpty {
            currentNumber = generatedNumbers[0]
            currentRepetition = 1
            
            // Track first number in live game
            trackLiveNumber(currentNumber)
            
            // Only set showingResult = true if we're not already in a game session
            // This prevents navigation conflicts when starting a new game from ResultView
            if !showingResult {
                showingResult = true
            } else {
                // If we're already in ResultView, signal that a new game is starting
                isNewGameStarting = true
            }
        }
        
        isGenerating = false
    }
    
    func nextNumber() {
        guard hasNextNumber else {
            finalizeGame()
            return
        }
        
        currentIndex += 1
        currentNumber = generatedNumbers[currentIndex]
        currentRepetition = currentIndex + 1
        
        // Track this number in the live game
        trackLiveNumber(currentNumber)
        
        // Note: shouldStopGame() check is now handled in ResultView AFTER the number is displayed
    }
    
    func reset() {
        generatedNumbers.removeAll()
        liveGameNumbers.removeAll()
        winnerOrder.removeAll()
        numberCounts.removeAll()
        currentIndex = 0
        currentNumber = 0
        currentRepetition = 0
        totalRepetitions = 0
        totalNumbersToGenerate = 0
        rangeSize = 0
        showingResult = false
        showingCongrats = false
        showingWinners = false
        isGenerating = false
        isNewGameStarting = false
        isCompletingRace = false
        currentPlayers.removeAll()
        gameWinners.removeAll()
    }
    
    func goHome() {
        reset()
    }
    
    // MARK: - Private Helper Methods
    
    private func generateBalancedNumbers(start: Int, end: Int, repetitions: Int) -> [Int] {
        var numbers: [Int] = []
        
        // Create exactly the right number of each value
        for number in start...end {
            for _ in 0..<repetitions {
                numbers.append(number)
            }
        }
        
        // Shuffle to randomize order
        numbers.shuffle()
        
        // Ensure no consecutive duplicates
        return removeConsecutiveDuplicates(from: numbers)
    }
    
    private func removeConsecutiveDuplicates(from numbers: [Int]) -> [Int] {
        guard numbers.count > 1 else { return numbers }
        
        var result = numbers
        var attempts = 0
        let maxAttempts = 100 // Prevent infinite loops
        
        while hasConsecutiveDuplicates(result) && attempts < maxAttempts {
            // Find first consecutive duplicate
            for i in 0..<result.count - 1 {
                if result[i] == result[i + 1] {
                    // Try to swap with a different number
                    if let swapIndex = findSwapIndex(for: i, in: result) {
                        result.swapAt(i + 1, swapIndex)
                        break
                    }
                }
            }
            attempts += 1
        }
        
        return result
    }
    
    private func hasConsecutiveDuplicates(_ numbers: [Int]) -> Bool {
        for i in 0..<numbers.count - 1 {
            if numbers[i] == numbers[i + 1] {
                return true
            }
        }
        return false
    }
    
    private func findSwapIndex(for position: Int, in numbers: [Int]) -> Int? {
        let duplicateValue = numbers[position]
        
        // Look for a position to swap that won't create new consecutive duplicates
        for i in 0..<numbers.count {
            if i == position || i == position + 1 { continue }
            
            // Check if swapping would create new consecutive duplicates
            let wouldCreateNewDuplicate = 
                (i > 0 && numbers[i - 1] == duplicateValue) ||
                (i < numbers.count - 1 && numbers[i + 1] == duplicateValue)
            
            if !wouldCreateNewDuplicate && numbers[i] != duplicateValue {
                return i
            }
        }
        
        return nil
    }
    
    private func trackLiveNumber(_ number: Int) {
        // Use repetitions from current game mode if available, otherwise fall back to input field
        let targetReps = currentGameMode?.repetitions ?? Int(repetitions) ?? 1
        
        // Always add to live game numbers
        liveGameNumbers.append(number)
        
        // Update count for this number
        numberCounts[number, default: 0] += 1
        
        // Check if this number just reached the target repetition count
        if numberCounts[number] == targetReps {
            // This number becomes a winner if it's not already in the winner list
            if !winnerOrder.contains(number) {
                winnerOrder.append(number)
            }
        }
    }
    
    func shouldStopGame() -> Bool {
        // Get the required number of winners from the game mode
        let requiredWinners = currentGameMode?.maxWinners ?? Int(winnersCount) ?? 1
        let targetReps = currentGameMode?.repetitions ?? Int(repetitions) ?? 1
        
        // Check if we have enough winners who have reached the finish line (target repetitions)
        let winnersAtFinishLine = winnerOrder.filter { number in
            numberCounts[number] ?? 0 >= targetReps
        }
        
        // Stop the game immediately when we have enough winners at the finish line
        if winnersAtFinishLine.count >= requiredWinners {
            isCompletingRace = true
            return true
        }
        
        return false
    }

    
    func finalizeGame() {
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