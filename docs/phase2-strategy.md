# Phase 2 Strategy Database

TBC Gear Exporter v0.4.4 includes a versioned Phase 2 / Tier 5 strategy database used by the in-game P2 Guide, gear comparison engine, and AI/JSON exports.

## Database Scale

- 9 playable TBC classes.
- 28 PvE specializations: 3 tanks, 5 healers, 11 melee/ranged physical DPS roles, and 9 caster DPS roles.
- 3 switchable analysis modes for every role.
- 29 simulation reference presets with 475 non-empty target item slots.
- 17-slot target-set tracking against current equipment plus saved bags and bank.
- English, simplified Chinese, and traditional Chinese role, mode, cap, and route labels.
- Database version 4, including explicit pinned Hunter EP weights and dual-wield-aware one-hand comparisons.

The source of truth is [`TBCGearExporter/Phase2StrategyDB.lua`](../TBCGearExporter/Phase2StrategyDB.lua). Every role records its talent-tree rule, archetype, analysis models, priorities, stat tokens, caps, three modes, set/route goal, reference talent string where available, presets, evidence level, and guide URL.

## Evidence Policy

| Evidence | Meaning |
| --- | --- |
| Simulation preset + class guide | A WoWSims P2/T5 gear preset is available and the role also links to a Phase 2 class guide. |
| Class guide | The role uses curated stat/cap logic and a class guide, but no mature healer or niche-spec preset is presented as simulated certainty. |

The addon deliberately labels evidence instead of calling every weighted score a definitive BiS result. It never silently invents set-bonus values, proc rates, encounter timelines, rotations, gems, or enchants.

## Strategy Modes

| Archetype | Balanced | Specialized mode 1 | Specialized mode 2 |
| --- | --- | --- | --- |
| Tank | Required gates, survival, threat | Mitigation / progression: effective health, armor, avoidance, crit immunity | Threat / farm: hit, expertise, weapon or spell threat, tempo |
| Healer | Throughput and longevity | Burst throughput: healing, crit/haste, intellect | Mana longevity: mp5, spirit, intellect, fight length |
| DPS | Caps, set value, output | Cap recovery: hit and expertise | Maximum output: primary power, crit, haste |

Mode selection changes the role weights used by every item comparison. The selected mode is exported with the result so an external AI can reproduce the intended lens.

## Class And Route Matrix

| Class | Specialization | Important P2 gate or model | Route goal | Evidence |
| --- | --- | --- | --- | --- |
| Druid | Balance | Adjusted spell hit; caster output and mana | Nordrassil Regalia 4-piece | Simulation + guide |
| Druid | Feral Bear | Crit immunity; survival/threat; encounter resistance | Survival, Balanced, Offensive, Warden, or Hydross set by encounter | Simulation + guide |
| Druid | Feral Cat | 6%/9% hit routes; expertise; finisher value | Compare T4 2-piece with T5 alternatives | Simulation + guide |
| Druid | Restoration | Healing throughput versus fight-length mana | Nordrassil Raiment plus longevity variant | Guide |
| Warrior | Arms | 9% special hit; expertise; raid debuff value | Destroyer Battlegear and Blood Frenzy utility | Simulation + guide |
| Warrior | Fury | 9% special hit; expertise; dual-wield budget | Destroyer Battlegear with optimized hit plan | Simulation + guide |
| Warrior | Protection | 5.6% combined crit reduction; contextual 102.4 table; threat | Destroyer Armor plus Hydross resistance set | Simulation + guide |
| Paladin | Holy | Healing, intellect, crit, mp5; fight length | Crystalforge only when set value beats healing off-pieces | Guide |
| Paladin | Protection | 5.6% combined crit reduction; contextual 102.4 table; spell threat | Keep Justicar 2-piece for single-target threat; do not force weak T5 bonuses | Simulation + guide |
| Paladin | Retribution | 9% special hit; expertise; weapon damage | Crystalforge Battlegear with weapon-first upgrades | Simulation + guide |
| Priest | Discipline | Throughput, intellect/mp5, raid support | Avatar pieces versus high-healing off-pieces | Guide |
| Priest | Holy | Throughput, spirit/mp5, fight length | Separate Avatar throughput and longevity sets | Guide |
| Priest | Shadow | 6% spell hit after 5/5 Shadow Focus | Avatar Regalia 4-piece and mana-support uptime | Simulation + guide |
| Shaman | Elemental | 7% raid-adjusted spell hit assumption | Cataclysm Regalia and Totem of Wrath support | Simulation + guide |
| Shaman | Enhancement | Hit/expertise; weapon pairing; group buffs | Cataclysm Harness with Windfury/Unleashed Rage value | Simulation + guide |
| Shaman | Restoration | Chain Heal throughput versus mana longevity | Cataclysm Raiment with encounter-length variants | Guide |
| Hunter | Beast Mastery | 6%/9% hit route; pet and weapon scaling | Rift Stalker with party-hit-aware 2H/DW route | Simulation + guide |
| Hunter | Marksmanship | Ranged hit and raid-support value | Rift Stalker with support-aware off-pieces | Guide |
| Hunter | Survival | Ranged hit and Expose Weakness agility | Rift Stalker with maximum sustainable agility | Simulation + guide |
| Rogue | Assassination | Special hit, expertise, weapon/poison plan | Deathmantle only when build and poison plan support it | Guide |
| Rogue | Combat | Special/poison hit, expertise, weapon specialization | Deathmantle with weapon-matched upgrades | Simulation + guide |
| Rogue | Subtlety | Special hit and utility-build tradeoffs | Combat P2 set as a starting point; validate separately | Guide |
| Mage | Arcane | 6% arcane hit after 5/5 Arcane Focus; mana cycle | Tirisfal Regalia and Serpent-Coil Braid route | Simulation + guide |
| Mage | Fire | 13% fire hit after 3/3 Elemental Precision | Tirisfal versus fire-damage off-pieces | Guide |
| Mage | Frost | 13% frost hit after 3/3 Elemental Precision | Tirisfal versus frost-damage off-pieces | Guide |
| Warlock | Affliction | Adjusted spell hit; DoT/debuff uptime | Corruptor Raiment with uptime requirements | Simulation reference + guide |
| Warlock | Demonology | Spell hit; pet scaling and survival | Corruptor with pet-survival alternatives | Simulation reference + guide |
| Warlock | Destruction | Spell hit; shadow/fire output variants | Corruptor with separate school variants | Simulation + guide |

## Tank Rules

1. Resolve critical-hit immunity before treating a threat piece as a clean upgrade. The engine targets 5.6% combined boss critical-hit reduction from defense skill above the level-70 base, resilience rating, and applicable talents.
2. Defense skill contributes 0.04% critical-hit reduction per point above 350. At level 70, about 59.1 defense rating contributes 1%; 39.4 resilience rating contributes 1%.
3. A Feral bear with 3/3 Survival of the Fittest receives 3% from talents and therefore needs the remaining 2.6% from defense and resilience. This corresponds to 415 defense skill with no resilience, or about 103 resilience with no defense rating.
4. Treat the 102.4% shield combat table as contextual. The standing paper doll does not include boss miss or temporary block effects such as Holy Shield or Shield Block.
5. After gates, use Mitigation for progression/effective health, Balanced for general encounters, or Threat for farm and damage-limited pulls.
6. Resistance presets are encounter sets, never default boss sets.

## Healer Rules

1. Healer gearing is not reduced to a universal cap. Fight length, assignment, spell mix, downranking, raid composition, and mana support determine the throughput/longevity balance.
2. Throughput mode raises visible healing and crit/haste value. Longevity mode raises mp5, spirit, and intellect value.
3. Healer roles without a mature simulator preset are explicitly guide-backed. The engine still compares visible item stats but marks the evidence boundary.

## DPS Rules

1. Cap Recovery prioritizes the role's adjusted hit/expertise target; Maximum Output prioritizes power, crit, and haste after required caps.
2. Talent and raid assumptions are attached to the cap. For example, Arcane Focus, Elemental Precision, Shadow Focus, Totem of Wrath, Misery, Improved Faerie Fire, and Draenei party hit can change the amount needed from gear.
3. Weapon DPS, speed, set bonuses, school-specific effects, pet survival, and proc behavior remain explicit comparison caveats when the item API does not expose enough information.
4. Hunter visible-stat comparisons use the pinned WoWSims preset normalized to 1 agility: generic attack power 0.46, ranged attack power 0.40, hit 0.12, crit 0.92, haste 0.788, and ranged weapon DPS 1.75. Open hit caps and selected modes still apply their documented multipliers.
5. A generic one-hand weapon is compared with both current weapons only when the character is already dual wielding weapons. Shields, held-in-off-hand items, explicit main-hand weapons, and two-hand setups do not create a false off-hand route.

## Sources And Reproducibility

- [WoWSims TBC](https://github.com/wowsims/tbc-new), pinned to commit `3fc6a414979d62186f75d51ab6f6dd5d44f35b9c`, supplies the adapted P2/T5 item-ID presets and reference talent strings where available.
- [Pinned WoWSims Hunter preset source](https://github.com/wowsims/tbc-new/blob/3fc6a414979d62186f75d51ab6f6dd5d44f35b9c/ui/hunter/dps/presets.ts) supplies the Hunter EP values used by database version 4.
- [Wowhead Phase 2 specialization guide index](https://www.wowhead.com/tbc/news/best-in-slot-guides-for-every-class-specialization-updated-for-phase-2-tbc-381617) supplies role-specific acquisition, alternative, set-bonus, and healer context.
- [Wowhead Hunter stat priority](https://www.wowhead.com/tbc/guide/classes/hunter/dps-stat-priority-attributes-pve) supplies the TBC agility, hit, crit, and ranged attack-power context used to interpret the simulator weights.
- [Wowhead Feral tank stat priority](https://www.wowhead.com/tbc/guide/classes/druid/feral/tank-stat-priority-attributes-pve) supplies the defense/resilience equivalence and 39.4 resilience per 1% critical-hit reduction reference.
- [Wowhead Feral tank talents](https://www.wowhead.com/tbc/guide/classes/druid/feral/tank-talent-builds-pve) supplies the 3% reduction from 3/3 Survival of the Fittest.
- [Wowhead Feral tank gear set](https://www.wowhead.com/tbc/gear-set/pve-feral-tank-131518) supplies the 415 defense-skill and 103 resilience hard-cap references for a 3/3 Survival of the Fittest bear.
- The bundled [`ThirdPartyNotices.txt`](../TBCGearExporter/ThirdPartyNotices.txt) includes the WoWSims MIT license and exact source revision.

This database is designed to be auditable and replaceable. Future phases can add a new versioned database without changing saved inventory snapshots or the export contract.
