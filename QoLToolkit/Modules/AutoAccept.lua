---@class QoLToolkit
local addonName, addon = ...

local AutoAccept = {}

-- Event frame for this module
local eventFrame = CreateFrame("Frame")

-- Auto accept resurrection
local function OnResurrectRequest()
    if not addon.db.autoAcceptRes then return end
    
    -- Check if there's a pending resurrection
    local resurrectionPending = UnitHasIncomingResurrection("player") or 
                                 C_DeathInfo.GetSelfResurrectOptions() ~= nil
    
    -- Auto accept after a short delay to allow cancellation
    C_Timer.After(0.5, function()
        if StaticPopup_Visible("RESURRECT") or StaticPopup_Visible("RESURRECT_NO_SICKNESS") then
            AcceptResurrect()
            StaticPopup_Hide("RESURRECT")
            StaticPopup_Hide("RESURRECT_NO_SICKNESS")
            addon:Print("Auto-accepted resurrection")
        end
    end)
end

-- Auto release in battlegrounds/arenas
local function OnPlayerDead()
    if not addon.db.autoReleasePvP then return end
    
    local instanceType = select(2, GetInstanceInfo())
    
    -- Only auto-release in PvP instances
    if instanceType == "pvp" or instanceType == "arena" then
        C_Timer.After(0.5, function()
            if UnitIsDeadOrGhost("player") and not UnitIsFeignDeath("player") then
                RepopMe()
                addon:Print("Auto-released in PvP")
            end
        end)
    end
end

-- Auto accept summons
local function OnSummonConfirm()
    if not addon.db.autoAcceptSummon then return end
    
    -- Get summon info
    local summonArea = C_SummonInfo.GetSummonConfirmAreaName()
    
    if summonArea then
        C_Timer.After(1, function()
            if C_SummonInfo.GetSummonConfirmTimeLeft() and C_SummonInfo.GetSummonConfirmTimeLeft() > 0 then
                C_SummonInfo.ConfirmSummon()
                StaticPopup_Hide("CONFIRM_SUMMON")
                addon:Print("Auto-accepted summon to " .. summonArea)
            end
        end)
    end
end

-- Auto accept party invites from friends/guildies
local function OnPartyInvite(name)
    if not addon.db.autoAcceptParty then return end
    
    -- Check if inviter is a friend or guildie
    local isFriend = C_FriendList.IsFriend(name) or C_BattleNet.GetFriendAccountInfo(name)
    local isGuildMember = false
    
    if IsInGuild() then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local guildMemberName = GetGuildRosterInfo(i)
            if guildMemberName and guildMemberName:find(name) then
                isGuildMember = true
                break
            end
        end
    end
    
    if isFriend or isGuildMember then
        C_Timer.After(0.5, function()
            AcceptGroup()
            StaticPopup_Hide("PARTY_INVITE")
            addon:Print("Auto-accepted party invite from " .. name)
        end)
    end
end

function AutoAccept:OnInitialize()
    eventFrame:RegisterEvent("RESURRECT_REQUEST")
    eventFrame:RegisterEvent("PLAYER_DEAD")
    eventFrame:RegisterEvent("CONFIRM_SUMMON")
    eventFrame:RegisterEvent("PARTY_INVITE_REQUEST")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "RESURRECT_REQUEST" then
            OnResurrectRequest()
        elseif event == "PLAYER_DEAD" then
            OnPlayerDead()
        elseif event == "CONFIRM_SUMMON" then
            OnSummonConfirm()
        elseif event == "PARTY_INVITE_REQUEST" then
            local name = ...
            OnPartyInvite(name)
        end
    end)
end

-- Register the module
addon:RegisterModule("AutoAccept", AutoAccept)
