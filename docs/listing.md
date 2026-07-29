# Addon Listing Copy

## 256-Character Summary

TBC Gear Exporter saves bags, bank, talents, live stats for TBC Anniversary, groups items, records stat totals, Wowhead links, shows in-game stats analysis, and exports AI-ready JSON/Markdown/text with a strategy book for class/race/talents/raid/party tab.

Character count: 256

## Full Markdown Description

![TBC Gear Exporter logo](https://raw.githubusercontent.com/tomqwu/TBC-Gear-Exporter/main/assets/tbc-gear-exporter-logo.png)

**TBC Gear Exporter** is a World of Warcraft TBC Classic / TBC Anniversary addon for saving, reviewing, and exporting your character's bag, bank, current talent build, and live character-sheet stats.

It scans visible bags, bank containers, current talents, and character-sheet stats, stores the results in `TBCGearExporterDB`, groups items by category, records item stats, exports chart-ready aggregate totals, preserves WoW quality colors, adds TBC Wowhead links, builds a role-aware strategy book, and gives you a compact in-game GUI for reviewing items visually, reading stats analysis in-game, or exporting everything in AI-friendly formats.

### Key Features

- Saves bag and bank snapshots locally per character.
- Saves current talent tree points, explicit `tree_points`, per-tree `points_spent`, primary tree, total/unspent points, and selected talent `points_spent`/`rank` values.
- Saves live race, faction, level, raid/party context, attributes, armor, defense, attack power, combat ratings, crit/avoidance chances, spell damage, healing, and mana regen.
- Scans bags when you open your bags, and scans bank contents when the bank is open.
- Prints scan/debug lines in chat so you know when the local database changed.
- Groups items into useful categories such as gear, consumables, gems, recipes, reagents, quest items, trade goods, and more.
- Records item name, count, location, item level, quality, quality color, item type, equip slot, stats, item link, item string, and TBC Wowhead URL.
- Exports chart-ready totals by source, category, quality, equip slot, item level, and aggregate stat values.
- Builds a strategy book that maps class, race, current talents, raid/party context, live stats, and gear totals to mitigation, threat, DPS, healing, and mana models.
- Shows a localized Stats Analysis GUI page with character stats, role models, benchmark statuses, race/group notes, and gear stat highlights without leaving the game.
- Filters exports by scope: all saved items, bags only, bank only, or gear only.
- Filters by quality, including rare-or-better, epic-only, and epic gear-only views.
- Exports as AI Text, JSON, Markdown, or plain text.
- Shows a visual item browser with saved item icons, colored names, counts, item levels, locations, quality/type labels, and item-link tooltips.
- Generates a class-aware AI prompt before the data export so external GenAI tools can analyze gear by likely role/spec, using `character_stats`, `current_talents`, `chart_stats`, and `strategy_book`.
- Supports English, simplified Chinese, and traditional Chinese client UI text.

### AI-Ready Export

The default AI Text export starts with an `AI_PROMPT` section and then includes structured `DATA_JSON`. JSON exports also include the prompt under `ai_prompt`.

The prompt includes:

- Character name, realm, class, and client locale.
- Current talent build summary, tree point distribution, and selected ranked talents with points spent.
- Live character stats, race, raid/party context, and strategy-book benchmarks for hit, crit, defense, avoidance, threat, mitigation, healing, mana, and DPS.
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
