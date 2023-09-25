function ZO_Tooltip:LayoutZoneStoryActivityCompletion(zoneData, completionType)
    local headerSection = self:AcquireSection(self:GetStyle("topSection"))
    headerSection:AddLine(GetString("SI_ZONECOMPLETIONTYPE", completionType), self:GetStyle("title"))
    headerSection:AddLine(zoneData.name)
    self:AddSection(headerSection)

    local statValuePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    statValuePair:SetStat(GetString("SI_ZONECOMPLETIONTYPE_PROGRESSHEADER", completionType), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(ZO_ZoneStories_Manager.GetActivityCompletionProgressText(zoneData.id, completionType), self:GetStyle("statValuePairValue"))
    self:AddStatValuePair(statValuePair)

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(GetString("SI_ZONECOMPLETIONTYPE_DESCRIPTION", completionType), self:GetStyle("flavorText"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutZoneStoryActivityCompletionTypeList(zoneData, completionType)
    -- Title
    local titleTextSection = self:AcquireSection(self:GetStyle("topSection"))
    titleTextSection:AddLine(zo_strformat(SI_ZONE_STORY_LIST_TOOLTIP_TITLE_FORMATTER, zoneData.name, GetString("SI_ZONECOMPLETIONTYPE", completionType)), self:GetStyle("title"))
    self:AddSection(titleTextSection)

    -- Checkboxes
    local numUnblockedActivities, blockingBranchErrorStringId = select(3, ZO_ZoneStories_Manager.GetActivityCompletionProgressValues(zoneData.id, completionType))
    local activityListSection = self:AcquireSection(self:GetStyle("achievementCriteriaSection"))

    for i = 1, numUnblockedActivities do
        local name = GetZoneStoryActivityNameByActivityIndex(zoneData.id, completionType, i)
        local isComplete = IsZoneStoryActivityComplete(zoneData.id, completionType, i)
        activityListSection:AddSection(self:GetCheckboxSection(zo_strformat(SI_ZONE_STORY_LIST_TOOLTIP_ACTIVITY_NAME_FORMATTER, name), isComplete))
    end

    self:AddSection(activityListSection)

    if blockingBranchErrorStringId ~= 0 then
        local blockingBranchRequirementSection = self:AcquireSection(self:GetStyle("bodySection"))
        local errorStringText = GetErrorString(blockingBranchErrorStringId)
        blockingBranchRequirementSection:AddLine(errorStringText, self:GetStyle("flavorText"))
        self:AddSection(blockingBranchRequirementSection)
    end
end

function ZO_Tooltip:LayoutGroupFinderGroupListingTooltip(data)
    local title = data:GetTitle()
    local category = data:GetCategory()
    local ROLE_ICON_DIMENSION = 64
    local playerCountString, roleListString, roleListNarrations = ZO_GroupFinder_GroupListing_GetPlayerCountAndRoleStrings(data, ROLE_ICON_DIMENSION)

    -- Applied/DLC Required indicator
    local indicatorIcon = data:GetStatusIndicatorIcon()
    local indicatorText = data:GetStatusIndicatorText()
    if indicatorIcon and indicatorText then
        local indicatorSection = self:AcquireSection(self:GetStyle("topSection"))
        indicatorSection:AddLine(indicatorText)
        indicatorSection:AddTexture(indicatorIcon, self:GetStyle("groupFinderStatusIndicator"))
        self:AddSection(indicatorSection)
    end

    -- Title
    local titleTextSection = self:AcquireSection(self:GetStyle("title"))
    titleTextSection:AddLine(EscapeMarkup(title, ALLOW_MARKUP_TYPE_COLOR_ONLY))
    self:AddSection(titleTextSection)

    local ownerSection = self:AcquireSection(self:GetStyle("bodySection"))
    local displayName = data:GetOwnerDisplayName()
    local characterName = data:GetOwnerCharacterName()
    ownerSection:AddLine(GetString(SI_GROUP_FINDER_TOOLTIP_LISTING_OWNER_LABEL), self:GetStyle("bodyHeader"))
    ownerSection:AddLine(ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName), self:GetStyle("bodyDescription"))
    self:AddSection(ownerSection)

    -- Category/location
    local categorySection = self:AcquireSection(self:GetStyle("bodySection"))
    categorySection:AddLine(GetString("SI_GROUPFINDERCATEGORY", category), self:GetStyle("bodyHeader"))
    if category ~= GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON and category ~= GROUP_FINDER_CATEGORY_CUSTOM then
        local firstText = category == GROUP_FINDER_CATEGORY_PVP and data:GetPrimaryOptionText() or data:GetSecondaryOptionText()
        local secondText = category == GROUP_FINDER_CATEGORY_PVP and data:GetSecondaryOptionText() or data:GetPrimaryOptionText()
        local optionsString = ZO_GenerateCommaSeparatedListWithoutAnd({ firstText, secondText})
        categorySection:AddLine(optionsString, self:GetStyle("bodyDescription"))
    end
    self:AddSection(categorySection)

    -- Role list
    local roleList = self:AcquireSection(self:GetStyle("bodySection"))
    roleList:AddLineWithCustomNarration(roleListString, roleListNarrations, self:GetStyle("bodyDescription"))

    -- Player count
    local playerCount = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    playerCount:SetStat(GetString(SI_GROUP_FINDER_TOOLTIP_PLAYER_LABEL), self:GetStyle("statValuePairStat"))
    playerCount:SetValue(playerCountString, self:GetStyle("statValuePairValue"))
    self:AddStatValuePair(playerCount)
    self:AddSection(roleList)

    -- Description
    local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    descriptionSection:AddLine(GetString(SI_GROUP_FINDER_TOOLTIP_DESCRIPTION_HEADER), self:GetStyle("bodyHeader"))
    descriptionSection:AddLine(EscapeMarkup(data:GetDescription(), ALLOW_MARKUP_TYPE_COLOR_ONLY), self:GetStyle("bodyDescription"))
    self:AddSection(descriptionSection)

    -- Flags
    local requirementTextYes = GetString(SI_DIALOG_YES)
    local requirementTextNo = GetString(SI_DIALOG_NO)

    local flagsSection = self:AcquireSection(self:GetStyle("bodySection"))

    local championPair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    championPair:SetStat(zo_strformat(SI_GROUP_FINDER_CHAMPION_REQUIRED_TEXT, ZO_GetChampionIconMarkupString(ZO_GROUP_LISTING_CHAMPION_ICON_SIZE)), self:GetStyle("statValuePairStat"))
    local championRequirement = data:GetChampionPoints()
    if not data:DoesGroupRequireChampion() then
        championRequirement = GetString(SI_GROUP_FINDER_TOOLTIP_CHAMPION_NOT_APPLICABLE)
    end
    championPair:SetValue(championRequirement, self:GetStyle("statValuePairValue"))
    flagsSection:AddStatValuePair(championPair)

    local inviteCodePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    local requiresInviteCodeText = data:DoesGroupRequireInviteCode() and requirementTextYes or requirementTextNo
    inviteCodePair:SetStat(GetString(SI_GROUP_FINDER_TOOLTIP_INVITE_CODE_LABEL), self:GetStyle("statValuePairStat"))
    inviteCodePair:SetValue(requiresInviteCodeText, self:GetStyle("statValuePairValue"))
    flagsSection:AddStatValuePair(inviteCodePair)

    if category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_ARENA or category == GROUP_FINDER_CATEGORY_TRIAL then
        local playstylePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
        playstylePair:SetStat(GetString(SI_GROUP_FINDER_TOOLTIP_PLAYSTYLE_LABEL), self:GetStyle("statValuePairStat"))
        playstylePair:SetValue(GetString("SI_GROUPFINDERPLAYSTYLE", data:GetPlaystyle()), self:GetStyle("statValuePairValue"))
        flagsSection:AddStatValuePair(playstylePair)
    end

    local autoAcceptPair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    local autoAcceptsRequestsText = data:DoesGroupAutoAcceptRequests() and requirementTextYes or requirementTextNo
    autoAcceptPair:SetStat(GetString(SI_GROUP_FINDER_TOOLTIP_AUTO_ACCEPT_LABEL), self:GetStyle("statValuePairStat"))
    autoAcceptPair:SetValue(autoAcceptsRequestsText, self:GetStyle("statValuePairValue"))
    flagsSection:AddStatValuePair(autoAcceptPair)

    local VOIPPair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    local requiresVOIPText = data:DoesGroupRequireVOIP() and requirementTextYes or requirementTextNo
    VOIPPair:SetStat(GetString(SI_GROUP_FINDER_TOOLTIP_VOIP_LABEL), self:GetStyle("statValuePairStat"))
    VOIPPair:SetValue(requiresVOIPText, self:GetStyle("statValuePairValue"))
    flagsSection:AddStatValuePair(VOIPPair)

    local lookingForPair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
    local lookingForText, lookingForNarrations = ZO_GroupFinder_GroupListing_GetDesiredRolesList(data, ROLE_ICON_DIMENSION)
    lookingForPair:SetStat(GetString(SI_GROUP_FINDER_TOOLTIP_LOOKING_FOR_LABEL), self:GetStyle("statValuePairStat"))
    lookingForPair:SetValueWithCustomNarration(lookingForText, lookingForNarrations, self:GetStyle("statValuePairValue"))
    flagsSection:AddStatValuePair(lookingForPair)

    self:AddSection(flagsSection)

    local warningText = data:GetWarningText()
    if warningText then
        local warningSection = self:AcquireSection(self:GetStyle("bodySection"))
        warningSection:AddLine(warningText, self:GetStyle("bodyDescription"), self:GetStyle("failed"))
        self:AddSection(warningSection)
    end
end

function ZO_Tooltip:LayoutGroupFinderApplicationDetails(applicationData)
    local displayName = applicationData:GetDisplayName()
    local characterName = applicationData:GetCharacterName()
    local primaryName = ZO_GetPrimaryPlayerName(displayName, characterName)
    local secondaryName = ZO_GetSecondaryPlayerName(displayName, characterName)
    
    -- Primary Name Header
    local headerSection = self:AcquireSection(self:GetStyle("socialTitle"))
    headerSection:AddLine(primaryName)
    self:AddSection(headerSection)

    -- Secondary Name
    local characterSection = self:AcquireSection(self:GetStyle("characterNameSection"))
    characterSection:AddLine(secondaryName, self:GetStyle("socialStatsValue"))
    self:AddSection(characterSection)

    local statsSection = self:AcquireSection(self:GetStyle("socialStatsSection"))

    -- Player Level
    local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    statValuePair:SetStat(GetString(SI_GAMEPAD_GROUP_FINDER_APPLICATION_LIST_HEADER_LEVEL), self:GetStyle("statValuePairStat"))
    local level = applicationData:GetLevel()
    local championPoints = applicationData:GetChampionPoints()
    local ICON_SIZE = 40
    local levelText = ZO_GetLevelOrChampionPointsString(level, championPoints, ICON_SIZE)
    local levelNarrationText = ZO_GetLevelOrChampionPointsNarrationString(level, championPoints)
    statValuePair:SetValueWithCustomNarration(levelText, levelNarrationText, self:GetStyle("socialStatsValue"))
    statsSection:AddStatValuePair(statValuePair)

    -- Player Class
    statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    statValuePair:SetStat(GetString(SI_GROUP_LIST_PANEL_CLASS_HEADER), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(applicationData:GetClassName(), self:GetStyle("socialStatsValue"))
    statsSection:AddStatValuePair(statValuePair)

    -- Player Role
    statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    statValuePair:SetStat(GetString(SI_GROUP_LIST_PANEL_ROLES_HEADER), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(GetString("SI_LFGROLE", applicationData:GetRole()), self:GetStyle("socialStatsValue"))
    statsSection:AddStatValuePair(statValuePair)

    self:AddSection(statsSection)

    -- Optional Message
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(applicationData:GetNote(), self:GetStyle("flavorText"))
    self:AddSection(bodySection)
end


function ZO_Tooltip:LayoutReportGroupFinderListingInfo(title, description, ownerDisplayName, ownerCharacterName)
    self:AddLine(GetString(SI_CUSTOMER_SERVICE_ASK_FOR_HELP_GROUP_FINDER_LISTING_DETAILS), self:GetStyle("title"))

    local ownerSection = self:AcquireSection(self:GetStyle("bodySection"))
    ownerSection:AddLine(GetString(SI_GROUP_FINDER_TOOLTIP_LISTING_OWNER_LABEL), self:GetStyle("bodyHeader"))
    ownerSection:AddLine(ZO_GetPrimaryPlayerNameWithSecondary(ownerDisplayName, ownerCharacterName), self:GetStyle("bodyDescription"))
    self:AddSection(ownerSection)

    local titleSection = self:AcquireSection(self:GetStyle("bodySection"))
    titleSection:AddLine(GetString(SI_GROUP_FINDER_TOOLTIP_TITLE_HEADER), self:GetStyle("bodyHeader"))
    titleSection:AddLine(EscapeMarkup(title, ALLOW_MARKUP_TYPE_COLOR_ONLY), self:GetStyle("bodyDescription"))
    self:AddSection(titleSection)

    local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
    descriptionSection:AddLine(GetString(SI_GROUP_FINDER_TOOLTIP_DESCRIPTION_HEADER), self:GetStyle("bodyHeader"))
    descriptionSection:AddLine(EscapeMarkup(description, ALLOW_MARKUP_TYPE_COLOR_ONLY), self:GetStyle("bodyDescription"))
    self:AddSection(descriptionSection)
end