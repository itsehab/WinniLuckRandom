//
//  DeviceInfo.swift
//  WinniLuckRandom
//
//  Created by Ehab Fayez on 23/07/25.
//

import SwiftUI

extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

extension View {
    /// Applies different modifiers based on whether the device is iPad or iPhone
    @ViewBuilder
    func adaptiveStyle<iPad: View, iPhone: View>(
        iPad: () -> iPad,
        iPhone: () -> iPhone
    ) -> some View {
        if UIDevice.isIPad {
            iPad()
        } else {
            iPhone()
        }
    }

    
    /// Provides adaptive padding based on device type
    func adaptivePadding(
        iPadPadding: CGFloat = 40,
        iPhonePadding: CGFloat = 20
    ) -> some View {
        self.padding(.horizontal, UIDevice.isIPad ? iPadPadding : iPhonePadding)
    }
    
    /// Provides adaptive font size based on device type
    func adaptiveFontSize(
        _ baseSize: CGFloat,
        iPadMultiplier: CGFloat = 1.3
    ) -> some View {
        let fontSize = UIDevice.isIPad ? baseSize * iPadMultiplier : baseSize
        return self.font(.system(size: fontSize))
    }
}

// Screen size helpers
extension UIScreen {
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    static var isLandscape: Bool {
        screenWidth > screenHeight
    }
    
    static var isCompact: Bool {
        screenWidth < 768
    }
}

// Adaptive sizing helpers
struct AdaptiveSize {
    static func cardWidth(for screenWidth: CGFloat) -> CGFloat {
        if UIDevice.isIPad {
            return min(400, screenWidth * 0.7)
        } else {
            return screenWidth * 0.85
        }
    }
    
    static func gridColumns(for screenWidth: CGFloat) -> Int {
        if UIDevice.isIPad {
            return screenWidth > 1000 ? 4 : 3
        } else {
            return 2
        }
    }
    
    static func buttonHeight() -> CGFloat {
        UIDevice.isIPad ? 60 : 50
    }
    
    static func minimumTouchTarget() -> CGFloat {
        44 // Apple's recommended minimum touch target
    }
} 