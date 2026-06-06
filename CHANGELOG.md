# Changelog

All notable changes to TBC Gear Exporter are tracked here.

## [Unreleased]

- Add `C_Container` bag API compatibility for TBC Anniversary clients that no longer expose legacy `GetContainer*` globals.
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
