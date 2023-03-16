ZO_FURNITURE_SETTINGS =
{
    [HOUSE_PERMISSION_OPTIONS_CATEGORIES_SOCIAL_OPTIONS] = 
    {
        HOUSE_PERMISSION_OPTIONS_CATEGORIES_GENERAL,
        HOUSE_PERMISSION_OPTIONS_CATEGORIES_OCCUPANTS,
        HOUSE_PERMISSION_OPTIONS_CATEGORIES_VISITORS,
        HOUSE_PERMISSION_OPTIONS_CATEGORIES_BANLIST,
        HOUSE_PERMISSION_OPTIONS_CATEGORIES_GUILD_VISITORS,
        HOUSE_PERMISSION_OPTIONS_CATEGORIES_GUILD_BANLIST,
    },
}

ZO_PATH_SETTINGS =
{
    [HOUSE_PATH_SETTING_CATEGORIES_EDIT_PATH] =
    {
        HOUSE_PATH_SETTING_CATEGORIES_PATH_SETTINGS,
    },
}

ZO_HOUSING_SETTINGS_CONTROL_DATA_PRIMARY_RESIDENCE = 1
ZO_HOUSING_SETTINGS_CONTROL_DATA_DEFAULT_ACCESS = 2
ZO_HOUSING_SETTINGS_CONTROL_DATA_RESTART_PATHS = 3
ZO_HOUSING_SETTINGS_CONTROL_DATA =
{
    -- Primary Residence
    [ZO_HOUSING_SETTINGS_CONTROL_DATA_PRIMARY_RESIDENCE] =
    {
        text = SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_TEXT,
        buttonText = SI_HOUSING_FURNITURE_SETTINGS_GENERAL_PRIMARY_RESIDENCE_BUTTON_TEXT,
        tooltipFunction = function(...) return SYSTEMS:GetObject("furniture_settings"):ShowPrimaryResidenceTooltip(...) end,
        gamepadTemplate = "ZO_HousingPermissionsSettingsRow_Gamepad",
    },
    -- Default Visitor Access
    [ZO_HOUSING_SETTINGS_CONTROL_DATA_DEFAULT_ACCESS] =
    {
        text = SI_HOUSING_FURNITURE_SETTINGS_GENERAL_DEFAULT_ACCESS_TEXT,
        tooltipFunction = function(...) return SYSTEMS:GetObject("furniture_settings"):ShowDefaultAccessTooltip(...) end,
        gamepadTemplate = "ZO_GamepadHorizontalListRow",
    },
    -- Restart All Paths
    [ZO_HOUSING_SETTINGS_CONTROL_DATA_RESTART_PATHS] =
    {
        text = SI_HOUSING_FURNITURE_SETTINGS_GENERAL_RESTART_PATHS_TEXT,
        buttonText = SI_HOUSING_FURNITURE_SETTINGS_GENERAL_RESTART_PATHS_BUTTON_TEXT,
        tooltipFunction = function(...) return SYSTEMS:GetObject("furniture_settings"):ShowRestartPathsTooltip(...) end,
        gamepadTemplate = "ZO_HousingPermissionsSettingsRow_Gamepad",
    },
}

ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA_PATH_TYPE = 1
ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA_PATHING_STATE = 2
ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA_CONFORM_TO_GROUND = 3
ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA_CHANGE_COLLECTIBLE = 4
ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA =
{
    -- Path Type
    [ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA_PATH_TYPE] =
    {
        text = SI_HOUSING_PATH_SETTINGS_PATHING_TYPE_TEXT,
        tooltipFunction = function(...) return SYSTEMS:GetObject("path_settings"):ShowPathTypeTooltip(...) end,
        gamepadTemplate = "ZO_GamepadHorizontalListRow",
    },
    -- Pathing State
    [ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA_PATHING_STATE] =
    {
        text = SI_HOUSING_PATH_SETTINGS_PATHING_STATE_TEXT,
        tooltipFunction = function(...) return SYSTEMS:GetObject("path_settings"):ShowPathingStateTooltip(...) end,
        gamepadTemplate = "ZO_CheckBoxTemplate_Gamepad",
    },
    -- Conform To Ground
    [ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA_CONFORM_TO_GROUND] =
    {
        text = SI_HOUSING_PATH_SETTINGS_CONFORM_TO_GROUND_TEXT,
        tooltipFunction = function(...) return SYSTEMS:GetObject("path_settings"):ShowConformToGroundTooltip(...) end,
        gamepadTemplate = "ZO_CheckBoxTemplate_Gamepad",
    },
    -- Change Collectible
    [ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA_CHANGE_COLLECTIBLE] =
    {
        text = SI_HOUSING_PATH_SETTINGS_CHANGE_COLLECTIBLE_TEXT,
        buttonText = SI_HOUSING_PATH_SETTINGS_CHANGE_COLLECTIBLE_BUTTON_TEXT,
        tooltipFunction = function(...) return SYSTEMS:GetObject("path_settings"):ShowChangeCollectibleTooltip(...) end,
        visible = function() return HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner() end,
        gamepadTemplate = "ZO_GamepadFullWidthLabelEntryTemplate",
    },
}

ZO_HOUSING_SETTINGS_LIST_ENTRY_SORT_KEYS =
{
    ["displayName"] = { },
    ["permissionPresetName"] = { tiebreaker = "displayName"},
}

ZO_HouseSettings_Manager = ZO_CallbackObject:Subclass()

function ZO_HouseSettings_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_HouseSettings_Manager:Initialize()
    self.applyToAllHousesFlag = true
    self.defaultPreset = HOUSE_PERMISSION_PRESET_SETTING_VISITOR
    self.permissionPresets = {}
    self.defaultAccessSettings = {}

    for i = HOUSE_PERMISSION_PRESET_SETTING_ITERATION_BEGIN, HOUSE_PERMISSION_PRESET_SETTING_ITERATION_END do
        local presetName = GetString("SI_HOUSEPERMISSIONPRESETSETTING", i)
        self.permissionPresets[i] = presetName
    end

    for i = HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_ITERATION_BEGIN, HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_ITERATION_END do
        local presetName = GetString("SI_HOUSEPERMISSIONDEFAULTACCESSSETTING", i)
        self.defaultAccessSettings[i] = presetName
    end
end

function ZO_HouseSettings_Manager:GetHousingPresetIndex(presetName)
    for i, name in pairs(self.permissionPresets) do
        if name == presetName then
            return i
        end
    end
end

function ZO_HouseSettings_Manager:GetPresetNameFromPermissionData(houseId, userGroup, index)
    local presetIndex = GetHousingPermissionPresetType(houseId, userGroup, index)
    return GetString("SI_HOUSEPERMISSIONPRESETSETTING", presetIndex)
end

function ZO_HouseSettings_Manager:GetDefaultHousingPermission(houseId)
    local hasAccess = DoesHousingUserGroupHaveAccess(houseId, HOUSE_PERMISSION_USER_GROUP_GENERAL, 1)
    local preset = GetHousingPermissionPresetType(houseId, HOUSE_PERMISSION_USER_GROUP_GENERAL, 1)
    local isMarkedForDelete = IsHousingPermissionMarkedForDelete(houseId, HOUSE_PERMISSION_USER_GROUP_GENERAL, 1)
    if hasAccess and not isMarkedForDelete then
        if preset == HOUSE_PERMISSION_PRESET_SETTING_DECORATOR then
            return HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_DECORATOR
        elseif preset == HOUSE_PERMISSION_PRESET_SETTING_VISITOR then
            return HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_VISITOR
        elseif preset == HOUSE_PERMISSION_PRESET_SETTING_LIMITED_VISITOR then
            return HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_LIMITED_VISITOR
        end
    end
    return HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_NO_ACCESS
end

function ZO_HouseSettings_Manager:GetHousingPermissionsFromDefaultAccess(defaultAccessType)
    local canAccess, preset
    if defaultAccessType == HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_NO_ACCESS then
        canAccess = false
        preset = HOUSE_PERMISSION_PRESET_SETTING_INVALID
    elseif defaultAccessType == HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_VISITOR then
        canAccess = true
        preset = HOUSE_PERMISSION_PRESET_SETTING_VISITOR
    elseif defaultAccessType == HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_DECORATOR then
        canAccess = true
        preset = HOUSE_PERMISSION_PRESET_SETTING_DECORATOR
    elseif defaultAccessType == HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_LIMITED_VISITOR then
        canAccess = true
        preset = HOUSE_PERMISSION_PRESET_SETTING_LIMITED_VISITOR
    end

    return canAccess, preset
end

local function ZO_HouseSettings_HouseEntrySort(left, right)
    return ZO_TableOrderingFunction(left, right, "name", ZO_SORT_BY_NAME, ZO_SORT_ORDER_UP)
end

function ZO_HouseSettings_Manager:SetupCopyPermissionsCombobox(dropdown, currentHouse, callback)
    dropdown:SetSelectedItemText(GetString(SI_DIALOG_COPY_HOUSING_PERMISSION_DEFAULT_CHOICE))

    local allHouses = COLLECTIONS_BOOK_SINGLETON:GetOwnedHouses()
    local houseEntries = {}

    for collectibleId, houseData in pairs(allHouses) do
        if houseData.houseId ~= currentHouse then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
            local newEntry = dropdown:CreateItemEntry(zo_strformat(SI_COLLECTIONS_HOUSING_DISPLAY_NAME_FORMAT, collectibleData:GetName(), collectibleData:GetNickname()), callback)
            newEntry.houseId = houseData.houseId
            table.insert(houseEntries, newEntry)
        end
    end

    table.sort(houseEntries, ZO_HouseSettings_HouseEntrySort)

    for index, houseEntry in ipairs(houseEntries) do
        houseEntry.houseIndex = index
        dropdown:AddItem(houseEntry)
    end
end

function ZO_HouseSettings_Manager:GetDefaultPreset()
    return self.defaultPreset
end

function ZO_HouseSettings_Manager:GetAllPermissionPresets()
    return self.permissionPresets
end

function ZO_HouseSettings_Manager:GetAllDefaultAccessSettings()
    return self.defaultAccessSettings
end

function ZO_HouseSettings_Manager:GetApplyToAllHousesFlag()
    return self.applyToAllHousesFlag
end

function ZO_HouseSettings_Manager:SetApplyToAllHousesFlag(applyToAllHousesFlag)
    self.applyToAllHousesFlag = applyToAllHousesFlag
end

HOUSE_SETTINGS_MANAGER = ZO_HouseSettings_Manager:New()