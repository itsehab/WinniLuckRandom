//
//  AvatarService.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import Foundation
import SwiftUI

enum DiceBear {
    static func avatarURL(style: String = "adventurer", seed: String) -> URL {
        // DiceBear v8 syntax with PNG format
        let encodedSeed = seed.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "seed"
        let urlString = "https://api.dicebear.com/8.x/\(style)/png?seed=\(encodedSeed)&backgroundColor=fde047,f97316,37d19c"
        return URL(string: urlString)!
    }
}

class AvatarService {
    
    // MARK: - Avatar Generation
    
    /// Generate a DiceBear avatar URL using a seed
    static func generateAvatarURL(seed: String) -> String {
        let url = DiceBear.avatarURL(style: "adventurer", seed: seed)
        print("Avatar URL → \(url.absoluteString)")
        return url.absoluteString
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
        AsyncImage(url: URL(string: avatarURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure(let error):
                // Show error and fallback
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .overlay(
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .font(.system(size: size * 0.4))
                            Text("Error")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    )
                    .onAppear {
                        print("Avatar loading error: \(error)")
                        print("Avatar URL: \(avatarURL)")
                    }
            case .empty:
                // Placeholder while loading
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: size * 0.6))
                    )
            @unknown default:
                // Fallback
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: size * 0.6))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .onAppear {
            print("Avatar URL for display → \(avatarURL)")
        }
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