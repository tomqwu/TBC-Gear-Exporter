# TBC Gear Exporter

<p align="center">
  <img src="https://raw.githubusercontent.com/tomqwu/TBC-Gear-Exporter/main/assets/tbc-gear-exporter-logo.png" alt="TBC Gear Exporter logo" width="128">
</p>

[![Tests](https://github.com/tomqwu/TBC-Gear-Exporter/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tomqwu/TBC-Gear-Exporter/actions/workflows/test.yml)
![Lua 5.1](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua&logoColor=white)
![WoW AddOn](https://img.shields.io/badge/WoW-TBC%20Classic-C69B6D)
![TBC Anniversary](https://img.shields.io/badge/client-Anniversary-0E8A16)
![Tests](https://img.shields.io/badge/tests-78%20passing-brightgreen)
![Coverage](https://img.shields.io/badge/coverage-99.15%25-brightgreen)
![Coverage Gate](https://img.shields.io/badge/coverage%20gate-99%25-blue)
![Local Install](https://img.shields.io/badge/local%20install-PowerShell-5391FE?logo=powershell&logoColor=white)

A World of Warcraft TBC Classic addon that scans current equipment, bags, bank, talents, and live character-sheet stats; gives Phase 2 role/mode-aware gear decisions from saved items; tracks reference sets; exposes caps and priority stats; adds TBC Wowhead links; and shows a localized GUI with Overview, icon-based Gear Advice, P2 Guide, item browser, stats analysis, and AI-ready export pages.

Reusable addon listing copy is available in [docs/listing.md](docs/listing.md), including an exact 256-character summary and a full Markdown description.

## Install

1. Download the latest zip from the [Releases page](https://github.com/tomqwu/TBC-Gear-Exporter/releases).
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

## Manual Package

CurseForge tag monitoring is the normal release path. If a manual fallback is needed, run the `Manual Package` GitHub Actions workflow. Leave `publish_curseforge` off to build a downloadable artifact only; turn it on only when the `CF_API_KEY` repository secret is set and you want to upload to CurseForge.

Local build-only fallback:

```bash
scripts/package-local.sh
```

Local CurseForge upload fallback:

```bash
CF_API_KEY=... scripts/package-local.sh --publish-curseforge
```

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

The export panel pops up from saved `TBCGearExporterDB` data. It shows saved bag/bank counts, scan/debug controls, source buttons for **All**, **Bags**, **Bank**, and **Gear**, format buttons for **AI**, **JSON**, **Markdown**, and **Text**, filter buttons for **All Q**, **Rare+**, **Epic**, and **Gear Epic**, and tabs for **Overview**, **Gear Advice**, visual items, stats analysis, **P2 Guide**, and copyable text export. The default Overview page gives a compact character, inventory, talent, stat, quality, category, and role snapshot. The Gear Advice page has role buttons for hybrid builds and a visual comparison workbench with large current/candidate icons, item tooltips, quality-colored names, verdict, score change, evidence, gained/lost stats, and benchmark impact. The P2 Guide lets you switch tank mitigation/threat, healer throughput/longevity, or DPS cap/output models; it shows caps, the localized set route, target-set progress, missing item icons, localized item links, item levels, tooltips, and evidence source. Recommendation rows remain clickable so you can move the full comparison between suggested slots. Spell damage and spell power are compared as one offensive stat. The 102.4% shield table is shown as a contextual check because standing character stats omit attacker miss and temporary block effects. Set bonuses, sockets, enchants, and proc effects still require tooltip judgment. The item browser uses saved item icons, colored names, counts, item levels, locations, quality, type, and item-link tooltips so you can review gear without staring at raw JSON. The Stats Analysis page shows only the model details relevant to each role, so healing roles no longer repeat tank fields. Markdown and plain-text exports follow the client locale throughout and organize current equipment, recommendations, P2 strategy, role judgment, detailed analysis, and candidate inventory into separate sections without duplicating the long AI prompt. AI Text and JSON keep the engineered prompt and full structured dataset for external tools.

## Phase 2 strategy database

Version 0.4.3 replaces the defense-only tank gate with combined boss critical-hit reduction from defense skill, resilience, and applicable talents. For Feral bears, each rank of Survival of the Fittest contributes its 1% reduction, so 3/3 bears need the remaining 2.6% from defense and resilience rather than 490 defense skill. Gear comparisons convert defense and resilience rating changes into the same percentage unit, reject off-hands beside an equipped two-hander, and exclude a comparison when either item has no parsed static stats, since hidden use/proc/set/gem/enchant value would make the score misleading. Version 0.4.2 made role summaries sheet-aware, scoped Hunter weapon DPS to the ranged slot, recognized Beast Mastery talents, selected unresolved 9% hit routes, and blocked swaps that worsen an unmet benchmark. Version 0.4.0 introduced the versioned Tier 5 database covering all 9 TBC classes and 28 PvE specializations. Every role has localized labels, stat priorities, explicit cap assumptions, three switchable modes, a P2 set/route goal, a guide source, and a reference talent string where available. The database includes 29 WoWSims reference sets with 475 non-empty target slots; target progress is checked against current equipment plus saved bags and bank, independent of the active export filter.

Simulation presets and guide-only roles are labeled separately. Healers and niche builds without a mature preset still receive visible-stat comparisons, but the addon does not present those results as simulation certainty. The full role matrix, tank/healer/DPS rules, source revisions, and limitations are documented in [docs/phase2-strategy.md](docs/phase2-strategy.md). WoWSims-derived preset data is pinned to an exact commit and distributed with its MIT notice in [TBCGearExporter/ThirdPartyNotices.txt](TBCGearExporter/ThirdPartyNotices.txt).

AI Text exports begin with an `AI_PROMPT` block before `DATA_JSON`. JSON exports include the same instructions under `ai_prompt`, plus `character_stats`, `current_talents`, `chart_stats`, `strategy_book`, and `gear_recommendations`. The strategy book combines class, race, current talents, raid/party context, live stats, and current equipped item stats into role models such as tank mitigation, threat, melee/ranged/caster DPS, healing throughput, and mana longevity. Tank observations export the combined crit-reduction total, target, gap, defense contribution, resilience contribution, talent contribution, resilience rating, and rating source. `gear_recommendations.phase2_strategy` records the selected mode, caps, route goal, evidence level, guide, available modes, target preset, target ownership, missing target items, Wowhead links, and source revisions. Every selected talent is represented in each role's `talent_mapping`, including icon, rank, tree alignment, coverage, and aligned points. Curated key-talent rules for all TBC classes apply rank-scaled multipliers to relevant stat weights, while `available_roles` lets hybrid builds score the same item under a different role. Candidate bag/bank totals remain separate under `chart_stats`. Anniversary-client aliases for armor, ratings, spell damage/healing, spell power, mana regen, and weapon DPS are normalized before scoring. Each proposed swap includes `stat_gains`, `stat_losses`, and an `evidence` level so an AI can distinguish a well-supported upgrade from a tooltip-dependent review. The prompt follows the client locale from `GetLocale()`.

This is an explainable strategy and comparison engine, not a full combat simulator. It does not model encounter timelines, rotations, hidden proc rates, set bonuses, enchants, gems, temporary buffs, or every talent's exact combat formula. Those remain explicit manual/AI review inputs instead of being silently invented.

Current talents are saved into `current_talents` with tree point summary, explicit `points_spent`, `tree_points`, primary tree, total/unspent points, per-tree points, and selected talent `points_spent`/`rank` values. Talent tree names fall back to localized English, simplified Chinese, or traditional Chinese labels when the WoW API only returns tree IDs. Live character-sheet stats are saved into `character_stats` with race, faction, level, raid/party context, attributes, armor, defense, attack power, combat ratings, crit/avoidance chances, spell damage, healing, and mana regen. Talent, character-stat, and currently equipped gear snapshots refresh when bags or bank are scanned, when exports are generated, and when WoW fires talent, character-point, or equipment-change events.

Item names use WoW quality colors, such as rare blue and epic purple. Item level remains a numeric field, while item type/category remains a separate classification for AI analysis.

On login, the addon prints a loaded message with item and slot counts. Opening a bag scans bag contents and prints a debug line in chat. Opening the bank scans bank contents and prints a matching debug line.

## Tests

The addon is pure Lua and headless-testable. The suite stubs the WoW API surface it needs.

```sh
lua tests/run.lua
luac -p TBCGearExporter/TBCGearExporter.lua
luac -p TBCGearExporter/Phase2StrategyDB.lua
```

CI runs syntax checks for every Lua file and the local WoW API mock suite on every push to `main` and every pull request. The test runner includes a line coverage gate of 99% for `TBCGearExporter.lua`.

## Release workflow

This repo follows the same shape as `ArenaCoachTBC`:

- Pull requests and `main` pushes run Lua tests, the 99% coverage gate, syntax checks, and a package dry run.
- Stable tags named `v*`, for example `v0.4.3`, build a GitHub Release using notes from `CHANGELOG.md`; routine `main` pushes do not create development tags.
- The release zip contains the addon folder as the top-level entry, so extraction into `Interface/AddOns/` works directly.
- Local release mirroring is done with `scripts/install-local.ps1` because GitHub Actions cannot access your `F:\` drive.
