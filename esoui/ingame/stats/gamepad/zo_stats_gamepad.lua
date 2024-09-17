
ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_ENTRY_WIDTH = 350
ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_ENTRY_HEIGHT = 40
ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_HEADER_WIDTH = 700
ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_X = 40
ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_Y = 0
ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_SECTION_SPACING = 40

--Attribute Spinner

ZO_AttributeSpinner_Gamepad = ZO_AttributeSpinner_Shared:Subclass()

function ZO_AttributeSpinner_Gamepad:New(attributeControl, attributeType, attributeManager, valueChangedCallback)
    local attributeSpinner = ZO_AttributeSpinner_Shared.New(self, attributeControl, attributeType, attributeManager, valueChangedCallback)
    attributeSpinner:SetSpinner(ZO_Spinner_Gamepad:New(attributeControl.spinner, 0, 0, GAMEPAD_SPINNER_DIRECTION_HORIZONTAL))
    return attributeSpinner
end

function ZO_AttributeSpinner_Gamepad:SetActive(active)
    self.pointsSpinner:SetActive(active)
end

--ZO_AttributeItem

ZO_AttributeItem_Gamepad = ZO_InitializingObject:Subclass()

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
    self.headerText = text
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
    self.valueText = text
end

function ZO_AttributeItem_Gamepad:RefreshBonusText()
    local bonusValue = GAMEPAD_STATS:GetPendingStatBonuses(self.statType)
    local hideBonus = bonusValue == 0 or bonusValue == nil
    self.bonus:SetHidden(hideBonus)
    self.bonusText = nil
    if not hideBonus then
        if bonusValue > 0 then
            self.bonusText = zo_strformat(SI_STAT_PENDING_BONUS_FORMAT, bonusValue)
            self.bonus:SetText(self.bonusText)
            self.bonus:SetColor(STAT_HIGHER_COLOR:UnpackRGBA())
        else
            self.bonusText = zo_strformat(SI_STAT_PENDING_CHANGE_FORMAT, bonusValue)
            self.bonus:SetText(self.bonusText)
            self.bonus:SetColor(STAT_LOWER_COLOR:UnpackRGBA())
        end
    end
end

function ZO_AttributeItem_Gamepad:RefreshText()
    self:RefreshHeaderText()
    self:RefreshDataText()
    self:RefreshBonusText()
end

function ZO_AttributeItem_Gamepad:GetNarrationText()
    local headerNarration = SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.headerText)
    local bonusNarration = SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.bonusText)
    local valueNarration = SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.valueText)
    return { headerNarration, bonusNarration, valueNarration }
end

--ZO_AttributeTooltipsGrid_Gamepad

local ZO_AttributeTooltipsGrid_Gamepad = ZO_GamepadGrid:Subclass()

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
    ZO_GamepadGrid.Activate(self)
    self:RefreshGridHighlight()
end

function ZO_AttributeTooltipsGrid_Gamepad:Deactivate()
    ZO_GamepadGrid.Deactivate(self)
    if self.currentItemColumn and self.currentItemRow then
        local NOT_VISIBLE = false
        self:SetItemHighlightVisible(self.currentItemColumn, self.currentItemRow, NOT_VISIBLE)
    end

    local DO_NOT_RETAIN_FRAGMENT = false
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, DO_NOT_RETAIN_FRAGMENT)
end

function ZO_AttributeTooltipsGrid_Gamepad:GetNarrationText()
    if self.currentItemColumn and self.currentItemRow then
        local currentAttributeItem = self.attributeItems[self.currentItemRow][self.currentItemColumn]
        local currentStatType = currentAttributeItem.statType
        if currentStatType ~= STAT_NONE then
            return GAMEPAD_STATS:GetAttributeItem(currentStatType):GetNarrationText()
        else
            local bonusValue = GAMEPAD_STATS:GetEquipmentBonusInfo()
            local narrations = { SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STATS_EQUIPMENT_BONUS))}
            local bonusNarrationText
            if bonusValue == EQUIPMENT_BONUS_MAX_VALUE then
                bonusNarrationText = zo_strformat(SI_STAT_GAMEPAD_EQUIPMENT_BONUS_NARRATION, bonusValue, EQUIPMENT_BONUS_MAX_VALUE)
            else
                bonusNarrationText = zo_strformat(SI_STAT_GAMEPAD_EQUIPMENT_BONUS_NARRATION, bonusValue, EQUIPMENT_BONUS_MAX_VALUE - 1)
            end
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(bonusNarrationText))
            return narrations
        end
    end
end

function ZO_AttributeTooltipsGrid_Gamepad:GetHeaderNarration()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STATS_ATTRIBUTES))
end

--Stats

local GAMEPAD_STATS_COMMIT_POINTS_DIALOG_NAME = "GAMEPAD_STATS_COMMIT_POINTS"
local GAMEPAD_STATS_RESPEC_ATTRIBUTES_DIALOG_NAME = "GAMEPAD_STATS_RESPEC_ATTRIBUTES"

local GAMEPAD_STATS_DISPLAY_MODE = 
{
    CHARACTER = 1,
    ATTRIBUTES = 2,
    EFFECTS = 3,
    TITLE = 4,
    OUTFIT = 5,
    LEVEL_UP_REWARDS = 6,
    UPCOMING_LEVEL_UP_REWARDS = 7,
    ADVANCED_ATTRIBUTES = 8,
}

ZO_GamepadStats = ZO_InitializingObject.MultiSubclass(ZO_Stats_Common, ZO_Gamepad_ParametricList_Screen)

function ZO_GamepadStats:Initialize(control)
    ZO_Stats_Common.Initialize(self, control)
    GAMEPAD_STATS_ROOT_SCENE = ZO_InteractScene:New("gamepad_stats_root", SCENE_MANAGER, ZO_ATTRIBUTE_RESPEC_INTERACT_INFO)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_STATS_ROOT_SCENE)
    self:SetListsUseTriggerKeybinds(true)

    self.mainList = self:GetMainList()

    self.displayMode = GAMEPAD_STATS_DISPLAY_MODE.TITLE
    self.previewAvailable = true

    --Only allow the window to update once every quarter second so if buffs are updating like crazy we're not tanking the frame rate
    self:SetUpdateCooldown(250)

    GAMEPAD_STATS_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    GAMEPAD_STATS_FRAGMENT:SetHideOnSceneHidden(true)

    GAMEPAD_STATS_CHARACTER_INFO_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(control:GetNamedChild("RightPane"))

    GAMEPAD_STATS_ROOT_SCENE:SetHideSceneConfirmationCallback(ZO_GamepadStats.OnConfirmHideScene)

    local function OnActivatedChanged()
        if self.mainList:IsActive() then
            local selectedControl = self.mainList:GetSelectedControl()
            if selectedControl and selectedControl.pointLimitedSpinner then
                selectedControl.pointLimitedSpinner:SetActive(true)
            end
        end
    end
    self.mainList:RegisterCallback("ActivatedChanged", OnActivatedChanged)

    self:InitializeRespecConfirmationGoldDialog()
end

function ZO_GamepadStats.OnConfirmHideScene(scene, nextSceneName, bypassHideSceneConfirmationReason)
    if bypassHideSceneConfirmationReason == nil and GAMEPAD_STATS:DoesAttributePointAllocationModeBatchSave() then

        ZO_Dialogs_ShowGamepadDialog("CONFIRM_REVERT_CHANGES",
        {
            confirmCallback = function() scene:AcceptHideScene() end,
            declineCallback = function() scene:RejectHideScene() end,
        })
    else
        scene:AcceptHideScene()
    end
end

function ZO_GamepadStats:OnStateChanged(oldState, newState)
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

        ZO_OUTFITS_SELECTOR_GAMEPAD:SetCurrentActorCategory(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    elseif newState == SCENE_HIDDEN then
        self:DeactivateMainList()

        if self.currentTitleDropdown ~= nil then
            self.currentTitleDropdown:Deactivate(true)
        end

        if self.attributeTooltips then
            self.attributeTooltips:Deactivate()
        end

        if self.advancedAttributesGridList then
            self:ExitAdvancedGridList()
        end

        self:ResetAttributeData()
        self:SetAttributePointAllocationMode(ATTRIBUTE_POINT_ALLOCATION_MODE_PURCHASE_ONLY)

        self:UnregisterForEvents()
    end
    ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
end

function ZO_GamepadStats:SelectAttributes()
    local attributeData = self.attributeEntries and self.attributeEntries[1]
    if attributeData then
        local UNSPECIFIED_TEMPLATE = nil
        local attributeIndex = self.mainList:GetIndexForData(UNSPECIFIED_TEMPLATE, attributeData)
        self.mainList:SetSelectedIndex(attributeIndex)
    end
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
        TITLE_MANAGER:RegisterCallback("UpdateTitlesData", OnUpdate)
        self.control:RegisterForEvent(EVENT_CHAMPION_POINT_GAINED, OnUpdate)
        self.control:RegisterForEvent(EVENT_CHAMPION_SYSTEM_UNLOCKED, OnUpdate)
        self.control:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_ADDED, OnUpdate)
        self.control:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_REMOVED, OnUpdate)
        STABLE_MANAGER:RegisterCallback("StableMountInfoUpdated", OnUpdate)
        ZO_LEVEL_UP_REWARDS_MANAGER:RegisterCallback("OnLevelUpRewardsUpdated", OnUpdate)
        self.control:SetHandler("OnUpdate", function()
            local isPreviewingAvailable = IsCharacterPreviewingAvailable()
            if self.previewAvailable ~= isPreviewingAvailable then
                self.previewAvailable = isPreviewingAvailable
                if self.previewAvailable then
                    self.outfitSelectorHeaderFocus:Enable()
                else
                    self.outfitSelectorHeaderFocus:Disable()
                end
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end
        end)
    end

    function ZO_GamepadStats:UnregisterForEvents()
        self.control:UnregisterForEvent(EVENT_STATS_UPDATED)
        self.control:UnregisterForEvent(EVENT_LEVEL_UPDATE)
        self.control:UnregisterForEvent(EVENT_EFFECT_CHANGED)
        self.control:UnregisterForEvent(EVENT_EFFECTS_FULL_UPDATE)
        self.control:UnregisterForEvent(EVENT_ATTRIBUTE_UPGRADE_UPDATED)
        self.control:UnregisterForEvent(EVENT_TITLE_UPDATE)
        TITLE_MANAGER:UnregisterCallback("UpdateTitlesData", OnUpdate)
        self.control:UnregisterForEvent(EVENT_CHAMPION_POINT_GAINED)
        self.control:UnregisterForEvent(EVENT_CHAMPION_SYSTEM_UNLOCKED)
        self.control:UnregisterForEvent(EVENT_ARTIFICIAL_EFFECT_ADDED)
        self.control:UnregisterForEvent(EVENT_ARTIFICIAL_EFFECT_REMOVED)
        STABLE_MANAGER:UnregisterCallback("StableMountInfoUpdated", OnUpdate)
        ZO_LEVEL_UP_REWARDS_MANAGER:UnregisterCallback("OnLevelUpRewardsUpdated", OnUpdate)
        self.control:SetHandler("OnUpdate", nil)
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
    if self:IsCurrentList(self.mainList) and not self.mainList:IsActive() then
        self:ActivateCurrentList()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadStats:DeactivateMainList()
    if self:IsCurrentList(self.mainList) and self.mainList:IsActive() then
        self:DeactivateCurrentList()

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

        local currentDropdownTitleIndex = self:GetDropdownTitleIndex(self.currentTitleDropdown)
        self.currentTitleDropdown:SetHighlightedItem(currentDropdownTitleIndex)
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

function ZO_GamepadStats:GetUnspentAttributePoints()
    local availablePoints = GetAttributeUnspentPoints()

    for attributeType = 1, GetNumAttributes() do
        availablePoints = availablePoints - self.attributeData[attributeType].addedPoints
    end

    return availablePoints
end

function ZO_GamepadStats:ResetAttributeData()
    self.attributeData = {}

    for attributeType = 1, GetNumAttributes() do
        self.attributeData[attributeType] =
        {
            addedPoints = 0,
        }
    end

    for attributeType, statType in pairs(STAT_TYPES) do
        self:UpdatePendingStatBonuses(statType, 0)
    end
end

function ZO_GamepadStats:DoesChangeIncurCost()
    for attributeType = 1, GetNumAttributes() do
        if self.attributeData[attributeType].addedPoints < 0 then
            return true
        end
    end
    return false
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
    self:InitializeAdvancedAttributesPanel()
    self:InitializeCharacterEffects()

    self:InitializeHeader()
    self:InitializeCommitPointsDialog()
    self:InitializeRespecAttributesDialog()
    self:InitializeMainListEntries()
end

function ZO_GamepadStats:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select / Commit Points
        {
            name = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.OUTFIT
                    or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE
                    or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.LEVEL_UP_REWARDS then
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                else
                    if self:DoesAttributePointAllocationModeBatchSave() then
                        return GetString(SI_STATS_CONFIRM_ATTRIBUTES_BUTTON)
                    else
                        return GetString(SI_STAT_GAMEPAD_COMMIT_POINTS)
                    end
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.OUTFIT and not self.previewAvailable then
                    return false, GetString("SI_EQUIPOUTFITRESULT", EQUIP_OUTFIT_RESULT_OUTFIT_SWITCHING_UNAVAILABLE)
                end

                return true
            end,
            visible = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.OUTFIT
                    or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE
                    or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.LEVEL_UP_REWARDS then
                    return true
                else
                    return self:DoesAttributePointAllocationModeBatchSave() or self:GetNumPointsAdded() > 0
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
                    if self:DoesAttributePointAllocationModeBatchSave() and self:DoesChangeIncurCost() then
                        if self:IsPaymentTypeScroll() then
                            ZO_Dialogs_ShowPlatformDialog("STAT_EDIT_CONFIRM")
                        else
                            ZO_Dialogs_ShowPlatformDialog("ATTRIBUTE_RESPEC_CONFIRM_GOLD_GAMEPAD")
                        end
                    else
                        ZO_Dialogs_ShowGamepadDialog(GAMEPAD_STATS_COMMIT_POINTS_DIALOG_NAME)
                    end
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
                    local targetData = self.mainList:GetTargetData()
                    if targetData ~= nil and targetData.buffSlot ~= nil then
                        return targetData.canClickOff
                    end
                    return false
                elseif self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.ATTRIBUTES or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.ADVANCED_ATTRIBUTES then
                    return true
                end
                return false
            end,
            callback = function()
                if self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.EFFECTS then
                    local targetData = self.mainList:GetTargetData()
                    CancelBuff(targetData.buffSlot)
                elseif self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.ADVANCED_ATTRIBUTES then
                    self:DeactivateMainList()
                    self:EnterAdvancedGridList()
                else
                    self:ActivateViewAttributes()
                end
            end,
        },
        -- Clear Attributes
        {
            name = GetString(SI_STATS_CLEAR_ALL_ATTRIBUTES_BUTTON),
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                return self:DoesAttributePointAllocationModeBatchSave() and self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.ATTRIBUTES
            end,
            callback = function()
                self:ResetAttributeData()
                for index, attributeData in ipairs(self.attributeEntries) do
                    local control = self.mainList:GetControlFromData(attributeData)
                    control.pointLimitedSpinner:RefreshSpinnerMax()
                    control.pointLimitedSpinner.pointsSpinner:SetValue(0)
                end
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self.advancedStatsKeybindStripDescriptor = {}
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.advancedStatsKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:ExitAdvancedGridList()
        self:ActivateMainList()
    end)
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

function ZO_GamepadStats:SetAttributePointAllocationMode(attributePointAllocationMode)
    ZO_Stats_Common.SetAttributePointAllocationMode(self, attributePointAllocationMode)

    if self:IsShowing() then
        self:RefreshMainList()
    end
end

function ZO_GamepadStats:PurchaseAttributes()
    PlaySound(SOUNDS.STATS_PURCHASE)
    PurchaseAttributes(self.attributeData[ATTRIBUTE_HEALTH].addedPoints, self.attributeData[ATTRIBUTE_MAGICKA].addedPoints, self.attributeData[ATTRIBUTE_STAMINA].addedPoints)
    self:ResetAttributeData()
    self:SetAttributePointAllocationMode(ATTRIBUTE_POINT_ALLOCATION_MODE_PURCHASE_ONLY)
end

function ZO_GamepadStats:RespecAttributes()
    PlaySound(SOUNDS.STATS_PURCHASE)
    SendAttributePointAllocationRequest(self.attributeRespecPaymentType, self.attributeData[ATTRIBUTE_HEALTH].addedPoints, self.attributeData[ATTRIBUTE_MAGICKA].addedPoints, self.attributeData[ATTRIBUTE_STAMINA].addedPoints)
    self:ResetAttributeData()
    self:SetAttributePointAllocationMode(ATTRIBUTE_POINT_ALLOCATION_MODE_PURCHASE_ONLY)
end

function ZO_GamepadStats:UpdateScreenVisibility()
    local isAttributesHidden = true
    local isCharacterHidden = true
    local isEffectsHidden = true
    local showUpcomingRewards = false
    local isAdvancedAttributesHidden = true

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
    elseif self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.ADVANCED_ATTRIBUTES then
        isAdvancedAttributesHidden = false
        self:RefreshAdvancedAttributesPanel()
    end

    self.characterStatsPanel:SetHidden(isCharacterHidden)
    self.attributesPanel:SetHidden(isAttributesHidden)
    self.equipmentBonus:SetHidden(isAttributesHidden)
    self.characterEffects:SetHidden(isEffectsHidden)
    self.advancedAttributesPanel:SetHidden(isAdvancedAttributesHidden)

    local hideQuadrant2_3Background = isAttributesHidden and isCharacterHidden and isEffectsHidden and isAdvancedAttributesHidden
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

    local targetData = self.mainList:GetTargetData()

    if self.outfitSelectorHeaderFocus:IsActive() then
        self.displayMode = GAMEPAD_STATS_DISPLAY_MODE.OUTFIT
    elseif targetData.displayMode ~= nil then
        self.displayMode = targetData.displayMode
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

function ZO_GamepadStats:EnterAdvancedGridList()
    self.advancedAttributesGridList:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.advancedStatsKeybindStripDescriptor)
end

function ZO_GamepadStats:ExitAdvancedGridList()
    self.advancedAttributesGridList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.advancedStatsKeybindStripDescriptor)
end

--------------------------
-- Commit Points Dialog --
--------------------------

function ZO_GamepadStats:InitializeCommitPointsDialog()
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_STATS_COMMIT_POINTS_DIALOG_NAME,
    {
        gamepadInfo =
        {
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
                    self:SetAttributePointAllocationMode(ATTRIBUTE_POINT_ALLOCATION_MODE_PURCHASE_ONLY)
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_DIALOG_NO_BUTTON,
            },
        }
    })
end

--------------------------
-- Respec Attributes Dialog --
--------------------------

function ZO_GamepadStats:InitializeRespecAttributesDialog()
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_STATS_RESPEC_ATTRIBUTES_DIALOG_NAME,
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = SI_STAT_GAMEPAD_CHANGE_ATTRIBUTES,
        },

        mainText = 
        {
            text = SI_STAT_GAMEPAD_COMMIT_POINTS_CONFIRM_CHANGES,
        },

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_DIALOG_YES_BUTTON,
                callback = function()
                    self:RespecAttributes()
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

        messageTextNarration = function()
            local outfit = ZO_OUTFIT_MANAGER:GetOutfitManipulator(GAMEPLAY_ACTOR_CATEGORY_PLAYER, ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(GAMEPLAY_ACTOR_CATEGORY_PLAYER))
            if outfit then
                return zo_strformat(SI_SCREEN_NARRATION_DROPDOWN_NAMED, GetString(SI_OUTFIT_SELECTOR_TITLE), outfit:GetOutfitName())
            else
                return zo_strformat(SI_SCREEN_NARRATION_DROPDOWN_NAMED, GetString(SI_OUTFIT_SELECTOR_TITLE), GetString(SI_NO_OUTFIT_EQUIP_ENTRY))
            end
        end,
    }

    local rightPane = self.control:GetNamedChild("RightPane")
    local contentContainer = rightPane:GetNamedChild("HeaderContainer")
    self.contentHeader = contentContainer:GetNamedChild("Header")

    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)
    self.contentHeaderData = {}
end

function ZO_GamepadStats:RefreshHeader()
    self.headerData.data1Text = tostring(self:GetAvailablePoints())

    local currentActorCategory, currentlyEquippedOutfitIndex = ZO_OUTFITS_SELECTOR_GAMEPAD:GetCurrentActorCategoryAndIndex()
    if currentlyEquippedOutfitIndex then
        local currentOutfit = ZO_OUTFIT_MANAGER:GetOutfitManipulator(currentActorCategory, currentlyEquippedOutfitIndex)
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
        self.upcomingRewardsEntry.narrationText = function(entryData, entryControl)
            local narrations = {}
            -- Generate the standard parametric list entry narration
            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

            -- Append the upcoming level up text
            ZO_AppendNarration(narrations, ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS:GetNarrationText())

            return narrations
        end

        --Title Entry
        self.titleEntry = ZO_GamepadEntryData:New("")
        self.titleEntry.displayMode = GAMEPAD_STATS_DISPLAY_MODE.TITLE
        self.titleEntry:SetNew(function() return TITLE_MANAGER:HasNewTitle() end)
        self.titleEntry.statsObject = self
        self.titleEntry:SetHeader(GetString(SI_STATS_TITLE))
        self.titleEntry.narrationText = function(entryData, entryControl)
            return self.currentTitleDropdown:GetNarrationText()
        end

        --Advanced Stats Entry
        self.advancedStatsEntry = ZO_GamepadEntryData:New(GetString(SI_STATS_ADVANCED_ATTRIBUTES))
        self.advancedStatsEntry.displayMode = GAMEPAD_STATS_DISPLAY_MODE.ADVANCED_ATTRIBUTES
        self.advancedStatsEntry:SetHeader(GetString(SI_STATS_CHARACTER))

        --Character Entry
        self.characterEntry = ZO_GamepadEntryData:New(GetString(SI_STAT_GAMEPAD_CHARACTER_SHEET_DESCRIPTION))
        self.characterEntry.displayMode = GAMEPAD_STATS_DISPLAY_MODE.CHARACTER
        self.characterEntry.narrationText = function(entryData, entryControl)
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_CHARACTER_SHEET_DESCRIPTION)))

            --Get the narration for the player's race
            local unitRace = GetUnitRace("player")
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_RACE_LABEL)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_STAT_GAMEPAD_RACE_NAME, unitRace)))

            --Get the narration for the player's alliance
            local allianceName = GetAllianceName(GetUnitAlliance("player"))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_ALLIANCE_LABEL)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_ALLIANCE_NAME, allianceName)))

            --Get the narration for the player's class
            local unitClass = GetUnitClass("player")
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_CLASS_LABEL)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_STAT_GAMEPAD_CLASS_NAME, unitClass)))

            --Get the narration for the player's AVA Rank
            local rank, subRank = GetUnitAvARank("player")
            local rankName = GetAvARankName(GetUnitGender("player"), rank)
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_RANK_LABEL)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_STAT_RANK_NAME_FORMAT, rankName)))

            --Get the narration for the player's champion level if applicable
            if IsChampionSystemUnlocked() then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_CHAMPION_POINTS_LABEL)))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetPlayerChampionPointsEarned()))
            end

            --Get the narration for the player's current bounty if applicable
            local bountyNarration = GAMEPAD_STATS_BOUNTY_DISPLAY:GetNarrationText()
            if bountyNarration then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_BOUNTY_LABEL)))
                ZO_AppendNarration(narrations, bountyNarration)
            end

            local speedBonus, _, staminaBonus, _, inventoryBonus = STABLE_MANAGER:GetStats()
            --Get the narration for the player's riding speed
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_RIDING_HEADER_SPEED)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_MOUNT_ATTRIBUTE_SPEED_FORMAT, speedBonus)))

            --Get the narration for the player's riding stamina
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_RIDING_HEADER_STAMINA)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(staminaBonus))

            --Get the narration for the player's riding capacity
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_RIDING_HEADER_CAPACITY)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(inventoryBonus))

            --Get the narration for whether riding training is available if it isn't already maxed out
            if not STABLE_MANAGER:IsRidingSkillMaxedOut() then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_RIDING_HEADER_TRAINING)))
                local timeUntilCanBeTrained = GetTimeUntilCanBeTrained()
                --Either narrate that riding training is ready, or the time remaining until it's ready
                if timeUntilCanBeTrained == 0 then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_STABLE_TRAINABLE_READY)))
                else
                    local timeLeft = ZO_FormatTimeMilliseconds(timeUntilCanBeTrained, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(timeLeft))
                end
            end

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
            end

            --Get the narration for the player's xp progress
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_STAT_GAMEPAD_EXPERIENCE_LABEL)))
            --This is for when the XP limit has been reached
            if not totalXP then
                hideEnlightenment = true
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_EXPERIENCE_LIMIT_REACHED)))
            else
                local percentageXP = zo_floor(currentXP / totalXP * 100)
                local experienceProgress = zo_strformat(SI_EXPERIENCE_CURRENT_MAX_PERCENT, ZO_CommaDelimitNumber(currentXP), ZO_CommaDelimitNumber(totalXP), percentageXP)
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(experienceProgress))
            end

            --Get the narration for the player being enlightened if applicable
            if not hideEnlightenment then
                local poolSize = self:GetEnlightenedPool()
                if poolSize > 0 then
                    local enlightenmentText = zo_strformat(SI_EXPERIENCE_CHAMPION_ENLIGHTENED_TOOLTIP, ZO_CommaDelimitNumber(poolSize))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(enlightenmentText))
                end
            end

            return narrations
        end

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

            data.onValueChangedCallback = function()
                if self:IsShowing() then
                    -- Renarrate the list entry when points are added or removed
                    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList())
                end
            end

            data.narrationText = function(entryData, entryControl)
                local narrations = {}
                local displayedPoints = entryControl.pointLimitedSpinner:GetPoints() + self:GetAddedPoints(attributeType)
                ZO_AppendNarration(narrations, ZO_FormatSpinnerNarrationText(entryData.text, displayedPoints))
                ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryStatusIndicatorNarrationText(entryData, entryControl))

                return narrations
            end

            if index == 1 then
                data:SetHeader(GetString(SI_STATS_ATTRIBUTES))
            end
            table.insert(self.attributeEntries, data)
        end
    end

    function ZO_GamepadStats:GetFooterNarration()
        return GAMEPAD_PLAYER_PROGRESS_BAR_NAME_LOCATION:GetNarration()
    end

end

do
    local function SetupEffectAttributeRow(control, data, ...)
        ZO_SharedGamepadEntry_OnSetup(control, data, ...)
        local frameControl = control:GetNamedChild("Frame")
        --local stackCount = frameControl:GetNamedChild("StackCount")
        local hasIcon = data:GetNumIcons() > 0
        frameControl:SetHidden(not hasIcon)
        --stackCount:SetText(data.stackCount)
    end

    function ZO_GamepadStats:SetupList(list)
        list:SetHandleDynamicViewProperties(true)

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

function ZO_GamepadStats:OnTargetChanged(list, targetData, oldTargetData)
    if not (self.outfitSelectorHeaderFocus:IsActive() or self.attributeTooltips:IsActive()) then
        self.displayMode = targetData.displayMode
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
        self.mainList:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", self.advancedStatsEntry)
        self.mainList:AddEntry("ZO_GamepadMenuEntryTemplate", self.characterEntry)

        -- Active Effects--
        self.numActiveEffects = 0

        local function GetActiveEffectNarration(entryData, entryControl)
            local narrations = {}

            -- Generate the standard parametric list entry narration
            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

            -- Right panel header
            ZO_AppendNarration(narrations, ZO_GamepadGenericHeader_GetNarrationText(self.contentHeader, self.contentHeaderData))

            -- Right panel description
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.effectDescNarrationText))

            return narrations
        end

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

            data.narrationText = GetActiveEffectNarration

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
                local buffName, startTime, endTime, buffSlot, stackCount, iconFile, deprecatedBuffType, effectType, abilityType, statusEffectType, abilityId, canClickOff = GetUnitBuffInfo("player", i)

                if buffSlot > 0 and buffName ~= "" then
                    local data = ZO_GamepadEntryData:New(zo_strformat(SI_ABILITY_TOOLTIP_NAME, buffName), iconFile)
                    data.displayMode = GAMEPAD_STATS_DISPLAY_MODE.EFFECTS
                    data.buffIndex = i
                    data.buffSlot = buffSlot
                    data.canClickOff = canClickOff
                    data.isArtificial = false
                    --data.stackCount = stackCount

                    local duration = endTime - startTime
                    if duration > 0 then
                        local timeLeft = (endTime * 1000.0) - GetFrameTimeMilliseconds()
                        data:SetCooldown(timeLeft, duration * 1000.0)
                    end

                    data.narrationText = GetActiveEffectNarration

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
    local targetData = self.mainList:GetTargetData()

    local contentTitle, contentDescription, contentStartTime, contentEndTime, _

    if targetData.isArtificial then
        contentTitle, _, _, _, contentStartTime, contentEndTime = GetArtificialEffectInfo(targetData.artificialEffectId)
        contentDescription = GetArtificialEffectTooltipText(targetData.artificialEffectId)
    else
        local buffSlot, abilityId
        contentTitle, contentStartTime, contentEndTime, buffSlot, _, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", targetData.buffIndex)

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
    self.effectDescNarrationText = contentDescription
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
            {
                STAT_SPELL_PENETRATION,
                STAT_PHYSICAL_PENETRATION,
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

function ZO_GamepadStats:GetAttributeItem(statType)
    return self.attributeItems[statType]
end

function ZO_GamepadStats:InitializeAdvancedAttributesPanel()
    self.advancedAttributesPanel = self.infoPanel:GetNamedChild("AdvancedAttributesPanel")
    self.advancedAttributesGridList = ZO_GridScrollList_Gamepad:New(self.advancedAttributesPanel)

    local function SetupStatEntry(control, data, list)
         control.nameLabel:SetText(zo_strformat(SI_STAT_NAME_FORMAT, data.displayName))
         local _, flatValue, percentValue = GetAdvancedStatValue(data.statType)

         if data.formatType == ADVANCED_STAT_DISPLAY_FORMAT_FLAT then
            data.formattedValue = tostring(flatValue)
            control.valueLabel:SetText(flatValue)
         elseif data.formatType == ADVANCED_STAT_DISPLAY_FORMAT_PERCENT or data.formatType == ADVANCED_STAT_DISPLAY_FORMAT_FLAT_OR_PERCENT then
            data.formattedValue = zo_strformat(SI_STAT_VALUE_PERCENT, percentValue)
            control.valueLabel:SetText(data.formattedValue)
            if data.formatType == ADVANCED_STAT_DISPLAY_FORMAT_FLAT_OR_PERCENT then
                data.flatValue = flatValue
            end
         else
            control.valueLabel:SetText("")
            internalassert(false, "Invalid advanced stat format type.")
         end
         control.statData = data
    end

    local function SetupFlatValueEntry(control, data, list)
        local _, flatValue = GetAdvancedStatValue(data.statType)
        data.formattedValue = tostring(flatValue)
        control.valueLabel:SetText(flatValue)
    end

    local function SetupPercentValueEntry(control, data, list)
        local _, _, percentValue = GetAdvancedStatValue(data.statType)
        data.formattedValue = zo_strformat(SI_STAT_VALUE_PERCENT, percentValue)
        control.valueLabel:SetText(data.formattedValue)
    end

    local function SetupHeaderEntry(control, data, list)
        data.formattedValue = nil
        control.nameLabel:SetText(zo_strformat(SI_STAT_NAME_FORMAT, data.displayName))
    end

    --When nil is passed in for the reset function, ZO_ObjectPool_DefaultResetControl is what will get called
    local DEFAULT_RESET_ENTRY = nil
    local NO_HIDE_CALLBACK = nil
    self.advancedAttributesGridList:AddEntryTemplate("ZO_AdvancedAttributes_GridEntry_Template_Gamepad", ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_ENTRY_WIDTH, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_ENTRY_HEIGHT, SetupStatEntry, NO_HIDE_CALLBACK, DEFAULT_RESET_ENTRY, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_X, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_Y)
    self.advancedAttributesGridList:AddEntryTemplate("ZO_AdvancedAttributes_CategoryHeader_Template_Gamepad", ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_HEADER_WIDTH, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_ENTRY_HEIGHT, SetupHeaderEntry, NO_HIDE_CALLBACK, DEFAULT_RESET_ENTRY, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_X, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_Y)
    self.advancedAttributesGridList:AddEntryTemplate("ZO_AdvancedAttributes_GridEntryFlat_Template_Gamepad", ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_ENTRY_WIDTH, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_ENTRY_HEIGHT, SetupFlatValueEntry, NO_HIDE_CALLBACK, DEFAULT_RESET_ENTRY, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_X, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_Y)
    self.advancedAttributesGridList:AddEntryTemplate("ZO_AdvancedAttributes_GridEntryPercent_Template_Gamepad", ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_ENTRY_WIDTH, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_ENTRY_HEIGHT, SetupPercentValueEntry, NO_HIDE_CALLBACK, DEFAULT_RESET_ENTRY, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_X, ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_GRID_PADDING_Y)
    self.advancedAttributesGridList:RegisterCallback("SelectedDataChanged", function(...) self:OnAdvancedAttributeSelectionChanged(...) end )

    self:SetupAdvancedStats()

    --Update Info
    self.nextAdvancedAttributeRefreshSeconds = 0

    local function OnAdvancedAttributesUpdate(_, currentFrameTimeSeconds)
        if self.nextAdvancedAttributeRefreshSeconds < currentFrameTimeSeconds then
            self:RefreshAdvancedAttributesPanel()
        end    
    end
    self.advancedAttributesPanel:SetHandler("OnUpdate", OnAdvancedAttributesUpdate)
end

function ZO_GamepadStats:SetupAdvancedStats()
    --Make sure the grid list is empty before populating it
    self.advancedAttributesGridList:ClearGridList()

    --First, grab the stat data from the def
    local advancedStatData = {}
    local numCategories = GetNumAdvancedStatCategories()
    for categoryIndex = 1, numCategories do
        local categoryId = GetAdvancedStatsCategoryId(categoryIndex)
        local displayName, numStats = GetAdvancedStatCategoryInfo(categoryId)

        --ESO-819006: Only include categories with at least one stat in it
        if numStats > 0 then
            local categoryData =
            {
                header = displayName, --This field is not used on gamepad, but keeping it here in case we choose to show it later
                stats = {},
            }

            for statIndex = 1, numStats do
                local statType, statDisplayName, description, flatValueDescription, percentValueDescription = GetAdvancedStatInfo(categoryId, statIndex)

                --We need the format type ahead of time so we know what type of control(s) to create for this stat
                --We don't bother with the flat and percent values returned here, as they get refreshed every time we set up the control
                --The stat format type never changes, so it is safe to get it here
                local statFormatType = GetAdvancedStatValue(statType)

                local statData =
                {
                    statType = statType, --Used to calculate the value of the stat
                    displayName = statDisplayName, --The name shown to the users for the stat
                    description = description, --The description used in the tooltip window
                    flatDescription = flatValueDescription, --The description used for the flat value tooltip window when the stat is split into both flat and percent
                    percentDescription = percentValueDescription, --The description used for the percent value tooltip window when the stat is split into both flat and percent
                    formatType = statFormatType, --How are we formatting this stat?
                    narrationText = function(entryData) --How are we narrating this stat?
                        --If we do not have a formatted value, just use the display name
                        local narration = entryData.displayName
                        if entryData.formattedValue then
                            --Stats with entries for both flat and percent narrates both the name of the stat, and "Flat" or "Percent" depending on which entry is selected.
                            if entryData.secondaryDisplayName then
                                narration = zo_strformat(SI_STATS_ADVANCED_SCREEN_NARRATION_MULTI_ENTRY_FORMATTER, entryData.displayName, entryData.secondaryDisplayName, entryData.formattedValue)
                            else
                                narration = zo_strformat(SI_STATS_ADVANCED_SCREEN_NARRATION_FORMATTER, entryData.displayName, entryData.formattedValue)
                            end
                        end
                        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(narration)
                    end,
                }
                table.insert(categoryData.stats, statData)
            end

            table.insert(advancedStatData, categoryData)
        end
    end

    --Now, set up the actual list of stats based on the data we just grabbed
    for categoryIndex, statCategory in ipairs(advancedStatData) do
        --We want to have spacing between every category
        if categoryIndex > 1 then
            self.advancedAttributesGridList:AddLineBreak(ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_SECTION_SPACING)
        end

        local previousStatFormatType = nil

        --Add each stat in this category
        for statIndex, statEntry in ipairs(statCategory.stats) do
            if statEntry.formatType == ADVANCED_STAT_DISPLAY_FORMAT_FLAT_AND_PERCENT then
                --Make sure this isn't the first entry of the category, otherwise we will have double spacing
                if statIndex > 1 then
                    self.advancedAttributesGridList:AddLineBreak(ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_SECTION_SPACING)
                end

                --Multi value stats need 3 entries: the header, the flat value, and the percent value
                local categoryEntryData = ZO_GridSquareEntryData_Shared:New(statEntry)
                local flatEntryData = ZO_GridSquareEntryData_Shared:New(statEntry)
                local percentEntryData = ZO_GridSquareEntryData_Shared:New(statEntry)

                --Overwrite the flat entry and percent entry descriptions with the more specific ones
                flatEntryData.description = statEntry.flatDescription
                flatEntryData.secondaryDisplayName = GetString(SI_STATS_ADVANCED_VALUE_TYPE_FLAT)
                percentEntryData.description = statEntry.percentDescription
                percentEntryData.secondaryDisplayName = GetString(SI_STATS_ADVANCED_VALUE_TYPE_PERCENT)

                --Add the entries
                self.advancedAttributesGridList:AddEntry(categoryEntryData, "ZO_AdvancedAttributes_CategoryHeader_Template_Gamepad")
                self.advancedAttributesGridList:AddEntry(flatEntryData, "ZO_AdvancedAttributes_GridEntryFlat_Template_Gamepad")
                self.advancedAttributesGridList:AddEntry(percentEntryData, "ZO_AdvancedAttributes_GridEntryPercent_Template_Gamepad")
            else
                if previousStatFormatType == ADVANCED_STAT_DISPLAY_FORMAT_FLAT_AND_PERCENT then
                    self.advancedAttributesGridList:AddLineBreak(ZO_ADVANCED_STATS_GAMEPAD_CONSTANTS_SECTION_SPACING)
                end
                self.advancedAttributesGridList:AddEntry(statEntry, "ZO_AdvancedAttributes_GridEntry_Template_Gamepad")
            end

            previousStatFormatType = statEntry.formatType
        end
    end

    self.advancedAttributesGridList:CommitGridList()
end

function ZO_GamepadStats:RefreshAdvancedAttributesPanel()
    self.nextAdvancedAttributeRefreshSeconds = GetFrameTimeSeconds() + ZO_STATS_REFRESH_TIME_SECONDS
    self.advancedAttributesGridList:RefreshGridList()
    self:RefreshContentHeader(GetString(SI_STATS_ADVANCED_ATTRIBUTES))
end

function ZO_GamepadStats:OnAdvancedAttributeSelectionChanged(oldData, newData)
    --If we don't have new data this means we no longer have anything selected, so we want to hide the tooltip completely
    if not newData then
        local DO_NOT_RETAIN_FRAGMENT = false
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, DO_NOT_RETAIN_FRAGMENT)
    else
        local RETAIN_FRAGMENT = true;
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, RETAIN_FRAGMENT)
        GAMEPAD_TOOLTIPS:LayoutAdvancedAttributeTooltip(GAMEPAD_RIGHT_TOOLTIP, newData)
    end
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
        ZO_StatusBar_SetGradientColor(self.experienceBarControl, ZO_CP_BAR_GRADIENT_COLORS[GetChampionPointPoolForRank(currentLevel)])
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
        local nextPointPoolType = GetChampionPointPoolForRank(currentLevel)
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
        ZO_StatusBar_SetGradientColor(self.experienceBarControl, ZO_CP_BAR_GRADIENT_COLORS[nextPointPoolType])
        ZO_StatusBar_SetGradientColor(self.experienceBarControl:GetNamedChild("EnlightenedBar"), ZO_CP_BAR_GRADIENT_COLORS[nextPointPoolType])
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

function ZO_GamepadStats:InitializeRespecConfirmationGoldDialog()
    local dialogData =
    {
        data1 =
        {
            header = GetString(SI_GAMEPAD_SKILL_RESPEC_CONFIRM_DIALOG_BALANCE_HEADER),
        },
        data2 = 
        {
            header = GetString(SI_GAMEPAD_SKILL_RESPEC_CONFIRM_DIALOG_COST_HEADER),
        },
    }

    ZO_Dialogs_RegisterCustomDialog("ATTRIBUTE_RESPEC_CONFIRM_GOLD_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_ATTRIBUTE_RESPEC_CONFIRM_DIALOG_TITLE,
        },
        mainText = 
        {
            text = SI_ATTRIBUTE_RESPEC_CONFIRM_DIALOG_BODY_INTRO,
        },
        setup = function(dialog)
            local balance = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
            local cost = GetAttributeRespecGoldCost()
            local IS_GAMEPAD = true
            dialogData.data1.value = ZO_Currency_Format(balance, CURT_MONEY, ZO_CURRENCY_FORMAT_AMOUNT_ICON, IS_GAMEPAD)
            dialogData.data2.value = ZO_Currency_Format(cost, CURT_MONEY, balance > cost and ZO_CURRENCY_FORMAT_AMOUNT_ICON or ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON, IS_GAMEPAD)
            dialog.setupFunc(dialog, dialogData)
        end,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function()
                    GAMEPAD_STATS:RespecAttributes()
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end

------------------------------
-- Stat Title Attribute Row --
------------------------------

function ZO_GamepadStatTitleRow_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control.dropdown:SetSortsItems(false)
    control.dropdown:SetName(GetString(SI_STATS_TITLE))

    data.statsObject:SetCurrentTitleDropdown(control.dropdown)
    data.statsObject:UpdateTitleDropdownTitles(control.dropdown)
    local statsObject = data.statsObject
    statsObject:SetCurrentTitleDropdown(control.dropdown)
    statsObject:UpdateTitleDropdownTitles(control.dropdown)
    
    local function OnDropdownItemDeselected(control, data)
        if data.titleInfo and data.titleInfo.isNew then
            TITLE_MANAGER:ClearTitleNew(data.titleInfo.name)
            data.name = data.titleInfo.name
            control.nameControl:SetText(data.name)
        end
    end

    control.dropdown:RegisterCallback("OnItemDeselected", OnDropdownItemDeselected)
    control.dropdown:SetDeactivatedCallback(data.statsObject.OnTitleDropdownDeactivated, data.statsObject)
    control.dropdown:SetSelectedItemTextColor(selected)
end
------------------------
-- Stat Attribute Row --
------------------------

function ZO_GamepadStatAttributeRow_Setup(control, data, selected, selectedDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)

    local availablePoints = 0
    if data.screen.GetUnspentAttributePoints then
        availablePoints = data.screen:GetUnspentAttributePoints()
    else
        availablePoints = GetAttributeUnspentPoints()
    end
    local showSpinnerArrows = (availablePoints > 0)

    control.spinnerDecrease:SetHidden(not showSpinnerArrows)
    control.spinnerIncrease:SetHidden(not showSpinnerArrows)

    control.attributeType = data.attributeType

    local function SetAttributeText(points, addedPoints)
        if addedPoints > 0 then
            control.pointLimitedSpinner.pointsSpinner:SetNormalColor(STAT_HIGHER_COLOR)
        elseif addedPoints < 0 then
            control.pointLimitedSpinner.pointsSpinner:SetNormalColor(STAT_LOWER_COLOR)
        else
            control.pointLimitedSpinner.pointsSpinner:SetNormalColor(ZO_SELECTED_TEXT)
        end
    end

    local function onValueChangedCallback(points, addedPoints)
        data.screen:SetAddedPoints(control.attributeType, addedPoints)
        SetAttributeText(points, addedPoints)
        if data.onValueChangedCallback then
            data.onValueChangedCallback(data, control)
        end
    end

    local addedPoints = data.screen:GetAddedPoints(data.attributeType)

    if control.pointLimitedSpinner == nil then
        control.pointLimitedSpinner = ZO_AttributeSpinner_Gamepad:New(control, control.attributeType, data.screen, onValueChangedCallback)
        control.pointLimitedSpinner:ResetAddedPoints()
    else
        control.pointLimitedSpinner:Reinitialize(control.attributeType, addedPoints, onValueChangedCallback)
    end

    if active then
        control.pointLimitedSpinner:SetActive(selected)
    end

    SetAttributeText(control.pointLimitedSpinner:GetPoints(), addedPoints)

    local function GetDirectionalInputNarrationData()
        --Only narrate directional input if there is more than one possible value
        if control.pointLimitedSpinner.pointsSpinner:GetMin() ~= control.pointLimitedSpinner.pointsSpinner:GetMax() then
            local decreaseEnabled = control.pointLimitedSpinner.pointsSpinner:IsDecreaseEnabled()
            local increaseEnabled = control.pointLimitedSpinner.pointsSpinner:IsIncreaseEnabled()
            return ZO_GetNumericHorizontalDirectionalInputNarrationData(decreaseEnabled, increaseEnabled)
        else
            return {}
        end
    end

    data.additionalInputNarrationFunction = GetDirectionalInputNarrationData
end