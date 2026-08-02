# Phase 2 Strategy Database

TBC Gear Exporter v0.5.2 includes Phase 2 / Tier 5 strategy database version 8 and recommendation engine version 15, used by the in-game P2 Guide, explainable candidate ranking, and AI/JSON exports.

## Database Scale

- 9 playable TBC classes.
- 28 PvE specializations: 3 tanks, 5 healers, 11 melee/ranged physical DPS roles, and 9 caster DPS roles.
- 3 switchable analysis modes for every role.
- 32 reference gear presets with 526 non-empty target item slots: 29 WoWSims routes plus 3 Holy Paladin guide routes.
- 17-slot target-set tracking against current equipment plus saved bags and bank.
- 14 source-linked contextual item effects and all 17 Tier 5 class sets with localized 2-piece and 4-piece thresholds.
- Complete Tier 5 representation for all 28 class-role combinations, with class and role ownership checked independently.
- English, simplified Chinese, and traditional Chinese role, mode, cap, and route labels.
- Database version 8, including the score-model contract for every role, exact pinned P2 static EP tables for Balance, Retribution, and Arcane, a clearly downgraded shared P1 Hunter estimate, and no definitive upgrade verdicts.

The source of truth is [`TBCGearExporter/Phase2StrategyDB.lua`](../TBCGearExporter/Phase2StrategyDB.lua). Every role records its score-model kind and limitations in addition to its talent-tree rule, archetype, priorities, stat tokens, caps, modes, route goal, reference talent string where available, presets, route evidence, and guide URL. The exact support boundary and all 28 role maturity levels are in [the engine contract](engine-contract.md).

## Evidence Policy

| Route evidence | Meaning |
| --- | --- |
| WoWSims reference gear route + class guide | A P2/T5 item-ID route is available for target tracking. This does not calibrate candidate scoring. |
| Class guide route | No WoWSims target route is attached; the guide supplies route context only. |

Route evidence, score-model provenance, item-data completeness, curated effect decisions, and set impacts are independent. The addon does not call any current weighted result a definitive upgrade. It never silently invents unlisted set-bonus values, proc rates, encounter timelines, rotations, gems, or enchants.

## Strategy Modes

| Archetype | Balanced | Specialized mode 1 | Specialized mode 2 |
| --- | --- | --- | --- |
| Tank | Required gates, survival, threat | Mitigation / progression: effective health, armor, avoidance, crit immunity | Threat / farm: hit, expertise, weapon or spell threat, tempo |
| Healer | Throughput and longevity | Burst throughput: healing, crit/haste, intellect | Mana longevity: mp5, spirit, intellect, fight length |
| Holy Paladin | Mixed Flash of Light / Holy Light | Flash of Light: efficiency and sustained casting | Holy Light: burst and mana-cost management |
| DPS | Caps, set value, output | Cap recovery: hit and expertise | Maximum output: primary power, crit, haste |

Mode selection changes the role weights used by every item comparison. The same three localized controls appear on Gear Advice and the P2 Guide, and changing one immediately recalculates both pages and the export. Readable reports name the selected view and all available views; AI/JSON exports retain their keys and weights so external tools can reproduce the intended lens. Tank mitigation/progression and threat/farm remain separate rankings rather than being averaged together. Threat / farm deliberately lowers survival weights while raising offensive weights; unresolved hard gates still prevent unsafe suggestions.

Curated item effects are also mode-specific gates. If the equipped item's known effect has higher affinity for the selected mode, the candidate is excluded from that mode's recommendations even when its visible-stat heuristic is positive. The same candidate can reappear when another mode prefers its effect. This prevents a mitigation-oriented pull tool from being displayed as a balanced or threat upgrade solely because it has stamina.

## Class And Route Matrix

| Class | Specialization | Important P2 gate or model | Route goal | Route evidence |
| --- | --- | --- | --- | --- |
| Druid | Balance | Adjusted spell hit; caster output and mana | Nordrassil Regalia 4-piece | WoWSims route + guide |
| Druid | Feral Bear | Crit immunity; survival/threat; encounter resistance | Survival, Balanced, Offensive, Warden, or Hydross set by encounter | WoWSims route + guide |
| Druid | Feral Cat | 6%/9% hit routes; expertise; finisher value | Compare T4 2-piece with T5 alternatives | WoWSims route + guide |
| Druid | Restoration | Healing throughput versus fight-length mana | Nordrassil Raiment plus longevity variant | Guide route |
| Warrior | Arms | 9% special hit; expertise; raid debuff value | Destroyer Battlegear and Blood Frenzy utility | WoWSims route + guide |
| Warrior | Fury | 9% special hit; expertise; dual-wield budget | Destroyer Battlegear with optimized hit plan | WoWSims route + guide |
| Warrior | Protection | 5.6% combined crit reduction; contextual 102.4 table; threat | Destroyer Armor plus Hydross resistance set | WoWSims route + guide |
| Paladin | Holy | Healing, intellect, crit, mp5; spell cycle; known relic/trinket effects | Preserve Crystalforge 4-piece unless the replacement route is validated; choose libram by spell cycle | Three guide routes |
| Paladin | Protection | 5.6% combined crit reduction; contextual 102.4 table; spell threat | Keep Justicar 2-piece for single-target threat; do not force weak T5 bonuses | WoWSims route + guide |
| Paladin | Retribution | 9% special hit; expertise; weapon damage | Crystalforge Battlegear with weapon-first upgrades | WoWSims route + guide |
| Priest | Discipline | Throughput, intellect/mp5, raid support | Avatar pieces versus high-healing off-pieces | Guide route |
| Priest | Holy | Throughput, spirit/mp5, fight length | Separate Avatar throughput and longevity sets | Guide route |
| Priest | Shadow | 6% spell hit after 5/5 Shadow Focus | Avatar Regalia 4-piece and mana-support uptime | WoWSims route + guide |
| Shaman | Elemental | 7% raid-adjusted spell hit assumption | Cataclysm Regalia and Totem of Wrath support | WoWSims route + guide |
| Shaman | Enhancement | Hit/expertise; weapon pairing; group buffs | Cataclysm Harness with Windfury/Unleashed Rage value | WoWSims route + guide |
| Shaman | Restoration | Chain Heal throughput versus mana longevity | Cataclysm Raiment with encounter-length variants | Guide route |
| Hunter | Beast Mastery | 6%/9% hit route; pet and weapon scaling | Rift Stalker with party-hit-aware 2H/DW route | WoWSims route + guide |
| Hunter | Marksmanship | Ranged hit and raid-support value | Rift Stalker with support-aware off-pieces | Guide route |
| Hunter | Survival | Ranged hit and Expose Weakness agility | Rift Stalker with maximum sustainable agility | WoWSims route + guide |
| Rogue | Assassination | Special hit, expertise, weapon/poison plan | Deathmantle only when build and poison plan support it | Guide route |
| Rogue | Combat | Special/poison hit, expertise, weapon specialization | Deathmantle with weapon-matched upgrades | WoWSims route + guide |
| Rogue | Subtlety | Special hit and utility-build tradeoffs | Combat P2 set as a starting point; validate separately | Guide route |
| Mage | Arcane | 6% arcane hit after 5/5 Arcane Focus; mana cycle | Tirisfal Regalia and Serpent-Coil Braid route | WoWSims route + guide |
| Mage | Fire | 13% fire hit after 3/3 Elemental Precision | Tirisfal versus fire-damage off-pieces | Guide route |
| Mage | Frost | 13% frost hit after 3/3 Elemental Precision | Tirisfal versus frost-damage off-pieces | Guide route |
| Warlock | Affliction | Adjusted spell hit; DoT/debuff uptime | Corruptor Raiment with uptime requirements | WoWSims route + guide |
| Warlock | Demonology | Spell hit; pet scaling and survival | Corruptor with pet-survival alternatives | WoWSims route + guide |
| Warlock | Destruction | Spell hit; shadow/fire output variants | Corruptor with separate school variants | WoWSims route + guide |

## Tank Rules

1. Resolve critical-hit immunity before treating a threat piece as a clean upgrade. The engine targets 5.6% combined boss critical-hit reduction from defense skill above the level-70 base, resilience rating, and applicable talents.
2. Defense skill contributes 0.04% critical-hit reduction per point above 350. At level 70, 2.3654 defense rating supplies one defense skill, about 59.1 defense rating supplies 1% critical-hit reduction, and 39.4231 resilience rating supplies 1%.
3. A Feral bear with 3/3 Survival of the Fittest receives 3% from talents and therefore needs the remaining 2.6% from defense and resilience. This corresponds to 415 defense skill with no resilience, or about 103 resilience with no defense rating.
4. Treat the 102.4% shield combat table as contextual. The standing paper doll does not include boss miss or temporary block effects such as Holy Shield or Shield Block.
5. Item benchmark impacts convert ratings to their matching units: 15.77 physical hit rating per 1%, 12.62 spell hit rating per 1%, 3.94 expertise rating per expertise point, 18.9231 dodge rating per 1%, 23.6538 parry rating per 1%, and 7.8846 block rating per 1%.
6. Once the combined critical-hit reduction target is already met, excess resilience is heavily devalued; defense keeps partial value because it still contributes avoidance. A swap that reduces buffer but remains above target is labeled separately from one that actually falls below target.
7. Feral Bear Balanced and Mitigation include dodge rating. Strength and critical strike remain lower-priority threat signals and become more important in Threat / farm.
8. After gates, use Mitigation for progression/effective health, Balanced for general encounters, or Threat for farm and damage-limited pulls.
9. Resistance presets are encounter sets, never default boss sets.

## Healer Rules

1. Healer gearing is not reduced to a universal cap. Fight length, assignment, spell mix, downranking, raid composition, and mana support determine the throughput/longevity balance.
2. Throughput mode raises visible healing and crit/haste value. Longevity mode raises mp5, spirit, and intellect value.
3. Healer roles without a mature simulator preset are explicitly guide-backed. The engine still compares visible item stats but marks the evidence boundary.
4. Holy Paladin uses separate Mixed Healing, Flash of Light, and Holy Light modes. Blessed Book of Nagrand, Libram of Souls Redeemed, and Libram of Absolute Truth are compared by their sourced spell-specific behavior, not converted into EP.
5. Every Tier 5 set's 2-piece and 4-piece thresholds are evaluated against the full equipped set. A visible-stat off-piece that breaks an active threshold is labeled a tradeoff; a swap that completes one is surfaced as a contextual decision. A 5-to-4 swap preserves 4-piece, while a 4-to-3 swap breaks it.

## DPS Rules

1. Cap Recovery prioritizes the role's adjusted hit/expertise target; Maximum Output prioritizes power, crit, and haste after required caps.
2. Talent and raid assumptions are attached to the cap. For example, Arcane Focus, Elemental Precision, Shadow Focus, Totem of Wrath, Misery, Improved Faerie Fire, and Draenei party hit can change the amount needed from gear.
3. Weapon DPS, speed, set bonuses, school-specific effects, pet survival, and proc behavior remain explicit comparison caveats when the item API does not expose enough information.
4. Hunter visible-stat comparisons use the pinned WoWSims **P1** BM/SV EP table normalized to 1 agility: generic attack power 0.46, ranged attack power 0.40, hit 0.12, crit 0.92, haste 0.788, and ranged weapon DPS 1.75. Reusing it for P2 and Marksmanship is explicitly labeled a cross-phase/shared estimate.
5. A generic one-hand weapon is compared with both current weapons only when the character is already dual wielding weapons. Shields, held-in-off-hand items, explicit main-hand weapons, and two-hand setups do not create a false off-hand route.

## Sources And Reproducibility

- [WoWSims TBC](https://github.com/wowsims/tbc-new), pinned to commit `3fc6a414979d62186f75d51ab6f6dd5d44f35b9c`, supplies the adapted P2/T5 item-ID presets and reference talent strings where available.
- [Pinned WoWSims Balance source](https://github.com/wowsims/tbc-new/blob/3fc6a414979d62186f75d51ab6f6dd5d44f35b9c/ui/druid/balance/presets.ts), [Arcane source](https://github.com/wowsims/tbc-new/blob/3fc6a414979d62186f75d51ab6f6dd5d44f35b9c/ui/mage/dps/presets.ts), and [Retribution source](https://github.com/wowsims/tbc-new/blob/3fc6a414979d62186f75d51ab6f6dd5d44f35b9c/ui/paladin/retribution/presets.ts) supply the exact P2 static EP tables retained by database version 8.
- [Pinned WoWSims Hunter source](https://github.com/wowsims/tbc-new/blob/3fc6a414979d62186f75d51ab6f6dd5d44f35b9c/ui/hunter/dps/presets.ts) identifies the reused Hunter values as P1 BM/SV EP presets.
- [Pinned WoWSims TBC combat-rating constants](https://github.com/wowsims/tbc/blob/9e7504dca2e5253fb9ddff566c66c00e11679376/sim/core/constants.go) supply the level-70 rating conversions retained by database version 8.
- [Wowhead Phase 2 specialization guide index](https://www.wowhead.com/tbc/news/best-in-slot-guides-for-every-class-specialization-updated-for-phase-2-tbc-381617) supplies role-specific acquisition, alternative, set-bonus, and healer context.
- [Wowhead Holy Paladin Phase 2 gear guide](https://www.wowhead.com/tbc/guide/classes/paladin/holy/healer-bis-gear-pve-phase-2), [the Tier 5 set overview](https://www.wowhead.com/tbc/guide/tier-5-set-overview-burning-crusade-classic), and linked item/set pages in the database supply the spell-cycle routes, Tier 5 thresholds, and 14 curated effect records.
- [Wowhead Hunter stat priority](https://www.wowhead.com/tbc/guide/classes/hunter/dps-stat-priority-attributes-pve) supplies the TBC agility, hit, crit, and ranged attack-power context used to interpret the simulator weights.
- [Wowhead Feral tank stat priority](https://www.wowhead.com/tbc/guide/classes/druid/feral/tank-stat-priority-attributes-pve) supplies the defense/resilience equivalence and 39.4 resilience per 1% critical-hit reduction reference.
- [Wowhead Feral tank talents](https://www.wowhead.com/tbc/guide/classes/druid/feral/tank-talent-builds-pve) supplies the 3% reduction from 3/3 Survival of the Fittest.
- [Wowhead Feral tank gear set](https://www.wowhead.com/tbc/gear-set/pve-feral-tank-131518) supplies the 415 defense-skill and 103 resilience hard-cap references for a 3/3 Survival of the Fittest bear.
- The bundled [`ThirdPartyNotices.txt`](../TBCGearExporter/ThirdPartyNotices.txt) includes the WoWSims MIT license and exact source revision.

This database is designed to be auditable and replaceable. Future phases can add a new versioned database without changing saved inventory snapshots or the export contract.
