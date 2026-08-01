# Gear Engine Contract

This document defines what TBC Gear Exporter database version 6 actually computes. It is the release gate for future engine claims.

## Current Maturity

The database contains 28 role records, but a role record is not the same thing as a validated specialization model.

| Scoring model | Roles | What it means |
| --- | ---: | --- |
| `phase_ep` | 3 | A static Phase 2 EP table was copied field-by-field from the pinned WoWSims source: Balance Druid, Retribution Paladin, and Arcane Mage. |
| `cross_phase_shared_ep` | 3 | The pinned WoWSims P1 Hunter BM/SV table is reused as an estimate for BM, MM, and SV. It is neither P2-specific nor MM-calibrated. |
| `ordered_stat_heuristic` | 22 | Weights are generated from the role's ordered stat list and generic unit scales. No simulator EP table calibrates the score. |

No current model supports definitive upgrade verdicts. The addon may rank a visible-stat candidate, but labels it **Estimated candidate / 估算候选**. Low-data items remain manual checks, and swaps that risk a tracked cap remain tradeoffs or are rejected.

Separately, 18 roles have a WoWSims reference gear route and 10 use a class-guide route. A reference set supplies target item IDs and collection progress. It does **not** prove that a bag or bank candidate was simulated.

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
2. Reject items whose visible stats conflict with the selected role archetype.
3. Normalize item-stat aliases exposed by the TBC Anniversary API.
4. Apply the declared static EP table or ordered-stat heuristic.
5. Apply tracked cap-gap, selected key-talent, and strategy-mode multipliers.
6. Compare visible relevant stats and reject swaps that worsen an unmet tracked gate.
7. Rank one candidate per slot and report gains, losses, cap impact, model kind, and item-data completeness.

Item level and quality do not add score. They are display and filtering fields, not performance stats.

The engine does not currently model set bonuses, gems, enchants, socket bonuses, use/proc effects, weapon speed rules, school-specific spell coefficients, rotations, encounter timelines, party buff uptime, pet uptime, healing assignments, or whole-loadout interactions. It is not a combat simulator or a global loadout optimizer.

## Talent Contract

Every selected talent is exported with tree, rank, icon, and alignment when the client API supplies it. That is **representation coverage**.

Only a curated subset has a calculation rule that modifies weights or a tracked formula. That is **model coverage**. Database version 6 reports both values separately; it no longer counts an exported but unmodeled talent as modeled.

## Evidence Contract

Three independent fields must not be conflated:

| Field | Question answered |
| --- | --- |
| `score_model` | How was the candidate score produced? |
| `route_evidence` | Where did the reference gear route come from? |
| `data_completeness` | How much comparable visible stat data was available for this item pair? |

`evidence` remains in JSON as a compatibility alias for `data_completeness`; new consumers should use the explicit field.

## Engine Completion Gates

A role may enable definitive verdicts only after all of these are true:

1. Phase-appropriate, specialization-specific weights or an evaluator are pinned to a reproducible source and scenario.
2. Talent, race, group, and cap assumptions are inputs rather than prose-only notes.
3. Set, gem, enchant, socket, proc, and weapon constraints that can reverse a decision are represented.
4. Candidate swaps are validated in full-loadout context, including paired slots and set thresholds.
5. Golden fixtures cover representative real characters and compare results with the source simulator or another reproducible reference.
6. The UI and exports show scenario, provenance, limitations, and confidence separately.

Until then, the addon is a transparent candidate-ranking and export tool. This contract is intentionally stricter than the earlier documentation.
