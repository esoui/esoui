ZO_GROUP_FINDER_ROLES =
{
    LFG_ROLE_TANK,
    LFG_ROLE_HEAL,
    LFG_ROLE_DPS,
    LFG_ROLE_INVALID,
}
-- TODO GroupFinder: Re-evaluate whether or not this table needs LFG_ROLE_INVALID
-- once roles are implemented in Create/Edit

ZO_GROUP_FINDER_MODES =
{
    OVERVIEW = 1,
    SEARCH = 2,
    CREATE_EDIT = 3,
    MANAGE = 4,
}

ZO_GROUP_LISTING_CHAMPION_ICON_SIZE = 22

local GROUP_ROLES_TO_ICONS =
{
    [LFG_ROLE_INVALID] =
    {
        filled = "EsoUI/Art/LFG/LFG_any_down_no_glow_64.dds",
        unfilled = "EsoUI/Art/LFG/LFG_any_disabled_64.dds",
    },
    [LFG_ROLE_DPS] =
    {
        filled = "EsoUI/Art/LFG/LFG_dps_down_no_glow_64.dds",
        unfilled = "EsoUI/Art/LFG/LFG_dps_disabled_64.dds",
    },
    [LFG_ROLE_TANK] =
    {
        filled = "EsoUI/Art/LFG/LFG_tank_down_no_glow_64.dds",
        unfilled = "EsoUI/Art/LFG/LFG_tank_disabled_64.dds",
    },
    [LFG_ROLE_HEAL] =
    {
        filled = "EsoUI/Art/LFG/LFG_healer_down_no_glow_64.dds",
        unfilled = "EsoUI/Art/LFG/LFG_healer_disabled_64.dds",
    },
}

--------------------------
-- ZO_GroupFinder_Shared
--------------------------

ZO_GroupFinder_Shared = ZO_InitializingObject:Subclass()

function ZO_GroupFinder_Shared:Initialize(control)
    self.control = control

    self:InitializeControls()
    self:InitializeFragments()
    self:InitializeGroupFinderCategories()

    function OnGroupVeteranDifficultyChanged()
        ResetGroupFinderFilterAndDraftDifficultyToDefault()
    end

    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_STATUS_UPDATED, function(_, ...) self:OnGroupFinderStatusUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_CREATE_GROUP_LISTING_RESULT, function(_, ...) self:OnGroupListingRequestCreateResult(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_UPDATE_GROUP_LISTING_RESULT, function(_, ...) self:OnGroupListingRequestEditResult(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_GROUP_LISTING_ATTAINED_ROLES_CHANGED, function(_, ...) self:OnGroupListingAttainedRolesChanged(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_FINDER_REMOVE_GROUP_LISTING_RESULT, function(_, ...) self:OnGroupListingRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_VETERAN_DIFFICULTY_CHANGED, OnGroupVeteranDifficultyChanged)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_GROUP_VETERAN_DIFFICULTY_CHANGED, OnGroupVeteranDifficultyChanged)
end

function ZO_GroupFinder_Shared:InitializeFragments()
    self.sceneFragment = ZO_FadeSceneFragment:New(self.control)
    -- TODO GroupFinder: OnShowing, OnShown, OnHiding, OnHidden handlers if necessary
end

function ZO_GroupFinder_Shared:OnShowing()
    -- TODO GroupFinder: Any behavior needed that can be shared between keyboard and gamepad
end

function ZO_GroupFinder_Shared:InitializeControls()
    -- To be overridden
end

function ZO_GroupFinder_Shared:InitializeGroupFinderCategories()
    -- To be overridden
end

function ZO_GroupFinder_Shared:OnGroupListingRequestCreateResult(result)
    -- To be overridden
end

function ZO_GroupFinder_Shared:OnGroupListingRequestEditResult(result)
    -- To be overridden
end

function ZO_GroupFinder_Shared:OnGroupListingAttainedRolesChanged()
    -- To be overridden
end

function ZO_GroupFinder_Shared:OnGroupListingRemoved(result)
    -- To be overridden
end

function ZO_GroupFinder_Shared:OnGroupFinderStatusUpdated(status)
    self:ApplyPendingMode()
end

function ZO_GroupFinder_Shared:ApplyPendingMode()
    -- To be overridden
end

function ZO_GroupFinder_Shared.SetUpGroupListingFromData(control, controlPool, data, horizontalPadding)
    horizontalPadding = horizontalPadding or 0

    local joinabilityResult = data:GetJoinabilityResult()
    local isListingJoinable = joinabilityResult == GROUP_FINDER_ACTION_RESULT_SUCCESS
        or joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ENTITLEMENT_REQUIREMENT
        or joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_QUEUED
        or joinabilityResult == nil
    local titleColor
    local labelColor
    if isListingJoinable then
        titleColor = ZO_SELECTED_TEXT
        labelColor = ZO_NORMAL_TEXT
    else
        titleColor = ZO_DISABLED_TEXT
        labelColor = ZO_DISABLED_TEXT
    end

    local titleText = EscapeMarkup(data:GetTitle(), ALLOW_MARKUP_TYPE_COLOR_ONLY)
    local statusIndicatorIcon = data:GetStatusIndicatorIcon()
    if statusIndicatorIcon then
        statusIndicatorIcon = zo_iconFormat(statusIndicatorIcon, "100%", "100%")
        titleText = string.format("%s%s", statusIndicatorIcon, titleText)
    end
    control.groupTitleLabel:SetText(titleText)
    control.groupTitleLabel:SetColor(titleColor:UnpackRGBA())

    local category = data:GetCategory()
    if category ~= GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON and category ~= GROUP_FINDER_CATEGORY_CUSTOM then
        local firstText = category == GROUP_FINDER_CATEGORY_PVP and data:GetPrimaryOptionText() or data:GetSecondaryOptionText()
        local secondText = category == GROUP_FINDER_CATEGORY_PVP and data:GetSecondaryOptionText() or data:GetPrimaryOptionText()
        control.settingsLabel:SetText(ZO_GenerateCommaSeparatedListWithoutAnd({ firstText, secondText }))
        control.settingsLabel:SetColor(labelColor:UnpackRGBA())
    else
        control.settingsLabel:SetText("")
    end

    if control.roleControlKeys then
        ZO_GroupFinder_Shared.ResetRoleControls(control, controlPool)
    else
        control.roleControlKeys = {}
    end

    if isListingJoinable then
        control.disabledLabel:SetHidden(true)
        local previousControl = nil
        for _, roleType in ipairs(ZO_GROUP_FINDER_ROLES) do
            local desiredCount, attainedCount = data:GetRoleStatusCount(roleType)
            if attainedCount > 0 then
                local roleControl, key = controlPool:AcquireObject()
                table.insert(control.roleControlKeys, key)

                local iconTexture = GROUP_ROLES_TO_ICONS[roleType].filled

                roleControl:GetNamedChild("Icon"):SetTexture(iconTexture)
                roleControl:GetNamedChild("Label"):SetText(attainedCount)
                roleControl:ClearAnchors()
                roleControl:SetParent(control.roleList)

                if not previousControl then
                    roleControl:SetAnchor(LEFT, control.roleList, LEFT)
                else
                    roleControl:SetAnchor(LEFT, previousControl, RIGHT, horizontalPadding)
                end
                previousControl = roleControl
            end
        end
        control.roleList:SetHidden(false)
    else
        if joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_APPLICATION_DECLINED then
            control.disabledLabel:SetText(GetString(SI_GROUP_FINDER_SEARCH_RESULTS_DECLINED))
        elseif joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ALREADY_JOINED_GROUP then
            control.disabledLabel:SetText(GetString(SI_GROUP_FINDER_SEARCH_RESULTS_YOUR_GROUP))
        elseif joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ROLE_REQUIREMENT then
            control.disabledLabel:SetText(GetString(SI_GROUP_FINDER_SEARCH_RESULTS_NOT_ELIGIBLE))
        else
            control.disabledLabel:SetText(GetString(SI_GROUP_FINDER_SEARCH_RESULTS_DELISTED))
        end
        control.roleList:SetHidden(true)
        control.disabledLabel:SetHidden(false)
    end
end

function ZO_GroupFinder_Shared.ResetRoleControls(control, controlPool)
    for _, key in ipairs(control.roleControlKeys) do
        controlPool:ReleaseObject(key)
    end
    ZO_ClearTable(control.roleControlKeys)
end

function ZO_GroupFinder_Shared.BuildCategoryData()
    local categoryData = {}

    for index = GROUP_FINDER_CATEGORY_ITERATION_BEGIN, GROUP_FINDER_CATEGORY_ITERATION_END do
        local categoryEntry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_GROUPFINDERCATEGORY", index))
        table.insert(categoryData, categoryEntry)
    end

    return categoryData
end

--------------------------------------------------------------
-- ZO_GroupFinder_CreateEditGroupListing_Shared
--------------------------------------------------------------

ZO_GroupFinder_CreateEditGroupListing_Shared = ZO_InitializingObject:Subclass()

function ZO_GroupFinder_CreateEditGroupListing_Shared:Initialize(control)
    self:UpdateUserType()
    self.userTypeData:UpdateOptions()
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:Refresh()
    self.userTypeData:UpdateOptions()
    SetGroupFinderUserTypeGroupListingSecondaryOptionDefault(GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT)
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateUserType()
    local currentUserType = GetCurrentGroupFinderUserType()
    if self.userTypeData == nil then
        local IS_EDITABLE = true
        self.userTypeData = ZO_GroupListingUserTypeData:New(currentUserType, IS_EDITABLE)
    else
        self.userTypeData:SetUserType(currentUserType)
    end

    if currentUserType == GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING then
        self.userTypeData:SetEditableUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT)
    end

    for i, roleType in pairs(ZO_GROUP_FINDER_ROLES) do
        self.userTypeData:UpdateDesiredRoleCountAtEdit(roleType)
        self.userTypeData:UpdateAttainedRoleCountAtEdit(roleType)
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:GetTitleTooltipText()
    local titleViolationsString = ZO_GroupFinder_GetGroupTitleViolationString(self.groupTitleEditControl:GetText())
    return titleViolationsString
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:DoCreateEdit()
    if self.userTypeData:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING then
        RequestEditGroupListing()
    else
        RequestCreateGroupListing()
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:SetCategory(category)
    self.userTypeData:SetCategory(category)
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:OnCategorySelection(comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    -- This function should not be able to be called when editing so the userTypeData should be fine here
    self.userTypeData:SetCategory(selectedData.value)

    -- Reset the roles to the default when setting the category. This will ensure that the number of roles expected matches the category selected,
    -- however the roles will not retain their user set values when switching between categories like other entries will.
    for i, roleType in pairs(ZO_GROUP_FINDER_ROLES) do
        self.userTypeData:UpdateDesiredRoleCountAtEdit(roleType)
        self.userTypeData:UpdateAttainedRoleCountAtEdit(roleType)
    end

    self:Refresh()
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:OnPrimarySelection(dropdown, selectedDataName, selectedData, selectionChanged, oldData)
    if self.userTypeData:IsUserTypeActive() then
        self.userTypeData:SetPrimaryOption(selectedData.value)
        local category = self.userTypeData:GetCategory()
        if category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_ARENA or category == GROUP_FINDER_CATEGORY_TRIAL then
            SetVeteranDifficulty(selectedData.value == DUNGEON_DIFFICULTY_VETERAN)
        end
        self:PopulateSecondaryDropdown()
        self:PopulateSizeDropdown()
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:OnSecondarySelection(dropdown, selectedDataName, selectedData, selectionChanged, oldData)
    if self.userTypeData:IsUserTypeActive() then
        self.userTypeData:SetSecondaryOption(selectedData.value)
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:OnSizeSelection(comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    -- This function should not be able to be called when editing so the userTypeData should be fine here
    self.userTypeData:SetSize(selectedData.value)
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:OnPlaystyleSelection(comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    self.userTypeData:SetPlaystyle(selectedData.value)
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateEditBoxGroupListingTitle()
    if self.groupTitleEditControl then
        self.groupTitleEditControl:SetText(self.userTypeData:GetTitle())
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:PopulateCategoryDropdown()
    if self.categoryDropdown then
        local startIndex = GROUP_FINDER_CATEGORY_ITERATION_BEGIN
        local endIndex = GROUP_FINDER_CATEGORY_ITERATION_END
        local textPrefix = "SI_GROUPFINDERCATEGORY"
        local data =
        {
            currentValue = self.userTypeData:GetCategory()
        }

        local function OnCategorySelection(...)
            self:OnCategorySelection(...)
        end

        ZO_GroupFinder_PopulateEnumDropdown(self.categoryDropdown, startIndex, endIndex, textPrefix, OnCategorySelection, data)
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:PopulatePrimaryDropdown()
    if self.primaryOptionDropdown then
        local function OnPrimarySelection(...)
            self:OnPrimarySelection(...)
        end

        ZO_GroupFinder_PopulateUserTypePrimaryOptionsDropdown(self.primaryOptionDropdown, self.userTypeData, OnPrimarySelection)

        self:PopulateSecondaryDropdown()
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:PopulateSecondaryDropdown()
    if self.secondaryOptionDropdown then
        local function OnSecondarySelection(...)
            self:OnSecondarySelection(...)
        end

        ZO_GroupFinder_PopulateUserTypeSecondaryOptionsDropdown(self.secondaryOptionDropdown, self.userTypeData, OnSecondarySelection)
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:PopulateSizeDropdown()
    if self.sizeDropdown then
        local startIndex = self.userTypeData:GetSizeMin()
        local endIndex = self.userTypeData:GetSizeMax()
        local textPrefix = "SI_GROUPFINDERGROUPSIZE"
        local defaultText = GetString(SI_GROUP_FINDER_CREATE_SIZE_DEFAULT_TEXT)
        local data =
        {
            currentValue = self.userTypeData:GetSize()
        }

        local function OnSizeSelection(...)
            self:OnSizeSelection(...)
        end

        ZO_GroupFinder_PopulateFlagDropdown(self.sizeDropdown, startIndex, endIndex, textPrefix, OnSizeSelection, data, defaultText)
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateEditBoxGroupListingDescription()
    if self.descriptionEditControl then
        self.descriptionEditControl:SetText(self.userTypeData:GetDescription())
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:PopulatePlaystyleDropdown()
    if self.playstyleDropdown then
        local startIndex = GROUP_FINDER_PLAYSTYLE_ITERATION_BEGIN
        local endIndex = GROUP_FINDER_PLAYSTYLE_ITERATION_END
        local textPrefix = "SI_GROUPFINDERPLAYSTYLE"
        local defaultText = GetString(SI_GROUP_FINDER_CREATE_PLAYSTYLE_DEFAULT_TEXT)
        local data =
        {
            currentValue = self.userTypeData:GetPlaystyle()
        }

        local function OnPlaystyleSelection(...)
            self:OnPlaystyleSelection(...)
        end

        ZO_GroupFinder_PopulateFlagDropdown(self.playstyleDropdown, startIndex, endIndex, textPrefix, OnPlaystyleSelection, data, defaultText)
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateCheckStateRequireChampion()
    if self.championCheckbox then
        ZO_CheckButton_SetCheckState(self.championCheckbox, self.userTypeData:DoesGroupRequireChampion())

        self:UpdateChampionPointsEditBox()
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateChampionPointsEditBox()
    if self.championPointsEditBoxControl then
        local championPoints = self.userTypeData:GetChampionPoints()
        if championPoints == 0 then
            self.championPointsEditBoxControl:SetDefaultText(GetString(SI_GROUP_FINDER_FILTERS_CHAMPION_POINTS_DEFAULT_TEXT))
            self.championPointsEditBoxControl:Clear()
        else
            self.championPointsEditBoxControl:SetText(championPoints)
        end
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateCheckStateRequireVOIP()
    if self.voipCheckbox then
        ZO_CheckButton_SetCheckState(self.voipCheckbox, self.userTypeData:DoesGroupRequireVOIP())
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateCheckStateInviteCode()
    if self.inviteCodeCheckbox then
        ZO_CheckButton_SetCheckState(self.inviteCodeCheckbox, self.userTypeData:DoesGroupRequireInviteCode())

        self:UpdateInviteCodeEditBox()
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateInviteCodeEditBox()
    if self.inviteCodeEditBoxControl then
        local inviteCode = self.userTypeData:GetInviteCode()
        if inviteCode == 0 then
            self.inviteCodeEditBoxControl:SetDefaultText(GetString(SI_GROUP_FINDER_CREATE_INVITE_CODE_DEFAULT_TEXT))
            self.inviteCodeEditBoxControl:Clear()
        else
            self.inviteCodeEditBoxControl:SetText(inviteCode)
        end
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateCheckStateAutoAcceptRequests()
    if self.autoAcceptCheckbox then
        ZO_CheckButton_SetCheckState(self.autoAcceptCheckbox, self.userTypeData:DoesGroupAutoAcceptRequests())
    end
end

function ZO_GroupFinder_CreateEditGroupListing_Shared:UpdateCheckStateEnforceRoles()
    if self.enforceRolesCheckbox then
        ZO_CheckButton_SetCheckState(self.enforceRolesCheckbox, self.userTypeData:DoesGroupEnforceRoles())
    end
end

do
    local ROLE_ICON_DIMENSION = 32
    function ZO_GroupFinder_CreateEditGroupListing_Shared:GetRoleLabelText(roleType)
        local roleText
        if roleType == LFG_ROLE_INVALID then
            roleText = GetString(SI_GROUP_FINDER_ROLE_ANY)
        else
            roleText= GetString("SI_LFGROLE", roleType)
        end

        return string.format("%s %s", zo_iconFormat(GROUP_ROLES_TO_ICONS[roleType].filled, ROLE_ICON_DIMENSION, ROLE_ICON_DIMENSION), roleText)
    end
end

--------------------------------------------------------------
-- ZO_GroupFinder_AdditionalFilters_Shared
--------------------------------------------------------------

ZO_GroupFinder_AdditionalFilters_Shared = ZO_InitializingObject:Subclass()

ZO_GroupFinder_AdditionalFilters_Shared.Refresh = ZO_GroupFinder_AdditionalFilters_Shared:MUST_IMPLEMENT()

function ZO_GroupFinder_AdditionalFilters_Shared:GetPrimaryDropdownByCategory()
    local category = GetGroupFinderFilterCategory()

    if category == GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON or category == GROUP_FINDER_CATEGORY_ZONE or category == GROUP_FINDER_CATEGORY_CUSTOM then
        return self.primaryOptionDropdown
    else
        return self.primaryOptionDropdownSingleSelect
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:OnCategorySelection(comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    local IS_CANCELABLE = true
    SetGroupFinderFilterCategory(selectedData.value, IS_CANCELABLE)
    self:Refresh()
end

function ZO_GroupFinder_AdditionalFilters_Shared:OnPrimarySelectionSingleSelect(dropdown, selectedDataName, selectedData)
    SetGroupFinderFilterPrimaryOptionByIndex(selectedData.value, true)
    self:PopulateSecondaryDropdown()
    self:PopulateSizeDropdown()
end

function ZO_GroupFinder_AdditionalFilters_Shared:OnPrimarySelection(dropdown, selectedDataName, selectedData)
    SetGroupFinderFilterPrimaryOptionByIndex(selectedData.value, dropdown:IsItemSelected(selectedData))
    self:PopulateSecondaryDropdown()
    self:PopulateSizeDropdown()
end

function ZO_GroupFinder_AdditionalFilters_Shared:OnSecondarySelection(dropdown, selectedDataName, selectedData)
    SetGroupFinderFilterSecondaryOptionByIndex(selectedData.value, dropdown:IsItemSelected(selectedData))
end

function ZO_GroupFinder_AdditionalFilters_Shared:OnSizeSelection(comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    local sizeFlags = GetGroupFinderFilterGroupSizes()

    if comboBox:IsItemSelected(selectedData) then
        sizeFlags = ZO_FlagHelpers.SetMaskFlag(sizeFlags, selectedData.value)
    else
        sizeFlags = ZO_FlagHelpers.ClearMaskFlag(sizeFlags, selectedData.value)
    end
    SetGroupFinderFilterGroupSizeFlags(sizeFlags)
end

function ZO_GroupFinder_AdditionalFilters_Shared:OnPlaystyleSelection(comboBox, selectedDataName, selectedData, selectionChanged, oldData)
    local playstyleFlags = GetGroupFinderFilterPlaystyles()

    if comboBox:IsItemSelected(selectedData) then
        playstyleFlags = ZO_FlagHelpers.SetMaskFlag(playstyleFlags, selectedData.value)
    else
        playstyleFlags = ZO_FlagHelpers.ClearMaskFlag(playstyleFlags, selectedData.value)
    end
    SetGroupFinderFilterPlaystyleFlags(playstyleFlags)
end

function ZO_GroupFinder_AdditionalFilters_Shared:PopulateCategoryDropdown()
    if self.categoryDropdown then
        local startIndex = GROUP_FINDER_CATEGORY_ITERATION_BEGIN
        local endIndex = GROUP_FINDER_CATEGORY_ITERATION_END
        local textPrefix = "SI_GROUPFINDERCATEGORY"
        local data =
        {
            currentValue = GetGroupFinderFilterCategory()
        }

        local function OnCategorySelection(...)
            self:OnCategorySelection(...)
        end

        ZO_GroupFinder_PopulateEnumDropdown(self.categoryDropdown, startIndex, endIndex, textPrefix, OnCategorySelection, data)
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:PopulatePrimaryDropdownSingleSelect()
    local category = GetGroupFinderFilterCategory()
    if self.primaryOptionDropdownSingleSelect and not (category == GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON or category == GROUP_FINDER_CATEGORY_ZONE or category == GROUP_FINDER_CATEGORY_CUSTOM) then
        local defaultText = ""

        local function OnPrimarySelection(...)
            self:OnPrimarySelectionSingleSelect(...)
        end

        local function GetNumPrimaryOptions()
            return GetGroupFinderFilterNumPrimaryOptions()
        end

        ZO_GroupFinder_PopulateOptionsDropdown(self.primaryOptionDropdownSingleSelect, GetNumPrimaryOptions, GetGroupFinderFilterPrimaryOptionByIndex, OnPrimarySelection, defaultText)

        self:PopulateSecondaryDropdown()
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:PopulatePrimaryDropdown()
    local category = GetGroupFinderFilterCategory()
    if self.primaryOptionDropdown and (category == GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON or category == GROUP_FINDER_CATEGORY_ZONE or category == GROUP_FINDER_CATEGORY_CUSTOM) then
        local function OnPrimarySelection(...)
            self:OnPrimarySelection(...)
        end

        ZO_GroupFinder_PopulateFiltersPrimaryOptionsDropdown(self.primaryOptionDropdown, OnPrimarySelection)

        self:PopulateSecondaryDropdown()
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:PopulateSecondaryDropdown()
    if self.secondaryOptionDropdown then
        local function OnSecondarySelection(...)
            self:OnSecondarySelection(...)
        end

        ZO_GroupFinder_PopulateFiltersSecondaryOptionsDropdown(self.secondaryOptionDropdown, OnSecondarySelection)
        if self.secondaryOptionDropdown:IsInstanceOf(ZO_MultiSelection_ComboBox_Gamepad) and self.secondaryOptionDropdown.dropDownData then
            self.secondaryOptionDropdown:LoadData(self.secondaryOptionDropdown.dropDownData)
        end
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:PopulateSizeDropdown()
    if self.sizeDropdown then
        local startIndex = GROUP_FINDER_SIZE_ITERATION_BEGIN
        local endIndex = GetGroupFinderFilterGroupSizeIterationEnd()
        local textPrefix = "SI_GROUPFINDERGROUPSIZE"
        local defaultText = GetString(SI_GROUP_FINDER_FILTERS_GROUP_SIZE_DEFAULT_TEXT)
        local multiSelectionText = GetString(SI_GROUP_FINDER_FILTERS_GROUP_SIZE_DROPDOWN_TEXT)
        local data =
        {
            currentValue = GetGroupFinderFilterGroupSizes()
        }

        local function OnSizeSelection(...)
            self:OnSizeSelection(...)
        end

        ZO_GroupFinder_PopulateFlagDropdown(self.sizeDropdown, startIndex, endIndex, textPrefix, OnSizeSelection, data, defaultText, multiSelectionText)
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:PopulatePlaystyleDropdown()
    if self.playstyleDropdown then
        local startIndex = GROUP_FINDER_PLAYSTYLE_ITERATION_BEGIN
        local endIndex = GROUP_FINDER_PLAYSTYLE_ITERATION_END
        local textPrefix = "SI_GROUPFINDERPLAYSTYLE"
        local defaultText = GetString(SI_GROUP_FINDER_FILTERS_PLAYSTYLE_DEFAULT_TEXT)
        local multiSelectionText = GetString(SI_GROUP_FINDER_FILTERS_PLAYSTYLE_DROPDOWN_TEXT)
        local data =
        {
            currentValue = GetGroupFinderFilterPlaystyles()
        }

        local function OnPlaystyleSelection(...)
            self:OnPlaystyleSelection(...)
        end

        ZO_GroupFinder_PopulateFlagDropdown(self.playstyleDropdown, startIndex, endIndex, textPrefix, OnPlaystyleSelection, data, defaultText, multiSelectionText)
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:UpdateCheckStateRequireChampion()
    if self.championCheckbox then
        ZO_CheckButton_SetCheckState(self.championCheckbox, DoesGroupFinderFilterRequireChampion())

        if self.championTextBoxControl then
            local championPoints = GetGroupFinderFilterChampionPoints()
            if championPoints == 0 then
                self.championTextBoxControl:SetDefaultText(GetString(SI_GROUP_FINDER_FILTERS_CHAMPION_POINTS_DEFAULT_TEXT))
                self.championTextBoxControl:Clear()
            else
                self.championTextBoxControl:SetText(championPoints)
            end
        end

        if not IsUnitChampion("player") then
           ZO_CheckButton_Disable(self.championCheckbox)
        end
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:UpdateCheckStateRequireVOIP()
    if self.voipCheckbox then
        ZO_CheckButton_SetCheckState(self.voipCheckbox, DoesGroupFinderFilterRequireVOIP())
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:UpdateCheckStateInviteCode()
    if self.inviteCodeCheckbox then
        ZO_CheckButton_SetCheckState(self.inviteCodeCheckbox, DoesGroupFinderFilterRequireInviteCode())
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:UpdateCheckStateAutoAcceptRequests()
    if self.autoAcceptCheckbox then
        ZO_CheckButton_SetCheckState(self.autoAcceptCheckbox, DoesGroupFinderFilterAutoAcceptRequests())
    end
end

function ZO_GroupFinder_AdditionalFilters_Shared:UpdateCheckStateOwnRoles()
    if self.ownRoleOnlyCheckbox then
        ZO_CheckButton_SetCheckState(self.ownRoleOnlyCheckbox, DoesGroupFinderFilterRequireEnforceRoles())
    end
end

---------------------------------
-- Global Helper Functions
---------------------------------

function ZO_GroupFinder_IsGroupFinderInUse()
    return GetCurrentGroupFinderUserType() ~= GROUP_FINDER_GROUP_LISTING_USER_TYPE_GROUP_LISTING_DRAFT
end

function ZO_GroupFinder_GetGroupTitleViolationString(groupTitleText)
    local violations = { IsValidGroupFinderListingTitle(groupTitleText) }
    local HIDE_UNVIOLATED_RULES = true
    return ZO_ValidNameInstructions_GetViolationString(groupTitleText, violations, HIDE_UNVIOLATED_RULES)
end

function ZO_GroupFinder_CanDoCreateEdit(userTypeData, groupTitleEditControl, isEditing)
    local statusResult = GetGroupFinderStatusReason()
    if IsGroupFinderRoleChangeRequested() then
        return false, GetString(SI_GROUP_FINDER_ROLE_CHANGING)
    elseif statusResult == GROUP_FINDER_ACTION_RESULT_FAILED_ACCOUNT_TYPE_BLOCKS_CREATION then
        return false, GetString("SI_GROUPFINDERACTIONRESULT", statusResult)
    elseif ZO_GroupFinder_GetIsCurrentlyInQueue() then
        return false, GetString(SI_GROUP_FINDER_CREATE_GROUP_DISABLED_QUEUED)
    elseif not IsUnitSoloOrGroupLeader("player") then
        return false, GetString(SI_GROUP_FINDER_CREATE_GROUP_DISABLED_NOT_LEADER)
    elseif userTypeData then
        if userTypeData:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING then
            if HasPendingAcceptedGroupFinderApplication() then
                return false, GetString("SI_GROUPFINDERACTIONRESULT", GROUP_FINDER_ACTION_RESULT_FAILED_APPLICATION_PENDING)
            elseif isEditing and not userTypeData:HasUserTypeChanged() then
                return false, GetString(SI_GROUP_FINDER_EDIT_NO_CHANGES_TOOLTIP)
            end
        end

        local createEditErrors = {}

        if userTypeData:GetNumRoles() <= GetGroupSize() then
            table.insert(createEditErrors, GetString(SI_GROUP_FINDER_CREATE_GROUP_DISABLED_GROUP_FULL))
        end

        if groupTitleEditControl then
            local violations = { IsValidGroupFinderListingTitle(groupTitleEditControl:GetText()) }
            if #violations > 0 then
                table.insert(createEditErrors, GetString(SI_GROUP_FINDER_CREATE_INVALID_TITLE_TOOLTIP))
            end
        end

        if userTypeData:DoesGroupRequireInviteCode() and userTypeData:GetInviteCode() == 0 then
            table.insert(createEditErrors, GetString(SI_GROUP_FINDER_CREATE_GROUP_NO_INVITE_CODE))
        end

        if isEditing and not userTypeData:DoesDesiredRolesMatchAttainedRoles() then
            table.insert(createEditErrors, GetString(SI_GROUP_FINDER_CREATE_ROLE_MISMATCH_TOOLTIP))
        end

        if #createEditErrors > 0 then
            local errorString = ZO_GenerateParagraphSeparatedList(createEditErrors)
            return false, errorString
        end
    end
    return true
end

function ZO_GroupFinder_GetIsCurrentlyInQueue()
    local activityFinderStatus = GetActivityFinderStatus()
    return activityFinderStatus == ACTIVITY_FINDER_STATUS_QUEUED or activityFinderStatus == ACTIVITY_FINDER_STATUS_READY_CHECK
end

function ZO_GroupFinder_PopulateDropdown(dropDownObject, iterBegin, iterEnd, getStringFunction, selectionFunction, isCurrentValueFunction, extraValues, omittedIndex, defaultText, iteratorFunction, multiSelectionText)
    dropDownObject:ClearItems()

    -- Order matters; we must set these text options before we start selecting entries in a multiselect dropdown.
    if multiSelectionText then
        dropDownObject:SetNoSelectionText(defaultText)
        dropDownObject:SetMultiSelectionTextFormatter(multiSelectionText)
    end

    if type(omittedIndex) == "function" then
        omittedIndex = omittedIndex()
    end

    local selectedEntryIndex
    local currentIndex = 1

    local isGamepadMultiSelectComboBox = dropDownObject:IsInstanceOf(ZO_MultiSelection_ComboBox_Gamepad)

    local function AddEntry(value)
        if value ~= omittedIndex then
            local text = getStringFunction and getStringFunction(value)
            local entry = dropDownObject:CreateItemEntry(text, selectionFunction)
            entry.value = value
            local isCurrentValue = not isCurrentValueFunction or isCurrentValueFunction(value)

            if isGamepadMultiSelectComboBox then
                dropDownObject.dropDownData:AddItem(entry)
            else
                dropDownObject:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
            end

            if isCurrentValue then
                if multiSelectionText then
                    if isGamepadMultiSelectComboBox then
                        dropDownObject.dropDownData:SetItemSelected(entry, true)
                    else
                        dropDownObject:AddItemToSelected(entry)
                    end
                else
                    selectedEntryIndex = currentIndex
                end
            end
            currentIndex = currentIndex + 1
        end
    end

    if type(iterEnd) == "function" then
        iterEnd = iterEnd()
    end

    if multiSelectionText and isGamepadMultiSelectComboBox then
        dropDownObject.dropDownData:Clear()
    end

    if iteratorFunction then
        iteratorFunction(iterBegin, iterEnd, AddEntry)
    else
        for i = iterBegin, iterEnd do
            AddEntry(i)
        end
    end

    if extraValues then
        for _, value in ipairs(extraValues) do
            AddEntry(value)
        end
    end

    local IGNORE_CALLBACK = true
    if selectedEntryIndex then
        dropDownObject:SelectItemByIndex(selectedEntryIndex, IGNORE_CALLBACK)
    elseif multiSelectionText then
        dropDownObject:RefreshSelectedItemText()
    else
        dropDownObject:SetSelectedItemText(defaultText)
    end
end

function ZO_GroupFinder_PopulateEnumDropdown(dropDownObject, iterBegin, iterEnd, stringBase, selectionFunction, data, omittedIndex, defaultText)
    local function getStringFunction(value)
        return GetString(stringBase, value)
    end

    local function isCurrentValueFunction(value)
        return data.currentValue == value
    end

    ZO_GroupFinder_PopulateDropdown(dropDownObject, iterBegin, iterEnd, getStringFunction, selectionFunction, isCurrentValueFunction, data.extraValues, omittedIndex, defaultText)
end

function ZO_GroupFinder_PopulateFlagDropdown(dropDownObject, iterBegin, iterEnd, stringBase, selectionFunction, data, defaultText, multiSelectionText)
    local function GetStringFunction(value)
        return GetString(stringBase, value)
    end

    local function IsCurrentValueFunction(value)
        if multiSelectionText then
            return ZO_FlagHelpers.MaskHasFlag(data.currentValue, value)
        else
            return data.currentValue == value
        end
    end

    local function IterationFunction(iteratorBegin, iteratorEnd, addEntryFunction)
        for flag in ZO_FlagHelpers.FlagIterator(iteratorBegin, iteratorEnd) do
            addEntryFunction(flag)
        end
    end

    local NO_OMITTED_INDEX = nil
    ZO_GroupFinder_PopulateDropdown(dropDownObject, iterBegin, iterEnd, GetStringFunction, selectionFunction, IsCurrentValueFunction, data.extraValues, NO_OMITTED_INDEX, defaultText, IterationFunction, multiSelectionText)
end

function ZO_GroupFinder_PopulateOptionsDropdown(dropDownObject, maxNum, getInfoFunction, selectionFunction, defaultText, multiSelectionText)
    local function GetStringFunction(value)
        local name = getInfoFunction(value)
        return name
    end

    local function IsCurrentValueFunction(value)
        local _, isSet = getInfoFunction(value)
        return isSet
    end

    local NO_EXTRA_VALUES = nil
    local NO_OMITTED_INDEX = nil
    local NO_ITERATION_FUNCTION = nil
    ZO_GroupFinder_PopulateDropdown(dropDownObject, 1, maxNum, GetStringFunction, selectionFunction, IsCurrentValueFunction, NO_EXTRA_VALUES, NO_OMITTED_INDEX, defaultText, NO_ITERATION_FUNCTION, multiSelectionText)
end

function ZO_GroupFinder_PopulateUserTypePrimaryOptionsDropdown(primaryOptionsDropdown, userTypeData, OnPrimarySelectionFunction)
    local defaultText = ""
    if userTypeData:GetCategory() == GROUP_FINDER_CATEGORY_ZONE then
        defaultText = GetString(SI_GROUP_FINDER_CREATE_ACTIVITY_DEFAULT_TEXT)
    end

    local function GetNumPrimaryOptions(...)
        return userTypeData:GetNumPrimaryOptions()
    end

    local function GetPrimaryOptionByIndex(...)
        return userTypeData:GetPrimaryOptionByIndex(...)
    end

    ZO_GroupFinder_PopulateOptionsDropdown(primaryOptionsDropdown, GetNumPrimaryOptions, GetPrimaryOptionByIndex, OnPrimarySelectionFunction, defaultText)
end

function ZO_GroupFinder_PopulateFiltersPrimaryOptionsDropdown(primaryOptionsDropdown, OnPrimarySelectionFunction)
    local category = GetGroupFinderFilterCategory()
    local defaultText = ""
    local multiSelectionText
    if category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_TRIAL or category == GROUP_FINDER_CATEGORY_ARENA then
        defaultText = GetString(SI_GROUP_FINDER_FILTERS_DIFFICULTY_DEFAULT_TEXT)
        multiSelectionText = SI_GROUP_FINDER_FILTERS_DIFFICULTY_DROPDOWN_TEXT
    elseif category == GROUP_FINDER_CATEGORY_ZONE then
        defaultText = GetString(SI_GROUP_FINDER_FILTERS_ACTIVITY_DEFAULT_TEXT)
        multiSelectionText = SI_GROUP_FINDER_FILTERS_ACTIVITY_DROPDOWN_TEXT
    elseif category == GROUP_FINDER_CATEGORY_PVP then
        -- TODO GroupFinder: Implement this along with implementing the single-select PvP filter dropdown.
    elseif category == GROUP_FINDER_CATEGORY_CUSTOM then
        -- This state should disable the dropdown so no value is necessary.
    end

    local function GetNumPrimaryOptions()
        return GetGroupFinderFilterNumPrimaryOptions()
    end

    ZO_GroupFinder_PopulateOptionsDropdown(primaryOptionsDropdown, GetNumPrimaryOptions, GetGroupFinderFilterPrimaryOptionByIndex, OnPrimarySelectionFunction, defaultText, multiSelectionText)
end

function ZO_GroupFinder_PopulateUserTypeSecondaryOptionsDropdown(secondaryOptionDropdown, userTypeData, OnSecondarySelectionFunction, primaryOptionDropdown)
    local defaultText = ""
    local category = userTypeData:GetCategory()
    if category == GROUP_FINDER_CATEGORY_PVP then
        local numPrimaryItems = GetGroupFinderFilterNumPrimaryOptions()
        local lastPrimaryName, isLastPrimarySelected = GetGroupFinderFilterPrimaryOptionByIndex(numPrimaryItems)
        -- The last item in a pvp primary options dropdown will always be battlegrounds.
        if not isLastPrimarySelected then
            defaultText = GetString(SI_GROUP_FINDER_CREATE_CAMPAIGN_DEFAULT_TEXT)
        else
            defaultText = GetString(SI_GROUP_FINDER_CREATE_BATTLEGROUND_DEFAULT_TEXT)
        end
    elseif category == GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON or category == GROUP_FINDER_CATEGORY_CUSTOM then
        -- ENDLESS_DUNGEON and CUSTOM should disable the dropdown so no value is necessary
    else
        defaultText = GetString("SI_GROUPFINDERCATEGORY_SINGLESELECTDEFAULT", category)
    end

    local function GetNumSecondaryOptions(...)
        return userTypeData:GetNumSecondaryOptions()
    end

    local function GetSecondaryOptionByIndex(...)
        return userTypeData:GetSecondaryOptionByIndex(...)
    end

    ZO_GroupFinder_PopulateOptionsDropdown(secondaryOptionDropdown, GetNumSecondaryOptions, GetSecondaryOptionByIndex, OnSecondarySelectionFunction, defaultText)
end

function ZO_GroupFinder_PopulateFiltersSecondaryOptionsDropdown(secondaryOptionDropdown, OnSecondarySelectionFunction)
    local defaultText = ""
    local multiSelectionText
    local category = GetGroupFinderFilterCategory()
    if category == GROUP_FINDER_CATEGORY_PVP then
        local numPrimaryItems = GetGroupFinderFilterNumPrimaryOptions()
        local lastPrimaryName, isLastPrimarySelected = GetGroupFinderFilterPrimaryOptionByIndex(numPrimaryItems)
        -- The last item in a pvp primary options dropdown will always be battlegrounds.
        if not isLastPrimarySelected then
            defaultText = GetString(SI_GROUP_FINDER_FILTERS_CAMPAIGN_DEFAULT_TEXT)
            multiSelectionText = GetString(SI_GROUP_FINDER_FILTERS_CAMPAIGN_DROPDOWN_TEXT)
        else
            defaultText = GetString(SI_GROUP_FINDER_FILTERS_BATTLEGROUND_DEFAULT_TEXT)
            multiSelectionText = GetString(SI_GROUP_FINDER_FILTERS_BATTLEGROUND_DROPDOWN_TEXT)
        end
    elseif category == GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON or category == GROUP_FINDER_CATEGORY_CUSTOM then
        -- ENDLESS_DUNGEON and CUSTOM should disable the dropdown so no value is necessary
    else
        defaultText = GetString("SI_GROUPFINDERCATEGORY_MULTISELECTDEFAULT", category)
        multiSelectionText = GetString("SI_GROUPFINDERCATEGORY_MULTISELECTSELECTIONS", category)
    end

    local function GetNumSecondaryOptions()
        return GetGroupFinderFilterNumSecondaryOptions()
    end

    ZO_GroupFinder_PopulateOptionsDropdown(secondaryOptionDropdown, GetNumSecondaryOptions, GetGroupFinderFilterSecondaryOptionByIndex, OnSecondarySelectionFunction, defaultText, multiSelectionText)
end

-- Helper function for tooltips; data should be a ZO_GroupListingData_Base
function ZO_GroupFinder_GroupListing_GetPlayerCountAndRoleStrings(data, iconDimension)
    local roleTable = {}
    local roleNarrations = {}
    local numRoles = data:GetNumRoles()
    local numCurrentMembers = 0
    for _, roleType in ipairs(ZO_GROUP_FINDER_ROLES) do
        if roleType ~= LFG_ROLE_INVALID then
            local desiredCount, attainedCount = data:GetRoleStatusCount(roleType)
            local iconTexture
            if attainedCount > 0 then
                numCurrentMembers = numCurrentMembers + attainedCount
                iconTexture = GROUP_ROLES_TO_ICONS[roleType].filled
                table.insert(roleTable, string.format("%d %s", attainedCount, zo_iconFormat(iconTexture, iconDimension, iconDimension)))
                table.insert(roleNarrations, string.format("%d %s", attainedCount, GetString("SI_LFGROLE", roleType)))
            end
        end
    end

    local playerCountString = zo_strformat(SI_GROUP_FINDER_TOOLTIP_PLAYER_COUNT_FORMATTER, numCurrentMembers, numRoles)
    local roleString = ZO_GenerateSpaceSeparatedList(roleTable)
    return playerCountString, roleString, roleNarrations
end

-- Helper function for tooltips; data should be a ZO_GroupListingData_Base
function ZO_GroupFinder_GroupListing_GetDesiredRolesList(data, iconDimension)
    local desiredRolesTable = {}
    local desiredRolesNarrations = {}
    local totalDesiredRoles = 0
    for _, roleType in ipairs(ZO_GROUP_FINDER_ROLES) do
        if roleType ~= LFG_ROLE_INVALID then
            local desiredCount, attainedCount = data:GetRoleStatusCount(roleType)
            local iconTexture
            if desiredCount > 0 then
                totalDesiredRoles = totalDesiredRoles + desiredCount
            end
        end
    end

    local anyRoleDesired = totalDesiredRoles < data:GetNumRoles()

    for _, roleType in ipairs(ZO_GROUP_FINDER_ROLES) do
        if roleType ~= LFG_ROLE_INVALID then
            local desiredCount, attainedCount = data:GetRoleStatusCount(roleType)
            local iconTexture
            if desiredCount > attainedCount or anyRoleDesired then
                iconTexture = GROUP_ROLES_TO_ICONS[roleType].filled
                table.insert(desiredRolesTable, zo_iconFormat(iconTexture, iconDimension, iconDimension))
                table.insert(desiredRolesNarrations, GetString("SI_LFGROLE", roleType))
            end
        end
    end

    return ZO_GenerateSpaceSeparatedList(desiredRolesTable), desiredRolesNarrations
end

-- Global XML

function ZO_GroupFinder_GroupListing_OnInitialize(control)
    control.groupTitleLabel = control:GetNamedChild("ContainerTitle")
    control.settingsLabel = control:GetNamedChild("ContainerSettings")
    control.roleList = control:GetNamedChild("RoleList")
    control.disabledLabel = control:GetNamedChild("DisabledLabel")
    control.roleControls = {}
end