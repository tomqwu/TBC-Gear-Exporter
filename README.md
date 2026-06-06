# TBC Gear Exporter

[![Tests](https://github.com/tomqwu/tbc-wow-list-gears/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tomqwu/tbc-wow-list-gears/actions/workflows/test.yml)
![Lua 5.1](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua&logoColor=white)
![WoW AddOn](https://img.shields.io/badge/WoW-TBC%20Classic-C69B6D)
![TBC Anniversary](https://img.shields.io/badge/client-Anniversary-0E8A16)
![Tests](https://img.shields.io/badge/tests-24%20passing-brightgreen)
![Coverage](https://img.shields.io/badge/coverage-99.54%25-brightgreen)
![Coverage Gate](https://img.shields.io/badge/coverage%20gate-99%25-blue)
![Local Install](https://img.shields.io/badge/local%20install-PowerShell-5391FE?logo=powershell&logoColor=white)

A small World of Warcraft TBC Classic addon that saves the current character's bag and bank items, groups them into categories, lists item stats, and shows a GUI with an auto-selected AI-ready text export.

## Install

1. Copy the `TBCGearExporter` folder into the AddOns folder for the client you play on, for example:
   `World of Warcraft/_classic_/Interface/AddOns/TBCGearExporter`
2. Restart the game or run `/reload`.
3. Enable **Load out of date AddOns** if your TBC Anniversary client uses a newer interface number than the one in `TBCGearExporter.toc`.

For this local machine, install or refresh the Anniversary client copy with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-local.ps1
```

## Commands

- `/tbcgear gui` opens the export GUI.
- `/tbcgear export` opens the export GUI with bags and the last saved bank scan.
- `/tbcgear bags` exports bag items only.
- `/tbcgear bank` exports the last saved bank scan.
- `/tbcgear gear` exports only gear from bags and bank.
- `/tbcgear scan` refreshes bag data. If your bank is open, it refreshes bank data too.
- `/tbcgear clear` clears this character's saved bag and bank snapshots.

WoW only exposes bank contents to addons while the bank is open. Open your bank once after installing, or any time you want the bank snapshot refreshed.

The export box auto-selects text formatted for AI tools: a short instruction header followed by structured `DATA_JSON` containing character info, scan timestamps, categories, items, and stat arrays.

Opening a bag scans bag contents and prints a debug line in chat. Opening the bank scans bank contents and prints a matching debug line.

## Tests

Run the local WoW API mock suite with:

```sh
lua tests/run.lua
```

The test runner includes a line coverage gate of 99% for `TBCGearExporter.lua`.
