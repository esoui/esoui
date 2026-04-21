ZO_VETERANCY_GRIDLIST_WIDTH_GAMEPAD = ZO_VETERANCY_GRIDLIST_WIDTH + 80

ZO_VETERANCY_GRID_ROW =
{
    RANK = 0,
    REWARDS_1 = 1,
    REWARDS_2 = 2,
}

local g_isVeterancyTooltipShown = true

----------------------------
-- Veterancy Rank
----------------------------

ZO_Veterancy_RankTile_Gamepad = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Gamepad, ZO_Veterancy_RankTile_Shared)

function ZO_Veterancy_RankTile_Gamepad:New(...)
    return ZO_Veterancy_RankTile_Shared.New(self, ...)
end

function ZO_Veterancy_RankTile_Gamepad:OnSelectionChanged()
    ZO_ContextualActionsTile_Gamepad.OnSelectionChanged(self)

    -- Don't show reward tooltip when rank is selected
    if self:IsSelected() then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD1_TOOLTIP)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_Veterancy_RankTile_Gamepad.OnControlInitialized(control)
    ZO_Veterancy_RankTile_Gamepad:New(control)
end

----------------------------------
-- Veterancy Empty Rank
----------------------------------

ZO_Veterancy_RankTile_Empty_Gamepad = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Gamepad, ZO_Veterancy_RankTile_Empty_Shared)

function ZO_Veterancy_RankTile_Empty_Gamepad:New(...)
    return ZO_Veterancy_RankTile_Empty_Shared.New(self, ...)
end

function ZO_Veterancy_RankTile_Empty_Gamepad:InitializePlatform()
    ZO_ContextualActionsTile_Gamepad.InitializePlatform(self)

    self:SetHighlightAnimationProvider(nil)
end

function ZO_Veterancy_RankTile_Empty_Gamepad.OnControlInitialized(control)
    ZO_Veterancy_RankTile_Empty_Gamepad:New(control)
end

-------------------------------
-- Veterancy Reward
-------------------------------

ZO_VeterancyReward_Gamepad = ZO_VeterancyReward_Shared:Subclass()

function ZO_VeterancyReward_Gamepad:Initialize(control)
    ZO_VeterancyReward_Shared.Initialize(self, control)

    self.highlightControl = control:GetNamedChild("Highlight")

    table.insert(self.keybindStripDescriptor,
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_PRIMARY",
        name = GetString(SI_VETERANCY_CLAIM_ACTION_TEXT),
        callback = function()
            self:GetRewardableEventData():TryClaimReward()
        end,
        visible = function()
            return self:GetRewardableEventData():CanClaimReward()
        end,
    })

    table.insert(self.keybindStripDescriptor,
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_SECONDARY",
        name = GetString(SI_VETERANCY_TOGGLE_TOOLTIP_TEXT),
        callback = function()
            self:ToggleTooltip()
        end,
    })

    table.insert(self.keybindStripDescriptor,
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_QUATERNARY",
        name = GetString(SI_VETERANCY_PREVIEW_ACTION_TEXT),
        callback = function()
            VETERANCY_GAMEPAD:BeginPreview(ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW, self:GetRewardableEventData())
        end,
        visible = function()
            return not ITEM_PREVIEW_GAMEPAD:IsWaitingForPreviewBegin()
                and self:GetRewardableEventData():CanPreviewReward()
        end,
    })
end

function ZO_VeterancyReward_Gamepad:SetSelected(isSelected)
    if isSelected then
        local rewardableEventData = self.control.object:GetRewardableEventData()
        if self.rewardableEventData:IsInstanceOf(ZO_VeterancyRankPerkRewardData) then
            self.perkHighlightControl:SetTexture(self.rewardableEventData:GetHighlightTexture())
            self.perkHighlightControl:SetAlpha(1)
            self.highlightControl:SetAlpha(0)
        else
            self.highlightControl:SetAlpha(1)
            self.perkHighlightControl:SetAlpha(0)
        end
    else
        self.highlightControl:SetAlpha(0)
        self.perkHighlightControl:SetAlpha(0)
    end
end

function ZO_VeterancyReward_Gamepad:ToggleTooltip()
    g_isVeterancyTooltipShown = not g_isVeterancyTooltipShown
    if g_isVeterancyTooltipShown then
        self:ShowTooltipForReward()
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD1_TOOLTIP)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_VeterancyReward_Gamepad:ShowTooltipForReward()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD1_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

    local rewardData = self.control:GetRewardData()
    local rewardableEventData = self.control.object:GetRewardableEventData()
    local rankData = rewardableEventData:GetRankData()
    local tooltipType = rankData:IsLeftTooltip() and GAMEPAD_QUAD1_TOOLTIP or GAMEPAD_RIGHT_TOOLTIP
    if rewardData:IsInstanceOf(ZO_VeterancyPerkData) then
        GAMEPAD_TOOLTIPS:LayoutVeterancyPerkTooltip(tooltipType, rewardData)
    else
        GAMEPAD_TOOLTIPS:LayoutRewardData(tooltipType, rewardData)
    end
    VETERANCY_GAMEPAD:NarrateCurrentSelection()
end

function ZO_VeterancyReward_Gamepad.OnControlInitialized(control)
    ZO_VeterancyReward_Gamepad:New(control)
end

------------------------------------
-- Veterancy Reward Tile
------------------------------------

ZO_Veterancy_RewardTile_Gamepad = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Gamepad, ZO_Veterancy_RewardTile_Shared)

function ZO_Veterancy_RewardTile_Gamepad:New(...)
    return ZO_Veterancy_RewardTile_Shared.New(self, ...)
end

function ZO_Veterancy_RewardTile_Gamepad:PostInitializePlatform(...)
    -- keybindStripDescriptor and canFocus need to be set after initialize, because ZO_ContextualActionsTile
    -- won't have finished initializing those until after InitializePlatform is called
    ZO_ContextualActionsTile_Gamepad.PostInitializePlatform(self, ...)

    -- Hide the default highlight that covers the extent of the tile and use the reward control highlight instead
    self.highlightControl:SetHidden(true)

    self.keybindStripDescriptor = self.rewardControl.object.keybindStripDescriptor
end

function ZO_Veterancy_RewardTile_Gamepad:OnSelectionChanged()
    ZO_ContextualActionsTile_Gamepad.OnSelectionChanged(self)

    -- Don't show reward tooltip when rank is selected
    if g_isVeterancyTooltipShown and self:IsSelected() then
        self:ShowTooltipForReward()
    end

    self.rewardControl.object:SetSelected(self:IsSelected())
end

function ZO_Veterancy_RewardTile_Gamepad:ToggleTooltip()
    self.rewardControl.object:ToggleTooltip()
end

function ZO_Veterancy_RewardTile_Gamepad:ShowTooltipForReward()
    self.rewardControl.object:ShowTooltipForReward()
end

function ZO_Veterancy_RewardTile_Gamepad.OnControlInitialized(control)
    ZO_Veterancy_RewardTile_Gamepad:New(control)
end

-----------------------------------
-- Veterancy No Reward
-----------------------------------

ZO_Veterancy_NoRewardTile_Gamepad = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Gamepad, ZO_Veterancy_NoRewardTile_Shared)

function ZO_Veterancy_NoRewardTile_Gamepad:New(...)
    return ZO_Veterancy_NoRewardTile_Shared.New(self, ...)
end

function ZO_Veterancy_NoRewardTile_Gamepad.OnControlInitialized(control)
    ZO_Veterancy_NoRewardTile_Gamepad:New(control)
end

---------------------------------------------
-- Veterancy Horizontal Scroll List Gamepad
---------------------------------------------

ZO_Veterancy_HorizontalScrollList_Gamepad = ZO_Veterancy_HorizontalScrollList_Shared:Subclass()

function ZO_Veterancy_HorizontalScrollList_Gamepad:EntrySetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    -- Make sure to deactivate existing page of the same number before
    -- reconstructing it to avoid duplicate keybind conflicts
    local gridList = self.gridListPages[data.pageIndex]
    if gridList and gridList:IsActive() then
        data.lastSelectedData = gridList:GetSelectedData()
        local FOREGO_DIRECTIONAL_INPUT = true
        self.gridListPages[data.pageIndex]:Deactivate(FOREGO_DIRECTIONAL_INPUT)
    end

    ZO_Veterancy_HorizontalScrollList_Shared.EntrySetup(self, control, data, selected, reselectingDuringRebuild, enabled, activated)
end

---------------------------------------------
-- Veterancy Grid Scroll List Gamepad
---------------------------------------------

ZO_Veterancy_GridScrollList_Gamepad = ZO_GridScrollList_Gamepad:Subclass()

function ZO_Veterancy_GridScrollList_Gamepad:SetPageNavigation(pageNavigation)
    self.pageNavigation = pageNavigation
end

function ZO_Veterancy_GridScrollList_Gamepad:RefreshGridList()
    ZO_GridScrollList_Gamepad.RefreshGridList(self)

    if self.previousPage then
        if self.previousPage > self.pageNavigation:GetCurrentPage() then
            local data = self:GetData()
            local rankEntryData = data[ZO_Veterancy_Shared.GetMaxRanksPerPage()].data
            local dataToSelect = rankEntryData
            if self.previousRow > ZO_VETERANCY_GRID_ROW.RANK then
                local numRewards = #rankEntryData.rewardDataList
                if numRewards > self.previousRow * REWARDS_PER_ROW then
                    dataToSelect = rankEntryData.rewardDataList[self.previousRow * REWARDS_PER_ROW]
                elseif self.previousRow == ZO_VETERANCY_GRID_ROW.REWARDS_2 and numRewards > REWARDS_PER_ROW then
                    dataToSelect = rankEntryData.rewardDataList[REWARDS_PER_ROW + 1]
                else
                    dataToSelect = rankEntryData.rewardDataList[1]
                end
            end
            self:SelectData(dataToSelect)
            self:RefreshLastHoldPosition()
        elseif self.previousRow > ZO_VETERANCY_GRID_ROW.RANK then
            local data = self:GetData()
            local rankEntryData = data[1].data
            local numRewards = #rankEntryData.rewardDataList
            local dataToSelect = nil
            if self.previousRow == ZO_VETERANCY_GRID_ROW.REWARDS_2 and numRewards > REWARDS_PER_ROW then
                dataToSelect = rankEntryData.rewardDataList[REWARDS_PER_ROW + 1]
            else
                dataToSelect = rankEntryData.rewardDataList[1]
            end
            self:SelectData(dataToSelect)
            self:RefreshLastHoldPosition()
        end
        self.previousPage = nil
    end
end

-------------------------------------------
-- Veterancy Focus Horizontal Scroll List
-------------------------------------------

local Veterancy_GamepadFocus_HorizontalScrollList = ZO_GamepadMultiFocusArea_Base:Subclass()

-- Start ZO_GridScrollList_Gamepad_FocusArea Overrides

function Veterancy_GamepadFocus_HorizontalScrollList:Initialize(scrollList, manager)
    self.scrollList = scrollList

    local FOREGO_DIRECTIONAL_INPUT = true

    local function GridActivateCallback()
        local gridList = self:GetCurrentGridList()
        if gridList then
            gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)
            gridList.HandleMoveInDirection = function(...) self:HandleGridListMoveInDirection(...) end
            gridList:Activate(FOREGO_DIRECTIONAL_INPUT)
            gridList:RemoveTriggerKeybinds()
        end
    end

    local function GridDeactivateCallback()
        local gridList = self:GetCurrentGridList()
        if gridList then
            gridList:Deactivate(FOREGO_DIRECTIONAL_INPUT)
        end
    end
    ZO_GamepadMultiFocusArea_Base.Initialize(self, manager, GridActivateCallback, GridDeactivateCallback)
end

function Veterancy_GamepadFocus_HorizontalScrollList:Deactivate()
    ZO_GamepadMultiFocusArea_Base.Deactivate(self)
    self.previousPage = nil
end

function Veterancy_GamepadFocus_HorizontalScrollList:GetCurrentGridList()
    local selectedData = self.scrollList:GetSelectedData()
    local selectedPageIndex = selectedData and selectedData.pageIndex
    return self.scrollList:GetGridListByPageIndex(selectedPageIndex)
end

function Veterancy_GamepadFocus_HorizontalScrollList:HandleMovement(horizontalResult, verticalResult)
    local gridList = self:GetCurrentGridList()
    if gridList then
        gridList:HandleMoveInDirection(horizontalResult, verticalResult)
    end
    return true
end

function Veterancy_GamepadFocus_HorizontalScrollList:CanBeSelected()
    local gridList = self:GetCurrentGridList()
    if gridList then
        return gridList:HasEntries()
    end
end

function Veterancy_GamepadFocus_HorizontalScrollList:HandleMovePrevious()
    local gridList = self:GetCurrentGridList()
    if gridList then
        if self:CanBeSelected() and not gridList:AtTopOfGrid() then
            -- let the grid handle the move if we can move up in the grid
            return false
        end
    end

    return ZO_GamepadMultiFocusArea_Base.HandleMovePrevious(self)
end

function Veterancy_GamepadFocus_HorizontalScrollList:HandleMoveNext()
    local gridList = self:GetCurrentGridList()
    if gridList then
        if self:CanBeSelected() and not gridList:AtBottomOfGrid() then
            -- let the grid handle the move if we can move down in the grid
            return false
        end
    end

    return ZO_GamepadMultiFocusArea_Base.HandleMoveNext(self)
end

-- End ZO_GridScrollList_Gamepad_FocusArea Overrides

function Veterancy_GamepadFocus_HorizontalScrollList:OnGridSelectionChanged(oldSelectedData, selectedData)
    -- Deselect previous entry
    if oldSelectedData and oldSelectedData.dataEntry then
        if oldSelectedData.dataEntry.control then
            oldSelectedData.dataEntry.control.object:SetSelected(false)
        end
        oldSelectedData.isSelected = false
    end

    -- Select newly selected entry.
    if selectedData and selectedData.dataEntry then
        if selectedData.dataEntry.control then
            selectedData.dataEntry.control.object:SetSelected(true)
        end
        selectedData.isSelected = true

        if oldSelectedData and oldSelectedData.dataEntry then
            local gridList = self:GetCurrentGridList()
            if gridList then
                self.currentGridListSelectedData = gridList:GetSelectedData()
            end
        end
    end
end

do
    local REWARDS_PER_ROW = 2
    function Veterancy_GamepadFocus_HorizontalScrollList:HandleGridListMoveInDirection(gridList, moveX, moveY)
        if not gridList:IsActive() then
            return
        end

        local pageNavigation = self.manager.pageNavigation
        local currentRankIndex = ZO_ScrollList_GetSelectedDataIndex(gridList.list)
        local currentRowIndex = ZO_VETERANCY_GRID_ROW.RANK
        local currentRewardIndex = 0
        local currentSelectionData = ZO_ScrollList_GetSelectedData(gridList.list)
        if currentSelectionData.rewardData then
            currentRankIndex = currentSelectionData.rewardData:GetRankIndex()
            currentRewardIndex = currentSelectionData.rewardData:GetRewardIndex()
            if currentRewardIndex <= REWARDS_PER_ROW then
                currentRowIndex = ZO_VETERANCY_GRID_ROW.REWARDS_1
            else
                currentRowIndex = ZO_VETERANCY_GRID_ROW.REWARDS_2
            end
        end
        if moveX == MOVEMENT_CONTROLLER_MOVE_NEXT then
            if ZO_Veterancy_Shared.GetPageIndexFromRankIndex(currentRankIndex) == ZO_Veterancy_Shared.GetMaxRanksPerPage()
                and (currentRowIndex == ZO_VETERANCY_GRID_ROW.RANK
                or currentRewardIndex == currentSelectionData.rewardData:GetRankNumRewards()
                or (currentRowIndex == ZO_VETERANCY_GRID_ROW.REWARDS_1 and currentRewardIndex == REWARDS_PER_ROW)) then -- Move to next page
                self.previousPage = pageNavigation:GetCurrentPage()
                self.previousRow = currentRowIndex
                pageNavigation:ChangePage(ZO_PAGE_NAVIGATION_NEXT_PAGE)
                return
            elseif currentSelectionData.rewardData and currentRewardIndex == currentSelectionData.rewardData:GetRankNumRewards() or
                zo_mod(currentRewardIndex, REWARDS_PER_ROW) == 0 then
                local nextRankIndex = currentRankIndex + 1
                if nextRankIndex > ZO_VETERANCY_MANAGER:GetNumRanks() then
                    -- Can't go any further right, so do nothing rather than wrap
                    return
                elseif currentRowIndex == ZO_VETERANCY_GRID_ROW.REWARDS_2 then
                    local nextRankPageIndex = ZO_Veterancy_Shared.GetPageIndexFromRankIndex(nextRankIndex)
                    local data = gridList:GetData()
                    local nextRankData = data[nextRankPageIndex].data
                    local nextNumRewards = #nextRankData.rewardDataList
                    local dataToSelect = nil
                    if nextNumRewards > REWARDS_PER_ROW then
                        dataToSelect = nextRankData.rewardDataList[REWARDS_PER_ROW + 1]
                    else
                        dataToSelect = nextRankData.rewardDataList[1]
                    end
                    gridList:SelectData(dataToSelect)
                    gridList:RefreshLastHoldPosition()
                    return
                end
            end
        elseif moveX == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            if ZO_Veterancy_Shared.GetPageIndexFromRankIndex(currentRankIndex) == 1
                and (currentRowIndex == ZO_VETERANCY_GRID_ROW.RANK
                or currentRewardIndex == 1
                or (currentRowIndex == ZO_VETERANCY_GRID_ROW.REWARDS_2 and currentRewardIndex == REWARDS_PER_ROW + 1)) then -- Move to previous page
                self.previousPage = pageNavigation:GetCurrentPage()
                self.previousRow = currentRowIndex
                pageNavigation:ChangePage(ZO_PAGE_NAVIGATION_PREVIOUS_PAGE)
                return
            elseif currentRewardIndex == REWARDS_PER_ROW + 1 then -- Move from last row of rewards to rewards at the previous rank
                local previousRankIndex = currentRankIndex - 1
                local previousRankPageIndex = ZO_Veterancy_Shared.GetPageIndexFromRankIndex(previousRankIndex)
                local data = gridList:GetData()
                local previousRankData = data[previousRankPageIndex].data
                local previousNumRewards = #previousRankData.rewardDataList
                local dataToSelect = previousRankData.rewardDataList[previousNumRewards]
                gridList:SelectData(dataToSelect)
                gridList:RefreshLastHoldPosition()
                return
            end
        elseif moveY == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            if currentRowIndex == ZO_VETERANCY_GRID_ROW.RANK and self.manager.repeatableRankFocalArea:CanBeSelected() then
                -- Order matters here to avoid duplicate keybinds
                self.manager:SelectFocusArea(self.manager.repeatableRankFocalArea)
                self.manager.repeatableRankRewardControl.object:SetSelected(true)
                self.manager.repeatableRankRewardControl.object:AddKeybinds()
                return
            end
        end
        ZO_GridScrollList_Gamepad.HandleMoveInDirection(gridList, moveX, moveY)
    end

    function Veterancy_GamepadFocus_HorizontalScrollList:RefreshGridList(newData, oldData, reselectingDuringRebuild)
        local FOREGO_DIRECTIONAL_INPUT = true
        local pageNavigation = self.manager.pageNavigation
        local scrollListSelectedData = self.scrollList:GetSelectedData()

        if not scrollListSelectedData then
            return
        end

        if scrollListSelectedData.pageIndex ~= newData.pageIndex then
            if oldData then
                local oldGridList = self.scrollList:GetGridListByPageIndex(oldData.pageIndex)

                if oldGridList then
                    oldGridList:Deactivate(FOREGO_DIRECTIONAL_INPUT)
                end
            end
            return
        end

        if self.previousPage and self.previousPage == scrollListSelectedData.pageIndex then
            return
        end

        local gridList = self.scrollList:GetGridListByPageIndex(newData.pageIndex)
        if not gridList then
            return
        end

        if not self.manager:IsCurrentFocusArea(self.manager.scrollListFocalArea) then
            return
        end

        gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)
        gridList.HandleMoveInDirection = function(...) self:HandleGridListMoveInDirection(...) end
        gridList:Activate(FOREGO_DIRECTIONAL_INPUT)
        gridList:RemoveTriggerKeybinds()
        gridList:RefreshLastHoldPosition()

        if self.previousPage then
            if self.previousPage > pageNavigation:GetCurrentPage() then
                local data = gridList:GetData()
                local rankEntryData = data[ZO_Veterancy_Shared.GetMaxRanksPerPage()].data
                local dataToSelect = rankEntryData
                if self.previousRow > ZO_VETERANCY_GRID_ROW.RANK then
                    local numRewards = #rankEntryData.rewardDataList
                    if numRewards > self.previousRow * REWARDS_PER_ROW then
                        dataToSelect = rankEntryData.rewardDataList[self.previousRow * REWARDS_PER_ROW]
                    elseif self.previousRow == ZO_VETERANCY_GRID_ROW.REWARDS_2 and numRewards > REWARDS_PER_ROW then
                        dataToSelect = rankEntryData.rewardDataList[REWARDS_PER_ROW + 1]
                    else
                        dataToSelect = rankEntryData.rewardDataList[1]
                    end
                end
                gridList:SelectData(dataToSelect)
                gridList:RefreshLastHoldPosition()
            elseif self.previousRow > ZO_VETERANCY_GRID_ROW.RANK then
                local data = gridList:GetData()
                local rankEntryData = data[1].data
                local numRewards = #rankEntryData.rewardDataList
                local dataToSelect = nil
                if self.previousRow == ZO_VETERANCY_GRID_ROW.REWARDS_2 and numRewards > REWARDS_PER_ROW then
                    dataToSelect = rankEntryData.rewardDataList[REWARDS_PER_ROW + 1]
                else
                    dataToSelect = rankEntryData.rewardDataList[1]
                end
                gridList:SelectData(dataToSelect)
                gridList:RefreshLastHoldPosition()
            else
                gridList:RefreshSelection()
            end
            self.previousPage = nil
        end
    end
end

-----------------------------------
-- Veterancy Focus Max Rank
-----------------------------------

local Veterancy_GamepadFocus_RepeatableRank = ZO_GamepadMultiFocusArea_Base:Subclass()

function Veterancy_GamepadFocus_RepeatableRank:CanBeSelected()
    return ZO_VETERANCY_MANAGER:IsOnMaxRank() and ZO_VETERANCY_MANAGER:HasRepeatableRankReward()
end

function Veterancy_GamepadFocus_RepeatableRank:HandleMovement(horizontalResult, verticalResult)
    if verticalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self.manager:SelectGridList()
        self:UpdateKeybinds()
        return true
    end
    return false
end

function Veterancy_GamepadFocus_RepeatableRank:GetNarrationText()
    local narrations = {}
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_VETERANCY_REPEATABLE_REWARD_TEXT)))
    return narrations
end

--------------------------
-- Veterancy
--------------------------

ZO_Veterancy_Gamepad = ZO_Object.MultiSubclass(ZO_Veterancy_Shared, ZO_GamepadMultiFocusArea_Manager)

function ZO_Veterancy_Gamepad:Initialize(control)
    VETERANCY_SCENE_GAMEPAD = ZO_Scene:New("VeterancySceneGamepad", SCENE_MANAGER)

    local function RewardTileSetupFunction(control, data)
        ZO_DefaultGridTileEntrySetup(control, data)
        control.object:SetRewardFxPools(self.rewardPendingLoopPool, self.blastParticleSystemPool)
    end

    local function RewardEqual(left, right)
        return left.rewardData == right.rewardData
    end

    local GRID_DATA = ZO_VETERANCY.GRID_DATA
    local ATTRIBUTE = ZO_VETERANCY.ATTRIBUTE
    local templateData =
    {
        [ZO_VETERANCY.GRID_DATA.SCROLL_CLASS] = ZO_Veterancy_HorizontalScrollList_Gamepad,
        [ZO_VETERANCY.GRID_DATA.SCROLL_TEMPLATE] = "ZO_Veterancy_GridList_Gamepad",
        [ZO_VETERANCY.GRID_DATA.CLASS] = ZO_GridScrollList_Gamepad,
        [ZO_VETERANCY.GRID_DATA.GAMEPAD_HIGHLIGHT] = "ZO_Veterancy_Rank_Gamepad_Highlight_Template",
        [ZO_VETERANCY.TEMPLATE_TYPE.RANK] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RankTile_Template_Gamepad",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RANK_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_RANK_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = ZO_DefaultGridTileEntrySetup,
            [ATTRIBUTE.EQUALITY_FUNCTION] = function(left, right)
                return left.rankData == right.rankData
            end,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.EMPTY_RANK] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RankTile_Empty_Template_Gamepad",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RANK_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_RANK_Y,
            [ATTRIBUTE.IS_SELECTABLE] = false,
            [ATTRIBUTE.SETUP_FUNCTION] = ZO_DefaultGridTileEntrySetup,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.CENTERED_REWARD] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RewardTile_CenteredReward_Gamepad",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RANK_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_REWARD_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = RewardTileSetupFunction,
            [ATTRIBUTE.EQUALITY_FUNCTION] = RewardEqual,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.LEFT_REWARD] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RewardTile_LeftReward_Gamepad",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_LEFT_REWARD_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_REWARD_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = RewardTileSetupFunction,
            [ATTRIBUTE.EQUALITY_FUNCTION] = RewardEqual,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.RIGHT_REWARD] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RewardTile_RightReward_Gamepad",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RIGHT_REWARD_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_REWARD_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = RewardTileSetupFunction,
            [ATTRIBUTE.EQUALITY_FUNCTION] = RewardEqual,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.NO_REWARD] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RewardTile_NoReward_Gamepad",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RANK_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_REWARD_Y,
            [ATTRIBUTE.IS_SELECTABLE] = false,
            [ATTRIBUTE.SETUP_FUNCTION] = ZO_DefaultGridTileEntrySetup,
        },
    }

    ZO_Veterancy_Shared.Initialize(self, control, VETERANCY_SCENE_GAMEPAD, templateData)

    SYSTEMS:RegisterGamepadRootScene("veterancy", self.scene)
end

function ZO_Veterancy_Gamepad:OnDeferredInitialize()
    ZO_Veterancy_Shared.OnDeferredInitialize(self)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self)

    ZO_StatusBar_InitializeDefaultColors(self.repeatableRankRewardProgressControl)

    self.pageNavigation:SetDefaultIndicatorFont("ZoFontGamepad42")

    self:InitializeMultiFocusAreas()

    -- Function needs to be run after self.pageNavigation has been created
    self:InitializeKeybindStripDescriptors()
end

function ZO_Veterancy_Gamepad:InitializeKeybindStripDescriptors()
    if not self.pageNavigation then
        return
    end

    local previousKeybind = self.pageNavigation:GetPreviousPageKeybindDescriptor()
    local nextKeybind = self.pageNavigation:GetNextPageKeybindDescriptor()

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_VETERANCY_CLAIM_ALL_ACTION_TEXT),
            callback = function()
                self:TryClaimAllRewards()
            end,
            visible = function()
                return self:AreAnyRewardsClaimable()
            end,
        },
        previousKeybind,
        nextKeybind,
    }

    local function OnBack()
        BATTLEGROUND_FINDER_GAMEPAD:SetIsFromVeterancy(true)
        SCENE_MANAGER:HideCurrentScene()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnBack)
end

function ZO_Veterancy_Gamepad:InitializeMultiFocusAreas()
    -- Grid List Focus
    self.scrollListFocalArea = Veterancy_GamepadFocus_HorizontalScrollList:New(self.scrollList, self)
    self:AddNextFocusArea(self.scrollListFocalArea)

    -- Max Rank Focus
    local function repeatableRankActivateCallback()
        self:NarrateCurrentSelection()
    end

    local function repeatableRankDeactivateCallback()
        self:SelectGridList()
    end

    self.repeatableRankFocalArea = Veterancy_GamepadFocus_RepeatableRank:New(self, repeatableRankActivateCallback, repeatableRankDeactivateCallback)
    self:AddNextFocusArea(self.repeatableRankFocalArea)
end

function ZO_Veterancy_Gamepad:ExitVeterancy()
    if self:GetCurrentPreviewType() ~= ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE then
        self:EndPreview()
    end
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_Veterancy_Gamepad:RefreshHorizontalScrollList(newData, oldData, reselectingDuringRebuild)
    ZO_Veterancy_Shared.RefreshHorizontalScrollList(self)
    if self.scrollListFocalArea then
        self.scrollListFocalArea:RefreshGridList(newData, oldData, reselectingDuringRebuild)
    end
end

function ZO_Veterancy_Gamepad:OnShowing()
    PREVIEW_SCREEN_ACTIVE_PREVIEW_SCREEN_GAMEPAD:SetSceneGroup(VETERANCY_SCENE_GROUP_GAMEPAD)

    if self:GetCurrentFocus() then
        self:ActivateCurrentFocus()
    else
        self:SelectFocusArea(self.scrollListFocalArea)
        self:ActivateFocusArea(self.scrollListFocalArea)
    end

    DIRECTIONAL_INPUT:Activate(self, self.control)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    -- Call to shared must happen after input has been activated to not break navigation
    ZO_Veterancy_Shared.OnShowing(self)
end

function ZO_Veterancy_Gamepad:OnHiding()
    ZO_Veterancy_Shared.OnHiding(self)

    self:DeactivateCurrentFocus()
    DIRECTIONAL_INPUT:Deactivate(self)
    self.currentGridListSelectedData = nil

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Veterancy_Gamepad:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Veterancy_Gamepad:ActivePreviewRewardInternal(rewardId)
    if CanPreviewReward(rewardId) then
        PREVIEW_SCREEN_ACTIVE_PREVIEW_SCREEN_GAMEPAD:SetPreviewableRewardData(self.activePreviewableRewardData)
        SCENE_MANAGER:Push("PreviewScreenActivePreviewSceneGamepad")
    end
end

function ZO_Veterancy_Gamepad:SelectGridList()
    -- Order matters here to avoid duplicate keybinds
    self.repeatableRankRewardControl.object:SetSelected(false)
    self.repeatableRankRewardControl.object:RemoveKeybinds()
    self:SelectFocusArea(self.scrollListFocalArea)
end

function ZO_Veterancy_Gamepad:NarrateCurrentSelection()
    local currentFocus = self:GetCurrentFocus()
    if currentFocus == self.scrollListFocalArea then
        local currentScrollListData = self.scrollList:GetSelectedData()
        local currentGridList = self.scrollList:GetGridListByPageIndex(currentScrollListData.pageIndex)
        SCREEN_NARRATION_MANAGER:QueueGridListEntry(currentGridList)
    elseif currentFocus == self.repeatableRankFocalArea then
        SCREEN_NARRATION_MANAGER:QueueFocus(self.repeatableRankFocalArea)
    end
end

--------------------------
-- Global Functions
--------------------------

function ZO_Veterancy_Gamepad.OnControlInitialized(control)
    VETERANCY_GAMEPAD = ZO_Veterancy_Gamepad:New(control)
end