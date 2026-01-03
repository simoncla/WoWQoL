---@class QoLToolkit
local addonName, addon = ...

local QuestHelper = {}

-- Event frame for this module
local eventFrame = CreateFrame("Frame")

-- Auto accept quests from NPCs
local function AutoAcceptQuest()
    if not addon.db.autoAcceptQuests then return end
    
    -- Don't auto-accept certain types
    local questInfo = C_QuestLog.GetQuestInfo(GetQuestID())
    
    -- Check if this is a trivial (gray) quest
    if addon.db.skipTrivialQuests and C_QuestLog.IsQuestTrivial(GetQuestID()) then
        return
    end
    
    -- Auto accept the quest
    AcceptQuest()
end

-- Auto complete quests at NPCs
local function AutoCompleteQuest()
    if not addon.db.autoCompleteQuests then return end
    
    -- Check if there are multiple rewards to choose from
    local numChoices = GetNumQuestChoices()
    
    if numChoices <= 1 then
        -- No choice needed, auto complete
        GetQuestReward(numChoices)
    end
    -- If there are choices, let the player choose
end

-- Auto select gossip quest options
local function AutoSelectGossip()
    if not addon.db.autoSelectGossip then return end
    
    -- Check for available quests
    local availableQuests = C_GossipInfo.GetAvailableQuests()
    local activeQuests = C_GossipInfo.GetActiveQuests()
    
    -- Auto select available quests (priority: non-trivial first)
    for _, quest in ipairs(availableQuests) do
        if not quest.isTrivial then
            C_GossipInfo.SelectAvailableQuest(quest.questID)
            return
        end
    end
    
    -- Auto turn in active quests that are complete
    for _, quest in ipairs(activeQuests) do
        if quest.isComplete then
            C_GossipInfo.SelectActiveQuest(quest.questID)
            return
        end
    end
end

-- Track quest progress
local function AnnounceQuestProgress(questID, objective, fulfilled, required)
    if not addon.db.announceQuestProgress then return end
    
    local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
    
    if fulfilled == required then
        addon:Print(format("|cff00ff00%s|r - %s Complete!", questName, objective))
        
        -- Play a sound
        if addon.db.questCompleteSound then
            PlaySound(SOUNDKIT.RAID_WARNING)
        end
    end
end

-- Show quest objectives on screen
local function UpdateQuestObjectiveDisplay()
    if not addon.db.showQuestObjectives then return end
    
    -- This integrates with the objective tracker
    -- Could add custom overlay display here
end

-- Auto share quests with party
local function AutoShareQuest(questID)
    if not addon.db.autoShareQuests then return end
    if not IsInGroup() then return end
    
    -- Check if quest is shareable
    local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    if questLogIndex and C_QuestLog.IsPushableQuest(questID) then
        C_QuestLog.SetSelectedQuest(questID)
        QuestLogPushQuest()
        
        local questName = C_QuestLog.GetTitleForQuestID(questID)
        addon:Print("Shared quest: " .. (questName or "Unknown"))
    end
end

-- Watch recently accepted quests
local function OnQuestAccepted(questID)
    -- Auto share with party
    C_Timer.After(0.5, function()
        AutoShareQuest(questID)
    end)
end

-- Quest turn in announcement
local function OnQuestTurnedIn(questID, xpReward, moneyReward)
    if not addon.db.announceQuestComplete then return end
    
    local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
    
    local rewards = ""
    if xpReward and xpReward > 0 then
        rewards = rewards .. format(" +%d XP", xpReward)
    end
    if moneyReward and moneyReward > 0 then
        rewards = rewards .. " " .. C_CurrencyInfo.GetCoinTextureString(moneyReward)
    end
    
    addon:Print(format("Completed: |cff00ff00%s|r%s", questName, rewards))
end

function QuestHelper:OnInitialize()
    eventFrame:RegisterEvent("QUEST_DETAIL")
    eventFrame:RegisterEvent("QUEST_PROGRESS")
    eventFrame:RegisterEvent("QUEST_COMPLETE")
    eventFrame:RegisterEvent("GOSSIP_SHOW")
    eventFrame:RegisterEvent("QUEST_ACCEPTED")
    eventFrame:RegisterEvent("QUEST_TURNED_IN")
    eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "QUEST_DETAIL" then
            AutoAcceptQuest()
        elseif event == "QUEST_COMPLETE" then
            AutoCompleteQuest()
        elseif event == "GOSSIP_SHOW" then
            C_Timer.After(0.1, AutoSelectGossip)
        elseif event == "QUEST_ACCEPTED" then
            local questID = ...
            OnQuestAccepted(questID)
        elseif event == "QUEST_TURNED_IN" then
            local questID, xpReward, moneyReward = ...
            OnQuestTurnedIn(questID, xpReward, moneyReward)
        end
    end)
end

-- Register the module
addon:RegisterModule("QuestHelper", QuestHelper)
