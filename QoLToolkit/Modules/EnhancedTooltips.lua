---@class QoLToolkit
local addonName, addon = ...

local EnhancedTooltips = {}

-- Item level pattern for parsing
local ITEM_LEVEL_PATTERN = ITEM_LEVEL:gsub("%%d", "(%%d+)")

-- Add item ID to tooltip
local function AddItemID(tooltip)
    if not addon.db.enhancedTooltips then return end
    
    local _, itemLink = GameTooltip:GetItem()
    if not itemLink then return end
    
    local itemID = C_Item.GetItemIDForItemInfo(itemLink)
    if itemID then
        tooltip:AddDoubleLine("Item ID:", "|cffffffff" .. itemID .. "|r")
    end
end

-- Add spell ID to tooltip
local function AddSpellID(tooltip, spellID)
    if not addon.db.enhancedTooltips then return end
    
    if spellID then
        tooltip:AddDoubleLine("Spell ID:", "|cffffffff" .. spellID .. "|r")
    end
end

-- Add NPC ID to tooltip
local function AddUnitInfo(tooltip)
    if not addon.db.enhancedTooltips then return end
    
    local _, unit = tooltip:GetUnit()
    if not unit then return end
    
    local guid = UnitGUID(unit)
    if not guid then return end
    
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    
    if npcID and (unitType == "Creature" or unitType == "Vehicle") then
        tooltip:AddDoubleLine("NPC ID:", "|cffffffff" .. npcID .. "|r")
    end
    
    -- Add target of target info
    local targetUnit = unit .. "target"
    if UnitExists(targetUnit) then
        local targetName = UnitName(targetUnit)
        local targetClass = select(2, UnitClass(targetUnit))
        local classColor = targetClass and RAID_CLASS_COLORS[targetClass]
        
        if targetName then
            local coloredName = classColor 
                and format("|c%s%s|r", classColor.colorStr, targetName)
                or targetName
            tooltip:AddDoubleLine("Targeting:", coloredName)
        end
    end
end

-- Add currency info
local function AddCurrencyInfo(tooltip, currencyID)
    if not addon.db.enhancedTooltips then return end
    
    if currencyID then
        tooltip:AddDoubleLine("Currency ID:", "|cffffffff" .. currencyID .. "|r")
    end
end

function EnhancedTooltips:OnInitialize()
    -- Hook into item tooltips using TooltipDataProcessor (modern API)
    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
            if tooltip == GameTooltip then
                AddItemID(tooltip)
            end
        end)
        
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
            if tooltip == GameTooltip and data then
                AddSpellID(tooltip, data.id)
            end
        end)
        
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            if tooltip == GameTooltip then
                AddUnitInfo(tooltip)
            end
        end)
        
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tooltip, data)
            if tooltip == GameTooltip and data then
                AddCurrencyInfo(tooltip, data.id)
            end
        end)
    else
        -- Fallback for older API (pre-10.0.2)
        GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
            AddItemID(tooltip)
        end)
        
        GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
            AddUnitInfo(tooltip)
        end)
    end
end

-- Register the module
addon:RegisterModule("EnhancedTooltips", EnhancedTooltips)
