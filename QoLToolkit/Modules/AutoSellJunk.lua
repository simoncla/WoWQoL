---@class QoLToolkit
local addonName, addon = ...

local AutoSellJunk = {}

-- Event frame for this module
local eventFrame = CreateFrame("Frame")

local function SellJunkItems()
    if not addon.db.autoSellJunk then return end
    
    local totalValue = 0
    local itemsSold = 0
    
    -- Iterate through all bag slots using the new API
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            
            if itemInfo and itemInfo.quality == Enum.ItemQuality.Poor then
                -- It's a gray/junk item
                if itemInfo.sellPrice and itemInfo.sellPrice > 0 then
                    totalValue = totalValue + (itemInfo.sellPrice * itemInfo.stackCount)
                    itemsSold = itemsSold + 1
                    
                    -- Use the item to sell it
                    C_Container.UseContainerItem(bag, slot)
                end
            end
        end
    end
    
    if itemsSold > 0 then
        addon:Print(format("Sold %d junk item(s) for %s", 
            itemsSold, 
            C_CurrencyInfo.GetCoinTextureString(totalValue)))
    end
end

function AutoSellJunk:OnInitialize()
    eventFrame:RegisterEvent("MERCHANT_SHOW")
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "MERCHANT_SHOW" then
            -- Small delay to ensure merchant is fully loaded
            C_Timer.After(0.2, SellJunkItems)
        end
    end)
end

-- Register the module
addon:RegisterModule("AutoSellJunk", AutoSellJunk)
