# 🧋 Boba — Budget App

A premium, warm-toned iOS budgeting app built natively in Swift.

## Features

- **Safe to Spend** — Know at a glance how much you can spend
- **4 Budget Methods** — Envelope, 50/30/20, Zero-Based, Pay Yourself First
- **Multi-Account** — Track checking, savings, credit cards, cash
- **Multi-Currency** — 20+ currencies with auto-detect
- **Apple Shortcuts** — Log expenses with Siri, check budgets by voice
- **Widgets** — Home screen & lock screen widgets
- **Swift Charts** — Beautiful spending analytics and reports
- **Biometric Lock** — Face ID / Touch ID security
- **Smart Notifications** — Friendly, shame-free budget alerts

## Tech Stack

| Layer | Technology |
|:---|:---|
| UI | SwiftUI (iOS 17+) |
| Architecture | MVVM + Repository Pattern |
| Persistence | SwiftData |
| Charts | Swift Charts |
| Shortcuts | App Intents Framework |
| Widgets | WidgetKit |
| Auth | LocalAuthentication |

## Color Palette

| Name | Hex | Usage |
|:---|:---|:---|
| Shadow Grey | `#221d23` | Primary background |
| Deep Walnut | `#4f3824` | Secondary surfaces |
| Fiery Terracotta | `#d1603d` | Primary accent, CTAs |
| Metallic Gold | `#ddb967` | Highlights, warnings |
| Lime Cream | `#d0e37f` | Positive states, income |

## Getting Started

### Prerequisites
- Xcode 16+
- iOS 17+ device or simulator
- XcodeGen (optional, for project generation)

### Setup

**Option A: Using XcodeGen (recommended)**

```bash
# Install XcodeGen
brew install xcodegen

# Generate Xcode project
cd budget-app
xcodegen generate

# Open in Xcode
open Boba.xcodeproj
```

**Option B: Manual Xcode setup**

1. Open Xcode → File → New → Project → iOS App
2. Name it "Boba", set bundle ID to `com.juszuf.boba`
3. Drag the `Boba/` folder into the project
4. Add `BobaWidgets/` as a Widget Extension target
5. Build and run

### Apple Shortcuts

After installing, these Siri phrases work automatically:

- *"Hey Siri, log $15 for coffee in Boba"*
- *"Hey Siri, how's my food budget in Boba?"*
- *"Hey Siri, what can I spend today in Boba?"*
- *"Hey Siri, my spending this month in Boba"*

## Project Structure

```
Boba/
├── BobaApp.swift              — App entry point
├── ContentView.swift          — Root tab navigation
├── Design/                    — Theme, typography, reusable components
├── Models/                    — SwiftData @Model entities
├── ViewModels/                — @Observable MVVM view models
├── Views/                     — All screens (Dashboard, Transactions, etc.)
├── Repositories/              — Data access layer
├── Services/                  — Notifications, biometrics, currency
├── Intents/                   — Apple Shortcuts (App Intents)
├── Utilities/                 — Extensions, haptics
└── Resources/                 — Assets, localization
```

## License

Private project — all rights reserved.
