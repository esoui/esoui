------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_ENTRY_TEMPLATE =
{
    COMBOBOX = 1,
    COMBOBOX_STATUS = 2,
    COMBOBOX_START_TIME = 3,
    COMBOBOX_END_TIME = 4,
    CHECKBOX = 5,
    CHECKBOX_END = 6,
    EDITBOX = 7,
    DESCRIPTION_EDITBOX = 8,
    ROLE_SELECTOR = 9,
    ROLE_SELECTOR_END = 10,
    SINGLE_LINE_EDITBOX = 11,
}

ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_NOT_LISTED_DIALOG_NAME = "GAMEPAD_GUILD_LISTING_NOT_LISTED_PROMPT"
ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_UNLISTED_DIALOG_NAME = "GAMEPAD_GUILD_LISTING_UNLISTED_PROMPT"

ZO_GuildRecruitment_GuildListing_Gamepad = ZO_Object.MultiSubclass(ZO_GuildRecruitment_GuildListing_Shared, ZO_GuildFinder_Panel_GamepadBehavior)

function ZO_GuildRecruitment_GuildListing_Gamepad:New(...)
    return ZO_GuildFinder_Panel_GamepadBehavior.New(self, ...)
end

function ZO_GuildRecruitment_GuildListing_Gamepad:Initialize(control)
    local templateData =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        gridHighlightTemplate = "ZO_GuildRecruitment_GuildListing_Gamepad_Highlight_Template",
        headerTemplate = "ZO_GuildRecruitment_GuildListing_Gamepad_Header_Template",
        headerHeight = ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_HEIGHT,
        gridPaddingY = 10,
        attributeSelection =
        {
            entryTemplate = "ZO_GuildRecruitment_AttributeSelectionTile_Gamepad_Control",
            dimensionsX = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_COLUMN_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_COMBOBOX_ENTRY_HEIGHT,
            statusEntryTemplate = "ZO_GuildRecruitment_StatusSelectionTile_Gamepad_Control",
            startTimeEntryTemplate = "ZO_GuildRecruitment_StartTimeSelectionTile_Gamepad_Control",
            endTimeEntryTemplate = "ZO_GuildRecruitment_EndTimeSelectionTile_Gamepad_Control",
            startTimeDimensionsX = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_START_TIME_COMBOBOX_ENTRY_WIDTH,
            timeDimensionsY = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_COMBOBOX_ENTRY_HEIGHT,
            statusDimensionsX = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_COMBOBOX_LONG_ENTRY_WIDTH,
            recruitmentHeaderText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_STATUS),
            primaryFocusHeaderText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PRIMARY_FOCUS),
            secondaryFocusHeaderText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SECONDARY_FOCUS),
            personalityHeaderText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PERSONALITIES),
            languageHeaderText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_LANGUAGES),
            timeRangeHeaderText = GetString(SI_GUILD_FINDER_CORE_HOURS_LABEL),
            gridPaddingX = 20,
            gridPaddingY = 10,
            narrationText = ZO_GetNarrationTextForGridListTile,
        },
        activityCheckbox =
        {
            entryTemplate = "ZO_CheckboxTile_Gamepad_Control",
            dimensionsX = ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_COLUMN_WIDTH,
            dimensionsY = ZO_CHECKBOX_TILE_GAMEPAD_HEIGHT,
            endEntryTemplate = "ZO_GuildRecruitment_ActivityCheckboxEndTile_Gamepad_Control",
            endDimensionsY = ZO_CHECKBOX_TILE_GAMEPAD_HEIGHT,
            gridPaddingX = 20,
            gridPaddingY = 0,
            headerText = GetString(SI_GAMEPAD_GUILD_RECRUITMENT_ADDITIONAL_ACTIVITIES_HEADER),
            narrationText = function(entryData)
                local isChecked = entryData.isChecked()
                return ZO_FormatToggleNarrationText(entryData.text, isChecked, entryData.gridHeaderName)
            end,
        },
        headlineEditBox =
        {
            entryTemplate = "ZO_GuildRecruitment_EditBoxTile_Gamepad_Control",
            dimensionsX = ZO_GUILD_RECRUITMENT_EDITBOX_GAMEPAD_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_EDITBOX_GAMEPAD_HEADLINE_HEIGHT,
            headerText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_HEADER_MESSAGE),
            gridPaddingY = 10,
            narrationText = ZO_GetNarrationTextForGridListTile,
        },
        descriptionEditBox =
        {
            entryTemplate = "ZO_GuildRecruitment_EditBoxTile_Description_Gamepad_Control",
            dimensionsX = ZO_GUILD_RECRUITMENT_EDITBOX_GAMEPAD_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_EDITBOX_GAMEPAD_DESCRIPTION_HEIGHT,
            headerText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_MESSAGE),
            gridPaddingY = 10,
            narrationText = ZO_GetNarrationTextForGridListTile,
        },
        roleSelector =
        {
            entryTemplate = "ZO_GuildRecruitment_RoleSelectorTile_Gamepad_Control",
            endEntryTemplate = "ZO_GuildRecruitment_RoleSelectorEndTile_Gamepad_Control",
            headerText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES),
            dimensionsX = ZO_GUILD_RECRUITMENT_ROLE_GAMEPAD_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_ROLE_SELECTOR_GAMEPAD_HEIGHT,
            endDimensionsX = ZO_GUILD_RECRUITMENT_ROLE_END_GAMEPAD_WIDTH,
            gridPaddingY = 0,
            narrationText = ZO_GetNarrationTextForGridListTile,
        },
        minimumCP =
        {
            entryTemplate = "ZO_GuildRecruitment_NumericEditBoxTile_Gamepad_Control",
            headerText = GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP),
            dimensionsX = ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_GAMEPAD_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_GAMEPAD_ENTRY_HEIGHT,
            gridPaddingY = 10,
            narrationText = ZO_GetNarrationTextForGridListTile,
        },
    }

    ZO_GuildRecruitment_GuildListing_Shared.Initialize(self, control, templateData)
    ZO_GuildFinder_Panel_GamepadBehavior.Initialize(self, control)

    self:InitializeGuildNotListedDialog()
    self:InitializeGuildUnlistedDialog()
end

function ZO_GuildRecruitment_GuildListing_Gamepad:InitializeGridList()
    ZO_GuildRecruitment_GuildListing_Shared.InitializeGridList(self)

    self.gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)
end

function ZO_GuildRecruitment_GuildListing_Gamepad:UpdateAlert(previousData, selectedData)
    if self:GetFragment():IsShowing() then
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

        local numMembers, _, _, numInvitees = GetGuildInfo(self.guildId)
        if numMembers + numInvitees >= MAX_GUILD_MEMBERS then
            GAMEPAD_TOOLTIPS:LayoutGuildAlert(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_GUILD_RECRUITMENT_GUILD_LISTING_FULL_GUILD_ALERT))
        elseif GetGuildFinderNumGuildApplications(self.guildId) >= MAX_PENDING_APPLICATIONS_PER_GUILD then
            GAMEPAD_TOOLTIPS:LayoutGuildAlert(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_GUILD_RECRUITMENT_GUILD_LISTING_APPLICATIONS_FULL_GUILD_ALERT))
        end
    end
end

function ZO_GuildRecruitment_GuildListing_Gamepad:OnGridSelectionChanged(oldSelectedData, selectedData)
    -- Deselect previous tile
    if oldSelectedData and oldSelectedData.dataEntry then
        oldSelectedData.isSelected = false
    end

    -- Select newly selected tile.
    if selectedData and selectedData.dataEntry then
        selectedData.isSelected = true

        if oldSelectedData and oldSelectedData.dataEntry then
            self.currentGridListSelectedData = self.gridList:GetSelectedData()
        end
    end

    self.gridList:RefreshGridList()
end

function ZO_GuildRecruitment_GuildListing_Gamepad:OnShowing()
    ZO_GuildRecruitment_GuildListing_Shared.OnShowing(self)
end

function ZO_GuildRecruitment_GuildListing_Gamepad:OnHidden()
    ZO_GuildRecruitment_GuildListing_Shared.OnHidden(self)

    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_GuildRecruitment_GuildListing_Gamepad:Activate()
    ZO_GuildFinder_Panel_GamepadBehavior.Activate(self)

    self.gridList:Activate()
end

function ZO_GuildRecruitment_GuildListing_Gamepad:Deactivate()
    ZO_GuildFinder_Panel_GamepadBehavior.Deactivate(self)

    if self.currentActiveGridListEntry then
        self.currentActiveGridListEntry:Deactivate()
        self.currentActiveGridListEntry = nil
    end

    self.currentGridListSelectedData = nil
    self.gridList:Deactivate()

    self:Save()
end

function ZO_GuildRecruitment_GuildListing_Gamepad:Save(onRecruitmentStatusChanged)
    if self:CanSave() then
        local desiredRecruitmentStatus = self.attributeSelectionData.recruitmentStatus.currentValue
        local remainingRequiredFields = { SaveGuildRecruitmentPendingChanges(self.guildId) }
        PlaySound(SOUNDS.GUILD_RANK_SAVED)
        if desiredRecruitmentStatus == GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_LISTED and #remainingRequiredFields > 0 then
            self:RefreshData()
            if onRecruitmentStatusChanged then
                ZO_Dialogs_ShowPlatformDialog(ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_NOT_LISTED_DIALOG_NAME, remainingRequiredFields)
            else
                ZO_Dialogs_ShowPlatformDialog(ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_UNLISTED_DIALOG_NAME, remainingRequiredFields)
            end
        elseif onRecruitmentStatusChanged then
            local guildName = ZO_WHITE:Colorize(GetGuildName(self.guildId))
            local decoratedGuildName = ZO_AllianceIconNameFormatter(GetGuildAlliance(self.guildId), guildName)
            if desiredRecruitmentStatus == GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_LISTED then
                ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_SAVE_FROM_RECRUITMENT_STATUS_LISTED", nil, { mainTextParams = { decoratedGuildName } })
            else
                ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_SAVE_FROM_RECRUITMENT_STATUS_UNLISTED", nil, { mainTextParams = { decoratedGuildName } })
            end
        end

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GuildRecruitment_GuildListing_Gamepad:InitializeKeybinds()
    ZO_GuildFinder_Panel_GamepadBehavior.InitializeKeybinds(self)

    self.keybindsNeededInActiveAttributes = {}
    for i, data in pairs(self.keybindStripDescriptor) do
        if i ~= "alignment" then
            table.insert(self.keybindsNeededInActiveAttributes, data)
        end
    end

    table.insert(self.keybindStripDescriptor,
        -- select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedData = self.gridList:GetSelectedData()
                if selectedData then
                    if selectedData.dataEntry.typeId == ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_ENTRY_TEMPLATE.CHECKBOX or
                       selectedData.dataEntry.typeId == ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_ENTRY_TEMPLATE.CHECKBOX_END then
                        selectedData.dataEntry.control.object:OnCheckboxToggle()
                        --Re-narrate the selection when a checkbox is toggled
                        SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.gridList)
                    elseif selectedData.dataEntry.typeId == ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_ENTRY_TEMPLATE.ROLE_SELECTOR or
                           selectedData.dataEntry.typeId == ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_ENTRY_TEMPLATE.ROLE_SELECTOR_END then
                        selectedData.dataEntry.control.object:OnRoleToggle()
                        --Re-narrate the selection when a role is toggled
                        SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.gridList)
                    else
                        self.currentGridListSelectedData = selectedData
                        self.gridList:Deactivate()

                        local function DeactivateCallback()
                            self.gridList:Activate()
                            self.currentActiveGridListEntry = nil
                        end

                        self.currentActiveGridListEntry = selectedData.dataEntry.control.object
                        self.currentActiveGridListEntry:SetDeactivateCallback(DeactivateCallback)
                        self.currentActiveGridListEntry:Activate()
                    end
                end
            end,
        }
    )
end

function ZO_GuildRecruitment_GuildListing_Gamepad:BuildGridList()
    ZO_GuildRecruitment_GuildListing_Shared.BuildGridList(self)

    if self.currentGridListSelectedData then
        self.gridList:SelectData(self.currentGridListSelectedData)
    end
end

do
    local BULLET_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_bullet.dds"
    local BULLET_ICON_SIZE = 32

    function ZO_GuildRecruitment_GuildListing_Gamepad:InitializeGuildNotListedDialog()
        local function ReleaseDialog()
            GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
            ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_NOT_LISTED_DIALOG_NAME)
        end

        ZO_Dialogs_RegisterCustomDialog(ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_NOT_LISTED_DIALOG_NAME,
        {
            blockDialogReleaseOnPress = true,

            canQueue = true,

            gamepadInfo = {
                dialogType = GAMEPAD_DIALOGS.STATIC_LIST,
                allowShowOnNextScene = true,
            },

            setup = function(dialog)
                dialog:setupFunc()
            end,

            title =
            {
                text = SI_GUILD_RECRUITMENT_NOT_LISTED_DIALOG_TITLE,
            },

            mainText =
            {
                text = SI_GUILD_RECRUITMENT_NOT_LISTED_DIALOG_DESCRIPTION,
            },

            itemInfo = function(dialog)
                local bulletListTable = {}

                for i, attribute in ipairs(dialog.data) do
                    table.insert(bulletListTable,
                    {
                        icon = BULLET_ICON,
                        iconSize = BULLET_ICON_SIZE,
                        label = GetString("SI_GUILDMETADATAATTRIBUTE", attribute),
                    })
                end

                return bulletListTable
            end,

            buttons =
            {
                -- Exit Button
                {
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_GAMEPAD_BACK_OPTION,
                    callback = function(dialog)
                        ReleaseDialog()
                    end,
                },
            }
        })
    end

    function ZO_GuildRecruitment_GuildListing_Gamepad:InitializeGuildUnlistedDialog()
        local function ReleaseDialog()
            GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
            ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_UNLISTED_DIALOG_NAME)
        end

        ZO_Dialogs_RegisterCustomDialog(ZO_GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD_UNLISTED_DIALOG_NAME,
        {
            blockDialogReleaseOnPress = true,

            canQueue = true,

            gamepadInfo = {
                dialogType = GAMEPAD_DIALOGS.STATIC_LIST,
                allowShowOnNextScene = true,
            },

            setup = function(dialog)
                dialog:setupFunc()
            end,

            title =
            {
                text = SI_GUILD_RECRUITMENT_LISTING_FAILED_DIALOG_TITLE,
            },

            mainText =
            {
                text = SI_GUILD_RECRUITMENT_LISTING_FAILED_DIALOG_DESCRIPTION,
            },

            itemInfo = function(dialog)
                local bulletListTable = {}

                for i, attribute in ipairs(dialog.data) do
                    table.insert(bulletListTable,
                    {
                        icon = BULLET_ICON,
                        iconSize = BULLET_ICON_SIZE,
                        label = GetString("SI_GUILDMETADATAATTRIBUTE", attribute),
                    })
                end

                return bulletListTable
            end,

            buttons =
            {
                -- Exit Button
                {
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_GAMEPAD_BACK_OPTION,
                    callback = function(dialog)
                        ReleaseDialog()
                    end,
                },
            }
        })
    end
end

-- XML functions
----------------

function ZO_GuildRecruitment_GuildListing_Gamepad_OnInitialized(control)
    GUILD_RECRUITMENT_GUILD_LISTING_GAMEPAD = ZO_GuildRecruitment_GuildListing_Gamepad:New(control)
end