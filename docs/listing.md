# Addon Listing Copy

## 256-Character Summary

TBC Gear Exporter saves bag and bank snapshots for TBC Anniversary, groups gear and items, records stats, quality colors, Wowhead links, and exports localized AI-ready JSON, Markdown, or text through an in-game GUI with filters for class/spec PvE gear sets

Character count: 256

## Full Markdown Description

**TBC Gear Exporter** is a World of Warcraft TBC Classic / TBC Anniversary addon for saving, reviewing, and exporting your character's bag and bank inventory.

It scans visible bags and bank containers, stores the results in `TBCGearExporterDB`, groups items by category, records item stats, preserves WoW quality colors, adds TBC Wowhead links, and gives you a compact in-game GUI for exporting everything in AI-friendly formats.

### Key Features

- Saves bag and bank snapshots locally per character.
- Scans bags when you open your bags, and scans bank contents when the bank is open.
- Prints scan/debug lines in chat so you know when the local database changed.
- Groups items into useful categories such as gear, consumables, gems, recipes, reagents, quest items, trade goods, and more.
- Records item name, count, location, item level, quality, quality color, item type, equip slot, stats, item link, item string, and TBC Wowhead URL.
- Filters exports by scope: all saved items, bags only, bank only, or gear only.
- Filters by quality, including rare-or-better, epic-only, and epic gear-only views.
- Exports as AI Text, JSON, Markdown, or plain text.
- Generates a class-aware AI prompt before the data export so external GenAI tools can analyze gear by likely role/spec.
- Supports English, simplified Chinese, and traditional Chinese client UI text.

### AI-Ready Export

The default AI Text export starts with an `AI_PROMPT` section and then includes structured `DATA_JSON`. JSON exports also include the prompt under `ai_prompt`.

The prompt includes:

- Character name, realm, class, and client locale.
- Export scope and active filter.
- Class-aware role context, such as tank, DPS, caster, or healer evaluation lenses.
- Instructions for ranking keepers, weak slots, upgrade priorities, duplicates, offspec pieces, consumables, and vendor/disenchant candidates.

This makes the export easy to paste into ChatGPT or another AI tool for gear review.

### Commands

```text
/tbcgear gui
/tbcgear scan
/tbcgear export
/tbcgear json
/tbcgear markdown
/tbcgear text
/tbcgear bags
/tbcgear bank
/tbcgear gear
/tbcgear gear epic
/tbcgear rare+ text
/tbcgear debug
/tbcgear clear
```

### Notes

WoW only exposes bank contents to addons while the bank is open. Open your bank once and scan while it is visible to refresh the saved bank snapshot.

The minimap bag icon opens the export GUI on left-click. Right-click scans and saves bags, and also saves bank data if the bank is currently open.
