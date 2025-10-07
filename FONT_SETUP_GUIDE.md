# Figtree Font Integration Guide

## Step 1: Add Font Files to Project
Place your downloaded Figtree font files in: `/Broccoli/Resources/Fonts/`

Required font weights:
- Figtree-Regular.ttf
- Figtree-Medium.ttf
- Figtree-SemiBold.ttf
- Figtree-Bold.ttf
- Figtree-ExtraBold.ttf

## Step 2: Add to Xcode Project
1. Drag font files from Finder into Xcode's Resources/Fonts folder
2. Ensure "Add to target" is checked for your main app target
3. Verify files appear in your project navigator

## Step 3: Update Info.plist
Add the following to your Info.plist (or build settings):
```xml
<key>UIAppFonts</key>
<array>
    <string>Figtree-Regular.ttf</string>
    <string>Figtree-Medium.ttf</string>
    <string>Figtree-SemiBold.ttf</string>
    <string>Figtree-Bold.ttf</string>
    <string>Figtree-ExtraBold.ttf</string>
</array>
```

## Step 4: Apply Theme to Your App
Update your BroccoliApp.swift to inject the theme:

```swift
import SwiftUI

@main
struct BroccoliApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appTheme, AppTheme.default)
        }
    }
}
```

## Step 5: Use in SwiftUI Views
Example usage in any SwiftUI view:

```swift
struct MyView: View {
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack {
            Text("Welcome to Broccoli")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
            
            Text("Your health, simplified")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .padding(theme.spacing.lg)
    }
}
```

## ✅ What's Already Set Up
- Font+App.swift extension with Figtree font methods
- Color+App.swift extension with app color palette
- Theme system updated to use Figtree fonts
- AppTypography configured with proper font weights and sizes

## 🎯 Next Steps
1. Copy your Figtree .ttf files to Resources/Fonts/
2. Add them to your Xcode project
3. Update Info.plist with font names
4. Apply theme to your app root
5. Start using the theme in your views!

Note: Make sure to add the font files to your Xcode target when importing.
