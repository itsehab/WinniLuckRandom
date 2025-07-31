//
//  CountdownView.swift
//  WinniLuckRandom
//
//  Created by Assistant on 2025.
//

import SwiftUI

struct CountdownView: View {
    @ObservedObject var viewModel: RandomNumberViewModel
    @ObservedObject var settings: SettingsModel
    @State private var countdownNumber = 3
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                BackgroundView(image: settings.backgroundImage)
                
                // Animated background particles
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: CGFloat.random(in: 4...12))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 2...4))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...2)),
                            value: countdownNumber
                        )
                }
                
                VStack(spacing: 40) {
                    // Title
                    Text("¡Preparate!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                        .scaleEffect(pulseScale)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                    
                    // Main countdown number
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.yellow.opacity(0.8),
                                        Color.orange.opacity(0.6),
                                        Color.red.opacity(0.4)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(rotation))
                            .scaleEffect(scale * 1.1)
                            .opacity(opacity * 0.7)
                        
                        // Main circle
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.yellow,
                                        Color.orange,
                                        Color.red.opacity(0.8)
                                    ]),
                                    center: .topLeading,
                                    startRadius: 10,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 180, height: 180)
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .shadow(color: .orange.opacity(0.8), radius: 20, x: 0, y: 10)
                        
                        // Inner circle
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: 3)
                            .frame(width: 140, height: 140)
                            .scaleEffect(scale)
                            .opacity(opacity)
                        
                        // Countdown number
                        if countdownNumber > 0 {
                            Text("\(countdownNumber)")
                                .font(.system(size: 80, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                                .scaleEffect(scale)
                                .opacity(opacity)
                                .rotationEffect(.degrees(rotation * 0.1))
                        } else {
                            // "GO!" text
                            Text("¡YA!")
                                .font(.system(size: 60, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                                .scaleEffect(scale)
                                .opacity(opacity)
                        }
                    }
                    
                    // Subtitle
                    Text("El juego comenzará pronto...")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                        .opacity(opacity * 0.8)
                }
                
                // Cancel button (top right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            // CRITICAL: Properly reset game state when canceled
                            viewModel.hardReset()
                            dismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
            }
        }
        .onAppear {
            startCountdown()
        }
    }
    
    private func startCountdown() {
        // Initial animation - show the number 3 first
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scale = 1.0
            opacity = 1.0
            pulseScale = 1.1
        }
        
        // Start rotation animation
        withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // EXPLICIT COUNTDOWN SEQUENCE: 3 → 2 → 1 → ¡YA!
        
        // Step 1: Show "3" for 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.animateToNumber2()
        }
    }
    
    private func animateToNumber2() {
        print("🔢 Animating from 3 to 2")
        // Shrink animation
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.6
            opacity = 0.4
        }
        
        // Change to 2 and grow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            countdownNumber = 2
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.2
                opacity = 1.0
            }
            
            // Settle and wait
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.2)) {
                    scale = 1.0
                }
                
                // Show "2" for 1 second, then go to 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.animateToNumber1()
                }
            }
        }
    }
    
    private func animateToNumber1() {
        print("🔢 Animating from 2 to 1")
        // Shrink animation
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.6
            opacity = 0.4
        }
        
        // Change to 1 and grow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            countdownNumber = 1
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.2
                opacity = 1.0
            }
            
            // Settle and wait
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.2)) {
                    scale = 1.0
                }
                
                // Show "1" for 1 second, then go to ¡YA!
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.animateToGo()
                }
            }
        }
    }
    
    private func animateToGo() {
        print("🔢 Animating from 1 to ¡YA!")
        // Shrink animation
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.6
            opacity = 0.4
        }
        
        // Change to ¡YA! and grow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            countdownNumber = 0
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.2
                opacity = 1.0
            }
            
            // Settle and wait
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.2)) {
                    scale = 1.0
                }
                
                // Show "¡YA!" for 1 second, then start game
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.showGoAndStartGame()
                }
            }
        }
    }
    
    private func showGoAndStartGame() {
        // Final "¡YA!" animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            scale = 1.8
            rotation += 180
        }
        
        // Start the actual game after showing "¡YA!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            print("🕰️ COUNTDOWN FINISHED - About to call startGameAfterCountdown()")
            print("🕰️ ViewModel exists: \(viewModel != nil)")
            print("🕰️ Current players count: \(viewModel.currentPlayers.count)")
            print("🕰️ Current game mode: \(viewModel.currentGameMode?.title ?? "nil")")
            
            viewModel.startGameAfterCountdown()
            
            print("🕰️ startGameAfterCountdown() call completed, dismissing countdown")
            dismiss()
        }
    }
}

#Preview {
    let viewModel = RandomNumberViewModel()
    let settings = SettingsModel()
    return CountdownView(viewModel: viewModel, settings: settings)
} 