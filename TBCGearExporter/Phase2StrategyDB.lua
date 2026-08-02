local DB = {
    version = 8,
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
            use = "P2/T5 reference gear and talent presets plus explicitly imported static EP tables. A gear preset does not by itself calibrate candidate scoring.",
        },
        {
            key = "wowhead",
            label = "Wowhead TBC Anniversary Phase 2 class guides",
            url = "https://www.wowhead.com/tbc/news/best-in-slot-guides-for-every-class-specialization-updated-for-phase-2-tbc-381617",
            use = "P2 acquisition routes, alternatives, set-bonus context, and healer guidance where a mature simulator is unavailable.",
        },
    },
    presets = {},
    itemEffects = {},
    sets = {},
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

local function ScoreModel(kind, sourcePath, sourcePhase, sourceSpec, limitations)
    return {
        version = 1,
        kind = kind,
        sourceKey = sourcePath and "wowsims" or "local_heuristic",
        sourcePath = sourcePath,
        sourcePhase = sourcePhase,
        sourceSpec = sourceSpec,
        supportsDefinitiveVerdicts = false,
        limitations = limitations or {},
    }
end

local function TankModes(threat)
    local threatMultipliers = {
        [S.stamina] = 0.70,
        [S.armor] = 0.72,
        [S.bonusArmor] = 0.72,
        [S.defense] = 0.65,
        [S.dodge] = 0.55,
        [S.parry] = 0.55,
        [S.block] = 0.70,
        [S.resilience] = 0.50,
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

local function HolyPaladinModes()
    return {
        Mode("balanced", Labels("Mixed healing", "混合治疗", "混合治療"), {}, { "flash_of_light", "holy_light", "longevity" }),
        Mode("flash_of_light", Labels("Flash of Light", "圣光闪现", "聖光閃現"), {
            [S.healing] = 1.18, [S.intellect] = 1.08, [S.spellCrit] = 1.08, [S.mp5] = 1.12,
        }, { "flash_of_light", "efficiency", "sustained_casting" }),
        Mode("holy_light", Labels("Holy Light", "圣光术", "聖光術"), {
            [S.healing] = 1.12, [S.spellCrit] = 1.18, [S.intellect] = 1.12, [S.mp5] = 1.18,
        }, { "holy_light", "burst_throughput", "mana_cost" }),
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
    Cap("crit_immunity", 5.6, "%", "hard_gate", Labels("Combined critical-hit reduction", "综合免暴减免", "綜合免暴減免"), "Combines defense skill, resilience, and applicable talents. A bear with 3/3 Survival of the Fittest needs the remaining 2.6% from defense and resilience."),
    Cap("avoidance_table", 102.4, "%", "context", Labels("Uncrushable combat table", "防碾压战斗表", "防輾壓戰鬥表"), "Paladin and Warrior only. Include boss miss and temporary block effects; the standing sheet subtotal is incomplete."),
}

-- Pinned WoWSims P1 Hunter EP presets, normalized to 1 agility. These are
-- shared by the source BM and SV presets and are not a P2 or MM calibration.
-- Generic item attack power contributes both melee AP (0.06) and ranged AP
-- (0.40) for the visible item stat exposed by the WoW API.
local HUNTER_EP_WEIGHTS = {
    [S.agility] = 1,
    [S.attackPower] = 0.46,
    [S.rangedAttackPower] = 0.40,
    [S.hit] = 0.12,
    [S.rangedHit] = 0.12,
    [S.crit] = 0.92,
    [S.rangedCrit] = 0.92,
    [S.haste] = 0.788,
    [S.rangedHaste] = 0.788,
    [S.weaponDps] = 1.75,
}

-- Exact static Phase 2 EP tables imported from the pinned WoWSims revision.
-- They remain linear visible-stat estimates, not live character simulations.
local BALANCE_P2_EP_WEIGHTS = {
    [S.intellect] = 0.56,
    [S.spirit] = 0.12,
    [S.spellPower] = 1,
    [S.spellDamage] = 1,
    [S.spellHit] = 1.86,
    [S.spellCrit] = 0.69,
    [S.spellHaste] = 1.29,
    [S.mp5] = 0.04,
}

local ARCANE_P2_EP_WEIGHTS = {
    [S.intellect] = 1.31,
    [S.spirit] = 0.90,
    [S.spellPower] = 1,
    [S.spellDamage] = 1,
    [S.spellHit] = 2.30,
    [S.spellCrit] = 0.77,
    [S.spellHaste] = 0.55,
    [S.mp5] = 0.48,
}

local RETRIBUTION_P2_EP_WEIGHTS = {
    [S.strength] = 1,
    [S.agility] = 0.75,
    [S.attackPower] = 0.41,
    [S.hit] = 2.15,
    [S.crit] = 0.77,
    [S.meleeHaste] = 1.17,
    [S.expertise] = 2.14,
    [S.spellPower] = 0.17,
    [S.spellDamage] = 0.17,
    [S.weaponDps] = 5.34,
}

local ORDERED_STAT_MODEL = ScoreModel("ordered_stat_heuristic", nil, nil, nil, {
    "Weights are generated from the declared stat order and generic unit scales.",
    "No simulator EP table is attached to this role.",
})

local HUNTER_SHARED_P1_MODEL = ScoreModel("cross_phase_shared_ep", "ui/hunter/dps/presets.ts", 1, "BM/SV", {
    "The source labels these as P1 BM and P1 SV EP presets.",
    "The same table is reused for BM, MM, and SV here and is not P2-spec calibrated.",
})

local function Role(definition)
    definition.phase = 2
    definition.modes = definition.modes or DpsModes({})
    definition.scoreModel = definition.scoreModel or ORDERED_STAT_MODEL
    definition.routeEvidence = definition.evidence or (#(definition.presets or {}) > 0 and "simulator_preset" or "guide")
    return definition
end

local function Preset(key, label, roleKey, modeKey, itemIDs, sourcePath, notes, source)
    DB.presets[key] = {
        key = key,
        label = label,
        roleKey = roleKey,
        modeKey = modeKey or "balanced",
        itemIDs = itemIDs,
        source = source or "wowsims",
        sourcePath = sourcePath,
        notes = notes,
    }
end

local function ItemEffect(itemID, definition)
    definition.itemID = itemID
    definition.sourceKey = definition.sourceKey or "wowhead"
    definition.sourceUrl = definition.sourceUrl or ("https://www.wowhead.com/tbc/item=" .. tostring(itemID))
    DB.itemEffects[itemID] = definition
end

local function SetDefinition(key, definition)
    definition.key = key
    definition.sourceKey = definition.sourceKey or "wowhead"
    DB.sets[key] = definition
end

local function SetBonus(pieces, labels, roleKeys, modeAffinity)
    return {
        pieces = pieces,
        labels = labels,
        roleKeys = roleKeys,
        modeAffinity = modeAffinity or {},
    }
end

local function Tier5Set(key, setID, classToken, labels, roleKeys, itemIDs, bonuses)
    SetDefinition(key, {
        tier = 5,
        setID = setID,
        labels = labels,
        classTokens = { [classToken] = true },
        roleKeys = roleKeys,
        itemIDs = itemIDs,
        sourceUrl = "https://www.wowhead.com/tbc/item-set=" .. tostring(setID),
        bonuses = bonuses,
    })
end

ItemEffect(25644, {
    key = "blessed_book_of_nagrand",
    kind = "spell_specific_healing",
    choiceKind = "spell_cycle",
    roleKeys = { holy_healer = true },
    modeAffinity = { balanced = 2, flash_of_light = 3, holy_light = 0 },
    labels = Labels("Adds up to 79 healing to Flash of Light", "圣光闪现最多额外治疗 79 点", "聖光閃現最多額外治療 79 點"),
})
ItemEffect(28592, {
    key = "libram_of_souls_redeemed",
    kind = "blessing_synergy",
    choiceKind = "spell_cycle",
    roleKeys = { holy_healer = true },
    modeAffinity = { balanced = 3, flash_of_light = 2, holy_light = 2 },
    labels = Labels("Blessing of Light grants 60 more Flash of Light and 120 more Holy Light healing", "光明祝福使圣光闪现额外获得 60、圣光术额外获得 120 治疗", "光明祝福使聖光閃現額外獲得 60、聖光術額外獲得 120 治療"),
    requirements = { "Blessing of Light on the target" },
})
ItemEffect(30063, {
    key = "libram_of_absolute_truth",
    kind = "spell_mana_reduction",
    choiceKind = "spell_cycle",
    roleKeys = { holy_healer = true },
    modeAffinity = { balanced = 1, flash_of_light = 0, holy_light = 3 },
    labels = Labels("Reduces Holy Light mana cost by 34", "圣光术法力消耗降低 34 点", "聖光術法力消耗降低 34 點"),
})
ItemEffect(29388, {
    key = "libram_of_repentance",
    kind = "tank_block_effect",
    roleKeys = { protection_tank = true },
    modeAffinity = { balanced = 3, mitigation = 3, threat = 1 },
    labels = Labels("Increases Holy Shield block rating", "提高神圣之盾的格挡等级", "提高神聖之盾的格擋等級"),
})
ItemEffect(28590, {
    key = "ribbon_of_sacrifice",
    kind = "healing_cooldown",
    archetypes = { healer = true },
    modeAffinity = { balanced = 2, throughput = 3, longevity = 1, flash_of_light = 2, holy_light = 2 },
    labels = Labels("Direct heals can stack up to 150 additional healing received on the target for 20 sec", "20 秒内直接治疗可使目标受到的额外治疗叠加至 150 点", "20 秒內直接治療可使目標受到的額外治療疊加至 150 點"),
})
ItemEffect(30841, {
    key = "lower_city_prayerbook",
    kind = "healing_mana_cooldown",
    archetypes = { healer = true },
    modeAffinity = { balanced = 2, throughput = 1, longevity = 3, flash_of_light = 3, holy_light = 2 },
    labels = Labels("Heals cost 22 less mana for 15 sec on a 1 min cooldown", "使用后 15 秒内每次治疗少消耗 22 点法力，冷却 1 分钟", "使用後 15 秒內每次治療少消耗 22 點法力，冷卻 1 分鐘"),
})
ItemEffect(29376, {
    key = "essence_of_the_martyr",
    kind = "healing_throughput_cooldown",
    archetypes = { healer = true },
    modeAffinity = { balanced = 3, throughput = 3, longevity = 1, flash_of_light = 2, holy_light = 3 },
    labels = Labels("Increases healing by up to 297 for 20 sec on a 2 min cooldown", "使用后 20 秒内治疗提高最多 297 点，冷却 2 分钟", "使用後 20 秒內治療提高最多 297 點，冷卻 2 分鐘"),
})
ItemEffect(28727, {
    key = "pendant_of_the_violet_eye",
    kind = "stacking_mana_regen_cooldown",
    archetypes = { healer = true },
    modeAffinity = { balanced = 3, throughput = 1, longevity = 3, flash_of_light = 3, holy_light = 3 },
    labels = Labels("Spell casts grant stacking 21 mana per 5 sec regeneration for 20 sec", "使用后施法可叠加每 5 秒 21 点法力回复，持续 20 秒", "使用後施法可疊加每 5 秒 21 點法力回復，持續 20 秒"),
})
ItemEffect(30621, {
    key = "prism_of_inner_calm",
    kind = "harmful_crit_threat_reduction",
    archetypes = { melee = true, ranged = true, caster = true },
    modeAffinity = { balanced = 1, output = 1, threat = 3 },
    labels = Labels("Reduces threat from harmful critical strikes", "降低伤害性暴击产生的威胁", "降低傷害性致命一擊產生的威脅"),
})
ItemEffect(23836, {
    key = "goblin_rocket_launcher",
    kind = "engineering_stamina_pull_tool",
    roleKeys = { protection_tank = true, warrior_protection = true },
    modeAffinity = { balanced = 1, mitigation = 3, threat = 1 },
    labels = Labels("Stamina-focused pull tool; launches a ranged rocket but knocks the user down", "耐力向远程开怪工具；发射火箭时会击倒使用者", "耐力向遠程開怪工具；發射火箭時會擊倒使用者"),
    requirements = { "Engineering (350)", "Goblin Engineering", "Long cast makes the active effect an opener, not a tanking cooldown" },
})
ItemEffect(30629, {
    key = "scarab_of_displacement",
    kind = "defense_rating_cooldown",
    archetypes = { tank = true },
    modeAffinity = { balanced = 2, mitigation = 3, threat = 1 },
    labels = Labels("Grants 165 defense rating and reduces attack power by 330 for 15 sec; 3 min cooldown", "使用后 15 秒内获得 165 防御等级并降低 330 攻击强度；冷却 3 分钟", "使用後 15 秒內獲得 165 防禦等級並降低 330 攻擊強度；冷卻 3 分鐘"),
    requirements = { "Rebalance the full loadout around its passive defense rating", "Attack-power penalty matters to physical-threat tanks" },
})
ItemEffect(27529, {
    key = "figurine_of_the_colossus",
    kind = "block_healing_cooldown",
    roleKeys = { protection_tank = true, warrior_protection = true },
    modeAffinity = { balanced = 2, mitigation = 2, threat = 2 },
    labels = Labels("Each blocked attack heals 120 for 20 sec; 2 min cooldown", "使用后 20 秒内每次格挡恢复 120 点生命；冷却 2 分钟", "使用後 20 秒內每次格擋恢復 120 點生命；冷卻 2 分鐘"),
    requirements = { "Shield equipped", "Best against many frequent blockable attacks" },
})
ItemEffect(29370, {
    key = "icon_of_the_silver_crescent",
    kind = "spell_power_cooldown",
    roleKeys = { protection_tank = true },
    archetypes = { caster = true },
    modeAffinity = { balanced = 2, mitigation = 0, threat = 3, cap = 1, output = 3 },
    labels = Labels("Grants 155 spell damage for 20 sec; 2 min cooldown", "使用后 20 秒内获得 155 法术伤害；冷却 2 分钟", "使用後 20 秒內獲得 155 法術傷害；冷卻 2 分鐘"),
})
ItemEffect(28528, {
    key = "moroes_lucky_pocket_watch",
    kind = "dodge_cooldown",
    archetypes = { tank = true },
    modeAffinity = { balanced = 3, mitigation = 3, threat = 1 },
    labels = Labels("Grants 300 dodge rating for 10 sec; 2 min cooldown", "使用后 10 秒内获得 300 躲闪等级；冷却 2 分钟", "使用後 10 秒內獲得 300 閃躲等級；冷卻 2 分鐘"),
})

Tier5Set("nordrassil_regalia", 643, "DRUID", Labels("Nordrassil Regalia", "诺达希尔平衡套装", "諾達希爾平衡套裝"),
    { balance_caster = true }, { 30231, 30232, 30233, 30234, 30235 }, {
        SetBonus(2, Labels("Leaving Moonkin Form makes the next Regrowth cost 450 less mana", "离开枭兽形态后，下一次愈合法力消耗降低 450", "離開梟獸形態後，下一次癒合法力消耗降低 450"), { balance_caster = true }, { balanced = 1, cap = 0, output = 0 }),
        SetBonus(4, Labels("Starfire deals 10% more damage to targets affected by Moonfire or Insect Swarm", "目标受到月火术或虫群影响时，星火术伤害提高 10%", "目標受到月火術或蟲群影響時，星火術傷害提高 10%"), { balance_caster = true }, { balanced = 3, cap = 2, output = 3 }),
    })
Tier5Set("nordrassil_harness", 641, "DRUID", Labels("Nordrassil Harness", "诺达希尔野性套装", "諾達希爾野性套裝"),
    { bear_tank = true, cat_dps = true }, { 30222, 30223, 30228, 30229, 30230 }, {
        SetBonus(2, Labels("Leaving Bear or Cat Form reduces the next Regrowth cast time by 2.0 sec", "离开熊或猎豹形态后，下一次愈合施法时间缩短 2.0 秒", "離開熊或獵豹形態後，下一次癒合施法時間縮短 2.0 秒"), { bear_tank = true, cat_dps = true }, { balanced = 1, mitigation = 1, threat = 1, cap = 0, output = 1 }),
        SetBonus(4, Labels("Shred deals 75 more damage and Lacerate deals 15 more damage per application", "撕碎额外造成 75 点伤害，割伤每层额外造成 15 点伤害", "撕碎額外造成 75 點傷害，割傷每層額外造成 15 點傷害"), { bear_tank = true, cat_dps = true }, { balanced = 3, mitigation = 1, threat = 3, cap = 2, output = 3 }),
    })
Tier5Set("nordrassil_raiment", 642, "DRUID", Labels("Nordrassil Raiment", "诺达希尔恢复套装", "諾達希爾恢復套裝"),
    { restoration_healer = true }, { 30216, 30217, 30219, 30220, 30221 }, {
        SetBonus(2, Labels("Increases Regrowth duration by 6 sec", "愈合持续时间延长 6 秒", "癒合持續時間延長 6 秒"), { restoration_healer = true }, { balanced = 2, throughput = 2, longevity = 2 }),
        SetBonus(4, Labels("Increases Lifebloom final healing by 150", "生命绽放最终治疗量提高 150", "生命之花最終治療量提高 150"), { restoration_healer = true }, { balanced = 3, throughput = 3, longevity = 1 }),
    })
Tier5Set("rift_stalker_armor", 652, "HUNTER", Labels("Rift Stalker Armor", "裂隙追猎者护甲", "裂隙追獵者護甲"),
    { beast_mastery = true, marksmanship_hunter = true, survival_hunter = true }, { 30139, 30140, 30141, 30142, 30143 }, {
        SetBonus(2, Labels("Heals the pet for 15% of damage dealt", "造成伤害的 15% 会治疗宠物", "造成傷害的 15% 會治療寵物"), { beast_mastery = true, marksmanship_hunter = true, survival_hunter = true }, { balanced = 2, cap = 0, output = 1 }),
        SetBonus(4, Labels("Steady Shot gains 5% critical strike chance", "稳固射击的暴击几率提高 5%", "穩固射擊的致命一擊機率提高 5%"), { beast_mastery = true, marksmanship_hunter = true, survival_hunter = true }, { balanced = 3, cap = 2, output = 3 }),
    })
Tier5Set("tirisfal_regalia", 649, "MAGE", Labels("Tirisfal Regalia", "提瑞斯法法衣", "提里斯法法衣"),
    { arcane_mage = true, fire_mage = true, frost_mage = true }, { 30196, 30205, 30206, 30207, 30210 }, {
        SetBonus(2, Labels("Arcane Blast damage and mana cost increase by 20%", "奥术冲击伤害和法力消耗提高 20%", "秘法衝擊傷害和法力消耗提高 20%"), { arcane_mage = true }, { balanced = 3, cap = 1, output = 3 }),
        SetBonus(4, Labels("Spell critical strikes grant up to 70 spell damage for 6 sec", "法术暴击后获得最多 70 点法术伤害，持续 6 秒", "法術致命一擊後獲得最多 70 點法術傷害，持續 6 秒"), { arcane_mage = true, fire_mage = true, frost_mage = true }, { balanced = 3, cap = 2, output = 3 }),
    })
Tier5Set("crystalforge_raiment", 627, "PALADIN", Labels("Crystalforge Raiment", "晶铸圣装", "晶鑄聖裝"),
    { holy_healer = true }, { 30134, 30135, 30136, 30137, 30138 }, {
        SetBonus(2, Labels("Judgements restore 50 mana to party members", "施放审判时为小队成员恢复 50 点法力", "施放審判時為小隊成員恢復 50 點法力"), { holy_healer = true }, { balanced = 2, flash_of_light = 1, holy_light = 2 }),
        SetBonus(4, Labels("Critical heals reduce the next Holy Light cast time by 0.50 sec for 10 sec; 1 min cooldown", "治疗暴击使下一次圣光术施法时间缩短 0.50 秒，效果持续 10 秒；冷却 1 分钟", "治療致命一擊使下一次聖光術施法時間縮短 0.50 秒，效果持續 10 秒；冷卻 1 分鐘"), { holy_healer = true }, { balanced = 3, flash_of_light = 1, holy_light = 3 }),
    })
Tier5Set("crystalforge_armor", 628, "PALADIN", Labels("Crystalforge Armor", "晶铸护甲", "晶鑄護甲"),
    { protection_tank = true }, { 30123, 30124, 30125, 30126, 30127 }, {
        SetBonus(2, Labels("Retribution Aura deals 15 additional damage", "惩罚光环额外造成 15 点伤害", "懲罰光環額外造成 15 點傷害"), { protection_tank = true }, { balanced = 1, mitigation = 0, threat = 2 }),
        SetBonus(4, Labels("Holy Shield grants 100 block value against one attack within 6 sec", "施放神圣之盾后，6 秒内下一次格挡获得 100 格挡值", "施放神聖之盾後，6 秒內下一次格擋獲得 100 格擋值"), { protection_tank = true }, { balanced = 2, mitigation = 3, threat = 1 }),
    })
Tier5Set("crystalforge_battlegear", 629, "PALADIN", Labels("Crystalforge Battlegear", "晶铸战甲", "晶鑄戰甲"),
    { retribution_dps = true }, { 30129, 30130, 30131, 30132, 30133 }, {
        SetBonus(2, Labels("Reduces Judgement mana cost by 35", "审判的法力消耗降低 35", "審判的法力消耗降低 35"), { retribution_dps = true }, { balanced = 2, cap = 1, output = 2 }),
        SetBonus(4, Labels("Judgements can heal nearby party members for 244 to 257", "审判有几率为附近小队成员恢复 244 至 257 点生命", "審判有機率為附近隊伍成員恢復 244 至 257 點生命"), { retribution_dps = true }, { balanced = 2, cap = 0, output = 1 }),
    })
Tier5Set("avatar_raiment", 665, "PRIEST", Labels("Avatar Raiment", "神使治疗套装", "神使治療套裝"),
    { discipline_priest = true, holy_priest = true }, { 30150, 30151, 30152, 30153, 30154 }, {
        SetBonus(2, Labels("Greater Heal restoring a target to full health returns 100 mana", "强效治疗术将目标生命值恢复满时返还 100 点法力", "強效治療術將目標生命值恢復滿時返還 100 點法力"), { discipline_priest = true, holy_priest = true }, { balanced = 2, throughput = 1, longevity = 3 }),
        SetBonus(4, Labels("Increases Renew duration by 3 sec", "恢复的持续时间延长 3 秒", "恢復的持續時間延長 3 秒"), { discipline_priest = true, holy_priest = true }, { balanced = 3, throughput = 2, longevity = 3 }),
    })
Tier5Set("avatar_regalia", 666, "PRIEST", Labels("Avatar Regalia", "神使暗影套装", "神使暗影套裝"),
    { shadow_dps = true }, { 30159, 30160, 30161, 30162, 30163 }, {
        SetBonus(2, Labels("Offensive spells can reduce the next spell's mana cost by 150", "攻击法术有几率使下一个法术的法力消耗降低 150", "攻擊法術有機率使下一個法術的法力消耗降低 150"), { shadow_dps = true }, { balanced = 3, cap = 1, output = 2 }),
        SetBonus(4, Labels("Shadow Word: Pain ticks can grant the next spell within 15 sec up to 100 spell damage and healing", "暗言术：痛的周期伤害有几率使 15 秒内施放的下一个法术获得最多 100 点法术伤害和治疗", "暗言術：痛的週期傷害有機率使 15 秒內施放的下一個法術獲得最多 100 點法術傷害和治療"), { shadow_dps = true }, { balanced = 3, cap = 2, output = 3 }),
    })
Tier5Set("deathmantle", 622, "ROGUE", Labels("Deathmantle", "死亡阴影套装", "死亡陰影套裝"),
    { assassination_rogue = true, combat_rogue = true, subtlety_rogue = true }, { 30144, 30145, 30146, 30148, 30149 }, {
        SetBonus(2, Labels("Eviscerate and Envenom deal 40 additional damage per combo point", "刺骨和毒伤每个连击点数额外造成 40 点伤害", "剔骨和毒化每個連擊點數額外造成 40 點傷害"), { assassination_rogue = true, combat_rogue = true, subtlety_rogue = true }, { balanced = 3, cap = 1, output = 3 }),
        SetBonus(4, Labels("Attacks can make the next finishing move cost no energy", "攻击有几率使下一个终结技不消耗能量", "攻擊有機率使下一個終結技不消耗能量"), { assassination_rogue = true, combat_rogue = true, subtlety_rogue = true }, { balanced = 3, cap = 2, output = 3 }),
    })
Tier5Set("cataclysm_regalia", 635, "SHAMAN", Labels("Cataclysm Regalia", "灾难元素套装", "災難元素套裝"),
    { elemental_dps = true }, { 30169, 30170, 30171, 30172, 30173 }, {
        SetBonus(2, Labels("Offensive spells can reduce the next Lesser Healing Wave mana cost by 380", "攻击法术有几率使下一次次级治疗波的法力消耗降低 380", "攻擊法術有機率使下一次次級治療波的法力消耗降低 380"), { elemental_dps = true }, { balanced = 1, cap = 0, output = 0 }),
        SetBonus(4, Labels("Lightning Bolt critical strikes can restore 120 mana", "闪电箭暴击有几率恢复 120 点法力", "閃電箭致命一擊有機率恢復 120 點法力"), { elemental_dps = true }, { balanced = 3, cap = 2, output = 3 }),
    })
Tier5Set("cataclysm_harness", 636, "SHAMAN", Labels("Cataclysm Harness", "灾难增强套装", "災難增強套裝"),
    { enhancement_dps = true }, { 30185, 30189, 30190, 30192, 30194 }, {
        SetBonus(2, Labels("Melee attacks can reduce the next Lesser Healing Wave cast time by 1.5 sec", "近战攻击有几率使下一次次级治疗波施法时间缩短 1.5 秒", "近戰攻擊有機率使下一次次級治療波施法時間縮短 1.5 秒"), { enhancement_dps = true }, { balanced = 1, cap = 0, output = 0 }),
        SetBonus(4, Labels("Flurry grants 5% additional haste", "乱舞额外提供 5% 急速", "亂舞額外提供 5% 加速"), { enhancement_dps = true }, { balanced = 3, cap = 2, output = 3 }),
    })
Tier5Set("cataclysm_raiment", 634, "SHAMAN", Labels("Cataclysm Raiment", "灾难恢复套装", "災難恢復套裝"),
    { restoration_healer = true }, { 30164, 30165, 30166, 30167, 30168 }, {
        SetBonus(2, Labels("Reduces Lesser Healing Wave mana cost by 5%", "次级治疗波的法力消耗降低 5%", "次級治療波的法力消耗降低 5%"), { restoration_healer = true }, { balanced = 2, throughput = 1, longevity = 3 }),
        SetBonus(4, Labels("Critical heals reduce the next Healing Wave cast time by 0.50 sec for 10 sec; 1 min cooldown", "治疗暴击使下一次治疗波施法时间缩短 0.50 秒，效果持续 10 秒；冷却 1 分钟", "治療致命一擊使下一次治療波施法時間縮短 0.50 秒，效果持續 10 秒；冷卻 1 分鐘"), { restoration_healer = true }, { balanced = 3, throughput = 3, longevity = 2 }),
    })
Tier5Set("corruptor_raiment", 646, "WARLOCK", Labels("Corruptor Raiment", "腐蚀者套装", "腐化者套裝"),
    { affliction_warlock = true, demonology_warlock = true, destruction_warlock = true }, { 30211, 30212, 30213, 30214, 30215 }, {
        SetBonus(2, Labels("Heals the pet for 15% of damage dealt", "造成伤害的 15% 会治疗宠物", "造成傷害的 15% 會治療寵物"), { affliction_warlock = true, demonology_warlock = true, destruction_warlock = true }, { balanced = 2, cap = 0, output = 1 }),
        SetBonus(4, Labels("Shadow Bolt boosts Corruption and Incinerate boosts Immolate damage by 10%", "暗影箭使腐蚀术伤害提高 10%，烧尽使献祭伤害提高 10%", "暗影箭使腐蝕術傷害提高 10%，燒盡使獻祭傷害提高 10%"), { affliction_warlock = true, demonology_warlock = true, destruction_warlock = true }, { balanced = 3, cap = 2, output = 3 }),
    })
Tier5Set("destroyer_battlegear", 657, "WARRIOR", Labels("Destroyer Battlegear", "毁灭者战甲", "毀滅者戰甲"),
    { arms_warrior = true, fury_warrior = true }, { 30118, 30119, 30120, 30121, 30122 }, {
        SetBonus(2, Labels("Overpower grants 100 attack power for 5 sec", "压制使你获得 100 攻击强度，持续 5 秒", "壓制使你獲得 100 攻擊強度，持續 5 秒"), { arms_warrior = true, fury_warrior = true }, { balanced = 2, cap = 1, output = 3 }),
        SetBonus(4, Labels("Bloodthirst and Mortal Strike cost 5 less rage", "嗜血和致死打击少消耗 5 点怒气", "嗜血和致死打擊少消耗 5 點怒氣"), { arms_warrior = true, fury_warrior = true }, { balanced = 3, cap = 2, output = 3 }),
    })
Tier5Set("destroyer_armor", 656, "WARRIOR", Labels("Destroyer Armor", "毁灭者护甲", "毀滅者護甲"),
    { warrior_protection = true }, { 30113, 30114, 30115, 30116, 30117 }, {
        SetBonus(2, Labels("Shield Block grants 100 block value against one attack within 6 sec", "施放盾牌格挡后，6 秒内下一次格挡获得 100 格挡值", "施放盾牌格擋後，6 秒內下一次格擋獲得 100 格擋值"), { warrior_protection = true }, { balanced = 2, mitigation = 3, threat = 1 }),
        SetBonus(4, Labels("Being hit can grant 200 haste rating for 10 sec", "受到攻击时有几率获得 200 急速等级，持续 10 秒", "受到攻擊時有機率獲得 200 加速等級，持續 10 秒"), { warrior_protection = true }, { balanced = 2, mitigation = 1, threat = 3 }),
    })

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
Preset("paladin_holy_mixed_p2", "Holy Paladin P2 Mixed Healing", "holy_healer", "balanced", { 30136, 30018, 30138, 29989, 30134, 30047, 30135, 30030, 29991, 30027, 30110, 28790, 29376, 28727, 30108, 29923, 28592 }, "https://www.wowhead.com/tbc/guide/classes/paladin/holy/healer-bis-gear-pve-phase-2", "Guide route adjusted to preserve the source-backed Crystalforge Raiment 4-piece threshold.", "wowhead")
Preset("paladin_holy_flash_p2", "Holy Paladin P2 Flash of Light", "holy_healer", "flash_of_light", { 30136, 30018, 30138, 29989, 30134, 30047, 30135, 30030, 29991, 30027, 30110, 28790, 29376, 28727, 30108, 29923, 25644 }, "https://www.wowhead.com/tbc/guide/classes/paladin/holy/healer-bis-gear-pve-phase-2", "Flash of Light route uses the spell-specific Blessed Book of Nagrand and preserves Crystalforge Raiment 4-piece.", "wowhead")
Preset("paladin_holy_light_p2", "Holy Paladin P2 Holy Light", "holy_healer", "holy_light", { 30136, 30018, 30138, 29989, 30134, 30047, 30135, 30030, 29991, 30027, 30110, 28790, 29376, 28727, 30108, 29923, 30063 }, "https://www.wowhead.com/tbc/item=30063/libram-of-absolute-truth", "Holy Light route uses the mana-reduction libram and preserves Crystalforge Raiment 4-piece.", "wowhead")
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
    Role({ key = "balance_caster", talentRuleKey = "balance_caster", label = "Balance Druid", labels = Labels("Balance Druid", "平衡德鲁伊", "平衡德魯伊"), talentTabs = { 1 }, archetype = "caster", models = { "caster_dps", "mana_longevity" }, priorities = { "spell hit to adjusted cap", "Tier 5 set threshold", "spell damage", "spell crit", "haste", "intellect" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellPower, S.spellHit, S.spellCrit, S.spellHaste, S.intellect, S.spirit }, baseWeights = BALANCE_P2_EP_WEIGHTS, scoreModel = ScoreModel("phase_ep", "ui/druid/balance/presets.ts", 2, "Balance"), caps = SPELL_CAPS, modes = DpsModes({ S.spellPower }), setGoal = "Nordrassil Regalia 4-piece", talentString = "510022312503135231351--520033", presets = { "balance_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/druid/balance/dps-bis-gear-pve-phase-2" }),
    Role({ key = "bear_tank", talentRuleKey = "bear_tank", label = "Feral Bear Tank", labels = Labels("Feral Bear Tank", "野性熊坦", "野性熊坦"), talentTabs = { 2 }, archetype = "tank", models = { "tank_mitigation", "tank_threat" }, priorities = { "combined crit immunity", "armor and effective health", "stamina", "agility/dodge", "expertise", "hit", "feral attack power and threat" }, benchmarkKeys = { "crit_immunity", "melee_special_hit", "expertise_dodge" }, statTokens = { S.stamina, S.armor, S.bonusArmor, S.agility, S.dodge, S.resilience, S.defense, S.expertise, S.hit, S.feralAttackPower, S.strength, S.crit }, caps = { TANK_CAPS[1], MELEE_CAPS[1], MELEE_CAPS[2] }, modes = TankModes({ [S.feralAttackPower] = 1.25, [S.agility] = 1.12, [S.strength] = 1.20, [S.crit] = 1.12 }), setGoal = "Choose Survival, Balanced, Offensive, Warden, or Hydross resistance set per encounter", talentString = "-503032132322105301251-05503301", presets = { "bear_balanced", "bear_survival", "bear_offensive", "bear_warden", "bear_hydross_frost", "bear_hydross_nature" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/druid/feral/tank-bis-gear-pve-phase-2" }),
    Role({ key = "cat_dps", talentRuleKey = "cat_dps", label = "Feral Cat DPS", labels = Labels("Feral Cat DPS", "野性猎豹输出", "野性獵豹輸出"), talentTabs = { 2 }, archetype = "melee", models = { "melee_dps", "weapon_selection" }, priorities = { "6% or 9% hit route", "Tier 4 2-piece versus T5 off-pieces", "agility", "strength", "feral attack power", "crit", "expertise" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.agility, S.strength, S.feralAttackPower, S.attackPower, S.hit, S.expertise, S.crit }, caps = MELEE_CAPS, modes = DpsModes({ S.agility, S.feralAttackPower }), setGoal = "Compare Tier 4 2-piece finisher route against T5 alternatives", talentString = "-503032132322105301251-05503301", presets = { "cat_6_hit", "cat_9_hit", "cat_alt_6_hit", "cat_alt_9_hit" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/druid/feral/dps-bis-gear-pve-phase-2" }),
    Role({ key = "restoration_healer", talentRuleKey = "restoration_healer", label = "Restoration Druid", labels = Labels("Restoration Druid", "恢复德鲁伊", "恢復德魯伊"), talentTabs = { 3 }, archetype = "healer", models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "spirit", "mp5", "intellect", "haste", "Lifebloom idol" }, benchmarkKeys = {}, statTokens = { S.healing, S.spirit, S.mp5, S.intellect, S.spellHaste }, caps = {}, modes = HealerModes(), setGoal = "Nordrassil Raiment and encounter-length mana set", talentString = "05320031103--230023312131502331050313051", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/druid/healer-bis-gear-pve-phase-2", evidence = "guide" }),
} }

DB.classes.WARRIOR = { roles = {
    Role({ key = "arms_warrior", talentRuleKey = "arms_fury_dps", label = "Arms Warrior", labels = Labels("Arms Warrior", "武器战士", "武器戰士"), talentTabs = { 1 }, archetype = "melee", models = { "melee_dps", "raid_debuff" }, priorities = { "weapon damage", "hit", "expertise", "strength", "attack power", "crit", "haste" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.strength, S.attackPower, S.crit, S.meleeHaste }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.strength }), setGoal = "Destroyer Battlegear and Blood Frenzy raid utility", talentString = "3400502130201-05050005505012050115", presets = { "warrior_arms_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/warrior/arms/dps-bis-gear-pve-phase-2" }),
    Role({ key = "fury_warrior", talentRuleKey = "arms_fury_dps", label = "Fury Warrior", labels = Labels("Fury Warrior", "狂怒战士", "狂怒戰士"), talentTabs = { 2 }, archetype = "melee", models = { "melee_dps", "weapon_selection" }, priorities = { "main/off-hand weapon damage", "hit plan", "expertise", "strength", "attack power", "crit", "haste" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.strength, S.attackPower, S.crit, S.meleeHaste }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.strength }), setGoal = "Destroyer Battlegear with optimized dual-wield hit budget", talentString = "32005011352010500221-0550000500521203", presets = { "warrior_fury_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/warrior/fury/dps-bis-gear-pve-phase-2" }),
    Role({ key = "warrior_protection", talentRuleKey = "protection_tank", label = "Protection Warrior", labels = Labels("Protection Warrior", "防护战士", "防護戰士"), talentTabs = { 3 }, archetype = "tank", models = { "tank_mitigation", "tank_threat" }, priorities = { "crit immunity", "102.4 combat table when required", "effective health", "expertise", "hit", "block value", "weapon threat" }, benchmarkKeys = { "crit_immunity", "avoidance_table", "melee_special_hit", "expertise_dodge" }, statTokens = { S.stamina, S.armor, S.defense, S.resilience, S.dodge, S.parry, S.block, S.blockValue, S.expertise, S.hit, S.weaponDps }, caps = { TANK_CAPS[1], TANK_CAPS[2], MELEE_CAPS[1], MELEE_CAPS[2] }, modes = TankModes({ [S.weaponDps] = 1.25, [S.blockValue] = 1.15 }), setGoal = "Destroyer Armor with a separate Hydross resistance set", talentString = "35000301302-03-0055511033001101501351", presets = { "warrior_protection_p2", "warrior_hydross_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/warrior/protection/tank-bis-gear-pve-phase-2" }),
} }

DB.classes.PALADIN = { roles = {
    Role({ key = "holy_healer", talentRuleKey = "holy_healer", label = "Holy Paladin", labels = Labels("Holy Paladin", "神圣圣骑士", "神聖聖騎士"), talentTabs = { 1 }, archetype = "healer", models = { "healing_throughput", "mana_longevity", "spell_cycle", "set_thresholds" }, priorities = { "bonus healing", "intellect", "spell crit", "mp5", "haste", "spell cycle efficiency" }, benchmarkKeys = {}, statTokens = { S.healing, S.intellect, S.spellCrit, S.mp5, S.spellHaste }, caps = {}, modes = HolyPaladinModes(), setGoal = "Preserve Crystalforge Raiment 4-piece unless the full replacement route is validated; choose the libram by healing spell cycle", presets = { "paladin_holy_mixed_p2", "paladin_holy_flash_p2", "paladin_holy_light_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/paladin/holy/healer-bis-gear-pve-phase-2", evidence = "guide" }),
    Role({ key = "protection_tank", talentRuleKey = "protection_tank", label = "Protection Paladin", labels = Labels("Protection Paladin", "防护圣骑士", "防護聖騎士"), talentTabs = { 2 }, archetype = "tank", models = { "tank_mitigation", "spell_threat" }, priorities = { "crit immunity", "102.4 combat table", "stamina", "spell power", "defense/avoidance", "spell hit", "mana sustain" }, benchmarkKeys = { "crit_immunity", "avoidance_table", "spell_hit" }, statTokens = { S.stamina, S.defense, S.resilience, S.armor, S.dodge, S.parry, S.block, S.blockValue, S.spellPower, S.spellHit, S.intellect, S.mp5 }, caps = { TANK_CAPS[1], TANK_CAPS[2], SPELL_CAPS[1] }, modes = TankModes({ [S.spellPower] = 1.32, [S.spellHit] = 1.30, [S.intellect] = 1.10 }), setGoal = "Keep Justicar Armor 2-piece for single-target threat; do not force weak Crystalforge bonuses", talentString = "-0530513050000142521051-052050003003", presets = { "paladin_protection_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/paladin/tank-bis-gear-pve-phase-2" }),
    Role({ key = "retribution_dps", talentRuleKey = "retribution_dps", label = "Retribution Paladin", labels = Labels("Retribution Paladin", "惩戒圣骑士", "懲戒聖騎士"), talentTabs = { 3 }, archetype = "melee", models = { "melee_dps", "utility_dps" }, priorities = { "weapon damage", "hit", "expertise", "strength", "crit", "haste", "seal twisting" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.strength, S.attackPower, S.crit, S.meleeHaste }, baseWeights = RETRIBUTION_P2_EP_WEIGHTS, scoreModel = ScoreModel("phase_ep", "ui/paladin/retribution/presets.ts", 2, "Retribution"), caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.strength }), setGoal = "Crystalforge Battlegear and weapon-first upgrade path", talentString = "5-053201-0523005120033125331051", presets = { "paladin_retribution_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/paladin/retribution/dps-bis-gear-pve-phase-2" }),
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
    Role({ key = "beast_mastery", talentRuleKey = "ranged_dps", label = "Beast Mastery Hunter", labels = Labels("Beast Mastery Hunter", "野兽控制猎人", "野獸控制獵人"), talentTabs = { 1 }, archetype = "ranged", models = { "ranged_dps", "pet_synergy" }, priorities = { "6% or 9% hit route", "ranged weapon DPS", "agility", "attack power", "crit", "haste", "pet scaling" }, benchmarkKeys = { "ranged_hit" }, statTokens = { S.weaponDps, S.rangedHit, S.agility, S.rangedAttackPower, S.attackPower, S.rangedCrit, S.rangedHaste }, baseWeights = HUNTER_EP_WEIGHTS, scoreModel = HUNTER_SHARED_P1_MODEL, caps = RANGED_CAPS, modes = DpsModes({ S.weaponDps, S.agility, S.rangedAttackPower }), setGoal = "Rift Stalker Armor and 2H/DW route selected around party hit", talentString = "522002005150122431051-0505201205", presets = { "hunter_bm_dw_6", "hunter_bm_dw_9", "hunter_bm_2h_6", "hunter_bm_2h_9" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/hunter/beast-mastery/dps-bis-gear-pve-phase-2" }),
    Role({ key = "marksmanship_hunter", talentRuleKey = "ranged_dps", label = "Marksmanship Hunter", labels = Labels("Marksmanship Hunter", "射击猎人", "射擊獵人"), talentTabs = { 2 }, archetype = "ranged", models = { "ranged_dps", "raid_support" }, priorities = { "ranged hit", "ranged weapon DPS", "agility", "attack power", "crit", "haste", "Trueshot Aura" }, benchmarkKeys = { "ranged_hit" }, statTokens = { S.rangedHit, S.weaponDps, S.agility, S.rangedAttackPower, S.attackPower, S.rangedCrit, S.rangedHaste }, baseWeights = HUNTER_EP_WEIGHTS, scoreModel = HUNTER_SHARED_P1_MODEL, caps = RANGED_CAPS, modes = DpsModes({ S.weaponDps, S.agility, S.rangedAttackPower }), setGoal = "Rift Stalker Armor with raid-support-aware off-pieces", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/hunter/marksmanship/dps-bis-gear-pve-phase-2", evidence = "guide" }),
    Role({ key = "survival_hunter", talentRuleKey = "ranged_dps", label = "Survival Hunter", labels = Labels("Survival Hunter", "生存猎人", "生存獵人"), talentTabs = { 3 }, archetype = "ranged", models = { "ranged_dps", "raid_support" }, priorities = { "6% or 9% hit route", "agility for Expose Weakness", "ranged weapon DPS", "crit", "attack power", "haste" }, benchmarkKeys = { "ranged_hit" }, statTokens = { S.rangedHit, S.agility, S.weaponDps, S.rangedCrit, S.rangedAttackPower, S.attackPower, S.rangedHaste }, baseWeights = HUNTER_EP_WEIGHTS, scoreModel = HUNTER_SHARED_P1_MODEL, caps = RANGED_CAPS, modes = DpsModes({ S.agility, S.weaponDps }), setGoal = "Rift Stalker pieces with maximum sustainable Expose Weakness agility", talentString = "502-0550201205-333200022003223005103", presets = { "hunter_sv_dw_6", "hunter_sv_2h_6" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/hunter/survival/dps-bis-gear-pve-phase-2" }),
} }

DB.classes.ROGUE = { roles = {
    Role({ key = "assassination_rogue", talentRuleKey = "melee_dps", label = "Assassination Rogue", labels = Labels("Assassination Rogue", "刺杀潜行者", "刺殺盜賊"), talentTabs = { 1 }, archetype = "melee", models = { "melee_dps", "weapon_selection" }, priorities = { "weapon speed/poison plan", "special hit", "expertise", "agility", "attack power", "crit", "haste" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.agility, S.attackPower, S.crit, S.meleeHaste }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.agility }), setGoal = "Deathmantle pieces only when the build and poison plan support them", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2", evidence = "guide" }),
    Role({ key = "combat_rogue", talentRuleKey = "melee_dps", label = "Combat Rogue", labels = Labels("Combat Rogue", "战斗潜行者", "戰鬥盜賊"), talentTabs = { 2 }, archetype = "melee", models = { "melee_dps", "weapon_selection" }, priorities = { "main/off-hand weapon plan", "special and poison hit", "expertise", "agility", "attack power", "haste", "crit" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.weaponDps, S.hit, S.expertise, S.agility, S.attackPower, S.meleeHaste, S.crit }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.agility }), setGoal = "Deathmantle Armor with weapon-specialization-matched upgrades", talentString = "0053201252-023305200005015002321151", presets = { "rogue_combat_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2" }),
    Role({ key = "subtlety_rogue", talentRuleKey = "melee_dps", label = "Subtlety Rogue", labels = Labels("Subtlety Rogue", "敏锐潜行者", "敏銳盜賊"), talentTabs = { 3 }, archetype = "melee", models = { "melee_dps", "utility_dps" }, priorities = { "special hit", "weapon damage", "expertise", "agility", "attack power", "crit", "utility" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { S.hit, S.weaponDps, S.expertise, S.agility, S.attackPower, S.crit }, caps = MELEE_CAPS, modes = DpsModes({ S.weaponDps, S.agility }), setGoal = "Use Combat P2 pieces only as a starting point; validate the utility build separately", presets = {}, guideUrl = "https://www.wowhead.com/tbc/guide/classes/rogue/dps-bis-gear-pve-phase-2", evidence = "guide" }),
} }

DB.classes.MAGE = { roles = {
    Role({ key = "arcane_mage", talentRuleKey = "caster_dps", label = "Arcane Mage", labels = Labels("Arcane Mage", "奥术法师", "奧術法師"), talentTabs = { 1 }, archetype = "caster", models = { "caster_dps", "mana_longevity" }, priorities = { "arcane hit after Arcane Focus", "Tier 5 set", "intellect", "spell power", "spirit", "crit", "haste" }, benchmarkKeys = { "spell_hit" }, statTokens = { S.spellHit, S.intellect, S.spellPower, S.spirit, S.spellCrit, S.spellHaste, S.mp5 }, baseWeights = ARCANE_P2_EP_WEIGHTS, scoreModel = ScoreModel("phase_ep", "ui/mage/dps/presets.ts", 2, "Arcane"), caps = { Cap("spell_hit", 6, "%", "talent_cap", Labels("Arcane hit after talents", "天赋后奥术命中", "天賦後奧術命中"), "Assumes 5/5 Arcane Focus; subtract reliable Misery when present.") }, modes = DpsModes({ S.intellect, S.spellPower }), setGoal = "Tirisfal Regalia and Serpent-Coil Braid mana-cycle route", talentString = "2500052300030150330125--053500031003001", presets = { "mage_arcane_p2" }, guideUrl = "https://www.wowhead.com/tbc/guide/classes/mage/arcane/dps-bis-gear-pve-phase-2" }),
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
    ["PALADIN.holy_healer"] = Labels("Preserve Crystalforge Raiment 4-piece unless the full replacement route is validated; choose the libram by healing spell cycle", "除非已验证整套替换路线，否则保留晶铸圣装 4 件套；圣契按治疗循环选择", "除非已驗證整套替換路線，否則保留晶鑄聖裝 4 件套；聖契按治療循環選擇"),
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
        role.classToken = classToken
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

function DB.GetItemEffect(itemID)
    return DB.itemEffects[tonumber(itemID)]
end

function DB.GetSet(key)
    return DB.sets[key]
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

function DB.Validate()
    local issues = {}
    local summary = {
        classes = 0,
        roles = 0,
        phaseEp = 0,
        crossPhaseEp = 0,
        orderedHeuristic = 0,
        simulatorRoutes = 0,
        guideRoutes = 0,
        definitiveModels = 0,
        itemEffects = 0,
        sets = 0,
        tier5Sets = 0,
        tier5Roles = 0,
    }
    local tier5RoleCoverage = {}
    local tier5ItemOwners = {}

    for classToken, class in pairs(DB.classes) do
        summary.classes = summary.classes + 1
        for index = 1, #(class.roles or {}) do
            local role = class.roles[index]
            local model = role.scoreModel
            summary.roles = summary.roles + 1
            if not model or not model.kind then
                issues[#issues + 1] = classToken .. "." .. tostring(role.key) .. ": missing score model contract"
            else
                if model.kind == "phase_ep" then
                    summary.phaseEp = summary.phaseEp + 1
                elseif model.kind == "cross_phase_shared_ep" then
                    summary.crossPhaseEp = summary.crossPhaseEp + 1
                elseif model.kind == "ordered_stat_heuristic" then
                    summary.orderedHeuristic = summary.orderedHeuristic + 1
                else
                    issues[#issues + 1] = classToken .. "." .. tostring(role.key) .. ": unknown score model " .. tostring(model.kind)
                end
                if model.kind ~= "ordered_stat_heuristic" and not next(role.baseWeights or {}) then
                    issues[#issues + 1] = classToken .. "." .. tostring(role.key) .. ": sourced score model has no explicit weights"
                end
                if model.supportsDefinitiveVerdicts then
                    summary.definitiveModels = summary.definitiveModels + 1
                end
            end

            if role.routeEvidence == "simulator_preset" then
                summary.simulatorRoutes = summary.simulatorRoutes + 1
                if #(role.presets or {}) == 0 then
                    issues[#issues + 1] = classToken .. "." .. tostring(role.key) .. ": simulator route has no preset"
                end
            elseif role.routeEvidence == "guide" then
                summary.guideRoutes = summary.guideRoutes + 1
            else
                issues[#issues + 1] = classToken .. "." .. tostring(role.key) .. ": unknown route evidence " .. tostring(role.routeEvidence)
            end
        end
    end


    for itemID, effect in pairs(DB.itemEffects) do
        summary.itemEffects = summary.itemEffects + 1
        if tonumber(itemID) ~= tonumber(effect.itemID) or not effect.key or not effect.kind or not effect.labels then
            issues[#issues + 1] = "invalid item effect " .. tostring(itemID)
        end
    end

    for key, set in pairs(DB.sets) do
        summary.sets = summary.sets + 1
        if set.key ~= key or #(set.itemIDs or {}) == 0 or #(set.bonuses or {}) == 0 then
            issues[#issues + 1] = "invalid set definition " .. tostring(key)
        end
        if set.tier == 5 then
            summary.tier5Sets = summary.tier5Sets + 1
            if not set.setID or #(set.itemIDs or {}) ~= 5 or #(set.bonuses or {}) ~= 2 then
                issues[#issues + 1] = tostring(key) .. ": Tier 5 sets require a set ID, five items, and two bonuses"
            end
            if not set.labels or not set.labels.enUS or not set.labels.zhCN or not set.labels.zhTW then
                issues[#issues + 1] = tostring(key) .. ": missing localized Tier 5 labels"
            end
            if not next(set.classTokens or {}) or not next(set.roleKeys or {}) then
                issues[#issues + 1] = tostring(key) .. ": missing class or role ownership"
            end

            local bonusPieces = {}
            for bonusIndex = 1, #(set.bonuses or {}) do
                local bonus = set.bonuses[bonusIndex]
                bonusPieces[bonus.pieces] = true
                if not bonus.labels or not bonus.labels.enUS or not bonus.labels.zhCN or not bonus.labels.zhTW then
                    issues[#issues + 1] = tostring(key) .. ": missing localized " .. tostring(bonus.pieces) .. "-piece bonus"
                end
            end
            if not bonusPieces[2] or not bonusPieces[4] then
                issues[#issues + 1] = tostring(key) .. ": Tier 5 bonuses must use the 2-piece and 4-piece thresholds"
            end

            for itemIndex = 1, #(set.itemIDs or {}) do
                local itemID = tonumber(set.itemIDs[itemIndex])
                if not itemID then
                    issues[#issues + 1] = tostring(key) .. ": invalid item ID"
                elseif tier5ItemOwners[itemID] then
                    issues[#issues + 1] = tostring(key) .. ": item " .. tostring(itemID) .. " already belongs to " .. tier5ItemOwners[itemID]
                else
                    tier5ItemOwners[itemID] = key
                end
            end

            for classToken in pairs(set.classTokens or {}) do
                if not DB.classes[classToken] then
                    issues[#issues + 1] = tostring(key) .. ": unknown class " .. tostring(classToken)
                end
                for roleKey in pairs(set.roleKeys or {}) do
                    if DB.GetRole(classToken, roleKey) then
                        tier5RoleCoverage[classToken .. "." .. roleKey] = true
                    else
                        issues[#issues + 1] = tostring(key) .. ": role " .. tostring(roleKey) .. " does not belong to " .. tostring(classToken)
                    end
                end
            end
        end
    end

    for classToken, class in pairs(DB.classes) do
        for index = 1, #(class.roles or {}) do
            local roleKey = class.roles[index].key
            if tier5RoleCoverage[classToken .. "." .. roleKey] then
                summary.tier5Roles = summary.tier5Roles + 1
            else
                issues[#issues + 1] = classToken .. "." .. tostring(roleKey) .. ": no Tier 5 set coverage"
            end
        end
    end

    if summary.classes ~= 9 then
        issues[#issues + 1] = "expected 9 classes, found " .. tostring(summary.classes)
    end
    if summary.roles ~= 28 then
        issues[#issues + 1] = "expected 28 roles, found " .. tostring(summary.roles)
    end
    if summary.tier5Sets ~= 17 then
        issues[#issues + 1] = "expected 17 Tier 5 sets, found " .. tostring(summary.tier5Sets)
    end
    if summary.tier5Roles ~= 28 then
        issues[#issues + 1] = "expected Tier 5 coverage for 28 roles, found " .. tostring(summary.tier5Roles)
    end
    return #issues == 0, issues, summary
end

_G.TBCGearExporterP2DB = DB
