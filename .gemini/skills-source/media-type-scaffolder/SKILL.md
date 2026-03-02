---
name: media-type-scaffolder
description: Automates the end-to-end integration of new media types (e.g., "Playlists" or "Episodes"). Use when adding support for a new category of audio content from the Spotify API.
---

# Media Type Scaffolder

This skill handles the complex mapping and boilerplate required to add new media types to the ListenList project.

## Workflow

1.  **Domain Model**: Add the new type to `IdentifiableTypes.swift`.
2.  **DTOs**: Create a corresponding DTO in `DTOs.swift` with mapping logic.
3.  **Database**: Add `add[Type]`, `delete[Type]`, and `log[Type]AsCompleted` methods to `DatabaseManager.swift`.
4.  **UI Boilerplate**: Generate `GridCard` and `DetailView` for the new type.

## References
- See [SCHEMA.md](references/SCHEMA.md) for domain model templates.
