local DB = {
    version = 2,
    phase = 2,
    phaseLabel = "TBC Anniversary Phase 2 (Tier 5)",
    patch = "2.5.6",
    updatedAt = "2026-08-01",
    content = { "Serpentshrine Cavern", "Tempest Keep: The Eye", "Arena Season 2", "Ogri'la", "Sha'tari Skyguard" },
    slotOrder = { "HEAD", "NECK", "SHOULDER", "BACK", "CHEST", "WRIST", "HANDS", "WAIST", "LEGS", "FEET", "FINGER1", "FINGER2", "TRINKET1", "TRINKET2", "MAINHAND", "OFFHAND", "RANGED" },
    sources = {
        {
            key = "wowsims",
            label = "WoWSims TBC",
            url = "https://github.com/wowsims/tbc-new",
            commit = "3fc6a414979d62186f75d51ab6f6dd5d44f35b9c",
            use = "P2/T5 gear presets, talent strings, encounter variants, and simulation-backed stat models where supported.",
        },
        {
            key = "wowhead",
            label = "Wowhead TBC Anniversary Phase 2 class guides",
            url = "https://www.wowhead.com/tbc/news/best-in-slot-guides-for-every-class-specialization-updated-for-phase-2-tbc-381617",
            use = "P2 acquisition routes, alternatives, set-bonus context, and healer guidance where a mature simulator is unavailable.",
        },
    },
    presets = {},
    classes = {},
}

local S = {
    stamina = "ITEM_MOD_STAMINA_SHORT",
    strength = "ITEM_MOD_STRENGTH_SHORT",
    agility = "ITEM_MOD_AGILITY_SHORT",
    intellect = "ITEM_MOD_INTELLECT_SHORT",
    spirit = "ITEM_MOD_SPIRIT_SHORT",
    armor = "ITEM_MOD_ARMOR",
    bonusArmor = "ITEM_MOD_BONUS_ARMOR_SHORT",
    defense = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
    dodge = "ITEM_MOD_DODGE_RATING_SHORT",
    parry = "ITEM_MOD_PARRY_RATING_SHORT",
    block = "ITEM_MOD_BLOCK_RATING_SHORT",
    blockValue = "ITEM_MOD_BLOCK_VALUE_SHORT",
    resilience = "ITEM_MOD_RESILIENCE_RATING_SHORT",
    attackPower = "ITEM_MOD_ATTACK_POWER_SHORT",
    rangedAttackPower = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    feralAttackPower = "ITEM_MOD_FERAL_ATTACK_POWER_SHORT",
    weaponDps = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
    hit = "ITEM_MOD_HIT_RATING_SHORT",
    rangedHit = "ITEM_MOD_HIT_RANGED_RATING_SHORT",
    spellHit = "ITEM_MOD_HIT_SPELL_RATING_SHORT",
    expertise = "ITEM_MOD_EXPERTISE_RATING_SHORT",
    crit = "ITEM_MOD_CRIT_RATING_SHORT",
    rangedCrit = "ITEM_MOD_CRIT_RANGED_RATING_SHORT",
    spellCrit = "ITEM_MOD_CRIT_SPELL_RATING_SHORT",
    haste = "ITEM_MOD_HASTE_RATING_SHORT",
    meleeHaste = "ITEM_MOD_HASTE_MELEE_RATING_SHORT",
    rangedHaste = "ITEM_MOD_HASTE_RANGED_RATING_SHORT",
    spellHaste = "ITEM_MOD_HASTE_SPELL_RATING_SHORT",
    spellPower = "ITEM_MOD_SPELL_POWER_SHORT",
    spellDamage = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
    healing = "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
    mp5 = "ITEM_MOD_MANA_REGENERATION_SHORT",
}

local function Labels(enUS, zhCN, zhTW)
    return { enUS = enUS, zhCN = zhCN, zhTW = zhTW or zhCN }
end

local function Cap(key, target, unit, kind, labels, note)
    return { key = key, target = target, unit = unit, kind = kind, labels = labels, note = note }
end

local function Mode(key, labels, multipliers, focus)
    return { key = key, labels = labels, multipliers = multipliers or {}, focus = focus or {} }
end

local function TankModes(threat)
    local threatMultipliers = {
        [S.hit] = 1.28,
        [S.spellHit] = 1.28,
        [S.expertise] = 1.30,
        [S.attackPower] = 1.18,
        [S.feralAttackPower] = 1.18,
        [S.spellPower] = 1.22,
        [S.weaponDps] = 1.15,
    }
    for token, multiplier in pairs(threat or {}) do
        threatMultipliers[token] = multiplier
    end
    return {
        Mode("balanced", Labels("Balanced", "均衡", "均衡"), {}, { "caps", "survival", "threat" }),
        Mode("mitigation", Labels("Mitigation / progression", "减伤 / 开荒", "減傷 / 開荒"), {
            [S.stamina] = 1.20, [S.armor] = 1.18, [S.bonusArmor] = 1.18, [S.defense] = 1.14,
            [S.dodge] = 1.14, [S.parry] = 1.12, [S.block] = 1.10, [S.resilience] = 1.10,
        }, { "crit_immunity", "effective_health", "avoidance" }),
        Mode("threat", Labels("Threat / farm", "仇恨 / Farm", "仇恨 / Farm"), threatMultipliers, { "required_caps", "threat", "tempo" }),
    }
end

local function HealerModes()
    return {
        Mode("balanced", Labels("Balanced", "均衡", "均衡"), {}, { "throughput", "longevity" }),
        Mode("throughput", Labels("Burst throughput", "爆发治疗量", "爆發治療量"), {
            [S.healing] = 1.22, [S.spellCrit] = 1.12, [S.spellHaste] = 1.12, [S.intellect] = 1.06,
        }, { "healing_power", "crit_or_haste" }),
        Mode("longevity", Labels("Mana longevity", "法力续航", "法力續航"), {
            [S.mp5] = 1.28, [S.spirit] = 1.22, [S.intellect] = 1.16, [S.spellCrit] = 1.06,
        }, { "fight_length", "regen", "mana_pool" }),
    }
end

local function DpsModes(powerTokens)
    local output = { [S.crit] = 1.10, [S.spellCrit] = 1.10, [S.haste] = 1.10, [S.spellHaste] = 1.10 }
    for index = 1, #(powerTokens or {}) do
        output[powerTokens[index]] = 1.14
    end
    return {
        Mode("balanced", Labels("Balanced", "均衡", "均衡"), {}, { "caps", "set_bonus", "output" }),
        Mode("cap", Labels("Cap recovery", "阈值补齐", "閾值補齊"), {
            [S.hit] = 1.35, [S.rangedHit] = 1.35, [S.spellHit] = 1.35, [S.expertise] = 1.30,
        }, { "hit", "expertise" }),
        Mode("output", Labels("Maximum output", "最大输出", "最大輸出"), output, { "power", "crit", "haste" }),
    }
end

local MELEE_CAPS = {
    Cap("melee_special_hit", 9, "%", "cap", Labels("Special attack hit", "近战技能命中", "近戰技能命中"), "Boss target before talents, racial bonuses, or raid debuffs."),
    Cap("expertise_dodge", 6.5, "%", "soft_cap", Labels("Dodge expertise", "防躲闪精准", "防閃躲熟練"), "26 expertise against a level 73 boss; do not assume parry is removed when attacking from the front."),
}

local RANGED_CAPS = {
    Cap("ranged_hit", 9, "%", "cap", Labels("Ranged hit", "远程命中", "遠程命中"), "Use a 6% gear route only when reliable talents or raid support supplies the remaining 3%; otherwise use 9%."),
}

local SPELL_CAPS = {
    Cap("spell_hit", 16, "%", "base_cap", Labels("Boss spell hit", "首领法术命中", "首領法術命中"), "Subtract school-specific talents and reliable raid debuffs from the 16% base miss chance."),
}

local TANK_CAPS = {
    Cap("defense_crit_immunity", 490, "defense", "hard_gate", Labels("Critical-hit immunity", "免暴防御技能", "免暴防禦技能"), "Resilience can replace part of defense; verify the combined crit reduction."),
    Cap("avoidance_table", 102.4, "%", "context", Labels("Uncrushable combat table", "防碾压战斗表", "防輾壓戰鬥表"), "Paladin and Warrior only. Include boss miss and temporary block effects; the standing sheet subtotal is incomplete."),
}

local function Role(definition)
    definition.phase = 2
    definition.modes = definition.modes or DpsModes({})
    return definition
end

local function Preset(key, label, roleKey, modeKey, itemIDs, sourcePath, notes)
    DB.presets[key] = {
        key = key,
        label = label,
        roleKey = roleKey,
        modeKey = modeKey or "balanced",
        itemIDs = itemIDs,
        source = "wowsims",
        sourcePath = sourcePath,
        notes = notes,
    }
end

Preset("balance_p2", "Balance P2", "balance_caster", "balanced", { 30233, 30015, 30235, 28797, 30231, 29918, 30232, 30038, 24262, 30067, 28753, 29302, 29370, 27683, 29988, 0, 32387 }, "ui/druid/balance/gear_sets/p2_a.gear.json")
Preset("bear_balanced", "Feral Bear P2 Balanced", "bear_tank", "balanced", { 30228, 30017, 30230, 28660, 30222, 32810, 29947, 30106, 30229, 32790, 30834, 29279, 28579, 32658, 32014, 0, 32387 }, "ui/druid/feralbear/gear_sets/p2_balanced.gear.json")
Preset("bear_survival", "Feral Bear P2 Survival", "bear_tank", "mitigation", { 30228, 33066, 30230, 28660, 30222, 32810, 30223, 30106, 30229, 32790, 29279, 28792, 32658, 28579, 30021, 0, 32387 }, "ui/druid/feralbear/gear_sets/p2_survival.gear.json")
Preset("bear_offensive", "Feral Bear P2 Offensive", "bear_tank", "threat", { 30228, 33066, 30230, 28660, 30222, 32810, 29947, 30106, 30229, 32790, 30834, 29997, 28288, 29383, 32014, 0, 32387 }, "ui/druid/feralbear/gear_sets/p2_offensive.gear.json")
Preset("bear_warden", "Feral Bear P2 Warden", "bear_tank", "balanced", { 8345, 30017, 30230, 28660, 30222, 32810, 30223, 30106, 30229, 32790, 30052, 29997, 30627, 29383, 32014, 0, 32387 }, "ui/druid/feralbear/gear_sets/p2_warden.gear.json")
Preset("bear_hydross_frost", "Feral Bear Hydross Frost", "bear_tank", "mitigation", { 8345, 24093, 28129, 22658, 22661, 22663, 22662, 32802, 22701, 32790, 31398, 30834, 28288, 29383, 28476, 0, 32387 }, "ui/druid/feralbear/gear_sets/p2_hydross_frost.gear.json", "Encounter resistance set; never use as a default boss set.")
Preset("bear_hydross_nature", "Feral Bear Hydross Nature", "bear_tank", "mitigation", { 8345, 24095, 24804, 25043, 24800, 32814, 24801, 32802, 24803, 32790, 31399, 30834, 28288, 29383, 28476, 0, 32387 }, "ui/druid/feralbear/gear_sets/p2_hydross_nature.gear.json", "Encounter resistance set; never use as a default boss set.")
Preset("cat_6_hit", "Feral Cat P2 6% Hit", "cat_dps", "output", { 8345, 30017, 29100, 29994, 29096, 29966, 29947, 30106, 29995, 28545, 29997, 30052, 30627, 29383, 32014, 0, 32387 }, "ui/druid/feralcat/gear_sets/p2_6p.gear.json")
Preset("cat_9_hit", "Feral Cat P2 9% Hit", "cat_dps", "cap", { 8345, 30017, 29100, 28672, 29096, 29966, 29947, 30106, 28741, 28545, 29997, 30052, 30627, 29383, 32014, 0, 32387 }, "ui/druid/feralcat/gear_sets/p2_9p.gear.json")
Preset("cat_alt_6_hit", "Feral Cat P2 T5 6% Hit", "cat_dps", "output", { 8345, 30017, 30230, 29994, 30222, 29966, 30223, 30106, 30229, 28545, 30834, 30052, 30627, 29383, 32014, 0, 32387 }, "ui/druid/feralcat/gear_sets/p2_alt_6p.gear.json")
Preset("cat_alt_9_hit", "Feral Cat P2 T5 9% Hit", "cat_dps", "cap", { 8345, 30017, 30230, 28672, 30222, 29966, 30223, 30106, 30229, 28545, 29997, 30052, 30627, 29383, 32014, 0, 32387 }, "ui/druid/feralcat/gear_sets/p2_alt_9p.gear.json")
Preset("hunter_bm_dw_6", "Beast Mastery DW 6% Hit", "beast_mastery", "output", { 30141, 30017, 30143, 29994, 30139, 29966, 30140, 30040, 29995, 30104, 29997, 28791, 29383, 28830, 32944, 29948, 30105 }, "ui/hunter/dps/gear_sets/phase_2/bm/dw_6p.gear.json")
Preset("hunter_bm_dw_9", "Beast Mastery DW 9% Hit", "beast_mastery", "cap", { 30141, 30017, 30143, 29994, 30139, 29966, 30140, 30040, 29995, 30104, 29997, 30052, 29383, 28830, 32944, 29948, 30105 }, "ui/hunter/dps/gear_sets/phase_2/bm/dw_9p.gear.json")
Preset("hunter_bm_2h_6", "Beast Mastery 2H 6% Hit", "beast_mastery", "output", { 30141, 30017, 30143, 29994, 30139, 29966, 30140, 30040, 29995, 30104, 29997, 28791, 29383, 28830, 29993, 0, 30105 }, "ui/hunter/dps/gear_sets/phase_2/bm/2h_6p.gear.json")
Preset("hunter_bm_2h_9", "Beast Mastery 2H 9% Hit", "beast_mastery", "cap", { 30141, 29381, 30143, 29994, 30139, 29966, 30140, 30040, 29995, 30104, 29997, 30052, 29383, 28830, 29993, 0, 30105 }, "ui/hunter/dps/gear_sets/phase_2/bm/2h_9p.gear.json")
Preset("hunter_sv_dw_6", "Survival DW 6% Hit", "survival_hunter", "output", { 30141, 30017, 30143, 29994, 30054, 29966, 28506, 30040, 29985, 30104, 29298, 28791, 29383, 28830, 29924, 29948, 30105 }, "ui/hunter/dps/gear_sets/phase_2/sv/dw_6p.gear.json")
Preset("hunter_sv_2h_6", "Survival 2H 6% Hit", "survival_hunter", "output", { 30141, 30017, 30143, 29994, 30054, 29966, 28506, 30040, 29985, 30104, 29298, 28791, 29383, 28830, 29993, 0, 30105 }, "ui/hunter/dps/gear_sets/phase_2/sv/2h_6p.gear.json")
Preset("mage_arcane_p2", "Arcane Mage P2", "arcane_mage", "balanced", { 30206, 30015, 30210, 29992, 30196, 29918, 29987, 30038, 30207, 30067, 29287, 29302, 30720, 29370, 29988, 0, 28783 }, "ui/mage/dps/gear_sets/p2Arcane.gear.json")
Preset("paladin_protection_p2", "Protection Paladin P2", "protection_tank", "balanced", { 30125, 30007, 29070, 29925, 29066, 32515, 30124, 30096, 30126, 32267, 30083, 28407, 29370, 28789, 30095, 28825, 27917 }, "ui/paladin/protection/gear_sets/p2.gear.json")
Preset("paladin_retribution_p2", "Retribution Paladin P2", "retribution_dps", "balanced", { 32461, 30022, 30055, 30098, 30129, 28795, 29947, 30106, 30257, 30104, 30061, 30834, 29383, 28830, 28430, 0, 27484 }, "ui/paladin/retribution/gear_sets/p2.gear.json")
Preset("shadow_priest_p2", "Shadow Priest P2", "shadow_dps", "balanced", { 30161, 30666, 30163, 29992, 30107, 24692, 28780, 30038, 29972, 21870, 30109, 29922, 38290, 29370, 28770, 29272, 29982 }, "ui/priest/dps/gear_sets/p2.gear.json")
Preset("rogue_combat_p2", "Combat Rogue P2", "combat_rogue", "balanced", { 30146, 29381, 30149, 28672, 30101, 29966, 30145, 30106, 30148, 28545, 30052, 29997, 28830, 30450, 30082, 32027, 29949 }, "ui/rogue/dps/gear_sets/p2.gear.json")
Preset("shaman_elemental_p2", "Elemental Shaman P2", "elemental_dps", "balanced", { 29035, 30015, 29037, 28797, 30169, 29918, 28780, 30038, 30172, 30067, 30667, 30109, 29370, 28785, 29988, 0, 28248 }, "ui/shaman/elemental/gear_sets/p2.gear.json")
Preset("shaman_enhancement_p2", "Enhancement Shaman P2", "enhancement_dps", "balanced", { 30190, 30017, 30055, 29994, 30185, 30091, 30189, 30106, 30192, 30039, 29997, 30052, 28830, 29383, 32944, 29996, 27815 }, "ui/shaman/enhancement/gear_sets/p2.gear.json")
Preset("warlock_t5", "Warlock T5", "destruction_warlock", "balanced", { 30212, 30015, 28967, 28766, 30107, 29918, 28968, 30038, 30213, 30037, 30109, 29302, 29370, 27683, 30095, 30049, 29982 }, "ui/warlock/dps/gear_sets/t5.gear.json")
Preset("warrior_arms_p2", "Arms Warrior P2", "arms_warrior", "balanced", { 32461, 30022, 30055, 24259, 30101, 30057, 29947, 30106, 29995, 30081, 29997, 30834, 28830, 21670, 29993, 0, 30105 }, "ui/warrior/dps/gear_sets/p2_arms.gear.json")
Preset("warrior_fury_p2", "Fury Warrior P2", "fury_warrior", "balanced", { 30120, 30022, 30122, 24259, 30118, 30057, 30119, 30106, 29995, 30081, 29997, 28757, 21670, 28830, 28439, 30082, 30105 }, "ui/warrior/dps/gear_sets/p2_fury.gear.json")
Preset("warrior_protection_p2", "Protection Warrior P2", "warrior_protection", "balanced", { 30115, 33066, 30117, 29994, 30113, 32818, 29947, 30106, 30116, 32793, 30834, 29283, 28121, 37128, 30058, 28825, 32756 }, "ui/warrior/protection/gear_sets/p2_bis.gear.json")
Preset("warrior_hydross_p2", "Protection Warrior Hydross", "warrior_protection", "mitigation", { 31371, 28244, 29023, 28328, 31369, 28996, 30644, 28995, 31370, 28997, 31398, 30834, 23836, 29181, 28438, 28189, 28319 }, "ui/warrior/protection/gear_sets/p2_hydross.gear.json", "Encounter resistance set; never use as a default boss set.")

DB.classes.DRUID = { roles = {
    Role({ key = "balance_caster", talentRuleKey = "balance_caster", label = "Balance Druid", labels = Labels("Balance Druid", "平衡德鲁伊", "平衡德魯伊"), talentTabs = { 1 }, archetype = "caster", models = { "caster_dps", "mana_longevity" }, priorities = { "spell hit to adjusted cap", "Tier 5 set threshold", "spell damage", "spell crit", "haste", "intellect" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellPower, S.spellHit, S.spellCrit, S.spellHaste, S.intellect, S.spirit }, caps = SPELL_CAPS, modes = DpsModes({ S.spellPower }), setGoal = "Nordrassil Regalia 4-piece", talentString = "510022312503135231351--520033", presets = { "balance_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/druid/balance/dps-bis-gear-pve-phase-2" }),
    Role({ key = "bear_tank", talentRuleKey = "bear_tank", label = "Feral Bear Tank", labels = Labels("Feral Bear Tank", "野性熊坦", "野性熊坦"), talentTabs = { 2 }, archetype = "tank", models = { "tank_mitigation", "tank_threat" }, priorities = { "crit immunity", "armor and effective health", "stamina", "agility/dodge", "expertise", "hit", "feral attack power" }, benchmarkKeys = { "defense_crit_immunity", "melee_special_hit", "expertise_dodge" }, statTokens = { S.stamina, S.armor, S.bonusArmor, S.agility, S.resilience, S.defense, S.expertise, S.hit, S.feralAttackPower }, caps = { TANK_CAPS[1], MELEE_CAPS[1], MELEE_CAPS[2] }, modes = TankModes({ [S.feralAttackPower] = 1.25, [S.agility] = 1.12 }), setGoal = "Choose Survival, Balanced, Offensive, Warden, or Hydross resistance set per encounter", talentString = "-503032132322105301251-05503301", presets = { "bear_balanced", "bear_survival", "bear_offensive", "bear_warden", "bear_hydross_frost", "bear_hydross_nature" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/druid/feral/tank-bis-gear-pve-phase-2" }),
    Role({ key = "cat_dps", talentRuleKey = "cat_dps", label = "Feral Cat DPS", labels = Labels("Feral Cat DPS", "野性猎豹输出", "野性獵豹輸出"), talentTabs = { 2 }, archetype = "melee", models = { "melee_dps", "weapon_selection" }, priorities = { "6% or 9% hit route", "Tier 4 2-piece versus T5 off-pieces", "agility", "strength", "feral attack power", "crit", "expertise" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.agility, S.strength, S.feralAttackPower, S.attackPower, S.hit, S.expertise, S.crit }, caps = MELEE_CAPS, modes = DpsModes({ S.agility, S.feralAttackPower }), setGoal = "Compare Tier 4 2-piece finisher route against T5 alternatives", talentString = "-503032132322105301251-05503301", presets = { "cat_6_hit", "cat_9_hit", "cat_alt_6_hit", "cat_alt_9_hit" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/druid/feral/dps-bis-gear-pve-phase-2" }),
    Role({ key = "restoration_healer", talentRuleKey = "restoration_healer", label = "Restoration Druid", labels = Labels("Restoration Druid", "恢复德鲁伊", "恢復德魯伊"), talentTabs = { 3 }, archetype = "healer", models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "spirit", "mp5", "intellect", "haste", "Lifebloom idol" }, benchmarkKeys = {}, statTokens = { S.healing, S.spirit, S.mp5, S.intellect, S.spellHaste }, caps = {}, modes = HealerModes(), setGoal = "Nordrassil Raiment and encounter-length mana set", talentString = "05320031103--230023312131502331050313051", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/druid/healer-bis-gear-pve-phase-2", evidence = "guide" }),
} }

DB.classes.WARRIOR = { roles = {
    Role({ key = "arms_warrior", talentRuleKey = "arms_fury_dps", label = "Arms Warrior", labels = Labels("Arms Warrior", "武器战士", "武器戰士"), talentTabs = { 1 }, archetype = "melee", models = { "melee_dps", "raid_debuff" }, priorities = { "weapon damage", "hit", "expertise", "strength", "attack power", "crit", "haste" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.strength, S.attackPower, S.crit, S.meleeHaste }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.strength }), setGoal = "Destroyer Battlegear and Blood Frenzy raid utility", talentString = "3400502130201-05050005505012050115", presets = { "warrior_arms_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/warrior/arms/dps-bis-gear-pve-phase-2" }),
    Role({ key = "fury_warrior", talentRuleKey = "arms_fury_dps", label = "Fury Warrior", labels = Labels("Fury Warrior", "狂怒战士", "狂怒戰士"), talentTabs = { 2 }, archetype = "melee", models = { "melee_dps", "weapon_selection" }, priorities = { "main/off-hand weapon damage", "hit plan", "expertise", "strength", "attack power", "crit", "haste" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.strength, S.attackPower, S.crit, S.meleeHaste }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.strength }), setGoal = "Destroyer Battlegear with optimized dual-wield hit budget", talentString = "32005011352010500221-0550000500521203", presets = { "warrior_fury_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/warrior/fury/dps-bis-gear-pve-phase-2" }),
    Role({ key = "warrior_protection", talentRuleKey = "protection_tank", label = "Protection Warrior", labels = Labels("Protection Warrior", "防护战士", "防護戰士"), talentTabs = { 3 }, archetype = "tank", models = { "tank_mitigation", "tank_threat" }, priorities = { "crit immunity", "102.4 combat table when required", "effective health", "expertise", "hit", "block value", "weapon threat" }, benchmarkKeys = { "defense_crit_immunity", "avoidance_table", "melee_special_hit", "expertise_dodge" }, statTokens = { S.stamina, S.armor, S.defense, S.dodge, S.parry, S.block, S.blockValue, S.expertise, S.hit, S.weaponDps }, caps = { TANK_CAPS[1], TANK_CAPS[2], MELEE_CAPS[1], MELEE_CAPS[2] }, modes = TankModes({ [S.weaponDps] = 1.25, [S.blockValue] = 1.15 }), setGoal = "Destroyer Armor with a separate Hydross resistance set", talentString = "35000301302-03-0055511033001101501351", presets = { "warrior_protection_p2", "warrior_hydross_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/warrior/protection/tank-bis-gear-pve-phase-2" }),
} }

DB.classes.PALADIN = { roles = {
    Role({ key = "holy_healer", talentRuleKey = "holy_healer", label = "Holy Paladin", labels = Labels("Holy Paladin", "神圣圣骑士", "神聖聖騎士"), talentTabs = { 1 }, archetype = "healer", models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "intellect", "spell crit", "mp5", "haste", "downrank efficiency" }, benchmarkKeys = {}, statTokens = { S.healing, S.intellect, S.spellCrit, S.mp5, S.spellHaste }, caps = {}, modes = HealerModes(), setGoal = "Crystalforge Raiment only when its set value beats healing off-pieces", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/paladin/holy/healer-bis-gear-pve-phase-2", evidence = "guide" }),
    Role({ key = "protection_tank", talentRuleKey = "protection_tank", label = "Protection Paladin", labels = Labels("Protection Paladin", "防护圣骑士", "防護聖騎士"), talentTabs = { 2 }, archetype = "tank", models = { "tank_mitigation", "spell_threat" }, priorities = { "crit immunity", "102.4 combat table", "stamina", "spell power", "defense/avoidance", "spell hit", "mana sustain" }, benchmarkKeys = { "defense_crit_immunity", "avoidance_table", "spell_hit" }, statTokens = { S.stamina, S.defense, S.armor, S.dodge, S.parry, S.block, S.blockValue, S.spellPower, S.spellHit, S.intellect, S.mp5 }, caps = { TANK_CAPS[1], TANK_CAPS[2], SPELL_CAPS[1] }, modes = TankModes({ [S.spellPower] = 1.32, [S.spellHit] = 1.30, [S.intellect] = 1.10 }), setGoal = "Keep Justicar Armor 2-piece for single-target threat; do not force weak Crystalforge bonuses", talentString = "-0530513050000142521051-052050003003", presets = { "paladin_protection_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/paladin/tank-bis-gear-pve-phase-2" }),
    Role({ key = "retribution_dps", talentRuleKey = "retribution_dps", label = "Retribution Paladin", labels = Labels("Retribution Paladin", "惩戒圣骑士", "懲戒聖騎士"), talentTabs = { 3 }, archetype = "melee", models = { "melee_dps", "utility_dps" }, priorities = { "weapon damage", "hit", "expertise", "strength", "crit", "haste", "seal twisting" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.strength, S.attackPower, S.crit, S.meleeHaste }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.strength }), setGoal = "Crystalforge Battlegear and weapon-first upgrade path", talentString = "5-053201-0523005120033125331051", presets = { "paladin_retribution_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/paladin/retribution/dps-bis-gear-pve-phase-2" }),
} }

DB.classes.PRIEST = { roles = {
    Role({ key = "discipline_priest", talentRuleKey = "healing", label = "Discipline Priest", labels = Labels("Discipline Priest", "戒律牧师", "戒律牧師"), talentTabs = { 1 }, archetype = "healer", models = { "healing_throughput", "mana_longevity", "raid_support" }, priorities = { "bonus healing", "intellect", "mp5", "spirit", "spell crit", "haste" }, benchmarkKeys = {}, statTokens = { S.healing, S.intellect, S.mp5, S.spirit, S.spellCrit, S.spellHaste }, caps = {}, modes = HealerModes(), setGoal = "Avatar Raiment pieces versus high-healing off-pieces", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/priest/healer-bis-gear-pve-phase-2", evidence = "guide" }),
    Role({ key = "holy_priest", talentRuleKey = "healing", label = "Holy Priest", labels = Labels("Holy Priest", "神圣牧师", "神聖牧師"), talentTabs = { 2 }, archetype = "healer", models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "spirit", "mp5", "intellect", "haste", "spell crit" }, benchmarkKeys = {}, statTokens = { S.healing, S.spirit, S.mp5, S.intellect, S.spellHaste, S.spellCrit }, caps = {}, modes = HealerModes(), setGoal = "Avatar Raiment with separate throughput and long-fight sets", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/priest/healer-bis-gear-pve-phase-2", evidence = "guide" }),
    Role({ key = "shadow_dps", talentRuleKey = "shadow_dps", label = "Shadow Priest", labels = Labels("Shadow Priest", "暗影牧师", "暗影牧師"), talentTabs = { 3 }, archetype = "caster", models = { "caster_dps", "mana_support" }, priorities = { "6% spell hit after Shadow Focus", "shadow damage", "spell power", "haste", "crit", "mana sustain" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellHit, S.spellPower, S.spellDamage, S.spellHaste, S.spellCrit, S.intellect, S.spirit }, caps = { Cap("spell_hit", 6, "%", "talent_cap", Labels("Shadow spell hit after talents", "天赋后暗影命中", "天賦後暗影命中"), "Assumes 5/5 Shadow Focus; adjust when the current build differs.") }, modes = DpsModes({ S.spellPower }), setGoal = "Avatar Regalia 4-piece and raid-mana support uptime", talentString = "500230013--503250510240103051451", presets = { "shadow_priest_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/priest/shadow/dps-bis-gear-pve-phase-2" }),
} }

DB.classes.SHAMAN = { roles = {
    Role({ key = "elemental_dps", talentRuleKey = "elemental_dps", label = "Elemental Shaman", labels = Labels("Elemental Shaman", "元素萨满", "元素薩滿"), talentTabs = { 1 }, archetype = "caster", models = { "caster_dps", "raid_support" }, priorities = { "adjusted spell hit", "spell power", "spell crit", "haste", "intellect", "mp5" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellHit, S.spellPower, S.spellCrit, S.spellHaste, S.intellect, S.mp5 }, caps = { Cap("spell_hit", 7, "%", "raid_cap", Labels("Raid-adjusted spell hit", "团队调整后法术命中", "團隊調整後法術命中"), "Assumes Elemental Precision and Totem of Wrath; use the 16% base cap when support changes.") }, modes = DpsModes({ S.spellPower }), setGoal = "Cataclysm Regalia with Totem of Wrath raid support", talentString = "55003105100213351051--05105301005", presets = { "shaman_elemental_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/shaman/elemental/dps-bis-gear-pve-phase-2" }),
    Role({ key = "enhancement_dps", talentRuleKey = "enhancement_dps", label = "Enhancement Shaman", labels = Labels("Enhancement Shaman", "增强萨满", "增強薩滿"), talentTabs = { 2 }, archetype = "melee", models = { "melee_dps", "raid_support", "weapon_selection" }, priorities = { "main/off-hand weapon speed", "hit", "expertise", "attack power", "strength/agility", "crit", "haste" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.attackPower, S.strength, S.agility, S.crit, S.meleeHaste }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.attackPower }), setGoal = "Cataclysm Harness with group Windfury/Unleashed Rage value", talentString = "03-500502210501133531151-50005301", presets = { "shaman_enhancement_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/shaman/enhancement/dps-bis-gear-pve-phase-2" }),
    Role({ key = "restoration_healer", talentRuleKey = "restoration_healer", label = "Restoration Shaman", labels = Labels("Restoration Shaman", "恢复萨满", "恢復薩滿"), talentTabs = { 3 }, archetype = "healer", models = { "healing_throughput", "mana_longevity", "raid_support" }, priorities = { "bonus healing", "mp5", "intellect", "spell crit", "haste", "Chain Heal efficiency" }, benchmarkKeys = {}, statTokens = { S.healing, S.mp5, S.intellect, S.spellCrit, S.spellHaste }, caps = {}, modes = HealerModes(), setGoal = "Cataclysm Raiment with Chain Heal and encounter-length mana variants", talentString = "-30205033-05005331335010501122331251", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/shaman/healer-bis-gear-pve-phase-2", evidence = "guide" }),
} }

DB.classes.HUNTER = { roles = {
    Role({ key = "beast_mastery", talentRuleKey = "ranged_dps", label = "Beast Mastery Hunter", labels = Labels("Beast Mastery Hunter", "野兽控制猎人", "野獸控制獵人"), talentTabs = { 1 }, archetype = "ranged", models = { "ranged_dps", "pet_synergy" }, priorities = { "6% or 9% hit route", "ranged weapon DPS", "agility", "attack power", "crit", "haste", "pet scaling" }, benchmarkKeys = { "ranged_hit" }, statTokens = { S.weaponDps, S.rangedHit, S.agility, S.rangedAttackPower, S.attackPower, S.rangedCrit, S.rangedHaste }, caps = RANGED_CAPS, modes = DpsModes({ S.weaponDps, S.agility, S.rangedAttackPower }), setGoal = "Rift Stalker Armor and 2H/DW route selected around party hit", talentString = "522002005150122431051-0505201205", presets = { "hunter_bm_dw_6", "hunter_bm_dw_9", "hunter_bm_2h_6", "hunter_bm_2h_9" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/hunter/beast-mastery/dps-bis-gear-pve-phase-2" }),
    Role({ key = "marksmanship_hunter", talentRuleKey = "ranged_dps", label = "Marksmanship Hunter", labels = Labels("Marksmanship Hunter", "射击猎人", "射擊獵人"), talentTabs = { 2 }, archetype = "ranged", models = { "ranged_dps", "raid_support" }, priorities = { "ranged hit", "ranged weapon DPS", "agility", "attack power", "crit", "haste", "Trueshot Aura" }, benchmarkKeys = { "ranged_hit" }, statTokens = { S.rangedHit, S.weaponDps, S.agility, S.rangedAttackPower, S.rangedCrit, S.rangedHaste }, caps = RANGED_CAPS, modes = DpsModes({ S.weaponDps, S.agility, S.rangedAttackPower }), setGoal = "Rift Stalker Armor with raid-support-aware off-pieces", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/hunter/marksmanship/dps-bis-gear-pve-phase-2", evidence = "guide" }),
    Role({ key = "survival_hunter", talentRuleKey = "ranged_dps", label = "Survival Hunter", labels = Labels("Survival Hunter", "生存猎人", "生存獵人"), talentTabs = { 3 }, archetype = "ranged", models = { "ranged_dps", "raid_support" }, priorities = { "6% or 9% hit route", "agility for Expose Weakness", "ranged weapon DPS", "crit", "attack power", "haste" }, benchmarkKeys = { "ranged_hit" }, statTokens = { S.rangedHit, S.agility, S.weaponDps, S.rangedCrit, S.rangedAttackPower, S.rangedHaste }, caps = RANGED_CAPS, modes = DpsModes({ S.agility, S.weaponDps }), setGoal = "Rift Stalker pieces with maximum sustainable Expose Weakness agility", talentString = "502-0550201205-333200022003223005103", presets = { "hunter_sv_dw_6", "hunter_sv_2h_6" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/hunter/survival/dps-bis-gear-pve-phase-2" }),
} }

DB.classes.ROGUE = { roles = {
    Role({ key = "assassination_rogue", talentRuleKey = "melee_dps", label = "Assassination Rogue", labels = Labels("Assassination Rogue", "刺杀潜行者", "刺殺盜賊"), talentTabs = { 1 }, archetype = "melee", models = { "melee_dps", "weapon_selection" }, priorities = { "weapon speed/poison plan", "special hit", "expertise", "agility", "attack power", "crit", "haste" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.agility, S.attackPower, S.crit, S.meleeHaste }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.agility }), setGoal = "Deathmantle pieces only when the build and poison plan support them", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2", evidence = "guide" }),
    Role({ key = "combat_rogue", talentRuleKey = "melee_dps", label = "Combat Rogue", labels = Labels("Combat Rogue", "战斗潜行者", "戰鬥盜賊"), talentTabs = { 2 }, archetype = "melee", models = { "melee_dps", "weapon_selection" }, priorities = { "main/off-hand weapon plan", "special and poison hit", "expertise", "agility", "attack power", "haste", "crit" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.agility, S.attackPower, S.meleeHaste, S.crit }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.agility }), setGoal = "Deathmantle Armor with weapon-specialization-matched upgrades", talentString = "0053201252-023305200005015002321151", presets = { "rogue_combat_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2" }),
    Role({ key = "subtlety_rogue", talentRuleKey = "melee_dps", label = "Subtlety Rogue", labels = Labels("Subtlety Rogue", "敏锐潜行者", "敏銳盜賊"), talentTabs = { 3 }, archetype = "melee", models = { "melee_dps", "utility_dps" }, priorities = { "special hit", "weapon damage", "expertise", "agility", "attack power", "crit", "utility" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.hit, S.weaponDps, S.expertise, S.agility, S.attackPower, S.crit }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.agility }), setGoal = "Use Combat P2 pieces only as a starting point; validate the utility build separately", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2", evidence = "guide" }),
} }

DB.classes.MAGE = { roles = {
    Role({ key = "arcane_mage", talentRuleKey = "caster_dps", label = "Arcane Mage", labels = Labels("Arcane Mage", "奥术法师", "奧術法師"), talentTabs = { 1 }, archetype = "caster", models = { "caster_dps", "mana_longevity" }, priorities = { "arcane hit after Arcane Focus", "Tier 5 set", "intellect", "spell power", "spirit", "crit", "haste" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellHit, S.intellect, S.spellPower, S.spirit, S.spellCrit, S.spellHaste, S.mp5 }, caps = { Cap("spell_hit", 6, "%", "talent_cap", Labels("Arcane hit after talents", "天赋后奥术命中", "天賦後奧術命中"), "Assumes 5/5 Arcane Focus; subtract reliable Misery when present.") }, modes = DpsModes({ S.intellect, S.spellPower }), setGoal = "Tirisfal Regalia and Serpent-Coil Braid mana-cycle route", talentString = "2500052300030150330125--053500031003001", presets = { "mage_arcane_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/mage/arcane/dps-bis-gear-pve-phase-2" }),
    Role({ key = "fire_mage", talentRuleKey = "caster_dps", label = "Fire Mage", labels = Labels("Fire Mage", "火焰法师", "火焰法師"), talentTabs = { 2 }, archetype = "caster", models = { "caster_dps" }, priorities = { "fire hit after Elemental Precision", "spell power", "spell crit", "haste", "intellect", "set bonus" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellHit, S.spellPower, S.spellCrit, S.spellHaste, S.intellect }, caps = { Cap("spell_hit", 13, "%", "talent_cap", Labels("Fire hit after talents", "天赋后火焰命中", "天賦後火焰命中"), "Assumes 3/3 Elemental Precision; subtract reliable Misery when present.") }, modes = DpsModes({ S.spellPower }), setGoal = "Tirisfal Regalia versus fire-damage off-pieces", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/mage/fire/dps-bis-gear-pve-phase-2", evidence = "guide" }),
    Role({ key = "frost_mage", talentRuleKey = "caster_dps", label = "Frost Mage", labels = Labels("Frost Mage", "冰霜法师", "冰霜法師"), talentTabs = { 3 }, archetype = "caster", models = { "caster_dps", "control" }, priorities = { "frost hit after Elemental Precision", "spell power", "spell crit", "haste", "intellect", "survivability" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellHit, S.spellPower, S.spellCrit, S.spellHaste, S.intellect, S.stamina }, caps = { Cap("spell_hit", 13, "%", "talent_cap", Labels("Frost hit after talents", "天赋后冰霜命中", "天賦後冰霜命中"), "Assumes 3/3 Elemental Precision; subtract reliable Misery when present.") }, modes = DpsModes({ S.spellPower }), setGoal = "Tirisfal Regalia versus frost-damage off-pieces", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/mage/frost/dps-bis-gear-pve-phase-2", evidence = "guide" }),
} }

DB.classes.WARLOCK = { roles = {
    Role({ key = "affliction_warlock", talentRuleKey = "caster_dps", label = "Affliction Warlock", labels = Labels("Affliction Warlock", "痛苦术士", "痛苦術士"), talentTabs = { 1 }, archetype = "caster", models = { "caster_dps", "raid_debuff" }, priorities = { "school-adjusted spell hit", "shadow damage", "spell power", "haste", "crit", "DoT uptime" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellHit, S.spellPower, S.spellDamage, S.spellHaste, S.spellCrit, S.intellect }, caps = SPELL_CAPS, modes = DpsModes({ S.spellPower }), setGoal = "Corruptor Raiment with Affliction uptime/debuff requirements", talentString = "05022221112351055003--50500051220001", presets = { "warlock_t5" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/warlock/affliction/dps-bis-gear-pve-phase-2" }),
    Role({ key = "demonology_warlock", talentRuleKey = "caster_dps", label = "Demonology Warlock", labels = Labels("Demonology Warlock", "恶魔学识术士", "惡魔學識術士"), talentTabs = { 2 }, archetype = "caster", models = { "caster_dps", "pet_synergy", "survivability" }, priorities = { "spell hit", "spell power", "stamina/intellect pet scaling", "crit", "haste", "pet uptime" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellHit, S.spellPower, S.stamina, S.intellect, S.spellCrit, S.spellHaste }, caps = SPELL_CAPS, modes = DpsModes({ S.spellPower, S.stamina, S.intellect }), setGoal = "Corruptor Raiment with pet-survival-aware alternatives", talentString = "01-205003213305010150134-50500251020001", presets = { "warlock_t5" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/warlock/demonology/dps-bis-gear-pve-phase-2" }),
    Role({ key = "destruction_warlock", talentRuleKey = "caster_dps", label = "Destruction Warlock", labels = Labels("Destruction Warlock", "毁灭术士", "毀滅術士"), talentTabs = { 3 }, archetype = "caster", models = { "caster_dps" }, priorities = { "spell hit", "shadow/fire damage", "spell power", "crit", "haste", "set bonus" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellHit, S.spellPower, S.spellDamage, S.spellCrit, S.spellHaste, S.intellect }, caps = SPELL_CAPS, modes = DpsModes({ S.spellPower }), setGoal = "Corruptor Raiment with separate shadow and fire encounter variants", talentString = "-20500301332101-50500051220051053105", presets = { "warlock_t5" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/warlock/destruction/dps-bis-gear-pve-phase-2" }),
} }

local GOAL_LABELS = {
    ["DRUID.balance_caster"] = Labels("Nordrassil Regalia 4-piece", "诺达希尔法衣 4 件套", "諾達希爾法衣 4 件套"),
    ["DRUID.bear_tank"] = Labels("Choose Survival, Balanced, Offensive, Warden, or Hydross resistance set per encounter", "按首领选择生存、均衡、仇恨、典狱官或海度斯抗性套装", "按首領選擇生存、均衡、仇恨、典獄官或海度斯抗性套裝"),
    ["DRUID.cat_dps"] = Labels("Compare Tier 4 2-piece finisher route against T5 alternatives", "比较 T4 两件套终结技路线与 T5 替代散件", "比較 T4 兩件套終結技路線與 T5 替代散件"),
    ["DRUID.restoration_healer"] = Labels("Nordrassil Raiment and encounter-length mana set", "诺达希尔愈衣，并按战斗时长准备续航套装", "諾達希爾癒衣，並按戰鬥時長準備續航套裝"),
    ["WARRIOR.arms_warrior"] = Labels("Destroyer Battlegear and Blood Frenzy raid utility", "毁灭者战甲与血性狂乱团队增益", "毀滅者戰甲與血性狂亂團隊增益"),
    ["WARRIOR.fury_warrior"] = Labels("Destroyer Battlegear with optimized dual-wield hit budget", "毁灭者战甲，并优化双持命中预算", "毀滅者戰甲，並最佳化雙持命中預算"),
    ["WARRIOR.warrior_protection"] = Labels("Destroyer Armor with a separate Hydross resistance set", "毁灭者护甲，并单独准备海度斯抗性套装", "毀滅者護甲，並單獨準備海度斯抗性套裝"),
    ["PALADIN.holy_healer"] = Labels("Crystalforge Raiment only when its set value beats healing off-pieces", "仅在套装收益胜过高治疗散件时使用晶铸圣装", "僅在套裝收益勝過高治療散件時使用晶鑄聖裝"),
    ["PALADIN.protection_tank"] = Labels("Keep Justicar Armor 2-piece for single-target threat; do not force weak Crystalforge bonuses", "保留公正两件套强化单体仇恨，不强凑较弱的晶铸套装效果", "保留公正兩件套強化單體仇恨，不強湊較弱的晶鑄套裝效果"),
    ["PALADIN.retribution_dps"] = Labels("Crystalforge Battlegear and weapon-first upgrade path", "晶铸战甲，并优先升级武器", "晶鑄戰甲，並優先升級武器"),
    ["PRIEST.discipline_priest"] = Labels("Avatar Raiment pieces versus high-healing off-pieces", "比较神使圣装部件与高治疗散件", "比較神使聖裝部件與高治療散件"),
    ["PRIEST.holy_priest"] = Labels("Avatar Raiment with separate throughput and long-fight sets", "神使圣装，并分别准备治疗量套装与长战续航套装", "神使聖裝，並分別準備治療量套裝與長戰續航套裝"),
    ["PRIEST.shadow_dps"] = Labels("Avatar Regalia 4-piece and raid-mana support uptime", "神使法衣 4 件套，并维持团队法力支援", "神使法衣 4 件套，並維持團隊法力支援"),
    ["SHAMAN.elemental_dps"] = Labels("Cataclysm Regalia with Totem of Wrath raid support", "灾难法衣与天怒图腾团队支援", "災難法衣與天怒圖騰團隊支援"),
    ["SHAMAN.enhancement_dps"] = Labels("Cataclysm Harness with group Windfury/Unleashed Rage value", "灾难甲胄，并计入小队风怒与怒火释放收益", "災難甲冑，並計入小隊風怒與怒火釋放收益"),
    ["SHAMAN.restoration_healer"] = Labels("Cataclysm Raiment with Chain Heal and encounter-length mana variants", "灾难圣装，并按治疗链与战斗时长准备变体", "災難聖裝，並按治療鏈與戰鬥時長準備變體"),
    ["HUNTER.beast_mastery"] = Labels("Rift Stalker Armor and 2H/DW route selected around party hit", "裂隙追猎者护甲，并按小队命中选择双持或双手路线", "裂隙追獵者護甲，並按小隊命中選擇雙持或雙手路線"),
    ["HUNTER.marksmanship_hunter"] = Labels("Rift Stalker Armor with raid-support-aware off-pieces", "裂隙追猎者护甲，并按团队支援选择散件", "裂隙追獵者護甲，並按團隊支援選擇散件"),
    ["HUNTER.survival_hunter"] = Labels("Rift Stalker pieces with maximum sustainable Expose Weakness agility", "裂隙追猎者部件，并最大化可持续的破甲虚弱敏捷收益", "裂隙追獵者部件，並最大化可持續的破甲虛弱敏捷收益"),
    ["ROGUE.assassination_rogue"] = Labels("Deathmantle pieces only when the build and poison plan support them", "仅当天赋与毒药方案匹配时采用死亡阴影部件", "僅當天賦與毒藥方案匹配時採用死亡陰影部件"),
    ["ROGUE.combat_rogue"] = Labels("Deathmantle Armor with weapon-specialization-matched upgrades", "死亡阴影护甲，并按武器专精匹配升级", "死亡陰影護甲，並按武器專精匹配升級"),
    ["ROGUE.subtlety_rogue"] = Labels("Use Combat P2 pieces only as a starting point; validate the utility build separately", "仅把战斗专精 P2 部件作为起点，单独验证功能型天赋", "僅把戰鬥專精 P2 部件作為起點，單獨驗證功能型天賦"),
    ["MAGE.arcane_mage"] = Labels("Tirisfal Regalia and Serpent-Coil Braid mana-cycle route", "提瑞斯法法衣与盘蛇饰带法力循环路线", "提瑞斯法法衣與盤蛇飾帶法力循環路線"),
    ["MAGE.fire_mage"] = Labels("Tirisfal Regalia versus fire-damage off-pieces", "比较提瑞斯法法衣与火焰伤害散件", "比較提瑞斯法法衣與火焰傷害散件"),
    ["MAGE.frost_mage"] = Labels("Tirisfal Regalia versus frost-damage off-pieces", "比较提瑞斯法法衣与冰霜伤害散件", "比較提瑞斯法法衣與冰霜傷害散件"),
    ["WARLOCK.affliction_warlock"] = Labels("Corruptor Raiment with Affliction uptime/debuff requirements", "腐蚀者法衣，并满足痛苦持续时间与减益需求", "腐蝕者法衣，並滿足痛苦持續時間與減益需求"),
    ["WARLOCK.demonology_warlock"] = Labels("Corruptor Raiment with pet-survival-aware alternatives", "腐蚀者法衣，并准备兼顾宠物生存的替代装备", "腐蝕者法衣，並準備兼顧寵物生存的替代裝備"),
    ["WARLOCK.destruction_warlock"] = Labels("Corruptor Raiment with separate shadow and fire encounter variants", "腐蚀者法衣，并分别准备暗影与火焰战斗变体", "腐蝕者法衣，並分別準備暗影與火焰戰鬥變體"),
}

for classToken, class in pairs(DB.classes) do
    for index = 1, #(class.roles or {}) do
        local role = class.roles[index]
        role.setGoalLabels = GOAL_LABELS[classToken .. "." .. role.key] or Labels(role.setGoal, role.setGoal, role.setGoal)
    end
end

function DB.GetClassRoles(classToken)
    local class = DB.classes[tostring(classToken or ""):upper()]
    return class and class.roles or nil
end

function DB.GetPreset(key)
    return DB.presets[key]
end

function DB.GetRole(classToken, roleKey)
    for index = 1, #(DB.GetClassRoles(classToken) or {}) do
        local role = DB.GetClassRoles(classToken)[index]
        if role.key == roleKey then
            return role
        end
    end
    return nil
end

_G.TBCGearExporterP2DB = DB
