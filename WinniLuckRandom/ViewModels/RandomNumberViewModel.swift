//
//  RandomNumberViewModel.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI

@MainActor
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
    @Published var gameIsReady = false
    @Published var totalNumbersToGenerate: Int = 0
    @Published var rangeSize: Int = 0
    @Published var currentGameMode: GameMode?
    @Published var currentGameSession: GameSession?
    @Published var currentPlayers: [Player] = []
    @Published var gameWinners: [WinnerData] = []
    @Published var confirmedNumbersCount: Int = 0 // Track actual announced numbers for progress bar
    @Published var numberCounts: [Int: Int] = [:] // Track current count for each number (shown on progress bar)
    private var pendingNumber: Int? = nil // Number waiting to be announced by voice
    var pendingNumberExists: Bool { pendingNumber != nil }
    
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
              let _ = Int(winnersCount) else {
            return ""
        }
        
        let range = end - start + 1
        let total = range * reps
        return "\(range) numbers × \(reps) repetitions = \(total) total numbers"
    }
    
    func generateRandomNumbers() {
        print("🎮 GENERATE RANDOM NUMBERS CALLED")
        print("📊 Validation check:")
        print("  - Current players: \(currentPlayers.count)")
        print("  - Current game mode: \(currentGameMode?.title ?? "nil")")
        
        // Validate that we have players and game mode
        guard !currentPlayers.isEmpty, currentGameMode != nil else {
            print("❌ ERROR: Missing players or game mode - cannot start countdown")
            return
        }
        
        print("✅ Game mode validation passed - showing countdown then starting game")
        
        // Show countdown UI first
        showingCountdown = true
    }
    
    func startGameAfterCountdown() {
        print("🎮 startGameAfterCountdown() CALLED")
        print("📊 Game parameters:")
        print("  - Players: \(currentPlayers.count)")
        print("  - Game mode: \(currentGameMode?.title ?? "nil")")
        
        // Reset game state
        _currentIndex = 0
        _generatedNumbers.removeAll()
        liveGameNumbers.removeAll()
        winnerOrder.removeAll()
        numberCounts.removeAll()
        currentNumber = 0
        currentRepetition = 0
        confirmedNumbersCount = 0
        pendingNumber = nil
        
        // Get range from game mode or players
        let selectedNumbers = currentPlayers.compactMap { $0.selectedNumber }
        let start = selectedNumbers.min() ?? 1
        let end = selectedNumbers.max() ?? 100
        let repetitions = currentGameMode?.repetitions ?? 1
        
        print("📊 Range: \(start)-\(end), Repetitions: \(repetitions)")
        
        // Generate balanced numbers
        _generatedNumbers = generateBalancedNumbers(start: start, end: end, repetitions: repetitions)
        totalRepetitions = _generatedNumbers.count
        
        print("🎲 Generated \(_generatedNumbers.count) total numbers")
        print("🎲 First 10 numbers: \(Array(_generatedNumbers.prefix(10)))")
        
        // Mark game as ready to start
        gameIsReady = true
    }
    
    private func generateBalancedNumbers(start: Int, end: Int, repetitions: Int) -> [Int] {
        func hasConsecutiveDuplicates(_ array: [Int]) -> Bool {
            for i in 0..<(array.count - 1) where array[i] == array[i + 1] {
                return true
            }
            return false
        }
        // Create a pool where every number appears exactly `repetitions` times
        var pool: [Int] = []
        for num in start...end {
            pool.append(contentsOf: Array(repeating: num, count: repetitions))
        }
        // Shuffle until no consecutive duplicates
        var shuffled = pool.shuffled()
        var safety = 0
        while hasConsecutiveDuplicates(shuffled) && safety < 1000 {
            shuffled.shuffle()
            safety += 1
        }
        return shuffled
    }
    
    func startNewGame() {
        print("🔄 Starting new game")
        isNewGameStarting = true
        reset()
    }
    
    func goHome() {
        print("🏠 Going home")
        reset()
    }
    
    func nextNumber() {
        print("🎲 nextNumber() CALLED")
        print("  - Current index: \(_currentIndex)")
        print("  - Generated numbers count: \(_generatedNumbers.count)")
        
        guard _currentIndex < _generatedNumbers.count else {
            print("❌ No more numbers available")
            return
        }
        
        let nextNumber = _generatedNumbers[_currentIndex]
        print("🎲 Next number: \(nextNumber)")
        
        // Set as pending until voice announces it
        pendingNumber = nextNumber
        currentNumber = nextNumber
        currentRepetition = _currentIndex + 1
        
        // Track live game numbers
        liveGameNumbers.append(nextNumber)
        
        // Advance index for next call
        _currentIndex += 1
        
        print("🎲 Updated state:")
        print("  - Pending number: \(pendingNumber ?? -1)")
        print("  - Current number: \(currentNumber)")
        print("  - Current repetition: \(currentRepetition)")
    }
    
    func confirmPendingNumber() {
        print("🎯 confirmPendingNumber() CALLED")
        guard let number = pendingNumber else {
            print("❌ No pending number to confirm")
            return 
        }
        
        // Update counts and check for winners
        trackLiveNumber(number)
        
        // Clear pending state
        pendingNumber = nil
        confirmedNumbersCount += 1
        
        print("✅ Confirmed number \(number)")
        print("  - Current counts: \(numberCounts)")
        print("  - Winners order: \(winnerOrder)")
    }
    
    private func trackLiveNumber(_ number: Int) {
        // Update count for this number
        numberCounts[number, default: 0] += 1
        
        // Check if this number just reached target repetitions
        let targetReps = currentGameMode?.repetitions ?? 1
        let finalCount = numberCounts[number] ?? 0
        
        if finalCount == targetReps {
            print("🏆 Number \(number) reached target repetitions!")
            // Add to winners list if not already there
            if !winnerOrder.contains(number) {
                winnerOrder.append(number)
                
                // Create winner data
                if let player = currentPlayers.first(where: { $0.selectedNumber == number }) {
                    let winnerData = WinnerData(
                        player: player,
                        number: number,
                        finalCount: finalCount
                    )
                    gameWinners.append(winnerData)
                }
            }
        }
    }
    
    func shouldStopGame() -> Bool {
        print("🎮 Checking if game should stop")
        print("  - Winners: \(winnerOrder.count)")
        print("  - Target winners: \(currentGameMode?.maxWinners ?? 1)")
        
        // Get required winners from game mode
        let targetWinners = currentGameMode?.maxWinners ?? 1
        let shouldStop = winnerOrder.count >= targetWinners
        
        if shouldStop {
            print("🏁 Game should stop - sufficient winners reached")
        } else {
            print("🎮 Game continues - need more winners")
        }
        
        return shouldStop
    }
    
    func finalizeGame() {
        print("🏁 Finalizing game")
        showingWinners = true
        isCompletingRace = true
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
        gameIsReady = false
        
        // Clear game session data but keep players for potential restart
        
        print("🔄 Game state completely reset")
    }
    
    func getTargetRepetitions() -> Int {
        return currentGameMode?.repetitions ?? 1
    }
    
    func getWinnerData(for number: Int) -> (number: Int, count: Int)? {
        if numberCounts[number] != nil {
                let finalCount = numberCounts[number] ?? 0
            return (number: number, count: finalCount)
            }
            return nil
    }
} 