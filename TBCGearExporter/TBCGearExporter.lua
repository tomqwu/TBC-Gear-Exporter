local addonName = ...

local Addon = {}
local frame = CreateFrame("Frame")

local DB_NAME = "TBCGearExporterDB"
local BANK_CONTAINER_ID = BANK_CONTAINER or -1
local PLAYER_BAG_SLOTS = NUM_BAG_SLOTS or 4
local BANK_BAG_SLOTS = NUM_BANKBAGSLOTS or 7

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

local function CategoryFromInfo(classID, itemType, equipSlot)
    if equipSlot and equipSlot ~= "" then
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

    return profile
end

function Addon:GetContainerItemValues(bagID, slotID)
    if type(GetContainerItemInfo) ~= "function" then
        return nil
    end

    local info = GetContainerItemInfo(bagID, slotID)
    if type(info) == "table" then
        return info.iconFileID or info.texture,
            info.stackCount or info.count,
            info.quality or info.itemQuality,
            info.hyperlink or info.link
    end

    local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bagID, slotID)

    if not link and type(GetContainerItemLink) == "function" then
        link = GetContainerItemLink(bagID, slotID)
    end

    return texture, count, quality, link
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

    return {
        source = source,
        bag = bagID,
        slot = slotID,
        location = LocationLabel(source, bagID, slotID),
        itemID = itemID,
        itemString = ParseItemString(link),
        link = itemLinkForExport,
        name = name or ParseItemName(link) or (itemID and ("Item " .. itemID)) or "Unknown Item",
        count = count or 1,
        quality = quality,
        qualityName = QualityName(quality),
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
    }

    if type(GetContainerNumSlots) ~= "function" then
        return snapshot
    end

    for index = 1, #containers do
        local bagID = containers[index]
        local slots = GetContainerNumSlots(bagID) or 0

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

function Addon:ScanBags()
    local profile = self:GetProfile()
    profile.bags = self:ScanContainers("bags", self:GetBagContainers())
    return profile.bags
end

function Addon:ScanBank()
    local profile = self:GetProfile()
    profile.bank = self:ScanContainers("bank", self:GetBankContainers())
    return profile.bank
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

function Addon:CollectExportItems(scope)
    local profile = self:GetProfile()
    local items = {}
    local includeBags = scope == "all" or scope == "gear" or scope == "bags"
    local includeBank = scope == "all" or scope == "gear" or scope == "bank"
    local gearOnly = scope == "gear"

    if includeBags then
        local bagItems = CopyItems(profile.bags and profile.bags.items)
        for index = 1, #bagItems do
            if not gearOnly or bagItems[index].category == "Gear" then
                items[#items + 1] = bagItems[index]
            end
        end
    end

    if includeBank then
        local bankItems = CopyItems(profile.bank and profile.bank.items)
        for index = 1, #bankItems do
            if not gearOnly or bankItems[index].category == "Gear" then
                items[#items + 1] = bankItems[index]
            end
        end
    end

    return items
end

function Addon:BuildExport(scope)
    scope = scope or "all"

    local profile = self:GetProfile()
    local items = self:CollectExportItems(scope)
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
    AppendIndented(lines, 2, JsonField("format", "tbc_gear_exporter_ai_v1", true))
    AppendIndented(lines, 2, "\"character\": {")
    AppendIndented(lines, 4, JsonField("name", profile.player or "Unknown Player", true))
    AppendIndented(lines, 4, JsonField("realm", profile.realm or "Unknown Realm", false))
    AppendIndented(lines, 2, "},")
    AppendIndented(lines, 2, "\"export\": {")
    AppendIndented(lines, 4, JsonField("scope", scope, true))
    AppendIndented(lines, 4, JsonField("scope_title", ScopeTitle(scope), true))
    AppendIndented(lines, 4, JsonField("generated_at", FormatTime(Now()), true))
    AppendIndented(lines, 4, JsonField("bag_scan_at", FormatTime(profile.bags and profile.bags.updatedAt), true))
    AppendIndented(lines, 4, JsonField("bank_scan_at", FormatTime(profile.bank and profile.bank.updatedAt), true))
    AppendIndented(lines, 4, JsonField("item_count", #items, false))
    AppendIndented(lines, 2, "},")
    AppendIndented(lines, 2, "\"notes\": [")
    AppendIndented(lines, 4, JsonString("Bank contents are the last saved snapshot. Open the bank in game and scan to refresh bank data.") .. (#items == 0 and "," or ""))

    if #items == 0 then
        AppendIndented(lines, 4, JsonString("No saved items are available for this export. Use /tbcgear scan to scan bags.") )
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
            local statsText = FormatStats(item.stats)
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
            AppendIndented(lines, 6, JsonField("item_id", item.itemID, true))
            AppendIndented(lines, 6, JsonField("item_string", item.itemString, true))
            AppendIndented(lines, 6, JsonField("item_link", item.link, true))
            AppendIndented(lines, 6, JsonField("quality", item.qualityName or "Unknown", true))
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

    return table.concat(lines, "\n")
end

function Addon:RefreshExport(scope)
    self.exportScope = scope or self.exportScope or "all"

    if not self.exportFrame then
        return
    end

    local text = self:BuildExport(self.exportScope)
    self.exportFrame.editBox:SetText(text)
    self.exportFrame.editBox:SetCursorPosition(0)
    self.exportFrame.editBox:HighlightText()
    self.exportFrame.editBox:SetFocus()
    self.exportFrame.status:SetText("AI-ready export is selected. Press Ctrl+C to copy.")
end

function Addon:CreateExportFrame()
    local exportFrame = CreateFrame("Frame", "TBCGearExporterExportFrame", UIParent)
    SetFrameSize(exportFrame, 720, 540)
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
    end

    local title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText("TBC Gear Exporter - AI Export")

    local close = CreateFrame("Button", nil, exportFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local scan = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(scan, 80, 24)
    scan:SetPoint("TOPLEFT", 20, -46)
    scan:SetText("Scan")
    scan:SetScript("OnClick", function()
        Addon:ScanBags()
        if Addon.bankOpen then
            Addon:ScanBank()
        else
            Addon:Print("Bags scanned. Open your bank and scan again to update bank items.")
        end
        Addon:RefreshExport()
    end)

    local all = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(all, 80, 24)
    all:SetPoint("LEFT", scan, "RIGHT", 8, 0)
    all:SetText("All")
    all:SetScript("OnClick", function()
        Addon:RefreshExport("all")
    end)

    local bags = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(bags, 80, 24)
    bags:SetPoint("LEFT", all, "RIGHT", 8, 0)
    bags:SetText("Bags")
    bags:SetScript("OnClick", function()
        Addon:ScanBags()
        Addon:RefreshExport("bags")
    end)

    local bank = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(bank, 80, 24)
    bank:SetPoint("LEFT", bags, "RIGHT", 8, 0)
    bank:SetText("Bank")
    bank:SetScript("OnClick", function()
        if Addon.bankOpen then
            Addon:ScanBank()
        else
            Addon:Print("Showing the last saved bank scan. Open your bank to refresh it.")
        end
        Addon:RefreshExport("bank")
    end)

    local gear = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    SetFrameSize(gear, 90, 24)
    gear:SetPoint("LEFT", bank, "RIGHT", 8, 0)
    gear:SetText("Gear Only")
    gear:SetScript("OnClick", function()
        Addon:RefreshExport("gear")
    end)

    local scroll = CreateFrame("ScrollFrame", "TBCGearExporterScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -82)
    scroll:SetPoint("BOTTOMRIGHT", -38, 48)

    local editBox = CreateFrame("EditBox", nil, scroll)
    SetFrameSize(editBox, 640, 380)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnTextChanged", function(self)
        local lineCount = self.GetNumLines and self:GetNumLines() or 1
        local height = math.max(380, (lineCount * 14) + 20)
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
    exportFrame.status = status
    self.exportFrame = exportFrame
end

function Addon:ShowExport(scope)
    if not self.exportFrame then
        self:CreateExportFrame()
    end

    self.exportFrame:Show()
    self:RefreshExport(scope)
end

function Addon:ClearProfile()
    local profile = self:GetProfile()
    profile.bags = { updatedAt = 0, items = {} }
    profile.bank = { updatedAt = 0, items = {} }
end

function Addon:ShowHelp()
    self:Print("Commands: /tbcgear gui, /tbcgear export, /tbcgear bags, /tbcgear bank, /tbcgear gear, /tbcgear scan, /tbcgear clear")
end

function Addon:HandleSlash(message)
    local command = Trim(message):lower()

    if command == "" or command == "gui" or command == "export" or command == "show" then
        self:ScanBags()
        self:ShowExport("all")
        return
    end

    if command == "bags" then
        self:ScanBags()
        self:ShowExport("bags")
        return
    end

    if command == "bank" then
        if self.bankOpen then
            self:ScanBank()
        else
            self:Print("Showing the last saved bank scan. Open your bank to refresh it.")
        end
        self:ShowExport("bank")
        return
    end

    if command == "gear" then
        self:ScanBags()
        if self.bankOpen then
            self:ScanBank()
        end
        self:ShowExport("gear")
        return
    end

    if command == "scan" then
        self:ScanBags()
        if self.bankOpen then
            self:ScanBank()
            self:Print("Bags and bank scanned.")
        else
            self:Print("Bags scanned. Open your bank and scan again to update bank items.")
        end
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
        self:ScanBags()
        self:Print("Loaded. Use /tbcgear export to copy your saved bags and bank.")
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
        self:ScanBank()
        self:Print("Bank scanned.")
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
        Trim = Trim,
        Now = Now,
        FormatTime = FormatTime,
        ParseItemID = ParseItemID,
        ParseItemString = ParseItemString,
        ParseItemName = ParseItemName,
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
        AppendIndented = AppendIndented,
        LocationLabel = LocationLabel,
        SourceLabel = SourceLabel,
        CategoryFromInfo = CategoryFromInfo,
        CopyItems = CopyItems,
    }

    _G.TBCGearExporter = Addon
end

SafeRegister("ADDON_LOADED")
