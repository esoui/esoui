ZO_GROUP_LISTING_KEYBOARD_HEIGHT = 65
ZO_GROUP_LISTING_ROLE_CONTROL_PADDING = 5
ZO_GROUP_LISTING_TOOLTIP_FLAGS_PADDING = 8

--------------------------------------------------------------
-- ZO_GroupFinder_BasePanel_Keyboard
--------------------------------------------------------------

ZO_GroupFinder_BasePanel_Keyboard = ZO_InitializingObject:Subclass()

function ZO_GroupFinder_BasePanel_Keyboard:Initialize(control)
    self.control = control

    self.fragment = ZO_SimpleSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(...) self:OnStateChange(...) end)

    self:InitializeControls()
end

function ZO_GroupFinder_BasePanel_Keyboard:GetFragment()
    return self.fragment
end

function ZO_GroupFinder_BasePanel_Keyboard:OnStateChange(oldState, newState)
    if newState == SCENE_FRAGMENT_SHOWING then
        self:Show()
    elseif newState == SCENE_FRAGMENT_HIDDEN then
        self:Hide()
    end
end

function ZO_GroupFinder_BasePanel_Keyboard:InitializeControls()
    -- To be overridden
end

function ZO_GroupFinder_BasePanel_Keyboard:IsHidden()
    return self.control:IsHidden()
end

function ZO_GroupFinder_BasePanel_Keyboard:Show()
    SCENE_MANAGER:AddFragment(self.fragment)
end

function ZO_GroupFinder_BasePanel_Keyboard:Hide()
    SCENE_MANAGER:RemoveFragment(self.fragment)
end

----------------------------------------
-- Group Finder Group Listing Tooltip --
----------------------------------------

function ZO_GroupFinderGroupListingTooltip_Initialize(tooltipControl)
    tooltipControl.indicatorIcon = tooltipControl:GetNamedChild("IndicatorIcon")
    tooltipControl.indicatorLabel = tooltipControl:GetNamedChild("IndicatorLabel")

    tooltipControl.titleLabel = tooltipControl:GetNamedChild("Title")
    local ownerSection = tooltipControl:GetNamedChild("OwnerSection")
    tooltipControl.listingOwnerNameLabel = ownerSection:GetNamedChild("OwnerName")
    tooltipControl.categoryLabel = tooltipControl:GetNamedChild("Category")
    tooltipControl.descriptionLabel = tooltipControl:GetNamedChild("Description")
    tooltipControl.playerCountLabel = tooltipControl:GetNamedChild("PlayersSectionPlayerCount")
    tooltipControl.roleListLabel = tooltipControl:GetNamedChild("PlayersSectionRoleList")

    local flagsSection = tooltipControl:GetNamedChild("FlagsSection")
    tooltipControl.championLabel = flagsSection:GetNamedChild("Champion")
    tooltipControl.inviteCodeLabel = flagsSection:GetNamedChild("InviteCode")
    tooltipControl.playstyleLabel = flagsSection:GetNamedChild("Playstyle")
    tooltipControl.autoAcceptLabel = flagsSection:GetNamedChild("AutoAccept")
    tooltipControl.VOIPLabel = flagsSection:GetNamedChild("VOIP")
    tooltipControl.lookingForLabel = flagsSection:GetNamedChild("LookingFor")

    tooltipControl.warningLabel = tooltipControl:GetNamedChild("WarningLabel")
end

function ZO_GroupFinderGroupListingTooltip_SetGroupFinderListing(tooltipControl, data)
    tooltipControl.titleLabel:ClearAnchors()

    local indicatorIcon = data:GetStatusIndicatorIcon()
    local indicatorText = data:GetStatusIndicatorText()

    if indicatorIcon and indicatorText then
        tooltipControl.indicatorIcon:SetTexture(indicatorIcon)
        tooltipControl.indicatorLabel:SetText(indicatorText)
        tooltipControl.indicatorIcon:SetHidden(false)
        tooltipControl.indicatorLabel:SetHidden(false)
        tooltipControl.titleLabel:SetAnchor(TOP, nil, nil, 0, 0, ANCHOR_CONSTRAINS_X)
        tooltipControl.titleLabel:SetAnchor(TOP, tooltipControl.indicatorLabel, BOTTOM, 0, 5, ANCHOR_CONSTRAINS_Y)
    else
        tooltipControl.titleLabel:SetAnchor(TOP, nil, nil, 0, 20)
    end

    tooltipControl.titleLabel:SetText(EscapeMarkup(data:GetTitle(), ALLOW_MARKUP_TYPE_COLOR_ONLY))

    local category = data:GetCategory()
    local categoryString = GetString("SI_GROUPFINDERCATEGORY", category)

    if category ~= GROUP_FINDER_CATEGORY_ENDLESS_DUNGEON and category ~= GROUP_FINDER_CATEGORY_CUSTOM then
        local firstText = category == GROUP_FINDER_CATEGORY_PVP and data:GetPrimaryOptionText() or data:GetSecondaryOptionText()
        local secondText = category == GROUP_FINDER_CATEGORY_PVP and data:GetSecondaryOptionText() or data:GetPrimaryOptionText()
        local optionsString = ZO_SELECTED_TEXT:Colorize(ZO_GenerateCommaSeparatedListWithoutAnd({ firstText, secondText }))
        tooltipControl.categoryLabel:SetText(ZO_GenerateSpaceSeparatedList({categoryString, optionsString}))
    else
        tooltipControl.categoryLabel:SetText(categoryString)
    end

    local displayName = data:GetOwnerDisplayName()
    local characterName = data:GetOwnerCharacterName()
    tooltipControl.listingOwnerNameLabel:SetText(ZO_GetPrimaryPlayerNameWithSecondary(displayName, characterName))

    local ROLE_ICON_DIMENSION = 32
    local playerCountString, roleListString = ZO_GroupFinder_GroupListing_GetPlayerCountAndRoleStrings(data, ROLE_ICON_DIMENSION)
    tooltipControl.playerCountLabel:SetText(playerCountString)
    tooltipControl.roleListLabel:SetText(roleListString)

    tooltipControl.descriptionLabel:SetText(EscapeMarkup(data:GetDescription(), ALLOW_MARKUP_TYPE_COLOR_ONLY))

    local requirementTextYes = GetString(SI_DIALOG_YES)
    local requirementTextNo = GetString(SI_DIALOG_NO)

    local flagLabels = {}

    local championRequirement = data:GetChampionPoints()
    if not data:DoesGroupRequireChampion() then
        championRequirement = GetString(SI_GROUP_FINDER_TOOLTIP_CHAMPION_NOT_APPLICABLE)
    end
    local championText = zo_strformat(SI_GROUP_FINDER_TOOLTIP_FLAGS_FORMATTER, zo_strformat(SI_GROUP_FINDER_CHAMPION_REQUIRED_TEXT, ZO_GetChampionIconMarkupString(ZO_GROUP_LISTING_CHAMPION_ICON_SIZE)), ZO_SELECTED_TEXT:Colorize(championRequirement))
    tooltipControl.championLabel:SetText(championText)
    table.insert(flagLabels, tooltipControl.championLabel)

    local requiresInviteCodeText = data:DoesGroupRequireInviteCode() and requirementTextYes or requirementTextNo
    local inviteCodeText = zo_strformat(SI_GROUP_FINDER_TOOLTIP_FLAGS_FORMATTER, GetString(SI_GROUP_FINDER_TOOLTIP_INVITE_CODE_LABEL), ZO_SELECTED_TEXT:Colorize(requiresInviteCodeText))
    tooltipControl.inviteCodeLabel:SetText(inviteCodeText)
    table.insert(flagLabels, tooltipControl.inviteCodeLabel)

    if category == GROUP_FINDER_CATEGORY_DUNGEON or category == GROUP_FINDER_CATEGORY_ARENA or category == GROUP_FINDER_CATEGORY_TRIAL then
        local playstyleText = zo_strformat(SI_GROUP_FINDER_TOOLTIP_FLAGS_FORMATTER, GetString(SI_GROUP_FINDER_TOOLTIP_PLAYSTYLE_LABEL), ZO_SELECTED_TEXT:Colorize(GetString("SI_GROUPFINDERPLAYSTYLE", data:GetPlaystyle())))
        tooltipControl.playstyleLabel:SetText(playstyleText)
        table.insert(flagLabels, tooltipControl.playstyleLabel)
    end

    local autoAcceptsRequestsText = data:DoesGroupAutoAcceptRequests() and requirementTextYes or requirementTextNo
    local autoAcceptText = zo_strformat(SI_GROUP_FINDER_TOOLTIP_FLAGS_FORMATTER, GetString(SI_GROUP_FINDER_TOOLTIP_AUTO_ACCEPT_LABEL), ZO_SELECTED_TEXT:Colorize(autoAcceptsRequestsText))
    tooltipControl.autoAcceptLabel:SetText(autoAcceptText)
    table.insert(flagLabels, tooltipControl.autoAcceptLabel)

    local requiresVOIPText = data:DoesGroupRequireVOIP() and requirementTextYes or requirementTextNo
    local VOIPText = zo_strformat(SI_GROUP_FINDER_TOOLTIP_FLAGS_FORMATTER, GetString(SI_GROUP_FINDER_TOOLTIP_VOIP_LABEL), ZO_SELECTED_TEXT:Colorize(requiresVOIPText))
    tooltipControl.VOIPLabel:SetText(VOIPText)
    table.insert(flagLabels, tooltipControl.VOIPLabel)

    local desiredRolesList = ZO_GroupFinder_GroupListing_GetDesiredRolesList(data, ROLE_ICON_DIMENSION)
    local lookingForText = zo_strformat(SI_GROUP_FINDER_TOOLTIP_FLAGS_FORMATTER, GetString(SI_GROUP_FINDER_TOOLTIP_LOOKING_FOR_LABEL), desiredRolesList)
    tooltipControl.lookingForLabel:SetText(lookingForText)
    table.insert(flagLabels, tooltipControl.lookingForLabel)

    for index, flagLabel in ipairs(flagLabels) do
        if index == 1 then
            flagLabel:SetAnchor(TOPLEFT)
        elseif index == 2 then
            flagLabel:SetAnchor(TOPRIGHT)
        elseif index % 2 == 1 then
            flagLabel:SetAnchor(TOPLEFT, flagLabels[index - 2], BOTTOMLEFT, 0, ZO_GROUP_LISTING_TOOLTIP_FLAGS_PADDING)
        else
            flagLabel:SetAnchor(TOPRIGHT, flagLabels[index - 2], BOTTOMRIGHT, 0, ZO_GROUP_LISTING_TOOLTIP_FLAGS_PADDING)
        end
        flagLabel:SetHidden(false)
    end

    local warningText = data:GetWarningText()
    if warningText then
        tooltipControl.warningLabel:SetText(warningText)
        tooltipControl.warningLabel:SetHidden(false)
    end
end

function ZO_GroupFinderGroupListingTooltip_Clear(tooltipControl)
    tooltipControl.indicatorIcon:SetTexture("")
    tooltipControl.indicatorIcon:SetHidden(true)
    tooltipControl.indicatorLabel:SetText("")
    tooltipControl.indicatorLabel:SetHidden(true)
    tooltipControl.titleLabel:SetText("")
    tooltipControl.listingOwnerNameLabel:SetText("")
    tooltipControl.categoryLabel:SetText("")
    tooltipControl.playerCountLabel:SetText("")
    tooltipControl.roleListLabel:SetText("")
    tooltipControl.descriptionLabel:SetText("")
    tooltipControl.championLabel:SetText("")
    tooltipControl.championLabel:SetHidden(true)
    tooltipControl.championLabel:ClearAnchors()
    tooltipControl.inviteCodeLabel:SetText("")
    tooltipControl.inviteCodeLabel:SetHidden(true)
    tooltipControl.inviteCodeLabel:ClearAnchors()
    tooltipControl.playstyleLabel:SetText("")
    tooltipControl.playstyleLabel:SetHidden(true)
    tooltipControl.playstyleLabel:ClearAnchors()
    tooltipControl.autoAcceptLabel:SetText("")
    tooltipControl.autoAcceptLabel:SetHidden(true)
    tooltipControl.autoAcceptLabel:ClearAnchors()
    tooltipControl.VOIPLabel:SetText("")
    tooltipControl.VOIPLabel:SetHidden(true)
    tooltipControl.VOIPLabel:ClearAnchors()
    tooltipControl.lookingForLabel:SetText("")
    tooltipControl.lookingForLabel:SetHidden(true)
    tooltipControl.lookingForLabel:ClearAnchors()
    tooltipControl.warningLabel:SetText("")
    tooltipControl.warningLabel:SetHidden(true)
end