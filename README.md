# TBC Gear Exporter

A small World of Warcraft TBC Classic addon that saves the current character's bag and bank items, groups them into categories, lists item stats, and shows a copyable text export in game.

## Install

1. Copy the `TBCGearExporter` folder into the AddOns folder for the client you play on, for example:
   `World of Warcraft/_classic_/Interface/AddOns/TBCGearExporter`
2. Restart the game or run `/reload`.
3. Enable **Load out of date AddOns** if your TBC Anniversary client uses a newer interface number than the one in `TBCGearExporter.toc`.

## Commands

- `/tbcgear export` opens a copyable export window with bags and the last saved bank scan.
- `/tbcgear bags` exports bag items only.
- `/tbcgear bank` exports the last saved bank scan.
- `/tbcgear gear` exports only gear from bags and bank.
- `/tbcgear scan` refreshes bag data. If your bank is open, it refreshes bank data too.
- `/tbcgear clear` clears this character's saved bag and bank snapshots.

WoW only exposes bank contents to addons while the bank is open. Open your bank once after installing, or any time you want the bank snapshot refreshed.

## Tests

Run the local WoW API mock suite with:

```sh
lua tests/run.lua
```

The test runner includes a line coverage gate of 99% for `TBCGearExporter.lua`.
