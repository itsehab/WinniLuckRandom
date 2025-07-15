//
//  CloudKitService.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class CloudKitService: StorageServiceProtocol {
    static let shared = CloudKitService()
    
    private let container = CKContainer.default()
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    // MARK: - Published Properties
    @Published var isOnline = false
    @Published var isInitialized = false
    @Published var errorMessage: String?
    
    // MARK: - Cached Data
    @Published var players: [Player] = []
    @Published var gameModes: [GameMode] = []
    @Published var gameSessions: [GameSession] = []
    
    // MARK: - Initialization
    init() {
        setupNotifications()
        // Don't start CloudKit operations in init to avoid crashes
        // CloudKit will be initialized on first use
    }
    
    // MARK: - Initialization Management
    private var initializationTask: Task<Void, Never>?
    
    private func ensureInitialized() async {
        // If already initialized, return
        let isInitializedValue = await MainActor.run { isInitialized }
        if isInitializedValue {
            return
        }
        
        // If initialization is already in progress, wait for it
        if let existingTask = initializationTask {
            await existingTask.value
            return
        }
        
        // Start new initialization
        initializationTask = Task {
            await checkAccountStatus()
        }
        
        await initializationTask?.value
    }
    
    // MARK: - Account Status
    private func checkAccountStatus() async {
        do {
            let accountStatus = try await container.accountStatus()
            await MainActor.run {
                switch accountStatus {
                case .available:
                    isOnline = true
                case .noAccount:
                    errorMessage = "Please sign in to iCloud in Settings"
                    isOnline = false
                case .restricted:
                    errorMessage = "iCloud account is restricted"
                    isOnline = false
                case .couldNotDetermine:
                    errorMessage = "Could not determine iCloud account status"
                    isOnline = false
                case .temporarilyUnavailable:
                    errorMessage = "iCloud is temporarily unavailable"
                    isOnline = false
                @unknown default:
                    errorMessage = "Unknown iCloud account status"
                    isOnline = false
                }
            }
            
            // Only initialize data if online
            let isOnlineValue = await MainActor.run { isOnline }
            if isOnlineValue {
                await initializeData()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error checking iCloud account: \(error.localizedDescription)"
                isOnline = false
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accountChanged),
            name: .CKAccountChanged,
            object: nil
        )
    }
    
    @objc private func accountChanged() {
        Task {
            await checkAccountStatus()
        }
    }
    
    // MARK: - Data Initialization
    private func initializeData() {
        Task {
            await loadAllData()
            
            // Create default game modes if none exist
            if gameModes.isEmpty {
                await createDefaultGameModes()
            }
            
            await MainActor.run {
                isInitialized = true
            }
        }
    }
    
    private func loadAllData() async {
        async let playersResult = fetchPlayers()
        async let gameModesResult = fetchGameModes()
        async let gameSessionsResult = fetchGameSessions()
        
        let players = await playersResult
        let gameModes = await gameModesResult
        let gameSessions = await gameSessionsResult
        
        await MainActor.run {
            self.players = players
            self.gameModes = gameModes
            self.gameSessions = gameSessions
        }
    }
    
    // MARK: - Player Operations
    func fetchPlayers() async -> [Player] {
        guard isOnline else { return [] }
        
        do {
            let query = CKQuery(recordType: "Player", predicate: NSPredicate(value: true))
            let result = try await database.records(matching: query)
            
            return result.matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Player(from: record)
                case .failure(let error):
                    print("Error fetching player record: \(error)")
                    return nil
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error fetching players: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    func savePlayer(_ player: Player) async -> Bool {
        guard isOnline else { return false }
        
        do {
            let record = player.toCKRecord()
            _ = try await database.save(record)
            
            await MainActor.run {
                if let index = players.firstIndex(where: { $0.id == player.id }) {
                    players[index] = player
                } else {
                    players.append(player)
                }
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Error saving player: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func deletePlayer(_ player: Player) async -> Bool {
        guard isOnline else { return false }
        
        do {
            let recordID = CKRecord.ID(recordName: player.id.uuidString)
            _ = try await database.deleteRecord(withID: recordID)
            
            await MainActor.run {
                players.removeAll { $0.id == player.id }
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Error deleting player: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - GameMode Operations
    func fetchGameModes() async -> [GameMode] {
        // Ensure CloudKit is initialized
        await ensureInitialized()
        
        let isOnlineValue = await MainActor.run { isOnline }
        guard isOnlineValue else { 
            return await MainActor.run { gameModes } 
        }
        
        do {
            let query = CKQuery(recordType: "GameMode", predicate: NSPredicate(value: true))
            let result = try await database.records(matching: query)
            
            return result.matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return GameMode(from: record)
                case .failure(let error):
                    print("Error fetching game mode record: \(error)")
                    return nil
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error fetching game modes: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    func saveGameMode(_ gameMode: GameMode) async -> Bool {
        guard isOnline else { return false }
        
        do {
            let record = gameMode.toCKRecord()
            _ = try await database.save(record)
            
            await MainActor.run {
                if let index = gameModes.firstIndex(where: { $0.id == gameMode.id }) {
                    gameModes[index] = gameMode
                } else {
                    gameModes.append(gameMode)
                }
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Error saving game mode: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func deleteGameMode(_ gameMode: GameMode) async -> Bool {
        guard isOnline else { return false }
        
        do {
            let recordID = CKRecord.ID(recordName: gameMode.id.uuidString)
            _ = try await database.deleteRecord(withID: recordID)
            
            await MainActor.run {
                gameModes.removeAll { $0.id == gameMode.id }
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Error deleting game mode: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func updateGameMode(_ gameMode: GameMode) async -> Bool {
        // For CloudKit, update is the same as save since saveGameMode handles both
        return await saveGameMode(gameMode)
    }
    
    // MARK: - GameSession Operations
    func fetchGameSessions() async -> [GameSession] {
        guard isOnline else { return [] }
        
        do {
            let query = CKQuery(recordType: "GameSession", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            let result = try await database.records(matching: query)
            
            return result.matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return GameSession(from: record)
                case .failure(let error):
                    print("Error fetching game session record: \(error)")
                    return nil
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error fetching game sessions: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    func saveGameSession(_ gameSession: GameSession) async -> Bool {
        guard isOnline else { return false }
        
        do {
            let record = gameSession.toCKRecord()
            _ = try await database.save(record)
            
            await MainActor.run {
                if let index = gameSessions.firstIndex(where: { $0.id == gameSession.id }) {
                    gameSessions[index] = gameSession
                } else {
                    gameSessions.insert(gameSession, at: 0) // Insert at beginning for chronological order
                }
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Error saving game session: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func deleteGameSession(_ gameSession: GameSession) async -> Bool {
        guard isOnline else { return false }
        
        do {
            let recordID = CKRecord.ID(recordName: gameSession.id.uuidString)
            _ = try await database.deleteRecord(withID: recordID)
            
            await MainActor.run {
                gameSessions.removeAll { $0.id == gameSession.id }
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Error deleting game session: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Utility Methods
    func getPlayer(by id: UUID) -> Player? {
        return players.first { $0.id == id }
    }
    
    func getGameMode(by id: UUID) -> GameMode? {
        return gameModes.first { $0.id == id }
    }
    
    func getGameSession(by id: UUID) -> GameSession? {
        return gameSessions.first { $0.id == id }
    }
    
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    // MARK: - Default Data
    private func createDefaultGameModes() async {
        let defaultModes = [
            GameMode(
                title: "Quick Game",
                maxPlayers: 5,
                entryPriceSoles: 2.00,
                prizeTiers: [6.00], // 1st place: S/. 6.00
                maxWinners: 1
            ),
            GameMode(
                title: "Standard Game",
                maxPlayers: 10,
                entryPriceSoles: 5.00,
                prizeTiers: [25.00, 15.00], // 1st: S/. 25.00, 2nd: S/. 15.00
                maxWinners: 2
            ),
            GameMode(
                title: "Premium Game",
                maxPlayers: 20,
                entryPriceSoles: 10.00,
                prizeTiers: [80.00, 60.00, 40.00], // 1st: S/. 80.00, 2nd: S/. 60.00, 3rd: S/. 40.00
                maxWinners: 3
            )
        ]
        
        for mode in defaultModes {
            _ = await saveGameMode(mode)
        }
        
        // Reload game modes after creating defaults
        let updatedGameModes = await fetchGameModes()
        await MainActor.run {
            self.gameModes = updatedGameModes
        }
    }
}

// MARK: - Error Handling
extension CloudKitService {
    func handleError(_ error: Error) {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable:
                errorMessage = "Network unavailable. Please check your internet connection."
            case .quotaExceeded:
                errorMessage = "iCloud storage quota exceeded."
            case .requestRateLimited:
                errorMessage = "Too many requests. Please try again later."
            case .zoneNotFound:
                errorMessage = "iCloud zone not found. Please try again."
            default:
                errorMessage = "CloudKit error: \(ckError.localizedDescription)"
            }
        } else {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
    }
} 