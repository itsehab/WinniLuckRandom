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
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: Double.random(in: 1.5...3.0))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2.0)),
                            value: pulseScale
                        )
                }
                
                // Central countdown circle
                VStack {
                    Spacer()
                    
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.yellow, .orange]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(scale * 1.1)
                            .opacity(opacity * 0.6)
                            .rotationEffect(.degrees(rotation))
                        
                        // Inner circle background
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [.orange.opacity(0.8), .red.opacity(0.6)]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                            .scaleEffect(scale)
                            .opacity(opacity)
                        
                        // Inner ring
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: 3)
                            .frame(width: 140, height: 140)
                            .scaleEffect(scale)
                            .opacity(opacity)
                        
                        // Countdown number or Ya text
                        if countdownNumber > 0 {
                            Text("\(countdownNumber)")
                                .font(.system(size: 80, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                                .scaleEffect(scale)
                                .opacity(opacity)
                                .rotationEffect(.degrees(rotation * 0.1))
                        } else {
                            // "¡Ya!" text
                            Text("¡Ya!")
                                .font(.system(size: 60, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                                .scaleEffect(scale)
                                .opacity(opacity)
                        }
                        
                        // Inner sparkle effect
                        ForEach(0..<8, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: cos(Double(index) * .pi / 4) * 50,
                                    y: sin(Double(index) * .pi / 4) * 50
                                )
                                .scaleEffect(scale)
                                .opacity(opacity)
                                .rotationEffect(.degrees(rotation * 2))
                        }
                    }
                    .shadow(color: .orange.opacity(0.5), radius: 20, x: 0, y: 0)
                    
                    Spacer()
                    
                    // Branding
                    VStack(spacing: 8) {
                        Text("WinniLuck")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
                        
                        Text("Get Ready!")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.6), radius: 1, x: 1, y: 1)
                    }
                    .padding(.bottom, 60)
                    .scaleEffect(scale * 0.8)
                    .opacity(opacity)
                }
            }
        }
        .onAppear {
            print("⏰ CountdownView appeared - starting countdown")
            // Set initial state
            countdownNumber = 3
            scale = 0.5
            opacity = 0.0
            
            // Animate entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
                pulseScale = 1.1
            }
            
            // Start countdown sequence
            startCountdown()
        }
    }
    
    private func startCountdown() {
        print("🔢 Starting countdown from 3")
        // Start rotation animation
        withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Animate to number 2 after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            animateToNumber2()
        }
    }
    
    private func animateToNumber2() {
        print("🔢 Animating to 2")
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
                
                // Animate to number 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateToNumber1()
                }
            }
        }
    }
    
    private func animateToNumber1() {
        print("🔢 Animating to 1")
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
                
                // Show "GO!" and start game
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showGoAndStartGame()
                }
            }
        }
    }
    
    private func showGoAndStartGame() {
        print("🔢 Showing ¡Ya! and starting game")
        // Shrink animation
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.6
            opacity = 0.4
        }
        
        // Change to "¡Ya!" and grow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            countdownNumber = 0
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.2
                opacity = 1.0
            }
            
            // Final burst animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.5
                    opacity = 1.0
                    rotation += 180
                }
                
                // Start game after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🎮 Starting game after countdown")
                    viewModel.startGameAfterCountdown()
                    viewModel.showingCountdown = false
                    viewModel.showingResult = true
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    let viewModel = RandomNumberViewModel()
    let settings = SettingsModel()
    return CountdownView(viewModel: viewModel, settings: settings)
}