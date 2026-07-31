# Addon Listing Copy

## 256-Character Summary

TBC Gear Exporter scans equipped gear, bags, bank, talents, and live stats; recommends P2 upgrades by class, role, mode, and stat caps; tracks reference sets; adds TBC Wowhead links; and exports AI Text, JSON, Markdown, and text for TBC Anniversary client.

Character count: 256

## Full Markdown Description

![TBC Gear Exporter logo](https://raw.githubusercontent.com/tomqwu/TBC-Gear-Exporter/main/assets/tbc-gear-exporter-logo.png)

**TBC Gear Exporter** is a World of Warcraft TBC Classic / TBC Anniversary addon for saving, reviewing, and exporting your character's bag, bank, current talent build, and live character-sheet stats.

It scans current equipment, visible bags, bank containers, talents, and character-sheet stats, stores the results in `TBCGearExporterDB`, recommends compatible bag/bank upgrades by role and stat gaps, preserves WoW quality colors, adds TBC Wowhead links, and gives you a compact in-game GUI with Overview, icon-based Gear Advice, item browser, stats analysis, and copyable AI-friendly exports.

### Key Features

- Saves current equipment plus bag and bank snapshots locally per character.
- Saves current talent tree points, explicit `tree_points`, per-tree `points_spent`, primary tree, total/unspent points, and selected talent `points_spent`/`rank` values.
- Saves live race, faction, level, raid/party context, attributes, armor, defense, attack power, combat ratings, crit/avoidance chances, spell damage, healing, and mana regen.
- Scans bags when you open your bags, and scans bank contents when the bank is open.
- Prints scan/debug lines in chat so you know when the local database changed.
- Groups items into useful categories such as gear, consumables, gems, recipes, reagents, quest items, trade goods, and more.
- Records item name, count, location, item level, quality, quality color, item type, equip slot, stats, item link, item string, and TBC Wowhead URL.
- Normalizes the TBC Anniversary stat-token variants used for armor, ratings, spell damage/healing, spell power, mana regen, and weapon DPS before role scoring.
- Exports chart-ready totals by source, category, quality, equip slot, item level, and aggregate stat values.
- Builds a Phase 2 strategy database for all 9 TBC classes and 28 PvE specializations, with localized roles, cap assumptions, three modes per role, set routes, guide evidence, and reference talents.
- Tracks 29 WoWSims P2/T5 reference sets and 475 target slots against current equipment plus saved bags and bank, with real missing-item icons, localized links, item levels, tooltips, and Wowhead URLs.
- Maps every selected talent into each class role, including rank, icon, tree alignment, and coverage; curated rank-scaled key-talent rules adjust mitigation, threat, DPS, healing, and mana stat weights.
- Compares compatible saved gear against current equipment and labels each result as a clear upgrade, small improvement, tradeoff, or manual check; each swap shows net gained/lost stats, benchmark impact, and evidence.
- Opens to a localized Overview GUI page with compact inventory, talent, stat, quality, category, and role snapshots.
- Shows an icon-based Gear Advice page with role switching and a visual current-to-candidate workbench: large real item icons, tooltips, quality-colored names, decision labels, score gains, stat tradeoffs, evidence, and benchmark checks.
- Shows a localized P2 Guide page with tank mitigation/threat, healer throughput/longevity, and DPS cap/output mode switching, plus current cap status, route goal, target-set progress, and evidence level.
- Compares spell damage and spell power as one offensive stat, and treats the 102.4% shield table as a contextual check that still needs attacker miss and temporary block effects.
- Shows a localized Stats Analysis GUI page with character stats, role-specific models, benchmark statuses, race/group notes, and current-gear highlights without repeating irrelevant tank or hit sections.
- Filters exports by scope: all saved items, bags only, bank only, or gear only.
- Filters by quality, including rare-or-better, epic-only, and epic gear-only views.
- Exports as AI Text, JSON, Markdown, or plain text; AI Text/JSON retain the engineered prompt and full data, while the fully localized readable formats open directly to current equipment, recommendations, role judgment, detailed analysis, and candidate inventory.
- Shows a visual item browser with saved item icons, colored names, counts, item levels, locations, quality/type labels, and item-link tooltips.
- Generates a class-aware AI prompt before the data export so external GenAI tools can analyze gear by likely role/spec and selected strategy mode, using `character_stats`, `current_talents`, `chart_stats`, `strategy_book.roles[].talent_mapping`, `gear_recommendations.phase2_strategy`, `available_roles`, caps, evidence, target progress, and role-specific comparisons.
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

The built-in recommendations are an explainable strategy/comparison engine, not a full combat simulator. Encounter timelines, rotations, hidden proc rates, set bonuses, enchants, gems, temporary buffs, and unmodeled talent formulas still require tooltip or external analysis. Simulation-backed presets and guide-only healer or niche-spec evidence are labeled separately.

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
