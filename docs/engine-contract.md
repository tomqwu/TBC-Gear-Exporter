# Gear Engine Contract

This document defines what TBC Gear Exporter database version 8 actually computes. It is the release gate for future engine claims.

## Current Maturity

The database contains 28 role records, but a role record is not the same thing as a validated specialization model.

| Scoring model | Roles | What it means |
| --- | ---: | --- |
| `phase_ep` | 3 | A static Phase 2 EP table was copied field-by-field from the pinned WoWSims source: Balance Druid, Retribution Paladin, and Arcane Mage. |
| `cross_phase_shared_ep` | 3 | The pinned WoWSims P1 Hunter BM/SV table is reused as an estimate for BM, MM, and SV. It is neither P2-specific nor MM-calibrated. |
| `ordered_stat_heuristic` | 22 | Weights are generated from the role's ordered stat list and generic unit scales. No simulator EP table calibrates the score. |

No current model supports definitive upgrade verdicts. The addon may rank a visible-stat candidate, but labels it **Estimated candidate / 估算候选**. Low-data items remain manual checks, and swaps that risk a tracked cap remain tradeoffs or are rejected.

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

1. Resolve class compatibility, equipment slot, and legal one-hand/two-hand layout.
2. Reject items whose visible stats or curated known effect conflicts with the selected role archetype.
3. Normalize item-stat aliases exposed by the TBC Anniversary API.
4. Apply the declared static EP table or ordered-stat heuristic to visible stats only.
5. Apply tracked cap-gap, selected key-talent, and strategy-mode multipliers.
6. Compare curated item effects categorically for the selected strategy mode; effect affinity is never added to EP, and a candidate with an explicitly weaker known effect is excluded from that mode's recommendations.
7. Evaluate curated set thresholds in the current full equipped set, marking a broken bonus as a tradeoff and a newly completed threshold as a contextual decision.
8. Reject swaps that worsen an unmet tracked gate.
9. Reconcile the score delta against a per-stat formula and record every changed but unscored visible stat with either a missing-role-weight or role/slot-applicability reason.
10. Rank one candidate per slot, retain an audit outcome for every other evaluated gear item, and report the formula, excluded changes, rejection/ranking reason, effect choice, set impact, route gaps, cap impact, model kind, and item-data completeness.

Item level and quality do not add score. They are display and filtering fields, not performance stats.

Database version 8 contains a deliberately bounded contextual layer: 14 source-linked item effects and all 17 Tier 5 class sets with localized 2/4-piece thresholds. Every one of the 28 class-role combinations has a Tier 5 definition. Set rules require both class and role ownership, and active set counts are evaluated against the full equipped loadout. These rules can choose between strategy-mode items and protect active bonuses, but they do not produce numeric EP.

The engine does not currently model unlisted set bonuses or item effects, gems, enchants, socket bonuses, proc rates, weapon speed rules, school-specific spell coefficients, full rotations, encounter timelines, party buff uptime, pet uptime, healing assignments, or global whole-loadout interactions. It is not a combat simulator or a global loadout optimizer.

## Talent Contract

Every selected talent is exported with tree, rank, icon, and alignment when the client API supplies it. That is **representation coverage**.

Only a curated subset has a calculation rule that modifies weights or a tracked formula. That is **model coverage**. Database version 8 reports both values separately; it does not count an exported but unmodeled talent as modeled.

## Evidence Contract

Three independent fields must not be conflated:

| Field | Question answered |
| --- | --- |
| `score_model` | How was the candidate score produced? |
| `score_breakdown` | Which signed stat deltas and active weights produced the visible-stat score, and does their net reconcile with `score_gain`? |
| `unscored_changes` | Which visible stat changes were excluded because the role has no weight for them or the role does not use them in that equipment slot? |
| `candidate_evaluations` | Why was each evaluated gear item recommended, ranked below another same-slot candidate, blocked by a benchmark, or rejected by a compatibility/reliability gate? |
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
