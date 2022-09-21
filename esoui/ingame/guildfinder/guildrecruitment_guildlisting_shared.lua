------------------
-- Guild Finder --
------------------

ZO_GuildRecruitment_GuildListing_Shared = ZO_GuildRecruitment_Panel_Shared:Subclass()

function ZO_GuildRecruitment_GuildListing_Shared:New(...)
    return ZO_GuildRecruitment_Panel_Shared.New(self, ...)
end

function ZO_GuildRecruitment_GuildListing_Shared:Initialize(control, templateData)
    ZO_GuildRecruitment_Panel_Shared.Initialize(self, control)

    self.templateData = templateData

    self:InitializeGridList()

    local function OnGuildMembershipOrApplicationsChanged(guildId)
        if guildId == self.guildId then
            self:UpdateAlert()
        end
    end

    local function OnGuildInfoChanged(guildId)
        if guildId == self.guildId then
            self:RefreshData()
        end
    end

    GUILD_RECRUITMENT_MANAGER:RegisterCallback("GuildMembershipChanged", OnGuildMembershipOrApplicationsChanged)
    GUILD_RECRUITMENT_MANAGER:RegisterCallback("GuildInfoChanged", OnGuildInfoChanged)
    GUILD_RECRUITMENT_MANAGER:RegisterCallback("GuildApplicationResultsReady", OnGuildMembershipOrApplicationsChanged)
end

function ZO_GuildRecruitment_GuildListing_Shared:InitializeGridList()
    -- Initialize grid list object
    local templateData = self.templateData
    local gridListControl = self.control:GetNamedChild("InfoPanel")
    self.gridListControl = gridListControl
    -- Override default highlight template to hide white outline around tiles
    self.gridList = templateData.gridListClass:New(gridListControl, templateData.gridHighlightTemplate)

    -- NOTE: If you update the number of templates being added to the gridList you must also update 
    --       ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_ENTRY_TEMPLATE in GuildRecruitment_GuildListing_Gamepad.lua
    local HIDE_CALLBACK = nil
    local GRID_PADDING_X = 0
    local attributeSelectionData = templateData.attributeSelection
    local activityCheckboxData = templateData.activityCheckbox
    local headlineData = templateData.headlineEditBox
    local descriptionData = templateData.descriptionEditBox
    local roleSelectorData = templateData.roleSelector
    local minimumCPData = templateData.minimumCP
    self.gridList:AddEntryTemplate(attributeSelectionData.entryTemplate, attributeSelectionData.dimensionsX, attributeSelectionData.dimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, attributeSelectionData.gridPaddingX, attributeSelectionData.gridPaddingY)
    self.gridList:AddEntryTemplate(attributeSelectionData.statusEntryTemplate, attributeSelectionData.statusDimensionsX, attributeSelectionData.dimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, GRID_PADDING_X, attributeSelectionData.gridPaddingY)
    self.gridList:AddEntryTemplate(attributeSelectionData.startTimeEntryTemplate, attributeSelectionData.startTimeDimensionsX, attributeSelectionData.timeDimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, GRID_PADDING_X, attributeSelectionData.gridPaddingY)
    self.gridList:AddEntryTemplate(attributeSelectionData.endTimeEntryTemplate, attributeSelectionData.dimensionsX, attributeSelectionData.timeDimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, GRID_PADDING_X, attributeSelectionData.gridPaddingY)
    self.gridList:AddEntryTemplate(activityCheckboxData.entryTemplate, activityCheckboxData.dimensionsX, activityCheckboxData.dimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, activityCheckboxData.gridPaddingX, activityCheckboxData.gridPaddingY)
    self.gridList:AddEntryTemplate(activityCheckboxData.endEntryTemplate, activityCheckboxData.dimensionsX, activityCheckboxData.endDimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, activityCheckboxData.gridPaddingX, activityCheckboxData.gridPaddingY)
    self.gridList:AddEntryTemplate(headlineData.entryTemplate, headlineData.dimensionsX, headlineData.dimensionsY, ZO_DefaultGridTileEntrySetup, self.templateData.textEditHideCallback, ZO_DefaultGridTileEntryReset, GRID_PADDING_X, headlineData.gridPaddingY)
    self.gridList:AddEntryTemplate(descriptionData.entryTemplate, descriptionData.dimensionsX, descriptionData.dimensionsY, ZO_DefaultGridTileEntrySetup, self.templateData.textEditHideCallback, ZO_DefaultGridTileEntryReset, GRID_PADDING_X, descriptionData.gridPaddingY)
    self.gridList:AddEntryTemplate(roleSelectorData.entryTemplate, roleSelectorData.dimensionsX, roleSelectorData.dimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, GRID_PADDING_X, roleSelectorData.gridPaddingY)
    self.gridList:AddEntryTemplate(roleSelectorData.endEntryTemplate, roleSelectorData.endDimensionsX, roleSelectorData.dimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, GRID_PADDING_X, roleSelectorData.gridPaddingY)
    self.gridList:AddEntryTemplate(minimumCPData.entryTemplate, minimumCPData.dimensionsX, minimumCPData.dimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, GRID_PADDING_X, minimumCPData.gridPaddingY)
    self.gridList:AddHeaderTemplate(templateData.headerTemplate, templateData.headerHeight, ZO_DefaultGridTileHeaderSetup)
    self.gridList:SetHeaderPrePadding(templateData.gridPaddingY)

    self:BuildAttributeSelectionData()
end

function ZO_GuildRecruitment_GuildListing_Shared:UpdateAlert()
    -- To be overridden
end

function ZO_GuildRecruitment_GuildListing_Shared:CanSave()
    return HasGuildRecruitmentDataChanged(self.guildId)
end

function ZO_GuildRecruitment_GuildListing_Shared:Save()
    -- To be overridden
end

function ZO_GuildRecruitment_GuildListing_Shared:GetActivitiesForFocus(value)
    local activities = {}
    if value then
        if value == GUILD_FOCUS_ATTRIBUTE_VALUE_TRADING then
            table.insert(activities, GUILD_ACTIVITY_ATTRIBUTE_VALUE_TRADING)
        elseif value == GUILD_FOCUS_ATTRIBUTE_VALUE_GROUP_PVE then
            -- Not currently tied to any additional attributes
        elseif value == GUILD_FOCUS_ATTRIBUTE_VALUE_ROLEPLAYING then
            table.insert(activities, GUILD_ACTIVITY_ATTRIBUTE_VALUE_ROLEPLAYING)
        elseif value == GUILD_FOCUS_ATTRIBUTE_VALUE_SOCIAL then
            -- Not currently tied to any additional attributes
        elseif value == GUILD_FOCUS_ATTRIBUTE_VALUE_PVP then
            table.insert(activities, GUILD_ACTIVITY_ATTRIBUTE_VALUE_PVP)
        elseif value == GUILD_FOCUS_ATTRIBUTE_VALUE_QUESTING then
            table.insert(activities, GUILD_ACTIVITY_ATTRIBUTE_VALUE_QUESTING)
        elseif value == GUILD_FOCUS_ATTRIBUTE_VALUE_CRAFTING then
            table.insert(activities, GUILD_ACTIVITY_ATTRIBUTE_VALUE_CRAFTING)
        end
    end

    return activities
end

function ZO_GuildRecruitment_GuildListing_Shared:SetDisabledAdditionalActivitiesForFocus(value)
    local activities = self:GetActivitiesForFocus(value)

    for _, activity in pairs(activities) do
        self.attributeSelectionData.activities.isDisabled[activity] = true
    end
end

function ZO_GuildRecruitment_GuildListing_Shared:UpdateAdditionalActivitiesForFocus(value, selected)
    local activities = self:GetActivitiesForFocus(value)

    for _, activity in pairs(activities) do
        SetGuildRecruitmentActivityValue(self.guildId, activity, selected)
        self.attributeSelectionData.activities.isChecked[activity] = selected
    end
end

function ZO_GuildRecruitment_GuildListing_Shared:UpdateAttributeValue(attribute, value)
    for _, data in pairs(self.attributeSelectionData) do
        if data.attribute == attribute then
            if data.currentValue ~= value then
                data.currentValue = value
                if data.updateFunction then
                    data.updateFunction(self.guildId, value)
                end
            end
            break
        end
    end
end

function ZO_GuildRecruitment_GuildListing_Shared:OnFocusSelected(attribute, value, oldValue)
    self:UpdateAttributeValue(attribute, value)

    local SELECTED = true
    self:UpdateAdditionalActivitiesForFocus(oldValue, SELECTED)
    self:UpdateAdditionalActivitiesForFocus(value, SELECTED)

    self.attributeSelectionData.activities.isDisabled = {}
    self:SetDisabledAdditionalActivitiesForFocus(self.attributeSelectionData.primaryFocus.currentValue)
    self:SetDisabledAdditionalActivitiesForFocus(self.attributeSelectionData.secondaryFocus.currentValue)

    self.gridList:RefreshGridList()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_GuildListing_Shared:OnDropdownSelected(attribute, value)
    self:UpdateAttributeValue(attribute, value)

    self.gridList:RefreshGridList()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_GuildListing_Shared:OnTextEdited(attribute, text)
    self:UpdateAttributeValue(attribute, text)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_GuildListing_Shared:OnRoleSelected(role, isSelected)
    -- Keyboard sends the role as an object with a role element on it. If that's the case
    -- extract the role enum from the control
    if type(role) ~= "number" and role.role then
        role = role.role
    end

    self.attributeSelectionData.roles.currentValue[role] = isSelected
    if self.attributeSelectionData.roles.baseData.updateFunction then
        self.attributeSelectionData.roles.baseData.updateFunction(self.guildId, role, isSelected)
    end
end

function ZO_GuildRecruitment_GuildListing_Shared:OnMinCPFocusLost(editBox)
    local maxAllowedValue = ZO_GuildFinder_Manager.GetMaxCPAllowedForInput()
    local updatedValue = tonumber(editBox:GetText()) or 0
    if updatedValue > maxAllowedValue then
        editBox:SetText(maxAllowedValue)
        SetGuildRecruitmentMinimumCP(guildId, maxAllowedValue)
    end
end

function ZO_GuildRecruitment_GuildListing_Shared:BuildAttributeSelectionData()
    local function OnFocusSelected(...)
        self:OnFocusSelected(...)
    end

    local function OnDropdownSelected(...)
        self:OnDropdownSelected(...)
    end

    local function OnTextEdited(...)
        self:OnTextEdited(...)
    end

    local function OnRoleSelected(...)
        self:OnRoleSelected(...)
    end

    local function OnMinCPFocusLost(...)
        self:OnMinCPFocusLost(...)
    end

    self.attributeSelectionData =
    {
        recruitmentStatus = 
        {
            attribute = GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_STATUS,
            entryTemplate = self.templateData.attributeSelection.statusEntryTemplate,
            iterBegin = GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_ITERATION_BEGIN,
            iterEnd = GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_ITERATION_END,
            stringPrefix = "SI_GUILDRECRUITMENTSTATUSATTRIBUTEVALUE",
            headerText = self.templateData.attributeSelection.recruitmentHeaderText,
            onSelectionCallback = OnDropdownSelected,
            updateFunction = function(...)
                SetGuildRecruitmentRecruitmentStatus(...)
                local RECRUITMENT_STATUS_CHANGED = true
                self:Save(RECRUITMENT_STATUS_CHANGED)
            end,
            narrationText = self.templateData.attributeSelection.narrationText
        },
        primaryFocus =
        {
            attribute = GUILD_META_DATA_ATTRIBUTE_PRIMARY_FOCUS,
            entryTemplate = self.templateData.attributeSelection.entryTemplate,
            iterBegin = GUILD_FOCUS_ATTRIBUTE_VALUE_TRADING, -- Start at selection after None
            iterEnd = GUILD_FOCUS_ATTRIBUTE_VALUE_ITERATION_END,
            omittedIndex = function()
                local recruitmentMessage, headerMessage, recruitmentStatus, primaryFocus, secondaryFocus = GetGuildRecruitmentInfo(self.guildId)
                return secondaryFocus
            end,
            stringPrefix = "SI_GUILDFOCUSATTRIBUTEVALUE",
            headerText = self.templateData.attributeSelection.primaryFocusHeaderText,
            onSelectionCallback = OnFocusSelected,
            updateFunction = function(...) SetGuildRecruitmentPrimaryFocus(...) end,
            narrationText = self.templateData.attributeSelection.narrationText,
        },
        secondaryFocus =
        {
            attribute = GUILD_META_DATA_ATTRIBUTE_SECONDARY_FOCUS,
            entryTemplate = self.templateData.attributeSelection.entryTemplate,
            iterBegin = GUILD_FOCUS_ATTRIBUTE_VALUE_ITERATION_BEGIN,
            iterEnd = GUILD_FOCUS_ATTRIBUTE_VALUE_ITERATION_END,
            omittedIndex = function()
                local recruitmentMessage, headerMessage, recruitmentStatus, primaryFocus, secondaryFocus = GetGuildRecruitmentInfo(self.guildId)
                return primaryFocus
            end,
            stringPrefix = "SI_GUILDFOCUSATTRIBUTEVALUE",
            headerText = self.templateData.attributeSelection.secondaryFocusHeaderText,
            onSelectionCallback = OnFocusSelected,
            updateFunction = function(...) SetGuildRecruitmentSecondaryFocus(...) end,
            narrationText = self.templateData.attributeSelection.narrationText,
        },
        personality =
        {
            attribute = GUILD_META_DATA_ATTRIBUTE_PERSONALITIES,
            entryTemplate = self.templateData.attributeSelection.entryTemplate,
            iterBegin = GUILD_PERSONALITY_ATTRIBUTE_VALUE_ITERATION_BEGIN,
            iterEnd = GUILD_PERSONALITY_ATTRIBUTE_VALUE_ITERATION_END,
            stringPrefix = "SI_GUILDPERSONALITYATTRIBUTEVALUE",
            headerText = self.templateData.attributeSelection.personalityHeaderText,
            onSelectionCallback = OnDropdownSelected,
            updateFunction = function(...) SetGuildRecruitmentPersonality(...) end,
            narrationText = self.templateData.attributeSelection.narrationText,
        },
        language =
        {
            attribute = GUILD_META_DATA_ATTRIBUTE_LANGUAGES,
            entryTemplate = self.templateData.attributeSelection.entryTemplate,
            iterBegin = GUILD_LANGUAGE_ATTRIBUTE_VALUE_ITERATION_BEGIN,
            iterEnd = GUILD_LANGUAGE_ATTRIBUTE_VALUE_ITERATION_END,
            extraValues = { GUILD_LANGUAGE_ATTRIBUTE_VALUE_OTHER },
            stringPrefix = "SI_GUILDLANGUAGEATTRIBUTEVALUE",
            headerText = self.templateData.attributeSelection.languageHeaderText,
            onSelectionCallback = OnDropdownSelected,
            updateFunction = function(...) SetGuildRecruitmentLanguage(...) end,
            narrationText = self.templateData.attributeSelection.narrationText,
        },
        recruitmentHeadline =
        {
            attribute = GUILD_META_DATA_ATTRIBUTE_HEADER_MESSAGE,
            entryTemplate = self.templateData.headlineEditBox.entryTemplate,
            dimensionsX = self.templateData.headlineEditBox.dimensionsX,
            dimensionsY = self.templateData.headlineEditBox.dimensionsY,
            headerText = self.templateData.headlineEditBox.headerText,
            defaultText = GetString(SI_GUILD_RECRUITMENT_HEADLINE_DEFAULT_TEXT),
            emptyText = GetString(SI_GUILD_RECRUITMENT_HEADLINE_EMPTY_TEXT),
            stripMarkup = true,
            onEditCallback = OnTextEdited,
            updateFunction = function(...) SetGuildRecruitmentHeaderMessage(...) end,
            narrationText = self.templateData.headlineEditBox.narrationText,
        },
        description =
        {
            attribute =  GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_MESSAGE,
            entryTemplate = self.templateData.descriptionEditBox.entryTemplate,
            dimensionsX = self.templateData.descriptionEditBox.dimensionsX,
            dimensionsY = self.templateData.descriptionEditBox.dimensionsY,
            headerText = self.templateData.descriptionEditBox.headerText,
            defaultText = GetString(SI_GUILD_RECRUITMENT_DESCRIPTION_DEFAULT_TEXT),
            emptyText = GetString(SI_GUILD_RECRUITMENT_DESCRIPTION_EMPTY_TEXT),
            onEditCallback = OnTextEdited,
            updateFunction = function(...) SetGuildRecruitmentRecruitmentMessage(...) end,
            narrationText = self.templateData.descriptionEditBox.narrationText
        },
        roles =
        {
            ordering = ZO_GUILD_FINDER_ROLE_ORDER,
            baseData =
            {
                attribute =  GUILD_META_DATA_ATTRIBUTE_ROLES,
                entryTemplate = self.templateData.roleSelector.entryTemplate,
                dimensionsX = self.templateData.roleSelector.dimensionsX,
                dimensionsY = self.templateData.roleSelector.dimensionsY,
                onSelectionCallback = OnRoleSelected,
                updateFunction = function(...) SetGuildRecruitmentRoleValue(...) end,
                narrationText = self.templateData.roleSelector.narrationText,
            },
            overrideData =
            {
                [LFG_ROLE_TANK] =
                {
                    headerText = self.templateData.roleSelector.headerText,
                },
                [LFG_ROLE_HEAL] =
                {
                    headerText = " ",
                },
                [LFG_ROLE_DPS] =
                {
                    entryTemplate = self.templateData.roleSelector.endEntryTemplate,
                    dimensionsX = self.templateData.roleSelector.endDimensionsX,
                    headerText = " ",
                },
            },
        },
        minimumCP =
        {
            attribute =  GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP,
            entryTemplate = self.templateData.minimumCP.entryTemplate,
            dimensionsX = self.templateData.minimumCP.dimensionsX,
            dimensionsY = self.templateData.minimumCP.dimensionsY,
            headerText = self.templateData.minimumCP.headerText,
            onEditCallback = OnTextEdited,
            defaultText = "0",
            onFocusLostCallback = OnMinCPFocusLost,
            updateFunction = function(guildId, text)
                SetGuildRecruitmentMinimumCP(guildId, tonumber(text) or 0)
            end,
            narrationText = self.templateData.minimumCP.narrationText,
        },
        startTime =
        {
            attribute =  GUILD_META_DATA_ATTRIBUTE_START_TIME,
            entryTemplate = self.templateData.attributeSelection.startTimeEntryTemplate,
            isTimeSelection = true,
            headerText = self.templateData.attributeSelection.timeRangeHeaderText,
            onSelectionCallback = OnDropdownSelected,
            updateFunction = function(...) SetGuildRecruitmentStartTime(...) end,
            narrationText = self.templateData.attributeSelection.narrationText,
        },
        endTime =
        {
            attribute =  GUILD_META_DATA_ATTRIBUTE_END_TIME,
            entryTemplate = self.templateData.attributeSelection.endTimeEntryTemplate,
            isTimeSelection = true,
            headerText = " ",
            onSelectionCallback = OnDropdownSelected,
            updateFunction = function(...) SetGuildRecruitmentEndTime(...) end,
            narrationText = self.templateData.attributeSelection.narrationText,
        },
        activities =
        {
            isChecked = {},
            isDisabled = {},
        }
    }
end

function ZO_GuildRecruitment_GuildListing_Shared:SetGuildId(guildId)
    self.guildId = guildId

    self:RefreshData()
end

function ZO_GuildRecruitment_GuildListing_Shared:RefreshData()
    local guildId = self.guildId
    local recruitmentMessage, headerMessage, recruitmentStatus, primaryFocus, secondaryFocus, personality, language, minimumCP = GetGuildRecruitmentInfo(guildId)
    self.attributeSelectionData.recruitmentStatus.currentValue = recruitmentStatus
    self.attributeSelectionData.primaryFocus.currentValue = primaryFocus
    self.attributeSelectionData.secondaryFocus.currentValue = secondaryFocus
    self.attributeSelectionData.personality.currentValue = personality
    self.attributeSelectionData.language.currentValue = language
    self.attributeSelectionData.recruitmentHeadline.currentValue = headerMessage
    self.attributeSelectionData.description.currentValue = recruitmentMessage
    self.attributeSelectionData.startTime.currentValue = GetGuildRecruitmentStartTime(guildId)
    self.attributeSelectionData.endTime.currentValue = GetGuildRecruitmentEndTime(guildId)
    self.attributeSelectionData.minimumCP.currentValue = minimumCP

    for i = GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_END do
        self.attributeSelectionData.activities.isChecked[i] = GetGuildRecruitmentActivityValue(self.guildId, i)
    end

    self.attributeSelectionData.roles.currentValue = {}
    for i, role in ipairs(self.attributeSelectionData.roles.ordering) do
        self.attributeSelectionData.roles.currentValue[role] = GetGuildRecruitmentRoleValue(guildId, role)
    end

    self:BuildGridList()

    self:UpdateAlert()
end

function ZO_GuildRecruitment_GuildListing_Shared:BuildGridList()
    if self.gridList then
        local currentScrollValue = self.gridList:GetScrollValue()
        self.gridList:ClearGridList()
        self.attributeSelectionData.activities.isDisabled = {}

        -- Recruitment Status
        self:BuildAttributeSelectionEntry(self.attributeSelectionData.recruitmentStatus)

        -- Primary Focus
        self:BuildAttributeSelectionEntry(self.attributeSelectionData.primaryFocus)

        -- Secondary Focus
        self:BuildAttributeSelectionEntry(self.attributeSelectionData.secondaryFocus)

        -- Activity Checkboxes
        self:SetDisabledAdditionalActivitiesForFocus(self.attributeSelectionData.primaryFocus.currentValue)
        self:SetDisabledAdditionalActivitiesForFocus(self.attributeSelectionData.secondaryFocus.currentValue)
        self:BuildActivityCheckboxes()

        -- Role Selector
        self:BuildRoleSelectorEntry(self.attributeSelectionData.roles)

        -- Minimum CP
        self:BuildEditBoxEntry(self.attributeSelectionData.minimumCP)

        -- Personality
        self:BuildAttributeSelectionEntry(self.attributeSelectionData.personality)

        -- Language
        self:BuildAttributeSelectionEntry(self.attributeSelectionData.language)

        -- Play Time Range
        self:BuildAttributeSelectionEntry(self.attributeSelectionData.startTime)
        self:BuildAttributeSelectionEntry(self.attributeSelectionData.endTime)

        -- Recruitment Headline
        self:BuildEditBoxEntry(self.attributeSelectionData.recruitmentHeadline)

        -- Guild Description
        self:BuildEditBoxEntry(self.attributeSelectionData.description)
        
        self.gridList:CommitGridList()

        self.gridList:ScrollToValue(currentScrollValue)
    end
end

function ZO_GuildRecruitment_GuildListing_Shared:BuildAttributeSelectionEntry(data)
    data.gridHeaderName = ""
    self.gridList:AddEntry(data, data.entryTemplate)
end

function ZO_GuildRecruitment_GuildListing_Shared:OnActivityCheckboxToggle(attribute, isChecked)
    SetGuildRecruitmentActivityValue(self.guildId, attribute, isChecked)

    self.attributeSelectionData.activities.isChecked[attribute] = isChecked

    self.gridList:RefreshGridList()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_GuildListing_Shared:BuildActivityCheckboxes()
    local attribute = GUILD_META_DATA_ATTRIBUTE_ACTIVITIES
    local headerText = self.templateData.activityCheckbox.headerText
    local narrationText = self.templateData.activityCheckbox.narrationText
    self.attributeSelectionData.activities.entryData = {}
    for i = GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_END do
        local data =
        {
            attribute = attribute,
            value = i,
            text = GetString("SI_GUILDACTIVITYATTRIBUTEVALUE", i),
            clickSound = SOUNDS.GAMEPAD_GUILD_FINDER_TOGGLE_ACTIVITY,
            isDisabled = function()
                return self.attributeSelectionData.activities.isDisabled[i]
            end,
            isChecked = function()
                return self.attributeSelectionData.activities.isChecked[i] or self.attributeSelectionData.activities.isDisabled[i]
            end,
            onToggleFunction = function(...) self:OnActivityCheckboxToggle(...) end,
            gridHeaderName = headerText,
            gridHeaderTemplate = self.templateData.headerTemplate,
            narrationText = narrationText,
        }
        if i == GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_END then
            self.gridList:AddEntry(data, self.templateData.activityCheckbox.endEntryTemplate)
        else
            self.gridList:AddEntry(data, self.templateData.activityCheckbox.entryTemplate)
        end
        self.attributeSelectionData.activities.entryData[i] = data
    end
end

function ZO_GuildRecruitment_GuildListing_Shared:BuildEditBoxEntry(data)
    data.gridHeaderName = ""
    self.gridList:AddEntry(data, data.entryTemplate)
end

function ZO_GuildRecruitment_GuildListing_Shared:BuildRoleSelectorEntry(data)
    for i, role in ipairs(data.ordering) do
        local resultData = ZO_ShallowTableCopy(data.baseData, nil)
        resultData = ZO_ShallowTableCopy(data.overrideData[role], resultData)
        resultData.currentValues = data.currentValue
        resultData.role = role
        self:AddRoleEntry(resultData)
    end
end

function ZO_GuildRecruitment_GuildListing_Shared:AddRoleEntry(data)
    data.gridHeaderName = ""
    self.gridList:AddEntry(data, data.entryTemplate)
end

function ZO_GuildRecruitment_GuildListing_Shared:OnShowing()
    self:RefreshData()
end

function ZO_GuildRecruitment_GuildListing_Shared:OnHidden()

end