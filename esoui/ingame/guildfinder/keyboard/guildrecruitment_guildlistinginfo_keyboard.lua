------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_GUILD_INFO_RECRUITMENT_MESSAGE_BASE_OFFSET_Y = 20

ZO_GuildRecruitment_GuildListingInfo_Keyboard = ZO_GuildRecruitment_GuildListingInfo_Shared:Subclass()

function ZO_GuildRecruitment_GuildListingInfo_Keyboard:New(...)
    return ZO_GuildRecruitment_GuildListingInfo_Shared.New(self, ...)
end

function ZO_GuildRecruitment_GuildListingInfo_Keyboard:Initialize(control)
    ZO_GuildRecruitment_GuildListingInfo_Shared.Initialize(self, control)

    self.topSection = control:GetNamedChild("TopSection")
    self.infoPanel = control:GetNamedChild("InfoPanel")
    self.alertControl = self.control:GetNamedChild("AlertContainerAlert")

    self.recruitmentStatusLabel = self.topSection:GetNamedChild("Status")
    self.primaryFocusLabel = self.topSection:GetNamedChild("PrimaryFocus")
    self.secondaryFocusLabel = self.topSection:GetNamedChild("SecondaryFocus")
    self.playtimeLabel = self.topSection:GetNamedChild("Playtime")
    self.personalitiesLabel = self.topSection:GetNamedChild("Personalities")
    self.languagesLabel = self.topSection:GetNamedChild("Languages")
    self.rolesLabel = self.topSection:GetNamedChild("Roles")
    self.minCPLabel = self.topSection:GetNamedChild("MinCP")

    local infoContainerControl = control:GetNamedChild("InfoPanelScrollChild")
    self.activitiesLabel = infoContainerControl:GetNamedChild("Activities")
    self.headerMessageLabel = infoContainerControl:GetNamedChild("HeaderMessage")
    self.recruitmentMessageLabel = infoContainerControl:GetNamedChild("RecruitmentMessage")

    self:InitializeKeybindDescriptors()
end

function ZO_GuildRecruitment_GuildListingInfo_Keyboard:InitializeKeybindDescriptors()
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

function ZO_GuildRecruitment_GuildListingInfo_Shared:UpdateAlert()
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

function ZO_GuildRecruitment_GuildListingInfo_Keyboard:OnShowing()
    ZO_GuildRecruitment_GuildListingInfo_Shared.OnShowing(self)
end

function ZO_GuildRecruitment_GuildListingInfo_Keyboard:OnHidden()
    ZO_GuildRecruitment_GuildListingInfo_Shared.OnHidden(self)
end

function ZO_GuildRecruitment_GuildListingInfo_Keyboard:ShowCategory()
    ZO_GuildRecruitment_GuildListingInfo_Shared.ShowCategory(self)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRecruitment_GuildListingInfo_Keyboard:HideCategory()
    ZO_GuildRecruitment_GuildListingInfo_Shared.HideCategory(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

-- Overridden
function ZO_GuildRecruitment_GuildListingInfo_Keyboard:RefreshInfoPanel()
    ZO_GuildRecruitment_GuildListingInfo_Shared.RefreshInfoPanel(self)

    local currentData = self.currentData
    if currentData then
        ZO_GuildFinder_Manager.SetTextForMetaDataAttributeKeyboard(self.recruitmentStatusLabel, GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_STATUS, "SI_GUILDRECRUITMENTSTATUSATTRIBUTEVALUE", currentData.recruitmentStatus)

        if currentData.recruitmentStatus == GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_LISTED then
            ZO_GuildFinder_Manager.SetTextForMetaDataAttributeKeyboard(self.primaryFocusLabel, GUILD_META_DATA_ATTRIBUTE_PRIMARY_FOCUS, "SI_GUILDFOCUSATTRIBUTEVALUE", currentData.primaryFocus)
            ZO_GuildFinder_Manager.SetTextForMetaDataAttributeKeyboard(self.secondaryFocusLabel, GUILD_META_DATA_ATTRIBUTE_SECONDARY_FOCUS, "SI_GUILDFOCUSATTRIBUTEVALUE", currentData.secondaryFocus)
            ZO_GuildFinder_Manager.SetTextForMetaDataAttributeKeyboard(self.personalitiesLabel, GUILD_META_DATA_ATTRIBUTE_PERSONALITIES, "SI_GUILDPERSONALITYATTRIBUTEVALUE", currentData.personality)
            ZO_GuildFinder_Manager.SetTextForMetaDataAttributeKeyboard(self.languagesLabel, GUILD_META_DATA_ATTRIBUTE_LANGUAGES, "SI_GUILDLANGUAGEATTRIBUTEVALUE", currentData.language)

            local rolesText = ZO_GuildFinder_Manager.GetRoleIconsText(currentData.roles)
            ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.rolesLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES)), rolesText)
            ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.minCPLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP)), currentData.minimumCP)

            local formattedTimeRange = ZO_GuildFinder_Manager.CreatePlaytimeRangeText(currentData)
            ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.playtimeLabel, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString(SI_GUILD_FINDER_GUILD_INFO_PLAYTIME_HEADER)), formattedTimeRange)

            ZO_GuildFinder_Manager.SetTextForNoGrammarValuePairKeyboard(self.headerMessageLabel, ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_HEADER_MESSAGE))), EscapeMarkup(currentData.recruitmentHeadline, ALLOW_MARKUP_TYPE_COLOR_ONLY))
            ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.activitiesLabel,  ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ACTIVITIES))), currentData.activitiesText)
            ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(self.recruitmentMessageLabel,  ZO_NORMAL_TEXT:Colorize(zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_MESSAGE))), currentData.description)

            self.primaryFocusLabel:SetHidden(false)
            self.secondaryFocusLabel:SetHidden(false)
            self.personalitiesLabel:SetHidden(false)
            self.languagesLabel:SetHidden(false)
            self.rolesLabel:SetHidden(false)
            self.minCPLabel:SetHidden(false)
            self.playtimeLabel:SetHidden(false)
            self.infoPanel:SetHidden(false)
        else
            self.primaryFocusLabel:SetHidden(true)
            self.secondaryFocusLabel:SetHidden(true)
            self.personalitiesLabel:SetHidden(true)
            self.languagesLabel:SetHidden(true)
            self.rolesLabel:SetHidden(true)
            self.minCPLabel:SetHidden(true)
            self.playtimeLabel:SetHidden(true)
            self.infoPanel:SetHidden(true)
        end
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

-- XML functions
----------------

function ZO_GuildRecruitment_GuildListingInfo_Keyboard_OnInitialized(control)
    GUILD_RECRUITMENT_GUILD_LISTING_INFO_KEYBOARD = ZO_GuildRecruitment_GuildListingInfo_Keyboard:New(control)
end