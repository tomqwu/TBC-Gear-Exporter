# Changelog

All notable changes to TBC Gear Exporter are tracked here.

## [Unreleased]

## [0.5.6] - 2026-08-03

- Treat defense rating consistently after either the combined-crit or defense-skill immunity benchmark is met, preserving partial avoidance value without applying the contextual shield-table boost twice.
- Project defense-rating swaps into both tracked tank outcomes: critical-hit reduction and the visible dodge/parry/block subtotal. Each defense skill contributes 0.12% to that displayed subtotal, while attacker miss remains outside the paper-doll total.
- Reclassify positive visible-stat scores below 8 as a localized small improvement instead of an estimated upgrade, across every class and role model; larger heuristic candidates remain estimates and cap risks remain tradeoffs.
- Fix the Strongge Protection Paladin ring case: The Unyielding Defender is now a small `+2.73` candidate over Shermanar Great-Ring, with explicit `+0.05%` crit-immunity buffer and `+0.15%` visible avoidance/block impact.
- Redesign Stats Analysis as up to six structured, icon-led panels for character/talents, live stats, race/group context, and the top three role models, with dynamic wrapping and localized titles instead of one unbroken text wall.
- Keep the complete structured analysis text available to Markdown, text, AI Text, and JSON consumers while the in-game page uses the more readable panel presentation.
- Upgrade the recommendation engine to version 19; all 120 tests pass with 99.03% executable-line coverage.

## [0.5.5] - 2026-08-02

- Fix strategy-mode weight application: mode multipliers now scale only weights the selected role actually declares, and generic hit/crit/haste multipliers fall through to the role's school-specific weights instead of inventing a generic weight from unit scales.
- Fix Feral Bear and Protection Warrior Threat / farm mode gaining invented spell-hit and spell-power weights, which could rank caster pieces above genuine threat gear; Protection Paladin keeps its declared 1.32/1.30 spell-power/spell-hit threat boosts.
- Fix Retribution Maximum output mode lowering the haste valuation from 1.17 to an invented 1.10; melee haste now correctly rises to about 1.29 and Hunter generic/ranged crit and haste weights stay in sync.
- Score negative visible stats symmetrically: a stat malus now subtracts from candidate and equipped scores, so shedding a cursed stat counts as a gain and every score breakdown reconciles against its formula.
- Convert paper-doll expertise from points to percent (one point removes 0.25% boss dodge) before checking the 6.5% expertise benchmark; melee with around 26 expertise rating no longer report as expertise-capped, and the below-cap weight boost fires correctly.
- Add class weapon and relic proficiency gates so candidates a class cannot wield, such as Druid swords, Paladin daggers, Hunter maces, wands on non-casters, and cross-class librams/idols/totems, are rejected before ranking.
- Score `equipped_gear` JSON entries with the active role's slot gating so a hunter's melee-weapon score no longer includes weapon DPS and matches the role-aware scores used elsewhere in the same export.
- Give Prism of Inner Calm reachable mode affinities (balanced, cap recovery, maximum output); its previous `threat` affinity did not exist for any applicable DPS role, which silently disabled equipped-effect protection in Cap recovery mode.
- Localize the remaining English "never" and "none" fragments in Chinese Markdown, plain-text, Overview, and Gear Advice surfaces; JSON keeps the stable `never` sentinel for machine consumers.
- Fix swapped mana-regen assignment: `mana_regen_casting` and `mana_regen_not_casting` now follow the client API's return order (while-not-casting first).
- Refresh the Items tab rows on click so they match the recomputed status count, and derive resilience crit-reduction from the single pinned WoWSims constant.
- Stop crediting physical hit rating toward the spell-hit benchmark: generic hit/crit/haste ratings are physical-only in TBC, so they no longer inherit spell-school weights, and a Retribution chest's +23 hit no longer scores 2.24 per point for a Protection Paladin closing a spell-hit gap.
- Benchmark-gap and talent weight boosts now scale only weights the role declares, matching the mode-multiplier rule; a cap gap cannot invent a weight for a stat outside the role model.
- Protect the tank shield: for tank roles with a block model (Protection Warrior/Paladin), a non-shield off-hand candidate is rejected with the new `shield_required` status instead of appearing as a tradeoff, because block chance, block value, and 102.4% table coverage vanish with the shield without ever showing up as an item stat delta.
- Keep four decimal places on exported and displayed stat weights so `delta x weight = contribution` reproduces the printed result; `-475 armor x 0.03 = -14.68` now renders as `x 0.0309`.
- Document that empty sockets carry a fixed nominal placeholder weight in candidate scoring while gem choices themselves remain out of scope.
- Add context-aware known-effect decisions: equal mode affinity no longer makes different-use trinkets look equivalent, and the GUI/exports show localized scenarios, decision dimensions, affinity deltas, and a non-green `effect_context` tradeoff.
- Compare ring and trinket candidates against both equipped items, preserving a threat trinket when the candidate is a better replacement for the other slot; mode-specific candidate ranking now uses the full affinity delta.
- Fix the P2 guide's all-class priority panel initialization and expand comparison/advice rows for localized scenario evidence without text overlap.
- Upgrade the strategy database to version 9 and the recommendation engine to version 18; all 120 tests pass with 99.08% executable-line coverage.

## [0.5.4] - 2026-08-02

- Fix talent-adjusted cap checks by storing raw paper-doll values, detected talent bonuses, effective values, and role-specific targets as separate benchmark fields.
- Recognize Hunter Surefooted, Lightning Reflexes, and Expose Weakness in English, simplified Chinese, and traditional Chinese; 3/3 Surefooted now contributes its actual 3% hit and 5/5 Lightning Reflexes applies its actual 15% Agility multiplier.
- Explain Expose Weakness Agility changes as contextual attack power per physical attacker while active, explicitly outside the personal EP score.
- Fix the real Yamede Survival case: 7.93% paper-doll hit plus 3% Surefooted is 10.93% effective hit, and losing 19 hit rating leaves about 9.73%, so Danger Intent Leggings are no longer incorrectly blocked by the 9% gate.
- Use each role's declared cap contract across all 28 role models instead of reporting a conflicting global target.
- Include the complete score formula, excluded stats, talent context, and projected cap math for rejected and lower-ranked candidates in the GUI and every export format.
- Expand recommendation rows, the selected comparison panel, and other-candidate spacing for the longer localized evidence without text overlap.
- Upgrade the recommendation engine to version 17; all 107 tests pass with 99.01% executable-line coverage.

## [0.5.3] - 2026-08-02

- Add a candidate audit ledger so every evaluated gear item keeps a concrete outcome instead of disappearing behind aggregate rejection counts.
- Show localized **Other Candidate Decisions** in Gear Advice, Markdown, and plain text, with machine-readable `candidate_evaluations` in JSON and AI Text.
- Explain benchmark gates, sub-threshold scores, lower same-slot ranking, role/class mismatch, illegal weapon layouts, weaker known effects, unscorable data, and unsupported slots separately.
- Add a four-candidate Yamede Hunter regression: Spiteblade is selected, hit-losing legs are gate-blocked, a weaker off-hand is lower-ranked, and a tiny head upgrade remains below the recommendation threshold.
- Upgrade the recommendation engine to version 16; all 105 tests pass with 99.01% executable-line coverage.

## [0.5.2] - 2026-08-02

- Explain every visible-stat recommendation as `stat delta x active weight = contribution`, including the reconciled net score shown in the GUI, Markdown, plain text, AI Text, and JSON.
- Export structured `score_breakdown` components, score residual, reconciliation status, and `unscored_changes` for machine-readable audits.
- State why visible changes were excluded: either the selected role has no weight for the stat or that role does not use the stat in the compared slot.
- Fix the Yamede Hunter case so Spiteblade's `+4.04` is shown as `+24 Attack Power x 0.46 - 7 Agility x 1.00`, while off-hand weapon DPS and Stamina are explicitly marked unscored.
- Bind score provenance to each recommendation, including the Hunter model's P1 BM/SV source context and non-definitive limitation.
- Expand recommendation rows and the selected comparison panel to fit the added Chinese and English explanations without overlap.
- Upgrade the recommendation engine to version 15; all 103 tests pass with 99.01% executable-line coverage, including reconciliation checks across all 9 classes and 28 role models.

## [0.5.1] - 2026-08-01

- Suppress a candidate when its curated effect is explicitly weaker than the equipped effect in the selected strategy mode; it can reappear automatically in a mode where its effect is preferred.
- Fix the Protection Paladin regression where Goblin Rocket Launcher still appeared as a green balanced/threat upgrade over Icon of the Silver Crescent.
- Export `effect_rejected_count` and effect `choice_kind` so GUI and AI consumers can distinguish a rejected contextual effect from missing item data.
- Keep Holy Paladin librams labeled as spell-cycle choices while generic trinkets use the broader effect-choice label.
- Render tradeoffs in yellow instead of upgrade green and widen the recommendation metric column from 104 to 128 pixels to prevent score/status truncation.
- Upgrade the recommendation engine to version 14; all 99 tests pass with 99.01% executable-line coverage.

## [0.5.0] - 2026-08-01

- Add all 17 Tier 5 class sets and their localized 2/4-piece effects, covering every one of the 28 class-role combinations in the Phase 2 strategy database.
- Gate sets by both class and role so shared role keys, especially Restoration Druid and Restoration Shaman, cannot use each other's set rules.
- Show `active_sets` in Gear Advice, the P2 Guide, Markdown, plain text, AI Text, and JSON, including equipped counts, active thresholds, strategy-mode affinity, and source URLs.
- Evaluate exact set transitions: replacing one piece from a five-piece loadout preserves four-piece, while dropping from four to three is a protected tradeoff.
- Add sourced contextual rules for Goblin Rocket Launcher, Scarab of Displacement, Figurine of the Colossus, Icon of the Silver Crescent, and Moroes' Lucky Pocket Watch.
- Make contextual tank-item decisions mode-aware, preventing a mitigation pull tool from being presented as a clean balanced/threat upgrade over a threat trinket.
- Expand database validation to enforce five unique items, localized 2/4-piece bonuses, valid class ownership, and complete 28-role Tier 5 coverage.
- Upgrade the database to version 8, the recommendation engine to version 13, and the suite to 99 tests with 99.01% executable-line coverage.

## [0.4.9] - 2026-08-01

- Add a source-linked item-effect layer for nine key TBC healer relics/trinkets and role-gate known tank/DPS effects before recommendation scoring.
- Give Holy Paladin separate Mixed Healing, Flash of Light, and Holy Light views with three P2 guide routes and spell-cycle-aware libram choices.
- Protect the Crystalforge Raiment 2/4-piece thresholds: breaking an active bonus is a tradeoff, while completing a threshold is surfaced even when visible stats decline.
- Export `known_effect`, `effect_decision`, `set_impacts`, and `route_gaps` in AI/JSON, plus localized explanations in Markdown, text, and Gear Advice.
- Show guide-route gaps in Gear Advice and expand the summary/comparison layout to prevent the Chinese text overlap visible in long recommendations.
- Expand the database to 32 reference sets and 526 target slots, the engine to version 12, and the suite to 96 tests with 99.05% executable-line coverage.

## [0.4.8] - 2026-08-01

- Add an enforceable score-model contract to all 28 role records and publish the audited maturity matrix in `docs/engine-contract.md`.
- Separate reference-route evidence, score provenance, and visible item-data completeness in the GUI and every export format.
- Disable definitive upgrade labels for every current model; visible-stat rankings now use the honest `Estimated candidate` verdict unless a cap risk or missing data requires a stronger warning.
- Correct Hunter provenance: the shared EP table is labeled as a P1 BM/SV estimate rather than a P2 simulation, including its unsupported Marksmanship reuse.
- Import the exact pinned WoWSims Phase 2 static EP tables for Balance Druid, Retribution Paladin, and Arcane Mage.
- Split talent representation coverage from modeled-effect coverage so exported talents without calculation rules are no longer counted as modeled.
- Remove arbitrary item-level and quality score bonuses; only normalized, role-relevant visible stats contribute to candidate ranking.
- Expand the Gear Advice and P2 Guide layouts to show model maturity without overlapping the comparison and target sections.
- Expand the suite to 91 tests with 99.17% executable-line coverage, including model-distribution, provenance, definitive-verdict, talent-coverage, and score-input gates.

## [0.4.7] - 2026-08-01

- Convert level-70 hit, spell hit, expertise, defense, dodge, parry, block, and resilience rating changes into their real benchmark units using pinned WoWSims TBC constants.
- Restore the omitted dodge-rating weight for Feral Bear recommendations and include lower-priority strength/critical-strike threat signals.
- Devalue excess resilience after combined critical-hit immunity is already met while preserving defense's remaining avoidance value.
- Make Threat / farm reduce survival weighting and increase offensive weighting, so it produces a genuinely different ranking from Balanced and Mitigation / progression.
- Distinguish a reduced-but-still-safe cap buffer from a swap that actually falls below the target.
- Expand Gear Advice rows to a fixed non-overlapping layout with separate compact gain, loss, and benchmark lines; full details remain in the comparison panel and exports.
- Add the exact Thatdruid Wildfury Greatstaff versus Merciless Gladiator's Maul regression and expand the suite to 85 tests with 99.16% executable-line coverage.

## [0.4.6] - 2026-08-01

- Put the three strategy controls directly on Gear Advice, so tank players can switch Balanced, Mitigation / progression, and Threat / farm without discovering them on another page.
- Recalculate the complete recommendation list, weights, selected comparison, and export whenever the strategy view changes.
- Name both the selected mode and all available modes in localized Markdown and plain-text reports.
- Explain the separate tank views on Stats Analysis and instruct external AI tools not to collapse mitigation and threat into one ranking.
- Keep mode controls in fixed non-overlapping regions and expand GUI regression coverage for switching, localization, export synchronization, and empty states.
- Expand the suite to 83 tests with 99.16% executable-line coverage.

## [0.4.5] - 2026-08-01

- Make stable `v*` tags publish both the GitHub Release and the CurseForge BCC release from the default `Release` workflow.
- Fail stable releases visibly when the `CF_API_KEY` repository secret is missing instead of silently skipping CurseForge.
- Retain the generated CurseForge zip as a workflow artifact and keep `Manual Package` only as a recovery path.
- Add a release-policy regression test that protects trigger, token, ordering, stable-only, packager, and artifact requirements.
- Expand the suite to 82 tests with 99.16% executable-line coverage.

## [0.4.4] - 2026-08-01

- Evaluate generic one-hand weapon candidates against both main hand and off hand when the current loadout is dual wielding, then keep only the strongest legal comparison.
- Preserve safe weapon routing for shields, held-in-off-hand items, explicit main-hand weapons, and two-handed loadouts.
- Replace Hunter's generic priority heuristic with the pinned WoWSims EP preset for agility, attack power, ranged attack power, hit, crit, haste, and ranged weapon DPS.
- Combine generic hit, crit, and haste ratings into role-specific melee, ranged, and spell highlights, and include generic attack power for Marksmanship and Survival Hunters.
- Add the exact Yamede 41/20/0 weapon fixture: Spiteblade is now a `+5.54` minor off-hand upgrade over Stellaris and is not falsely compared only with Big Bad Wolf's Paw.
- Expand the suite to 81 tests with 99.16% executable-line coverage.

## [0.4.3] - 2026-08-01

- Replace the tank defense-only benchmark with combined 5.6% boss critical-hit reduction from defense skill, resilience, and applicable talents.
- Model Feral Druid Survival of the Fittest at 1% critical-hit reduction per rank; export and localize the total, target, remaining gap, and each contribution.
- Convert item defense/resilience rating changes into critical-hit reduction percentages so benchmark impact no longer mixes rating, defense skill, and percent units.
- Reject off-hand recommendations while a two-handed weapon is equipped, and reject two-handed comparisons that ignore an equipped off-hand.
- Exclude comparisons where either item has no parsed static stats, instead of assigning a misleading score that ignores possible use/proc/set/gem/enchant value.
- Merge one-hand and two-hand inventory counts under the localized main-hand slot instead of showing duplicate slot labels.
- Add resilience API compatibility and a current-equipped-item fallback for Anniversary clients that expose a different resilience combat-rating constant.
- Expand the suite to 78 tests with 99.15% executable-line coverage, including the exact 350 defense, 80 resilience, 3/3 Survival of the Fittest regression fixture.

## [0.4.2] - 2026-08-01

- Make overview and role analysis stats follow the selected tank, melee, ranged, caster, or healer model instead of showing the same generic melee/spell fields for every class.
- Scope weapon DPS to the relevant equipment slots, so Hunter analysis and scoring use the ranged weapon rather than summing main-hand, off-hand, and ranged DPS.
- Recognize Beast Mastery key talents including Bestial Wrath, Focused Fire, Frenzy, Unleashed Fury, Ferocity, Animal Handler, Intimidation, and The Beast Within.
- Select 9% Hunter and Feral reference routes while an observed hit benchmark is unresolved, while preserving dual-wield versus two-hand weapon choice.
- Exclude candidate swaps that worsen an already unmet benchmark, export `gate_rejected_count`, and explain when no safe upgrade remains.
- Localize raid-support, raid-debuff, and control model names, and round role highlight values to two decimals.
- Expand the suite to 72 tests with 99.13% executable-line coverage, including a 41/20/0 Beast Mastery Hunter export fixture and all five role-sheet summaries.

## [0.4.1] - 2026-07-31

- Add archetype-level role-fit gates for healer, caster, melee, and ranged recommendations so incompatible stat directions are rejected before heuristic scoring.
- Fix the Holy Paladin regression where Vicious Bracers could outrank White Stag Wristguards by treating generic critical-strike rating as spell crit despite the candidate containing attack power and no healing-role anchor stat.
- Export `role_rejected_count` and localize the role-mismatch decision for English, simplified Chinese, and traditional Chinese.
- Give the Gear Advice summary, caveat, comparison panel, and recommendation rows fixed non-overlapping regions; condense the summary to four readable lines.
- Expand the suite to 67 tests with 99.27% executable-line coverage, including exact Holy Paladin item fixtures and GUI layout boundaries.

## [0.4.0] - 2026-07-31

- Add a versioned Phase 2 strategy database covering all 9 TBC classes and 28 PvE specializations with localized role names, stat priorities, hard/soft caps, set goals, talent strings, guide links, and three switchable strategy modes per role.
- Import 29 WoWSims P2/T5 reference gear presets pinned to commit `3fc6a414979d62186f75d51ab6f6dd5d44f35b9c`, representing 475 non-empty target slots, with source attribution and the upstream MIT notice included in release packages.
- Add distinct tank mitigation/threat, healer throughput/longevity, and DPS cap-recovery/output models that recalculate item comparisons and recommendations immediately.
- Add a localized P2 Guide GUI with mode controls, cap status, route goal, target-set collection progress, real item icons, localized links, item levels, and in-game tooltips.
- Export the full P2 strategy context, modes, caps, evidence level, guide source, target preset, owned/missing target items, Wowhead links, and research sources in AI Text/JSON, Markdown, and plain text.
- Update the AI prompt to resolve hard gates before throughput, respect the selected strategy mode, and distinguish simulation-backed presets from guide-only healer or niche-spec evidence.
- Expand the suite to 66 tests with 99.25% executable-line coverage, including database completeness, model separation, cap states, target progress, localization, JSON, and GUI interaction tests.

## [0.3.0] - 2026-07-31

- Map every selected talent into each class role model, including role-aligned points, selected talent icons/ranks, mapping coverage, and localized summaries.
- Add rank-scaled curated key-talent rules across every TBC class and common tank, healing, melee, ranged, and caster roles; these rules adjust relevant stat weights without pretending to be a full combat simulator.
- Add role switching to Gear Advice so hybrid classes can compare the same saved items through tank, healing, or damage priorities.
- Add a visual comparison workbench with large current/candidate item icons, localized colored names, verdict, score change, evidence, gained/lost stats, and benchmark impact.
- Add a reusable item comparison engine with slot compatibility checks and role-specific scoring, and export available roles plus full talent mappings in JSON, Markdown, and text.
- Expand the suite to 62 tests with 99.17% executable-line coverage.

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
