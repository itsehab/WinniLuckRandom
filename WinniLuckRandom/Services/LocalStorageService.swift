//
//  LocalStorageService.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI

@MainActor
class LocalStorageService: StorageServiceProtocol {
    static let shared = LocalStorageService()
    
    // MARK: - Published Properties
    @Published var _isOnline = true // Always "online" for local storage
    @Published var _isInitialized = true // Always initialized
    @Published var _errorMessage: String?
    
    // MARK: - Nonisolated Properties for Protocol Conformance
    nonisolated var isOnline: Bool {
        get {
            MainActor.assumeIsolated { _isOnline }
        }
        set {
            MainActor.assumeIsolated { _isOnline = newValue }
        }
    }
    
    nonisolated var isInitialized: Bool {
        get {
            MainActor.assumeIsolated { _isInitialized }
        }
        set {
            MainActor.assumeIsolated { _isInitialized = newValue }
        }
    }
    
    nonisolated var errorMessage: String? {
        get {
            MainActor.assumeIsolated { _errorMessage }
        }
        set {
            MainActor.assumeIsolated { _errorMessage = newValue }
        }
    }
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let documentsURL: URL
    
    private var playersURL: URL {
        documentsURL.appendingPathComponent("players.json")
    }
    
    private var gameModesURL: URL {
        documentsURL.appendingPathComponent("gameModes.json")
    }
    
    private var gameSessionsURL: URL {
        documentsURL.appendingPathComponent("gameSessions.json")
    }
    
    // MARK: - Initialization
    private init() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory")
        }
        self.documentsURL = documentsPath
        
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: documentsURL.path) {
            try? fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Generic Storage Methods
    private func loadData<T: Codable>(from url: URL, as type: T.Type) -> T? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            print("Error loading data from \(url.lastPathComponent): \(error)")
            errorMessage = "Error loading \(url.lastPathComponent): \(error.localizedDescription)"
            return nil
        }
    }
    
    private func saveData<T: Codable>(_ data: T, to url: URL) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url)
            return true
        } catch {
            print("Error saving data to \(url.lastPathComponent): \(error)")
            errorMessage = "Error saving \(url.lastPathComponent): \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Player Operations
    func fetchPlayers() async -> [Player] {
        return loadData(from: playersURL, as: [Player].self) ?? []
    }
    
    func savePlayer(_ player: Player) async -> Bool {
        var players = await fetchPlayers()
        
        // Update existing or add new
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index] = player
        } else {
            players.append(player)
        }
        
        return saveData(players, to: playersURL)
    }
    
    func deletePlayer(_ player: Player) async -> Bool {
        var players = await fetchPlayers()
        players.removeAll { $0.id == player.id }
        return saveData(players, to: playersURL)
    }
    
    // MARK: - GameMode Operations
    func fetchGameModes() async -> [GameMode] {
        print("📁 LocalStorageService: Fetching game modes from \(gameModesURL.path)")
        
        // Try to load existing game modes
        if let existingGameModes = loadData(from: gameModesURL, as: [GameMode].self), !existingGameModes.isEmpty {
            print("✅ Found \(existingGameModes.count) existing game modes")
            return existingGameModes
        }
        
        print("⚠️ No game modes found, creating defaults...")
        
        // Create and save default game modes with explicit order
        let defaultModes = [
            GameMode(title: "Juego Rápido", maxPlayers: 5, entryPriceSoles: Decimal(2.00), prizeTiers: [Decimal(6.00)], maxWinners: 1, repetitions: 3, order: 1),
            GameMode(title: "Juego Estándar", maxPlayers: 10, entryPriceSoles: Decimal(5.00), prizeTiers: [Decimal(25.00), Decimal(15.00)], maxWinners: 2, repetitions: 3, order: 2),
            GameMode(title: "Juego Premium", maxPlayers: 20, entryPriceSoles: Decimal(10.00), prizeTiers: [Decimal(80.00), Decimal(60.00), Decimal(40.00)], maxWinners: 3, repetitions: 3, order: 3)
        ]
        
        let saveSuccess = saveData(defaultModes, to: gameModesURL)
        print("💾 Default game modes save result: \(saveSuccess)")
        
        if saveSuccess {
            print("✅ Successfully created \(defaultModes.count) default game modes")
            return defaultModes
        } else {
            print("❌ Failed to save default game modes")
            return []
        }
    }
    
    func saveGameMode(_ gameMode: GameMode) async -> Bool {
        var gameModes = await fetchGameModes()
        
        // Update existing or add new
        if let index = gameModes.firstIndex(where: { $0.id == gameMode.id }) {
            gameModes[index] = gameMode
        } else {
            gameModes.append(gameMode)
        }
        
        return saveData(gameModes, to: gameModesURL)
    }
    
    func updateGameMode(_ gameMode: GameMode) async -> Bool {
        // For local storage, update is the same as save since saveGameMode handles both
        return await saveGameMode(gameMode)
    }
    
    func deleteGameMode(_ gameMode: GameMode) async -> Bool {
        var gameModes = await fetchGameModes()
        gameModes.removeAll { $0.id == gameMode.id }
        return saveData(gameModes, to: gameModesURL)
    }
    
    // MARK: - GameSession Operations
    func fetchGameSessions() async -> [GameSession] {
        let sessions = loadData(from: gameSessionsURL, as: [GameSession].self) ?? []
        return sessions.sorted { $0.date > $1.date } // Sort by date, newest first
    }
    
    func saveGameSession(_ session: GameSession) async -> Bool {
        var sessions = await fetchGameSessions()
        
        // Update existing or add new
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        
        return saveData(sessions, to: gameSessionsURL)
    }
    
    func deleteGameSession(_ session: GameSession) async -> Bool {
        var sessions = await fetchGameSessions()
        sessions.removeAll { $0.id == session.id }
        return saveData(sessions, to: gameSessionsURL)
    }
    
    // MARK: - Utility Methods
    func clearAllData() -> Bool {
        let urls = [playersURL, gameModesURL, gameSessionsURL]
        var success = true
        
        for url in urls {
            do {
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(at: url)
                }
            } catch {
                print("Error deleting \(url.lastPathComponent): \(error)")
                success = false
            }
        }
        
        return success
    }
    
    func getStorageInfo() -> String {
        let players = (try? Data(contentsOf: playersURL))?.count ?? 0
        let gameModes = (try? Data(contentsOf: gameModesURL))?.count ?? 0
        let sessions = (try? Data(contentsOf: gameSessionsURL))?.count ?? 0
        
        return """
        Local Storage Info:
        - Players file: \(players) bytes
        - Game Modes file: \(gameModes) bytes
        - Sessions file: \(sessions) bytes
        - Location: \(documentsURL.path)
        """
    }
} 