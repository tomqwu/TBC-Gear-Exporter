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
    "For each plausible role, rank strong keepers, weak slots, and upgrade priorities.",
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
    "针对每个可能职责，列出值得保留的强力装备、薄弱部位和升级优先级。",
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
    "針對每個可能職責，列出值得保留的強力裝備、薄弱部位和升級優先順序。",
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
    { key = "resilience", label = "Resilience", global = "CR_RESILIENCE_PLAYER_DAMAGE_TAKEN" },
}

local TBC_BENCHMARKS = {
    defense_crit_immunity = { label = "Defense crit-immunity benchmark", value = 490, unit = "defense skill", note = "Common level-70 raid-boss tank reference." },
    melee_special_hit = { label = "Melee special hit benchmark", value = 9, unit = "% hit", note = "Common boss-level yellow-hit reference." },
    ranged_hit = { label = "Ranged hit benchmark", value = 9, unit = "% hit", note = "Common boss-level ranged-hit reference." },
    spell_hit = { label = "Spell hit benchmark", value = 16, unit = "% hit", note = "Common TBC boss-level spell-hit reference before class/talent debuffs." },
    expertise_dodge = { label = "Expertise dodge benchmark", value = 6.5, unit = "% dodge reduction", note = "Common boss dodge reduction reference where expertise exists." },
    avoidance_table = { label = "Shield table coverage benchmark", value = 102.4, unit = "% known avoidance/block table", note = "Useful for warrior/paladin mitigation models; exported value omits unreported miss when the API cannot expose it." },
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
        },
        statuses = {
            meets_or_exceeds = "Meets / exceeds",
            near = "Near target",
            below = "Below target",
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
        },
        benchmarks = {
            defense_crit_immunity = "防御免暴基准",
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
            unknown = "未知",
        },
        units = {
            ["defense skill"] = "防御技能",
            ["% hit"] = "% 命中",
            ["% dodge reduction"] = "% 躲闪降低",
            ["% known avoidance/block table"] = "% 已知免伤/格挡表",
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
            ITEM_MOD_HIT_RATING_SHORT = "命中等级",
            ITEM_MOD_HIT_MELEE_RATING_SHORT = "近战命中等级",
            ITEM_MOD_HIT_RANGED_RATING_SHORT = "远程命中等级",
            ITEM_MOD_HIT_SPELL_RATING_SHORT = "法术命中等级",
            ITEM_MOD_CRIT_RATING_SHORT = "暴击等级",
            ITEM_MOD_CRIT_MELEE_RATING_SHORT = "近战暴击等级",
            ITEM_MOD_CRIT_RANGED_RATING_SHORT = "远程暴击等级",
            ITEM_MOD_CRIT_SPELL_RATING_SHORT = "法术暴击等级",
            ITEM_MOD_HASTE_SPELL_RATING_SHORT = "法术急速等级",
            ITEM_MOD_EXPERTISE_RATING_SHORT = "熟练等级",
            ITEM_MOD_SPELL_POWER_SHORT = "法术强度",
            ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "法术伤害",
            ITEM_MOD_SPELL_HEALING_DONE_SHORT = "治疗",
            ITEM_MOD_MANA_REGENERATION_SHORT = "法力回复",
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
        },
        benchmarks = {
            defense_crit_immunity = "防禦免暴基準",
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
            unknown = "未知",
        },
        units = {
            ["defense skill"] = "防禦技能",
            ["% hit"] = "% 命中",
            ["% dodge reduction"] = "% 閃躲降低",
            ["% known avoidance/block table"] = "% 已知減傷/格擋表",
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
            ITEM_MOD_HIT_RATING_SHORT = "命中等級",
            ITEM_MOD_HIT_MELEE_RATING_SHORT = "近戰命中等級",
            ITEM_MOD_HIT_RANGED_RATING_SHORT = "遠程命中等級",
            ITEM_MOD_HIT_SPELL_RATING_SHORT = "法術命中等級",
            ITEM_MOD_CRIT_RATING_SHORT = "致命等級",
            ITEM_MOD_CRIT_MELEE_RATING_SHORT = "近戰致命等級",
            ITEM_MOD_CRIT_RANGED_RATING_SHORT = "遠程致命等級",
            ITEM_MOD_CRIT_SPELL_RATING_SHORT = "法術致命等級",
            ITEM_MOD_HASTE_SPELL_RATING_SHORT = "法術加速等級",
            ITEM_MOD_EXPERTISE_RATING_SHORT = "熟練等級",
            ITEM_MOD_SPELL_POWER_SHORT = "法術強度",
            ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "法術傷害",
            ITEM_MOD_SPELL_HEALING_DONE_SHORT = "治療",
            ITEM_MOD_MANA_REGENERATION_SHORT = "法力回復",
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
            { key = "bear_tank", label = "Bear Feral Tank", talentTabs = { 2 }, models = { "tank_mitigation", "tank_threat" }, priorities = { "armor", "stamina", "defense/resilience", "dodge", "agility", "hit/expertise where available", "feral attack power", "threat trinkets" }, benchmarkKeys = { "defense_crit_immunity", "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_ARMOR", "ITEM_MOD_BONUS_ARMOR_SHORT", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_FERAL_ATTACK_POWER_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
            { key = "cat_dps", label = "Cat Feral DPS", talentTabs = { 2 }, models = { "melee_dps", "threat_awareness" }, priorities = { "agility", "strength", "attack power", "crit", "hit/expertise", "feral attack power", "set synergy" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_FERAL_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
            { key = "restoration_healer", label = "Restoration Healing", talentTabs = { 3 }, models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "spirit", "intellect", "mp5", "haste", "mana longevity" }, benchmarkKeys = {}, statTokens = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_SPIRIT_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT" } },
            { key = "balance_caster", label = "Balance Caster DPS", talentTabs = { 1 }, models = { "caster_dps", "mana_longevity" }, priorities = { "spell damage", "spell hit", "spell crit", "haste", "intellect", "mana sustain" }, benchmarkKeys = { "spell_hit" }, statTokens = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT", "ITEM_MOD_INTELLECT_SHORT" } },
        },
    },
    WARRIOR = {
        roles = {
            { key = "protection_tank", label = "Protection Tank", talentTabs = { 3 }, models = { "tank_mitigation", "tank_threat" }, priorities = { "stamina", "armor", "defense", "avoidance", "shield block/value", "hit/expertise", "threat stats" }, benchmarkKeys = { "defense_crit_immunity", "avoidance_table", "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_ARMOR", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT", "ITEM_MOD_BLOCK_RATING_SHORT", "ITEM_MOD_BLOCK_VALUE_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
            { key = "arms_fury_dps", label = "Arms/Fury DPS", talentTabs = { 1, 2 }, models = { "melee_dps", "weapon_selection" }, priorities = { "weapon damage/speed", "strength", "attack power", "crit", "hit/expertise", "set bonuses" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_EXPERTISE_RATING_SHORT" } },
        },
    },
    PALADIN = {
        roles = {
            { key = "protection_tank", label = "Protection Tank", talentTabs = { 2 }, models = { "tank_mitigation", "spell_threat" }, priorities = { "stamina", "defense", "avoidance", "block value", "spell damage/threat", "mana sustain" }, benchmarkKeys = { "defense_crit_immunity", "avoidance_table", "spell_hit" }, statTokens = { "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_BLOCK_VALUE_SHORT", "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT" } },
            { key = "holy_healer", label = "Holy Healing", talentTabs = { 1 }, models = { "healing_throughput", "mana_longevity" }, priorities = { "bonus healing", "intellect", "mp5", "spell crit", "mana longevity" }, benchmarkKeys = {}, statTokens = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT" } },
            { key = "retribution_dps", label = "Retribution DPS", talentTabs = { 3 }, models = { "melee_dps", "utility_dps" }, priorities = { "weapon quality", "strength", "attack power", "crit", "hit/expertise", "set synergy" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
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
            { key = "enhancement_dps", label = "Enhancement DPS", talentTabs = { 2 }, models = { "melee_dps", "weapon_selection" }, priorities = { "weapon options", "attack power", "agility", "strength", "crit", "hit/expertise" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
        },
    },
    HUNTER = {
        roles = {
            { key = "ranged_dps", label = "Ranged DPS", talentTabs = { 1, 2, 3 }, models = { "ranged_dps", "pet_synergy" }, priorities = { "ranged weapon", "agility", "attack power", "crit", "hit", "ammo/quiver support", "set bonuses" }, benchmarkKeys = { "ranged_hit" }, statTokens = { "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RANGED_RATING_SHORT", "ITEM_MOD_HIT_RANGED_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT" } },
        },
    },
    ROGUE = {
        roles = {
            { key = "melee_dps", label = "Melee DPS", talentTabs = { 1, 2, 3 }, models = { "melee_dps", "weapon_selection" }, priorities = { "weapon speed/type", "agility", "attack power", "crit", "hit/expertise", "set bonuses" }, benchmarkKeys = { "melee_special_hit", "expertise_dodge" }, statTokens = { "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_EXPERTISE_RATING_SHORT" } },
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
        items_tab = "Items",
        stats_analysis_tab = "Stats Analysis",
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
        status_overview = "Overview updated: %d items, %d role models. Use Text Export to copy AI-ready data.",
        overview_title = "Overview",
        overview_inventory = "Inventory: %d item lines, %d stacks, %d gear, %d equippable",
        overview_talents = "Talents: %s; selected: %s",
        overview_stats = "Core stats: defense %s, armor %s, melee hit %s, spell hit %s, melee crit %s, best spell crit %s",
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
        analysis_role_tank = "Tank lens: defense %s, armor %s, known avoidance/block %s",
        analysis_benchmark = "Benchmark: %s = %s (observed %s; target %s %s)",
        analysis_highlights = "Gear highlights: %s",
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
        items_tab = "物品",
        stats_analysis_tab = "属性分析",
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
        status_overview = "总览已更新：%d 件物品，%d 个职责模型。切到文本导出即可复制 AI 数据。",
        overview_title = "总览",
        overview_inventory = "库存：%d 条物品，%d 堆叠，%d 件装备，%d 件可装备",
        overview_talents = "天赋：%s；已点：%s",
        overview_stats = "核心属性：防御 %s，护甲 %s，近战命中 %s，法术命中 %s，近战暴击 %s，最佳法术暴击 %s",
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
        analysis_role_tank = "坦克视角：防御 %s，护甲 %s，已知免伤/格挡 %s",
        analysis_benchmark = "基准：%s = %s（实测 %s；目标 %s %s）",
        analysis_highlights = "装备属性亮点：%s",
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
        items_tab = "物品",
        stats_analysis_tab = "屬性分析",
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
        status_overview = "總覽已更新：%d 件物品，%d 個職責模型。切到文字匯出即可複製 AI 資料。",
        overview_title = "總覽",
        overview_inventory = "庫存：%d 條物品，%d 堆疊，%d 件裝備，%d 件可裝備",
        overview_talents = "天賦：%s；已點：%s",
        overview_stats = "核心屬性：防禦 %s，護甲 %s，近戰命中 %s，法術命中 %s，近戰致命 %s，最佳法術致命 %s",
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
        analysis_role_tank = "坦克視角：防禦 %s，護甲 %s，已知減傷/格擋 %s",
        analysis_benchmark = "基準：%s = %s（實測 %s；目標 %s %s）",
        analysis_highlights = "裝備屬性亮點：%s",
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
    if STAT_LABELS[statToken] then
        return STAT_LABELS[statToken]
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
local function LocationLabel(source, bagID, slotID)
    if source == "bags" then
        if bagID == 0 then
            return "Backpack slot " .. slotID
        end

        return "Bag " .. bagID .. " slot " .. slotID
    end

    if bagID == BANK_CONTAINER_ID then
        return "Bank slot " .. slotID
    end

    return "Bank bag " .. (bagID - PLAYER_BAG_SLOTS) .. " slot " .. slotID
end

local function SourceLabel(source)
    if source == "bags" then
        return "Bags"
    end

    if source == "bank" then
        return "Bank"
    end

    return source or "Unknown"
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
        local ratingID = _G and _G[spec.global]
        local rating, bonus

        if type(ratingID) == "number" then
            rating = SafeNumber(SafeApiCall(GetCombatRating, ratingID))
            bonus = SafeNumber(SafeApiCall(GetCombatRatingBonus, ratingID))
        end

        ratings[#ratings + 1] = {
            key = spec.key,
            label = spec.label,
            global = spec.global,
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
        return (promptLocale == "enUS") and "unavailable" or "不可用"
    end

    local treePoints = TalentTreePoints(talents)
    if #treePoints == 0 then
        return (promptLocale == "enUS") and "none" or "无"
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
        return (promptLocale == "enUS") and "unavailable" or "不可用"
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
        return (promptLocale == "enUS") and "none" or "无"
    end

    if omitted > 0 then
        if promptLocale == "enUS" then
            parts[#parts + 1] = "+" .. tostring(omitted) .. " more"
        else
            parts[#parts + 1] = "另 " .. tostring(omitted) .. " 个"
        end
    end

    return table.concat(parts, ", ")
end

local function TalentSummaryText(talents, locale)
    talents = talents or {}

    if not talents.available then
        return (PromptLocale(locale) == "enUS") and "unavailable" or "不可用"
    end

    local primary = talents.primaryTab or ((PromptLocale(locale) == "enUS") and "none" or "无")
    local unspent = talents.unspentPoints
    local parts = {
        tostring(talents.summary or ""),
        "primary=" .. tostring(primary),
        "points=" .. tostring(talents.totalPoints or talents.pointsSpent or 0),
        "trees=" .. TalentTreePointsText(talents, locale),
    }

    if unspent ~= nil then
        parts[#parts + 1] = "unspent=" .. tostring(unspent)
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
    local classDisplay = profile.classLocalized or profile.classEnglish or "Unknown Class"
    local locale = profile.locale or ClientLocale()
    local promptLocale = PromptLocale(locale)
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
            "请使用 character_stats、chart_stats、strategy_book、物品属性、物品等级、品质、装备栏位、分类、来源位置和 wowhead_url 字段。不要编造缺失属性，也不要假设隐藏附魔或宝石。",
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
            "請使用 character_stats、chart_stats、strategy_book、物品屬性、物品等級、品質、裝備欄位、分類、來源位置和 wowhead_url 欄位。不要編造缺失屬性，也不要假設隱藏附魔或寶石。",
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
            "Use character_stats, chart_stats, strategy_book, item stats, item level, quality, equip slot, category, source location, and wowhead_url fields. Do not invent missing stats or assume hidden enchants/gems.",
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
            AddChartCount(equipSlotMap, item.equipSlot, { slot = item.equipSlot }, stackCount)
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
                local token = tostring(stat.token or stat.label or "Unknown Stat")
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

local function ChartCountLine(label, entry)
    return tostring(label) .. ": " .. tostring(entry.itemCount or 0) .. " item lines; stack " .. tostring(entry.stackCount or 0)
end

local function ChartStatLine(entry)
    return FormatStats({ entry }) .. " (" .. tostring(entry.itemCount or 0) .. " item lines; stack " .. tostring(entry.stackCount or 0) .. ")"
end

local function AppendMarkdownChartCountSection(lines, title, entries, labeler)
    lines[#lines + 1] = "### " .. title
    lines[#lines + 1] = ""

    if #(entries or {}) == 0 then
        lines[#lines + 1] = "_None._"
    else
        for index = 1, #entries do
            lines[#lines + 1] = "- " .. ChartCountLine(labeler(entries[index]), entries[index])
        end
    end

    lines[#lines + 1] = ""
end

local function AppendChartStatsMarkdown(lines, chartStats)
    chartStats = chartStats or BuildChartStats({})
    lines[#lines + 1] = "## Chart Stats"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "- Item lines: " .. tostring(chartStats.itemCount or 0)
    lines[#lines + 1] = "- Total stack count: " .. tostring(chartStats.stackCount or 0)
    lines[#lines + 1] = "- Gear item lines: " .. tostring(chartStats.gearItemCount or 0) .. "; gear stack count: " .. tostring(chartStats.gearStackCount or 0)
    lines[#lines + 1] = "- Equippable item lines: " .. tostring(chartStats.equippableItemCount or 0)

    if chartStats.itemLevel and chartStats.itemLevel.count and chartStats.itemLevel.count > 0 then
        lines[#lines + 1] = "- Item level: min " .. tostring(chartStats.itemLevel.min) .. "; max " .. tostring(chartStats.itemLevel.max) .. "; average " .. tostring(chartStats.itemLevel.average) .. " across " .. tostring(chartStats.itemLevel.count) .. " item lines"
    else
        lines[#lines + 1] = "- Item level: none"
    end

    lines[#lines + 1] = ""
    AppendMarkdownChartCountSection(lines, "Source Counts", chartStats.sourceCounts, function(entry)
        return entry.sourceLabel or entry.source
    end)
    AppendMarkdownChartCountSection(lines, "Category Counts", chartStats.categoryCounts, function(entry)
        return entry.name
    end)
    AppendMarkdownChartCountSection(lines, "Quality Counts", chartStats.qualityCounts, function(entry)
        return tostring(entry.quality or "Unknown") .. (entry.color and " (" .. entry.color .. ")" or "")
    end)
    AppendMarkdownChartCountSection(lines, "Equip Slot Counts", chartStats.equipSlotCounts, function(entry)
        return entry.slot
    end)
    lines[#lines + 1] = "### Stat Totals"
    lines[#lines + 1] = ""

    if #(chartStats.statTotals or {}) == 0 then
        lines[#lines + 1] = "_No item stats recorded._"
    else
        for index = 1, #chartStats.statTotals do
            lines[#lines + 1] = "- " .. ChartStatLine(chartStats.statTotals[index])
        end
    end

    lines[#lines + 1] = ""
end

local function AppendTextChartCountSection(lines, title, entries, labeler)
    lines[#lines + 1] = title

    if #(entries or {}) == 0 then
        lines[#lines + 1] = "None"
    else
        for index = 1, #entries do
            lines[#lines + 1] = "- " .. ChartCountLine(labeler(entries[index]), entries[index])
        end
    end

    lines[#lines + 1] = ""
end

local function AppendChartStatsText(lines, chartStats)
    chartStats = chartStats or BuildChartStats({})
    lines[#lines + 1] = "CHART STATS"
    lines[#lines + 1] = "Item lines: " .. tostring(chartStats.itemCount or 0)
    lines[#lines + 1] = "Total stack count: " .. tostring(chartStats.stackCount or 0)
    lines[#lines + 1] = "Gear item lines: " .. tostring(chartStats.gearItemCount or 0) .. "; gear stack count: " .. tostring(chartStats.gearStackCount or 0)
    lines[#lines + 1] = "Equippable item lines: " .. tostring(chartStats.equippableItemCount or 0)

    if chartStats.itemLevel and chartStats.itemLevel.count and chartStats.itemLevel.count > 0 then
        lines[#lines + 1] = "Item level: min " .. tostring(chartStats.itemLevel.min) .. "; max " .. tostring(chartStats.itemLevel.max) .. "; average " .. tostring(chartStats.itemLevel.average) .. " across " .. tostring(chartStats.itemLevel.count) .. " item lines"
    else
        lines[#lines + 1] = "Item level: none"
    end

    lines[#lines + 1] = ""
    AppendTextChartCountSection(lines, "Source Counts", chartStats.sourceCounts, function(entry)
        return entry.sourceLabel or entry.source
    end)
    AppendTextChartCountSection(lines, "Category Counts", chartStats.categoryCounts, function(entry)
        return entry.name
    end)
    AppendTextChartCountSection(lines, "Quality Counts", chartStats.qualityCounts, function(entry)
        return tostring(entry.quality or "Unknown") .. (entry.color and " (" .. entry.color .. ")" or "")
    end)
    AppendTextChartCountSection(lines, "Equip Slot Counts", chartStats.equipSlotCounts, function(entry)
        return entry.slot
    end)
    lines[#lines + 1] = "Stat Totals"

    if #(chartStats.statTotals or {}) == 0 then
        lines[#lines + 1] = "No item stats recorded."
    else
        for index = 1, #chartStats.statTotals do
            lines[#lines + 1] = "- " .. ChartStatLine(chartStats.statTotals[index])
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

local function RoleGearHighlights(role, chartStats)
    local highlights = {}

    for index = 1, #(role.statTokens or {}) do
        local stat = ChartStatTotal(chartStats, role.statTokens[index])
        if stat then
            highlights[#highlights + 1] = stat
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

local function BuildRoleObservedStats(role, characterStats, chartStats)
    local chances = characterStats and characterStats.chances or {}
    local spell = characterStats and characterStats.spell or {}
    local attackPower = characterStats and characterStats.attackPower or {}
    local defense = characterStats and characterStats.defense or {}
    local armor = characterStats and characterStats.armor or {}

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
        },
        power = {
            attackPower = attackPower.melee and attackPower.melee.effective or nil,
            rangedAttackPower = attackPower.ranged and attackPower.ranged.effective or nil,
            spellPowerBest = BestSpellValue(spell.spellDamage, "bonus"),
            healing = spell.healing,
            manaRegenCasting = spell.manaRegenCasting,
        },
        gearStatHighlights = RoleGearHighlights(role, chartStats),
    }
end

local function BenchmarkObservedValue(key, observed)
    observed = observed or {}

    if key == "defense_crit_immunity" then
        return observed.tank and observed.tank.defense or nil
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
        if value >= benchmark.value then
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
    local classBook = CLASS_STRATEGY_BOOK[ClassToken(classToken)]
    return (classBook and classBook.roles) or DEFAULT_STRATEGY_ROLES
end

local function BuildStrategyBook(profile, chartStats)
    local classToken = ClassToken(profile and profile.classEnglish or "UNKNOWN")
    local characterStats = profile and profile.characterStats or BuildCharacterStatsSnapshot()
    local race = characterStats and characterStats.race or GetPlayerRaceInfo()
    local group = characterStats and characterStats.group or GetGroupContext()
    local roles = {}
    local sourceRoles = StrategyClassRoles(classToken)

    for index = 1, #sourceRoles do
        local role = sourceRoles[index]
        local observed = BuildRoleObservedStats(role, characterStats, chartStats)
        local talentPoints = TalentPointsForTabs(profile and profile.talents, role.talentTabs)
        local primaryMatch = TalentPrimaryMatches(profile and profile.talents, role.talentTabs)
        roles[#roles + 1] = {
            key = role.key,
            label = role.label,
            confidence = RoleConfidence(role, profile and profile.talents),
            talentPoints = talentPoints,
            primaryTalentMatch = primaryMatch,
            models = role.models or {},
            priorities = role.priorities or {},
            observed = observed,
            benchmarks = BuildRoleBenchmarks(role, observed),
            notes = {
                "Mapped from class, race, current talent distribution, live character stats, and exported gear stat totals.",
                "Use confidence as a role-lens hint, not a final spec declaration.",
            },
        }
    end

    table.sort(roles, function(left, right)
        if left.confidence ~= right.confidence then
            return left.confidence > right.confidence
        end

        return tostring(left.label) < tostring(right.label)
    end)

    return {
        version = 1,
        generatedAt = Now(),
        classToken = classToken,
        raceToken = race and race.english or "UNKNOWN",
        groupType = group and group.type or "solo",
        raceNotes = race and race.notes or {},
        groupNotes = group and group.notes or {},
        benchmarkReferences = TBC_BENCHMARKS,
        roles = roles,
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
    AppendIndented(lines, indent + 2, "\"roles\": [")

    for roleIndex = 1, #(strategyBook.roles or {}) do
        local role = strategyBook.roles[roleIndex]
        AppendIndented(lines, indent + 4, "{")
        AppendIndented(lines, indent + 6, JsonField("key", role.key, true))
        AppendIndented(lines, indent + 6, JsonField("label", role.label, true))
        AppendIndented(lines, indent + 6, JsonField("confidence", role.confidence, true))
        AppendIndented(lines, indent + 6, JsonField("talent_points", role.talentPoints, true))
        AppendIndented(lines, indent + 6, JsonField("primary_talent_match", role.primaryTalentMatch and true or false, true))
        AppendJsonStringArray(lines, indent + 6, "models", role.models, true)
        AppendJsonStringArray(lines, indent + 6, "priorities", role.priorities, true)
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

local function PercentText(value)
    if type(value) ~= "number" then
        return "unknown"
    end

    return CompactNumber(value, 2) .. "%"
end

local function AppendCharacterStatsMarkdown(lines, characterStats)
    characterStats = characterStats or BuildCharacterStatsSnapshot()
    lines[#lines + 1] = "## Character Stats"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "- Race: " .. tostring(characterStats.race and characterStats.race.localized or "Unknown") .. " (" .. tostring(characterStats.race and characterStats.race.english or "UNKNOWN") .. ")"
    lines[#lines + 1] = "- Group: " .. tostring(characterStats.group and characterStats.group.type or "solo") .. "; size " .. tostring(characterStats.group and characterStats.group.size or 1)
    lines[#lines + 1] = "- Defense: " .. tostring(characterStats.defense and characterStats.defense.effective or "unknown") .. "; Armor: " .. tostring(characterStats.armor and characterStats.armor.effective or "unknown")
    lines[#lines + 1] = "- Hit: melee " .. PercentText(RatingBonus(characterStats, "melee_hit")) .. "; ranged " .. PercentText(RatingBonus(characterStats, "ranged_hit")) .. "; spell " .. PercentText(RatingBonus(characterStats, "spell_hit"))
    lines[#lines + 1] = "- Crit: melee " .. PercentText(characterStats.chances and characterStats.chances.meleeCrit) .. "; ranged " .. PercentText(characterStats.chances and characterStats.chances.rangedCrit) .. "; spell best " .. PercentText(BestSpellValue(characterStats.chances and characterStats.chances.spellCrit, "crit"))
    lines[#lines + 1] = ""
end

local function AppendStrategyBookMarkdown(lines, strategyBook)
    strategyBook = strategyBook or BuildStrategyBook({}, BuildChartStats({}))
    lines[#lines + 1] = "## Strategy Book"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "- Class: " .. tostring(strategyBook.classToken or "UNKNOWN")
    lines[#lines + 1] = "- Race: " .. tostring(strategyBook.raceToken or "UNKNOWN")
    lines[#lines + 1] = "- Group context: " .. tostring(strategyBook.groupType or "solo")

    for index = 1, #(strategyBook.raceNotes or {}) do
        lines[#lines + 1] = "- Race note: " .. strategyBook.raceNotes[index]
    end

    for index = 1, #(strategyBook.groupNotes or {}) do
        lines[#lines + 1] = "- Group note: " .. strategyBook.groupNotes[index]
    end

    lines[#lines + 1] = ""

    for roleIndex = 1, #(strategyBook.roles or {}) do
        local role = strategyBook.roles[roleIndex]
        lines[#lines + 1] = "### " .. tostring(role.label or role.key)
        lines[#lines + 1] = ""
        lines[#lines + 1] = "- Confidence: " .. tostring(role.confidence or 0) .. "; talent points: " .. tostring(role.talentPoints or 0) .. "; primary match: " .. tostring(role.primaryTalentMatch and "yes" or "no")
        lines[#lines + 1] = "- Models: " .. table.concat(role.models or {}, ", ")
        lines[#lines + 1] = "- Priorities: " .. table.concat(role.priorities or {}, ", ")
        lines[#lines + 1] = "- Observed hit: melee " .. PercentText(role.observed and role.observed.hit and role.observed.hit.melee) .. "; ranged " .. PercentText(role.observed and role.observed.hit and role.observed.hit.ranged) .. "; spell " .. PercentText(role.observed and role.observed.hit and role.observed.hit.spell)
        lines[#lines + 1] = "- Observed crit: melee " .. PercentText(role.observed and role.observed.crit and role.observed.crit.melee) .. "; ranged " .. PercentText(role.observed and role.observed.crit and role.observed.crit.ranged) .. "; spell best " .. PercentText(role.observed and role.observed.crit and role.observed.crit.spellBest)
        lines[#lines + 1] = "- Tank model: defense " .. tostring(role.observed and role.observed.tank and role.observed.tank.defense or "unknown") .. "; armor " .. tostring(role.observed and role.observed.tank and role.observed.tank.armor or "unknown") .. "; known avoidance/block " .. PercentText(role.observed and role.observed.tank and role.observed.tank.knownAvoidanceBlock)

        if #(role.benchmarks or {}) > 0 then
            lines[#lines + 1] = "- Benchmarks:"
            for benchmarkIndex = 1, #role.benchmarks do
                local benchmark = role.benchmarks[benchmarkIndex]
                lines[#lines + 1] = "  - " .. tostring(benchmark.label or benchmark.key) .. ": " .. tostring(benchmark.status) .. " (observed " .. tostring(benchmark.observed or "unknown") .. "; target " .. tostring(benchmark.target or "unknown") .. " " .. tostring(benchmark.unit or "") .. ")"
            end
        end

        if role.observed and role.observed.gearStatHighlights and #role.observed.gearStatHighlights > 0 then
            lines[#lines + 1] = "- Gear stat highlights: " .. FormatStats(role.observed.gearStatHighlights)
        end

        lines[#lines + 1] = ""
    end
end

local function AppendCharacterStatsText(lines, characterStats)
    characterStats = characterStats or BuildCharacterStatsSnapshot()
    lines[#lines + 1] = "CHARACTER STATS"
    lines[#lines + 1] = "Race: " .. tostring(characterStats.race and characterStats.race.localized or "Unknown") .. " (" .. tostring(characterStats.race and characterStats.race.english or "UNKNOWN") .. ")"
    lines[#lines + 1] = "Group: " .. tostring(characterStats.group and characterStats.group.type or "solo") .. "; size " .. tostring(characterStats.group and characterStats.group.size or 1)
    lines[#lines + 1] = "Defense: " .. tostring(characterStats.defense and characterStats.defense.effective or "unknown") .. "; Armor: " .. tostring(characterStats.armor and characterStats.armor.effective or "unknown")
    lines[#lines + 1] = "Hit: melee " .. PercentText(RatingBonus(characterStats, "melee_hit")) .. "; ranged " .. PercentText(RatingBonus(characterStats, "ranged_hit")) .. "; spell " .. PercentText(RatingBonus(characterStats, "spell_hit"))
    lines[#lines + 1] = "Crit: melee " .. PercentText(characterStats.chances and characterStats.chances.meleeCrit) .. "; ranged " .. PercentText(characterStats.chances and characterStats.chances.rangedCrit) .. "; spell best " .. PercentText(BestSpellValue(characterStats.chances and characterStats.chances.spellCrit, "crit"))
    lines[#lines + 1] = ""
end

local function AppendStrategyBookText(lines, strategyBook)
    strategyBook = strategyBook or BuildStrategyBook({}, BuildChartStats({}))
    lines[#lines + 1] = "STRATEGY BOOK"
    lines[#lines + 1] = "Class: " .. tostring(strategyBook.classToken or "UNKNOWN")
    lines[#lines + 1] = "Race: " .. tostring(strategyBook.raceToken or "UNKNOWN")
    lines[#lines + 1] = "Group context: " .. tostring(strategyBook.groupType or "solo")

    for index = 1, #(strategyBook.raceNotes or {}) do
        lines[#lines + 1] = "Race note: " .. strategyBook.raceNotes[index]
    end

    for index = 1, #(strategyBook.groupNotes or {}) do
        lines[#lines + 1] = "Group note: " .. strategyBook.groupNotes[index]
    end

    lines[#lines + 1] = ""

    for roleIndex = 1, #(strategyBook.roles or {}) do
        local role = strategyBook.roles[roleIndex]
        lines[#lines + 1] = "[" .. tostring(role.label or role.key) .. "]"
        lines[#lines + 1] = "Confidence: " .. tostring(role.confidence or 0) .. "; talent points: " .. tostring(role.talentPoints or 0) .. "; primary match: " .. tostring(role.primaryTalentMatch and "yes" or "no")
        lines[#lines + 1] = "Models: " .. table.concat(role.models or {}, ", ")
        lines[#lines + 1] = "Priorities: " .. table.concat(role.priorities or {}, ", ")
        lines[#lines + 1] = "Observed hit: melee " .. PercentText(role.observed and role.observed.hit and role.observed.hit.melee) .. "; ranged " .. PercentText(role.observed and role.observed.hit and role.observed.hit.ranged) .. "; spell " .. PercentText(role.observed and role.observed.hit and role.observed.hit.spell)
        lines[#lines + 1] = "Observed crit: melee " .. PercentText(role.observed and role.observed.crit and role.observed.crit.melee) .. "; ranged " .. PercentText(role.observed and role.observed.crit and role.observed.crit.ranged) .. "; spell best " .. PercentText(role.observed and role.observed.crit and role.observed.crit.spellBest)
        lines[#lines + 1] = "Tank model: defense " .. tostring(role.observed and role.observed.tank and role.observed.tank.defense or "unknown") .. "; armor " .. tostring(role.observed and role.observed.tank and role.observed.tank.armor or "unknown") .. "; known avoidance/block " .. PercentText(role.observed and role.observed.tank and role.observed.tank.knownAvoidanceBlock)

        for benchmarkIndex = 1, #(role.benchmarks or {}) do
            local benchmark = role.benchmarks[benchmarkIndex]
            lines[#lines + 1] = "Benchmark: " .. tostring(benchmark.label or benchmark.key) .. " = " .. tostring(benchmark.status) .. " (observed " .. tostring(benchmark.observed or "unknown") .. "; target " .. tostring(benchmark.target or "unknown") .. " " .. tostring(benchmark.unit or "") .. ")"
        end

        if role.observed and role.observed.gearStatHighlights and #role.observed.gearStatHighlights > 0 then
            lines[#lines + 1] = "Gear stat highlights: " .. FormatStats(role.observed.gearStatHighlights)
        end

        lines[#lines + 1] = ""
    end
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
    return AnalysisLookup(locale, "roles", role and role.key, role and (role.label or role.key) or "Role")
end

local function AnalysisModelLabels(models, locale)
    local labels = {}

    for index = 1, #(models or {}) do
        labels[#labels + 1] = AnalysisLookup(locale, "models", models[index], models[index])
    end

    return table.concat(labels, ", ")
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

local function FormatAnalysisStats(stats, locale)
    if not stats or #stats == 0 then
        return "none"
    end

    local parts = {}
    for index = 1, #stats do
        local stat = stats[index]
        local value = stat and stat.value
        local label = AnalysisStatLabel(stat, locale)
        if value and value < 0 then
            parts[#parts + 1] = tostring(value) .. " " .. label
        else
            parts[#parts + 1] = "+" .. tostring(value or 0) .. " " .. label
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
        local hit = observed.hit or {}
        local crit = observed.crit or {}
        local tank = observed.tank or {}
        lines[#lines + 1] = ""
        lines[#lines + 1] = LForLocale(locale, "analysis_role", AnalysisRoleLabel(role, locale), AnalysisValue(role.confidence, nil, locale), AnalysisValue(role.talentPoints, nil, locale))
        lines[#lines + 1] = LForLocale(locale, "analysis_models", AnalysisModelLabels(role.models, locale))
        lines[#lines + 1] = LForLocale(locale, "analysis_role_hit",
            AnalysisValue(hit.melee, "%", locale),
            AnalysisValue(hit.spell, "%", locale),
            AnalysisValue(crit.melee, "%", locale),
            AnalysisValue(crit.spellBest, "%", locale))
        lines[#lines + 1] = LForLocale(locale, "analysis_role_tank",
            AnalysisValue(tank.defense, nil, locale),
            AnalysisValue(tank.armor, nil, locale),
            AnalysisValue(tank.knownAvoidanceBlock, "%", locale))

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

function Addon.ShortStats(stats, maxCount)
    if not stats or #stats == 0 then
        return "none"
    end

    local selected = {}
    maxCount = maxCount or 4

    for index = 1, math.min(#stats, maxCount) do
        selected[#selected + 1] = stats[index]
    end

    local text = FormatStats(selected)
    if #stats > maxCount then
        text = text .. ", +" .. tostring(#stats - maxCount) .. " more"
    end

    return text
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
        LForLocale(locale, "overview_stats",
            AnalysisValue(defense.effective, nil, locale),
            AnalysisValue(armor.effective, nil, locale),
            AnalysisValue(RatingBonus(characterStats, "melee_hit"), "%", locale),
            AnalysisValue(RatingBonus(characterStats, "spell_hit"), "%", locale),
            AnalysisValue(chances.meleeCrit, "%", locale),
            AnalysisValue(BestSpellValue(chances.spellCrit, "crit"), "%", locale)),
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

    lines[#lines + 1] = "## Quick Summary"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| Field | Value |"
    lines[#lines + 1] = "| --- | --- |"
    lines[#lines + 1] = "| Character | " .. Addon.MarkdownEscape(tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm")) .. " |"
    lines[#lines + 1] = "| Class | " .. Addon.MarkdownEscape(profile.classLocalized or profile.classEnglish or "Unknown Class") .. " |"
    lines[#lines + 1] = "| Scope / Filter | " .. Addon.MarkdownEscape(ScopeTitle(scope) .. " / " .. ExportFilterTitle(filter)) .. " |"
    lines[#lines + 1] = "| Items | " .. tostring(#items) .. " lines, " .. tostring(chartStats.stackCount or 0) .. " stacked; gear " .. tostring(chartStats.gearItemCount or 0) .. " |"
    lines[#lines + 1] = "| Talents | " .. Addon.MarkdownEscape(TalentTreePointsText(profile.talents, profile.locale)) .. " |"
    lines[#lines + 1] = "| Selected talents | " .. Addon.MarkdownEscape(TalentSelectedPointsText(profile.talents, profile.locale, 8)) .. " |"
    lines[#lines + 1] = "| Top role | " .. Addon.MarkdownEscape(topRole and ((topRole.label or topRole.key) .. " (" .. tostring(topRole.confidence or 0) .. " confidence)") or "none") .. " |"
    lines[#lines + 1] = "| Core stats | Defense " .. Addon.MarkdownEscape(AnalysisValue(characterStats.defense and characterStats.defense.effective)) .. ", armor " .. Addon.MarkdownEscape(AnalysisValue(characterStats.armor and characterStats.armor.effective)) .. ", melee hit " .. Addon.MarkdownEscape(AnalysisValue(RatingBonus(characterStats, "melee_hit"), "%")) .. ", spell hit " .. Addon.MarkdownEscape(AnalysisValue(RatingBonus(characterStats, "spell_hit"), "%")) .. " |"
    lines[#lines + 1] = "| Categories | " .. Addon.MarkdownEscape(Addon.CompactCountList(chartStats.categoryCounts, function(entry) return entry.name end, 5)) .. " |"
    lines[#lines + 1] = "| Top stats | " .. Addon.MarkdownEscape(FormatStats(Addon.FirstEntries(chartStats.statTotals, 8))) .. " |"
    lines[#lines + 1] = ""
end

function Addon.AppendMarkdownRoleSnapshot(lines, strategyBook)
    lines[#lines + 1] = "## Role Snapshot"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| Role | Confidence | Talent points | Models | Gear highlights |"
    lines[#lines + 1] = "| --- | ---: | ---: | --- | --- |"

    for roleIndex = 1, math.min(#(strategyBook.roles or {}), 5) do
        local role = strategyBook.roles[roleIndex]
        lines[#lines + 1] = "| " .. Addon.MarkdownEscape(role.label or role.key)
            .. " | " .. tostring(role.confidence or 0)
            .. " | " .. tostring(role.talentPoints or 0)
            .. " | " .. Addon.MarkdownEscape(table.concat(role.models or {}, ", "))
            .. " | " .. Addon.MarkdownEscape(FormatStats(role.observed and role.observed.gearStatHighlights))
            .. " |"
    end

    if #(strategyBook.roles or {}) == 0 then
        lines[#lines + 1] = "| none | 0 | 0 | none | none |"
    end

    lines[#lines + 1] = ""
end

function Addon.AppendMarkdownItemTable(lines, category, bucket, defaultOpen)
    lines[#lines + 1] = defaultOpen and "<details open>" or "<details>"
    lines[#lines + 1] = "<summary>" .. Addon.MarkdownEscape(category) .. " (" .. tostring(#(bucket or {})) .. ")</summary>"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| Item | Q | iLvl | Source | Location | Stats |"
    lines[#lines + 1] = "| --- | --- | ---: | --- | --- | --- |"

    for itemIndex = 1, #(bucket or {}) do
        local item = bucket[itemIndex]
        lines[#lines + 1] = "| " .. Addon.MarkdownPlainItemName(item)
            .. " x" .. tostring(item.count or 1)
            .. " | " .. Addon.MarkdownEscape(QualityDisplay(item))
            .. " | " .. Addon.MarkdownEscape(ItemLevelDisplay(item))
            .. " | " .. Addon.MarkdownEscape(SourceLabel(item.source))
            .. " | " .. Addon.MarkdownEscape(item.location or "Unknown Location")
            .. " | " .. Addon.MarkdownEscape(Addon.ShortStats(item.stats, 4))
            .. " |"
    end

    if #(bucket or {}) == 0 then
        lines[#lines + 1] = "| none | - | - | - | - | - |"
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
    profile.talents = profile.talents or { updatedAt = 0, available = false, summary = "", tabs = {} }
    profile.characterStats = profile.characterStats or { updatedAt = 0, api = "unavailable" }
    profile.localDB = profile.localDB or {
        name = DB_NAME,
        version = 1,
        savedAt = 0,
        bagItemCount = #(profile.bags.items or {}),
        bankItemCount = #(profile.bank.items or {}),
    }
    profile.localDB.name = DB_NAME
    profile.localDB.version = 1

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

function Addon:BuildItem(source, bagID, slotID)
    local texture, count, containerQuality, link = self:GetContainerItemValues(bagID, slotID)

    if not link then
        return nil
    end

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
    icon = icon or instantTexture or texture
    quality = quality or containerQuality

    local itemLinkForExport = resolvedLink or link
    local itemName = name or ParseItemName(link) or (itemID and ("Item " .. itemID)) or "Unknown Item"
    local qualityColor = QualityColorHex(quality) or ParseItemLinkColorHex(itemLinkForExport)

    return {
        source = source,
        bag = bagID,
        slot = slotID,
        location = LocationLabel(source, bagID, slotID),
        itemID = itemID,
        itemString = ParseItemString(link),
        link = itemLinkForExport,
        wowheadUrl = WowheadItemURL(itemID),
        name = itemName,
        nameColored = ColorizeItemName(itemName, qualityColor),
        count = count or 1,
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
    profile.localDB = profile.localDB or { name = DB_NAME, version = 1 }
    profile.localDB.name = DB_NAME
    profile.localDB.version = 1
    profile.localDB.savedAt = Now()

    if source == "bags" then
        profile.bags = snapshot
        profile.localDB.bagSavedAt = snapshot.updatedAt
        profile.localDB.bagItemCount = #(snapshot.items or {})
    elseif source == "bank" then
        profile.bank = snapshot
        profile.localDB.bankSavedAt = snapshot.updatedAt
        profile.localDB.bankItemCount = #(snapshot.items or {})
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
    profile.localDB = profile.localDB or { name = DB_NAME, version = 1 }
    profile.localDB.name = DB_NAME
    profile.localDB.version = 1
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
    profile.localDB = profile.localDB or { name = DB_NAME, version = 1 }
    profile.localDB.name = DB_NAME
    profile.localDB.version = 1
    profile.localDB.savedAt = Now()
    profile.localDB.characterStatsSavedAt = snapshot.updatedAt
    profile.localDB.race = snapshot.race and snapshot.race.localized or nil
    profile.localDB.raceToken = snapshot.race and snapshot.race.english or nil
    profile.localDB.groupType = snapshot.group and snapshot.group.type or nil
    return snapshot
end

function Addon:ScanBags()
    self:SaveTalentSnapshot()
    self:SaveCharacterStatsSnapshot()
    local snapshot = self:ScanContainers("bags", self:GetBagContainers())
    return self:SaveSnapshot("bags", snapshot)
end

function Addon:ScanBank()
    self:SaveTalentSnapshot()
    self:SaveCharacterStatsSnapshot()
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

function Addon:BuildMarkdownExport(scope, profile, items, categories, buckets, filter, prompt, chartStats, characterStats, strategyBook)
    local lines = {
        "# TBC Gear Exporter",
        "",
        "> Human-readable report. Use JSON or AI Text when another tool needs the full raw dataset.",
        "",
    }

    chartStats = chartStats or BuildChartStats(items or {})
    strategyBook = strategyBook or BuildStrategyBook(profile, chartStats)
    Addon.AppendMarkdownQuickSummary(lines, profile, scope, filter, items or {}, chartStats, strategyBook)
    Addon.AppendMarkdownRoleSnapshot(lines, strategyBook)

    lines[#lines + 1] = "## AI Prompt"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "```text"
    lines[#lines + 1] = prompt and prompt.text or ""
    lines[#lines + 1] = "```"
    lines[#lines + 1] = ""

    lines[#lines + 1] = "<details>"
    lines[#lines + 1] = "<summary>Character, strategy, and chart details</summary>"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "## Export Metadata"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "- Character: " .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm")
    lines[#lines + 1] = "- Class: " .. tostring(profile.classLocalized or profile.classEnglish or "Unknown Class")
    lines[#lines + 1] = "- Current talents: " .. TalentSummaryText(profile.talents, profile.locale)
    lines[#lines + 1] = "- Talent points: " .. TalentTreePointsText(profile.talents, profile.locale)
    lines[#lines + 1] = "- Selected talents: " .. TalentSelectedPointsText(profile.talents, profile.locale, 12)
    lines[#lines + 1] = "- Client locale: " .. tostring(profile.locale or "enUS")
    lines[#lines + 1] = "- Local DB: " .. DB_NAME .. " saved at " .. FormatTime(profile.localDB and profile.localDB.savedAt)
    lines[#lines + 1] = "- Scope: " .. ScopeTitle(scope)
    lines[#lines + 1] = "- Filter: " .. ExportFilterTitle(filter)
    lines[#lines + 1] = "- Items: " .. #(items or {})
    lines[#lines + 1] = "- Bag scan: " .. FormatTime(profile.bags and profile.bags.updatedAt)
    lines[#lines + 1] = "- Bank scan: " .. FormatTime(profile.bank and profile.bank.updatedAt)
    lines[#lines + 1] = ""

    AppendCharacterStatsMarkdown(lines, characterStats)
    AppendStrategyBookMarkdown(lines, strategyBook)
    AppendChartStatsMarkdown(lines, chartStats)
    lines[#lines + 1] = "</details>"
    lines[#lines + 1] = ""

    if #(items or {}) == 0 then
        lines[#lines + 1] = "_No saved items are available. Use `/tbcgear scan` to save bags, and open the bank while scanning to save bank items._"
        return table.concat(lines, "\n")
    end

    lines[#lines + 1] = "## Item Tables"
    lines[#lines + 1] = ""

    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        local bucket = buckets[category] or {}
        Addon.AppendMarkdownItemTable(lines, category, bucket, category == "Gear")
    end

    return table.concat(lines, "\n")
end
function Addon:BuildTextExport(scope, profile, items, categories, buckets, filter, prompt, chartStats, characterStats, strategyBook)
    local lines = {
        "TBC Gear Exporter",
        "",
        "AI PROMPT",
        prompt and prompt.text or "",
        "",
        "EXPORT METADATA",
        "Character: " .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm"),
        "Class: " .. tostring(profile.classLocalized or profile.classEnglish or "Unknown Class"),
        "Current talents: " .. TalentSummaryText(profile.talents, profile.locale),
        "Talent points: " .. TalentTreePointsText(profile.talents, profile.locale),
        "Selected talents: " .. TalentSelectedPointsText(profile.talents, profile.locale, 12),
        "Client locale: " .. tostring(profile.locale or "enUS"),
        "Local DB: " .. DB_NAME .. " saved at " .. FormatTime(profile.localDB and profile.localDB.savedAt),
        "Scope: " .. ScopeTitle(scope),
        "Filter: " .. ExportFilterTitle(filter),
        "Items: " .. #items,
        "Bag scan: " .. FormatTime(profile.bags and profile.bags.updatedAt),
        "Bank scan: " .. FormatTime(profile.bank and profile.bank.updatedAt),
        "",
    }

    AppendCharacterStatsText(lines, characterStats)
    AppendStrategyBookText(lines, strategyBook)
    AppendChartStatsText(lines, chartStats)

    if #items == 0 then
        lines[#lines + 1] = "No saved items are available. Use /tbcgear scan to save bags."
        return table.concat(lines, "\n")
    end

    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        local bucket = buckets[category] or {}
        lines[#lines + 1] = "[" .. category .. "]"

        for itemIndex = 1, #bucket do
            local item = bucket[itemIndex]
            local wowheadUrl = ItemWowheadURL(item)
            local line = "- " .. ItemColoredName(item)
                .. " x" .. tostring(item.count or 1)
                .. " | " .. QualityDisplay(item)
                .. " | iLvl: " .. ItemLevelDisplay(item)
                .. " | Type: " .. ItemTypeDisplay(item)
                .. " | " .. SourceLabel(item.source)
                .. " | " .. tostring(item.location or "Unknown Location")

            if wowheadUrl then
                line = line .. " | Wowhead: " .. wowheadUrl
            end

            lines[#lines + 1] = line
                .. " | Stats: " .. FormatStats(item.stats)
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

    local lines = {
        "AI_READY_WOW_TBC_INVENTORY_EXPORT v1",
        "Paste this entire selected text into an AI chat. It contains a prompt plus structured JSON for TBC bag and bank gear analysis.",
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
        return self:BuildMarkdownExport(scope, profile, items, categories, buckets, filter, prompt, chartStats, profile.characterStats, strategyBook)
    end

    if format == "text" then
        return self:BuildTextExport(scope, profile, items, categories, buckets, filter, prompt, chartStats, profile.characterStats, strategyBook)
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
            GameTooltip:AddLine(tostring(item.location or item.sourceLabel or item.source or ""))
            local stats = FormatStats(item.stats)
            if stats ~= "none" then
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
        row.meta:SetText(tostring(item.location or "") .. "  " .. QualityDisplay(item) .. "  iLvl " .. ItemLevelDisplay(item) .. "  " .. ItemTypeDisplay(item))
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
    local overviewRoleCount = 0
    local analysisRoleCount = 0
    self.exportFrame.editBox:SetText(text)
    self:RefreshVisualItems(items)
    overviewRoleCount = self:RefreshOverview(profile, chartStats, strategyBook, items)
    analysisRoleCount = self:RefreshStatsAnalysis(profile, chartStats, strategyBook)
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
    SetFrameSize(overviewTab, 78, 24)
    overviewTab:SetPoint("TOPLEFT", 282, -64)
    overviewTab:SetText(L("overview_tab"))
    overviewTab:SetScript("OnClick", function()
        Addon:SetExportView("overview")
        Addon:RefreshExport()
    end)

    local itemsTab = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(itemsTab, 70, 24)
    itemsTab:SetPoint("LEFT", overviewTab, "RIGHT", 8, 0)
    itemsTab:SetText(L("items_tab"))
    itemsTab:SetScript("OnClick", function()
        Addon:SetExportView("items")
        Addon.exportFrame.status:SetText(L("status_visual", #(Addon:CollectExportItems(Addon.exportScope or "all", Addon.exportFilter))))
    end)

    local analysisTab = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(analysisTab, 112, 24)
    analysisTab:SetPoint("LEFT", itemsTab, "RIGHT", 8, 0)
    analysisTab:SetText(L("stats_analysis_tab"))
    analysisTab:SetScript("OnClick", function()
        Addon:SetExportView("analysis")
        Addon:RefreshExport()
    end)

    local textTab = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(textTab, 104, 24)
    textTab:SetPoint("LEFT", analysisTab, "RIGHT", 8, 0)
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
    exportFrame.itemsTab = itemsTab
    exportFrame.analysisTab = analysisTab
    exportFrame.textTab = textTab
    exportFrame.overviewScroll = overviewScroll
    exportFrame.visualScroll = visualScroll
    exportFrame.analysisScroll = analysisScroll
    exportFrame.textScroll = textScroll
    exportFrame.overviewContent = overviewContent
    exportFrame.overviewText = overviewText
    exportFrame.itemListContent = itemListContent
    exportFrame.analysisContent = analysisContent
    exportFrame.analysisText = analysisText
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
        version = 1,
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
        BestSpellValue = BestSpellValue,
        KnownAvoidanceBlock = KnownAvoidanceBlock,
        TalentPointsForTabs = TalentPointsForTabs,
        TalentPrimaryMatches = TalentPrimaryMatches,
        RoleConfidence = RoleConfidence,
        BuildRoleObservedStats = BuildRoleObservedStats,
        BenchmarkObservedValue = BenchmarkObservedValue,
        BenchmarkStatus = BenchmarkStatus,
        BuildRoleBenchmarks = BuildRoleBenchmarks,
        StrategyClassRoles = StrategyClassRoles,
        BuildStrategyBook = BuildStrategyBook,
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
