ZO_TAMRIEL_TOMES_GRID_LIST_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 5 + ZO_SCROLL_BAR_WIDTH + 10
ZO_TAMRIEL_TOMES_GRID_LIST_HEIGHT = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT * 3 + ZO_TAMRIEL_TOMES_REWARD_DIVIDER_HEIGHT

ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES =
{
    NONE = 0,
    ACTIVE_PREVIEW = 1,
    QUICK_PREVIEW = 2,
}

ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES =
{
    TEMPLATE_DIVIDER = 1,
    TEMPLATE_1X_WIDTH = 2,
    TEMPLATE_2X_WIDTH_LEFT = 3,
    TEMPLATE_2X_WIDTH_RIGHT = 4,
    TEMPLATE_2_5X_WIDTH_LEFT = 5,
    TEMPLATE_2_5X_WIDTH_RIGHT = 6,
}

ZO_TAMRIEL_TOMES_REWARD_ENTRY_TEMPLATE_LAYOUT =
{
    -- Row 1
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2_5X_WIDTH_RIGHT,
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2_5X_WIDTH_LEFT,

    -- Row 2
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2X_WIDTH_RIGHT,
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_1X_WIDTH,
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2X_WIDTH_LEFT,

    -- Divider
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_DIVIDER,

    -- Row 3
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_1X_WIDTH,
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_1X_WIDTH,
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_1X_WIDTH,
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_1X_WIDTH,
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_1X_WIDTH,
}

local QUICK_PREVIEW_DELAY_SECONDS = 0.5

ZO_TamrielTomesScreen_Shared = ZO_DeferredInitializingObject:Subclass()

ZO_TamrielTomesScreen_Shared:MUST_IMPLEMENT("InitializeKeybindStripDescriptor")
ZO_TamrielTomesScreen_Shared:MUST_IMPLEMENT("PreviewRewardList")
ZO_TamrielTomesScreen_Shared:MUST_IMPLEMENT("ShowIntroScreen")

function ZO_TamrielTomesScreen_Shared:Initialize(control, scene, templateData)
    self.control = control
    self.templateData = templateData

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    self.control:SetHandler("OnUpdate", function(_, ...) self:OnUpdate(...) end)
end

function ZO_TamrielTomesScreen_Shared:OnDeferredInitialize()
    self:InitializeControls()
    self:InitializeKeybindStripDescriptor()
    self:InitializeParticleSystems()
    self:RegisterForEvents()
end

function ZO_TamrielTomesScreen_Shared:InitializeControls()
    local headerContainer = self.control:GetNamedChild("Header")
    self.titleLabel = headerContainer:GetNamedChild("Title")
    self.subtitleLabel = headerContainer:GetNamedChild("Subtitle")
    self.buttonContainer = headerContainer:GetNamedChild("Buttons")
    self.challengesButton = self.buttonContainer:GetNamedChild("ChallengesButton")
    self.upgradeButton = self.buttonContainer:GetNamedChild("UpgradeButton")

    local bookContainer = self.control:GetNamedChild("Book")
    self.particleGeneratorPositionControl = bookContainer:GetNamedChild("RewardParticleGeneratorPosition")

    local currencyInfoContainer = bookContainer:GetNamedChild("Currency")
    local currencyContainer = currencyInfoContainer:GetNamedChild("Balance")
    self.currencyBalanceBackdrop = currencyInfoContainer:GetNamedChild("BalanceBackdrop")
    self.currencyFullBackdrop = currencyInfoContainer:GetNamedChild("FullBackdrop")
    self.currencyNameLabel = currencyContainer:GetNamedChild("Name")
    self.currencyAmountRollingMeter = currencyContainer:GetNamedChild("Amount")
    self.currencyIconControl = currencyContainer:GetNamedChild("Icon")

    local currencyBonusContainer = currencyInfoContainer:GetNamedChild("Bonus")
    self.currencyBonusContainer = currencyBonusContainer
    self.currencyBonusPercentLabel = currencyBonusContainer:GetNamedChild("Percent")
    self.currencyBonusIconTexture = currencyBonusContainer:GetNamedChild("Icon")

    local pageNavigationControl = bookContainer:GetNamedChild("PageNavigation")
    self.pageNavigation = ZO_PageNavigation:New(pageNavigationControl)
    self.pageNavigation:SetStartingPageNumber(0)
    self.pageNavigation:SetPageChangeSound(SOUNDS.TAMRIEL_TOMES_PAGE_FLIPPED)
    self.pageNavigation:RegisterCallback("PageChanged", self.OnPageChanged, self)

    self.unlockPointsRequired = bookContainer:GetNamedChild("UnlockPointsRequired")

    self.gridListControl = bookContainer:GetNamedChild("GridList")

    self:InitializeCurrencyRollingMeter()
    self:InitializeGridList()
end

function ZO_TamrielTomesScreen_Shared:InitializeCurrencyRollingMeter()
    self.currencyAmountRollingMeter:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    self.currencyAmountRollingMeter:SetIsCommaDelimited(true)
    self.currencyAmountRollingMeter:SetResizeToFitLabels(true)
    self.currencyAmountRollingMeter:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())

    self.currencyAmountTransitionManager = self.currencyAmountRollingMeter:GetOrCreateTransitionManager()
    self.currencyAmountTransitionManager:SetTransitionAnimationStartedCallback(function(rollingMeterLabel, currentStep, numSteps, currentValue, targetValue)
        if currentValue == targetValue and not self.fragment:IsHidden() then
            PlaySound(SOUNDS.TAMRIEL_TOMES_TOME_POINTS_ROLLING_ENDED)
        end
    end)

    local IS_PLURAL = false
    local currencyName = GetCurrencyName(CURT_TOME_POINTS, IS_PLURAL)
    local formattedCurrencyNameString = zo_strformat(SI_TAMRIEL_TOMES_CURRENCY_NAME_LABEL, currencyName)
    self.currencyNameLabel:SetText(formattedCurrencyNameString)
end

function ZO_TamrielTomesScreen_Shared:InitializeGridList()
    local templateData = self.templateData

    -- Override default highlight template to hide white outline around tiles on gamepad
    local gridList = templateData.gridClass:New(self.gridListControl, templateData.gamepadHighlightTemplate)
    self.gridList = gridList
    gridList:SetIndentAmount(10)
    gridList:SetHeaderPrePadding(0)
    gridList:SetHeaderPostPadding(0)
    gridList:SetYDistanceFromEdgeWhereSelectionCausesScroll(10)

    local DEFAULT_HIDE_CALLBACK = nil
    local DEFAULT_ENTRIES_CENTERED = nil
    local templateTypes = ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES
    for _, templateTypeIndex in pairs(templateTypes) do
        local typeData = templateData[templateTypeIndex]
        local setupCallback = typeData.setupCallback or ZO_DefaultGridTileEntrySetup
        local resetCallback = typeData.resetCallback or ZO_DefaultGridTileEntryReset
        self.gridList:AddEntryTemplate(typeData.entryTemplate, typeData.width, typeData.height, setupCallback, DEFAULT_HIDE_CALLBACK, resetCallback, 0, 0, DEFAULT_ENTRIES_CENTERED, typeData.isSelectable)
    end
end

function ZO_TamrielTomesScreen_Shared:InitializeParticleSystems()
    self.blastParticleSystem = ZO_BlastParticleSystem:New()
    self.blastParticleSystem:SetSound(SOUNDS.DAILY_LOGIN_REWARDS_CLAIM_FANFARE) -- TODO Tamriel Tomes : Do we want a custom sound for this?
    self.blastParticleSystem:SetParentControl(self.particleGeneratorPositionControl)
end

function ZO_TamrielTomesScreen_Shared:RegisterForEvents()
    -- eventId, currencyType, currencyLocation, delta, reason, reasonInfo
    local function OnCurrencyUpdated(_, currencyType)
        if not self.control:IsHidden() then
            if currencyType == CURT_TOME_POINTS then
                self:UpdateCurrencyAmount()
            elseif currencyType == CURT_TOME_POINT_CACHES then
                self:UpdateKeybinds()
            end
        end
    end

    self.control:RegisterForEvent(EVENT_CURRENCY_UPDATE, OnCurrencyUpdated)

    local function OnRewardTrackRewardClaimed(_, rewardTrackType, rewardTrackId, rewardTrackTier, rewardTrackComponent, rewardIndex, isFallback)
        if self.control:IsHidden() then
            return
        end

        if rewardTrackType ~= REWARD_TRACK_TYPE_TAMRIEL_TOMES then
            return
        end

        PlaySound(SOUNDS.TAMRIEL_TOMES_REWARD_PURCHASED)
        self:RebuildGridList()

        local gridTile = self:GetTileByTamrielTomesRewardIndex(rewardTrackId, rewardTrackTier, rewardTrackComponent, rewardIndex)
        if gridTile then
            self:ShowClaimedRewardFlair(gridTile)
        end
    end

    self.control:RegisterForEvent(EVENT_REWARD_TRACK_REWARD_CLAIMED, OnRewardTrackRewardClaimed)

    local function OnSelectedTomeChanged(tomeId)
        if self:IsShowing() then
            self:UpdateTomeInfo(tomeId)
        end
    end

    TAMRIEL_TOMES_MANAGER:RegisterCallback("SelectedTomeChanged", OnSelectedTomeChanged)

    local function OnPurchaseDataUpdated()
        if self:IsShowing() then
            self:UpdateButtons()
        end
    end

    TAMRIEL_TOMES_MANAGER:RegisterCallback("DirectPurchaseDataUpdated", OnPurchaseDataUpdated)
end

function ZO_TamrielTomesScreen_Shared:ShowClaimedRewardFlair(gridTile)
    local tileReward = gridTile:GetNamedChild("Reward")
    if not tileReward then
        return
    end

    self.particleGeneratorPositionControl:ClearAnchors()
    self.particleGeneratorPositionControl:SetAnchor(CENTER, tileReward, CENTER, 0, -10)
    self.blastParticleSystem:Start()

    ZO_CraftingResults_Base_PlayPulse(tileReward)
end

function ZO_TamrielTomesScreen_Shared:UpdateTomeInfo(tomeId)
    self.selectedTomeId = tomeId
    self.selectedTomeData = ZO_TamrielTomeData:New(tomeId)
    self.selectedTomeIndex = self.selectedTomeData:GetTamrielTomeIndex()
    self.currentRewardTrackId = self.selectedTomeData:GetRewardTrackId()
    self.currentTierIndex = 1

    self:UpdateButtons()
    self:UpdatePageNavigation()
end

function ZO_TamrielTomesScreen_Shared:GetSelectedTamrielTomesRewardData()
    return self.selectedTamrielTomesRewardData
end

function ZO_TamrielTomesScreen_Shared:SetSelectedTamrielTomesRewardData(newData)
    if newData == self.selectedTamrielTomesRewardData then
        return
    end

    local previousData = self.selectedTamrielTomesRewardData
    local previousTileControl = self:GetSelectedTile()
    if previousTileControl then
        previousTileControl.object:GetReward():SetSelected(false)
    end

    self.selectedTamrielTomesRewardData = newData
    self:RefreshGridList()

    local newTileControl = self:GetSelectedTile()
    if newTileControl then
        newTileControl.object:GetReward():SetSelected(true)
    end

    self:OnSelectedTamrielTomesRewardDataChanged(previousData, newData, previousTileControl, newTileControl)
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:GetPreviewedTile()
    local previewTamrielTomesRewardData = self:GetCurrentPreviewTamrielTomesRewardData()
    if previewTamrielTomesRewardData then
        return self:GetTileByTamrielTomesRewardData(previewTamrielTomesRewardData)
    end

    return nil
end

function ZO_TamrielTomesScreen_Shared:GetSelectedTile()
    return self:GetTileByTamrielTomesRewardData(self.selectedTamrielTomesRewardData)
end

function ZO_TamrielTomesScreen_Shared:GetTileByTamrielTomesRewardData(tamrielTomesRewardData)
    if tamrielTomesRewardData then
        return self.gridList:GetControlFromData(tamrielTomesRewardData)
    end

    return nil
end

function ZO_TamrielTomesScreen_Shared:GetTamrielTomeRewardDataFromEntryData(entryData)
    if entryData and entryData.rewardTrackId then
        return entryData
    end

    return nil
end

function ZO_TamrielTomesScreen_Shared:GetTileByTamrielTomesRewardIndex(rewardTrackId, rewardTrackTier, rewardTrackComponent, rewardIndex)
    local gridEntries = self.gridList:GetData()
    if not gridEntries then
        return nil
    end

    for _, entry in ipairs(gridEntries) do
        local entryData = entry.data
        if entryData then
            local tamrielTomeRewardData = self:GetTamrielTomeRewardDataFromEntryData(entryData)
            if tamrielTomeRewardData and tamrielTomeRewardData:Equals(rewardTrackId, rewardTrackTier, rewardTrackComponent, rewardIndex) then
                return self.gridList:GetControlFromData(entryData)
            end
        end
    end

    return nil
end

function ZO_TamrielTomesScreen_Shared:HasSelectedTamrielTomesRewardData()
    return self:GetSelectedTamrielTomesRewardData() ~= nil
end

function ZO_TamrielTomesScreen_Shared:AddGridEntryInternal(rewardData, entryTemplateId)
    local templateData = self.templateData[entryTemplateId]
    if not templateData then
        internalassert(templateData, string.format("Invalid entryTemplateId specified: %s", tostring(entryTemplateId or "nil")))
        return
    end

    self.gridList:AddEntry(rewardData, templateData.entryTemplate)
end

function ZO_TamrielTomesScreen_Shared:ClearTamrielTomesRewardCursor()
    self.currentRewardComponent = nil
    self.currentRewardIndex = nil
end

function ZO_TamrielTomesScreen_Shared:GetCurrentTamrielTomesRewardData()
    local tamrielTomesRewardData = ZO_TamrielTomesRewardData:New(self.selectedTomeId, self.currentRewardTrackId, self.currentTierIndex, self.currentRewardComponent, self.currentRewardIndex)
    return tamrielTomesRewardData
end

function ZO_TamrielTomesScreen_Shared:GetFirstTamrielTomesRewardData()
    self.currentRewardComponent = REWARD_TRACK_COMPONENT_SECONDARY
    self.currentRewardIndex = 0
    return self:GetNextTamrielTomesRewardData()
end

function ZO_TamrielTomesScreen_Shared:GetNextTamrielTomesRewardData()
    if not self:IsTamrielTomesRewardDataCursorValid() then
        internalassert(false, "Tamriel Tomes Reward Data cursor is invalid. Call GetFirstTamrielTomesRewardData() to create a new cursor.")
        return nil
    end

    if not self:HasNextTamrielTomesRewardDataForCurrentRewardComponent() then
        if self.currentRewardComponent == REWARD_TRACK_COMPONENT_SECONDARY then
            -- Advance to secondary reward components.
            self.currentRewardComponent = REWARD_TRACK_COMPONENT_PRIMARY
            self.currentRewardIndex = 0

            if not self:HasNextTamrielTomesRewardDataForCurrentRewardComponent() then
                -- No secondary reward components exist.
                self:ClearTamrielTomesRewardCursor()
                return nil
            end
        else
            -- End of primary and secondary rewards.
            self:ClearTamrielTomesRewardCursor()
            return nil
        end
    end

    self.currentRewardIndex = self.currentRewardIndex + 1
    local tamrielTomesRewardData = self:GetCurrentTamrielTomesRewardData()
    return tamrielTomesRewardData
end

function ZO_TamrielTomesScreen_Shared:GetNumTamrielTomesRewardDataForCurrentRewardComponent()
    local numRewards = GetNumRewardsAtRewardTrackTier(self.currentRewardTrackId, self.currentTierIndex, self.currentRewardComponent)
    return numRewards
end

function ZO_TamrielTomesScreen_Shared:HasNextTamrielTomesRewardDataForCurrentRewardComponent()
    return self.currentRewardIndex < self:GetNumTamrielTomesRewardDataForCurrentRewardComponent()
end

function ZO_TamrielTomesScreen_Shared:IsTamrielTomesRewardDataCursorValid()
    return self.currentRewardComponent and self.currentRewardIndex
end

function ZO_TamrielTomesScreen_Shared:RebuildGridList()
    self.gridList:ClearGridList()

    local entryData = self:GetFirstTamrielTomesRewardData()
    for entryIndex, entryTemplate in ipairs(ZO_TAMRIEL_TOMES_REWARD_ENTRY_TEMPLATE_LAYOUT) do
        if not entryData then
            -- End of rewards reached.
            break
        end

        if entryTemplate == ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_DIVIDER then
            self:AddGridEntryInternal({}, ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_DIVIDER)
        else
            self:AddGridEntryInternal(entryData, entryTemplate)
            entryData = self:GetNextTamrielTomesRewardData()
        end
    end

    self.gridList:CommitGridList()
end

function ZO_TamrielTomesScreen_Shared:Refresh()
    local selectedTomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    self:UpdateTomeInfo(selectedTomeId)

    local rewardTrackId = self.currentRewardTrackId
    local titleText = GetRewardTrackDisplayName(rewardTrackId)
    self.titleLabel:SetText(titleText)

    local currencyBonusPercentage = GetCurrencyBonusPercentage(CURT_TOME_POINTS)
    local hasCurrencyBonus = currencyBonusPercentage > 0
    self.currencyBonusContainer:SetHidden(not hasCurrencyBonus)
    self.currencyBalanceBackdrop:SetHidden(hasCurrencyBonus)
    self.currencyFullBackdrop:SetHidden(not hasCurrencyBonus)
    if hasCurrencyBonus then
        self.currencyBonusPercentLabel:SetText(zo_strformat(SI_TAMRIEL_TOMES_CURRENCY_BONUS_PERCENTAGE_LABEL, currencyBonusPercentage))
    end

    local UPDATE_IMMEDIATELY = true
    self:UpdateCurrencyAmount(UPDATE_IMMEDIATELY)
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:RefreshGridList()
    self.gridList:RefreshGridList()
end

function ZO_TamrielTomesScreen_Shared:UpdateButtons()
    local shouldEnableUpgrade = TAMRIEL_TOMES_MANAGER:CanPurchaseAnySelectedTomeProduct()
    self.upgradeButton:SetEnabled(shouldEnableUpgrade)
end

function ZO_TamrielTomesScreen_Shared:BeginActivePreviewInternal(previousTamrielTomesRewardData, tamrielTomesRewardData)
    -- Active preview is a higher priority than quick preview.
    -- Order matters
    self.activePreviewTamrielTomesRewardData = tamrielTomesRewardData
    self:EndQuickPreview()

    local rewardId = tamrielTomesRewardData:GetRewardId()
    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
        self:PreviewRewardList(rewardId)
    else
        SYSTEMS:GetObject("itemPreview"):PreviewReward(rewardId)
    end
    self:SetPreviewControlsHidden(false)

    local newPreviewRewardData = self:GetCurrentPreviewTamrielTomesRewardData()
    self:OnPreviewedTamrielTomesRewardDataChanged(previousTamrielTomesRewardData, newPreviewRewardData)
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:BeginPreview(previewType, tamrielTomesRewardData)
    if not tamrielTomesRewardData:CanPreviewReward() then
        return
    end

    local previousTamrielTomesRewardData = self:GetCurrentPreviewTamrielTomesRewardData()
    if previewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW then
        self:BeginQuickPreviewInternal(previousTamrielTomesRewardData, tamrielTomesRewardData)
    elseif previewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        self:BeginActivePreviewInternal(previousTamrielTomesRewardData, tamrielTomesRewardData)
    else
        internalassert(false, "Invalid previewType: ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES value specified is invalid.")
    end
end

function ZO_TamrielTomesScreen_Shared:BeginQuickPreview(tamrielTomesRewardData)
    if not (tamrielTomesRewardData:CanPreviewReward() and self:CanQuickPreview()) then
        return
    end

    -- Order matters
    self.quickPreviewTimeoutSeconds = nil
    self.queuedQuickPreviewTamrielTomesRewardData = tamrielTomesRewardData
    self.queuedQuickPreviewTamrielTomesRewardDataStartTimeSeconds = GetFrameTimeSeconds() + QUICK_PREVIEW_DELAY_SECONDS
end

function ZO_TamrielTomesScreen_Shared:BeginQuickPreviewInternal(previousTamrielTomesRewardData, tamrielTomesRewardData)
    if not self:CanQuickPreview() then
        self:EndQuickPreview()
        return
    end

    self.quickPreviewTamrielTomesRewardData = tamrielTomesRewardData

    local rewardId = tamrielTomesRewardData:GetRewardId()
    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
        self:PreviewRewardList(rewardId)
    else
        SYSTEMS:GetObject("itemPreview"):PreviewReward(rewardId)
    end
    self:SetPreviewControlsHidden(true)

    local newPreviewRewardData = self:GetCurrentPreviewTamrielTomesRewardData()
    self:OnPreviewedTamrielTomesRewardDataChanged(previousTamrielTomesRewardData, newPreviewRewardData)
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:EndActivePreview()
    if self.activePreviewTamrielTomesRewardData then
        local previousTamrielTomesRewardData = self.activePreviewTamrielTomesRewardData
        self.activePreviewTamrielTomesRewardData = nil
        self:EndPreviewInternal()
        self:OnPreviewedTamrielTomesRewardDataChanged(previousTamrielTomesRewardData, nil)
    end
end

function ZO_TamrielTomesScreen_Shared:EndPreviewInternal()
    if self:IsPreviewing() then
        SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
        ApplyChangesToPreviewCollectionShown()
        self:UpdateKeybinds()
    end
end

function ZO_TamrielTomesScreen_Shared:EndPreview()
    local currentPreviewType = self:GetCurrentPreviewType()
    if currentPreviewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        self:EndActivePreview()
    elseif currentPreviewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW then
        self:EndQuickPreview()
    else
        self:EndPreviewInternal()
    end
end

function ZO_TamrielTomesScreen_Shared:ClearQueuedQuickPreview()
    self.queuedQuickPreviewTamrielTomesRewardData = nil
    self.queuedQuickPreviewTamrielTomesRewardDataStartTimeSeconds = nil
end

function ZO_TamrielTomesScreen_Shared:ClearQuickPreview()
    local previousTamrielTomesRewardData = self:GetCurrentPreviewTamrielTomesRewardData()
    self.quickPreviewTamrielTomesRewardData = nil
    self.quickPreviewTimeoutSeconds = nil

    local newTamrielTomesRewardData = self:GetCurrentPreviewTamrielTomesRewardData()
    self:OnPreviewedTamrielTomesRewardDataChanged(previousTamrielTomesRewardData, newTamrielTomesRewardData)
end

function ZO_TamrielTomesScreen_Shared:EndQuickPreview()
    if self.quickPreviewTamrielTomesRewardData or self.queuedQuickPreviewTamrielTomesRewardDataStartTimeSeconds then
        -- Order matters
        self:ClearQueuedQuickPreview()
        self:ClearQuickPreview()

        if self:GetCurrentPreviewType() ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
            self:EndPreviewInternal()
        end
    end
end

function ZO_TamrielTomesScreen_Shared:IsPreviewing()
    return IsCurrentlyPreviewing() or self:GetCurrentPreviewType() ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE
end

function ZO_TamrielTomesScreen_Shared:IsPreviewingSelectedTamrielTomesRewardData()
    local selectedTamrielTomesRewardData = self:GetSelectedTamrielTomesRewardData()
    if not selectedTamrielTomesRewardData then
        return false
    end

    return selectedTamrielTomesRewardData == self:GetCurrentPreviewTamrielTomesRewardData()
end

function ZO_TamrielTomesScreen_Shared:GetCurrentPreviewType()
    if self.activePreviewTamrielTomesRewardData then
        return ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW
    end

    if self.quickPreviewTamrielTomesRewardData or self.quickPreviewTamrielTomesRewardDataStartTimeSeconds then
        return ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW
    end

    return ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE
end

function ZO_TamrielTomesScreen_Shared:GetCurrentPreviewTamrielTomesRewardData()
    local previewType = self:GetCurrentPreviewType()

    if previewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        return self.activePreviewTamrielTomesRewardData
    end
    
    if previewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW then
        return self.quickPreviewTamrielTomesRewardData or self.queuedQuickPreviewTamrielTomesRewardData
    end

    return nil
end

function ZO_TamrielTomesScreen_Shared:CanQuickPreview()
    if not self.scene:IsShowing() then
        return false
    end

    if self:GetCurrentPreviewType() == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        -- An active preview suppresses any request to quick preview.
        return false
    end

    return true
end

function ZO_TamrielTomesScreen_Shared:SetIsTamrielTomesRewardPreviewing(tamrielTomesRewardData, isPreviewing)
    local tile = self:GetTileByTamrielTomesRewardData(tamrielTomesRewardData)
    if not tile then
        return
    end

    tile.object:GetReward():SetPreviewing(isPreviewing)
end

function ZO_TamrielTomesScreen_Shared:UpdateKeybinds()
    if self.scene:IsShowing() then
        if self.areKeybindsAdded then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        else
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self.areKeybindsAdded = true
        end
    else
        if self.areKeybindsAdded then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self.areKeybindsAdded = false
        end
    end
end

function ZO_TamrielTomesScreen_Shared:OnPreviewedTamrielTomesRewardDataChanged(previousTamrielTomesRewardData, newTamrielTomesRewardData)
    if previousTamrielTomesRewardData ~= newTamrielTomesRewardData then
        if previousTamrielTomesRewardData then
            self:SetIsTamrielTomesRewardPreviewing(previousTamrielTomesRewardData, false)
        end

        if newTamrielTomesRewardData then
            self:SetIsTamrielTomesRewardPreviewing(newTamrielTomesRewardData, true)
        end
    end
end

function ZO_TamrielTomesScreen_Shared:SetPreviewControlsHidden(hidden)
    local previewSystem = SYSTEMS:GetObject("itemPreview")
    if hidden then
        previewSystem:SetActionControlsHidden(true)
        previewSystem:SetVariationControlsHidden(true)
    else
        -- Restores the preview action carousel and/or variaton controls if appropriate to do so.
        previewSystem:SetupActionCarousel()
        previewSystem:SetupVariationControls()
    end
end

-- Indicates whether this scene should retain the current preview when hidden.
function ZO_TamrielTomesScreen_Shared:ShouldRetainPreview()
    return false
end

function ZO_TamrielTomesScreen_Shared:OnHiding()
    if self:ShouldRetainPreview() then
        -- The upcoming scene will need the current preview, if any, to remain visible.
        self:SetPreviewControlsHidden(false)
    else
        self:EndPreview()
    end

    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:OnShowing()
    self:Refresh()
    self:RefreshGridList()

    DIRECT_PURCHASE_MANAGER:RequestCatalog()
end

function ZO_TamrielTomesScreen_Shared:OnShown()
    local selectedTomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    TAMRIEL_TOMES_MANAGER:MarkTomeSeen(selectedTomeId)

    TriggerTutorial(TUTORIAL_TRIGGER_TAMRIEL_TOMES_OPENED)
end

function ZO_TamrielTomesScreen_Shared:OnSelectedTamrielTomesRewardDataChanged(previousData, newData, previousTileControl, newTileControl)
    if newData and newData:CanPreviewReward() then
        self:BeginQuickPreview(newData)
    else
        self.quickPreviewTimeoutSeconds = GetFrameTimeSeconds() + QUICK_PREVIEW_DELAY_SECONDS
        self:ClearQueuedQuickPreview()
    end
end

function ZO_TamrielTomesScreen_Shared:OnUpdate(currentFrameTimeSeconds)
    if self.queuedQuickPreviewTamrielTomesRewardDataStartTimeSeconds and currentFrameTimeSeconds >= self.queuedQuickPreviewTamrielTomesRewardDataStartTimeSeconds then
        self:BeginPreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW, self.queuedQuickPreviewTamrielTomesRewardData)
        self:ClearQueuedQuickPreview()
    elseif self.quickPreviewTimeoutSeconds and currentFrameTimeSeconds >= self.quickPreviewTimeoutSeconds then
        self:EndQuickPreview()
    end

    if not self.nextTimeRemainingUpdateS or currentFrameTimeSeconds > self.nextTimeRemainingUpdateS then
        local endTimeS = GetActiveTamrielTomeSeasonEndTimeS()
        local timeRemainingS = zo_max(0, endTimeS - GetTimeStamp())
        local timeRemainingText = ""
        if timeRemainingS > 0 then
            local durationText
            if timeRemainingS > ZO_ONE_MINUTE_IN_SECONDS then
                durationText = ZO_FormatTimeLargestTwo(timeRemainingS, TIME_FORMAT_STYLE_DESCRIPTIVE)
            else
                durationText = GetString(SI_STR_TIME_LESS_THAN_MINUTE)
            end
            timeRemainingText = zo_strformat(SI_EVENT_ANNOUNCEMENT_TIME, durationText)

            if timeRemainingS > ZO_ONE_DAY_IN_SECONDS + ZO_ONE_HOUR_IN_SECONDS then
                self.nextTimeRemainingUpdateS = currentFrameTimeSeconds + ZO_ONE_HOUR_IN_SECONDS
            elseif timeRemainingS > ZO_ONE_HOUR_IN_SECONDS + ZO_ONE_MINUTE_IN_SECONDS then
                self.nextTimeRemainingUpdateS = currentFrameTimeSeconds + ZO_ONE_MINUTE_IN_SECONDS
            else
                self.nextTimeRemainingUpdateS = currentFrameTimeSeconds + 1
            end
        end
        self.subtitleLabel:SetText(timeRemainingText)
    end
end

function ZO_TamrielTomesScreen_Shared:GetNumBaseRewardPages()
    local rewardTrackId = self.currentRewardTrackId
    return GetNumBaseTiersForRewardTrack(rewardTrackId)
end

function ZO_TamrielTomesScreen_Shared:GetNumBonusRewardPages()
    local rewardTrackId = self.currentRewardTrackId
    return GetNumBonusTiersForRewardTrack(rewardTrackId)
end

function ZO_TamrielTomesScreen_Shared:GetNumRewardPages()
    local rewardTrackId = self.currentRewardTrackId
    return GetTotalNumTiersForRewardTrack(rewardTrackId)
end

function ZO_TamrielTomesScreen_Shared:OnPageChanged(pageNumber)
    if pageNumber == 0 then
        self:ShowIntroScreen()
        return
    end

    self.currentTierIndex = zo_clamp(pageNumber, 1, self:GetNumRewardPages())
    self:RebuildGridList()

    -- TODO Tamriel Tomes: Update the label to show the number of points remaining to unlock this page, if it is not unlocked, or the subsequent page (if any exists).
    self.unlockPointsRequired:SetHidden(true)
    if self.selectedTomeData then
        local unlockPointsRemaining = self.selectedTomeData:GetProgressToNextTier()
        if unlockPointsRemaining > 0 then
            local currentTier = self.selectedTomeData:GetCurrentTier()
            if currentTier <= self.pageNavigation:GetCurrentPage() then
                local nextTier = currentTier + 1
                local unlockPointsRemainingString = ZO_Currency_FormatPlatform(CURT_TOME_POINTS, unlockPointsRemaining, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
                local unlockPointsRequiredString = zo_strformat(SI_TAMRIEL_TOMES_PAGE_UNLOCK_REQUIREMENT, unlockPointsRemainingString, tostring(nextTier))
                self.unlockPointsRequired:SetText(unlockPointsRequiredString)
                self.unlockPointsRequired:SetHidden(false)
            end
        end
    end
end

function ZO_TamrielTomesScreen_Shared:UpdatePageNavigation()
    local numRewardPages = self:GetNumRewardPages()
    local pageNavigation = self.pageNavigation
    local pageToSelect = pageNavigation:GetCurrentPage()
    if pageToSelect == nil or pageToSelect == 0 or pageToSelect > numRewardPages then
        pageToSelect = 1
    end

    pageNavigation:Clear()

    -- Add initial intro page (page 0).
    pageNavigation:AddPage()

    -- Add page 1 through n.
    local numBaseRewardPages = self:GetNumBaseRewardPages()
    pageNavigation:AddPages(numBaseRewardPages)

    -- Add any optional bonus pages.
    local numBonusRewardPages = self:GetNumBonusRewardPages()
    local pageIndicatorInfo =
    {
        color = ZO_OFF_WHITE,
        selectedColor = ZO_WHITE,
        icon = "/EsoUI/Art/TamrielTomes/tome_bonus_page_icon.dds",
    }
    pageNavigation:AddPages(numBonusRewardPages, pageIndicatorInfo)

    pageNavigation:Commit(pageToSelect)
end

function ZO_TamrielTomesScreen_Shared:UpdateCurrencyAmount(updateImmediately)
    local currencyAmount = GetPlayerStoredCurrencyAmount(CURT_TOME_POINTS)

    if updateImmediately then
        self.currencyAmountTransitionManager:SetValueImmediately(currencyAmount)
    else
        self.currencyAmountTransitionManager:SetValue(currencyAmount)
        PlaySound(SOUNDS.TAMRIEL_TOMES_TOME_POINTS_ROLLING_STARTED)
    end
end