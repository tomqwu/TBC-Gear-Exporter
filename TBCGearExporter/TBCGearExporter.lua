local addonName = ...

local Addon = {}
local frame = CreateFrame("Frame")

local DB_NAME = "TBCGearExporterDB"
local BANK_CONTAINER_ID = BANK_CONTAINER or -1
local PLAYER_BAG_SLOTS = NUM_BAG_SLOTS or 4
local BANK_BAG_SLOTS = NUM_BANKBAGSLOTS or 7
local MINIMAP_ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Bag_10_Blue"
local WOWHEAD_TBC_ITEM_URL_PREFIX = "https://www.wowhead.com/tbc/item="

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

local EXPORT_FORMAT_LABELS = {
    ai = "AI Text",
    json = "JSON",
    markdown = "Markdown",
    text = "Text",
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

    self.db.profiles[key] = self.db.profiles[key] or {
        player = player,
        realm = realm,
        bags = { updatedAt = 0, items = {} },
        bank = { updatedAt = 0, items = {} },
    }

    local profile = self.db.profiles[key]
    profile.player = player
    profile.realm = realm
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
    return label .. ": " .. #(snapshot.items or {}) .. " items, " .. tostring(snapshot.totalSlots or 0) .. " slots via " .. tostring(snapshot.api or "unknown") .. ", saved to local DB"
end

function Addon:ScanBagsAndReport(label)
    local snapshot = self:ScanBags()
    self:Print(self:FormatScanSummary(label or "Bags scanned", snapshot) .. ".")
    return snapshot
end

function Addon:ScanBankAndReport(label)
    local snapshot = self:ScanBank()
    self:Print(self:FormatScanSummary(label or "Bank scanned", snapshot) .. ".")
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

function Addon:BuildMarkdownExport(scope, profile, items, categories, buckets, filter)
    local lines = {
        "# TBC Gear Exporter",
        "",
        "- Character: " .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm"),
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

function Addon:BuildTextExport(scope, profile, items, categories, buckets, filter)
    local lines = {
        "TBC Gear Exporter",
        "Character: " .. tostring(profile.player or "Unknown Player") .. " - " .. tostring(profile.realm or "Unknown Realm"),
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
        "Paste this entire selected text into an AI chat. It contains structured JSON for TBC bag and bank gear analysis.",
        "DATA_JSON:",
    }

    AppendIndented(lines, 0, "{")
    AppendIndented(lines, 2, JsonField("format", format == "json" and "tbc_gear_exporter_json_v1" or "tbc_gear_exporter_ai_v1", true))
    AppendIndented(lines, 2, "\"character\": {")
    AppendIndented(lines, 4, JsonField("name", profile.player or "Unknown Player", true))
    AppendIndented(lines, 4, JsonField("realm", profile.realm or "Unknown Realm", false))
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
        return self:BuildMarkdownExport(scope, profile, items, categories, buckets, filter)
    end

    if format == "text" then
        return self:BuildTextExport(scope, profile, items, categories, buckets, filter)
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
        self.exportFrame.summary:SetText("Bags: " .. bagCount .. " items   Bank: " .. bankCount .. " items   Scope: " .. ScopeTitle(self.exportScope) .. "   Filter: " .. ExportFilterTitle(self.exportFilter) .. "   Format: " .. ExportFormatTitle(self.exportFormat))
    end

    self.exportFrame.status:SetText(ExportFormatTitle(self.exportFormat) .. " export generated from saved local DB with filter: " .. ExportFilterTitle(self.exportFilter) .. ". Press Ctrl+C to copy.")
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
    title:SetText("TBC Gear Exporter")

    local close = CreateFrame("Button", nil, exportFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local summary = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summary:SetPoint("TOPLEFT", 20, -42)
    summary:SetPoint("TOPRIGHT", -20, -42)
    summary:SetJustifyH("LEFT")
    summary:SetText("Bags: 0 items   Bank: 0 items   Scope: All")

    local scan = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(scan, 100, 24)
    scan:SetPoint("TOPLEFT", 20, -64)
    scan:SetText("Scan Bags")
    scan:SetScript("OnClick", function()
        Addon:ScanBagsAndReport("Bags scanned")
        if Addon.bankOpen then
            Addon:ScanBankAndReport("Bank scanned")
        else
            Addon:Print("Open your bank and scan again to update bank items.")
        end
        Addon:RefreshExport()
    end)

    local export = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(export, 78, 24)
    export:SetPoint("LEFT", scan, "RIGHT", 8, 0)
    export:SetText("Export")
    export:SetScript("OnClick", function()
        Addon:ExportSaved("all")
    end)

    local bags = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(bags, 62, 24)
    bags:SetPoint("LEFT", export, "RIGHT", 8, 0)
    bags:SetText("Bags")
    bags:SetScript("OnClick", function()
        Addon:ExportSaved("bags")
    end)

    local bank = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(bank, 62, 24)
    bank:SetPoint("LEFT", bags, "RIGHT", 8, 0)
    bank:SetText("Bank")
    bank:SetScript("OnClick", function()
        Addon:ExportSaved("bank")
    end)

    local gear = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(gear, 70, 24)
    gear:SetPoint("LEFT", bank, "RIGHT", 8, 0)
    gear:SetText("Gear")
    gear:SetScript("OnClick", function()
        Addon:ExportSaved("gear")
    end)

    local debugButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(debugButton, 70, 24)
    debugButton:SetPoint("LEFT", gear, "RIGHT", 8, 0)
    debugButton:SetText("Debug")
    debugButton:SetScript("OnClick", function()
        Addon:DebugContainers()
    end)

    local selectButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(selectButton, 86, 24)
    selectButton:SetPoint("LEFT", debugButton, "RIGHT", 8, 0)
    selectButton:SetText("Select")
    selectButton:SetScript("OnClick", function()
        Addon:SelectExportText()
        Addon.exportFrame.status:SetText("Export text selected. Press Ctrl+C to copy.")
    end)

    local formatLabel = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    formatLabel:SetPoint("TOPLEFT", 20, -96)
    formatLabel:SetText("Format:")

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
    textFormat:SetText("Text")
    textFormat:SetScript("OnClick", function()
        Addon:ExportSaved(nil, "text")
    end)

    local filterLabel = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    filterLabel:SetPoint("TOPLEFT", 20, -126)
    filterLabel:SetText("Filter:")

    local allQuality = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(allQuality, 62, 22)
    allQuality:SetPoint("LEFT", filterLabel, "RIGHT", 8, 0)
    allQuality:SetText("All Q")
    allQuality:SetScript("OnClick", function()
        Addon:ExportSaved(nil, nil, "all")
    end)

    local rarePlus = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(rarePlus, 68, 22)
    rarePlus:SetPoint("LEFT", allQuality, "RIGHT", 6, 0)
    rarePlus:SetText("Rare+")
    rarePlus:SetScript("OnClick", function()
        Addon:ExportSaved(nil, nil, { qualityMin = 3 })
    end)

    local epicQuality = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(epicQuality, 62, 22)
    epicQuality:SetPoint("LEFT", rarePlus, "RIGHT", 6, 0)
    epicQuality:SetText("Epic")
    epicQuality:SetScript("OnClick", function()
        Addon:ExportSaved(nil, nil, { qualityID = 4 })
    end)

    local gearEpic = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(gearEpic, 94, 22)
    gearEpic:SetPoint("LEFT", epicQuality, "RIGHT", 6, 0)
    gearEpic:SetText("Gear Epic")
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
    status:SetText("AI-ready export is selected. Press Ctrl+C to copy.")

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
    self:Print(ExportFormatTitle(self.exportFormat) .. " export opened from local DB: " .. bagCount .. " bag items, " .. bankCount .. " bank items. Filter: " .. ExportFilterTitle(self.exportFilter) .. ".")
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
            Addon:ScanBagsAndReport("Bags scanned")
            if Addon.bankOpen then
                Addon:ScanBankAndReport("Bank scanned")
            else
                Addon:Print("Open your bank and scan again to update bank items.")
            end
            return
        end

        Addon:ExportSaved("all")
    end)

    button:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("TBC Gear Exporter")
            GameTooltip:AddLine("Left-click: export saved local DB", 1, 1, 1)
            GameTooltip:AddLine("Right-click: scan and save bags/bank", 0.8, 0.8, 0.8)
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
    self:Print("Commands: /tbcgear export [scope] [quality|quality+] [ai|json|markdown|text], /tbcgear gear epic, /tbcgear rare+, /tbcgear scan, /tbcgear debug, /tbcgear clear")
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
        self:ScanBagsAndReport("Bags scanned")
        if self.bankOpen then
            self:ScanBankAndReport("Bank scanned")
        else
            self:Print("Open your bank and scan again to update bank items.")
        end
        return
    end

    if command == "debug" then
        self:DebugContainers()
        return
    end

    if command == "clear" then
        self:ClearProfile()
        self:Print("Saved bag and bank snapshots cleared for this character.")
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
        self:Print("Loaded. " .. self:FormatScanSummary("Bags", snapshot) .. ". Click the minimap bag icon or use /tbcgear gui.")
        return
    end

    if eventName == "BAG_OPEN" then
        local bagID = ...
        local snapshot = self:ScanBags()
        if bagID ~= nil then
            self:Print("Debug: bag " .. bagID .. " opened; " .. self:FormatScanSummary("bags", snapshot) .. ".")
        else
            self:Print("Debug: bag opened; " .. self:FormatScanSummary("bags", snapshot) .. ".")
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
        self:Print("Debug: bank opened; " .. self:FormatScanSummary("bank", snapshot) .. ".")
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
        TitleCase = TitleCase,
        CleanStatLabel = CleanStatLabel,
        StatLabel = StatLabel,
        BuildStatList = BuildStatList,
        FormatStats = FormatStats,
        JsonString = JsonString,
        JsonValue = JsonValue,
        JsonField = JsonField,
        ScopeTitle = ScopeTitle,
        NormalizeExportFormat = NormalizeExportFormat,
        IsExportFormatToken = IsExportFormatToken,
        ExportFormatTitle = ExportFormatTitle,
        SplitWords = SplitWords,
        NormalizeQualityID = NormalizeQualityID,
        DefaultExportFilter = DefaultExportFilter,
        NormalizeExportFilter = NormalizeExportFilter,
        ExportFilterHasCriteria = ExportFilterHasCriteria,
        ExportFilterTitle = ExportFilterTitle,
        ItemQualityID = ItemQualityID,
        ExportFilterMatchesItem = ExportFilterMatchesItem,
        NormalizeExportScope = NormalizeExportScope,
        ParseExportOptions = ParseExportOptions,
        AppendIndented = AppendIndented,
        LocationLabel = LocationLabel,
        SourceLabel = SourceLabel,
        IsEquippableSlot = IsEquippableSlot,
        CategoryFromInfo = CategoryFromInfo,
        CopyItems = CopyItems,
    }

    _G.TBCGearExporter = Addon
end

SafeRegister("ADDON_LOADED")
