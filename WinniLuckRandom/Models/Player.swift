//
//  Player.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import CloudKit

struct Player: Identifiable, Codable, Hashable {
    let id: UUID
    let firstName: String
    
    init(firstName: String) {
        self.id = UUID()
        self.firstName = firstName
    }
    
    init(id: UUID, firstName: String) {
        self.id = id
        self.firstName = firstName
    }
}

// MARK: - CloudKit Support
extension Player {
    
    /// Convert Player to CloudKit CKRecord
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Player")
        record["id"] = id.uuidString
        record["firstName"] = firstName
        return record
    }
    
    /// Initialize Player from CloudKit CKRecord
    init?(from record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let firstName = record["firstName"] as? String else {
            return nil
        }
        
        self.id = id
        self.firstName = firstName
    }
}

// MARK: - Display Helper
extension Player {
    /// Display name for UI (just first name)
    var displayName: String {
        return firstName
    }
    
    /// Check if name is valid (not empty or whitespace)
    var isValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
} 