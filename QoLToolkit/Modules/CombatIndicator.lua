---@class QoLToolkit
local addonName, addon = ...

local CombatIndicator = {}

-- Create the visual indicator frame
local indicatorFrame

local function CreateIndicator()
    if indicatorFrame then return end
    
    indicatorFrame = CreateFrame("Frame", "QoLToolkitCombatIndicator", UIParent)
    indicatorFrame:SetSize(UIParent:GetWidth(), 4)
    indicatorFrame:SetPoint("TOP", UIParent, "TOP", 0, 0)
    indicatorFrame:SetFrameStrata("HIGH")
    
    -- Create the glowing texture
    local texture = indicatorFrame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetColorTexture(1, 0, 0, 0.6) -- Red color
    indicatorFrame.texture = texture
    
    -- Create pulse animation
    local animGroup = indicatorFrame:CreateAnimationGroup()
    animGroup:SetLooping("BOUNCE")
    
    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.6)
    fadeOut:SetToAlpha(0.2)
    fadeOut:SetDuration(0.8)
    fadeOut:SetSmoothing("IN_OUT")
    
    indicatorFrame.animGroup = animGroup
    indicatorFrame:Hide()
end

local function ShowCombatIndicator()
    if not addon.db.showCombatIndicator then return end
    if not indicatorFrame then CreateIndicator() end
    
    indicatorFrame:Show()
    indicatorFrame.animGroup:Play()
end

local function HideCombatIndicator()
    if not indicatorFrame then return end
    
    indicatorFrame.animGroup:Stop()
    indicatorFrame:Hide()
end

-- Event frame for this module
local eventFrame = CreateFrame("Frame")

function CombatIndicator:OnInitialize()
    CreateIndicator()
    
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            ShowCombatIndicator()
        elseif event == "PLAYER_REGEN_ENABLED" then
            HideCombatIndicator()
        end
    end)
    
    -- Check if already in combat on login
    if InCombatLockdown() then
        ShowCombatIndicator()
    end
end

-- Register the module
addon:RegisterModule("CombatIndicator", CombatIndicator)
