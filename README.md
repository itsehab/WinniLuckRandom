# WinniLuckRandom

A professional iOS lottery/random number generator app with Spanish voice synthesis, confetti animations, and elegant UI design.

## Features

### 🎯 **Core Functionality**
- Random number generation with customizable range (1-100)
- Configurable repetition count for each number
- Winner selection with customizable winner count
- Anti-consecutive duplicate algorithm for fair distribution
- Race-based winner system where numbers compete to reach target

### 🎨 **Visual Design**
- Elegant golden coin animation with 3D rotation
- Confetti animations for celebrations
- Background image customization from photo library
- Clean, modern SwiftUI interface
- Support for dark mode and dynamic type
- Mobile-optimized layout for all iOS devices

### 🎤 **Voice & Audio**
- Spanish voice synthesis with natural human tone
- Automatic number announcement
- Enhanced voice quality selection
- Latin American Spanish accent priority
- Professional speech parameters for clarity

### ⚙️ **Settings & Customization**
- Persistent settings with UserDefaults
- Custom background image support
- Voice announcement toggle
- Confetti animation toggle
- All settings preserved between app sessions

### 🎮 **Gameplay Experience**
- Automatic 3-second progression between numbers
- 1-second randomization animation before reveal
- Visual progress bar with numerical indicators
- Smooth navigation between screens
- One-tap exit functionality

## Technical Implementation

### Architecture
- **SwiftUI** for modern UI development
- **MVVM** (Model-View-ViewModel) architecture
- **Protocol-oriented programming** with Swift best practices
- **Combine** framework for reactive programming

### Key Components
- `RandomNumberViewModel`: Business logic and state management
- `SpeechHelper`: Voice synthesis and audio management
- `ConfettiHelper`: Animation and visual effects
- `SettingsModel`: Data persistence and configuration
- `ImagePicker`: Photo library integration

### Performance
- Efficient memory management
- Optimized animations and transitions
- Background task handling
- Proper state restoration

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.0+

## Installation

1. Clone the repository
2. Open `WinniLuckRandom.xcodeproj` in Xcode
3. Build and run on your iOS device or simulator

## Usage

1. **Setup**: Configure your number range (1-100) and repetition count
2. **Customize**: Set winner count and enable/disable voice & confetti
3. **Background**: Choose a custom background image (optional)
4. **Play**: Tap the golden coin to start the automatic lottery
5. **Results**: Watch numbers compete to reach the target in real-time
6. **Winners**: Celebrate the numbers that reached the goal first

## Localization

- Full Spanish language support
- Proper NSLocalizedString implementation
- Cultural considerations for Latin American users

## Contributing

This project follows Apple's Human Interface Guidelines and iOS development best practices. Feel free to contribute improvements or new features.

## License

© 2024 WinniLuckRandom. All rights reserved. 