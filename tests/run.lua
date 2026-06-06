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

    _G.UnitClass = function(unit)
        if unit == "player" then
            return "Druid", "DRUID", 11
        end

        return "Unknown", "UNKNOWN", nil
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
    _G.TBCGearExporterDB = nil
    Addon.db = nil
    Addon.pendingBagScan = nil
    Addon.pendingBankScan = nil
    Addon.bankOpen = nil
    Addon.exportFrame = nil
    Addon.exportScope = nil
    Addon.exportFormat = nil
    Addon.exportFilter = nil
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
    assertEquals(private.ClassToken("death knight"), "DEATH_KNIGHT")
    assertEquals(private.ClassToken(nil), "UNKNOWN")

    local profile = Addon:GetProfile()
    local prompt = private.BuildAIPrompt(profile, "gear", { qualityID = 4 }, 1)
    assertContains(prompt.text, "World of Warcraft: The Burning Crusade Classic")
    assertContains(prompt.text, "Character: Tester - Test Realm (Druid)")
    assertContains(prompt.text, "Export scope: Gear Only; filter: Epic only; item count: 1")
    assertContains(prompt.text, "Bear Feral tank")
    assertContains(prompt.text, "Cat Feral DPS")
    assertContains(prompt.text, "Restoration healing")
    assertContains(prompt.text, "Balance caster")
    assertEquals(prompt.classToken, "DRUID")
    assertTrue(#prompt.roleContext >= 4)
    assertTrue(#prompt.outputRequests >= 6)

    local fallback = private.ClassRoleContext("UNKNOWN")
    assertContains(fallback[1], "Primary role")
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
    assertEquals(item.location, "Backpack slot 1")
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
    assertEquals(Addon:GetProfile().localDB.name, "TBCGearExporterDB")
    assertEquals(Addon:GetProfile().classLocalized, "Druid")
    assertEquals(Addon:GetProfile().classEnglish, "DRUID")
    assertEquals(Addon:GetProfile().classID, 11)
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

    local bags = Addon:ScanBagsAndReport("Bags scanned")
    assertTrue(#bags.items >= 3)
    assertAnyMessageContains("Bags scanned:")
    assertAnyMessageContains("via C_Container")

    local bank = Addon:ScanBankAndReport("Bank scanned")
    assertTrue(#bank.items >= 2)
    assertAnyMessageContains("Bank scanned:")

    local bagCount, bankCount = Addon:SavedItemCounts()
    assertEquals(bagCount, #bags.items)
    assertEquals(bankCount, #bank.items)
    assertContains(Addon:FormatScanSummary("Bags", bags), "items")

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
    assertContains(allExport, "Class role lenses:")
    assertContains(allExport, "Bear Feral tank")
    assertTrue(allExport:find("AI_PROMPT:", 1, true) < allExport:find("DATA_JSON:", 1, true))
    assertContains(allExport, "DATA_JSON:")
    assertContains(allExport, "\"ai_prompt\": {")
    assertContains(allExport, "\"class_token\": \"DRUID\"")
    assertContains(allExport, "\"role_context\": [")
    assertContains(allExport, "\"character\": {")
    assertContains(allExport, "\"name\": \"Tester\"")
    assertContains(allExport, "\"realm\": \"Test Realm\"")
    assertContains(allExport, "\"class\": \"Druid\"")
    assertContains(allExport, "\"class_id\": 11")
    assertContains(allExport, "\"local_db\": {")
    assertContains(allExport, "\"name\": \"TBCGearExporterDB\"")
    assertContains(allExport, "\"bag_item_count\":")
    assertContains(allExport, "\"name\": \"Gear\"")
    assertContains(allExport, "\"name\": \"Consumables\"")
    assertContains(allExport, "\"stats_text\": \"+27 Stamina")
    assertContains(allExport, "\"location\": \"Bank slot 1\"")
    assertContains(allExport, "\"token\": \"ITEM_MOD_STAMINA_SHORT\"")
    assertContains(allExport, "\"wowhead_url\": \"https://www.wowhead.com/tbc/item=1001\"")
    assertContains(allExport, "\"name_colored\": \"|cff0070ddDefender Helm|r\"")
    assertContains(allExport, "\"quality_color\": \"#0070DD\"")

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
    assertFalse(epicGearExport:find("Defender Helm", 1, true), "epic gear export should omit rare gear")
    assertFalse(epicGearExport:find("Super Mana Potion", 1, true), "epic gear export should omit consumables")

    local rarePlusText = Addon:BuildExport("all", "text", "rare+")
    assertContains(rarePlusText, "Filter: Rare+")
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
    assertContains(markdownExport, "# TBC Gear Exporter")
    assertContains(markdownExport, "## AI Prompt")
    assertContains(markdownExport, "Bear Feral tank")
    assertContains(markdownExport, "## Export Metadata")
    assertContains(markdownExport, "## Gear")
    assertContains(markdownExport, "<span style=\"color:#0070DD\"><strong>Defender Helm</strong></span>")
    assertContains(markdownExport, "Rare (#0070DD)")
    assertContains(markdownExport, "iLvl: 115")
    assertContains(markdownExport, "Type: Armor / Plate")
    assertContains(markdownExport, "Wowhead: https://www.wowhead.com/tbc/item=1001")

    local textExport = Addon:BuildExport("all", "text")
    assertContains(textExport, "TBC Gear Exporter")
    assertContains(textExport, "AI PROMPT")
    assertContains(textExport, "EXPORT METADATA")
    assertContains(textExport, "Bear Feral tank")
    assertContains(textExport, "[Gear]")
    assertContains(textExport, "- |cff0070ddDefender Helm|r")
    assertContains(textExport, "Rare (#0070DD)")
    assertContains(textExport, "iLvl: 115")
    assertContains(textExport, "Type: Armor / Plate")
    assertContains(textExport, "Wowhead: https://www.wowhead.com/tbc/item=1001")
    assertFalse(textExport:find("# TBC Gear Exporter", 1, true), "text export should be plain text")

    Addon:ClearProfile()
    local empty = Addon:BuildExport("all")
    assertContains(empty, "\"item_count\": 0")
    assertContains(empty, "No saved items match")
    assertContains(Addon:BuildExport("all", "markdown"), "No saved items are available")
    assertContains(Addon:BuildExport("all", "text"), "No saved items are available")
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
    Addon:CreateExportFrame()
    Addon:RefreshExport("bags")
    assertContains(Addon.exportFrame.editBox.text, "Super Mana Potion")
    assertTrue(Addon.exportFrame.editBox.highlighted)
    assertTrue(Addon.exportFrame.editBox.focused)
    assertEquals(Addon.exportFrame.status.text, "AI Text export generated from saved local DB with filter: All qualities. Press Ctrl+C to copy.")
    assertContains(Addon.exportFrame.summary.text, "Bags:")
end)

test("CreateExportFrame wires UI controls and scripts", function()
    resetRuntimeState(Addon)
    Addon:CreateExportFrame()
    local exportFrame = Addon.exportFrame
    assertEquals(exportFrame.width, 680)
    assertEquals(exportFrame.template, "BackdropTemplate")
    assertFalse(exportFrame:IsShown())
    assertTrue(exportFrame.backdrop ~= nil)
    assertTrue(exportFrame.backdropColor ~= nil)
    assertTrue(exportFrame.backdropBorderColor ~= nil)
    assertTrue(exportFrame.editBox ~= nil)
    assertTrue(exportFrame.summary ~= nil)
    assertTrue(exportFrame.status ~= nil)
    assertTrue(exportFrame.filterLabel ~= nil)

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

    Addon:ScanBags()
    button.scripts.OnClick(button, "LeftButton")
    assertTrue(Addon.exportFrame:IsShown())
    assertEquals(Addon.exportScope, "all")
    assertAnyMessageContains("export opened from local DB")

    button.scripts.OnClick(button, "RightButton")
    assertAnyMessageContains("Bags scanned")

    Addon.bankOpen = true
    button.scripts.OnClick(button, "RightButton")
    assertAnyMessageContains("Bank scanned")

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
    findButtonByText("Scan Bags").scripts.OnClick()
    assertAnyMessageContains("Bags scanned")
    Addon:ScanBank()

    findButtonByText("Export").scripts.OnClick()
    assertEquals(Addon.exportScope, "all")
    assertAnyMessageContains("export opened from local DB")

    findButtonByText("Bags").scripts.OnClick()
    assertEquals(Addon.exportScope, "bags")
    assertAnyMessageContains("export opened from local DB")

    findButtonByText("Bank").scripts.OnClick()
    assertEquals(Addon.exportScope, "bank")
    assertAnyMessageContains("export opened from local DB")

    Addon.bankOpen = true
    findButtonByText("Bank").scripts.OnClick()
    assertEquals(Addon.exportScope, "bank")
    assertAnyMessageContains("export opened from local DB")

    findButtonByText("Gear").scripts.OnClick()
    assertEquals(Addon.exportScope, "gear")
    assertAnyMessageContains("export opened from local DB")

    findButtonByText("Debug").scripts.OnClick()
    assertAnyMessageContains("API=")

    findButtonByText("Select").scripts.OnClick()
    assertEquals(Addon.exportFrame.status.text, "Export text selected. Press Ctrl+C to copy.")

    findButtonByText("JSON").scripts.OnClick()
    assertEquals(Addon.exportFormat, "json")
    assertContains(Addon.exportFrame.editBox.text, "\"format\": \"tbc_gear_exporter_json_v1\"")

    findButtonByText("Markdown").scripts.OnClick()
    assertEquals(Addon.exportFormat, "markdown")
    assertContains(Addon.exportFrame.editBox.text, "# TBC Gear Exporter")

    findButtonByText("Text").scripts.OnClick()
    assertEquals(Addon.exportFormat, "text")
    assertContains(Addon.exportFrame.editBox.text, "TBC Gear Exporter")

    findButtonByText("AI").scripts.OnClick()
    assertEquals(Addon.exportFormat, "ai")
    assertContains(Addon.exportFrame.editBox.text, "AI_READY_WOW_TBC_INVENTORY_EXPORT")

    findButtonByText("Epic").scripts.OnClick()
    assertEquals(Addon.exportFilter.qualityID, 4)
    assertContains(Addon.exportFrame.summary.text, "Filter: Epic only")
    assertContains(Addon.exportFrame.editBox.text, "Arcane Blade")
    assertFalse(Addon.exportFrame.editBox.text:find("Defender Helm", 1, true), "epic filter should omit rare gear in current gear scope")

    findButtonByText("All Q").scripts.OnClick()
    assertEquals(Addon.exportFilter.qualityID, nil)
    assertEquals(Addon.exportFilter.qualityMin, nil)
    assertContains(Addon.exportFrame.editBox.text, "Defender Helm")

    findButtonByText("Rare+").scripts.OnClick()
    assertEquals(Addon.exportFilter.qualityMin, 3)
    assertContains(Addon.exportFrame.editBox.text, "Defender Helm")

    findButtonByText("Gear Epic").scripts.OnClick()
    assertEquals(Addon.exportScope, "gear")
    assertEquals(Addon.exportFilter.qualityID, 4)
    assertContains(Addon.exportFrame.editBox.text, "Arcane Blade")
    assertFalse(Addon.exportFrame.editBox.text:find("Super Mana Potion", 1, true), "gear epic filter should omit consumables")

    findButtonByText("Scan Bags").scripts.OnClick()
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
    assertAnyMessageContains("export opened from local DB")
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
    assertAnyMessageContains("Bags scanned")

    Addon.bankOpen = true
    Addon:HandleSlash("bank")
    Addon:HandleSlash("gear")
    Addon:HandleSlash("scan")
    assertAnyMessageContains("Bank scanned")

    Addon:HandleSlash("debug")
    assertAnyMessageContains("API=")

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
    assertContains(mock.messages[#mock.messages], "Debug: bag 0 opened; bags:")

    Addon:OnEvent("BAG_OPEN")
    assertContains(mock.messages[#mock.messages], "Debug: bag opened; bags:")

    Addon.bankOpen = false
    Addon:OnEvent("BAG_UPDATE")
    flushTimers()

    Addon.bankOpen = true
    Addon:OnEvent("BAG_UPDATE_DELAYED")
    flushTimers()

    Addon:OnEvent("BANKFRAME_OPENED")
    assertTrue(Addon.bankOpen)
    assertContains(mock.messages[#mock.messages], "Debug: bank opened; bank:")

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
