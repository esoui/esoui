ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_TEMPLATE_DIMENSIONS_GAMEPAD = 103
ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_TEMPLATE_ICON_DIMENSIONS_GAMEPAD = 48
ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_GAMEPAD = 4
ZO_GAMEPAD_DAILY_LOGIN_REWARDS_GRID_ENTRY_BORDER_EDGE_WIDTH = 128
ZO_GAMEPAD_DAILY_LOGIN_REWARDS_GRID_ENTRY_BORDER_EDGE_HEIGHT = 16

ZO_DailyLoginRewards_Gamepad = ZO_Object.MultiSubclass(ZO_DailyLoginRewards_Base, ZO_Main_Menu_Helper_Panel_Gamepad)

function ZO_DailyLoginRewards_Gamepad:New(...)
    return ZO_Main_Menu_Helper_Panel_Gamepad.New(self, ...)
end

function ZO_DailyLoginRewards_Gamepad:Initialize(control)
    ZO_Main_Menu_Helper_Panel_Gamepad.Initialize(self, control)
    ZO_DailyLoginRewards_Base.Initialize(self, control)

    local contentHeader = control:GetNamedChild("ContentHeader")
    self.changeTimer = contentHeader:GetNamedChild("ChangeTimer")
    self.changeTimerValueLabel = self.changeTimer:GetNamedChild("Value")
    self.currentMonthLabel = contentHeader:GetNamedChild("CurrentMonth")
    self.particleGeneratorPosition = control:GetNamedChild("RewardParticleGeneratorPosition")
    self.lockedLabel = control:GetNamedChild("LockedText")

    self.blastParticleSystem:SetParentControl(self.particleGeneratorPosition)

    self.exitScreenByBackingOutOfPreviewIndex = 0

    local previewNarrationData =
    {
        canNarrate = function()
            return IsCurrentlyPreviewing()
        end,
        selectedNarrationFunction = function()
            return ITEM_PREVIEW_GAMEPAD:GetPreviewSpinnerNarrationText()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("dailyLoginRewardsPreview", previewNarrationData)

    self:InitializeGridListPanel()

    GAMEPAD_DAILY_LOGIN_PREVIEW_SCENE = ZO_Scene:New("dailyLoginRewardsPreview_Gamepad", SCENE_MANAGER)
    GAMEPAD_DAILY_LOGIN_PREVIEW_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnPreviewShowing()
        elseif newState == SCENE_SHOWN then
            self:OnPreviewShown()
        elseif newState == SCENE_HIDING then
            self:OnPreviewHiding()
        elseif newState == SCENE_HIDDEN then
            self:OnPreviewHidden()
        end
    end)
end

function ZO_DailyLoginRewards_Gamepad:InitializeGridListPanel()
    local gridListPanel = self.control:GetNamedChild("Rewards")
    self.gridListPanelControl = gridListPanel
    self.gridListPanelList = ZO_SingleTemplateGridScrollList_Gamepad:New(gridListPanel, ZO_GRID_SCROLL_LIST_AUTOFILL, "ZO_Daily_Login_Reward_Highlight_Gamepad")

    local function DailyLoginRewardsGridEntryReset(control)
        ZO_Daily_Login_Rewards_Gamepad_CleanupAnimationOnControl(control)
        self:GridEntryCleanup(control)
    end

    local HEADER_HEIGHT = 30
    local HIDE_CALLBACK = nil
    local CENTER_ENTRIES = true
    -- Add spacing in dimensions of entries to allow spaced for border, entries must also be centered for this to work correctly
    local GRID_LIST_TILE_DIMENSIONS_GAMEPAD = ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_TEMPLATE_DIMENSIONS_GAMEPAD + 1
    self.gridListPanelList:SetGridEntryTemplate("ZO_DailyLoginRewards_GridEntry_Template_Gamepad", GRID_LIST_TILE_DIMENSIONS_GAMEPAD, GRID_LIST_TILE_DIMENSIONS_GAMEPAD, self.dailyLoginRewardsGridEntrySetup, HIDE_CALLBACK, DailyLoginRewardsGridEntryReset, ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_GAMEPAD, ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_GAMEPAD, CENTER_ENTRIES)
    self.gridListPanelList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.gridListPanelList:SetHeaderPrePadding(ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_GAMEPAD * 3)
    self.gridListPanelList:SetOnSelectedDataChangedCallback(function(previousData, newData) self:OnGridListSelectedDataChanged(previousData, newData) end)

    local function GetHeaderNarration()
        local narrations = {}
        if not self.currentMonthLabel:IsHidden() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.currentMonthText))
        end

        if not self:ShouldChangeTimerBeHidden() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_DAILY_LOGIN_REWARDS_MONTH_CHANGE_TITLE)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.changeTimerValueText))
        end

        if not self.lockedLabel:IsHidden() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.lockedLabelText))
        end
        return narrations
    end
    self.gridListPanelList:SetHeaderNarrationFunction(GetHeaderNarration)
end

function ZO_DailyLoginRewards_Gamepad:SetupGridEntryBorderAndMilestone(control, data, controlPool)
    ZO_Daily_Login_Gamepad_SetRewardEntryBorder(control, data, controlPool)
end

function ZO_DailyLoginRewards_Gamepad:InitializeKeybinds()
    ZO_Main_Menu_Helper_Panel_Gamepad.InitializeKeybinds(self)

    -- Claim
    table.insert(self.keybindStripDescriptor,
    {
        name = GetString(SI_DAILY_LOGIN_REWARDS_CLAIM_KEYBIND),
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = function()
                        local numSlotsNeeded = GetNumInventorySlotsNeededForDailyLoginRewardInCurrentMonth(GetDailyLoginClaimableRewardIndex())
                        if CheckInventorySpaceAndWarn(numSlotsNeeded) then
                            self:SetTargetedClaimData(self.gridListPanelList:GetSelectedData())
                            PlaySound(SOUNDS.DAILY_LOGIN_REWARDS_ACTION_CLAIM)
                            ClaimCurrentDailyLoginReward()
                        end
                    end,
        enabled = function()
            local selectedReward = self.gridListPanelList:GetSelectedData()

            if selectedReward and selectedReward.day then
                return GetDailyLoginClaimableRewardIndex() == selectedReward.day
            end

            return false
        end,
    })

    -- Preview
    table.insert(self.keybindStripDescriptor,
    {
        name = GetString(SI_DAILY_LOGIN_REWARDS_PREVIEW_KEYBIND),
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = function()
            self.currentRewardPreviewIndex = self.gridListPanelList:GetSelectedDataIndex()
            SCENE_MANAGER:Push("dailyLoginRewardsPreview_Gamepad")
        end,
        visible = function()
            local selectedReward = self.gridListPanelList:GetSelectedData()

            if selectedReward and selectedReward.day then
                return CanPreviewReward(selectedReward:GetRewardId()) and IsCharacterPreviewingAvailable()
            end

            return false
        end,
    })

    self.previewKeybindStripDesciptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_GAMEPAD_PREVIEW_PREVIOUS),
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            callback = function()
                self:MovePreviewToPreviousReward()
            end,
            visible = function() return self:HasMultiplePreviews() end,
            enabled = function() return ITEM_PREVIEW_GAMEPAD:CanChangePreview() end,
        },
        {
            name = GetString(SI_GAMEPAD_PREVIEW_NEXT),
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            callback = function()
                self:MovePreviewToNextReward()
            end,
            visible = function() return self:HasMultiplePreviews() end,
            enabled = function() return ITEM_PREVIEW_GAMEPAD:CanChangePreview() end,
        },
        self:GetBackButtonDescriptor()
    }
end

function ZO_DailyLoginRewards_Gamepad:GetBackButtonDescriptor()
    local function backButtonCallback()
        self.exitScreenByBackingOutOfPreviewIndex = ZO_ScrollList_GetAutoSelectIndex(self.gridListPanelList.list)
        SCENE_MANAGER:HideCurrentScene()
    end
    return KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(backButtonCallback)
end

function ZO_DailyLoginRewards_Gamepad:UpdateTimeToNextMonthText(formattedTime)
    ZO_DailyLoginRewards_Base.UpdateTimeToNextMonthText(self, formattedTime)

    self.changeTimerValueText = formattedTime
    self.changeTimerValueLabel:SetText(self.changeTimerValueText)
end

function ZO_DailyLoginRewards_Gamepad:UpdateTimeToNextMonthVisibility()
    self.changeTimer:SetHidden(self:ShouldChangeTimerBeHidden())
end

function ZO_DailyLoginRewards_Gamepad:OnHiding()
    ZO_DailyLoginRewards_Base.OnHiding(self)
    self.gridListPanelList:Deactivate()
end

function ZO_DailyLoginRewards_Gamepad:Activate()
    self.gridListPanelList:Activate()
    ZO_Main_Menu_Helper_Panel_Gamepad.Activate(self)

    local previewData
    if self.exitScreenByBackingOutOfPreviewIndex > 0 then
        local data = self.gridListPanelList:GetData()
        if data and self.exitScreenByBackingOutOfPreviewIndex then
            previewData = data[self.exitScreenByBackingOutOfPreviewIndex].data
        end
    end

    local selectionData = previewData or self.defaultSelectionData
    if selectionData then
        local NO_CALLBACK = nil
        local ANIMATE_INSTANTLY = true
        self.gridListPanelList:ScrollDataToCenter(selectionData, NO_CALLBACK, ANIMATE_INSTANTLY)
    end
    self.exitScreenByBackingOutOfPreviewIndex = 0
end

function ZO_DailyLoginRewards_Gamepad:Deactivate()
    ZO_Main_Menu_Helper_Panel_Gamepad.Deactivate(self)
    self.gridListPanelList:Deactivate()
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_DailyLoginRewards_Gamepad:CleanDirty()
    ZO_DailyLoginRewards_Base.CleanDirty(self)

    if self.gridListPanelList:IsActive() and self.defaultSelectionData then
        local NO_CALLBACK = nil
        local ANIMATE_INSTANTLY = true
        self.gridListPanelList:ScrollDataToCenter(self.defaultSelectionData, NO_CALLBACK, ANIMATE_INSTANTLY)
    end
end

function ZO_DailyLoginRewards_Gamepad:OnGridListSelectedDataChanged(previousData, newData)
    self:RefreshTooltip(newData)
    if newData then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_DailyLoginRewards_Gamepad:RefreshTooltip(selectedData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

    if selectedData then
        if not selectedData.isEmptyCell then
            GAMEPAD_TOOLTIPS:LayoutDailyLoginReward(GAMEPAD_RIGHT_TOOLTIP, selectedData.day)
        end
    end
end

function ZO_DailyLoginRewards_Gamepad:IsShowing()
    return self.fragment:IsShowing()
end

function ZO_DailyLoginRewards_Gamepad:ShouldShowNextClaimableRewardBorder()
    return false
end

function ZO_DailyLoginRewards_Gamepad:HasRewards()
    return self.gridListPanelList:HasEntries()
end

do
    local PENDING_ANIMATION_INSET = 3
    function ZO_Daily_Login_Gamepad_SetRewardEntryBorder(control, data, pendingPool)
        local edgeTexture
        local isCurrentReward
        if data.isEmptyCell then
            control.isMilestoneTag:SetHidden(true)
            edgeTexture = "EsoUI/Art/Tooltips/Gamepad/gp_toolTip_edge_16.dds"
        else
            isCurrentReward = GetDailyLoginClaimableRewardIndex() == data.day
            local isMilestone = data.isMilestone
            if isCurrentReward then
                if not control.pendingLoop then
                    ZO_PendingLoop.ApplyToControl(control, pendingPool, PENDING_ANIMATION_INSET)
                end
                edgeTexture = "EsoUI/Art/Restyle/Gamepad/gp_outfits_edge_bluePending_16.dds"
            else
                if data.day > GetNumClaimableDailyLoginRewardsInCurrentMonth() then
                    edgeTexture = "EsoUI/Art/Tooltips/Gamepad/gp_toolTip_edge_grey_16.dds"
                else
                    edgeTexture = "EsoUI/Art/Tooltips/Gamepad/gp_toolTip_edge_16.dds"
                end
            end
            control.isMilestoneTag:SetHidden(not isMilestone)
        end

        if not isCurrentReward then
            ZO_Daily_Login_Rewards_Gamepad_CleanupAnimationOnControl(control)
        end

        control.borderBackground:SetEdgeTexture(edgeTexture, ZO_GAMEPAD_DAILY_LOGIN_REWARDS_GRID_ENTRY_BORDER_EDGE_WIDTH, ZO_GAMEPAD_DAILY_LOGIN_REWARDS_GRID_ENTRY_BORDER_EDGE_HEIGHT)
    end
end

function ZO_Daily_Login_Rewards_Gamepad_CleanupAnimationOnControl(control)
    if control.pendingLoop then
        control.pendingLoop:ReleaseObject()
    end
end

---------------------------
-- Preview Scene Functions
---------------------------

do
    local NEXT_INDEX = 1
    local PREVIOUS_INDEX = -1

    local function GetNextIndex(currentIndex, maxIndex, direction)
        if currentIndex == maxIndex and direction == NEXT_INDEX then
            return 1
        elseif currentIndex == 1 and direction == PREVIOUS_INDEX then
            return maxIndex
        end

        return currentIndex + direction
    end

    function ZO_DailyLoginRewards_Gamepad:MovePreviewToPreviousReward()
        local scrollData = self.gridListPanelList:GetData()
        local numScrollEntries = #scrollData
        local nextIndex = GetNextIndex(self.currentRewardPreviewIndex, numScrollEntries, PREVIOUS_INDEX)
        while nextIndex ~= self.currentRewardPreviewIndex do
            local selectedRewardEntry = scrollData[nextIndex]
            local rewardData = selectedRewardEntry.data
            if rewardData.day then
                if CanPreviewReward(rewardData:GetRewardId()) then
                    self:UpdatePreview(rewardData)
                    self.currentRewardPreviewIndex = nextIndex
                    return
                end
            end

            nextIndex = GetNextIndex(nextIndex, numScrollEntries, PREVIOUS_INDEX)
        end
    end

    function ZO_DailyLoginRewards_Gamepad:MovePreviewToNextReward()
        local scrollData = self.gridListPanelList:GetData()
        local numScrollEntries = #scrollData
        local nextIndex = GetNextIndex(self.currentRewardPreviewIndex, numScrollEntries, NEXT_INDEX)
        while nextIndex ~= self.currentRewardPreviewIndex do
            local selectedRewardEntry = scrollData[nextIndex]
            local rewardData = selectedRewardEntry.data
            if rewardData.day then
                if CanPreviewReward(rewardData:GetRewardId()) then
                    self:UpdatePreview(rewardData)
                    self.currentRewardPreviewIndex = nextIndex
                    return
                end
            end

            nextIndex = GetNextIndex(nextIndex, numScrollEntries, NEXT_INDEX)
        end
    end
end

function ZO_DailyLoginRewards_Gamepad:OnPreviewShowing()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.previewKeybindStripDesciptor)
end

function ZO_DailyLoginRewards_Gamepad:OnPreviewShown()
    local scrollData = self.gridListPanelList:GetData()
    local selectedReward = scrollData[self.currentRewardPreviewIndex]
    self:UpdatePreview(selectedReward.data)
    ITEM_PREVIEW_GAMEPAD:RegisterCallback("RefreshActions", function()
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("dailyLoginRewardsPreview")
    end)
end

function ZO_DailyLoginRewards_Gamepad:UpdatePreview(rewardData)
    SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
    SYSTEMS:GetObject("itemPreview"):PreviewReward(rewardData:GetRewardId())
    self:RefreshTooltip(rewardData)
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("dailyLoginRewardsPreview")
end

function ZO_DailyLoginRewards_Gamepad:OnPreviewHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.previewKeybindStripDesciptor)
    self.currentRewardPreviewIndex = 0
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
    ITEM_PREVIEW_GAMEPAD:UnregisterCallback("RefreshActions")
end

function ZO_DailyLoginRewards_Gamepad:OnPreviewHidden()

end

-------------------
-- XML Functions
-------------------

function ZO_DailyLoginRewards_Gamepad_OnInitialize(control)
    ZO_DAILY_LOGIN_REWARDS_GAMEPAD = ZO_DailyLoginRewards_Gamepad:New(control)
end