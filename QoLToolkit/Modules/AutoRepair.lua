---@class QoLToolkit
local addonName, addon = ...

local AutoRepair = {}

-- Event frame for this module
local eventFrame = CreateFrame("Frame")

local function OnMerchantShow()
    if not addon.db.autoRepair then return end
    
    -- Check if merchant can repair
    if not CanMerchantRepair() then return end
    
    local repairCost, canRepair = GetRepairAllCost()
    
    if not canRepair or repairCost == 0 then return end
    
    local money = GetMoney()
    
    -- Try guild bank repair first if enabled and available
    if addon.db.useGuildBank and IsInGuild() then
        local guildBankLimit = GetGuildBankWithdrawMoney()
        local guildBankMoney = GetGuildBankMoney()
        
        -- Check if we can use guild bank funds
        -- guildBankLimit of -1 means unlimited withdrawals
        if (guildBankLimit == -1 or guildBankLimit >= repairCost) and guildBankMoney >= repairCost then
            RepairAllItems(true) -- true = use guild bank
            addon:Print(format("Repaired all items for %s (Guild Bank)", 
                C_CurrencyInfo.GetCoinTextureString(repairCost)))
            return
        end
    end
    
    -- Fall back to personal funds
    if money >= repairCost then
        RepairAllItems(false)
        addon:Print(format("Repaired all items for %s", 
            C_CurrencyInfo.GetCoinTextureString(repairCost)))
    else
        addon:Print("|cffff0000Not enough gold to repair!|r Need " .. 
            C_CurrencyInfo.GetCoinTextureString(repairCost - money) .. " more.")
    end
end

function AutoRepair:OnInitialize()
    eventFrame:RegisterEvent("MERCHANT_SHOW")
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "MERCHANT_SHOW" then
            -- Small delay to ensure merchant is fully loaded
            C_Timer.After(0.1, OnMerchantShow)
        end
    end)
end

-- Register the module
addon:RegisterModule("AutoRepair", AutoRepair)
