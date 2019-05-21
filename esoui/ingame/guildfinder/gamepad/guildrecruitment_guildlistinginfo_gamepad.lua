------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_GUILD_INFO_ATTRIBUTE_OFFSET_X = 20
ZO_GUILD_RECRUITMENT_GUILD_INFO_ATTRIBUTE_OFFSET_Y = 20

ZO_GuildRecruitment_GuildListingInfo_Gamepad = ZO_Object.MultiSubclass(ZO_GuildRecruitment_GuildListingInfo_Shared, ZO_GuildFinder_Panel_GamepadBehavior)

function ZO_GuildRecruitment_GuildListingInfo_Gamepad:New(...)
    return ZO_GuildFinder_Panel_GamepadBehavior.New(self, ...)
end

function ZO_GuildRecruitment_GuildListingInfo_Gamepad:Initialize(control)
    ZO_GuildRecruitment_GuildListingInfo_Shared.Initialize(self, control)
    ZO_GuildFinder_Panel_GamepadBehavior.Initialize(self, control)

    self.infoPanel = control:GetNamedChild("InfoPanel")
    self.topSection = self.infoPanel:GetNamedChild("TopSection")
    self.scrollContainer = self.infoPanel:GetNamedChild("ScrollContainer")
    self.scrollChild = self.scrollContainer:GetNamedChild("ScrollChild")

    self.recruitmentStatusLabelPair = self.topSection:GetNamedChild("Status")
    self.recruitmentStatusLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_RECRUITMENT_STATUS))
    self.primaryFocusLabelPair = self.topSection:GetNamedChild("PrimaryFocus")
    self.primaryFocusLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PRIMARY_FOCUS))
    self.secondaryFocusLabelPair = self.topSection:GetNamedChild("SecondaryFocus")
    self.secondaryFocusLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SECONDARY_FOCUS))
    self.playtimeLabelPair = self.topSection:GetNamedChild("Playtime")
    self.playtimeLabelPair.header:SetText(GetString(SI_GUILD_FINDER_GUILD_INFO_PLAYTIME_HEADER))
    self.personalitiesLabelPair = self.topSection:GetNamedChild("Personalities")
    self.personalitiesLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_PERSONALITIES))
    self.languagesLabelPair = self.topSection:GetNamedChild("Languages")
    self.languagesLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_LANGUAGES))
    self.rolesLabelPair = self.topSection:GetNamedChild("Roles")
    self.rolesLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ROLES))
    self.minCPLabelPair = self.topSection:GetNamedChild("MinCP")
    self.minCPLabelPair.header:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_MINIMUM_CP))

    self.activitiesLabel = self.scrollChild:GetNamedChild("Activities")
    self.headerMessageLabel = self.scrollChild:GetNamedChild("HeaderMessage")
    self.recruitmentMessageLabel = self.scrollChild:GetNamedChild("RecruitmentMessage")
    local activitiesHeader = self.scrollChild:GetNamedChild("ActivitiesHeader")
    activitiesHeader:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ACTIVITIES))
end

function ZO_GuildRecruitment_GuildListingInfo_Gamepad:UpdateAlert(previousData, selectedData)
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

function ZO_GuildRecruitment_GuildListingInfo_Gamepad:OnShowing()
    ZO_GuildRecruitment_GuildListingInfo_Shared.OnShowing(self)
end

function ZO_GuildRecruitment_GuildListingInfo_Gamepad:OnHidden()
    ZO_GuildRecruitment_GuildListingInfo_Shared.OnHidden(self)

    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_GuildRecruitment_GuildListingInfo_Gamepad:Activate()
    ZO_GuildFinder_Panel_GamepadBehavior.Activate(self)
end

function ZO_GuildRecruitment_GuildListingInfo_Gamepad:Deactivate()
    ZO_GuildFinder_Panel_GamepadBehavior.Deactivate(self)
end

-- Overridden
function ZO_GuildRecruitment_GuildListingInfo_Gamepad:CanBeActivated()
    return false
end

-- Overridden
function ZO_GuildRecruitment_GuildListingInfo_Gamepad:RefreshInfoPanel()
    local currentData = self.currentData
    if currentData then
        self.recruitmentStatusLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDRECRUITMENTSTATUSATTRIBUTEVALUE", currentData.recruitmentStatus)))

        if currentData.recruitmentStatus == GUILD_RECRUITMENT_STATUS_ATTRIBUTE_VALUE_LISTED then
            self.primaryFocusLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDFOCUSATTRIBUTEVALUE", currentData.primaryFocus)))
            self.secondaryFocusLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDFOCUSATTRIBUTEVALUE", currentData.secondaryFocus)))
            self.playtimeLabelPair.value:SetText(ZO_GuildFinder_Manager.CreatePlaytimeRangeText(currentData))
            self.personalitiesLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDPERSONALITYATTRIBUTEVALUE", currentData.personality)))
            self.languagesLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, GetString("SI_GUILDLANGUAGEATTRIBUTEVALUE", currentData.language)))

            local rolesText = ZO_GuildFinder_Manager.GetRoleIconsText(currentData.roles)
            self.rolesLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, rolesText))
            self.minCPLabelPair.value:SetText(zo_strformat(SI_GAMEPAD_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, currentData.minimumCP))

            self.headerMessageLabel:SetText(EscapeMarkup(currentData.recruitmentHeadline, ALLOW_MARKUP_TYPE_COLOR_ONLY))
            self.activitiesLabel:SetText(currentData.activitiesText)
            self.recruitmentMessageLabel:SetText(currentData.description)

            self.primaryFocusLabelPair:SetHidden(false)
            self.secondaryFocusLabelPair:SetHidden(false)
            self.playtimeLabelPair:SetHidden(false)
            self.personalitiesLabelPair:SetHidden(false)
            self.languagesLabelPair:SetHidden(false)
            self.rolesLabelPair:SetHidden(false)
            self.minCPLabelPair:SetHidden(false)
            self.scrollContainer:SetHidden(false)
        else
            self.primaryFocusLabelPair:SetHidden(true)
            self.secondaryFocusLabelPair:SetHidden(true)
            self.playtimeLabelPair:SetHidden(true)
            self.personalitiesLabelPair:SetHidden(true)
            self.languagesLabelPair:SetHidden(true)
            self.rolesLabelPair:SetHidden(true)
            self.minCPLabelPair:SetHidden(true)
            self.scrollContainer:SetHidden(true)
        end
    end
end

-- XML functions
----------------

function ZO_GuildRecruitment_GuildListingInfo_Gamepad_OnInitialized(control)
    GUILD_RECRUITMENT_GUILD_LISTING_INFO_GAMEPAD = ZO_GuildRecruitment_GuildListingInfo_Gamepad:New(control)
end