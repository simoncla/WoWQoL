---@class QoLToolkit
local addonName, addon = ...

local LootMonitor = {}

-- Constants
local QUALITY_COLORS = {
    [0] = "9d9d9d", -- Poor (gray)
    [1] = "ffffff", -- Common (white)
    [2] = "1eff00", -- Uncommon (green)
    [3] = "0070dd", -- Rare (blue)
    [4] = "a335ee", -- Epic (purple)
    [5] = "ff8000", -- Legendary (orange)
    [6] = "e6cc80", -- Artifact (light gold)
    [7] = "00ccff", -- Heirloom (cyan)
    [8] = "00ccff", -- WoW Token (cyan)
}

local ENTRY_HEIGHT = 50
local ICON_SIZE = 40
local FRAME_WIDTH = 350
local MAX_VISIBLE_ENTRIES = 8

-- Tracked currencies (we'll track changes between updates)
local previousCurrencies = {}

-- Main frame
local mainFrame
local entries = {}
local entryPool = {}

-- Create an entry row
local function CreateEntryRow(parent)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(FRAME_WIDTH - 20, ENTRY_HEIGHT)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    row:SetBackdropColor(0, 0, 0, 0.6)
    row:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    
    -- Icon
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetPoint("LEFT", 5, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim icon borders
    
    -- Main text (item name / currency name / rep name)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.text:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -4)
    row.text:SetPoint("RIGHT", row, "RIGHT", -80, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    
    -- Subtext (ilvl, stats, progress)
    row.subtext = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.subtext:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -2)
    row.subtext:SetPoint("RIGHT", row, "RIGHT", -80, 0)
    row.subtext:SetJustifyH("LEFT")
    row.subtext:SetWordWrap(false)
    
    -- Right text (price / quantity)
    row.rightText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.rightText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.rightText:SetJustifyH("RIGHT")
    
    -- Enable mouse for tooltips
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    row.createdTime = 0
    row.entryType = nil
    row.itemLink = nil
    
    return row
end

-- Get or create an entry row from pool
local function AcquireEntryRow(parent)
    local row = table.remove(entryPool)
    if not row then
        row = CreateEntryRow(parent)
    end
    row:SetParent(parent)
    row:Show()
    return row
end

-- Return entry to pool
local function ReleaseEntryRow(row)
    row:Hide()
    row:SetParent(nil)
    row.itemLink = nil
    table.insert(entryPool, row)
end

-- Format money string
local function FormatMoney(copper)
    local gold = floor(copper / 10000)
    local silver = floor((copper % 10000) / 100)
    local copperRemain = copper % 100
    
    local str = ""
    if gold > 0 then
        str = str .. "|cffffd700" .. gold .. "g|r "
    end
    if silver > 0 or gold > 0 then
        str = str .. "|cffc0c0c0" .. silver .. "s|r "
    end
    str = str .. "|cffeda55f" .. copperRemain .. "c|r"
    
    return str
end

-- Format compact money (for right side)
local function FormatMoneyCompact(copper)
    local gold = floor(copper / 10000)
    local silver = floor((copper % 10000) / 100)
    local copperRemain = copper % 100
    
    return string.format("|cffffd700%dg|r |cffc0c0c0%ds|r |cffeda55f%dc|r", gold, silver, copperRemain)
end

-- Get item stats summary
local function GetItemStatsSummary(itemLink)
    local stats = {}
    local tooltipData = C_TooltipInfo.GetHyperlink(itemLink)
    
    if not tooltipData then return "" end
    
    -- Parse tooltip for key stats
    for _, line in ipairs(tooltipData.lines or {}) do
        local text = line.leftText or ""
        
        -- Look for notable stats
        if text:match("Leech") then
            table.insert(stats, "|cff00ff00Leech|r")
        elseif text:match("Avoidance") then
            table.insert(stats, "|cff00ff00Avoidance|r")
        elseif text:match("Indestructible") then
            table.insert(stats, "|cff00ff00Indestructible|r")
        elseif text:match("Speed") and not text:match("Attack Speed") then
            table.insert(stats, "|cff00ff00Speed|r")
        end
        
        -- Check for sockets
        if text:match("Socket") then
            table.insert(stats, "|cffff00ffSocket|r")
        end
    end
    
    return table.concat(stats, " ")
end

-- Add a new entry
local function AddEntry(entryType, data)
    if not addon.db.lootMonitorEnabled then return end
    
    -- Check type-specific toggles
    if entryType == "item" and not addon.db.lootMonitorShowItems then return end
    if entryType == "money" and not addon.db.lootMonitorShowMoney then return end
    if entryType == "currency" and not addon.db.lootMonitorShowCurrency then return end
    if entryType == "reputation" and not addon.db.lootMonitorShowReputation then return end
    
    local scrollChild = mainFrame.scrollChild
    local row = AcquireEntryRow(scrollChild)
    
    row.createdTime = GetTime()
    row.entryType = entryType
    
    if entryType == "item" then
        local itemName, itemLink, itemQuality, itemLevel, _, _, _, _, _, itemIcon, sellPrice = C_Item.GetItemInfo(data.itemLink)
        
        if itemName then
            row.icon:SetTexture(itemIcon)
            row.itemLink = itemLink
            
            local qualityColor = QUALITY_COLORS[itemQuality] or "ffffff"
            local quantityStr = data.quantity > 1 and (data.quantity .. "x ") or ""
            row.text:SetText(quantityStr .. "|cff" .. qualityColor .. itemName .. "|r")
            
            -- Build subtext with ilvl and stats
            local subParts = {}
            if itemLevel and itemLevel > 1 then
                table.insert(subParts, "|cffffcc00ilvl: " .. itemLevel .. "|r")
            end
            
            local stats = GetItemStatsSummary(itemLink)
            if stats ~= "" then
                table.insert(subParts, stats)
            end
            
            row.subtext:SetText(table.concat(subParts, " "))
            
            -- Vendor price
            if sellPrice and sellPrice > 0 then
                local totalPrice = sellPrice * data.quantity
                row.rightText:SetText(FormatMoneyCompact(totalPrice))
            else
                row.rightText:SetText("")
            end
        else
            -- Item info not cached, try again after a delay
            C_Timer.After(0.5, function()
                if row and row:IsShown() then
                    local name2, link2, quality2, ilvl2, _, _, _, _, _, icon2, price2 = C_Item.GetItemInfo(data.itemLink)
                    if name2 then
                        row.icon:SetTexture(icon2)
                        row.itemLink = link2
                        local qColor = QUALITY_COLORS[quality2] or "ffffff"
                        local qStr = data.quantity > 1 and (data.quantity .. "x ") or ""
                        row.text:SetText(qStr .. "|cff" .. qColor .. name2 .. "|r")
                        
                        local sub = {}
                        if ilvl2 and ilvl2 > 1 then
                            table.insert(sub, "|cffffcc00ilvl: " .. ilvl2 .. "|r")
                        end
                        row.subtext:SetText(table.concat(sub, " "))
                        
                        if price2 and price2 > 0 then
                            row.rightText:SetText(FormatMoneyCompact(price2 * data.quantity))
                        end
                    end
                end
            end)
            
            -- Temporary display
            row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            row.text:SetText(data.itemLink)
            row.subtext:SetText("")
            row.rightText:SetText("")
        end
        
    elseif entryType == "money" then
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        row.text:SetText("|cffffd700Money|r")
        row.subtext:SetText("")
        row.rightText:SetText(FormatMoneyCompact(data.amount))
        row.itemLink = nil
        
    elseif entryType == "currency" then
        local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(data.currencyID)
        if currencyInfo then
            row.icon:SetTexture(currencyInfo.iconFileID)
            
            local quantityStr = data.quantity > 0 and ("+" .. data.quantity .. "x ") or (data.quantity .. "x ")
            local color = data.quantity > 0 and "00ff00" or "ff0000"
            row.text:SetText("|cff" .. color .. quantityStr .. "|r|cffffffff" .. currencyInfo.name .. "|r")
            
            -- Show current/max
            local progressText = ""
            if currencyInfo.maxQuantity and currencyInfo.maxQuantity > 0 then
                progressText = string.format("(|cffffff00%d|r / |cffffff00%d|r)", currencyInfo.quantity, currencyInfo.maxQuantity)
            else
                progressText = string.format("(|cffffff00%d|r)", currencyInfo.quantity)
            end
            row.subtext:SetText(progressText)
            row.rightText:SetText("")
        end
        row.itemLink = nil
        
    elseif entryType == "reputation" then
        row.icon:SetTexture(data.icon or "Interface\\Icons\\Achievement_Reputation_01")
        
        local color = data.amount > 0 and "00ff00" or "ff0000"
        local sign = data.amount > 0 and "+" or ""
        row.text:SetText("|cff" .. color .. sign .. data.amount .. "|r " .. data.factionName .. " Rep")
        
        -- Show progress if available
        if data.current and data.max then
            row.subtext:SetText(string.format("(|cffffff00%d|r / |cffffff00%d|r)", data.current, data.max))
        else
            row.subtext:SetText("")
        end
        row.rightText:SetText("")
        row.itemLink = nil
    end
    
    -- Insert at top
    table.insert(entries, 1, row)
    
    -- Remove excess entries
    while #entries > (addon.db.lootMonitorMaxEntries or MAX_VISIBLE_ENTRIES) do
        local oldRow = table.remove(entries)
        ReleaseEntryRow(oldRow)
    end
    
    -- Reposition all entries
    LootMonitor:RepositionEntries()
    
    -- Show frame if hidden
    if not mainFrame:IsShown() then
        mainFrame:Show()
    end
end

-- Reposition all entries
function LootMonitor:RepositionEntries()
    local yOffset = -5
    for i, row in ipairs(entries) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", mainFrame.scrollChild, "TOPLEFT", 5, yOffset)
        row:SetPoint("TOPRIGHT", mainFrame.scrollChild, "TOPRIGHT", -5, yOffset)
        yOffset = yOffset - ENTRY_HEIGHT - 5
    end
    
    -- Update scroll child height
    local totalHeight = #entries * (ENTRY_HEIGHT + 5) + 10
    mainFrame.scrollChild:SetHeight(math.max(totalHeight, 1))
end

-- Parse loot message
local function ParseLootMessage(msg)
    -- Pattern: You receive loot: [Item Link]x5. or You receive loot: [Item Link].
    local itemLink, quantity = msg:match("You receive loot: (.+)x(%d+)%.")
    if not itemLink then
        itemLink = msg:match("You receive loot: (.+)%.")
        quantity = 1
    end
    
    -- Also match "You receive item: [Item Link]"
    if not itemLink then
        itemLink, quantity = msg:match("You receive item: (.+)x(%d+)")
        if not itemLink then
            itemLink = msg:match("You receive item: (.+)")
            quantity = 1
        end
    end
    
    -- Quest reward pattern
    if not itemLink then
        itemLink = msg:match("Received (.+)%.")
        quantity = 1
    end
    
    return itemLink, tonumber(quantity) or 1
end

-- Parse money message
local function ParseMoneyMessage(msg)
    local gold = tonumber(msg:match("(%d+) Gold")) or 0
    local silver = tonumber(msg:match("(%d+) Silver")) or 0
    local copper = tonumber(msg:match("(%d+) Copper")) or 0
    
    return (gold * 10000) + (silver * 100) + copper
end

-- Update fade for entries
local function UpdateEntryFade()
    local fadeTime = addon.db.lootMonitorFadeTime or 10
    local currentTime = GetTime()
    
    for i = #entries, 1, -1 do
        local row = entries[i]
        local age = currentTime - row.createdTime
        
        if age > fadeTime then
            -- Start fading
            local fadeAlpha = 1 - ((age - fadeTime) / 3) -- 3 second fade
            if fadeAlpha <= 0 then
                table.remove(entries, i)
                ReleaseEntryRow(row)
            else
                row:SetAlpha(fadeAlpha)
            end
        else
            row:SetAlpha(1)
        end
    end
    
    -- Hide frame if no entries
    if #entries == 0 and mainFrame:IsShown() then
        mainFrame:Hide()
    end
    
    LootMonitor:RepositionEntries()
end

-- Create main frame
local function CreateMainFrame()
    local frame = CreateFrame("Frame", "QoLToolkitLootMonitor", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, 300)
    frame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0.4)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relPoint, x, y = self:GetPoint()
        addon.db.lootMonitorPosition = { point = point, relPoint = relPoint, x = x, y = y }
    end)
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetSize(FRAME_WIDTH, 20)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    titleBar:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("LEFT", 8, 0)
    titleText:SetText("|cff00ff00Loot Monitor|r")
    
    -- Close/minimize button (optional)
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("RIGHT", -4, 0)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        -- Clear entries
        for i = #entries, 1, -1 do
            ReleaseEntryRow(entries[i])
            entries[i] = nil
        end
    end)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -25)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(FRAME_WIDTH - 30, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    frame.scrollChild = scrollChild
    frame.scrollFrame = scrollFrame
    
    -- Restore saved position
    if addon.db.lootMonitorPosition then
        local pos = addon.db.lootMonitorPosition
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    end
    
    frame:Hide() -- Start hidden, show when we have entries
    
    return frame
end

-- Event handlers
local eventFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_LOOT" then
        local msg, _, _, _, playerName = ...
        -- Only track our own loot
        local myName = UnitName("player")
        if playerName == myName or playerName == "" then
            local itemLink, quantity = ParseLootMessage(msg)
            if itemLink then
                AddEntry("item", { itemLink = itemLink, quantity = quantity })
            end
        end
        
    elseif event == "CHAT_MSG_MONEY" then
        local msg = ...
        local amount = ParseMoneyMessage(msg)
        if amount > 0 then
            AddEntry("money", { amount = amount })
        end
        
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        local currencyID, quantity, quantityChange = ...
        if currencyID and quantityChange and quantityChange ~= 0 then
            AddEntry("currency", { currencyID = currencyID, quantity = quantityChange })
        end
        
    elseif event == "COMBAT_TEXT_UPDATE" then
        local messageType, factionName, amount = ...
        if messageType == "FACTION" and factionName and amount then
            -- Get faction info
            local factionID
            for i = 1, GetNumFactions() do
                local name, _, _, _, _, _, _, _, _, _, _, _, _, id = GetFactionInfo(i)
                if name == factionName then
                    factionID = id
                    break
                end
            end
            
            local current, max
            if factionID then
                local factionData = C_Reputation.GetFactionDataByID(factionID)
                if factionData then
                    current = factionData.currentReactionThreshold and 
                              (factionData.currentStanding - factionData.currentReactionThreshold) or factionData.currentStanding
                    max = factionData.nextReactionThreshold and 
                          (factionData.nextReactionThreshold - factionData.currentReactionThreshold) or nil
                end
            end
            
            AddEntry("reputation", {
                factionName = factionName,
                amount = amount,
                current = current,
                max = max,
                icon = nil -- Could look up faction icon if desired
            })
        end
        
    elseif event == "UPDATE_FACTION" then
        -- Could be used for tracking all rep changes
    end
end

function LootMonitor:OnInitialize()
    -- Create the main frame
    mainFrame = CreateMainFrame()
    
    -- Register events
    eventFrame:RegisterEvent("CHAT_MSG_LOOT")
    eventFrame:RegisterEvent("CHAT_MSG_MONEY")
    eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    eventFrame:RegisterEvent("COMBAT_TEXT_UPDATE")
    eventFrame:SetScript("OnEvent", OnEvent)
    
    -- Start fade timer
    C_Timer.NewTicker(0.5, UpdateEntryFade)
    
    -- Slash command for testing
    SLASH_LOOTMONITORTEST1 = "/lmtest"
    SlashCmdList["LOOTMONITORTEST"] = function(msg)
        -- Add test entries
        AddEntry("reputation", { factionName = "Iskaara Tuskarr", amount = 80, current = 80, max = 3000 })
        AddEntry("currency", { currencyID = 1792, quantity = 500 }) -- Honor
        AddEntry("money", { amount = 2000000 }) -- 200g
        addon:Print("Added test entries to Loot Monitor")
    end
end

-- Register the module
addon:RegisterModule("LootMonitor", LootMonitor)
