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

struct InfinityConfettiView: View {
    @State private var confettiPieces: [InfinityConfettiPiece] = []
    @State private var timer: Timer?
    let isActive: Bool
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(x: piece.x, y: piece.y)
                    .opacity(piece.opacity)
                    .rotation3DEffect(
                        .degrees(piece.rotation),
                        axis: (x: piece.rotationAxis.x, y: piece.rotationAxis.y, z: piece.rotationAxis.z)
                    )
            }
        }
        .onAppear {
            if isActive {
                startInfinityConfetti()
            }
        }
        .onDisappear {
            stopInfinityConfetti()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startInfinityConfetti()
            } else {
                stopInfinityConfetti()
            }
        }
    }
    
    private func startInfinityConfetti() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            addConfettiBurst()
        }
    }
    
    private func stopInfinityConfetti() {
        timer?.invalidate()
        timer = nil
        confettiPieces.removeAll()
    }
    
    private func addConfettiBurst() {
        let newPieces = (0..<8).map { _ in
            InfinityConfettiPiece(
                id: UUID(),
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: -20,
                color: [.red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan].randomElement() ?? .red,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0,
                rotation: 0,
                rotationAxis: (
                    x: Double.random(in: 0...1),
                    y: Double.random(in: 0...1),
                    z: Double.random(in: 0...1)
                )
            )
        }
        
        confettiPieces.append(contentsOf: newPieces)
        
        // Animate each piece
        for piece in newPieces {
            withAnimation(.easeOut(duration: Double.random(in: 3...5))) {
                if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[index].y = UIScreen.main.bounds.height + 50
                    confettiPieces[index].x += CGFloat.random(in: -100...100)
                    confettiPieces[index].opacity = 0.0
                    confettiPieces[index].rotation = Double.random(in: 0...720)
                }
            }
        }
        
        // Remove old pieces
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            confettiPieces.removeAll { piece in
                newPieces.contains { $0.id == piece.id }
            }
        }
    }
}

struct InfinityConfettiPiece: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var opacity: Double
    var rotation: Double
    var rotationAxis: (x: Double, y: Double, z: Double)
}

extension View {
    func confetti(trigger: Bool) -> some View {
        self.modifier(ConfettiModifier(trigger: trigger))
    }
    
    func infinityConfetti(isActive: Bool) -> some View {
        self.overlay(
            InfinityConfettiView(isActive: isActive)
                .allowsHitTesting(false)
        )
    }
} 