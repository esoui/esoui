ZO_HouseInformation_Shared = ZO_InitializingObject:Subclass()

function ZO_HouseInformation_Shared:Initialize(control, fragment, rowTemplate, childVerticalPadding, sectionVerticalPadding)
    self.control = control
    self.rowTemplate = rowTemplate
    self.childVerticalPadding = childVerticalPadding
    self.sectionVerticalPadding = sectionVerticalPadding

    self:SetupControls()
    
    fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:UpdateHouseInformation()
            self:UpdateHousePopulation()
            self:UpdatePermissions()
            self:UpdateLimits()
        end
    end)
    
    local function RefreshItemLimits()
        if fragment:IsShowing() then
            self:UpdateLimits()
        end
    end

    local function RefreshHouseInformation()
        if fragment:IsShowing() then
            self:UpdateHouseInformation()
        end
    end

    local function RefreshHousePopulation(eventId, population)
        if fragment:IsShowing() then
            self:UpdateHousePopulation(population)
        end
    end

    local function RefreshHousePermissions(eventId, userGroup)
        if fragment:IsShowing() then
            self:UpdatePermissions(userGroup)
        end
    end

    control:RegisterForEvent(EVENT_HOUSING_FURNITURE_PLACED, RefreshItemLimits)
    control:RegisterForEvent(EVENT_HOUSING_FURNITURE_REMOVED, RefreshItemLimits)
    control:RegisterForEvent(EVENT_HOUSING_PRIMARY_RESIDENCE_SET, RefreshHouseInformation)
    control:RegisterForEvent(EVENT_HOUSING_POPULATION_CHANGED, RefreshHousePopulation)
    control:RegisterForEvent(EVENT_HOUSING_PERMISSIONS_CHANGED, RefreshHousePermissions)
end

do
    local function SetupRow(rootControl, controlName, nameText)
        local rowControl = rootControl:GetNamedChild(controlName)
        rowControl.nameLabel = rowControl:GetNamedChild("Name")
        rowControl.valueLabel = rowControl:GetNamedChild("Value")

        if nameText then
            rowControl.nameText = nameText
            rowControl.nameLabel:SetText(nameText)
        end

        return rowControl
    end
    
    function ZO_HouseInformation_Shared:SetupControls()
        self.nameRow = SetupRow(self.control, "NameRow", GetString(SI_HOUSING_NAME_HEADER))
        self.locationRow = SetupRow(self.control, "LocationRow", GetString(SI_HOUSING_LOCATION_HEADER))
        self.ownerRow = SetupRow(self.control, "OwnerRow", GetString(SI_HOUSING_OWNER_HEADER))
        self.infoSection = SetupRow(self.control, "InfoSection")
        self.primaryResidenceRow = SetupRow(self.control, "PrimaryResidenceRow", GetString(SI_HOUSING_PRIMARY_RESIDENCE_HEADER))
        self.currentVisitorsRow = SetupRow(self.control, "CurrentVisitorsRow", GetString(SI_HOUSING_CURRENT_RESIDENTS_HEADER))
        self.individualPermissionsRow = SetupRow(self.control, "IndividualPermissions", GetString(SI_PERMISSION_USER_GROUP_INDIVIDUAL_TOTAL_HEADER))
        self.guildPermissionsRow = SetupRow(self.control, "GuildPermissions", GetString(SI_PERMISSION_USER_GROUP_GUILD_TOTAL_HEADER))
        self.overPopulationWarningIcon = self.currentVisitorsRow:GetNamedChild("Help")
        self.overPopulationWarningLabel = self.control:GetNamedChild("OverPopulationWarningLabel")
    
        local furnishingLimits = self.infoSection:GetNamedChild("FurnishingLimits")
        local lastRow = nil
        self.limitRows = {}
        for i = HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_BEGIN, HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_END do
            local furnishingLimitRow = CreateControlFromVirtual(furnishingLimits:GetName().."Row"..i, furnishingLimits, self.rowTemplate)
    
            if not lastRow then
                furnishingLimitRow:SetAnchor(TOPLEFT)
            else
                furnishingLimitRow:SetAnchor(TOPLEFT, lastRow, BOTTOMLEFT, 0, self.childVerticalPadding)
            end
            lastRow = furnishingLimitRow
            self.limitRows[i] = SetupRow(furnishingLimits, "Row"..i)
        end
    end
end

function ZO_HouseInformation_Shared:UpdateHouseInformation()
    local currentHouseId = HOUSING_EDITOR_STATE:GetHouseId()
    local houseCollectibleId = HOUSING_EDITOR_STATE:GetHouseCollectibleId()
    local houseCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(houseCollectibleId)

    self.nameRow.valueText = houseCollectibleData:GetFormattedName()
    self.nameRow.valueLabel:SetText(self.nameRow.valueText)

    self.locationRow.valueText = houseCollectibleData:GetFormattedHouseLocation()
    self.locationRow.valueLabel:SetText(self.locationRow.valueText)

    self.currentVisitorsRow:ClearAnchors()
    local isHouseOwner = HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()
    if isHouseOwner then
        local isPrimaryHouse = IsPrimaryHouse(currentHouseId)
        self.primaryResidenceRow.valueText = isPrimaryHouse and GetString(SI_YES) or GetString(SI_NO)
        self.primaryResidenceRow.valueLabel:SetText(self.primaryResidenceRow.valueText)
        self.currentVisitorsRow:SetAnchor(TOPLEFT, self.primaryResidenceRow, BOTTOMLEFT, 0, 20)
    else
        self.currentVisitorsRow:SetAnchor(TOPLEFT, self.infoSection, BOTTOMLEFT, 0, 20)
    end

    local hideOwnerRows = not isHouseOwner
    self.guildPermissionsRow:SetHidden(hideOwnerRows)
    self.individualPermissionsRow:SetHidden(hideOwnerRows)
    self.primaryResidenceRow:SetHidden(hideOwnerRows)

    local ownerDisplayName = HOUSING_EDITOR_STATE:GetOwnerName()
    if ownerDisplayName ~= "" then
        self.ownerRow.valueText = ZO_FormatUserFacingDisplayName(ownerDisplayName)
        self.ownerRow.valueLabel:SetText(self.ownerRow.valueText)
        self.ownerRow:SetHidden(false)
        self.infoSection:SetAnchor(TOPLEFT, self.ownerRow, BOTTOMLEFT, 0, self.sectionVerticalPadding)
    else
        self.ownerRow:SetHidden(true)
        self.infoSection:SetAnchor(TOPLEFT, self.locationRow, BOTTOMLEFT, 0, self.sectionVerticalPadding)
    end
end

function ZO_HouseInformation_Shared:UpdateHousePopulation(population)
    local currentPopulation = population or GetCurrentHousePopulation()
    local maxPopulation = GetCurrentHousePopulationCap()

    self.currentVisitorsRow.valueText = zo_strformat(SI_HOUSE_INFORMATION_COUNT_FORMAT, currentPopulation, maxPopulation)
    self.currentVisitorsRow.valueLabel:SetText(self.currentVisitorsRow.valueText)
    
    local overpopulated = currentPopulation > maxPopulation
    self.overPopulationWarningIcon:SetHidden(not overpopulated)
    if self.overPopulationWarningLabel then
        self.overPopulationWarningLabel:SetHidden(not overpopulated)
    end
end

function ZO_HouseInformation_Shared:UpdatePermissions(userGroup)
    if userGroup == HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL or userGroup == nil then
        local numIndividualPermissions = GetNumHousingPermissions(GetCurrentZoneHouseId(), HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL)
        local textColor = numIndividualPermissions >= HOUSING_MAX_INDIVIDUAL_USER_GROUP_ENTRIES and ZO_ERROR_COLOR or ZO_SELECTED_TEXT

        self.individualPermissionsRow.valueText = zo_strformat(SI_HOUSING_NUM_PERMISSIONS_FORMAT, numIndividualPermissions, HOUSING_MAX_INDIVIDUAL_USER_GROUP_ENTRIES)
        self.individualPermissionsRow.valueLabel:SetText(textColor:Colorize(self.individualPermissionsRow.valueText))
    end

    if userGroup == HOUSE_PERMISSION_USER_GROUP_GUILD or userGroup == nil then
        local numGuildPermissions = GetNumHousingPermissions(GetCurrentZoneHouseId(), HOUSE_PERMISSION_USER_GROUP_GUILD)
        local textColor = numGuildPermissions >= HOUSING_MAX_GUILD_USER_GROUP_ENTRIES and ZO_ERROR_COLOR or ZO_SELECTED_TEXT

        self.guildPermissionsRow.valueText = zo_strformat(SI_HOUSING_NUM_PERMISSIONS_FORMAT, numGuildPermissions, HOUSING_MAX_GUILD_USER_GROUP_ENTRIES)
        self.guildPermissionsRow.valueLabel:SetText(textColor:Colorize(self.guildPermissionsRow.valueText))
    end
end

do
    local function UpdateRow(rowControl, name, value)
        rowControl.nameLabel:SetText(name)
        rowControl.valueLabel:SetText(value)
        rowControl.nameText = name
        rowControl.valueText = value
    end
    
    function ZO_HouseInformation_Shared:UpdateLimits()
        local currentHouseId = GetCurrentZoneHouseId()
    
        for i = HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_BEGIN, HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_END do
            local limit = GetHouseFurnishingPlacementLimit(currentHouseId, i)
            local currentlyPlaced = GetNumHouseFurnishingsPlaced(i)
            UpdateRow(self.limitRows[i], GetString("SI_HOUSINGFURNISHINGLIMITTYPE", i), zo_strformat(SI_HOUSE_INFORMATION_COUNT_FORMAT, currentlyPlaced, limit))
        end
    end
end

function ZO_HousingBook_GetHouseLink(houseId, ownerDisplayName)
    houseId = tonumber(houseId)
    if not houseId then
        -- Invalid houseId.
        return nil
    end

    if GetHouseZoneId(houseId) == 0 then
        -- Invalid houseId.
        return nil
    end

    if ownerDisplayName then
        ownerDisplayName = DecorateDisplayName(ownerDisplayName)
    end

    local link = ZO_LinkHandler_CreateChatLink(GetHousingLink, houseId, ownerDisplayName)
    return link
end

-- Links a specific house in chat.
function ZO_HousingBook_LinkHouseInChat(houseId, ownerDisplayName)
    local link = ZO_HousingBook_GetHouseLink(houseId, ownerDisplayName)
    if not link then
        -- Invalid houseId.
        return
    end

    if IsInGamepadPreferredMode() then
        ZO_LinkHandler_InsertLinkAndSubmit(link)
    else
        ZO_LinkHandler_InsertLink(link)
    end
end

-- Links the current house in chat, if any.
function ZO_HousingBook_LinkCurrentHouseInChat()
    local houseId = GetCurrentZoneHouseId()
    if houseId == 0 then
        -- Not currently in a house.
        return
    end

    local ownerDisplayName = GetCurrentHouseOwner()
    ZO_HousingBook_LinkHouseInChat(houseId, ownerDisplayName)
end