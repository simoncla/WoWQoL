---@class QoLToolkit
local addonName, addon = ...

local FastLoot = {}

-- Event frame for this module
local eventFrame = CreateFrame("Frame")

-- Speed up looting
local lootDelay = 0

local function FastLootHandler()
    if not addon.db.fastLoot then return end
    
    local currentTime = GetTime()
    
    -- Prevent too rapid looting which can cause issues
    if currentTime - lootDelay >= 0.3 then
        lootDelay = currentTime
        
        -- Check if auto loot is enabled
        if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
            -- Auto loot all items
            for i = GetNumLootItems(), 1, -1 do
                LootSlot(i)
            end
        end
    end
end

-- Auto confirm loot rolls (bind on pickup, etc.)
local function AutoConfirmLoot()
    if not addon.db.autoConfirmLoot then return end
    
    -- Check for loot confirmation dialogs
    for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsShown() then
            local which = popup.which
            if which == "CONFIRM_LOOT_ROLL" or 
               which == "LOOT_BIND" or 
               which == "EQUIP_BIND" or
               which == "USE_BIND" or
               which == "DELETE_GOOD_ITEM" then
                -- Auto-click the confirm button
                local button = _G["StaticPopup" .. i .. "Button1"]
                if button and button:IsShown() then
                    button:Click()
                end
            end
        end
    end
end

-- Auto close loot window after looting completes
local function AutoCloseLootWindow()
    if not addon.db.autoCloseLoot then return end
    
    if GetNumLootItems() == 0 then
        CloseLoot()
    end
end

function FastLoot:OnInitialize()
    eventFrame:RegisterEvent("LOOT_READY")
    eventFrame:RegisterEvent("LOOT_OPENED")
    eventFrame:RegisterEvent("LOOT_SLOT_CLEARED")
    eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "LOOT_READY" then
            FastLootHandler()
        elseif event == "LOOT_OPENED" then
            FastLootHandler()
        elseif event == "LOOT_SLOT_CLEARED" then
            AutoCloseLootWindow()
        elseif event == "UI_ERROR_MESSAGE" then
            -- Ignore inventory full errors during fast loot
        end
    end)
    
    -- Also create a repeating timer to handle confirmation dialogs
    C_Timer.NewTicker(0.3, AutoConfirmLoot)
end

-- Register the module
addon:RegisterModule("FastLoot", FastLoot)
