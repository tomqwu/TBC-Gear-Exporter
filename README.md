# TBC Gear Exporter

[![Tests](https://github.com/tomqwu/tbc-wow-list-gears/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tomqwu/tbc-wow-list-gears/actions/workflows/test.yml)
![Lua 5.1](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua&logoColor=white)
![WoW AddOn](https://img.shields.io/badge/WoW-TBC%20Classic-C69B6D)
![TBC Anniversary](https://img.shields.io/badge/client-Anniversary-0E8A16)
![Tests](https://img.shields.io/badge/tests-32%20passing-brightgreen)
![Coverage](https://img.shields.io/badge/coverage-99.36%25-brightgreen)
![Coverage Gate](https://img.shields.io/badge/coverage%20gate-99%25-blue)
![Local Install](https://img.shields.io/badge/local%20install-PowerShell-5391FE?logo=powershell&logoColor=white)

A small World of Warcraft TBC Classic addon that saves the current character's bag and bank items, groups them into categories, lists item stats, adds TBC Wowhead links and quality colors for every item, and shows a GUI with an auto-selected AI-ready text export.

## Install

1. Download the latest zip from the [Releases page](https://github.com/tomqwu/tbc-wow-list-gears/releases).
2. Extract the `TBCGearExporter/` folder, the one containing `TBCGearExporter.toc`, into your WoW AddOns directory:
   - **TBC Classic / Anniversary**: `<WoW install>/_anniversary_/Interface/AddOns/`
   - **Windows example**: `F:\World of Warcraft\_anniversary_\Interface\AddOns\TBCGearExporter`
3. Restart the game or run `/reload`.
4. Look for the small bag icon on the minimap, or run `/tbcgear gui`.

For this local machine, install or refresh the Anniversary client copy with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-local.ps1
```

When I create a GitHub release or tag from this workspace, I also run that local install command so your `F:\World of Warcraft\_anniversary_\Interface\AddOns` copy stays in sync.

## First-run checklist

```text
/tbcgear scan    -- scan visible bags and save the snapshot to TBCGearExporterDB
/tbcgear export  -- open the export popup from the saved local DB
/tbcgear json    -- open the export popup in JSON format
/tbcgear markdown -- open the export popup in Markdown format
/tbcgear text    -- open the export popup in plain text format
/tbcgear debug   -- print bag API, slot, and first item-link diagnostics
/tbcgear gear    -- export only gear from bags and saved bank snapshot
/tbcgear gear epic -- export only epic-quality gear
/tbcgear rare+ text -- export rare-or-better items in plain text
```

Open the bank once and scan while it is open so the addon can save the bank snapshot. WoW only exposes bank contents to addons while the bank is open.

The minimap bag icon opens the export popup on left-click. Right-click scans and saves bags, and also saves bank contents if the bank is currently open.

## Commands

- `/tbcgear gui` opens the export popup from the saved local DB.
- `/tbcgear export` opens the export popup with bags and the last saved bank scan in AI Text format.
- `/tbcgear export json`, `/tbcgear export markdown`, and `/tbcgear export text` open the same saved data in that format.
- `/tbcgear json`, `/tbcgear markdown`, and `/tbcgear text` are shortcuts for exporting all saved data in those formats.
- `/tbcgear bags` exports bag items only.
- `/tbcgear bank` exports the last saved bank scan.
- `/tbcgear gear` exports only real equippable gear from bags and bank; consumables/food with non-equip placeholder slots are excluded.
- `/tbcgear gear epic` exports only epic-quality gear.
- `/tbcgear rare+`, `/tbcgear epic`, and `/tbcgear export gear epic json` apply quality filters before export.
- `/tbcgear scan` saves visible bag data into `TBCGearExporterDB`. If your bank is open, it saves bank data too.
- `/tbcgear debug` prints the detected bag API, visible bag slots, saved counts, and first visible item link.
- `/tbcgear clear` clears this character's saved bag and bank snapshots.

The export panel pops up from saved `TBCGearExporterDB` data. It shows saved bag/bank counts, scan/debug controls, an `Export` action, format buttons for **AI**, **JSON**, **Markdown**, and **Text**, filter buttons for **All Q**, **Rare+**, **Epic**, and **Gear Epic**, and an auto-selected text box containing a class-aware AI prompt, character info, local DB metadata, scan timestamps, categories, export filters, items, item links, TBC Wowhead URLs, item level, quality color, colored item names, and stat arrays.

AI Text exports begin with an `AI_PROMPT` block before `DATA_JSON`. JSON exports include the same instructions under `ai_prompt`, so external GenAI tools can consume either the prompt text, the structured data, or both. The prompt uses the character class to add role lenses, for example Druid bear mitigation/threat, cat DPS, Restoration healing, and Balance caster analysis.

Item names use WoW quality colors, such as rare blue and epic purple. Item level remains a numeric field, while item type/category remains a separate classification for AI analysis.

On login, the addon prints a loaded message with item and slot counts. Opening a bag scans bag contents and prints a debug line in chat. Opening the bank scans bank contents and prints a matching debug line.

## Tests

The addon is pure Lua and headless-testable. The suite stubs the WoW API surface it needs.

```sh
lua tests/run.lua
luac -p TBCGearExporter/TBCGearExporter.lua
```

CI runs syntax checks for every Lua file and the local WoW API mock suite on every push to `main` and every pull request. The test runner includes a line coverage gate of 99% for `TBCGearExporter.lua`.

## Release workflow

This repo follows the same shape as `ArenaCoachTBC`:

- Every `main` push builds a prerelease zip like `TBCGearExporter-v0.1.0-dev.<run>.zip`.
- Stable tags named `v*`, for example `v0.1.0`, build a GitHub Release using notes from `CHANGELOG.md`.
- The release zip contains the addon folder as the top-level entry, so extraction into `Interface/AddOns/` works directly.
- Local release mirroring is done with `scripts/install-local.ps1` because GitHub Actions cannot access your `F:\` drive.
