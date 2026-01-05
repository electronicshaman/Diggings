# Project Status: Early Stage / Green Field
- **Backward Compatibility:** EXPLICITLY FORBIDDEN. Do not use wrappers, adapters, or "legacy" patterns to preserve old APIs.
- **Refactoring Strategy:** If a change requires an API break, perform a "clean sweep" refactor. Update all call sites and dependencies immediately.
- **Code Hygiene:** Prioritize "Clean Code" over speed. Avoid tech debt, temporary hacks, or "TODO" shortcuts.
- **Technology Stack:** Godot 4.5 (GDExtension/GDScript). Use modern features (e.g., Stencil Buffer, Typed Arrays) as the default.