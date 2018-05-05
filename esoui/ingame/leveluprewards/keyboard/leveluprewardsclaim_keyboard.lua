local REWARD_LIST_ENTRY = 1
local REWARD_LIST_ENTRY_HEADER = 2

ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_REWARD_ROW_HEIGHT = 64
ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_POINT_ROW_HEIGHT = 32
ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_HEADER_ROW_HEIGHT = 26
ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_ART_HEIGHT = 140
ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_GROUPING_SPACING = 15

--the time that only the fanfare is playing
ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_FANFARE_EXCLUSIVE_DURATION_MS = 400
ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_FANFARE_FULL_DURATION_MS = 2000
ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_ROW_ANIMATION_DURATION_MS = 350
ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_ROW_ANIMATION_OFFSET_MS = 300
ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_BUTTON_ANIMATION_DURATION_MS = 250

--The static part of the window (title, header, claim button)
local WINDOW_HEIGHT_WITHOUT_DYNAMIC_CONTROLS = 264

ZO_LevelUpRewardsClaim_Keyboard = ZO_LevelUpRewardsClaim_Base:Subclass()

function ZO_LevelUpRewardsClaim_Keyboard:New(...)
    return ZO_LevelUpRewardsClaim_Base.New(self, ...)
end

function ZO_LevelUpRewardsClaim_Keyboard:Initialize(control)
    ZO_LevelUpRewardsClaim_Base.Initialize(self)
    self.control = control
    ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS_FRAGMENT:RegisterCallback("StateChange",
                                                function(oldState, newState)
                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                        self:OnShowing()
                                                    elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                        self:OnHidden()
                                                    end
                                                end)

    self.titleControl = control:GetNamedChild("Title")

    self.rewardList = control:GetNamedChild("List")
    self.rewardListScrollChild =  self.rewardList:GetNamedChild("ScrollChild")
    self.artTileControl = self.rewardListScrollChild:GetNamedChild("ArtTile")
    self.artTexture = self.artTileControl:GetNamedChild("Art")
    self.claimButton = control:GetNamedChild("ClaimButton")

    self.layout = ZO_LevelUpRewardsLayout_Keyboard:New()

    self.rewardPool = ZO_ControlPool:New("ZO_LevelUpRewards_RewardRow", self.rewardListScrollChild)
    self.choiceRewardPool = ZO_ControlPool:New("ZO_LevelUpRewards_ChoiceRewardRow", self.rewardListScrollChild)
    self.pointRewardPool = ZO_ControlPool:New("ZO_LevelUpRewards_PointRow", self.rewardListScrollChild)
    self.rewardHeaderPool = ZO_ControlPool:New("ZO_LevelUpRewards_RewardRowHeader", self.rewardListScrollChild)
    self.selectionHighlightPool = ZO_ControlPool:New("ZO_ListEntryHighlight", self.rewardListScrollChild)
    self.tipPool = ZO_ControlPool:New("ZO_LevelUpRewards_Tip", self.rewardListScrollChild)
    self.claimRowAnimationPool = ZO_AnimationPool:New("ZO_LevelUpRewardsClaimRowAnimation")

    self.claimButtonAnimationTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_LevelUpRewardsClaimButtonAnimation", self.claimButton)
    self.claimButtonAnimationTimeline:GetFirstAnimation():SetHandler("OnPlay", function() PlaySound(SOUNDS.LEVEL_UP_REWARD_CLAIM_APPEAR) end)
    --When claim is shown we turn down the particles a bit
    self.claimButtonAnimationTimeline:SetHandler("OnStop", function(_, completedPlaying)
        if completedPlaying then
            self.claimParticleSystem:SetParticlesPerSecond(5)
        end
    end)

    local claimParticleSystem = ZO_LEVEL_UP_REWARDS_MANAGER:CreateArtAreaParticleSystem(self.artTexture)
    self.claimParticleSystem = claimParticleSystem

    local function UpdateLevelUpRewards()
        if self:IsShowing() then
            if HasPendingLevelUpReward() then
                self:ShowLevelUpRewards()
            end
        end
    end
    ZO_LEVEL_UP_REWARDS_MANAGER:RegisterCallback("OnLevelUpRewardsUpdated", UpdateLevelUpRewards)

    SYSTEMS:RegisterKeyboardObject("LevelUpRewardsClaim", self)
end

function ZO_LevelUpRewardsClaim_Keyboard:SetupRewardRow(rowControl, data)
    local name = ZO_LEVEL_UP_REWARDS_MANAGER:GetPendingRewardNameFromRewardData(data)
    rowControl.nameControl:SetText(name)
    local rewardType = data:GetRewardType()
    if rewardType then
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data:GetItemQuality())
        rowControl.nameControl:SetColor(r, g, b, 1)
    else
        local r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
        rowControl.nameControl:SetColor(r, g, b, 1)
    end

    local icon = data:GetKeyboardIcon()
    if icon then
        rowControl.iconControl:SetTexture(icon)
    end
    rowControl.iconControl:SetHidden(icon == nil)

    rowControl.data = data

    if rowControl.stackCountControl then
        local stackCount = data:GetQuantity()
        if data.rewardType and data.rewardType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
            stackCount = 1 -- not showing stack count for currency
        end
        if stackCount and stackCount > 1 then
            local USE_LOWERCASE_NUMBER_SUFFIXES = false
            local formattedCount = zo_strformat(SI_NUMBER_FORMAT, ZO_AbbreviateNumber(stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
            rowControl.stackCountControl:SetText(formattedCount)
            rowControl.stackCountControl:SetHidden(false)
        else
            rowControl.stackCountControl:SetHidden(true)
        end
    end

    if data.isSelectedChoice then
        local selectionHightlightControl = self.selectionHighlightPool:AcquireObject()
        selectionHightlightControl:SetAlpha(1)
        selectionHightlightControl:SetAnchorFill(rowControl)
        selectionHightlightControl:SetParent(rowControl)
    end
end

function ZO_LevelUpRewardsClaim_Keyboard:SetupRewardHeader(rewardHeaderControl, headerName)
    local headerString = headerName or ""
    rewardHeaderControl.nameControl:SetText(headerString)
end

function ZO_LevelUpRewardsClaim_Keyboard:OnShowing()
    self:ShowLevelUpRewards()
    CENTER_SCREEN_ANNOUNCE:SupressAnnouncementByType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_POINTS_GAINED)
end

function ZO_LevelUpRewardsClaim_Keyboard:OnHidden()
    self.claimRowAnimationPool:ReleaseAllObjects()
    self.claimParticleSystem:Stop()
    self.claimButtonAnimationTimeline:Stop()
    CENTER_SCREEN_ANNOUNCE:ResumeAnnouncementByType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_POINTS_GAINED)
end

function ZO_LevelUpRewardsClaim_Keyboard:Show()
    if not self:IsShowing() then
        SCENE_MANAGER:AddFragment(ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS_FRAGMENT)
    end
end

function ZO_LevelUpRewardsClaim_Keyboard:Hide()
    if self:IsShowing() then
        SCENE_MANAGER:RemoveFragment(ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS_FRAGMENT)
    end
end

function ZO_LevelUpRewardsClaim_Keyboard:IsShowing()
    return ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS_FRAGMENT:IsShowing()
end

function ZO_LevelUpRewardsClaim_Keyboard:ShowLevelUpRewards()
    ZO_LevelUpRewardsClaim_Base.ShowLevelUpRewards(self)
    self:UpdateClaimButtonState()
end

function ZO_LevelUpRewardsClaim_Keyboard:UpdateHeader()
    local titleString = zo_strformat(SI_LEVEL_UP_REWARDS_HEADER, self.rewardLevel)
    self.titleControl:SetText(titleString)
end

function ZO_LevelUpRewardsClaim_Keyboard:PlayShowAnimations()
    self.claimParticleSystem:SetParticlesPerSecond(50)
    self.claimParticleSystem:Start()
    PlaySound(SOUNDS.LEVEL_UP_REWARD_FANFARE)

    local animationOffsetMS = ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_FANFARE_EXCLUSIVE_DURATION_MS

    for sectionIndex, sectionControls in ipairs(self.layout:GetRewardControlsBySection()) do
        for rewardIndex, rewardControl in ipairs(sectionControls) do
            rewardControl:SetAlpha(0)
            rewardControl:SetMouseEnabled(false)

            local animationTimeline = self.claimRowAnimationPool:AcquireObject()
            animationTimeline:ApplyAllAnimationsToControl(rewardControl)
            animationTimeline:SetAllAnimationOffsets(animationOffsetMS)

            if rewardIndex == 1 then
                local firstAnimation = animationTimeline:GetFirstAnimation()
                firstAnimation:SetHandler("OnPlay", function() PlaySound(SOUNDS.LEVEL_UP_REWARD_SECTION_APPEAR) end)
            end

            for animationIndex = 1, animationTimeline:GetNumAnimations() do
                local animation = animationTimeline:GetAnimation(animationIndex)
                animation:SetHandler("OnStop", function(_, animatingControl) animatingControl:SetMouseEnabled(true) end)
            end

            animationTimeline:PlayFromStart()
        end
        animationOffsetMS = animationOffsetMS + ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_ROW_ANIMATION_OFFSET_MS
    end

    self.claimButton:SetAlpha(0)
    self.claimButtonAnimationTimeline:SetAllAnimationOffsets(animationOffsetMS)
    self.claimButtonAnimationTimeline:PlayFromStart()
end

function ZO_LevelUpRewardsClaim_Keyboard:AddRewards(rewards)
    self.rewardPool:ReleaseAllObjects()
    self.choiceRewardPool:ReleaseAllObjects()
    self.pointRewardPool:ReleaseAllObjects()
    self.rewardHeaderPool:ReleaseAllObjects()
    self.selectionHighlightPool:ReleaseAllObjects()
    self.tipPool:ReleaseAllObjects()
    self.choiceRewardDataToControl = {}

    ZO_Scroll_ResetToTop(self.rewardList)
    self.layout:ResetAnchoring(self.artTileControl)

    ZO_LevelUpRewardsArtTile_SetupTileForLevel(self.artTileControl, self.rewardLevel)

    local overviewText = GetKeyboardLevelUpTipOverview(self.rewardLevel)
    local descriptionText = GetKeyboardLevelUpTipDescription(self.rewardLevel)
    if overviewText ~= "" and descriptionText ~= "" then
        self.layout:AddOffsetY(ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_GROUPING_SPACING)
        self.layout:StartSection()
        local tipText = zo_strformat(SI_LEVEL_UP_REWARDS_KEYBOARD_TIP_FORMAT, overviewText, descriptionText)
        local tipLabel = self.tipPool:AcquireObject()
        tipLabel:SetText(tipText)
        self.layout:Anchor(tipLabel)
    end

    local attributePoints = GetAttributePointsAwardedForLevel(self.rewardLevel)
    local skillPoints = GetSkillPointsAwardedForLevel(self.rewardLevel)

    if attributePoints > 0 or skillPoints > 0 then
        self.layout:AddOffsetY(ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_GROUPING_SPACING)
    end

    if attributePoints > 0 then
        self.layout:StartSection()
        local rewardControl = self.pointRewardPool:AcquireObject()
        local rowControlData = ZO_LEVEL_UP_REWARDS_MANAGER:GetAttributePointEntryInfo(attributePoints)
        self:SetupRewardRow(rewardControl, rowControlData)
        self.layout:Anchor(rewardControl)
    end

    if skillPoints > 0 then
        self.layout:StartSection()
        local rewardControl = self.pointRewardPool:AcquireObject()
        local rowControlData = ZO_LEVEL_UP_REWARDS_MANAGER:GetSkillPointEntryInfo(skillPoints)
        self:SetupRewardRow(rewardControl, rowControlData)
        self.layout:Anchor(rewardControl)
    end

    if #rewards > 0 then
        self.layout:AddOffsetY(ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_GROUPING_SPACING)
    end

    for i, reward in ipairs(rewards) do
        if reward:IsValidReward() then
            if reward.choices == nil then
                self.layout:StartSection()
                local rewardControl = self.rewardPool:AcquireObject()
                self:SetupRewardRow(rewardControl, reward)
                self.layout:Anchor(rewardControl)
            else
                self.layout:StartSection()
                local rewardHeaderControl = self.rewardHeaderPool:AcquireObject()
                self:SetupRewardHeader(rewardHeaderControl, GetString(SI_LEVEL_UP_REWARDS_CHOICE_HEADER))
                self.layout:AddOffsetY(ZO_CLAIM_LEVEL_UP_REWARDS_KEYBOARD_GROUPING_SPACING)
                self.layout:Anchor(rewardHeaderControl)

                for choiceIndex, choiceReward in ipairs(reward.choices) do
                    if choiceReward:IsValidReward() then
                        local rewardControl = self.choiceRewardPool:AcquireObject()
                        self:SetupRewardRow(rewardControl, choiceReward)
                        self.layout:Anchor(rewardControl)
                        self.choiceRewardDataToControl[choiceReward] = rewardControl
                    end
                end
            end
        end
    end

    self.control:SetHeight(zo_min(WINDOW_HEIGHT_WITHOUT_DYNAMIC_CONTROLS + self.layout:GetTotalHeight(), ZO_LEVEL_UP_REWARDS_KEYBOARD_MAX_SCREEN_HEIGHT))

    self:PlayShowAnimations()
end

function ZO_LevelUpRewardsClaim_Keyboard:OnRewardRowClicked(control)
    local rewardData = control.data
    if rewardData then
        local parentChoice = rewardData:GetParentChoice()
        if parentChoice then
            local parentRewardId = parentChoice:GetRewardId()
            local choiceRewardId = rewardData:GetRewardId()
            MakeLevelUpRewardChoice(parentRewardId, choiceRewardId)
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
    end
end

function ZO_LevelUpRewardsClaim_Keyboard:RefreshSelectedChoices()
    self.selectionHighlightPool:ReleaseAllObjects()
    for rewardData, rewardControl in pairs(self.choiceRewardDataToControl) do
        self:SetupRewardRow(rewardControl, rewardData)
    end

    self:UpdateClaimButtonState()
end

function ZO_LevelUpRewardsClaim_Keyboard:UpdateClaimButtonState()
    self.claimButton:SetEnabled(DoAllValidLevelUpRewardChoicesHaveSelections())
end

--
--[[ XML Handlers ]]--
--

function ZO_ClaimLevelUpRewards_Keyboard_OnInitialized(control)
    ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS = ZO_LevelUpRewardsClaim_Keyboard:New(control)
end

function ZO_ClaimLevelUpRewards_Keyboard_OnClaimButtonMouseEnter(control)
    local currentState = control:GetState()
    if currentState == BSTATE_DISABLED then -- currently the button is only disabled if you haven't made choices for each choice reward
        InitializeTooltip(InformationTooltip, control, LEFT, 0, 0, RIGHT)
        InformationTooltip:AddLine(GetString(SI_LEVEL_UP_REWARDS_KEYBOARD_CLAIM_REWARDS_BUTTON_MISSING_CHOICE_TOOLTIP), "ZoFontGameMedium")
    end
end

function ZO_ClaimLevelUpRewards_Keyboard_OnClaimButtonMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_ClaimLevelUpRewards_Keyboard_OnClaimButtonClicked()
    ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS:ClaimLevelUpRewards()
end

do
    local function LayoutBasicTooltip(tooltip, control, title, body)
        InitializeTooltip(tooltip, control, LEFT, 0, 0, RIGHT)

        tooltip:AddVerticalPadding(5)

        local r, g, b = ZO_SELECTED_TEXT:UnpackRGB()
        local FULL_WIDTH = true
        tooltip:AddLine(title, "ZoFontWinH2", r, g, b, TOPLEFT, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, FULL_WIDTH)

        ZO_Tooltip_AddDivider(tooltip)

        r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
        tooltip:AddLine(body, "ZoFontGameMedium", r, g, b)
    end

    function ZO_LevelUpRewards_RewardRow_OnMouseEnter(control)
        local rewardData = control.data
        if rewardData then
            local rewardType = rewardData:GetRewardType()
            if rewardType then
                ZO_Rewards_Shared_OnMouseEnter(control)
            elseif rewardData:IsAdditionalUnlock() then
                LayoutBasicTooltip(ItemTooltip, control, rewardData:GetFormattedName(), rewardData:GetDescription())
            elseif rewardData:IsSkillPoint() then
                LayoutBasicTooltip(ItemTooltip, control, GetString(SI_LEVEL_UP_REWARDS_SKILL_POINT_TOOLTIP_HEADER), GetString(SI_LEVEL_UP_REWARDS_SKILL_POINT_TOOLTIP_BODY))
            elseif rewardData:IsAttributePoint() then
                LayoutBasicTooltip(ItemTooltip, control, GetString(SI_LEVEL_UP_REWARDS_ATTRIBUTE_POINT_TOOLTIP_HEADER), GetString(SI_LEVEL_UP_REWARDS_ATTRIBUTE_POINT_TOOLTIP_BODY))
            end
        end
    end
end

function ZO_LevelUpRewards_RewardRow_OnMouseExit(control)
    ZO_Rewards_Shared_OnMouseExit(control)
end

function ZO_LevelUpRewards_ChoiceRewardRow_OnMouseEnter(control)
    ZO_LevelUpRewards_RewardRow_OnMouseEnter(control)
    ZO_InventorySlot_SetHighlightHidden(control, false)
end

function ZO_LevelUpRewards_ChoiceRewardRow_OnMouseExit(control)
    ZO_LevelUpRewards_RewardRow_OnMouseExit(control)
    ZO_InventorySlot_SetHighlightHidden(control, true)
end 

function ZO_LevelUpRewards_ChoiceRewardRow_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
        ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS:OnRewardRowClicked(control)
    end
end
