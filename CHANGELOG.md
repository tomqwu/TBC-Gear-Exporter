# Changelog

All notable changes to TBC Gear Exporter are tracked here.

## [Unreleased]

- Add item quality colors and colored item names to saved snapshots and exports.
- Add TBC Wowhead item URLs to saved item snapshots and AI/JSON/Markdown/Text exports.
- Fix Gear Only exports so consumables/food with `INVTYPE_NON_EQUIP_IGNORE` are not misclassified as gear.
- Add export format options for AI Text, JSON, Markdown, and plain Text in the GUI and slash commands.
- Add `/tbcgear json`, `/tbcgear markdown`, `/tbcgear text`, and `export <format>` command support.
- Make scan/export behavior explicit: scans persist snapshots and counts into `TBCGearExporterDB`, while export opens a popup from the saved local DB.
- Add a dedicated `Export` GUI action for opening/selecting saved AI-ready text without doing another hidden scan.
- Prefer `C_Container` over legacy bag APIs, fixing clients where legacy calls exist but report zero slots.
- Add visible scan count messages and `/tbcgear debug` diagnostics for API, slot, and item-link visibility.
- Rework the export GUI into a compact opaque panel with item counts, clearer controls, debug, and select actions.
- Use `BackdropTemplate` when available so the export window has a readable background on current clients.
- Bump TBC Anniversary addon interface metadata to `20505`.
- Add a minimap button that opens the AI export GUI on left-click and scans bags/bank on right-click.
- Add GitHub release packaging that builds a WoW-ready addon zip from `TBCGearExporter/`.
- Add package metadata for addon packagers.
- Document the local Anniversary-client install mirror step.

## [0.1.0] - 2026-06-06

- Add a TBC Classic bag and bank scanner with SavedVariables snapshots.
- Add an in-game GUI that auto-selects AI-ready export text.
- Export structured JSON data with character info, scan timestamps, categories, items, locations, links, and stat arrays.
- Scan bags and bank on open and print chat debug lines.
- Add local Lua tests with a 99% line coverage gate.
