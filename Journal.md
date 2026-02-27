# Journal

## The Big Picture
Pulse is like a low-friction “black box” for cravings. You log what happened, how strong it felt, whether you followed through, and the context around it. Later, patterns emerge: times, places, feelings, and triggers.

## Architecture Deep Dive
Think of the app like a restaurant kitchen:
- SwiftUI Views are the front-of-house. They take orders from taps and text fields.
- ViewModels are the line cooks. They prep and transform user input into clean model updates.
- SwiftData Models are the pantry and walk-in fridge. They hold durable state.
- Services (weather/location/notifications) are suppliers bringing external ingredients when available.
- Use cases are the head chef recipes, especially for logging a new moment with optional context enrichment.

## The Codebase Map
- `Pulse/App`: app entry point.
- `Pulse/Domain`: core model types and seed defaults.
- `Pulse/Features`: screen-by-screen UI (Home, LogMoment, Moments, Onboarding, Settings).
- `Pulse/Core/ViewModels`: mutable screen state and save/update flows.
- `Pulse/Core/Services`: integrations (location, weather, notifications).
- `Pulse/Core/Utilities` and `Core/DesignSystem`: formatting, helpers, and reusable UI behavior.
- `PulseTests` and `PulseUITests`: unit and UI coverage.

## Tech Stack & Why
- SwiftUI: fast iteration for feature-heavy forms and detail screens.
- SwiftData: natural fit for model-driven apps with relational data (`Moment` ↔ `Tag`/`Urge`).
- Observation (`@Observable`): simpler, modern state flow without heavy boilerplate.
- Async/await: easier-to-reason-about async flows (weather/location fetch and save choreography).

## The Journey
### 2026-02-27 - Context Editing, But Keep the Main Screen Calm
- Feature: converted the bottom “Around This Moment” area in `EditMomentView` into tappable value rows, matching the compact pattern used in design.
- Bug/pitfall: inline controls (date pickers + weather controls) made the edit screen feel crowded and harder to scan.
- Fix:
  - Replaced inline Date/Time, Weather, and Location UI with tappable rows.
  - Added a dedicated Date/Time sheet with draft state and explicit Save.
  - Added a dedicated Weather sheet for condition + temperature adjustments with explicit Save.
  - Made Location row tappable and routed it to a placeholder sheet for future location editing.
- Lesson: dense edit screens work better when high-frequency fields stay inline and contextual metadata moves behind focused sub-flows.

### 2026-02-27 - Weather Control, Not Weather Fate
- Feature: `EditMomentView` can now edit a moment’s weather snapshot directly (condition + temperature).
- Bug/pitfall: the screen showed weather context but treated it like museum glass, so incorrect captures were stuck forever.
- Fix:
  - Added editable weather state to `EditMomentViewModel`: `hasWeatherSnapshot`, `weatherCode`, and `temperatureCelsius`.
  - Persisted weather edits in `save(in:)`, including the ability to clear weather entirely.
  - Replaced the read-only weather row in `EditMomentView` with:
    - a toggle to include/remove weather snapshot
    - a condition picker backed by `WeatherSnapshot.codeDescription`
    - a temperature stepper with localized display formatting
- Lesson: context fields are still first-class data. If users can trust them for reflection, they must be correctable.

### 2026-02-27 - Time Travel Fix (The Useful Kind)
- Feature: added date and time editing in `EditMomentView`.
- Bug/pitfall: editing a moment let you change almost everything except when it actually happened, which made historical corrections impossible.
- Fix:
  - Added editable `timestamp` state to `EditMomentViewModel`.
  - Wired `save(in:)` to persist `originalMoment.timestamp`.
  - Added separate Date and Time pickers in `EditMomentView`.
  - Updated contextual timestamp display to reflect in-progress edits.
- Lesson: if a screen says “Edit,” users assume all core fields are editable unless clearly labeled read-only.

## Engineer's Wisdom
- Keep domain truth in one place: mutation happens in view models/use-cases, not ad-hoc across views.
- Optional data should degrade gracefully. Context is a bonus, not a blocker.
- UI promises matter. If an edit form exposes a concept (like timestamp), it should be editable or explicitly immutable.

## If I Were Starting Over...
- I would define editable-field parity checks early (Create vs Edit) to avoid capability drift.
- I would add targeted tests for edit persistence of every primary `Moment` field, especially timestamp and relational fields.
