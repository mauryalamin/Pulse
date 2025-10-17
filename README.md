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
