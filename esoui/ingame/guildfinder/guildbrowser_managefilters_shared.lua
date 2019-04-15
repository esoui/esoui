
ZO_GuildBrowser_ManageFilters_Shared = ZO_CallbackObject:Subclass()

function ZO_GuildBrowser_ManageFilters_Shared:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_GuildBrowser_ManageFilters_Shared:Initialize(control)
    self.control = control

    self.isSetToDefaultFilterTable = {}
end

function ZO_GuildBrowser_ManageFilters_Shared:SetFilterValueIsDefaultByAttributeType(attributeType, isDefault)
    local oldDefaultState = self:AreFiltersSetToDefault()

    self.isSetToDefaultFilterTable[attributeType] = not isDefault and attributeType or nil

    if oldDefaultState ~= self:AreFiltersSetToDefault() then
        self:FireCallbacks("OnGuildBrowserFilterValueIsDefaultChanged")
    end
end

function ZO_GuildBrowser_ManageFilters_Shared:GetHasGuildTraderDefault()
    return false
end

function ZO_GuildBrowser_ManageFilters_Shared:GetComboBoxEntrySelectionDefault()
    return false
end

function ZO_GuildBrowser_ManageFilters_Shared:GetMinCPDefault()
    return 0
end

function ZO_GuildBrowser_ManageFilters_Shared:GetMaxCPDefault()
    return ZO_GuildFinder_Manager.GetMaxCPAllowedForInput()
end

function ZO_GuildBrowser_ManageFilters_Shared:GetTimeDefault(isGamepad)
    if isGamepad then
        return 1
    else
        return 0
    end
end

function ZO_GuildBrowser_ManageFilters_Shared:AreFiltersSetToDefault()
    return next(self.isSetToDefaultFilterTable) == nil
end

function ZO_GuildBrowser_ManageFilters_Shared:ResetFiltersToDefault()
    self.isSetToDefaultFilterTable = {}
end
