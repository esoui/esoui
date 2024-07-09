ZO_GuildSelectorManager = ZO_InitializingCallbackObject:Subclass()

function ZO_GuildSelectorManager:Initialize()
    self:RegisterForEvents()
end

function ZO_GuildSelectorManager:RegisterForEvents()
    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
            EVENT_MANAGER:UnregisterForEvent("ZO_GuildSelectorManager", EVENT_ADD_ON_LOADED)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_GuildSelectorManager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ZO_GuildSelectorManager:SetupSavedVars()
    local defaults =
    {
        selectedGuildStoreId = 0,
        selectedGuildBankId = 0,
        selectedGuildMenuId = 0,
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "ZO_GuildSelectorManager", defaults)
    self:FireCallbacks("OnReady")
end

function ZO_GuildSelectorManager:SetSelectedGuildStoreId(selectedGuildStoreId)
    if not self:IsReady() then return end

    self.savedVars.selectedGuildStoreId = selectedGuildStoreId
    SelectTradingHouseGuildId(selectedGuildStoreId)
end

function ZO_GuildSelectorManager:GetSelectedGuildStoreId()
    if not self:IsReady() then return 0 end

    return self.savedVars.selectedGuildStoreId
end

function ZO_GuildSelectorManager:SetSelectedGuildBankId(selectedGuildBankId)
    if not self:IsReady() then return end

    self.savedVars.selectedGuildBankId = selectedGuildBankId
    SelectGuildBank(selectedGuildBankId)
end

function ZO_GuildSelectorManager:GetSelectedGuildBankId()
    if not self:IsReady() then return 0 end

    return self.savedVars.selectedGuildBankId
end

function ZO_GuildSelectorManager:SetSelectedGuildMenuId(selectedGuildMenuId)
    if not self:IsReady() then return end

    self.savedVars.selectedGuildMenuId = selectedGuildMenuId
end

function ZO_GuildSelectorManager:GetSelectedGuildMenuId()
    if not self:IsReady() then return 0 end

    return self.savedVars.selectedGuildMenuId
end

function ZO_GuildSelectorManager:IsReady()
    return self.savedVars ~= nil
end

ZO_GUILD_SELECTOR_MANAGER = ZO_GuildSelectorManager:New()