---@class QoLToolkit
local addonName, addon = ...

local Config = {}

-- Configuration categories and their options
local CONFIG_LAYOUT = {
    {
        name = "General",
        icon = "Interface\\Icons\\INV_Misc_Gear_01",
        options = {
            { key = "autoRepair", label = "Auto Repair", desc = "Automatically repair gear at merchants" },
            { key = "useGuildBank", label = "Use Guild Bank", desc = "Prioritize guild bank for repairs" },
            { key = "autoSellJunk", label = "Auto Sell Junk", desc = "Automatically sell gray items" },
            { key = "enhancedTooltips", label = "Enhanced Tooltips", desc = "Show IDs and extra info in tooltips" },
            { key = "showCombatIndicator", label = "Combat Indicator", desc = "Show red bar when in combat" },
        }
    },
    {
        name = "Auto Accept",
        icon = "Interface\\Icons\\Spell_Holy_Resurrection",
        options = {
            { key = "autoAcceptRes", label = "Auto Accept Resurrect", desc = "Automatically accept resurrections" },
            { key = "autoReleasePvP", label = "Auto Release (PvP)", desc = "Auto release spirit in battlegrounds/arenas" },
            { key = "autoAcceptSummon", label = "Auto Accept Summon", desc = "Automatically accept warlock summons" },
            { key = "autoAcceptParty", label = "Auto Accept Party", desc = "Accept party invites from friends/guildies" },
        }
    },
    {
        name = "Chat",
        icon = "Interface\\Icons\\INV_Letter_15",
        options = {
            { key = "shortenChannelNames", label = "Shorten Channels", desc = "Use abbreviated channel names" },
            { key = "chatTimestamps", label = "Timestamps", desc = "Show timestamps in chat" },
            { key = "stickyChannels", label = "Sticky Channels", desc = "Remember last used chat channel" },
        }
    },
    {
        name = "Loot",
        icon = "Interface\\Icons\\INV_Misc_Bag_10_Green",
        options = {
            { key = "fastLoot", label = "Fast Loot", desc = "Speed up looting" },
            { key = "autoConfirmLoot", label = "Auto Confirm BoP", desc = "Auto-confirm Bind on Pickup dialogs" },
            { key = "autoCloseLoot", label = "Auto Close Loot", desc = "Close loot window when empty" },
        }
    },
    {
        name = "Quests",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        options = {
            { key = "autoAcceptQuests", label = "Auto Accept Quests", desc = "Automatically accept quests from NPCs" },
            { key = "autoCompleteQuests", label = "Auto Complete Quests", desc = "Auto turn-in quests (if no reward choice)" },
            { key = "autoSelectGossip", label = "Auto Select Gossip", desc = "Auto-select quest options in gossip" },
            { key = "autoShareQuests", label = "Auto Share Quests", desc = "Share new quests with party" },
            { key = "skipTrivialQuests", label = "Skip Trivial Quests", desc = "Don't auto-accept gray quests" },
            { key = "announceQuestComplete", label = "Announce Completion", desc = "Chat message on quest completion" },
            { key = "questCompleteSound", label = "Completion Sound", desc = "Play sound on objective completion" },
        }
    },
    {
        name = "Screenshots",
        icon = "Interface\\Icons\\INV_Misc_Spyglass_03",
        options = {
            { key = "screenshotAchievements", label = "Achievement Screenshots", desc = "Screenshot when earning achievements" },
            { key = "screenshotLevelUp", label = "Level Up Screenshots", desc = "Screenshot on level up" },
            { key = "screenshotBossKills", label = "Boss Kill Screenshots", desc = "Screenshot after boss kills" },
            { key = "screenshotMythicPlus", label = "M+ Screenshots", desc = "Screenshot on M+ completion" },
        }
    },
    {
        name = "Loot Monitor",
        icon = "Interface\\Icons\\INV_Misc_Bag_10_Green",
        options = {
            { key = "lootMonitorEnabled", label = "Enable Loot Monitor", desc = "Show visual feed of looted items and gains" },
            { key = "lootMonitorShowItems", label = "Show Items", desc = "Display looted items with icons and prices" },
            { key = "lootMonitorShowMoney", label = "Show Money", desc = "Display gold/silver/copper gains" },
            { key = "lootMonitorShowCurrency", label = "Show Currency", desc = "Display Honor, Badges, and other currency gains" },
            { key = "lootMonitorShowReputation", label = "Show Reputation", desc = "Display reputation gains with progress" },
        }
    },
}

-- Create the main config frame
local function CreateConfigFrame()
    -- Main frame
    local frame = CreateFrame("Frame", "QoLToolkitConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()
    
    -- Make it closeable with Escape
    tinsert(UISpecialFrames, "QoLToolkitConfigFrame")
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("|cff00ff00QoL Toolkit|r Configuration")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    
    -- Category tabs on the left
    local categoryFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    categoryFrame:SetSize(140, 420)
    categoryFrame:SetPoint("TOPLEFT", 15, -50)
    categoryFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    categoryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    
    -- Options container on the right
    local optionsContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    optionsContainer:SetSize(420, 420)
    optionsContainer:SetPoint("TOPRIGHT", -15, -50)
    optionsContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    optionsContainer:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    
    -- Scroll frame for options
    local scrollFrame = CreateFrame("ScrollFrame", nil, optionsContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(380, 1) -- Height will be set dynamically
    scrollFrame:SetScrollChild(scrollChild)
    
    frame.scrollChild = scrollChild
    frame.categoryButtons = {}
    frame.optionCheckboxes = {}
    
    -- Create category buttons
    local yOffset = -10
    for i, category in ipairs(CONFIG_LAYOUT) do
        local catButton = CreateFrame("Button", nil, categoryFrame)
        catButton:SetSize(120, 30)
        catButton:SetPoint("TOP", 0, yOffset)
        
        -- Button background
        local bg = catButton:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        catButton.bg = bg
        
        -- Highlight
        local highlight = catButton:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.4, 0.4, 0.4, 0.5)
        
        -- Icon
        local icon = catButton:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", 5, 0)
        icon:SetTexture(category.icon)
        
        -- Text
        local text = catButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        text:SetText(category.name)
        
        catButton.categoryIndex = i
        catButton:SetScript("OnClick", function(self)
            Config:ShowCategory(self.categoryIndex)
        end)
        
        frame.categoryButtons[i] = catButton
        yOffset = yOffset - 35
    end
    
    return frame
end

-- Create a checkbox for an option
local function CreateCheckbox(parent, option, yOffset)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 10, yOffset)
    
    checkbox.Text:SetText(option.label)
    checkbox.Text:SetFontObject("GameFontNormal")
    
    -- Description - attach to checkbox so it gets hidden with it
    local desc = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", checkbox.Text, "BOTTOMLEFT", 0, -2)
    desc:SetText("|cff888888" .. option.desc .. "|r")
    desc:SetJustifyH("LEFT")
    checkbox.desc = desc  -- Store reference
    
    checkbox.optionKey = option.key
    checkbox:SetChecked(addon.db[option.key])
    
    checkbox:SetScript("OnClick", function(self)
        addon.db[self.optionKey] = self:GetChecked()
        addon:Print(option.label .. ":", self:GetChecked() and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r")
    end)
    
    -- Tooltip on hover
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(option.label, 1, 1, 1)
        GameTooltip:AddLine(option.desc, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", GameTooltip_Hide)
    
    return checkbox
end

-- Show a category's options
function Config:ShowCategory(categoryIndex)
    local frame = QoLToolkitConfigFrame
    if not frame then return end
    
    -- Clear existing elements (checkboxes and their children get hidden automatically)
    for _, element in pairs(frame.optionCheckboxes) do
        if element.Hide then
            element:Hide()
        end
        if element.SetParent then
            element:SetParent(nil)
        end
    end
    
    -- Also hide the header if it exists
    if frame.categoryHeader then
        frame.categoryHeader:Hide()
        frame.categoryHeader:SetParent(nil)
        frame.categoryHeader = nil
    end
    
    wipe(frame.optionCheckboxes)
    
    -- Update button highlights
    for i, button in ipairs(frame.categoryButtons) do
        if i == categoryIndex then
            button.bg:SetColorTexture(0.0, 0.4, 0.0, 0.8)
        else
            button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        end
    end
    
    -- Create checkboxes for this category
    local category = CONFIG_LAYOUT[categoryIndex]
    local yOffset = -10
    
    -- Category header
    local header = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, yOffset)
    header:SetText(category.name .. " Settings")
    frame.categoryHeader = header  -- Store separately for cleanup
    
    yOffset = yOffset - 30
    
    for _, option in ipairs(category.options) do
        local checkbox = CreateCheckbox(frame.scrollChild, option, yOffset)
        table.insert(frame.optionCheckboxes, checkbox)
        yOffset = yOffset - 50
    end
    
    -- Update scroll child height
    frame.scrollChild:SetHeight(math.abs(yOffset) + 20)
end

function Config:Toggle()
    if not QoLToolkitConfigFrame then
        CreateConfigFrame()
    end
    
    if QoLToolkitConfigFrame:IsShown() then
        QoLToolkitConfigFrame:Hide()
    else
        QoLToolkitConfigFrame:Show()
        self:ShowCategory(1) -- Show first category by default
    end
end

function Config:OnInitialize()
    -- Update slash command to open config
    local originalHandler = SlashCmdList["QOLTOOLKIT"]
    SlashCmdList["QOLTOOLKIT"] = function(msg)
        local command = msg:lower():trim()
        if command == "" or command == "config" or command == "options" or command == "settings" then
            Config:Toggle()
        else
            originalHandler(msg)
        end
    end
    
    -- Also add to Interface Options (Settings panel)
    local panel = CreateFrame("Frame")
    panel.name = "QoL Toolkit"
    
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ff00QoL Toolkit|r")
    
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("A collection of quality of life improvements")
    
    local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openButton:SetSize(200, 30)
    openButton:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    openButton:SetText("Open QoL Toolkit Config")
    openButton:SetScript("OnClick", function()
        Config:Toggle()
        -- Close the settings panel
        if Settings and Settings.CloseUI then
            Settings.CloseUI()
        elseif InterfaceOptionsFrame then
            InterfaceOptionsFrame:Hide()
        end
    end)
    
    -- Register with the new Settings API (10.0+) or legacy
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end

-- Register the module
addon:RegisterModule("Config", Config)

-- Expose toggle function globally for keybinds
function QoLToolkit_ToggleConfig()
    Config:Toggle()
end
