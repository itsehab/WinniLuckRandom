//
//  ConfettiHelper.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 12/07/25.
//

import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces.indices, id: \.self) { index in
                let piece = confettiPieces[index]
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(x: piece.x, y: piece.y)
                    .opacity(piece.opacity)
                    .animation(.easeOut(duration: piece.duration), value: animate)
            }
        }
        .onAppear {
            startConfetti()
        }
    }
    
    private func startConfetti() {
        // Create confetti pieces
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: -50,
                color: [.red, .blue, .green, .yellow, .orange, .purple, .pink].randomElement() ?? .red,
                size: CGFloat.random(in: 8...15),
                duration: Double.random(in: 2...4),
                opacity: 1.0
            )
        }
        
        // Animate confetti falling
        withAnimation(.easeOut(duration: 3.0)) {
            animate = true
            for index in confettiPieces.indices {
                confettiPieces[index].y = UIScreen.main.bounds.height + 100
                confettiPieces[index].opacity = 0.0
            }
        }
    }
}

struct ConfettiPiece {
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var duration: Double
    var opacity: Double
}

struct ConfettiModifier: ViewModifier {
    @State private var showConfetti = false
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showConfetti {
                        ConfettiView()
                            .allowsHitTesting(false)
                    }
                }
            )
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    showConfetti = true
                    // Hide confetti after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        showConfetti = false
                    }
                }
            }
    }
}

extension View {
    func confetti(trigger: Bool) -> some View {
        self.modifier(ConfettiModifier(trigger: trigger))
    }
} 