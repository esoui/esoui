------------------
-- Guild Finder --
------------------

ZO_GuildRecruitment_GuildListing_Keyboard = ZO_GuildRecruitment_GuildListing_Shared:Subclass()

function ZO_GuildRecruitment_GuildListing_Keyboard:New(...)
    return ZO_GuildRecruitment_GuildListing_Shared.New(self, ...)
end

function ZO_GuildRecruitment_GuildListing_Keyboard:Initialize(control)
    local function OnTextEdited(control, data)
        local attribute = data.attribute
        local editBoxObject = control and control.object
        editBoxObject:SetControlHidden()
        if editBoxObject:IsEditing() then
            data.currentValue = editBoxObject:GetEditBoxText()
        end
    end

    local templateData =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        headerTemplate = "ZO_GuildRecruitment_GuildListing_Keyboard_Header_Template",
        headerHeight = 24,
        gridPaddingY = 10,
        textEditHideCallback = OnTextEdited,
        attributeSelection =
        {
            entryTemplate = "ZO_GuildRecruitment_AttributeSelectionTile_Keyboard_Control",
            dimensionsX = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COLUMN_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COMBOBOX_HEIGHT,
            statusEntryTemplate = "ZO_GuildRecruitment_StatusSelectionTile_Keyboard_Control",
            statusDimensionsX = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COLUMN_LONG_WIDTH,
            startTimeEntryTemplate = "ZO_GuildRecruitment_StartTimeSelectionTile_Keyboard_Control",
            endTimeEntryTemplate = "ZO_GuildRecruitment_EndTimeSelectionTile_Keyboard_Control",
            startTimeDimensionsX = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COLUMN_WIDTH,
            timeDimensionsY = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COMBOBOX_TALL_HEIGHT,
            recruitmentHeaderText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_STATUS)),
            primaryFocusHeaderText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PRIMARY_FOCUS)),
            secondaryFocusHeaderText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SECONDARY_FOCUS)),
            personalityHeaderText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PERSONALITIES)),
            languageHeaderText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_LANGUAGES)),
            timeRangeHeaderText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString(SI_GUILD_FINDER_CORE_HOURS_LABEL)),
            gridPaddingX = 0,
            gridPaddingY = 10,
        },
        activityCheckbox =
        {
            entryTemplate = "ZO_GuildRecruitment_ActivityCheckboxTile_Keyboard_Control",
            headerText = GetString(SI_GUILD_RECRUITMENT_ADDITIONAL_ACTIVITIES_HEADER),
            dimensionsX = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COLUMN_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_CHECKBOX_HEIGHT,
            endEntryTemplate = "ZO_GuildRecruitment_ActivityCheckboxEndTile_Keyboard_Control",
            endDimensionsY = ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_CHECKBOX_END_HEIGHT,
            gridPaddingX = 0,
            gridPaddingY = 0,
        },
        headlineEditBox =
        {
            entryTemplate = "ZO_GuildRecruitment_MultilineEditBoxTile_Keyboard_Control",
            dimensionsX = ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_HEADLINE_ENTRY_HEIGHT,
            headerText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_HEADER_MESSAGE)),
            gridPaddingY = 10,
        },
        descriptionEditBox =
        {
            entryTemplate = "ZO_GuildRecruitment_MultilineEditBoxTile_Description_Keyboard_Control",
            dimensionsX = ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_EDITBOX_KEYBOARD_DESCRIPTION_ENTRY_HEIGHT,
            headerText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_MESSAGE)),
            gridPaddingY = 10,
        },
        roleSelector =
        {
            entryTemplate = "ZO_GuildRecruitment_RoleSelectorTile_Keyboard_Control",
            endEntryTemplate = "ZO_GuildRecruitment_RoleSelectorEndTile_Keyboard_Control",
            headerText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES)),
            dimensionsX = ZO_GUILD_RECRUITMENT_ROLE_KEYBOARD_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_ROLESELECTOR_KEYBOARD_HEIGHT,
            endDimensionsX = ZO_GUILD_RECRUITMENT_ROLE_END_KEYBOARD_WIDTH,
            gridPaddingY = 10,
        },
        minimumCP =
        {
            entryTemplate = "ZO_GuildRecruitment_NumericEditBoxTile_Keyboard_Control",
            headerText = zo_strformat(SI_GUILD_RECRUITMENT_GUILD_LISTING_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP)),
            dimensionsX = ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_KEYBOARD_WIDTH,
            dimensionsY = ZO_GUILD_RECRUITMENT_NUMERIC_EDITBOX_KEYBOARD_ENTRY_HEIGHT,
            gridPaddingY = 10,
        },
    }

    ZO_GuildRecruitment_GuildListing_Shared.Initialize(self, control, templateData)

    self.alertControl = self.control:GetNamedChild("AlertContainerAlert")

    self:InitializeKeybindDescriptors()
end

function ZO_GuildRecruitment_GuildListing_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Link in Chat
        {
            name = GetString(SI_GUILD_RECRUITMENT_LINK_IN_CHAT),
            keybind = "UI_SHORTCUT_SECONDARY",
            enabled = function()
                local numMembers, _, _, numInvitees = GetGuildInfo(self.guildId)
                if numMembers + numInvitees >= MAX_GUILD_MEMBERS then
                    return false, GetString(SI_GUILD_RECRUITMENT_MAX_GUILDS_CANT_LINK)
                end
                return true
            end,
            visible = function()
                return GetGuildRecruitmentStatus(self.guildId) == GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_LISTED
            end,
            callback = function()
                local link = GetGuildRecruitmentLink(self.guildId, LINK_STYLE_BRACKETS)
                ZO_LinkHandler_InsertLink(link)
            end,
        },
    }
end

function ZO_GuildRecruitment_GuildListing_Shared:Save(onRecruitmentStatusChanged)
    if self:CanSave() then
        local desiredRecruitmentStatus = self.attributeSelectionData.recruitmentStatus.currentValue
        local remainingRequiredFields = { SaveGuildRecruitmentPendingChanges(self.guildId) }
        PlaySound(SOUNDS.GUILD_RANK_SAVED)
        if desiredRecruitmentStatus == GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_LISTED and #remainingRequiredFields > 0 then
            self:RefreshData()
            if onRecruitmentStatusChanged then
                ZO_Dialogs_ShowPlatformDialog("GUILD_NOT_LISTED_KEYBOARD", remainingRequiredFields)
            else
                ZO_Dialogs_ShowPlatformDialog("GUILD_UNLISTED_KEYBOARD", remainingRequiredFields)
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

function ZO_GuildRecruitment_GuildListing_Keyboard:ChangeSelectedGuild(dialogCallback, dialogParams)
    if dialogCallback and self.guildId ~= dialogParams.entry.guildId then
        dialogCallback(dialogParams)
    end
end

function ZO_GuildRecruitment_GuildListing_Keyboard:UpdateAlert()
    local numMembers, _, _, numInvitees = GetGuildInfo(self.guildId)
    local hideAlert = true

    if numMembers + numInvitees >= MAX_GUILD_MEMBERS then
        self.alertControl:SetText(GetString(SI_GUILD_RECRUITMENT_GUILD_LISTING_FULL_GUILD_ALERT))
        hideAlert = false
    elseif GetGuildFinderNumGuildApplications(self.guildId) >= MAX_PENDING_APPLICATIONS_PER_GUILD then
        self.alertControl:SetText(GetString(SI_GUILD_RECRUITMENT_GUILD_LISTING_APPLICATIONS_FULL_GUILD_ALERT))
        hideAlert = false
    end

    self.alertControl:SetHidden(hideAlert)
end

function ZO_GuildRecruitment_GuildListing_Keyboard:OnHidden()
    ZO_GuildRecruitment_GuildListing_Shared.OnHidden(self)

    self:Save()

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_GuildListing_Keyboard:ShowCategory()
    ZO_GuildFinder_Panel_Shared.ShowCategory(self)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_GuildListing_Keyboard:HideCategory()
    ZO_GuildFinder_Panel_Shared.HideCategory(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

-- XML functions
----------------

function ZO_GuildRecruitment_GuildListing_Keyboard_OnInitialized(control)
    GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD = ZO_GuildRecruitment_GuildListing_Keyboard:New(control)
end

function ZO_GuildRecruitment_GuildListing_NotListedDialog_Keyboard_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("GUILD_NOT_LISTED_KEYBOARD",
    {
        title =
        {
            text = SI_GUILD_RECRUITMENT_NOT_LISTED_DIALOG_TITLE,
        },
        mainText =
        {
            text = SI_GUILD_RECRUITMENT_NOT_LISTED_DIALOG_DESCRIPTION,
        },
        canQueue = true,
        customControl = self,
        setup = function(dialog)
            if not dialog.bulletList then
                dialog.bulletList = ZO_BulletList:New(dialog:GetNamedChild("BulletList"))
            end

            dialog.bulletList:Clear()

            for i, attribute in ipairs(dialog.data) do
                dialog.bulletList:AddLine(GetString("SI_GUILDMETADATAATTRIBUTE", attribute))
            end
        end,
        buttons =
        {
            -- Exit Button
            {
                control = self:GetNamedChild("Exit"),
                keybind = "DIALOG_NEGATIVE",
                text = SI_EXIT_BUTTON,
            },
        },
    })
end

function ZO_GuildRecruitment_GuildListing_UnlistedDialog_Keyboard_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("GUILD_UNLISTED_KEYBOARD",
    {
        title =
        {
            text = SI_GUILD_RECRUITMENT_LISTING_FAILED_DIALOG_TITLE,
        },
        mainText =
        {
            text = SI_GUILD_RECRUITMENT_LISTING_FAILED_DIALOG_DESCRIPTION,
        },
        canQueue = true,
        customControl = self,
        setup = function(dialog)
            if not dialog.bulletList then
                dialog.bulletList = ZO_BulletList:New(dialog:GetNamedChild("BulletList"))
            end

            dialog.bulletList:Clear()

            for i, attribute in ipairs(dialog.data) do
                dialog.bulletList:AddLine(GetString("SI_GUILDMETADATAATTRIBUTE", attribute))
            end
        end,
        buttons =
        {
            -- Exit Button
            {
                control = self:GetNamedChild("Exit"),
                keybind = "DIALOG_NEGATIVE",
                text = SI_EXIT_BUTTON,
            },
        },
    })
end