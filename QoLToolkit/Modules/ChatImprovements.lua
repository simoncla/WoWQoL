---@class QoLToolkit
local addonName, addon = ...

local ChatImprovements = {}

-- Shorten channel names
local SHORT_CHANNEL_NAMES = {
    ["Guild"] = "G",
    ["Party"] = "P",
    ["Party Leader"] = "PL",
    ["Raid"] = "R",
    ["Raid Leader"] = "RL",
    ["Raid Warning"] = "RW",
    ["Instance"] = "I",
    ["Instance Leader"] = "IL",
    ["Whisper"] = "W",
    ["Say"] = "S",
    ["Yell"] = "Y",
    ["General"] = "1",
    ["Trade"] = "2",
    ["LocalDefense"] = "LD",
    ["LookingForGroup"] = "LFG",
}

-- Class colors for player names
local function GetClassColoredName(name, class)
    if not name then return name end
    
    local classColor = RAID_CLASS_COLORS[class]
    if classColor then
        return format("|c%s%s|r", classColor.colorStr, name)
    end
    return name
end

-- Add copy button to chat frames
local function AddCopyButtons()
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        local tab = _G["ChatFrame" .. i .. "Tab"]
        
        if chatFrame and tab and not chatFrame.copyButton then
            local copyButton = CreateFrame("Button", nil, chatFrame)
            copyButton:SetSize(16, 16)
            copyButton:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", -4, -4)
            copyButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
            copyButton:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
            copyButton:SetAlpha(0.5)
            
            copyButton:SetScript("OnEnter", function(self)
                self:SetAlpha(1)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Copy Chat")
                GameTooltip:Show()
            end)
            
            copyButton:SetScript("OnLeave", function(self)
                self:SetAlpha(0.5)
                GameTooltip:Hide()
            end)
            
            copyButton:SetScript("OnClick", function()
                -- Create a copy frame
                if not QoLToolkitCopyFrame then
                    local copyFrame = CreateFrame("Frame", "QoLToolkitCopyFrame", UIParent, "BackdropTemplate")
                    copyFrame:SetSize(500, 300)
                    copyFrame:SetPoint("CENTER")
                    copyFrame:SetBackdrop({
                        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                        tile = true, tileSize = 32, edgeSize = 32,
                        insets = { left = 11, right = 12, top = 12, bottom = 11 }
                    })
                    copyFrame:SetMovable(true)
                    copyFrame:EnableMouse(true)
                    copyFrame:RegisterForDrag("LeftButton")
                    copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
                    copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing)
                    copyFrame:SetFrameStrata("DIALOG")
                    
                    local scrollFrame = CreateFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
                    scrollFrame:SetPoint("TOPLEFT", 16, -16)
                    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 50)
                    
                    local editBox = CreateFrame("EditBox", nil, scrollFrame)
                    editBox:SetMultiLine(true)
                    editBox:SetFontObject(ChatFontNormal)
                    editBox:SetWidth(440)
                    editBox:SetAutoFocus(true)
                    scrollFrame:SetScrollChild(editBox)
                    
                    copyFrame.editBox = editBox
                    
                    local closeButton = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton")
                    closeButton:SetPoint("TOPRIGHT", -5, -5)
                    
                    copyFrame:Hide()
                end
                
                -- Get chat text
                local text = ""
                for j = 1, chatFrame:GetNumMessages() do
                    local msg = chatFrame:GetMessageInfo(j)
                    if msg then
                        text = text .. msg .. "\n"
                    end
                end
                
                QoLToolkitCopyFrame.editBox:SetText(text)
                QoLToolkitCopyFrame.editBox:HighlightText()
                QoLToolkitCopyFrame:Show()
            end)
            
            chatFrame.copyButton = copyButton
        end
    end
end

-- Shorten channel names in chat
local function ShortenChannelNames(self, event, msg, ...)
    if not addon.db.shortenChannelNames then return false, msg, ... end
    
    for long, short in pairs(SHORT_CHANNEL_NAMES) do
        msg = msg:gsub("%[" .. long .. "%]", "[" .. short .. "]")
    end
    
    return false, msg, ...
end

-- Add timestamps to chat
local function AddTimestamps()
    if not addon.db.chatTimestamps then return end
    
    -- Use Blizzard's built-in timestamp feature
    SetCVar("showTimestamps", addon.db.timestampFormat or "HH:MM")
end

-- Enable URL detection and make clickable
local function EnableURLs()
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:SetHyperlinksEnabled(true)
        end
    end
end

-- Sticky chat channels
local function SetStickyChannels()
    if not addon.db.stickyChannels then return end
    
    ChatTypeInfo.WHISPER.sticky = 1
    ChatTypeInfo.PARTY.sticky = 1
    ChatTypeInfo.RAID.sticky = 1
    ChatTypeInfo.GUILD.sticky = 1
    ChatTypeInfo.INSTANCE_CHAT.sticky = 1
end

function ChatImprovements:OnInitialize()
    -- Add copy buttons
    C_Timer.After(1, AddCopyButtons)
    
    -- Hook into chat message filter for channel shortening
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ShortenChannelNames)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", ShortenChannelNames)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", ShortenChannelNames)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", ShortenChannelNames)
    
    -- Apply improvements
    AddTimestamps()
    EnableURLs()
    SetStickyChannels()
end

-- Register the module
addon:RegisterModule("ChatImprovements", ChatImprovements)
