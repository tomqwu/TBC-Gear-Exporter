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
    "針對每個可能職責，列出值得保留的強力裝備、薄弱部位和升級優先順序。",
    "在相關時分別分析減傷、仇恨、輸出、治療、法系和功能性價值。",
    "標記重複物品、副天賦裝備、消耗品、材料，或可能適合出售、存銀行、分解、保留的物品。",
    "提到具體物品時使用 wowhead_url 欄位，方便使用者快速查看。",
    "只有當匯出資料無法判斷時，才提出簡短的追問。",
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
            parts[#parts + 1] = "+" .. value .. " " .. label
        elseif type(value) == "number" and value == 1 and socketStat then
            parts[#parts + 1] = label
        else
            parts[#parts + 1] = tostring(value) .. " " .. label
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
    local lines

    if promptLocale == "zhCN" then
        lines = {
            "你是一名精通《魔兽世界：燃烧的远征》经典版配装分析的助手。",
            "请分析下面的结构化物品导出，并给出实用、按职责区分的配装建议。",
            "角色：" .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm") .. "（" .. tostring(classDisplay) .. "）。",
            "客户端语言：" .. tostring(locale) .. "；请使用与客户端一致的语言回答，并保留物品原始本地化名称。",
            "导出范围：" .. LocalizedScopeTitle(scope, promptLocale) .. "；过滤器：" .. LocalizedExportFilterTitle(filter, promptLocale) .. "；物品数量：" .. tostring(itemCount or 0) .. "。",
            "银行内容是最后一次保存的快照。背包/银行来源只代表库存位置，不代表物品已经装备。",
            "请使用物品属性、物品等级、品质、装备栏位、分类、来源位置和 wowhead_url 字段。不要编造缺失属性，也不要假设隐藏附魔或宝石。",
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
            "銀行內容是最後一次儲存的快照。背包/銀行來源只代表庫存位置，不代表物品已經裝備。",
            "請使用物品屬性、物品等級、品質、裝備欄位、分類、來源位置和 wowhead_url 欄位。不要編造缺失屬性，也不要假設隱藏附魔或寶石。",
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
            "Bank contents are the last saved snapshot. Treat bag and bank source labels as inventory location, not proof that an item is equipped.",
            "Use item stats, item level, quality, equip slot, category, source location, and wowhead_url fields. Do not invent missing stats or assume hidden enchants/gems.",
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

function Addon:ScanBags()
    local snapshot = self:ScanContainers("bags", self:GetBagContainers())
    return self:SaveSnapshot("bags", snapshot)
end

function Addon:ScanBank()
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

function Addon:BuildMarkdownExport(scope, profile, items, categories, buckets, filter, prompt)
    local lines = {
        "# TBC Gear Exporter",
        "",
        "## AI Prompt",
        "",
        "```text",
        prompt and prompt.text or "",
        "```",
        "",
        "## Export Metadata",
        "",
        "- Character: " .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm"),
        "- Class: " .. tostring(profile.classLocalized or profile.classEnglish or "Unknown Class"),
        "- Client locale: " .. tostring(profile.locale or "enUS"),
        "- Local DB: " .. DB_NAME .. " saved at " .. FormatTime(profile.localDB and profile.localDB.savedAt),
        "- Scope: " .. ScopeTitle(scope),
        "- Filter: " .. ExportFilterTitle(filter),
        "- Items: " .. #items,
        "- Bag scan: " .. FormatTime(profile.bags and profile.bags.updatedAt),
        "- Bank scan: " .. FormatTime(profile.bank and profile.bank.updatedAt),
        "",
    }

    if #items == 0 then
        lines[#lines + 1] = "_No saved items are available. Use `/tbcgear scan` to save bags, and open the bank while scanning to save bank items._"
        return table.concat(lines, "\n")
    end

    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        local bucket = buckets[category] or {}
        lines[#lines + 1] = "## " .. category .. " (" .. #bucket .. ")"

        for itemIndex = 1, #bucket do
            local item = bucket[itemIndex]
            local wowheadUrl = ItemWowheadURL(item)
            local line = "- " .. MarkdownItemName(item) .. " x" .. tostring(item.count or 1)
                .. " | " .. QualityDisplay(item)
                .. " | iLvl: " .. ItemLevelDisplay(item)
                .. " | Type: " .. ItemTypeDisplay(item)
                .. " | " .. SourceLabel(item.source)
                .. " | " .. tostring(item.location or "Unknown Location")

            if wowheadUrl then
                line = line .. " | Wowhead: " .. wowheadUrl
            end

            lines[#lines + 1] = line .. " | Stats: " .. FormatStats(item.stats)
        end

        lines[#lines + 1] = ""
    end

    return table.concat(lines, "\n")
end

function Addon:BuildTextExport(scope, profile, items, categories, buckets, filter, prompt)
    local lines = {
        "TBC Gear Exporter",
        "",
        "AI PROMPT",
        prompt and prompt.text or "",
        "",
        "EXPORT METADATA",
        "Character: " .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm"),
        "Class: " .. tostring(profile.classLocalized or profile.classEnglish or "Unknown Class"),
        "Client locale: " .. tostring(profile.locale or "enUS"),
        "Local DB: " .. DB_NAME .. " saved at " .. FormatTime(profile.localDB and profile.localDB.savedAt),
        "Scope: " .. ScopeTitle(scope),
        "Filter: " .. ExportFilterTitle(filter),
        "Items: " .. #items,
        "Bag scan: " .. FormatTime(profile.bags and profile.bags.updatedAt),
        "Bank scan: " .. FormatTime(profile.bank and profile.bank.updatedAt),
        "",
    }

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
    AppendIndented(lines, 4, JsonField("class_id", profile.classID, false))
    AppendIndented(lines, 2, "},")
    AppendIndented(lines, 2, "\"local_db\": {")
    AppendIndented(lines, 4, JsonField("name", DB_NAME, true))
    AppendIndented(lines, 4, JsonField("saved_at", FormatTime(profile.localDB and profile.localDB.savedAt), true))
    AppendIndented(lines, 4, JsonField("bag_item_count", profile.localDB and profile.localDB.bagItemCount, true))
    AppendIndented(lines, 4, JsonField("bank_item_count", profile.localDB and profile.localDB.bankItemCount, false))
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
        return self:BuildMarkdownExport(scope, profile, items, categories, buckets, filter, prompt)
    end

    if format == "text" then
        return self:BuildTextExport(scope, profile, items, categories, buckets, filter, prompt)
    end

    return aiText
end

function Addon:SavedItemCounts()
    local profile = self:GetProfile()
    local bagItems = profile.bags and profile.bags.items or {}
    local bankItems = profile.bank and profile.bank.items or {}
    return #bagItems, #bankItems
end

function Addon:SelectExportText()
    if not self.exportFrame or not self.exportFrame.editBox then
        return
    end

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
    local bagCount, bankCount = self:SavedItemCounts()
    self.exportFrame.editBox:SetText(text)
    self:SelectExportText()

    if self.exportFrame.summary then
        self.exportFrame.summary:SetText(L("summary", bagCount, bankCount, LocalizedScopeTitle(self.exportScope, ClientLocale()), LocalizedExportFilterTitle(self.exportFilter, ClientLocale()), LocalizedExportFormatTitle(self.exportFormat, ClientLocale())))
    end

    self.exportFrame.status:SetText(L("status_generated", LocalizedExportFormatTitle(self.exportFormat, ClientLocale()), LocalizedExportFilterTitle(self.exportFilter, ClientLocale())))
end

function Addon:CreateExportFrame()
    local exportFrame = CreateFrame("Frame", "TBCGearExporterExportFrame", UIParent, BackdropTemplate())
    SetFrameSize(exportFrame, 680, 520)
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

    local scan = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(scan, 100, 24)
    scan:SetPoint("TOPLEFT", 20, -64)
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
    SetFrameSize(export, 78, 24)
    export:SetPoint("LEFT", scan, "RIGHT", 8, 0)
    export:SetText(L("export_button"))
    export:SetScript("OnClick", function()
        Addon:ExportSaved("all")
    end)

    local bags = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(bags, 62, 24)
    bags:SetPoint("LEFT", export, "RIGHT", 8, 0)
    bags:SetText(L("bags_button"))
    bags:SetScript("OnClick", function()
        Addon:ExportSaved("bags")
    end)

    local bank = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(bank, 62, 24)
    bank:SetPoint("LEFT", bags, "RIGHT", 8, 0)
    bank:SetText(L("bank_button"))
    bank:SetScript("OnClick", function()
        Addon:ExportSaved("bank")
    end)

    local gear = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(gear, 70, 24)
    gear:SetPoint("LEFT", bank, "RIGHT", 8, 0)
    gear:SetText(L("gear_button"))
    gear:SetScript("OnClick", function()
        Addon:ExportSaved("gear")
    end)

    local debugButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(debugButton, 70, 24)
    debugButton:SetPoint("LEFT", gear, "RIGHT", 8, 0)
    debugButton:SetText(L("debug_button"))
    debugButton:SetScript("OnClick", function()
        Addon:DebugContainers()
    end)

    local selectButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(selectButton, 86, 24)
    selectButton:SetPoint("LEFT", debugButton, "RIGHT", 8, 0)
    selectButton:SetText(L("select_button"))
    selectButton:SetScript("OnClick", function()
        Addon:SelectExportText()
        Addon.exportFrame.status:SetText(L("status_selected"))
    end)

    local formatLabel = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    formatLabel:SetPoint("TOPLEFT", 20, -96)
    formatLabel:SetText(L("format_label"))

    local aiFormat = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(aiFormat, 52, 22)
    aiFormat:SetPoint("LEFT", formatLabel, "RIGHT", 8, 0)
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
    markdownFormat:SetPoint("LEFT", jsonFormat, "RIGHT", 6, 0)
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
    filterLabel:SetPoint("TOPLEFT", 20, -126)
    filterLabel:SetText(L("filter_label"))

    local allQuality = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(allQuality, 62, 22)
    allQuality:SetPoint("LEFT", filterLabel, "RIGHT", 8, 0)
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
    epicQuality:SetPoint("LEFT", rarePlus, "RIGHT", 6, 0)
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

    local scroll = CreateFrame("ScrollFrame", "TBCGearExporterScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -156)
    scroll:SetPoint("BOTTOMRIGHT", -38, 48)

    local editBox = CreateFrame("EditBox", nil, scroll)
    SetFrameSize(editBox, 600, 300)
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
    scroll:SetScrollChild(editBox)

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
    self.exportFrame = exportFrame
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
    profile.localDB = {
        name = DB_NAME,
        version = 1,
        savedAt = 0,
        bagSavedAt = 0,
        bankSavedAt = 0,
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
        LocationLabel = LocationLabel,
        SourceLabel = SourceLabel,
        ClientLocale = ClientLocale,
        PromptLocale = PromptLocale,
        LForLocale = LForLocale,
        L = L,
        LocalizedExportFormatTitle = LocalizedExportFormatTitle,
        ClassToken = ClassToken,
        GetPlayerClassInfo = GetPlayerClassInfo,
        ClassRoleContext = ClassRoleContext,
        LocalizedRoleContext = LocalizedRoleContext,
        LocalizedOutputRequests = LocalizedOutputRequests,
        BuildAIPrompt = BuildAIPrompt,
        IsEquippableSlot = IsEquippableSlot,
        CategoryFromInfo = CategoryFromInfo,
        CopyItems = CopyItems,
    }

    _G.TBCGearExporter = Addon
end

SafeRegister("ADDON_LOADED")
