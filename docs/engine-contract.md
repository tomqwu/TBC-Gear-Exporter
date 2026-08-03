# Gear Engine Contract

This document defines what TBC Gear Exporter database version 11 actually computes. It is the release gate for future engine claims.

## Current Maturity

The database contains 28 role records, but a role record is not the same thing as a validated specialization model.

| Scoring model | Roles | What it means |
| --- | ---: | --- |
| `phase_ep` | 3 | A static Phase 2 EP table was copied field-by-field from the pinned WoWSims source: Balance Druid, Retribution Paladin, and Arcane Mage. |
| `cross_phase_shared_ep` | 3 | The pinned WoWSims P1 Hunter BM/SV table is reused as an estimate for BM, MM, and SV. It is neither P2-specific nor MM-calibrated. |
| `ordered_stat_heuristic` | 22 | Weights are generated from the role's ordered stat list and generic unit scales. No simulator EP table calibrates the score. |
| `pvp_context_heuristic` | 28 overlays | PvP mode wraps the selected role model with same-level hit targets and explicit resilience/stamina weighting. Caster roles also receive spell penetration. This is not a PvP simulator or BiS list. |

No current model supports definitive upgrade verdicts. The addon may rank a visible-stat candidate, but labels larger heuristic results **Estimated candidate / 估算候选** and scores below 8 **Small improvement / 小幅提升**. Low-data items remain manual checks, and swaps that risk a tracked cap remain tradeoffs or are rejected.

Separately, 18 roles have a WoWSims reference gear route and 10 use a class-guide route. Holy Paladin now has three class-guide presets for Mixed Healing, Flash of Light, and Holy Light. A reference set supplies target item IDs and collection progress. It does **not** prove that a bag or bank candidate was simulated.

## Role Matrix

| Class | Role | Score model | Route evidence |
| --- | --- | --- | --- |
| Druid | Balance | P2 static EP | WoWSims reference gear + guide |
| Druid | Feral Bear | Ordered-stat heuristic | WoWSims reference gear + guide |
| Druid | Feral Cat | Ordered-stat heuristic | WoWSims reference gear + guide |
| Druid | Restoration | Ordered-stat heuristic | Guide |
| Warrior | Arms | Ordered-stat heuristic | WoWSims reference gear + guide |
| Warrior | Fury | Ordered-stat heuristic | WoWSims reference gear + guide |
| Warrior | Protection | Ordered-stat heuristic | WoWSims reference gear + guide |
| Paladin | Holy | Ordered-stat heuristic | Guide |
| Paladin | Protection | Ordered-stat heuristic | WoWSims reference gear + guide |
| Paladin | Retribution | P2 static EP | WoWSims reference gear + guide |
| Priest | Discipline | Ordered-stat heuristic | Guide |
| Priest | Holy | Ordered-stat heuristic | Guide |
| Priest | Shadow | Ordered-stat heuristic | WoWSims reference gear + guide |
| Shaman | Elemental | Ordered-stat heuristic | WoWSims reference gear + guide |
| Shaman | Enhancement | Ordered-stat heuristic | WoWSims reference gear + guide |
| Shaman | Restoration | Ordered-stat heuristic | Guide |
| Hunter | Beast Mastery | Shared P1 BM/SV EP estimate | WoWSims reference gear + guide |
| Hunter | Marksmanship | Shared P1 BM/SV EP estimate | Guide |
| Hunter | Survival | Shared P1 BM/SV EP estimate | WoWSims reference gear + guide |
| Rogue | Assassination | Ordered-stat heuristic | Guide |
| Rogue | Combat | Ordered-stat heuristic | WoWSims reference gear + guide |
| Rogue | Subtlety | Ordered-stat heuristic | Guide |
| Mage | Arcane | P2 static EP | WoWSims reference gear + guide |
| Mage | Fire | Ordered-stat heuristic | Guide |
| Mage | Frost | Ordered-stat heuristic | Guide |
| Warlock | Affliction | Ordered-stat heuristic | WoWSims reference gear + guide |
| Warlock | Demonology | Ordered-stat heuristic | WoWSims reference gear + guide |
| Warlock | Destruction | Ordered-stat heuristic | WoWSims reference gear + guide |

## Computation Boundary

The current comparison path is:

1. Detect gear context from equipped resilience density. At least 80 resilience across at least three pieces selects PvP automatically; smaller resilience samples remain mixed/PvE so a tank item or trinket cannot silently change the whole model. An explicit mode choice overrides automatic selection.
2. Resolve class compatibility (armor tier, shields, weapon proficiency, and relic ownership), equipment slot, and legal one-hand/two-hand layout. A tank role with a declared block model additionally rejects replacing an equipped shield with a non-shield off-hand (`shield_required`), because block chance and combat-table coverage are not visible as item stat deltas.
3. Reject items whose visible stats or curated known effect conflicts with the selected role archetype. In PvP mode, resilience is a universal compatible signal and spell penetration is compatible with caster roles.
4. Normalize item-stat aliases exposed by the TBC Anniversary API.
5. Apply the declared static EP table or ordered-stat heuristic to visible stats only.
6. Apply tracked cap-gap, selected key-talent, and strategy-mode multipliers. PvE multiplier layers scale only weights the role already declares; the explicit PvP overlay adds resilience and stamina for every role plus spell penetration for casters. Generic hit/crit/haste multipliers fall through to the role's physical school-specific weights. Generic hit/crit/haste ratings are physical-only stats in TBC: they never inherit spell-school weights and do not count toward the spell-hit benchmark. PvP uses 5% physical and 4% spell hit against same-level players and sharply devalues hit after the target. Preserve raw paper-doll values, detected talent bonuses, effective values, and role-specific targets separately; paper-doll expertise points are converted to percent (0.25% per point) before cap comparison. Defense rating projects into both combined critical-hit reduction and the visible dodge/parry/block subtotal. Once crit immunity is met, defense keeps partial avoidance value but is not boosted again by the contextual table check.
7. For a tank's Mitigation or Threat mode, split the same signed visible-stat formula into an explicit selected-objective subtotal and an off-objective subtotal. Feral Bear, Protection Warrior, and Protection Paladin declare separate role-specific threat tokens; all three share an explicit survival token set. A positive blended score that does not clear +2 in the selected objective is rejected from that mode's recommendation list and retained as `mode_mismatch` evidence. A selected-objective gain that gives up at least 2 points in the other dimension remains a visible tradeoff.
8. Compare curated item effects categorically for the selected strategy mode; effect affinity is never added to EP. A candidate with an explicitly weaker known effect is excluded from that replacement path. Equal affinity across different decision dimensions is an `effect_context` scenario tradeoff, not a numeric upgrade. Ring and trinket candidates are evaluated against both equipped items, and same-slot candidates rank by the full affinity delta before visible score. Sourced effect and set decisions remain independent from the tank objective subscore.
9. Evaluate curated set thresholds in the current full equipped set, marking a broken bonus as a tradeoff and a newly completed threshold as a contextual decision.
10. Reject swaps that worsen an unmet tracked gate. In PvP mode, any resilience loss is at least a visible tradeoff even when offensive stats produce a positive estimate.
11. Reconcile the score delta against a per-stat formula and record every changed but unscored visible stat with either a missing-role-weight or role/slot-applicability reason. Stat values participate with their sign: a weighted malus subtracts from an item's score instead of being silently dropped.
12. Rank one candidate per slot, retain an audit outcome for every other evaluated gear item, and report the formula, selected objective, off-objective score, excluded changes, talent context, rejection/ranking reason, effect choice, set impact, route gaps, projected cap impact, model kind, item-data completeness, and detected/active gear context.

Item level and quality do not add score. They are display and filtering fields, not performance stats. Empty sockets carry a fixed nominal placeholder weight (4 per socket) so a socketed item is not treated as statless; the placeholder appears in the score formula like any other component, while gem choices, socket bonuses, and enchants remain outside the evaluator. Exported stat weights keep four decimal places so each recorded `delta x weight` reproduces its recorded contribution.

Database version 11 contains a deliberately bounded contextual layer: 14 source-linked item effects, all 17 Tier 5 class sets with localized 2/4-piece thresholds, a source-labeled PvP overlay shared by all 28 roles, and explicit mitigation/threat objectives for all three tanks. Every class-role combination has a Tier 5 definition. Set rules require both class and role ownership, and active set counts are evaluated against the full equipped loadout. These rules can choose between strategy-mode items and protect active bonuses, but they do not produce numeric EP.

The engine does not currently model unlisted set bonuses or item effects, gems, enchants, socket bonuses, proc rates, weapon speed rules, school-specific spell coefficients, full rotations, encounter timelines, party buff uptime, pet uptime, healing assignments, or global whole-loadout interactions. It is not a combat simulator or a global loadout optimizer.

## Talent Contract

Every selected talent is exported with tree, rank, icon, and alignment when the client API supplies it. That is **representation coverage**.

Only a curated subset has a calculation rule that modifies weights or a tracked formula. That is **model coverage**. Database version 11 reports both values separately; it does not count an exported but unmodeled talent as modeled.

Talent benchmark bonuses are applied only when a role cap is expressed as a base target. A cap already labeled `talent_cap` or `raid_cap` is not adjusted a second time. Contextual conversions remain outside EP: for example, Expose Weakness reports attack power per physical attacker while active but does not pretend that raid value is the Hunter's simulated personal DPS.

## Evidence Contract

Three independent fields must not be conflated:

| Field | Question answered |
| --- | --- |
| `score_model` | How was the candidate score produced? |
| `gear_context` | Which context was detected, which one is active, whether it was automatic or manual, and how much equipped resilience supported detection? |
| `score_breakdown` | Which signed stat deltas and active weights produced the visible-stat score, and does their net reconcile with `score_gain`? |
| `mode_objective` / `ranking_score_gain` | For a specialized tank view, which stat axis controls ranking, how much that axis changes, how much the other dimension changes, and whether the candidate was rejected as a mode mismatch? |
| `unscored_changes` | Which visible stat changes were excluded because the role has no weight for them or the role does not use them in that equipment slot? |
| `raw_observed` / `talent_bonus` / `effective_observed` | How did the engine turn the paper-doll value plus detected talent contribution into the value tested against the role cap? |
| `talent_context_impacts` | Which talent-driven contextual values changed but were deliberately not converted into EP? |
| `candidate_evaluations` | Why was each evaluated gear item recommended, ranked below another same-slot candidate, blocked by a benchmark, or rejected by a compatibility/reliability gate? Each entry retains the actual equipped item and structured effect decision used for that comparison. |
| `route_evidence` | Where did the reference gear route come from? |
| `data_completeness` | How much comparable visible stat data was available for this item pair? |
| `known_effect` / `effect_decision` | Is a source-linked item effect applicable, and which selected mode does it fit? |
| `active_sets` | Which supported Tier 5 sets are equipped, and are their 2/4-piece bonuses active? |
| `set_impacts` | Does the proposed swap cross a curated equipped-set threshold? |
| `route_gaps` | Which items from the selected guide/reference route are not in current gear, bags, or bank? |

`evidence` remains in JSON as a compatibility alias for `data_completeness`; new consumers should use the explicit field. Effect affinity is ordinal context, not a score model or simulation result. `effect_rejected_count` reports candidates suppressed because the equipped effect is preferred in the selected mode, while `choice_kind` distinguishes spell-cycle choices from generic contextual effects.

## Engine Completion Gates

A role may enable definitive verdicts only after all of these are true:

1. Phase-appropriate, specialization-specific weights or an evaluator are pinned to a reproducible source and scenario.
2. Talent, race, group, and cap assumptions are inputs rather than prose-only notes.
3. Set, gem, enchant, socket, proc, and weapon constraints that can reverse a decision are represented.
4. Candidate swaps are validated in full-loadout context, including paired slots and set thresholds.
5. Golden fixtures cover representative real characters and compare results with the source simulator or another reproducible reference.
6. The UI and exports show scenario, provenance, limitations, and confidence separately.

Until then, the addon is a transparent candidate-ranking and export tool. This contract is intentionally stricter than the earlier documentation.
