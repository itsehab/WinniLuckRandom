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
    var selectedNumber: Int? // Optional selected number for manual assignment
    
    init(firstName: String, selectedNumber: Int? = nil) {
        self.id = UUID()
        self.firstName = firstName
        self.selectedNumber = selectedNumber
    }
    
    init(id: UUID, firstName: String, selectedNumber: Int? = nil) {
        self.id = id
        self.firstName = firstName
        self.selectedNumber = selectedNumber
    }
}

// MARK: - CloudKit Support
extension Player {
    
    /// Convert Player to CloudKit CKRecord
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Player")
        record["id"] = id.uuidString
        record["firstName"] = firstName
        if let number = selectedNumber {
            record["selectedNumber"] = number
        }
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
        self.selectedNumber = record["selectedNumber"] as? Int
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
    
    /// Display text for selected number
    var numberDisplayText: String {
        if let number = selectedNumber {
            return "\(number)"
        } else {
            return NSLocalizedString("select_number", comment: "Select number placeholder")
        }
    }
} 