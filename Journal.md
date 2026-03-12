# Journal.md

## 1) The Big Picture
Pulse is your private pressure-release notebook for urges. When a moment hits, you log what happened fast: the urge, intensity, whether you stayed present or followed it, plus context like tags, notes, weather, and place. The app is designed like a quiet co-pilot: no noise, just useful reflection.

## 2) Architecture Deep Dive
Think of Pulse like a restaurant kitchen:
- `SwiftData` models are the pantry where raw ingredients live (`Moment`, `Urge`, `Tag`).
- View models are the line cooks deciding what gets prepped for each plate.
- Use cases are the expediter calling out the order of operations so screens stay clean.

For Insights, we added a new plating layer: precomputed payload structs. They are not storage models and not UI. They are the ready-to-serve dishes for teaser cards and the full Insights screen.

## 3) The Codebase Map
- `Pulse/Pulse/Domain/Models`: core domain entities and domain enums.
- `Pulse/Pulse/Core`: services, view models, use cases, utilities.
- `Pulse/Pulse/Features`: SwiftUI feature screens and components.
- `Pulse/Pulse/Domain/Models/Insights`: new Insights payload model layer.

## 4) Tech Stack & Why
- SwiftUI for feature screens because iteration speed matters.
- SwiftData for local-first persistence because privacy and offline behavior are core.
- Async/await patterns to keep async workflows readable and testable.
- Plain Swift structs/enums for Insights payloads because they are lightweight, `Codable`-friendly, and safe to pass between layers.

## 5) The Journey
### 2026-03-10 - Story 1: Define Insights Data Models
We laid the foundation for premium Insights without touching UI or computation yet.

What we added:
- `InsightsPeriod` for date windows (`last7Days`, `last30Days`, `custom`).
- `InsightsSnapshot` as the full precomputed payload container.
- `InsightsSummary`, `InsightFactoid`, `InsightObservation` for narrative and teaser content.
- Activity/time pattern models (`ActivityDataPoint`, `TimePatternSummary`, `TimeBucketInsight`, `TimeBucket`).
- Ranking/breakdown models (`TagInsight`, `UrgeBreakdownItem`).
- State/source enums (`InsightsDataState`, `InsightTextSource`, `ObservationSignalKind`, `InsightFactoidKind`).

Aha moment:
- Keeping Insights as plain domain payloads avoids coupling charts or premium gating logic into persistence and keeps Story 2 computation work straightforward.

Pitfall avoided:
- Reusing SwiftData `@Model` classes directly in insights payloads would create unnecessary coupling and reduce portability. We stayed with value types.

### 2026-03-10 - Story 2: Build Insights Computation Service
This was the \"turn ingredients into plated meals\" phase. We already had the Insights containers; now we taught Pulse how to fill them with deterministic data from raw moments.

What we added:
- `InsightsComputationService` as a synchronous, testable service that maps `[Moment] + InsightsPeriod` into `InsightsSnapshot`.
- Period filtering plus previous-period comparison window support for trend-style factoids.
- Deterministic computations for:
  - Data state (`empty`, `insufficientData`, `ready`)
  - Factoid candidates with eligibility flags
  - Day-by-day activity series
  - Time-of-day bucket summaries
  - Top tags and urge breakdown percentages
  - Template-based observations grounded in multi-signal patterns
  - Template summary fallback text

Aha moment:
- Treating observation generation as \"structured evidence + safe templates\" gives us useful narrative now, while keeping the door open for Foundation Models later without changing payload contracts.

Pitfalls avoided:
- No AI text generation in this layer, so behavior is deterministic and easy to test.
- No UI assumptions leaked into compute logic.
- Sparse-data guards prevent overconfident statements when context fields (location/weather/tags) are thin.

### 2026-03-11 - Story 3 Slice: By the Numbers Teaser on Home
Today we put a front counter in the restaurant: a compact \"By the Numbers\" teaser at the top of the Moments screen.

What shipped:
- A reusable `InsightsTeaserView` that renders from `InsightsSnapshot` (not raw moments).
- A small display mapper model (`InsightsTeaserFactoidItem`) to keep view-body logic lean.
- Home screen integration that replaces the old `FactoidGroupView()` placeholder.
- Teaser states for `.empty`, `.insufficientData`, `.ready`, and `.locked`.
- Liquid Glass styling using SwiftUI’s native `glassEffect(_:in:)`, matching the app’s existing glass usage.

Aha moment:
- Moving snapshot creation into `MomentsListViewModel` kept HomeView declarative and made the teaser almost plug-and-play for future navigation.

Gotcha:
- The teaser currently reflects the same filtered moment set used by the list. That’s coherent for now, but product may want global-period insights independent of list filters in a later story.

### 2026-03-12 - Story 4: Full Insights Screen Skeleton
This was the dining room build-out. We had appetizers (the teaser), now we needed the full table service: all sections, one coherent flow, and clear states for empty/sparse/ready/locked.

What shipped:
- A dedicated `InsightsView` screen powered directly by `InsightsSnapshot`.
- Modular section views in approved order:
  - Weekly Summary
  - By the Numbers
  - Activity
  - Time Patterns
  - What Stood Out
  - Top Tags / Common Contexts
  - Urge Breakdown
- State-aware rendering for `.empty`, `.insufficientData`, `.ready`, `.locked`.
- Navigation wiring from the Home teaser tap into the new full Insights destination.

Aha moment:
- Building one reusable section-card container kept the screen consistent and made each section small, testable, and swappable.

Pitfall avoided:
- No raw `Moment` computation leaked into SwiftUI. The view reads snapshot data only, preserving the compute/UI boundary from Story 2.

## 6) Engineer's Wisdom
- Keep persisted entities and computed read models separate.
- Make payloads explicit, typed, and boring; computation can be fancy later.
- Add `Sendable` and `Codable` early when payloads may cross concurrency boundaries or caching layers.

## 7) If I Were Starting Over...
I would define Insights payload contracts even earlier, before any chart UI. Once contracts exist, UI and compute teams can move in parallel without stepping on each other.
