# 🫀 Pulse – Craving & Urge Tracker  
*Private, fast, and supportive.*

Pulse helps users quickly and privately log urges related to vices such as alcohol, drugs, gambling, or sex — with no tracking, no judgment, and full local control.

Built for **iOS 26** using **SwiftUI + SwiftData**, Pulse prioritizes:
- **Speed:** One-tap logging, Siri Shortcuts, and widgets.
- **Privacy:** Local-only storage, Face ID lock, and Stealth Mode.
- **Support:** Insightful trends, contextual data capture, and gentle encouragement.

---

## 🧱 Architecture

Pulse follows a **modern MVVM-lite architecture** tuned for SwiftUI’s state-driven design:

| Layer | Responsibility | Example |
|-------|----------------|---------|
| **Domain** | Core SwiftData models and seeds. | `Moment`, `Urge`, `Tag` |
| **Features** | Independent UI + logic bundles per app area. | `LogMoment`, `Moments`, `Onboarding`, `Settings` |
| **Core** | Shared services and utilities. | `AppLockManager`, `WeatherProvider`, `LocationManager` |
| **App** | Entry point and composition root. | `PulseApp.swift` |

Each feature includes its own subcomponents (views, helpers, and localized view models).  
Shared UI patterns and theming live in **Core/DesignSystem**.

---

## 📁 Folder Structure
Pulse/
└─ Pulse/
├─ App/
│  └─ PulseApp.swift
│
├─ Domain/
│  ├─ Models/                 # SwiftData @Model types
│  └─ Seed/                   # Default urges/tags
│
├─ Features/
│  ├─ Home/
│  ├─ LogMoment/
│  │  └─ Components/
│  ├─ Moments/
│  │  └─ Components/
│  ├─ Onboarding/
│  │  └─ Components/
│  └─ Settings/
│     └─ Components/
│
├─ Core/
│  ├─ Privacy/                # Face ID & blur overlay
│  ├─ Services/               # Weather, Location, Notifications
│  ├─ DesignSystem/           # Reusable views, colors, blur, typography
│  └─ Utilities/              # Extensions, small helpers
│
├─ Resources/                 # Assets & Info.plist
└─ Deprecated/                # Legacy files staged for removal

---

## 🔐 Privacy Principles

1. **All data stays local.** No cloud sync, analytics, or external APIs store user data.
2. **Optional Face ID lock** guards access at launch.
3. **Stealth Mode** hides sensitive visuals and uses neutral app icons.
4. **Widgets & notifications** respect redaction — no identifiable information displayed.

---

## ⚙️ Build & Run

- **Platform:** iOS 26 +  
- **Frameworks:** SwiftUI, SwiftData, CoreLocation  
- **Languages:** Swift 6 +  
- **Minimum Xcode:** 16.0 (Stable Release)

### Run steps
1. Open `Pulse.xcodeproj` (or workspace if present).
2. Select the `Pulse` target.
3. Choose an iOS 26 simulator or device.
4. `⌘R` to build and run.

All data is stored locally via SwiftData — deleting the app clears it.

---

## 🧠 Development Notes

- **Observation:** Uses new `@Observable` macro for view models instead of `ObservableObject`.
- **Feature flags:** MVP and premium options toggled via `FeatureFlags.swift`.
- **Context capture:** Weather and location snapshots are collected only when user grants permission.
- **Testing:** Includes `PulseTests`, `PulseUITests`, and snapshot tests for key components.

---

## 🚀 Roadmap (High-Level)

| Phase | Focus |
|-------|--------|
| **1. Privacy & Protection** | Face ID, Stealth Mode, local encryption, blur overlay |
| **2. Search & Calendar** | Full-text search, contextual event tagging |
| **3. Reflection & Trends** | Insights view, streaks, data export |
| **4. Premium Layer (Optional)** | Reflection journaling, guided exercises |

---

## 🤝 Contribution Guidelines

- Follow Swift’s [API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).  
- Keep features modular — new screens belong under `Features/<FeatureName>/`.  
- Use `@Observable` for state, prefer async/await, and isolate side effects in `UseCase` or `Service` types.  
- Never introduce networking or analytics that compromise privacy.  

---

## 🧩 Credits

**Design & Product:** [Maury Alamin - Touch Digital]  
**Engineering Partner:** ChatGPT (GPT-5, iOS Engineering Mode)  
**Special Thanks:** Early testers and UX collaborators who shaped Pulse’s supportive tone.

---

© 2025 Pulse. All rights reserved.  
This app is open-source for educational demonstration purposes — please respect user privacy in any derivative work.
