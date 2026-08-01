local addonName = ...

local Addon = {}
local frame = CreateFrame("Frame")

local DB_NAME = "TBCGearExporterDB"
local BANK_CONTAINER_ID = BANK_CONTAINER or -1
local PLAYER_BAG_SLOTS = NUM_BAG_SLOTS or 4
local BANK_BAG_SLOTS = NUM_BANKBAGSLOTS or 7
local MINIMAP_ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Bag_10_Blue"
local WOWHEAD_TBC_ITEM_URL_PREFIX = "https://www.wowhead.com/tbc/item="

local ClientLocale
local PromptLocale

local GEAR_ENGINE = {}
local P2_STRATEGY_DB = _G.TBCGearExporterP2DB or { classes = {}, presets = {}, sources = {}, slotOrder = {} }

GEAR_ENGINE.EQUIPMENT_SLOTS = {
    { id = 1, key = "HEAD" },
    { id = 2, key = "NECK" },
    { id = 3, key = "SHOULDER" },
    { id = 4, key = "SHIRT" },
    { id = 5, key = "CHEST" },
    { id = 6, key = "WAIST" },
    { id = 7, key = "LEGS" },
    { id = 8, key = "FEET" },
    { id = 9, key = "WRIST" },
    { id = 10, key = "HANDS" },
    { id = 11, key = "FINGER" },
    { id = 12, key = "FINGER" },
    { id = 13, key = "TRINKET" },
    { id = 14, key = "TRINKET" },
    { id = 15, key = "BACK" },
    { id = 16, key = "MAINHAND" },
    { id = 17, key = "OFFHAND" },
    { id = 18, key = "RANGED" },
    { id = 19, key = "TABARD" },
}

GEAR_ENGINE.EQUIP_SLOT_KEYS = {
    INVTYPE_HEAD = "HEAD",
    INVTYPE_NECK = "NECK",
    INVTYPE_SHOULDER = "SHOULDER",
    INVTYPE_BODY = "SHIRT",
    INVTYPE_CHEST = "CHEST",
    INVTYPE_ROBE = "CHEST",
    INVTYPE_WAIST = "WAIST",
    INVTYPE_LEGS = "LEGS",
    INVTYPE_FEET = "FEET",
    INVTYPE_WRIST = "WRIST",
    INVTYPE_HAND = "HANDS",
    INVTYPE_FINGER = "FINGER",
    INVTYPE_TRINKET = "TRINKET",
    INVTYPE_CLOAK = "BACK",
    INVTYPE_WEAPON = "MAINHAND",
    INVTYPE_WEAPONMAINHAND = "MAINHAND",
    INVTYPE_2HWEAPON = "MAINHAND",
    INVTYPE_WEAPONOFFHAND = "OFFHAND",
    INVTYPE_SHIELD = "OFFHAND",
    INVTYPE_HOLDABLE = "OFFHAND",
    INVTYPE_RANGED = "RANGED",
    INVTYPE_RANGEDRIGHT = "RANGED",
    INVTYPE_THROWN = "RANGED",
    INVTYPE_RELIC = "RANGED",
    INVTYPE_TABARD = "TABARD",
}

local CLASS_CATEGORY = {
    [0] = "Consumables",
    [1] = "Containers",
    [2] = "Gear",
    [3] = "Gems",
    [4] = "Gear",
    [5] = "Reagents",
    [6] = "Projectiles",
    [7] = "Trade Goods",
    [8] = "Enhancements",
    [9] = "Recipes",
    [10] = "Currency",
    [11] = "Containers",
    [12] = "Quest Items",
    [13] = "Keys",
    [14] = "Permanent",
    [15] = "Miscellaneous",
}

local CATEGORY_ORDER = {
    "Gear",
    "Consumables",
    "Trade Goods",
    "Gems",
    "Enhancements",
    "Recipes",
    "Reagents",
    "Quest Items",
    "Containers",
    "Keys",
    "Projectiles",
    "Currency",
    "Permanent",
    "Miscellaneous",
    "Other",
}

local QUALITY_LABELS = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Artifact",
    [7] = "Heirloom",
}

local QUALITY_COLOR_HEX = {
    [0] = "9D9D9D",
    [1] = "FFFFFF",
    [2] = "1EFF00",
    [3] = "0070DD",
    [4] = "A335EE",
    [5] = "FF8000",
    [6] = "E6CC80",
    [7] = "00CCFF",
}

local QUALITY_ALIASES = {
    poor = 0,
    gray = 0,
    grey = 0,
    common = 1,
    white = 1,
    uncommon = 2,
    green = 2,
    rare = 3,
    blue = 3,
    epic = 4,
    purple = 4,
    legendary = 5,
    orange = 5,
    artifact = 6,
    heirloom = 7,
}

local EXPORT_FILTER_IGNORE_TOKENS = {
    filter = true,
    filters = true,
    only = true,
    quality = true,
    q = true,
}

local EXPORT_FORMAT_ALIASES = {
    ai = true,
    chatgpt = true,
    gpt = true,
    json = true,
    raw = true,
    markdown = true,
    md = true,
    text = true,
    txt = true,
    plain = true,
}

local EXPORT_SCOPE_ALIASES = {
    all = "all",
    bags = "bags",
    bag = "bags",
    inventory = "bags",
    bank = "bank",
    gear = "gear",
    gears = "gear",
    equipment = "gear",
    equip = "gear",
}

local CLASS_ROLE_CONTEXT = {
    DRUID = {
        "Bear Feral tank: evaluate armor, stamina, defense/resilience, dodge/agility, threat stats, hit/expertise where present, feral attack power weapons, tank trinkets, and mitigation versus threat tradeoffs.",
        "Cat Feral DPS: evaluate agility, strength, attack power, crit, hit/expertise where present, weapon feral attack power, set synergy, and whether pieces conflict with bear mitigation needs.",
        "Restoration healing: evaluate bonus healing, spirit, intellect, mp5, haste where present, mana longevity, plus healing weapon/offhand/ring/trinket options.",
        "Balance caster: evaluate spell damage, spell hit, spell crit, haste where present, intellect, mana sustain, and whether caster pieces are better reserved for healing or damage sets.",
    },
    WARRIOR = {
        "Protection tank: evaluate armor, stamina, defense, shield/block value, avoidance, hit/expertise where present, and threat versus mitigation tradeoffs.",
        "Arms/Fury DPS: evaluate strength, attack power, crit, hit/expertise where present, weapon speed/type, and set bonuses.",
    },
    PALADIN = {
        "Protection tank: evaluate spell damage/threat, stamina, defense, block value, avoidance, and mitigation.",
        "Holy healing: evaluate bonus healing, intellect, mp5, crit, and mana longevity.",
        "Retribution DPS: evaluate strength, attack power, crit, hit/expertise where present, weapon quality, and set synergy.",
    },
    PRIEST = {
        "Healing: evaluate bonus healing, spirit, intellect, mp5, haste where present, and mana longevity.",
        "Shadow DPS: evaluate spell damage, shadow damage, spell hit, spell crit, haste where present, and mana sustain.",
    },
    SHAMAN = {
        "Restoration healing: evaluate bonus healing, mp5, intellect, crit, haste where present, and mana longevity.",
        "Elemental DPS: evaluate spell damage, spell hit, spell crit, haste where present, and mana sustain.",
        "Enhancement DPS: evaluate attack power, agility, strength, crit, hit/expertise where present, weapon options, and set synergy.",
    },
    HUNTER = {
        "Ranged DPS: evaluate agility, attack power, crit, hit, ranged weapon quality, ammo/quiver support, and set bonuses.",
    },
    ROGUE = {
        "Melee DPS: evaluate agility, attack power, crit, hit/expertise where present, weapon speed/type, and set bonuses.",
    },
    MAGE = {
        "Caster DPS: evaluate spell damage, spell hit, spell crit, haste where present, intellect, mana sustain, and school-specific bonuses.",
    },
    WARLOCK = {
        "Caster DPS: evaluate spell damage, spell hit, spell crit, haste where present, stamina, intellect, and shadow/fire damage priorities.",
    },
}

local DEFAULT_ROLE_CONTEXT = {
    "Primary role: identify the most likely use for each equippable item from stats, item type, equip slot, quality, item level, and category.",
    "Alternate role: call out items that may belong to an offspec set instead of the main set.",
}

local AI_OUTPUT_REQUESTS = {
    "Summarize likely class/spec roles represented by the saved items.",
    "Use current_talents when available to anchor the main-spec recommendation, while still calling out useful offspec items.",
    "Use chart_stats for high-level totals by source, category, quality, equip slot, item level, and stat totals before drilling into individual items.",
    "For each plausible role, rank strong keepers, weak slots, and upgrade priorities. Validate every proposed swap with gear_recommendations.upgrades[].stat_gains, stat_losses, evidence, and both item links.",
    "Use gear_recommendations.phase2_strategy to select the requested strategy mode, resolve caps before throughput, compare the saved target-set progress, and separate simulation presets from guide-only evidence.",
    "Separate mitigation, threat, DPS, healing, caster, and utility value when relevant.",
    "Flag duplicates, offspec pieces, consumables, materials, or items that are probably safe to vendor, bank, disenchant, or keep.",
    "Use wowhead_url fields when naming specific items so the user can inspect them quickly.",
    "Ask concise follow-up questions only when the exported data cannot determine the answer.",
}

local CLASS_ROLE_CONTEXT_ZHCN = {
    DRUID = {
        "熊形态野性坦克：重点评估护甲、耐力、防御/韧性、躲闪/敏捷、仇恨属性、命中/精准、野性攻击强度武器、坦克饰品，以及生存和仇恨之间的取舍。",
        "猎豹野性输出：重点评估敏捷、力量、攻击强度、暴击、命中/精准、武器的野性攻击强度、套装协同，以及这些装备是否会和熊坦减伤装冲突。",
        "恢复治疗：重点评估治疗效果、精神、智力、5 秒回蓝、急速、续航，以及治疗武器、副手、戒指、饰品选择。",
        "平衡法系输出：重点评估法术伤害、法术命中、法术暴击、急速、智力、法力续航，并判断法系装备更适合治疗还是输出套装。",
    },
    WARRIOR = {
        "防护坦克：重点评估护甲、耐力、防御、盾牌/格挡值、躲闪招架、命中/精准，以及仇恨和减伤之间的取舍。",
        "武器/狂暴输出：重点评估力量、攻击强度、暴击、命中/精准、武器速度/类型，以及套装加成。",
    },
    PALADIN = {
        "防护坦克：重点评估法术伤害/仇恨、耐力、防御、格挡值、躲闪招架和整体减伤。",
        "神圣治疗：重点评估治疗效果、智力、5 秒回蓝、暴击和法力续航。",
        "惩戒输出：重点评估力量、攻击强度、暴击、命中/精准、武器质量和套装协同。",
    },
    PRIEST = {
        "治疗：重点评估治疗效果、精神、智力、5 秒回蓝、急速和法力续航。",
        "暗影输出：重点评估法术伤害、暗影伤害、法术命中、法术暴击、急速和法力续航。",
    },
    SHAMAN = {
        "恢复治疗：重点评估治疗效果、5 秒回蓝、智力、暴击、急速和法力续航。",
        "元素输出：重点评估法术伤害、法术命中、法术暴击、急速和法力续航。",
        "增强输出：重点评估攻击强度、敏捷、力量、暴击、命中/精准、武器选择和套装协同。",
    },
    HUNTER = {
        "远程输出：重点评估敏捷、攻击强度、暴击、命中、远程武器质量、弹药/箭袋支持和套装加成。",
    },
    ROGUE = {
        "近战输出：重点评估敏捷、攻击强度、暴击、命中/精准、武器速度/类型和套装加成。",
    },
    MAGE = {
        "法系输出：重点评估法术伤害、法术命中、法术暴击、急速、智力、法力续航和特定法术系别加成。",
    },
    WARLOCK = {
        "法系输出：重点评估法术伤害、法术命中、法术暴击、急速、耐力、智力，以及暗影/火焰伤害优先级。",
    },
}

local DEFAULT_ROLE_CONTEXT_ZHCN = {
    "主职责：根据属性、物品类型、装备栏位、品质、物品等级和分类，判断每件可装备物品最可能的用途。",
    "副天赋/备用套装：指出哪些物品更可能属于副天赋或备用套装，而不是主套装。",
}

local AI_OUTPUT_REQUESTS_ZHCN = {
    "总结这些已保存物品最可能对应的职业天赋/职责。",
    "如果 current_talents 可用，请用当前天赋锚定主天赋建议，同时指出有价值的副天赋物品。",
    "在逐件分析前，请先使用 character_stats、chart_stats 和 strategy_book 按当前天赋、职业、种族、队伍/团队环境、命中、暴击、防御、免伤、仇恨、治疗、续航和输出价值做整体对比。",
    "针对每个可能职责，列出值得保留的强力装备、薄弱部位和升级优先级；每条换装建议必须核对 gear_recommendations.upgrades[] 中的 stat_gains、stat_losses、evidence 和新旧物品链接。",
    "使用 gear_recommendations.phase2_strategy 选择当前策略模式，先处理属性硬门槛，再比较目标套装收集进度，并明确区分模拟器预设与仅攻略证据。",
    "在相关时分别分析减伤、仇恨、输出、治疗、法系和功能性价值。",
    "标记重复物品、副天赋装备、消耗品、材料，或可能适合出售、存银行、分解、保留的物品。",
    "提到具体物品时使用 wowhead_url 字段，方便用户快速查看。",
    "只有当导出数据无法判断时，才提出简短的追问。",
}

local CLASS_ROLE_CONTEXT_ZHTW = {
    DRUID = {
        "熊形態野性坦克：重點評估護甲、耐力、防禦/韌性、閃躲/敏捷、仇恨屬性、命中/熟練、野性攻擊強度武器、坦克飾品，以及生存和仇恨之間的取捨。",
        "獵豹野性輸出：重點評估敏捷、力量、攻擊強度、致命一擊、命中/熟練、武器的野性攻擊強度、套裝協同，以及這些裝備是否會和熊坦減傷裝衝突。",
        "恢復治療：重點評估治療效果、精神、智力、每 5 秒回魔、加速、續航，以及治療武器、副手、戒指、飾品選擇。",
        "平衡法系輸出：重點評估法術傷害、法術命中、法術致命、加速、智力、法力續航，並判斷法系裝備更適合治療還是輸出套裝。",
    },
}

local DEFAULT_ROLE_CONTEXT_ZHTW = {
    "主職責：根據屬性、物品類型、裝備欄位、品質、物品等級和分類，判斷每件可裝備物品最可能的用途。",
    "副天賦/備用套裝：指出哪些物品更可能屬於副天賦或備用套裝，而不是主套裝。",
}

local AI_OUTPUT_REQUESTS_ZHTW = {
    "總結這些已儲存物品最可能對應的職業天賦/職責。",
    "如果 current_talents 可用，請用目前天賦錨定主天賦建議，同時指出有價值的副天賦物品。",
    "在逐件分析前，請先使用 character_stats、chart_stats 和 strategy_book 按目前天賦、職業、種族、隊伍/團隊環境、命中、致命、防禦、減傷、仇恨、治療、續航和輸出價值做整體比較。",
    "針對每個可能職責，列出值得保留的強力裝備、薄弱部位和升級優先順序；每條換裝建議必須核對 gear_recommendations.upgrades[] 中的 stat_gains、stat_losses、evidence 和新舊物品連結。",
    "使用 gear_recommendations.phase2_strategy 選擇目前策略模式，先處理屬性硬門檻，再比較目標套裝收集進度，並明確區分模擬器預設與僅攻略證據。",
    "在相關時分別分析減傷、仇恨、輸出、治療、法系和功能性價值。",
    "標記重複物品、副天賦裝備、消耗品、材料，或可能適合出售、存銀行、分解、保留的物品。",
    "提到具體物品時使用 wowhead_url 欄位，方便使用者快速查看。",
    "只有當匯出資料無法判斷時，才提出簡短的追問。",
}

local CHARACTER_ATTRIBUTE_SPECS = {
    { index = 1, key = "strength", label = "Strength" },
    { index = 2, key = "agility", label = "Agility" },
    { index = 3, key = "stamina", label = "Stamina" },
    { index = 4, key = "intellect", label = "Intellect" },
    { index = 5, key = "spirit", label = "Spirit" },
}

local SPELL_SCHOOL_SPECS = {
    { index = 2, key = "holy", label = "Holy" },
    { index = 3, key = "fire", label = "Fire" },
    { index = 4, key = "nature", label = "Nature" },
    { index = 5, key = "frost", label = "Frost" },
    { index = 6, key = "shadow", label = "Shadow" },
    { index = 7, key = "arcane", label = "Arcane" },
}

local COMBAT_RATING_SPECS = {
    { key = "defense", label = "Defense Rating", global = "CR_DEFENSE_SKILL" },
    { key = "dodge", label = "Dodge Rating", global = "CR_DODGE" },
    { key = "parry", label = "Parry Rating", global = "CR_PARRY" },
    { key = "block", label = "Block Rating", global = "CR_BLOCK" },
    { key = "melee_hit", label = "Melee Hit", global = "CR_HIT_MELEE" },
    { key = "ranged_hit", label = "Ranged Hit", global = "CR_HIT_RANGED" },
    { key = "spell_hit", label = "Spell Hit", global = "CR_HIT_SPELL" },
    { key = "melee_crit", label = "Melee Crit", global = "CR_CRIT_MELEE" },
    { key = "ranged_crit", label = "Ranged Crit", global = "CR_CRIT_RANGED" },
    { key = "spell_crit", label = "Spell Crit", global = "CR_CRIT_SPELL" },
    { key = "melee_haste", label = "Melee Haste", global = "CR_HASTE_MELEE" },
    { key = "ranged_haste", label = "Ranged Haste", global = "CR_HASTE_RANGED" },
    { key = "spell_haste", label = "Spell Haste", global = "CR_HASTE_SPELL" },
    { key = "expertise", label = "Expertise", global = "CR_EXPERTISE" },
    { key = "resilience", label = "Resilience", global = "CR_RESILIENCE_CRIT_TAKEN", fallbackGlobal = "CR_RESILIENCE_PLAYER_DAMAGE_TAKEN" },
}

local TBC_BENCHMARKS = {
    defense_crit_immunity = { label = "Defense crit-immunity benchmark", value = 490, unit = "defense skill", note = "Common level-70 raid-boss tank reference." },
    crit_immunity = { label = "Combined crit-immunity benchmark", value = 5.6, unit = "% crit reduction", note = "Boss critical-hit reduction from defense skill, resilience, and applicable talents." },
    melee_special_hit = { label = "Melee special hit benchmark", value = 9, unit = "% hit", note = "Common boss-level yellow-hit reference." },
    ranged_hit = { label = "Ranged hit benchmark", value = 9, unit = "% hit", note = "Common boss-level ranged-hit reference." },
    spell_hit = { label = "Spell hit benchmark", value = 16, unit = "% hit", note = "Common TBC boss-level spell-hit reference before class/talent debuffs." },
    expertise_dodge = { label = "Expertise dodge benchmark", value = 6.5, unit = "% dodge reduction", note = "Common boss dodge reduction reference where expertise exists." },
    avoidance_table = { label = "Shield table context check", value = 102.4, unit = "% dodge/parry/block subtotal", note = "The exported subtotal excludes attacker miss and temporary block effects, so it cannot prove or disprove full shield-table coverage by itself." },
}

GEAR_ENGINE.GEAR_SLOT_ORDER = {
    "HEAD", "NECK", "SHOULDER", "BACK", "CHEST", "WRIST", "HANDS", "WAIST", "LEGS", "FEET",
    "FINGER", "TRINKET", "MAINHAND", "OFFHAND", "RANGED",
}

GEAR_ENGINE.EQUIPMENT_SLOT_LABELS = {
    enUS = {
        HEAD = "Head", NECK = "Neck", SHOULDER = "Shoulder", SHIRT = "Shirt", CHEST = "Chest",
        WAIST = "Waist", LEGS = "Legs", FEET = "Feet", WRIST = "Wrist", HANDS = "Hands",
        FINGER = "Ring", TRINKET = "Trinket", BACK = "Back", MAINHAND = "Main hand",
        OFFHAND = "Off hand", RANGED = "Ranged / relic", TABARD = "Tabard",
    },
    zhCN = {
        HEAD = "头部", NECK = "颈部", SHOULDER = "肩部", SHIRT = "衬衣", CHEST = "胸部",
        WAIST = "腰部", LEGS = "腿部", FEET = "脚部", WRIST = "手腕", HANDS = "手部",
        FINGER = "戒指", TRINKET = "饰品", BACK = "背部", MAINHAND = "主手",
        OFFHAND = "副手", RANGED = "远程/圣物", TABARD = "战袍",
    },
    zhTW = {
        HEAD = "頭部", NECK = "頸部", SHOULDER = "肩部", SHIRT = "襯衣", CHEST = "胸部",
        WAIST = "腰部", LEGS = "腿部", FEET = "腳部", WRIST = "手腕", HANDS = "手部",
        FINGER = "戒指", TRINKET = "飾品", BACK = "背部", MAINHAND = "主手",
        OFFHAND = "副手", RANGED = "遠程/聖物", TABARD = "戰袍",
    },
}

GEAR_ENGINE.CLASS_MAX_ARMOR_SUBCLASS = {
    WARRIOR = 4, PALADIN = 4, HUNTER = 3, SHAMAN = 3, ROGUE = 2, DRUID = 2,
    MAGE = 1, PRIEST = 1, WARLOCK = 1,
}

GEAR_ENGINE.SHIELD_CLASSES = { WARRIOR = true, PALADIN = true, SHAMAN = true }

GEAR_ENGINE.STAT_SCORE_SCALES = {
    ITEM_MOD_ARMOR = 0.03,
    ITEM_MOD_BONUS_ARMOR_SHORT = 0.05,
    ITEM_MOD_ATTACK_POWER_SHORT = 0.25,
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = 0.22,
    ITEM_MOD_FERAL_ATTACK_POWER_SHORT = 0.22,
    ITEM_MOD_SPELL_POWER_SHORT = 0.30,
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 0.30,
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = 0.12,
    ITEM_MOD_BLOCK_VALUE_SHORT = 0.20,
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 1.50,
}

GEAR_ENGINE.ROLE_FIT_SIGNALS = {
    healer = {
        primary = {
            ITEM_MOD_SPELL_HEALING_DONE_SHORT = true,
            ITEM_MOD_SPELL_POWER_SHORT = true,
            ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = true,
            ITEM_MOD_MANA_REGENERATION_SHORT = true,
        },
        secondary = {
            ITEM_MOD_INTELLECT_SHORT = true,
            ITEM_MOD_SPIRIT_SHORT = true,
        },
        conflict = {
            ITEM_MOD_ATTACK_POWER_SHORT = true,
            ITEM_MOD_RANGED_ATTACK_POWER_SHORT = true,
            ITEM_MOD_FERAL_ATTACK_POWER_SHORT = true,
            ITEM_MOD_DAMAGE_PER_SECOND_SHORT = true,
            ITEM_MOD_STRENGTH_SHORT = true,
            ITEM_MOD_AGILITY_SHORT = true,
            ITEM_MOD_HIT_MELEE_RATING_SHORT = true,
            ITEM_MOD_HIT_RANGED_RATING_SHORT = true,
            ITEM_MOD_EXPERTISE_RATING_SHORT = true,
        },
    },
    caster = {
        primary = {
            ITEM_MOD_SPELL_POWER_SHORT = true,
            ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = true,
            ITEM_MOD_HIT_SPELL_RATING_SHORT = true,
        },
        secondary = {
            ITEM_MOD_INTELLECT_SHORT = true,
            ITEM_MOD_SPIRIT_SHORT = true,
            ITEM_MOD_MANA_REGENERATION_SHORT = true,
        },
        conflict = {
            ITEM_MOD_ATTACK_POWER_SHORT = true,
            ITEM_MOD_RANGED_ATTACK_POWER_SHORT = true,
            ITEM_MOD_FERAL_ATTACK_POWER_SHORT = true,
            ITEM_MOD_DAMAGE_PER_SECOND_SHORT = true,
            ITEM_MOD_STRENGTH_SHORT = true,
            ITEM_MOD_AGILITY_SHORT = true,
            ITEM_MOD_HIT_MELEE_RATING_SHORT = true,
            ITEM_MOD_HIT_RANGED_RATING_SHORT = true,
            ITEM_MOD_EXPERTISE_RATING_SHORT = true,
        },
    },
    melee = {
        primary = {
            ITEM_MOD_ATTACK_POWER_SHORT = true,
            ITEM_MOD_FERAL_ATTACK_POWER_SHORT = true,
            ITEM_MOD_DAMAGE_PER_SECOND_SHORT = true,
            ITEM_MOD_HIT_RATING_SHORT = true,
            ITEM_MOD_HIT_MELEE_RATING_SHORT = true,
            ITEM_MOD_EXPERTISE_RATING_SHORT = true,
        },
        secondary = {
            ITEM_MOD_STRENGTH_SHORT = true,
            ITEM_MOD_AGILITY_SHORT = true,
        },
        conflict = {
            ITEM_MOD_SPELL_HEALING_DONE_SHORT = true,
            ITEM_MOD_SPELL_POWER_SHORT = true,
            ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = true,
            ITEM_MOD_HIT_SPELL_RATING_SHORT = true,
        },
    },
    ranged = {
        primary = {
            ITEM_MOD_RANGED_ATTACK_POWER_SHORT = true,
            ITEM_MOD_ATTACK_POWER_SHORT = true,
            ITEM_MOD_DAMAGE_PER_SECOND_SHORT = true,
            ITEM_MOD_HIT_RATING_SHORT = true,
            ITEM_MOD_HIT_RANGED_RATING_SHORT = true,
        },
        secondary = {
            ITEM_MOD_AGILITY_SHORT = true,
        },
        conflict = {
            ITEM_MOD_SPELL_HEALING_DONE_SHORT = true,
            ITEM_MOD_SPELL_POWER_SHORT = true,
            ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = true,
            ITEM_MOD_HIT_SPELL_RATING_SHORT = true,
        },
    },
}

GEAR_ENGINE.STAT_TOKEN_ALIASES = {
    RESISTANCE0_NAME = "ITEM_MOD_ARMOR",
    ITEM_MOD_CRIT_RATING = "ITEM_MOD_CRIT_RATING_SHORT",
    ITEM_MOD_CRIT_MELEE_RATING = "ITEM_MOD_CRIT_MELEE_RATING_SHORT",
    ITEM_MOD_CRIT_RANGED_RATING = "ITEM_MOD_CRIT_RANGED_RATING_SHORT",
    ITEM_MOD_CRIT_SPELL_RATING = "ITEM_MOD_CRIT_SPELL_RATING_SHORT",
    ITEM_MOD_DEFENSE_SKILL_RATING = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
    ITEM_MOD_DODGE_RATING = "ITEM_MOD_DODGE_RATING_SHORT",
    ITEM_MOD_EXPERTISE_RATING = "ITEM_MOD_EXPERTISE_RATING_SHORT",
    ITEM_MOD_HASTE_RATING = "ITEM_MOD_HASTE_RATING_SHORT",
    ITEM_MOD_HASTE_MELEE_RATING = "ITEM_MOD_HASTE_MELEE_RATING_SHORT",
    ITEM_MOD_HASTE_RANGED_RATING = "ITEM_MOD_HASTE_RANGED_RATING_SHORT",
    ITEM_MOD_HASTE_SPELL_RATING = "ITEM_MOD_HASTE_SPELL_RATING_SHORT",
    ITEM_MOD_HIT_RATING = "ITEM_MOD_HIT_RATING_SHORT",
    ITEM_MOD_HIT_MELEE_RATING = "ITEM_MOD_HIT_MELEE_RATING_SHORT",
    ITEM_MOD_HIT_RANGED_RATING = "ITEM_MOD_HIT_RANGED_RATING_SHORT",
    ITEM_MOD_HIT_SPELL_RATING = "ITEM_MOD_HIT_SPELL_RATING_SHORT",
    ITEM_MOD_PARRY_RATING = "ITEM_MOD_PARRY_RATING_SHORT",
    ITEM_MOD_BLOCK_RATING = "ITEM_MOD_BLOCK_RATING_SHORT",
    ITEM_MOD_BLOCK_VALUE = "ITEM_MOD_BLOCK_VALUE_SHORT",
    ITEM_MOD_ATTACK_POWER = "ITEM_MOD_ATTACK_POWER_SHORT",
    ITEM_MOD_RANGED_ATTACK_POWER = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    ITEM_MOD_FERAL_ATTACK_POWER = "ITEM_MOD_FERAL_ATTACK_POWER_SHORT",
    ITEM_MOD_POWER_REGEN0_SHORT = "ITEM_MOD_MANA_REGENERATION_SHORT",
    ITEM_MOD_RESILIENCE_RATING = "ITEM_MOD_RESILIENCE_RATING_SHORT",
    ITEM_MOD_SPELL_DAMAGE_DONE = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
    ITEM_MOD_SPELL_HEALING_DONE = "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
    ITEM_MOD_SPELL_POWER = "ITEM_MOD_SPELL_POWER_SHORT",
    ITEM_MOD_HEALTH_REGEN = "ITEM_MOD_HEALTH_REGEN_SHORT",
}

function GEAR_ENGINE.NormalizeStatToken(token)
    return GEAR_ENGINE.STAT_TOKEN_ALIASES[token] or token
end

function GEAR_ENGINE.ComparisonStatToken(token)
    token = GEAR_ENGINE.NormalizeStatToken(token)
    if token == "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" then
        return "ITEM_MOD_SPELL_POWER_SHORT"
    end
    return token
end

GEAR_ENGINE.BENCHMARK_STAT_TOKENS = {
    defense_crit_immunity = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT" },
    crit_immunity = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_RESILIENCE_RATING_SHORT" },
    melee_special_hit = { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_HIT_MELEE_RATING_SHORT" },
    ranged_hit = { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_HIT_RANGED_RATING_SHORT" },
    spell_hit = { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT" },
    expertise_dodge = { "ITEM_MOD_EXPERTISE_RATING_SHORT" },
    avoidance_table = { "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT", "ITEM_MOD_BLOCK_RATING_SHORT" },
}

local RACE_STRATEGY_NOTES = {
    HUMAN = { "Weapon and spirit racials can affect melee threat/DPS and mana-adjacent evaluations." },
    NIGHTELF = { "Quickness-style avoidance and Shadowmeld utility can matter for mitigation and solo context." },
    DWARF = { "Stoneform and weapon/ranged racials can matter for defensive utility and weapon choice." },
    GNOME = { "Intellect and Escape Artist utility can matter for caster throughput and control-heavy encounters." },
    DRAENEI = { "Party-local hit aura context can change raid/party hit planning in TBC groups." },
    ORC = { "Blood Fury, weapon, pet, and stun-resist racials can affect threat, DPS, and pet classes." },
    TAUREN = { "Stamina and War Stomp utility can affect tank and control evaluations." },
    TROLL = { "Berserking and ranged racials can affect throughput windows and ranged weapon choices." },
    SCOURGE = { "Will of the Forsaken utility can matter for PvP/control-heavy encounters." },
    UNDEAD = { "Will of the Forsaken utility can matter for PvP/control-heavy encounters." },
    BLOODELF = { "Arcane Torrent and magic utility can matter for mana/control context." },
}

local ANALYSIS_LOCALIZATION = {
    enUS = {
        models = {
            role_identification = "Role identification",
            upgrade_triage = "Upgrade triage",
            tank_mitigation = "Tank mitigation",
            tank_threat = "Tank threat",
            melee_dps = "Melee DPS",
            threat_awareness = "Threat awareness",
            healing_throughput = "Healing throughput",
            mana_longevity = "Mana longevity",
            caster_dps = "Caster DPS",
            weapon_selection = "Weapon selection",
            spell_threat = "Spell threat",
            utility_dps = "Utility DPS",
            mana_support = "Mana support",
            ranged_dps = "Ranged DPS",
            pet_synergy = "Pet synergy",
            survivability = "Survivability",
            raid_support = "Raid support",
            raid_debuff = "Raid debuff",
            control = "Control",
        },
        benchmarks = {
            defense_crit_immunity = "Defense crit-immunity benchmark",
            crit_immunity = "Combined crit-immunity benchmark",
            melee_special_hit = "Melee special hit benchmark",
            ranged_hit = "Ranged hit benchmark",
            spell_hit = "Spell hit benchmark",
            expertise_dodge = "Expertise dodge benchmark",
            avoidance_table = "Shield table context check",
        },
        units = {
            ["defense skill"] = "defense skill",
            ["% crit reduction"] = "% crit reduction",
            ["% hit"] = "% hit",
            ["% dodge reduction"] = "% dodge reduction",
            ["% dodge/parry/block subtotal"] = "% dodge/parry/block subtotal",
        },
        statuses = {
            meets_or_exceeds = "Meets / exceeds",
            near = "Near target",
            below = "Below target",
            context_required = "Needs combat context",
            unknown = "Unknown",
        },
        groupTypes = {
            raid = "Raid",
            party = "Party",
            solo = "Solo",
        },
    },
    zhCN = {
        roles = {
            general_inventory = "通用背包策略",
            bear_tank = "熊形态野性坦克",
            cat_dps = "猎豹野性输出",
            restoration_healer = "恢复治疗",
            balance_caster = "平衡法系输出",
            protection_tank = "防护坦克",
            arms_fury_dps = "武器/狂暴输出",
            holy_healer = "神圣治疗",
            retribution_dps = "惩戒输出",
            healing = "戒律/神圣治疗",
            shadow_dps = "暗影输出",
            elemental_dps = "元素输出",
            enhancement_dps = "增强输出",
            ranged_dps = "远程输出",
            melee_dps = "近战输出",
            caster_dps = "法系输出",
        },
        models = {
            role_identification = "职责识别",
            upgrade_triage = "升级优先级",
            tank_mitigation = "坦克免伤",
            tank_threat = "坦克仇恨",
            melee_dps = "近战输出",
            threat_awareness = "仇恨控制",
            healing_throughput = "治疗量",
            mana_longevity = "法力续航",
            caster_dps = "法系输出",
            weapon_selection = "武器选择",
            spell_threat = "法术仇恨",
            utility_dps = "功能性输出",
            mana_support = "法力支援",
            ranged_dps = "远程输出",
            pet_synergy = "宠物协同",
            survivability = "生存能力",
            raid_support = "团队支援",
            raid_debuff = "团队减益",
            control = "控制",
        },
        benchmarks = {
            defense_crit_immunity = "防御免暴基准",
            crit_immunity = "综合免暴基准",
            melee_special_hit = "近战技能命中基准",
            ranged_hit = "远程命中基准",
            spell_hit = "法术命中基准",
            expertise_dodge = "熟练降低躲闪基准",
            avoidance_table = "免伤/格挡表覆盖基准",
        },
        statuses = {
            meets_or_exceeds = "达标",
            near = "接近目标",
            below = "低于目标",
            context_required = "需结合战斗状态核对",
            unknown = "未知",
        },
        units = {
            ["defense skill"] = "防御技能",
            ["% crit reduction"] = "% 免暴减免",
            ["% hit"] = "% 命中",
            ["% dodge reduction"] = "% 躲闪降低",
            ["% dodge/parry/block subtotal"] = "% 躲闪+招架+格挡小计",
        },
        groupTypes = {
            raid = "团队",
            party = "队伍",
            solo = "单人",
        },
        classes = {
            DRUID = "德鲁伊",
            WARRIOR = "战士",
            PALADIN = "圣骑士",
            PRIEST = "牧师",
            SHAMAN = "萨满祭司",
            HUNTER = "猎人",
            ROGUE = "潜行者",
            MAGE = "法师",
            WARLOCK = "术士",
        },
        races = {
            HUMAN = "人类",
            NIGHTELF = "暗夜精灵",
            DWARF = "矮人",
            GNOME = "侏儒",
            DRAENEI = "德莱尼",
            ORC = "兽人",
            TAUREN = "牛头人",
            TROLL = "巨魔",
            SCOURGE = "亡灵",
            UNDEAD = "亡灵",
            BLOODELF = "血精灵",
        },
        raceNotes = {
            HUMAN = { "武器和精神种族特长会影响近战仇恨/输出，以及与法力相关的评估。" },
            NIGHTELF = { "闪避类种族特长和影遁会影响免伤和单人场景。" },
            DWARF = { "石像形态、武器和远程种族特长会影响防御功能性和武器选择。" },
            GNOME = { "智力和逃脱大师会影响法系收益和控制压力较高的战斗。" },
            DRAENEI = { "队伍命中光环会改变 TBC 队伍/团队中的命中规划。" },
            ORC = { "血性狂怒、武器、宠物和抗昏迷种族特长会影响仇恨、输出和宠物职业。" },
            TAUREN = { "耐力和战争践踏会影响坦克和控制评估。" },
            TROLL = { "狂暴和远程种族特长会影响爆发窗口和远程武器选择。" },
            SCOURGE = { "亡灵意志会影响 PvP 或控制压力较高的战斗。" },
            UNDEAD = { "亡灵意志会影响 PvP 或控制压力较高的战斗。" },
            BLOODELF = { "奥术洪流和魔法功能性会影响法力与控制场景。" },
        },
        groupNotes = {
            raid = {
                "团队场景：基准使用常见首领等级参考，但 TBC 团队小队仍会影响队伍光环和种族加成。",
                "请确认命中、法力、仇恨或功能性增益是否真的存在于角色所在小队。",
            },
            party = {
                "队伍场景：队伍光环和种族加成会改变命中、仇恨、法力与功能性规划。",
                "如果当前有队伍增益，导出的实时属性应按已增益状态理解。",
            },
            solo = {
                "单人场景：实时属性可能缺少团队/队伍增益、减益和队伍种族光环。",
            },
        },
        stats = {
            ITEM_MOD_MANA = "法力值",
            ITEM_MOD_HEALTH = "生命值",
            ITEM_MOD_STAMINA_SHORT = "耐力",
            ITEM_MOD_ARMOR = "护甲",
            ITEM_MOD_BONUS_ARMOR_SHORT = "额外护甲",
            ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "防御等级",
            ITEM_MOD_DODGE_RATING_SHORT = "躲闪等级",
            ITEM_MOD_PARRY_RATING_SHORT = "招架等级",
            ITEM_MOD_BLOCK_RATING_SHORT = "格挡等级",
            ITEM_MOD_BLOCK_VALUE_SHORT = "格挡值",
            ITEM_MOD_AGILITY_SHORT = "敏捷",
            ITEM_MOD_STRENGTH_SHORT = "力量",
            ITEM_MOD_INTELLECT_SHORT = "智力",
            ITEM_MOD_SPIRIT_SHORT = "精神",
            ITEM_MOD_ATTACK_POWER_SHORT = "攻击强度",
            ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "远程攻击强度",
            ITEM_MOD_FERAL_ATTACK_POWER_SHORT = "野性攻击强度",
            ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "每秒伤害",
            ITEM_MOD_HIT_RATING_SHORT = "命中等级",
            ITEM_MOD_HIT_MELEE_RATING_SHORT = "近战命中等级",
            ITEM_MOD_HIT_RANGED_RATING_SHORT = "远程命中等级",
            ITEM_MOD_HIT_SPELL_RATING_SHORT = "法术命中等级",
            ITEM_MOD_CRIT_RATING_SHORT = "暴击等级",
            ITEM_MOD_CRIT_MELEE_RATING_SHORT = "近战暴击等级",
            ITEM_MOD_CRIT_RANGED_RATING_SHORT = "远程暴击等级",
            ITEM_MOD_CRIT_SPELL_RATING_SHORT = "法术暴击等级",
            ITEM_MOD_HASTE_RATING_SHORT = "急速等级",
            ITEM_MOD_HASTE_MELEE_RATING_SHORT = "近战急速等级",
            ITEM_MOD_HASTE_RANGED_RATING_SHORT = "远程急速等级",
            ITEM_MOD_HASTE_SPELL_RATING_SHORT = "法术急速等级",
            ITEM_MOD_RESILIENCE_RATING_SHORT = "韧性等级",
            ITEM_MOD_EXPERTISE_RATING_SHORT = "熟练等级",
            ITEM_MOD_SPELL_POWER_SHORT = "法术强度",
            ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "法术伤害",
            ITEM_MOD_SPELL_HEALING_DONE_SHORT = "治疗",
            ITEM_MOD_MANA_REGENERATION_SHORT = "法力回复",
            ITEM_MOD_HEALTH_REGEN_SHORT = "生命回复",
            EMPTY_SOCKET_BLUE = "蓝色插槽",
            EMPTY_SOCKET_RED = "红色插槽",
            EMPTY_SOCKET_YELLOW = "黄色插槽",
            EMPTY_SOCKET_META = "多彩插槽",
        },
    },
    zhTW = {
        roles = {
            general_inventory = "通用背包策略",
            bear_tank = "熊形態野性坦克",
            cat_dps = "獵豹野性輸出",
            restoration_healer = "恢復治療",
            balance_caster = "平衡法系輸出",
            protection_tank = "防護坦克",
            arms_fury_dps = "武器/狂怒輸出",
            holy_healer = "神聖治療",
            retribution_dps = "懲戒輸出",
            healing = "戒律/神聖治療",
            shadow_dps = "暗影輸出",
            elemental_dps = "元素輸出",
            enhancement_dps = "增強輸出",
            ranged_dps = "遠程輸出",
            melee_dps = "近戰輸出",
            caster_dps = "法系輸出",
        },
        models = {
            role_identification = "職責識別",
            upgrade_triage = "升級優先順序",
            tank_mitigation = "坦克減傷",
            tank_threat = "坦克仇恨",
            melee_dps = "近戰輸出",
            threat_awareness = "仇恨控制",
            healing_throughput = "治療量",
            mana_longevity = "法力續航",
            caster_dps = "法系輸出",
            weapon_selection = "武器選擇",
            spell_threat = "法術仇恨",
            utility_dps = "功能性輸出",
            mana_support = "法力支援",
            ranged_dps = "遠程輸出",
            pet_synergy = "寵物協同",
            survivability = "生存能力",
            raid_support = "團隊支援",
            raid_debuff = "團隊減益",
            control = "控制",
        },
        benchmarks = {
            defense_crit_immunity = "防禦免暴基準",
            crit_immunity = "綜合免暴基準",
            melee_special_hit = "近戰技能命中基準",
            ranged_hit = "遠程命中基準",
            spell_hit = "法術命中基準",
            expertise_dodge = "熟練降低閃躲基準",
            avoidance_table = "減傷/格擋表覆蓋基準",
        },
        statuses = {
            meets_or_exceeds = "達標",
            near = "接近目標",
            below = "低於目標",
            context_required = "需結合戰鬥狀態核對",
            unknown = "未知",
        },
        units = {
            ["defense skill"] = "防禦技能",
            ["% crit reduction"] = "% 免暴減免",
            ["% hit"] = "% 命中",
            ["% dodge reduction"] = "% 閃躲降低",
            ["% dodge/parry/block subtotal"] = "% 閃躲+招架+格擋小計",
        },
        groupTypes = {
            raid = "團隊",
            party = "隊伍",
            solo = "單人",
        },
        classes = {
            DRUID = "德魯伊",
            WARRIOR = "戰士",
            PALADIN = "聖騎士",
            PRIEST = "牧師",
            SHAMAN = "薩滿祭司",
            HUNTER = "獵人",
            ROGUE = "盜賊",
            MAGE = "法師",
            WARLOCK = "術士",
        },
        races = {
            HUMAN = "人類",
            NIGHTELF = "夜精靈",
            DWARF = "矮人",
            GNOME = "地精",
            DRAENEI = "德萊尼",
            ORC = "獸人",
            TAUREN = "牛頭人",
            TROLL = "食人妖",
            SCOURGE = "不死族",
            UNDEAD = "不死族",
            BLOODELF = "血精靈",
        },
        raceNotes = {
            HUMAN = { "武器和精神種族特長會影響近戰仇恨/輸出，以及與法力相關的評估。" },
            NIGHTELF = { "閃避類種族特長和影遁會影響減傷與單人場景。" },
            DWARF = { "石像形態、武器和遠程種族特長會影響防禦功能性和武器選擇。" },
            GNOME = { "智力和逃脫大師會影響法系收益與控制壓力較高的戰鬥。" },
            DRAENEI = { "隊伍命中光環會改變 TBC 隊伍/團隊中的命中規劃。" },
            ORC = { "血性狂怒、武器、寵物和抗昏迷種族特長會影響仇恨、輸出和寵物職業。" },
            TAUREN = { "耐力和戰爭踐踏會影響坦克和控制評估。" },
            TROLL = { "狂暴和遠程種族特長會影響爆發窗口和遠程武器選擇。" },
            SCOURGE = { "亡靈意志會影響 PvP 或控制壓力較高的戰鬥。" },
            UNDEAD = { "亡靈意志會影響 PvP 或控制壓力較高的戰鬥。" },
            BLOODELF = { "奧術洪流和魔法功能性會影響法力與控制場景。" },
        },
        groupNotes = {
            raid = {
                "團隊場景：基準使用常見首領等級參考，但 TBC 團隊小隊仍會影響隊伍光環和種族加成。",
                "請確認命中、法力、仇恨或功能性增益是否真的存在於角色所在小隊。",
            },
            party = {
                "隊伍場景：隊伍光環和種族加成會改變命中、仇恨、法力與功能性規劃。",
                "如果目前有隊伍增益，匯出的即時屬性應按已增益狀態理解。",
            },
            solo = {
                "單人場景：即時屬性可能缺少團隊/隊伍增益、減益和隊伍種族光環。",
            },
        },
        stats = {
            ITEM_MOD_MANA = "法力",
            ITEM_MOD_HEALTH = "生命",
            ITEM_MOD_STAMINA_SHORT = "耐力",
            ITEM_MOD_ARMOR = "護甲",
            ITEM_MOD_BONUS_ARMOR_SHORT = "額外護甲",
            ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "防禦等級",
            ITEM_MOD_DODGE_RATING_SHORT = "閃躲等級",
            ITEM_MOD_PARRY_RATING_SHORT = "招架等級",
            ITEM_MOD_BLOCK_RATING_SHORT = "格擋等級",
            ITEM_MOD_BLOCK_VALUE_SHORT = "格擋值",
            ITEM_MOD_AGILITY_SHORT = "敏捷",
            ITEM_MOD_STRENGTH_SHORT = "力量",
            ITEM_MOD_INTELLECT_SHORT = "智力",
            ITEM_MOD_SPIRIT_SHORT = "精神",
            ITEM_MOD_ATTACK_POWER_SHORT = "攻擊強度",
            ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "遠程攻擊強度",
            ITEM_MOD_FERAL_ATTACK_POWER_SHORT = "野性攻擊強度",
            ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "每秒傷害",
            ITEM_MOD_HIT_RATING_SHORT = "命中等級",
            ITEM_MOD_HIT_MELEE_RATING_SHORT = "近戰命中等級",
            ITEM_MOD_HIT_RANGED_RATING_SHORT = "遠程命中等級",
            ITEM_MOD_HIT_SPELL_RATING_SHORT = "法術命中等級",
            ITEM_MOD_CRIT_RATING_SHORT = "致命等級",
            ITEM_MOD_CRIT_MELEE_RATING_SHORT = "近戰致命等級",
            ITEM_MOD_CRIT_RANGED_RATING_SHORT = "遠程致命等級",
            ITEM_MOD_CRIT_SPELL_RATING_SHORT = "法術致命等級",
            ITEM_MOD_HASTE_RATING_SHORT = "加速等級",
            ITEM_MOD_HASTE_MELEE_RATING_SHORT = "近戰加速等級",
            ITEM_MOD_HASTE_RANGED_RATING_SHORT = "遠程加速等級",
            ITEM_MOD_HASTE_SPELL_RATING_SHORT = "法術加速等級",
            ITEM_MOD_RESILIENCE_RATING_SHORT = "韌性等級",
            ITEM_MOD_EXPERTISE_RATING_SHORT = "熟練等級",
            ITEM_MOD_SPELL_POWER_SHORT = "法術強度",
            ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "法術傷害",
            ITEM_MOD_SPELL_HEALING_DONE_SHORT = "治療",
            ITEM_MOD_MANA_REGENERATION_SHORT = "法力回復",
            ITEM_MOD_HEALTH_REGEN_SHORT = "生命回復",
            EMPTY_SOCKET_BLUE = "藍色插槽",
            EMPTY_SOCKET_RED = "紅色插槽",
            EMPTY_SOCKET_YELLOW = "黃色插槽",
            EMPTY_SOCKET_META = "變換插槽",
        },
    },
}
local DEFAULT_STRATEGY_ROLES = {
    {
        key = "general_inventory",
        label = "General Inventory Strategy",
        talentTabs = {},
        models = { "role_identification", "upgrade_triage" },
        priorities = { "item level", "quality", "primary stats", "role-specific secondary stats", "useful on-use/proc effects" },
        benchmarkKeys = {},
        statTokens = { "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_HEALING_DONE_SHORT" },
    },
}

local CLASS_STRATEGY_BOOK = {
    DRUID = {
        roles = {
            { key = "bear_tank", label = "Bear Feral Tank", talentTabs = { 2 }, models = { "tank_mitigation", "tank_threat" }, priorities = { "armor", "stamina", "defense/resilience", "dodge", "agility", "hit/expertise where available", "feral attack power", "threat trinkets" }, benchmarkKeys = { "crit_immunity", "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_ARMOR", "ITEM_MOD_BONUS_ARMOR_SHORT", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_RESILIENCE_RATING_SHORT", "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_FERAL_ATTACK_POWER_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
            { key = "cat_dps", label = "Cat Feral DPS", talentTabs = { 2 }, models = { "melee_dps", "threat_awareness" }, priorities = { "agility", "strength", "attack power", "crit", "hit/expertise", "feral attack power", "set synergy" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_FERAL_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
            { key = "restoration_healer", label = "Restoration Healing", talentTabs = { 3 }, models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "spirit", "intellect", "mp5", "haste", "mana longevity" }, benchmarkKeys = {}, statTokens = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_SPIRIT_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT" } },
            { key = "balance_caster", label = "Balance Caster DPS", talentTabs = { 1 }, models = { "caster_dps", "mana_longevity" }, priorities = { "spell damage", "spell hit", "spell crit", "haste", "intellect", "mana sustain" }, benchmarkKeys = { "spell_hit" }, statTokens = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT", "ITEM_MOD_INTELLECT_SHORT" } },
        },
    },
    WARRIOR = {
        roles = {
            { key = "protection_tank", label = "Protection Tank", talentTabs = { 3 }, models = { "tank_mitigation", "tank_threat" }, priorities = { "stamina", "armor", "defense", "avoidance", "shield block/value", "hit/expertise", "threat stats" }, benchmarkKeys = { "crit_immunity", "avoidance_table", "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_ARMOR", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_RESILIENCE_RATING_SHORT", "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT", "ITEM_MOD_BLOCK_RATING_SHORT", "ITEM_MOD_BLOCK_VALUE_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
            { key = "arms_fury_dps", label = "Arms/Fury DPS", talentTabs = { 1, 2 }, models = { "melee_dps", "weapon_selection" }, priorities = { "weapon damage/speed", "strength", "attack power", "crit", "hit/expertise", "set bonuses" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_EXPERTISE_RATING_SHORT" } },
        },
    },
    PALADIN = {
        roles = {
            { key = "protection_tank", label = "Protection Tank", talentTabs = { 2 }, models = { "tank_mitigation", "spell_threat" }, priorities = { "stamina", "defense", "avoidance", "block value", "spell damage/threat", "mana sustain" }, benchmarkKeys = { "crit_immunity", "avoidance_table", "spell_hit" }, statTokens = { "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_RESILIENCE_RATING_SHORT", "ITEM_MOD_ARMOR", "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT", "ITEM_MOD_BLOCK_RATING_SHORT", "ITEM_MOD_BLOCK_VALUE_SHORT", "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT" } },
            { key = "holy_healer", label = "Holy Healing", talentTabs = { 1 }, models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "intellect", "mp5", "spell crit", "mana longevity" }, benchmarkKeys = {}, statTokens = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT" } },
            { key = "retribution_dps", label = "Retribution DPS", talentTabs = { 3 }, models = { "melee_dps", "utility_dps" }, priorities = { "weapon quality", "strength", "attack power", "crit", "hit/expertise", "set synergy" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
        },
    },
    PRIEST = {
        roles = {
            { key = "healing", label = "Discipline/Holy Healing", talentTabs = { 1, 2 }, models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "spirit", "intellect", "mp5", "haste", "mana longevity" }, benchmarkKeys = {}, statTokens = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_SPIRIT_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT" } },
            { key = "shadow_dps", label = "Shadow DPS", talentTabs = { 3 }, models = { "caster_dps", "mana_support" }, priorities = { "shadow damage", "spell hit", "spell crit", "haste", "mana sustain" }, benchmarkKeys = { "spell_hit" }, statTokens = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT" } },
        },
    },
    SHAMAN = {
        roles = {
            { key = "restoration_healer", label = "Restoration Healing", talentTabs = { 3 }, models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "mp5", "intellect", "crit", "haste", "mana longevity" }, benchmarkKeys = {}, statTokens = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT" } },
            { key = "elemental_dps", label = "Elemental DPS", talentTabs = { 1 }, models = { "caster_dps", "mana_longevity" }, priorities = { "spell damage", "spell hit", "spell crit", "haste", "mana sustain" }, benchmarkKeys = { "spell_hit" }, statTokens = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT" } },
            { key = "enhancement_dps", label = "Enhancement DPS", talentTabs = { 2 }, models = { "melee_dps", "weapon_selection" }, priorities = { "weapon options", "attack power", "agility", "strength", "crit", "hit/expertise" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
        },
    },
    HUNTER = {
        roles = {
            { key = "ranged_dps", label = "Ranged DPS", talentTabs = { 1, 2, 3 }, models = { "ranged_dps", "pet_synergy" }, priorities = { "ranged weapon", "agility", "attack power", "crit", "hit", "ammo/quiver support", "set bonuses" }, benchmarkKeys = { "ranged_hit" }, statTokens = { "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RANGED_RATING_SHORT", "ITEM_MOD_HIT_RANGED_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
        },
    },
    ROGUE = {
        roles = {
            { key = "melee_dps", label = "Melee DPS", talentTabs = { 1, 2, 3 }, models = { "melee_dps", "weapon_selection" }, priorities = { "weapon speed/type", "agility", "attack power", "crit", "hit/expertise", "set bonuses" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_EXPERTISE_RATING_SHORT" } },
        },
    },
    MAGE = {
        roles = {
            { key = "caster_dps", label = "Caster DPS", talentTabs = { 1, 2, 3 }, models = { "caster_dps", "mana_longevity" }, priorities = { "spell damage", "spell hit", "spell crit", "haste", "intellect", "school-specific bonuses" }, benchmarkKeys = { "spell_hit" }, statTokens = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT", "ITEM_MOD_INTELLECT_SHORT" } },
        },
    },
    WARLOCK = {
        roles = {
            { key = "caster_dps", label = "Caster DPS", talentTabs = { 1, 2, 3 }, models = { "caster_dps", "pet_synergy", "survivability" }, priorities = { "spell damage", "spell hit", "spell crit", "haste", "stamina", "intellect", "shadow/fire bonuses" }, benchmarkKeys = { "spell_hit" }, statTokens = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT", "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_INTELLECT_SHORT" } },
        },
    },
}

local TALENT_EFFECT_RULES = {
    DRUID = {
        bear_tank = {
            { key = "thick_hide", names = { "Thick Hide", "厚皮" }, labels = { enUS = "Thick Hide armor", zhCN = "厚皮护甲", zhTW = "厚皮護甲" }, tags = { "mitigation", "armor" }, multipliers = { ITEM_MOD_ARMOR = 1.12, ITEM_MOD_BONUS_ARMOR_SHORT = 1.12 } },
            { key = "survival_of_the_fittest", names = { "Survival of the Fittest", "适者生存", "適者生存" }, labels = { enUS = "Survival of the Fittest", zhCN = "适者生存", zhTW = "適者生存" }, tags = { "mitigation", "survival" }, multipliers = { ITEM_MOD_STAMINA_SHORT = 1.08, ITEM_MOD_AGILITY_SHORT = 1.05 } },
        },
        cat_dps = {
            { key = "predatory_instincts", names = { "Predatory Instincts", "狩猎天性", "狩獵天性" }, labels = { enUS = "Predatory Instincts", zhCN = "狩猎天性", zhTW = "狩獵天性" }, tags = { "melee_dps", "crit" }, multipliers = { ITEM_MOD_CRIT_RATING_SHORT = 1.12, ITEM_MOD_AGILITY_SHORT = 1.06 } },
            { key = "shredding_attacks", names = { "Shredding Attacks", "撕碎攻击", "撕碎攻擊" }, labels = { enUS = "Shredding Attacks", zhCN = "撕碎攻击", zhTW = "撕碎攻擊" }, tags = { "melee_dps", "energy" }, multipliers = { ITEM_MOD_ATTACK_POWER_SHORT = 1.08, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 1.08 } },
        },
        restoration_healer = {
            { key = "tree_of_life", names = { "Tree of Life", "生命之树", "生命之樹" }, labels = { enUS = "Tree of Life", zhCN = "生命之树", zhTW = "生命之樹" }, tags = { "healing", "spirit" }, multipliers = { ITEM_MOD_SPELL_HEALING_DONE_SHORT = 1.12, ITEM_MOD_SPIRIT_SHORT = 1.10 } },
        },
        balance_caster = {
            { key = "balance_of_power", names = { "Balance of Power", "能量平衡" }, labels = { enUS = "Balance of Power", zhCN = "能量平衡", zhTW = "能量平衡" }, tags = { "caster_dps", "spell_hit" }, multipliers = { ITEM_MOD_HIT_SPELL_RATING_SHORT = 1.12, ITEM_MOD_SPELL_POWER_SHORT = 1.06 } },
        },
    },
    WARRIOR = {
        protection_tank = {
            { key = "shield_specialization", names = { "Shield Specialization", "盾牌专精", "盾牌專精" }, labels = { enUS = "Shield Specialization", zhCN = "盾牌专精", zhTW = "盾牌專精" }, tags = { "shield", "block" }, multipliers = { ITEM_MOD_BLOCK_RATING_SHORT = 1.12, ITEM_MOD_BLOCK_VALUE_SHORT = 1.10 } },
            { key = "vitality", names = { "Vitality", "活力" }, labels = { enUS = "Vitality", zhCN = "活力", zhTW = "活力" }, tags = { "survival", "threat" }, multipliers = { ITEM_MOD_STAMINA_SHORT = 1.08, ITEM_MOD_STRENGTH_SHORT = 1.05 } },
        },
        arms_fury_dps = {
            { key = "flurry", names = { "Flurry", "乱舞", "亂舞" }, labels = { enUS = "Flurry", zhCN = "乱舞", zhTW = "亂舞" }, tags = { "melee_dps", "haste" }, multipliers = { ITEM_MOD_CRIT_RATING_SHORT = 1.10, ITEM_MOD_HASTE_MELEE_RATING_SHORT = 1.08 } },
            { key = "weapon_mastery", names = { "Weapon Mastery", "武器掌握", "武器專精" }, labels = { enUS = "Weapon Mastery", zhCN = "武器掌握", zhTW = "武器專精" }, tags = { "melee_dps", "expertise" }, multipliers = { ITEM_MOD_EXPERTISE_RATING_SHORT = 1.12, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 1.06 } },
        },
    },
    PALADIN = {
        protection_tank = {
            { key = "shield_specialization", tab = 2, index = 1, names = { "Shield Specialization", "盾牌壁垒", "盾牌壁壘" }, labels = { enUS = "Shield Specialization", zhCN = "盾牌壁垒", zhTW = "盾牌壁壘" }, tags = { "shield", "block" }, multipliers = { ITEM_MOD_BLOCK_RATING_SHORT = 1.15, ITEM_MOD_BLOCK_VALUE_SHORT = 1.10 } },
            { key = "holy_shield", tab = 2, index = 8, names = { "Holy Shield", "神圣之盾", "神聖之盾" }, labels = { enUS = "Holy Shield", zhCN = "神圣之盾", zhTW = "神聖之盾" }, tags = { "shield_table", "spell_threat" }, multipliers = { ITEM_MOD_BLOCK_RATING_SHORT = 1.12, ITEM_MOD_SPELL_POWER_SHORT = 1.08 } },
            { key = "improved_righteous_fury", tab = 2, index = 11, names = { "Improved Righteous Fury", "强化正义之怒", "強化正義之怒" }, labels = { enUS = "Improved Righteous Fury", zhCN = "强化正义之怒", zhTW = "強化正義之怒" }, tags = { "mitigation", "threat" }, multipliers = { ITEM_MOD_STAMINA_SHORT = 1.08, ITEM_MOD_ARMOR = 1.06 } },
            { key = "combat_expertise", tab = 2, index = 20, names = { "Combat Expertise", "战斗精准", "戰鬥精準" }, labels = { enUS = "Combat Expertise", zhCN = "战斗精准", zhTW = "戰鬥精準" }, tags = { "survival", "threat" }, multipliers = { ITEM_MOD_STAMINA_SHORT = 1.08, ITEM_MOD_INTELLECT_SHORT = 1.05 } },
            { key = "avengers_shield", tab = 2, index = 21, names = { "Avenger's Shield", "复仇者之盾", "復仇者之盾" }, labels = { enUS = "Avenger's Shield", zhCN = "复仇者之盾", zhTW = "復仇者之盾" }, tags = { "spell_threat", "ranged_pull" }, multipliers = { ITEM_MOD_SPELL_POWER_SHORT = 1.10, ITEM_MOD_HIT_SPELL_RATING_SHORT = 1.06 } },
            { key = "improved_holy_shield", tab = 2, index = 22, names = { "Improved Holy Shield", "强化神圣之盾", "強化神聖之盾" }, labels = { enUS = "Improved Holy Shield", zhCN = "强化神圣之盾", zhTW = "強化神聖之盾" }, tags = { "shield_table", "block" }, multipliers = { ITEM_MOD_BLOCK_RATING_SHORT = 1.10, ITEM_MOD_BLOCK_VALUE_SHORT = 1.08 } },
        },
        holy_healer = {
            { key = "illumination", names = { "Illumination", "启发", "啟發" }, labels = { enUS = "Illumination", zhCN = "启发", zhTW = "啟發" }, tags = { "healing", "mana" }, multipliers = { ITEM_MOD_CRIT_SPELL_RATING_SHORT = 1.12, ITEM_MOD_MANA_REGENERATION_SHORT = 1.08 } },
            { key = "holy_guidance", names = { "Holy Guidance", "神圣指引", "神聖指引" }, labels = { enUS = "Holy Guidance", zhCN = "神圣指引", zhTW = "神聖指引" }, tags = { "healing", "intellect" }, multipliers = { ITEM_MOD_INTELLECT_SHORT = 1.10, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 1.06 } },
        },
        retribution_dps = {
            { key = "conviction", names = { "Conviction", "定罪" }, labels = { enUS = "Conviction", zhCN = "定罪", zhTW = "定罪" }, tags = { "melee_dps", "crit" }, multipliers = { ITEM_MOD_CRIT_RATING_SHORT = 1.12 } },
            { key = "crusade", names = { "Crusade", "征伐" }, labels = { enUS = "Crusade", zhCN = "征伐", zhTW = "征伐" }, tags = { "melee_dps", "damage" }, multipliers = { ITEM_MOD_ATTACK_POWER_SHORT = 1.08, ITEM_MOD_STRENGTH_SHORT = 1.06 } },
        },
    },
    PRIEST = {
        healing = {
            { key = "meditation", names = { "Meditation", "冥想" }, labels = { enUS = "Meditation", zhCN = "冥想", zhTW = "冥想" }, tags = { "healing", "mana" }, multipliers = { ITEM_MOD_MANA_REGENERATION_SHORT = 1.12, ITEM_MOD_SPIRIT_SHORT = 1.06 } },
            { key = "spiritual_guidance", names = { "Spiritual Guidance", "精神指导", "精神導引" }, labels = { enUS = "Spiritual Guidance", zhCN = "精神指导", zhTW = "精神導引" }, tags = { "healing", "spirit" }, multipliers = { ITEM_MOD_SPIRIT_SHORT = 1.10, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 1.08 } },
        },
        shadow_dps = {
            { key = "shadow_focus", names = { "Shadow Focus", "暗影集中" }, labels = { enUS = "Shadow Focus", zhCN = "暗影集中", zhTW = "暗影集中" }, tags = { "caster_dps", "spell_hit" }, multipliers = { ITEM_MOD_HIT_SPELL_RATING_SHORT = 1.12 } },
            { key = "shadowform", names = { "Shadowform", "暗影形态", "暗影形態" }, labels = { enUS = "Shadowform", zhCN = "暗影形态", zhTW = "暗影形態" }, tags = { "caster_dps", "shadow" }, multipliers = { ITEM_MOD_SPELL_POWER_SHORT = 1.10 } },
        },
    },
    SHAMAN = {
        restoration_healer = {
            { key = "mana_tide_totem", names = { "Mana Tide Totem", "法力之潮图腾", "法力之潮圖騰" }, labels = { enUS = "Mana Tide Totem", zhCN = "法力之潮图腾", zhTW = "法力之潮圖騰" }, tags = { "healing", "mana" }, multipliers = { ITEM_MOD_MANA_REGENERATION_SHORT = 1.12, ITEM_MOD_INTELLECT_SHORT = 1.06 } },
        },
        elemental_dps = {
            { key = "elemental_precision", names = { "Elemental Precision", "元素精准", "元素精準" }, labels = { enUS = "Elemental Precision", zhCN = "元素精准", zhTW = "元素精準" }, tags = { "caster_dps", "spell_hit" }, multipliers = { ITEM_MOD_HIT_SPELL_RATING_SHORT = 1.12, ITEM_MOD_SPELL_POWER_SHORT = 1.05 } },
        },
        enhancement_dps = {
            { key = "dual_wield_specialization", names = { "Dual Wield Specialization", "双武器专精", "雙武器專精" }, labels = { enUS = "Dual Wield Specialization", zhCN = "双武器专精", zhTW = "雙武器專精" }, tags = { "melee_dps", "hit" }, multipliers = { ITEM_MOD_HIT_RATING_SHORT = 1.12, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 1.05 } },
        },
    },
    HUNTER = {
        ranged_dps = {
            { key = "bestial_wrath", names = { "Bestial Wrath", "狂野怒火" }, labels = { enUS = "Bestial Wrath", zhCN = "狂野怒火", zhTW = "狂野怒火" }, tags = { "ranged_dps", "pet_burst" } },
            { key = "focused_fire", names = { "Focused Fire", "火力集中" }, labels = { enUS = "Focused Fire", zhCN = "火力集中", zhTW = "火力集中" }, tags = { "ranged_dps", "pet_synergy" } },
            { key = "frenzy", names = { "Frenzy", "狂乱", "狂亂" }, labels = { enUS = "Frenzy", zhCN = "狂乱", zhTW = "狂亂" }, tags = { "pet_synergy", "pet_crit" } },
            { key = "unleashed_fury", names = { "Unleashed Fury", "狂怒释放", "狂怒釋放" }, labels = { enUS = "Unleashed Fury", zhCN = "狂怒释放", zhTW = "狂怒釋放" }, tags = { "pet_synergy", "pet_damage" } },
            { key = "ferocity", names = { "Ferocity", "凶暴" }, labels = { enUS = "Ferocity", zhCN = "凶暴", zhTW = "凶暴" }, tags = { "pet_synergy", "pet_crit" } },
            { key = "animal_handler", names = { "Animal Handler", "驭兽者", "馭獸者" }, labels = { enUS = "Animal Handler", zhCN = "驭兽者", zhTW = "馭獸者" }, tags = { "pet_synergy", "pet_hit" } },
            { key = "intimidation", names = { "Intimidation", "胁迫", "脅迫" }, labels = { enUS = "Intimidation", zhCN = "胁迫", zhTW = "脅迫" }, tags = { "pet_synergy", "control" } },
            { key = "the_beast_within", names = { "The Beast Within", "野兽之心", "野獸之心" }, labels = { enUS = "The Beast Within", zhCN = "野兽之心", zhTW = "野獸之心" }, tags = { "ranged_dps", "pet_burst" } },
            { key = "careful_aim", names = { "Careful Aim", "仔细瞄准", "仔細瞄準" }, labels = { enUS = "Careful Aim", zhCN = "仔细瞄准", zhTW = "仔細瞄準" }, tags = { "ranged_dps", "intellect" }, multipliers = { ITEM_MOD_INTELLECT_SHORT = 1.08, ITEM_MOD_RANGED_ATTACK_POWER_SHORT = 1.08 } },
            { key = "lightning_reflexes", names = { "Lightning Reflexes", "闪电反射", "閃電反射" }, labels = { enUS = "Lightning Reflexes", zhCN = "闪电反射", zhTW = "閃電反射" }, tags = { "ranged_dps", "agility" }, multipliers = { ITEM_MOD_AGILITY_SHORT = 1.10 } },
        },
    },
    ROGUE = {
        melee_dps = {
            { key = "precision", names = { "Precision", "精确", "精準" }, labels = { enUS = "Precision", zhCN = "精确", zhTW = "精準" }, tags = { "melee_dps", "hit" }, multipliers = { ITEM_MOD_HIT_RATING_SHORT = 1.12 } },
            { key = "weapon_expertise", names = { "Weapon Expertise", "武器专家", "武器專家" }, labels = { enUS = "Weapon Expertise", zhCN = "武器专家", zhTW = "武器專家" }, tags = { "melee_dps", "expertise" }, multipliers = { ITEM_MOD_EXPERTISE_RATING_SHORT = 1.12 } },
        },
    },
    MAGE = {
        caster_dps = {
            { key = "arcane_focus", names = { "Arcane Focus", "奥术集中", "奧術集中" }, labels = { enUS = "Arcane Focus", zhCN = "奥术集中", zhTW = "奧術集中" }, tags = { "caster_dps", "spell_hit" }, multipliers = { ITEM_MOD_HIT_SPELL_RATING_SHORT = 1.10 } },
            { key = "elemental_precision", names = { "Elemental Precision", "元素精准", "元素精準" }, labels = { enUS = "Elemental Precision", zhCN = "元素精准", zhTW = "元素精準" }, tags = { "caster_dps", "spell_hit" }, multipliers = { ITEM_MOD_HIT_SPELL_RATING_SHORT = 1.10 } },
        },
    },
    WARLOCK = {
        caster_dps = {
            { key = "suppression", names = { "Suppression", "镇压", "鎮壓" }, labels = { enUS = "Suppression", zhCN = "镇压", zhTW = "鎮壓" }, tags = { "caster_dps", "spell_hit" }, multipliers = { ITEM_MOD_HIT_SPELL_RATING_SHORT = 1.12 } },
            { key = "demonic_knowledge", names = { "Demonic Knowledge", "恶魔知识", "惡魔知識" }, labels = { enUS = "Demonic Knowledge", zhCN = "恶魔知识", zhTW = "惡魔知識" }, tags = { "caster_dps", "pet" }, multipliers = { ITEM_MOD_STAMINA_SHORT = 1.06, ITEM_MOD_INTELLECT_SHORT = 1.06, ITEM_MOD_SPELL_POWER_SHORT = 1.08 } },
        },
    },
}
local EXPORT_FORMAT_LABELS = {
    ai = "AI Text",
    json = "JSON",
    markdown = "Markdown",
    text = "Text",
}

local UI_STRINGS = {
    enUS = {
        addon_title = "TBC Gear Exporter",
        summary_initial = "Bags: 0 items   Bank: 0 items   Scope: All",
        summary = "Bags: %d items   Bank: %d items   Scope: %s   Filter: %s   Format: %s",
        scan_button = "Scan Bags",
        export_button = "Export",
        bags_button = "Bags",
        bank_button = "Bank",
        gear_button = "Gear",
        debug_button = "Debug",
        select_button = "Select",
        source_label = "Source:",
        local_db_label = "Local DB",
        overview_tab = "Overview",
        gear_advice_tab = "Gear Advice",
        items_tab = "Items",
        stats_analysis_tab = "Stats Analysis",
        phase2_tab = "P2 Guide",
        text_export_tab = "Text Export",
        generate_button = "Generate",
        format_label = "Format:",
        filter_label = "Filter:",
        all_q_button = "All Q",
        rare_plus_button = "Rare+",
        epic_button = "Epic",
        gear_epic_button = "Gear Epic",
        format_ai_title = "AI Text",
        format_json_title = "JSON",
        format_markdown_title = "Markdown",
        format_text_title = "Text",
        status_ready = "AI-ready export is selected. Press Ctrl+C to copy.",
        status_selected = "Export text selected. Press Ctrl+C to copy.",
        status_generated = "%s export generated from saved local DB with filter: %s. Press Ctrl+C to copy.",
        status_visual = "Visual item view updated: %d items. Use Text Export to copy AI-ready data.",
        status_analysis = "Stats analysis updated: %d role models. Use Text Export to copy AI-ready data.",
        status_phase2 = "Phase 2 strategy updated for %s in %s mode.",
        status_overview = "Overview updated: %d items, %d role models. Use Text Export to copy AI-ready data.",
        status_advice = "Gear advice updated: %d decisions for %s.",
        advice_title = "Gear Strategy",
        advice_summary = "%s · %d equipped · %d candidates · %d role-rejected · %d decisions",
        advice_verdicts = "Decision: %s",
        advice_talent_map = "Talent mapping: %s",
        advice_role_hint = "Role lens",
        compare_title = "Selected item comparison",
        compare_current = "Current",
        compare_candidate = "Candidate",
        compare_select_hint = "Click either item icon in a recommendation to inspect the full comparison.",
        advice_priorities = "Priority stats: %s",
        advice_benchmarks = "Key checks: %s",
        advice_no_gaps = "No unresolved benchmark check",
        advice_no_upgrades = "No saved bag or bank item is strong enough to compare for this role.",
        advice_no_safe_upgrades = "No safe upgrade is recommended; %d candidate(s) would move an unmet benchmark farther from its target.",
        advice_no_scorable_upgrades = "No reliable upgrade is recommended; %d comparison(s) include unparsed use, proc, set, gem, or enchant effects.",
        advice_no_legal_upgrades = "No legal upgrade is recommended; %d candidate(s) conflict with the currently equipped weapon loadout.",
        advice_empty_slot = "Fill empty slot",
        advice_replace = "Estimated +%s score; %s",
        advice_ilvl = "item level %s → %s",
        advice_stats = "matched stats: %s",
        advice_gains = "Gains: %s",
        advice_losses = "Gives up: %s",
        advice_impact = "Benchmark impact: %s",
        advice_evidence = "%s evidence",
        advice_evidence_high = "High",
        advice_evidence_medium = "Medium",
        advice_evidence_low = "Low",
        advice_caveat = "Heuristic score uses visible item stats. Confirm set bonuses, sockets, enchants and proc effects in the tooltip.",
        phase2_title = "Phase 2 Strategy Engine",
        phase2_summary = "%s · %s · database v%s · patch %s",
        phase2_mode_hint = "Choose analysis mode",
        phase2_set_goal = "Set / route goal: %s",
        phase2_caps = "Caps and gates: %s",
        phase2_preset = "Reference set: %s",
        phase2_targets = "Next target items",
        phase2_evidence = "Evidence: %s",
        phase2_talent = "Reference talent string: %s",
        phase2_no_targets = "No missing simulator target items for this role and mode.",
        overview_title = "Overview",
        overview_inventory = "Inventory: %d item lines, %d stacks, %d gear, %d equippable",
        overview_talents = "Talents: %s; selected: %s",
        overview_stats = "Core stats: defense %s, armor %s, melee hit %s, spell hit %s, melee crit %s, best spell crit %s",
        overview_stats_tank = "Tank stats: crit reduction %s/%s%%, armor %s, stamina %s, standing avoidance/block %s",
        overview_stats_melee = "Melee stats: hit %s, expertise %s, crit %s, attack power %s",
        overview_stats_ranged = "Ranged stats: hit %s, crit %s, ranged attack power %s, agility %s",
        overview_stats_caster = "Caster stats: spell hit %s, spell crit %s, spell power %s, intellect %s",
        overview_stats_healer = "Healing stats: bonus healing %s, spell crit %s, casting regen %s, intellect %s",
        overview_categories = "Categories: %s",
        overview_quality = "Quality: %s",
        overview_top_stats = "Top gear stats: %s",
        overview_roles_title = "Top role lenses",
        overview_role = "%s - confidence %s, talent points %s, models %s",
        analysis_title = "Stats Analysis",
        analysis_unknown = "unknown",
        analysis_character = "Character: %s (%s), race %s, %s size %s",
        analysis_talents = "Talents: %s",
        analysis_talent_points = "Talent points: %s; selected talents: %s",
        analysis_defense = "Defense/mitigation: defense %s, armor %s, stamina %s, dodge %s, parry %s, block %s",
        analysis_hit = "Hit model: melee %s, ranged %s, spell %s, expertise %s",
        analysis_crit = "Crit model: melee %s, ranged %s, best spell %s",
        analysis_power = "Power model: attack power %s, ranged AP %s, best spell power %s, healing %s, casting regen %s",
        analysis_race_note = "Race note: %s",
        analysis_group_note = "Group note: %s",
        analysis_roles_title = "Role Strategy",
        analysis_role = "%s - confidence %s, talent points %s",
        analysis_models = "Models: %s",
        analysis_role_hit = "Observed hit/crit: hit melee %s, spell %s; crit melee %s, spell %s",
        analysis_role_hit_melee = "Observed melee: hit %s, expertise %s, crit %s",
        analysis_role_hit_ranged = "Observed ranged: hit %s, crit %s",
        analysis_role_hit_caster = "Observed caster: spell hit %s, spell crit %s",
        analysis_role_tank = "Tank lens: crit reduction %s/%s%%, defense %s, armor %s, standing dodge/parry/block subtotal %s",
        analysis_crit_immunity_breakdown = "Crit reduction sources: talents %s%% + defense %s%% + resilience %s%% (%s rating); remaining gap %s%%.",
        analysis_benchmark = "Benchmark: %s = %s (observed %s; target %s %s)",
        analysis_highlights = "Current gear highlights: %s",
        analysis_no_roles = "No role models available yet. Scan bags or generate an export to refresh the local DB.",
        item_view_empty = "No saved items match this view.",
        export_opened = "%s export opened from local DB: %d bag items, %d bank items. Filter: %s.",
        bags_scanned = "Bags scanned",
        bank_scanned = "Bank scanned",
        bags_label = "Bags",
        bank_label = "Bank",
        scan_summary = "%s: %d items, %d slots via %s, saved to local DB",
        open_bank_hint = "Open your bank and scan again to update bank items.",
        tooltip_left = "Left-click: export saved local DB",
        tooltip_right = "Right-click: scan and save bags/bank",
        help_commands = "Commands: /tbcgear export [scope] [quality|quality+] [ai|json|markdown|text], /tbcgear gear epic, /tbcgear rare+, /tbcgear scan, /tbcgear debug, /tbcgear clear",
        clear_done = "Saved bag and bank snapshots cleared for this character.",
        loaded = "Loaded. %s. Click the minimap bag icon or use /tbcgear gui.",
        debug_bag_open_id = "Debug: bag %s opened; %s.",
        debug_bag_open = "Debug: bag opened; %s.",
        debug_bank_open = "Debug: bank opened; %s.",
    },
    zhCN = {
        addon_title = "TBC 装备导出器",
        summary_initial = "背包：0 件   银行：0 件   范围：全部",
        summary = "背包：%d 件   银行：%d 件   范围：%s   过滤：%s   格式：%s",
        scan_button = "扫描背包",
        export_button = "导出",
        bags_button = "背包",
        bank_button = "银行",
        gear_button = "装备",
        debug_button = "调试",
        select_button = "全选",
        source_label = "来源：",
        local_db_label = "本地数据库",
        overview_tab = "总览",
        gear_advice_tab = "装备建议",
        items_tab = "物品",
        stats_analysis_tab = "属性分析",
        phase2_tab = "P2 攻略",
        text_export_tab = "文本导出",
        generate_button = "生成",
        format_label = "格式：",
        filter_label = "过滤：",
        all_q_button = "全部",
        rare_plus_button = "精良+",
        epic_button = "史诗",
        gear_epic_button = "史诗装备",
        format_ai_title = "AI 文本",
        format_json_title = "JSON",
        format_markdown_title = "Markdown",
        format_text_title = "文本",
        status_ready = "AI 导出文本已选中，按 Ctrl+C 复制。",
        status_selected = "导出文本已选中，按 Ctrl+C 复制。",
        status_generated = "%s 已从本地数据库生成，过滤：%s。按 Ctrl+C 复制。",
        status_visual = "物品图标视图已更新：%d 件。切到文本导出即可复制 AI 数据。",
        status_analysis = "属性分析已更新：%d 个职责模型。切到文本导出即可复制 AI 数据。",
        status_phase2 = "P2 攻略已更新：%s，%s模式。",
        status_overview = "总览已更新：%d 件物品，%d 个职责模型。切到文本导出即可复制 AI 数据。",
        status_advice = "装备建议已更新：%d 条配装结论，职责 %s。",
        advice_title = "装备策略",
        advice_summary = "%s · 已装备 %d 件 · 候选 %d 件 · 职责排除 %d 件 · 配装结论 %d 条",
        advice_verdicts = "结论：%s",
        advice_talent_map = "天赋映射：%s",
        advice_role_hint = "职责视角",
        compare_title = "当前选择的物品对比",
        compare_current = "当前",
        compare_candidate = "候选",
        compare_select_hint = "点击任意建议中的物品图标，可查看完整对比。",
        advice_priorities = "优先属性：%s",
        advice_benchmarks = "关键检查：%s",
        advice_no_gaps = "当前没有待处理的基准检查",
        advice_no_upgrades = "背包和银行中没有值得为此职责进一步比较的候选装备。",
        advice_no_safe_upgrades = "没有可安全推荐的升级；%d 件候选会让尚未达标的属性离目标更远。",
        advice_no_scorable_upgrades = "没有可可靠推荐的升级；%d 项比较包含尚未解析的使用、触发、套装、宝石或附魔效果。",
        advice_no_legal_upgrades = "没有合法的升级建议；%d 件候选与当前武器组合冲突。",
        advice_empty_slot = "填补空栏位",
        advice_replace = "预计评分 +%s；%s",
        advice_ilvl = "物品等级 %s → %s",
        advice_stats = "匹配属性：%s",
        advice_gains = "获得：%s",
        advice_losses = "失去：%s",
        advice_impact = "基准影响：%s",
        advice_evidence = "%s证据",
        advice_evidence_high = "高",
        advice_evidence_medium = "中",
        advice_evidence_low = "低",
        advice_caveat = "启发式评分只使用可见物品属性；套装、宝石、附魔和触发效果请结合提示框确认。",
        phase2_title = "P2 配装策略引擎",
        phase2_summary = "%s · %s · 数据库 v%s · 客户端 %s",
        phase2_mode_hint = "选择分析模式",
        phase2_set_goal = "套装 / 路线目标：%s",
        phase2_caps = "属性阈值与硬门槛：%s",
        phase2_preset = "参考目标套装：%s",
        phase2_targets = "下一批目标物品",
        phase2_evidence = "研究证据：%s",
        phase2_talent = "参考天赋字符串：%s",
        phase2_no_targets = "此职责与模式没有缺失的模拟器目标物品。",
        overview_title = "总览",
        overview_inventory = "库存：%d 条物品，%d 堆叠，%d 件装备，%d 件可装备",
        overview_talents = "天赋：%s；已点：%s",
        overview_stats = "核心属性：防御 %s，护甲 %s，近战命中 %s，法术命中 %s，近战暴击 %s，最佳法术暴击 %s",
        overview_stats_tank = "坦克属性：免暴减免 %s/%s%%，护甲 %s，耐力 %s，常驻躲闪/招架/格挡 %s",
        overview_stats_melee = "近战属性：命中 %s，熟练 %s，暴击 %s，攻强 %s",
        overview_stats_ranged = "远程属性：命中 %s，暴击 %s，远程攻强 %s，敏捷 %s",
        overview_stats_caster = "法系属性：法术命中 %s，法术暴击 %s，法强 %s，智力 %s",
        overview_stats_healer = "治疗属性：治疗加成 %s，法术暴击 %s，施法回蓝 %s，智力 %s",
        overview_categories = "分类：%s",
        overview_quality = "品质：%s",
        overview_top_stats = "装备属性重点：%s",
        overview_roles_title = "主要职责视角",
        overview_role = "%s - 置信度 %s，天赋点 %s，模型 %s",
        analysis_title = "属性分析",
        analysis_unknown = "未知",
        analysis_character = "角色：%s（%s），种族 %s，%s 人数 %s",
        analysis_talents = "天赋：%s",
        analysis_talent_points = "天赋点：%s；已点天赋：%s",
        analysis_defense = "防御/免伤：防御 %s，护甲 %s，耐力 %s，躲闪 %s，招架 %s，格挡 %s",
        analysis_hit = "命中模型：近战 %s，远程 %s，法术 %s，熟练 %s",
        analysis_crit = "暴击模型：近战 %s，远程 %s，最佳法术 %s",
        analysis_power = "强度模型：攻强 %s，远程攻强 %s，最佳法强 %s，治疗 %s，施法回蓝 %s",
        analysis_race_note = "种族提示：%s",
        analysis_group_note = "队伍提示：%s",
        analysis_roles_title = "职责策略",
        analysis_role = "%s - 置信度 %s，天赋点 %s",
        analysis_models = "模型：%s",
        analysis_role_hit = "实测命中/暴击：近战命中 %s，法术命中 %s；近战暴击 %s，法术暴击 %s",
        analysis_role_hit_melee = "实测近战：命中 %s，熟练 %s，暴击 %s",
        analysis_role_hit_ranged = "实测远程：命中 %s，暴击 %s",
        analysis_role_hit_caster = "实测法系：法术命中 %s，法术暴击 %s",
        analysis_role_tank = "坦克视角：免暴减免 %s/%s%%，防御 %s，护甲 %s，常驻躲闪/招架/格挡小计 %s",
        analysis_crit_immunity_breakdown = "免暴来源：天赋 %s%% + 防御 %s%% + 韧性 %s%%（%s 等级）；距离目标还差 %s%%。",
        analysis_benchmark = "基准：%s = %s（实测 %s；目标 %s %s）",
        analysis_highlights = "当前装备属性亮点：%s",
        analysis_no_roles = "还没有可用的职责模型。扫描背包或生成导出以刷新本地数据库。",
        item_view_empty = "没有已保存物品匹配当前视图。",
        export_opened = "%s 已从本地数据库打开：背包 %d 件，银行 %d 件。过滤：%s。",
        bags_scanned = "背包已扫描",
        bank_scanned = "银行已扫描",
        bags_label = "背包",
        bank_label = "银行",
        scan_summary = "%s：%d 件物品，%d 个栏位，使用 %s，已保存到本地数据库",
        open_bank_hint = "打开银行后再次扫描即可更新银行物品。",
        tooltip_left = "左键：导出已保存的本地数据库",
        tooltip_right = "右键：扫描并保存背包/银行",
        help_commands = "命令：/tbcgear export [范围] [品质|品质+] [ai|json|markdown|text]，/tbcgear gear epic，/tbcgear rare+，/tbcgear scan，/tbcgear debug，/tbcgear clear",
        clear_done = "此角色已保存的背包和银行快照已清除。",
        loaded = "已加载。%s。点击小地图背包图标或使用 /tbcgear gui。",
        debug_bag_open_id = "调试：背包 %s 已打开；%s。",
        debug_bag_open = "调试：背包已打开；%s。",
        debug_bank_open = "调试：银行已打开；%s。",
    },
    zhTW = {
        addon_title = "TBC 裝備匯出器",
        summary_initial = "背包：0 件   銀行：0 件   範圍：全部",
        summary = "背包：%d 件   銀行：%d 件   範圍：%s   篩選：%s   格式：%s",
        scan_button = "掃描背包",
        export_button = "匯出",
        bags_button = "背包",
        bank_button = "銀行",
        gear_button = "裝備",
        debug_button = "偵錯",
        select_button = "全選",
        source_label = "來源：",
        local_db_label = "本地資料庫",
        overview_tab = "總覽",
        gear_advice_tab = "裝備建議",
        items_tab = "物品",
        stats_analysis_tab = "屬性分析",
        phase2_tab = "P2 攻略",
        text_export_tab = "文字匯出",
        generate_button = "產生",
        format_label = "格式：",
        filter_label = "篩選：",
        all_q_button = "全部",
        rare_plus_button = "精良+",
        epic_button = "史詩",
        gear_epic_button = "史詩裝備",
        format_ai_title = "AI 文字",
        format_json_title = "JSON",
        format_markdown_title = "Markdown",
        format_text_title = "文字",
        status_ready = "AI 匯出文字已選取，按 Ctrl+C 複製。",
        status_selected = "匯出文字已選取，按 Ctrl+C 複製。",
        status_generated = "%s 已從本地資料庫產生，篩選：%s。按 Ctrl+C 複製。",
        status_visual = "物品圖示檢視已更新：%d 件。切到文字匯出即可複製 AI 資料。",
        status_analysis = "屬性分析已更新：%d 個職責模型。切到文字匯出即可複製 AI 資料。",
        status_phase2 = "P2 攻略已更新：%s，%s模式。",
        status_overview = "總覽已更新：%d 件物品，%d 個職責模型。切到文字匯出即可複製 AI 資料。",
        status_advice = "裝備建議已更新：%d 條配裝結論，職責 %s。",
        advice_title = "裝備策略",
        advice_summary = "%s · 已裝備 %d 件 · 候選 %d 件 · 職責排除 %d 件 · 配裝結論 %d 條",
        advice_verdicts = "結論：%s",
        advice_talent_map = "天賦映射：%s",
        advice_role_hint = "職責視角",
        compare_title = "目前選取的物品比較",
        compare_current = "目前",
        compare_candidate = "候選",
        compare_select_hint = "點擊任一建議中的物品圖示，可查看完整比較。",
        advice_priorities = "優先屬性：%s",
        advice_benchmarks = "關鍵檢查：%s",
        advice_no_gaps = "目前沒有待處理的基準檢查",
        advice_no_upgrades = "背包和銀行中沒有值得為此職責進一步比較的候選裝備。",
        advice_no_safe_upgrades = "沒有可安全推薦的升級；%d 件候選會讓尚未達標的屬性離目標更遠。",
        advice_no_scorable_upgrades = "沒有可可靠推薦的升級；%d 項比較包含尚未解析的使用、觸發、套裝、寶石或附魔效果。",
        advice_no_legal_upgrades = "沒有合法的升級建議；%d 件候選與目前武器組合衝突。",
        advice_empty_slot = "填補空欄位",
        advice_replace = "預估評分 +%s；%s",
        advice_ilvl = "物品等級 %s → %s",
        advice_stats = "匹配屬性：%s",
        advice_gains = "獲得：%s",
        advice_losses = "失去：%s",
        advice_impact = "基準影響：%s",
        advice_evidence = "%s證據",
        advice_evidence_high = "高",
        advice_evidence_medium = "中",
        advice_evidence_low = "低",
        advice_caveat = "啟發式評分只使用可見物品屬性；套裝、寶石、附魔和觸發效果請結合提示框確認。",
        phase2_title = "P2 配裝策略引擎",
        phase2_summary = "%s · %s · 資料庫 v%s · 客戶端 %s",
        phase2_mode_hint = "選擇分析模式",
        phase2_set_goal = "套裝 / 路線目標：%s",
        phase2_caps = "屬性門檻與硬條件：%s",
        phase2_preset = "參考目標套裝：%s",
        phase2_targets = "下一批目標物品",
        phase2_evidence = "研究證據：%s",
        phase2_talent = "參考天賦字串：%s",
        phase2_no_targets = "此職責與模式沒有缺少的模擬器目標物品。",
        overview_title = "總覽",
        overview_inventory = "庫存：%d 條物品，%d 堆疊，%d 件裝備，%d 件可裝備",
        overview_talents = "天賦：%s；已點：%s",
        overview_stats = "核心屬性：防禦 %s，護甲 %s，近戰命中 %s，法術命中 %s，近戰致命 %s，最佳法術致命 %s",
        overview_stats_tank = "坦克屬性：免暴減免 %s/%s%%，護甲 %s，耐力 %s，常駐閃躲/招架/格擋 %s",
        overview_stats_melee = "近戰屬性：命中 %s，熟練 %s，致命 %s，攻強 %s",
        overview_stats_ranged = "遠程屬性：命中 %s，致命 %s，遠程攻強 %s，敏捷 %s",
        overview_stats_caster = "法系屬性：法術命中 %s，法術致命 %s，法強 %s，智力 %s",
        overview_stats_healer = "治療屬性：治療加成 %s，法術致命 %s，施法回魔 %s，智力 %s",
        overview_categories = "分類：%s",
        overview_quality = "品質：%s",
        overview_top_stats = "裝備屬性重點：%s",
        overview_roles_title = "主要職責視角",
        overview_role = "%s - 信心 %s，天賦點 %s，模型 %s",
        analysis_title = "屬性分析",
        analysis_unknown = "未知",
        analysis_character = "角色：%s（%s），種族 %s，%s 人數 %s",
        analysis_talents = "天賦：%s",
        analysis_talent_points = "天賦點：%s；已點天賦：%s",
        analysis_defense = "防禦/減傷：防禦 %s，護甲 %s，耐力 %s，閃躲 %s，招架 %s，格擋 %s",
        analysis_hit = "命中模型：近戰 %s，遠程 %s，法術 %s，熟練 %s",
        analysis_crit = "致命模型：近戰 %s，遠程 %s，最佳法術 %s",
        analysis_power = "強度模型：攻強 %s，遠程攻強 %s，最佳法強 %s，治療 %s，施法回魔 %s",
        analysis_race_note = "種族提示：%s",
        analysis_group_note = "隊伍提示：%s",
        analysis_roles_title = "職責策略",
        analysis_role = "%s - 信心 %s，天賦點 %s",
        analysis_models = "模型：%s",
        analysis_role_hit = "實測命中/致命：近戰命中 %s，法術命中 %s；近戰致命 %s，法術致命 %s",
        analysis_role_hit_melee = "實測近戰：命中 %s，熟練 %s，致命 %s",
        analysis_role_hit_ranged = "實測遠程：命中 %s，致命 %s",
        analysis_role_hit_caster = "實測法系：法術命中 %s，法術致命 %s",
        analysis_role_tank = "坦克視角：免暴減免 %s/%s%%，防禦 %s，護甲 %s，常駐閃躲/招架/格擋小計 %s",
        analysis_crit_immunity_breakdown = "免暴來源：天賦 %s%% + 防禦 %s%% + 韌性 %s%%（%s 等級）；距離目標還差 %s%%。",
        analysis_benchmark = "基準：%s = %s（實測 %s；目標 %s %s）",
        analysis_highlights = "目前裝備屬性亮點：%s",
        analysis_no_roles = "還沒有可用的職責模型。掃描背包或產生匯出以重新整理本地資料庫。",
        item_view_empty = "沒有已儲存物品符合目前檢視。",
        export_opened = "%s 已從本地資料庫開啟：背包 %d 件，銀行 %d 件。篩選：%s。",
        bags_scanned = "背包已掃描",
        bank_scanned = "銀行已掃描",
        bags_label = "背包",
        bank_label = "銀行",
        scan_summary = "%s：%d 件物品，%d 個欄位，使用 %s，已儲存到本地資料庫",
        open_bank_hint = "打開銀行後再次掃描即可更新銀行物品。",
        tooltip_left = "左鍵：匯出已儲存的本地資料庫",
        tooltip_right = "右鍵：掃描並儲存背包/銀行",
        help_commands = "命令：/tbcgear export [範圍] [品質|品質+] [ai|json|markdown|text]，/tbcgear gear epic，/tbcgear rare+，/tbcgear scan，/tbcgear debug，/tbcgear clear",
        clear_done = "此角色已儲存的背包和銀行快照已清除。",
        loaded = "已載入。%s。點擊小地圖背包圖示或使用 /tbcgear gui。",
        debug_bag_open_id = "偵錯：背包 %s 已開啟；%s。",
        debug_bag_open = "偵錯：背包已開啟；%s。",
        debug_bank_open = "偵錯：銀行已開啟；%s。",
    },
}

GEAR_ENGINE.REPORT_TERMS = {
    enUS = {
        human_note = "Readable strategy report. Use AI Text or JSON for the complete machine-readable dataset.",
        quick_summary = "Quick Summary", field = "Field", value = "Value", character = "Character", class = "Class",
        scope_filter = "Scope / filter", items = "Candidate inventory", talents = "Talents", selected_talents = "Selected talents",
        top_role = "Primary role", core_stats = "Live core stats", categories = "Categories", top_stats = "Candidate stat totals",
        role_snapshot = "Role Snapshot", role = "Role", confidence = "Confidence", talent_points = "Talent points",
        models = "Models", current_highlights = "Current gear highlights", gear_recommendations = "Gear Recommendations",
        phase2_strategy = "Phase 2 Strategy", mode = "Strategy mode", set_goal = "Set / route goal", target_preset = "Reference gear set",
        target_progress = "Saved progress", missing_targets = "Next target items", caps = "Caps and gates", research_evidence = "Research evidence",
        sources = "Sources", no_preset = "No simulator preset; use the class guide and the current stat model.",
        priority_stats = "Priority stats", benchmark_gaps = "Key benchmark checks", caveat = "Limit",
        slot = "Slot", current = "Current", suggested = "Candidate", score = "Score", evidence = "Evidence", verdict = "Decision",
        gains = "Gains", losses = "Gives up", high = "High", medium = "Medium", low = "Low",
        verdict_upgrade = "Clear upgrade", verdict_minor = "Small improvement", verdict_tradeoff = "Tradeoff", verdict_review = "Manual check", verdict_incompatible = "Different slot", verdict_loadout_mismatch = "Illegal weapon loadout", verdict_unscorable = "Effects not quantifiable", verdict_role_mismatch = "Wrong stats for role",
        verdict_summary = "%d clear · %d small · %d tradeoff · %d manual",
        talent_map = "Talent mapping", talent_map_summary = "%d/%d selected mapped · %d aligned points · key effects: %s", no_key_effects = "none",
        benchmark_impact = "Benchmark impact", impact_helps_gap = "moves toward target", impact_worsens_gap = "moves away from target",
        impact_cap_buffer = "adds buffer above target", impact_cap_risk = "recheck target after equipping",
        impact_context_help = "improves the visible subtotal", impact_context_risk = "reduces the visible subtotal",
        no_benchmark_impact = "no tracked benchmark change",
        ai_prompt = "AI Analysis Prompt", details = "Detailed character, strategy, and inventory statistics",
        export_metadata = "Export Metadata", client_locale = "Client locale", local_db = "Local DB",
        scope = "Scope", filter = "Filter", bag_scan = "Bag scan", bank_scan = "Bank scan", equipped_scan = "Equipped scan",
        stats_analysis = "Stats Analysis", inventory_stats = "Candidate Inventory Statistics", current_equipment = "Current Equipment", item_tables = "Candidate Items",
        item = "Item", quality = "Quality", item_level = "iLvl", source = "Source", location = "Location", stats = "Stats",
        item_lines = "item lines", stacks = "stacks", gear = "gear", equippable = "equippable",
        item_level_summary = "Item level: min %s, max %s, average %s across %s items",
        source_counts = "Source counts", category_counts = "Category counts", quality_counts = "Quality counts",
        slot_counts = "Equipment slot counts", stat_totals = "Stat totals", none = "none",
        no_items = "No saved items are available. Scan bags, and scan again while the bank is open.",
        more = "+%d more", equipped_count = "%d equipped", candidate_count = "%d candidates", upgrade_count = "%d suggestions",
        bags = "Bags", bank = "Bank", equipped = "Equipped", unknown = "Unknown", unknown_location = "Unknown location",
        backpack_slot = "Backpack slot %s", bag_slot = "Bag %s slot %s", bank_slot = "Bank slot %s", bank_bag_slot = "Bank bag %s slot %s",
        categories_map = { Equipped = "Current Equipment", Gear = "Gear", Consumables = "Consumables", ["Trade Goods"] = "Trade Goods", Gems = "Gems", Enhancements = "Enhancements", Recipes = "Recipes", Reagents = "Reagents", ["Quest Items"] = "Quest Items", Containers = "Containers", Keys = "Keys", Projectiles = "Projectiles", Currency = "Currency", Permanent = "Permanent", Miscellaneous = "Miscellaneous", Other = "Other" },
    },
    zhCN = {
        human_note = "便于阅读的配装策略报告；需要完整机器数据时请选择 AI 文本或 JSON。",
        quick_summary = "角色概览", field = "项目", value = "当前结果", character = "角色", class = "职业",
        scope_filter = "范围 / 过滤", items = "候选库存", talents = "天赋", selected_talents = "已点天赋",
        top_role = "主要职责", core_stats = "实时核心属性", categories = "物品分类", top_stats = "候选库存属性合计",
        role_snapshot = "职责判断", role = "职责", confidence = "置信度", talent_points = "天赋点",
        models = "分析模型", current_highlights = "当前装备属性重点", gear_recommendations = "换装建议",
        phase2_strategy = "P2 配装攻略", mode = "策略模式", set_goal = "套装 / 路线目标", target_preset = "参考目标套装",
        target_progress = "本地收集进度", missing_targets = "下一批目标物品", caps = "属性阈值与硬门槛", research_evidence = "研究证据",
        sources = "资料来源", no_preset = "该专精暂无成熟模拟器预设；使用职业攻略与当前属性模型。",
        priority_stats = "优先属性", benchmark_gaps = "关键基准检查", caveat = "分析限制",
        slot = "栏位", current = "当前装备", suggested = "候选装备", score = "评分变化", evidence = "证据", verdict = "结论",
        gains = "获得", losses = "失去", high = "高", medium = "中", low = "低",
        verdict_upgrade = "明确升级", verdict_minor = "小幅提升", verdict_tradeoff = "有取舍", verdict_review = "需手动核对", verdict_incompatible = "栏位不同", verdict_loadout_mismatch = "武器组合不合法", verdict_unscorable = "效果无法量化", verdict_role_mismatch = "属性方向不符",
        verdict_summary = "明确 %d · 小幅 %d · 有取舍 %d · 需核对 %d",
        talent_map = "天赋映射", talent_map_summary = "已映射 %d/%d 个已点天赋 · 本职责 %d 点 · 关键效果：%s", no_key_effects = "无",
        benchmark_impact = "基准影响", impact_helps_gap = "向目标靠近", impact_worsens_gap = "离目标更远",
        impact_cap_buffer = "增加达标余量", impact_cap_risk = "换装后需重新核对是否达标",
        impact_context_help = "提高可见常驻小计", impact_context_risk = "降低可见常驻小计",
        no_benchmark_impact = "不改变已跟踪基准",
        ai_prompt = "AI 分析指令", details = "角色、策略与候选库存详细数据",
        export_metadata = "导出信息", client_locale = "客户端语言", local_db = "本地数据库",
        scope = "范围", filter = "过滤", bag_scan = "背包扫描", bank_scan = "银行扫描", equipped_scan = "当前装备扫描",
        stats_analysis = "属性分析", inventory_stats = "候选库存统计", current_equipment = "当前装备", item_tables = "候选物品",
        item = "物品", quality = "品质", item_level = "物品等级", source = "来源", location = "位置", stats = "属性",
        item_lines = "条物品", stacks = "件总数", gear = "件装备", equippable = "件可装备",
        item_level_summary = "物品等级：最低 %s，最高 %s，平均 %s（%s 件）",
        source_counts = "来源统计", category_counts = "分类统计", quality_counts = "品质统计",
        slot_counts = "装备栏位统计", stat_totals = "属性合计", none = "无",
        no_items = "没有已保存物品。请扫描背包，并在银行打开时再次扫描。",
        more = "另 %d 项", equipped_count = "已装备 %d 件", candidate_count = "候选 %d 件", upgrade_count = "建议 %d 条",
        bags = "背包", bank = "银行", equipped = "当前装备", unknown = "未知", unknown_location = "未知位置",
        backpack_slot = "背包第 %s 格", bag_slot = "%s 号背包第 %s 格", bank_slot = "银行第 %s 格", bank_bag_slot = "银行背包 %s 第 %s 格",
        categories_map = { Equipped = "当前装备", Gear = "装备", Consumables = "消耗品", ["Trade Goods"] = "材料", Gems = "宝石", Enhancements = "强化物品", Recipes = "配方", Reagents = "施法材料", ["Quest Items"] = "任务物品", Containers = "容器", Keys = "钥匙", Projectiles = "弹药", Currency = "货币", Permanent = "永久物品", Miscellaneous = "杂项", Other = "其他" },
    },
    zhTW = {
        human_note = "便於閱讀的配裝策略報告；需要完整機器資料時請選擇 AI 文字或 JSON。",
        quick_summary = "角色概覽", field = "項目", value = "目前結果", character = "角色", class = "職業",
        scope_filter = "範圍 / 篩選", items = "候選庫存", talents = "天賦", selected_talents = "已點天賦",
        top_role = "主要職責", core_stats = "即時核心屬性", categories = "物品分類", top_stats = "候選庫存屬性合計",
        role_snapshot = "職責判斷", role = "職責", confidence = "信心", talent_points = "天賦點",
        models = "分析模型", current_highlights = "目前裝備屬性重點", gear_recommendations = "換裝建議",
        phase2_strategy = "P2 配裝攻略", mode = "策略模式", set_goal = "套裝 / 路線目標", target_preset = "參考目標套裝",
        target_progress = "本地收集進度", missing_targets = "下一批目標物品", caps = "屬性門檻與硬條件", research_evidence = "研究證據",
        sources = "資料來源", no_preset = "該專精暫無成熟模擬器預設；使用職業攻略與目前屬性模型。",
        priority_stats = "優先屬性", benchmark_gaps = "關鍵基準檢查", caveat = "分析限制",
        slot = "欄位", current = "目前裝備", suggested = "候選裝備", score = "評分變化", evidence = "證據", verdict = "結論",
        gains = "獲得", losses = "失去", high = "高", medium = "中", low = "低",
        verdict_upgrade = "明確升級", verdict_minor = "小幅提升", verdict_tradeoff = "有取捨", verdict_review = "需手動核對", verdict_incompatible = "欄位不同", verdict_loadout_mismatch = "武器組合不合法", verdict_unscorable = "效果無法量化", verdict_role_mismatch = "屬性方向不符",
        verdict_summary = "明確 %d · 小幅 %d · 有取捨 %d · 需核對 %d",
        talent_map = "天賦映射", talent_map_summary = "已映射 %d/%d 個已點天賦 · 本職責 %d 點 · 關鍵效果：%s", no_key_effects = "無",
        benchmark_impact = "基準影響", impact_helps_gap = "向目標靠近", impact_worsens_gap = "離目標更遠",
        impact_cap_buffer = "增加達標餘量", impact_cap_risk = "換裝後需重新核對是否達標",
        impact_context_help = "提高可見常駐小計", impact_context_risk = "降低可見常駐小計",
        no_benchmark_impact = "不改變已追蹤基準",
        ai_prompt = "AI 分析指令", details = "角色、策略與候選庫存詳細資料",
        export_metadata = "匯出資訊", client_locale = "客戶端語言", local_db = "本地資料庫",
        scope = "範圍", filter = "篩選", bag_scan = "背包掃描", bank_scan = "銀行掃描", equipped_scan = "目前裝備掃描",
        stats_analysis = "屬性分析", inventory_stats = "候選庫存統計", current_equipment = "目前裝備", item_tables = "候選物品",
        item = "物品", quality = "品質", item_level = "物品等級", source = "來源", location = "位置", stats = "屬性",
        item_lines = "筆物品", stacks = "件總數", gear = "件裝備", equippable = "件可裝備",
        item_level_summary = "物品等級：最低 %s，最高 %s，平均 %s（%s 件）",
        source_counts = "來源統計", category_counts = "分類統計", quality_counts = "品質統計",
        slot_counts = "裝備欄位統計", stat_totals = "屬性合計", none = "無",
        no_items = "沒有已儲存物品。請掃描背包，並在銀行開啟時再次掃描。",
        more = "另 %d 項", equipped_count = "已裝備 %d 件", candidate_count = "候選 %d 件", upgrade_count = "建議 %d 條",
        bags = "背包", bank = "銀行", equipped = "目前裝備", unknown = "未知", unknown_location = "未知位置",
        backpack_slot = "背包第 %s 格", bag_slot = "%s 號背包第 %s 格", bank_slot = "銀行第 %s 格", bank_bag_slot = "銀行背包 %s 第 %s 格",
        categories_map = { Equipped = "目前裝備", Gear = "裝備", Consumables = "消耗品", ["Trade Goods"] = "材料", Gems = "寶石", Enhancements = "強化物品", Recipes = "配方", Reagents = "施法材料", ["Quest Items"] = "任務物品", Containers = "容器", Keys = "鑰匙", Projectiles = "彈藥", Currency = "貨幣", Permanent = "永久物品", Miscellaneous = "雜項", Other = "其他" },
    },
}

function GEAR_ENGINE.ReportTerms(locale)
    locale = locale == "zhCN" and "zhCN" or (locale == "zhTW" and "zhTW" or "enUS")
    return GEAR_ENGINE.REPORT_TERMS[locale]
end

function GEAR_ENGINE.CategoryLabel(category, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    return terms.categories_map[category] or tostring(category or terms.none)
end

local STAT_LABELS = {
    ITEM_MOD_MANA = "Mana",
    ITEM_MOD_HEALTH = "Health",
    ITEM_MOD_STRENGTH_SHORT = "Strength",
    ITEM_MOD_AGILITY_SHORT = "Agility",
    ITEM_MOD_STAMINA_SHORT = "Stamina",
    ITEM_MOD_INTELLECT_SHORT = "Intellect",
    ITEM_MOD_SPIRIT_SHORT = "Spirit",
    ITEM_MOD_ARMOR = "Armor",
    ITEM_MOD_BONUS_ARMOR_SHORT = "Bonus Armor",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense Rating",
    ITEM_MOD_DODGE_RATING_SHORT = "Dodge Rating",
    ITEM_MOD_PARRY_RATING_SHORT = "Parry Rating",
    ITEM_MOD_BLOCK_RATING_SHORT = "Block Rating",
    ITEM_MOD_HIT_MELEE_RATING_SHORT = "Melee Hit Rating",
    ITEM_MOD_HIT_RANGED_RATING_SHORT = "Ranged Hit Rating",
    ITEM_MOD_HIT_SPELL_RATING_SHORT = "Spell Hit Rating",
    ITEM_MOD_CRIT_MELEE_RATING_SHORT = "Melee Crit Rating",
    ITEM_MOD_CRIT_RANGED_RATING_SHORT = "Ranged Crit Rating",
    ITEM_MOD_CRIT_SPELL_RATING_SHORT = "Spell Crit Rating",
    ITEM_MOD_HASTE_MELEE_RATING_SHORT = "Melee Haste Rating",
    ITEM_MOD_HASTE_RANGED_RATING_SHORT = "Ranged Haste Rating",
    ITEM_MOD_HASTE_SPELL_RATING_SHORT = "Spell Haste Rating",
    ITEM_MOD_HIT_RATING_SHORT = "Hit Rating",
    ITEM_MOD_CRIT_RATING_SHORT = "Crit Rating",
    ITEM_MOD_HASTE_RATING_SHORT = "Haste Rating",
    ITEM_MOD_RESILIENCE_RATING_SHORT = "Resilience Rating",
    ITEM_MOD_EXPERTISE_RATING_SHORT = "Expertise Rating",
    ITEM_MOD_ATTACK_POWER_SHORT = "Attack Power",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Ranged Attack Power",
    ITEM_MOD_FERAL_ATTACK_POWER_SHORT = "Feral Attack Power",
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "Damage per Second",
    ITEM_MOD_SPELL_POWER_SHORT = "Spell Power",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "Spell Damage",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "Healing",
    ITEM_MOD_MANA_REGENERATION_SHORT = "Mana Regen",
    ITEM_MOD_HEALTH_REGEN_SHORT = "Health Regen",
    ITEM_MOD_BLOCK_VALUE_SHORT = "Block Value",
    RESISTANCE0_NAME = "Armor",
    RESISTANCE1_NAME = "Holy Resistance",
    RESISTANCE2_NAME = "Fire Resistance",
    RESISTANCE3_NAME = "Nature Resistance",
    RESISTANCE4_NAME = "Frost Resistance",
    RESISTANCE5_NAME = "Shadow Resistance",
    RESISTANCE6_NAME = "Arcane Resistance",
    EMPTY_SOCKET_BLUE = "Blue Socket",
    EMPTY_SOCKET_RED = "Red Socket",
    EMPTY_SOCKET_YELLOW = "Yellow Socket",
    EMPTY_SOCKET_META = "Meta Socket",
}

local STAT_ORDER = {
    "ITEM_MOD_STRENGTH_SHORT",
    "ITEM_MOD_AGILITY_SHORT",
    "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_INTELLECT_SHORT",
    "ITEM_MOD_SPIRIT_SHORT",
    "ITEM_MOD_ARMOR",
    "ITEM_MOD_BONUS_ARMOR_SHORT",
    "RESISTANCE1_NAME",
    "RESISTANCE2_NAME",
    "RESISTANCE3_NAME",
    "RESISTANCE4_NAME",
    "RESISTANCE5_NAME",
    "RESISTANCE6_NAME",
    "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
    "ITEM_MOD_DODGE_RATING_SHORT",
    "ITEM_MOD_PARRY_RATING_SHORT",
    "ITEM_MOD_BLOCK_RATING_SHORT",
    "ITEM_MOD_BLOCK_VALUE_SHORT",
    "ITEM_MOD_RESILIENCE_RATING_SHORT",
    "ITEM_MOD_HIT_RATING_SHORT",
    "ITEM_MOD_HIT_MELEE_RATING_SHORT",
    "ITEM_MOD_HIT_RANGED_RATING_SHORT",
    "ITEM_MOD_HIT_SPELL_RATING_SHORT",
    "ITEM_MOD_CRIT_RATING_SHORT",
    "ITEM_MOD_CRIT_MELEE_RATING_SHORT",
    "ITEM_MOD_CRIT_RANGED_RATING_SHORT",
    "ITEM_MOD_CRIT_SPELL_RATING_SHORT",
    "ITEM_MOD_HASTE_RATING_SHORT",
    "ITEM_MOD_HASTE_MELEE_RATING_SHORT",
    "ITEM_MOD_HASTE_RANGED_RATING_SHORT",
    "ITEM_MOD_HASTE_SPELL_RATING_SHORT",
    "ITEM_MOD_EXPERTISE_RATING_SHORT",
    "ITEM_MOD_ATTACK_POWER_SHORT",
    "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    "ITEM_MOD_FERAL_ATTACK_POWER_SHORT",
    "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
    "ITEM_MOD_SPELL_POWER_SHORT",
    "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
    "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
    "ITEM_MOD_MANA_REGENERATION_SHORT",
    "ITEM_MOD_HEALTH_REGEN_SHORT",
    "EMPTY_SOCKET_META",
    "EMPTY_SOCKET_RED",
    "EMPTY_SOCKET_YELLOW",
    "EMPTY_SOCKET_BLUE",
}

local STAT_ORDER_INDEX = {}
for index = 1, #STAT_ORDER do
    STAT_ORDER_INDEX[STAT_ORDER[index]] = index
end

local function SafeRegister(eventName)
    pcall(frame.RegisterEvent, frame, eventName)
end

local function SetFrameSize(target, width, height)
    if target.SetSize then
        target:SetSize(width, height)
    else
        target:SetWidth(width)
        target:SetHeight(height)
    end
end

local function BackdropTemplate()
    if BackdropTemplateMixin then
        return "BackdropTemplate"
    end

    return nil
end

local function HasCContainer()
    return C_Container
        and type(C_Container.GetContainerNumSlots) == "function"
        and type(C_Container.GetContainerItemInfo) == "function"
end

local function HasLegacyContainer()
    return type(GetContainerNumSlots) == "function"
        and type(GetContainerItemInfo) == "function"
end

local function ContainerApiName()
    if HasCContainer() then
        return "C_Container"
    end

    if HasLegacyContainer() then
        return "legacy"
    end

    return "none"
end

local function YesNo(value)
    return value and "yes" or "no"
end

local function GetContainerNumSlotsCompat(bagID)
    if C_Container and type(C_Container.GetContainerNumSlots) == "function" then
        local ok, slots = pcall(C_Container.GetContainerNumSlots, bagID)
        if ok and type(slots) == "number" and slots > 0 then
            return slots
        end
    end

    if type(GetContainerNumSlots) == "function" then
        local ok, slots = pcall(GetContainerNumSlots, bagID)
        if ok and type(slots) == "number" then
            return slots
        end
    end

    return 0
end

local function GetContainerItemLinkCompat(bagID, slotID)
    if C_Container and type(C_Container.GetContainerItemLink) == "function" then
        local ok, link = pcall(C_Container.GetContainerItemLink, bagID, slotID)
        if ok and link then
            return link
        end
    end

    if type(GetContainerItemLink) == "function" then
        local ok, link = pcall(GetContainerItemLink, bagID, slotID)
        if ok and link then
            return link
        end
    end

    return nil
end

local function ValuesFromContainerInfo(info, fallbackLink)
    local link = info.hyperlink or info.link or fallbackLink
    if not link and info.itemID then
        link = "item:" .. tostring(info.itemID)
    end

    return info.iconFileID or info.texture or info.icon,
        info.stackCount or info.count,
        info.quality or info.itemQuality,
        link
end

local function Trim(value)
    return (value or ""):match("^%s*(.-)%s*$")
end

local function Now()
    if type(GetServerTime) == "function" then
        return GetServerTime()
    end

    if type(time) == "function" then
        return time()
    end

    return 0
end

local function FormatTime(timestamp)
    if not timestamp or timestamp == 0 then
        return "never"
    end

    if type(date) == "function" then
        return date("%Y-%m-%d %H:%M:%S", timestamp)
    end

    return tostring(timestamp)
end

local function ParseItemID(link)
    if not link then
        return nil
    end

    local itemID = link:match("item:(%d+)")
    return itemID and tonumber(itemID) or nil
end

local function WowheadItemURL(itemID)
    if type(itemID) == "string" then
        itemID = tonumber(itemID:match("^%d+$"))
    end

    if type(itemID) == "number" and itemID > 0 then
        return WOWHEAD_TBC_ITEM_URL_PREFIX .. tostring(itemID)
    end

    return nil
end

local function ItemWowheadURL(item)
    if not item then
        return nil
    end

    return item.wowheadUrl or item.wowhead_url or WowheadItemURL(item.itemID or item.item_id)
end

local function ParseItemString(link)
    if not link then
        return nil
    end

    return link:match("|H(item:[^|]+)|h")
end

local function ParseItemName(link)
    if not link then
        return nil
    end

    return link:match("%[(.-)%]")
end

local function NormalizeQualityColorHex(color)
    if not color then
        return nil
    end

    color = tostring(color)

    if color:sub(1, 4):lower() == "|cff" then
        color = color:sub(5)
    end

    color = color:gsub("^#", "")
    color = color:gsub("|r$", "")

    if #color == 8 and color:match("^%x+$") then
        color = color:sub(3)
    end

    if #color == 6 and color:match("^%x+$") then
        return "#" .. color:upper()
    end

    return nil
end

local function ColorChannelToByte(channel)
    if type(channel) ~= "number" then
        return nil
    end

    channel = math.floor((channel * 255) + 0.5)

    if channel < 0 then
        return 0
    end

    if channel > 255 then
        return 255
    end

    return channel
end

local function QualityColorHex(quality)
    local qualityColor = _G and _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[quality]

    if type(qualityColor) == "table" then
        local normalized = NormalizeQualityColorHex(qualityColor.hex)
        if normalized then
            return normalized
        end

        local red = ColorChannelToByte(qualityColor.r)
        local green = ColorChannelToByte(qualityColor.g)
        local blue = ColorChannelToByte(qualityColor.b)

        if red and green and blue then
            return string.format("#%02X%02X%02X", red, green, blue)
        end
    elseif type(qualityColor) == "string" then
        local normalized = NormalizeQualityColorHex(qualityColor)
        if normalized then
            return normalized
        end
    end

    return NormalizeQualityColorHex(QUALITY_COLOR_HEX[quality])
end

local function ParseItemLinkColorHex(link)
    if not link then
        return nil
    end

    return NormalizeQualityColorHex(tostring(link):match("|c(%x%x%x%x%x%x%x%x)"))
end

local function ItemQualityColorHex(item)
    if not item then
        return nil
    end

    return NormalizeQualityColorHex(item.qualityColor or item.quality_color)
        or QualityColorHex(item.quality or item.quality_id)
        or ParseItemLinkColorHex(item.link or item.item_link)
end

local function ColorizeItemName(name, colorHex)
    local normalized = NormalizeQualityColorHex(colorHex)
    name = tostring(name or "Unknown Item")

    if normalized then
        return "|cff" .. normalized:sub(2):lower() .. name .. "|r"
    end

    return name
end

local function ItemColoredName(item)
    if not item then
        return ColorizeItemName(nil, nil)
    end

    return item.nameColored or item.name_colored or ColorizeItemName(item.name or "Unknown Item", ItemQualityColorHex(item))
end

local HTML_ESCAPE_CHARS = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ["\""] = "&quot;",
}

local function HtmlEscape(value)
    return tostring(value or ""):gsub("[&<>\"]", HTML_ESCAPE_CHARS)
end

local function MarkdownItemName(item)
    local name = item and item.name or "Unknown Item"
    local colorHex = ItemQualityColorHex(item)

    if colorHex then
        return "<span style=\"color:" .. colorHex .. "\"><strong>" .. HtmlEscape(name) .. "</strong></span>"
    end

    return "**" .. tostring(name) .. "**"
end

local function QualityDisplay(item)
    local label = tostring(item and item.qualityName or "Unknown")
    local colorHex = ItemQualityColorHex(item)

    if colorHex then
        return label .. " (" .. colorHex .. ")"
    end

    return label
end

local function ItemLevelDisplay(item)
    if item and item.itemLevel then
        return tostring(item.itemLevel)
    end

    return "unknown"
end

local function ItemTypeDisplay(item)
    local itemType = item and item.itemType or "Unknown"
    local itemSubType = item and item.itemSubType

    if itemSubType and itemSubType ~= "" then
        return tostring(itemType) .. " / " .. tostring(itemSubType)
    end

    return tostring(itemType)
end

local function QualityName(quality)
    if quality and _G then
        local localized = _G["ITEM_QUALITY" .. quality .. "_DESC"]
        if localized then
            return localized
        end
    end

    return QUALITY_LABELS[quality] or "Unknown"
end

local function LocalizedQualityName(quality, locale)
    local qualityID
    if type(quality) == "number" then
        qualityID = quality
    elseif type(quality) == "string" then
        local normalized = Trim(quality):lower()
        qualityID = tonumber(normalized) or QUALITY_ALIASES[normalized]
    end
    locale = PromptLocale(locale)

    if locale == "zhCN" then
        return ({
            [0] = "粗糙",
            [1] = "普通",
            [2] = "优秀",
            [3] = "精良",
            [4] = "史诗",
            [5] = "传说",
            [6] = "神器",
            [7] = "传家宝",
        })[qualityID] or "未知"
    end

    if locale == "zhTW" then
        return ({
            [0] = "粗糙",
            [1] = "普通",
            [2] = "優秀",
            [3] = "精良",
            [4] = "史詩",
            [5] = "傳說",
            [6] = "神器",
            [7] = "傳家寶",
        })[qualityID] or "未知"
    end

    return QualityName(qualityID)
end

local function TitleCase(value)
    return tostring(value or ""):lower():gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest
    end)
end

local function CleanStatLabel(label)
    label = tostring(label or "")
    label = label:gsub("%%d", "")
    label = label:gsub("%%s", "")
    label = label:gsub("%+", "")
    label = label:gsub("^%s+", "")
    label = label:gsub("%s+$", "")
    return label
end

local function StatLabel(statToken)
    local normalized = GEAR_ENGINE.NormalizeStatToken(statToken)
    if STAT_LABELS[normalized] then
        return STAT_LABELS[normalized]
    end

    if _G and _G[statToken] then
        local localized = CleanStatLabel(_G[statToken])
        if localized ~= "" then
            return localized
        end
    end

    if type(GetItemStatInfo) == "function" then
        local ok, statName = pcall(GetItemStatInfo, statToken)
        if ok and type(statName) == "string" then
            statName = CleanStatLabel(statName)
            if statName ~= "" then
                return statName
            end
        end
    end

    local fallback = tostring(statToken or "Unknown Stat")
    fallback = fallback:gsub("^ITEM_MOD_", "")
    fallback = fallback:gsub("_SHORT$", "")
    fallback = fallback:gsub("_RATING$", " Rating")
    fallback = fallback:gsub("_NAME$", "")
    fallback = fallback:gsub("_", " ")
    return TitleCase(fallback)
end

local function BuildStatList(link)
    local stats = {}

    if not link or type(GetItemStats) ~= "function" then
        return stats
    end

    local rawStats = {}
    local ok, result = pcall(GetItemStats, link, rawStats)

    if not ok then
        return stats
    end

    if type(result) == "table" then
        rawStats = result
    end

    for statToken, value in pairs(rawStats) do
        if value and value ~= 0 then
            stats[#stats + 1] = {
                token = statToken,
                label = StatLabel(statToken),
                value = value,
            }
        end
    end

    table.sort(stats, function(left, right)
        local leftRank = STAT_ORDER_INDEX[left.token] or 1000
        local rightRank = STAT_ORDER_INDEX[right.token] or 1000

        if leftRank ~= rightRank then
            return leftRank < rightRank
        end

        return (left.label or left.token or "") < (right.label or right.token or "")
    end)

    return stats
end

local function CompactNumber(value, decimals)
    if type(value) ~= "number" then
        return tostring(value)
    end

    if value ~= value or value == math.huge or value == -math.huge then
        return tostring(value)
    end

    decimals = decimals or 2
    local text

    if math.floor(value) == value then
        text = tostring(value)
    else
        text = string.format("%." .. tostring(decimals) .. "f", value)
        text = text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
    end

    if text == "-0" then
        return "0"
    end

    return text
end

function GEAR_ENGINE.LocalizedStatLabel(stat, locale)
    local localized = ANALYSIS_LOCALIZATION[locale == "zhCN" and "zhCN" or (locale == "zhTW" and "zhTW" or "enUS")]
    local token = GEAR_ENGINE.NormalizeStatToken(stat and stat.token)
    return localized and localized.stats and localized.stats[token]
        or stat and (stat.label or StatLabel(stat.token))
        or "Unknown Stat"
end

function GEAR_ENGINE.FormatLocalizedStats(stats, locale, maxCount)
    if not stats or #stats == 0 then
        return GEAR_ENGINE.ReportTerms(locale).none
    end

    local parts = {}
    local count = math.min(#stats, maxCount or #stats)
    for index = 1, count do
        local stat = stats[index]
        local value = tonumber(stat and stat.value) or 0
        local label = GEAR_ENGINE.LocalizedStatLabel(stat, locale)
        if tostring(stat and stat.token or ""):find("EMPTY_SOCKET", 1, true) then
            parts[#parts + 1] = value == 1 and label or (CompactNumber(value, 2) .. " " .. label)
        else
            local prefix = value < 0 and "" or "+"
            parts[#parts + 1] = prefix .. CompactNumber(value, 2) .. " " .. label
        end
    end
    if #stats > count then
        parts[#parts + 1] = string.format(GEAR_ENGINE.ReportTerms(locale).more, #stats - count)
    end
    return table.concat(parts, ", ")
end

function GEAR_ENGINE.DeltaText(entries, locale)
    return GEAR_ENGINE.FormatLocalizedStats(entries, locale, 3)
end

function GEAR_ENGINE.EvidenceLabel(evidence, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    return terms[evidence or "low"] or terms.low
end

function GEAR_ENGINE.RecommendationVerdictLabel(verdict, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    return terms["verdict_" .. tostring(verdict or "review")] or terms.verdict_review
end

function GEAR_ENGINE.VerdictSummary(engine, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    local counts = engine and engine.verdictCounts or GEAR_ENGINE.VerdictCounts(engine and engine.upgrades)
    return string.format(terms.verdict_summary, counts.upgrade or 0, counts.minor or 0, counts.tradeoff or 0, counts.review or 0)
end

function GEAR_ENGINE.BenchmarkImpactText(impacts, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    local localized = ANALYSIS_LOCALIZATION[PromptLocale(locale or ClientLocale())]
    local parts = {}
    for index = 1, math.min(#(impacts or {}), 2) do
        local impact = impacts[index]
        local label = localized and localized.benchmarks and localized.benchmarks[impact.key] or impact.label or impact.key
        local delta = tonumber(impact.delta) or 0
        local signedDelta = delta > 0 and ("+" .. CompactNumber(delta, 2)) or CompactNumber(delta, 2)
        if tostring(impact.unit or ""):find("%", 1, true) then
            signedDelta = signedDelta .. "%"
        end
        parts[#parts + 1] = tostring(label) .. " " .. signedDelta .. " (" .. tostring(terms["impact_" .. tostring(impact.effect)] or impact.effect) .. ")"
    end
    return #parts > 0 and table.concat(parts, "; ") or terms.no_benchmark_impact
end

function GEAR_ENGINE.TalentEffectLabel(effect, locale)
    local promptLocale = PromptLocale(locale or ClientLocale())
    return effect and effect.labels and (effect.labels[promptLocale] or effect.labels.enUS) or effect and effect.name or ""
end

function GEAR_ENGINE.TalentMapSummary(talentMap, locale, maxEffects)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    local effects = {}
    maxEffects = maxEffects or 4
    for index = 1, math.min(#(talentMap and talentMap.effects or {}), maxEffects) do
        effects[#effects + 1] = GEAR_ENGINE.TalentEffectLabel(talentMap.effects[index], locale)
    end
    if #(talentMap and talentMap.effects or {}) > maxEffects then
        effects[#effects + 1] = string.format(terms.more, #(talentMap.effects or {}) - maxEffects)
    end
    local effectText = #effects > 0 and table.concat(effects, ", ") or terms.no_key_effects
    return string.format(terms.talent_map_summary,
        talentMap and talentMap.mappedCount or 0,
        talentMap and talentMap.selectedCount or 0,
        talentMap and talentMap.alignedPoints or 0,
        effectText)
end

local function FormatStats(stats)
    if not stats or #stats == 0 then
        return "none"
    end

    local parts = {}

    for index = 1, #stats do
        local stat = stats[index]
        local label = stat.label or stat.token or "Unknown Stat"
        local value = stat.value
        local socketStat = label:lower():find("socket", 1, true)

        if type(value) == "number" and value > 0 and not socketStat then
            parts[#parts + 1] = "+" .. CompactNumber(value, 2) .. " " .. label
        elseif type(value) == "number" and value == 1 and socketStat then
            parts[#parts + 1] = label
        else
            parts[#parts + 1] = tostring(type(value) == "number" and CompactNumber(value, 2) or value) .. " " .. label
        end
    end

    return table.concat(parts, ", ")
end

local JSON_ESCAPE_CHARS = {
    ["\\"] = "\\\\",
    ["\""] = "\\\"",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
}

local function JsonString(value)
    value = tostring(value or "")
    value = value:gsub('[%z\1-\31\\"]', function(character)
        return JSON_ESCAPE_CHARS[character] or string.format("\\u%04x", character:byte())
    end)
    return "\"" .. value .. "\""
end

local function JsonValue(value)
    local valueType = type(value)

    if value == nil then
        return "null"
    end

    if valueType == "number" then
        return tostring(value)
    end

    if valueType == "boolean" then
        return value and "true" or "false"
    end

    return JsonString(value)
end

local function JsonField(key, value, comma)
    return JsonString(key) .. ": " .. JsonValue(value) .. (comma and "," or "")
end

local function ScopeTitle(scope)
    if scope == "gear" then
        return "Gear Only"
    end

    return (scope or "all"):gsub("^%l", string.upper)
end

local function LocalizedScopeTitle(scope, locale)
    locale = Trim(locale or "")

    if locale == "zhCN" then
        if scope == "bags" then
            return "背包"
        end
        if scope == "bank" then
            return "银行"
        end
        if scope == "gear" then
            return "仅装备"
        end
        return "全部"
    end

    if locale == "zhTW" then
        if scope == "bags" then
            return "背包"
        end
        if scope == "bank" then
            return "銀行"
        end
        if scope == "gear" then
            return "僅裝備"
        end
        return "全部"
    end

    return ScopeTitle(scope)
end

local function NormalizeExportFormat(format)
    format = Trim(format):lower()

    if format == "" or format == "ai" or format == "chatgpt" or format == "gpt" then
        return "ai"
    end

    if format == "json" or format == "raw" then
        return "json"
    end

    if format == "markdown" or format == "md" then
        return "markdown"
    end

    if format == "text" or format == "txt" or format == "plain" then
        return "text"
    end

    return "ai"
end

local function IsExportFormatToken(token)
    return EXPORT_FORMAT_ALIASES[Trim(token):lower()] and true or false
end

local function ExportFormatTitle(format)
    return EXPORT_FORMAT_LABELS[NormalizeExportFormat(format)] or EXPORT_FORMAT_LABELS.ai
end

local function SplitWords(value)
    local words = {}
    value = Trim(value)

    for word in value:gmatch("%S+") do
        words[#words + 1] = word
    end

    return words
end

local function NormalizeQualityID(value)
    if type(value) == "number" then
        if value >= 0 and value <= 7 then
            return value
        end

        return nil
    end

    if type(value) ~= "string" then
        return nil
    end

    value = Trim(value):lower()
    value = value:gsub("^quality[:=_%-]?", "")
    value = value:gsub("^q[:=_%-]?", "")

    if value:match("^%d+$") then
        return NormalizeQualityID(tonumber(value))
    end

    return QUALITY_ALIASES[value]
end

local function DefaultExportFilter()
    return {
        qualityID = nil,
        qualityMin = nil,
    }
end

local function NormalizeExportFilter(filter)
    if filter == nil then
        return DefaultExportFilter()
    end

    if type(filter) == "table" then
        return {
            qualityID = NormalizeQualityID(filter.qualityID or filter.quality_id or filter.quality),
            qualityMin = NormalizeQualityID(filter.qualityMin or filter.quality_min),
        }
    end

    filter = Trim(filter):lower()
    if filter == "" or filter == "all" or filter == "none" or filter == "any" then
        return DefaultExportFilter()
    end

    local normalized = DefaultExportFilter()
    local words = SplitWords(filter)

    for index = 1, #words do
        local token = words[index]:lower()
        token = token:gsub("[,;]", "")

        if not EXPORT_FILTER_IGNORE_TOKENS[token] then
            local minimumQuality = token:match("^(.+)%+$") or token:match("^min[:=_%-]?(.+)$") or token:match("^(.+)plus$")
            if minimumQuality then
                local qualityID = NormalizeQualityID(minimumQuality)
                if qualityID then
                    normalized.qualityMin = qualityID
                    normalized.qualityID = nil
                end
            else
                local qualityID = NormalizeQualityID(token)
                if qualityID then
                    normalized.qualityID = qualityID
                    normalized.qualityMin = nil
                end
            end
        end
    end

    return normalized
end

local function ExportFilterHasCriteria(filter)
    filter = NormalizeExportFilter(filter)
    return filter.qualityID ~= nil or filter.qualityMin ~= nil
end

local function ExportFilterTitle(filter)
    filter = NormalizeExportFilter(filter)

    if filter.qualityID ~= nil then
        return QualityName(filter.qualityID) .. " only"
    end

    if filter.qualityMin ~= nil then
        return QualityName(filter.qualityMin) .. "+"
    end

    return "All qualities"
end

local function LocalizedExportFilterTitle(filter, locale)
    filter = NormalizeExportFilter(filter)
    locale = PromptLocale(locale)

    if locale == "zhCN" then
        if filter.qualityID ~= nil then
            return "仅" .. LocalizedQualityName(filter.qualityID, locale)
        end
        if filter.qualityMin ~= nil then
            return LocalizedQualityName(filter.qualityMin, locale) .. "及以上"
        end
        return "全部品质"
    end

    if locale == "zhTW" then
        if filter.qualityID ~= nil then
            return "僅" .. LocalizedQualityName(filter.qualityID, locale)
        end
        if filter.qualityMin ~= nil then
            return LocalizedQualityName(filter.qualityMin, locale) .. "以上"
        end
        return "全部品質"
    end

    return ExportFilterTitle(filter)
end

local function ItemQualityID(item)
    if not item then
        return nil
    end

    return NormalizeQualityID(item.quality or item.quality_id)
end

local function ExportFilterMatchesItem(item, filter)
    filter = NormalizeExportFilter(filter)
    local qualityID = ItemQualityID(item)

    if filter.qualityID ~= nil and qualityID ~= filter.qualityID then
        return false
    end

    if filter.qualityMin ~= nil and (not qualityID or qualityID < filter.qualityMin) then
        return false
    end

    return true
end

local function NormalizeExportScope(scope)
    scope = Trim(scope):lower()
    return EXPORT_SCOPE_ALIASES[scope] or "all"
end

local function ParseExportOptions(defaultScope, value)
    local scope = NormalizeExportScope(defaultScope or "all")
    local format
    local filterParts = {}
    local recognized = 0
    local words = SplitWords(value)

    for index = 1, #words do
        local token = words[index]:lower()
        token = token:gsub("[,;]", "")

        if EXPORT_SCOPE_ALIASES[token] then
            scope = EXPORT_SCOPE_ALIASES[token]
            recognized = recognized + 1
        elseif IsExportFormatToken(token) then
            format = NormalizeExportFormat(token)
            recognized = recognized + 1
        elseif EXPORT_FILTER_IGNORE_TOKENS[token] then
            recognized = recognized + 1
        else
            local minimumQuality = token:match("^(.+)%+$") or token:match("^min[:=_%-]?(.+)$") or token:match("^(.+)plus$")
            local qualityID = NormalizeQualityID(minimumQuality or token)

            if qualityID then
                filterParts[#filterParts + 1] = token
                recognized = recognized + 1
            end
        end
    end

    return scope, format, NormalizeExportFilter(table.concat(filterParts, " ")), recognized
end

local function AppendIndented(lines, indent, text)
    lines[#lines + 1] = string.rep(" ", indent) .. text
end

local function AppendJsonStringArray(lines, indent, key, values, comma)
    AppendIndented(lines, indent, JsonString(key) .. ": [")

    for index = 1, #(values or {}) do
        local suffix = index < #(values or {}) and "," or ""
        AppendIndented(lines, indent + 2, JsonString(values[index]) .. suffix)
    end

    AppendIndented(lines, indent, "]" .. (comma and "," or ""))
end

local function TalentTreePoints(talents)
    local points = {}

    for index = 1, #(talents and talents.treePoints or {}) do
        local tree = talents.treePoints[index]
        points[#points + 1] = {
            index = tree.index,
            name = tree.name,
            points = tonumber(tree.points or tree.pointsSpent) or 0,
            pointsSpent = tonumber(tree.pointsSpent or tree.points) or 0,
            isPrimary = tree.isPrimary and true or false,
        }
    end

    if #points == 0 then
        for index = 1, #(talents and talents.tabs or {}) do
            local tab = talents.tabs[index]
            local treeIndex = tab and tab.index or index
            local spent = tonumber(tab and (tab.pointsSpent or tab.points)) or 0
            points[#points + 1] = {
                index = treeIndex,
                name = tab and tab.name or ("Tree " .. tostring(index)),
                points = spent,
                pointsSpent = spent,
                isPrimary = talents and talents.primaryTabIndex == treeIndex or false,
            }
        end
    end

    return points
end

local function TalentSnapshotHasSpentPoints(talents)
    return (tonumber(talents and (talents.pointsSpent or talents.totalPoints)) or 0) > 0
end

local function AppendTalentJson(lines, indent, talents, comma)
    talents = talents or {}
    local treePoints = TalentTreePoints(talents)

    AppendIndented(lines, indent, "\"current_talents\": {")
    AppendIndented(lines, indent + 2, JsonField("updated_at", FormatTime(talents.updatedAt), true))
    AppendIndented(lines, indent + 2, JsonField("api", talents.api or "unavailable", true))
    AppendIndented(lines, indent + 2, JsonField("available", talents.available and true or false, true))
    AppendIndented(lines, indent + 2, JsonField("summary", talents.summary or "", true))
    AppendIndented(lines, indent + 2, JsonField("total_points", talents.totalPoints or 0, true))
    AppendIndented(lines, indent + 2, JsonField("points_spent", talents.pointsSpent or talents.totalPoints or 0, true))
    AppendIndented(lines, indent + 2, JsonField("unspent_points", talents.unspentPoints, true))
    AppendIndented(lines, indent + 2, JsonField("primary_tree", talents.primaryTab, true))
    AppendIndented(lines, indent + 2, JsonField("primary_tree_index", talents.primaryTabIndex, true))
    AppendIndented(lines, indent + 2, "\"tree_points\": [")

    for treeIndex = 1, #treePoints do
        local tree = treePoints[treeIndex]
        AppendIndented(lines, indent + 4, "{ "
            .. JsonField("index", tree.index, true) .. " "
            .. JsonField("name", tree.name, true) .. " "
            .. JsonField("points", tree.points or 0, true) .. " "
            .. JsonField("points_spent", tree.pointsSpent or tree.points or 0, true) .. " "
            .. JsonField("is_primary", tree.isPrimary and true or false, false)
            .. " }" .. (treeIndex < #treePoints and "," or ""))
    end

    AppendIndented(lines, indent + 2, "],")
    AppendIndented(lines, indent + 2, "\"trees\": [")

    for tabIndex = 1, #(talents.tabs or {}) do
        local tab = talents.tabs[tabIndex]
        AppendIndented(lines, indent + 4, "{")
        AppendIndented(lines, indent + 6, JsonField("index", tab.index, true))
        AppendIndented(lines, indent + 6, JsonField("name", tab.name, true))
        AppendIndented(lines, indent + 6, JsonField("points", tab.points or 0, true))
        AppendIndented(lines, indent + 6, JsonField("points_spent", tab.pointsSpent or tab.points or 0, true))
        AppendIndented(lines, indent + 6, JsonField("icon", tab.icon, true))
        AppendIndented(lines, indent + 6, JsonField("background", tab.background, true))
        AppendIndented(lines, indent + 6, "\"talents\": [")

        for talentIndex = 1, #(tab.talents or {}) do
            local talent = tab.talents[talentIndex]
            local suffix = talentIndex < #(tab.talents or {}) and "," or ""
            AppendIndented(lines, indent + 8, "{ "
                .. JsonField("index", talent.index, true) .. " "
                .. JsonField("name", talent.name, true) .. " "
                .. JsonField("tier", talent.tier, true) .. " "
                .. JsonField("column", talent.column, true) .. " "
                .. JsonField("points", talent.points or talent.rank or 0, true) .. " "
                .. JsonField("points_spent", talent.pointsSpent or talent.rank or 0, true) .. " "
                .. JsonField("rank", talent.rank or 0, true) .. " "
                .. JsonField("current_rank", talent.rank or 0, true) .. " "
                .. JsonField("max_rank", talent.maxRank or 0, true) .. " "
                .. JsonField("is_exceptional", talent.isExceptional and true or false, true) .. " "
                .. JsonField("meets_prereq", talent.meetsPrereq ~= false, true) .. " "
                .. JsonField("icon", talent.icon, false)
                .. " }" .. suffix)
        end

        AppendIndented(lines, indent + 6, "]")
        AppendIndented(lines, indent + 4, "}" .. (tabIndex < #(talents.tabs or {}) and "," or ""))
    end

    AppendIndented(lines, indent + 2, "]")
    AppendIndented(lines, indent, "}" .. (comma and "," or ""))
end
local function LocationLabel(source, bagID, slotID, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale or ClientLocale())
    if source == "bags" then
        if bagID == 0 then
            return string.format(terms.backpack_slot, tostring(slotID))
        end

        return string.format(terms.bag_slot, tostring(bagID), tostring(slotID))
    end

    if bagID == BANK_CONTAINER_ID then
        return string.format(terms.bank_slot, tostring(slotID))
    end

    return string.format(terms.bank_bag_slot, tostring(bagID - PLAYER_BAG_SLOTS), tostring(slotID))
end

local function SourceLabel(source, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale or ClientLocale())
    if source == "bags" then
        return terms.bags
    end

    if source == "bank" then
        return terms.bank
    end

    if source == "equipped" then
        return terms.equipped
    end

    return source or terms.unknown
end

function GEAR_ENGINE.ItemLocationLabel(item, locale)
    if not item then
        return GEAR_ENGINE.ReportTerms(locale).unknown_location
    end
    if item.source == "bags" or item.source == "bank" then
        if item.bag ~= nil and item.slot ~= nil then
            return LocationLabel(item.source, item.bag, item.slot, locale)
        end
    end
    if item.source == "equipped" then
        local slotKey = GEAR_ENGINE.EquipmentSlotKey(item)
        if slotKey then
            return GEAR_ENGINE.EquipmentSlotLabel(slotKey, locale)
        end
    end
    return item.location or GEAR_ENGINE.ReportTerms(locale).unknown_location
end

function ClientLocale()
    if type(GetLocale) == "function" then
        local ok, locale = pcall(GetLocale)
        if ok and type(locale) == "string" and locale ~= "" then
            return locale
        end
    end

    return "enUS"
end

function PromptLocale(locale)
    locale = Trim(locale or ClientLocale())

    if locale == "zhCN" then
        return "zhCN"
    end

    if locale == "zhTW" then
        return "zhTW"
    end

    return "enUS"
end

local function LForLocale(locale, key, ...)
    local uiLocale = PromptLocale(locale)
    local strings = UI_STRINGS[uiLocale] or UI_STRINGS.enUS
    local value = strings[key] or UI_STRINGS.enUS[key] or key

    if select("#", ...) > 0 then
        return string.format(value, ...)
    end

    return value
end

local function L(key, ...)
    return LForLocale(ClientLocale(), key, ...)
end

local function LocalizedExportFormatTitle(format, locale)
    local normalized = NormalizeExportFormat(format)
    return LForLocale(locale, "format_" .. normalized .. "_title")
end

local function ClassToken(value)
    value = Trim(value or ""):upper()
    value = value:gsub("%s+", "_")

    if value == "" then
        return "UNKNOWN"
    end

    return value
end

local function GetPlayerClassInfo()
    local localizedClass, englishClass, classID

    if type(UnitClass) == "function" then
        local ok, localized, english, id = pcall(UnitClass, "player")
        if ok then
            localizedClass = localized
            englishClass = english
            classID = id
        end
    end

    englishClass = ClassToken(englishClass or localizedClass)

    return {
        localized = localizedClass or englishClass or "Unknown Class",
        english = englishClass,
        id = classID,
    }
end

local function SafeApiCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end

    local ok, first, second, third, fourth, fifth, sixth, seventh, eighth = pcall(fn, ...)
    if not ok then
        return nil
    end

    return first, second, third, fourth, fifth, sixth, seventh, eighth
end

local function SafeNumber(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    return value
end

local function SumKnown(...)
    local total = 0
    local seen = false

    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if type(value) == "number" then
            total = total + value
            seen = true
        end
    end

    return seen and total or nil
end

local function RaceToken(value)
    value = Trim(value or ""):upper()
    value = value:gsub("%s+", "")
    value = value:gsub("_", "")

    if value == "BLOODELF" or value == "BLOODELVES" then
        return "BLOODELF"
    end

    if value == "NIGHTELF" or value == "NIGHTELVES" then
        return "NIGHTELF"
    end

    if value == "UNDEAD" or value == "SCOURGE" then
        return value
    end

    if value == "" then
        return "UNKNOWN"
    end

    return value
end

local function GetPlayerRaceInfo()
    local localizedRace, englishRace, raceID

    if type(UnitRace) == "function" then
        local ok, localized, english, id = pcall(UnitRace, "player")
        if ok then
            localizedRace = localized
            englishRace = english
            raceID = id
        end
    end

    local factionToken, factionLocalized
    if type(UnitFactionGroup) == "function" then
        local ok, faction, localized = pcall(UnitFactionGroup, "player")
        if ok then
            factionToken = faction
            factionLocalized = localized or faction
        end
    end

    local token = RaceToken(englishRace or localizedRace)
    return {
        localized = localizedRace or englishRace or "Unknown Race",
        english = token,
        id = raceID,
        faction = factionToken,
        factionLocalized = factionLocalized,
        notes = RACE_STRATEGY_NOTES[token] or {},
    }
end

local function GetGroupContext()
    local inRaid = SafeApiCall(IsInRaid)
    local inGroup = SafeApiCall(IsInGroup)
    local raidCount = SafeNumber(SafeApiCall(GetNumGroupMembers)) or SafeNumber(SafeApiCall(GetNumRaidMembers)) or 0
    local partyCount = SafeNumber(SafeApiCall(GetNumSubgroupMembers)) or SafeNumber(SafeApiCall(GetNumPartyMembers)) or 0
    local groupType = "solo"
    local size = 1

    if inRaid or raidCount > 0 then
        groupType = "raid"
        size = math.max(raidCount, 1)
    elseif inGroup or partyCount > 0 then
        groupType = "party"
        size = math.max(partyCount + 1, 1)
    end

    local notes
    if groupType == "raid" then
        notes = {
            "Raid context: benchmark checks use common boss-level references, but TBC party groups inside raids still affect party-local buffs and racials.",
            "Confirm whether hit, mana, threat, or utility buffs are active in the player's actual raid subgroup.",
        }
    elseif groupType == "party" then
        notes = {
            "Party context: party-local buffs and racials can change hit, threat, mana, and utility planning.",
            "Treat exported live stats as currently buffed if party buffs are active.",
        }
    else
        notes = {
            "Solo context: exported live stats may be missing raid/party buffs, debuffs, and party-local racial auras.",
        }
    end

    return {
        type = groupType,
        size = size,
        partyMembers = partyCount,
        raidMembers = raidCount,
        notes = notes,
    }
end

local function BuildAttributeSnapshot()
    local attributes = {}

    for index = 1, #CHARACTER_ATTRIBUTE_SPECS do
        local spec = CHARACTER_ATTRIBUTE_SPECS[index]
        local base, effective, positive, negative = SafeApiCall(UnitStat, "player", spec.index)
        attributes[#attributes + 1] = {
            key = spec.key,
            label = spec.label,
            base = SafeNumber(base),
            effective = SafeNumber(effective),
            positive = SafeNumber(positive),
            negative = SafeNumber(negative),
        }
    end

    return attributes
end

local function BuildArmorSnapshot()
    local base, effective, armor, positive, negative = SafeApiCall(UnitArmor, "player")
    return {
        base = SafeNumber(base),
        effective = SafeNumber(effective or armor),
        armor = SafeNumber(armor),
        positive = SafeNumber(positive),
        negative = SafeNumber(negative),
    }
end

local function BuildDefenseSnapshot()
    local base, modifier = SafeApiCall(UnitDefense, "player")
    base = SafeNumber(base)
    modifier = SafeNumber(modifier)

    return {
        base = base,
        modifier = modifier,
        effective = SumKnown(base, modifier),
    }
end

local function BuildAttackPowerSnapshot()
    local base, positive, negative = SafeApiCall(UnitAttackPower, "player")
    local rangedBase, rangedPositive, rangedNegative = SafeApiCall(UnitRangedAttackPower, "player")
    base = SafeNumber(base)
    positive = SafeNumber(positive)
    negative = SafeNumber(negative)
    rangedBase = SafeNumber(rangedBase)
    rangedPositive = SafeNumber(rangedPositive)
    rangedNegative = SafeNumber(rangedNegative)

    return {
        melee = {
            base = base,
            positive = positive,
            negative = negative,
            effective = SumKnown(base, positive, negative),
        },
        ranged = {
            base = rangedBase,
            positive = rangedPositive,
            negative = rangedNegative,
            effective = SumKnown(rangedBase, rangedPositive, rangedNegative),
        },
    }
end

local function BuildCombatRatingSnapshot()
    local ratings = {}

    for index = 1, #COMBAT_RATING_SPECS do
        local spec = COMBAT_RATING_SPECS[index]
        local globalName = spec.global
        local ratingID = _G and _G[globalName]
        local rating, bonus

        if type(ratingID) ~= "number" and spec.fallbackGlobal then
            globalName = spec.fallbackGlobal
            ratingID = _G and _G[globalName]
        end

        if type(ratingID) == "number" then
            rating = SafeNumber(SafeApiCall(GetCombatRating, ratingID))
            bonus = SafeNumber(SafeApiCall(GetCombatRatingBonus, ratingID))
        end

        ratings[#ratings + 1] = {
            key = spec.key,
            label = spec.label,
            global = globalName,
            rating_id = ratingID,
            rating = rating,
            bonus = bonus,
        }
    end

    return ratings
end

local function BuildChanceSnapshot()
    local spellCrit = {}

    for index = 1, #SPELL_SCHOOL_SPECS do
        local spec = SPELL_SCHOOL_SPECS[index]
        spellCrit[#spellCrit + 1] = {
            key = spec.key,
            label = spec.label,
            crit = SafeNumber(SafeApiCall(GetSpellCritChance, spec.index)),
        }
    end

    return {
        meleeCrit = SafeNumber(SafeApiCall(GetCritChance)),
        rangedCrit = SafeNumber(SafeApiCall(GetRangedCritChance)),
        dodge = SafeNumber(SafeApiCall(GetDodgeChance)),
        parry = SafeNumber(SafeApiCall(GetParryChance)),
        block = SafeNumber(SafeApiCall(GetBlockChance)),
        spellCrit = spellCrit,
    }
end

local function BuildSpellSnapshot()
    local spellDamage = {}

    for index = 1, #SPELL_SCHOOL_SPECS do
        local spec = SPELL_SCHOOL_SPECS[index]
        spellDamage[#spellDamage + 1] = {
            key = spec.key,
            label = spec.label,
            bonus = SafeNumber(SafeApiCall(GetSpellBonusDamage, spec.index)),
        }
    end

    local manaRegenCasting, manaRegenNotCasting = SafeApiCall(GetManaRegen)
    return {
        healing = SafeNumber(SafeApiCall(GetSpellBonusHealing)),
        manaRegenCasting = SafeNumber(manaRegenCasting),
        manaRegenNotCasting = SafeNumber(manaRegenNotCasting),
        spellDamage = spellDamage,
    }
end

local function BuildCharacterStatsSnapshot()
    local race = GetPlayerRaceInfo()
    return {
        updatedAt = Now(),
        api = "paper_doll",
        level = SafeNumber(SafeApiCall(UnitLevel, "player")),
        race = race,
        group = GetGroupContext(),
        attributes = BuildAttributeSnapshot(),
        armor = BuildArmorSnapshot(),
        defense = BuildDefenseSnapshot(),
        attackPower = BuildAttackPowerSnapshot(),
        ratings = BuildCombatRatingSnapshot(),
        chances = BuildChanceSnapshot(),
        spell = BuildSpellSnapshot(),
    }
end
local function TalentApiName()
    if type(GetNumTalentTabs) == "function"
        and type(GetTalentTabInfo) == "function"
        and type(GetNumTalents) == "function"
        and type(GetTalentInfo) == "function" then
        return "GetTalentInfo"
    end

    return "unavailable"
end

local function SafeTalentCall(fn, ...)
    return SafeApiCall(fn, ...)
end

Addon.TALENT_TREE_NAMES = {
    DRUID = {
        enUS = { "Balance", "Feral Combat", "Restoration" },
        zhCN = { "平衡", "野性战斗", "恢复" },
        zhTW = { "平衡", "野性戰鬥", "恢復" },
    },
    HUNTER = {
        enUS = { "Beast Mastery", "Marksmanship", "Survival" },
        zhCN = { "野兽掌握", "射击", "生存" },
        zhTW = { "野獸控制", "射擊", "生存" },
    },
    MAGE = {
        enUS = { "Arcane", "Fire", "Frost" },
        zhCN = { "奥术", "火焰", "冰霜" },
        zhTW = { "秘法", "火焰", "冰霜" },
    },
    PALADIN = {
        enUS = { "Holy", "Protection", "Retribution" },
        zhCN = { "神圣", "防护", "惩戒" },
        zhTW = { "神聖", "防護", "懲戒" },
    },
    PRIEST = {
        enUS = { "Discipline", "Holy", "Shadow" },
        zhCN = { "戒律", "神圣", "暗影" },
        zhTW = { "戒律", "神聖", "暗影" },
    },
    ROGUE = {
        enUS = { "Assassination", "Combat", "Subtlety" },
        zhCN = { "刺杀", "战斗", "敏锐" },
        zhTW = { "刺殺", "戰鬥", "敏銳" },
    },
    SHAMAN = {
        enUS = { "Elemental", "Enhancement", "Restoration" },
        zhCN = { "元素", "增强", "恢复" },
        zhTW = { "元素", "增強", "恢復" },
    },
    WARLOCK = {
        enUS = { "Affliction", "Demonology", "Destruction" },
        zhCN = { "痛苦", "恶魔学识", "毁灭" },
        zhTW = { "痛苦", "惡魔學識", "毀滅" },
    },
    WARRIOR = {
        enUS = { "Arms", "Fury", "Protection" },
        zhCN = { "武器", "狂怒", "防护" },
        zhTW = { "武器", "狂怒", "防護" },
    },
}

function Addon.LocalizedTalentTreeName(classToken, tabIndex, locale)
    local names = Addon.TALENT_TREE_NAMES[ClassToken(classToken)]
    if not names then
        return nil
    end

    local promptLocale = PromptLocale(locale)
    local localized = names[promptLocale] or names.enUS
    return localized and localized[tabIndex] or nil
end

function Addon.TalentTabInfo(tabIndex, classToken, locale)
    local first, second, third, fourth, fifth, sixth = SafeTalentCall(GetTalentTabInfo, tabIndex)
    local tabID, name, icon, pointsSpent, background

    if type(first) == "number" then
        tabID = first
        if type(second) == "string" and second ~= "" then
            name = second
        end
        if type(third) == "number" then
            pointsSpent = third
            icon = fourth
            background = fifth
        elseif type(sixth) == "number" then
            pointsSpent = sixth
            icon = fourth or third
            background = fifth
        end
    else
        name = first
        icon = second
        pointsSpent = third
        background = fourth
    end

    if type(name) ~= "string" or name == "" or tonumber(name) then
        name = Addon.LocalizedTalentTreeName(classToken, tabIndex, locale) or ("Tree " .. tostring(tabIndex))
    end

    return name, icon, tonumber(pointsSpent) or 0, background, tabID
end

local function UnspentTalentPoints()
    local points = SafeTalentCall(UnitCharacterPoints, "player")
    points = tonumber(points)

    if points then
        return points
    end

    points = SafeTalentCall(GetUnspentTalentPoints)
    return tonumber(points)
end

local function BuildTalentSnapshot()
    local snapshot = {
        updatedAt = Now(),
        api = TalentApiName(),
        available = false,
        totalPoints = 0,
        pointsSpent = 0,
        unspentPoints = UnspentTalentPoints(),
        primaryTab = nil,
        primaryTabIndex = nil,
        summary = "",
        treePoints = {},
        tabs = {},
    }

    if snapshot.api == "unavailable" then
        return snapshot
    end

    local tabCount = tonumber(SafeTalentCall(GetNumTalentTabs)) or 0
    local classToken = GetPlayerClassInfo().english
    local locale = ClientLocale()
    local summaryParts = {}
    local primaryPoints = -1

    for tabIndex = 1, tabCount do
        local name, icon, pointsSpent, background, tabID = Addon.TalentTabInfo(tabIndex, classToken, locale)

        local tab = {
            index = tabIndex,
            id = tabID,
            name = name or ("Tree " .. tostring(tabIndex)),
            icon = icon,
            points = pointsSpent,
            pointsSpent = pointsSpent,
            talentPoints = pointsSpent,
            background = background,
            talents = {},
        }

        local talentRankTotal = 0
        local talentCount = tonumber(SafeTalentCall(GetNumTalents, tabIndex)) or 0
        for talentIndex = 1, talentCount do
            local talentName, talentIcon, tier, column, rank, maxRank, isExceptional, meetsPrereq = SafeTalentCall(GetTalentInfo, tabIndex, talentIndex)
            rank = tonumber(rank) or 0
            maxRank = tonumber(maxRank) or 0

            if rank > 0 then
                talentRankTotal = talentRankTotal + rank
                tab.talents[#tab.talents + 1] = {
                    index = talentIndex,
                    name = talentName or ("Talent " .. tostring(talentIndex)),
                    icon = talentIcon,
                    tier = tonumber(tier),
                    column = tonumber(column),
                    points = rank,
                    pointsSpent = rank,
                    rank = rank,
                    currentRank = rank,
                    maxRank = maxRank,
                    isExceptional = isExceptional and true or false,
                    meetsPrereq = meetsPrereq ~= false,
                }
            end
        end

        if talentRankTotal > pointsSpent then
            pointsSpent = talentRankTotal
        end

        tab.points = pointsSpent
        tab.pointsSpent = pointsSpent
        tab.talentPoints = pointsSpent
        snapshot.available = true
        snapshot.totalPoints = snapshot.totalPoints + pointsSpent
        snapshot.pointsSpent = snapshot.totalPoints
        summaryParts[#summaryParts + 1] = tostring(pointsSpent)
        snapshot.tabs[#snapshot.tabs + 1] = tab
        snapshot.treePoints[#snapshot.treePoints + 1] = {
            index = tab.index,
            id = tab.id,
            name = tab.name,
            points = pointsSpent,
            pointsSpent = pointsSpent,
            isPrimary = false,
        }

        if pointsSpent > primaryPoints then
            primaryPoints = pointsSpent
            snapshot.primaryTab = tab.name
            snapshot.primaryTabIndex = tab.index
        end
    end

    snapshot.summary = table.concat(summaryParts, "/")
    snapshot.pointsSpent = snapshot.totalPoints
    if primaryPoints <= 0 then
        snapshot.primaryTab = nil
        snapshot.primaryTabIndex = nil
    end

    for index = 1, #(snapshot.treePoints or {}) do
        snapshot.treePoints[index].isPrimary = snapshot.primaryTabIndex == snapshot.treePoints[index].index
    end

    return snapshot
end

local function TalentTreePointsText(talents, locale)
    local promptLocale = PromptLocale(locale)

    if not talents or not talents.available then
        return promptLocale == "enUS" and "unavailable" or (promptLocale == "zhTW" and "無法取得" or "不可用")
    end

    local treePoints = TalentTreePoints(talents)
    if #treePoints == 0 then
        return promptLocale == "enUS" and "none" or (promptLocale == "zhTW" and "無" or "无")
    end

    local parts = {}
    for index = 1, #treePoints do
        local tree = treePoints[index]
        parts[#parts + 1] = tostring(tree.name or ("Tree " .. tostring(tree.index or index))) .. " " .. tostring(tree.pointsSpent or tree.points or 0)
    end

    return table.concat(parts, ", ")
end

local function TalentSelectedPointsText(talents, locale, maxCount)
    local promptLocale = PromptLocale(locale)

    if not talents or not talents.available then
        return promptLocale == "enUS" and "unavailable" or (promptLocale == "zhTW" and "無法取得" or "不可用")
    end

    local parts = {}
    local omitted = 0
    maxCount = maxCount or 10

    for tabIndex = 1, #(talents.tabs or {}) do
        local tab = talents.tabs[tabIndex]
        for talentIndex = 1, #(tab and tab.talents or {}) do
            local talent = tab.talents[talentIndex]
            local spent = tonumber(talent and (talent.pointsSpent or talent.points or talent.rank)) or 0
            if spent > 0 then
                if #parts < maxCount then
                    parts[#parts + 1] = tostring(talent.name or ("Talent " .. tostring(talent.index or talentIndex)))
                        .. " " .. tostring(spent) .. "/" .. tostring(talent.maxRank or spent)
                else
                    omitted = omitted + 1
                end
            end
        end
    end

    if #parts == 0 then
        return promptLocale == "enUS" and "none" or (promptLocale == "zhTW" and "無" or "无")
    end

    if omitted > 0 then
        if promptLocale == "enUS" then
            parts[#parts + 1] = "+" .. tostring(omitted) .. " more"
        elseif promptLocale == "zhTW" then
            parts[#parts + 1] = "另 " .. tostring(omitted) .. " 個"
        else
            parts[#parts + 1] = "另 " .. tostring(omitted) .. " 个"
        end
    end

    return table.concat(parts, ", ")
end

local function TalentSummaryText(talents, locale)
    talents = talents or {}
    local promptLocale = PromptLocale(locale)

    if not talents.available then
        return promptLocale == "enUS" and "unavailable" or (promptLocale == "zhTW" and "無法取得" or "不可用")
    end

    local primary = talents.primaryTab or (promptLocale == "enUS" and "none" or (promptLocale == "zhTW" and "無" or "无"))
    local unspent = talents.unspentPoints
    local parts

    if promptLocale == "zhCN" then
        parts = {
            tostring(talents.summary or ""),
            "主天赋=" .. tostring(primary),
            "已用点数=" .. tostring(talents.totalPoints or talents.pointsSpent or 0),
            "天赋树=" .. TalentTreePointsText(talents, locale),
        }
    elseif promptLocale == "zhTW" then
        parts = {
            tostring(talents.summary or ""),
            "主天賦=" .. tostring(primary),
            "已用點數=" .. tostring(talents.totalPoints or talents.pointsSpent or 0),
            "天賦樹=" .. TalentTreePointsText(talents, locale),
        }
    else
        parts = {
            tostring(talents.summary or ""),
            "primary=" .. tostring(primary),
            "points=" .. tostring(talents.totalPoints or talents.pointsSpent or 0),
            "trees=" .. TalentTreePointsText(talents, locale),
        }
    end

    if unspent ~= nil then
        if promptLocale == "zhCN" then
            parts[#parts + 1] = "未分配=" .. tostring(unspent)
        elseif promptLocale == "zhTW" then
            parts[#parts + 1] = "未分配=" .. tostring(unspent)
        else
            parts[#parts + 1] = "unspent=" .. tostring(unspent)
        end
    end

    return table.concat(parts, "; ")
end
local function ClassRoleContext(classToken)
    classToken = ClassToken(classToken)
    return CLASS_ROLE_CONTEXT[classToken] or DEFAULT_ROLE_CONTEXT
end

local function LocalizedRoleContext(classToken, locale)
    local promptLocale = PromptLocale(locale)
    classToken = ClassToken(classToken)

    if promptLocale == "zhCN" then
        return CLASS_ROLE_CONTEXT_ZHCN[classToken] or DEFAULT_ROLE_CONTEXT_ZHCN
    end

    if promptLocale == "zhTW" then
        return CLASS_ROLE_CONTEXT_ZHTW[classToken] or CLASS_ROLE_CONTEXT_ZHCN[classToken] or DEFAULT_ROLE_CONTEXT_ZHTW
    end

    return ClassRoleContext(classToken)
end

local function LocalizedOutputRequests(locale)
    local promptLocale = PromptLocale(locale)

    if promptLocale == "zhCN" then
        return AI_OUTPUT_REQUESTS_ZHCN
    end

    if promptLocale == "zhTW" then
        return AI_OUTPUT_REQUESTS_ZHTW
    end

    return AI_OUTPUT_REQUESTS
end

local function BuildAIPrompt(profile, scope, filter, itemCount)
    local classToken = ClassToken(profile.classEnglish or profile.class or "UNKNOWN")
    local locale = profile.locale or ClientLocale()
    local promptLocale = PromptLocale(locale)
    local localized = ANALYSIS_LOCALIZATION[promptLocale]
    local classDisplay = localized and localized.classes and localized.classes[classToken]
        or profile.classLocalized or profile.classEnglish or "Unknown Class"
    local roleContext = LocalizedRoleContext(classToken, promptLocale)
    local outputRequests = LocalizedOutputRequests(promptLocale)
    local talentSummary = TalentSummaryText(profile.talents, promptLocale)
    local lines

    if promptLocale == "zhCN" then
        lines = {
            "你是一名精通《魔兽世界：燃烧的远征》经典版配装分析的助手。",
            "请分析下面的结构化物品导出，并给出实用、按职责区分的配装建议。",
            "角色：" .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm") .. "（" .. tostring(classDisplay) .. "）。",
            "客户端语言：" .. tostring(locale) .. "；请使用与客户端一致的语言回答，并保留物品原始本地化名称。",
            "导出范围：" .. LocalizedScopeTitle(scope, promptLocale) .. "；过滤器：" .. LocalizedExportFilterTitle(filter, promptLocale) .. "；物品数量：" .. tostring(itemCount or 0) .. "。",
            "当前天赋：" .. talentSummary .. "。",
            "请优先使用 current_talents.tree_points、current_talents.trees[].points_spent 和每个已点天赋的 points_spent/rank 来判断当前天赋点数。",
            "银行内容是最后一次保存的快照。背包/银行来源只代表库存位置，不代表物品已经装备。",
            "请使用 character_stats、chart_stats、strategy_book、gear_recommendations、当前装备、物品属性、物品等级、品质、装备栏位、来源位置和 wowhead_url 字段。重点读取 strategy_book.roles[].talent_mapping、gear_recommendations.phase2_strategy、gear_recommendations.available_roles、verdict、benchmark_impacts 和关键基准；比较不同职责或减伤/仇恨/续航模式时必须切换对应权重。不要编造隐藏附魔、宝石、套装或触发效果。",
            "请考虑该职业可能的天赋/职责，不要只假设一个专精。",
            "",
            "职业职责分析视角：",
        }
    elseif promptLocale == "zhTW" then
        lines = {
            "你是一名精通《魔獸世界：燃燒的遠征》經典版配裝分析的助手。",
            "請分析下面的結構化物品匯出，並給出實用、按職責區分的配裝建議。",
            "角色：" .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm") .. "（" .. tostring(classDisplay) .. "）。",
            "客戶端語言：" .. tostring(locale) .. "；請使用與客戶端一致的語言回答，並保留物品原始在地化名稱。",
            "匯出範圍：" .. LocalizedScopeTitle(scope, promptLocale) .. "；過濾器：" .. LocalizedExportFilterTitle(filter, promptLocale) .. "；物品數量：" .. tostring(itemCount or 0) .. "。",
            "目前天賦：" .. talentSummary .. "。",
            "請優先使用 current_talents.tree_points、current_talents.trees[].points_spent 和每個已點天賦的 points_spent/rank 來判斷目前天賦點數。",
            "銀行內容是最後一次儲存的快照。背包/銀行來源只代表庫存位置，不代表物品已經裝備。",
            "請使用 character_stats、chart_stats、strategy_book、gear_recommendations、目前裝備、物品屬性、物品等級、品質、裝備欄位、來源位置和 wowhead_url 欄位。重點讀取 strategy_book.roles[].talent_mapping、gear_recommendations.phase2_strategy、gear_recommendations.available_roles、verdict、benchmark_impacts 和關鍵基準；比較不同職責或減傷/仇恨/續航模式時必須切換對應權重。不要編造隱藏附魔、寶石、套裝或觸發效果。",
            "請考慮該職業可能的天賦/職責，不要只假設一個專精。",
            "",
            "職業職責分析視角：",
        }
    else
        lines = {
            "You are an expert World of Warcraft: The Burning Crusade Classic gearing assistant.",
            "Analyze the structured item export below for this character and produce practical, role-aware gearing advice.",
            "Character: " .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm") .. " (" .. tostring(classDisplay) .. ").",
            "Client locale: " .. tostring(locale) .. ". Answer in the client locale when possible and preserve localized item names.",
            "Export scope: " .. LocalizedScopeTitle(scope, promptLocale) .. "; filter: " .. LocalizedExportFilterTitle(filter, promptLocale) .. "; item count: " .. tostring(itemCount or 0) .. ".",
            "Current talents: " .. talentSummary .. ".",
            "Use current_talents.tree_points, current_talents.trees[].points_spent, and each selected talent points_spent/rank to anchor the current talent distribution.",
            "Bank contents are the last saved snapshot. Treat bag and bank source labels as inventory location, not proof that an item is equipped.",
            "Use character_stats, chart_stats, strategy_book, gear_recommendations, current equipment, item stats, item level, quality, equip slot, source location, and wowhead_url fields. Read strategy_book.roles[].talent_mapping, gear_recommendations.phase2_strategy, and gear_recommendations.available_roles; switch role and mitigation/threat/longevity weights when comparing models. Check caps, verdict, benchmark_impacts, and evidence first; do not invent hidden enchants, gems, set bonuses, or proc effects.",
            "Consider plausible class talents/specs instead of assuming one role.",
            "",
            "Class role lenses:",
        }
    end

    for index = 1, #roleContext do
        lines[#lines + 1] = "- " .. roleContext[index]
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = (promptLocale == "zhCN" or promptLocale == "zhTW") and "输出要求：" or "Output requirements:"

    for index = 1, #outputRequests do
        lines[#lines + 1] = tostring(index) .. ". " .. outputRequests[index]
    end

    return {
        text = table.concat(lines, "\n"),
        classToken = classToken,
        locale = locale,
        promptLocale = promptLocale,
        roleContext = roleContext,
        outputRequests = outputRequests,
    }
end

local function IsEquippableSlot(equipSlot)
    if not equipSlot or equipSlot == "" then
        return false
    end

    if equipSlot == "INVTYPE_NON_EQUIP" or equipSlot == "INVTYPE_NON_EQUIP_IGNORE" then
        return false
    end

    return true
end

local function NormalizedStackCount(count)
    count = tonumber(count)

    if not count or count < 1 then
        return 1
    end

    return count
end

local function AddChartCount(map, key, defaults, stackCount)
    key = tostring(key or "Unknown")

    if key == "" then
        key = "Unknown"
    end

    local entry = map[key]
    if not entry then
        entry = defaults or {}
        entry.itemCount = 0
        entry.stackCount = 0
        map[key] = entry
    end

    entry.itemCount = entry.itemCount + 1
    entry.stackCount = entry.stackCount + stackCount
    return entry
end

local function SortedChartEntries(map, sorter)
    local entries = {}

    for _, entry in pairs(map or {}) do
        entries[#entries + 1] = entry
    end

    table.sort(entries, sorter)
    return entries
end

local function CategoryRank(category)
    for index = 1, #CATEGORY_ORDER do
        if CATEGORY_ORDER[index] == category then
            return index
        end
    end

    return 1000
end

local function RoundedStatNumber(value)
    return math.floor((value * 100) + 0.5) / 100
end

local function BuildChartStats(items)
    local sourceMap = {}
    local categoryMap = {}
    local qualityMap = {}
    local equipSlotMap = {}
    local statMap = {}
    local summary = {
        itemCount = #(items or {}),
        stackCount = 0,
        gearItemCount = 0,
        gearStackCount = 0,
        equippableItemCount = 0,
        itemLevel = { count = 0, min = nil, max = nil, average = nil },
        sourceCounts = {},
        categoryCounts = {},
        qualityCounts = {},
        equipSlotCounts = {},
        statTotals = {},
    }

    for index = 1, #(items or {}) do
        local item = items[index] or {}
        local stackCount = NormalizedStackCount(item.count)
        local source = item.source or "Unknown"
        local category = item.category or "Other"
        local qualityID = ItemQualityID(item)
        local qualityKey = qualityID ~= nil and tostring(qualityID) or tostring(item.qualityName or "Unknown")
        local itemLevel = tonumber(item.itemLevel)

        summary.stackCount = summary.stackCount + stackCount
        AddChartCount(sourceMap, source, { source = source, sourceLabel = SourceLabel(source) }, stackCount)
        AddChartCount(categoryMap, category, { name = category }, stackCount)
        AddChartCount(qualityMap, qualityKey, {
            qualityID = qualityID,
            quality = qualityID ~= nil and QualityName(qualityID) or tostring(item.qualityName or "Unknown"),
            color = ItemQualityColorHex(item),
        }, stackCount)

        if category == "Gear" then
            summary.gearItemCount = summary.gearItemCount + 1
            summary.gearStackCount = summary.gearStackCount + stackCount
        end

        if IsEquippableSlot(item.equipSlot) then
            summary.equippableItemCount = summary.equippableItemCount + 1
            local slotKey = GEAR_ENGINE.EquipmentSlotKey(item) or item.equipSlot
            AddChartCount(equipSlotMap, slotKey, { slot = slotKey }, stackCount)
        end

        if itemLevel then
            local itemLevelSummary = summary.itemLevel
            itemLevelSummary.count = itemLevelSummary.count + 1
            itemLevelSummary.total = (itemLevelSummary.total or 0) + itemLevel
            itemLevelSummary.min = itemLevelSummary.min and math.min(itemLevelSummary.min, itemLevel) or itemLevel
            itemLevelSummary.max = itemLevelSummary.max and math.max(itemLevelSummary.max, itemLevel) or itemLevel
        end

        for statIndex = 1, #(item.stats or {}) do
            local stat = item.stats[statIndex]
            local value = stat and tonumber(stat.value)

            if value and value ~= 0 then
                local token = GEAR_ENGINE.NormalizeStatToken(tostring(stat.token or stat.label or "Unknown Stat"))
                local entry = statMap[token]
                if not entry then
                    entry = {
                        token = token,
                        label = stat.label or StatLabel(token),
                        value = 0,
                        itemCount = 0,
                        stackCount = 0,
                    }
                    statMap[token] = entry
                end

                entry.value = entry.value + (value * stackCount)
                entry.itemCount = entry.itemCount + 1
                entry.stackCount = entry.stackCount + stackCount
            end
        end
    end

    if summary.itemLevel.count > 0 then
        summary.itemLevel.average = RoundedStatNumber((summary.itemLevel.total or 0) / summary.itemLevel.count)
    end

    summary.itemLevel.total = nil
    summary.sourceCounts = SortedChartEntries(sourceMap, function(left, right)
        local sourceOrder = { bags = 1, bank = 2 }
        local leftRank = sourceOrder[left.source] or 100
        local rightRank = sourceOrder[right.source] or 100

        if leftRank ~= rightRank then
            return leftRank < rightRank
        end

        return tostring(left.sourceLabel or left.source) < tostring(right.sourceLabel or right.source)
    end)
    summary.categoryCounts = SortedChartEntries(categoryMap, function(left, right)
        local leftRank = CategoryRank(left.name)
        local rightRank = CategoryRank(right.name)

        if leftRank ~= rightRank then
            return leftRank < rightRank
        end

        return tostring(left.name) < tostring(right.name)
    end)
    summary.qualityCounts = SortedChartEntries(qualityMap, function(left, right)
        local leftQuality = left.qualityID ~= nil and left.qualityID or 100
        local rightQuality = right.qualityID ~= nil and right.qualityID or 100

        if leftQuality ~= rightQuality then
            return leftQuality < rightQuality
        end

        return tostring(left.quality) < tostring(right.quality)
    end)
    summary.equipSlotCounts = SortedChartEntries(equipSlotMap, function(left, right)
        return tostring(left.slot) < tostring(right.slot)
    end)
    summary.statTotals = SortedChartEntries(statMap, function(left, right)
        local leftRank = STAT_ORDER_INDEX[left.token] or 1000
        local rightRank = STAT_ORDER_INDEX[right.token] or 1000

        if leftRank ~= rightRank then
            return leftRank < rightRank
        end

        return tostring(left.label or left.token) < tostring(right.label or right.token)
    end)

    return summary
end

local function AppendJsonObjectArray(lines, indent, key, entries, fields, comma)
    AppendIndented(lines, indent, JsonString(key) .. ": [")

    for index = 1, #(entries or {}) do
        local entry = entries[index]
        AppendIndented(lines, indent + 2, "{")

        for fieldIndex = 1, #fields do
            local field = fields[fieldIndex]
            AppendIndented(lines, indent + 4, JsonField(field.name, entry[field.value], fieldIndex < #fields))
        end

        AppendIndented(lines, indent + 2, "}" .. (index < #(entries or {}) and "," or ""))
    end

    AppendIndented(lines, indent, "]" .. (comma and "," or ""))
end

local function AppendChartStatsJson(lines, indent, chartStats, comma)
    chartStats = chartStats or BuildChartStats({})
    AppendIndented(lines, indent, "\"chart_stats\": {")
    AppendIndented(lines, indent + 2, JsonField("item_count", chartStats.itemCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("stack_count", chartStats.stackCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("gear_item_count", chartStats.gearItemCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("gear_stack_count", chartStats.gearStackCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("equippable_item_count", chartStats.equippableItemCount or 0, true))
    AppendIndented(lines, indent + 2, "\"item_level\": {")
    AppendIndented(lines, indent + 4, JsonField("measured_items", chartStats.itemLevel and chartStats.itemLevel.count or 0, true))
    AppendIndented(lines, indent + 4, JsonField("min", chartStats.itemLevel and chartStats.itemLevel.min, true))
    AppendIndented(lines, indent + 4, JsonField("max", chartStats.itemLevel and chartStats.itemLevel.max, true))
    AppendIndented(lines, indent + 4, JsonField("average", chartStats.itemLevel and chartStats.itemLevel.average, false))
    AppendIndented(lines, indent + 2, "},")
    AppendJsonObjectArray(lines, indent + 2, "source_counts", chartStats.sourceCounts, {
        { name = "source", value = "source" },
        { name = "source_label", value = "sourceLabel" },
        { name = "item_count", value = "itemCount" },
        { name = "stack_count", value = "stackCount" },
    }, true)
    AppendJsonObjectArray(lines, indent + 2, "category_counts", chartStats.categoryCounts, {
        { name = "name", value = "name" },
        { name = "item_count", value = "itemCount" },
        { name = "stack_count", value = "stackCount" },
    }, true)
    AppendJsonObjectArray(lines, indent + 2, "quality_counts", chartStats.qualityCounts, {
        { name = "quality_id", value = "qualityID" },
        { name = "quality", value = "quality" },
        { name = "color", value = "color" },
        { name = "item_count", value = "itemCount" },
        { name = "stack_count", value = "stackCount" },
    }, true)
    AppendJsonObjectArray(lines, indent + 2, "equip_slot_counts", chartStats.equipSlotCounts, {
        { name = "slot", value = "slot" },
        { name = "item_count", value = "itemCount" },
        { name = "stack_count", value = "stackCount" },
    }, true)
    AppendJsonObjectArray(lines, indent + 2, "stat_totals", chartStats.statTotals, {
        { name = "token", value = "token" },
        { name = "label", value = "label" },
        { name = "value", value = "value" },
        { name = "item_count", value = "itemCount" },
        { name = "stack_count", value = "stackCount" },
    }, false)
    AppendIndented(lines, indent, "}" .. (comma and "," or ""))
end

local function ChartCountLine(label, entry, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    return tostring(label) .. ": " .. tostring(entry.itemCount or 0) .. " " .. terms.item_lines .. "; " .. tostring(entry.stackCount or 0) .. " " .. terms.stacks
end

local function ChartStatLine(entry, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    return GEAR_ENGINE.FormatLocalizedStats({ entry }, locale) .. " (" .. tostring(entry.itemCount or 0) .. " " .. terms.item_lines .. "; " .. tostring(entry.stackCount or 0) .. " " .. terms.stacks .. ")"
end

local function AppendMarkdownChartCountSection(lines, title, entries, labeler, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    lines[#lines + 1] = "### " .. title
    lines[#lines + 1] = ""

    if #(entries or {}) == 0 then
        lines[#lines + 1] = "_" .. terms.none .. "._"
    else
        for index = 1, #entries do
            lines[#lines + 1] = "- " .. ChartCountLine(labeler(entries[index]), entries[index], locale)
        end
    end

    lines[#lines + 1] = ""
end

local function AppendChartStatsMarkdown(lines, chartStats, locale)
    chartStats = chartStats or BuildChartStats({})
    local terms = GEAR_ENGINE.ReportTerms(locale)
    lines[#lines + 1] = "## " .. terms.inventory_stats
    lines[#lines + 1] = ""
    lines[#lines + 1] = "- " .. tostring(chartStats.itemCount or 0) .. " " .. terms.item_lines
        .. "; " .. tostring(chartStats.stackCount or 0) .. " " .. terms.stacks
        .. "; " .. tostring(chartStats.gearItemCount or 0) .. " " .. terms.gear
        .. "; " .. tostring(chartStats.equippableItemCount or 0) .. " " .. terms.equippable

    if chartStats.itemLevel and chartStats.itemLevel.count and chartStats.itemLevel.count > 0 then
        lines[#lines + 1] = "- " .. string.format(terms.item_level_summary, tostring(chartStats.itemLevel.min), tostring(chartStats.itemLevel.max), tostring(chartStats.itemLevel.average), tostring(chartStats.itemLevel.count))
    else
        lines[#lines + 1] = "- " .. terms.item_level .. ": " .. terms.none
    end

    lines[#lines + 1] = ""
    AppendMarkdownChartCountSection(lines, terms.source_counts, chartStats.sourceCounts, function(entry)
        return entry.sourceLabel or entry.source
    end, locale)
    AppendMarkdownChartCountSection(lines, terms.category_counts, chartStats.categoryCounts, function(entry)
        return GEAR_ENGINE.CategoryLabel(entry.name, locale)
    end, locale)
    AppendMarkdownChartCountSection(lines, terms.quality_counts, chartStats.qualityCounts, function(entry)
        return tostring(entry.quality or terms.none) .. (entry.color and " (" .. entry.color .. ")" or "")
    end, locale)
    AppendMarkdownChartCountSection(lines, terms.slot_counts, chartStats.equipSlotCounts, function(entry)
        return GEAR_ENGINE.EquipmentSlotLabel(entry.slot, locale)
    end, locale)
    lines[#lines + 1] = "### " .. terms.stat_totals
    lines[#lines + 1] = ""

    if #(chartStats.statTotals or {}) == 0 then
        lines[#lines + 1] = "_" .. terms.none .. "._"
    else
        for index = 1, #chartStats.statTotals do
            lines[#lines + 1] = "- " .. ChartStatLine(chartStats.statTotals[index], locale)
        end
    end

    lines[#lines + 1] = ""
end

local function AppendTextChartCountSection(lines, title, entries, labeler, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    lines[#lines + 1] = title

    if #(entries or {}) == 0 then
        lines[#lines + 1] = terms.none
    else
        for index = 1, #entries do
            lines[#lines + 1] = "- " .. ChartCountLine(labeler(entries[index]), entries[index], locale)
        end
    end

    lines[#lines + 1] = ""
end

local function AppendChartStatsText(lines, chartStats, locale)
    chartStats = chartStats or BuildChartStats({})
    local terms = GEAR_ENGINE.ReportTerms(locale)
    lines[#lines + 1] = terms.inventory_stats
    lines[#lines + 1] = tostring(chartStats.itemCount or 0) .. " " .. terms.item_lines
        .. "; " .. tostring(chartStats.stackCount or 0) .. " " .. terms.stacks
        .. "; " .. tostring(chartStats.gearItemCount or 0) .. " " .. terms.gear
        .. "; " .. tostring(chartStats.equippableItemCount or 0) .. " " .. terms.equippable

    if chartStats.itemLevel and chartStats.itemLevel.count and chartStats.itemLevel.count > 0 then
        lines[#lines + 1] = string.format(terms.item_level_summary, tostring(chartStats.itemLevel.min), tostring(chartStats.itemLevel.max), tostring(chartStats.itemLevel.average), tostring(chartStats.itemLevel.count))
    else
        lines[#lines + 1] = terms.item_level .. ": " .. terms.none
    end

    lines[#lines + 1] = ""
    AppendTextChartCountSection(lines, terms.source_counts, chartStats.sourceCounts, function(entry)
        return entry.sourceLabel or entry.source
    end, locale)
    AppendTextChartCountSection(lines, terms.category_counts, chartStats.categoryCounts, function(entry)
        return GEAR_ENGINE.CategoryLabel(entry.name, locale)
    end, locale)
    AppendTextChartCountSection(lines, terms.quality_counts, chartStats.qualityCounts, function(entry)
        return tostring(entry.quality or terms.none) .. (entry.color and " (" .. entry.color .. ")" or "")
    end, locale)
    AppendTextChartCountSection(lines, terms.slot_counts, chartStats.equipSlotCounts, function(entry)
        return GEAR_ENGINE.EquipmentSlotLabel(entry.slot, locale)
    end, locale)
    lines[#lines + 1] = terms.stat_totals

    if #(chartStats.statTotals or {}) == 0 then
        lines[#lines + 1] = terms.none
    else
        for index = 1, #chartStats.statTotals do
            lines[#lines + 1] = "- " .. ChartStatLine(chartStats.statTotals[index], locale)
        end
    end

    lines[#lines + 1] = ""
end
local function FindEntryByKey(entries, key)
    for index = 1, #(entries or {}) do
        if entries[index] and entries[index].key == key then
            return entries[index]
        end
    end

    return nil
end

local function AttributeValue(characterStats, key)
    local entry = FindEntryByKey(characterStats and characterStats.attributes, key)
    return entry and entry.effective or nil
end

local function RatingBonus(characterStats, key)
    local entry = FindEntryByKey(characterStats and characterStats.ratings, key)
    return entry and entry.bonus or nil
end

function GEAR_ENGINE.RatingValue(characterStats, key)
    local entry = FindEntryByKey(characterStats and characterStats.ratings, key)
    return entry and entry.rating or nil
end

local function BestSpellValue(entries, valueKey)
    local best

    for index = 1, #(entries or {}) do
        local value = entries[index] and entries[index][valueKey]
        if type(value) == "number" and (not best or value > best) then
            best = value
        end
    end

    return best
end

local function KnownAvoidanceBlock(chances)
    chances = chances or {}
    local total = 0
    local seen = false

    for _, value in ipairs({ chances.dodge, chances.parry, chances.block }) do
        if type(value) == "number" then
            total = total + value
            seen = true
        end
    end

    return seen and total or nil
end

local function ChartStatTotal(chartStats, token)
    for index = 1, #((chartStats and chartStats.statTotals) or {}) do
        local stat = chartStats.statTotals[index]
        if stat and stat.token == token then
            return stat
        end
    end

    return nil
end

local function RoleGearHighlights(role, chartStats, equippedItems)
    local highlights = {}
    local scopedTotals

    if equippedItems then
        scopedTotals = {}
        for itemIndex = 1, #equippedItems do
            local item = equippedItems[itemIndex]
            for statIndex = 1, #(item and item.stats or {}) do
                local stat = item.stats[statIndex]
                local token = GEAR_ENGINE.NormalizeStatToken(stat and stat.token)
                local value = tonumber(stat and stat.value)
                if token and value and GEAR_ENGINE.StatAppliesToRoleSlot(role, token, item) then
                    local entry = scopedTotals[token]
                    if not entry then
                        entry = { token = token, label = stat.label or StatLabel(token), value = 0 }
                        scopedTotals[token] = entry
                    end
                    entry.value = entry.value + value
                end
            end
        end
    end

    local seen = {}
    for index = 1, #(role.statTokens or {}) do
        local token = GEAR_ENGINE.NormalizeStatToken(role.statTokens[index])
        local stat = scopedTotals and scopedTotals[token] or ChartStatTotal(chartStats, token)
        if stat and not seen[token] then
            seen[token] = true
            highlights[#highlights + 1] = {
                token = stat.token,
                label = stat.label,
                value = RoundedStatNumber(stat.value),
            }
        end
    end

    return highlights
end

local function TalentPointsForTabs(talents, tabIndexes)
    local total = 0

    for index = 1, #(talents and talents.tabs or {}) do
        local tab = talents.tabs[index]
        for tabIndex = 1, #(tabIndexes or {}) do
            if tab and tab.index == tabIndexes[tabIndex] then
                total = total + (tonumber(tab.points) or 0)
            end
        end
    end

    return total
end

local function TalentPrimaryMatches(talents, tabIndexes)
    local primaryIndex = talents and talents.primaryTabIndex

    if not primaryIndex then
        return false
    end

    for index = 1, #(tabIndexes or {}) do
        if primaryIndex == tabIndexes[index] then
            return true
        end
    end

    return false
end

local function RoleConfidence(role, talents)
    if not talents or not talents.available then
        return 25
    end

    local talentPoints = TalentPointsForTabs(talents, role.talentTabs)
    local confidence = 20 + math.min(60, talentPoints * 2)

    if TalentPrimaryMatches(talents, role.talentTabs) then
        confidence = confidence + 20
    end

    if confidence > 100 then
        confidence = 100
    end

    return confidence
end

local function TalentTabMatches(tabIndex, tabIndexes)
    if #(tabIndexes or {}) == 0 then
        return true
    end
    for index = 1, #(tabIndexes or {}) do
        if tonumber(tabIndex) == tonumber(tabIndexes[index]) then
            return true
        end
    end
    return false
end

local function NormalizeTalentName(name)
    return tostring(name or ""):lower():gsub("[%s%p]", "")
end

local function TalentRuleMatches(rule, tabIndex, talent)
    if rule.tab and rule.index and tonumber(rule.tab) == tonumber(tabIndex) and tonumber(rule.index) == tonumber(talent and talent.index) then
        return true
    end
    local talentName = NormalizeTalentName(talent and talent.name)
    for index = 1, #(rule.names or {}) do
        if talentName ~= "" and talentName == NormalizeTalentName(rule.names[index]) then
            return true
        end
    end
    return false
end

local function TalentRuleFor(classToken, roleKey, tabIndex, talent)
    local classRules = TALENT_EFFECT_RULES[ClassToken(classToken)] or {}
    for index = 1, #(classRules[roleKey] or {}) do
        local rule = classRules[roleKey][index]
        if TalentRuleMatches(rule, tabIndex, talent) then
            return rule
        end
    end
    return nil
end

local function BuildTalentRoleMap(classToken, talents, role)
    local result = {
        version = 1,
        selectedCount = 0,
        selectedPoints = 0,
        mappedCount = 0,
        alignedCount = 0,
        alignedPoints = 0,
        affinityScore = 0,
        selected = {},
        effects = {},
        weightMultipliers = {},
        weightModifiers = {},
    }

    for tabIndex = 1, #(talents and talents.tabs or {}) do
        local tab = talents.tabs[tabIndex]
        for talentIndex = 1, #(tab and tab.talents or {}) do
            local talent = tab.talents[talentIndex]
            local rank = tonumber(talent and (talent.currentRank or talent.pointsSpent or talent.points or talent.rank)) or 0
            if rank > 0 then
                local aligned = TalentTabMatches(tab and tab.index or tabIndex, role and role.talentTabs)
                local rule = TalentRuleFor(classToken, role and (role.talentRuleKey or role.key), tab and tab.index or tabIndex, talent)
                local entry = {
                    treeIndex = tab and tab.index or tabIndex,
                    treeName = tab and tab.name,
                    talentIndex = talent and talent.index or talentIndex,
                    name = talent and talent.name,
                    icon = talent and talent.icon,
                    rank = rank,
                    maxRank = tonumber(talent and talent.maxRank) or rank,
                    aligned = aligned,
                    effectKey = rule and rule.key or nil,
                    tags = rule and rule.tags or {},
                }
                result.selected[#result.selected + 1] = entry
                result.selectedCount = result.selectedCount + 1
                result.selectedPoints = result.selectedPoints + rank
                result.mappedCount = result.mappedCount + 1
                if aligned then
                    result.alignedCount = result.alignedCount + 1
                    result.alignedPoints = result.alignedPoints + rank
                end
                if rule then
                    local effect = {
                        key = rule.key,
                        name = talent and talent.name,
                        icon = talent and talent.icon,
                        rank = rank,
                        maxRank = entry.maxRank,
                        labels = rule.labels or {},
                        tags = rule.tags or {},
                    }
                    result.effects[#result.effects + 1] = effect
                    for token, maximumMultiplier in pairs(rule.multipliers or {}) do
                        local progress = entry.maxRank > 0 and (rank / entry.maxRank) or 1
                        local multiplier = 1 + ((maximumMultiplier - 1) * progress)
                        result.weightMultipliers[token] = (result.weightMultipliers[token] or 1) * multiplier
                    end
                end
            end
        end
    end

    for token, multiplier in pairs(result.weightMultipliers) do
        result.weightModifiers[#result.weightModifiers + 1] = {
            token = token,
            multiplier = RoundedStatNumber(multiplier),
        }
    end
    table.sort(result.weightModifiers, function(left, right)
        return tostring(left.token) < tostring(right.token)
    end)
    result.affinityScore = result.alignedPoints + (#result.effects * 3)
    result.coverage = result.selectedCount > 0 and RoundedStatNumber(result.mappedCount / result.selectedCount) or 0
    return result
end

function GEAR_ENGINE.TalentEffectRank(talentMap, effectKey)
    local rank = 0
    for index = 1, #(talentMap and talentMap.effects or {}) do
        local effect = talentMap.effects[index]
        if effect and effect.key == effectKey then
            rank = math.max(rank, tonumber(effect.rank) or 0)
        end
    end
    return rank
end

function GEAR_ENGINE.BuildCritImmunity(characterStats, talentMap, equippedChartStats)
    local defenseSkill = tonumber(characterStats and characterStats.defense and characterStats.defense.effective)
    local resilienceRating = tonumber(GEAR_ENGINE.RatingValue(characterStats, "resilience"))
    local resilienceSource = resilienceRating ~= nil and "live_rating" or nil
    local equippedResilience
    for index = 1, #(equippedChartStats and equippedChartStats.statTotals or {}) do
        local stat = equippedChartStats.statTotals[index]
        if GEAR_ENGINE.NormalizeStatToken(stat and stat.token) == "ITEM_MOD_RESILIENCE_RATING_SHORT" then
            equippedResilience = tonumber(stat.value)
            break
        end
    end
    if (resilienceRating == nil or resilienceRating <= 0) and equippedResilience and equippedResilience > 0 then
        resilienceRating = equippedResilience
        resilienceSource = "equipped_items"
    end
    local survivalRank = GEAR_ENGINE.TalentEffectRank(talentMap, "survival_of_the_fittest")
    local hasObservedSource = defenseSkill ~= nil or resilienceRating ~= nil or survivalRank > 0
    local defenseReduction = math.max((defenseSkill or 350) - 350, 0) * 0.04
    local resilienceReduction = (resilienceRating or 0) / 39.4
    local talentReduction = survivalRank
    local total = hasObservedSource and (defenseReduction + resilienceReduction + talentReduction) or nil
    local target = 5.6

    return {
        target = target,
        total = total and RoundedStatNumber(total) or nil,
        gap = total and RoundedStatNumber(math.max(target - total, 0)) or nil,
        defenseSkill = defenseSkill,
        defenseReduction = RoundedStatNumber(defenseReduction),
        resilienceRating = resilienceRating,
        resilienceRatingSource = resilienceSource,
        resilienceReduction = RoundedStatNumber(resilienceReduction),
        talentReduction = RoundedStatNumber(talentReduction),
        survivalOfTheFittestRank = survivalRank,
    }
end

local function BuildRoleObservedStats(role, characterStats, chartStats, equippedItems, talentMap)
    local chances = characterStats and characterStats.chances or {}
    local spell = characterStats and characterStats.spell or {}
    local attackPower = characterStats and characterStats.attackPower or {}
    local defense = characterStats and characterStats.defense or {}
    local armor = characterStats and characterStats.armor or {}
    local critImmunity = GEAR_ENGINE.BuildCritImmunity(characterStats, talentMap, chartStats)

    return {
        hit = {
            melee = RatingBonus(characterStats, "melee_hit"),
            ranged = RatingBonus(characterStats, "ranged_hit"),
            spell = RatingBonus(characterStats, "spell_hit"),
            expertise = RatingBonus(characterStats, "expertise"),
        },
        crit = {
            melee = chances.meleeCrit,
            ranged = chances.rangedCrit,
            spellBest = BestSpellValue(chances.spellCrit, "crit"),
        },
        tank = {
            defense = defense.effective,
            armor = armor.effective,
            stamina = AttributeValue(characterStats, "stamina"),
            dodge = chances.dodge,
            parry = chances.parry,
            block = chances.block,
            knownAvoidanceBlock = KnownAvoidanceBlock(chances),
            critImmunity = critImmunity,
            critReduction = critImmunity.total,
            critReductionTarget = critImmunity.target,
        },
        power = {
            attackPower = attackPower.melee and attackPower.melee.effective or nil,
            rangedAttackPower = attackPower.ranged and attackPower.ranged.effective or nil,
            spellPowerBest = BestSpellValue(spell.spellDamage, "bonus"),
            healing = spell.healing,
            manaRegenCasting = spell.manaRegenCasting,
        },
        gearStatHighlights = RoleGearHighlights(role, chartStats, equippedItems),
    }
end

local function BenchmarkObservedValue(key, observed)
    observed = observed or {}

    if key == "defense_crit_immunity" then
        return observed.tank and observed.tank.defense or nil
    end

    if key == "crit_immunity" then
        return observed.tank and observed.tank.critReduction or nil
    end

    if key == "melee_special_hit" then
        return observed.hit and observed.hit.melee or nil
    end

    if key == "ranged_hit" then
        return observed.hit and observed.hit.ranged or nil
    end

    if key == "spell_hit" then
        return observed.hit and observed.hit.spell or nil
    end

    if key == "expertise_dodge" then
        return observed.hit and observed.hit.expertise or nil
    end

    if key == "avoidance_table" then
        return observed.tank and observed.tank.knownAvoidanceBlock or nil
    end

    return nil
end

local function BenchmarkStatus(key, observed)
    local benchmark = TBC_BENCHMARKS[key]
    local value = BenchmarkObservedValue(key, observed)
    local status = "unknown"

    if type(value) == "number" and benchmark then
        if key == "avoidance_table" then
            status = "context_required"
        elseif value >= benchmark.value then
            status = "meets_or_exceeds"
        elseif value >= (benchmark.value * 0.9) then
            status = "near"
        else
            status = "below"
        end
    end

    return {
        key = key,
        label = benchmark and benchmark.label or key,
        observed = value,
        target = benchmark and benchmark.value or nil,
        unit = benchmark and benchmark.unit or nil,
        status = status,
        note = benchmark and benchmark.note or nil,
    }
end

local function BuildRoleBenchmarks(role, observed)
    local benchmarks = {}

    for index = 1, #(role.benchmarkKeys or {}) do
        benchmarks[#benchmarks + 1] = BenchmarkStatus(role.benchmarkKeys[index], observed)
    end

    return benchmarks
end

local function StrategyClassRoles(classToken)
    local phaseRoles = P2_STRATEGY_DB.GetClassRoles and P2_STRATEGY_DB.GetClassRoles(ClassToken(classToken))
    if phaseRoles and #phaseRoles > 0 then
        return phaseRoles
    end
    local classBook = CLASS_STRATEGY_BOOK[ClassToken(classToken)]
    return (classBook and classBook.roles) or DEFAULT_STRATEGY_ROLES
end

local function BuildStrategyBook(profile, chartStats)
    local classToken = ClassToken(profile and profile.classEnglish or "UNKNOWN")
    local characterStats = profile and profile.characterStats or BuildCharacterStatsSnapshot()
    local equippedChartStats = BuildChartStats(profile and profile.equipped and profile.equipped.items or {})
    local race = characterStats and characterStats.race or GetPlayerRaceInfo()
    local group = characterStats and characterStats.group or GetGroupContext()
    local roles = {}
    local sourceRoles = StrategyClassRoles(classToken)

    for index = 1, #sourceRoles do
        local role = sourceRoles[index]
        local talentPoints = TalentPointsForTabs(profile and profile.talents, role.talentTabs)
        local primaryMatch = TalentPrimaryMatches(profile and profile.talents, role.talentTabs)
        local talentMap = BuildTalentRoleMap(classToken, profile and profile.talents, role)
        local observed = BuildRoleObservedStats(role, characterStats, equippedChartStats, profile and profile.equipped and profile.equipped.items or {}, talentMap)
        roles[#roles + 1] = {
            key = role.key,
            label = role.label,
            labels = role.labels,
            talentRuleKey = role.talentRuleKey,
            archetype = role.archetype,
            phase = role.phase,
            confidence = RoleConfidence(role, profile and profile.talents),
            talentPoints = talentPoints,
            primaryTalentMatch = primaryMatch,
            models = role.models or {},
            priorities = role.priorities or {},
            statTokens = role.statTokens or {},
            caps = role.caps or {},
            modes = role.modes or {},
            setGoal = role.setGoal,
            setGoalLabels = role.setGoalLabels,
            talentString = role.talentString,
            presets = role.presets or {},
            guideUrl = role.guideUrl,
            researchEvidence = role.evidence or "sim_and_guide",
            talentMap = talentMap,
            observed = observed,
            benchmarks = BuildRoleBenchmarks(role, observed),
            notes = {
                "Mapped from class, race, current talent distribution, live character stats, and currently equipped gear stats.",
                "Use confidence as a role-lens hint, not a final spec declaration.",
            },
        }
    end

    table.sort(roles, function(left, right)
        if left.confidence ~= right.confidence then
            return left.confidence > right.confidence
        end

        local leftAffinity = left.talentMap and left.talentMap.affinityScore or 0
        local rightAffinity = right.talentMap and right.talentMap.affinityScore or 0
        if leftAffinity ~= rightAffinity then
            return leftAffinity > rightAffinity
        end

        return tostring(left.label) < tostring(right.label)
    end)

    return {
        version = 5,
        generatedAt = Now(),
        classToken = classToken,
        raceToken = race and race.english or "UNKNOWN",
        groupType = group and group.type or "solo",
        raceNotes = race and race.notes or {},
        groupNotes = group and group.notes or {},
        benchmarkReferences = TBC_BENCHMARKS,
        phaseDatabase = {
            version = P2_STRATEGY_DB.version,
            phase = P2_STRATEGY_DB.phase,
            phaseLabel = P2_STRATEGY_DB.phaseLabel,
            patch = P2_STRATEGY_DB.patch,
            updatedAt = P2_STRATEGY_DB.updatedAt,
            sources = P2_STRATEGY_DB.sources,
        },
        roles = roles,
    }
end

function GEAR_ENGINE.EquipmentSlotKey(item)
    if item and item.slotKey then
        return item.slotKey
    end

    if item and item.inventorySlot then
        for index = 1, #GEAR_ENGINE.EQUIPMENT_SLOTS do
            if GEAR_ENGINE.EQUIPMENT_SLOTS[index].id == item.inventorySlot then
                return GEAR_ENGINE.EQUIPMENT_SLOTS[index].key
            end
        end
    end

    return item and GEAR_ENGINE.EQUIP_SLOT_KEYS[item.equipSlot] or nil
end

function GEAR_ENGINE.EquipmentSlotLabel(slotKey, locale)
    locale = PromptLocale(locale or ClientLocale())
    local labels = GEAR_ENGINE.EQUIPMENT_SLOT_LABELS[locale] or GEAR_ENGINE.EQUIPMENT_SLOT_LABELS.enUS
    return labels[slotKey] or tostring(slotKey or "Unknown")
end

function GEAR_ENGINE.EquippedItemForSlot(profile, slotKey)
    for index = 1, #(profile and profile.equipped and profile.equipped.items or {}) do
        local item = profile.equipped.items[index]
        if GEAR_ENGINE.EquipmentSlotKey(item) == slotKey then
            return item
        end
    end
    return nil
end

function GEAR_ENGINE.IsTwoHandedItem(item)
    return item and item.equipSlot == "INVTYPE_2HWEAPON" or false
end

function GEAR_ENGINE.LoadoutCompatible(profile, candidateItem)
    local slotKey = GEAR_ENGINE.EquipmentSlotKey(candidateItem)
    local mainHand = GEAR_ENGINE.EquippedItemForSlot(profile, "MAINHAND")
    local offHand = GEAR_ENGINE.EquippedItemForSlot(profile, "OFFHAND")
    if slotKey == "OFFHAND" and GEAR_ENGINE.IsTwoHandedItem(mainHand) then
        return false, "two_handed_main"
    end
    if slotKey == "MAINHAND" and GEAR_ENGINE.IsTwoHandedItem(candidateItem) and offHand then
        return false, "occupied_offhand"
    end
    return true, nil
end

function GEAR_ENGINE.MaximumWeight(weights, tokens)
    local best

    for index = 1, #tokens do
        local value = weights[tokens[index]]
        if type(value) == "number" and (not best or value > best) then
            best = value
        end
    end

    return best
end

function GEAR_ENGINE.StatWeightForToken(weights, token)
    token = GEAR_ENGINE.NormalizeStatToken(token)
    if weights[token] then
        return weights[token]
    end

    if token == "ITEM_MOD_HIT_RATING_SHORT" then
        return GEAR_ENGINE.MaximumWeight(weights, { "ITEM_MOD_HIT_MELEE_RATING_SHORT", "ITEM_MOD_HIT_RANGED_RATING_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT" })
    end

    if token == "ITEM_MOD_CRIT_RATING_SHORT" then
        return GEAR_ENGINE.MaximumWeight(weights, { "ITEM_MOD_CRIT_MELEE_RATING_SHORT", "ITEM_MOD_CRIT_RANGED_RATING_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT" })
    end

    if token == "ITEM_MOD_HASTE_RATING_SHORT" then
        return GEAR_ENGINE.MaximumWeight(weights, { "ITEM_MOD_HASTE_MELEE_RATING_SHORT", "ITEM_MOD_HASTE_RANGED_RATING_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT" })
    end

    if tostring(token or ""):find("EMPTY_SOCKET", 1, true) then
        return 4
    end

    return nil
end

function GEAR_ENGINE.FindStrategyMode(role, modeKey)
    for index = 1, #(role and role.modes or {}) do
        local mode = role.modes[index]
        if not modeKey or mode.key == modeKey then
            return mode
        end
    end
    return role and role.modes and role.modes[1] or { key = "balanced", labels = { enUS = "Balanced", zhCN = "均衡", zhTW = "均衡" }, multipliers = {} }
end

function GEAR_ENGINE.AvailableStrategyModes(role)
    local modes = {}
    for index = 1, #(role and role.modes or {}) do
        local mode = role.modes[index]
        modes[#modes + 1] = { key = mode.key, labels = mode.labels, focus = mode.focus or {} }
    end
    if #modes == 0 then
        modes[1] = { key = "balanced", labels = { enUS = "Balanced", zhCN = "均衡", zhTW = "均衡" }, focus = {} }
    end
    return modes
end

function GEAR_ENGINE.BuildRoleStatWeights(role, modeKey)
    local weights = {}

    for index = 1, #(role and role.statTokens or {}) do
        local token = role.statTokens[index]
        local priority = math.max(0.65, 1.8 - ((index - 1) * 0.15))
        weights[token] = priority * (GEAR_ENGINE.STAT_SCORE_SCALES[token] or 1)
    end

    for index = 1, #(role and role.benchmarks or {}) do
        local benchmark = role.benchmarks[index]
        local boost = benchmark.status == "below" and 1.75
            or ((benchmark.status == "near" or benchmark.status == "context_required") and 1.30 or 1)
        local tokens = GEAR_ENGINE.BENCHMARK_STAT_TOKENS[benchmark.key] or {}
        for tokenIndex = 1, #tokens do
            local token = tokens[tokenIndex]
            local base = weights[token] or (GEAR_ENGINE.STAT_SCORE_SCALES[token] or 1)
            weights[token] = base * boost
        end
    end

    for index = 1, #(role and role.talentMap and role.talentMap.weightModifiers or {}) do
        local modifier = role.talentMap.weightModifiers[index]
        local token = GEAR_ENGINE.NormalizeStatToken(modifier and modifier.token)
        local multiplier = tonumber(modifier and modifier.multiplier) or 1
        local base = weights[token] or (GEAR_ENGINE.STAT_SCORE_SCALES[token] or 1)
        weights[token] = base * multiplier
    end

    local mode = GEAR_ENGINE.FindStrategyMode(role, modeKey)
    for token, multiplier in pairs(mode and mode.multipliers or {}) do
        token = GEAR_ENGINE.NormalizeStatToken(token)
        local base = weights[token] or (GEAR_ENGINE.STAT_SCORE_SCALES[token] or 1)
        weights[token] = base * (tonumber(multiplier) or 1)
    end

    local spellOffenseWeight = GEAR_ENGINE.MaximumWeight(weights, {
        "ITEM_MOD_SPELL_POWER_SHORT",
        "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
    })
    if spellOffenseWeight then
        weights.ITEM_MOD_SPELL_POWER_SHORT = spellOffenseWeight
        weights.ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = spellOffenseWeight
    end

    return weights
end

function GEAR_ENGINE.StatAppliesToRoleSlot(role, token, item)
    token = GEAR_ENGINE.NormalizeStatToken(token)
    if token ~= "ITEM_MOD_DAMAGE_PER_SECOND_SHORT" then
        return true
    end

    local archetype = role and role.archetype
    local slotKey = GEAR_ENGINE.EquipmentSlotKey(item)
    if archetype == "ranged" then
        return slotKey == "RANGED"
    end
    if archetype == "melee" or archetype == "tank" then
        return slotKey == "MAINHAND" or slotKey == "OFFHAND"
    end
    return true
end

function GEAR_ENGINE.ItemRoleScore(item, role, weights)
    weights = weights or GEAR_ENGINE.BuildRoleStatWeights(role)
    local score = ((tonumber(item and item.itemLevel) or 0) * 0.08) + ((tonumber(item and item.quality) or 0) * 1.5)
    local matched = {}

    for index = 1, #(item and item.stats or {}) do
        local stat = item.stats[index]
        local value = tonumber(stat and stat.value)
        local token = GEAR_ENGINE.NormalizeStatToken(stat and stat.token)
        local weight = GEAR_ENGINE.StatWeightForToken(weights, token)
        if value and value > 0 and weight and GEAR_ENGINE.StatAppliesToRoleSlot(role, token, item) then
            score = score + (value * weight)
            matched[#matched + 1] = {
                token = token,
                label = StatLabel(token),
                value = value,
                weight = RoundedStatNumber(weight),
            }
        end
    end

    table.sort(matched, function(left, right)
        local leftValue = (left.value or 0) * (left.weight or 0)
        local rightValue = (right.value or 0) * (right.weight or 0)
        if leftValue ~= rightValue then
            return leftValue > rightValue
        end
        return tostring(left.label) < tostring(right.label)
    end)

    return RoundedStatNumber(score), matched
end

function GEAR_ENGINE.ItemRoleFit(item, role)
    local archetype = role and role.archetype
    local signals = GEAR_ENGINE.ROLE_FIT_SIGNALS[archetype]
    if not signals then
        return { suitable = true, reason = "not_gated", archetype = archetype }
    end

    local fit = {
        suitable = false,
        reason = "missing_role_stats",
        archetype = archetype,
        positiveStatCount = 0,
        primarySignalCount = 0,
        secondarySignalCount = 0,
        conflictSignalCount = 0,
    }

    for index = 1, #(item and item.stats or {}) do
        local stat = item.stats[index]
        local token = GEAR_ENGINE.NormalizeStatToken(stat and stat.token)
        local value = tonumber(stat and stat.value)
        if token and value and value > 0 then
            fit.positiveStatCount = fit.positiveStatCount + 1
            if signals.primary[token] then
                fit.primarySignalCount = fit.primarySignalCount + 1
            end
            if signals.secondary[token] then
                fit.secondarySignalCount = fit.secondarySignalCount + 1
            end
            if signals.conflict[token] then
                fit.conflictSignalCount = fit.conflictSignalCount + 1
            end
        end
    end

    if fit.positiveStatCount == 0 then
        fit.suitable = true
        fit.reason = "hidden_effects_require_review"
    elseif fit.primarySignalCount > 0 or (fit.secondarySignalCount > 0 and fit.conflictSignalCount == 0) then
        fit.suitable = true
        fit.reason = "role_signals_present"
    elseif fit.conflictSignalCount > 0 then
        fit.reason = "conflicting_role_stats"
    end

    return fit
end

function GEAR_ENGINE.ItemRelevantStatMap(item, weights, role)
    local values = {}

    for index = 1, #(item and item.stats or {}) do
        local stat = item.stats[index]
        local token = GEAR_ENGINE.ComparisonStatToken(stat and stat.token)
        local value = tonumber(stat and stat.value)
        if token and value and GEAR_ENGINE.StatWeightForToken(weights, token) and GEAR_ENGINE.StatAppliesToRoleSlot(role, token, item) then
            values[token] = (values[token] or 0) + value
        end
    end

    return values
end

function GEAR_ENGINE.BuildStatDeltas(currentItem, candidateItem, weights, role)
    local current = GEAR_ENGINE.ItemRelevantStatMap(currentItem, weights, role)
    local candidate = GEAR_ENGINE.ItemRelevantStatMap(candidateItem, weights, role)
    local tokens = {}
    local seen = {}
    local gains = {}
    local losses = {}

    for token in pairs(current) do
        seen[token] = true
        tokens[#tokens + 1] = token
    end
    for token in pairs(candidate) do
        if not seen[token] then
            tokens[#tokens + 1] = token
        end
    end

    for index = 1, #tokens do
        local token = tokens[index]
        local delta = (candidate[token] or 0) - (current[token] or 0)
        if delta ~= 0 then
            local entry = {
                token = token,
                label = StatLabel(token),
                value = RoundedStatNumber(math.abs(delta)),
                weightedValue = RoundedStatNumber(math.abs(delta) * (GEAR_ENGINE.StatWeightForToken(weights, token) or 0)),
            }
            if delta > 0 then
                gains[#gains + 1] = entry
            else
                losses[#losses + 1] = entry
            end
        end
    end

    local function SortDeltas(left, right)
        if left.weightedValue ~= right.weightedValue then
            return left.weightedValue > right.weightedValue
        end
        return tostring(left.label) < tostring(right.label)
    end
    table.sort(gains, SortDeltas)
    table.sort(losses, SortDeltas)
    return gains, losses
end

function GEAR_ENGINE.RecommendationEvidence(currentItem, candidateItem, gains, losses)
    local currentStats = #(currentItem and currentItem.stats or {})
    local candidateStats = #(candidateItem and candidateItem.stats or {})
    local comparedStats = #(gains or {}) + #(losses or {})
    local slotKey = GEAR_ENGINE.EquipmentSlotKey(candidateItem)

    if not currentItem or currentStats == 0 or candidateStats == 0 or slotKey == "TRINKET" or slotKey == "RANGED" then
        return "low"
    end
    if comparedStats >= 3 then
        return "high"
    end
    return "medium"
end

function GEAR_ENGINE.BenchmarkDeltaValue(benchmarkKey, token, value)
    value = tonumber(value) or 0
    token = GEAR_ENGINE.ComparisonStatToken(token)
    if benchmarkKey == "crit_immunity" then
        if token == "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT" then
            return value / 59.1
        end
        if token == "ITEM_MOD_RESILIENCE_RATING_SHORT" then
            return value / 39.4
        end
    end
    return value
end

function GEAR_ENGINE.BuildBenchmarkImpacts(role, gains, losses)
    local signed = {}
    local impacts = {}
    for index = 1, #(gains or {}) do
        local entry = gains[index]
        local token = GEAR_ENGINE.ComparisonStatToken(entry and entry.token)
        signed[token] = (signed[token] or 0) + (tonumber(entry and entry.value) or 0)
    end
    for index = 1, #(losses or {}) do
        local entry = losses[index]
        local token = GEAR_ENGINE.ComparisonStatToken(entry and entry.token)
        signed[token] = (signed[token] or 0) - (tonumber(entry and entry.value) or 0)
    end

    for index = 1, #(role and role.benchmarks or {}) do
        local benchmark = role.benchmarks[index]
        local delta = 0
        local seen = {}
        for tokenIndex = 1, #(GEAR_ENGINE.BENCHMARK_STAT_TOKENS[benchmark.key] or {}) do
            local token = GEAR_ENGINE.ComparisonStatToken(GEAR_ENGINE.BENCHMARK_STAT_TOKENS[benchmark.key][tokenIndex])
            if not seen[token] then
                delta = delta + GEAR_ENGINE.BenchmarkDeltaValue(benchmark.key, token, signed[token] or 0)
                seen[token] = true
            end
        end

        if delta ~= 0 then
            local effect
            if benchmark.status == "below" or benchmark.status == "near" then
                effect = delta > 0 and "helps_gap" or "worsens_gap"
            elseif benchmark.status == "meets_or_exceeds" then
                effect = delta > 0 and "cap_buffer" or "cap_risk"
            elseif benchmark.status == "context_required" then
                effect = delta > 0 and "context_help" or "context_risk"
            end
            if effect then
                impacts[#impacts + 1] = {
                    key = benchmark.key,
                    label = benchmark.label,
                    status = benchmark.status,
                    delta = RoundedStatNumber(delta),
                    unit = benchmark.unit,
                    effect = effect,
                }
            end
        end
    end
    return impacts
end

function GEAR_ENGINE.RecommendationVerdict(evidence, scoreGain, impacts)
    if evidence == "low" then
        return "review"
    end
    for index = 1, #(impacts or {}) do
        local effect = impacts[index] and impacts[index].effect
        if effect == "worsens_gap" or effect == "cap_risk" or effect == "context_risk" then
            return "tradeoff"
        end
    end
    if (tonumber(scoreGain) or 0) < 8 then
        return "minor"
    end
    return "upgrade"
end

function GEAR_ENGINE.RecommendationWorsensUnmetBenchmark(impacts)
    for index = 1, #(impacts or {}) do
        if impacts[index] and impacts[index].effect == "worsens_gap" then
            return true
        end
    end
    return false
end

function GEAR_ENGINE.NoUpgradeText(engine, locale)
    local rejected = tonumber(engine and engine.gateRejectedCount) or 0
    if rejected > 0 then
        return LForLocale(locale or ClientLocale(), "advice_no_safe_upgrades", rejected)
    end
    rejected = tonumber(engine and engine.unscorableRejectedCount) or 0
    if rejected > 0 then
        return LForLocale(locale or ClientLocale(), "advice_no_scorable_upgrades", rejected)
    end
    rejected = tonumber(engine and engine.loadoutRejectedCount) or 0
    if rejected > 0 then
        return LForLocale(locale or ClientLocale(), "advice_no_legal_upgrades", rejected)
    end
    return LForLocale(locale or ClientLocale(), "advice_no_upgrades")
end

function GEAR_ENGINE.VerdictCounts(upgrades)
    local counts = { upgrade = 0, minor = 0, tradeoff = 0, review = 0 }
    for index = 1, #(upgrades or {}) do
        local verdict = upgrades[index] and upgrades[index].verdict or "review"
        counts[verdict] = (counts[verdict] or 0) + 1
    end
    return counts
end

function GEAR_ENGINE.CandidateCompatibleWithClass(profile, item)
    if not item or item.category ~= "Gear" or not GEAR_ENGINE.EquipmentSlotKey(item) then
        return false
    end

    local classToken = ClassToken(profile and profile.classEnglish or "UNKNOWN")
    local subClassID = tonumber(item.subClassID)
    if item.classID == 4 and subClassID and subClassID >= 1 and subClassID <= 4 then
        local maximum = GEAR_ENGINE.CLASS_MAX_ARMOR_SUBCLASS[classToken]
        if maximum and subClassID > maximum then
            return false
        end
    end

    if item.classID == 4 and subClassID == 6 and not GEAR_ENGINE.SHIELD_CLASSES[classToken] then
        return false
    end

    if type(IsEquippableItem) == "function" and item.link then
        local ok, canEquip = pcall(IsEquippableItem, item.link)
        if ok and canEquip == false then
            return false
        end
    end

    return true
end

function GEAR_ENGINE.PriorityStats(role, weights)
    local priorities = {}
    local seen = {}

    for index = 1, #(role and role.statTokens or {}) do
        local token = role.statTokens[index]
        if not seen[token] then
            seen[token] = true
            priorities[#priorities + 1] = {
                token = token,
                label = StatLabel(token),
                weight = RoundedStatNumber(weights[token] or 0),
            }
        end
    end

    table.sort(priorities, function(left, right)
        if left.weight ~= right.weight then
            return left.weight > right.weight
        end
        return left.label < right.label
    end)

    while #priorities > 6 do
        table.remove(priorities)
    end

    return priorities
end

function GEAR_ENGINE.LocalizedDataLabel(labels, locale, fallback)
    local promptLocale = PromptLocale(locale or ClientLocale())
    return labels and (labels[promptLocale] or labels.enUS) or fallback
end

function GEAR_ENGINE.BuildPhase2CapStatuses(role)
    local statuses = {}
    for index = 1, #(role and role.caps or {}) do
        local cap = role.caps[index]
        local observed = BenchmarkObservedValue(cap.key, role and role.observed or {})
        local status = "unknown"
        if cap.kind == "context" then
            status = "context_required"
        elseif type(observed) == "number" and type(cap.target) == "number" then
            if observed >= cap.target then
                status = "meets_or_exceeds"
            elseif observed >= cap.target * 0.9 then
                status = "near"
            else
                status = "below"
            end
        end
        statuses[#statuses + 1] = {
            key = cap.key,
            labels = cap.labels,
            observed = observed,
            target = cap.target,
            unit = cap.unit,
            kind = cap.kind,
            status = status,
            note = cap.note,
        }
    end
    return statuses
end

function GEAR_ENGINE.RoleNeedsCapRecovery(role)
    for index = 1, #(role and role.benchmarks or {}) do
        local status = role.benchmarks[index] and role.benchmarks[index].status
        if status == "below" or status == "near" then
            return true
        end
    end
    return false
end

function GEAR_ENGINE.EquippedWeaponRoute(profile)
    local hasMainHand = false
    for index = 1, #(profile and profile.equipped and profile.equipped.items or {}) do
        local slotKey = GEAR_ENGINE.EquipmentSlotKey(profile.equipped.items[index])
        if slotKey == "OFFHAND" then
            return "_dw_"
        end
        if slotKey == "MAINHAND" then
            hasMainHand = true
        end
    end
    return hasMainHand and "_2h_" or nil
end

function GEAR_ENGINE.FindPhase2Preset(role, modeKey, profile)
    local presets = {}
    local fallback
    local hasRequestedMode = false
    for index = 1, #(role and role.presets or {}) do
        local preset = P2_STRATEGY_DB.GetPreset and P2_STRATEGY_DB.GetPreset(role.presets[index]) or P2_STRATEGY_DB.presets[role.presets[index]]
        if preset then
            presets[#presets + 1] = preset
            fallback = fallback or preset
            if preset.modeKey == modeKey then
                hasRequestedMode = true
            end
        end
    end

    local targetMode = modeKey
    if modeKey == "balanced" and not hasRequestedMode then
        targetMode = GEAR_ENGINE.RoleNeedsCapRecovery(role) and "cap" or "output"
    end

    local route = GEAR_ENGINE.EquippedWeaponRoute(profile)
    if route then
        for index = 1, #presets do
            local preset = presets[index]
            if preset.modeKey == targetMode and tostring(preset.key):find(route, 1, true) then
                return preset
            end
        end
    end
    for index = 1, #presets do
        if presets[index].modeKey == targetMode then
            return presets[index]
        end
    end
    return fallback
end

function GEAR_ENGINE.Phase2ItemInfo(itemID)
    if type(GetItemInfo) ~= "function" then
        return nil, nil, nil, nil, nil
    end
    local ok, name, link, quality, itemLevel, _, _, _, _, _, icon = pcall(GetItemInfo, itemID)
    if not ok then
        return nil, nil, nil, nil, nil
    end
    if not icon and type(GetItemInfoInstant) == "function" then
        local instantOK, _, _, _, _, instantIcon = pcall(GetItemInfoInstant, itemID)
        if instantOK then
            icon = instantIcon
        end
    end
    if not name and C_Item and type(C_Item.RequestLoadItemDataByID) == "function" then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
    return name, link, quality, itemLevel, icon
end

function GEAR_ENGINE.BuildPhase2PresetProgress(profile, candidateItems, role, modeKey)
    local preset = GEAR_ENGINE.FindPhase2Preset(role, modeKey, profile)
    if not preset then
        return { available = false, owned = 0, total = 0, missing = {}, items = {} }
    end

    local ownedCounts = {}
    local allItems = {}
    for index = 1, #(profile and profile.equipped and profile.equipped.items or {}) do
        allItems[#allItems + 1] = profile.equipped.items[index]
    end

    local hasSavedSnapshot = false
    for _, source in ipairs({ "bags", "bank" }) do
        for index = 1, #(profile and profile[source] and profile[source].items or {}) do
            allItems[#allItems + 1] = profile[source].items[index]
            hasSavedSnapshot = true
        end
    end
    if not hasSavedSnapshot then
        for index = 1, #(candidateItems or {}) do
            allItems[#allItems + 1] = candidateItems[index]
        end
    end
    for index = 1, #allItems do
        local itemID = tonumber(allItems[index] and (allItems[index].itemID or allItems[index].item_id))
        if itemID then
            ownedCounts[itemID] = (ownedCounts[itemID] or 0) + 1
        end
    end

    local progress = {
        available = true,
        key = preset.key,
        label = preset.label,
        source = preset.source,
        sourcePath = preset.sourcePath,
        notes = preset.notes,
        owned = 0,
        total = 0,
        missing = {},
        items = {},
    }
    for index = 1, #(preset.itemIDs or {}) do
        local itemID = tonumber(preset.itemIDs[index]) or 0
        if itemID > 0 then
            local isOwned = (ownedCounts[itemID] or 0) > 0
            if isOwned then
                ownedCounts[itemID] = ownedCounts[itemID] - 1
                progress.owned = progress.owned + 1
            end
            progress.total = progress.total + 1
            local itemName, itemLink, itemQuality, itemLevel, itemIcon = GEAR_ENGINE.Phase2ItemInfo(itemID)
            local entry = {
                itemID = itemID,
                slotKey = P2_STRATEGY_DB.slotOrder and P2_STRATEGY_DB.slotOrder[index],
                name = itemName,
                link = itemLink,
                quality = itemQuality,
                itemLevel = itemLevel,
                icon = itemIcon,
                owned = isOwned,
                wowheadUrl = WOWHEAD_TBC_ITEM_URL_PREFIX .. tostring(itemID),
            }
            progress.items[#progress.items + 1] = entry
            if not isOwned then
                progress.missing[#progress.missing + 1] = entry
            end
        end
    end
    progress.percent = progress.total > 0 and RoundedStatNumber(progress.owned / progress.total * 100) or 0
    return progress
end

function GEAR_ENGINE.BuildPhase2Strategy(profile, candidateItems, role, modeKey)
    local mode = GEAR_ENGINE.FindStrategyMode(role, modeKey)
    return {
        databaseVersion = P2_STRATEGY_DB.version,
        phase = P2_STRATEGY_DB.phase,
        phaseLabel = P2_STRATEGY_DB.phaseLabel,
        patch = P2_STRATEGY_DB.patch,
        updatedAt = P2_STRATEGY_DB.updatedAt,
        roleKey = role and role.key,
        archetype = role and role.archetype,
        modeKey = mode and mode.key or "balanced",
        modeLabels = mode and mode.labels,
        modeFocus = mode and mode.focus or {},
        availableModes = GEAR_ENGINE.AvailableStrategyModes(role),
        caps = GEAR_ENGINE.BuildPhase2CapStatuses(role),
        setGoal = role and role.setGoal,
        setGoalLabels = role and role.setGoalLabels,
        talentString = role and role.talentString,
        guideUrl = role and role.guideUrl,
        evidence = role and role.researchEvidence,
        presetProgress = GEAR_ENGINE.BuildPhase2PresetProgress(profile, candidateItems, role, mode and mode.key),
        sources = P2_STRATEGY_DB.sources,
    }
end

function GEAR_ENGINE.FindStrategyRole(strategyBook, roleKey)
    for index = 1, #(strategyBook and strategyBook.roles or {}) do
        local role = strategyBook.roles[index]
        if not roleKey or role.key == roleKey then
            return role
        end
    end
    return strategyBook and strategyBook.roles and strategyBook.roles[1] or DEFAULT_STRATEGY_ROLES[1]
end

function GEAR_ENGINE.AvailableStrategyRoles(strategyBook)
    local roles = {}
    for index = 1, #(strategyBook and strategyBook.roles or {}) do
        local role = strategyBook.roles[index]
        roles[#roles + 1] = {
            key = role.key,
            label = role.label,
            labels = role.labels,
            confidence = role.confidence or 0,
            talentPoints = role.talentPoints or 0,
            talentAffinity = role.talentMap and role.talentMap.affinityScore or 0,
            keyEffectCount = #(role.talentMap and role.talentMap.effects or {}),
        }
    end
    return roles
end

function GEAR_ENGINE.CompareItems(profile, currentItem, candidateItem, strategyBook, roleKey, weights, modeKey)
    strategyBook = strategyBook or BuildStrategyBook(profile, BuildChartStats({ candidateItem }))
    local role = GEAR_ENGINE.FindStrategyRole(strategyBook, roleKey)
    local mode = GEAR_ENGINE.FindStrategyMode(role, modeKey)
    weights = weights or GEAR_ENGINE.BuildRoleStatWeights(role, mode and mode.key)
    local currentScore = currentItem and GEAR_ENGINE.ItemRoleScore(currentItem, role, weights) or 0
    local candidateScore, matchedStats = GEAR_ENGINE.ItemRoleScore(candidateItem, role, weights)
    local scoreGain = candidateScore - currentScore
    local statGains, statLosses = GEAR_ENGINE.BuildStatDeltas(currentItem, candidateItem, weights, role)
    local evidence = GEAR_ENGINE.RecommendationEvidence(currentItem, candidateItem, statGains, statLosses)
    local benchmarkImpacts = GEAR_ENGINE.BuildBenchmarkImpacts(role, statGains, statLosses)
    local currentSlot = GEAR_ENGINE.EquipmentSlotKey(currentItem)
    local candidateSlot = GEAR_ENGINE.EquipmentSlotKey(candidateItem)
    local slotCompatible = not currentItem or currentSlot == candidateSlot
    local loadoutCompatible, loadoutReason = GEAR_ENGINE.LoadoutCompatible(profile, candidateItem)
    local comparable = #(candidateItem and candidateItem.stats or {}) > 0
        and (not currentItem or #(currentItem and currentItem.stats or {}) > 0)
    local roleFit = GEAR_ENGINE.ItemRoleFit(candidateItem, role)
    local verdict = not slotCompatible and "incompatible"
        or (not loadoutCompatible and "loadout_mismatch")
        or (not roleFit.suitable and "role_mismatch")
        or (not comparable and "unscorable")
        or GEAR_ENGINE.RecommendationVerdict(evidence, scoreGain, benchmarkImpacts)
    local blockedByHardGate = GEAR_ENGINE.RecommendationWorsensUnmetBenchmark(benchmarkImpacts)
    return {
        slotKey = candidateSlot or currentSlot,
        slotCompatible = slotCompatible,
        loadoutCompatible = loadoutCompatible,
        loadoutReason = loadoutReason,
        comparable = comparable,
        current = currentItem,
        candidate = candidateItem,
        currentScore = currentScore,
        candidateScore = candidateScore,
        scoreGain = RoundedStatNumber(scoreGain),
        matchedStats = matchedStats,
        statGains = statGains,
        statLosses = statLosses,
        benchmarkImpacts = benchmarkImpacts,
        blockedByHardGate = blockedByHardGate,
        evidence = evidence,
        verdict = verdict,
        roleFit = roleFit,
        roleKey = role.key,
        roleLabel = role.label,
        roleLabels = role.labels,
        modeKey = mode and mode.key or "balanced",
        modeLabels = mode and mode.labels,
        talentMap = role.talentMap,
    }
end

function GEAR_ENGINE.BuildGearRecommendations(profile, candidateItems, strategyBook, roleKey, modeKey)
    strategyBook = strategyBook or BuildStrategyBook(profile, BuildChartStats(candidateItems or {}))
    local role = GEAR_ENGINE.FindStrategyRole(strategyBook, roleKey)
    local mode = GEAR_ENGINE.FindStrategyMode(role, modeKey)
    local weights = GEAR_ENGINE.BuildRoleStatWeights(role, mode and mode.key)
    local currentBySlot = {}
    local equippedItems = profile and profile.equipped and profile.equipped.items or {}

    for index = 1, #equippedItems do
        local item = equippedItems[index]
        local slotKey = GEAR_ENGINE.EquipmentSlotKey(item)
        if slotKey and slotKey ~= "SHIRT" and slotKey ~= "TABARD" then
            local score, matched = GEAR_ENGINE.ItemRoleScore(item, role, weights)
            local current = { item = item, score = score, matchedStats = matched }
            if not currentBySlot[slotKey] or score < currentBySlot[slotKey].score then
                currentBySlot[slotKey] = current
            end
        end
    end

    local bestBySlot = {}
    local candidateCount = 0
    local roleRejectedCount = 0
    local gateRejectedCount = 0
    local loadoutRejectedCount = 0
    local unscorableRejectedCount = 0
    for index = 1, #(candidateItems or {}) do
        local item = candidateItems[index]
        local slotKey = GEAR_ENGINE.EquipmentSlotKey(item)
        if slotKey ~= "SHIRT" and slotKey ~= "TABARD" and GEAR_ENGINE.CandidateCompatibleWithClass(profile, item) then
            local roleFit = GEAR_ENGINE.ItemRoleFit(item, role)
            if roleFit.suitable then
                candidateCount = candidateCount + 1
                local current = currentBySlot[slotKey]
                local recommendation = GEAR_ENGINE.CompareItems(profile, current and current.item or nil, item, strategyBook, role.key, weights, mode and mode.key)
                if not recommendation.loadoutCompatible then
                    loadoutRejectedCount = loadoutRejectedCount + 1
                elseif not recommendation.comparable then
                    unscorableRejectedCount = unscorableRejectedCount + 1
                elseif recommendation.scoreGain >= 2 and #recommendation.matchedStats > 0 then
                    if recommendation.blockedByHardGate then
                        gateRejectedCount = gateRejectedCount + 1
                    elseif not bestBySlot[slotKey] or recommendation.candidateScore > bestBySlot[slotKey].candidateScore then
                        bestBySlot[slotKey] = recommendation
                    end
                end
            else
                roleRejectedCount = roleRejectedCount + 1
            end
        end
    end

    local upgrades = {}
    local slotRank = {}
    for index = 1, #GEAR_ENGINE.GEAR_SLOT_ORDER do
        slotRank[GEAR_ENGINE.GEAR_SLOT_ORDER[index]] = index
        if bestBySlot[GEAR_ENGINE.GEAR_SLOT_ORDER[index]] then
            upgrades[#upgrades + 1] = bestBySlot[GEAR_ENGINE.GEAR_SLOT_ORDER[index]]
        end
    end

    table.sort(upgrades, function(left, right)
        if left.scoreGain ~= right.scoreGain then
            return left.scoreGain > right.scoreGain
        end
        return (slotRank[left.slotKey] or 99) < (slotRank[right.slotKey] or 99)
    end)

    local benchmarkGaps = {}
    for index = 1, #(role and role.benchmarks or {}) do
        local benchmark = role.benchmarks[index]
        if benchmark.status == "below" or benchmark.status == "near" or benchmark.status == "context_required" then
            benchmarkGaps[#benchmarkGaps + 1] = benchmark
        end
    end

    return {
        version = 8,
        generatedAt = Now(),
        roleKey = role.key,
        roleLabel = role.label,
        roleLabels = role.labels,
        roleConfidence = role.confidence or 0,
        modeKey = mode and mode.key or "balanced",
        modeLabels = mode and mode.labels,
        availableModes = GEAR_ENGINE.AvailableStrategyModes(role),
        roleWeights = weights,
        talentMap = role.talentMap,
        availableRoles = GEAR_ENGINE.AvailableStrategyRoles(strategyBook),
        equippedCount = #equippedItems,
        candidateCount = candidateCount,
        roleRejectedCount = roleRejectedCount,
        gateRejectedCount = gateRejectedCount,
        loadoutRejectedCount = loadoutRejectedCount,
        unscorableRejectedCount = unscorableRejectedCount,
        priorityStats = GEAR_ENGINE.PriorityStats(role, weights),
        benchmarkGaps = benchmarkGaps,
        upgrades = upgrades,
        verdictCounts = GEAR_ENGINE.VerdictCounts(upgrades),
        equipped = equippedItems,
        phase2 = GEAR_ENGINE.BuildPhase2Strategy(profile, candidateItems, role, mode and mode.key),
        caveat = LForLocale(profile and profile.locale or ClientLocale(), "advice_caveat"),
    }
end

local function AppendCharacterStatsJson(lines, indent, characterStats, comma)
    characterStats = characterStats or BuildCharacterStatsSnapshot()
    AppendIndented(lines, indent, "\"character_stats\": {")
    AppendIndented(lines, indent + 2, JsonField("updated_at", FormatTime(characterStats.updatedAt), true))
    AppendIndented(lines, indent + 2, JsonField("api", characterStats.api or "paper_doll", true))
    AppendIndented(lines, indent + 2, JsonField("level", characterStats.level, true))
    AppendIndented(lines, indent + 2, "\"race\": {")
    AppendIndented(lines, indent + 4, JsonField("localized", characterStats.race and characterStats.race.localized, true))
    AppendIndented(lines, indent + 4, JsonField("token", characterStats.race and characterStats.race.english, true))
    AppendIndented(lines, indent + 4, JsonField("id", characterStats.race and characterStats.race.id, true))
    AppendIndented(lines, indent + 4, JsonField("faction", characterStats.race and characterStats.race.faction, true))
    AppendIndented(lines, indent + 4, JsonField("faction_localized", characterStats.race and characterStats.race.factionLocalized, false))
    AppendIndented(lines, indent + 2, "},")
    AppendIndented(lines, indent + 2, "\"group\": {")
    AppendIndented(lines, indent + 4, JsonField("type", characterStats.group and characterStats.group.type, true))
    AppendIndented(lines, indent + 4, JsonField("size", characterStats.group and characterStats.group.size, true))
    AppendIndented(lines, indent + 4, JsonField("party_members", characterStats.group and characterStats.group.partyMembers, true))
    AppendIndented(lines, indent + 4, JsonField("raid_members", characterStats.group and characterStats.group.raidMembers, false))
    AppendIndented(lines, indent + 2, "},")
    AppendJsonObjectArray(lines, indent + 2, "attributes", characterStats.attributes, {
        { name = "key", value = "key" },
        { name = "label", value = "label" },
        { name = "base", value = "base" },
        { name = "effective", value = "effective" },
        { name = "positive", value = "positive" },
        { name = "negative", value = "negative" },
    }, true)
    AppendIndented(lines, indent + 2, "\"armor\": {")
    AppendIndented(lines, indent + 4, JsonField("base", characterStats.armor and characterStats.armor.base, true))
    AppendIndented(lines, indent + 4, JsonField("effective", characterStats.armor and characterStats.armor.effective, true))
    AppendIndented(lines, indent + 4, JsonField("positive", characterStats.armor and characterStats.armor.positive, true))
    AppendIndented(lines, indent + 4, JsonField("negative", characterStats.armor and characterStats.armor.negative, false))
    AppendIndented(lines, indent + 2, "},")
    AppendIndented(lines, indent + 2, "\"defense\": {")
    AppendIndented(lines, indent + 4, JsonField("base", characterStats.defense and characterStats.defense.base, true))
    AppendIndented(lines, indent + 4, JsonField("modifier", characterStats.defense and characterStats.defense.modifier, true))
    AppendIndented(lines, indent + 4, JsonField("effective", characterStats.defense and characterStats.defense.effective, false))
    AppendIndented(lines, indent + 2, "},")
    AppendIndented(lines, indent + 2, "\"attack_power\": {")
    AppendIndented(lines, indent + 4, JsonField("melee", characterStats.attackPower and characterStats.attackPower.melee and characterStats.attackPower.melee.effective, true))
    AppendIndented(lines, indent + 4, JsonField("ranged", characterStats.attackPower and characterStats.attackPower.ranged and characterStats.attackPower.ranged.effective, false))
    AppendIndented(lines, indent + 2, "},")
    AppendJsonObjectArray(lines, indent + 2, "ratings", characterStats.ratings, {
        { name = "key", value = "key" },
        { name = "label", value = "label" },
        { name = "global", value = "global" },
        { name = "rating_id", value = "rating_id" },
        { name = "rating", value = "rating" },
        { name = "bonus", value = "bonus" },
    }, true)
    AppendIndented(lines, indent + 2, "\"chances\": {")
    AppendIndented(lines, indent + 4, JsonField("melee_crit", characterStats.chances and characterStats.chances.meleeCrit, true))
    AppendIndented(lines, indent + 4, JsonField("ranged_crit", characterStats.chances and characterStats.chances.rangedCrit, true))
    AppendIndented(lines, indent + 4, JsonField("dodge", characterStats.chances and characterStats.chances.dodge, true))
    AppendIndented(lines, indent + 4, JsonField("parry", characterStats.chances and characterStats.chances.parry, true))
    AppendIndented(lines, indent + 4, JsonField("block", characterStats.chances and characterStats.chances.block, true))
    AppendJsonObjectArray(lines, indent + 4, "spell_crit", characterStats.chances and characterStats.chances.spellCrit, {
        { name = "key", value = "key" },
        { name = "label", value = "label" },
        { name = "crit", value = "crit" },
    }, false)
    AppendIndented(lines, indent + 2, "},")
    AppendIndented(lines, indent + 2, "\"spell\": {")
    AppendIndented(lines, indent + 4, JsonField("healing", characterStats.spell and characterStats.spell.healing, true))
    AppendIndented(lines, indent + 4, JsonField("mana_regen_casting", characterStats.spell and characterStats.spell.manaRegenCasting, true))
    AppendIndented(lines, indent + 4, JsonField("mana_regen_not_casting", characterStats.spell and characterStats.spell.manaRegenNotCasting, true))
    AppendJsonObjectArray(lines, indent + 4, "spell_damage", characterStats.spell and characterStats.spell.spellDamage, {
        { name = "key", value = "key" },
        { name = "label", value = "label" },
        { name = "bonus", value = "bonus" },
    }, false)
    AppendIndented(lines, indent + 2, "}")
    AppendIndented(lines, indent, "}" .. (comma and "," or ""))
end

local function AppendObservedStatsJson(lines, indent, observed)
    observed = observed or {}
    AppendIndented(lines, indent, "\"observed\": {")
    AppendIndented(lines, indent + 2, "\"hit\": {")
    AppendIndented(lines, indent + 4, JsonField("melee", observed.hit and observed.hit.melee, true))
    AppendIndented(lines, indent + 4, JsonField("ranged", observed.hit and observed.hit.ranged, true))
    AppendIndented(lines, indent + 4, JsonField("spell", observed.hit and observed.hit.spell, true))
    AppendIndented(lines, indent + 4, JsonField("expertise", observed.hit and observed.hit.expertise, false))
    AppendIndented(lines, indent + 2, "},")
    AppendIndented(lines, indent + 2, "\"crit\": {")
    AppendIndented(lines, indent + 4, JsonField("melee", observed.crit and observed.crit.melee, true))
    AppendIndented(lines, indent + 4, JsonField("ranged", observed.crit and observed.crit.ranged, true))
    AppendIndented(lines, indent + 4, JsonField("spell_best", observed.crit and observed.crit.spellBest, false))
    AppendIndented(lines, indent + 2, "},")
    AppendIndented(lines, indent + 2, "\"tank\": {")
    AppendIndented(lines, indent + 4, JsonField("defense", observed.tank and observed.tank.defense, true))
    AppendIndented(lines, indent + 4, JsonField("crit_reduction", observed.tank and observed.tank.critReduction, true))
    AppendIndented(lines, indent + 4, JsonField("crit_reduction_target", observed.tank and observed.tank.critReductionTarget, true))
    AppendIndented(lines, indent + 4, JsonField("crit_reduction_gap", observed.tank and observed.tank.critImmunity and observed.tank.critImmunity.gap, true))
    AppendIndented(lines, indent + 4, JsonField("crit_reduction_from_talents", observed.tank and observed.tank.critImmunity and observed.tank.critImmunity.talentReduction, true))
    AppendIndented(lines, indent + 4, JsonField("crit_reduction_from_defense", observed.tank and observed.tank.critImmunity and observed.tank.critImmunity.defenseReduction, true))
    AppendIndented(lines, indent + 4, JsonField("crit_reduction_from_resilience", observed.tank and observed.tank.critImmunity and observed.tank.critImmunity.resilienceReduction, true))
    AppendIndented(lines, indent + 4, JsonField("resilience_rating", observed.tank and observed.tank.critImmunity and observed.tank.critImmunity.resilienceRating, true))
    AppendIndented(lines, indent + 4, JsonField("resilience_rating_source", observed.tank and observed.tank.critImmunity and observed.tank.critImmunity.resilienceRatingSource, true))
    AppendIndented(lines, indent + 4, JsonField("armor", observed.tank and observed.tank.armor, true))
    AppendIndented(lines, indent + 4, JsonField("stamina", observed.tank and observed.tank.stamina, true))
    AppendIndented(lines, indent + 4, JsonField("dodge", observed.tank and observed.tank.dodge, true))
    AppendIndented(lines, indent + 4, JsonField("parry", observed.tank and observed.tank.parry, true))
    AppendIndented(lines, indent + 4, JsonField("block", observed.tank and observed.tank.block, true))
    AppendIndented(lines, indent + 4, JsonField("known_avoidance_block", observed.tank and observed.tank.knownAvoidanceBlock, false))
    AppendIndented(lines, indent + 2, "},")
    AppendIndented(lines, indent + 2, "\"power\": {")
    AppendIndented(lines, indent + 4, JsonField("attack_power", observed.power and observed.power.attackPower, true))
    AppendIndented(lines, indent + 4, JsonField("ranged_attack_power", observed.power and observed.power.rangedAttackPower, true))
    AppendIndented(lines, indent + 4, JsonField("spell_power_best", observed.power and observed.power.spellPowerBest, true))
    AppendIndented(lines, indent + 4, JsonField("healing", observed.power and observed.power.healing, true))
    AppendIndented(lines, indent + 4, JsonField("mana_regen_casting", observed.power and observed.power.manaRegenCasting, false))
    AppendIndented(lines, indent + 2, "},")
    AppendJsonObjectArray(lines, indent + 2, "gear_stat_highlights", observed.gearStatHighlights, {
        { name = "token", value = "token" },
        { name = "label", value = "label" },
        { name = "value", value = "value" },
        { name = "item_count", value = "itemCount" },
        { name = "stack_count", value = "stackCount" },
    }, false)
    AppendIndented(lines, indent, "}")
end

local function AppendTalentRoleMapJson(lines, indent, talentMap, comma)
    talentMap = talentMap or {}
    AppendIndented(lines, indent, "\"talent_mapping\": {")
    AppendIndented(lines, indent + 2, JsonField("version", talentMap.version or 1, true))
    AppendIndented(lines, indent + 2, JsonField("selected_count", talentMap.selectedCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("selected_points", talentMap.selectedPoints or 0, true))
    AppendIndented(lines, indent + 2, JsonField("mapped_count", talentMap.mappedCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("aligned_count", talentMap.alignedCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("aligned_points", talentMap.alignedPoints or 0, true))
    AppendIndented(lines, indent + 2, JsonField("coverage", talentMap.coverage or 0, true))
    AppendIndented(lines, indent + 2, JsonField("affinity_score", talentMap.affinityScore or 0, true))
    AppendJsonObjectArray(lines, indent + 2, "selected_talents", talentMap.selected, {
        { name = "tree_index", value = "treeIndex" },
        { name = "tree_name", value = "treeName" },
        { name = "talent_index", value = "talentIndex" },
        { name = "name", value = "name" },
        { name = "icon", value = "icon" },
        { name = "rank", value = "rank" },
        { name = "max_rank", value = "maxRank" },
        { name = "aligned", value = "aligned" },
        { name = "effect_key", value = "effectKey" },
    }, true)
    AppendJsonObjectArray(lines, indent + 2, "key_effects", talentMap.effects, {
        { name = "key", value = "key" },
        { name = "name", value = "name" },
        { name = "icon", value = "icon" },
        { name = "rank", value = "rank" },
        { name = "max_rank", value = "maxRank" },
    }, true)
    AppendJsonObjectArray(lines, indent + 2, "weight_modifiers", talentMap.weightModifiers, {
        { name = "token", value = "token" },
        { name = "multiplier", value = "multiplier" },
    }, false)
    AppendIndented(lines, indent, "}" .. (comma and "," or ""))
end

local function AppendStrategyBookJson(lines, indent, strategyBook, comma)
    strategyBook = strategyBook or BuildStrategyBook({}, BuildChartStats({}))
    AppendIndented(lines, indent, "\"strategy_book\": {")
    AppendIndented(lines, indent + 2, JsonField("version", strategyBook.version or 1, true))
    AppendIndented(lines, indent + 2, JsonField("generated_at", FormatTime(strategyBook.generatedAt), true))
    AppendIndented(lines, indent + 2, JsonField("class_token", strategyBook.classToken, true))
    AppendIndented(lines, indent + 2, JsonField("race_token", strategyBook.raceToken, true))
    AppendIndented(lines, indent + 2, JsonField("group_type", strategyBook.groupType, true))
    AppendJsonStringArray(lines, indent + 2, "race_notes", strategyBook.raceNotes, true)
    AppendJsonStringArray(lines, indent + 2, "group_notes", strategyBook.groupNotes, true)
    AppendIndented(lines, indent + 2, "\"phase_database\": {")
    AppendIndented(lines, indent + 4, JsonField("version", strategyBook.phaseDatabase and strategyBook.phaseDatabase.version, true))
    AppendIndented(lines, indent + 4, JsonField("phase", strategyBook.phaseDatabase and strategyBook.phaseDatabase.phase, true))
    AppendIndented(lines, indent + 4, JsonField("phase_label", strategyBook.phaseDatabase and strategyBook.phaseDatabase.phaseLabel, true))
    AppendIndented(lines, indent + 4, JsonField("patch", strategyBook.phaseDatabase and strategyBook.phaseDatabase.patch, true))
    AppendIndented(lines, indent + 4, JsonField("updated_at", strategyBook.phaseDatabase and strategyBook.phaseDatabase.updatedAt, false))
    AppendIndented(lines, indent + 2, "},")
    AppendIndented(lines, indent + 2, "\"roles\": [")

    for roleIndex = 1, #(strategyBook.roles or {}) do
        local role = strategyBook.roles[roleIndex]
        AppendIndented(lines, indent + 4, "{")
        AppendIndented(lines, indent + 6, JsonField("key", role.key, true))
        AppendIndented(lines, indent + 6, JsonField("label", role.label, true))
        AppendIndented(lines, indent + 6, JsonField("label_zh_cn", role.labels and role.labels.zhCN, true))
        AppendIndented(lines, indent + 6, JsonField("archetype", role.archetype, true))
        AppendIndented(lines, indent + 6, JsonField("phase", role.phase, true))
        AppendIndented(lines, indent + 6, JsonField("confidence", role.confidence, true))
        AppendIndented(lines, indent + 6, JsonField("talent_points", role.talentPoints, true))
        AppendIndented(lines, indent + 6, JsonField("primary_talent_match", role.primaryTalentMatch and true or false, true))
        AppendJsonStringArray(lines, indent + 6, "models", role.models, true)
        AppendJsonStringArray(lines, indent + 6, "priorities", role.priorities, true)
        AppendIndented(lines, indent + 6, JsonField("set_goal", role.setGoal, true))
        AppendIndented(lines, indent + 6, JsonField("set_goal_zh_cn", role.setGoalLabels and role.setGoalLabels.zhCN, true))
        AppendIndented(lines, indent + 6, JsonField("talent_string", role.talentString, true))
        AppendIndented(lines, indent + 6, JsonField("guide_url", role.guideUrl, true))
        AppendIndented(lines, indent + 6, JsonField("research_evidence", role.researchEvidence, true))
        AppendIndented(lines, indent + 6, "\"modes\": [")
        for modeIndex = 1, #(role.modes or {}) do
            local mode = role.modes[modeIndex]
            AppendIndented(lines, indent + 8, "{ " .. JsonField("key", mode.key, true)
                .. " " .. JsonField("label_en", mode.labels and mode.labels.enUS, true)
                .. " " .. JsonField("label_zh_cn", mode.labels and mode.labels.zhCN, false)
                .. " }" .. (modeIndex < #(role.modes or {}) and "," or ""))
        end
        AppendIndented(lines, indent + 6, "],")
        AppendIndented(lines, indent + 6, "\"caps\": [")
        for capIndex = 1, #(role.caps or {}) do
            local cap = role.caps[capIndex]
            AppendIndented(lines, indent + 8, "{ " .. JsonField("key", cap.key, true)
                .. " " .. JsonField("label_en", cap.labels and cap.labels.enUS, true)
                .. " " .. JsonField("label_zh_cn", cap.labels and cap.labels.zhCN, true)
                .. " " .. JsonField("target", cap.target, true)
                .. " " .. JsonField("unit", cap.unit, true)
                .. " " .. JsonField("kind", cap.kind, false)
                .. " }" .. (capIndex < #(role.caps or {}) and "," or ""))
        end
        AppendIndented(lines, indent + 6, "],")
        AppendTalentRoleMapJson(lines, indent + 6, role.talentMap, true)
        AppendObservedStatsJson(lines, indent + 6, role.observed)
        AppendIndented(lines, indent + 6, ",")
        AppendJsonObjectArray(lines, indent + 6, "benchmarks", role.benchmarks, {
            { name = "key", value = "key" },
            { name = "label", value = "label" },
            { name = "observed", value = "observed" },
            { name = "target", value = "target" },
            { name = "unit", value = "unit" },
            { name = "status", value = "status" },
            { name = "note", value = "note" },
        }, true)
        AppendJsonStringArray(lines, indent + 6, "notes", role.notes, false)
        AppendIndented(lines, indent + 4, "}" .. (roleIndex < #(strategyBook.roles or {}) and "," or ""))
    end

    AppendIndented(lines, indent + 2, "]")
    AppendIndented(lines, indent, "}" .. (comma and "," or ""))
end

function GEAR_ENGINE.AppendGearItemJson(lines, indent, key, item, score, comma)
    if not item then
        AppendIndented(lines, indent, JsonString(key) .. ": null" .. (comma and "," or ""))
        return
    end

    AppendIndented(lines, indent, JsonString(key) .. ": {")
    AppendIndented(lines, indent + 2, JsonField("name", item.name, true))
    AppendIndented(lines, indent + 2, JsonField("item_id", item.itemID, true))
    AppendIndented(lines, indent + 2, JsonField("item_link", item.link, true))
    AppendIndented(lines, indent + 2, JsonField("wowhead_url", ItemWowheadURL(item), true))
    AppendIndented(lines, indent + 2, JsonField("item_level", item.itemLevel, true))
    AppendIndented(lines, indent + 2, JsonField("quality_id", item.quality, true))
    AppendIndented(lines, indent + 2, JsonField("equip_slot", item.equipSlot, true))
    AppendIndented(lines, indent + 2, JsonField("slot_key", GEAR_ENGINE.EquipmentSlotKey(item), true))
    AppendIndented(lines, indent + 2, JsonField("inventory_slot", item.inventorySlot, true))
    AppendIndented(lines, indent + 2, JsonField("source", item.source, true))
    AppendIndented(lines, indent + 2, JsonField("location", item.location, true))
    AppendIndented(lines, indent + 2, JsonField("score", score, true))
    AppendIndented(lines, indent + 2, JsonField("stats_text", FormatStats(item.stats), true))
    AppendIndented(lines, indent + 2, "\"stats\": [")
    for index = 1, #(item.stats or {}) do
        local stat = item.stats[index]
        AppendIndented(lines, indent + 4, "{ " .. JsonField("token", stat.token, true) .. " " .. JsonField("label", stat.label, true) .. " " .. JsonField("value", stat.value, false) .. " }" .. (index < #(item.stats or {}) and "," or ""))
    end
    AppendIndented(lines, indent + 2, "]")
    AppendIndented(lines, indent, "}" .. (comma and "," or ""))
end

function GEAR_ENGINE.AppendPhase2StrategyJson(lines, indent, phase2, comma)
    phase2 = phase2 or {}
    local progress = phase2.presetProgress or { available = false, items = {}, missing = {} }
    AppendIndented(lines, indent, "\"phase2_strategy\": {")
    AppendIndented(lines, indent + 2, JsonField("database_version", phase2.databaseVersion, true))
    AppendIndented(lines, indent + 2, JsonField("phase", phase2.phase, true))
    AppendIndented(lines, indent + 2, JsonField("phase_label", phase2.phaseLabel, true))
    AppendIndented(lines, indent + 2, JsonField("patch", phase2.patch, true))
    AppendIndented(lines, indent + 2, JsonField("updated_at", phase2.updatedAt, true))
    AppendIndented(lines, indent + 2, JsonField("role_key", phase2.roleKey, true))
    AppendIndented(lines, indent + 2, JsonField("archetype", phase2.archetype, true))
    AppendIndented(lines, indent + 2, JsonField("mode_key", phase2.modeKey, true))
    AppendIndented(lines, indent + 2, JsonField("mode_label_en", phase2.modeLabels and phase2.modeLabels.enUS, true))
    AppendIndented(lines, indent + 2, JsonField("mode_label_zh_cn", phase2.modeLabels and phase2.modeLabels.zhCN, true))
    AppendIndented(lines, indent + 2, JsonField("set_goal", phase2.setGoal, true))
    AppendIndented(lines, indent + 2, JsonField("set_goal_zh_cn", phase2.setGoalLabels and phase2.setGoalLabels.zhCN, true))
    AppendIndented(lines, indent + 2, JsonField("talent_string", phase2.talentString, true))
    AppendIndented(lines, indent + 2, JsonField("evidence", phase2.evidence, true))
    AppendIndented(lines, indent + 2, JsonField("guide_url", phase2.guideUrl, true))
    AppendJsonStringArray(lines, indent + 2, "mode_focus", phase2.modeFocus, true)
    AppendIndented(lines, indent + 2, "\"available_modes\": [")
    for index = 1, #(phase2.availableModes or {}) do
        local mode = phase2.availableModes[index]
        AppendIndented(lines, indent + 4, "{ " .. JsonField("key", mode.key, true)
            .. " " .. JsonField("label_en", mode.labels and mode.labels.enUS, true)
            .. " " .. JsonField("label_zh_cn", mode.labels and mode.labels.zhCN, false)
            .. " }" .. (index < #(phase2.availableModes or {}) and "," or ""))
    end
    AppendIndented(lines, indent + 2, "],")
    AppendIndented(lines, indent + 2, "\"caps\": [")
    for index = 1, #(phase2.caps or {}) do
        local cap = phase2.caps[index]
        AppendIndented(lines, indent + 4, "{ " .. JsonField("key", cap.key, true)
            .. " " .. JsonField("label_en", cap.labels and cap.labels.enUS, true)
            .. " " .. JsonField("label_zh_cn", cap.labels and cap.labels.zhCN, true)
            .. " " .. JsonField("observed", cap.observed, true)
            .. " " .. JsonField("target", cap.target, true)
            .. " " .. JsonField("unit", cap.unit, true)
            .. " " .. JsonField("kind", cap.kind, true)
            .. " " .. JsonField("status", cap.status, true)
            .. " " .. JsonField("note", cap.note, false)
            .. " }" .. (index < #(phase2.caps or {}) and "," or ""))
    end
    AppendIndented(lines, indent + 2, "],")
    AppendIndented(lines, indent + 2, "\"target_preset\": {")
    AppendIndented(lines, indent + 4, JsonField("available", progress.available and true or false, true))
    AppendIndented(lines, indent + 4, JsonField("key", progress.key, true))
    AppendIndented(lines, indent + 4, JsonField("label", progress.label, true))
    AppendIndented(lines, indent + 4, JsonField("source", progress.source, true))
    AppendIndented(lines, indent + 4, JsonField("source_path", progress.sourcePath, true))
    AppendIndented(lines, indent + 4, JsonField("owned", progress.owned or 0, true))
    AppendIndented(lines, indent + 4, JsonField("total", progress.total or 0, true))
    AppendIndented(lines, indent + 4, JsonField("percent", progress.percent or 0, true))
    AppendIndented(lines, indent + 4, "\"items\": [")
    for index = 1, #(progress.items or {}) do
        local item = progress.items[index]
        AppendIndented(lines, indent + 6, "{ " .. JsonField("item_id", item.itemID, true)
            .. " " .. JsonField("name", item.name, true)
            .. " " .. JsonField("item_link", item.link, true)
            .. " " .. JsonField("quality_id", item.quality, true)
            .. " " .. JsonField("item_level", item.itemLevel, true)
            .. " " .. JsonField("slot_key", item.slotKey, true)
            .. " " .. JsonField("owned", item.owned and true or false, true)
            .. " " .. JsonField("wowhead_url", item.wowheadUrl, false)
            .. " }" .. (index < #(progress.items or {}) and "," or ""))
    end
    AppendIndented(lines, indent + 4, "]")
    AppendIndented(lines, indent + 2, "},")
    AppendIndented(lines, indent + 2, "\"sources\": [")
    for index = 1, #(phase2.sources or {}) do
        local source = phase2.sources[index]
        AppendIndented(lines, indent + 4, "{ " .. JsonField("key", source.key, true)
            .. " " .. JsonField("label", source.label, true)
            .. " " .. JsonField("url", source.url, true)
            .. " " .. JsonField("commit", source.commit, true)
            .. " " .. JsonField("use", source.use, false)
            .. " }" .. (index < #(phase2.sources or {}) and "," or ""))
    end
    AppendIndented(lines, indent + 2, "]")
    AppendIndented(lines, indent, "}" .. (comma and "," or ""))
end

function GEAR_ENGINE.AppendGearRecommendationsJson(lines, indent, engine, comma)
    engine = engine or GEAR_ENGINE.BuildGearRecommendations({}, {}, nil)
    AppendIndented(lines, indent, "\"gear_recommendations\": {")
    AppendIndented(lines, indent + 2, JsonField("version", engine.version or 1, true))
    AppendIndented(lines, indent + 2, JsonField("generated_at", FormatTime(engine.generatedAt), true))
    AppendIndented(lines, indent + 2, JsonField("role_key", engine.roleKey, true))
    AppendIndented(lines, indent + 2, JsonField("role_label", engine.roleLabel, true))
    AppendIndented(lines, indent + 2, JsonField("role_confidence", engine.roleConfidence, true))
    AppendIndented(lines, indent + 2, JsonField("mode_key", engine.modeKey, true))
    AppendIndented(lines, indent + 2, JsonField("mode_label_en", engine.modeLabels and engine.modeLabels.enUS, true))
    AppendIndented(lines, indent + 2, JsonField("mode_label_zh_cn", engine.modeLabels and engine.modeLabels.zhCN, true))
    AppendIndented(lines, indent + 2, JsonField("equipped_count", engine.equippedCount, true))
    AppendIndented(lines, indent + 2, JsonField("candidate_count", engine.candidateCount, true))
    AppendIndented(lines, indent + 2, JsonField("role_rejected_count", engine.roleRejectedCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("gate_rejected_count", engine.gateRejectedCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("loadout_rejected_count", engine.loadoutRejectedCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("unscorable_rejected_count", engine.unscorableRejectedCount or 0, true))
    AppendIndented(lines, indent + 2, JsonField("caveat", engine.caveat, true))
    AppendJsonObjectArray(lines, indent + 2, "available_roles", engine.availableRoles, {
        { name = "key", value = "key" },
        { name = "label", value = "label" },
        { name = "confidence", value = "confidence" },
        { name = "talent_points", value = "talentPoints" },
        { name = "talent_affinity", value = "talentAffinity" },
        { name = "key_effect_count", value = "keyEffectCount" },
    }, true)
    AppendTalentRoleMapJson(lines, indent + 2, engine.talentMap, true)
    GEAR_ENGINE.AppendPhase2StrategyJson(lines, indent + 2, engine.phase2, true)
    local verdictCounts = engine.verdictCounts or GEAR_ENGINE.VerdictCounts(engine.upgrades)
    AppendIndented(lines, indent + 2, "\"verdict_counts\": { "
        .. JsonField("upgrade", verdictCounts.upgrade or 0, true) .. " "
        .. JsonField("minor", verdictCounts.minor or 0, true) .. " "
        .. JsonField("tradeoff", verdictCounts.tradeoff or 0, true) .. " "
        .. JsonField("review", verdictCounts.review or 0, false) .. " },")
    AppendJsonObjectArray(lines, indent + 2, "priority_stats", engine.priorityStats, {
        { name = "token", value = "token" },
        { name = "label", value = "label" },
        { name = "weight", value = "weight" },
    }, true)
    AppendJsonObjectArray(lines, indent + 2, "benchmark_gaps", engine.benchmarkGaps, {
        { name = "key", value = "key" },
        { name = "label", value = "label" },
        { name = "observed", value = "observed" },
        { name = "target", value = "target" },
        { name = "unit", value = "unit" },
        { name = "status", value = "status" },
    }, true)
    AppendIndented(lines, indent + 2, "\"equipped_gear\": [")
    for index = 1, #(engine.equipped or {}) do
        local item = engine.equipped[index]
        local score = GEAR_ENGINE.ItemRoleScore(item, nil, engine.roleWeights or {})
        AppendIndented(lines, indent + 4, "{")
        GEAR_ENGINE.AppendGearItemJson(lines, indent + 6, "item", item, score, false)
        AppendIndented(lines, indent + 4, "}" .. (index < #(engine.equipped or {}) and "," or ""))
    end
    AppendIndented(lines, indent + 2, "],")
    AppendIndented(lines, indent + 2, "\"upgrades\": [")
    for index = 1, #(engine.upgrades or {}) do
        local upgrade = engine.upgrades[index]
        AppendIndented(lines, indent + 4, "{")
        AppendIndented(lines, indent + 6, JsonField("slot_key", upgrade.slotKey, true))
        AppendIndented(lines, indent + 6, JsonField("score_gain", upgrade.scoreGain, true))
        AppendIndented(lines, indent + 6, JsonField("evidence", upgrade.evidence, true))
        AppendIndented(lines, indent + 6, JsonField("verdict", upgrade.verdict, true))
        GEAR_ENGINE.AppendGearItemJson(lines, indent + 6, "current", upgrade.current, upgrade.currentScore, true)
        GEAR_ENGINE.AppendGearItemJson(lines, indent + 6, "candidate", upgrade.candidate, upgrade.candidateScore, true)
        AppendJsonObjectArray(lines, indent + 6, "matched_stats", upgrade.matchedStats, {
            { name = "token", value = "token" },
            { name = "label", value = "label" },
            { name = "value", value = "value" },
            { name = "weight", value = "weight" },
        }, true)
        AppendJsonObjectArray(lines, indent + 6, "stat_gains", upgrade.statGains, {
            { name = "token", value = "token" },
            { name = "label", value = "label" },
            { name = "value", value = "value" },
            { name = "weighted_value", value = "weightedValue" },
        }, true)
        AppendJsonObjectArray(lines, indent + 6, "stat_losses", upgrade.statLosses, {
            { name = "token", value = "token" },
            { name = "label", value = "label" },
            { name = "value", value = "value" },
            { name = "weighted_value", value = "weightedValue" },
        }, true)
        AppendJsonObjectArray(lines, indent + 6, "benchmark_impacts", upgrade.benchmarkImpacts, {
            { name = "key", value = "key" },
            { name = "label", value = "label" },
            { name = "status", value = "status" },
            { name = "delta", value = "delta" },
            { name = "effect", value = "effect" },
        }, false)
        AppendIndented(lines, indent + 4, "}" .. (index < #(engine.upgrades or {}) and "," or ""))
    end
    AppendIndented(lines, indent + 2, "]")
    AppendIndented(lines, indent, "}" .. (comma and "," or ""))
end

function GEAR_ENGINE.GearRoleLabel(engine, locale)
    local localized = ANALYSIS_LOCALIZATION[PromptLocale(locale or ClientLocale())]
    local fallback = localized and localized.roles and localized.roles[engine.roleKey] or engine.roleLabel or engine.roleKey
    return GEAR_ENGINE.LocalizedDataLabel(engine and engine.roleLabels, locale, fallback)
end

function GEAR_ENGINE.Phase2ModeLabel(engine, locale)
    return GEAR_ENGINE.LocalizedDataLabel(engine and engine.phase2 and engine.phase2.modeLabels, locale, engine and engine.modeKey or "balanced")
end

function GEAR_ENGINE.Phase2EvidenceLabel(engine, locale)
    local evidence = engine and engine.phase2 and engine.phase2.evidence or "sim_and_guide"
    local promptLocale = PromptLocale(locale or ClientLocale())
    if promptLocale == "enUS" then
        return evidence == "guide" and "guide-backed" or "simulation preset + class guide"
    end
    if promptLocale == "zhTW" then
        return evidence == "guide" and "職業攻略" or "模擬器預設 + 職業攻略"
    end
    return evidence == "guide" and "职业攻略" or "模拟器预设 + 职业攻略"
end

function GEAR_ENGINE.Phase2CapText(engine, locale)
    local values = {}
    local localized = ANALYSIS_LOCALIZATION[PromptLocale(locale or ClientLocale())]
    for index = 1, #(engine and engine.phase2 and engine.phase2.caps or {}) do
        local cap = engine.phase2.caps[index]
        local label = GEAR_ENGINE.LocalizedDataLabel(cap.labels, locale, cap.key)
        local status = localized and localized.statuses and localized.statuses[cap.status] or cap.status
        local observed = type(cap.observed) == "number" and CompactNumber(cap.observed, 2) or "?"
        local target = type(cap.target) == "number" and CompactNumber(cap.target, 2) or "?"
        values[#values + 1] = tostring(label) .. " " .. observed .. "/" .. target .. tostring(cap.unit or "") .. " (" .. tostring(status or "unknown") .. ")"
    end
    return #values > 0 and table.concat(values, "; ") or GEAR_ENGINE.ReportTerms(locale).none
end

function GEAR_ENGINE.Phase2PresetText(engine, locale, maxMissing)
    local progress = engine and engine.phase2 and engine.phase2.presetProgress
    if not progress or not progress.available then
        return GEAR_ENGINE.ReportTerms(locale).no_preset
    end

    local missing = {}
    for index = 1, math.min(#(progress.missing or {}), maxMissing or 6) do
        local item = progress.missing[index]
        missing[#missing + 1] = tostring(item.name or ("Item #" .. tostring(item.itemID)))
    end
    return tostring(progress.label) .. " · " .. tostring(progress.owned or 0) .. "/" .. tostring(progress.total or 0)
        .. " (" .. tostring(progress.percent or 0) .. "%)"
        .. (#missing > 0 and " · " .. table.concat(missing, ", ") or "")
end

function GEAR_ENGINE.Phase2Goal(engine, locale)
    local phase2 = engine and engine.phase2 or {}
    return GEAR_ENGINE.LocalizedDataLabel(phase2.setGoalLabels, locale, phase2.setGoal or GEAR_ENGINE.ReportTerms(locale).none)
end

function GEAR_ENGINE.GearPriorityText(engine, locale)
    local values = {}
    local localized = ANALYSIS_LOCALIZATION[PromptLocale(locale or ClientLocale())]
    for index = 1, #(engine and engine.priorityStats or {}) do
        local priority = engine.priorityStats[index]
        values[#values + 1] = localized and localized.stats and localized.stats[priority.token] or priority.label
    end
    return #values > 0 and table.concat(values, ", ") or "none"
end

function GEAR_ENGINE.GearBenchmarkText(engine, locale)
    local values = {}
    local localized = ANALYSIS_LOCALIZATION[PromptLocale(locale or ClientLocale())]
    for index = 1, #(engine and engine.benchmarkGaps or {}) do
        local gap = engine.benchmarkGaps[index]
        local label = localized and localized.benchmarks and localized.benchmarks[gap.key] or gap.label or gap.key
        local status = localized and localized.statuses and localized.statuses[gap.status] or gap.status
        values[#values + 1] = tostring(label) .. " " .. CompactNumber(gap.observed or 0, 2) .. "/" .. CompactNumber(gap.target or 0, 2)
            .. " (" .. tostring(status or "unknown") .. ")"
    end
    return #values > 0 and table.concat(values, "; ") or LForLocale(locale or ClientLocale(), "advice_no_gaps")
end

function GEAR_ENGINE.GearMatchedStatsText(upgrade, locale)
    return GEAR_ENGINE.FormatLocalizedStats(upgrade and upgrade.matchedStats or {}, locale, 3)
end

function GEAR_ENGINE.AppendGearRecommendationsMarkdown(lines, engine, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    lines[#lines + 1] = "## " .. terms.gear_recommendations
    lines[#lines + 1] = ""
    lines[#lines + 1] = "- " .. terms.role .. ": " .. tostring(GEAR_ENGINE.GearRoleLabel(engine, locale)) .. " (" .. terms.confidence .. " " .. tostring(engine.roleConfidence or 0) .. ")"
    lines[#lines + 1] = "- " .. terms.mode .. ": " .. Addon.MarkdownEscape(GEAR_ENGINE.Phase2ModeLabel(engine, locale))
    lines[#lines + 1] = "- " .. terms.caps .. ": " .. Addon.MarkdownEscape(GEAR_ENGINE.Phase2CapText(engine, locale))
    lines[#lines + 1] = "- " .. terms.set_goal .. ": " .. Addon.MarkdownEscape(GEAR_ENGINE.Phase2Goal(engine, locale))
    lines[#lines + 1] = "- " .. terms.target_preset .. ": " .. Addon.MarkdownEscape(GEAR_ENGINE.Phase2PresetText(engine, locale, 6))
    lines[#lines + 1] = "- " .. terms.research_evidence .. ": " .. Addon.MarkdownEscape(GEAR_ENGINE.Phase2EvidenceLabel(engine, locale))
        .. (engine.phase2 and engine.phase2.guideUrl and " ([Wowhead](" .. engine.phase2.guideUrl .. "))" or "")
    lines[#lines + 1] = "- " .. terms.verdict .. ": " .. GEAR_ENGINE.VerdictSummary(engine, locale)
    lines[#lines + 1] = "- " .. terms.talent_map .. ": " .. GEAR_ENGINE.TalentMapSummary(engine.talentMap, locale, 5)
    lines[#lines + 1] = "- " .. terms.priority_stats .. ": " .. GEAR_ENGINE.GearPriorityText(engine, locale)
    lines[#lines + 1] = "- " .. terms.benchmark_gaps .. ": " .. GEAR_ENGINE.GearBenchmarkText(engine, locale)
    lines[#lines + 1] = "- " .. terms.caveat .. ": " .. tostring(engine.caveat)
    lines[#lines + 1] = ""
    for index = 1, #(engine.upgrades or {}) do
        local upgrade = engine.upgrades[index]
        local current = upgrade.current and Addon.MarkdownPlainItemName(upgrade.current) or LForLocale(locale, "advice_empty_slot")
        local candidate = Addon.MarkdownPlainItemName(upgrade.candidate)
        lines[#lines + 1] = "### " .. tostring(index) .. ". " .. Addon.MarkdownEscape(GEAR_ENGINE.EquipmentSlotLabel(upgrade.slotKey, locale))
            .. " · " .. Addon.MarkdownEscape(GEAR_ENGINE.RecommendationVerdictLabel(upgrade.verdict, locale))
            .. " · +" .. Addon.MarkdownEscape(CompactNumber(upgrade.scoreGain, 2))
        lines[#lines + 1] = "- " .. terms.current .. ": " .. current
        lines[#lines + 1] = "- " .. terms.suggested .. ": " .. candidate
        lines[#lines + 1] = "- " .. terms.gains .. ": " .. Addon.MarkdownEscape(GEAR_ENGINE.DeltaText(upgrade.statGains, locale))
        lines[#lines + 1] = "- " .. terms.losses .. ": " .. Addon.MarkdownEscape(GEAR_ENGINE.DeltaText(upgrade.statLosses, locale))
        lines[#lines + 1] = "- " .. terms.benchmark_impact .. ": " .. Addon.MarkdownEscape(GEAR_ENGINE.BenchmarkImpactText(upgrade.benchmarkImpacts, locale))
        lines[#lines + 1] = "- " .. terms.evidence .. ": " .. Addon.MarkdownEscape(GEAR_ENGINE.EvidenceLabel(upgrade.evidence, locale))
        lines[#lines + 1] = ""
    end
    if #(engine.upgrades or {}) == 0 then
        lines[#lines + 1] = Addon.MarkdownEscape(GEAR_ENGINE.NoUpgradeText(engine, locale))
        lines[#lines + 1] = ""
    end
end

function GEAR_ENGINE.AppendGearRecommendationsText(lines, engine, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    lines[#lines + 1] = terms.gear_recommendations
    lines[#lines + 1] = terms.role .. ": " .. tostring(GEAR_ENGINE.GearRoleLabel(engine, locale)) .. "; " .. terms.confidence .. " " .. tostring(engine.roleConfidence or 0)
    lines[#lines + 1] = terms.mode .. ": " .. GEAR_ENGINE.Phase2ModeLabel(engine, locale)
    lines[#lines + 1] = terms.caps .. ": " .. GEAR_ENGINE.Phase2CapText(engine, locale)
    lines[#lines + 1] = terms.set_goal .. ": " .. GEAR_ENGINE.Phase2Goal(engine, locale)
    lines[#lines + 1] = terms.target_preset .. ": " .. GEAR_ENGINE.Phase2PresetText(engine, locale, 6)
    lines[#lines + 1] = terms.research_evidence .. ": " .. GEAR_ENGINE.Phase2EvidenceLabel(engine, locale)
        .. (engine.phase2 and engine.phase2.guideUrl and " | " .. engine.phase2.guideUrl or "")
    lines[#lines + 1] = terms.verdict .. ": " .. GEAR_ENGINE.VerdictSummary(engine, locale)
    lines[#lines + 1] = terms.talent_map .. ": " .. GEAR_ENGINE.TalentMapSummary(engine.talentMap, locale, 5)
    lines[#lines + 1] = terms.priority_stats .. ": " .. GEAR_ENGINE.GearPriorityText(engine, locale)
    lines[#lines + 1] = terms.benchmark_gaps .. ": " .. GEAR_ENGINE.GearBenchmarkText(engine, locale)
    for index = 1, #(engine.upgrades or {}) do
        local upgrade = engine.upgrades[index]
        local current = upgrade.current and upgrade.current.name or LForLocale(locale, "advice_empty_slot")
        lines[#lines + 1] = tostring(index) .. ". " .. GEAR_ENGINE.EquipmentSlotLabel(upgrade.slotKey, locale)
            .. " · " .. GEAR_ENGINE.RecommendationVerdictLabel(upgrade.verdict, locale)
            .. " · " .. terms.score .. " +" .. CompactNumber(upgrade.scoreGain, 2)
        lines[#lines + 1] = "   " .. terms.current .. ": " .. tostring(current)
        lines[#lines + 1] = "   " .. terms.suggested .. ": " .. tostring(upgrade.candidate and upgrade.candidate.name)
        lines[#lines + 1] = "   " .. terms.gains .. ": " .. GEAR_ENGINE.DeltaText(upgrade.statGains, locale)
        lines[#lines + 1] = "   " .. terms.losses .. ": " .. GEAR_ENGINE.DeltaText(upgrade.statLosses, locale)
        lines[#lines + 1] = "   " .. terms.benchmark_impact .. ": " .. GEAR_ENGINE.BenchmarkImpactText(upgrade.benchmarkImpacts, locale)
        lines[#lines + 1] = "   " .. terms.evidence .. ": " .. GEAR_ENGINE.EvidenceLabel(upgrade.evidence, locale)
    end
    if #(engine.upgrades or {}) == 0 then
        lines[#lines + 1] = GEAR_ENGINE.NoUpgradeText(engine, locale)
    end
    lines[#lines + 1] = terms.caveat .. ": " .. tostring(engine.caveat)
    lines[#lines + 1] = ""
end

local function AnalysisLocale(locale)
    return PromptLocale(locale or ClientLocale())
end

local function AnalysisLocalization(locale)
    return ANALYSIS_LOCALIZATION[AnalysisLocale(locale)]
end

local function AnalysisLookup(locale, section, key, fallback)
    local localized = AnalysisLocalization(locale)
    local values = localized and localized[section]
    return (values and values[key]) or fallback or key
end

local function AnalysisValue(value, suffix, locale)
    if type(value) == "number" then
        return CompactNumber(value, 2) .. (suffix or "")
    end

    if value ~= nil and value ~= "" then
        return tostring(value) .. (suffix or "")
    end

    return LForLocale(locale or ClientLocale(), "analysis_unknown")
end

local function AnalysisClassName(profile, locale)
    local classToken = ClassToken(profile and (profile.classEnglish or profile.class))
    return AnalysisLookup(locale, "classes", classToken, profile and (profile.classLocalized or profile.classEnglish) or nil) or "Unknown Class"
end

local function AnalysisRaceName(race, locale)
    local token = RaceToken(race and (race.english or race.localized))
    return AnalysisLookup(locale, "races", token, race and (race.localized or race.english) or nil) or "Unknown Race"
end

local function AnalysisGroupType(groupType, locale)
    return AnalysisLookup(locale, "groupTypes", groupType or "solo", groupType or "solo")
end

local function AnalysisRoleLabel(role, locale)
    local fallback = role and (role.label or role.key) or "Role"
    return GEAR_ENGINE.LocalizedDataLabel(role and role.labels, locale, AnalysisLookup(locale, "roles", role and role.key, fallback))
end

local function AnalysisModelLabels(models, locale)
    local labels = {}

    for index = 1, #(models or {}) do
        labels[#labels + 1] = AnalysisLookup(locale, "models", models[index], models[index])
    end

    return table.concat(labels, ", ")
end

function GEAR_ENGINE.RoleHasModel(role, expected)
    for index = 1, #(role and role.models or {}) do
        if role.models[index] == expected then
            return true
        end
    end
    return false
end

function GEAR_ENGINE.RoleUsesHitModel(role)
    return GEAR_ENGINE.RoleHasModel(role, "tank_threat")
        or GEAR_ENGINE.RoleHasModel(role, "spell_threat")
        or GEAR_ENGINE.RoleHasModel(role, "melee_dps")
        or GEAR_ENGINE.RoleHasModel(role, "ranged_dps")
        or GEAR_ENGINE.RoleHasModel(role, "caster_dps")
end

local function AnalysisBenchmarkLabel(benchmark, locale)
    return AnalysisLookup(locale, "benchmarks", benchmark and benchmark.key, benchmark and (benchmark.label or benchmark.key) or "Benchmark")
end

local function AnalysisBenchmarkStatus(status, locale)
    return AnalysisLookup(locale, "statuses", status or "unknown", status or "unknown")
end

local function AnalysisBenchmarkUnit(unit, locale)
    return AnalysisLookup(locale, "units", unit or "", unit or "")
end

local function AnalysisRaceNotes(race, locale)
    local localized = AnalysisLocalization(locale)
    local token = RaceToken(race and (race.english or race.localized))
    return localized and localized.raceNotes and localized.raceNotes[token] or race and race.notes or {}
end

local function AnalysisGroupNotes(group, locale)
    local localized = AnalysisLocalization(locale)
    local groupType = group and group.type or "solo"
    return localized and localized.groupNotes and localized.groupNotes[groupType] or group and group.notes or {}
end

local function AppendFirstAnalysisNotes(lines, locale, key, notes)
    for index = 1, math.min(#(notes or {}), 2) do
        lines[#lines + 1] = LForLocale(locale, key, notes[index])
    end
end

local function AnalysisStatLabel(stat, locale)
    return AnalysisLookup(locale, "stats", stat and stat.token, stat and stat.label or nil) or "Unknown Stat"
end

function GEAR_ENGINE.CoreStatsText(characterStats, role, locale)
    characterStats = characterStats or {}
    local chances = characterStats.chances or {}
    local spell = characterStats.spell or {}
    local attackPower = characterStats.attackPower or {}
    local defense = characterStats.defense or {}
    local armor = characterStats.armor or {}
    local archetype = role and role.archetype

    if archetype == "tank" then
        local tank = role and role.observed and role.observed.tank or {}
        local critImmunity = tank.critImmunity or GEAR_ENGINE.BuildCritImmunity(characterStats, role and role.talentMap)
        return LForLocale(locale, "overview_stats_tank",
            AnalysisValue(critImmunity.total, nil, locale),
            AnalysisValue(critImmunity.target, nil, locale),
            AnalysisValue(armor.effective, nil, locale),
            AnalysisValue(AttributeValue(characterStats, "stamina"), nil, locale),
            AnalysisValue(KnownAvoidanceBlock(chances), "%", locale))
    end
    if archetype == "melee" then
        return LForLocale(locale, "overview_stats_melee",
            AnalysisValue(RatingBonus(characterStats, "melee_hit"), "%", locale),
            AnalysisValue(RatingBonus(characterStats, "expertise"), "%", locale),
            AnalysisValue(chances.meleeCrit, "%", locale),
            AnalysisValue(attackPower.melee and attackPower.melee.effective, nil, locale))
    end
    if archetype == "ranged" then
        return LForLocale(locale, "overview_stats_ranged",
            AnalysisValue(RatingBonus(characterStats, "ranged_hit"), "%", locale),
            AnalysisValue(chances.rangedCrit, "%", locale),
            AnalysisValue(attackPower.ranged and attackPower.ranged.effective, nil, locale),
            AnalysisValue(AttributeValue(characterStats, "agility"), nil, locale))
    end
    if archetype == "caster" then
        return LForLocale(locale, "overview_stats_caster",
            AnalysisValue(RatingBonus(characterStats, "spell_hit"), "%", locale),
            AnalysisValue(BestSpellValue(chances.spellCrit, "crit"), "%", locale),
            AnalysisValue(BestSpellValue(spell.spellDamage, "bonus"), nil, locale),
            AnalysisValue(AttributeValue(characterStats, "intellect"), nil, locale))
    end
    if archetype == "healer" then
        return LForLocale(locale, "overview_stats_healer",
            AnalysisValue(spell.healing, nil, locale),
            AnalysisValue(BestSpellValue(chances.spellCrit, "crit"), "%", locale),
            AnalysisValue(spell.manaRegenCasting, nil, locale),
            AnalysisValue(AttributeValue(characterStats, "intellect"), nil, locale))
    end
    return LForLocale(locale, "overview_stats",
        AnalysisValue(defense.effective, nil, locale),
        AnalysisValue(armor.effective, nil, locale),
        AnalysisValue(RatingBonus(characterStats, "melee_hit"), "%", locale),
        AnalysisValue(RatingBonus(characterStats, "spell_hit"), "%", locale),
        AnalysisValue(chances.meleeCrit, "%", locale),
        AnalysisValue(BestSpellValue(chances.spellCrit, "crit"), "%", locale))
end

function GEAR_ENGINE.RoleHitCritText(role, observed, locale)
    local hit = observed and observed.hit or {}
    local crit = observed and observed.crit or {}
    if role and role.archetype == "ranged" then
        return LForLocale(locale, "analysis_role_hit_ranged",
            AnalysisValue(hit.ranged, "%", locale),
            AnalysisValue(crit.ranged, "%", locale))
    end
    if role and role.archetype == "melee" then
        return LForLocale(locale, "analysis_role_hit_melee",
            AnalysisValue(hit.melee, "%", locale),
            AnalysisValue(hit.expertise, "%", locale),
            AnalysisValue(crit.melee, "%", locale))
    end
    if role and role.archetype == "caster" then
        return LForLocale(locale, "analysis_role_hit_caster",
            AnalysisValue(hit.spell, "%", locale),
            AnalysisValue(crit.spellBest, "%", locale))
    end
    return LForLocale(locale, "analysis_role_hit",
        AnalysisValue(hit.melee, "%", locale),
        AnalysisValue(hit.spell, "%", locale),
        AnalysisValue(crit.melee, "%", locale),
        AnalysisValue(crit.spellBest, "%", locale))
end

local function FormatAnalysisStats(stats, locale)
    if not stats or #stats == 0 then
        return "none"
    end

    local parts = {}
    for index = 1, #stats do
        local stat = stats[index]
        local value = stat and stat.value
        local label = AnalysisStatLabel(stat, locale)
        local formatted = CompactNumber(value or 0, 2)
        if value and value < 0 then
            parts[#parts + 1] = formatted .. " " .. label
        else
            parts[#parts + 1] = "+" .. formatted .. " " .. label
        end
    end

    return table.concat(parts, ", ")
end

local function BuildStatsAnalysisText(profile, chartStats, strategyBook)
    profile = profile or {}
    local locale = AnalysisLocale(profile.locale or ClientLocale())
    local characterStats = profile.characterStats or BuildCharacterStatsSnapshot()
    chartStats = chartStats or BuildChartStats({})
    strategyBook = strategyBook or BuildStrategyBook(profile, chartStats)

    local race = characterStats.race or {}
    local group = characterStats.group or {}
    local chances = characterStats.chances or {}
    local spell = characterStats.spell or {}
    local attackPower = characterStats.attackPower or {}
    local defense = characterStats.defense or {}
    local armor = characterStats.armor or {}
    local lines = {
        LForLocale(locale, "analysis_title"),
        "",
        LForLocale(locale, "analysis_character",
            tostring(profile.player or "Unknown Player"),
            AnalysisClassName(profile, locale),
            AnalysisRaceName(race, locale),
            AnalysisGroupType(group.type or "solo", locale),
            tostring(group.size or 1)),
        LForLocale(locale, "analysis_talents", TalentSummaryText(profile.talents, locale)),
        LForLocale(locale, "analysis_talent_points", TalentTreePointsText(profile.talents, locale), TalentSelectedPointsText(profile.talents, locale, 8)),
        LForLocale(locale, "analysis_defense",
            AnalysisValue(defense.effective, nil, locale),
            AnalysisValue(armor.effective, nil, locale),
            AnalysisValue(AttributeValue(characterStats, "stamina"), nil, locale),
            AnalysisValue(chances.dodge, "%", locale),
            AnalysisValue(chances.parry, "%", locale),
            AnalysisValue(chances.block, "%", locale)),
        LForLocale(locale, "analysis_hit",
            AnalysisValue(RatingBonus(characterStats, "melee_hit"), "%", locale),
            AnalysisValue(RatingBonus(characterStats, "ranged_hit"), "%", locale),
            AnalysisValue(RatingBonus(characterStats, "spell_hit"), "%", locale),
            AnalysisValue(RatingBonus(characterStats, "expertise"), "%", locale)),
        LForLocale(locale, "analysis_crit",
            AnalysisValue(chances.meleeCrit, "%", locale),
            AnalysisValue(chances.rangedCrit, "%", locale),
            AnalysisValue(BestSpellValue(chances.spellCrit, "crit"), "%", locale)),
        LForLocale(locale, "analysis_power",
            AnalysisValue(attackPower.melee and attackPower.melee.effective, nil, locale),
            AnalysisValue(attackPower.ranged and attackPower.ranged.effective, nil, locale),
            AnalysisValue(BestSpellValue(spell.spellDamage, "bonus"), nil, locale),
            AnalysisValue(spell.healing, nil, locale),
            AnalysisValue(spell.manaRegenCasting, nil, locale)),
    }

    AppendFirstAnalysisNotes(lines, locale, "analysis_race_note", AnalysisRaceNotes(race, locale))
    AppendFirstAnalysisNotes(lines, locale, "analysis_group_note", AnalysisGroupNotes(group, locale))

    lines[#lines + 1] = ""
    lines[#lines + 1] = LForLocale(locale, "analysis_roles_title")

    local roles = strategyBook.roles or {}
    if #roles == 0 then
        lines[#lines + 1] = LForLocale(locale, "analysis_no_roles")
    end

    for roleIndex = 1, math.min(#roles, 3) do
        local role = roles[roleIndex]
        local observed = role.observed or {}
        local tank = observed.tank or {}
        lines[#lines + 1] = ""
        lines[#lines + 1] = LForLocale(locale, "analysis_role", AnalysisRoleLabel(role, locale), AnalysisValue(role.confidence, nil, locale), AnalysisValue(role.talentPoints, nil, locale))
        lines[#lines + 1] = LForLocale(locale, "advice_talent_map", GEAR_ENGINE.TalentMapSummary(role.talentMap, locale, 5))
        lines[#lines + 1] = LForLocale(locale, "analysis_models", AnalysisModelLabels(role.models, locale))
        if GEAR_ENGINE.RoleUsesHitModel(role) then
            lines[#lines + 1] = GEAR_ENGINE.RoleHitCritText(role, observed, locale)
        end
        if GEAR_ENGINE.RoleHasModel(role, "tank_mitigation") then
            local critImmunity = tank.critImmunity or {}
            lines[#lines + 1] = LForLocale(locale, "analysis_role_tank",
                AnalysisValue(critImmunity.total, nil, locale),
                AnalysisValue(critImmunity.target, nil, locale),
                AnalysisValue(tank.defense, nil, locale),
                AnalysisValue(tank.armor, nil, locale),
                AnalysisValue(tank.knownAvoidanceBlock, "%", locale))
            lines[#lines + 1] = LForLocale(locale, "analysis_crit_immunity_breakdown",
                AnalysisValue(critImmunity.talentReduction, nil, locale),
                AnalysisValue(critImmunity.defenseReduction, nil, locale),
                AnalysisValue(critImmunity.resilienceReduction, nil, locale),
                AnalysisValue(critImmunity.resilienceRating, nil, locale),
                AnalysisValue(critImmunity.gap, nil, locale))
        end

        for benchmarkIndex = 1, math.min(#(role.benchmarks or {}), 4) do
            local benchmark = role.benchmarks[benchmarkIndex]
            lines[#lines + 1] = LForLocale(locale, "analysis_benchmark",
                AnalysisBenchmarkLabel(benchmark, locale),
                AnalysisBenchmarkStatus(benchmark and benchmark.status, locale),
                AnalysisValue(benchmark and benchmark.observed, nil, locale),
                AnalysisValue(benchmark and benchmark.target, nil, locale),
                AnalysisBenchmarkUnit(benchmark and benchmark.unit, locale))
        end

        if observed.gearStatHighlights and #observed.gearStatHighlights > 0 then
            lines[#lines + 1] = LForLocale(locale, "analysis_highlights", FormatAnalysisStats(observed.gearStatHighlights, locale))
        end
    end

    return table.concat(lines, "\n"), #roles
end

function Addon.CompactCountList(entries, labeler, maxCount)
    local parts = {}
    local omitted = 0
    maxCount = maxCount or 4

    for index = 1, #(entries or {}) do
        local entry = entries[index]
        if #parts < maxCount then
            parts[#parts + 1] = tostring(labeler(entry)) .. " " .. tostring(entry.itemCount or 0)
        else
            omitted = omitted + 1
        end
    end

    if #parts == 0 then
        return "none"
    end

    if omitted > 0 then
        parts[#parts + 1] = "+" .. tostring(omitted)
    end

    return table.concat(parts, ", ")
end

function Addon.FirstEntries(entries, maxCount)
    local selected = {}

    for index = 1, math.min(#(entries or {}), maxCount or 6) do
        selected[#selected + 1] = entries[index]
    end

    return selected
end

function Addon.MarkdownEscape(value)
    value = tostring(value or "")
    value = value:gsub("\n", " "):gsub("|", "\\|")
    return value
end

function Addon.MarkdownPlainItemName(item)
    local name = Addon.MarkdownEscape(item and item.name or "Unknown Item")
    local url = ItemWowheadURL(item)

    if url then
        return "[" .. name .. "](" .. url .. ")"
    end

    return name
end

function Addon.ShortStats(stats, maxCount, locale)
    return GEAR_ENGINE.FormatLocalizedStats(stats, locale or "enUS", maxCount or 4)
end

function Addon.BuildOverviewText(profile, chartStats, strategyBook, items)
    profile = profile or {}
    chartStats = chartStats or BuildChartStats(items or {})
    strategyBook = strategyBook or BuildStrategyBook(profile, chartStats)

    local locale = AnalysisLocale(profile.locale or ClientLocale())
    local characterStats = profile.characterStats or BuildCharacterStatsSnapshot()
    local race = characterStats.race or {}
    local group = characterStats.group or {}
    local chances = characterStats.chances or {}
    local defense = characterStats.defense or {}
    local armor = characterStats.armor or {}
    local roles = strategyBook.roles or {}
    local lines = {
        LForLocale(locale, "overview_title"),
        "",
        LForLocale(locale, "analysis_character",
            tostring(profile.player or "Unknown Player"),
            AnalysisClassName(profile, locale),
            AnalysisRaceName(race, locale),
            AnalysisGroupType(group.type or "solo", locale),
            tostring(group.size or 1)),
        LForLocale(locale, "overview_inventory",
            chartStats.itemCount or 0,
            chartStats.stackCount or 0,
            chartStats.gearItemCount or 0,
            chartStats.equippableItemCount or 0),
        LForLocale(locale, "overview_talents", TalentTreePointsText(profile.talents, locale), TalentSelectedPointsText(profile.talents, locale, 5)),
        GEAR_ENGINE.CoreStatsText(characterStats, roles[1], locale),
        LForLocale(locale, "overview_categories", Addon.CompactCountList(chartStats.categoryCounts, function(entry) return entry.name end, 5)),
        LForLocale(locale, "overview_quality", Addon.CompactCountList(chartStats.qualityCounts, function(entry) return entry.quality or "Unknown" end, 4)),
        LForLocale(locale, "overview_top_stats", FormatAnalysisStats(Addon.FirstEntries(chartStats.statTotals, 6), locale)),
        "",
        LForLocale(locale, "overview_roles_title"),
    }

    if #roles == 0 then
        lines[#lines + 1] = LForLocale(locale, "analysis_no_roles")
    else
        for roleIndex = 1, math.min(#roles, 3) do
            local role = roles[roleIndex]
            lines[#lines + 1] = LForLocale(locale, "overview_role",
                AnalysisRoleLabel(role, locale),
                AnalysisValue(role.confidence, nil, locale),
                AnalysisValue(role.talentPoints, nil, locale),
                AnalysisModelLabels(role.models, locale))
        end
    end

    return table.concat(lines, "\n"), #roles
end

function Addon.AppendMarkdownQuickSummary(lines, profile, scope, filter, items, chartStats, strategyBook)
    local characterStats = profile.characterStats or BuildCharacterStatsSnapshot()
    local roles = strategyBook.roles or {}
    local topRole = roles[1]
    local locale = profile.locale or ClientLocale()
    local terms = GEAR_ENGINE.ReportTerms(locale)

    lines[#lines + 1] = "## " .. terms.quick_summary
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| " .. terms.field .. " | " .. terms.value .. " |"
    lines[#lines + 1] = "| --- | --- |"
    lines[#lines + 1] = "| " .. terms.character .. " | " .. Addon.MarkdownEscape(tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm")) .. " |"
    lines[#lines + 1] = "| " .. terms.class .. " | " .. Addon.MarkdownEscape(AnalysisClassName(profile, locale)) .. " |"
    lines[#lines + 1] = "| " .. terms.scope_filter .. " | " .. Addon.MarkdownEscape(LocalizedScopeTitle(scope, locale) .. " / " .. LocalizedExportFilterTitle(filter, locale)) .. " |"
    lines[#lines + 1] = "| " .. terms.items .. " | " .. tostring(#items) .. " " .. terms.item_lines .. ", " .. tostring(chartStats.stackCount or 0) .. " " .. terms.stacks .. ", " .. tostring(chartStats.gearItemCount or 0) .. " " .. terms.gear .. " |"
    lines[#lines + 1] = "| " .. terms.talents .. " | " .. Addon.MarkdownEscape(TalentTreePointsText(profile.talents, locale)) .. " |"
    lines[#lines + 1] = "| " .. terms.selected_talents .. " | " .. Addon.MarkdownEscape(TalentSelectedPointsText(profile.talents, locale, 8)) .. " |"
    lines[#lines + 1] = "| " .. terms.top_role .. " | " .. Addon.MarkdownEscape(topRole and (AnalysisRoleLabel(topRole, locale) .. " (" .. terms.confidence .. " " .. tostring(topRole.confidence or 0) .. ")") or terms.none) .. " |"
    lines[#lines + 1] = "| " .. terms.core_stats .. " | " .. Addon.MarkdownEscape(GEAR_ENGINE.CoreStatsText(characterStats, topRole, locale)) .. " |"
    lines[#lines + 1] = "| " .. terms.categories .. " | " .. Addon.MarkdownEscape(Addon.CompactCountList(chartStats.categoryCounts, function(entry) return GEAR_ENGINE.CategoryLabel(entry.name, locale) end, 5)) .. " |"
    lines[#lines + 1] = "| " .. terms.top_stats .. " | " .. Addon.MarkdownEscape(GEAR_ENGINE.FormatLocalizedStats(chartStats.statTotals, locale, 8)) .. " |"
    lines[#lines + 1] = ""
end

function Addon.AppendMarkdownRoleSnapshot(lines, strategyBook, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    lines[#lines + 1] = "## " .. terms.role_snapshot
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| " .. terms.role .. " | " .. terms.confidence .. " | " .. terms.talent_points .. " | " .. terms.models .. " | " .. terms.current_highlights .. " |"
    lines[#lines + 1] = "| --- | ---: | ---: | --- | --- |"

    for roleIndex = 1, math.min(#(strategyBook.roles or {}), 5) do
        local role = strategyBook.roles[roleIndex]
        lines[#lines + 1] = "| " .. Addon.MarkdownEscape(AnalysisRoleLabel(role, locale))
            .. " | " .. tostring(role.confidence or 0)
            .. " | " .. tostring(role.talentPoints or 0)
            .. " | " .. Addon.MarkdownEscape(AnalysisModelLabels(role.models, locale))
            .. " | " .. Addon.MarkdownEscape(GEAR_ENGINE.FormatLocalizedStats(role.observed and role.observed.gearStatHighlights, locale, 6))
            .. " |"
    end

    if #(strategyBook.roles or {}) == 0 then
        lines[#lines + 1] = "| " .. terms.none .. " | 0 | 0 | " .. terms.none .. " | " .. terms.none .. " |"
    end

    lines[#lines + 1] = ""
end

function Addon.AppendMarkdownItemTable(lines, category, bucket, defaultOpen, locale)
    local terms = GEAR_ENGINE.ReportTerms(locale)
    lines[#lines + 1] = defaultOpen and "<details open>" or "<details>"
    lines[#lines + 1] = "<summary>" .. Addon.MarkdownEscape(GEAR_ENGINE.CategoryLabel(category, locale)) .. " (" .. tostring(#(bucket or {})) .. ")</summary>"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| " .. terms.item .. " | " .. terms.quality .. " | " .. terms.item_level .. " | " .. terms.source .. " | " .. terms.location .. " | " .. terms.stats .. " |"
    lines[#lines + 1] = "| --- | --- | ---: | --- | --- | --- |"

    for itemIndex = 1, #(bucket or {}) do
        local item = bucket[itemIndex]
        lines[#lines + 1] = "| " .. Addon.MarkdownPlainItemName(item)
            .. " x" .. tostring(item.count or 1)
            .. " | " .. Addon.MarkdownEscape(QualityDisplay(item))
            .. " | " .. Addon.MarkdownEscape(ItemLevelDisplay(item))
            .. " | " .. Addon.MarkdownEscape(SourceLabel(item.source, locale))
            .. " | " .. Addon.MarkdownEscape(GEAR_ENGINE.ItemLocationLabel(item, locale))
            .. " | " .. Addon.MarkdownEscape(Addon.ShortStats(item.stats, 4, locale))
            .. " |"
    end

    if #(bucket or {}) == 0 then
        lines[#lines + 1] = "| " .. terms.none .. " | - | - | - | - | - |"
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "</details>"
    lines[#lines + 1] = ""
end

local function CategoryFromInfo(classID, itemType, equipSlot)
    if IsEquippableSlot(equipSlot) then
        return "Gear"
    end

    if classID and CLASS_CATEGORY[classID] then
        return CLASS_CATEGORY[classID]
    end

    if itemType == "Weapon" or itemType == "Armor" then
        return "Gear"
    end

    if itemType == "Consumable" then
        return "Consumables"
    end

    if itemType == "Trade Goods" then
        return "Trade Goods"
    end

    if itemType == "Gem" then
        return "Gems"
    end

    if itemType == "Recipe" then
        return "Recipes"
    end

    if itemType == "Quest" or itemType == "Quest Item" then
        return "Quest Items"
    end

    if itemType == "Container" or itemType == "Quiver" then
        return "Containers"
    end

    if itemType == "Key" then
        return "Keys"
    end

    if itemType == "Projectile" then
        return "Projectiles"
    end

    if itemType == "Miscellaneous" then
        return "Miscellaneous"
    end

    return "Other"
end

local function CopyItems(items)
    local copied = {}

    for index = 1, #(items or {}) do
        copied[#copied + 1] = items[index]
    end

    return copied
end

function Addon:Print(message)
    local text = "|cff33ff99TBCGearExporter:|r " .. tostring(message)

    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    elseif print then
        print(text)
    end
end

function Addon:GetProfile()
    if not self.db then
        self.db = _G[DB_NAME] or {}
        _G[DB_NAME] = self.db
    end

    self.db.profiles = self.db.profiles or {}

    local realm = GetRealmName and GetRealmName() or "Unknown Realm"
    local player = UnitName and UnitName("player") or "Unknown Player"
    local key = player .. " - " .. realm
    local classInfo = GetPlayerClassInfo()
    local locale = ClientLocale()

    self.db.profiles[key] = self.db.profiles[key] or {
        player = player,
        realm = realm,
        locale = locale,
        classLocalized = classInfo.localized,
        classEnglish = classInfo.english,
        classID = classInfo.id,
        bags = { updatedAt = 0, items = {} },
        bank = { updatedAt = 0, items = {} },
        equipped = { updatedAt = 0, items = {}, totalSlots = #GEAR_ENGINE.EQUIPMENT_SLOTS, api = "unavailable" },
        talents = { updatedAt = 0, available = false, summary = "", tabs = {} },
        characterStats = { updatedAt = 0, api = "unavailable" },
    }

    local profile = self.db.profiles[key]
    profile.player = player
    profile.realm = realm
    profile.locale = locale
    profile.classLocalized = classInfo.localized
    profile.classEnglish = classInfo.english
    profile.classID = classInfo.id
    profile.bags = profile.bags or { updatedAt = 0, items = {} }
    profile.bank = profile.bank or { updatedAt = 0, items = {} }
    profile.equipped = profile.equipped or { updatedAt = 0, items = {}, totalSlots = #GEAR_ENGINE.EQUIPMENT_SLOTS, api = "unavailable" }
    profile.talents = profile.talents or { updatedAt = 0, available = false, summary = "", tabs = {} }
    profile.characterStats = profile.characterStats or { updatedAt = 0, api = "unavailable" }
    profile.localDB = profile.localDB or {
        name = DB_NAME,
        version = 2,
        savedAt = 0,
        bagItemCount = #(profile.bags.items or {}),
        bankItemCount = #(profile.bank.items or {}),
        equippedItemCount = #(profile.equipped.items or {}),
    }
    profile.localDB.name = DB_NAME
    profile.localDB.version = 2

    return profile
end

function Addon:GetContainerItemValues(bagID, slotID)
    if C_Container and type(C_Container.GetContainerItemInfo) == "function" then
        local ok, info = pcall(C_Container.GetContainerItemInfo, bagID, slotID)
        if ok and type(info) == "table" then
            return ValuesFromContainerInfo(info, GetContainerItemLinkCompat(bagID, slotID))
        end

        if not ok then
            self.lastContainerError = tostring(info)
        end
    end

    if type(GetContainerItemInfo) == "function" then
        local ok, texture, count, locked, quality, readable, lootable, link = pcall(GetContainerItemInfo, bagID, slotID)
        if ok then
            if type(texture) == "table" then
                return ValuesFromContainerInfo(texture, GetContainerItemLinkCompat(bagID, slotID))
            end

            if texture or count or quality or link then
                return texture, count, quality, link or GetContainerItemLinkCompat(bagID, slotID)
            end
        else
            self.lastContainerError = tostring(texture)
        end
    end

    return nil
end

function Addon:BuildItemFromLink(source, link, values)
    if not link then
        return nil
    end

    values = values or {}
    local itemID = ParseItemID(link)
    local instantItemType, instantItemSubType, instantEquipSlot, instantTexture, classID, subClassID

    if type(GetItemInfoInstant) == "function" then
        local ok, resolvedID, itemTypeInstant, itemSubTypeInstant, itemEquipLocInstant, iconInstant, classIDInstant, subClassIDInstant = pcall(GetItemInfoInstant, link)
        if ok then
            itemID = itemID or resolvedID
            instantItemType = itemTypeInstant
            instantItemSubType = itemSubTypeInstant
            instantEquipSlot = itemEquipLocInstant
            instantTexture = iconInstant
            classID = classIDInstant
            subClassID = subClassIDInstant
        end
    end

    local name, resolvedLink, quality, itemLevel, requiredLevel, itemType, itemSubType, maxStack, equipSlot, icon, sellPrice

    if type(GetItemInfo) == "function" then
        local ok, infoName, infoLink, infoQuality, infoLevel, infoReqLevel, infoType, infoSubType, infoMaxStack, infoEquipSlot, infoIcon, infoSellPrice = pcall(GetItemInfo, link)
        if ok then
            name = infoName
            resolvedLink = infoLink
            quality = infoQuality
            itemLevel = infoLevel
            requiredLevel = infoReqLevel
            itemType = infoType
            itemSubType = infoSubType
            maxStack = infoMaxStack
            equipSlot = infoEquipSlot
            icon = infoIcon
            sellPrice = infoSellPrice
        end
    end

    equipSlot = equipSlot or instantEquipSlot
    itemType = itemType or instantItemType
    itemSubType = itemSubType or instantItemSubType
    icon = icon or instantTexture or values.texture
    quality = quality or values.quality

    local itemLinkForExport = resolvedLink or link
    local itemName = name or ParseItemName(link) or (itemID and ("Item " .. itemID)) or "Unknown Item"
    local qualityColor = QualityColorHex(quality) or ParseItemLinkColorHex(itemLinkForExport)

    return {
        source = source,
        bag = values.bag,
        slot = values.slot,
        inventorySlot = values.inventorySlot,
        slotKey = values.slotKey,
        location = values.location or LocationLabel(source, values.bag, values.slot),
        itemID = itemID,
        itemString = ParseItemString(link),
        link = itemLinkForExport,
        wowheadUrl = WowheadItemURL(itemID),
        name = itemName,
        nameColored = ColorizeItemName(itemName, qualityColor),
        count = values.count or 1,
        quality = quality,
        qualityName = QualityName(quality),
        qualityColor = qualityColor,
        itemLevel = itemLevel,
        requiredLevel = requiredLevel,
        itemType = itemType,
        itemSubType = itemSubType,
        classID = classID,
        subClassID = subClassID,
        maxStack = maxStack,
        equipSlot = equipSlot,
        icon = icon,
        sellPrice = sellPrice,
        stats = BuildStatList(itemLinkForExport),
        category = CategoryFromInfo(classID, itemType, equipSlot),
        updatedAt = Now(),
    }
end

function Addon:BuildItem(source, bagID, slotID)
    local texture, count, containerQuality, link = self:GetContainerItemValues(bagID, slotID)
    return self:BuildItemFromLink(source, link, {
        bag = bagID,
        slot = slotID,
        texture = texture,
        count = count,
        quality = containerQuality,
    })
end

function Addon:ScanContainers(source, containers)
    local snapshot = {
        updatedAt = Now(),
        items = {},
        totalSlots = 0,
        api = ContainerApiName(),
    }

    for index = 1, #containers do
        local bagID = containers[index]
        local slots = GetContainerNumSlotsCompat(bagID)
        snapshot.totalSlots = snapshot.totalSlots + slots

        for slotID = 1, slots do
            local item = self:BuildItem(source, bagID, slotID)
            if item then
                snapshot.items[#snapshot.items + 1] = item
            end
        end
    end

    return snapshot
end

function Addon:ScanEquipped()
    local snapshot = {
        updatedAt = Now(),
        items = {},
        totalSlots = #GEAR_ENGINE.EQUIPMENT_SLOTS,
        api = type(GetInventoryItemLink) == "function" and "inventory" or "unavailable",
    }

    if type(GetInventoryItemLink) ~= "function" then
        return snapshot
    end

    for index = 1, #GEAR_ENGINE.EQUIPMENT_SLOTS do
        local slot = GEAR_ENGINE.EQUIPMENT_SLOTS[index]
        local ok, link = pcall(GetInventoryItemLink, "player", slot.id)
        if ok and link then
            local texture
            if type(GetInventoryItemTexture) == "function" then
                local textureOK, value = pcall(GetInventoryItemTexture, "player", slot.id)
                texture = textureOK and value or nil
            end
            local item = self:BuildItemFromLink("equipped", link, {
                slot = slot.id,
                inventorySlot = slot.id,
                slotKey = slot.key,
                texture = texture,
                location = GEAR_ENGINE.EquipmentSlotLabel(slot.key, ClientLocale()),
            })
            if item then
                snapshot.items[#snapshot.items + 1] = item
            end
        end
    end

    return snapshot
end

function Addon:GetBagContainers()
    local containers = {}

    for bagID = 0, PLAYER_BAG_SLOTS do
        containers[#containers + 1] = bagID
    end

    return containers
end

function Addon:GetBankContainers()
    local containers = { BANK_CONTAINER_ID }

    for bagID = PLAYER_BAG_SLOTS + 1, PLAYER_BAG_SLOTS + BANK_BAG_SLOTS do
        containers[#containers + 1] = bagID
    end

    return containers
end

function Addon:SaveSnapshot(source, snapshot)
    local profile = self:GetProfile()
    profile.localDB = profile.localDB or { name = DB_NAME, version = 2 }
    profile.localDB.name = DB_NAME
    profile.localDB.version = 2
    profile.localDB.savedAt = Now()

    if source == "bags" then
        profile.bags = snapshot
        profile.localDB.bagSavedAt = snapshot.updatedAt
        profile.localDB.bagItemCount = #(snapshot.items or {})
    elseif source == "bank" then
        profile.bank = snapshot
        profile.localDB.bankSavedAt = snapshot.updatedAt
        profile.localDB.bankItemCount = #(snapshot.items or {})
    elseif source == "equipped" then
        profile.equipped = snapshot
        profile.localDB.equippedSavedAt = snapshot.updatedAt
        profile.localDB.equippedItemCount = #(snapshot.items or {})
    end

    return snapshot
end

function Addon:SaveTalentSnapshot()
    local profile = self:GetProfile()
    local previous = profile.talents
    local snapshot = BuildTalentSnapshot()

    if TalentSnapshotHasSpentPoints(previous)
        and not TalentSnapshotHasSpentPoints(snapshot)
        and (tonumber(snapshot.unspentPoints) or 0) <= 0 then
        snapshot = previous
    end

    profile.talents = snapshot
    profile.localDB = profile.localDB or { name = DB_NAME, version = 2 }
    profile.localDB.name = DB_NAME
    profile.localDB.version = 2
    profile.localDB.savedAt = Now()
    profile.localDB.talentSavedAt = snapshot.updatedAt
    profile.localDB.talentSummary = snapshot.summary
    profile.localDB.talentPrimaryTab = snapshot.primaryTab
    profile.localDB.talentTotalPoints = snapshot.totalPoints
    profile.localDB.talentPointsSpent = snapshot.pointsSpent or snapshot.totalPoints
    profile.localDB.talentTreePoints = TalentTreePointsText(snapshot, profile.locale)
    return snapshot
end

function Addon:SaveCharacterStatsSnapshot()
    local profile = self:GetProfile()
    local snapshot = BuildCharacterStatsSnapshot()
    profile.characterStats = snapshot
    profile.localDB = profile.localDB or { name = DB_NAME, version = 2 }
    profile.localDB.name = DB_NAME
    profile.localDB.version = 2
    profile.localDB.savedAt = Now()
    profile.localDB.characterStatsSavedAt = snapshot.updatedAt
    profile.localDB.race = snapshot.race and snapshot.race.localized or nil
    profile.localDB.raceToken = snapshot.race and snapshot.race.english or nil
    profile.localDB.groupType = snapshot.group and snapshot.group.type or nil
    return snapshot
end

function Addon:SaveEquippedSnapshot()
    return self:SaveSnapshot("equipped", self:ScanEquipped())
end

function Addon:ScanBags()
    self:SaveTalentSnapshot()
    self:SaveCharacterStatsSnapshot()
    self:SaveEquippedSnapshot()
    local snapshot = self:ScanContainers("bags", self:GetBagContainers())
    return self:SaveSnapshot("bags", snapshot)
end

function Addon:ScanBank()
    self:SaveTalentSnapshot()
    self:SaveCharacterStatsSnapshot()
    self:SaveEquippedSnapshot()
    local snapshot = self:ScanContainers("bank", self:GetBankContainers())
    return self:SaveSnapshot("bank", snapshot)
end

function Addon:FormatScanSummary(label, snapshot)
    snapshot = snapshot or { items = {}, totalSlots = 0, api = ContainerApiName() }
    return L("scan_summary", label, #(snapshot.items or {}), snapshot.totalSlots or 0, tostring(snapshot.api or "unknown"))
end

function Addon:ScanBagsAndReport(label)
    local snapshot = self:ScanBags()
    self:Print(self:FormatScanSummary(label or L("bags_scanned"), snapshot) .. ".")
    return snapshot
end

function Addon:ScanBankAndReport(label)
    local snapshot = self:ScanBank()
    self:Print(self:FormatScanSummary(label or L("bank_scanned"), snapshot) .. ".")
    return snapshot
end

function Addon:DebugContainers()
    local bagContainers = self:GetBagContainers()
    local bagSlots = 0
    local firstLink

    for index = 1, #bagContainers do
        local bagID = bagContainers[index]
        local slots = GetContainerNumSlotsCompat(bagID)
        bagSlots = bagSlots + slots

        if not firstLink then
            for slotID = 1, slots do
                firstLink = GetContainerItemLinkCompat(bagID, slotID)
                if firstLink then
                    break
                end
            end
        end
    end

    local profile = self:GetProfile()
    local bagItems = profile.bags and profile.bags.items or {}
    local bankItems = profile.bank and profile.bank.items or {}

    self:Print("Debug: API=" .. ContainerApiName()
        .. ", C_Container=" .. YesNo(HasCContainer())
        .. ", legacy=" .. YesNo(HasLegacyContainer())
        .. ", bagSlots=" .. bagSlots
        .. ", savedBags=" .. #bagItems
        .. ", savedBank=" .. #bankItems .. ".")
    self:Print("Debug: first visible bag link=" .. tostring(firstLink or "none")
        .. (self.lastContainerError and (", last container error=" .. self.lastContainerError) or "") .. ".")
end

function Addon:ScheduleBagScan()
    if self.pendingBagScan then
        return
    end

    self.pendingBagScan = true

    if C_Timer and C_Timer.After then
        C_Timer.After(0.25, function()
            Addon.pendingBagScan = false
            Addon:ScanBags()
        end)
    else
        self.pendingBagScan = false
        self:ScanBags()
    end
end

function Addon:ScheduleBankScan()
    if not self.bankOpen or self.pendingBankScan then
        return
    end

    self.pendingBankScan = true

    if C_Timer and C_Timer.After then
        C_Timer.After(0.25, function()
            Addon.pendingBankScan = false
            if Addon.bankOpen then
                Addon:ScanBank()
            end
        end)
    else
        self.pendingBankScan = false
        self:ScanBank()
    end
end

function Addon:CollectExportItems(scope, filter)
    local profile = self:GetProfile()
    local items = {}
    local includeBags = scope == "all" or scope == "gear" or scope == "bags"
    local includeBank = scope == "all" or scope == "gear" or scope == "bank"
    local gearOnly = scope == "gear"
    filter = NormalizeExportFilter(filter)

    if includeBags then
        local bagItems = CopyItems(profile.bags and profile.bags.items)
        for index = 1, #bagItems do
            local item = bagItems[index]
            if (not gearOnly or item.category == "Gear") and ExportFilterMatchesItem(item, filter) then
                items[#items + 1] = item
            end
        end
    end

    if includeBank then
        local bankItems = CopyItems(profile.bank and profile.bank.items)
        for index = 1, #bankItems do
            local item = bankItems[index]
            if (not gearOnly or item.category == "Gear") and ExportFilterMatchesItem(item, filter) then
                items[#items + 1] = item
            end
        end
    end

    return items
end

function Addon:BuildMarkdownExport(scope, profile, items, categories, buckets, filter, prompt, chartStats, characterStats, strategyBook, gearEngine)
    local locale = profile.locale or ClientLocale()
    local terms = GEAR_ENGINE.ReportTerms(locale)
    local lines = {
        "# " .. LForLocale(locale, "addon_title"),
        "",
        "> " .. terms.human_note,
        "",
    }

    chartStats = chartStats or BuildChartStats(items or {})
    strategyBook = strategyBook or BuildStrategyBook(profile, chartStats)
    gearEngine = gearEngine or GEAR_ENGINE.BuildGearRecommendations(profile, items or {}, strategyBook)
    Addon.AppendMarkdownQuickSummary(lines, profile, scope, filter, items or {}, chartStats, strategyBook)
    GEAR_ENGINE.AppendGearRecommendationsMarkdown(lines, gearEngine, locale)
    Addon.AppendMarkdownRoleSnapshot(lines, strategyBook, locale)
    lines[#lines + 1] = "## " .. terms.current_equipment
    lines[#lines + 1] = ""
    Addon.AppendMarkdownItemTable(lines, "Equipped", profile.equipped and profile.equipped.items or {}, false, locale)

    lines[#lines + 1] = "<details>"
    lines[#lines + 1] = "<summary>" .. terms.details .. "</summary>"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "## " .. terms.export_metadata
    lines[#lines + 1] = ""
    lines[#lines + 1] = "- " .. terms.character .. ": " .. tostring(profile.player or terms.unknown) .. " - " .. tostring(profile.realm or terms.unknown)
    lines[#lines + 1] = "- " .. terms.class .. ": " .. AnalysisClassName(profile, locale)
    lines[#lines + 1] = "- " .. terms.talents .. ": " .. TalentSummaryText(profile.talents, locale)
    lines[#lines + 1] = "- " .. terms.talent_points .. ": " .. TalentTreePointsText(profile.talents, locale)
    lines[#lines + 1] = "- " .. terms.selected_talents .. ": " .. TalentSelectedPointsText(profile.talents, locale, 12)
    lines[#lines + 1] = "- " .. terms.client_locale .. ": " .. tostring(locale)
    lines[#lines + 1] = "- " .. terms.local_db .. ": " .. DB_NAME .. " @ " .. FormatTime(profile.localDB and profile.localDB.savedAt)
    lines[#lines + 1] = "- " .. terms.scope .. ": " .. LocalizedScopeTitle(scope, locale)
    lines[#lines + 1] = "- " .. terms.filter .. ": " .. LocalizedExportFilterTitle(filter, locale)
    lines[#lines + 1] = "- " .. terms.items .. ": " .. #(items or {})
    lines[#lines + 1] = "- " .. terms.bag_scan .. ": " .. FormatTime(profile.bags and profile.bags.updatedAt)
    lines[#lines + 1] = "- " .. terms.bank_scan .. ": " .. FormatTime(profile.bank and profile.bank.updatedAt)
    lines[#lines + 1] = "- " .. terms.equipped_scan .. ": " .. FormatTime(profile.equipped and profile.equipped.updatedAt)
    lines[#lines + 1] = ""

    lines[#lines + 1] = "## " .. terms.stats_analysis
    lines[#lines + 1] = ""
    lines[#lines + 1] = "```text"
    lines[#lines + 1] = BuildStatsAnalysisText(profile, chartStats, strategyBook)
    lines[#lines + 1] = "```"
    lines[#lines + 1] = ""
    AppendChartStatsMarkdown(lines, chartStats, locale)
    lines[#lines + 1] = "</details>"
    lines[#lines + 1] = ""

    if #(items or {}) == 0 then
        lines[#lines + 1] = "_" .. terms.no_items .. "_"
        return table.concat(lines, "\n")
    end

    lines[#lines + 1] = "## " .. terms.item_tables
    lines[#lines + 1] = ""

    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        local bucket = buckets[category] or {}
        Addon.AppendMarkdownItemTable(lines, category, bucket, category == "Gear", locale)
    end

    return table.concat(lines, "\n")
end
function Addon:BuildTextExport(scope, profile, items, categories, buckets, filter, prompt, chartStats, characterStats, strategyBook, gearEngine)
    local locale = profile.locale or ClientLocale()
    local terms = GEAR_ENGINE.ReportTerms(locale)
    local lines = {
        LForLocale(locale, "addon_title"),
        "",
        terms.export_metadata,
        terms.character .. ": " .. tostring(profile.player or terms.unknown) .. " - " .. tostring(profile.realm or terms.unknown),
        terms.class .. ": " .. AnalysisClassName(profile, locale),
        terms.talents .. ": " .. TalentSummaryText(profile.talents, locale),
        terms.talent_points .. ": " .. TalentTreePointsText(profile.talents, locale),
        terms.selected_talents .. ": " .. TalentSelectedPointsText(profile.talents, locale, 12),
        terms.client_locale .. ": " .. tostring(locale),
        terms.local_db .. ": " .. DB_NAME .. " @ " .. FormatTime(profile.localDB and profile.localDB.savedAt),
        terms.scope .. ": " .. LocalizedScopeTitle(scope, locale),
        terms.filter .. ": " .. LocalizedExportFilterTitle(filter, locale),
        terms.items .. ": " .. #items,
        terms.bag_scan .. ": " .. FormatTime(profile.bags and profile.bags.updatedAt),
        terms.bank_scan .. ": " .. FormatTime(profile.bank and profile.bank.updatedAt),
        terms.equipped_scan .. ": " .. FormatTime(profile.equipped and profile.equipped.updatedAt),
        "",
    }

    gearEngine = gearEngine or GEAR_ENGINE.BuildGearRecommendations(profile, items or {}, strategyBook)
    GEAR_ENGINE.AppendGearRecommendationsText(lines, gearEngine, locale)
    lines[#lines + 1] = BuildStatsAnalysisText(profile, chartStats, strategyBook)
    lines[#lines + 1] = ""
    lines[#lines + 1] = terms.current_equipment
    for itemIndex = 1, #(profile.equipped and profile.equipped.items or {}) do
        local item = profile.equipped.items[itemIndex]
        local wowheadUrl = ItemWowheadURL(item)
        lines[#lines + 1] = "- " .. GEAR_ENGINE.EquipmentSlotLabel(GEAR_ENGINE.EquipmentSlotKey(item), locale)
            .. ": " .. ItemColoredName(item)
            .. " | " .. terms.item_level .. " " .. ItemLevelDisplay(item)
            .. " | " .. terms.stats .. ": " .. GEAR_ENGINE.FormatLocalizedStats(item.stats, locale)
            .. (wowheadUrl and " | Wowhead: " .. wowheadUrl or "")
    end
    if #(profile.equipped and profile.equipped.items or {}) == 0 then
        lines[#lines + 1] = terms.none
    end
    lines[#lines + 1] = ""
    AppendChartStatsText(lines, chartStats, locale)

    if #items == 0 then
        lines[#lines + 1] = terms.no_items
        return table.concat(lines, "\n")
    end

    lines[#lines + 1] = terms.item_tables
    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        local bucket = buckets[category] or {}
        lines[#lines + 1] = "[" .. GEAR_ENGINE.CategoryLabel(category, locale) .. "]"

        for itemIndex = 1, #bucket do
            local item = bucket[itemIndex]
            local wowheadUrl = ItemWowheadURL(item)
            local line = "- " .. ItemColoredName(item)
                .. " x" .. tostring(item.count or 1)
                .. " | " .. QualityDisplay(item)
                .. " | " .. terms.item_level .. ": " .. ItemLevelDisplay(item)
                .. " | " .. ItemTypeDisplay(item)
                .. " | " .. SourceLabel(item.source, locale)
                .. " | " .. GEAR_ENGINE.ItemLocationLabel(item, locale)

            if wowheadUrl then
                line = line .. " | Wowhead: " .. wowheadUrl
            end

            lines[#lines + 1] = line
                .. " | " .. terms.stats .. ": " .. GEAR_ENGINE.FormatLocalizedStats(item.stats, locale)
        end

        lines[#lines + 1] = ""
    end

    return table.concat(lines, "\n")
end

function Addon:BuildExport(scope, format, filter)
    scope = scope or "all"
    format = NormalizeExportFormat(format or self.exportFormat or "ai")
    filter = NormalizeExportFilter(filter or self.exportFilter)

    local profile = self:GetProfile()
    profile.talents = self:SaveTalentSnapshot()
    profile.characterStats = self:SaveCharacterStatsSnapshot()
    profile.equipped = self:SaveEquippedSnapshot()
    local items = self:CollectExportItems(scope, filter)
    local prompt = BuildAIPrompt(profile, scope, filter, #items)
    local buckets = {}
    local categorySeen = {}

    for index = 1, #items do
        local item = items[index]
        local category = item.category or "Other"
        buckets[category] = buckets[category] or {}
        buckets[category][#buckets[category] + 1] = item
        categorySeen[category] = true
    end

    local categories = {}
    for index = 1, #CATEGORY_ORDER do
        local category = CATEGORY_ORDER[index]
        if categorySeen[category] then
            categories[#categories + 1] = category
            categorySeen[category] = nil
        end
    end

    for category in pairs(categorySeen) do
        categories[#categories + 1] = category
    end

    table.sort(categories, function(left, right)
        local leftRank, rightRank

        for index = 1, #CATEGORY_ORDER do
            if CATEGORY_ORDER[index] == left then
                leftRank = index
            end
            if CATEGORY_ORDER[index] == right then
                rightRank = index
            end
        end

        if leftRank and rightRank then
            return leftRank < rightRank
        end

        if leftRank then
            return true
        end

        if rightRank then
            return false
        end

        return left < right
    end)

    for category, bucket in pairs(buckets) do
        table.sort(bucket, function(left, right)
            local leftQuality = left.quality or -1
            local rightQuality = right.quality or -1

            if leftQuality ~= rightQuality then
                return leftQuality > rightQuality
            end

            local leftName = left.name or ""
            local rightName = right.name or ""

            if leftName ~= rightName then
                return leftName < rightName
            end

            return (left.location or "") < (right.location or "")
        end)
    end

    local chartStats = BuildChartStats(items)
    local strategyBook = BuildStrategyBook(profile, chartStats)
    local gearEngine = GEAR_ENGINE.BuildGearRecommendations(profile, items, strategyBook, self.selectedAdviceRoleKey, self.selectedStrategyModeKey)

    local lines = {
        "AI_READY_WOW_TBC_INVENTORY_EXPORT v1",
        "Paste this entire selected text into an AI chat. It contains a prompt plus structured JSON for current equipment, bag, and bank gear analysis.",
        "AI_PROMPT:",
        prompt.text,
        "",
        "DATA_JSON:",
    }

    AppendIndented(lines, 0, "{")
    AppendIndented(lines, 2, JsonField("format", format == "json" and "tbc_gear_exporter_json_v1" or "tbc_gear_exporter_ai_v1", true))
    AppendIndented(lines, 2, "\"ai_prompt\": {")
    AppendIndented(lines, 4, JsonField("text", prompt.text, true))
    AppendIndented(lines, 4, JsonField("class_token", prompt.classToken, true))
    AppendIndented(lines, 4, JsonField("client_locale", prompt.locale, true))
    AppendIndented(lines, 4, JsonField("prompt_locale", prompt.promptLocale, true))
    AppendJsonStringArray(lines, 4, "role_context", prompt.roleContext, true)
    AppendJsonStringArray(lines, 4, "output_requests", prompt.outputRequests, false)
    AppendIndented(lines, 2, "},")
    AppendIndented(lines, 2, "\"character\": {")
    AppendIndented(lines, 4, JsonField("name", profile.player or "Unknown Player", true))
    AppendIndented(lines, 4, JsonField("realm", profile.realm or "Unknown Realm", true))
    AppendIndented(lines, 4, JsonField("client_locale", profile.locale or "enUS", true))
    AppendIndented(lines, 4, JsonField("class", profile.classLocalized or profile.classEnglish or "Unknown Class", true))
    AppendIndented(lines, 4, JsonField("class_token", profile.classEnglish or "UNKNOWN", true))
    AppendIndented(lines, 4, JsonField("class_id", profile.classID, true))
    AppendIndented(lines, 4, JsonField("race", profile.characterStats and profile.characterStats.race and profile.characterStats.race.localized, true))
    AppendIndented(lines, 4, JsonField("race_token", profile.characterStats and profile.characterStats.race and profile.characterStats.race.english, true))
    AppendIndented(lines, 4, JsonField("group_type", profile.characterStats and profile.characterStats.group and profile.characterStats.group.type, false))
    AppendIndented(lines, 2, "},")
    AppendCharacterStatsJson(lines, 2, profile.characterStats, true)
    AppendTalentJson(lines, 2, profile.talents, true)
    AppendIndented(lines, 2, "\"local_db\": {")
    AppendIndented(lines, 4, JsonField("name", DB_NAME, true))
    AppendIndented(lines, 4, JsonField("saved_at", FormatTime(profile.localDB and profile.localDB.savedAt), true))
    AppendIndented(lines, 4, JsonField("bag_item_count", profile.localDB and profile.localDB.bagItemCount, true))
    AppendIndented(lines, 4, JsonField("bank_item_count", profile.localDB and profile.localDB.bankItemCount, true))
    AppendIndented(lines, 4, JsonField("equipped_item_count", profile.localDB and profile.localDB.equippedItemCount, true))
    AppendIndented(lines, 4, JsonField("equipped_saved_at", FormatTime(profile.localDB and profile.localDB.equippedSavedAt), true))
    AppendIndented(lines, 4, JsonField("talent_saved_at", FormatTime(profile.localDB and profile.localDB.talentSavedAt), true))
    AppendIndented(lines, 4, JsonField("talent_summary", profile.localDB and profile.localDB.talentSummary, true))
    AppendIndented(lines, 4, JsonField("talent_primary_tree", profile.localDB and profile.localDB.talentPrimaryTab, true))
    AppendIndented(lines, 4, JsonField("talent_total_points", profile.localDB and profile.localDB.talentTotalPoints, true))
    AppendIndented(lines, 4, JsonField("talent_points_spent", profile.localDB and profile.localDB.talentPointsSpent, true))
    AppendIndented(lines, 4, JsonField("talent_tree_points", profile.localDB and profile.localDB.talentTreePoints, true))
    AppendIndented(lines, 4, JsonField("character_stats_saved_at", FormatTime(profile.localDB and profile.localDB.characterStatsSavedAt), true))
    AppendIndented(lines, 4, JsonField("race", profile.localDB and profile.localDB.race, true))
    AppendIndented(lines, 4, JsonField("race_token", profile.localDB and profile.localDB.raceToken, true))
    AppendIndented(lines, 4, JsonField("group_type", profile.localDB and profile.localDB.groupType, false))
    AppendIndented(lines, 2, "},")
    AppendIndented(lines, 2, "\"export\": {")
    AppendIndented(lines, 4, JsonField("scope", scope, true))
    AppendIndented(lines, 4, JsonField("scope_title", ScopeTitle(scope), true))
    AppendIndented(lines, 4, "\"filter\": {")
    AppendIndented(lines, 6, JsonField("title", ExportFilterTitle(filter), true))
    AppendIndented(lines, 6, JsonField("quality_id", filter.qualityID, true))
    AppendIndented(lines, 6, JsonField("quality", filter.qualityID ~= nil and QualityName(filter.qualityID) or nil, true))
    AppendIndented(lines, 6, JsonField("quality_min_id", filter.qualityMin, true))
    AppendIndented(lines, 6, JsonField("quality_min", filter.qualityMin ~= nil and QualityName(filter.qualityMin) or nil, false))
    AppendIndented(lines, 4, "},")
    AppendIndented(lines, 4, JsonField("generated_at", FormatTime(Now()), true))
    AppendIndented(lines, 4, JsonField("bag_scan_at", FormatTime(profile.bags and profile.bags.updatedAt), true))
    AppendIndented(lines, 4, JsonField("bank_scan_at", FormatTime(profile.bank and profile.bank.updatedAt), true))
    AppendIndented(lines, 4, JsonField("item_count", #items, false))
    AppendIndented(lines, 2, "},")
    AppendIndented(lines, 2, "\"notes\": [")
    AppendIndented(lines, 4, JsonString("Bank contents are the last saved snapshot. Open the bank in game and scan to refresh bank data.") .. (#items == 0 and "," or ""))

    if #items == 0 then
        AppendIndented(lines, 4, JsonString("No saved items match this export. Use /tbcgear scan to refresh bags, or clear export filters.") )
    end

    AppendIndented(lines, 2, "],")
    AppendIndented(lines, 2, "\"categories\": [")

    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        local suffix = categoryIndex < #categories and "," or ""
        AppendIndented(lines, 4, "{ " .. JsonField("name", category, true) .. " " .. JsonField("item_count", #(buckets[category] or {}), false) .. " }" .. suffix)
    end

    AppendIndented(lines, 2, "],")
    AppendChartStatsJson(lines, 2, chartStats, true)
    AppendStrategyBookJson(lines, 2, strategyBook, true)
    GEAR_ENGINE.AppendGearRecommendationsJson(lines, 2, gearEngine, true)
    AppendIndented(lines, 2, "\"items\": [")

    local itemPosition = 0
    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        local bucket = buckets[category]

        for itemIndex = 1, #bucket do
            local item = bucket[itemIndex]
            local itemID = item.itemID or item.item_id
            local statsText = FormatStats(item.stats)
            local wowheadUrl = ItemWowheadURL(item)
            local qualityColor = ItemQualityColorHex(item)
            itemPosition = itemPosition + 1

            AppendIndented(lines, 4, "{")
            AppendIndented(lines, 6, JsonField("category", category, true))
            AppendIndented(lines, 6, JsonField("source", item.source, true))
            AppendIndented(lines, 6, JsonField("source_label", SourceLabel(item.source), true))
            AppendIndented(lines, 6, JsonField("location", item.location, true))
            AppendIndented(lines, 6, JsonField("bag", item.bag, true))
            AppendIndented(lines, 6, JsonField("slot", item.slot, true))
            AppendIndented(lines, 6, JsonField("count", item.count or 1, true))
            AppendIndented(lines, 6, JsonField("name", item.name or "Unknown Item", true))
            AppendIndented(lines, 6, JsonField("name_colored", ItemColoredName(item), true))
            AppendIndented(lines, 6, JsonField("item_id", itemID, true))
            AppendIndented(lines, 6, JsonField("item_string", item.itemString, true))
            AppendIndented(lines, 6, JsonField("item_link", item.link, true))
            AppendIndented(lines, 6, JsonField("wowhead_url", wowheadUrl, true))
            AppendIndented(lines, 6, JsonField("quality", item.qualityName or "Unknown", true))
            AppendIndented(lines, 6, JsonField("quality_color", qualityColor, true))
            AppendIndented(lines, 6, JsonField("quality_id", item.quality, true))
            AppendIndented(lines, 6, JsonField("item_level", item.itemLevel, true))
            AppendIndented(lines, 6, JsonField("required_level", item.requiredLevel, true))
            AppendIndented(lines, 6, JsonField("type", item.itemType, true))
            AppendIndented(lines, 6, JsonField("subtype", item.itemSubType, true))
            AppendIndented(lines, 6, JsonField("equip_slot", item.equipSlot, true))
            AppendIndented(lines, 6, JsonField("stats_text", statsText, true))
            AppendIndented(lines, 6, "\"stats\": [")

            for statIndex = 1, #(item.stats or {}) do
                local stat = item.stats[statIndex]
                local suffix = statIndex < #(item.stats or {}) and "," or ""
                AppendIndented(lines, 8, "{ " .. JsonField("token", stat.token, true) .. " " .. JsonField("label", stat.label, true) .. " " .. JsonField("value", stat.value, false) .. " }" .. suffix)
            end

            AppendIndented(lines, 6, "]")
            AppendIndented(lines, 4, "}" .. (itemPosition < #items and "," or ""))
        end
    end

    AppendIndented(lines, 2, "]")
    AppendIndented(lines, 0, "}")

    local aiText = table.concat(lines, "\n")
    local jsonText = aiText:match("DATA_JSON:\n(.+)$") or aiText

    if format == "json" then
        return jsonText
    end

    if format == "markdown" then
        return self:BuildMarkdownExport(scope, profile, items, categories, buckets, filter, prompt, chartStats, profile.characterStats, strategyBook, gearEngine)
    end

    if format == "text" then
        return self:BuildTextExport(scope, profile, items, categories, buckets, filter, prompt, chartStats, profile.characterStats, strategyBook, gearEngine)
    end

    return aiText
end

function Addon:SavedItemCounts()
    local profile = self:GetProfile()
    local bagItems = profile.bags and profile.bags.items or {}
    local bankItems = profile.bank and profile.bank.items or {}
    return #bagItems, #bankItems
end

function Addon:SetExportView(view)
    if view == "text" then
        self.exportView = "text"
    elseif view == "analysis" then
        self.exportView = "analysis"
    elseif view == "advice" then
        self.exportView = "advice"
    elseif view == "phase2" then
        self.exportView = "phase2"
    elseif view == "items" then
        self.exportView = "items"
    else
        self.exportView = "overview"
    end

    if not self.exportFrame then
        return
    end

    if self.exportFrame.overviewScroll then
        if self.exportView == "overview" then
            self.exportFrame.overviewScroll:Show()
        else
            self.exportFrame.overviewScroll:Hide()
        end
    end

    if self.exportFrame.adviceScroll then
        if self.exportView == "advice" then
            self.exportFrame.adviceScroll:Show()
        else
            self.exportFrame.adviceScroll:Hide()
        end
    end

    if self.exportFrame.visualScroll then
        if self.exportView == "items" then
            self.exportFrame.visualScroll:Show()
        else
            self.exportFrame.visualScroll:Hide()
        end
    end

    if self.exportFrame.analysisScroll then
        if self.exportView == "analysis" then
            self.exportFrame.analysisScroll:Show()
        else
            self.exportFrame.analysisScroll:Hide()
        end
    end

    if self.exportFrame.phase2Scroll then
        if self.exportView == "phase2" then
            self.exportFrame.phase2Scroll:Show()
        else
            self.exportFrame.phase2Scroll:Hide()
        end
    end

    if self.exportFrame.textScroll then
        if self.exportView == "text" then
            self.exportFrame.textScroll:Show()
        else
            self.exportFrame.textScroll:Hide()
        end
    end
end
function Addon:CreateVisualItemRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    SetFrameSize(row, 490, 42)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 44))
    row:EnableMouse(true)

    local icon = row:CreateTexture(nil, "ARTWORK")
    SetFrameSize(icon, 34, 34)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    name:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    name:SetJustifyH("LEFT")

    local meta = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    meta:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -20)
    meta:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    meta:SetJustifyH("LEFT")

    local count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    count:SetJustifyH("RIGHT")

    row.icon = icon
    row.name = name
    row.meta = meta
    row.count = count

    row:SetScript("OnEnter", function(self)
        local item = self.item
        if not item or not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if item.link and GameTooltip.SetHyperlink then
            GameTooltip:SetHyperlink(item.link)
        else
            GameTooltip:SetText(item.name or "Unknown Item")
        end
        if GameTooltip.AddLine then
            GameTooltip:AddLine(GEAR_ENGINE.ItemLocationLabel(item, ClientLocale()))
            local stats = GEAR_ENGINE.FormatLocalizedStats(item.stats, ClientLocale())
            if stats ~= GEAR_ENGINE.ReportTerms(ClientLocale()).none then
                GameTooltip:AddLine(stats)
            end
        end
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return row
end

function GEAR_ENGINE.ShowRecommendationTooltip(owner, item)
    if not item or not GameTooltip then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if item.link and GameTooltip.SetHyperlink then
        GameTooltip:SetHyperlink(item.link)
    else
        GameTooltip:SetText(item.name or "Unknown Item")
    end
    if GameTooltip.AddLine then
        GameTooltip:AddLine(GEAR_ENGINE.ItemLocationLabel(item, ClientLocale()))
        GameTooltip:AddLine(GEAR_ENGINE.FormatLocalizedStats(item.stats, ClientLocale()))
    end
    GameTooltip:Show()
end

function GEAR_ENGINE.LocalizedMatchedStats(upgrade, locale)
    return GEAR_ENGINE.FormatLocalizedStats(upgrade and upgrade.matchedStats or {}, locale, 3)
end

function Addon:CreateGearAdviceRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    SetFrameSize(row, 490, 72)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 74))

    local slot = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    slot:SetPoint("LEFT", 4, 0)
    slot:SetWidth(72)
    slot:SetJustifyH("LEFT")

    local currentButton = CreateFrame("Button", nil, row)
    SetFrameSize(currentButton, 34, 34)
    currentButton:SetPoint("LEFT", 78, 0)
    local currentIcon = currentButton:CreateTexture(nil, "ARTWORK")
    currentIcon:SetPoint("TOPLEFT", 0, 0)
    currentIcon:SetPoint("BOTTOMRIGHT", 0, 0)

    local arrow = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    arrow:SetPoint("LEFT", currentButton, "RIGHT", 5, 0)
    arrow:SetText(">")

    local candidateButton = CreateFrame("Button", nil, row)
    SetFrameSize(candidateButton, 34, 34)
    candidateButton:SetPoint("LEFT", currentButton, "RIGHT", 22, 0)
    local candidateIcon = candidateButton:CreateTexture(nil, "ARTWORK")
    candidateIcon:SetPoint("TOPLEFT", 0, 0)
    candidateIcon:SetPoint("BOTTOMRIGHT", 0, 0)

    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("TOPLEFT", candidateButton, "TOPRIGHT", 8, -1)
    name:SetPoint("RIGHT", row, "RIGHT", -70, 0)
    name:SetJustifyH("LEFT")

    local reason = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    reason:SetPoint("TOPLEFT", candidateButton, "TOPRIGHT", 8, -20)
    reason:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    reason:SetJustifyH("LEFT")

    local gain = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    gain:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -2)
    gain:SetJustifyH("RIGHT")

    currentButton:SetScript("OnEnter", function(self)
        GEAR_ENGINE.ShowRecommendationTooltip(self, self.item)
    end)
    candidateButton:SetScript("OnEnter", function(self)
        GEAR_ENGINE.ShowRecommendationTooltip(self, self.item)
    end)
    currentButton:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    candidateButton:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    currentButton:SetScript("OnClick", function(self)
        if self.upgradeIndex then
            Addon:RefreshGearComparison(Addon.currentAdviceProfile, Addon.currentGearEngine, self.upgradeIndex)
        end
    end)
    candidateButton:SetScript("OnClick", function(self)
        if self.upgradeIndex then
            Addon:RefreshGearComparison(Addon.currentAdviceProfile, Addon.currentGearEngine, self.upgradeIndex)
        end
    end)

    row.slot = slot
    row.currentButton = currentButton
    row.currentIcon = currentIcon
    row.candidateButton = candidateButton
    row.candidateIcon = candidateIcon
    row.name = name
    row.reason = reason
    row.gain = gain
    return row
end

function Addon:RefreshAdviceRoleButtons(engine, locale)
    for index = 1, #(self.exportFrame and self.exportFrame.adviceRoleButtons or {}) do
        local button = self.exportFrame.adviceRoleButtons[index]
        local role = engine and engine.availableRoles and engine.availableRoles[index]
        if role then
            button.roleKey = role.key
            button:SetText((role.key == engine.roleKey and "> " or "") .. tostring(GEAR_ENGINE.LocalizedDataLabel(role.labels, locale, AnalysisLookup(locale, "roles", role.key, role.label))))
            button:Show()
        else
            button.roleKey = nil
            button:Hide()
        end
    end
end

function Addon:RefreshGearComparison(profile, engine, index)
    if not self.exportFrame or not self.exportFrame.comparePanel then
        return nil
    end
    local locale = profile and profile.locale or ClientLocale()
    local upgrade = engine and engine.upgrades and engine.upgrades[index]
    self.selectedAdviceIndex = upgrade and index or nil
    if not upgrade then
        self.exportFrame.compareCurrentButton.item = nil
        self.exportFrame.compareCandidateButton.item = nil
        self.exportFrame.compareCurrentIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.exportFrame.compareCandidateIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.exportFrame.compareNames:SetText(LForLocale(locale, "compare_select_hint"))
        self.exportFrame.compareVerdict:SetText("")
        self.exportFrame.compareDetails:SetText("")
        return nil
    end

    self.exportFrame.compareCurrentButton.item = upgrade.current
    self.exportFrame.compareCandidateButton.item = upgrade.candidate
    self.exportFrame.compareCurrentIcon:SetTexture(upgrade.current and upgrade.current.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.exportFrame.compareCandidateIcon:SetTexture(upgrade.candidate and upgrade.candidate.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.exportFrame.compareNames:SetText((upgrade.current and ItemColoredName(upgrade.current) or LForLocale(locale, "advice_empty_slot"))
        .. "  >  " .. ItemColoredName(upgrade.candidate))
    self.exportFrame.compareVerdict:SetText(GEAR_ENGINE.RecommendationVerdictLabel(upgrade.verdict, locale)
        .. "  |cff33ff99+" .. CompactNumber(upgrade.scoreGain, 2) .. "|r  · "
        .. LForLocale(locale, "advice_evidence", LForLocale(locale, "advice_evidence_" .. tostring(upgrade.evidence or "low"))))
    self.exportFrame.compareDetails:SetText(LForLocale(locale, "advice_gains", GEAR_ENGINE.DeltaText(upgrade.statGains, locale))
        .. "\n" .. LForLocale(locale, "advice_losses", GEAR_ENGINE.DeltaText(upgrade.statLosses, locale))
        .. "\n" .. LForLocale(locale, "advice_impact", GEAR_ENGINE.BenchmarkImpactText(upgrade.benchmarkImpacts, locale)))
    return upgrade
end

function Addon:RefreshGearAdvice(profile, engine)
    if not self.exportFrame or not self.exportFrame.adviceContent then
        return 0
    end

    local locale = profile and profile.locale or ClientLocale()
    local roleLabel = GEAR_ENGINE.GearRoleLabel(engine, locale)
    self.currentAdviceProfile = profile
    self.currentGearEngine = engine
    self:RefreshAdviceRoleButtons(engine, locale)
    self.exportFrame.adviceSummary:SetText(LForLocale(locale, "advice_summary", roleLabel, engine.equippedCount or 0, engine.candidateCount or 0, engine.roleRejectedCount or 0, #(engine.upgrades or {}))
        .. "\n" .. LForLocale(locale, "advice_verdicts", GEAR_ENGINE.VerdictSummary(engine, locale))
        .. "\n" .. LForLocale(locale, "advice_talent_map", GEAR_ENGINE.TalentMapSummary(engine.talentMap, locale, 4))
        .. "\n" .. LForLocale(locale, "advice_priorities", GEAR_ENGINE.GearPriorityText(engine, locale)))
    self.exportFrame.adviceCaveat:SetText(engine.caveat or LForLocale(locale, "advice_caveat"))

    local rows = self.exportFrame.adviceRows or {}
    self.exportFrame.adviceRows = rows
    for index = 1, #rows do
        rows[index]:Hide()
    end

    local upgrades = engine.upgrades or {}
    if #upgrades == 0 then
        self.exportFrame.adviceEmpty:SetText(GEAR_ENGINE.NoUpgradeText(engine, locale))
        self.exportFrame.adviceEmpty:Show()
    else
        self.exportFrame.adviceEmpty:Hide()
    end

    for index = 1, #upgrades do
        local upgrade = upgrades[index]
        local row = rows[index] or self:CreateGearAdviceRow(self.exportFrame.adviceRowsContent, index)
        rows[index] = row
        row.currentButton.item = upgrade.current
        row.candidateButton.item = upgrade.candidate
        row.currentButton.upgradeIndex = index
        row.candidateButton.upgradeIndex = index
        row.currentIcon:SetTexture(upgrade.current and upgrade.current.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.candidateIcon:SetTexture(upgrade.candidate and upgrade.candidate.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.slot:SetText(GEAR_ENGINE.EquipmentSlotLabel(upgrade.slotKey, locale))
        row.name:SetText(ItemColoredName(upgrade.candidate))
        row.gain:SetText("|cff33ff99+" .. CompactNumber(upgrade.scoreGain, 2) .. "|r\n"
            .. GEAR_ENGINE.RecommendationVerdictLabel(upgrade.verdict, locale))
        row.reason:SetText(LForLocale(locale, "advice_gains", GEAR_ENGINE.DeltaText(upgrade.statGains, locale))
            .. "; " .. LForLocale(locale, "advice_losses", GEAR_ENGINE.DeltaText(upgrade.statLosses, locale))
            .. "\n" .. LForLocale(locale, "advice_impact", GEAR_ENGINE.BenchmarkImpactText(upgrade.benchmarkImpacts, locale))
            .. "; " .. LForLocale(locale, "advice_evidence", LForLocale(locale, "advice_evidence_" .. tostring(upgrade.evidence or "low"))))
        row:Show()
    end

    local selectedIndex = math.min(self.selectedAdviceIndex or 1, #upgrades)
    self:RefreshGearComparison(profile, engine, selectedIndex > 0 and selectedIndex or nil)

    if self.exportFrame.adviceRowsContent.SetHeight then
        self.exportFrame.adviceRowsContent:SetHeight(math.max(220, (#upgrades * 74) + 8))
    end
    if self.exportFrame.adviceContent.SetHeight then
        self.exportFrame.adviceContent:SetHeight(math.max(568, (#upgrades * 74) + 360))
    end
    return #upgrades
end

function Addon:RefreshVisualItems(items)
    if not self.exportFrame or not self.exportFrame.itemListContent then
        return
    end

    items = items or {}
    local rows = self.exportFrame.itemRows or {}
    self.exportFrame.itemRows = rows

    if self.exportFrame.emptyItems then
        if #items == 0 then
            self.exportFrame.emptyItems:SetText(L("item_view_empty"))
            self.exportFrame.emptyItems:Show()
        else
            self.exportFrame.emptyItems:Hide()
        end
    end

    for index = 1, #rows do
        rows[index]:Hide()
    end

    for index = 1, #items do
        local item = items[index]
        local row = rows[index]
        if not row then
            row = self:CreateVisualItemRow(self.exportFrame.itemListContent, index)
            rows[index] = row
        end

        row.item = item
        row.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.name:SetText(item.nameColored or item.name or "Unknown Item")
        local locale = ClientLocale()
        row.meta:SetText(GEAR_ENGINE.ItemLocationLabel(item, locale) .. "  " .. QualityDisplay(item) .. "  "
            .. GEAR_ENGINE.ReportTerms(locale).item_level .. " " .. ItemLevelDisplay(item) .. "  " .. ItemTypeDisplay(item))
        if item.count and item.count > 1 then
            row.count:SetText("x" .. tostring(item.count))
        else
            row.count:SetText("")
        end
        row:Show()
    end

    if self.exportFrame.itemListContent.SetHeight then
        self.exportFrame.itemListContent:SetHeight(math.max(300, (#items * 44) + 8))
    end
end

function Addon:RefreshOverview(profile, chartStats, strategyBook, items)
    if not self.exportFrame or not self.exportFrame.overviewText then
        return 0
    end

    local text, roleCount = Addon.BuildOverviewText(profile, chartStats, strategyBook, items)
    self.exportFrame.overviewText:SetText(text)
    self.exportFrame.overviewRoleCount = roleCount

    if self.exportFrame.overviewContent and self.exportFrame.overviewContent.SetHeight then
        local _, breaks = tostring(text or ""):gsub("\n", "\n")
        self.exportFrame.overviewContent:SetHeight(math.max(300, ((breaks + 1) * 16) + 28))
    end

    return roleCount or 0
end

function Addon:RefreshStatsAnalysis(profile, chartStats, strategyBook)
    if not self.exportFrame or not self.exportFrame.analysisText then
        return 0
    end

    local text, roleCount = BuildStatsAnalysisText(profile, chartStats, strategyBook)
    self.exportFrame.analysisText:SetText(text)
    self.exportFrame.analysisRoleCount = roleCount

    if self.exportFrame.analysisContent and self.exportFrame.analysisContent.SetHeight then
        local _, breaks = tostring(text or ""):gsub("\n", "\n")
        self.exportFrame.analysisContent:SetHeight(math.max(300, ((breaks + 1) * 15) + 24))
    end

    return roleCount or 0
end

function Addon:CreatePhase2TargetRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    SetFrameSize(row, 486, 42)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 44))

    local icon = row:CreateTexture(nil, "ARTWORK")
    SetFrameSize(icon, 34, 34)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    name:SetJustifyH("LEFT")

    local meta = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    meta:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -20)
    meta:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    meta:SetJustifyH("LEFT")

    row:SetScript("OnEnter", function(self)
        if not self.item or not GameTooltip then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetHyperlink then
            GameTooltip:SetHyperlink(self.item.link or ("item:" .. tostring(self.item.itemID)))
        else
            GameTooltip:SetText(self.item.name or ("Item #" .. tostring(self.item.itemID)))
        end
        if GameTooltip.AddLine then
            GameTooltip:AddLine(self.item.wowheadUrl or "")
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    row.icon = icon
    row.name = name
    row.meta = meta
    return row
end

function Addon:RefreshPhase2ModeButtons(engine, locale)
    for index = 1, #(self.exportFrame and self.exportFrame.phase2ModeButtons or {}) do
        local button = self.exportFrame.phase2ModeButtons[index]
        local mode = engine and engine.availableModes and engine.availableModes[index]
        if mode then
            button.modeKey = mode.key
            local label = GEAR_ENGINE.LocalizedDataLabel(mode.labels, locale, mode.key)
            button:SetText((mode.key == engine.modeKey and "> " or "") .. tostring(label))
            button:Show()
        else
            button.modeKey = nil
            button:Hide()
        end
    end
end

function Addon:RefreshPhase2Strategy(profile, engine)
    if not self.exportFrame or not self.exportFrame.phase2Content then
        return 0
    end

    local locale = profile and profile.locale or ClientLocale()
    local phase2 = engine and engine.phase2 or {}
    local progress = phase2.presetProgress or { missing = {} }
    self:RefreshPhase2ModeButtons(engine, locale)
    self.exportFrame.phase2Summary:SetText(LForLocale(locale, "phase2_summary",
        GEAR_ENGINE.GearRoleLabel(engine, locale),
        GEAR_ENGINE.Phase2ModeLabel(engine, locale),
        tostring(phase2.databaseVersion or "?"),
        tostring(phase2.patch or "?")))
    self.exportFrame.phase2Details:SetText(
        LForLocale(locale, "phase2_set_goal", GEAR_ENGINE.Phase2Goal(engine, locale))
        .. "\n" .. LForLocale(locale, "phase2_caps", GEAR_ENGINE.Phase2CapText(engine, locale))
        .. "\n" .. LForLocale(locale, "phase2_preset", GEAR_ENGINE.Phase2PresetText(engine, locale, 0))
        .. "\n" .. LForLocale(locale, "phase2_evidence", GEAR_ENGINE.Phase2EvidenceLabel(engine, locale))
        .. "\n" .. LForLocale(locale, "phase2_talent", tostring(phase2.talentString or GEAR_ENGINE.ReportTerms(locale).none)))

    local rows = self.exportFrame.phase2TargetRows or {}
    self.exportFrame.phase2TargetRows = rows
    for index = 1, #rows do
        rows[index]:Hide()
    end

    for index = 1, #(progress.missing or {}) do
        local item = progress.missing[index]
        local row = rows[index] or self:CreatePhase2TargetRow(self.exportFrame.phase2TargetsContent, index)
        rows[index] = row
        row.item = item
        row.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.name:SetText(item.link or item.name or ("Item #" .. tostring(item.itemID)))
        row.meta:SetText(GEAR_ENGINE.EquipmentSlotLabel(item.slotKey, locale) .. " · ID " .. tostring(item.itemID)
            .. (item.itemLevel and " · " .. GEAR_ENGINE.ReportTerms(locale).item_level .. " " .. tostring(item.itemLevel) or ""))
        row:Show()
    end

    if #(progress.missing or {}) == 0 then
        self.exportFrame.phase2TargetsEmpty:SetText(LForLocale(locale, "phase2_no_targets"))
        self.exportFrame.phase2TargetsEmpty:Show()
    else
        self.exportFrame.phase2TargetsEmpty:Hide()
    end

    if self.exportFrame.phase2TargetsContent.SetHeight then
        self.exportFrame.phase2TargetsContent:SetHeight(math.max(42, (#(progress.missing or {}) * 44) + 8))
    end
    if self.exportFrame.phase2Content.SetHeight then
        self.exportFrame.phase2Content:SetHeight(math.max(390, (#(progress.missing or {}) * 44) + 258))
    end
    return #(progress.missing or {})
end

function Addon:SelectExportText()
    if not self.exportFrame or not self.exportFrame.editBox then
        return
    end

    self:SetExportView("text")
    self.exportFrame.editBox:SetCursorPosition(0)
    self.exportFrame.editBox:HighlightText()
    self.exportFrame.editBox:SetFocus()
end

function Addon:RefreshExport(scope, format, filter)
    self.exportScope = scope or self.exportScope or "all"
    self.exportFormat = NormalizeExportFormat(format or self.exportFormat or "ai")
    if filter ~= nil then
        self.exportFilter = NormalizeExportFilter(filter)
    else
        self.exportFilter = self.exportFilter or NormalizeExportFilter(nil)
    end

    if not self.exportFrame then
        return
    end

    local text = self:BuildExport(self.exportScope, self.exportFormat, self.exportFilter)
    local items = self:CollectExportItems(self.exportScope, self.exportFilter)
    local bagCount, bankCount = self:SavedItemCounts()
    local profile = self:GetProfile()
    local chartStats = BuildChartStats(items)
    local strategyBook = BuildStrategyBook(profile, chartStats)
    local gearEngine = GEAR_ENGINE.BuildGearRecommendations(profile, items, strategyBook, self.selectedAdviceRoleKey, self.selectedStrategyModeKey)
    self.selectedAdviceRoleKey = gearEngine.roleKey
    self.selectedStrategyModeKey = gearEngine.modeKey
    local overviewRoleCount = 0
    local analysisRoleCount = 0
    local adviceCount = 0
    local phase2TargetCount = 0
    self.exportFrame.editBox:SetText(text)
    self:RefreshVisualItems(items)
    overviewRoleCount = self:RefreshOverview(profile, chartStats, strategyBook, items)
    adviceCount = self:RefreshGearAdvice(profile, gearEngine)
    analysisRoleCount = self:RefreshStatsAnalysis(profile, chartStats, strategyBook)
    phase2TargetCount = self:RefreshPhase2Strategy(profile, gearEngine)
    self:SetExportView(self.exportView or "overview")

    if self.exportView == "text" then
        self.exportFrame.editBox:SetCursorPosition(0)
        self.exportFrame.editBox:HighlightText()
        self.exportFrame.editBox:SetFocus()
    end

    if self.exportFrame.summary then
        self.exportFrame.summary:SetText(L("summary", bagCount, bankCount, LocalizedScopeTitle(self.exportScope, ClientLocale()), LocalizedExportFilterTitle(self.exportFilter, ClientLocale()), LocalizedExportFormatTitle(self.exportFormat, ClientLocale())))
    end

    if self.exportView == "text" then
        self.exportFrame.status:SetText(L("status_generated", LocalizedExportFormatTitle(self.exportFormat, ClientLocale()), LocalizedExportFilterTitle(self.exportFilter, ClientLocale())))
    elseif self.exportView == "analysis" then
        self.exportFrame.status:SetText(L("status_analysis", analysisRoleCount))
    elseif self.exportView == "advice" then
        self.exportFrame.status:SetText(L("status_advice", adviceCount, GEAR_ENGINE.GearRoleLabel(gearEngine, profile.locale)))
    elseif self.exportView == "phase2" then
        self.exportFrame.status:SetText(L("status_phase2", GEAR_ENGINE.GearRoleLabel(gearEngine, profile.locale), GEAR_ENGINE.Phase2ModeLabel(gearEngine, profile.locale), phase2TargetCount))
    elseif self.exportView == "items" then
        self.exportFrame.status:SetText(L("status_visual", #items))
    else
        self.exportFrame.status:SetText(L("status_overview", #items, overviewRoleCount))
    end
end

function Addon:CreateExportFrame()
    local exportFrame = CreateFrame("Frame", "TBCGearExporterExportFrame", UIParent, BackdropTemplate())
    SetFrameSize(exportFrame, 820, 560)
    exportFrame:SetPoint("CENTER")
    exportFrame:SetFrameStrata("DIALOG")
    exportFrame:SetMovable(true)
    exportFrame:EnableMouse(true)
    exportFrame:RegisterForDrag("LeftButton")
    exportFrame:SetScript("OnDragStart", exportFrame.StartMoving)
    exportFrame:SetScript("OnDragStop", exportFrame.StopMovingOrSizing)
    exportFrame:Hide()

    if exportFrame.SetBackdrop then
        exportFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })

        if exportFrame.SetBackdropColor then
            exportFrame:SetBackdropColor(0, 0, 0, 0.92)
        end

        if exportFrame.SetBackdropBorderColor then
            exportFrame:SetBackdropBorderColor(0.7, 0.55, 0.25, 1)
        end
    end

    local title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText(L("addon_title"))

    local close = CreateFrame("Button", nil, exportFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local summary = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summary:SetPoint("TOPLEFT", 20, -42)
    summary:SetPoint("TOPRIGHT", -20, -42)
    summary:SetJustifyH("LEFT")
    summary:SetText(L("summary_initial"))

    local leftPanel = CreateFrame("Frame", nil, exportFrame)
    SetFrameSize(leftPanel, 238, 438)
    leftPanel:SetPoint("TOPLEFT", 20, -64)

    local dbLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dbLabel:SetPoint("TOPLEFT", 0, 0)
    dbLabel:SetText(L("local_db_label"))

    local scan = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(scan, 100, 24)
    scan:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, -28)
    scan:SetText(L("scan_button"))
    scan:SetScript("OnClick", function()
        Addon:ScanBagsAndReport(L("bags_scanned"))
        if Addon.bankOpen then
            Addon:ScanBankAndReport(L("bank_scanned"))
        else
            Addon:Print(L("open_bank_hint"))
        end
        Addon:RefreshExport()
    end)

    local export = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(export, 86, 24)
    export:SetPoint("LEFT", scan, "RIGHT", 8, 0)
    export:SetText(L("export_button"))
    export:SetScript("OnClick", function()
        Addon:ExportSaved(Addon.exportScope or "all")
    end)

    local debugButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(debugButton, 82, 24)
    debugButton:SetPoint("TOPLEFT", scan, "BOTTOMLEFT", 0, -8)
    debugButton:SetText(L("debug_button"))
    debugButton:SetScript("OnClick", function()
        Addon:DebugContainers()
    end)

    local selectButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(selectButton, 98, 24)
    selectButton:SetPoint("LEFT", debugButton, "RIGHT", 8, 0)
    selectButton:SetText(L("select_button"))
    selectButton:SetScript("OnClick", function()
        Addon:SelectExportText()
        Addon.exportFrame.status:SetText(L("status_selected"))
    end)

    local sourceLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceLabel:SetPoint("TOPLEFT", 0, -92)
    sourceLabel:SetText(L("source_label"))

    local allSource = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(allSource, 58, 24)
    allSource:SetPoint("TOPLEFT", sourceLabel, "BOTTOMLEFT", 0, -6)
    allSource:SetText(LocalizedScopeTitle("all", ClientLocale()))
    allSource:SetScript("OnClick", function()
        Addon:ExportSaved("all")
    end)

    local bags = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(bags, 62, 24)
    bags:SetPoint("LEFT", allSource, "RIGHT", 6, 0)
    bags:SetText(L("bags_button"))
    bags:SetScript("OnClick", function()
        Addon:ExportSaved("bags")
    end)

    local bank = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(bank, 62, 24)
    bank:SetPoint("TOPLEFT", allSource, "BOTTOMLEFT", 0, -6)
    bank:SetText(L("bank_button"))
    bank:SetScript("OnClick", function()
        Addon:ExportSaved("bank")
    end)

    local gear = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(gear, 68, 24)
    gear:SetPoint("LEFT", bank, "RIGHT", 6, 0)
    gear:SetText(L("gear_button"))
    gear:SetScript("OnClick", function()
        Addon:ExportSaved("gear")
    end)

    local formatLabel = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    formatLabel:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, -178)
    formatLabel:SetText(L("format_label"))

    local aiFormat = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(aiFormat, 52, 22)
    aiFormat:SetPoint("TOPLEFT", formatLabel, "BOTTOMLEFT", 0, -6)
    aiFormat:SetText("AI")
    aiFormat:SetScript("OnClick", function()
        Addon:ExportSaved(nil, "ai")
    end)

    local jsonFormat = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(jsonFormat, 60, 22)
    jsonFormat:SetPoint("LEFT", aiFormat, "RIGHT", 6, 0)
    jsonFormat:SetText("JSON")
    jsonFormat:SetScript("OnClick", function()
        Addon:ExportSaved(nil, "json")
    end)

    local markdownFormat = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(markdownFormat, 90, 22)
    markdownFormat:SetPoint("TOPLEFT", aiFormat, "BOTTOMLEFT", 0, -6)
    markdownFormat:SetText("Markdown")
    markdownFormat:SetScript("OnClick", function()
        Addon:ExportSaved(nil, "markdown")
    end)

    local textFormat = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(textFormat, 60, 22)
    textFormat:SetPoint("LEFT", markdownFormat, "RIGHT", 6, 0)
    textFormat:SetText(L("format_text_title"))
    textFormat:SetScript("OnClick", function()
        Addon:ExportSaved(nil, "text")
    end)

    local filterLabel = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    filterLabel:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, -270)
    filterLabel:SetText(L("filter_label"))

    local allQuality = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(allQuality, 62, 22)
    allQuality:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -6)
    allQuality:SetText(L("all_q_button"))
    allQuality:SetScript("OnClick", function()
        Addon:ExportSaved(nil, nil, "all")
    end)

    local rarePlus = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(rarePlus, 68, 22)
    rarePlus:SetPoint("LEFT", allQuality, "RIGHT", 6, 0)
    rarePlus:SetText(L("rare_plus_button"))
    rarePlus:SetScript("OnClick", function()
        Addon:ExportSaved(nil, nil, { qualityMin = 3 })
    end)

    local epicQuality = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(epicQuality, 62, 22)
    epicQuality:SetPoint("TOPLEFT", allQuality, "BOTTOMLEFT", 0, -6)
    epicQuality:SetText(L("epic_button"))
    epicQuality:SetScript("OnClick", function()
        Addon:ExportSaved(nil, nil, { qualityID = 4 })
    end)

    local gearEpic = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(gearEpic, 94, 22)
    gearEpic:SetPoint("LEFT", epicQuality, "RIGHT", 6, 0)
    gearEpic:SetText(L("gear_epic_button"))
    gearEpic:SetScript("OnClick", function()
        Addon:ExportSaved("gear", nil, { qualityID = 4 })
    end)

    local overviewTab = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(overviewTab, 64, 24)
    overviewTab:SetPoint("TOPLEFT", 282, -64)
    overviewTab:SetText(L("overview_tab"))
    overviewTab:SetScript("OnClick", function()
        Addon:SetExportView("overview")
        Addon:RefreshExport()
    end)

    local adviceTab = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(adviceTab, 86, 24)
    adviceTab:SetPoint("LEFT", overviewTab, "RIGHT", 6, 0)
    adviceTab:SetText(L("gear_advice_tab"))
    adviceTab:SetScript("OnClick", function()
        Addon:SetExportView("advice")
        Addon:RefreshExport()
    end)

    local itemsTab = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(itemsTab, 54, 24)
    itemsTab:SetPoint("LEFT", adviceTab, "RIGHT", 6, 0)
    itemsTab:SetText(L("items_tab"))
    itemsTab:SetScript("OnClick", function()
        Addon:SetExportView("items")
        Addon.exportFrame.status:SetText(L("status_visual", #(Addon:CollectExportItems(Addon.exportScope or "all", Addon.exportFilter))))
    end)

    local analysisTab = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(analysisTab, 90, 24)
    analysisTab:SetPoint("LEFT", itemsTab, "RIGHT", 6, 0)
    analysisTab:SetText(L("stats_analysis_tab"))
    analysisTab:SetScript("OnClick", function()
        Addon:SetExportView("analysis")
        Addon:RefreshExport()
    end)

    local phase2Tab = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(phase2Tab, 72, 24)
    phase2Tab:SetPoint("LEFT", analysisTab, "RIGHT", 6, 0)
    phase2Tab:SetText(L("phase2_tab"))
    phase2Tab:SetScript("OnClick", function()
        Addon:SetExportView("phase2")
        Addon:RefreshExport()
    end)

    local textTab = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(textTab, 82, 24)
    textTab:SetPoint("LEFT", phase2Tab, "RIGHT", 6, 0)
    textTab:SetText(L("text_export_tab"))
    textTab:SetScript("OnClick", function()
        Addon:SelectExportText()
    end)

    local overviewScroll = CreateFrame("ScrollFrame", "TBCGearExporterOverviewScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
    overviewScroll:SetPoint("TOPLEFT", 282, -96)
    overviewScroll:SetPoint("BOTTOMRIGHT", -38, 48)

    local overviewContent = CreateFrame("Frame", nil, overviewScroll)
    SetFrameSize(overviewContent, 490, 300)
    overviewScroll:SetScrollChild(overviewContent)

    local overviewText = overviewContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    overviewText:SetPoint("TOPLEFT", 4, -4)
    overviewText:SetPoint("RIGHT", overviewContent, "RIGHT", -8, 0)
    overviewText:SetJustifyH("LEFT")
    overviewText:SetText(L("overview_title"))

    local adviceScroll = CreateFrame("ScrollFrame", "TBCGearExporterAdviceScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
    adviceScroll:SetPoint("TOPLEFT", 282, -96)
    adviceScroll:SetPoint("BOTTOMRIGHT", -38, 48)

    local adviceContent = CreateFrame("Frame", nil, adviceScroll)
    SetFrameSize(adviceContent, 490, 300)
    adviceScroll:SetScrollChild(adviceContent)

    local adviceRoleLabel = adviceContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    adviceRoleLabel:SetPoint("TOPLEFT", 4, -4)
    adviceRoleLabel:SetText(L("advice_role_hint"))

    local adviceRoleButtons = {}
    for index = 1, 4 do
        local roleButton = CreateFrame("Button", nil, adviceContent, "UIPanelButtonTemplate")
        SetFrameSize(roleButton, 232, 22)
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        roleButton:SetPoint("TOPLEFT", adviceContent, "TOPLEFT", 4 + (column * 238), -22 - (row * 24))
        roleButton:SetScript("OnClick", function(self)
            if self.roleKey then
                Addon.selectedAdviceRoleKey = self.roleKey
                Addon.selectedAdviceIndex = 1
                Addon:RefreshExport()
            end
        end)
        roleButton:Hide()
        adviceRoleButtons[index] = roleButton
    end

    local adviceSummary = adviceContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    adviceSummary:SetPoint("TOPLEFT", 4, -76)
    adviceSummary:SetWidth(478)
    adviceSummary:SetHeight(88)
    adviceSummary:SetJustifyH("LEFT")
    adviceSummary:SetJustifyV("TOP")
    adviceSummary:SetText(L("advice_title"))

    local adviceCaveat = adviceContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    adviceCaveat:SetPoint("TOPLEFT", 4, -168)
    adviceCaveat:SetWidth(478)
    adviceCaveat:SetHeight(38)
    adviceCaveat:SetJustifyH("LEFT")
    adviceCaveat:SetJustifyV("TOP")
    adviceCaveat:SetText(L("advice_caveat"))

    local comparePanel = CreateFrame("Frame", nil, adviceContent, BackdropTemplate())
    SetFrameSize(comparePanel, 486, 118)
    comparePanel:SetPoint("TOPLEFT", adviceContent, "TOPLEFT", 2, -214)
    if comparePanel.SetBackdrop then
        comparePanel:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        comparePanel:SetBackdropColor(0.04, 0.05, 0.06, 0.96)
        comparePanel:SetBackdropBorderColor(0.55, 0.45, 0.22, 1)
    end

    local compareTitle = comparePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    compareTitle:SetPoint("TOPLEFT", 8, -7)
    compareTitle:SetText(L("compare_title"))

    local compareCurrentLabel = comparePanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    compareCurrentLabel:SetPoint("TOPLEFT", 10, -28)
    compareCurrentLabel:SetText(L("compare_current"))
    local compareCurrentButton = CreateFrame("Button", nil, comparePanel)
    SetFrameSize(compareCurrentButton, 42, 42)
    compareCurrentButton:SetPoint("TOPLEFT", 8, -44)
    local compareCurrentIcon = compareCurrentButton:CreateTexture(nil, "ARTWORK")
    compareCurrentIcon:SetPoint("TOPLEFT", 0, 0)
    compareCurrentIcon:SetPoint("BOTTOMRIGHT", 0, 0)

    local compareArrow = comparePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    compareArrow:SetPoint("LEFT", compareCurrentButton, "RIGHT", 6, 0)
    compareArrow:SetText(">")

    local compareCandidateLabel = comparePanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    compareCandidateLabel:SetPoint("TOPLEFT", 68, -28)
    compareCandidateLabel:SetText(L("compare_candidate"))
    local compareCandidateButton = CreateFrame("Button", nil, comparePanel)
    SetFrameSize(compareCandidateButton, 42, 42)
    compareCandidateButton:SetPoint("TOPLEFT", 68, -44)
    local compareCandidateIcon = compareCandidateButton:CreateTexture(nil, "ARTWORK")
    compareCandidateIcon:SetPoint("TOPLEFT", 0, 0)
    compareCandidateIcon:SetPoint("BOTTOMRIGHT", 0, 0)

    local compareNames = comparePanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    compareNames:SetPoint("TOPLEFT", 120, -27)
    compareNames:SetPoint("RIGHT", comparePanel, "RIGHT", -8, 0)
    compareNames:SetJustifyH("LEFT")
    compareNames:SetText(L("compare_select_hint"))

    local compareVerdict = comparePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    compareVerdict:SetPoint("TOPLEFT", 120, -47)
    compareVerdict:SetPoint("RIGHT", comparePanel, "RIGHT", -8, 0)
    compareVerdict:SetJustifyH("LEFT")

    local compareDetails = comparePanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    compareDetails:SetPoint("TOPLEFT", 120, -66)
    compareDetails:SetPoint("RIGHT", comparePanel, "RIGHT", -8, 0)
    compareDetails:SetJustifyH("LEFT")

    compareCurrentButton:SetScript("OnEnter", function(self)
        GEAR_ENGINE.ShowRecommendationTooltip(self, self.item)
    end)
    compareCandidateButton:SetScript("OnEnter", function(self)
        GEAR_ENGINE.ShowRecommendationTooltip(self, self.item)
    end)
    compareCurrentButton:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    compareCandidateButton:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    local adviceRowsContent = CreateFrame("Frame", nil, adviceContent)
    SetFrameSize(adviceRowsContent, 490, 220)
    adviceRowsContent:SetPoint("TOPLEFT", adviceContent, "TOPLEFT", 0, -344)

    local adviceEmpty = adviceRowsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    adviceEmpty:SetPoint("TOPLEFT", 4, -4)
    adviceEmpty:SetPoint("RIGHT", adviceRowsContent, "RIGHT", -8, 0)
    adviceEmpty:SetJustifyH("LEFT")
    adviceEmpty:SetText(L("advice_no_upgrades"))

    local visualScroll = CreateFrame("ScrollFrame", "TBCGearExporterVisualScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
    visualScroll:SetPoint("TOPLEFT", 282, -96)
    visualScroll:SetPoint("BOTTOMRIGHT", -38, 48)
    local itemListContent = CreateFrame("Frame", nil, visualScroll)
    SetFrameSize(itemListContent, 490, 300)
    visualScroll:SetScrollChild(itemListContent)

    local emptyItems = itemListContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyItems:SetPoint("TOPLEFT", 4, -4)
    emptyItems:SetText(L("item_view_empty"))
    emptyItems:Hide()

    local analysisScroll = CreateFrame("ScrollFrame", "TBCGearExporterAnalysisScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
    analysisScroll:SetPoint("TOPLEFT", 282, -96)
    analysisScroll:SetPoint("BOTTOMRIGHT", -38, 48)

    local analysisContent = CreateFrame("Frame", nil, analysisScroll)
    SetFrameSize(analysisContent, 490, 300)
    analysisScroll:SetScrollChild(analysisContent)

    local analysisText = analysisContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    analysisText:SetPoint("TOPLEFT", 4, -4)
    analysisText:SetPoint("RIGHT", analysisContent, "RIGHT", -8, 0)
    analysisText:SetJustifyH("LEFT")
    analysisText:SetText(L("analysis_no_roles"))

    local phase2Scroll = CreateFrame("ScrollFrame", "TBCGearExporterPhase2ScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
    phase2Scroll:SetPoint("TOPLEFT", 282, -96)
    phase2Scroll:SetPoint("BOTTOMRIGHT", -38, 48)

    local phase2Content = CreateFrame("Frame", nil, phase2Scroll)
    SetFrameSize(phase2Content, 490, 390)
    phase2Scroll:SetScrollChild(phase2Content)

    local phase2Title = phase2Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    phase2Title:SetPoint("TOPLEFT", 4, -4)
    phase2Title:SetText(L("phase2_title"))

    local phase2Summary = phase2Content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    phase2Summary:SetPoint("TOPLEFT", 4, -28)
    phase2Summary:SetPoint("RIGHT", phase2Content, "RIGHT", -8, 0)
    phase2Summary:SetJustifyH("LEFT")

    local phase2ModeHint = phase2Content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    phase2ModeHint:SetPoint("TOPLEFT", 4, -52)
    phase2ModeHint:SetText(L("phase2_mode_hint"))

    local phase2ModeButtons = {}
    for index = 1, 3 do
        local modeButton = CreateFrame("Button", nil, phase2Content, "UIPanelButtonTemplate")
        SetFrameSize(modeButton, 150, 22)
        modeButton:SetPoint("TOPLEFT", phase2Content, "TOPLEFT", 4 + ((index - 1) * 158), -68)
        modeButton:SetScript("OnClick", function(self)
            if self.modeKey then
                Addon.selectedStrategyModeKey = self.modeKey
                Addon.selectedAdviceIndex = 1
                Addon:RefreshExport()
            end
        end)
        modeButton:Hide()
        phase2ModeButtons[index] = modeButton
    end

    local phase2Details = phase2Content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    phase2Details:SetPoint("TOPLEFT", 4, -100)
    phase2Details:SetPoint("RIGHT", phase2Content, "RIGHT", -8, 0)
    phase2Details:SetJustifyH("LEFT")

    local phase2TargetsTitle = phase2Content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    phase2TargetsTitle:SetPoint("TOPLEFT", 4, -204)
    phase2TargetsTitle:SetText(L("phase2_targets"))

    local phase2TargetsContent = CreateFrame("Frame", nil, phase2Content)
    SetFrameSize(phase2TargetsContent, 486, 42)
    phase2TargetsContent:SetPoint("TOPLEFT", phase2Content, "TOPLEFT", 0, -228)

    local phase2TargetsEmpty = phase2TargetsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    phase2TargetsEmpty:SetPoint("TOPLEFT", 4, -4)
    phase2TargetsEmpty:SetPoint("RIGHT", phase2TargetsContent, "RIGHT", -8, 0)
    phase2TargetsEmpty:SetJustifyH("LEFT")
    phase2TargetsEmpty:SetText(L("phase2_no_targets"))

    local textScroll = CreateFrame("ScrollFrame", "TBCGearExporterScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
    textScroll:SetPoint("TOPLEFT", 282, -96)
    textScroll:SetPoint("BOTTOMRIGHT", -38, 48)

    local editBox = CreateFrame("EditBox", nil, textScroll)
    SetFrameSize(editBox, 490, 300)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnTextChanged", function(self)
        local lineCount = self.GetNumLines and self:GetNumLines() or 1
        local height = math.max(300, (lineCount * 14) + 20)
        if self.SetHeight then
            self:SetHeight(height)
        end
    end)
    textScroll:SetScrollChild(editBox)

    local status = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT", 20, 24)
    status:SetPoint("BOTTOMRIGHT", -20, 24)
    status:SetJustifyH("LEFT")
    status:SetText(L("status_ready"))

    exportFrame.editBox = editBox
    exportFrame.summary = summary
    exportFrame.status = status
    exportFrame.formatLabel = formatLabel
    exportFrame.filterLabel = filterLabel
    exportFrame.sourceLabel = sourceLabel
    exportFrame.dbLabel = dbLabel
    exportFrame.overviewTab = overviewTab
    exportFrame.adviceTab = adviceTab
    exportFrame.itemsTab = itemsTab
    exportFrame.analysisTab = analysisTab
    exportFrame.phase2Tab = phase2Tab
    exportFrame.textTab = textTab
    exportFrame.overviewScroll = overviewScroll
    exportFrame.adviceScroll = adviceScroll
    exportFrame.visualScroll = visualScroll
    exportFrame.analysisScroll = analysisScroll
    exportFrame.phase2Scroll = phase2Scroll
    exportFrame.textScroll = textScroll
    exportFrame.overviewContent = overviewContent
    exportFrame.overviewText = overviewText
    exportFrame.adviceContent = adviceContent
    exportFrame.adviceRoleLabel = adviceRoleLabel
    exportFrame.adviceRoleButtons = adviceRoleButtons
    exportFrame.adviceSummary = adviceSummary
    exportFrame.adviceCaveat = adviceCaveat
    exportFrame.comparePanel = comparePanel
    exportFrame.compareCurrentButton = compareCurrentButton
    exportFrame.compareCurrentIcon = compareCurrentIcon
    exportFrame.compareCandidateButton = compareCandidateButton
    exportFrame.compareCandidateIcon = compareCandidateIcon
    exportFrame.compareNames = compareNames
    exportFrame.compareVerdict = compareVerdict
    exportFrame.compareDetails = compareDetails
    exportFrame.adviceRowsContent = adviceRowsContent
    exportFrame.adviceEmpty = adviceEmpty
    exportFrame.adviceRows = {}
    exportFrame.itemListContent = itemListContent
    exportFrame.analysisContent = analysisContent
    exportFrame.analysisText = analysisText
    exportFrame.phase2Content = phase2Content
    exportFrame.phase2Summary = phase2Summary
    exportFrame.phase2ModeButtons = phase2ModeButtons
    exportFrame.phase2Details = phase2Details
    exportFrame.phase2TargetsContent = phase2TargetsContent
    exportFrame.phase2TargetsEmpty = phase2TargetsEmpty
    exportFrame.phase2TargetRows = {}
    exportFrame.emptyItems = emptyItems
    exportFrame.itemRows = {}
    self.exportFrame = exportFrame
    self:SetExportView(self.exportView or "overview")
end

function Addon:ShowExport(scope, format, filter)
    if not self.exportFrame then
        self:CreateExportFrame()
    end

    self.exportFrame:Show()
    self:RefreshExport(scope, format, filter)
end

function Addon:ExportSaved(scope, format, filter)
    local selectedFormat = format
    if selectedFormat and Trim(selectedFormat) == "" then
        selectedFormat = nil
    end

    self:ShowExport(scope or self.exportScope or "all", selectedFormat, filter)
    local bagCount, bankCount = self:SavedItemCounts()
    self:Print(L("export_opened", LocalizedExportFormatTitle(self.exportFormat, ClientLocale()), bagCount, bankCount, LocalizedExportFilterTitle(self.exportFilter, ClientLocale())))
end

function Addon:CreateMinimapButton()
    if self.minimapButton then
        return self.minimapButton
    end

    if not Minimap then
        return nil
    end

    local button = CreateFrame("Button", "TBCGearExporterMinimapButton", Minimap)
    SetFrameSize(button, 32, 32)
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52, -4)
    button:SetFrameStrata("MEDIUM")
    button:EnableMouse(true)

    if button.RegisterForClicks then
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end

    if button.SetFrameLevel and Minimap.GetFrameLevel then
        button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    end

    local icon = button:CreateTexture(nil, "BACKGROUND")
    SetFrameSize(icon, 20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture(MINIMAP_ICON_TEXTURE)

    local border = button:CreateTexture(nil, "OVERLAY")
    SetFrameSize(border, 53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            Addon:ScanBagsAndReport(L("bags_scanned"))
            if Addon.bankOpen then
                Addon:ScanBankAndReport(L("bank_scanned"))
            else
                Addon:Print(L("open_bank_hint"))
            end
            return
        end

        Addon:ExportSaved("all")
    end)

    button:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(L("addon_title"))
            GameTooltip:AddLine(L("tooltip_left"), 1, 1, 1)
            GameTooltip:AddLine(L("tooltip_right"), 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    button.icon = icon
    button.border = border
    self.minimapButton = button
    return button
end

function Addon:ClearProfile()
    local profile = self:GetProfile()
    profile.bags = { updatedAt = 0, items = {} }
    profile.bank = { updatedAt = 0, items = {} }
    profile.talents = { updatedAt = 0, available = false, summary = "", tabs = {} }
    profile.localDB = {
        name = DB_NAME,
        version = 2,
        savedAt = 0,
        bagSavedAt = 0,
        bankSavedAt = 0,
        talentSavedAt = 0,
        talentSummary = "",
        talentPrimaryTab = nil,
        talentTotalPoints = 0,
        bagItemCount = 0,
        bankItemCount = 0,
    }
end

function Addon:ShowHelp()
    self:Print(L("help_commands"))
end

function Addon:HandleSlash(message)
    local input = Trim(message):lower()
    local command, argument = input:match("^(%S+)%s*(.-)$")
    command = command or ""
    argument = argument or ""

    if command == "" or command == "gui" or command == "show" then
        self:ExportSaved("all", nil, "all")
        return
    end

    if command == "export" then
        local scope, format, filter = ParseExportOptions("all", argument)
        self:ExportSaved(scope, format, filter)
        return
    end

    if command == "ai" or command == "json" or command == "markdown" or command == "md" or command == "text" or command == "txt" then
        local scope, _, filter = ParseExportOptions("all", argument)
        self:ExportSaved(scope, command, filter)
        return
    end

    if command == "bags" then
        local scope, format, filter = ParseExportOptions("bags", argument)
        self:ExportSaved(scope, format, filter)
        return
    end

    if command == "bank" then
        local scope, format, filter = ParseExportOptions("bank", argument)
        self:ExportSaved(scope, format, filter)
        return
    end

    if command == "gear" then
        local scope, format, filter = ParseExportOptions("gear", argument)
        self:ExportSaved(scope, format, filter)
        return
    end

    if command == "scan" then
        self:ScanBagsAndReport(L("bags_scanned"))
        if self.bankOpen then
            self:ScanBankAndReport(L("bank_scanned"))
        else
            self:Print(L("open_bank_hint"))
        end
        return
    end

    if command == "debug" then
        self:DebugContainers()
        return
    end

    if command == "clear" then
        self:ClearProfile()
        self:Print(L("clear_done"))
        if self.exportFrame and self.exportFrame:IsShown() then
            self:RefreshExport()
        end
        return
    end

    local scope, format, filter, recognized = ParseExportOptions("all", input)
    if recognized > 0 or ExportFilterHasCriteria(filter) then
        self:ExportSaved(scope, format, filter)
        return
    end

    self:ShowHelp()
end

function Addon:OnAddonLoaded(loadedName)
    if loadedName ~= addonName then
        return
    end

    self.db = _G[DB_NAME] or {}
    _G[DB_NAME] = self.db
    self:GetProfile()

    SafeRegister("PLAYER_LOGIN")
    SafeRegister("PLAYER_TALENT_UPDATE")
    SafeRegister("CHARACTER_POINTS_CHANGED")
    SafeRegister("PLAYER_EQUIPMENT_CHANGED")
    SafeRegister("BAG_OPEN")
    SafeRegister("BAG_UPDATE")
    SafeRegister("BAG_UPDATE_DELAYED")
    SafeRegister("BANKFRAME_OPENED")
    SafeRegister("BANKFRAME_CLOSED")
    SafeRegister("PLAYERBANKSLOTS_CHANGED")
    SafeRegister("PLAYERBANKBAGSLOTS_CHANGED")

    SLASH_TBCGEAREXPORTER1 = "/tbcgear"
    SLASH_TBCGEAREXPORTER2 = "/tbcexport"
    SlashCmdList.TBCGEAREXPORTER = function(message)
        Addon:HandleSlash(message)
    end
end

function Addon:OnEvent(eventName, ...)
    if eventName == "ADDON_LOADED" then
        self:OnAddonLoaded(...)
        return
    end

    if eventName == "PLAYER_LOGIN" then
        self:CreateMinimapButton()
        local snapshot = self:ScanBags()
        self:Print(L("loaded", self:FormatScanSummary(L("bags_label"), snapshot)))
        return
    end

    if eventName == "PLAYER_TALENT_UPDATE" or eventName == "CHARACTER_POINTS_CHANGED" then
        self:SaveTalentSnapshot()
        return
    end

    if eventName == "PLAYER_EQUIPMENT_CHANGED" then
        self:SaveCharacterStatsSnapshot()
        self:SaveEquippedSnapshot()
        if self.exportFrame and self.exportFrame:IsShown() then
            self:RefreshExport()
        end
        return
    end

    if eventName == "BAG_OPEN" then
        local bagID = ...
        local snapshot = self:ScanBags()
        if bagID ~= nil then
            self:Print(L("debug_bag_open_id", tostring(bagID), self:FormatScanSummary(L("bags_label"), snapshot)))
        else
            self:Print(L("debug_bag_open", self:FormatScanSummary(L("bags_label"), snapshot)))
        end
        return
    end

    if eventName == "BAG_UPDATE_DELAYED" or eventName == "BAG_UPDATE" then
        self:ScheduleBagScan()
        if self.bankOpen then
            self:ScheduleBankScan()
        end
        return
    end

    if eventName == "BANKFRAME_OPENED" then
        self.bankOpen = true
        local snapshot = self:ScanBank()
        self:Print(L("debug_bank_open", self:FormatScanSummary(L("bank_label"), snapshot)))
        return
    end

    if eventName == "BANKFRAME_CLOSED" then
        self.bankOpen = false
        return
    end

    if eventName == "PLAYERBANKSLOTS_CHANGED" or eventName == "PLAYERBANKBAGSLOTS_CHANGED" then
        self:ScheduleBankScan()
    end
end

frame:SetScript("OnEvent", function(_, eventName, ...)
    Addon:OnEvent(eventName, ...)
end)

if _G.TBCGearExporterTestMode then
    Addon._testing = {
        SafeRegister = SafeRegister,
        SetFrameSize = SetFrameSize,
        BackdropTemplate = BackdropTemplate,
        HasCContainer = HasCContainer,
        HasLegacyContainer = HasLegacyContainer,
        ContainerApiName = ContainerApiName,
        YesNo = YesNo,
        GetContainerNumSlotsCompat = GetContainerNumSlotsCompat,
        GetContainerItemLinkCompat = GetContainerItemLinkCompat,
        ValuesFromContainerInfo = ValuesFromContainerInfo,
        Trim = Trim,
        Now = Now,
        FormatTime = FormatTime,
        ParseItemID = ParseItemID,
        WowheadItemURL = WowheadItemURL,
        ItemWowheadURL = ItemWowheadURL,
        ParseItemString = ParseItemString,
        ParseItemName = ParseItemName,
        NormalizeQualityColorHex = NormalizeQualityColorHex,
        ColorChannelToByte = ColorChannelToByte,
        QualityColorHex = QualityColorHex,
        ParseItemLinkColorHex = ParseItemLinkColorHex,
        ItemQualityColorHex = ItemQualityColorHex,
        CompactNumber = CompactNumber,
        NormalizeStatToken = GEAR_ENGINE.NormalizeStatToken,
        ComparisonStatToken = GEAR_ENGINE.ComparisonStatToken,
        ColorizeItemName = ColorizeItemName,
        ItemColoredName = ItemColoredName,
        HtmlEscape = HtmlEscape,
        MarkdownItemName = MarkdownItemName,
        QualityDisplay = QualityDisplay,
        ItemLevelDisplay = ItemLevelDisplay,
        ItemTypeDisplay = ItemTypeDisplay,
        QualityName = QualityName,
        LocalizedQualityName = LocalizedQualityName,
        TitleCase = TitleCase,
        CleanStatLabel = CleanStatLabel,
        StatLabel = StatLabel,
        BuildStatList = BuildStatList,
        FormatStats = FormatStats,
        JsonString = JsonString,
        JsonValue = JsonValue,
        JsonField = JsonField,
        ScopeTitle = ScopeTitle,
        LocalizedScopeTitle = LocalizedScopeTitle,
        NormalizeExportFormat = NormalizeExportFormat,
        IsExportFormatToken = IsExportFormatToken,
        ExportFormatTitle = ExportFormatTitle,
        SplitWords = SplitWords,
        NormalizeQualityID = NormalizeQualityID,
        DefaultExportFilter = DefaultExportFilter,
        NormalizeExportFilter = NormalizeExportFilter,
        ExportFilterHasCriteria = ExportFilterHasCriteria,
        ExportFilterTitle = ExportFilterTitle,
        LocalizedExportFilterTitle = LocalizedExportFilterTitle,
        ItemQualityID = ItemQualityID,
        ExportFilterMatchesItem = ExportFilterMatchesItem,
        NormalizeExportScope = NormalizeExportScope,
        ParseExportOptions = ParseExportOptions,
        AppendIndented = AppendIndented,
        AppendJsonStringArray = AppendJsonStringArray,
        AppendTalentJson = AppendTalentJson,
        LocationLabel = LocationLabel,
        SourceLabel = SourceLabel,
        ItemLocationLabel = GEAR_ENGINE.ItemLocationLabel,
        ReportTerms = GEAR_ENGINE.ReportTerms,
        CategoryLabel = GEAR_ENGINE.CategoryLabel,
        LocalizedStatLabel = GEAR_ENGINE.LocalizedStatLabel,
        FormatLocalizedStats = GEAR_ENGINE.FormatLocalizedStats,
        DeltaText = GEAR_ENGINE.DeltaText,
        EvidenceLabel = GEAR_ENGINE.EvidenceLabel,
        RecommendationVerdictLabel = GEAR_ENGINE.RecommendationVerdictLabel,
        VerdictSummary = GEAR_ENGINE.VerdictSummary,
        BenchmarkImpactText = GEAR_ENGINE.BenchmarkImpactText,
        ClientLocale = ClientLocale,
        PromptLocale = PromptLocale,
        LForLocale = LForLocale,
        L = L,
        LocalizedExportFormatTitle = LocalizedExportFormatTitle,
        ClassToken = ClassToken,
        GetPlayerClassInfo = GetPlayerClassInfo,
        TalentApiName = TalentApiName,
        BuildTalentSnapshot = BuildTalentSnapshot,
        LocalizedTalentTreeName = Addon.LocalizedTalentTreeName,
        TalentTabInfo = Addon.TalentTabInfo,
        TalentTreePoints = TalentTreePoints,
        TalentTreePointsText = TalentTreePointsText,
        TalentSelectedPointsText = TalentSelectedPointsText,
        TalentSnapshotHasSpentPoints = TalentSnapshotHasSpentPoints,
        TalentSummaryText = TalentSummaryText,
        ClassRoleContext = ClassRoleContext,
        LocalizedRoleContext = LocalizedRoleContext,
        LocalizedOutputRequests = LocalizedOutputRequests,
        BuildAIPrompt = BuildAIPrompt,
        SafeApiCall = SafeApiCall,
        SafeNumber = SafeNumber,
        SumKnown = SumKnown,
        RaceToken = RaceToken,
        GetPlayerRaceInfo = GetPlayerRaceInfo,
        GetGroupContext = GetGroupContext,
        BuildCharacterStatsSnapshot = BuildCharacterStatsSnapshot,
        FindEntryByKey = FindEntryByKey,
        AttributeValue = AttributeValue,
        RatingBonus = RatingBonus,
        RatingValue = GEAR_ENGINE.RatingValue,
        BestSpellValue = BestSpellValue,
        KnownAvoidanceBlock = KnownAvoidanceBlock,
        TalentPointsForTabs = TalentPointsForTabs,
        TalentPrimaryMatches = TalentPrimaryMatches,
        RoleConfidence = RoleConfidence,
        TalentTabMatches = TalentTabMatches,
        NormalizeTalentName = NormalizeTalentName,
        TalentRuleMatches = TalentRuleMatches,
        TalentRuleFor = TalentRuleFor,
        BuildTalentRoleMap = BuildTalentRoleMap,
        TalentEffectRank = GEAR_ENGINE.TalentEffectRank,
        BuildCritImmunity = GEAR_ENGINE.BuildCritImmunity,
        BuildRoleObservedStats = BuildRoleObservedStats,
        BenchmarkObservedValue = BenchmarkObservedValue,
        BenchmarkStatus = BenchmarkStatus,
        BuildRoleBenchmarks = BuildRoleBenchmarks,
        StrategyClassRoles = StrategyClassRoles,
        BuildStrategyBook = BuildStrategyBook,
        EquipmentSlotKey = GEAR_ENGINE.EquipmentSlotKey,
        EquipmentSlotLabel = GEAR_ENGINE.EquipmentSlotLabel,
        EquippedItemForSlot = GEAR_ENGINE.EquippedItemForSlot,
        IsTwoHandedItem = GEAR_ENGINE.IsTwoHandedItem,
        LoadoutCompatible = GEAR_ENGINE.LoadoutCompatible,
        MaximumWeight = GEAR_ENGINE.MaximumWeight,
        StatWeightForToken = GEAR_ENGINE.StatWeightForToken,
        FindStrategyMode = GEAR_ENGINE.FindStrategyMode,
        AvailableStrategyModes = GEAR_ENGINE.AvailableStrategyModes,
        BuildRoleStatWeights = GEAR_ENGINE.BuildRoleStatWeights,
        StatAppliesToRoleSlot = GEAR_ENGINE.StatAppliesToRoleSlot,
        ItemRoleScore = GEAR_ENGINE.ItemRoleScore,
        ItemRoleFit = GEAR_ENGINE.ItemRoleFit,
        ItemRelevantStatMap = GEAR_ENGINE.ItemRelevantStatMap,
        BuildStatDeltas = GEAR_ENGINE.BuildStatDeltas,
        RecommendationEvidence = GEAR_ENGINE.RecommendationEvidence,
        BenchmarkDeltaValue = GEAR_ENGINE.BenchmarkDeltaValue,
        BuildBenchmarkImpacts = GEAR_ENGINE.BuildBenchmarkImpacts,
        RecommendationVerdict = GEAR_ENGINE.RecommendationVerdict,
        RecommendationWorsensUnmetBenchmark = GEAR_ENGINE.RecommendationWorsensUnmetBenchmark,
        NoUpgradeText = GEAR_ENGINE.NoUpgradeText,
        VerdictCounts = GEAR_ENGINE.VerdictCounts,
        CandidateCompatibleWithClass = GEAR_ENGINE.CandidateCompatibleWithClass,
        PriorityStats = GEAR_ENGINE.PriorityStats,
        LocalizedDataLabel = GEAR_ENGINE.LocalizedDataLabel,
        BuildPhase2CapStatuses = GEAR_ENGINE.BuildPhase2CapStatuses,
        RoleNeedsCapRecovery = GEAR_ENGINE.RoleNeedsCapRecovery,
        FindPhase2Preset = GEAR_ENGINE.FindPhase2Preset,
        Phase2ItemInfo = GEAR_ENGINE.Phase2ItemInfo,
        BuildPhase2PresetProgress = GEAR_ENGINE.BuildPhase2PresetProgress,
        BuildPhase2Strategy = GEAR_ENGINE.BuildPhase2Strategy,
        FindStrategyRole = GEAR_ENGINE.FindStrategyRole,
        AvailableStrategyRoles = GEAR_ENGINE.AvailableStrategyRoles,
        CompareItems = GEAR_ENGINE.CompareItems,
        BuildGearRecommendations = GEAR_ENGINE.BuildGearRecommendations,
        TalentEffectLabel = GEAR_ENGINE.TalentEffectLabel,
        TalentMapSummary = GEAR_ENGINE.TalentMapSummary,
        GearRoleLabel = GEAR_ENGINE.GearRoleLabel,
        Phase2ModeLabel = GEAR_ENGINE.Phase2ModeLabel,
        Phase2EvidenceLabel = GEAR_ENGINE.Phase2EvidenceLabel,
        Phase2CapText = GEAR_ENGINE.Phase2CapText,
        Phase2PresetText = GEAR_ENGINE.Phase2PresetText,
        Phase2Goal = GEAR_ENGINE.Phase2Goal,
        GearPriorityText = GEAR_ENGINE.GearPriorityText,
        GearBenchmarkText = GEAR_ENGINE.GearBenchmarkText,
        GearMatchedStatsText = GEAR_ENGINE.GearMatchedStatsText,
        RoleHasModel = GEAR_ENGINE.RoleHasModel,
        RoleUsesHitModel = GEAR_ENGINE.RoleUsesHitModel,
        CoreStatsText = GEAR_ENGINE.CoreStatsText,
        RoleHitCritText = GEAR_ENGINE.RoleHitCritText,
        BuildStatsAnalysisText = BuildStatsAnalysisText,
        BuildOverviewText = Addon.BuildOverviewText,
        CompactCountList = Addon.CompactCountList,
        MarkdownEscape = Addon.MarkdownEscape,
        MarkdownPlainItemName = Addon.MarkdownPlainItemName,
        ShortStats = Addon.ShortStats,
        AnalysisValue = AnalysisValue,
        NormalizedStackCount = NormalizedStackCount,
        RoundedStatNumber = RoundedStatNumber,
        BuildChartStats = BuildChartStats,
        ChartCountLine = ChartCountLine,
        ChartStatLine = ChartStatLine,
        IsEquippableSlot = IsEquippableSlot,
        CategoryFromInfo = CategoryFromInfo,
        CopyItems = CopyItems,
    }

    _G.TBCGearExporter = Addon
end

SafeRegister("ADDON_LOADED")
