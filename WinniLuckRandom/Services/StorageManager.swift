//
//  StorageManager.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI

enum StorageType {
    case local
    case cloudKit
}

enum PendingOperationType: String, Codable {
    case saveGameSession
    case savePlayer
    case saveGameMode
    case deleteGameSession
    case deletePlayer
    case deleteGameMode
}

struct PendingOperation: Codable {
    let id: UUID
    let type: PendingOperationType
    let data: Data
    let timestamp: Date
    
    init(id: UUID = UUID(), type: PendingOperationType, data: Data, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.data = data
        self.timestamp = timestamp
    }
}

@MainActor
class StorageManager: ObservableObject {
    @preconcurrency static let shared: StorageManager = {
        let instance = StorageManager()
        return instance
    }()
    
    @Published var currentStorageType: StorageType = .local
    @Published var isOnline: Bool = true
    @Published var isInitialized: Bool = true
    @Published var errorMessage: String?
    @Published var pendingOperations: Int = 0
    
    // Offline queue for CloudKit operations
    private var offlineQueue: [PendingOperation] = []
    private let offlineQueueKey = "StorageManager.OfflineQueue"
    
    private var currentService: any StorageServiceProtocol {
        switch currentStorageType {
        case .local:
            return LocalStorageService.shared
        case .cloudKit:
            return CloudKitService.shared
        }
    }
    
    private init() {
        // Default to local storage for better performance
        // CloudKit initialization will happen on first use
        currentStorageType = .local
        
        // Load any pending operations from previous app runs
        loadOfflineQueue()
        
        print("🔧 StorageManager initialized with local storage")
        print("📋 Loaded \(offlineQueue.count) pending operations from previous session")
    }
    
    // MARK: - Storage Type Management
    
    func switchToLocalStorage() {
        print("🔄 Switching to Local Storage")
        currentStorageType = .local
        updateStatus()
    }
    
    func switchToCloudKit() {
        print("🔄 Switching to CloudKit")
        currentStorageType = .cloudKit
        updateStatus()
        
        // Process any pending operations when switching to CloudKit
        Task {
            await processOfflineQueue()
        }
    }
    
    func tryCloudKitOrFallback() {
        // Try CloudKit first, fallback to local if not available
        currentStorageType = .cloudKit
        
        Task {
            // Give CloudKit a moment to initialize
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                let cloudKitService = CloudKitService.shared
                if !cloudKitService.isOnline || cloudKitService.errorMessage != nil {
                    print("⚠️ CloudKit not available, falling back to local storage")
                    switchToLocalStorage()
                } else {
                    print("✅ CloudKit is available")
                    updateStatus()
                }
            }
        }
    }
    
    private func updateStatus() {
        let service = currentService
        isOnline = service.isOnline
        isInitialized = service.isInitialized
        errorMessage = service.errorMessage
    }
    
    // MARK: - Data Migration
    
    func migrateLocalDataToCloudKit() async throws {
        print("🔄 Starting migration from Local to CloudKit...")
        
        let localService = LocalStorageService.shared
        let cloudKitService = CloudKitService.shared
        
        // Migrate players
        let localPlayers = await localService.fetchPlayers()
        for player in localPlayers {
            let success = await cloudKitService.savePlayer(player)
            if !success {
                print("⚠️ Failed to migrate player: \(player.firstName)")
            }
        } 
        print("✅ Migrated \(localPlayers.count) players")
        
        // Migrate game modes
        let localGameModes = await localService.fetchGameModes()
        for gameMode in localGameModes {
            let success = await cloudKitService.saveGameMode(gameMode)
            if !success {
                print("⚠️ Failed to migrate game mode: \(gameMode.title)")
            }
        }
        print("✅ Migrated \(localGameModes.count) game modes")
        
        // Migrate game sessions
        let localGameSessions = await localService.fetchGameSessions()
        for gameSession in localGameSessions {
            let success = await cloudKitService.saveGameSession(gameSession)
            if !success {
                print("⚠️ Failed to migrate game session: \(gameSession.id)")
            }
        }
        print("✅ Migrated \(localGameSessions.count) game sessions")
        
        print("🎉 Migration completed successfully!")
    }
    
    // MARK: - Migration Methods
    
    func migrateLocalToCloudKit() async -> Bool {
        guard currentStorageType == .cloudKit else {
            print("❌ Not using CloudKit, migration not needed")
            return false
        }
        
        print("📦 Starting migration from local to CloudKit...")
        
        let localService = LocalStorageService.shared
        let cloudKitService = CloudKitService.shared
        
        // Migrate game modes
        let localGameModes = await localService.fetchGameModes()
        for gameMode in localGameModes {
            let success = await cloudKitService.saveGameMode(gameMode)
            if !success {
                print("⚠️ Failed to migrate game mode: \(gameMode.title)")
            }
        }
        print("✅ Migrated \(localGameModes.count) game modes")
        
        // Migrate players
        let localPlayers = await localService.fetchPlayers()
        for player in localPlayers {
            let success = await cloudKitService.savePlayer(player)
            if !success {
                print("⚠️ Failed to migrate player: \(player.firstName)")
            }
        }
        print("✅ Migrated \(localPlayers.count) players")
        
        // Migrate game sessions
        let localSessions = await localService.fetchGameSessions()
        for session in localSessions {
            let success = await cloudKitService.saveGameSession(session)
            if !success {
                print("⚠️ Failed to migrate game session: \(session.id)")
            }
        }
        print("✅ Migrated \(localSessions.count) game sessions")
        
        print("🎉 Migration completed successfully!")
        return true
    }
    
    // MARK: - Delegate Methods (Forward to current service)
    
    // Player Operations
    func fetchPlayers() async -> [Player] {
        await currentService.fetchPlayers()
    }
    
    func savePlayer(_ player: Player) async -> Bool {
        await currentService.savePlayer(player)
    }
    
    func deletePlayer(_ player: Player) async -> Bool {
        await currentService.deletePlayer(player)
    }
    
    // GameMode Operations
    func fetchGameModes() async -> [GameMode] {
        await currentService.fetchGameModes()
    }
    
    func saveGameMode(_ gameMode: GameMode) async -> Bool {
        await currentService.saveGameMode(gameMode)
    }
    
    func updateGameMode(_ gameMode: GameMode) async -> Bool {
        await currentService.updateGameMode(gameMode)
    }
    
    func deleteGameMode(_ gameMode: GameMode) async -> Bool {
        await currentService.deleteGameMode(gameMode)
    }
    
    // GameSession Operations
    func fetchGameSessions() async -> [GameSession] {
        // Always fetch from local storage for immediate access
        let localSessions = await LocalStorageService.shared.fetchGameSessions()
        
        // If using CloudKit, also fetch from there and merge
        if currentStorageType == .cloudKit {
            let cloudKitSessions = await CloudKitService.shared.fetchGameSessions()
            
            // Merge sessions, preferring CloudKit versions for duplicates
            var sessionMap: [UUID: GameSession] = [:]
            
            // Add local sessions first
            for session in localSessions {
                sessionMap[session.id] = session
            }
            
            // Add CloudKit sessions, overriding local ones
            for session in cloudKitSessions {
                sessionMap[session.id] = session
            }
            
            return Array(sessionMap.values).sorted { $0.date > $1.date }
        }
        
        return localSessions
    }
    
    func saveGameSession(_ session: GameSession) async -> Bool {
        // Always save to local storage first for immediate access
        let localSuccess = await LocalStorageService.shared.saveGameSession(session)
        
        if !localSuccess {
            print("❌ Failed to save game session to local storage")
            return false
        }
        
        // If using CloudKit, also save there (or queue for later)
        if currentStorageType == .cloudKit {
            let cloudKitSuccess = await CloudKitService.shared.saveGameSession(session)
            
            if !cloudKitSuccess {
                // If CloudKit save failed, add to offline queue
                addToOfflineQueue(.saveGameSession, data: session)
                print("📋 CloudKit save failed, added to offline queue")
            }
        }
        
        return true
    }
    
    func deleteGameSession(_ session: GameSession) async -> Bool {
        await currentService.deleteGameSession(session)
    }
    
    // MARK: - Utility Methods
    
    var storageDescription: String {
        switch currentStorageType {
        case .local:
            return "📱 Local Storage (JSON Files)"
        case .cloudKit:
            return "☁️ CloudKit (iCloud)"
        }
    }
    
    func getStorageInfo() -> String {
        let baseInfo = """
        Current Storage: \(storageDescription)
        Online: \(isOnline)
        Initialized: \(isInitialized)
        Pending Operations: \(pendingOperations)
        """
        
        if currentStorageType == .local,
           let localService = currentService as? LocalStorageService {
            return baseInfo + "\n\n" + localService.getStorageInfo()
        }
        
        return baseInfo
    }
    
    // MARK: - Offline Queue Management
    
    private func loadOfflineQueue() {
        guard let data = UserDefaults.standard.data(forKey: offlineQueueKey) else {
            offlineQueue = []
            return
        }
        
        do {
            offlineQueue = try JSONDecoder().decode([PendingOperation].self, from: data)
            pendingOperations = offlineQueue.count
        } catch {
            print("❌ Error loading offline queue: \(error)")
            offlineQueue = []
        }
    }
    
    private func saveOfflineQueue() {
        do {
            let data = try JSONEncoder().encode(offlineQueue)
            UserDefaults.standard.set(data, forKey: offlineQueueKey)
            pendingOperations = offlineQueue.count
        } catch {
            print("❌ Error saving offline queue: \(error)")
        }
    }
    
    private func addToOfflineQueue<T: Codable>(_ operation: PendingOperationType, data: T) {
        do {
            let encodedData = try JSONEncoder().encode(data)
            let pendingOperation = PendingOperation(type: operation, data: encodedData)
            offlineQueue.append(pendingOperation)
            saveOfflineQueue()
            
            print("📋 Added \(operation.rawValue) to offline queue (total: \(offlineQueue.count))")
        } catch {
            print("❌ Error adding to offline queue: \(error)")
        }
    }
    
    private func processOfflineQueue() async {
        guard !offlineQueue.isEmpty else { return }
        
        print("🔄 Processing \(offlineQueue.count) pending operations...")
        
        var processedOperations: [UUID] = []
        
        for operation in offlineQueue {
            let success = await processOperation(operation)
            if success {
                processedOperations.append(operation.id)
            }
        }
        
        // Remove successfully processed operations
        offlineQueue.removeAll { processedOperations.contains($0.id) }
        saveOfflineQueue()
        
        print("✅ Processed \(processedOperations.count) operations, \(offlineQueue.count) remaining")
    }
    
    private func processOperation(_ operation: PendingOperation) async -> Bool {
        switch operation.type {
        case .saveGameSession:
            do {
                let session = try JSONDecoder().decode(GameSession.self, from: operation.data)
                return await CloudKitService.shared.saveGameSession(session)
            } catch {
                print("❌ Error decoding GameSession: \(error)")
                return false
            }
        case .savePlayer:
            do {
                let player = try JSONDecoder().decode(Player.self, from: operation.data)
                return await CloudKitService.shared.savePlayer(player)
            } catch {
                print("❌ Error decoding Player: \(error)")
                return false
            }
        case .saveGameMode:
            do {
                let gameMode = try JSONDecoder().decode(GameMode.self, from: operation.data)
                return await CloudKitService.shared.saveGameMode(gameMode)
            } catch {
                print("❌ Error decoding GameMode: \(error)")
                return false
            }
        case .deleteGameSession:
            do {
                let session = try JSONDecoder().decode(GameSession.self, from: operation.data)
                return await CloudKitService.shared.deleteGameSession(session)
            } catch {
                print("❌ Error decoding GameSession for deletion: \(error)")
                return false
            }
        case .deletePlayer:
            do {
                let player = try JSONDecoder().decode(Player.self, from: operation.data)
                return await CloudKitService.shared.deletePlayer(player)
            } catch {
                print("❌ Error decoding Player for deletion: \(error)")
                return false
            }
        case .deleteGameMode:
            do {
                let gameMode = try JSONDecoder().decode(GameMode.self, from: operation.data)
                return await CloudKitService.shared.deleteGameMode(gameMode)
            } catch {
                print("❌ Error decoding GameMode for deletion: \(error)")
                return false
            }
        }
    }
} 
