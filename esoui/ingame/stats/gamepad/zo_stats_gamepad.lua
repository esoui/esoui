--Attribute Spinner

local ZO_AttributeSpinner_Gamepad = ZO_AttributeSpinner_Shared:Subclass()

function ZO_AttributeSpinner_Gamepad:New(attributeControl, attributeType, attributeManager, valueChangedCallback)
    local attributeSpinner = ZO_AttributeSpinner_Shared.New(self, attributeControl, attributeType, attributeManager, valueChangedCallback)
    attributeSpinner:SetSpinner(ZO_Spinner_Gamepad:New(attributeControl.spinner, 0, 0, GAMEPAD_SPINNER_DIRECTION_HORIZONTAL))
    return attributeSpinner
end

function ZO_AttributeSpinner_Gamepad:SetActive(active)
    self.pointsSpinner:SetActive(active)
end

--ZO_AttributeItem

local ZO_AttributeItem_Gamepad = ZO_Object:Subclass()

function ZO_AttributeItem_Gamepad:New(...)
    local attribute = ZO_Object.New(self)
    attribute:Initialize(...)
    return attribute
end

function ZO_AttributeItem_Gamepad:Initialize(control)
    self.control = control
    self.header = control:GetNamedChild("Header")
    self.data = control:GetNamedChild("Data")
    self.bonus = control:GetNamedChild("Bonus")
end

function ZO_AttributeItem_Gamepad:SetAttributeInfo(statType)
    self.statType = statType
    if statType == STAT_CRITICAL_STRIKE or statType == STAT_SPELL_CRITICAL then
        self.formatString = SI_STAT_VALUE_PERCENT
    end
end

function ZO_AttributeItem_Gamepad:RefreshHeaderText()
    local text = GetString("SI_DERIVEDSTATS", self.statType)
    self.header:SetText(text)
end

function ZO_AttributeItem_Gamepad:RefreshDataText()
    local value = GetPlayerStat(self.statType, STAT_BONUS_OPTION_APPLY_BONUS)
    local text

    if self.statType == STAT_CRITICAL_STRIKE or self.statType == STAT_SPELL_CRITICAL then
        value = GetCriticalStrikeChance(value)
        text = zo_strformat(SI_STAT_VALUE_PERCENT, value)
    else
        if self.formatString ~= nil then
            text = zo_strformat(self.formatString, value)
        else
            text = value
        end
    end

    self.data:SetText(text)
end

function ZO_AttributeItem_Gamepad:RefreshBonusText()
    local bonusValue = GAMEPAD_STATS:GetPendingStatBonuses(self.statType)
    local hideBonus = bonusValue == 0 or bonusValue == nil
    self.bonus:SetHidden(hideBonus)
    if not hideBonus then
        self.bonus:SetText(zo_strformat(SI_STAT_PENDING_BONUS_FORMAT, bonusValue))
        self.bonus:SetColor(STAT_HIGHER_COLOR:UnpackRGBA())
    end
end

function ZO_AttributeItem_Gamepad:RefreshText()
    self:RefreshHeaderText()
    self:RefreshDataText()
    self:RefreshBonusText()
end

--ZO_AttributeTooltipsGrid_Gamepad

local ZO_AttributeTooltipsGrid_Gamepad = ZO_GamepadGrid:Subclass()

function ZO_AttributeTooltipsGrid_Gamepad:New(...)
    return ZO_GamepadGrid.New(self, ...)
end

function ZO_AttributeTooltipsGrid_Gamepad:Initialize(control, rowMajor, backButtonCallback)
    ZO_GamepadGrid.Initialize(self, control, rowMajor)
    self.attributeItems = {}
    self:InitializeKeybindStripDescriptors(backButtonCallback)
end

function ZO_AttributeTooltipsGrid_Gamepad:InitializeKeybindStripDescriptors(backButtonCallback)
    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, backButtonCallback)
end

function ZO_AttributeTooltipsGrid_Gamepad:AddGridItem(control, statType, column, row)
    local attributeItem = control
    attributeItem.highlight = attributeItem:GetNamedChild("Highlight")
    attributeItem.statType = statType

    if not self.attributeItems[row] then
        self.attributeItems[row] = {}
    end
    self.attributeItems[row][column] = attributeItem
end

function ZO_AttributeTooltipsGrid_Gamepad:GetGridItems()
    return self.attributeItems
end

function ZO_AttributeTooltipsGrid_Gamepad:SetItemHighlightVisible(column, row, visible)
    local attribute = self.attributeItems[row][column]
    attribute.highlight:SetHidden(not visible)
end

function ZO_AttributeTooltipsGrid_Gamepad:RefreshAttributeTooltip()
    local RETAIN_FRAGMENT = true;
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, RETAIN_FRAGMENT)

    local currentAttributeItem = self.attributeItems[self.currentItemRow][self.currentItemColumn]
    local currentStatType = currentAttributeItem.statType
    if currentStatType ~= STAT_NONE then
        GAMEPAD_TOOLTIPS:LayoutAttributeTooltip(GAMEPAD_RIGHT_TOOLTIP, currentStatType)
    else
        GAMEPAD_TOOLTIPS:LayoutEquipmentBonusTooltip(GAMEPAD_RIGHT_TOOLTIP, GAMEPAD_STATS:GetEquipmentBonusInfo())
    end
end

function ZO_AttributeTooltipsGrid_Gamepad:RefreshGridHighlight()
    if self.currentItemColumn and self.currentItemRow then
        local NOT_VISIBLE = false
        self:SetItemHighlightVisible(self.currentItemColumn, self.currentItemRow, NOT_VISIBLE)
    end

    local column, row = self:GetGridPosition()
    if column > 0 and row > 0 then
        local VISIBLE = true
        self:SetItemHighlightVisible(column, row, VISIBLE)
        self.currentItemColumn = column
        self.currentItemRow = row
    end

    self:RefreshAttributeTooltip()
end

function ZO_AttributeTooltipsGrid_Gamepad:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    DIRECTIONAL_INPUT:Activate(self, self.control)

    self:RefreshGridHighlight()
end

function ZO_AttributeTooltipsGrid_Gamepad:Deactivate()
    if self.currentItemColumn and self.currentItemRow then
        local NOT_VISIBLE = false
        self:SetItemHighlightVisible(self.currentItemColumn, self.currentItemRow, NOT_VISIBLE)
    end

    local DO_NOT_RETAIN_FRAGMENT = false
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, DO_NOT_RETAIN_FRAGMENT)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    DIRECTIONAL_INPUT:Deactivate(self)
end

--Stats

local GAMEPAD_STATS_COMMIT_POINTS_DIALOG_NAME = "GAMEPAD_STATS_COMMIT_POINTS"

local GAMEPAD_STATS_DISPLAY_MODE = 
{
    CHARACTER = 1,
    ATTRIBUTES = 2,
    EFFECTS = 3,
    TITLE = 4,
    OUTFIT = 5,
    LEVEL_UP_REWARDS = 6,
    UPCOMING_LEVEL_UP_REWARDS = 7,
}

ZO_GamepadStats = ZO_Object.MultiSubclass(ZO_Stats_Common, ZO_Gamepad_ParametricList_Screen)

function ZO_GamepadStats:New(...)
    local gamepadStats = ZO_Object.New(self)
    gamepadStats:Initialize(...)
    return gamepadStats
end

function ZO_GamepadStats:Initialize(control)
    ZO_Stats_Common.Initialize(self, control)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW)
    self:SetListsUseTriggerKeybinds(true)

    self.mainList = self:GetMainList()

    self.displayMode = GAMEPAD_STATS_DISPLAY_MODE.TITLE

    --Only allow the window to update once every quarter second so if buffs are updating like crazy we're not tanking the frame rate
    self:SetUpdateCooldown(250)

    GAMEPAD_STATS_ROOT_SCENE = ZO_Scene:New("gamepad_stats_root", SCENE_MANAGER)
    GAMEPAD_STATS_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitializationRoot()

            self:TryResetScreenState()

            self:RefreshEquipmentBonus()
            self:RegisterForEvents()

            self:Update()

            TriggerTutorial(TUTORIAL_TRIGGER_STATS_OPENED)
            if GetAttributeUnspentPoints() > 0 then
                TriggerTutorial(TUTORIAL_TRIGGER_STATS_OPENED_AND_ATTRIBUTE_POINTS_UNSPENT)
            end
        elseif newState == SCENE_HIDDEN then
            self:DeactivateMainList()

            if self.currentTitleDropdown ~= nil then
                self.currentTitleDropdown:Deactivate(true)
            end

            if self.attributeTooltips then
                self.attributeTooltips:Deactivate()
            end

            self:UnregisterForEvents()
        end

        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
    end)

    GAMEPAD_STATS_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    GAMEPAD_STATS_FRAGMENT:SetHideOnSceneHidden(true)

    GAMEPAD_STATS_CHARACTER_INFO_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(control:GetNamedChild("RightPane"))
end

do
    local function OnUpdate()
        GAMEPAD_STATS:Update()
    end

    function ZO_GamepadStats:RegisterForEvents()
        self.control:RegisterForEvent(EVENT_STATS_UPDATED, OnUpdate)
        self.control:AddFilterForEvent(EVENT_STATS_UPDATED, REGISTER_FILTER_UNIT_TAG, "player")
        self.control:RegisterForEvent(EVENT_LEVEL_UPDATE, OnUpdate)
        self.control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
        self.control:RegisterForEvent(EVENT_EFFECT_CHANGED, OnUpdate)
        self.control:AddFilterForEvent(EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")
        self.control:RegisterForEvent(EVENT_EFFECTS_FULL_UPDATE, OnUpdate)
        self.control:RegisterForEvent(EVENT_ATTRIBUTE_UPGRADE_UPDATED, OnUpdate)
        self.control:RegisterForEvent(EVENT_TITLE_UPDATE, OnUpdate)
        self.control:AddFilterForEvent(EVENT_TITLE_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
        self.control:RegisterForEvent(EVENT_PLAYER_TITLES_UPDATE, OnUpdate)
        self.control:RegisterForEvent(EVENT_CHAMPION_POINT_GAINED, OnUpdate)
        self.control:RegisterForEvent(EVENT_CHAMPION_SYSTEM_UNLOCKED, OnUpdate)
        self.control:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_ADDED, OnUpdate)
        self.control:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_REMOVED, OnUpdate)
        STABLE_MANAGER:RegisterCallback("StableMountInfoUpdated", OnUpdate)
        ZO_LEVEL_UP_REWARDS_MANAGER:RegisterCallback("OnLevelUpRewardsUpdated", OnUpdate)
    end

    function ZO_GamepadStats:UnregisterForEvents()
        self.control:UnregisterForEvent(EVENT_STATS_UPDATED)
        self.control:UnregisterForEvent(EVENT_LEVEL_UPDATE)
        self.control:UnregisterForEvent(EVENT_EFFECT_CHANGED)
        self.control:UnregisterForEvent(EVENT_EFFECTS_FULL_UPDATE)
        self.control:UnregisterForEvent(EVENT_ATTRIBUTE_UPGRADE_UPDATED)
        self.control:UnregisterForEvent(EVENT_TITLE_UPDATE)
        self.control:UnregisterForEvent(EVENT_PLAYER_TITLES_UPDATE)
        self.control:UnregisterForEvent(EVENT_CHAMPION_POINT_GAINED)
        self.control:UnregisterForEvent(EVENT_CHAMPION_SYSTEM_UNLOCKED)
        self.control:UnregisterForEvent(EVENT_ARTIFICIAL_EFFECT_ADDED)
        self.control:UnregisterForEvent(EVENT_ARTIFICIAL_EFFECT_REMOVED)
        STABLE_MANAGER:UnregisterCallback("StableMountInfoUpdated", OnUpdate)
        ZO_LEVEL_UP_REWARDS_MANAGER:UnregisterCallback("OnLevelUpRewardsUpdated", OnUpdate)
    end
end

function ZO_GamepadStats:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    if self.outfitSelectorHeaderFocus:IsActive() then
        self.displayMode = GAMEPAD_STATS_DISPLAY_MODE.OUTFIT
        self.mainList:Deactivate()
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadStats:ActivateMainList()
    if not self.mainList:IsActive() then
        self.mainList:Activate()

        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadStats:DeactivateMainList()
    if self.mainList:IsActive() then

        self.mainList:Deactivate()

        local selectedControl = self.mainList:GetSelectedControl()
        if selectedControl and selectedControl.pointLimitedSpinner then
            selectedControl.pointLimitedSpinner:SetActive(false)
        end

        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadStats:ActivateTitleDropdown()
    if self.currentTitleDropdown ~= nil then
        self:DeactivateMainList()

        self.currentTitleDropdown:Activate()

        local currentTitleIndex = GetCurrentTitleIndex()
        if currentTitleIndex then
            currentTitleIndex = currentTitleIndex + 1
        else
            currentTitleIndex = 1
        end
        self.currentTitleDropdown:SetHighlightedItem(currentTitleIndex)
    end
end

function ZO_GamepadStats:ShowOutfitSelector()
    SCENE_MANAGER:Push("gamepad_outfits_selection")
end

function ZO_GamepadStats:ShowLevelUpRewards()
    ZO_GAMEPAD_CLAIM_LEVEL_UP_REWARDS:Show()
end

function ZO_GamepadStats:OnTitleDropdownDeactivated()
    self:ActivateMainList()
    if self.refreshMainListOnDropdownClose then
        self:RefreshMainList()
        self.refreshMainListOnDropdownClose = false
    end
end

function ZO_GamepadStats:ActivateViewAttributes()
    self:DeactivateMainList()
    self.attributeTooltips:Activate()
end

function ZO_GamepadStats:DeactivateViewAttributes()
    self.attributeTooltips:Deactivate()
    self:ActivateMainList()
end

function ZO_GamepadStats:ResetAttributeData()
    self.attributeData = {}

    for attributeType = 1, GetNumAttributes() do
        self.attributeData[attributeType] = {
            addedPoints = 0
        }
    end

    for attributeType, statType in pairs(STAT_TYPES) do
        self:UpdatePendingStatBonuses(statType, 0)
    end
end

function ZO_GamepadStats:ResetDisplayState()
    -- Reset any stateful variables used in this screen.
    self.displayMode = nil
end

function ZO_GamepadStats:TryResetScreenState()
    self:ResetAttributeData()
    self:ResetDisplayState()
end

function ZO_GamepadStats:PerformDeferredInitializationRoot()
    if self.deferredInitialized then return end
    self.deferredInitialized = true
    
    self.outfitSelectorControl = self.header:GetNamedChild("OutfitSelector")
    self.outfitSelectorNameLabel = self.outfitSelectorControl:GetNamedChild("OutfitName")
    self.outfitSelectorHeaderFocus = ZO_Outfit_Selector_Header_Focus_Gamepad:New(self.outfitSelectorControl)
    self:SetupHeaderFocus(self.outfitSelectorHeaderFocus)

    self.infoPanel = self.control:GetNamedChild("RightPane"):GetNamedChild("InfoPanel")

    self:InitializeCharacterPanel()
    self:InitializeAttributesPanel()
    self:InitializeCharacterEffects()

    self:InitializeHeader()
    self:InitializeCommitPointsDialog()
    self:InitializeMainListEntries()
end

function ZO_GamepadStats:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = { 
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select / Commit Points
        {
            name = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.OUTFIT
                    or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE
                    or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.LEVEL_UP_REWARDS then
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                else
                    return GetString(SI_STAT_GAMEPAD_COMMIT_POINTS)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.OUTFIT
                    or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE
                    or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.LEVEL_UP_REWARDS then
                    return true
                else
                    return self:GetNumPointsAdded() > 0
                end
            end,
            callback = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.OUTFIT then
                    self:ShowOutfitSelector()
                elseif self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE then
                    self:ActivateTitleDropdown()
                elseif self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.LEVEL_UP_REWARDS then
                    self:ShowLevelUpRewards()
                else
                    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_STATS_COMMIT_POINTS_DIALOG_NAME)
                end
            end,
        },
        -- Remove Buff / View Attributes
        { 
            name = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.EFFECTS then
                    return GetString(SI_STAT_GAMEPAD_EFFECTS_REMOVE)
                else
                    return GetString(SI_STAT_GAMEPAD_VIEW_ATTRIBUTES)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.EFFECTS then
                    local selectedData = self.mainList:GetTargetData()
                    if selectedData ~= nil and selectedData.buffSlot ~= nil then
                        return selectedData.canClickOff
                    end
                    return false
                elseif self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.ATTRIBUTES then
                    return true
                end
                return false
            end,
            callback = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.EFFECTS then
                    local selectedData = self.mainList:GetTargetData()
                    CancelBuff(selectedData.buffSlot)
                else
                    self:ActivateViewAttributes()
                end
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_GamepadStats:SetAddedPoints(attributeType, addedPoints)
    self.attributeData[attributeType].addedPoints = addedPoints

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    if not self.attributesPanel.hidden then
        self:RefreshAttributesPanel()
    end
end

function ZO_GamepadStats:GetAddedPoints(attributeType)
    return self.attributeData[attributeType].addedPoints
end

function ZO_GamepadStats:GetNumPointsAdded()
    local addedPoints = 0

    for attributeType = 1, GetNumAttributes() do
        addedPoints = addedPoints + self.attributeData[attributeType].addedPoints
    end

    return addedPoints
end

function ZO_GamepadStats:PurchaseAttributes()
    PlaySound(SOUNDS.STATS_PURCHASE)
    PurchaseAttributes(self.attributeData[ATTRIBUTE_HEALTH].addedPoints, self.attributeData[ATTRIBUTE_MAGICKA].addedPoints, self.attributeData[ATTRIBUTE_STAMINA].addedPoints)
    self:ResetAttributeData()
        end

function ZO_GamepadStats:UpdateScreenVisibility()
    local isAttributesHidden = true
    local isCharacterHidden = true
    local isEffectsHidden = true
    local showUpcomingRewards = false

    if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.CHARACTER then
        isCharacterHidden = false
        self:RefreshCharacterPanel()
    elseif self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.EFFECTS then
        if self.numActiveEffects > 0 then
            isEffectsHidden = false
            self:RefreshCharacterEffects()
        end
    elseif self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.ATTRIBUTES
            or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE then
        --Title and attributes both display attributes, by design
        isAttributesHidden = false
        self:RefreshAttributesPanel()
    elseif self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.UPCOMING_LEVEL_UP_REWARDS then
        showUpcomingRewards = true
    end

    self.characterStatsPanel:SetHidden(isCharacterHidden)
    self.attributesPanel:SetHidden(isAttributesHidden)
    self.equipmentBonus:SetHidden(isAttributesHidden)
    self.characterEffects:SetHidden(isEffectsHidden)

    local hideQuadrant2_3Background = isAttributesHidden and isCharacterHidden and isEffectsHidden
    if hideQuadrant2_3Background then
        GAMEPAD_STATS_ROOT_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        GAMEPAD_STATS_ROOT_SCENE:RemoveFragment(GAMEPAD_STATS_CHARACTER_INFO_PANEL_FRAGMENT)
    else
        GAMEPAD_STATS_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        GAMEPAD_STATS_ROOT_SCENE:AddFragment(GAMEPAD_STATS_CHARACTER_INFO_PANEL_FRAGMENT)
    end

    if showUpcomingRewards then
        ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS:Show()
    else
        ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS:Hide()
    end
end

function ZO_GamepadStats:PerformUpdate()
    self:UpdateSpendablePoints()

    self:RefreshMainList()

    local selectedData = self.mainList:GetTargetData()

    if self.outfitSelectorHeaderFocus:IsActive() then
        self.displayMode = GAMEPAD_STATS_DISPLAY_MODE.OUTFIT
    elseif selectedData.displayMode ~= nil then
        self.displayMode = selectedData.displayMode
    end

    self:UpdateScreenVisibility()

    self.dirty = false
end

function ZO_GamepadStats:OnSetAvailablePoints()
    self:RefreshHeader()
end

function ZO_GamepadStats:UpdateSpendablePoints()
    self:SetAvailablePoints(self:GetTotalSpendablePoints() - self:GetNumPointsAdded())
end

--------------------------
-- Commit Points Dialog --
--------------------------

function ZO_GamepadStats:InitializeCommitPointsDialog()
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_STATS_COMMIT_POINTS_DIALOG_NAME,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = SI_STAT_GAMEPAD_CHANGE_ATTRIBUTES,
        },

        mainText = 
        {
            text = SI_STAT_GAMEPAD_COMMIT_POINTS_QUESTION,
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_DIALOG_YES_BUTTON,
                callback = function()
                    self:PurchaseAttributes()
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_DIALOG_NO_BUTTON,
            },
        }
    })
end
                 
------------
-- Header --
------------

function ZO_GamepadStats:InitializeHeader()
    self.headerData = {
        titleText = GetString(SI_STAT_GAMEPAD_CHARACTER_SHEET_TITLE),

        data1HeaderText = GetString(SI_STATS_GAMEPAD_AVAILABLE_POINTS),
    }

    local rightPane = self.control:GetNamedChild("RightPane")
    local contentContainer = rightPane:GetNamedChild("HeaderContainer")
    self.contentHeader = contentContainer:GetNamedChild("Header")

    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)
    self.contentHeaderData = {}
end

function ZO_GamepadStats:RefreshHeader()
    self.headerData.data1Text = tostring(self:GetAvailablePoints())

    local currentlyEquippedOutfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentOutfitIndex()
    if currentlyEquippedOutfitIndex then
        local currentOutfit = ZO_OUTFIT_MANAGER:GetOutfitManipulator(currentlyEquippedOutfitIndex)
        self.outfitSelectorNameLabel:SetText(currentOutfit:GetOutfitName())
    else
        self.outfitSelectorNameLabel:SetText(GetString(SI_NO_OUTFIT_EQUIP_ENTRY))
    end

    self.outfitSelectorHeaderFocus:Update()

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_GamepadStats:RefreshContentHeader(title, dataHeaderText, dataText)
    self.contentHeaderData.titleText = zo_strformat(SI_ABILITY_TOOLTIP_NAME, title)
    self.contentHeaderData.data1HeaderText = dataHeaderText
    self.contentHeaderData.data1Text = dataText
    ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)
end

---------------
-- Main List --
---------------

do
    local GAMEPAD_ATTRIBUTE_ICONS =
    {
        [ATTRIBUTE_HEALTH] = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_healthIcon.dds",
        [ATTRIBUTE_STAMINA] = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_staminaIcon.dds",
        [ATTRIBUTE_MAGICKA] = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_magickaIcon.dds",
    }

    local GAMEPAD_ATTRIBUTE_ORDERING =
    {
        ATTRIBUTE_MAGICKA,
        ATTRIBUTE_HEALTH,
        ATTRIBUTE_STAMINA,
    }

    function ZO_GamepadStats:InitializeMainListEntries()
        -- Claim Rewards Entry
        -- entry that lets you go to the claim rewards scene
        self.claimRewardsEntry = ZO_GamepadEntryData:New(GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_ENTRY_NAME))
        self.claimRewardsEntry:SetCanLevel(true)
        self.claimRewardsEntry.displayMode = GAMEPAD_STATS_DISPLAY_MODE.LEVEL_UP_REWARDS

        -- Upcoming Rewards Entry
        -- entry that shows the upcoming rewards when selected
        self.upcomingRewardsEntry = ZO_GamepadEntryData:New(GetString(SI_LEVEL_UP_REWARDS_UPCOMING_REWARDS_HEADER))
        self.upcomingRewardsEntry.displayMode = GAMEPAD_STATS_DISPLAY_MODE.UPCOMING_LEVEL_UP_REWARDS

        --Title Entry
        self.titleEntry = ZO_GamepadEntryData:New("")
        self.titleEntry.displayMode = GAMEPAD_STATS_DISPLAY_MODE.TITLE
        self.titleEntry.statsObject = self
        self.titleEntry:SetHeader(GetString(SI_STATS_TITLE))

        --Character Entry
        self.characterEntry = ZO_GamepadEntryData:New(GetString(SI_STAT_GAMEPAD_CHARACTER_SHEET_DESCRIPTION))
        self.characterEntry.displayMode = GAMEPAD_STATS_DISPLAY_MODE.CHARACTER
        self.characterEntry:SetHeader(GetString(SI_STATS_CHARACTER))

        local function CanSpendAttributePoints()
            return GetAttributeUnspentPoints() > 0
        end

        --Attribute Entries
        self.attributeEntries = {}
        for index, attributeType in ipairs(GAMEPAD_ATTRIBUTE_ORDERING) do
            local icon = GAMEPAD_ATTRIBUTE_ICONS[attributeType]
            local data = ZO_GamepadEntryData:New(GetString("SI_ATTRIBUTES", attributeType), icon)
            data:SetCanLevel(CanSpendAttributePoints)
            data.screen = self
            data.attributeType = attributeType
            data.displayMode = GAMEPAD_STATS_DISPLAY_MODE.ATTRIBUTES

            if index == 1 then
                data:SetHeader(GetString(SI_STATS_ATTRIBUTES))
            end
            table.insert(self.attributeEntries, data)
        end
    end
end

do
    local function SetupEffectAttributeRow(control, data, ...)
        ZO_SharedGamepadEntry_OnSetup(control, data, ...)
        local frameControl = control:GetNamedChild("Frame")
        local hasIcon = data:GetNumIcons() > 0
        frameControl:SetHidden(not hasIcon)
    end

    function ZO_GamepadStats:SetupList(list)
        list:SetValidateGradient(true)

        list:AddDataTemplate("ZO_GamepadStatTitleRow", ZO_GamepadStatTitleRow_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadStatTitleRow", ZO_GamepadStatTitleRow_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

        list:AddDataTemplate("ZO_GamepadStatAttributeRow", ZO_GamepadStatAttributeRow_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadStatAttributeRow", ZO_GamepadStatAttributeRow_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

        list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

        list:AddDataTemplate("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

        list:AddDataTemplate("ZO_GamepadEffectAttributeRow", SetupEffectAttributeRow, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadEffectAttributeRow", SetupEffectAttributeRow, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    end
end

function ZO_GamepadStats:OnSelectionChanged(list, selectedData, oldSelectedData)
    if not self.outfitSelectorHeaderFocus:IsActive() then
        self.displayMode = selectedData.displayMode
    end

    self:UpdateScreenVisibility()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadStats:OnEnterHeader()
    self.displayMode = GAMEPAD_STATS_DISPLAY_MODE.OUTFIT
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateScreenVisibility()
end

function ZO_GamepadStats:OnLeaveHeader()
    local targetData = self.mainList:GetTargetData()
    self.displayMode = targetData.displayMode
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateScreenVisibility()
end

do
    local function ArtificialEffectsRowComparator(left, right)
        return left.sortOrder < right.sortOrder
    end

    function ZO_GamepadStats:RefreshMainList()
        if self.currentTitleDropdown and self.currentTitleDropdown:IsDropdownVisible() then
            self.refreshMainListOnDropdownClose = true
            return
        end

        self.mainList:Clear()

        --Level Up Reward
        if HasPendingLevelUpReward() then
            self.mainList:AddEntry("ZO_GamepadNewMenuEntryTemplate", self.claimRewardsEntry)
        elseif HasUpcomingLevelUpReward() then
            self.mainList:AddEntry("ZO_GamepadMenuEntryTemplate", self.upcomingRewardsEntry)
        end

        --Title
        self.mainList:AddEntryWithHeader("ZO_GamepadStatTitleRow", self.titleEntry)

        -- Attributes
        for index, attributeEntry in ipairs(self.attributeEntries) do
            if index == 1 then
                self.mainList:AddEntryWithHeader("ZO_GamepadStatAttributeRow", attributeEntry)
            else
                self.mainList:AddEntry("ZO_GamepadStatAttributeRow", attributeEntry)
            end
        end

        -- Character Info
        self.mainList:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", self.characterEntry)

        -- Active Effects--
        self.numActiveEffects = 0

        --Artificial effects
        local sortedArtificialEffectsTable = {}
        for effectId in ZO_GetNextActiveArtificialEffectIdIter do
            local displayName, iconFile, effectType, sortOrder, startTime, endTime = GetArtificialEffectInfo(effectId)
        
            local data = ZO_GamepadEntryData:New(zo_strformat(SI_ABILITY_TOOLTIP_NAME, displayName), iconFile)
            data.displayMode = GAMEPAD_STATS_DISPLAY_MODE.EFFECTS
            data.canClickOff = false
            data.artificialEffectId = effectId
            data.tooltipTitle = displayName
            data.sortOrder = sortOrder
            data.isArtificial = true

            local duration = endTime - startTime
            if duration > 0 then
                local timeLeft = (endTime * 1000.0) - GetFrameTimeMilliseconds()
                data:SetCooldown(timeLeft, duration * 1000.0)
            end

            table.insert(sortedArtificialEffectsTable, data)
        end

        table.sort(sortedArtificialEffectsTable, ArtificialEffectsRowComparator)

        for i, data in ipairs(sortedArtificialEffectsTable) do
            self:AddActiveEffectData(data)
        end

        --Real Effects
        local numBuffs = GetNumBuffs("player")
        local hasActiveEffects = numBuffs > 0
        if hasActiveEffects then
            for i = 1, numBuffs do
                local buffName, startTime, endTime, buffSlot, stackCount, iconFile, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff = GetUnitBuffInfo("player", i)

                if buffSlot > 0 and buffName ~= "" then
                    local data = ZO_GamepadEntryData:New(zo_strformat(SI_ABILITY_TOOLTIP_NAME, buffName), iconFile)
                    data.displayMode = GAMEPAD_STATS_DISPLAY_MODE.EFFECTS
                    data.buffIndex = i
                    data.buffSlot = buffSlot
                    data.canClickOff = canClickOff
                    data.isArtificial = false

                    local duration = endTime - startTime
                    if duration > 0 then
                        local timeLeft = (endTime * 1000.0) - GetFrameTimeMilliseconds()
                        data:SetCooldown(timeLeft, duration * 1000.0)
                    end

                    self:AddActiveEffectData(data)
                end
            end
        end

        if self.numActiveEffects == 0 then
            local data = ZO_GamepadEntryData:New(GetString(SI_STAT_GAMEPAD_EFFECTS_NONE_ACTIVE))
            data.displayMode = GAMEPAD_STATS_DISPLAY_MODE.EFFECTS
            data:SetHeader(GetString(SI_STATS_ACTIVE_EFFECTS))
        
            self.mainList:AddEntryWithHeader("ZO_GamepadEffectAttributeRow", data)
        end

        self.mainList:Commit()

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadStats:AddActiveEffectData(data)
    if self.numActiveEffects == 0 then
        data:SetHeader(GetString(SI_STATS_ACTIVE_EFFECTS))
        self.mainList:AddEntryWithHeader("ZO_GamepadEffectAttributeRow", data)
    else
        self.mainList:AddEntry("ZO_GamepadEffectAttributeRow", data)
    end
    self.numActiveEffects = self.numActiveEffects + 1
end

-------------------
-- Heat & Bounty --
-------------------

function ZO_Stats_Gamepad_BountyDisplay_Initialize(control)
    GAMEPAD_STATS_BOUNTY_DISPLAY = ZO_BountyDisplay:New(control, true)
end

-----------------------
-- Character Effects --
-----------------------

function ZO_GamepadStats:InitializeCharacterEffects()
    self.characterEffects = self.infoPanel:GetNamedChild("CharacterEffectsPanel")

    local titleSection = self.characterEffects:GetNamedChild("TitleSection")

    self.effectDesc = titleSection:GetNamedChild("EffectDesc")
end

function ZO_GamepadStats:RefreshCharacterEffects()
    local selectedData = self.mainList:GetTargetData()

    local contentTitle, contentDescription, contentStartTime, contentEndTime, _

    if selectedData.isArtificial then
        contentTitle, _, _, _, contentStartTime, contentEndTime = GetArtificialEffectInfo(selectedData.artificialEffectId)
        contentDescription = GetArtificialEffectTooltipText(selectedData.artificialEffectId)
    else
        local buffSlot, abilityId
        contentTitle, contentStartTime, contentEndTime, buffSlot, _, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", selectedData.buffIndex)

        if DoesAbilityExist(abilityId) then
            contentDescription = GetAbilityEffectDescription(buffSlot)
        end
    end

    local contentDuration = contentEndTime - contentStartTime
    if contentDuration > 0 then
        local function OnTimerUpdate()
            local timeLeft = contentEndTime - (GetFrameTimeMilliseconds() / 1000.0)

            local timeLeftText = ZO_FormatTime(timeLeft, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)

            self:RefreshContentHeader(contentTitle, GetString(SI_STAT_GAMEPAD_TIME_REMAINING), timeLeftText)
        end

        self.effectDesc:SetHandler("OnUpdate", OnTimerUpdate)
    else
        self.effectDesc:SetHandler("OnUpdate", nil)
    end

    self.effectDesc:SetText(contentDescription)
    self:RefreshContentHeader(contentTitle)
end

---------------------
-- Character Stats --
---------------------

function ZO_GamepadStats:InitializeCharacterPanel()
    self.characterStatsPanel = self.infoPanel:GetNamedChild("CharacterStatsPanel")

    -- Left Column

    local leftColumn = self.characterStatsPanel:GetNamedChild("LeftColumn")

    self.race = leftColumn:GetNamedChild("Race")
    self.class = leftColumn:GetNamedChild("Class")

    self.championPointsHeader = leftColumn:GetNamedChild("ChampionPointsHeader")
    self.championPoints = leftColumn:GetNamedChild("ChampionPoints")

    self.ridingSpeed = leftColumn:GetNamedChild("RidingSpeed")
    self.ridingCapacity = leftColumn:GetNamedChild("RidingCapacity")

    -- Right Column

    local rightColumn = self.characterStatsPanel:GetNamedChild("RightColumn")

    self.alliance = rightColumn:GetNamedChild("AllianceData")
    self.rank = rightColumn:GetNamedChild("RankData")

    self.ridingStamina = rightColumn:GetNamedChild("RidingStamina")
    self.ridingTrainingHeader = rightColumn:GetNamedChild("RidingTrainingHeader")
    self.ridingTrainingReady = rightColumn:GetNamedChild("RidingTrainingReady")
    self.ridingTrainingTimer = rightColumn:GetNamedChild("RidingTrainingTimer")

    -- XP Bar
    self.experienceProgress = self.characterStatsPanel:GetNamedChild("ExperienceProgress")
    self.experienceBarControl = self.characterStatsPanel:GetNamedChild("ExperienceBar")
    self.enlightenedBarControl = self.experienceBarControl:GetNamedChild("EnlightenedBar")
    self.experienceBar = ZO_WrappingStatusBar:New(self.experienceBarControl)
    self.enlightenmentText = self.characterStatsPanel:GetNamedChild("Enlightenment")

    local function OnTimerUpdate()
        local timeUntilCanBeTrained = GetTimeUntilCanBeTrained()
        if timeUntilCanBeTrained == 0 then
            self:RefreshCharacterPanel()
        else
            local timeLeft = ZO_FormatTimeMilliseconds(timeUntilCanBeTrained, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
            self.ridingTrainingTimer:SetText(timeLeft)
        end
    end

    self.ridingTrainingTimer:SetHandler("OnUpdate", OnTimerUpdate)

    local function OnCharacterUpdate(_, currentFrameTimeSeconds)
        if self.nextCharacterRefreshSeconds < currentFrameTimeSeconds then
            self:RefreshCharacterPanel()
        end    
    end

    self.characterStatsPanel:SetHandler("OnUpdate", OnCharacterUpdate)
end

do
    local STATS_LAYOUT_DATA =
    {
        --sections
        {
            --lines
            {   
                STAT_MAGICKA_MAX, 
                STAT_MAGICKA_REGEN_COMBAT,
            },
            {   
                STAT_HEALTH_MAX, 
                STAT_HEALTH_REGEN_COMBAT,
            },
            {   
                STAT_STAMINA_MAX, 
                STAT_STAMINA_REGEN_COMBAT,
            },
        },
        {
            {   
                STAT_SPELL_POWER, 
                STAT_POWER,
            },
            {   
                STAT_SPELL_CRITICAL, 
                STAT_CRITICAL_STRIKE,
            },
        },
        {
            {   
                STAT_SPELL_RESIST, 
                STAT_PHYSICAL_RESIST,
            },
            {   
                STAT_CRITICAL_RESISTANCE,
            },
        },
    }

    local COLUMN_WIDTH = 375
    local ROW_HEIGHT = 40
    local COLUMN_SPACING = 40
    local SECTION_SPACING = 50
    local STARTING_Y_OFFSET = 20
    local STARTING_X_OFFSET = 0

    function ZO_GamepadStats:InitializeAttributesPanel()
        self.attributesPanel = self.infoPanel:GetNamedChild("AttributesPanel")
        self.attributeItems = {}

        --Tooltips Setup
        local ROW_MAJOR = true
        local function OnViewAttributesBack()
            self:DeactivateViewAttributes()
        end
        self.attributeTooltips = ZO_AttributeTooltipsGrid_Gamepad:New(self.attributesPanel, ROW_MAJOR, OnViewAttributesBack)

        local rowNumber = 1
        local EQUIPMENT_BONUS_COLUMN = 1

        --Equipment Bonus
        self.equipmentBonus = self.control:GetNamedChild("RightPane"):GetNamedChild("EquipmentBonus")
        local equipmentBonusIcons = self.equipmentBonus:GetNamedChild("Icons")
        self.equipmentBonus.iconPool = ZO_ControlPool:New("ZO_GamepadStatsEquipmentBonusIcon", equipmentBonusIcons)
        self.attributeTooltips:AddGridItem(self.equipmentBonus, STAT_NONE, EQUIPMENT_BONUS_COLUMN, rowNumber)
        rowNumber = rowNumber + 1

        -- Attributes
        local function CreateAttribute(objectPool)
            local attributeControl = ZO_ObjectPool_CreateControl("ZO_GamepadStatsHeaderDataPairTemplate", objectPool, self.attributesPanel)
            return ZO_AttributeItem_Gamepad:New(attributeControl)
        end
        self.attributeItemPool = ZO_ObjectPool:New(CreateAttribute)

        local yOffset = STARTING_Y_OFFSET
        for sectionNumber, section in ipairs(STATS_LAYOUT_DATA) do
            for lineNumber, line in ipairs(section) do
                local xOffset = STARTING_X_OFFSET
                for columnNumber, statType in ipairs(line) do
                    local attributeItem = self.attributeItemPool:AcquireObject()
                    attributeItem.control:SetAnchor(TOPLEFT, self.attributesPanel, TOPLEFT, xOffset, yOffset)
                    attributeItem.control:SetAnchor(TOPRIGHT, self.attributesPanel, TOPLEFT, xOffset + COLUMN_WIDTH, yOffset)
                    attributeItem:SetAttributeInfo(statType)
                    self.attributeItems[statType] = attributeItem
                    self.attributeTooltips:AddGridItem(attributeItem.control, statType, columnNumber, rowNumber)
                    xOffset = xOffset + COLUMN_WIDTH + COLUMN_SPACING
                end
                rowNumber = rowNumber + 1
                yOffset = yOffset + ROW_HEIGHT
            end
            yOffset = yOffset + SECTION_SPACING
        end

        --Update Info
        self.nextAttributeRefreshSeconds = 0
        self.nextCharacterRefreshSeconds = 0

        local function OnAttributesUpdate(_, currentFrameTimeSeconds)
            if self.nextAttributeRefreshSeconds < currentFrameTimeSeconds then
                self:RefreshAttributesPanel()
            end    
        end
        self.attributesPanel:SetHandler("OnUpdate", OnAttributesUpdate)
    end
end

function ZO_GamepadStats:RefreshAttributesPanel()
    self.nextAttributeRefreshSeconds = GetFrameTimeSeconds() + ZO_STATS_REFRESH_TIME_SECONDS

    for key, attribute in pairs(self.attributeItems) do
        attribute:RefreshText()
    end

    self:RefreshContentHeader(GetString(SI_STATS_ATTRIBUTES))
end

function ZO_GamepadStats:RefreshCharacterPanel()
    self.nextCharacterRefreshSeconds = GetFrameTimeSeconds() + ZO_STATS_REFRESH_TIME_SECONDS

    -- Left & Right Column
    local unitRace = GetUnitRace("player")
    local unitClass = GetUnitClass("player")
    self.race:SetText(zo_strformat(GetString(SI_STAT_GAMEPAD_RACE_NAME), unitRace))
    self.class:SetText(zo_strformat(GetString(SI_STAT_GAMEPAD_CLASS_NAME), unitClass))

    local hasChampionPoints = IsChampionSystemUnlocked()
    self.championPointsHeader:SetHidden(not hasChampionPoints)
    self.championPoints:SetHidden(not hasChampionPoints)
    if hasChampionPoints then
        self.championPoints:SetText(GetPlayerChampionPointsEarned())
    end

    -- Right Pane
    local allianceName = GetAllianceName(GetUnitAlliance("player"))
    self.alliance:SetText(zo_strformat(SI_ALLIANCE_NAME, allianceName))

    local rank, subRank = GetUnitAvARank("player")
    local rankName = GetAvARankName(GetUnitGender("player"), rank)
    local rankString
    if rank == 0 then
        rankString = zo_strformat(SI_STAT_RANK_NAME_FORMAT, rankName)
    else
        local rankIcon = GetAvARankIcon(rank)
        rankString = zo_iconTextFormatNoSpace(rankIcon, 32, 32, zo_strformat(SI_STAT_RANK_NAME_FORMAT, rankName))
    end
    self.rank:SetText(rankString)

    --Riding skill
    local speedBonus, _, staminaBonus, _, inventoryBonus = STABLE_MANAGER:GetStats()
    self.ridingSpeed:SetText(zo_strformat(SI_MOUNT_ATTRIBUTE_SPEED_FORMAT, speedBonus))
    self.ridingStamina:SetText(staminaBonus)
    self.ridingCapacity:SetText(inventoryBonus)

    local ridingSkillMaxedOut = STABLE_MANAGER:IsRidingSkillMaxedOut()
    local readyToTrain = GetTimeUntilCanBeTrained() == 0
    self.ridingTrainingHeader:SetHidden(ridingSkillMaxedOut)
    self.ridingTrainingTimer:SetHidden(ridingSkillMaxedOut or readyToTrain)
    self.ridingTrainingReady:SetHidden(ridingSkillMaxedOut or not readyToTrain)

    
    local currentLevel
    local currentXP
    local totalXP
    local hideEnlightenment = true
    if CanUnitGainChampionPoints("player") then
        currentLevel = GetPlayerChampionPointsEarned()
        currentXP = GetPlayerChampionXP()
        totalXP = GetNumChampionXPInChampionPoint(currentLevel)
        hideEnlightenment = false
    else
        currentLevel = GetUnitLevel("player")
        currentXP = GetUnitXP("player")
        totalXP = GetNumExperiencePointsInLevel(currentLevel)
        ZO_StatusBar_SetGradientColor(self.experienceBarControl, ZO_XP_BAR_GRADIENT_COLORS)
        ZO_StatusBar_SetGradientColor(self.experienceBarControl:GetNamedChild("EnlightenedBar"), ZO_XP_BAR_GRADIENT_COLORS)
    end

    if not totalXP then -- this is for the end of the line
        totalXP = 1
        currentXP = 1
        hideEnlightenment = true
        self.experienceProgress:SetText(GetString(SI_EXPERIENCE_LIMIT_REACHED))
        ZO_StatusBar_SetGradientColor(self.experienceBarControl, ZO_CP_BAR_GRADIENT_COLORS[GetChampionPointAttributeForRank(currentLevel)])
    else
        local percentageXP = zo_floor(currentXP / totalXP * 100)
        self.experienceProgress:SetText(zo_strformat(SI_EXPERIENCE_CURRENT_MAX_PERCENT, ZO_CommaDelimitNumber(currentXP), ZO_CommaDelimitNumber(totalXP), percentageXP))
    end
    local BAR_NO_WRAP = true
    self.experienceBar:SetValue(currentLevel, currentXP, totalXP, BAR_NO_WRAP)

    self.enlightenmentText:SetHidden(hideEnlightenment)
    if not hideEnlightenment then
        if GetNumChampionXPInChampionPoint(currentLevel) ~= nil then
            currentLevel = currentLevel + 1
        end
        local nextPoint = GetChampionPointAttributeForRank(currentLevel)
        if totalXP then
            local poolSize = self:GetEnlightenedPool()
            self.enlightenedBarControl:SetHidden(false)
            self.enlightenedBarControl:SetMinMax(0, totalXP)
            self.enlightenedBarControl:SetValue(zo_min(totalXP, currentXP + poolSize))
            if poolSize > 0 then
                self.enlightenmentText:SetHidden(false)
                self.enlightenmentText:SetText(zo_strformat(SI_EXPERIENCE_CHAMPION_ENLIGHTENED_TOOLTIP, ZO_CommaDelimitNumber(poolSize)))
            else
                self.enlightenmentText:SetHidden(true)
            end
        else
            self.enlightenmentText:SetHidden(false)
            self.enlightenmentText:SetText(GetString(SI_EXPERIENCE_CHAMPION_ENLIGHTENED_TOOLTIP_MAXED))
        end
        ZO_StatusBar_SetGradientColor(self.experienceBarControl, ZO_CP_BAR_GRADIENT_COLORS[nextPoint])
        ZO_StatusBar_SetGradientColor(self.experienceBarControl:GetNamedChild("EnlightenedBar"), ZO_CP_BAR_GRADIENT_COLORS[nextPoint])
    else
        self.enlightenedBarControl:SetHidden(true)
    end
    self:RefreshContentHeader(GetString(SI_STAT_GAMEPAD_CHARACTER_SHEET_DESCRIPTION))
end

function ZO_GamepadStats:GetEnlightenedPool()
    if IsEnlightenedAvailableForCharacter() then
        return GetEnlightenedPool() * (GetEnlightenedMultiplier() + 1)
    else
        return 0
    end
end

function ZO_GamepadStats_OnInitialize(control)
    GAMEPAD_STATS = ZO_GamepadStats:New(control)
end

function ZO_GamepadStats:SetCurrentTitleDropdown(dropdown)
    self.currentTitleDropdown = dropdown
end

------------------------------
-- Stat Title Attribute Row --
------------------------------

function ZO_GamepadStatTitleRow_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control.dropdown:SetSortsItems(false)

    data.statsObject:SetCurrentTitleDropdown(control.dropdown)
    data.statsObject:UpdateTitleDropdownTitles(control.dropdown)

    control.dropdown:SetDeactivatedCallback(data.statsObject.OnTitleDropdownDeactivated, data.statsObject)
    control.dropdown:SetSelectedItemTextColor(selected)
end

------------------------
-- Stat Attribute Row --
------------------------

function ZO_GamepadStatAttributeRow_Setup(control, data, selected, selectedDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)

    local availablePoints = GetAttributeUnspentPoints()
    local showSpinnerArrows = (availablePoints > 0)

    control.spinnerDecrease:SetHidden(not showSpinnerArrows)
    control.spinnerIncrease:SetHidden(not showSpinnerArrows)

    control.attributeType = data.attributeType

    local function SetAttributeText(points, addedPoints)
        if addedPoints > 0 then
            control.pointLimitedSpinner.pointsSpinner:SetNormalColor(STAT_HIGHER_COLOR)
        else
            control.pointLimitedSpinner.pointsSpinner:SetNormalColor(ZO_SELECTED_TEXT)
        end
    end

    local function onValueChangedCallback(points, addedPoints)
        data.screen:SetAddedPoints(control.attributeType, addedPoints)
        SetAttributeText(points, addedPoints)
    end

    local addedPoints = data.screen:GetAddedPoints(data.attributeType)

    if control.pointLimitedSpinner == nil then
        control.pointLimitedSpinner = ZO_AttributeSpinner_Gamepad:New(control, control.attributeType, data.screen, onValueChangedCallback)
        control.pointLimitedSpinner:ResetAddedPoints()
    else
        control.pointLimitedSpinner:Reinitialize(control.attributeType, addedPoints, onValueChangedCallback)
    end

    control.pointLimitedSpinner:SetActive(selected)

    SetAttributeText(control.pointLimitedSpinner:GetPoints(), addedPoints)
end