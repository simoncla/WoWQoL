---@class QoLToolkit
local addonName, addon = ...

-- Create the main addon table and make it globally accessible
QoLToolkit = addon

-- Addon metadata
addon.name = addonName
addon.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-- Saved variables default structure
addon.defaults = {
    -- Auto Repair
    autoRepair = true,
    useGuildBank = true,
    
    -- Auto Sell Junk
    autoSellJunk = true,
    
    -- Enhanced Tooltips
    enhancedTooltips = true,
    
    -- Auto Accept
    autoAcceptRes = true,
    autoReleasePvP = true,
    autoAcceptSummon = true,
    autoAcceptParty = true,  -- Only from friends/guildies
    
    -- Chat Improvements
    shortenChannelNames = true,
    chatTimestamps = true,
    timestampFormat = "HH:MM",
    stickyChannels = true,
    
    -- Fast Loot
    fastLoot = true,
    autoConfirmLoot = true,
    autoCloseLoot = true,
    
    -- Quest Helper
    autoAcceptQuests = false,  -- Off by default as some prefer manual
    autoCompleteQuests = false,
    autoSelectGossip = false,
    autoShareQuests = true,
    skipTrivialQuests = true,
    announceQuestProgress = true,
    announceQuestComplete = true,
    questCompleteSound = true,
    showQuestObjectives = true,
    
    -- Auto Screenshot
    screenshotAchievements = true,
    screenshotLevelUp = true,
    screenshotBossKills = false,  -- Can generate many screenshots
    screenshotMythicPlus = true,
    
    -- Combat Indicator
    showCombatIndicator = true,
    
    -- Loot Monitor
    lootMonitorEnabled = true,
    lootMonitorShowItems = true,
    lootMonitorShowMoney = true,
    lootMonitorShowCurrency = true,
    lootMonitorShowReputation = true,
    lootMonitorMaxEntries = 8,
    
    -- Loot Monitor Duration by Quality (seconds)
    lootMonitorDurationPoor = 3,
    lootMonitorDurationCommon = 5,
    lootMonitorDurationUncommon = 10,
    lootMonitorDurationRare = 15,
    lootMonitorDurationEpic = 20,
    lootMonitorDurationLegendary = 40,
    lootMonitorDurationArtifact = 15,
    lootMonitorDurationHeirloom = 15,
    
    -- Loot Monitor Duration by Type (seconds)
    lootMonitorDurationGold = 3,
    lootMonitorDurationReputation = 15,
    lootMonitorDurationCurrency = 15,
    
    -- Loot Monitor Display Options
    lootMonitorShowCopperSilver = true, -- Show low-value money pickups
    lootMonitorShowHonor = true, -- Show honor currency
    lootMonitorShowAHPrice = true, -- Show auction house price from Auctionator/TSM
    lootMonitorFadeSlide = "right", -- Slide direction when fading: "none", "left", "right"
    lootMonitorFadeDuration = 0.5, -- Fade/slide duration in seconds (0.1 to 2.0)
}

-- Initialize saved variables
local function InitializeSavedVariables()
    if not QoLToolkitDB then
        QoLToolkitDB = {}
    end
    
    -- Merge defaults with saved data
    for key, value in pairs(addon.defaults) do
        if QoLToolkitDB[key] == nil then
            QoLToolkitDB[key] = value
        end
    end
    
    addon.db = QoLToolkitDB
end

-- Print helper function
function addon:Print(...)
    local prefix = "|cff00ff00[QoL Toolkit]|r"
    print(prefix, ...)
end

-- Slash command handler
local function SlashCommandHandler(msg)
    local command = msg:lower():trim()
    
    if command == "" or command == "help" then
        addon:Print("Commands:")
        addon:Print("  /qol config - Open configuration")
        addon:Print("  /qol repair - Toggle auto repair")
        addon:Print("  /qol junk - Toggle auto sell junk")
        addon:Print("  /qol tooltips - Toggle enhanced tooltips")
    elseif command == "repair" then
        addon.db.autoRepair = not addon.db.autoRepair
        addon:Print("Auto Repair:", addon.db.autoRepair and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r")
    elseif command == "junk" then
        addon.db.autoSellJunk = not addon.db.autoSellJunk
        addon:Print("Auto Sell Junk:", addon.db.autoSellJunk and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r")
    elseif command == "tooltips" then
        addon.db.enhancedTooltips = not addon.db.enhancedTooltips
        addon:Print("Enhanced Tooltips:", addon.db.enhancedTooltips and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r")
    elseif command == "config" then
        -- Will be implemented when we add a config UI
        addon:Print("Configuration UI coming soon!")
    else
        addon:Print("Unknown command. Type /qol help for a list of commands.")
    end
end

-- Register slash commands
SLASH_QOLTOOLKIT1 = "/qol"
SLASH_QOLTOOLKIT2 = "/qoltoolkit"
SlashCmdList["QOLTOOLKIT"] = SlashCommandHandler

-- Main event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            InitializeSavedVariables()
            addon:InitializeAllModules()  -- Initialize all queued modules now that db is ready
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        addon:Print("v" .. addon.version .. " loaded. Type /qol for commands.")
    end
end)

-- Module registration system
addon.modules = {}
addon.pendingModules = {}
addon.initialized = false

function addon:RegisterModule(name, module)
    self.modules[name] = module
    
    -- If addon is already initialized, call OnInitialize immediately
    if self.initialized then
        if module.OnInitialize then
            module:OnInitialize()
        end
    else
        -- Queue for later initialization
        table.insert(self.pendingModules, module)
    end
end

function addon:InitializeAllModules()
    self.initialized = true
    for _, module in ipairs(self.pendingModules) do
        if module.OnInitialize then
            module:OnInitialize()
        end
    end
    wipe(self.pendingModules)
end

function addon:GetModule(name)
    return self.modules[name]
end

