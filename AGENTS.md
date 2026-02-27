# Pulse Project Memory

## Project Overview
Pulse is a private iOS journaling app for logging “moments” when a user feels an urge, capturing intensity, response, tags, notes, and contextual metadata like time, location, and weather. The app focuses on fast entry and reflection.

## Architecture Decisions
- SwiftUI-first architecture with feature-oriented folders.
- SwiftData `@Model` entities (`Moment`, `Urge`, `Tag`) for persistence.
- Lightweight view-model layer (`Core/ViewModels`) for edit/log/list workflows.
- Use-case boundary for creation flow (`CreateMomentUseCase`) to keep orchestration logic out of views.
- Services abstracted behind protocols where useful (weather/location).

## Conventions And Patterns
- Use `@State private var` for local SwiftUI state and `@Observable` view models for mutable screen state.
- Prefer async/await for asynchronous work.
- Keep feature UI under `Features/*`, cross-cutting code in `Core/*`, and domain models in `Domain/*`.
- Keep model mutations centralized in view models/use-cases.

## Build And Run
- Open the workspace/project in Xcode.
- Build using the active Pulse scheme for iOS Simulator.
- Run tests from `PulseTests` and `PulseUITests` targets.

## Quirks And Gotchas
- Some screens rely on environment-provided `ModelContext`; previews use in-memory containers.
- Weather/location data is optional and should never block moment creation or editing.
- Keep edit screens resilient to partial data (nil notes/tags/location/weather).
