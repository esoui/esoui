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
    local FILL_ROW_WITH_EMPTY_CELLS = true
    self.gridListPanelList = ZO_GridScrollList_Gamepad:New(gridListPanel, FILL_ROW_WITH_EMPTY_CELLS, "ZO_Daily_Login_Reward_Highlight_Gamepad")

    local function DailyLoginRewardsGridEntryReset(control)
        ZO_Daily_Login_Rewards_Gamepad_CleanupAnimationOnControl(control, self.currentRewardAnimationPool)
        self:GridEntryCleanup(control)
    end

    local HEADER_HEIGHT = 30
    local HIDE_CALLBACK = nil
    local CENTER_ENTRIES = true
    -- Add spacing in dimensions of entries to allow spaced for border, entries must also be centered for this to work correctly
    local GRID_LIST_TILE_DIMENSIONS_GAMEPAD = ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_TEMPLATE_DIMENSIONS_GAMEPAD + 1
    self.gridListPanelList:SetGridEntryTemplate("ZO_DailyLoginRewards_GridEntry_Template_Gamepad", GRID_LIST_TILE_DIMENSIONS_GAMEPAD, GRID_LIST_TILE_DIMENSIONS_GAMEPAD, self.dailyLoginRewardsGridEntrySetup, HIDE_CALLBACK, DailyLoginRewardsGridEntryReset, ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_GAMEPAD, ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_GAMEPAD, CENTER_ENTRIES)
    self.gridListPanelList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.gridListPanelList:SetLineBreakAmount(ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_TEMPLATE_DIMENSIONS_GAMEPAD + (ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_GAMEPAD * 3))
    self.gridListPanelList:SetOnSelectedDataChangedCallback(function(previousData, newData) self:OnGridListSelectedDataChanged(previousData, newData) end)
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

            if selectedReward.day then
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

            if selectedReward.day then
                return CanPreviewReward(selectedReward:GetRewardId())
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
    self.changeTimerValueLabel:SetText(formattedTime)
end

function ZO_DailyLoginRewards_Gamepad:UpdateTimeToNextMonthVisibility()
    local shouldBeHidden = self.lastCalculatedTimeUntilNextMonthS == 0 or GetNumRewardsInCurrentDailyLoginMonth() == 0
    self.changeTimer:SetHidden(shouldBeHidden)
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
        self.gridListPanelList:ScrollDataToCenter(selectionData)
    end
    self.exitScreenByBackingOutOfPreviewIndex = 0
end

function ZO_DailyLoginRewards_Gamepad:Deactivate()
    ZO_Main_Menu_Helper_Panel_Gamepad.Deactivate(self)
    self.gridListPanelList:Deactivate()
    self:CleanupTooltip()
end

function ZO_DailyLoginRewards_Gamepad:CleanDirty()
    ZO_DailyLoginRewards_Base.CleanDirty(self)

    if self.gridListPanelList:IsActive() and self.defaultSelectionData then
        self.gridListPanelList:ScrollDataToCenter(self.defaultSelectionData)
    end
end

function ZO_DailyLoginRewards_Gamepad:OnGridListSelectedDataChanged(previousData, newData)
    self:RefreshTooltip(newData)
    if newData then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

do
    local g_currentTooltipDay
    local function UpdateTooltip()
        if g_currentTooltipDay then
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, true)
            GAMEPAD_TOOLTIPS:LayoutDailyLoginReward(GAMEPAD_RIGHT_TOOLTIP, g_currentTooltipDay)
        end
    end

    function ZO_DailyLoginRewards_Gamepad:RefreshTooltip(selectedData)
        self:CleanupTooltip()

        if selectedData then
            if not selectedData.isEmptyCell then
                GAMEPAD_TOOLTIPS:LayoutDailyLoginReward(GAMEPAD_RIGHT_TOOLTIP, selectedData.day)
                g_currentTooltipDay = selectedData.day
                EVENT_MANAGER:RegisterForUpdate("DailyLoginRewards_Tooltip", 30, function(...) UpdateTooltip(...) end)
                return
            end
        end
    end

    function ZO_DailyLoginRewards_Gamepad:CleanupTooltip()
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
        g_currentTooltipDay = nil
        EVENT_MANAGER:UnregisterForUpdate("DailyLoginRewards_Tooltip")
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
                if not control.pendingLoopAnimationKey then
                    ZO_Restyle_ApplyPendingLoopAnimationToControl(control, pendingPool, PENDING_ANIMATION_INSET)
                end
                edgeTexture = "EsoUI/Art/Restyle/Gamepad/gp_outfits_edge_bluePending_16.dds"
            else
                edgeTexture = "EsoUI/Art/Tooltips/Gamepad/gp_toolTip_edge_16.dds"
            end
            control.isMilestoneTag:SetHidden(not isMilestone)
        end

        if not isCurrentReward then
            ZO_Daily_Login_Rewards_Gamepad_CleanupAnimationOnControl(control, pendingPool)
        end

        control.borderBackground:SetEdgeTexture(edgeTexture, ZO_GAMEPAD_DAILY_LOGIN_REWARDS_GRID_ENTRY_BORDER_EDGE_WIDTH, ZO_GAMEPAD_DAILY_LOGIN_REWARDS_GRID_ENTRY_BORDER_EDGE_HEIGHT)
    end
end

function ZO_Daily_Login_Rewards_Gamepad_CleanupAnimationOnControl(control, pendingPool)
    if control.pendingLoopAnimationKey then
        pendingPool:ReleaseObject(control.pendingLoopAnimationKey)
    end
end

---------------------------
-- Preview Scene Functions
---------------------------

function ZO_DailyLoginRewards_Gamepad:MovePreviewToPreviousReward()
    local scrollData = self.gridListPanelList:GetData()
    local nextIndex = self.currentRewardPreviewIndex - 1
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

        nextIndex = nextIndex - 1
        if nextIndex == 0 then
            nextIndex = #scrollData
        end
    end
end

function ZO_DailyLoginRewards_Gamepad:MovePreviewToNextReward()
    local scrollData = self.gridListPanelList:GetData()
    local nextIndex = self.currentRewardPreviewIndex + 1
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

        nextIndex = nextIndex + 1
        if nextIndex == #scrollData + 1 then
            nextIndex = 1
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
end

function ZO_DailyLoginRewards_Gamepad:UpdatePreview(rewardData)
    SYSTEMS:GetObject("itemPreview"):PreviewReward(rewardData:GetRewardId())
    self:RefreshTooltip(rewardData)
end

function ZO_DailyLoginRewards_Gamepad:OnPreviewHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.previewKeybindStripDesciptor)
    self.currentRewardPreviewIndex = 0
    self:CleanupTooltip()
end

function ZO_DailyLoginRewards_Gamepad:OnPreviewHidden()

end

-------------------
-- XML Functions
-------------------

function ZO_DailyLoginRewards_Gamepad_OnInitialize(control)
    ZO_DAILY_LOGIN_REWARDS_GAMEPAD = ZO_DailyLoginRewards_Gamepad:New(control)
end