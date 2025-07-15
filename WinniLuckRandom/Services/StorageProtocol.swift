//
//  StorageProtocol.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation

protocol StorageServiceProtocol: ObservableObject {
    var isOnline: Bool { get }
    var isInitialized: Bool { get }
    var errorMessage: String? { get set }
    
    // MARK: - Player Operations
    func fetchPlayers() async -> [Player]
    func savePlayer(_ player: Player) async -> Bool
    func deletePlayer(_ player: Player) async -> Bool
    
    // MARK: - GameMode Operations
    func fetchGameModes() async -> [GameMode]
    func saveGameMode(_ gameMode: GameMode) async -> Bool
    func updateGameMode(_ gameMode: GameMode) async -> Bool
    func deleteGameMode(_ gameMode: GameMode) async -> Bool
    
    // MARK: - GameSession Operations
    func fetchGameSessions() async -> [GameSession]
    func saveGameSession(_ session: GameSession) async -> Bool
    func deleteGameSession(_ session: GameSession) async -> Bool
} 