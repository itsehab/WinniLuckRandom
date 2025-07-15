//
//  AvatarService.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI

class AvatarService {
    
    // MARK: - Avatar Generation
    
    /// Generate a DiceBear avatar URL using a seed
    static func generateAvatarURL(seed: String) -> String {
        let baseURL = "https://api.dicebear.com/9.x/avataaars/svg"
        
        // Use the seed to create a deterministic avatar
        let encodedSeed = seed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? seed
        
        // Configure avatar style parameters for fun, colorful avatars
        let parameters = [
            "seed": encodedSeed,
            "backgroundColor": ["b6e3f4", "c0aede", "d1d4f9", "ffd93d", "ffdfbf"].randomElement() ?? "b6e3f4",
            "size": "64"
        ]
        
        let queryString = parameters.compactMap { key, value in
            return "\(key)=\(value)"
        }.joined(separator: "&")
        
        return "\(baseURL)?\(queryString)"
    }
    
    /// Generate a new random avatar URL
    static func generateRandomAvatarURL() -> String {
        return generateAvatarURL(seed: UUID().uuidString)
    }
    
    /// Refresh avatar for a player (generates new random avatar)
    static func refreshAvatarForPlayer(_ player: Player) -> Player {
        return Player(
            id: player.id,
            firstName: player.firstName,
            selectedNumber: player.selectedNumber,
            avatarURL: generateRandomAvatarURL()
        )
    }
}

// MARK: - SwiftUI AsyncImage Helper View

struct AvatarImageView: View {
    let avatarURL: String
    let size: CGFloat
    
    init(avatarURL: String, size: CGFloat = 50) {
        self.avatarURL = avatarURL
        self.size = size
    }
    
    var body: some View {
        AsyncImage(url: URL(string: avatarURL)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            // Placeholder while loading
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: size * 0.6))
                )
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AvatarImageView(avatarURL: AvatarService.generateRandomAvatarURL(), size: 50)
        AvatarImageView(avatarURL: AvatarService.generateRandomAvatarURL(), size: 80)
        AvatarImageView(avatarURL: AvatarService.generateRandomAvatarURL(), size: 120)
    }
    .padding()
} 