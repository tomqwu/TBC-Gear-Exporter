local ADDON_PATH = "TBCGearExporter/TBCGearExporter.lua"
local COVERAGE_MINIMUM = 99.0

local tests = {}
local coveredLines = {}
local executableLines = {}
local mock

local function shellQuote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function loadExecutableLines()
    local luac = os.getenv("LUAC") or "luac"
    local pipe = assert(io.popen(luac .. " -l -p " .. shellQuote(ADDON_PATH)))

    for line in pipe:lines() do
        local lineNumber = line:match("%[(%d+)%]")
        if lineNumber then
            lineNumber = tonumber(lineNumber)
            if lineNumber and lineNumber > 0 then
                executableLines[lineNumber] = true
            end
        end
    end

    pipe:close()
end

local function coverageHook(_, lineNumber)
    local info = debug.getinfo(2, "S")
    local source = info and info.source or ""

    if source:find(ADDON_PATH, 1, true) then
        coveredLines[lineNumber] = true
    end
end

local function countKeys(values)
    local count = 0

    for _ in pairs(values) do
        count = count + 1
    end

    return count
end

local function sortedMissingLines()
    local missing = {}

    for lineNumber in pairs(executableLines) do
        if not coveredLines[lineNumber] then
            missing[#missing + 1] = lineNumber
        end
    end

    table.sort(missing)
    return missing
end

local function assertEquals(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function assertTrue(value, message)
    if not value then
        error(message or "expected truthy value", 2)
    end
end

local function assertFalse(value, message)
    if value then
        error(message or "expected falsey value", 2)
    end
end

local function assertContains(text, needle, message)
    if not tostring(text):find(needle, 1, true) then
        error((message or "missing text") .. ": " .. tostring(needle), 2)
    end
end

local function assertAnyMessageContains(needle)
    for index = #mock.messages, 1, -1 do
        if tostring(mock.messages[index]):find(needle, 1, true) then
            return
        end
    end
    error("missing chat message: " .. tostring(needle), 2)
end

local function test(name, fn)
    tests[#tests + 1] = { name = name, fn = fn }
end

mock = {
    frames = {},
    namedFrames = {},
    timers = {},
    messages = {},
    containerSlots = {},
    containerItems = {},
    items = {},
    itemLinks = {},
    badInstantItems = {},
    badInfoItems = {},
    badStatsItems = {},
    tableInfo = {},
    equippedItems = {},
    unequippableItems = {},
    badEquippableItems = {},
    talentTabs = {},
    unspentTalentPoints = 0,
    badTalentTabs = {},
    badTalentInfo = {},
    character = {},
    group = {},
    ratings = {},
}

local function itemLink(itemID, name, qualityColor)
    qualityColor = qualityColor or "ffffffff"
    return "|c" .. qualityColor .. "|Hitem:" .. itemID .. ":0:0:0:0:0:0:0|h[" .. name .. "]|h|r"
end

local function parseItemID(link)
    local itemID = tostring(link or ""):match("item:(%d+)")
    return itemID and tonumber(itemID) or nil
end

local function frameMethod(name, fn)
    return function(self, ...)
        self.calls = self.calls or {}
        self.calls[#self.calls + 1] = { name = name, args = { ... } }
        if fn then
            return fn(self, ...)
        end
    end
end

local function createMockFrame(frameType, name, parent, template)
    local frame = {
        frameType = frameType,
        name = name,
        parent = parent,
        template = template,
        scripts = {},
        events = {},
        points = {},
        children = {},
        shown = true,
    }

    frame.RegisterEvent = frameMethod("RegisterEvent", function(self, eventName)
        if eventName == "FAIL_EVENT" then
            error("mock register failure")
        end
        self.events[eventName] = true
    end)
    frame.SetScript = frameMethod("SetScript", function(self, scriptName, fn)
        self.scripts[scriptName] = fn
    end)
    frame.GetScript = function(self, scriptName)
        return self.scripts[scriptName]
    end
    frame.SetSize = frameMethod("SetSize", function(self, width, height)
        self.width = width
        self.height = height
    end)
    frame.SetWidth = frameMethod("SetWidth", function(self, width)
        self.width = width
    end)
    frame.SetHeight = frameMethod("SetHeight", function(self, height)
        self.height = height
    end)
    frame.SetPoint = frameMethod("SetPoint", function(self, ...)
        self.points[#self.points + 1] = { ... }
    end)
    frame.SetFrameStrata = frameMethod("SetFrameStrata", function(self, strata)
        self.frameStrata = strata
    end)
    frame.SetFrameLevel = frameMethod("SetFrameLevel", function(self, level)
        self.frameLevel = level
    end)
    frame.GetFrameLevel = function(self)
        return self.frameLevel or 1
    end
    frame.SetMovable = frameMethod("SetMovable", function(self, movable)
        self.movable = movable
    end)
    frame.EnableMouse = frameMethod("EnableMouse", function(self, enabled)
        self.mouseEnabled = enabled
    end)
    frame.RegisterForDrag = frameMethod("RegisterForDrag", function(self, button)
        self.dragButton = button
    end)
    frame.StartMoving = frameMethod("StartMoving", function(self)
        self.moving = true
    end)
    frame.StopMovingOrSizing = frameMethod("StopMovingOrSizing", function(self)
        self.moving = false
    end)
    frame.Hide = frameMethod("Hide", function(self)
        self.shown = false
    end)
    frame.Show = frameMethod("Show", function(self)
        self.shown = true
    end)
    frame.IsShown = function(self)
        return self.shown
    end
    frame.SetBackdrop = frameMethod("SetBackdrop", function(self, backdrop)
        self.backdrop = backdrop
    end)
    frame.SetBackdropColor = frameMethod("SetBackdropColor", function(self, ...)
        self.backdropColor = { ... }
    end)
    frame.SetBackdropBorderColor = frameMethod("SetBackdropBorderColor", function(self, ...)
        self.backdropBorderColor = { ... }
    end)
    frame.CreateFontString = frameMethod("CreateFontString", function(self)
        local fontString = createMockFrame("FontString", nil, self, nil)
        fontString.SetText = frameMethod("SetText", function(target, text)
            target.text = text
        end)
        fontString.SetJustifyH = frameMethod("SetJustifyH", function(target, value)
            target.justifyH = value
        end)
        self.children[#self.children + 1] = fontString
        return fontString
    end)
    frame.SetText = frameMethod("SetText", function(self, text)
        self.text = text
        if self.scripts.OnTextChanged then
            self.scripts.OnTextChanged(self)
        end
    end)
    frame.GetText = function(self)
        return self.text
    end
    frame.SetMultiLine = frameMethod("SetMultiLine", function(self, value)
        self.multiLine = value
    end)
    frame.SetAutoFocus = frameMethod("SetAutoFocus", function(self, value)
        self.autoFocus = value
    end)
    frame.SetFontObject = frameMethod("SetFontObject", function(self, value)
        self.fontObject = value
    end)
    frame.SetCursorPosition = frameMethod("SetCursorPosition", function(self, value)
        self.cursorPosition = value
    end)
    frame.HighlightText = frameMethod("HighlightText", function(self)
        self.highlighted = true
    end)
    frame.SetFocus = frameMethod("SetFocus", function(self)
        self.focused = true
    end)
    frame.ClearFocus = frameMethod("ClearFocus", function(self)
        self.focused = false
    end)
    frame.GetNumLines = function(self)
        local _, breaks = tostring(self.text or ""):gsub("\n", "\n")
        return breaks + 1
    end
    frame.SetScrollChild = frameMethod("SetScrollChild", function(self, child)
        self.scrollChild = child
    end)
    frame.RegisterForClicks = frameMethod("RegisterForClicks", function(self, ...)
        self.clicks = { ... }
    end)
    frame.CreateTexture = frameMethod("CreateTexture", function(self, name, layer)
        local texture = createMockFrame("Texture", name, self, nil)
        texture.layer = layer
        texture.SetTexture = frameMethod("SetTexture", function(target, value)
            target.texture = value
        end)
        texture.SetTexCoord = frameMethod("SetTexCoord", function(target, ...)
            target.texCoord = { ... }
        end)
        self.children[#self.children + 1] = texture
        return texture
    end)

    mock.frames[#mock.frames + 1] = frame
    if name then
        mock.namedFrames[name] = frame
    end

    return frame
end

local function setContainerItem(bagID, slotID, itemID, count)
    mock.containerSlots[bagID] = math.max(mock.containerSlots[bagID] or 0, slotID)
    mock.containerItems[bagID] = mock.containerItems[bagID] or {}
    mock.containerItems[bagID][slotID] = { itemID = itemID, count = count or 1 }
end

local function addItem(item)
    item.link = item.link or itemLink(item.id, item.name, item.color)
    mock.items[item.id] = item
    mock.itemLinks[item.id] = item.link
end

local function resetTalentMock()
    mock.unspentTalentPoints = 0
    mock.badTalentTabs = {}
    mock.badTalentInfo = {}
    mock.talentTabs = {
        {
            name = "Balance",
            icon = "Interface\\Icons\\Spell_Nature_StarFall",
            points = 0,
            background = "DruidBalance",
            talents = {},
        },
        {
            name = "Feral Combat",
            icon = "Interface\\Icons\\Ability_Racial_BearForm",
            points = 46,
            background = "DruidFeral",
            talents = {
                { name = "Ferocity", icon = "Interface\\Icons\\Ability_Hunter_Pet_Hyena", tier = 1, column = 2, rank = 5, maxRank = 5 },
                { name = "Thick Hide", icon = "Interface\\Icons\\INV_Misc_Pelt_Bear_03", tier = 2, column = 3, rank = 3, maxRank = 3 },
                { name = "Leader of the Pack", icon = "Interface\\Icons\\Spell_Nature_UnyeildingStamina", tier = 5, column = 2, rank = 1, maxRank = 1, isExceptional = true },
            },
        },
        {
            name = "Restoration",
            icon = "Interface\\Icons\\Spell_Nature_HealingTouch",
            points = 15,
            background = "DruidRestoration",
            talents = {
                { name = "Furor", icon = "Interface\\Icons\\Spell_Holy_BlessingOfStamina", tier = 1, column = 2, rank = 5, maxRank = 5 },
                { name = "Naturalist", icon = "Interface\\Icons\\Spell_Nature_HealingTouch", tier = 2, column = 3, rank = 5, maxRank = 5 },
            },
        },
    }
end

local function resetCharacterMock()
    mock.character = {
        raceLocalized = "Tauren",
        raceEnglish = "TAUREN",
        raceID = 6,
        faction = "Horde",
        factionLocalized = "Horde",
        level = 70,
        attributes = {
            [1] = { base = 90, effective = 130, positive = 40, negative = 0 },
            [2] = { base = 110, effective = 180, positive = 70, negative = 0 },
            [3] = { base = 140, effective = 520, positive = 380, negative = 0 },
            [4] = { base = 95, effective = 240, positive = 145, negative = 0 },
            [5] = { base = 80, effective = 170, positive = 90, negative = 0 },
        },
        armor = { base = 12000, effective = 13500, armor = 13500, positive = 1500, negative = 0 },
        defense = { base = 350, modifier = 145 },
        attackPower = { base = 900, positive = 120, negative = -20 },
        rangedAttackPower = { base = 500, positive = 60, negative = 0 },
        meleeCrit = 28.5,
        rangedCrit = 31,
        dodge = 35,
        parry = 0,
        block = 0,
        spellCrit = { [2] = 3, [3] = 8.25, [4] = 7.5, [5] = 6, [6] = 19.25, [7] = 13.5 },
        spellDamage = { [2] = 120, [3] = 260, [4] = 250, [5] = 180, [6] = 400, [7] = 320 },
        healing = 900,
        manaRegenCasting = 82,
        manaRegenNotCasting = 126,
    }
    mock.group = {
        inRaid = true,
        inGroup = true,
        raidMembers = 25,
        partyMembers = 4,
    }
    mock.ratings = {
        [_G.CR_DEFENSE_SKILL or 1] = { rating = 225, bonus = 25 },
        [_G.CR_DODGE or 2] = { rating = 44, bonus = 2.1 },
        [_G.CR_PARRY or 3] = { rating = 0, bonus = 0 },
        [_G.CR_BLOCK or 4] = { rating = 0, bonus = 0 },
        [_G.CR_HIT_MELEE or 5] = { rating = 134, bonus = 8.5 },
        [_G.CR_HIT_RANGED or 6] = { rating = 142, bonus = 9 },
        [_G.CR_HIT_SPELL or 7] = { rating = 155, bonus = 12.25 },
        [_G.CR_CRIT_MELEE or 8] = { rating = 86, bonus = 3.9 },
        [_G.CR_CRIT_RANGED or 9] = { rating = 92, bonus = 4.1 },
        [_G.CR_CRIT_SPELL or 10] = { rating = 76, bonus = 3.4 },
        [_G.CR_HASTE_MELEE or 11] = { rating = 0, bonus = 0 },
        [_G.CR_HASTE_RANGED or 12] = { rating = 0, bonus = 0 },
        [_G.CR_HASTE_SPELL or 13] = { rating = 0, bonus = 0 },
        [_G.CR_EXPERTISE or 14] = { rating = 16, bonus = 4 },
        [_G.CR_RESILIENCE_PLAYER_DAMAGE_TAKEN or 15] = { rating = 0, bonus = 0 },
    }
end

local function installGlobals()
    _G.TBCGearExporterTestMode = true
    _G.BANK_CONTAINER = -1
    _G.NUM_BAG_SLOTS = 4
    _G.NUM_BANKBAGSLOTS = 7
    _G.BackdropTemplateMixin = {}
    _G.UIParent = createMockFrame("UIParent", "UIParent")
    _G.Minimap = createMockFrame("Frame", "Minimap")
    _G.Minimap.frameLevel = 4
    _G.ChatFontNormal = {}
    _G.GameFontNormalLarge = {}
    _G.GameFontHighlightSmall = {}
    _G.UIPanelCloseButton = {}
    _G.UIPanelButtonTemplate = {}
    _G.UIPanelScrollFrameTemplate = {}
    _G.SlashCmdList = {}
    _G.ITEM_QUALITY3_DESC = "Rare"
    _G.ITEM_QUALITY4_DESC = "Epic"
    _G.ITEM_MOD_CUSTOM_POWER_SHORT = "+%d Custom Power"
    _G.CR_DEFENSE_SKILL = 1
    _G.CR_DODGE = 2
    _G.CR_PARRY = 3
    _G.CR_BLOCK = 4
    _G.CR_HIT_MELEE = 5
    _G.CR_HIT_RANGED = 6
    _G.CR_HIT_SPELL = 7
    _G.CR_CRIT_MELEE = 8
    _G.CR_CRIT_RANGED = 9
    _G.CR_CRIT_SPELL = 10
    _G.CR_HASTE_MELEE = 11
    _G.CR_HASTE_RANGED = 12
    _G.CR_HASTE_SPELL = 13
    _G.CR_EXPERTISE = 14
    _G.CR_RESILIENCE_PLAYER_DAMAGE_TAKEN = 15
    resetCharacterMock()

    _G.DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, message)
            mock.messages[#mock.messages + 1] = message
        end,
    }

    _G.GameTooltip = {
        lines = {},
        SetOwner = function(self, owner, anchor)
            self.owner = owner
            self.anchor = anchor
        end,
        SetText = function(self, text)
            self.text = text
        end,
        SetHyperlink = function(self, link)
            self.hyperlink = link
        end,
        AddLine = function(self, text)
            self.lines[#self.lines + 1] = text
        end,
        Show = function(self)
            self.shown = true
        end,
        Hide = function(self)
            self.shown = false
        end,
    }

    _G.CreateFrame = function(frameType, name, parent, template)
        return createMockFrame(frameType, name, parent, template)
    end

    _G.GetRealmName = function()
        return "Test Realm"
    end

    _G.UnitName = function(unit)
        if unit == "player" then
            return "Tester"
        end
        return "Unit"
    end

    _G.UnitClass = function(unit)
        if unit == "player" then
            return "Druid", "DRUID", 11
        end

        return "Unknown", "UNKNOWN", nil
    end

    _G.UnitRace = function(unit)
        if unit == "player" then
            return mock.character.raceLocalized, mock.character.raceEnglish, mock.character.raceID
        end
        return "Unknown", "UNKNOWN", nil
    end

    _G.UnitFactionGroup = function(unit)
        if unit == "player" then
            return mock.character.faction, mock.character.factionLocalized
        end
        return nil, nil
    end

    _G.IsInRaid = function()
        return mock.group.inRaid
    end

    _G.IsInGroup = function()
        return mock.group.inGroup
    end

    _G.GetNumGroupMembers = function()
        return mock.group.raidMembers or 0
    end

    _G.GetNumSubgroupMembers = function()
        return mock.group.partyMembers or 0
    end

    _G.GetNumRaidMembers = function()
        return mock.group.legacyRaidMembers or mock.group.raidMembers or 0
    end

    _G.GetNumPartyMembers = function()
        return mock.group.legacyPartyMembers or mock.group.partyMembers or 0
    end

    _G.UnitLevel = function(unit)
        return unit == "player" and mock.character.level or nil
    end

    _G.UnitStat = function(unit, index)
        local stat = unit == "player" and mock.character.attributes[index] or nil
        if not stat then
            return nil
        end
        return stat.base, stat.effective, stat.positive, stat.negative
    end

    _G.UnitArmor = function(unit)
        local armor = unit == "player" and mock.character.armor or nil
        if not armor then
            return nil
        end
        return armor.base, armor.effective, armor.armor, armor.positive, armor.negative
    end

    _G.UnitDefense = function(unit)
        if unit == "player" then
            return mock.character.defense.base, mock.character.defense.modifier
        end
        return nil
    end

    _G.UnitAttackPower = function(unit)
        if unit == "player" then
            return mock.character.attackPower.base, mock.character.attackPower.positive, mock.character.attackPower.negative
        end
        return nil
    end

    _G.UnitRangedAttackPower = function(unit)
        if unit == "player" then
            return mock.character.rangedAttackPower.base, mock.character.rangedAttackPower.positive, mock.character.rangedAttackPower.negative
        end
        return nil
    end

    _G.GetCombatRating = function(ratingID)
        local rating = mock.ratings[ratingID]
        return rating and rating.rating or nil
    end

    _G.GetCombatRatingBonus = function(ratingID)
        local rating = mock.ratings[ratingID]
        return rating and rating.bonus or nil
    end

    _G.GetCritChance = function()
        return mock.character.meleeCrit
    end

    _G.GetRangedCritChance = function()
        return mock.character.rangedCrit
    end

    _G.GetDodgeChance = function()
        return mock.character.dodge
    end

    _G.GetParryChance = function()
        return mock.character.parry
    end

    _G.GetBlockChance = function()
        return mock.character.block
    end

    _G.GetSpellCritChance = function(index)
        return mock.character.spellCrit[index]
    end

    _G.GetSpellBonusDamage = function(index)
        return mock.character.spellDamage[index]
    end

    _G.GetSpellBonusHealing = function()
        return mock.character.healing
    end

    _G.GetManaRegen = function()
        return mock.character.manaRegenCasting, mock.character.manaRegenNotCasting
    end

    resetTalentMock()

    _G.GetNumTalentTabs = function()
        return #mock.talentTabs
    end

    _G.GetTalentTabInfo = function(tabIndex)
        if mock.badTalentTabs[tabIndex] then
            error("talent tab failure")
        end

        local tab = mock.talentTabs[tabIndex]
        if not tab then
            return nil
        end

        return tab.name, tab.icon, tab.points, tab.background
    end

    _G.GetNumTalents = function(tabIndex)
        local tab = mock.talentTabs[tabIndex]
        return tab and #(tab.talents or {}) or 0
    end

    _G.GetTalentInfo = function(tabIndex, talentIndex)
        if mock.badTalentInfo[tabIndex .. ":" .. talentIndex] then
            error("talent info failure")
        end

        local tab = mock.talentTabs[tabIndex]
        local talent = tab and tab.talents and tab.talents[talentIndex]
        if not talent then
            return nil
        end

        return talent.name,
            talent.icon,
            talent.tier,
            talent.column,
            talent.rank,
            talent.maxRank,
            talent.isExceptional,
            talent.meetsPrereq
    end

    _G.UnitCharacterPoints = function(unit)
        if unit == "player" then
            return mock.unspentTalentPoints
        end
        return 0
    end

    _G.GetLocale = function()
        return "zhCN"
    end

    _G.GetServerTime = function()
        return 1700000000
    end

    _G.time = function()
        return 1700000001
    end

    _G.date = function(format, timestamp)
        return "formatted(" .. tostring(format) .. "," .. tostring(timestamp) .. ")"
    end

    _G.C_Timer = {
        After = function(delay, callback)
            mock.timers[#mock.timers + 1] = { delay = delay, callback = callback }
        end,
    }

    _G.GetInventoryItemLink = function(unit, slotID)
        local itemID = unit == "player" and mock.equippedItems[slotID] or nil
        local item = itemID and mock.items[itemID]
        return item and item.link or nil
    end

    _G.GetInventoryItemTexture = function(unit, slotID)
        local itemID = unit == "player" and mock.equippedItems[slotID] or nil
        local item = itemID and mock.items[itemID]
        return item and item.icon or nil
    end

    _G.IsEquippableItem = function(link)
        local itemID = parseItemID(link)
        if mock.badEquippableItems[itemID] then
            error("equippable failure")
        end
        return not mock.unequippableItems[itemID]
    end

    _G.GetContainerNumSlots = function(bagID)
        return mock.containerSlots[bagID] or 0
    end

    _G.GetContainerItemInfo = function(bagID, slotID)
        local bag = mock.containerItems[bagID]
        local entry = bag and bag[slotID]
        if not entry then
            return nil, nil, nil, nil, nil, nil, nil
        end

        local item = mock.items[entry.itemID]
        if mock.tableInfo[bagID .. ":" .. slotID] then
            return {
                texture = item.icon,
                stackCount = entry.count,
                itemQuality = item.quality,
                hyperlink = item.link,
            }
        end

        if entry.omitInfoLink then
            return item.icon, entry.count, false, item.quality, false, false, nil
        end

        return item.icon, entry.count, false, item.quality, false, false, item.link
    end

    _G.GetContainerItemLink = function(bagID, slotID)
        local bag = mock.containerItems[bagID]
        local entry = bag and bag[slotID]
        local item = entry and mock.items[entry.itemID]
        return item and item.link or nil
    end

    _G.C_Container = {
        GetContainerNumSlots = function(bagID)
            return mock.containerSlots[bagID] or 0
        end,
        GetContainerItemInfo = function(bagID, slotID)
            local bag = mock.containerItems[bagID]
            local entry = bag and bag[slotID]
            if not entry then
                return nil
            end

            local item = mock.items[entry.itemID]
            return {
                iconFileID = item.icon,
                stackCount = entry.count,
                quality = item.quality,
                hyperlink = entry.omitInfoLink and nil or item.link,
                itemID = item.id,
            }
        end,
        GetContainerItemLink = function(bagID, slotID)
            local bag = mock.containerItems[bagID]
            local entry = bag and bag[slotID]
            local item = entry and mock.items[entry.itemID]
            return item and item.link or nil
        end,
    }

    _G.GetItemInfoInstant = function(link)
        local itemID = parseItemID(link)
        if mock.badInstantItems[itemID] then
            error("instant item failure")
        end

        local item = assert(mock.items[itemID], "missing instant item " .. tostring(itemID))
        return item.id, item.itemType, item.itemSubType, item.equipSlot, item.icon, item.classID, item.subClassID
    end

    _G.GetItemInfo = function(link)
        local itemID = parseItemID(link)
        if mock.badInfoItems[itemID] then
            error("item info failure")
        end

        local item = assert(mock.items[itemID], "missing item info " .. tostring(itemID))
        return item.name,
            item.link,
            item.quality,
            item.itemLevel,
            item.requiredLevel,
            item.itemType,
            item.itemSubType,
            item.maxStack,
            item.equipSlot,
            item.icon,
            item.sellPrice
    end

    _G.GetItemStats = function(link, rawStats)
        local itemID = parseItemID(link)
        if mock.badStatsItems[itemID] then
            error("stats failure")
        end

        local item = mock.items[itemID] or {}
        local stats = item.stats or {}
        rawStats = rawStats or {}

        for token, value in pairs(stats) do
            rawStats[token] = value
        end

        if item.returnStatsTable then
            return rawStats
        end

        return nil
    end

    _G.GetItemStatInfo = function(token)
        if token == "ITEM_MOD_DYNAMIC_SHORT" then
            return "+%d Dynamic Stat"
        end
        if token == "ITEM_MOD_BLANK_SHORT" then
            return "   "
        end
        return nil
    end
end

local function flushTimers()
    local timers = mock.timers
    mock.timers = {}

    for index = 1, #timers do
        timers[index].callback()
    end
end

local function resetRuntimeState(Addon)
    mock.messages = {}
    mock.timers = {}
    mock.equippedItems = { [1] = 6001 }
    mock.unequippableItems = {}
    mock.badEquippableItems = {}
    resetTalentMock()
    resetCharacterMock()
    _G.TBCGearExporterDB = nil
    Addon.db = nil
    Addon.pendingBagScan = nil
    Addon.pendingBankScan = nil
    Addon.bankOpen = nil
    Addon.exportFrame = nil
    Addon.exportScope = nil
    Addon.exportFormat = nil
    Addon.exportFilter = nil
    Addon.exportView = nil
    Addon.minimapButton = nil
    if _G.GameTooltip then
        _G.GameTooltip.lines = {}
        _G.GameTooltip.text = nil
        _G.GameTooltip.hyperlink = nil
        _G.GameTooltip.owner = nil
        _G.GameTooltip.shown = nil
    end
    SlashCmdList.TBCGEAREXPORTER = nil
    SLASH_TBCGEAREXPORTER1 = nil
    SLASH_TBCGEAREXPORTER2 = nil
end

installGlobals()

addItem({
    id = 1001,
    name = "Defender Helm",
    color = "ff0070dd",
    quality = 3,
    itemLevel = 115,
    requiredLevel = 70,
    itemType = "Armor",
    itemSubType = "Plate",
    classID = 4,
    subClassID = 4,
    equipSlot = "INVTYPE_HEAD",
    maxStack = 1,
    icon = "helm-icon",
    sellPrice = 12345,
    stats = {
        ITEM_MOD_STAMINA_SHORT = 27,
        ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 25,
        EMPTY_SOCKET_RED = 1,
        EMPTY_SOCKET_BLUE = 1,
    },
})

addItem({
    id = 1002,
    name = "Arcane Blade",
    color = "ffa335ee",
    quality = 4,
    itemLevel = 120,
    requiredLevel = 70,
    itemType = "Weapon",
    itemSubType = "Sword",
    classID = 2,
    subClassID = 7,
    equipSlot = "INVTYPE_WEAPON",
    maxStack = 1,
    icon = "blade-icon",
    sellPrice = 54321,
    returnStatsTable = true,
    stats = {
        ITEM_MOD_SPELL_POWER_SHORT = 121,
        ITEM_MOD_CUSTOM_POWER_SHORT = 9,
        ITEM_MOD_DYNAMIC_SHORT = 4,
        ITEM_MOD_BLANK_SHORT = 3,
    },
})

addItem({
    id = 2001,
    name = "Super Mana Potion",
    color = "ffffffff",
    quality = 1,
    itemLevel = 68,
    requiredLevel = 60,
    itemType = "Consumable",
    itemSubType = "Potion",
    classID = 0,
    subClassID = 1,
    equipSlot = "INVTYPE_NON_EQUIP_IGNORE",
    maxStack = 20,
    icon = "potion-icon",
    sellPrice = 500,
    stats = {},
})

addItem({
    id = 3001,
    name = "Living Ruby",
    color = "ff0070dd",
    quality = 3,
    itemLevel = 70,
    requiredLevel = 0,
    itemType = "Gem",
    itemSubType = "Red",
    classID = 3,
    subClassID = 0,
    equipSlot = "",
    maxStack = 20,
    icon = "ruby-icon",
    sellPrice = 10000,
    stats = { ITEM_MOD_CRIT_RATING_SHORT = 8 },
})

addItem({
    id = 4001,
    name = "Schematic: Test Scope",
    color = "ff1eff00",
    quality = 2,
    itemLevel = 60,
    requiredLevel = 0,
    itemType = "Recipe",
    itemSubType = "Engineering",
    classID = 9,
    subClassID = 4,
    equipSlot = "",
    maxStack = 1,
    icon = "recipe-icon",
    sellPrice = 2500,
    stats = {},
})

addItem({
    id = 5001,
    name = "Unknown Cache Item",
    color = "ffffffff",
    quality = 1,
    itemLevel = nil,
    requiredLevel = nil,
    itemType = "Miscellaneous",
    itemSubType = "",
    classID = 15,
    subClassID = 0,
    equipSlot = "",
    maxStack = 1,
    icon = "misc-icon",
    sellPrice = 0,
    stats = { ITEM_MOD_NEGATIVE_SHORT = -5 },
})

addItem({
    id = 6001,
    name = "Worn Leather Cap",
    color = "ff1eff00",
    quality = 2,
    itemLevel = 80,
    requiredLevel = 70,
    itemType = "Armor",
    itemSubType = "Leather",
    classID = 4,
    subClassID = 2,
    equipSlot = "INVTYPE_HEAD",
    maxStack = 1,
    icon = "worn-cap-icon",
    sellPrice = 1000,
    stats = { ITEM_MOD_STAMINA_SHORT = 10, ITEM_MOD_AGILITY_SHORT = 5 },
})

addItem({
    id = 6002,
    name = "Guardian Leather Crown",
    color = "ffa335ee",
    quality = 4,
    itemLevel = 128,
    requiredLevel = 70,
    itemType = "Armor",
    itemSubType = "Leather",
    classID = 4,
    subClassID = 2,
    equipSlot = "INVTYPE_HEAD",
    maxStack = 1,
    icon = "guardian-crown-icon",
    sellPrice = 24000,
    stats = { ITEM_MOD_STAMINA_SHORT = 36, ITEM_MOD_AGILITY_SHORT = 24, ITEM_MOD_ARMOR = 420 },
})

addItem({
    id = 6003,
    name = "Feral Grips",
    color = "ff0070dd",
    quality = 3,
    itemLevel = 115,
    requiredLevel = 70,
    itemType = "Armor",
    itemSubType = "Leather",
    classID = 4,
    subClassID = 2,
    equipSlot = "INVTYPE_HAND",
    maxStack = 1,
    icon = "feral-grips-icon",
    sellPrice = 16000,
    stats = { ITEM_MOD_STAMINA_SHORT = 22, ITEM_MOD_AGILITY_SHORT = 18, ITEM_MOD_HIT_RATING_SHORT = 12 },
})

addItem({
    id = 6004,
    name = "Forbidden Shield",
    color = "ffa335ee",
    quality = 4,
    itemLevel = 141,
    requiredLevel = 70,
    itemType = "Armor",
    itemSubType = "Shield",
    classID = 4,
    subClassID = 6,
    equipSlot = "INVTYPE_SHIELD",
    maxStack = 1,
    icon = "shield-icon",
    sellPrice = 30000,
    stats = { ITEM_MOD_STAMINA_SHORT = 50, ITEM_MOD_BLOCK_VALUE_SHORT = 100 },
})

addItem({
    id = 6005,
    name = "Unusable Leather Hood",
    color = "ffa335ee",
    quality = 4,
    itemLevel = 150,
    requiredLevel = 70,
    itemType = "Armor",
    itemSubType = "Leather",
    classID = 4,
    subClassID = 2,
    equipSlot = "INVTYPE_HEAD",
    maxStack = 1,
    icon = "unusable-hood-icon",
    sellPrice = 35000,
    stats = { ITEM_MOD_STAMINA_SHORT = 90, ITEM_MOD_AGILITY_SHORT = 60 },
})

setContainerItem(0, 1, 1001, 1)
setContainerItem(0, 2, 2001, 5)
mock.containerSlots[0] = 3
setContainerItem(1, 1, 3001, 2)
setContainerItem(-1, 1, 1002, 1)
setContainerItem(5, 1, 4001, 1)
setContainerItem(98, 1, 1001, 1)
mock.containerItems[98][1].omitInfoLink = true
setContainerItem(99, 1, 2001, 3)
mock.tableInfo["99:1"] = true

loadExecutableLines()
debug.sethook(coverageHook, "l")
local chunk = assert(loadfile(ADDON_PATH))
chunk("TBCGearExporter")
local Addon = assert(_G.TBCGearExporter, "test mode did not expose addon")
local private = assert(Addon._testing, "test helpers missing")

local function ui(key, ...)
    return private.LForLocale("zhCN", key, ...)
end

local function addonRootFrame()
    for index = 1, #mock.frames do
        local frame = mock.frames[index]
        if frame.events.ADDON_LOADED or frame.scripts.OnEvent then
            return frame
        end
    end
    error("addon root frame not found")
end

test("addon registers ADDON_LOADED on load", function()
    assertTrue(addonRootFrame().events.ADDON_LOADED, "root addon frame should register ADDON_LOADED")
end)

test("toc targets current TBC Anniversary interface", function()
    local file = assert(io.open("TBCGearExporter/TBCGearExporter.toc", "r"))
    local toc = file:read("*a")
    file:close()
    assertContains(toc, "## Interface: 20505")
    assertContains(toc, "## Interface-BCC: 20505")
end)

test("addon registers bag and bank scan events after load", function()
    resetRuntimeState(Addon)
    Addon:OnAddonLoaded("TBCGearExporter")
    assertTrue(addonRootFrame().events.BAG_OPEN, "bag open should be registered")
    assertTrue(addonRootFrame().events.BANKFRAME_OPENED, "bank open should be registered")
    assertTrue(addonRootFrame().events.PLAYER_TALENT_UPDATE, "talent updates should be registered")
    assertTrue(addonRootFrame().events.CHARACTER_POINTS_CHANGED, "character point changes should be registered")
    assertTrue(addonRootFrame().events.PLAYER_EQUIPMENT_CHANGED, "equipment changes should be registered")
end)

test("private parsers handle links and nils", function()
    local link = mock.itemLinks[1001]
    assertEquals(private.ParseItemID(link), 1001)
    assertEquals(private.ParseItemID(nil), nil)
    assertContains(private.ParseItemString(link), "item:1001")
    assertEquals(private.ParseItemString(nil), nil)
    assertEquals(private.ParseItemName(link), "Defender Helm")
    assertEquals(private.ParseItemName(nil), nil)
    assertEquals(private.Trim("  export  "), "export")
end)

test("time helpers cover server, time, date, and fallback paths", function()
    assertEquals(private.Now(), 1700000000)

    local oldServerTime = _G.GetServerTime
    _G.GetServerTime = nil
    assertEquals(private.Now(), 1700000001)

    local oldTime = _G.time
    _G.time = nil
    assertEquals(private.Now(), 0)
    _G.time = oldTime
    _G.GetServerTime = oldServerTime

    assertEquals(private.FormatTime(nil), "never")
    assertEquals(private.FormatTime(0), "never")
    assertEquals(private.FormatTime(123), "formatted(%Y-%m-%d %H:%M:%S,123)")

    local oldDate = _G.date
    _G.date = nil
    assertEquals(private.FormatTime(123), "123")
    _G.date = oldDate
end)

test("quality and stat labels use every fallback path", function()
    assertEquals(private.QualityName(3), "Rare")
    assertEquals(private.QualityName(2), "Uncommon")
    assertEquals(private.QualityName(99), "Unknown")
    assertEquals(private.NormalizeQualityColorHex("|cff0070dd"), "#0070DD")
    assertEquals(private.NormalizeQualityColorHex("ff1eff00"), "#1EFF00")
    assertEquals(private.NormalizeQualityColorHex("#a335ee"), "#A335EE")
    assertEquals(private.NormalizeQualityColorHex("bad"), nil)
    assertEquals(private.ColorChannelToByte(0.5), 128)
    assertEquals(private.ColorChannelToByte(-1), 0)
    assertEquals(private.ColorChannelToByte(2), 255)
    assertEquals(private.ColorChannelToByte("blue"), nil)
    assertEquals(private.QualityColorHex(3), "#0070DD")
    assertEquals(private.QualityColorHex(99), nil)

    local oldQualityColors = _G.ITEM_QUALITY_COLORS
    _G.ITEM_QUALITY_COLORS = {
        [3] = { hex = "ff112233" },
        [4] = { r = 0.5, g = 0, b = 1 },
        [5] = "ffaa5500",
    }
    assertEquals(private.QualityColorHex(3), "#112233")
    assertEquals(private.QualityColorHex(4), "#8000FF")
    assertEquals(private.QualityColorHex(5), "#AA5500")
    _G.ITEM_QUALITY_COLORS = oldQualityColors

    assertEquals(private.ParseItemLinkColorHex(mock.itemLinks[1001]), "#0070DD")
    assertEquals(private.ItemQualityColorHex({ qualityColor = "#123456" }), "#123456")
    assertEquals(private.ItemQualityColorHex({ quality_color = "ff654321" }), "#654321")
    assertEquals(private.ItemQualityColorHex({ quality_id = 4 }), "#A335EE")
    assertEquals(private.ItemQualityColorHex({ item_link = mock.itemLinks[1002] }), "#A335EE")
    assertEquals(private.ItemQualityColorHex(nil), nil)
    assertEquals(private.ColorizeItemName("Defender Helm", "#0070DD"), "|cff0070ddDefender Helm|r")
    assertEquals(private.ItemColoredName({ name = "Defender Helm", quality = 3 }), "|cff0070ddDefender Helm|r")
    assertEquals(private.ItemColoredName({ name_colored = "|cff123456Saved|r" }), "|cff123456Saved|r")
    assertEquals(private.ItemColoredName(nil), "Unknown Item")
    assertEquals(private.HtmlEscape("<Gem & Gear>"), "&lt;Gem &amp; Gear&gt;")
    assertContains(private.MarkdownItemName({ name = "Defender Helm", quality = 3 }), "color:#0070DD")
    assertEquals(private.MarkdownItemName({ name = "Plain" }), "**Plain**")
    assertEquals(private.QualityDisplay({ qualityName = "Rare", quality = 3 }), "Rare (#0070DD)")
    assertEquals(private.QualityDisplay(nil), "Unknown")
    assertEquals(private.ItemLevelDisplay({ itemLevel = 115 }), "115")
    assertEquals(private.ItemLevelDisplay(nil), "unknown")
    assertEquals(private.ItemTypeDisplay({ itemType = "Armor", itemSubType = "Plate" }), "Armor / Plate")
    assertEquals(private.ItemTypeDisplay({ itemType = "Miscellaneous", itemSubType = "" }), "Miscellaneous")
    assertEquals(private.ItemTypeDisplay(nil), "Unknown")
    assertEquals(private.TitleCase("spell hit rating"), "Spell Hit Rating")
    assertEquals(private.CleanStatLabel("+%d Spell Damage  "), "Spell Damage")
    assertEquals(private.StatLabel("ITEM_MOD_STAMINA_SHORT"), "Stamina")
    assertEquals(private.StatLabel("ITEM_MOD_CUSTOM_POWER_SHORT"), "Custom Power")
    assertEquals(private.StatLabel("ITEM_MOD_DYNAMIC_SHORT"), "Dynamic Stat")
    assertEquals(private.StatLabel("ITEM_MOD_UNKNOWN_RATING_SHORT"), "Unknown Rating")
    assertEquals(private.StatLabel(nil), "Unknown Stat")
end)

test("stat list handles missing API, errors, table returns, sorting, and formatting", function()
    assertEquals(#private.BuildStatList(nil), 0)

    local oldGetItemStats = _G.GetItemStats
    _G.GetItemStats = nil
    assertEquals(#private.BuildStatList(mock.itemLinks[1001]), 0)
    _G.GetItemStats = oldGetItemStats

    mock.badStatsItems[1001] = true
    assertEquals(#private.BuildStatList(mock.itemLinks[1001]), 0)
    mock.badStatsItems[1001] = nil

    local stats = private.BuildStatList(mock.itemLinks[1001])
    assertEquals(stats[1].token, "ITEM_MOD_STAMINA_SHORT")
    assertEquals(stats[2].token, "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT")
    assertContains(private.FormatStats(stats), "+27 Stamina")
    assertContains(private.FormatStats(stats), "Red Socket")
    assertEquals(private.FormatStats({}), "none")
    assertEquals(private.FormatStats(nil), "none")
    assertContains(private.FormatStats({ { label = "Penalty", value = -3 } }), "-3 Penalty")

    local tableStats = private.BuildStatList(mock.itemLinks[1002])
    local formatted = private.FormatStats(tableStats)
    assertContains(formatted, "+121 Spell Power")
    assertContains(formatted, "+9 Custom Power")
    assertContains(formatted, "+4 Dynamic Stat")
    assertContains(formatted, "+3 Blank")
end)

test("chart stats aggregate inventory counts, levels, and stat totals", function()
    local chartStats = private.BuildChartStats({
        { source = "bags", count = 0, category = "Gear", quality = 3, qualityName = "Rare", equipSlot = "INVTYPE_HEAD", itemLevel = 100, stats = { { token = "ITEM_MOD_STAMINA_SHORT", label = "Stamina", value = 10 } } },
        { source = "bags", count = 2, category = "Gear", quality = 3, qualityName = "Rare", equipSlot = "INVTYPE_HEAD", itemLevel = 120, stats = { { token = "ITEM_MOD_STAMINA_SHORT", label = "Stamina", value = 5 } } },
        { source = "guild", count = 1, category = "Zzz", qualityName = "Custom B", equipSlot = "", itemLevel = 80, stats = { { token = "ITEM_MOD_CUSTOM_POWER_SHORT", label = "Custom Power", value = 1 } } },
        { source = "", count = nil, category = "Zzz", qualityName = "Custom A", equipSlot = "", itemLevel = nil, stats = { { label = "Mystery", value = "2" } } },
    })

    assertEquals(private.NormalizedStackCount(nil), 1)
    assertEquals(private.NormalizedStackCount(0), 1)
    assertEquals(private.RoundedStatNumber(86.666), 86.67)
    assertEquals(chartStats.itemCount, 4)
    assertEquals(chartStats.stackCount, 5)
    assertEquals(chartStats.gearItemCount, 2)
    assertEquals(chartStats.gearStackCount, 3)
    assertEquals(chartStats.equippableItemCount, 2)
    assertEquals(chartStats.itemLevel.count, 3)
    assertEquals(chartStats.itemLevel.min, 80)
    assertEquals(chartStats.itemLevel.max, 120)
    assertEquals(chartStats.itemLevel.average, 100)
    assertEquals(chartStats.sourceCounts[1].source, "bags")
    assertEquals(chartStats.sourceCounts[1].itemCount, 2)
    assertEquals(chartStats.sourceCounts[1].stackCount, 3)
    assertEquals(chartStats.categoryCounts[1].name, "Gear")
    assertEquals(chartStats.qualityCounts[1].quality, "Rare")
    assertEquals(chartStats.qualityCounts[2].quality, "Custom A")
    assertEquals(chartStats.equipSlotCounts[1].slot, "INVTYPE_HEAD")
    assertEquals(chartStats.statTotals[1].token, "ITEM_MOD_STAMINA_SHORT")
    assertEquals(chartStats.statTotals[1].value, 20)
    assertContains(private.ChartCountLine("Bags", chartStats.sourceCounts[1], "enUS"), "Bags: 2 item lines; 3 stacks")
    assertContains(private.ChartCountLine("背包", chartStats.sourceCounts[1], "zhCN"), "背包: 2 条物品; 3 件总数")
    assertContains(private.ChartStatLine(chartStats.statTotals[1], "enUS"), "+20 Stamina")
    assertContains(private.ChartStatLine(chartStats.statTotals[1], "zhCN"), "+20 耐力")

    local emptyStats = private.BuildChartStats({})
    assertEquals(emptyStats.itemCount, 0)
    assertEquals(#emptyStats.statTotals, 0)
end)

test("json helpers create AI-safe values and fields", function()
    assertEquals(private.JsonString("A \"quote\"\nline"), "\"A \\\"quote\\\"\\nline\"")
    assertEquals(private.JsonValue(nil), "null")
    assertEquals(private.JsonValue(42), "42")
    assertEquals(private.JsonValue(true), "true")
    assertEquals(private.JsonValue(false), "false")
    assertEquals(private.JsonValue("gear"), "\"gear\"")
    assertEquals(private.JsonField("scope", "all", true), "\"scope\": \"all\",")
    assertEquals(private.ScopeTitle("gear"), "Gear Only")
    assertEquals(private.ScopeTitle("bags"), "Bags")
    assertEquals(private.NormalizeExportFormat(""), "ai")
    assertEquals(private.NormalizeExportFormat("md"), "markdown")
    assertEquals(private.NormalizeExportFormat("txt"), "text")
    assertEquals(private.NormalizeExportFormat("raw"), "json")
    assertEquals(private.NormalizeExportFormat("wat"), "ai")
    assertEquals(private.ExportFormatTitle("json"), "JSON")

    local lines = {}
    private.AppendIndented(lines, 2, "text")
    assertEquals(lines[1], "  text")
    private.AppendJsonStringArray(lines, 0, "values", { "a", "b" }, true)
    assertContains(table.concat(lines, "\n"), "\"values\": [")
    assertContains(table.concat(lines, "\n"), "\"b\"")
end)

test("export filters parse quality, scope, and format options", function()
    assertTrue(private.IsExportFormatToken("json"))
    assertFalse(private.IsExportFormatToken("epic"))
    assertEquals(#private.SplitWords(" gear epic json "), 3)
    assertEquals(private.NormalizeQualityID("epic"), 4)
    assertEquals(private.NormalizeQualityID("purple"), 4)
    assertEquals(private.NormalizeQualityID("q4"), 4)
    assertEquals(private.NormalizeQualityID("quality:rare"), 3)
    assertEquals(private.NormalizeQualityID("wat"), nil)

    local filter = private.NormalizeExportFilter("epic")
    assertEquals(filter.qualityID, 4)
    assertEquals(filter.qualityMin, nil)
    assertEquals(private.ExportFilterTitle(filter), "Epic only")
    assertTrue(private.ExportFilterHasCriteria(filter))

    filter = private.NormalizeExportFilter("rare+")
    assertEquals(filter.qualityID, nil)
    assertEquals(filter.qualityMin, 3)
    assertEquals(private.ExportFilterTitle(filter), "Rare+")

    filter = private.NormalizeExportFilter({ quality_id = "4" })
    assertEquals(filter.qualityID, 4)
    filter = private.NormalizeExportFilter({ quality_min = "rare" })
    assertEquals(filter.qualityMin, 3)
    assertFalse(private.ExportFilterHasCriteria("all"))
    assertEquals(private.ExportFilterTitle(nil), "All qualities")
    assertEquals(private.ItemQualityID({ quality_id = "4" }), 4)
    assertTrue(private.ExportFilterMatchesItem({ quality = 4 }, "epic"))
    assertFalse(private.ExportFilterMatchesItem({ quality = 3 }, "epic"))
    assertTrue(private.ExportFilterMatchesItem({ quality = 4 }, "rare+"))
    assertFalse(private.ExportFilterMatchesItem({ quality = 2 }, "rare+"))
    assertEquals(private.NormalizeExportScope("equipment"), "gear")
    assertEquals(private.NormalizeExportScope("bag"), "bags")
    assertEquals(private.NormalizeExportScope("wat"), "all")

    local scope, format, parsedFilter, recognized = private.ParseExportOptions("all", "gear epic json")
    assertEquals(scope, "gear")
    assertEquals(format, "json")
    assertEquals(parsedFilter.qualityID, 4)
    assertEquals(recognized, 3)

    scope, format, parsedFilter, recognized = private.ParseExportOptions("bags", "rare+ text only")
    assertEquals(scope, "bags")
    assertEquals(format, "text")
    assertEquals(parsedFilter.qualityMin, 3)
    assertEquals(recognized, 3)
end)

test("class-aware AI prompt covers Druid role lenses and fallback context", function()
    resetRuntimeState(Addon)
    local classInfo = private.GetPlayerClassInfo()
    assertEquals(classInfo.localized, "Druid")
    assertEquals(classInfo.english, "DRUID")
    assertEquals(classInfo.id, 11)
    assertEquals(private.ClientLocale(), "zhCN")
    assertEquals(private.PromptLocale("zhCN"), "zhCN")
    assertEquals(private.PromptLocale("zhTW"), "zhTW")
    assertEquals(private.PromptLocale("enGB"), "enUS")
    assertEquals(private.LocalizedScopeTitle("gear", "zhCN"), "仅装备")
    assertEquals(private.LocalizedScopeTitle("bags", "zhTW"), "背包")
    assertEquals(private.LocalizedScopeTitle("bank", "zhTW"), "銀行")
    assertEquals(private.LocalizedScopeTitle("gear", "zhTW"), "僅裝備")
    assertEquals(private.LocalizedScopeTitle("all", "zhTW"), "全部")
    assertEquals(private.LocalizedScopeTitle("bags", "enUS"), "Bags")
    assertEquals(private.LocalizedQualityName(4, "zhCN"), "史诗")
    assertEquals(private.LocalizedQualityName(3, "zhTW"), "精良")
    assertEquals(private.LocalizedExportFilterTitle({ qualityID = 4 }, "zhCN"), "仅史诗")
    assertEquals(private.LocalizedExportFilterTitle({ qualityID = 4 }, "zhTW"), "僅史詩")
    assertEquals(private.LocalizedExportFilterTitle({ qualityMin = 3 }, "zhTW"), "精良以上")
    assertEquals(private.LocalizedExportFilterTitle(nil, "zhCN"), "全部品质")
    assertEquals(private.LocalizedExportFilterTitle(nil, "zhTW"), "全部品質")
    assertEquals(private.LForLocale("zhCN", "scan_button"), "扫描背包")
    assertEquals(private.LForLocale("zhTW", "export_button"), "匯出")
    assertEquals(private.LForLocale("enGB", "scan_button"), "Scan Bags")
    assertEquals(private.LocalizedExportFormatTitle("text", "zhCN"), "文本")
    assertEquals(private.ClassToken("death knight"), "DEATH_KNIGHT")
    assertEquals(private.ClassToken(nil), "UNKNOWN")
    assertEquals(private.NormalizeQualityID(99), nil)
    assertEquals(private.ItemQualityID(nil), nil)

    local oldGetLocale = _G.GetLocale
    _G.GetLocale = nil
    assertEquals(private.ClientLocale(), "enUS")
    _G.GetLocale = function() return "" end
    assertEquals(private.ClientLocale(), "enUS")
    _G.GetLocale = function() error("locale failure") end
    assertEquals(private.ClientLocale(), "enUS")
    _G.GetLocale = oldGetLocale

    local profile = Addon:GetProfile()
    local prompt = private.BuildAIPrompt(profile, "gear", { qualityID = 4 }, 1)
    assertContains(prompt.text, "魔兽世界：燃烧的远征")
    assertContains(prompt.text, "角色：Tester - Test Realm（德鲁伊）")
    assertContains(prompt.text, "客户端语言：zhCN")
    assertContains(prompt.text, "导出范围：仅装备")
    assertContains(prompt.text, "过滤器：仅史诗")
    assertContains(prompt.text, "熊形态野性坦克")
    assertContains(prompt.text, "猎豹野性输出")
    assertContains(prompt.text, "恢复治疗")
    assertContains(prompt.text, "平衡法系输出")
    assertEquals(prompt.classToken, "DRUID")
    assertEquals(prompt.locale, "zhCN")
    assertEquals(prompt.promptLocale, "zhCN")
    assertTrue(#prompt.roleContext >= 4)
    assertTrue(#prompt.outputRequests >= 6)

    local englishPrompt = private.BuildAIPrompt({ player = "Tester", realm = "Test Realm", classLocalized = "Druid", classEnglish = "DRUID", locale = "enUS" }, "gear", { qualityID = 4 }, 1)
    assertContains(englishPrompt.text, "World of Warcraft: The Burning Crusade Classic")
    assertContains(englishPrompt.text, "Bear Feral tank")
    assertEquals(englishPrompt.promptLocale, "enUS")

    local traditionalPrompt = private.BuildAIPrompt({ player = "Tester", realm = "Test Realm", classLocalized = "德魯伊", classEnglish = "DRUID", locale = "zhTW" }, "gear", { qualityID = 4 }, 1)
    assertContains(traditionalPrompt.text, "魔獸世界：燃燒的遠征")
    assertContains(traditionalPrompt.text, "客戶端語言：zhTW")
    assertContains(traditionalPrompt.text, "匯出範圍：僅裝備")
    assertContains(traditionalPrompt.text, "職業職責分析視角")
    assertContains(traditionalPrompt.text, "熊形態野性坦克")
    assertEquals(traditionalPrompt.promptLocale, "zhTW")

    local unknownLocalePrompt = private.BuildAIPrompt({ player = "Tester", realm = "Test Realm", classLocalized = "Druid", classEnglish = "DRUID", locale = "deDE" }, "bags", nil, 0)
    assertContains(unknownLocalePrompt.text, "Client locale: deDE")
    assertContains(unknownLocalePrompt.text, "Export scope: Bags")

    local traditionalContext = private.LocalizedRoleContext("DRUID", "zhTW")
    assertContains(traditionalContext[1], "熊形態野性坦克")
    assertContains(private.LocalizedOutputRequests("zhCN")[1], "总结")
    assertContains(private.LocalizedOutputRequests("zhTW")[1], "總結")
    local fallback = private.ClassRoleContext("UNKNOWN")
    assertContains(fallback[1], "Primary role")
end)

test("location, source, category, copy, and sizing helpers cover branches", function()
    assertEquals(private.LocationLabel("bags", 0, 2, "enUS"), "Backpack slot 2")
    assertEquals(private.LocationLabel("bags", 3, 4, "enUS"), "Bag 3 slot 4")
    assertEquals(private.LocationLabel("bank", -1, 5, "enUS"), "Bank slot 5")
    assertEquals(private.LocationLabel("bank", 6, 7, "enUS"), "Bank bag 2 slot 7")
    assertEquals(private.LocationLabel("bags", 0, 2, "zhCN"), "背包第 2 格")
    assertEquals(private.LocationLabel("bank", 6, 7, "zhTW"), "銀行背包 2 第 7 格")
    assertEquals(private.SourceLabel("bags", "enUS"), "Bags")
    assertEquals(private.SourceLabel("bank", "zhCN"), "银行")
    assertEquals(private.SourceLabel("equipped", "zhCN"), "当前装备")
    assertEquals(private.SourceLabel(nil, "zhTW"), "未知")
    assertEquals(private.SourceLabel("guild", "enUS"), "guild")
    assertEquals(private.ItemLocationLabel({ source = "bags", bag = 0, slot = 3, location = "old" }, "zhCN"), "背包第 3 格")
    assertEquals(private.ItemLocationLabel(nil, "zhCN"), "未知位置")
    assertEquals(private.ItemLocationLabel({ source = "equipped", slotKey = "HEAD", location = "old" }, "zhCN"), "头部")
    assertEquals(private.ItemLocationLabel({ source = "guild", location = "Guild Vault" }, "zhCN"), "Guild Vault")
    assertEquals(private.ReportTerms("frFR").quick_summary, "Quick Summary")
    assertEquals(private.CategoryLabel("Gear", "zhCN"), "装备")
    assertEquals(private.CategoryLabel("Miscellaneous", "zhTW"), "雜項")
    assertEquals(private.CategoryLabel("Mystery", "zhCN"), "Mystery")
    assertEquals(private.LocalizedStatLabel({ token = "EMPTY_SOCKET_META", label = "Meta Socket" }, "zhTW"), "變換插槽")
    assertContains(private.FormatLocalizedStats({
        { token = "ITEM_MOD_STAMINA_SHORT", label = "Stamina", value = 12 },
        { token = "ITEM_MOD_RESILIENCE_RATING_SHORT", label = "Resilience", value = 5 },
    }, "zhCN"), "+12 耐力")
    assertEquals(private.FormatLocalizedStats({ { token = "EMPTY_SOCKET_RED", label = "Red Socket", value = 1 } }, "zhCN"), "红色插槽")
    assertEquals(private.FormatLocalizedStats({}, "zhTW"), "無")
    assertEquals(private.WowheadItemURL(1001), "https://www.wowhead.com/tbc/item=1001")
    assertEquals(private.WowheadItemURL("1002"), "https://www.wowhead.com/tbc/item=1002")
    assertEquals(private.WowheadItemURL("item:1002"), nil)
    assertEquals(private.WowheadItemURL(0), nil)
    assertEquals(private.ItemWowheadURL({ wowheadUrl = "https://example.test/item" }), "https://example.test/item")
    assertEquals(private.ItemWowheadURL({ wowhead_url = "https://example.test/snake" }), "https://example.test/snake")
    assertEquals(private.ItemWowheadURL({ item_id = 1002 }), "https://www.wowhead.com/tbc/item=1002")
    assertEquals(private.ItemWowheadURL(nil), nil)

    assertTrue(private.IsEquippableSlot("INVTYPE_HEAD"))
    assertFalse(private.IsEquippableSlot(""))
    assertFalse(private.IsEquippableSlot(nil))
    assertFalse(private.IsEquippableSlot("INVTYPE_NON_EQUIP"))
    assertFalse(private.IsEquippableSlot("INVTYPE_NON_EQUIP_IGNORE"))
    assertEquals(private.CategoryFromInfo(nil, nil, "INVTYPE_HEAD"), "Gear")
    assertEquals(private.CategoryFromInfo(0, "Consumable", "INVTYPE_NON_EQUIP_IGNORE"), "Consumables")
    assertEquals(private.CategoryFromInfo(nil, "Consumable", "INVTYPE_NON_EQUIP"), "Consumables")
    assertEquals(private.CategoryFromInfo(7, nil, ""), "Trade Goods")
    assertEquals(private.CategoryFromInfo(nil, "Weapon", ""), "Gear")
    assertEquals(private.CategoryFromInfo(nil, "Armor", ""), "Gear")
    assertEquals(private.CategoryFromInfo(nil, "Consumable", ""), "Consumables")
    assertEquals(private.CategoryFromInfo(nil, "Trade Goods", ""), "Trade Goods")
    assertEquals(private.CategoryFromInfo(nil, "Gem", ""), "Gems")
    assertEquals(private.CategoryFromInfo(nil, "Recipe", ""), "Recipes")
    assertEquals(private.CategoryFromInfo(nil, "Quest", ""), "Quest Items")
    assertEquals(private.CategoryFromInfo(nil, "Quest Item", ""), "Quest Items")
    assertEquals(private.CategoryFromInfo(nil, "Container", ""), "Containers")
    assertEquals(private.CategoryFromInfo(nil, "Quiver", ""), "Containers")
    assertEquals(private.CategoryFromInfo(nil, "Key", ""), "Keys")
    assertEquals(private.CategoryFromInfo(nil, "Projectile", ""), "Projectiles")
    assertEquals(private.CategoryFromInfo(nil, "Miscellaneous", ""), "Miscellaneous")
    assertEquals(private.CategoryFromInfo(nil, "Something New", ""), "Other")

    local copy = private.CopyItems({ "a", "b" })
    assertEquals(#copy, 2)
    assertEquals(private.CopyItems(nil)[1], nil)

    local withSetSize = {}
    withSetSize.SetSize = function(self, width, height)
        self.width = width
        self.height = height
    end
    private.SetFrameSize(withSetSize, 10, 20)
    assertEquals(withSetSize.width, 10)

    local withoutSetSize = {
        SetWidth = function(self, width)
            self.width = width
        end,
        SetHeight = function(self, height)
            self.height = height
        end,
    }
    private.SetFrameSize(withoutSetSize, 30, 40)
    assertEquals(withoutSetSize.height, 40)

    private.SafeRegister("FAIL_EVENT")
end)

test("container compatibility helpers use legacy, C_Container, and fallback paths", function()
    assertEquals(private.BackdropTemplate(), "BackdropTemplate")
    assertTrue(private.HasCContainer())
    assertTrue(private.HasLegacyContainer())
    assertEquals(private.ContainerApiName(), "C_Container")
    assertEquals(private.YesNo(true), "yes")
    assertEquals(private.YesNo(false), "no")
    assertEquals(private.GetContainerNumSlotsCompat(0), 3)
    assertContains(private.GetContainerItemLinkCompat(0, 1), "Defender Helm")
    local texture, count, quality, link = private.ValuesFromContainerInfo({
        iconFileID = "compat-icon",
        stackCount = 9,
        quality = 4,
    }, mock.itemLinks[1002])
    assertEquals(texture, "compat-icon")
    assertEquals(count, 9)
    assertEquals(quality, 4)
    assertContains(link, "Arcane Blade")
    local _, _, _, itemIDLink = private.ValuesFromContainerInfo({ itemID = 7777 }, nil)
    assertEquals(itemIDLink, "item:7777")

    local oldLegacySlots = _G.GetContainerNumSlots
    _G.GetContainerNumSlots = function()
        return 0
    end
    assertEquals(private.GetContainerNumSlotsCompat(0), 3)
    _G.GetContainerNumSlots = oldLegacySlots

    local oldSlots = _G.GetContainerNumSlots
    local oldLink = _G.GetContainerItemLink
    local oldInfo = _G.GetContainerItemInfo
    _G.GetContainerNumSlots = nil
    _G.GetContainerItemLink = nil
    assertEquals(private.GetContainerNumSlotsCompat(0), 3)
    assertContains(private.GetContainerItemLinkCompat(0, 1), "Defender Helm")
    _G.GetContainerNumSlots = oldSlots
    _G.GetContainerItemLink = oldLink

    local oldContainerSlots = _G.C_Container.GetContainerNumSlots
    local oldContainerLink = _G.C_Container.GetContainerItemLink
    local oldContainerInfo = _G.C_Container.GetContainerItemInfo
    _G.C_Container.GetContainerNumSlots = nil
    _G.C_Container.GetContainerItemLink = nil
    _G.C_Container.GetContainerItemInfo = nil
    assertEquals(private.ContainerApiName(), "legacy")
    assertEquals(private.GetContainerNumSlotsCompat(0), 3)
    assertContains(private.GetContainerItemLinkCompat(0, 1), "Defender Helm")

    _G.GetContainerNumSlots = nil
    _G.GetContainerItemLink = nil
    _G.GetContainerItemInfo = nil
    assertEquals(private.ContainerApiName(), "none")
    assertEquals(private.GetContainerNumSlotsCompat(0), 0)
    assertEquals(private.GetContainerItemLinkCompat(0, 1), nil)

    local oldBackdrop = _G.BackdropTemplateMixin
    _G.BackdropTemplateMixin = nil
    assertEquals(private.BackdropTemplate(), nil)
    _G.BackdropTemplateMixin = oldBackdrop
    _G.C_Container.GetContainerNumSlots = oldContainerSlots
    _G.C_Container.GetContainerItemLink = oldContainerLink
    _G.C_Container.GetContainerItemInfo = oldContainerInfo
    _G.GetContainerNumSlots = oldSlots
    _G.GetContainerItemLink = oldLink
    _G.GetContainerItemInfo = oldInfo
end)

test("profile creation uses real and fallback character names", function()
    resetRuntimeState(Addon)
    local profile = Addon:GetProfile()
    assertEquals(profile.player, "Tester")
    assertEquals(profile.realm, "Test Realm")

    local oldRealm = _G.GetRealmName
    local oldUnit = _G.UnitName
    _G.GetRealmName = nil
    _G.UnitName = nil
    Addon.db = nil
    _G.TBCGearExporterDB = nil
    profile = Addon:GetProfile()
    assertEquals(profile.player, "Unknown Player")
    assertEquals(profile.realm, "Unknown Realm")
    _G.GetRealmName = oldRealm
    _G.UnitName = oldUnit
end)

test("talent snapshot captures current build and fallback paths", function()
    resetRuntimeState(Addon)
    mock.unspentTalentPoints = 2

    local snapshot = private.BuildTalentSnapshot()
    assertTrue(snapshot.available)
    assertEquals(snapshot.api, "GetTalentInfo")
    assertEquals(snapshot.summary, "0/46/15")
    assertEquals(snapshot.totalPoints, 61)
    assertEquals(snapshot.pointsSpent, 61)
    assertEquals(snapshot.unspentPoints, 2)
    assertEquals(snapshot.primaryTab, "Feral Combat")
    assertEquals(snapshot.primaryTabIndex, 2)
    assertEquals(#snapshot.tabs, 3)
    assertEquals(#snapshot.treePoints, 3)
    assertEquals(snapshot.treePoints[2].pointsSpent, 46)
    assertTrue(snapshot.treePoints[2].isPrimary)
    assertEquals(snapshot.tabs[2].pointsSpent, 46)
    assertEquals(snapshot.tabs[2].talents[1].name, "Ferocity")
    assertEquals(snapshot.tabs[2].talents[1].rank, 5)
    assertEquals(snapshot.tabs[2].talents[1].points, 5)
    assertEquals(snapshot.tabs[2].talents[1].pointsSpent, 5)
    assertEquals(snapshot.tabs[2].talents[1].currentRank, 5)
    assertEquals(snapshot.tabs[2].talents[3].isExceptional, true)
    assertContains(private.TalentSummaryText(snapshot, "enUS"), "primary=Feral Combat")
    assertContains(private.TalentSummaryText(snapshot, "enUS"), "trees=Balance 0, Feral Combat 46, Restoration 15")
    assertContains(private.TalentSummaryText(snapshot, "zhCN"), "0/46/15")
    assertContains(private.TalentSummaryText(snapshot, "zhCN"), "主天赋=Feral Combat")
    assertContains(private.TalentSummaryText(snapshot, "zhCN"), "已用点数=61")
    assertContains(private.TalentSummaryText(snapshot, "zhTW"), "主天賦=Feral Combat")
    assertContains(private.TalentSummaryText(snapshot, "zhTW"), "未分配=2")
    assertContains(private.TalentTreePointsText(snapshot, "zhCN"), "Feral Combat 46")
    assertContains(private.TalentSelectedPointsText(snapshot, "enUS", 1), "Ferocity 5/5")
    assertContains(private.TalentSelectedPointsText(snapshot, "enUS", 1), "+4 more")
    assertContains(private.TalentSelectedPointsText(snapshot, "zhCN", 1), "另 4 个")
    assertContains(private.TalentSelectedPointsText(snapshot, "zhTW", 1), "另 4 個")

    mock.badTalentInfo["2:1"] = true
    snapshot = private.BuildTalentSnapshot()
    assertEquals(#snapshot.tabs[2].talents, 2)
    mock.badTalentInfo = {}

    mock.badTalentTabs[2] = true
    snapshot = private.BuildTalentSnapshot()
    assertEquals(snapshot.tabs[2].name, "野性战斗")
    assertEquals(snapshot.tabs[2].points, 9)
    mock.badTalentTabs = {}

    local originalTalentTabInfo = _G.GetTalentTabInfo
    _G.GetTalentTabInfo = function(tabIndex)
        local tab = mock.talentTabs[tabIndex]
        return ({ 382, 383, 381 })[tabIndex], nil, tab and tab.points or 0, tab and tab.icon, tab and tab.background
    end
    snapshot = private.BuildTalentSnapshot()
    assertEquals(snapshot.tabs[2].name, "野性战斗")
    assertContains(private.TalentTreePointsText(snapshot, "zhCN"), "野性战斗 46")
    assertEquals(private.LocalizedTalentTreeName("PALADIN", 1, "zhCN"), "神圣")
    _G.GetTalentTabInfo = originalTalentTabInfo

    local oldUnitPoints = _G.UnitCharacterPoints
    _G.UnitCharacterPoints = nil
    _G.GetUnspentTalentPoints = function()
        return 7
    end
    snapshot = private.BuildTalentSnapshot()
    assertEquals(snapshot.unspentPoints, 7)
    _G.GetUnspentTalentPoints = nil

    local oldTabs = _G.GetNumTalentTabs
    local oldTabInfo = _G.GetTalentTabInfo
    local oldNumTalents = _G.GetNumTalents
    local oldTalentInfo = _G.GetTalentInfo
    _G.GetNumTalentTabs = nil
    _G.GetTalentTabInfo = nil
    _G.GetNumTalents = nil
    _G.GetTalentInfo = nil
    snapshot = private.BuildTalentSnapshot()
    assertFalse(snapshot.available)
    assertEquals(snapshot.api, "unavailable")
    assertContains(private.TalentSummaryText(snapshot, "zhCN"), "不可用")
    assertContains(private.TalentTreePointsText(snapshot, "zhCN"), "不可用")
    assertContains(private.TalentSelectedPointsText(snapshot, "enUS"), "unavailable")

    _G.UnitCharacterPoints = oldUnitPoints
    _G.GetNumTalentTabs = oldTabs
    _G.GetTalentTabInfo = oldTabInfo
    _G.GetNumTalents = oldNumTalents
    _G.GetTalentInfo = oldTalentInfo
end)

test("saved talent snapshot keeps previous spent points when refresh returns zero", function()
    resetRuntimeState(Addon)

    local saved = Addon:SaveTalentSnapshot()
    assertEquals(saved.totalPoints, 61)
    assertTrue(private.TalentSnapshotHasSpentPoints(saved))

    mock.talentTabs[1].points = 0
    mock.talentTabs[2].points = 0
    mock.talentTabs[2].talents = {}
    mock.talentTabs[3].points = 0
    mock.talentTabs[3].talents = {}

    local fallback = Addon:SaveTalentSnapshot()
    assertEquals(fallback.totalPoints, 61)
    assertEquals(Addon:GetProfile().talents.summary, "0/46/15")
    assertEquals(Addon:GetProfile().localDB.talentPointsSpent, 61)
    assertContains(Addon:GetProfile().localDB.talentTreePoints, "Feral Combat 46")

    mock.unspentTalentPoints = 61
    local realReset = Addon:SaveTalentSnapshot()
    assertEquals(realReset.totalPoints, 0)
    assertEquals(realReset.unspentPoints, 61)
    assertEquals(Addon:GetProfile().localDB.talentPointsSpent, 0)

    local tabOnly = private.TalentTreePoints({ available = true, primaryTabIndex = 2, tabs = { { index = 2, name = "Feral Combat", points = 42 } } })
    assertEquals(tabOnly[1].pointsSpent, 42)
    assertTrue(tabOnly[1].isPrimary)
    assertFalse(private.TalentSnapshotHasSpentPoints({ totalPoints = 0 }))
end)

test("character stats snapshot captures paper doll stats and fallbacks", function()
    resetRuntimeState(Addon)

    assertEquals(private.SafeNumber("12.5"), 12.5)
    assertEquals(private.SafeNumber("bad"), nil)
    assertEquals(private.SumKnown(nil, 2, -1), 1)
    assertEquals(private.SumKnown(nil, nil), nil)
    assertEquals(private.RaceToken("Blood Elf"), "BLOODELF")
    assertEquals(private.RaceToken("blood_elves"), "BLOODELF")
    assertEquals(private.RaceToken("Night Elves"), "NIGHTELF")
    assertEquals(private.RaceToken("Scourge"), "SCOURGE")
    assertEquals(private.RaceToken(""), "UNKNOWN")
    assertEquals(private.RaceToken("Tauren"), "TAUREN")

    local snapshot = private.BuildCharacterStatsSnapshot()
    assertEquals(snapshot.api, "paper_doll")
    assertEquals(snapshot.level, 70)
    assertEquals(snapshot.race.localized, "Tauren")
    assertEquals(snapshot.race.english, "TAUREN")
    assertEquals(snapshot.race.faction, "Horde")
    assertContains(snapshot.race.notes[1], "Stamina")
    assertEquals(snapshot.group.type, "raid")
    assertEquals(snapshot.group.size, 25)
    assertContains(snapshot.group.notes[1], "Raid context")
    assertEquals(private.AttributeValue(snapshot, "stamina"), 520)
    assertEquals(private.AttributeValue(snapshot, "missing"), nil)
    assertEquals(snapshot.armor.effective, 13500)
    assertEquals(snapshot.defense.effective, 495)
    assertEquals(snapshot.attackPower.melee.effective, 1000)
    assertEquals(snapshot.attackPower.ranged.effective, 560)
    assertEquals(private.RatingBonus(snapshot, "melee_hit"), 8.5)
    assertEquals(private.RatingBonus(snapshot, "missing"), nil)
    assertEquals(private.BestSpellValue(snapshot.chances.spellCrit, "crit"), 19.25)
    assertEquals(private.BestSpellValue(nil, "crit"), nil)
    assertEquals(private.KnownAvoidanceBlock(snapshot.chances), 35)
    assertEquals(private.KnownAvoidanceBlock({}), nil)
    assertEquals(snapshot.spell.healing, 900)
    assertEquals(snapshot.spell.manaRegenCasting, 82)
    assertEquals(private.BestSpellValue(snapshot.spell.spellDamage, "bonus"), 400)

    mock.group.inRaid = false
    mock.group.raidMembers = 0
    mock.group.inGroup = true
    mock.group.partyMembers = 4
    local party = private.GetGroupContext()
    assertEquals(party.type, "party")
    assertEquals(party.size, 5)
    assertContains(party.notes[1], "Party context")

    mock.group.inGroup = false
    mock.group.partyMembers = 0
    local solo = private.GetGroupContext()
    assertEquals(solo.type, "solo")
    assertEquals(solo.size, 1)
    assertContains(solo.notes[1], "Solo context")

    local oldRace = _G.UnitRace
    local oldFaction = _G.UnitFactionGroup
    _G.UnitRace = function()
        error("race failure")
    end
    _G.UnitFactionGroup = function()
        return "Alliance"
    end
    local unknownRace = private.GetPlayerRaceInfo()
    assertEquals(unknownRace.localized, "Unknown Race")
    assertEquals(unknownRace.english, "UNKNOWN")
    assertEquals(unknownRace.factionLocalized, "Alliance")
    _G.UnitRace = nil
    _G.UnitFactionGroup = nil
    unknownRace = private.GetPlayerRaceInfo()
    assertEquals(unknownRace.localized, "Unknown Race")
    _G.UnitRace = oldRace
    _G.UnitFactionGroup = oldFaction

    local oldDefense = _G.UnitDefense
    local oldAttackPower = _G.UnitAttackPower
    local oldRangedAttackPower = _G.UnitRangedAttackPower
    _G.UnitDefense = nil
    _G.UnitAttackPower = nil
    _G.UnitRangedAttackPower = nil
    snapshot = private.BuildCharacterStatsSnapshot()
    assertEquals(snapshot.defense.effective, nil)
    assertEquals(snapshot.attackPower.melee.effective, nil)
    assertEquals(snapshot.attackPower.ranged.effective, nil)
    _G.UnitDefense = oldDefense
    _G.UnitAttackPower = oldAttackPower
    _G.UnitRangedAttackPower = oldRangedAttackPower
end)

test("strategy book ranks role models from talents gear race and raid context", function()
    resetRuntimeState(Addon)
    Addon:ScanBags()
    Addon:ScanBank()

    local profile = Addon:GetProfile()
    local items = Addon:CollectExportItems("all")
    local chartStats = private.BuildChartStats(items)
    local strategyBook = private.BuildStrategyBook(profile, chartStats)
    local firstRole = strategyBook.roles[1]

    assertEquals(strategyBook.classToken, "DRUID")
    assertEquals(strategyBook.raceToken, "TAUREN")
    assertEquals(strategyBook.groupType, "raid")
    assertContains(strategyBook.raceNotes[1], "Stamina")
    assertContains(strategyBook.groupNotes[1], "Raid context")
    assertEquals(firstRole.key, "bear_tank")
    assertEquals(firstRole.label, "Bear Feral Tank")
    assertEquals(firstRole.confidence, 100)
    assertEquals(firstRole.talentPoints, 46)
    assertTrue(firstRole.primaryTalentMatch)
    assertEquals(firstRole.observed.hit.melee, 8.5)
    assertEquals(firstRole.observed.hit.ranged, 9)
    assertEquals(firstRole.observed.hit.spell, 12.25)
    assertEquals(firstRole.observed.hit.expertise, 4)
    assertEquals(firstRole.observed.crit.melee, 28.5)
    assertEquals(firstRole.observed.crit.ranged, 31)
    assertEquals(firstRole.observed.crit.spellBest, 19.25)
    assertEquals(firstRole.observed.tank.defense, 495)
    assertEquals(firstRole.observed.tank.armor, 13500)
    assertEquals(firstRole.observed.tank.knownAvoidanceBlock, 35)
    assertEquals(firstRole.observed.power.attackPower, 1000)
    assertEquals(firstRole.observed.power.rangedAttackPower, 560)
    assertEquals(firstRole.observed.power.spellPowerBest, 400)
    assertEquals(firstRole.observed.power.healing, 900)
    assertTrue(#firstRole.observed.gearStatHighlights >= 1)

    assertEquals(private.TalentPointsForTabs(profile.talents, { 2 }), 46)
    assertTrue(private.TalentPrimaryMatches(profile.talents, { 2 }))
    assertFalse(private.TalentPrimaryMatches({ available = true }, { 1 }))
    assertEquals(private.RoleConfidence({ talentTabs = { 1 } }, nil), 25)
    assertEquals(private.RoleConfidence({ talentTabs = { 1 } }, profile.talents), 20)
    assertEquals(private.RoleConfidence({ talentTabs = { 2 } }, profile.talents), 100)
    assertEquals(private.StrategyClassRoles("MONK")[1].key, "general_inventory")

    local observed = private.BuildRoleObservedStats(firstRole, profile.characterStats, chartStats)
    assertEquals(private.BenchmarkObservedValue("defense_crit_immunity", observed), 495)
    assertEquals(private.BenchmarkObservedValue("melee_special_hit", observed), 8.5)
    assertEquals(private.BenchmarkObservedValue("ranged_hit", observed), 9)
    assertEquals(private.BenchmarkObservedValue("spell_hit", observed), 12.25)
    assertEquals(private.BenchmarkObservedValue("expertise_dodge", observed), 4)
    assertEquals(private.BenchmarkObservedValue("avoidance_table", observed), 35)
    assertEquals(private.BenchmarkObservedValue("unknown", observed), nil)
    assertEquals(private.BenchmarkStatus("defense_crit_immunity", observed).status, "meets_or_exceeds")
    assertEquals(private.BenchmarkStatus("melee_special_hit", observed).status, "near")
    assertEquals(private.BenchmarkStatus("unknown", observed).status, "unknown")
    assertEquals(private.BuildRoleBenchmarks({ benchmarkKeys = { "defense_crit_immunity" } }, observed)[1].target, 490)
    assertEquals(private.AnalysisValue(nil), "未知")
    assertEquals(private.AnalysisValue(8.5, "%"), "8.5%")
    assertEquals(private.AnalysisValue(14.451999664307, "%"), "14.45%")
    local analysisText, roleCount = private.BuildStatsAnalysisText(profile, chartStats, strategyBook)
    assertEquals(roleCount, #strategyBook.roles)
    assertContains(analysisText, "属性分析")
    assertContains(analysisText, "德鲁伊")
    assertContains(analysisText, "牛头人")
    assertContains(analysisText, "团队")
    assertContains(analysisText, "防御/免伤")
    assertContains(analysisText, "天赋点：Balance 0, Feral Combat 46, Restoration 15")
    assertContains(analysisText, "已点天赋：Ferocity 5/5")
    assertContains(analysisText, "熊形态野性坦克")
    assertContains(analysisText, "坦克免伤")
    assertContains(analysisText, "达标")
    assertContains(analysisText, "防御免暴基准")
    assertContains(analysisText, "耐力和战争践踏")
    assertContains(analysisText, "当前装备属性亮点")
    assertContains(analysisText, "+10 耐力")
    assertFalse(analysisText:find("+27 耐力", 1, true), "candidate inventory totals must not be presented as current gear")
    assertFalse(analysisText:find("Bear Feral Tank", 1, true), "Chinese analysis should not show English role labels")
    assertFalse(analysisText:find("tank_mitigation", 1, true), "Chinese analysis should not show internal model tokens")
    assertFalse(analysisText:find("meets_or_exceeds", 1, true), "Chinese analysis should not show internal status tokens")
    local _, tankLensCount = analysisText:gsub("坦克视角", "")
    assertEquals(tankLensCount, 1)
    assertTrue(private.RoleHasModel(firstRole, "tank_mitigation"))
    assertFalse(private.RoleHasModel(firstRole, "caster_dps"))
    assertTrue(private.RoleUsesHitModel(firstRole))
    assertFalse(private.RoleUsesHitModel(strategyBook.roles[3]))

    profile.locale = "enUS"
    local englishAnalysis = private.BuildStatsAnalysisText(profile, chartStats, strategyBook)
    assertContains(englishAnalysis, "Stats Analysis")
    assertContains(englishAnalysis, "Talent points: Balance 0, Feral Combat 46, Restoration 15")
    assertContains(englishAnalysis, "selected talents: Ferocity 5/5")
    assertContains(englishAnalysis, "Bear Feral Tank")
    assertContains(englishAnalysis, "Tank mitigation")
    assertContains(englishAnalysis, "Current gear highlights: +10 Stamina")
    assertContains(englishAnalysis, "Meets / exceeds")
    assertFalse(englishAnalysis:find("tank_mitigation", 1, true), "English analysis should not show internal model tokens")
    assertFalse(englishAnalysis:find("meets_or_exceeds", 1, true), "English analysis should not show internal status tokens")
    profile.locale = "zhCN"

    mock.talentTabs[1].points = 0
    mock.talentTabs[2].points = 0
    mock.talentTabs[2].talents = {}
    mock.talentTabs[3].points = 0
    mock.talentTabs[3].talents = {}
    local emptyTalents = private.BuildTalentSnapshot()
    assertEquals(emptyTalents.primaryTab, nil)
    assertEquals(emptyTalents.primaryTabIndex, nil)
    assertContains(private.TalentTreePointsText(emptyTalents, "enUS"), "Balance 0")
    assertEquals(private.TalentSelectedPointsText(emptyTalents, "enUS"), "none")
end)

test("gear strategy engine compares current slots with compatible saved candidates", function()
    resetRuntimeState(Addon)
    local equipped = Addon:ScanEquipped()
    assertEquals(equipped.api, "inventory")
    assertEquals(#equipped.items, 1)
    assertEquals(equipped.items[1].itemID, 6001)
    assertEquals(equipped.items[1].slotKey, "HEAD")
    assertEquals(equipped.items[1].location, "头部")

    local profile = Addon:GetProfile()
    profile.equipped = equipped
    profile.talents = private.BuildTalentSnapshot()
    profile.characterStats = private.BuildCharacterStatsSnapshot()

    local function candidate(itemID, location)
        return Addon:BuildItemFromLink("bags", mock.itemLinks[itemID], { bag = 0, slot = itemID, location = location })
    end

    local leatherHead = candidate(6002, "Backpack slot 8")
    local emptyHands = candidate(6003, "Backpack slot 9")
    local plateHead = candidate(1001, "Backpack slot 10")
    local shield = candidate(6004, "Bank slot 4")
    local unusable = candidate(6005, "Bank slot 5")
    local potion = candidate(2001, "Backpack slot 11")
    mock.unequippableItems[6005] = true

    local candidates = { leatherHead, emptyHands, plateHead, shield, unusable, potion }
    local strategyBook = private.BuildStrategyBook(profile, private.BuildChartStats(candidates))
    local engine = private.BuildGearRecommendations(profile, candidates, strategyBook)
    assertEquals(engine.roleKey, "bear_tank")
    assertEquals(engine.roleConfidence, 100)
    assertEquals(engine.equippedCount, 1)
    assertEquals(engine.candidateCount, 2)
    assertTrue(#engine.priorityStats <= 6)
    assertTrue(#engine.benchmarkGaps >= 2)
    assertEquals(#engine.upgrades, 2)
    assertContains(engine.caveat, "启发式评分")

    local bySlot = {}
    for index = 1, #engine.upgrades do
        bySlot[engine.upgrades[index].slotKey] = engine.upgrades[index]
    end
    assertEquals(bySlot.HEAD.current.itemID, 6001)
    assertEquals(bySlot.HEAD.candidate.itemID, 6002)
    assertTrue(bySlot.HEAD.scoreGain > 2)
    assertEquals(bySlot.HANDS.current, nil)
    assertEquals(bySlot.HANDS.candidate.itemID, 6003)
    assertTrue(#bySlot.HANDS.matchedStats >= 2)

    assertEquals(private.EquipmentSlotKey({ slotKey = "TRINKET" }), "TRINKET")
    assertEquals(private.EquipmentSlotKey({ inventorySlot = 17 }), "OFFHAND")
    assertEquals(private.EquipmentSlotKey({ equipSlot = "INVTYPE_CLOAK" }), "BACK")
    assertEquals(private.EquipmentSlotKey(nil), nil)
    assertEquals(private.EquipmentSlotLabel("HEAD", "zhCN"), "头部")
    assertEquals(private.EquipmentSlotLabel("HEAD", "enUS"), "Head")
    assertEquals(private.EquipmentSlotLabel("MYSTERY", "enUS"), "MYSTERY")

    assertFalse(private.CandidateCompatibleWithClass(profile, nil))
    assertFalse(private.CandidateCompatibleWithClass(profile, potion))
    assertFalse(private.CandidateCompatibleWithClass(profile, plateHead))
    assertFalse(private.CandidateCompatibleWithClass(profile, shield))
    assertFalse(private.CandidateCompatibleWithClass(profile, unusable))
    mock.unequippableItems[6005] = nil
    mock.badEquippableItems[6005] = true
    assertTrue(private.CandidateCompatibleWithClass(profile, unusable))
    mock.badEquippableItems[6005] = nil
    assertTrue(private.CandidateCompatibleWithClass(profile, leatherHead))

    local aliasRole = {
        statTokens = {
            "ITEM_MOD_HIT_MELEE_RATING_SHORT",
            "ITEM_MOD_CRIT_MELEE_RATING_SHORT",
            "ITEM_MOD_HASTE_MELEE_RATING_SHORT",
            "ITEM_MOD_STAMINA_SHORT",
            "ITEM_MOD_AGILITY_SHORT",
            "ITEM_MOD_STRENGTH_SHORT",
            "ITEM_MOD_DODGE_RATING_SHORT",
            "ITEM_MOD_PARRY_RATING_SHORT",
        },
        benchmarks = {
            { key = "melee_special_hit", status = "below" },
            { key = "avoidance_table", status = "near" },
            { key = "unknown", status = "meets_or_exceeds" },
        },
    }
    local weights = private.BuildRoleStatWeights(aliasRole)
    local score, matched = private.ItemRoleScore({
        itemLevel = 100,
        quality = 3,
        stats = {
            { token = "ITEM_MOD_HIT_RATING_SHORT", label = "Hit", value = 10 },
            { token = "ITEM_MOD_CRIT_RATING_SHORT", label = "Crit", value = 10 },
            { token = "ITEM_MOD_HASTE_RATING_SHORT", label = "Haste", value = 10 },
            { token = "EMPTY_SOCKET_BLUE", label = "Blue Socket", value = 1 },
            { token = "ITEM_MOD_SPIRIT_SHORT", label = "Spirit", value = -2 },
        },
    }, aliasRole, weights)
    assertTrue(score > 40)
    assertEquals(#matched, 4)
    assertEquals(private.GearMatchedStatsText({ matchedStats = matched }, "enUS"):find("Hit", 1, true) ~= nil, true)
    assertEquals(#private.PriorityStats(aliasRole, weights), 6)
    assertContains(private.GearPriorityText(engine, "zhCN"), "耐力")
    assertContains(private.GearBenchmarkText(engine, "zhCN"), "/")
    assertContains(private.GearBenchmarkText({ benchmarkGaps = {} }, "zhCN"), "没有")
    assertEquals(private.GearRoleLabel(engine, "zhCN"), "熊形态野性坦克")

    local emptyEngine = private.BuildGearRecommendations({ locale = "enUS", equipped = { items = {} } }, {}, nil)
    assertEquals(emptyEngine.roleKey, "general_inventory")
    assertEquals(#emptyEngine.upgrades, 0)

    local oldInventoryLink = _G.GetInventoryItemLink
    _G.GetInventoryItemLink = nil
    local unavailable = Addon:ScanEquipped()
    assertEquals(unavailable.api, "unavailable")
    assertEquals(#unavailable.items, 0)
    _G.GetInventoryItemLink = oldInventoryLink
    assertEquals(Addon:BuildItemFromLink("equipped", nil), nil)
end)

test("protection paladin strategy compares visible gains and losses without inventory leakage", function()
    resetRuntimeState(Addon)
    local current = {
        itemID = 7001, name = "Current Tank Neck", category = "Gear", equipSlot = "INVTYPE_NECK",
        classID = 4, subClassID = 0, itemLevel = 120, quality = 4, source = "equipped", slotKey = "NECK",
        stats = {
            { token = "ITEM_MOD_STAMINA_SHORT", label = "Stamina", value = 20 },
            { token = "RESISTANCE0_NAME", label = "Armor", value = 1000 },
            { token = "ITEM_MOD_SPELL_DAMAGE_DONE", label = "魔法法术和效果的伤害量提高最多点。", value = 30 },
        },
    }
    local candidate = {
        itemID = 7002, name = "Candidate Tank Neck", category = "Gear", equipSlot = "INVTYPE_NECK",
        classID = 4, subClassID = 0, itemLevel = 125, quality = 4, source = "bags",
        stats = {
            { token = "ITEM_MOD_STAMINA_SHORT", label = "Stamina", value = 30 },
            { token = "RESISTANCE0_NAME", label = "Armor", value = 1200 },
            { token = "ITEM_MOD_DEFENSE_SKILL_RATING", label = "防御等级提高。", value = 20 },
            { token = "ITEM_MOD_DODGE_RATING_SHORT", label = "Dodge Rating", value = 10 },
            { token = "ITEM_MOD_SPELL_DAMAGE_DONE", label = "魔法法术和效果的伤害量提高最多点。", value = 10 },
            { token = "ITEM_MOD_POWER_REGEN0_SHORT", label = "每5秒的法力值恢复", value = 6 },
        },
    }
    local profile = {
        classEnglish = "PALADIN",
        classLocalized = "圣骑士",
        locale = "zhCN",
        talents = {
            available = true, primaryTabIndex = 2, primaryTab = "防护", totalPoints = 61, pointsSpent = 61,
            summary = "0/43/18", unspentPoints = 0,
            tabs = {
                { index = 1, name = "神圣", points = 0, pointsSpent = 0, talents = {} },
                { index = 2, name = "防护", points = 43, pointsSpent = 43, talents = {} },
                { index = 3, name = "惩戒", points = 18, pointsSpent = 18, talents = {} },
            },
        },
        characterStats = private.BuildCharacterStatsSnapshot(),
        equipped = { items = { current } },
    }
    local candidateChart = private.BuildChartStats({ candidate })
    local strategyBook = private.BuildStrategyBook(profile, candidateChart)
    local role = strategyBook.roles[1]
    local weights = private.BuildRoleStatWeights(role)
    local engine = private.BuildGearRecommendations(profile, { candidate }, strategyBook)

    assertEquals(role.key, "protection_tank")
    assertEquals(role.talentPoints, 43)
    assertEquals(role.confidence, 100)
    assertTrue(weights.ITEM_MOD_ARMOR > 0)
    assertTrue(weights.ITEM_MOD_DODGE_RATING_SHORT > 0)
    assertTrue(weights.ITEM_MOD_PARRY_RATING_SHORT > 0)
    assertTrue(weights.ITEM_MOD_BLOCK_RATING_SHORT > 0)
    assertTrue(weights.ITEM_MOD_HIT_SPELL_RATING_SHORT > 0)
    assertEquals(private.NormalizeStatToken("ITEM_MOD_POWER_REGEN0_SHORT"), "ITEM_MOD_MANA_REGENERATION_SHORT")
    assertEquals(private.NormalizeStatToken("ITEM_MOD_SPELL_DAMAGE_DONE"), "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT")
    assertEquals(private.ComparisonStatToken("ITEM_MOD_SPELL_DAMAGE_DONE"), "ITEM_MOD_SPELL_POWER_SHORT")
    assertEquals(private.StatLabel("ITEM_MOD_DEFENSE_SKILL_RATING"), "Defense Rating")
    assertEquals(role.observed.gearStatHighlights[1].value, 20)
    assertFalse(role.observed.gearStatHighlights[1].value == 30, "candidate stamina must not leak into current gear highlights")

    assertEquals(engine.version, 3)
    assertEquals(#engine.upgrades, 1)
    assertEquals(engine.upgrades[1].evidence, "high")
    assertEquals(engine.upgrades[1].verdict, "upgrade")
    assertEquals(engine.upgrades[1].statGains[1].token, "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT")
    assertEquals(engine.upgrades[1].statLosses[1].token, "ITEM_MOD_SPELL_POWER_SHORT")
    assertContains(private.DeltaText(engine.upgrades[1].statGains, "zhCN"), "防御等级")
    assertContains(private.DeltaText(engine.upgrades[1].statLosses, "zhCN"), "法术强度")
    assertEquals(private.EvidenceLabel("high", "zhTW"), "高")

    local relevant = private.ItemRelevantStatMap(candidate, weights)
    assertEquals(relevant.ITEM_MOD_STAMINA_SHORT, 30)
    assertEquals(relevant.ITEM_MOD_ARMOR, 1200)
    assertEquals(relevant.ITEM_MOD_SPELL_POWER_SHORT, 10)
    assertEquals(relevant.ITEM_MOD_MANA_REGENERATION_SHORT, 6)
    assertEquals(candidateChart.statTotals[2].token, "ITEM_MOD_ARMOR")
    assertEquals(private.RecommendationEvidence(nil, candidate, {}, {}), "low")
    assertEquals(private.RecommendationEvidence(
        { stats = { { token = "ITEM_MOD_STAMINA_SHORT", value = 1 } } },
        { stats = { { token = "ITEM_MOD_STAMINA_SHORT", value = 2 } }, equipSlot = "INVTYPE_NECK" },
        { { token = "ITEM_MOD_STAMINA_SHORT" } },
        {}
    ), "medium")
    assertEquals(private.RecommendationEvidence(
        { stats = { { token = "ITEM_MOD_STAMINA_SHORT", value = 1 } } },
        { stats = { { token = "ITEM_MOD_STAMINA_SHORT", value = 2 } }, equipSlot = "INVTYPE_TRINKET" },
        { { token = "ITEM_MOD_STAMINA_SHORT" } },
        {}
    ), "low")
end)

test("spell damage and spell power compare as one offensive stat", function()
    local weights = {
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 1,
    }
    local current = {
        stats = {
            { token = "ITEM_MOD_SPELL_POWER", value = 20 },
        },
    }
    local candidate = {
        stats = {
            { token = "ITEM_MOD_SPELL_DAMAGE_DONE", value = 26 },
        },
    }
    local gains, losses = private.BuildStatDeltas(current, candidate, weights)
    assertEquals(#gains, 1)
    assertEquals(gains[1].token, "ITEM_MOD_SPELL_POWER_SHORT")
    assertEquals(gains[1].value, 6)
    assertEquals(#losses, 0)
    assertContains(private.DeltaText(gains, "zhCN"), "+6 法术强度")
end)

test("benchmark impacts distinguish gaps caps and contextual shield totals", function()
    local role = {
        benchmarks = {
            { key = "defense_crit_immunity", label = "Defense", status = "meets_or_exceeds" },
            { key = "spell_hit", label = "Spell Hit", status = "below" },
            { key = "avoidance_table", label = "Shield Table", status = "context_required" },
        },
    }
    local impacts = private.BuildBenchmarkImpacts(role, {
        { token = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", value = 3 },
        { token = "ITEM_MOD_HIT_SPELL_RATING_SHORT", value = 2 },
        { token = "ITEM_MOD_DODGE_RATING_SHORT", value = 5 },
    }, {
        { token = "ITEM_MOD_BLOCK_RATING_SHORT", value = 7 },
    })
    assertEquals(#impacts, 3)
    assertEquals(impacts[1].effect, "cap_buffer")
    assertEquals(impacts[2].effect, "helps_gap")
    assertEquals(impacts[3].delta, -2)
    assertEquals(impacts[3].effect, "context_risk")
end)

test("benchmark impacts flag cap risk gap regression and contextual progress", function()
    local role = {
        benchmarks = {
            { key = "defense_crit_immunity", label = "Defense", status = "meets_or_exceeds" },
            { key = "spell_hit", label = "Spell Hit", status = "near" },
            { key = "avoidance_table", label = "Shield Table", status = "context_required" },
        },
    }
    local impacts = private.BuildBenchmarkImpacts(role, {
        { token = "ITEM_MOD_PARRY_RATING_SHORT", value = 4 },
    }, {
        { token = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", value = 18 },
        { token = "ITEM_MOD_HIT_SPELL_RATING_SHORT", value = 3 },
    })
    assertEquals(impacts[1].effect, "cap_risk")
    assertEquals(impacts[2].effect, "worsens_gap")
    assertEquals(impacts[3].effect, "context_help")
end)

test("recommendation verdicts separate upgrades tradeoffs minor gains and manual checks", function()
    assertEquals(private.RecommendationVerdict("low", 40, {}), "review")
    assertEquals(private.RecommendationVerdict("high", 12, {}), "upgrade")
    assertEquals(private.RecommendationVerdict("medium", 7.99, {}), "minor")
    assertEquals(private.RecommendationVerdict("high", 20, { { effect = "cap_risk" } }), "tradeoff")
    assertEquals(private.RecommendationVerdict("high", 20, { { effect = "worsens_gap" } }), "tradeoff")
    assertEquals(private.RecommendationVerdict("high", 20, { { effect = "context_risk" } }), "tradeoff")
end)

test("verdict summaries are concise and localized", function()
    local engine = {
        upgrades = {
            { verdict = "upgrade" },
            { verdict = "minor" },
            { verdict = "tradeoff" },
            { verdict = "review" },
            {},
        },
    }
    local counts = private.VerdictCounts(engine.upgrades)
    assertEquals(counts.upgrade, 1)
    assertEquals(counts.minor, 1)
    assertEquals(counts.tradeoff, 1)
    assertEquals(counts.review, 2)
    assertContains(private.VerdictSummary(engine, "zhCN"), "明确 1")
    assertContains(private.VerdictSummary(engine, "zhTW"), "需核對 2")
    assertContains(private.VerdictSummary(engine, "enUS"), "1 clear")
    assertEquals(private.RecommendationVerdictLabel("tradeoff", "zhCN"), "有取舍")
end)

test("benchmark impact copy explains the direction without claiming a simulated stat", function()
    local impacts = {
        { key = "defense_crit_immunity", label = "Defense", delta = -18, effect = "cap_risk" },
        { key = "avoidance_table", label = "Shield Table", delta = 10, effect = "context_help" },
    }
    local zhCN = private.BenchmarkImpactText(impacts, "zhCN")
    assertContains(zhCN, "防御免暴基准 -18")
    assertContains(zhCN, "换装后需重新核对是否达标")
    assertContains(zhCN, "提高可见常驻小计")
    assertEquals(private.BenchmarkImpactText({}, "zhCN"), "不改变已跟踪基准")
end)

test("shield table benchmark is contextual instead of a false failed cap", function()
    local benchmark = private.BenchmarkStatus("avoidance_table", {
        tank = { knownAvoidanceBlock = 60.13 },
    })
    assertEquals(benchmark.status, "context_required")
    assertEquals(benchmark.observed, 60.13)
    assertEquals(benchmark.target, 102.4)
    local text = private.GearBenchmarkText({ benchmarkGaps = { benchmark } }, "zhCN")
    assertContains(text, "需结合战斗状态核对")
    assertFalse(text:find("低于目标", 1, true), "shield subtotal must not be presented as a failed full table")
end)

test("Strongge style neck swap reports net spell power and a defense tradeoff", function()
    local current = {
        itemID = 24121, name = "夜枭之链", category = "Gear", equipSlot = "INVTYPE_NECK",
        classID = 4, subClassID = 0, itemLevel = 115, quality = 4, slotKey = "NECK",
        stats = {
            { token = "ITEM_MOD_INTELLECT_SHORT", value = 19 },
            { token = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", value = 18 },
            { token = "ITEM_MOD_SPELL_POWER_SHORT", value = 20 },
        },
    }
    local candidate = {
        itemID = 30018, name = "萨古纳尔男爵的索求", category = "Gear", equipSlot = "INVTYPE_NECK",
        classID = 4, subClassID = 0, itemLevel = 138, quality = 4, slotKey = "NECK",
        stats = {
            { token = "ITEM_MOD_STAMINA_SHORT", value = 25 },
            { token = "ITEM_MOD_INTELLECT_SHORT", value = 19 },
            { token = "ITEM_MOD_SPELL_DAMAGE_DONE", value = 26 },
            { token = "ITEM_MOD_POWER_REGEN0_SHORT", value = 6 },
        },
    }
    local role = {
        key = "protection_tank", label = "Protection Tank", confidence = 100,
        statTokens = {
            "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_ARMOR",
            "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT", "ITEM_MOD_BLOCK_RATING_SHORT",
            "ITEM_MOD_BLOCK_VALUE_SHORT", "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
            "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT",
        },
        benchmarks = {
            { key = "defense_crit_immunity", label = "Defense", status = "meets_or_exceeds" },
            { key = "avoidance_table", label = "Shield Table", status = "context_required" },
            { key = "spell_hit", label = "Spell Hit", status = "below" },
        },
    }
    local engine = private.BuildGearRecommendations({
        classEnglish = "PALADIN", locale = "zhCN", equipped = { items = { current } },
    }, { candidate }, { roles = { role } })
    local upgrade = engine.upgrades[1]
    assertEquals(#engine.upgrades, 1)
    assertEquals(upgrade.verdict, "tradeoff")
    assertEquals(upgrade.evidence, "high")
    assertContains(private.DeltaText(upgrade.statGains, "zhCN"), "+6 法术强度")
    assertContains(private.DeltaText(upgrade.statLosses, "zhCN"), "+18 防御等级")
    assertFalse(private.DeltaText(upgrade.statLosses, "zhCN"):find("法术强度", 1, true))
    assertEquals(upgrade.benchmarkImpacts[1].effect, "cap_risk")
end)

test("Strongge style trinket is manual review while the ring is a minor gain", function()
    local role = {
        key = "protection_tank", label = "Protection Tank", confidence = 100,
        statTokens = {
            "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
            "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT", "ITEM_MOD_BLOCK_RATING_SHORT",
        },
        benchmarks = {
            { key = "defense_crit_immunity", label = "Defense", status = "meets_or_exceeds" },
            { key = "avoidance_table", label = "Shield Table", status = "context_required" },
        },
    }
    local profile = {
        classEnglish = "PALADIN", locale = "zhCN",
        equipped = { items = {
            {
                itemID = 27529, name = "巨人塑像", category = "Gear", equipSlot = "INVTYPE_TRINKET",
                classID = 4, subClassID = 0, itemLevel = 115, quality = 4, slotKey = "TRINKET",
                stats = { { token = "ITEM_MOD_BLOCK_RATING_SHORT", value = 32 } },
            },
            {
                itemID = 28675, name = "谢尔曼指环", category = "Gear", equipSlot = "INVTYPE_FINGER",
                classID = 4, subClassID = 0, itemLevel = 115, quality = 4, slotKey = "FINGER",
                stats = {
                    { token = "ITEM_MOD_STAMINA_SHORT", value = 36 },
                    { token = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", value = 23 },
                },
            },
        } },
    }
    local candidates = {
        {
            itemID = 30629, name = "偏移甲虫", category = "Gear", equipSlot = "INVTYPE_TRINKET",
            classID = 4, subClassID = 0, itemLevel = 128, quality = 4, slotKey = "TRINKET",
            stats = { { token = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", value = 42 } },
        },
        {
            itemID = 31319, name = "无懈防御指环", category = "Gear", equipSlot = "INVTYPE_FINGER",
            classID = 4, subClassID = 0, itemLevel = 100, quality = 4, slotKey = "FINGER",
            stats = {
                { token = "ITEM_MOD_STAMINA_SHORT", value = 36 },
                { token = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", value = 26 },
            },
        },
    }
    local engine = private.BuildGearRecommendations(profile, candidates, { roles = { role } })
    local bySlot = {}
    for index = 1, #engine.upgrades do
        bySlot[engine.upgrades[index].slotKey] = engine.upgrades[index]
    end
    assertEquals(bySlot.TRINKET.verdict, "review")
    assertEquals(bySlot.TRINKET.evidence, "low")
    assertEquals(bySlot.FINGER.verdict, "minor")
    assertEquals(bySlot.FINGER.evidence, "medium")
    assertContains(private.VerdictSummary(engine, "zhCN"), "需核对 1")
end)

test("container item values cover missing API, table info, tuple info, and link fallback", function()
    local oldInfo = _G.GetContainerItemInfo
    local oldContainerInfo = _G.C_Container.GetContainerItemInfo
    _G.GetContainerItemInfo = nil
    _G.C_Container.GetContainerItemInfo = nil
    assertEquals(Addon:GetContainerItemValues(0, 1), nil)
    _G.C_Container.GetContainerItemInfo = oldContainerInfo
    _G.GetContainerItemInfo = oldInfo

    local texture, count, quality, link = Addon:GetContainerItemValues(99, 1)
    assertEquals(texture, "potion-icon")
    assertEquals(count, 3)
    assertEquals(quality, 1)
    assertContains(link, "Super Mana Potion")

    texture, count, quality, link = Addon:GetContainerItemValues(98, 1)
    assertEquals(texture, "helm-icon")
    assertEquals(count, 1)
    assertEquals(quality, 3)
    assertContains(link, "Defender Helm")
end)

test("container item values and scans fall back to C_Container APIs", function()
    resetRuntimeState(Addon)
    local oldSlots = _G.GetContainerNumSlots
    local oldInfo = _G.GetContainerItemInfo
    local oldLink = _G.GetContainerItemLink
    _G.GetContainerNumSlots = nil
    _G.GetContainerItemInfo = nil
    _G.GetContainerItemLink = nil

    local texture, count, quality, link = Addon:GetContainerItemValues(0, 1)
    assertEquals(texture, "helm-icon")
    assertEquals(count, 1)
    assertEquals(quality, 3)
    assertContains(link, "Defender Helm")

    local snapshot = Addon:ScanBags()
    assertTrue(#snapshot.items >= 3)
    assertEquals(snapshot.items[1].name, "Defender Helm")

    _G.GetContainerNumSlots = oldSlots
    _G.GetContainerItemInfo = oldInfo
    _G.GetContainerItemLink = oldLink
end)

test("container item values fall back to legacy APIs when C_Container errors", function()
    resetRuntimeState(Addon)
    local oldContainerInfo = _G.C_Container.GetContainerItemInfo
    _G.C_Container.GetContainerItemInfo = function()
        error("container failure")
    end

    local texture, count, quality, link = Addon:GetContainerItemValues(0, 1)
    assertEquals(texture, "helm-icon")
    assertEquals(count, 1)
    assertEquals(quality, 3)
    assertContains(link, "Defender Helm")
    assertContains(Addon.lastContainerError, "container failure")

    _G.C_Container.GetContainerItemInfo = oldContainerInfo
end)

test("BuildItem captures full item metadata and stats", function()
    resetRuntimeState(Addon)
    local item = Addon:BuildItem("bags", 0, 1)
    assertEquals(item.itemID, 1001)
    assertEquals(item.name, "Defender Helm")
    assertEquals(item.category, "Gear")
    assertEquals(item.location, "背包第 1 格")
    assertEquals(item.qualityName, "Rare")
    assertEquals(item.wowheadUrl, "https://www.wowhead.com/tbc/item=1001")
    assertEquals(item.qualityColor, "#0070DD")
    assertEquals(item.nameColored, "|cff0070ddDefender Helm|r")
    assertTrue(#item.stats >= 4)
    assertContains(item.itemString, "item:1001")
end)

test("BuildItem returns nil for empty slots and survives cold cache branches", function()
    assertEquals(Addon:BuildItem("bags", 0, 3), nil)

    mock.badInstantItems[1001] = true
    local item = Addon:BuildItem("bags", 0, 1)
    assertEquals(item.name, "Defender Helm")
    mock.badInstantItems[1001] = nil

    mock.badInfoItems[5001] = true
    setContainerItem(2, 1, 5001, 1)
    item = Addon:BuildItem("bags", 2, 1)
    assertEquals(item.name, "Unknown Cache Item")
    assertEquals(item.category, "Miscellaneous")
    mock.badInfoItems[5001] = nil

    local oldInstant = _G.GetItemInfoInstant
    _G.GetItemInfoInstant = nil
    item = Addon:BuildItem("bags", 0, 2)
    assertEquals(item.category, "Consumables")
    _G.GetItemInfoInstant = oldInstant

    local oldInfo = _G.GetItemInfo
    _G.GetItemInfo = nil
    item = Addon:BuildItem("bags", 0, 1)
    assertEquals(item.name, "Defender Helm")
    assertEquals(item.category, "Gear")
    _G.GetItemInfo = oldInfo
end)

test("scans bags and bank containers into saved snapshots", function()
    resetRuntimeState(Addon)
    local bagSnapshot = Addon:ScanBags()
    assertTrue(#bagSnapshot.items >= 3)
    assertEquals(Addon:GetProfile().localDB.bagItemCount, #bagSnapshot.items)
    assertEquals(Addon:GetProfile().localDB.equippedItemCount, 1)
    assertEquals(Addon:GetProfile().equipped.items[1].itemID, 6001)
    assertEquals(Addon:GetProfile().localDB.version, 2)
    assertEquals(Addon:GetProfile().localDB.name, "TBCGearExporterDB")
    assertEquals(Addon:GetProfile().classLocalized, "Druid")
    assertEquals(Addon:GetProfile().classEnglish, "DRUID")
    assertEquals(Addon:GetProfile().classID, 11)
    assertEquals(Addon:GetProfile().locale, "zhCN")
    assertEquals(Addon:GetBagContainers()[1], 0)

    local bankContainers = Addon:GetBankContainers()
    assertEquals(bankContainers[1], -1)
    assertEquals(bankContainers[#bankContainers], 11)

    local bankSnapshot = Addon:ScanBank()
    assertTrue(#bankSnapshot.items >= 2)
    assertEquals(Addon:GetProfile().localDB.bankItemCount, #bankSnapshot.items)

    local oldSlots = _G.GetContainerNumSlots
    local oldContainerSlots = _G.C_Container.GetContainerNumSlots
    _G.GetContainerNumSlots = nil
    _G.C_Container.GetContainerNumSlots = nil
    local empty = Addon:ScanContainers("bags", { 0 })
    assertEquals(#empty.items, 0)
    _G.C_Container.GetContainerNumSlots = oldContainerSlots
    _G.GetContainerNumSlots = oldSlots
end)

test("scheduled scans handle pending guards, timers, no timers, and bank state", function()
    resetRuntimeState(Addon)
    Addon:ScheduleBagScan()
    Addon:ScheduleBagScan()
    assertEquals(#mock.timers, 1)
    flushTimers()
    assertFalse(Addon.pendingBagScan)

    Addon:ScheduleBankScan()
    assertEquals(#mock.timers, 0)

    Addon.bankOpen = true
    Addon:ScheduleBankScan()
    Addon:ScheduleBankScan()
    assertEquals(#mock.timers, 1)
    flushTimers()
    assertFalse(Addon.pendingBankScan)

    Addon.bankOpen = true
    Addon:ScheduleBankScan()
    Addon.bankOpen = false
    flushTimers()

    local oldTimer = _G.C_Timer
    _G.C_Timer = nil
    Addon:ScheduleBagScan()
    Addon.bankOpen = true
    Addon:ScheduleBankScan()
    assertFalse(Addon.pendingBagScan)
    assertFalse(Addon.pendingBankScan)
    _G.C_Timer = oldTimer
end)

test("scan reports, saved counts, debug output, and text selection are visible", function()
    resetRuntimeState(Addon)
    Addon:SelectExportText()

    local bags = Addon:ScanBagsAndReport(ui("bags_scanned"))
    assertTrue(#bags.items >= 3)
    assertAnyMessageContains(ui("bags_scanned"))
    assertAnyMessageContains("C_Container")

    local bank = Addon:ScanBankAndReport(ui("bank_scanned"))
    assertTrue(#bank.items >= 2)
    assertAnyMessageContains(ui("bank_scanned"))

    local bagCount, bankCount = Addon:SavedItemCounts()
    assertEquals(bagCount, #bags.items)
    assertEquals(bankCount, #bank.items)
    assertEquals(Addon:GetProfile().talents.summary, "0/46/15")
    assertEquals(Addon:GetProfile().localDB.talentPrimaryTab, "Feral Combat")
    assertContains(Addon:FormatScanSummary(ui("bags_label"), bags), "件物品")

    Addon.lastContainerError = "synthetic failure"
    Addon:DebugContainers()
    assertAnyMessageContains("API=C_Container")
    assertAnyMessageContains("first visible bag link=")
    assertAnyMessageContains("last container error=synthetic failure")
end)

test("exports include categories, bank data, gear filters, stats, and empty messages", function()
    resetRuntimeState(Addon)
    Addon:ScanBags()
    Addon:ScanBank()

    local allExport = Addon:BuildExport("all")
    assertContains(allExport, "AI_READY_WOW_TBC_INVENTORY_EXPORT v1")
    assertContains(allExport, "AI_PROMPT:")
    assertContains(allExport, "职业职责分析视角：")
    assertContains(allExport, "character_stats、chart_stats、strategy_book、gear_recommendations")
    assertContains(allExport, "熊形态野性坦克")
    assertContains(allExport, "当前天赋：0/46/15; 主天赋=Feral Combat; 已用点数=61")
    assertTrue(allExport:find("AI_PROMPT:", 1, true) < allExport:find("DATA_JSON:", 1, true))
    assertContains(allExport, "DATA_JSON:")
    assertContains(allExport, "\"ai_prompt\": {")
    assertContains(allExport, "\"class_token\": \"DRUID\"")
    assertContains(allExport, "\"client_locale\": \"zhCN\"")
    assertContains(allExport, "\"prompt_locale\": \"zhCN\"")
    assertContains(allExport, "\"role_context\": [")
    assertContains(allExport, "\"character\": {")
    assertContains(allExport, "\"name\": \"Tester\"")
    assertContains(allExport, "\"realm\": \"Test Realm\"")
    assertContains(allExport, "\"client_locale\": \"zhCN\"")
    assertContains(allExport, "\"class\": \"Druid\"")
    assertContains(allExport, "\"class_id\": 11")
    assertContains(allExport, "\"race\": \"Tauren\"")
    assertContains(allExport, "\"race_token\": \"TAUREN\"")
    assertContains(allExport, "\"group_type\": \"raid\"")
    assertContains(allExport, "\"character_stats\": {")
    assertContains(allExport, "\"level\": 70")
    assertContains(allExport, "\"effective\": 495")
    assertContains(allExport, "\"melee_crit\": 28.5")
    assertContains(allExport, "\"healing\": 900")
    assertContains(allExport, "\"current_talents\": {")
    assertContains(allExport, "\"summary\": \"0/46/15\"")
    assertContains(allExport, "\"primary_tree\": \"Feral Combat\"")
    assertContains(allExport, "\"total_points\": 61")
    assertContains(allExport, "\"points_spent\": 61")
    assertContains(allExport, "\"tree_points\": [")
    assertContains(allExport, "\"points_spent\": 46")
    assertContains(allExport, "\"is_primary\": true")
    assertContains(allExport, "\"unspent_points\": 0")
    assertContains(allExport, "\"name\": \"Ferocity\"")
    assertContains(allExport, "\"rank\": 5")
    assertContains(allExport, "\"current_rank\": 5")
    assertContains(allExport, "\"points\": 5")
    assertContains(allExport, "\"points_spent\": 5")
    assertContains(allExport, "\"max_rank\": 5")
    assertContains(allExport, "\"is_exceptional\": true")
    assertContains(allExport, "\"local_db\": {")
    assertContains(allExport, "\"name\": \"TBCGearExporterDB\"")
    assertContains(allExport, "\"talent_summary\": \"0/46/15\"")
    assertContains(allExport, "\"talent_primary_tree\": \"Feral Combat\"")
    assertContains(allExport, "\"talent_total_points\": 61")
    assertContains(allExport, "\"talent_points_spent\": 61")
    assertContains(allExport, "\"talent_tree_points\": \"Balance 0, Feral Combat 46, Restoration 15\"")
    assertContains(allExport, "\"character_stats_saved_at\":")
    assertContains(allExport, "\"bag_item_count\":")
    assertContains(allExport, "\"equipped_item_count\": 1")
    assertContains(allExport, "\"equipped_saved_at\":")
    assertContains(allExport, "\"name\": \"Gear\"")
    assertContains(allExport, "\"name\": \"Consumables\"")
    assertContains(allExport, "\"stats_text\": \"+27 Stamina")
    assertContains(allExport, "\"location\": \"银行第 1 格\"")
    assertContains(allExport, "\"token\": \"ITEM_MOD_STAMINA_SHORT\"")
    assertContains(allExport, "\"wowhead_url\": \"https://www.wowhead.com/tbc/item=1001\"")
    assertContains(allExport, "\"name_colored\": \"|cff0070ddDefender Helm|r\"")
    assertContains(allExport, "\"quality_color\": \"#0070DD\"")
    assertContains(allExport, "\"chart_stats\": {")
    assertContains(allExport, "\"stack_count\":")
    assertContains(allExport, "\"gear_item_count\": 2")
    assertContains(allExport, "\"average\": 86.6")
    assertContains(allExport, "\"source_counts\": [")
    assertContains(allExport, "\"source_label\": \"背包\"")
    assertContains(allExport, "\"category_counts\": [")
    assertContains(allExport, "\"quality_counts\": [")
    assertContains(allExport, "\"equip_slot_counts\": [")
    assertContains(allExport, "\"slot\": \"INVTYPE_HEAD\"")
    assertContains(allExport, "\"stat_totals\": [")
    assertContains(allExport, "\"strategy_book\": {")
    assertContains(allExport, "\"gear_recommendations\": {")
    assertContains(allExport, "\"equipped_gear\": [")
    assertContains(allExport, "Worn Leather Cap")
    assertContains(allExport, "\"caveat\": \"启发式评分")
    assertContains(allExport, "\"label\": \"Bear Feral Tank\"")
    assertContains(allExport, "\"confidence\": 100")
    assertContains(allExport, "\"tank_mitigation\"")
    assertContains(allExport, "\"known_avoidance_block\": 35")
    assertContains(allExport, "\"status\": \"meets_or_exceeds\"")
    assertContains(allExport, "\"status\": \"near\"")
    assertContains(allExport, "\"label\": \"Crit Rating\"")
    assertContains(allExport, "\"value\": 16")

    local bankExport = Addon:BuildExport("bank")
    assertContains(bankExport, "Arcane Blade")
    assertFalse(bankExport:find("Super Mana Potion", 1, true), "bank export should omit bags")

    local bagExport = Addon:BuildExport("bags")
    assertContains(bagExport, "Super Mana Potion")
    assertFalse(bagExport:find("Arcane Blade", 1, true), "bag export should omit bank")

    local gearExport = Addon:BuildExport("gear")
    assertContains(gearExport, "Defender Helm")
    assertContains(gearExport, "Arcane Blade")
    assertFalse(gearExport:find("Super Mana Potion", 1, true), "gear export should omit non-gear")

    local epicGearExport = Addon:BuildExport("gear", "json", "epic")
    assertContains(epicGearExport, "\"title\": \"Epic only\"")
    assertContains(epicGearExport, "\"quality_id\": 4")
    assertContains(epicGearExport, "Arcane Blade")
    assertContains(epicGearExport, "\"item_count\": 1")
    assertContains(epicGearExport, "\"stat_totals\": [")
    assertContains(epicGearExport, "\"value\": 121")
    assertFalse(epicGearExport:find("Defender Helm", 1, true), "epic gear export should omit rare gear")
    assertFalse(epicGearExport:find("Super Mana Potion", 1, true), "epic gear export should omit consumables")

    local rarePlusText = Addon:BuildExport("all", "text", "rare+")
    assertContains(rarePlusText, "过滤: 精良及以上")
    assertContains(rarePlusText, "Defender Helm")
    assertContains(rarePlusText, "Arcane Blade")
    assertFalse(rarePlusText:find("Super Mana Potion", 1, true), "rare+ export should omit common consumables")

    local jsonExport = Addon:BuildExport("all", "json")
    assertContains(jsonExport, "\"format\": \"tbc_gear_exporter_json_v1\"")
    assertContains(jsonExport, "\"ai_prompt\": {")
    assertContains(jsonExport, "\"items\": [")
    assertContains(jsonExport, "\"wowhead_url\": \"https://www.wowhead.com/tbc/item=1002\"")
    assertContains(jsonExport, "\"quality_color\": \"#A335EE\"")
    assertFalse(jsonExport:find("AI_READY_WOW_TBC_INVENTORY_EXPORT", 1, true), "json export should be pure JSON")

    local markdownExport = Addon:BuildExport("all", "markdown")
    assertContains(markdownExport, "# TBC 装备导出器")
    assertContains(markdownExport, "## 角色概览")
    assertContains(markdownExport, "| 项目 | 当前结果 |")
    assertContains(markdownExport, "## 职责判断")
    assertContains(markdownExport, "## 换装建议")
    assertContains(markdownExport, "优先属性:")
    assertContains(markdownExport, "背包和银行中没有值得")
    assertFalse(markdownExport:find("职业职责分析视角", 1, true), "human-readable Markdown should not duplicate the AI prompt")
    assertContains(markdownExport, "熊形态野性坦克")
    assertContains(markdownExport, "<summary>角色、策略与候选库存详细数据</summary>")
    assertContains(markdownExport, "## 导出信息")
    assertContains(markdownExport, "天赋: 0/46/15; 主天赋=Feral Combat; 已用点数=61")
    assertContains(markdownExport, "客户端语言: zhCN")
    assertContains(markdownExport, "## 属性分析")
    assertContains(markdownExport, "实测命中/暴击：近战命中 8.5%")
    assertContains(markdownExport, "防御免暴基准")
    assertContains(markdownExport, "## 候选物品")
    assertContains(markdownExport, "<details open>")
    assertContains(markdownExport, "<summary>装备 (2)</summary>")
    assertContains(markdownExport, "| 物品 | 品质 | 物品等级 | 来源 | 位置 | 属性 |")
    assertContains(markdownExport, "[Defender Helm](https://www.wowhead.com/tbc/item=1001)")
    assertContains(markdownExport, "Rare (#0070DD)")
    assertContains(markdownExport, "| 115 |")
    assertFalse(markdownExport:find("<span style=", 1, true), "markdown report should use readable links instead of HTML-colored item names")
    assertContains(markdownExport, "## 候选库存统计")
    assertContains(markdownExport, "### 属性合计")
    assertContains(markdownExport, "+16 暴击等级")
    assertFalse(markdownExport:find("INVTYPE_HEAD", 1, true), "readable Chinese Markdown should hide internal slot tokens")

    local textExport = Addon:BuildExport("all", "text")
    assertContains(textExport, "TBC 装备导出器")
    assertFalse(textExport:find("AI 分析指令", 1, true), "plain text should be a readable report; AI Text keeps the prompt")
    assertContains(textExport, "导出信息")
    assertContains(textExport, "熊形态野性坦克")
    assertContains(textExport, "天赋: 0/46/15; 主天赋=Feral Combat; 已用点数=61")
    assertContains(textExport, "客户端语言: zhCN")
    assertContains(textExport, "属性分析")
    assertContains(textExport, "换装建议")
    assertContains(textExport, "当前装备扫描:")
    assertContains(textExport, "实测命中/暴击：近战命中 8.5%")
    assertContains(textExport, "基准：防御免暴基准 = 达标")
    assertContains(textExport, "[装备]")
    assertContains(textExport, "- |cff0070ddDefender Helm|r")
    assertContains(textExport, "Rare (#0070DD)")
    assertContains(textExport, "物品等级: 115")
    assertContains(textExport, "Armor / Plate")
    assertContains(textExport, "Wowhead: https://www.wowhead.com/tbc/item=1001")
    assertContains(textExport, "候选库存统计")
    assertContains(textExport, "来源统计")
    assertContains(textExport, "+16 暴击等级")
    assertFalse(textExport:find("GEAR RECOMMENDATIONS", 1, true), "Chinese text export should not mix English headings")
    assertFalse(textExport:find("INVTYPE_HEAD", 1, true), "Chinese text export should hide internal slot tokens")
    assertFalse(textExport:find("# TBC Gear Exporter", 1, true), "text export should be plain text")

    Addon:ClearProfile()
    local empty = Addon:BuildExport("all")
    assertContains(empty, "\"item_count\": 0")
    assertContains(empty, "\"stack_count\": 0")
    assertContains(empty, "\"stat_totals\": [")
    assertContains(empty, "No saved items match")
    assertContains(Addon:BuildExport("all", "markdown"), "没有已保存物品")
    assertContains(Addon:BuildExport("all", "text"), "没有已保存物品")
end)

test("recommendation exports include current gear and concrete upgrades", function()
    resetRuntimeState(Addon)
    local profile = Addon:GetProfile()
    profile.bags.items = {
        Addon:BuildItemFromLink("bags", mock.itemLinks[6002], { bag = 0, slot = 8, location = "Backpack slot 8" }),
        Addon:BuildItemFromLink("bags", mock.itemLinks[6003], { bag = 0, slot = 9, location = "Backpack slot 9" }),
    }
    profile.bank.items = {}

    local json = Addon:BuildExport("all", "json")
    assertContains(json, "\"gear_recommendations\": {")
    assertContains(json, "\"role_key\": \"bear_tank\"")
    assertContains(json, "\"equipped_count\": 1")
    assertContains(json, "\"candidate_count\": 2")
    assertContains(json, "\"slot_key\": \"HEAD\"")
    assertContains(json, "\"current\": {")
    assertContains(json, "Worn Leather Cap")
    assertContains(json, "\"candidate\": {")
    assertContains(json, "Guardian Leather Crown")
    assertContains(json, "Feral Grips")
    assertContains(json, "\"matched_stats\": [")
    assertContains(json, "\"stat_gains\": [")
    assertContains(json, "\"stat_losses\": [")
    assertContains(json, "\"benchmark_impacts\": [")
    assertContains(json, "\"verdict_counts\": {")
    assertContains(json, "\"verdict\": \"")
    assertContains(json, "\"evidence\": \"high\"")
    assertContains(json, "\"evidence\": \"low\"")
    assertContains(json, "https://www.wowhead.com/tbc/item=6002")

    local markdown = Addon:BuildExport("all", "markdown")
    assertContains(markdown, "## 换装建议")
    assertContains(markdown, "### 1. 头部")
    assertContains(markdown, "[Worn Leather Cap](https://www.wowhead.com/tbc/item=6001)")
    assertContains(markdown, "[Guardian Leather Crown](https://www.wowhead.com/tbc/item=6002)")
    assertContains(markdown, "### 2. 手部")
    assertContains(markdown, "当前装备: 填补空栏位")
    assertContains(markdown, "候选装备: [Feral Grips]")
    assertContains(markdown, "基准影响:")
    assertContains(markdown, "结论")
    assertContains(markdown, "获得:")
    assertContains(markdown, "失去:")
    assertContains(markdown, "高")
    assertContains(markdown, "启发式评分")

    local textExport = Addon:BuildExport("all", "text")
    assertContains(textExport, "1. 头部 ·")
    assertContains(textExport, "当前装备: Worn Leather Cap")
    assertContains(textExport, "候选装备: Guardian Leather Crown")
    assertContains(textExport, "2. 手部 ·")
    assertContains(textExport, "当前装备: 填补空栏位")
    assertContains(textExport, "候选装备: Feral Grips")
    assertContains(textExport, "评分变化 +")
    assertContains(textExport, "基准影响")
    assertContains(textExport, "证据: 高")
    assertContains(textExport, "证据: 低")
end)
test("readable export helpers compact noisy details", function()
	local counts = {
		{ name = "Gear", itemCount = 7 },
		{ name = "Consumables", itemCount = 3 },
		{ name = "Quest", itemCount = 1 },
	}
	assertEquals(private.CompactCountList(counts, function(entry) return entry.name end, 2), "Gear 7, Consumables 3, +1")
	assertEquals(private.CompactCountList({}, function(entry) return entry.name end, 2), "none")
	assertEquals(private.MarkdownPlainItemName({ name = "Plain [Item]|Name" }), "Plain [Item]\\|Name")
	assertEquals(private.ShortStats({
		{ label = "Strength", value = 10 },
		{ label = "Agility", value = 9 },
		{ label = "Stamina", value = 8 },
	}, 2), "+10 Strength, +9 Agility, +1 more")
end)

test("export sorting covers quality, name, location, and unknown category ordering", function()
    resetRuntimeState(Addon)
    local profile = Addon:GetProfile()
    profile.bags.items = {
        { source = "bags", location = "Bag 2 slot 1", count = 1, name = "Zed", quality = 1, qualityName = "Common", itemType = "Mystery", itemID = 9001, category = "Zzz", stats = {} },
        { source = "bags", location = "Bag 1 slot 1", count = 1, name = "Alpha", quality = 1, qualityName = "Common", itemType = "Mystery", itemID = 9002, category = "Aaa", stats = {} },
        { source = "bags", location = "Bag 1 slot 2", count = 1, name = "Alpha", quality = 3, qualityName = "Rare", itemType = "Mystery", itemID = 9003, category = "Aaa", stats = {} },
        { source = "bags", location = "Bag 1 slot 3", count = 1, name = "Alpha", quality = 3, qualityName = "Rare", itemType = "Mystery", item_id = 9004, category = "Aaa", stats = {} },
    }
    profile.bank.items = {}

    local export = Addon:BuildExport("all")
    local aaaIndex = export:find("\"name\": \"Aaa\"", 1, true)
    local zzzIndex = export:find("\"name\": \"Zzz\"", 1, true)
    assertTrue(aaaIndex and zzzIndex and aaaIndex < zzzIndex)
    assertTrue(export:find("\"item_id\": 9003", 1, true) < export:find("\"item_id\": 9002", 1, true))
    assertContains(export, "\"wowhead_url\": \"https://www.wowhead.com/tbc/item=9004\"")
end)

test("RefreshExport no-ops without frame and updates edit box with frame", function()
    resetRuntimeState(Addon)
    Addon:RefreshExport("all")
    assertEquals(Addon.exportScope, "all")

    Addon:ScanBags()
    local profile = Addon:GetProfile()
    profile.bags.items[#profile.bags.items + 1] = Addon:BuildItemFromLink("bags", mock.itemLinks[6002], { bag = 0, slot = 8, location = "Backpack slot 8" })
    profile.bags.items[#profile.bags.items + 1] = Addon:BuildItemFromLink("bags", mock.itemLinks[6003], { bag = 0, slot = 9, location = "Backpack slot 9" })
    Addon:CreateExportFrame()
    Addon:RefreshExport("bags")
    assertContains(Addon.exportFrame.editBox.text, "Super Mana Potion")
    assertEquals(Addon.exportView, "overview")
    assertTrue(Addon.exportFrame.overviewScroll:IsShown())
    assertFalse(Addon.exportFrame.adviceScroll:IsShown())
    assertFalse(Addon.exportFrame.visualScroll:IsShown())
    assertFalse(Addon.exportFrame.analysisScroll:IsShown())
    assertFalse(Addon.exportFrame.textScroll:IsShown())
    assertTrue(#Addon.exportFrame.itemRows >= 1)
    assertContains(Addon.exportFrame.analysisText.text, "属性分析")
    assertContains(Addon.exportFrame.analysisText.text, "熊形态野性坦克")
    assertFalse(Addon.exportFrame.analysisText.text:find("Bear Feral Tank", 1, true), "GUI analysis should localize role labels")
    local sawVisualIcon = false
    for index = 1, #Addon.exportFrame.itemRows do
        local texture = Addon.exportFrame.itemRows[index].icon.texture
        if texture == "potion-icon" or texture == "helm-icon" then
            sawVisualIcon = true
        end
    end
    assertTrue(sawVisualIcon)
    assertContains(Addon.exportFrame.overviewText.text, "总览")
    assertContains(Addon.exportFrame.overviewText.text, "库存：")
    assertContains(Addon.exportFrame.overviewText.text, "熊形态野性坦克")
    assertContains(Addon.exportFrame.status.text, "总览已更新")
    assertContains(Addon.exportFrame.adviceSummary.text, "熊形态野性坦克")
    assertContains(Addon.exportFrame.adviceSummary.text, "配装结论 2 条")
    assertEquals(#Addon.exportFrame.adviceRows, 2)
    Addon:SetExportView("advice")
    Addon:RefreshExport("bags")
    assertTrue(Addon.exportFrame.adviceScroll:IsShown())
    assertFalse(Addon.exportFrame.overviewScroll:IsShown())
    assertContains(Addon.exportFrame.status.text, "装备建议已更新")
    assertContains(Addon.exportFrame.adviceRows[1].name.text .. Addon.exportFrame.adviceRows[2].name.text, "Guardian Leather Crown")
    local adviceWithCurrent
    local adviceWithoutCurrent
    for index = 1, #Addon.exportFrame.adviceRows do
        local row = Addon.exportFrame.adviceRows[index]
        if row.currentButton.item then adviceWithCurrent = row else adviceWithoutCurrent = row end
    end
    adviceWithCurrent.currentButton.scripts.OnEnter(adviceWithCurrent.currentButton)
    assertEquals(_G.GameTooltip.hyperlink, mock.itemLinks[6001])
    adviceWithCurrent.candidateButton.scripts.OnEnter(adviceWithCurrent.candidateButton)
    assertTrue(_G.GameTooltip.shown)
    adviceWithCurrent.candidateButton.scripts.OnLeave()
    assertFalse(_G.GameTooltip.shown)
    adviceWithoutCurrent.currentButton.scripts.OnEnter(adviceWithoutCurrent.currentButton)
    adviceWithoutCurrent.currentButton.scripts.OnLeave()

    Addon:SetExportView("analysis")
    Addon:RefreshExport("bags")
    assertTrue(Addon.exportFrame.analysisScroll:IsShown())
    assertFalse(Addon.exportFrame.overviewScroll:IsShown())
    assertFalse(Addon.exportFrame.visualScroll:IsShown())
    assertFalse(Addon.exportFrame.textScroll:IsShown())
    assertContains(Addon.exportFrame.status.text, "属性分析已更新")
    assertContains(Addon.exportFrame.analysisText.text, "实测命中")
    assertContains(Addon.exportFrame.analysisText.text, "达标")
    assertFalse(Addon.exportFrame.analysisText.text:find("meets_or_exceeds", 1, true), "GUI analysis should localize benchmark status")
    assertContains(Addon.exportFrame.summary.text, "背包：")
end)

test("CreateExportFrame wires UI controls and scripts", function()
    resetRuntimeState(Addon)
    Addon:CreateExportFrame()
    local exportFrame = Addon.exportFrame
    assertEquals(exportFrame.width, 820)
    assertEquals(exportFrame.template, "BackdropTemplate")
    assertFalse(exportFrame:IsShown())
    assertTrue(exportFrame.backdrop ~= nil)
    assertTrue(exportFrame.backdropColor ~= nil)
    assertTrue(exportFrame.backdropBorderColor ~= nil)
    assertTrue(exportFrame.editBox ~= nil)
    assertTrue(exportFrame.summary ~= nil)
    assertTrue(exportFrame.status ~= nil)
    assertTrue(exportFrame.sourceLabel ~= nil)
    assertTrue(exportFrame.filterLabel ~= nil)
    assertTrue(exportFrame.overviewScroll ~= nil)
    assertTrue(exportFrame.adviceScroll ~= nil)
    assertTrue(exportFrame.visualScroll ~= nil)
    assertTrue(exportFrame.analysisScroll ~= nil)
    assertTrue(exportFrame.textScroll ~= nil)
    assertTrue(exportFrame.overviewContent ~= nil)
    assertTrue(exportFrame.overviewText ~= nil)
    assertTrue(exportFrame.adviceContent ~= nil)
    assertTrue(exportFrame.adviceSummary ~= nil)
    assertTrue(exportFrame.adviceCaveat ~= nil)
    assertTrue(exportFrame.adviceRowsContent ~= nil)
    assertTrue(exportFrame.itemListContent ~= nil)
    assertTrue(exportFrame.analysisContent ~= nil)
    assertTrue(exportFrame.analysisText ~= nil)
    assertTrue(exportFrame.overviewScroll:IsShown())
    assertFalse(exportFrame.adviceScroll:IsShown())
    assertFalse(exportFrame.visualScroll:IsShown())
    assertFalse(exportFrame.analysisScroll:IsShown())
    assertFalse(exportFrame.textScroll:IsShown())

    exportFrame.scripts.OnDragStart(exportFrame)
    assertTrue(exportFrame.moving)
    exportFrame.scripts.OnDragStop(exportFrame)
    assertFalse(exportFrame.moving)

    exportFrame.editBox.scripts.OnEscapePressed(exportFrame.editBox)
    assertFalse(exportFrame.editBox.focused)

    exportFrame.editBox.text = "one\ntwo\nthree"
    exportFrame.editBox.scripts.OnTextChanged(exportFrame.editBox)
    assertTrue(exportFrame.editBox.height >= 300)

    exportFrame.editBox.scripts.OnTextChanged({ GetNumLines = function() return 1 end })

    Addon:SetExportView("text")
    assertFalse(exportFrame.overviewScroll:IsShown())
    assertFalse(exportFrame.adviceScroll:IsShown())
    assertFalse(exportFrame.visualScroll:IsShown())
    assertFalse(exportFrame.analysisScroll:IsShown())
    assertTrue(exportFrame.textScroll:IsShown())
    Addon:SetExportView("advice")
    assertFalse(exportFrame.overviewScroll:IsShown())
    assertTrue(exportFrame.adviceScroll:IsShown())
    assertFalse(exportFrame.visualScroll:IsShown())
    assertFalse(exportFrame.analysisScroll:IsShown())
    assertFalse(exportFrame.textScroll:IsShown())
    Addon:SetExportView("analysis")
    assertFalse(exportFrame.overviewScroll:IsShown())
    assertFalse(exportFrame.adviceScroll:IsShown())
    assertFalse(exportFrame.visualScroll:IsShown())
    assertTrue(exportFrame.analysisScroll:IsShown())
    assertFalse(exportFrame.textScroll:IsShown())
    Addon:SetExportView("bogus")
    assertTrue(exportFrame.overviewScroll:IsShown())
    assertFalse(exportFrame.adviceScroll:IsShown())
    assertFalse(exportFrame.visualScroll:IsShown())
    assertFalse(exportFrame.analysisScroll:IsShown())
    assertFalse(exportFrame.textScroll:IsShown())
end)

test("ShowExport creates once and refreshes selected scope", function()
    resetRuntimeState(Addon)
    Addon:ScanBags()
    Addon:ShowExport("bags")
    local firstFrame = Addon.exportFrame
    assertTrue(firstFrame:IsShown())
    assertContains(firstFrame.editBox.text, "\"scope_title\": \"Bags\"")
    Addon:ShowExport("gear")
    assertEquals(Addon.exportFrame, firstFrame)
    assertContains(firstFrame.editBox.text, "\"scope_title\": \"Gear Only\"")
end)

test("minimap button opens export, scans on right click, and shows tooltip", function()
    resetRuntimeState(Addon)
    local button = Addon:CreateMinimapButton()
    assertEquals(button, Addon.minimapButton)
    assertEquals(button.parent, _G.Minimap)
    assertEquals(button.width, 32)
    assertEquals(button.frameStrata, "MEDIUM")
    assertEquals(button.frameLevel, 12)
    assertEquals(button.icon.texture, "Interface\\Icons\\INV_Misc_Bag_10_Blue")
    assertEquals(button.border.texture, "Interface\\Minimap\\MiniMap-TrackingBorder")
    assertEquals(Addon:CreateMinimapButton(), button)

    button.scripts.OnEnter(button)
    assertEquals(GameTooltip.text, ui("addon_title"))
    assertTrue(GameTooltip.shown)
    assertContains(GameTooltip.lines[1], "左键")
    button.scripts.OnLeave(button)
    assertFalse(GameTooltip.shown)

    Addon:ScanBags()
    button.scripts.OnClick(button, "LeftButton")
    assertTrue(Addon.exportFrame:IsShown())
    assertEquals(Addon.exportScope, "all")
    assertAnyMessageContains("本地数据库打开")

    button.scripts.OnClick(button, "RightButton")
    assertAnyMessageContains(ui("bags_scanned"))

    Addon.bankOpen = true
    button.scripts.OnClick(button, "RightButton")
    assertAnyMessageContains(ui("bank_scanned"))

    local oldMinimap = _G.Minimap
    _G.Minimap = nil
    Addon.minimapButton = nil
    assertEquals(Addon:CreateMinimapButton(), nil)
    _G.Minimap = oldMinimap
end)

local function findButtonByText(text)
    for index = #mock.frames, 1, -1 do
        local frame = mock.frames[index]
        if frame.text == text and frame.scripts.OnClick then
            return frame
        end
    end
    error("button not found: " .. text)
end

test("export frame buttons scan and change scopes", function()
    resetRuntimeState(Addon)
    Addon:CreateExportFrame()
    Addon.bankOpen = false
    findButtonByText(ui("scan_button")).scripts.OnClick()
    assertAnyMessageContains(ui("bags_scanned"))
    Addon:ScanBank()
    assertTrue(Addon.exportFrame.overviewScroll:IsShown())
    assertFalse(Addon.exportFrame.adviceScroll:IsShown())
    assertFalse(Addon.exportFrame.visualScroll:IsShown())
    assertTrue(#Addon.exportFrame.itemRows >= 1)
    findButtonByText(ui("items_tab")).scripts.OnClick()
    assertTrue(Addon.exportFrame.visualScroll:IsShown())
    local visualRow = Addon.exportFrame.itemRows[1]
    visualRow.scripts.OnEnter(visualRow)
    assertEquals(GameTooltip.hyperlink, visualRow.item.link)
    assertTrue(GameTooltip.shown)
    visualRow.scripts.OnLeave(visualRow)
    assertFalse(GameTooltip.shown)

    findButtonByText(ui("export_button")).scripts.OnClick()
    assertEquals(Addon.exportScope, "all")
    assertAnyMessageContains("本地数据库打开")

    findButtonByText(ui("bags_button")).scripts.OnClick()
    assertEquals(Addon.exportScope, "bags")
    assertAnyMessageContains("本地数据库打开")

    findButtonByText(ui("bank_button")).scripts.OnClick()
    assertEquals(Addon.exportScope, "bank")
    assertAnyMessageContains("本地数据库打开")

    Addon.bankOpen = true
    findButtonByText(ui("bank_button")).scripts.OnClick()
    assertEquals(Addon.exportScope, "bank")
    assertAnyMessageContains("本地数据库打开")

    findButtonByText(ui("gear_button")).scripts.OnClick()
    assertEquals(Addon.exportScope, "gear")
    assertAnyMessageContains("本地数据库打开")

    findButtonByText(ui("debug_button")).scripts.OnClick()
    assertAnyMessageContains("API=")

    findButtonByText(ui("select_button")).scripts.OnClick()
    assertEquals(Addon.exportView, "text")
    assertTrue(Addon.exportFrame.textScroll:IsShown())
    assertFalse(Addon.exportFrame.visualScroll:IsShown())
    assertEquals(Addon.exportFrame.status.text, ui("status_selected"))

    findButtonByText(ui("overview_tab")).scripts.OnClick()
    assertEquals(Addon.exportView, "overview")
    assertTrue(Addon.exportFrame.overviewScroll:IsShown())
    findButtonByText(ui("items_tab")).scripts.OnClick()
    assertEquals(Addon.exportView, "items")
    assertTrue(Addon.exportFrame.visualScroll:IsShown())
    findButtonByText(ui("stats_analysis_tab")).scripts.OnClick()
    assertEquals(Addon.exportView, "analysis")
    assertTrue(Addon.exportFrame.analysisScroll:IsShown())
    assertFalse(Addon.exportFrame.overviewScroll:IsShown())
    assertFalse(Addon.exportFrame.visualScroll:IsShown())
    assertFalse(Addon.exportFrame.textScroll:IsShown())
    assertContains(Addon.exportFrame.status.text, "属性分析已更新")
    assertContains(Addon.exportFrame.analysisText.text, "熊形态野性坦克")
    assertContains(Addon.exportFrame.analysisText.text, "坦克免伤")
    assertFalse(Addon.exportFrame.analysisText.text:find("tank_mitigation", 1, true), "GUI analysis should localize model names")
    findButtonByText(ui("text_export_tab")).scripts.OnClick()
    assertEquals(Addon.exportView, "text")
    assertTrue(Addon.exportFrame.editBox.highlighted)

    findButtonByText("JSON").scripts.OnClick()
    assertEquals(Addon.exportFormat, "json")
    assertContains(Addon.exportFrame.editBox.text, "\"format\": \"tbc_gear_exporter_json_v1\"")

    findButtonByText("Markdown").scripts.OnClick()
    assertEquals(Addon.exportFormat, "markdown")
    assertContains(Addon.exportFrame.editBox.text, "# TBC 装备导出器")

    findButtonByText(ui("format_text_title")).scripts.OnClick()
    assertEquals(Addon.exportFormat, "text")
    assertContains(Addon.exportFrame.editBox.text, "TBC 装备导出器")

    findButtonByText("AI").scripts.OnClick()
    assertEquals(Addon.exportFormat, "ai")
    assertContains(Addon.exportFrame.editBox.text, "AI_READY_WOW_TBC_INVENTORY_EXPORT")

    findButtonByText(ui("epic_button")).scripts.OnClick()
    assertEquals(Addon.exportFilter.qualityID, 4)
    assertContains(Addon.exportFrame.summary.text, "过滤：仅史诗")
    assertContains(Addon.exportFrame.editBox.text, "Arcane Blade")
    assertFalse(Addon.exportFrame.editBox.text:find("Defender Helm", 1, true), "epic filter should omit rare gear in current gear scope")

    findButtonByText(ui("all_q_button")).scripts.OnClick()
    assertEquals(Addon.exportFilter.qualityID, nil)
    assertEquals(Addon.exportFilter.qualityMin, nil)
    assertContains(Addon.exportFrame.editBox.text, "Defender Helm")

    findButtonByText(ui("rare_plus_button")).scripts.OnClick()
    assertEquals(Addon.exportFilter.qualityMin, 3)
    assertContains(Addon.exportFrame.editBox.text, "Defender Helm")

    findButtonByText(ui("gear_epic_button")).scripts.OnClick()
    assertEquals(Addon.exportScope, "gear")
    assertEquals(Addon.exportFilter.qualityID, 4)
    assertContains(Addon.exportFrame.editBox.text, "Arcane Blade")
    assertFalse(Addon.exportFrame.editBox.text:find("Super Mana Potion", 1, true), "gear epic filter should omit consumables")

    findButtonByText(ui("scan_button")).scripts.OnClick()
    assertEquals(Addon.exportScope, "gear")
end)

test("slash commands cover export modes, scan modes, clear, help, and aliases", function()
    resetRuntimeState(Addon)
    Addon:OnAddonLoaded("OtherAddon")
    assertEquals(SlashCmdList.TBCGEAREXPORTER, nil)
    Addon:OnAddonLoaded("TBCGearExporter")
    assertEquals(SLASH_TBCGEAREXPORTER1, "/tbcgear")
    assertEquals(SLASH_TBCGEAREXPORTER2, "/tbcexport")
    assertTrue(type(SlashCmdList.TBCGEAREXPORTER) == "function")
    Addon:ScanBags()
    Addon:ScanBank()

    Addon:HandleSlash("")
    assertEquals(Addon.exportScope, "all")
    assertAnyMessageContains("本地数据库打开")
    Addon:HandleSlash("gui")
    assertEquals(Addon.exportScope, "all")
    Addon:HandleSlash("show")
    assertEquals(Addon.exportScope, "all")
    Addon:HandleSlash("bags")
    assertEquals(Addon.exportScope, "bags")
    Addon:HandleSlash("bank")
    assertEquals(Addon.exportScope, "bank")
    Addon:HandleSlash("gear")
    assertEquals(Addon.exportScope, "gear")
    assertEquals(Addon.exportFilter.qualityID, nil)
    Addon:HandleSlash("json")
    assertEquals(Addon.exportFormat, "json")
    Addon:HandleSlash("export markdown")
    assertEquals(Addon.exportFormat, "markdown")
    Addon:HandleSlash("bags text")
    assertEquals(Addon.exportScope, "bags")
    assertEquals(Addon.exportFormat, "text")
    Addon:HandleSlash("gear md")
    assertEquals(Addon.exportScope, "gear")
    assertEquals(Addon.exportFormat, "markdown")
    assertEquals(Addon.exportFilter.qualityID, nil)
    Addon:HandleSlash("gear epic")
    assertEquals(Addon.exportScope, "gear")
    assertEquals(Addon.exportFilter.qualityID, 4)
    assertContains(Addon.exportFrame.editBox.text, "Arcane Blade")
    assertFalse(Addon.exportFrame.editBox.text:find("Defender Helm", 1, true), "slash gear epic should omit rare gear")
    Addon:HandleSlash("export gear epic json")
    assertEquals(Addon.exportScope, "gear")
    assertEquals(Addon.exportFormat, "json")
    assertEquals(Addon.exportFilter.qualityID, 4)
    Addon:HandleSlash("rare+ text")
    assertEquals(Addon.exportScope, "all")
    assertEquals(Addon.exportFormat, "text")
    assertEquals(Addon.exportFilter.qualityMin, 3)
    Addon:HandleSlash("json gear epic")
    assertEquals(Addon.exportScope, "gear")
    assertEquals(Addon.exportFormat, "json")
    assertEquals(Addon.exportFilter.qualityID, 4)
    Addon:HandleSlash("gear")
    assertEquals(Addon.exportFilter.qualityID, nil)
    Addon:HandleSlash("scan")
    assertAnyMessageContains(ui("bags_scanned"))

    Addon.bankOpen = true
    Addon:HandleSlash("bank")
    Addon:HandleSlash("gear")
    Addon:HandleSlash("scan")
    assertAnyMessageContains(ui("bank_scanned"))

    Addon:HandleSlash("debug")
    assertAnyMessageContains("API=")

    Addon:HandleSlash("clear")
    assertContains(mock.messages[#mock.messages], "已清除")
    Addon:HandleSlash("wat")
    assertContains(mock.messages[#mock.messages], "命令：")

    SlashCmdList.TBCGEAREXPORTER("export")
    assertEquals(Addon.exportScope, "all")
end)

test("Print uses chat frame and print fallback", function()
    resetRuntimeState(Addon)
    Addon:Print("hello")
    assertContains(mock.messages[#mock.messages], "hello")

    local oldChat = _G.DEFAULT_CHAT_FRAME
    local oldPrint = _G.print
    local printed = {}
    _G.DEFAULT_CHAT_FRAME = nil
    _G.print = function(message)
        printed[#printed + 1] = message
    end
    Addon:Print("fallback")
    assertContains(printed[1], "fallback")
    _G.print = oldPrint
    _G.DEFAULT_CHAT_FRAME = oldChat
end)

test("event dispatcher covers addon, login, bags, bank, and bank slot events", function()
    resetRuntimeState(Addon)
    Addon:OnEvent("ADDON_LOADED", "TBCGearExporter")
    Addon:OnEvent("PLAYER_LOGIN")
    assertContains(mock.messages[#mock.messages], "已加载")
    assertEquals(Addon:GetProfile().talents.primaryTab, "Feral Combat")

    mock.talentTabs[2].points = 42
    mock.talentTabs[3].points = 19
    Addon:OnEvent("PLAYER_TALENT_UPDATE")
    Addon:OnEvent("CHARACTER_POINTS_CHANGED")
    assertEquals(Addon:GetProfile().talents.summary, "0/42/19")

    mock.equippedItems[1] = 6002
    Addon:OnEvent("PLAYER_EQUIPMENT_CHANGED", 1, true)
    assertEquals(Addon:GetProfile().equipped.items[1].itemID, 6002)
    Addon:CreateExportFrame()
    Addon.exportFrame:Show()
    mock.equippedItems[1] = 6001
    Addon:OnEvent("PLAYER_EQUIPMENT_CHANGED", 1, true)
    assertEquals(Addon:GetProfile().equipped.items[1].itemID, 6001)
    assertContains(Addon.exportFrame.overviewText.text, "总览")

    Addon:OnEvent("BAG_OPEN", 0)
    assertContains(mock.messages[#mock.messages], "调试：背包 0 已打开")

    Addon:OnEvent("BAG_OPEN")
    assertContains(mock.messages[#mock.messages], "调试：背包已打开")

    Addon.bankOpen = false
    Addon:OnEvent("BAG_UPDATE")
    flushTimers()

    Addon.bankOpen = true
    Addon:OnEvent("BAG_UPDATE_DELAYED")
    flushTimers()

    Addon:OnEvent("BANKFRAME_OPENED")
    assertTrue(Addon.bankOpen)
    assertContains(mock.messages[#mock.messages], "调试：银行已打开")

    Addon:OnEvent("PLAYERBANKSLOTS_CHANGED")
    flushTimers()
    Addon:OnEvent("PLAYERBANKBAGSLOTS_CHANGED")
    flushTimers()

    Addon:OnEvent("BANKFRAME_CLOSED")
    assertFalse(Addon.bankOpen)
    Addon:OnEvent("UNKNOWN_EVENT")
end)

test("frame event script delegates to addon event handler", function()
    resetRuntimeState(Addon)
    local rootFrame = addonRootFrame()
    rootFrame.scripts.OnEvent(rootFrame, "PLAYER_LOGIN")
    assertContains(mock.messages[#mock.messages], "已加载")
end)

local failures = {}

for index = 1, #tests do
    local ok, err = xpcall(tests[index].fn, debug.traceback)
    if ok then
        io.write(".")
    else
        io.write("F")
        failures[#failures + 1] = {
            name = tests[index].name,
            err = err,
        }
    end
end

debug.sethook()
io.write("\n")

if #failures > 0 then
    for index = 1, #failures do
        io.stderr:write("\nFAIL: " .. failures[index].name .. "\n")
        io.stderr:write(failures[index].err .. "\n")
    end
    os.exit(1)
end

local total = countKeys(executableLines)
local covered = 0

for lineNumber in pairs(executableLines) do
    if coveredLines[lineNumber] then
        covered = covered + 1
    end
end

local coverage = total > 0 and (covered / total * 100) or 100
local missing = sortedMissingLines()

io.write(string.format("%d tests passed\n", #tests))
io.write(string.format("Coverage: %.2f%% (%d/%d executable lines)\n", coverage, covered, total))

if coverage + 0.00001 < COVERAGE_MINIMUM then
    io.stderr:write(string.format("Coverage %.2f%% is below %.2f%%\n", coverage, COVERAGE_MINIMUM))
    if #missing > 0 then
        local preview = {}
        for index = 1, math.min(#missing, 40) do
            preview[#preview + 1] = tostring(missing[index])
        end
        io.stderr:write("Missing executable lines: " .. table.concat(preview, ", ") .. "\n")
    end
    os.exit(1)
end
