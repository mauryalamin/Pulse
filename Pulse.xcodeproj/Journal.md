# Pulse Journal

## The Big Picture
Pulse is a private journaling app for urge moments. Think of it as a pocket-sized checkpoint: quick capture in the moment, then honest reflection later.

## Architecture Deep Dive
The app is split like a calm, well-run kitchen:
- `Features/*` are the stations where dishes are plated (views).
- `Core/ViewModels` and use-cases are expediters coordinating timing and rules.
- `Domain/Models` are the pantry ingredients persisted with SwiftData.

Privacy lock behavior now follows an opt-in policy:
- `AppLockManager` acts as the front door bouncer.
- It only blocks entry if the user explicitly enables Face ID.
- If Face ID is not enabled, the app stays accessible with no lock overlay.

## The Codebase Map
Main areas:
- `Pulse/App`: app lifecycle and root scene (`PulseApp.swift`)
- `Pulse/Core/Privacy`: lock/auth policy (`AppLockManager.swift`)
- `Pulse/Features/Onboarding`: onboarding steps and opt-in entry point
- `Pulse/Features/Home`: primary app shell and lock blur overlay
- `Pulse/Features/Settings`: Face ID preference toggle

## Tech Stack & Why
- SwiftUI for fast iteration and feature-oriented UI composition.
- SwiftData for local-first persistence with simple model definitions.
- LocalAuthentication for Face ID, because privacy happens on-device without external services.
- Observation (`@Observable`) for lightweight shared app state.

## The Journey
### 2026-03-06 - Face ID opt-in roadblock fix
Bug story:
- The app lock was effectively mandatory. Even users who never opted in could hit a lock gate because lock UI and auth flow always assumed biometrics were required.

What changed:
- Added opt-in aware policy to `AppLockManager`:
  - New `isBiometricsEnabled` + `shouldLockUI`.
  - `authenticate()` now immediately unlocks when biometrics are disabled.
  - Background/foreground lock transitions run only when biometrics are enabled.
  - New `requestBiometricsOptIn()` prompts Face ID and only persists opt-in on success.
- Wired onboarding button behavior:
  - `OnboardingStepThreeView` now triggers the Face ID prompt from `Enable Face ID`.
- Updated root and home lock overlays:
  - `PulseApp` and `HomeView` now show lock blur/overlay only when `shouldLockUI` is true.

Aha moment:
- The critical fix wasn’t just “don’t authenticate on launch.” The lock UI condition itself had to be preference-aware, or users still get blocked visually.

Pitfall to avoid:
- Any future lock UI should key off `shouldLockUI`, not raw `isUnlocked`.

## Engineer's Wisdom
- Privacy controls should be explicit user choice, never implicit default lockouts.
- Centralize policy (`shouldLockUI`) so UI doesn’t duplicate auth logic across screens.
- Persist opt-in only after successful authentication when possible.

## If I Were Starting Over...
- I’d define a single `LockPolicy` type on day one (`.off`, `.biometricOptional`, `.biometricRequired`) and keep all root UI gating derived from it.
- I’d also add a small integration test around onboarding -> home launch without biometrics enabled to prevent regressions.
