# TBC Gear Exporter

<p align="center">
  <img src="https://raw.githubusercontent.com/tomqwu/TBC-Gear-Exporter/main/assets/tbc-gear-exporter-logo.png" alt="TBC Gear Exporter logo" width="128">
</p>

[![Tests](https://github.com/tomqwu/TBC-Gear-Exporter/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tomqwu/TBC-Gear-Exporter/actions/workflows/test.yml)
![Lua 5.1](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua&logoColor=white)
![WoW AddOn](https://img.shields.io/badge/WoW-TBC%20Classic-C69B6D)
![TBC Anniversary](https://img.shields.io/badge/client-Anniversary-0E8A16)
![Tests](https://img.shields.io/badge/tests-103%20passing-brightgreen)
![Coverage](https://img.shields.io/badge/coverage-99.01%25-brightgreen)
![Coverage Gate](https://img.shields.io/badge/coverage%20gate-99%25-blue)
![Local Install](https://img.shields.io/badge/local%20install-PowerShell-5391FE?logo=powershell&logoColor=white)

A World of Warcraft TBC Classic addon that scans current equipment, bags, bank, talents, and live character-sheet stats; ranks Phase 2 role/mode-aware gear candidates with an explicit model maturity label; tracks reference sets; exposes caps and priority stats; adds TBC Wowhead links; and shows a localized GUI with Overview, icon-based Gear Advice, P2 Guide, item browser, stats analysis, and AI-ready export pages.

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

Stable `v*` tags now publish both the GitHub Release and the CurseForge `release` automatically from the same `Release` workflow. The workflow requires the `CF_API_KEY` repository secret and fails visibly if it is missing. The `Manual Package` workflow remains a recovery path: leave `publish_curseforge` off to build a downloadable artifact only, or turn it on to retry a CurseForge upload.

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

The export panel pops up from saved `TBCGearExporterDB` data. It shows saved bag/bank counts, scan/debug controls, source buttons for **All**, **Bags**, **Bank**, and **Gear**, format buttons for **AI**, **JSON**, **Markdown**, and **Text**, filter buttons for **All Q**, **Rare+**, **Epic**, and **Gear Epic**, and tabs for **Overview**, **Gear Advice**, visual items, stats analysis, **P2 Guide**, and copyable text export. The Gear Advice page offers role and strategy views, real item icons, tooltips, quality-colored names, an auditable `stat delta x weight = contribution` explanation, explicitly unscored changes, contextual effect choices, active Tier 5 sets, set-threshold warnings, guide-route gaps, benchmark impact, model provenance, and item-data completeness. Current models rank candidates but do not issue definitive upgrade verdicts. Holy Paladin adds Mixed Healing, Flash of Light, and Holy Light views. Tank modes keep balanced, mitigation, and threat decisions separate, including contextual trinket effects. The P2 Guide displays route evidence separately from the score model so a reference set is never presented as proof that a candidate swap was simulated. Spell damage and spell power are compared as one offensive stat. Level-70 combat ratings are converted into the unit used by each tracked benchmark. Item level and quality do not add score. Unlisted sockets, enchants, proc effects, rotations, and encounters remain outside the evaluator. Markdown and plain-text exports follow the client locale; AI Text and JSON retain the full structured dataset and model contract for external tools.

## Phase 2 strategy database

Version 0.5.2 uses database version 8 and recommendation engine version 15. Every recommendation now carries a reconciled score breakdown with signed stat deltas, active role/mode weights, per-stat contributions, net visible-stat score, and excluded changes with an explicit reason. The contextual layer contains 14 source-linked item effects and all 17 Tier 5 class sets, covering every one of the 28 supported PvE roles. Set ownership is gated by both class and role, so shared role keys such as Restoration Druid and Restoration Shaman cannot leak across classes. The GUI and exports show currently equipped set counts and their 2/4-piece activation states. A 5-to-4 swap correctly keeps the 4-piece bonus, while a 4-to-3 swap is marked as a tradeoff. Candidates whose curated effect is weaker than the equipped effect in the selected mode are excluded instead of appearing as green upgrades; they can reappear in a mode where their effect is preferred. The database still tracks 32 reference sets and 526 target slots, with route gaps exported independently from bag-item recommendations.

Reference gear routes and guide-only routes are labeled separately from score models. The audited 28-role maturity matrix and the criteria required before definitive verdicts can be enabled are documented in [docs/engine-contract.md](docs/engine-contract.md); cap and route details remain in [docs/phase2-strategy.md](docs/phase2-strategy.md). WoWSims-derived data is pinned to an exact commit and distributed with its MIT notice in [TBCGearExporter/ThirdPartyNotices.txt](TBCGearExporter/ThirdPartyNotices.txt).

AI Text exports begin with an `AI_PROMPT` block before `DATA_JSON`. JSON exports include `character_stats`, `current_talents`, `chart_stats`, `strategy_book`, and `gear_recommendations`. Each upgrade's `score_breakdown` records its formula components, reconciled net score, and `unscored_changes`, including whether a stat has no role weight or does not apply to the compared slot. `active_sets` records equipped Tier 5 pieces, active bonuses, mode affinity, and source URLs; `set_impacts` records only thresholds crossed by a proposed swap. `score_model` records scoring provenance and limitations; `route_evidence` records where the target route came from; `data_completeness` reports how much visible item data was comparable. Every selected talent remains represented with tree, rank, icon, and alignment, while `modeled_count` and `coverage` count only talents with an actual calculation rule. The legacy `evidence` field remains as a compatibility alias for item-data completeness. The prompt follows the client locale from `GetLocale()` and explicitly prevents external AI tools from turning heuristic ranks into simulated certainty.

This is currently a transparent candidate-ranking and export engine, not a full combat simulator or global loadout optimizer. It does not model encounter timelines, full rotations, unlisted proc rates or set bonuses, enchants, gems, temporary buffs, or every talent's exact combat formula. Curated item effects and set thresholds are categorical context, not simulated EP. Everything else remains an explicit manual/AI review input instead of being silently invented.

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
- Stable tags named `v*`, for example `v0.5.2`, build a GitHub Release using notes from `CHANGELOG.md`, then automatically publish the BCC package to CurseForge as a stable release. Routine `main` pushes do not create development tags or uploads.
- The release zip contains the addon folder as the top-level entry, so extraction into `Interface/AddOns/` works directly.
- Local release mirroring is done with `scripts/install-local.ps1` because GitHub Actions cannot access your `F:\` drive.
