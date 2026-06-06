local ADDON_PATH = "TBCGearExporter/TBCGearExporter.lua"
local COVERAGE_MINIMUM = 99.0

local tests = {}
local coveredLines = {}
local executableLines = {}

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

local function test(name, fn)
    tests[#tests + 1] = { name = name, fn = fn }
end

local mock = {
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

local function installGlobals()
    _G.TBCGearExporterTestMode = true
    _G.BANK_CONTAINER = -1
    _G.NUM_BAG_SLOTS = 4
    _G.NUM_BANKBAGSLOTS = 7
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
    _G.TBCGearExporterDB = nil
    Addon.db = nil
    Addon.pendingBagScan = nil
    Addon.pendingBankScan = nil
    Addon.bankOpen = nil
    Addon.exportFrame = nil
    Addon.exportScope = nil
    Addon.minimapButton = nil
    if _G.GameTooltip then
        _G.GameTooltip.lines = {}
        _G.GameTooltip.text = nil
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
    equipSlot = "",
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

    local lines = {}
    private.AppendIndented(lines, 2, "text")
    assertEquals(lines[1], "  text")
end)

test("location, source, category, copy, and sizing helpers cover branches", function()
    assertEquals(private.LocationLabel("bags", 0, 2), "Backpack slot 2")
    assertEquals(private.LocationLabel("bags", 3, 4), "Bag 3 slot 4")
    assertEquals(private.LocationLabel("bank", -1, 5), "Bank slot 5")
    assertEquals(private.LocationLabel("bank", 6, 7), "Bank bag 2 slot 7")
    assertEquals(private.SourceLabel("bags"), "Bags")
    assertEquals(private.SourceLabel("bank"), "Bank")
    assertEquals(private.SourceLabel(nil), "Unknown")
    assertEquals(private.SourceLabel("guild"), "guild")

    assertEquals(private.CategoryFromInfo(nil, nil, "INVTYPE_HEAD"), "Gear")
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

test("container item values cover missing API, table info, tuple info, and link fallback", function()
    local oldInfo = _G.GetContainerItemInfo
    _G.GetContainerItemInfo = nil
    assertEquals(Addon:GetContainerItemValues(0, 1), nil)
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

test("BuildItem captures full item metadata and stats", function()
    resetRuntimeState(Addon)
    local item = Addon:BuildItem("bags", 0, 1)
    assertEquals(item.itemID, 1001)
    assertEquals(item.name, "Defender Helm")
    assertEquals(item.category, "Gear")
    assertEquals(item.location, "Backpack slot 1")
    assertEquals(item.qualityName, "Rare")
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
    assertEquals(Addon:GetBagContainers()[1], 0)

    local bankContainers = Addon:GetBankContainers()
    assertEquals(bankContainers[1], -1)
    assertEquals(bankContainers[#bankContainers], 11)

    local bankSnapshot = Addon:ScanBank()
    assertTrue(#bankSnapshot.items >= 2)

    local oldSlots = _G.GetContainerNumSlots
    _G.GetContainerNumSlots = nil
    local empty = Addon:ScanContainers("bags", { 0 })
    assertEquals(#empty.items, 0)
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

test("exports include categories, bank data, gear filters, stats, and empty messages", function()
    resetRuntimeState(Addon)
    Addon:ScanBags()
    Addon:ScanBank()

    local allExport = Addon:BuildExport("all")
    assertContains(allExport, "AI_READY_WOW_TBC_INVENTORY_EXPORT v1")
    assertContains(allExport, "DATA_JSON:")
    assertContains(allExport, "\"character\": {")
    assertContains(allExport, "\"name\": \"Tester\"")
    assertContains(allExport, "\"realm\": \"Test Realm\"")
    assertContains(allExport, "\"name\": \"Gear\"")
    assertContains(allExport, "\"name\": \"Consumables\"")
    assertContains(allExport, "\"stats_text\": \"+27 Stamina")
    assertContains(allExport, "\"location\": \"Bank slot 1\"")
    assertContains(allExport, "\"token\": \"ITEM_MOD_STAMINA_SHORT\"")

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

    Addon:ClearProfile()
    local empty = Addon:BuildExport("all")
    assertContains(empty, "\"item_count\": 0")
    assertContains(empty, "No saved items are available")
end)

test("export sorting covers quality, name, location, and unknown category ordering", function()
    resetRuntimeState(Addon)
    local profile = Addon:GetProfile()
    profile.bags.items = {
        { source = "bags", location = "Bag 2 slot 1", count = 1, name = "Zed", quality = 1, qualityName = "Common", itemType = "Mystery", itemID = 9001, category = "Zzz", stats = {} },
        { source = "bags", location = "Bag 1 slot 1", count = 1, name = "Alpha", quality = 1, qualityName = "Common", itemType = "Mystery", itemID = 9002, category = "Aaa", stats = {} },
        { source = "bags", location = "Bag 1 slot 2", count = 1, name = "Alpha", quality = 3, qualityName = "Rare", itemType = "Mystery", itemID = 9003, category = "Aaa", stats = {} },
        { source = "bags", location = "Bag 1 slot 3", count = 1, name = "Alpha", quality = 3, qualityName = "Rare", itemType = "Mystery", itemID = 9004, category = "Aaa", stats = {} },
    }
    profile.bank.items = {}

    local export = Addon:BuildExport("all")
    local aaaIndex = export:find("\"name\": \"Aaa\"", 1, true)
    local zzzIndex = export:find("\"name\": \"Zzz\"", 1, true)
    assertTrue(aaaIndex and zzzIndex and aaaIndex < zzzIndex)
    assertTrue(export:find("\"item_id\": 9003", 1, true) < export:find("\"item_id\": 9002", 1, true))
end)

test("RefreshExport no-ops without frame and updates edit box with frame", function()
    resetRuntimeState(Addon)
    Addon:RefreshExport("all")
    assertEquals(Addon.exportScope, "all")

    Addon:ScanBags()
    Addon:CreateExportFrame()
    Addon:RefreshExport("bags")
    assertContains(Addon.exportFrame.editBox.text, "Super Mana Potion")
    assertTrue(Addon.exportFrame.editBox.highlighted)
    assertTrue(Addon.exportFrame.editBox.focused)
    assertEquals(Addon.exportFrame.status.text, "AI-ready export is selected. Press Ctrl+C to copy.")
end)

test("CreateExportFrame wires UI controls and scripts", function()
    resetRuntimeState(Addon)
    Addon:CreateExportFrame()
    local exportFrame = Addon.exportFrame
    assertEquals(exportFrame.width, 720)
    assertFalse(exportFrame:IsShown())
    assertTrue(exportFrame.backdrop ~= nil)
    assertTrue(exportFrame.editBox ~= nil)
    assertTrue(exportFrame.status ~= nil)

    exportFrame.scripts.OnDragStart(exportFrame)
    assertTrue(exportFrame.moving)
    exportFrame.scripts.OnDragStop(exportFrame)
    assertFalse(exportFrame.moving)

    exportFrame.editBox.scripts.OnEscapePressed(exportFrame.editBox)
    assertFalse(exportFrame.editBox.focused)

    exportFrame.editBox.text = "one\ntwo\nthree"
    exportFrame.editBox.scripts.OnTextChanged(exportFrame.editBox)
    assertTrue(exportFrame.editBox.height >= 380)

    exportFrame.editBox.scripts.OnTextChanged({ GetNumLines = function() return 1 end })
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
    assertEquals(GameTooltip.text, "TBC Gear Exporter")
    assertTrue(GameTooltip.shown)
    assertContains(GameTooltip.lines[1], "Left-click")
    button.scripts.OnLeave(button)
    assertFalse(GameTooltip.shown)

    button.scripts.OnClick(button, "LeftButton")
    assertTrue(Addon.exportFrame:IsShown())
    assertEquals(Addon.exportScope, "all")

    button.scripts.OnClick(button, "RightButton")
    assertContains(mock.messages[#mock.messages], "Bags scanned")

    Addon.bankOpen = true
    button.scripts.OnClick(button, "RightButton")
    assertContains(mock.messages[#mock.messages], "Bags and bank scanned")

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
    findButtonByText("Scan").scripts.OnClick()
    assertContains(mock.messages[#mock.messages], "Bags scanned")

    findButtonByText("All").scripts.OnClick()
    assertEquals(Addon.exportScope, "all")

    findButtonByText("Bags").scripts.OnClick()
    assertEquals(Addon.exportScope, "bags")

    findButtonByText("Bank").scripts.OnClick()
    assertEquals(Addon.exportScope, "bank")
    assertContains(mock.messages[#mock.messages], "last saved bank scan")

    Addon.bankOpen = true
    findButtonByText("Bank").scripts.OnClick()
    assertEquals(Addon.exportScope, "bank")

    findButtonByText("Gear Only").scripts.OnClick()
    assertEquals(Addon.exportScope, "gear")

    findButtonByText("Scan").scripts.OnClick()
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

    Addon:HandleSlash("")
    assertEquals(Addon.exportScope, "all")
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
    Addon:HandleSlash("scan")
    assertContains(mock.messages[#mock.messages], "Bags scanned")

    Addon.bankOpen = true
    Addon:HandleSlash("bank")
    Addon:HandleSlash("gear")
    Addon:HandleSlash("scan")
    assertContains(mock.messages[#mock.messages], "Bags and bank scanned")

    Addon:HandleSlash("clear")
    assertContains(mock.messages[#mock.messages], "cleared")
    Addon:HandleSlash("wat")
    assertContains(mock.messages[#mock.messages], "Commands:")

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
    assertContains(mock.messages[#mock.messages], "Loaded")

    Addon:OnEvent("BAG_OPEN", 0)
    assertContains(mock.messages[#mock.messages], "Debug: bag 0 opened; bags scanned.")

    Addon:OnEvent("BAG_OPEN")
    assertContains(mock.messages[#mock.messages], "Debug: bag opened; bags scanned.")

    Addon.bankOpen = false
    Addon:OnEvent("BAG_UPDATE")
    flushTimers()

    Addon.bankOpen = true
    Addon:OnEvent("BAG_UPDATE_DELAYED")
    flushTimers()

    Addon:OnEvent("BANKFRAME_OPENED")
    assertTrue(Addon.bankOpen)
    assertContains(mock.messages[#mock.messages], "Debug: bank opened; bank scanned.")

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
    assertContains(mock.messages[#mock.messages], "Loaded")
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
