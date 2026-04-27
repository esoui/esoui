ZO_TAMRIEL_TOME_SEASON_SELECTED_ANIMATION_DURATION_SECONDS = 1.5
ZO_TAMRIEL_TOME_SEASON_ENTRY_BORDER_BRIGHTNESS_SELECTED = 1
ZO_TAMRIEL_TOME_SEASON_ENTRY_BORDER_BRIGHTNESS_UNSELECTED = 0.3

ZO_TAMRIEL_TOME_SEASON_END_DIALOG_WIDTH = 665
ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_BORDER_WIDTH = 32
ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_IMAGE_HEIGHT = 307
ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_IMAGE_WIDTH = 615
ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_PADDING = 4
ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_WIDTH = ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_IMAGE_WIDTH - ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_BORDER_WIDTH - ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_PADDING * 2
ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_HEIGHT = 64 + ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_PADDING * 2
ZO_TAMRIEL_TOME_SEASON_END_GRID_HEIGHT_MAX = ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_HEIGHT * 6
ZO_TAMRIEL_TOME_SEASON_END_GRID_WIDTH = ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_IMAGE_WIDTH

ZO_TamrielTomeSeasonGridEntry_Shared = ZO_InitializingObject:Subclass()

function ZO_TamrielTomeSeasonGridEntry_Shared:Initialize(control)
    self.control = control
    control.object = self
end

function ZO_TamrielTomeSeasonGridEntry_Shared.OnSelectedUpdate(control, frameTimeS)
    local self = control.object
    local endFrameTimeS = self.selectedAnimationEndFrameTimeS
    local hasAnimationEnded = endFrameTimeS == nil

    if endFrameTimeS then
        local interval = 1 - zo_max(0, endFrameTimeS - frameTimeS) / ZO_TAMRIEL_TOME_SEASON_SELECTED_ANIMATION_DURATION_SECONDS
        if interval >= 1 then
            hasAnimationEnded = true
        else
            local easedInterval = 1 - zo_sin(ZO_HALF_PI - interval * ZO_HALF_PI)
            local ORIGIN_X = 0.75
            local originY = 1 + interval * 0.5
            local blurStrength = easedInterval * 0.15
            local NUM_SAMPLES = 21
            local NORMALIZED_OFFSET = 0
            local imageGlowTextureControl = control:GetNamedChild("ImageGlow")
            imageGlowTextureControl:SetRadialBlur(ORIGIN_X, originY, NUM_SAMPLES, blurStrength, NORMALIZED_OFFSET)
            imageGlowTextureControl:SetAlpha(zo_lerp(0, 0.7, zo_min(1, 3 * easedInterval)))
        end
    end

    if hasAnimationEnded then
        self.control:SetHandler("OnUpdate", nil)
    end
end

function ZO_TamrielTomeSeasonGridEntry_Shared:IsHighlighted()
    return self.isHighlighted
end

function ZO_TamrielTomeSeasonGridEntry_Shared:SetIsHighlighted(isHighlighted)
    self.isHighlighted = isHighlighted

    if isHighlighted and self.owner then
        self.owner:SetTargetGridEntry(self)
    end

    self:Update()
end

function ZO_TamrielTomeSeasonGridEntry_Shared:IsSelected()
    return self.data and self.data.isSelected()
end

function ZO_TamrielTomeSeasonGridEntry_Shared:Select()
    if self:IsSelected() then
        -- Prevent selection of the currently selected Tome.
        return
    end

    if not self.TrySetIsSelectionPending(true) then
        -- A different Tome is already pending selection.
        return
    end

    self.selectedAnimationEndFrameTimeS = GetFrameTimeSeconds() + ZO_TAMRIEL_TOME_SEASON_SELECTED_ANIMATION_DURATION_SECONDS
    self.control:SetHandler("OnUpdate", ZO_TamrielTomeSeasonGridEntry_Shared.OnSelectedUpdate)

    local imageGlowTextureControl = self.control:GetNamedChild("ImageGlow")
    imageGlowTextureControl:SetAlpha(0)
    imageGlowTextureControl:SetHidden(false)

    -- Schedule the Tome selection to occur just before the end of
    -- the animation so that the scene transition is seamless.
    local tomeId = self.data.tomeData:GetTamrielTomeId()
    zo_callLater(function()
        -- Order matters:
        do
            -- First, hide the Season Selection dialog.
            SYSTEMS:GetObject("tamrielTomes"):HideSelectTomeDialog()

            -- Then, clear the Selection Pending flag after hiding the dialog.
            self.TrySetIsSelectionPending(false)

            -- Finally, select the Tome.
            TAMRIEL_TOMES_MANAGER:SelectTomeId(tomeId)
        end
    end, ZO_TAMRIEL_TOME_SEASON_SELECTED_ANIMATION_DURATION_SECONDS * ZO_ONE_SECOND_IN_MILLISECONDS * 0.9)

    zo_callLater(function()
        local sceneName = SYSTEMS:GetRootSceneName("tamrielTomes")
        if not (SCENE_MANAGER:IsShowing(sceneName) or SCENE_MANAGER:IsSceneOnStack(sceneName)) then
            -- Show the tome.
            TAMRIEL_TOMES_MANAGER:OpenTamrielTome(tomeId)
        end
    end, ZO_TAMRIEL_TOME_SEASON_SELECTED_ANIMATION_DURATION_SECONDS * ZO_ONE_SECOND_IN_MILLISECONDS)
end

function ZO_TamrielTomeSeasonGridEntry_Shared:Setup(data, owner)
    data.owner = self
    self.data = data
    self.owner = owner

    local control = self.control
    local nameLabel = control:GetNamedChild("Name")
    nameLabel:SetText(data.text)
    nameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())

    local tomeData = data.tomeData
    local imageTexture = tomeData:GetIntroBackgroundFile()
    control:GetNamedChild("Image"):SetTexture(imageTexture)

    local imageGlowTextureControl = control:GetNamedChild("ImageGlow")
    imageGlowTextureControl:SetTexture(imageTexture)
    imageGlowTextureControl:SetHidden(true)
    imageGlowTextureControl:SetAlpha(0)

    control:GetNamedChild("Rewards"):SetColor(ZO_NORMAL_TEXT:UnpackRGBA())

    local numClaimedRewards = tomeData:GetNumClaimedRewards()
    local numRewards = tomeData:GetNumRewards()
    local rewardCountString = zo_strformat(SI_TAMRIEL_TOME_SEASON_ENTRY_EARNED_REWARDS_FORMATTER, numClaimedRewards, numRewards)
    local rewardCountLabel = control:GetNamedChild("RewardCount")
    rewardCountLabel:SetText(rewardCountString)
    rewardCountLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())

    self:SetIsHighlighted(false)
    self.control:SetHandler("OnUpdate", nil)
    self.selectedAnimationEndFrameTimeS = nil
    self:Update()
end

function ZO_TamrielTomeSeasonGridEntry_Shared:Update()
    local isHighlighted = self:IsHighlighted()
    local isSelected = self:IsSelected()

    local factor = isHighlighted and (isSelected and 1 or 0.8) or (isSelected and 0.5 or 0.3)
    self.control:GetNamedChild("Image"):SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, factor)

    local borderColor = isHighlighted and ZO_TAMRIEL_TOME_SEASON_ENTRY_BORDER_BRIGHTNESS_SELECTED or ZO_TAMRIEL_TOME_SEASON_ENTRY_BORDER_BRIGHTNESS_UNSELECTED
    self.control:GetNamedChild("Border"):SetColor(borderColor, borderColor, borderColor, 1)
end

-- Static Methods

-- Indicates whether the Selection Pending flag is set.
function ZO_TamrielTomeSeasonGridEntry_Shared.IsSelectionPending()
    return ZO_TamrielTomeSeasonGridEntry_Shared.isSelectionPending
end

-- Attempts to set the Selection Pending flag that indicates when a grid entry is animating toward the selection of a different Tome season.
-- Returns true if successful.
function ZO_TamrielTomeSeasonGridEntry_Shared.TrySetIsSelectionPending(isSelectionPending)
    if isSelectionPending and ZO_TamrielTomeSeasonGridEntry_Shared.isSelectionPending then
        return false
    end

    ZO_TamrielTomeSeasonGridEntry_Shared.isSelectionPending = isSelectionPending
    return true
end


ZO_TamrielTomeSeasonEndGridEntry_Shared = ZO_InitializingObject:Subclass()

function ZO_TamrielTomeSeasonEndGridEntry_Shared:Initialize(control)
    self.control = control
    control.object = self

    self.highlightBackdrop = control:GetNamedChild("Highlight")
    self.rewardIconTexture = control:GetNamedChild("RewardIcon")
    self.rewardNameLabel = control:GetNamedChild("RewardName")
    self.rewardQuantityLabel = self.rewardIconTexture:GetNamedChild("Quantity")

    self.control.GetRewardData = function()
        return self.data and self.data.rewardData or nil
    end

    self:SetIsHighlighted(false)
end

function ZO_TamrielTomeSeasonEndGridEntry_Shared:IsHighlighted()
    return self.isHighlighted
end

function ZO_TamrielTomeSeasonEndGridEntry_Shared:SetIsHighlighted(isHighlighted)
    if isHighlighted == self.isHighlighted then
        return
    end

    self.isHighlighted = isHighlighted

    if self.highlightBackdrop then
        self.highlightBackdrop:SetHidden(not isHighlighted)
    end
end

function ZO_TamrielTomeSeasonEndGridEntry_Shared:OnMouseEnter()
    if self.owner then
        local PREVIOUS_DATA = nil
        self.owner:SetSelectedData(self.data, PREVIOUS_DATA, self.control)
    end
end

function ZO_TamrielTomeSeasonEndGridEntry_Shared:OnMouseExit()
    if self.owner then
        local CURRENT_DATA = nil
        self.owner:SetSelectedData(CURRENT_DATA, self.data, self.control)
    end
end

function ZO_TamrielTomeSeasonEndGridEntry_Shared:Setup(data, owner)
    data.owner = self
    self.data = data
    self.owner = owner

    self.rewardIconTexture:SetTexture(data.rewardIconTextureFile)
    self.rewardNameLabel:SetText(data.rewardDisplayNameFormatted)
    self.rewardQuantityLabel:SetText(data.rewardQuantityString)
end


ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES =
{
    NONE = 0,
    QUICK_PREVIEW = 1,
    FULL_PREVIEW = 2,
}

-- The default delay that precedes the beginning of an active preview.
ZO_DEFAULT_QUEUED_PREVIEW_DELAY_SECONDS = 0.5
-- The default delay that precedes the ending of the active preview.
ZO_DEFAULT_QUEUED_END_PREVIEW_DELAY_SECONDS = 0.6

ZO_TAMRIEL_TOMES_GRID_LIST_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 5 + ZO_SCROLL_BAR_WIDTH + 5
ZO_TAMRIEL_TOMES_GRID_LIST_HEIGHT = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT * 3 + ZO_TAMRIEL_TOMES_REWARD_DIVIDER_HEIGHT + 40

ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES =
{
    TEMPLATE_TOP_MARGIN = 1,
    TEMPLATE_DIVIDER = 2,
    TEMPLATE_1X_WIDTH = 3,
    TEMPLATE_2X_WIDTH_LEFT = 4,
    TEMPLATE_2X_WIDTH_RIGHT = 5,
    TEMPLATE_2_5X_WIDTH_LEFT = 6,
    TEMPLATE_2_5X_WIDTH_RIGHT = 7,
}

ZO_TAMRIEL_TOMES_REWARD_ENTRY_TEMPLATE_LAYOUT =
{
    -- Row 0
    ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_TOP_MARGIN,

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

local UNLOCKED_PAGE_INDICATOR_INFO =
{
    selectedTexture = "/EsoUI/Art/TamrielTomes/selected_page_outline.dds",
    highlightedTexture = "/EsoUI/Art/TamrielTomes/highlighted_page_backdrop.dds",
}
local LOCKED_PAGE_INDICATOR_INFO =
{
    color = ZO_ColorDef:New(.6, .6, .6, 1),
    highlightedTexture = "/EsoUI/Art/TamrielTomes/highlighted_page_backdrop.dds",
    selectedColor = ZO_ColorDef:New(.75, .75, .75, 1),
    selectedTexture = "/EsoUI/Art/TamrielTomes/selected_page_outline.dds",
}
local UNLOCKED_BONUS_PAGE_INDICATOR_INFO =
{
    icon = "/EsoUI/Art/TamrielTomes/tome_bonus_page_icon.dds",
    highlightedTexture = "/EsoUI/Art/TamrielTomes/highlighted_page_backdrop.dds",
    selectedTexture = "/EsoUI/Art/TamrielTomes/selected_page_outline.dds",
}
local LOCKED_BONUS_PAGE_INDICATOR_INFO =
{
    color = ZO_ColorDef:New(.4, .4, .4, 1),
    icon = "/EsoUI/Art/TamrielTomes/tome_bonus_page_icon.dds",
    highlightedTexture = "/EsoUI/Art/TamrielTomes/highlighted_page_backdrop.dds",
    selectedColor = ZO_ColorDef:New(.55, .55, .55, 1),
    selectedTexture = "/EsoUI/Art/TamrielTomes/selected_page_outline.dds",
}

ZO_TamrielTomesScreen_Shared = ZO_DeferredInitializingObject:Subclass()

ZO_TamrielTomesScreen_Shared:MUST_IMPLEMENT("BeginPreviewInternal")
ZO_TamrielTomesScreen_Shared:MUST_IMPLEMENT("EndPreviewInternal")
ZO_TamrielTomesScreen_Shared:MUST_IMPLEMENT("InitializeKeybindStripDescriptors")
ZO_TamrielTomesScreen_Shared:MUST_IMPLEMENT("ShowIntroScreen")
ZO_TamrielTomesScreen_Shared:MUST_IMPLEMENT("ShowSelectTomeDialog")
ZO_TamrielTomesScreen_Shared:MUST_IMPLEMENT("HideSelectTomeDialog")

function ZO_TamrielTomesScreen_Shared:Initialize(control, scene, templateData)
    self.control = control
    self.templateData = templateData
    self.activePreviewType = ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE
    self.pendingPreviewType = ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE

    ZO_TamrielTomesScreen_Shared.SetPreviousCurrencyAmount(GetPlayerStoredCurrencyAmount(CURT_TOME_POINTS))
    ZO_TamrielTomesScreen_Shared.ClearSeenTiers()

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    self.control:SetHandler("OnUpdate", function(_, ...) self:OnUpdate(...) end)
end

function ZO_TamrielTomesScreen_Shared:OnDeferredInitialize()
    self:InitializeControls()
    self:InitializeKeybindStripDescriptors()
    self:InitializeParticleSystems()
    self:RegisterForEvents()

    if self.buttonsFocus then
        local originalOnFocusChangedFunction = self.buttonsFocus.onFocusChangedFunction

        self.buttonsFocus.onFocusChangedFunction = function(...)
            originalOnFocusChangedFunction(self.buttonsFocus, ...)

            local focusItem = self.buttonsFocus:GetFocusItem()
            self:UpdateTooltip(focusItem and focusItem.control or nil)
        end
    end
end

function ZO_TamrielTomesScreen_Shared:InitializeControls()
    self.pageBackgroundTexture = self.control:GetNamedChild("PageBackground")

    local headerContainer = self.control:GetNamedChild("Header")
    self.headerContainer = headerContainer
    self.titleLabel = headerContainer:GetNamedChild("Title")
    self.subtitleLabel = headerContainer:GetNamedChild("Subtitle")
    local buttonContainer = headerContainer:GetNamedChild("Buttons")
    self.buttonContainer = buttonContainer

    self.challengesButton = buttonContainer:GetNamedChild("ChallengesButton")
    self.challengesButton:SetClickSound(SOUNDS.TAMRIEL_TOMES_NAVIGATE_FORWARD)

    self.upgradeButton = buttonContainer:GetNamedChild("UpgradeButton")
    self.upgradeButton:SetClickSound(SOUNDS.TAMRIEL_TOMES_NAVIGATE_FORWARD)
    self.upgradeButton:SetHandler("OnMouseEnter", function() self:OnUpgradeButtonFocusChanged(true) end, "Tooltip")
    self.upgradeButton:SetHandler("OnMouseExit", function() self:OnUpgradeButtonFocusChanged(false) end, "Tooltip")

    self.selectTomeButton = headerContainer:GetNamedChild("SelectTomeButton")
    self.selectTomeButton:SetClickSound(SOUNDS.TAMRIEL_TOMES_NAVIGATE_FORWARD)
    self.selectTomeButton:SetHandler("OnMouseEnter", function() self:OnSelectTomeSeasonButtonFocusChanged(true) end, "Tooltip")
    self.selectTomeButton:SetHandler("OnMouseExit", function() self:OnSelectTomeSeasonButtonFocusChanged(false) end, "Tooltip")

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

    self.premiumGroupBorderControl = bookContainer:GetNamedChild("PremiumGroupBorder")
    self.premiumGroupBorderLockedTexture = self.premiumGroupBorderControl:GetNamedChild("Locked")

    local pageNavigationControl = bookContainer:GetNamedChild("PageNavigation")
    self.pageNavigation = ZO_PageNavigation:New(pageNavigationControl)
    self.pageNavigation:SetStartingPageNumber(0)
    -- Note that page change sounds are handled manually via the PageChanged callback.
    self.pageNavigation:SetPageChangeSound(nil)
    self.pageNavigation:SetPageChangePreviousSound(nil)
    self.pageNavigation:SetPageChangeNextSound(nil)
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
    gridList:SetIndentAmount(0)
    gridList:SetHeaderPrePadding(0)
    gridList:SetHeaderPostPadding(0)
    gridList:SetYDistanceFromEdgeWhereSelectionCausesScroll(0)

    local function EntryEqualityFunction(left, right)
        if left.dataEntry.Equals and right.dataEntry.Equals then
            return left.dataEntry:Equals(right.dataEntry)
        end
        return false
    end

    local DEFAULT_HIDE_CALLBACK = nil
    local DEFAULT_ENTRIES_CENTERED = nil
    local templateTypes = ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES
    for _, templateTypeIndex in pairs(templateTypes) do
        local typeData = templateData[templateTypeIndex]
        local setupCallback = typeData.setupCallback or ZO_DefaultGridTileEntrySetup
        local resetCallback = typeData.resetCallback or ZO_DefaultGridTileEntryReset
        self.gridList:AddEntryTemplate(typeData.entryTemplate, typeData.width, typeData.height, setupCallback, DEFAULT_HIDE_CALLBACK, resetCallback, 0, 0, DEFAULT_ENTRIES_CENTERED, typeData.isSelectable)
        self.gridList:SetEntryTemplateEqualityFunction(typeData.entryTemplate, EntryEqualityFunction)
    end
end

function ZO_TamrielTomesScreen_Shared:InitializeParticleSystems()
    self.blastParticleSystem = ZO_BlastParticleSystem:New()
    self.blastParticleSystem:SetSound(SOUNDS.TAMRIEL_TOMES_REWARD_PURCHASED)
    self.blastParticleSystem:SetParentControl(self.particleGeneratorPositionControl)
end

function ZO_TamrielTomesScreen_Shared:RegisterForEvents()
    -- eventId, currencyType, currencyLocation, delta, reason, reasonInfo
    local function OnCurrencyUpdated(_, currencyType)
        if not self.control:IsHidden() then
            if currencyType == CURT_TOME_POINTS then
                self:UpdateCurrencyAmount()
                self:UpdatePageNavigation()
            elseif currencyType == CURT_TOME_POINT_CACHES then
                self:UpdateKeybinds()
            end
        end
    end

    self.control:RegisterForEvent(EVENT_CURRENCY_UPDATE, OnCurrencyUpdated)

    local function UpdateGridListAndNavigation()
        if self:IsShowing() then
            self:RefreshGridList()
            self:UpdatePageNavigation()
            self:UpdateSelectTomeButton()
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", UpdateGridListAndNavigation)
    TAMRIEL_TOMES_MANAGER:RegisterCallback("ProgressUpdated", UpdateGridListAndNavigation)
    TAMRIEL_TOMES_MANAGER:RegisterCallback("RewardsUpdated", UpdateGridListAndNavigation)

    local function UpdateAvailableTomes()
        if self:IsShowing() then
            self:UpdateSelectTomeButton()
        end
    end

    TAMRIEL_TOMES_MANAGER:RegisterCallback("AvailableTomesChanged", UpdateAvailableTomes)

    local function OnRewardTrackRewardClaimed(_, rewardTrackType, rewardTrackId, rewardTrackTier, rewardTrackComponent, rewardIndex, isFallback)
        if self.control:IsHidden() then
            return
        end

        if rewardTrackType ~= REWARD_TRACK_TYPE_TAMRIEL_TOMES then
            return
        end

        self:RebuildGridList()

        local gridTile = self:GetTileByTamrielTomesRewardIndex(rewardTrackId, rewardTrackTier, rewardTrackComponent, rewardIndex)
        if gridTile then
            self:ShowClaimedRewardFlair(gridTile)
        end
    end

    self.control:RegisterForEvent(EVENT_REWARD_TRACK_REWARD_CLAIMED, OnRewardTrackRewardClaimed)

    local function OnSelectedTomeChanged(tomeId)
        local FORCE_UPDATE = true
        if self:IsShowing() then
            self:HideSelectTomeDialog()
            self:Refresh()
            self:UpdateSeenTiers(FORCE_UPDATE)
        end

        -- Order matters:
        do
            -- The Time Remaining label only shows when viewing the currently active season's Tamriel Tome.
            local isTomeActive = TAMRIEL_TOMES_MANAGER:IsTomeActive(tomeId)
            self.subtitleLabel:SetHidden(not isTomeActive)

            if isTomeActive then
                -- Force the Time Remaining label to update immediately.
                self:UpdateTimeRemaining(GetFrameTimeSeconds(), FORCE_UPDATE)
            end
        end
    end

    TAMRIEL_TOMES_MANAGER:RegisterCallback("SelectedTomeChanged", OnSelectedTomeChanged)

    local function UpdateButtonsAndPageNavigation()
        if self:IsShowing() then
            self:UpdateButtons()
            self:UpdatePageNavigation()
        end
    end

    TAMRIEL_TOMES_MANAGER:RegisterCallback("DirectPurchaseDataUpdated", UpdateButtonsAndPageNavigation)
    DIRECT_PURCHASE_MANAGER:RegisterCallback("SettingsUpdated", UpdateButtonsAndPageNavigation)
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
    if tomeId == self.selectedTomeId then
        return
    end

    self.selectedTomeId = tomeId
    self.selectedTomeData = ZO_TamrielTomeData:New(tomeId)
    self.selectedTomeIndex = self.selectedTomeData:GetTamrielTomeIndex()
    self.currentRewardTrackId = self.selectedTomeData:GetRewardTrackId()
    self.currentTierIndex = 1

    self:UpdateButtons()
    self:UpdatePageNavigation()
end

function ZO_TamrielTomesScreen_Shared:CanSelectTome()
    return TAMRIEL_TOMES_MANAGER:GetNumAvailableTomes() > 1
end

function ZO_TamrielTomesScreen_Shared:UpdateSelectTomeButton()
    local isEnabled = self:CanSelectTome()
    self.selectTomeButton:SetState(isEnabled and BSTATE_NORMAL or BSTATE_DISABLED)
    self.selectTomeButton:SetEnabled(isEnabled)
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:UpdateFocusAreas()
    -- Can be overridden
end

function ZO_TamrielTomesScreen_Shared:MarkCurrentTierAsSeenIfUnlocked()
    local currentTier = self.pageNavigation:GetCurrentPage() or 0
    local highestUnlockedTier = self:GetHighestUnlockedPage()
    if currentTier <= highestUnlockedTier then
        ZO_TamrielTomesScreen_Shared.AddSeenTier(currentTier)
    end
end

function ZO_TamrielTomesScreen_Shared:RefreshSeenTiers()
    self.pageNavigation:ClearHighlightedPages()

    local highestUnlockedTier = self:GetHighestUnlockedPage()
    local seenTiers = ZO_TamrielTomesScreen_Shared.GetSeenTiers()
    local numTiers = self:GetNumRewardPages()
    for tier = 1, numTiers do
        if tier <= highestUnlockedTier and not seenTiers[tier] then
            -- This page has not yet been seen.
            self.pageNavigation:SetHighlightedPage(tier, true)
        end
    end

    self.pageNavigation:RefreshPageIndicators()
end

function ZO_TamrielTomesScreen_Shared:UpdateSeenTiers(forceUpdate)
    if ZO_TamrielTomesScreen_Shared.AreSeenTiersInitialized() and not forceUpdate then
        return
    end

    ZO_TamrielTomesScreen_Shared.ClearSeenTiers()

    local highestUnlockedTier = self:GetHighestUnlockedPage()
    for existingTier = 1, highestUnlockedTier do
        ZO_TamrielTomesScreen_Shared.AddSeenTier(existingTier)
    end

    self:RefreshSeenTiers()
    ZO_TamrielTomesScreen_Shared.SetAreSeenTiersInitialized(true)
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

function ZO_TamrielTomesScreen_Shared:CompareRewardDataIndices(rewardData1, rewardData2)
    if not (rewardData1 and rewardData2) then
        return 0
    end

    local component1 = rewardData1:GetRewardComponent()
    local component2 = rewardData2:GetRewardComponent()
    if component1 < component2 then
        return -1
    end
    if component2 < component1 then
        return 1
    end

    local index1 = rewardData1:GetRewardIndex()
    local index2 = rewardData2:GetRewardIndex()
    if index1 < index2 then
        return -1
    end
    if index2 < index1 then
        return 1
    end

    return 0
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

function ZO_TamrielTomesScreen_Shared:GetTamrielTomesRewardObject(tamrielTomesRewardData)
    local tileControl = self:GetTileByTamrielTomesRewardData(tamrielTomesRewardData)
    if tileControl then
        local rewardObject = tileControl.object.rewardControl.object
        return rewardObject
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
    local previousSelectedData = self:GetSelectedTamrielTomesRewardData()
    local currentSelectedData = nil
    self.gridList:ClearGridList()

    local entryData = self:GetFirstTamrielTomesRewardData()
    for entryIndex, entryTemplate in ipairs(ZO_TAMRIEL_TOMES_REWARD_ENTRY_TEMPLATE_LAYOUT) do
        if not entryData then
            -- End of rewards reached.
            break
        end

        if entryTemplate == ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_TOP_MARGIN or entryTemplate == ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_DIVIDER then
            self:AddGridEntryInternal({}, entryTemplate)
        else
            if previousSelectedData and previousSelectedData:Equals(entryData) then
                currentSelectedData = entryData
            end
            self:AddGridEntryInternal(entryData, entryTemplate)
            entryData = self:GetNextTamrielTomesRewardData()
        end
    end

    -- Order matters
    self.gridList:CommitGridList()
    if currentSelectedData then
        self.gridList:SelectData(currentSelectedData)
        self:SetSelectedTamrielTomesRewardData(currentSelectedData)
    end
    self:RefreshUnlockRequirements()
    self:RefreshSeenTiers()
    self:UpdateCurrencyAmount()
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:Refresh()
    local selectedTomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    self:UpdateTomeInfo(selectedTomeId)

    local rewardTrackId = self.currentRewardTrackId
    local titleText = GetRewardTrackDisplayName(rewardTrackId)
    self.titleLabel:SetText(titleText)

    local currencyBonusPercentage = GetTomePointGainBonusPercentage()
    local hasCurrencyBonus = currencyBonusPercentage > 0
    self.currencyBonusContainer:SetHidden(not hasCurrencyBonus)
    self.currencyBalanceBackdrop:SetHidden(hasCurrencyBonus)
    self.currencyFullBackdrop:SetHidden(not hasCurrencyBonus)
    if hasCurrencyBonus then
        self.currencyBonusPercentLabel:SetText(zo_strformat(SI_TAMRIEL_TOMES_CURRENCY_BONUS_PERCENTAGE_LABEL, currencyBonusPercentage))
    end

    self:RefreshUnlockRequirements()
    self:RefreshPageBackground()
    self:RefreshNewIndicators()
    self:RefreshSeenTiers()
    self:UpdateCurrencyAmount()
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:RefreshNewIndicators()
    local challengesButtonLabelText = GetString(SI_TAMRIEL_TOMES_VIEW_CHALLENGES_LABEL)
    if TIMED_ACTIVITIES_MANAGER:HasClaimableTimedActivities() or TIMED_ACTIVITIES_MANAGER:HasNewTimedActivities() then
        challengesButtonLabelText = string.format("%s %s", zo_iconFormat("/esoui/art/miscellaneous/new_icon.dds", 32, 32), challengesButtonLabelText)
    end
    self.challengesButton:SetText(challengesButtonLabelText)
end

function ZO_TamrielTomesScreen_Shared:RefreshGridList()
    self.gridList:RefreshGridList()
    self:RefreshUnlockRequirements()
    self:RefreshPageBackground()
    self:RefreshNewIndicators()
    self:RefreshSeenTiers()
    self:UpdateCurrencyAmount()
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:RefreshPageBackground()
    if self:IsCurrentBasePageLocked() then
        self.pageBackgroundTexture:SetColor(0.9, 0.9, 0.9, 1.0)
    else
        self.pageBackgroundTexture:SetColor(1.0, 1.0, 1.0, 1.0)
    end
end

function ZO_TamrielTomesScreen_Shared:RefreshUnlockRequirements()
    self.premiumGroupBorderLockedTexture:SetHidden(true)
    self.unlockPointsRequired:SetHidden(true)

    if self.selectedTomeData then
        -- Show the message that indicates how many additional Tome Points must be
        -- earned to unlock the next locked page, if any page is still locked.
        local nextPage = (self.selectedTomeData:GetCurrentTier() or 0) + 1
        local currentPage = self.pageNavigation:GetCurrentPage() or 0
        local tier = zo_max(nextPage, currentPage)
        local unlockPointsRemaining = self.selectedTomeData:GetCostToProgressToTier(tier)
        if unlockPointsRemaining > 0 then
            local unlockPointsRemainingString = ZO_Currency_FormatPlatform(CURT_TOME_POINTS, unlockPointsRemaining, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
            local unlockPointsRequiredString
            local numBaseTiers = self.selectedTomeData:GetNumBaseTiers()
            if tier <= numBaseTiers then
                unlockPointsRequiredString = zo_strformat(SI_TAMRIEL_TOMES_PAGE_UNLOCK_REQUIREMENT, unlockPointsRemainingString, tostring(tier))
            else
                local bonusTier = tier - numBaseTiers
                unlockPointsRequiredString = zo_strformat(SI_TAMRIEL_TOMES_BONUS_PAGE_UNLOCK_REQUIREMENT, unlockPointsRemainingString, tostring(bonusTier))
            end

            self.unlockPointsRequired:SetText(unlockPointsRequiredString)
            self.unlockPointsRequired:SetHidden(false)
        end

        -- Show the lock icon next to the Premium section caption if the premium
        -- component is not accessible.
        local hasPremiumComponent = self.selectedTomeData:HasAccessToComponent(REWARD_TRACK_COMPONENT_SECONDARY)
        self.premiumGroupBorderLockedTexture:SetHidden(hasPremiumComponent)
    end
end

function ZO_TamrielTomesScreen_Shared:GetSelectTomeTooltip()
    if self:CanSelectTome() then
        return GetString(SI_TAMRIEL_TOMES_SELECT_TAMRIEL_TOME_TOOLTIP)
    else
        return GetString(SI_TAMRIEL_TOMES_NO_OTHER_TAMRIEL_TOMES_AVAILABLE_TOOLTIP)
    end
end

function ZO_TamrielTomesScreen_Shared:UpdateTooltip(focusControl)
    ClearTooltip(InformationTooltip)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

    if hidden or not self:IsShowing() then
        return
    end

    local message = nil
    if focusControl == self.upgradeButton then
        message = TAMRIEL_TOMES_MANAGER:GetPurchaseDisabledMessage()
    elseif focusControl == self.selectTomeButton then
        message = self:GetSelectTomeTooltip()
    end

    if not message then
        return
    end

    if IsInGamepadPreferredMode() then
        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_RIGHT_TOOLTIP, message)
    else
        InitializeTooltip(InformationTooltip, self.upgradeButton, RIGHT)
        InformationTooltip:AddLine(message, "", ZO_WHITE:UnpackRGB())
    end
end

function ZO_TamrielTomesScreen_Shared:OnUpgradeButtonFocusChanged(hasFocus)
    local focusControl = nil
    if hasFocus then
        focusControl = self.upgradeButton
    end
    self:UpdateTooltip(focusControl)
end

function ZO_TamrielTomesScreen_Shared:OnSelectTomeSeasonButtonFocusChanged(hasFocus)
    local focusControl = nil
    if hasFocus then
        focusControl = self.selectTomeButton
    end
    self:UpdateTooltip(focusControl)
end

function ZO_TamrielTomesScreen_Shared:UpdateButtons()
    local isActiveTomeSelected = TAMRIEL_TOMES_MANAGER:IsActiveTomeSelected()
    local isEnabled = isActiveTomeSelected and TAMRIEL_TOMES_MANAGER:GetPurchaseDisabledMessage() == nil
    self.upgradeButton:SetEnabled(isEnabled)

    self:UpdateSelectTomeButton()
end

function ZO_TamrielTomesScreen_Shared:BeginClaimReward(tamrielTomesRewardData)
    local rewardObject = self:GetTamrielTomesRewardObject(tamrielTomesRewardData)
    if not rewardObject then
        internalasset(false, "Tile control not found for Tamriel Tomes Reward Data.")
        return
    end

    rewardObject:BeginClaimReward()
    PlaySound(SOUNDS.TAMRIEL_TOMES_REWARD_CLAIM_START)
end

function ZO_TamrielTomesScreen_Shared:EndClaimReward(tamrielTomesRewardData)
    local rewardObject = self:GetTamrielTomesRewardObject(tamrielTomesRewardData)
    if not rewardObject then
        internalasset(false, "Tile control not found for Tamriel Tomes Reward Data.")
        return
    end

    rewardObject:EndClaimReward()
end

function ZO_TamrielTomesScreen_Shared:ShouldHideKeybinds()
    return not self.scene:IsShowing()
end

function ZO_TamrielTomesScreen_Shared:UpdateKeybinds()
    local hideKeybinds = self:ShouldHideKeybinds()
    self:SetKeybindsHidden(hideKeybinds)
end

function ZO_TamrielTomesScreen_Shared:SetKeybindsHidden(hidden)
    if hidden then
        if self.areKeybindsAdded then
            self.areKeybindsAdded = false
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end

        return
    end

    KEYBIND_STRIP:RemoveDefaultExit()

    if self.areKeybindsAdded then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    else
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self.areKeybindsAdded = true
    end
end

function ZO_TamrielTomesScreen_Shared:SetIsTamrielTomesRewardPreviewing(tamrielTomesRewardData, isPreviewing)
    local tile = self:GetTileByTamrielTomesRewardData(tamrielTomesRewardData)
    if not tile then
        return
    end

    tile.object:GetReward():SetPreviewing(isPreviewing)
end

-- Indicates whether this scene should retain the current preview when hidden.
function ZO_TamrielTomesScreen_Shared:ShouldRetainPreview()
    return false
end

function ZO_TamrielTomesScreen_Shared:OnHiding()
    -- Order matters
    if self:ShouldRetainPreview() then
        self:ClearQueuedEndPreview()
    else
        self:ClearQueuedEndPreview()
        self:UpdateKeybinds()
    end
end

function ZO_TamrielTomesScreen_Shared:OnShowing()
    if self:GetActivePreviewType() == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
        -- If a Full Preview was active, downgrade it to a Quick Preview.
        self.activePreviewType = ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW
    end

    self:Refresh()
    self:RefreshGridList()
    self:UpdateSeenTiers()

    DIRECT_PURCHASE_MANAGER:RequestCatalog()
end

function ZO_TamrielTomesScreen_Shared:OnShown()
    local selectedTomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    TAMRIEL_TOMES_MANAGER:MarkTomeSeen(selectedTomeId)

    TriggerTutorial(TUTORIAL_TRIGGER_TAMRIEL_TOMES_OPENED)

    self:UpdateCurrencyAmount()
end

function ZO_TamrielTomesScreen_Shared:OnSelectedTamrielTomesRewardDataChanged(previousData, newData, previousTileControl, newTileControl)
    if not (newData and newTileControl and newTileControl.object and newTileControl.object.rewardData and newTileControl.object.rewardData:CanPreviewReward()) then
        if self:ShouldRetainPreview() then
            return
        end

        self:QueueEndPreview(ZO_DEFAULT_QUEUED_PREVIEW_DELAY_SECONDS)
        self:ClearQueuedPreview()
        return
    end

    local tamrielTomesRewardData = newTileControl.object.rewardData
    self:QueuePreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW, tamrielTomesRewardData:GetRewardData(), tamrielTomesRewardData, ZO_DEFAULT_QUEUED_PREVIEW_DELAY_SECONDS)
end

function ZO_TamrielTomesScreen_Shared:UpdateTimeRemaining(currentFrameTimeSeconds, forceUpdate)
    if (not self.nextTimeRemainingUpdateS or currentFrameTimeSeconds > self.nextTimeRemainingUpdateS) and not self.subtitleLabel:IsHidden() then
        
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
    local tomeData = self.selectedTomeData
    if tomeData then
        return tomeData:GetNumBaseTiers()
    end
    return 0
end

function ZO_TamrielTomesScreen_Shared:GetNumBonusRewardPages()
    local tomeData = self.selectedTomeData
    if tomeData then
        return tomeData:GetNumBonusTiers()
    end
    return 0
end

function ZO_TamrielTomesScreen_Shared:GetNumRewardPages()
    local tomeData = self.selectedTomeData
    if tomeData then
        return tomeData:GetNumTotalTiers()
    end
    return 0
end

function ZO_TamrielTomesScreen_Shared:GetHighestUnlockedPage()
    return self.selectedTomeData and self.selectedTomeData:GetCurrentTier() or 0
end

function ZO_TamrielTomesScreen_Shared:IsCurrentBasePageLocked()
    local currentPage = self.currentTierIndex or 0
    local maxUnlockedPage = self:GetHighestUnlockedPage()
    return currentPage > maxUnlockedPage
end

function ZO_TamrielTomesScreen_Shared:OnPageChanged(pageNumber, direction)
    -- Order matters
    local previousTierIndex = self.currentTierIndex
    self.currentTierIndex = zo_clamp(pageNumber, 1, self:GetNumRewardPages())
    local hasPageChanged = self.currentTierIndex ~= previousTierIndex
    if hasPageChanged then
        self:EndPreview()
    end

    local isShowing = not self.fragment:IsHidden()
    if isShowing then
        -- Applies to transitions between pages and between pages and the intro.
        PlaySound(SOUNDS.TAMRIEL_TOMES_PAGE_FLIPPED)
    end

    if pageNumber == 0 then
        self:ShowIntroScreen()
        return
    end

    if isShowing then
        -- Applies to transitions between pages only.
        if direction and direction < 0 then
            PlaySound(SOUNDS.TAMRIEL_TOMES_PAGE_FLIPPED_BACK)
        else
            PlaySound(SOUNDS.TAMRIEL_TOMES_PAGE_FLIPPED_FORWARD)
        end
    end

    -- Order matters
    local RETAIN_SELECTION = not hasPageChanged
    self:RebuildGridList(RETAIN_SELECTION)
    self:RefreshUnlockRequirements()
    self:RefreshPageBackground()
    self:MarkCurrentTierAsSeenIfUnlocked()
    self:RefreshSeenTiers()
end

function ZO_TamrielTomesScreen_Shared:UpdatePageNavigation()
    local numRewardPages = self:GetNumRewardPages()
    local pageNavigation = self.pageNavigation

    -- Order matters
    local pageToSelect = pageNavigation:GetCurrentPage()
    if pageToSelect == nil or pageToSelect == 0 or pageToSelect > numRewardPages then
        pageToSelect = 1
    end
    pageNavigation:Clear()

    -- Add initial intro page (page 0).
    pageNavigation:AddPage()

    -- Add page 1 through n.
    local numBaseRewardPages = self:GetNumBaseRewardPages()
    local highestUnlockedPage = self:GetHighestUnlockedPage()
    for pageIndex = 1, numBaseRewardPages do
        if pageIndex <= highestUnlockedPage then
            pageNavigation:AddPage(UNLOCKED_PAGE_INDICATOR_INFO)
        else
            pageNavigation:AddPage(LOCKED_PAGE_INDICATOR_INFO)
        end
    end

    -- Add bonus pages, if any.
    local numBonusRewardPages = self:GetNumBonusRewardPages()
    for pageIndex = 1, numBonusRewardPages do
        if pageIndex + numBaseRewardPages <= highestUnlockedPage then
            pageNavigation:AddPage(UNLOCKED_BONUS_PAGE_INDICATOR_INFO)
        else
            pageNavigation:AddPage(LOCKED_BONUS_PAGE_INDICATOR_INFO)
        end
    end

    -- Order matters
    pageNavigation:Commit(pageToSelect)
    self:RefreshSeenTiers()
end

function ZO_TamrielTomesScreen_Shared:UpdateCurrencyAmount()
    if not self:IsShowing() then
        return
    end

    local currencyAmount = GetPlayerStoredCurrencyAmount(CURT_TOME_POINTS)
    local previousCurrencyAmount = ZO_TamrielTomesScreen_Shared.GetPreviousCurrencyAmount()
    if currencyAmount ~= previousCurrencyAmount then
        -- The currency amount has changed.
        self.currentCurrencyAmount = currencyAmount
        ZO_TamrielTomesScreen_Shared.SetPreviousCurrencyAmount(currencyAmount)
        self.currencyAmountTransitionManager:SetValue(currencyAmount)
        PlaySound(SOUNDS.TAMRIEL_TOMES_TOME_POINTS_ROLLING_STARTED)
    elseif currencyAmount ~= self.currentCurrencyAmount then
        -- The currency amount has changed but that change was presented in the opposing UI view (Gamepad vs. Keyboard).
        self.currentCurrencyAmount = currencyAmount
        self.currencyAmountTransitionManager:SetValueImmediately(currencyAmount)
    end
end

-- Begins a preview of type 'previewType' for 'tamrielTomesRewardData'.
-- Returns true if the preview was successfully shown.
function ZO_TamrielTomesScreen_Shared:BeginPreviewTamrielTomesRewardData(previewType, tamrielTomesRewardData)
    assert(tamrielTomesRewardData and tamrielTomesRewardData:IsInstaneOf(ZO_TamrielTomesRewardData), "A valid instance of ZO_TamrielTomesRewardData is required.")

    local rewardData = tamrielTomesRewardData:GetRewardData()
    if not rewardData then
        return false
    end

    return self:BeginPreview(previewType, rewardData, tamrielTomesRewardData)
end

function ZO_TamrielTomesScreen_Shared:GetActivePreviewTamrielTomesRewardData()
    local previewType, rewardData, previewKey = self:GetActivePreviewInfo()
    if previewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE then
        return nil
    end

    if not (rewardData and previewKey) then
        return nil
    end

    -- In the context of Tamriel Tomes' reward previews, 'previewKey' is the
    -- ZO_TamrielTomesRewardData instance associated with the reward being previewed.
    return previewKey
end

function ZO_TamrielTomesScreen_Shared:GetActivePreviewRewardTileControl()
    local tamrielTomesRewardData = self:GetActivePreviewTamrielTomesRewardData()
    if not tamrielTomesRewardData then
        return nil
    end

    local tileControl = self:GetTileByTamrielTomesRewardData(tamrielTomesRewardData)
    return tileControl
end

function ZO_TamrielTomesScreen_Shared:OnBeginPreview(previewType, rewardData, previewKey)
    -- 'previewKey' is the ZO_TamrielTomeRewardData instance.
    if previewKey then
        self:SetIsTamrielTomesRewardPreviewing(previewKey, true)
    end
end

function ZO_TamrielTomesScreen_Shared:OnEndPreview(previewType, rewardData, previewKey)
    -- 'previewKey' is the ZO_TamrielTomeRewardData instance.
    if previewKey then
        self:SetIsTamrielTomesRewardPreviewing(previewKey, false)
    end
end

-- Begins a preview of type 'previewType' of 'rewardData' (including an optional 'previewKey' for reference).
-- Returns true if the preview was successfully shown.
function ZO_TamrielTomesScreen_Shared:BeginPreview(previewType, rewardData, previewKey)
    if not self:CanBeginPreview(previewType, rewardData) then
        return false
    end

    if self.activePreviewRewardData and not self.AreRewardsEqual(rewardData, self.activePreviewRewardData) then
        self.GetPreviewSystem():EndCurrentPreview()
    end

    -- Order matters
    self.activePreviewEndTimeS = nil
    self.activePreviewKey = previewKey
    self.activePreviewRewardData = rewardData
    self.activePreviewType = previewType
    self:BeginPreviewInternal()
    self:OnBeginPreview(previewType, rewardData, previewKey)
    self:UpdateKeybinds()
    return true
end

-- Returns true if a preview of type 'previewType' can be shown right now for 'rewardData'.
function ZO_TamrielTomesScreen_Shared:CanBeginPreview(previewType, rewardData)
    assert(previewType and previewType ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE, "A valid previewType is required.")

    if self.ComparePreviewTypePriorities(previewType, self.activePreviewType) < 0 and not self.activePreviewEndTimeS then
        -- The requested preview type is suppressed by the active preview type.
        return false
    end

    if not self.CanPreviewReward(rewardData) then
        return false
    end

    if previewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW and rewardData:GetRewardType() == REWARD_ENTRY_TYPE_REWARD_LIST then
        -- Reward lists must be full previewed in order to show the list.
        return false
    end

    return true
end

function ZO_TamrielTomesScreen_Shared:ClearQueuedEndPreview()
    self.activePreviewEndTimeS = nil
end

function ZO_TamrielTomesScreen_Shared:ClearQueuedPreview()
    self.pendingPreviewKey = nil
    self.pendingPreviewRewardData = nil
    self.pendingPreviewStartTimeS = nil
    self.pendingPreviewType = ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE
end

function ZO_TamrielTomesScreen_Shared:EndPreview()
    -- Order matters
    local activePreviewType = self.activePreviewType
    local activePreviewRewardData = self.activePreviewRewardData
    local activePreviewKey = self.activePreviewKey
    self.activePreviewEndTimeS = nil
    self.activePreviewKey = nil
    self.activePreviewRewardData = nil
    self.activePreviewType = ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE
    self:OnEndPreview(activePreviewType, activePreviewRewardData, activePreviewKey)

    -- Order matters
    self:EndPreviewInternal()
    self:SetPreviewActionsHidden(true)
    self:SetPreviewVariationsHidden(true)
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Shared:GetActivePreviewRewardData()
    return self.activePreviewRewardData
end

function ZO_TamrielTomesScreen_Shared:GetActivePreviewEndTimeSeconds()
    return self.activePreviewEndTimeS
end

function ZO_TamrielTomesScreen_Shared:GetActivePreviewInfo()
    return self.activePreviewType, self.activePreviewRewardData, self.activePreviewKey
end

function ZO_TamrielTomesScreen_Shared:GetActivePreviewType()
    return self.activePreviewType
end

function ZO_TamrielTomesScreen_Shared:GetPendingPreviewInfo()
    return self.pendingPreviewType, self.pendingPreviewRewardData, self.pendingPreviewKey, self.pendingPreviewStartTimeS
end

function ZO_TamrielTomesScreen_Shared:OnUpdate(currentFrameTimeS)
    self:UpdatePreview(currentFrameTimeS)
    self:UpdateTimeRemaining(currentFrameTimeS)
end

-- Queues the end of the active preview.
function ZO_TamrielTomesScreen_Shared:QueueEndPreview(delaySeconds)
    assert(tonumber(delaySeconds), "A valid delaySeconds is required.")

    if self:GetActivePreviewType() == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE then
        return
    end

    self.activePreviewEndTimeS = GetFrameTimeSeconds() + delaySeconds
end

-- Queues a preview of type 'previewType' of 'rewardData' (including an optional 'previewKey' for reference) to begin in 'delaySeconds'.
-- Returns true if the preview was successfully queued.
function ZO_TamrielTomesScreen_Shared:QueuePreview(previewType, rewardData, previewKey, delaySeconds)
    assert(previewType and previewType ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.NONE, "A valid previewType is required.")
    assert(tonumber(delaySeconds), "A valid delaySeconds is required.")

    if rewardData == self.activePreviewRewardData then
        -- The request is for the same reward; just retain the active preview.
        self:ClearQueuedPreview()
        self:ClearQueuedEndPreview()

        -- Update the preview details in the event that this request came from a different source
        -- or the preview type itself has changed.
        self.activePreviewKey = previewKey
        self.activePreviewType = previewType
        self:BeginPreviewInternal()

        return true
    end

    if not self.CanPreviewReward(rewardData) then
        return false
    end

    self.pendingPreviewKey = previewKey
    self.pendingPreviewRewardData = rewardData
    self.pendingPreviewStartTimeS = GetFrameTimeSeconds() + delaySeconds
    self.pendingPreviewType = previewType
    return true
end

function ZO_TamrielTomesScreen_Shared:SetPreviewActionsHidden(hidden)
    local previewSystem = self.GetPreviewSystem()
    if hidden then
        previewSystem:SetActionControlsHidden(true)
    else
        previewSystem:SetupActionCarousel()
    end
end

function ZO_TamrielTomesScreen_Shared:SetPreviewVariationsHidden(hidden)
    local previewSystem = self.GetPreviewSystem()
    if hidden then
        previewSystem:SetVariationControlsHidden(true)
    else
        previewSystem:SetupVariationControls()
    end
end

function ZO_TamrielTomesScreen_Shared:SetPreviewControlsHidden(hidden)
    self:SetPreviewActionsHidden(hidden)
    self:SetPreviewVariationsHidden(hidden)
end

function ZO_TamrielTomesScreen_Shared:ShouldActivePreviewShowFullPreview()
    local previewType = self:GetActivePreviewType()
    if previewType ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
        return false
    end

    local previewEndTimeS = self:GetActivePreviewEndTimeSeconds()
    if previewEndTimeS then
        return false
    end

    local rewardData = self:GetActivePreviewRewardData()
    if not rewardData or rewardData:GetRewardType() == REWARD_ENTRY_TYPE_REWARD_LIST then
        return false
    end

    return true
end

function ZO_TamrielTomesScreen_Shared:ShouldHidePreviewControls()
    local previewType = self:GetActivePreviewType()
    if previewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
        local previewRewardData = self:GetActivePreviewRewardData()
        if previewRewardData and previewRewardData:GetRewardType() ~= REWARD_ENTRY_TYPE_REWARD_LIST then
            return false
        end
    end

    return true
end

function ZO_TamrielTomesScreen_Shared:RefreshPreviewControls()
    local hidden = self:ShouldHidePreviewControls()
    self:SetPreviewControlsHidden(hidden)
end

function ZO_TamrielTomesScreen_Shared:UpdatePreview(currentFrameTimeS)
    if not self:IsShowing() then
        return
    end

    -- Process a queued preview request prior to a queued end preview request
    -- to ensure that a follow up preview is not cleared as a result of the
    -- scheduled termination of the previous preview.

    if self.pendingPreviewStartTimeS and currentFrameTimeS >= self.pendingPreviewStartTimeS then
        -- Order matters
        local previewKey = self.pendingPreviewKey
        local rewardData = self.pendingPreviewRewardData
        local previewType = self.pendingPreviewType
        self:ClearQueuedPreview()
        self:BeginPreview(previewType, rewardData, previewKey)
    elseif self.activePreviewEndTimeS and currentFrameTimeS >= self.activePreviewEndTimeS then
        self:EndPreview()
    end
end

-- Static methods

-- Returns true if 'rewardData' can be previewed.
function ZO_TamrielTomesScreen_Shared.CanPreviewReward(rewardData)
    assert(rewardData and rewardData:IsInstanceOf(ZO_RewardData), "A valid instance of ZO_RewardData is required.")

    local rewardType = rewardData:GetRewardType()
    if rewardType == REWARD_ENTRY_TYPE_REWARD_LIST then
        return true
    end

    local rewardId = rewardData:GetRewardId()
    if not CanPreviewReward(rewardId) then
        return false
    end

    return true
end

-- Returns a positive integer if previewType1 is a higher priority than previewType2;
-- returns a negative integer if previewType1 is a lower priority than previewType2;
-- returns zero if both preview types are of equal priority.
function ZO_TamrielTomesScreen_Shared.ComparePreviewTypePriorities(previewType1, previewType2)
    if previewType1 < previewType2 then
        return -1
    end

    if previewType1 > previewType2 then
        return 1
    end

    return 0
end

function ZO_TamrielTomesScreen_Shared.GetPreviewSystem()
    return SYSTEMS:GetObject("itemPreview")
end

function ZO_TamrielTomesScreen_Shared.GetPreviousCurrencyAmount()
    return ZO_TamrielTomesScreen_Shared.previousCurrencyAmount
end

function ZO_TamrielTomesScreen_Shared.SetPreviousCurrencyAmount(amount)
    ZO_TamrielTomesScreen_Shared.previousCurrencyAmount = amount
end

function ZO_TamrielTomesScreen_Shared.AddSeenTier(tier)
    local seenTiers = ZO_TamrielTomesScreen_Shared.GetSeenTiers()
    seenTiers[tier] = true
end

function ZO_TamrielTomesScreen_Shared.AreSeenTiersInitialized()
    return ZO_TamrielTomesScreen_Shared.areSeenTiersInitialized
end

function ZO_TamrielTomesScreen_Shared.ClearSeenTiers()
    local seenTiers = ZO_TamrielTomesScreen_Shared.GetSeenTiers()
    ZO_ClearTable(seenTiers)
end

function ZO_TamrielTomesScreen_Shared.GetSeenTiers()
    local seenTiers = ZO_TamrielTomesScreen_Shared.seenTiers
    if not seenTiers then
        seenTiers = {}
        ZO_TamrielTomesScreen_Shared.seenTiers = seenTiers
    end
    return seenTiers
end

function ZO_TamrielTomesScreen_Shared.AreRewardsEqual(reward1, reward2)
    if reward1 then
        if not reward2 then
            return false
        end

        if reward1:GetRewardId() ~= reward2:GetRewardId() then
            return false
        end
    elseif reward2 then
        return false
    end

    return true
end

function ZO_TamrielTomesScreen_Shared.SetAreSeenTiersInitialized(initialized)
    ZO_TamrielTomesScreen_Shared.areSeenTiersInitialized = initialized
end


ZO_TamrielTomeSeasonEndDialog_Shared = ZO_InitializingObject:Subclass()

function ZO_TamrielTomeSeasonEndDialog_Shared:Initialize(control)
    self.control = control
    control.object = self

    self:InitializeControls()
    self:InitializeGridList()
    self:InitializeDialog()
end

function ZO_TamrielTomeSeasonEndDialog_Shared:InitializeControls()
    self.summaryControl = self.control:GetNamedChild("Summary")
    self.seasonImageTexture = self.summaryControl:GetNamedChild("SeasonImage")
    self.seasonNameLabel = self.summaryControl:GetNamedChild("SeasonName")
    self.seasonRewardCountLabel = self.summaryControl:GetNamedChild("SeasonRewardCount")
    self.premiumExplanationLabel = self.summaryControl:GetNamedChild("PremiumExplanation")
    self.tomePointRolloverLabel = self.summaryControl:GetNamedChild("TomePointRollover")
    self.goldRolloverLabel = self.summaryControl:GetNamedChild("GoldRollover")
    self.claimedRewardsLabel = self.summaryControl:GetNamedChild("ClaimedRewards")
    self.dividerControl = self.summaryControl:GetNamedChild("Divider")
    self.gridControl = self.control:GetNamedChild("RewardsGrid")
end

function ZO_TamrielTomeSeasonEndDialog_Shared:InitializeDialog()
    local control = self.control
    local dialogData =
    {
        title =
        {
            text = SI_TAMRIEL_TOMES_SEASON_END_DIALOG_TITLE,
        },

        mainText =
        {
            text = "",
        },

        setup = function(dialog, data)
            -- Order matters:
            dialog.object = self
            self:UpdateSeason()
            self:BuildGridList()

            SetTamrielTomesEndOfSeasonRecapSeen(true)
        end,

        customControl = control,

        buttons =
        {
            {
                control = control:GetNamedChild("Close"),
                keybind = "DIALOG_PRIMARY",
                text = SI_TAMRIEL_TOMES_SEASON_END_DIALOG_CONTINUE,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },
        },
    }

    if self.templateData.isGamepad then
        dialogData.gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
        }
    end

    ZO_Dialogs_RegisterCustomDialog(self.dialogName, dialogData)
end

do
    local function SetupBulletLabel(labelControl, text)
        if text and text ~= "" then
            labelControl:SetText(text)
            labelControl:SetHidden(false)
        else
            labelControl:SetText("")
            labelControl:SetHidden(true)
        end
    end

    function ZO_TamrielTomeSeasonEndDialog_Shared:UpdateSeason()
        self.tomeId = GetTamrielTomesEndOfSeasonRecapTamrielTomeId()
        self.rewardTrackId = GetTamrielTomesEndOfSeasonRecapRewardTrackId()
        self.numClaimedRewards, self.numRewards = ZO_TamrielTomeData.GetRewardStatisticsForTamrielTome(self.tomeId)
        self.numTomePointsRolledOver = GetTomePointsRolledOverIntoNextSeason()
        self.numTomePointsConvertedToGold = GetEndOfSeasonTomePointsConvertedToGold()
        self.goldGainedFromTomePoints = GetGoldGainedFromEndOfSeasonTomePointConversion()
        self.hasPremiumTome = false

        for productTypeId = TAMRIEL_TOME_PRODUCT_TYPE_ITERATION_BEGIN, TAMRIEL_TOME_PRODUCT_TYPE_ITERATION_END do
            if HasTamrielTomeProductType(self.tomeId, productTypeId) then
                self.hasPremiumTome = true
                break
            end
        end

        local seasonName = GetRewardTrackDisplayName(self.rewardTrackId)
        self.seasonNameLabel:SetText(seasonName)

        local seasonTextureFile = GetTamrielTomeIntroBackgroundFileIndex(self.rewardTrackId)
        self.seasonImageTexture:SetTexture(seasonTextureFile)

        local rewardCountString = zo_strformat(SI_TAMRIEL_TOME_SEASON_ENTRY_EARNED_REWARDS_FORMATTER, self.numClaimedRewards, self.numRewards)
        self.seasonRewardCountLabel:SetText(rewardCountString)

        SetupBulletLabel(self.premiumExplanationLabel, self.hasPremiumTome and GetString(SI_TAMRIEL_TOMES_SEASON_END_DIALOG_PREMIUM_EXPLANATION) or "")

        local isGamepad = self.templateData.isGamepad
        local currencyOptions =
        {
            color = ZO_SELECTED_TEXT,
        }

        local tomePointsRollOverString = nil
        if self.numTomePointsRolledOver > 0 then
            local numTomePointsRolledOverString = ZO_Currency_Format(self.numTomePointsRolledOver, CURT_TOME_POINTS, ZO_CURRENCY_FORMAT_AMOUNT_ICON, isGamepad, currencyOptions)
            tomePointsRollOverString = zo_strformat(SI_TAMRIEL_TOMES_SEASON_END_DIALOG_TOME_POINT_ROLL_OVER, numTomePointsRolledOverString)
        end
        SetupBulletLabel(self.tomePointRolloverLabel, tomePointsRollOverString)

        local tomePointsConvertedToGoldString = nil
        if self.numTomePointsConvertedToGold > 0 and self.goldGainedFromTomePoints > 0 then
            local numTomePointsConvertedToGoldString = ZO_Currency_Format(self.numTomePointsConvertedToGold, CURT_TOME_POINTS, ZO_CURRENCY_FORMAT_AMOUNT_ICON, isGamepad, currencyOptions)
            local goldGainedFromTomePointsString = ZO_Currency_Format(self.goldGainedFromTomePoints, CURT_MONEY, ZO_CURRENCY_FORMAT_AMOUNT_ICON, isGamepad, currencyOptions)
            tomePointsConvertedToGoldString = zo_strformat(SI_TAMRIEL_TOMES_SEASON_END_DIALOG_GOLD_ROLL_OVER, numTomePointsConvertedToGoldString, goldGainedFromTomePointsString)
        end
        SetupBulletLabel(self.goldRolloverLabel, tomePointsConvertedToGoldString)
    end
end

function ZO_TamrielTomeSeasonEndDialog_Shared:InitializeGridList()
    local templateData = self.templateData
    local gridList = templateData.gridListClass:New(self.gridControl, templateData.highlightTemplate)
    self.gridList = gridList
    gridList:SetIndentAmount(0)
    gridList:SetHeaderPrePadding(0)
    gridList:SetHeaderPostPadding(0)
    gridList:SetYDistanceFromEdgeWhereSelectionCausesScroll(templateData.entryHeight)

    local function SetupGridEntry(...)
        self:SetupGridEntry(...)
    end

    local NO_HIDE_CALLBACK = nil
    local NO_RESET_CALLBACK = nil
    local GRID_PADDING = ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_PADDING
    self.gridList:AddEntryTemplate(templateData.entryTemplate, templateData.entryWidth, templateData.entryHeight, SetupGridEntry, NO_HIDE_CALLBACK, NO_RESET_CALLBACK, GRID_PADDING, GRID_PADDING)
end

function ZO_TamrielTomeSeasonEndDialog_Shared:BuildGridList()
    self.gridList:ClearGridList()
    self:PopulateGridList()
    self.gridList:CommitGridList()
end

-- Sort the automatically claimed rewards by:
--  Display Quality (descending); then,
--  Reward Tier (descending); then,
--  Reward Component (ascending [Premium first]); finally,
--  Reward Index within the Reward Tier & Reward Component (ascending).
function ZO_TamrielTomeSeasonEndDialog_Shared.CompareRewardEntryData(entryData1, entryData2)
    -- Rank by Reward Display Quality (descending).
    if entryData1.rewardDisplayQuality > entryData2.rewardDisplayQuality then
        return true
    elseif entryData1.rewardDisplayQuality ~= entryData2.rewardDisplayQuality then
        return false
    end

    -- Reward Display Qualities are equivalent; rank by Reward Tier (descending).
    if entryData1.rewardTier > entryData2.rewardTier then
        return true
    elseif entryData1.rewardTier ~= entryData2.rewardTier then
        return false
    end

    -- Reward Tiers are equivalent; rank by Reward Component (ascending).
    if entryData1.rewardComponent < entryData2.rewardComponent then
        return true
    elseif entryData1.rewardComponent ~= entryData2.rewardComponent then
        return false
    end

    -- Reward Components are equivalent; rank by Reward Index (ascending).
    return entryData1.rewardIndex < entryData2.rewardIndex
end

function ZO_TamrielTomeSeasonEndDialog_Shared:PopulateGridList()
    local entryTemplate = self.templateData.entryTemplate
    local tomeId = self.tomeId
    local rewardTrackId = self.rewardTrackId
    local numRewardTiers = GetTotalNumTiersForRewardTrack(rewardTrackId)
    local numRewards = 0
    local numAutoClaimedRewards = 0
    local entryDataList = {}

    for rewardTier = numRewardTiers, 1, -1 do
        for rewardComponent = REWARD_TRACK_COMPONENT_ITERATION_BEGIN, REWARD_TRACK_COMPONENT_ITERATION_END do
            local numRewardTierComponentRewards = GetNumRewardsAtRewardTrackTier(rewardTrackId, rewardTier, rewardComponent)

            for rewardIndex = 1, numRewardTierComponentRewards do
                local rewardId, rewardQuantity, rewardCost, rewardDisplayQuality, hideRewardQuality = GetTamrielTomesRewardInfo(rewardTrackId, rewardTier, rewardComponent, rewardIndex)

                if rewardId ~= 0 then
                    numRewards = numRewards + 1
                    local wasAutoClaimed, wasFallbackAutoClaim = GetTamrielTomesEndOfSeasonAutoClaimInfoForReward(rewardTier, rewardComponent, rewardIndex)

                    if wasAutoClaimed or wasFallbackAutoClaim then
                        local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, rewardQuantity)

                        if rewardData then
                            local rewardDisplayName = rewardData:GetFormattedName()
                            numAutoClaimedRewards = numAutoClaimedRewards + 1

                            rewardDisplayQuality = rewardDisplayQuality or ITEM_DISPLAY_QUALITY_NORMAL
                            local qualityColor = GetItemQualityColor(rewardDisplayQuality)
                            local rewardDisplayNameFormatted = qualityColor:Colorize(rewardDisplayName)

                            local rewardIconTextureFile = nil
                            local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, rewardQuantity)
                            if rewardData then
                                rewardIconTextureFile = rewardData:GetPlatformLootIcon()
                            end

                            local isRewardList = GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST
                            if isRewardList then
                                local rewardListId = GetRewardListIdFromReward(rewardId)
                                local rewardListData = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
                                if rewardListData and #rewardListData >= 1 then
                                    rewardQuantity = #rewardListData - 1

                                    local rewardData = rewardListData[1]
                                    if rewardData then
                                        rewardIconTextureFile = rewardData:GetPlatformLootIcon()
                                    end
                                end
                            end

                            local rewardQuantityString = ""
                            if rewardQuantity > 1 then
                                rewardQuantityString = ZO_CommaDelimitNumber(rewardQuantity)
                                if isRewardList then
                                    rewardQuantityString = zo_strformat(SI_TAMRIEL_TOMES_REWARD_LIST_QUANTITY_FORMATTER, rewardQuantityString)
                                end
                            end

                            local entryData = self:CreateGridEntryData(rewardData, rewardId, rewardIndex, rewardTier, rewardComponent, rewardDisplayQuality, rewardDisplayName, rewardDisplayNameFormatted, rewardQuantityString, rewardIconTextureFile)
                            table.insert(entryDataList, entryData)
                        end
                    end
                end
            end
        end
    end

    local MIN_X = nil
    local MAX_X = nil
    if numAutoClaimedRewards > 0 then
        table.sort(entryDataList, self.CompareRewardEntryData)

        for _, entryData in ipairs(entryDataList) do
            self.gridList:AddEntry(entryData, entryTemplate)
        end

        -- Resize the grid height to be the minimum of either the height necessary to
        -- fit the number entries in the grid or the maximum grid height allowed.
        local gridHeight = numAutoClaimedRewards * (ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_HEIGHT + ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_PADDING)
        gridHeight = zo_min(gridHeight, ZO_TAMRIEL_TOME_SEASON_END_GRID_HEIGHT_MAX)
        self.gridControl:SetDimensionConstraints(MIN_X, gridHeight, MAX_X, gridHeight)
        self.gridControl:SetHidden(false)
    else
        -- There were no automatically claimed rewards; resize the grid height to
        -- occupy virtually no space.
        local MIN_Y = 1
        local MAX_Y = 1
        self.gridControl:SetDimensionConstraints(MIN_X, MIN_Y, MAX_X, MAX_Y)
        self.gridControl:SetHidden(true)
    end

    self.claimedRewardsLabel:SetText(numAutoClaimedRewards == 0 and "" or zo_strformat(SI_TAMRIEL_TOMES_SEASON_END_DIALOG_CLAIMED_REWARDS, numAutoClaimedRewards))
end

function ZO_TamrielTomeSeasonEndDialog_Shared:CreateGridEntryData(rewardData, rewardId, rewardIndex, rewardTier, rewardComponent, rewardDisplayQuality, rewardDisplayName, rewardDisplayNameFormatted, rewardQuantityString, rewardIconTextureFile)
    local entryData =
    {
        rewardData = rewardData,
        rewardId = rewardId,
        rewardIndex = rewardIndex,
        rewardTier = rewardTier,
        rewardComponent = rewardComponent,
        rewardDisplayQuality = rewardDisplayQuality,
        rewardDisplayNameFormatted = rewardDisplayNameFormatted,
        rewardQuantityString = rewardQuantityString,
        rewardIconTextureFile = rewardIconTextureFile,
        narrationText = rewardDisplayName,
    }
    return entryData
end

function ZO_TamrielTomeSeasonEndDialog_Shared:SetupGridEntry(control, data)
    control.object:Setup(data, self)
end

function ZO_TamrielTomeSeasonEndDialog_Shared:SetSelectedData(data, previousData, control)
    if data == self.selectedData then
        return
    end

    if previousData and previousData ~= self.selectedData then
        return
    end

    if self.selectedData and self.selectedData.owner then
        self.selectedData.owner:SetIsHighlighted(false)
    end

    self.selectedData = data

    if data and data.owner then
        data.owner:SetIsHighlighted(true)
        self:ShowRewardTooltip(data.rewardData, control)
    else
        self:HideRewardTooltip()
    end
end

function ZO_TamrielTomeSeasonEndDialog_Shared:HideRewardTooltip()
    ZO_Rewards_Shared_OnMouseExit()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_TamrielTomeSeasonEndDialog_Shared:ShowRewardTooltip(rewardData, control)
    if not rewardData then
        self:HideRewardTooltip()
        return
    end

    if IsInGamepadPreferredMode() then
        GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, rewardData)
    else
        ZO_Rewards_Shared_ShowRewardTooltip(rewardData, control or self.gridControl, LEFT, RIGHT, 20)
    end
end

function ZO_TamrielTomeSeasonEndDialog_Shared:OnHidden()
    -- Can be overridden
end

function ZO_TamrielTomeSeasonEndDialog_Shared:OnShown()
    -- Can be overridden
end

function ZO_TamrielTomeSeasonEndDialog_Shared:OnSelectionChanged(previousSelectedData, currentSelectedData)
    self:SetSelectedData(currentSelectedData, previousSelectedData)
end

function ZO_TamrielTomeSeasonEndDialog_Shared:Hide()
    ZO_Dialogs_ReleaseDialog(self.dialogName)
end

function ZO_TamrielTomeSeasonEndDialog_Shared:Show()
    ZO_Dialogs_ShowPlatformDialog(self.dialogName, {})
end

function ZO_TamrielTomeSeasonEndDialog_Shared:TryShow()
    if not HasTamrielTomesEndOfSeasonRecap() then
        return false
    end

    if HasPlayerSeenTamrielTomesEndOfSeasonRecap() then
        return false
    end

    self:Show()
    return true
end

function ZO_TamrielTomeSeasonEndDialog_Shared.TryShowPlatformDialog()
    if IsInGamepadPreferredMode() then
        return TAMRIEL_TOME_SEASON_END_DIALOG_GAMEPAD:TryShow()
    end
    return TAMRIEL_TOME_SEASON_END_DIALOG_KEYBOARD:TryShow()
end