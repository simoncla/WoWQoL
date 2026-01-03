---@class QoLToolkit
local addonName, addon = ...

local AutoScreenshot = {}

-- Event frame for this module
local eventFrame = CreateFrame("Frame")

-- Take screenshot for achievement
local function OnAchievementEarned(achievementID)
    if not addon.db.screenshotAchievements then return end
    
    -- Small delay to let the UI update with the achievement toast
    C_Timer.After(1, function()
        Screenshot()
        local _, name = GetAchievementInfo(achievementID)
        addon:Print("Screenshot saved for achievement: " .. (name or "Unknown"))
    end)
end

-- Take screenshot on level up
local function OnPlayerLevelUp(level, ...)
    if not addon.db.screenshotLevelUp then return end
    
    C_Timer.After(1, function()
        Screenshot()
        addon:Print("Screenshot saved for reaching level " .. level)
    end)
end

-- Take screenshot on boss kill
local function OnBossKill(encounterID, encounterName, difficultyID, groupSize, success)
    if not addon.db.screenshotBossKills then return end
    if not success then return end
    
    C_Timer.After(2, function()
        Screenshot()
        addon:Print("Screenshot saved for defeating: " .. (encounterName or "Unknown Boss"))
    end)
end

-- Take screenshot on challenge mode completion
local function OnChallengeModeComplete()
    if not addon.db.screenshotMythicPlus then return end
    
    C_Timer.After(2, function()
        Screenshot()
        
        local mapID = C_ChallengeMode.GetActiveChallengeMapID()
        local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()
        local mapName = mapID and C_ChallengeMode.GetMapUIInfo(mapID) or "Unknown Dungeon"
        
        addon:Print(format("Screenshot saved for completing %s +%d", mapName, level or 0))
    end)
end

function AutoScreenshot:OnInitialize()
    eventFrame:RegisterEvent("ACHIEVEMENT_EARNED")
    eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
    eventFrame:RegisterEvent("ENCOUNTER_END")
    eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ACHIEVEMENT_EARNED" then
            local achievementID = ...
            OnAchievementEarned(achievementID)
        elseif event == "PLAYER_LEVEL_UP" then
            local level = ...
            OnPlayerLevelUp(level, ...)
        elseif event == "ENCOUNTER_END" then
            OnBossKill(...)
        elseif event == "CHALLENGE_MODE_COMPLETED" then
            OnChallengeModeComplete()
        end
    end)
end

-- Register the module
addon:RegisterModule("AutoScreenshot", AutoScreenshot)
