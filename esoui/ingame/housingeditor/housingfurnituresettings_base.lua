-- ZO_HousingFurnitureSettings_Base --
--------------------------------------

ZO_HousingFurnitureSettings_Base = ZO_Object:Subclass()

function ZO_HousingFurnitureSettings_Base:New(...)
    local browserBase = ZO_Object.New(self)
    browserBase:Initialize(...)
    return browserBase
end

function ZO_HousingFurnitureSettings_Base:Initialize(control, owner)
    self.control = control
    self.owner = owner

    local function OnPermissionsChanged(...)
        if self.owner:IsShowing() and self.owner:GetMode() == HOUSING_BROWSER_MODE.SETTINGS then
            self:OnPermissionsChanged(...)
        end
    end

    local function OnPrimaryResidenceSet()
        if self.owner:IsShowing() and self.owner:GetMode() == HOUSING_BROWSER_MODE.SETTINGS then
            self:UpdateGeneralSettings()
        end
    end

    self.control:RegisterForEvent(EVENT_HOUSING_PERMISSIONS_CHANGED, OnPermissionsChanged)
    self.control:RegisterForEvent(EVENT_HOUSING_PRIMARY_RESIDENCE_SET, OnPrimaryResidenceSet)
end

function ZO_HousingFurnitureSettings_Base:OnPermissionsChanged(eventId, userGroup)
    if userGroup == HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL then
        self:UpdateSingleVisitorSettings()
    elseif userGroup == HOUSE_PERMISSION_USER_GROUP_GUILD then
        self:UpdateGuildVisitorSettings()
    elseif userGroup == HOUSE_PERMISSION_USER_GROUP_GENERAL then
        self:UpdateGeneralSettings()
    end
end

function ZO_HousingFurnitureSettings_Base:GetCategoryInfo(categoryIndex)
    local normalIcon, pressedIcon, mouseoverIcon
    if categoryIndex == HOUSE_PERMISSION_OPTIONS_CATEGORIES_SOCIAL_OPTIONS then
        normalIcon = "EsoUI/Art/TreeIcons/tutorial_idexIcon_groups_up.dds"
        pressedIcon = "EsoUI/Art/TreeIcons/tutorial_idexIcon_groups_down.dds"
        mouseoverIcon = "EsoUI/Art/TreeIcons/tutorial_idexIcon_groups_over.dds"
    end

    return GetString("SI_HOUSEPERMISSIONOPTIONSCATEGORIES", categoryIndex), normalIcon, pressedIcon, mouseoverIcon
end

function ZO_HousingFurnitureSettings_Base:GetNumIndividualPermissions(houseId)
    return GetNumHousingPermissions(houseId, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL)
end

function ZO_HousingFurnitureSettings_Base:GetNumGuildPermissions(houseId)
    return GetNumHousingPermissions(houseId, HOUSE_PERMISSION_USER_GROUP_GUILD)
end

function ZO_HousingFurnitureSettings_Base:IsCurrentHomeInHomeShow()
    return self.isCurrentHomeShowListed
end

function ZO_HousingFurnitureSettings_Base:UpdateLists()
    self:UpdateGeneralSettings()
    self:UpdateSingleVisitorSettings()
    self:UpdateGuildVisitorSettings()
    self:BuildCategories()
end

function ZO_HousingFurnitureSettings_Base:TryShowCopyDialog()
    if GetTotalUnlockedCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_HOUSE) > 1 then
        local data = { currentHouse = GetCurrentZoneHouseId() }
        self:ShowCopyDialog(data)
    else
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_DIALOG_COPY_HOUSING_PERMISSION_REQUIRES_MORE_HOUSES))
    end
end

function ZO_HousingFurnitureSettings_Base:SetPrimaryResidence()
    local currentHouse = GetCurrentZoneHouseId()
    if self.primaryResidence == 0 then
        SetHousingPrimaryHouse(currentHouse)
    elseif currentHouse ~= self.primaryResidence then
        local collectibleId = GetCollectibleIdForHouse(self.primaryResidence)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_PRIMARY_RESIDENCE", { currentHouse = currentHouse }, { mainTextParams = { collectibleData:GetName(), collectibleData:GetNickname()}})
    end
end

function ZO_HousingFurnitureSettings_Base:ShowDefaultAccessTooltip()
    assert(false) -- override in derived classes
end

function ZO_HousingFurnitureSettings_Base:ShowPrimaryResidenceTooltip()
    assert(false) -- override in derived classes
end

function ZO_HousingFurnitureSettings_Base:ShowHomeShowTooltip()
    assert(false) -- override in derived classes
end

function ZO_HousingFurnitureSettings_Base:UpdateSingleVisitorSettings()
    assert(false) -- override in derived classes
end

function ZO_HousingFurnitureSettings_Base:UpdateGuildVisitorSettings()
    assert(false) -- override in derived classes
end

function ZO_HousingFurnitureSettings_Base:UpdateGeneralSettings()
    assert(false) -- override in derived classes
end

function ZO_HousingFurnitureSettings_Base:ShowCopyDialog()
    assert(false) -- override in derived classes
end