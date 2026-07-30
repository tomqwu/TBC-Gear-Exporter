# Changelog

All notable changes to TBC Gear Exporter are tracked here.

## [Unreleased]

## [0.2.1] - 2026-07-30

- Merge spell damage and spell power into one offensive spell stat for recommendation scoring and swap deltas, while preserving the original per-item stats in exports.
- Classify advice as a clear upgrade, small improvement, tradeoff, or manual check instead of presenting every positive heuristic score as an equally certain upgrade.
- Add localized per-swap benchmark impacts and verdict summaries to the Gear Advice GUI, JSON, Markdown, and plain-text reports.
- Treat the 102.4% shield table as a combat-context check because the exported standing subtotal excludes attacker miss and temporary block effects.
- Add real Protection Paladin regression cases for the Strongge necklace, trinket, and ring comparisons.

## [0.2.0] - 2026-07-30

- Fully localize readable Markdown and plain-text reports for English, simplified Chinese, and traditional Chinese, including headings, metadata, item locations, categories, equipment slots, and stat labels.
- Separate current equipped stats from bag/bank candidate totals so strategy roles no longer describe inventory-wide totals as current gear.
- Expand Protection Paladin scoring to cover armor, dodge, parry, block, spell threat, spell hit, intellect, and mana sustain.
- Normalize the real TBC Anniversary item-stat token variants used for armor, ratings, spell damage/healing, spell power, mana regen, and weapon DPS so role scoring does not silently ignore them.
- Add per-swap `stat_gains`, `stat_losses`, and high/medium/low evidence to the GUI, JSON, Markdown, and plain-text recommendations.
- Add a complete current-equipment section and reorganize readable exports around the character summary, recommendations, role judgment, detailed analysis, and candidate inventory.
- Keep the long engineered prompt in AI Text/JSON only; Markdown and plain text now open directly as concise human-readable reports.
- Remove irrelevant repeated tank/hit analysis from roles that do not use those models.

## [0.1.9] - 2026-07-29

- Save a fresh current-equipment snapshot with bag/bank scans, exports, login, and equipment changes.
- Add a role-aware gear strategy engine that compares compatible bag/bank candidates against the weakest current item for each slot, boosts stats tied to open TBC benchmark gaps, and rejects class-incompatible armor, shields, and non-equippable items.
- Add a localized, icon-based Gear Advice GUI page with current/candidate tooltips, estimated score gains, priority stats, benchmark gaps, and explicit heuristic caveats.
- Export structured `gear_recommendations` and `equipped_gear` in AI/JSON, plus concise recommendation tables in Markdown and plain text.

## [0.1.8] - 2026-07-29

- Add a default localized Overview GUI tab with compact inventory, talent, stat, category, quality, and role snapshots.
- Redesign Markdown export into a readable report with quick summary, role snapshot, collapsible details, and Wowhead-linked item tables.
- Round noisy human-facing stat decimals and fall back to localized talent tree names when the WoW API returns tree IDs.

## [0.1.7] - 2026-07-29

- Export explicit talent point fields, including `current_talents.points_spent`, `tree_points`, per-tree `points_spent`, and per-talent `points_spent`/`current_rank`.
- Rebuild talent tree totals from selected talent ranks when the tree API reports zero, and keep the last valid saved talent snapshot instead of overwriting it with a transient zero-point refresh.
- Show localized talent tree points and selected ranked talents on the in-game Stats Analysis page and in Markdown/Text export metadata.

## [0.1.6] - 2026-07-29

- Localize the Stats Analysis GUI display for Chinese clients so role names, model names, benchmark labels/statuses, group/race notes, and gear stat highlights no longer show English/internal tokens.
- Make English Stats Analysis wording use natural display labels instead of internal model/status tokens.

## [0.1.5] - 2026-07-29

- Add a localized Stats Analysis GUI page next to the item browser and text export tabs.
- Show live character stats, role strategy models, benchmark statuses, raid/party notes, and gear stat highlights directly inside the addon window.

## [0.1.4] - 2026-07-29

- Add live character-sheet stats to exports, including race, group/raid context, attributes, armor, defense, attack power, combat ratings, crit/avoidance chances, spell damage, healing, and mana regen.
- Add a strategy book export that maps current talents, gear stat totals, class, race, and raid/party context into role models such as mitigation, threat, DPS, healing, and mana longevity.
- Update AI prompt guidance to use character_stats, chart_stats, and strategy_book before ranking hit, crit, defense, avoidance, threat, mitigation, healing, mana, and DPS value.

## [0.1.3] - 2026-07-29

- Add chart-ready export stats with source, category, quality, equip-slot, item-level, and aggregate stat totals alongside the per-item stat arrays.

## [0.1.2] - 2026-06-24

- Add current talent snapshots to the saved local DB and AI/JSON/Markdown/Text exports, including tree point summary, primary tree, total/unspent points, and selected talent ranks.

## [0.1.1] - 2026-06-07

- Redesign the export GUI into a two-column power-user panel with source/filter/format controls, visual item-icon browsing, item-link tooltips, and a separate copyable text-export tab.
- Localize in-game GUI labels, status text, minimap tooltip, slash help, and scan chat lines for English, simplified Chinese, and traditional Chinese clients.
- Localize the generated AI prompt from the WoW client locale, including Chinese prompt wording for Chinese clients.
- Add a class-aware AI prompt block to exports, including Druid bear/cat/healing/caster role lenses.
- Add export quality filters, including rare-or-better, epic-only, and gear epic-only GUI/slash options.
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
