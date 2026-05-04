ZO_VETERANCY_TEMPLATE_RANK_X = 180
ZO_VETERANCY_TEMPLATE_RANK_Y = 240
ZO_VETERANCY_TEMPLATE_REWARD_Y = 71
ZO_VETERANCY_TEMPLATE_LEFT_REWARD_X = 76
ZO_VETERANCY_TEMPLATE_RIGHT_REWARD_X = 104

ZO_VETERANCY_RANK_GROUP_INDEX_UPPER_BOUND_LOW = 50
ZO_VETERANCY_RANK_GROUP_INDEX_UPPER_BOUND_HIGH = 100

ZO_VETERANCY_RANKS_PER_PAGE = 10
ZO_VETERANCY_GRIDLIST_WIDTH = ZO_VETERANCY_TEMPLATE_RANK_X * ZO_VETERANCY_RANKS_PER_PAGE + 20
ZO_VETERANCY_GRIDLIST_HEIGHT = 525

----------------------------
-- Veterancy Rank
----------------------------

local RANK_BACKGROUND =
{
    LOCKED = "EsoUI/Art/Veterancy/veterancy_rank_bg.dds",
    UNLOCKED = "EsoUI/Art/Veterancy/vengeance_rankComplete_BG.dds",
}

ZO_Veterancy_RankTile_Shared = ZO_ContextualActionsTile:Subclass()

function ZO_Veterancy_RankTile_Shared:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

function ZO_Veterancy_RankTile_Shared:Initialize(control)
    ZO_ContextualActionsTile.Initialize(self, control)

    self.backgroundTexture = self.control:GetNamedChild("Background")
    self.borderTexture = self.control:GetNamedChild("Border")
    self.lockedTexture = self.control:GetNamedChild("Locked")
    self.rankIndexLabel = self.control:GetNamedChild("RankIndex")
    self.progressControl = self.control:GetNamedChild("ProgressBar")

    table.insert(self.keybindStripDescriptor,
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_PRIMARY",
        name = GetString(SI_VETERANCY_CLAIM_ACTION_TEXT),
        callback = function()
            self:TryClaimRewards()
        end,

        visible = function()
            return not self:IsClaimed() and self:CanClaim()
        end,
    })
end

function ZO_Veterancy_RankTile_Shared:Layout(data)
    ZO_ContextualActionsTile.Layout(self, data)

    self.rankData = data.rankData

    local isAvailable = self.rankData:IsRankAttained() and (self:CanClaim() or self:IsClaimed())
    local textColor = isAvailable and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
    local backgroundTexture = isAvailable and RANK_BACKGROUND.UNLOCKED or RANK_BACKGROUND.LOCKED

    self.backgroundTexture:SetTexture(backgroundTexture)
    self.iconTexture:SetTexture(self.rankData:GetLargeIcon())
    self.iconTexture:SetDesaturation(isAvailable and 0 or 1)
    self.lockedTexture:SetHidden(isAvailable)
    self.rankIndexLabel:SetText(self.rankData:GetIndex())
    self.rankIndexLabel:SetColor(textColor:UnpackRGBA())
    self.titleLabel:SetText(self.rankData:GetName())
    self.titleLabel:SetColor(textColor:UnpackRGBA())
    self.progressControl:SetValue(self.rankData:GetProgressPercent())
    self:SetProgressBarHidden(data.isProgressBarHidden)
end

function ZO_Veterancy_RankTile_Shared:SetProgressBarHidden(isHidden)
    self.progressControl:SetHidden(isHidden)
end

function ZO_Veterancy_RankTile_Shared:IsClaimed()
    if self.rankData then
        return self.rankData:IsClaimed()
    end
    return false
end

function ZO_Veterancy_RankTile_Shared:CanClaim()
    if self.rankData then
        return self.rankData:CanClaimRank()
    end
    return false
end

function ZO_Veterancy_RankTile_Shared:TryClaimRewards()
    if self.rankData then
        self.rankData:TryClaimRankRewards()
    end
end

function ZO_Veterancy_RankTile_Shared.OnControlInitialized(control)
    ZO_Veterancy_RankTile_Shared:New(control)
end

----------------------------------
-- Veterancy Empty Rank
----------------------------------

ZO_Veterancy_RankTile_Empty_Shared = ZO_ContextualActionsTile:Subclass()

function ZO_Veterancy_RankTile_Empty_Shared:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

function ZO_Veterancy_RankTile_Empty_Shared.OnControlInitialized(control)
    ZO_Veterancy_RankTile_Shared:New(control)
end

-------------------------------
-- Veterancy Reward
-------------------------------

ZO_VeterancyReward_Shared = ZO_InitializingObject:Subclass()

function ZO_VeterancyReward_Shared:Initialize(control)
    self.control = control
    control.object = self
    self.rewardIconControl = control:GetNamedChild("RewardIcon")
    self.rewardIconTexture = self.rewardIconControl:GetNamedChild("Icon")
    self.rewardBorderTexture = self.rewardIconControl:GetNamedChild("Border")
    self.rewardQuantityLabel = self.rewardIconControl:GetNamedChild("Quantity")
    self.rewardCompleteMarkTexture = self.rewardIconControl:GetNamedChild("CompleteMark")
    self.rewardLockedTexture = self.rewardIconControl:GetNamedChild("Locked")
    self.rewardFxAnchorControl = self.rewardIconControl:GetNamedChild("FxAnchorControl")

    self.perkIconControl = control:GetNamedChild("PerkIcon")
    self.perkIcon = self.perkIconControl.object
    self.perkHighlightControl = self.perkIconControl:GetNamedChild("Highlight")
    self.perkCompleteMarkTexture = self.perkIconControl:GetNamedChild("CompleteMark")
    self.perkLockedTexture = self.perkIconControl:GetNamedChild("Locked")

    control.icon = self.rewardIconTexture -- For ZO_GridEntry_SetIconScaledUp
    control.GetRewardData = function()
        return self.displayRewardData
    end

    self.keybindStripDescriptor = {}
end

function ZO_VeterancyReward_Shared:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_VeterancyReward_Shared:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_VeterancyReward_Shared:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_VeterancyReward_Shared:SetRewardFxPools(rewardPendingLoopPool, blastParticleSystemPool)
    self.rewardPendingLoopPool = rewardPendingLoopPool
    self.blastParticleSystemPool = blastParticleSystemPool
end

function ZO_VeterancyReward_Shared:SetRewardableEventData(rewardableEventData)
    self.rewardableEventData = rewardableEventData
    local rewardData = rewardableEventData:GetRewardData()
    self.baseRewardData = rewardData
    if rewardData then
        self.control:SetHidden(false)
    else
        self.control:SetHidden(true)
    end

    self:Refresh()
end

function ZO_VeterancyReward_Shared:GetRewardableEventData()
    return self.rewardableEventData
end

function ZO_VeterancyReward_Shared:Refresh()
    if self.baseRewardData then
        local canClaim = false
        local isClaimed = false
        local wasFallbackClaimed = false
        local isAvailable = self.rewardableEventData:GetRankData():IsRankAttained()
        if self.rewardableEventData:CanClaimReward() then
            canClaim = true
        else
            isClaimed, wasFallbackClaimed = self.rewardableEventData:IsRewardClaimed()
        end

        local displayRewardData = self.baseRewardData
        if wasFallbackClaimed or (not isClaimed and self.baseRewardData:ShouldUseFallback()) then
            displayRewardData = self.baseRewardData:GetFallbackRewardData()
        end
        self.displayRewardData = displayRewardData

        local shouldHideQuantityLabel = true
        if self.rewardableEventData:IsInstanceOf(ZO_VeterancyRankPerkRewardData) then
            self.rewardIconControl:SetHidden(true)
            self.perkIcon:SetPerkData(self.rewardableEventData)
            self.perkIconControl:SetHidden(false)
            self.perkLockedTexture:SetTexture(self.rewardableEventData:GetLockedTexture())
            self.perkLockedTexture:SetHidden(isAvailable)
            self.perkCompleteMarkTexture:SetHidden(not isAvailable)
        else
            self.perkIconControl:SetHidden(true)
            self.rewardIconControl:SetHidden(false)
            self.rewardIconTexture:SetTexture(displayRewardData:GetPlatformLootIcon())

            local rewardId = displayRewardData:GetRewardId()
            if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
                local rewardListId = GetRewardListIdFromReward(rewardId)
                local rewardListData = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
                local quantity = GetNumRewardListEntries(rewardListId)
                shouldHideQuantityLabel = not (quantity > 1)
                if not shouldHideQuantityLabel then
                    quantity = zo_strformat(SI_PROMOTIONAL_EVENT_REWARD_LIST_QUANTITY_FORMATTER, quantity - 1)
                    self.rewardQuantityLabel:SetText(quantity)
                end
                local firstRewardData = rewardListData[1]
                if firstRewardData then
                    self.rewardIconTexture:SetTexture(firstRewardData:GetPlatformLootIcon())
                end
            elseif displayRewardData:GetQuantity() > 1 then
                local quantity = displayRewardData:GetAbbreviatedQuantity()
                self.rewardQuantityLabel:SetText(quantity)
                shouldHideQuantityLabel = false
            end
            self.rewardLockedTexture:SetHidden(isAvailable)

            local hasPendingLoop = self.rewardFxAnchorControl.pendingLoop ~= nil
            if canClaim ~= hasPendingLoop then
                if canClaim then
                    ZO_PendingLoop.ApplyToControl(self.rewardFxAnchorControl, self.rewardPendingLoopPool)
                else
                    self.rewardFxAnchorControl.pendingLoop:ReleaseObject()
                end
            end

            if isClaimed and not self.rewardableEventData:IsRepeatableRank() then
                self.rewardCompleteMarkTexture:SetHidden(false)
                self.rewardQuantityLabel:SetHidden(true)
                self.rewardIconTexture:SetColor(0.7, 0.7, 0.7)
            else
                self.rewardCompleteMarkTexture:SetHidden(true)
                self.rewardQuantityLabel:SetHidden(shouldHideQuantityLabel)
                self.rewardIconTexture:SetColor(1, 1, 1)
            end
        end
    else
        self.displayRewardData = nil
        if self.rewardFxAnchorControl.pendingLoop then
            self.rewardFxAnchorControl.pendingLoop:ReleaseObject()
        end
    end
end

function ZO_VeterancyReward_Shared:OnRewardClaimed()
    if self.baseRewardData then
        self:Refresh()

        local RELEASE_ON_STOP = true
        local blastParticleSystem = self.blastParticleSystemPool:AcquireForControl(self.control, RELEASE_ON_STOP)
        blastParticleSystem:Start()
    end
end


function ZO_VeterancyReward_Shared:OnCollectionUpdated()
    if self.baseRewardData and self.baseRewardData:GetFallbackRewardData() then
        self:Refresh()
    end
end

-----------------------------------
-- Veterancy Reward Tile
-----------------------------------

ZO_Veterancy_RewardTile_Shared = ZO_ContextualActionsTile:Subclass()

function ZO_Veterancy_RewardTile_Shared:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

function ZO_Veterancy_RewardTile_Shared:Initialize(control)
    ZO_ContextualActionsTile.Initialize(self, control)
    self.rewardControl = control:GetNamedChild("Reward")
end

function ZO_Veterancy_RewardTile_Shared:Layout(data)
    ZO_ContextualActionsTile.Layout(self, data)

    self.rewardData = data.rewardData
    self.rewardControl.object:SetRewardableEventData(self.rewardData)
end

function ZO_Veterancy_RewardTile_Shared:GetRewardableEventData()
    return self.rewardControl.object:GetRewardableEventData()
end

function ZO_Veterancy_RewardTile_Shared:SetRewardFxPools(rewardPendingLoopPool, blastParticleSystemPool)
    self.rewardControl.object:SetRewardFxPools(rewardPendingLoopPool, blastParticleSystemPool)
end

function ZO_Veterancy_RewardTile_Shared:OnRewardClaimed()
    self.rewardControl.object:OnRewardClaimed()
end

function ZO_Veterancy_RewardTile_Shared.OnControlInitialized(control)
    ZO_Veterancy_RewardTile_Shared:New(control)
end

---------------------------------------
-- Veterancy No Reward Tile
---------------------------------------

ZO_Veterancy_NoRewardTile_Shared = ZO_ContextualActionsTile:Subclass()

function ZO_Veterancy_NoRewardTile_Shared:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

function ZO_Veterancy_NoRewardTile_Shared.OnControlInitialized(control)
    ZO_Veterancy_RewardTile_Shared:New(control)
end

-------------------------------------
-- Veterancy Horizontal Scroll List
-------------------------------------

-- Shared is inheriting from Gamepad because Gamepad auto-hides the arrow button,
-- which we want in this case so that we can use the page navigator.
ZO_Veterancy_HorizontalScrollList_Shared = ZO_HorizontalScrollList_Gamepad:Subclass()

function ZO_Veterancy_HorizontalScrollList_Shared:Initialize(control, template)
    local function OnSelectedCallback(newData)
        if newData and newData.callback then
            newData.callback(newData)
        end
    end

    local NUM_VISIBLE_ENTRIES = 1
    ZO_HorizontalScrollList_Gamepad.Initialize(self, control, template, NUM_VISIBLE_ENTRIES, function(...) self:EntrySetup(...) end)
    self:SetOnTargetDataChangedCallback(OnSelectedCallback)
    self:SetDisplayEntryType(ZO_HORIZONTAL_SCROLL_LIST_DISPLAY_FIXED_NUMBER_OF_ENTRIES)

    self.gridListPages = {}
    self.rankInfoDataListByPage = {}
end

function ZO_Veterancy_HorizontalScrollList_Shared:SetParentObject(parentObject)
    self.parent = parentObject
end

function ZO_Veterancy_HorizontalScrollList_Shared:GetRankInfoDataByIndex(index)
    local selectedData = self:GetSelectedData()
    return self.rankInfoDataListByPage[selectedData.pageIndex][index]
end

function ZO_Veterancy_HorizontalScrollList_Shared:GetGridListByPageIndex(index)
    return self.gridListPages[index]
end

function ZO_Veterancy_HorizontalScrollList_Shared:RefreshGridLists()
    for i, gridList in pairs(self.gridListPages) do
        gridList:RefreshGridList()
    end
end

function ZO_Veterancy_HorizontalScrollList_Shared:EntrySetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    local templateData = data.templateData

    -- Setup templates for grid list
    -- Override default highlight template to hide white outline around tiles on gamepad
    local gridList = templateData[ZO_VETERANCY.GRID_DATA.CLASS]:New(control, templateData[ZO_VETERANCY.GRID_DATA.GAMEPAD_HIGHLIGHT])

    local DEFAULT_HIDE_CALLBACK = nil
    local DEFAULT_ENTRIES_CENTERED = nil
    local ATTRIBUTE = ZO_VETERANCY.ATTRIBUTE

    local templateTypes = ZO_VETERANCY.TEMPLATE_TYPE
    for i, value in pairs(templateTypes) do
        local typeData = templateData[value]
        gridList:AddEntryTemplate(typeData[ATTRIBUTE.ENTRY_TEMPLATE], typeData[ATTRIBUTE.DIMENSION_X], typeData[ATTRIBUTE.DIMENSION_Y], typeData[ATTRIBUTE.SETUP_FUNCTION], DEFAULT_HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, 0, 0, DEFAULT_ENTRIES_CENTERED, typeData[ATTRIBUTE.IS_SELECTABLE])
        if typeData[ATTRIBUTE.EQUALITY_FUNCTION] then
            gridList:SetEntryTemplateEqualityFunction(typeData[ATTRIBUTE.ENTRY_TEMPLATE], typeData[ATTRIBUTE.EQUALITY_FUNCTION])
        end
    end

    -- Populate Grid List
    gridList:ClearGridList()
    self.rankInfoDataListByPage[data.pageIndex] = {}
    local rankInfoDataList = self.rankInfoDataListByPage[data.pageIndex]

    -- Build Rank Row
    local maxRanksPerPage = self.parent.GetMaxRanksPerPage()
    local firstIndex = data.pageStartIndex
    local numRanks = self.parent.GetNumRanksForPage(data.pageIndex)
    local lastIndex = firstIndex + maxRanksPerPage - 1
    for i = firstIndex, lastIndex do
        if i <= firstIndex + numRanks - 1 then
            local rankData = ZO_VETERANCY_MANAGER:GetRankDataByIndex(i)
            rankData:SetIsLeftTooltip(i - firstIndex > maxRanksPerPage / 2)
            local gridListEntryData =
            {
                rankData = rankData,
                gridHeaderName = "",
                rewardDataList = {},
                isProgressBarHidden = i == ZO_VETERANCY_MANAGER:GetNumRanks(),
                narrationText = function(entryData, entryControl)
                    local narrations = {}
                    local entryRankData = entryData.rankData
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_VETERANCY_RANK_NARRATION_FORMATTER, entryRankData:GetIndex(), entryRankData:GetName())))
                    return narrations
                end
            }
            gridList:AddEntry(gridListEntryData, templateData[ZO_VETERANCY.TEMPLATE_TYPE.RANK][ZO_VETERANCY.ATTRIBUTE.ENTRY_TEMPLATE])
            table.insert(rankInfoDataList, gridListEntryData)
        else
            local gridListEntryData =
            {
                gridHeaderName = "",
            }
            gridList:AddEntry(gridListEntryData, templateData[ZO_VETERANCY.TEMPLATE_TYPE.EMPTY_RANK][ZO_VETERANCY.ATTRIBUTE.ENTRY_TEMPLATE])
        end
    end

    -- Build Rewards Row
    local NUM_REWARD_ROWS = 2
    local MAX_NUM_REWARDS_PER_ROW = 2
    for row = 1, NUM_REWARD_ROWS do
        for i = 1, maxRanksPerPage do
            if i <= #rankInfoDataList then
                local rankInfoData = rankInfoDataList[i]
                local numRewards = rankInfoData.rankData:GetNumRewards()
                local currentRowFirstIndex = 1 + ((row - 1) * MAX_NUM_REWARDS_PER_ROW)
                if numRewards - currentRowFirstIndex == 0 then
                    local gridListEntryData =
                    {
                        rewardData = rankInfoData.rankData:GetRankRewardDataByIndex(currentRowFirstIndex),
                        gridHeaderName = "",
                        narrationText = function(entryData, entryControl)
                            local narrations = {}
                            local rankData = entryData.rewardData.rankData
                            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_VETERANCY_RANK_NARRATION_FORMATTER, rankData:GetIndex(), rankData:GetName())))
                            return narrations
                        end
                    }
                    gridList:AddEntry(gridListEntryData, templateData[ZO_VETERANCY.TEMPLATE_TYPE.CENTERED_REWARD][ZO_VETERANCY.ATTRIBUTE.ENTRY_TEMPLATE])
                    table.insert(rankInfoData.rewardDataList, gridListEntryData)
                elseif numRewards - currentRowFirstIndex > 0 then
                    local leftData =
                    {
                        rewardData = rankInfoData.rankData:GetRankRewardDataByIndex(currentRowFirstIndex),
                        gridHeaderName = "",
                        narrationText = function(entryData, entryControl)
                            local narrations = {}
                            local rankData = entryData.rewardData.rankData
                            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_VETERANCY_RANK_NARRATION_FORMATTER, rankData:GetIndex(), rankData:GetName())))
                            return narrations
                        end
                    }
                    gridList:AddEntry(leftData, templateData[ZO_VETERANCY.TEMPLATE_TYPE.LEFT_REWARD][ZO_VETERANCY.ATTRIBUTE.ENTRY_TEMPLATE])
                    table.insert(rankInfoData.rewardDataList, leftData)
                    local rightData =
                    {
                        rewardData = rankInfoData.rankData:GetRankRewardDataByIndex(currentRowFirstIndex + 1),
                        gridHeaderName = "",
                        narrationText = function(entryData, entryControl)
                            local narrations = {}
                            local rankData = entryData.rewardData.rankData
                            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_VETERANCY_RANK_NARRATION_FORMATTER, rankData:GetIndex(), rankData:GetName())))
                            return narrations
                        end
                    }
                    gridList:AddEntry(rightData, templateData[ZO_VETERANCY.TEMPLATE_TYPE.RIGHT_REWARD][ZO_VETERANCY.ATTRIBUTE.ENTRY_TEMPLATE])
                    table.insert(rankInfoData.rewardDataList, rightData)
                else
                    local gridListEntryData =
                    {
                        rankData = rankInfoData.rankData,
                        gridHeaderName = "",
                    }
                    gridList:AddEntry(gridListEntryData, templateData[ZO_VETERANCY.TEMPLATE_TYPE.NO_REWARD][ZO_VETERANCY.ATTRIBUTE.ENTRY_TEMPLATE])
                end
            else
                local gridListEntryData =
                {
                    rankData = nil,
                    gridHeaderName = "",
                }
                gridList:AddEntry(gridListEntryData, templateData[ZO_VETERANCY.TEMPLATE_TYPE.NO_REWARD][ZO_VETERANCY.ATTRIBUTE.ENTRY_TEMPLATE])
            end
        end
    end

    if data.lastSelectedData then
        gridList:SetAutoSelectToMatchingDataEntry(data.lastSelectedData)
    end

    gridList:CommitGridList()

    if gridList.SetHeaderNarrationFunction then
        local function GetHeaderNarration()
            local narrations = {}
            if self.parent:IsNarrateOnShow() then
                narrations = self.parent:GetSeasonInfoNarrationText()
                self.parent:SetNarrateOnShow(false)
            end
            return narrations
        end
        gridList:SetHeaderNarrationFunction(GetHeaderNarration)
    end

    self.gridListPages[data.pageIndex] = gridList
end

--------------------------
-- Veterancy
--------------------------

ZO_VETERANCY =
{
    GRID_DATA =
    {
        SCROLL_CLASS = 1,
        SCROLL_TEMPLATE = 2,
        CLASS = 3,
        GAMEPAD_HIGHLIGHT = 4,
    },
    TEMPLATE_TYPE =
    {
        RANK = 10,
        EMPTY_RANK = 11,
        CENTERED_REWARD = 12,
        LEFT_REWARD = 13,
        RIGHT_REWARD = 14,
        NO_REWARD = 15,
    },
    ATTRIBUTE =
    {
        ENTRY_TEMPLATE = 20,
        DIMENSION_X = 21,
        DIMENSION_Y = 22,
        IS_SELECTABLE = 23,
        SETUP_FUNCTION = 24,
        EQUALITY_FUNCTION = 25,
    },
}

ZO_Veterancy_Shared = ZO_PreviewScreen_Shared:Subclass()

function ZO_Veterancy_Shared:Initialize(control, scene, templateData)
    self.control = control

    self.templateData = templateData

    ZO_PreviewScreen_Shared.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)
end

function ZO_Veterancy_Shared:OnDeferredInitialize()
    self.seasonInfo = self.control:GetNamedChild("SeasonInfo")
    self.seasonNameLabel = self.seasonInfo:GetNamedChild("SeasonName")
    self.seasonTimeRemainingLabel = self.seasonInfo:GetNamedChild("TimeRemaining")
    self.currentRankLabel = self.seasonInfo:GetNamedChild("CurrentRank")
    self.repeatableRankControl = self.seasonInfo:GetNamedChild("RepeatableRankReward")
    self.repeatableRankRewardControl = self.repeatableRankControl:GetNamedChild("Reward")
    self.repeatableRankRewardNameLabel = self.repeatableRankControl:GetNamedChild("Name")
    self.repeatableRankRewardProgressControl = self.repeatableRankControl:GetNamedChild("Progress")
    self.seasonBottomDivider = self.seasonInfo:GetNamedChild("BottomLineBorder")

    self.rewardsContainer = self.control:GetNamedChild("RewardsContainer")
    self.scrollListControl = self.rewardsContainer:GetNamedChild("ScrollList")
    self.rewardPendingLoopPool = ZO_MetaPool:New(ZO_Pending_LoopAnimation_Pool)
    self.blastParticleSystemPool = ZO_BlastParticleSystem_MetaPool:New()
    self.repeatableRankRewardControl.object:SetRewardFxPools(self.rewardPendingLoopPool, self.blastParticleSystemPool)

    local pageNavigationControl = self.rewardsContainer:GetNamedChild("PageNavigation")
    self.pageNavigation = ZO_PageNavigation:New(pageNavigationControl)
    self.pageNavigation:SetHidePageIndicators(true)
    self.pageNavigation:SetShowTooltips(false)
    self.pageNavigation:SetPageChangeNextSound(SOUNDS.VETERANCY_RANK_SCROLL_RIGHT)
    self.pageNavigation:SetPageChangePreviousSound(SOUNDS.VETERANCY_RANK_SCROLL_LEFT)
    self.pageNavigation:RegisterCallback("PageChanged", self.OnPageChanged, self)

    self:InitializeScrollList()

    ZO_VETERANCY_MANAGER:RegisterCallback("OnVeterancyRankClaimed", function(...) self:OnRewardsClaimed(...) end)
    ZO_VETERANCY_MANAGER:RegisterCallback("OnVeterancyRankProgressed", function(...) self:OnRankProgressed(...) end)
    ZO_VETERANCY_MANAGER:RegisterCallback("OnVeterancyRepeatableRankClaimed", function(...) self:OnRepeatableRankRewardClaimed(...) end)
    ZO_VETERANCY_MANAGER:RegisterCallback("OnVeterancyRankDataUpdated", function(...) self:RefreshScrollListRankData(...) end)

    self.control:SetHandler("OnUpdate", function(_, currentFrameTimeSeconds) self:UpdateSeasonInfo(currentFrameTimeSeconds) end)
end

function ZO_Veterancy_Shared:InitializeScrollList()
    local templateData = self.templateData

    self.scrollList = templateData[ZO_VETERANCY.GRID_DATA.SCROLL_CLASS]:New(self.scrollListControl, templateData[ZO_VETERANCY.GRID_DATA.SCROLL_TEMPLATE])
    self.scrollList:SetParentObject(self)

    local function RefreshGridLists(newData, oldData, reselectingDuringRebuild)
        self:RefreshHorizontalScrollList(newData, oldData, reselectingDuringRebuild)
    end
    self.scrollList:SetOnSelectedDataChangedCallback(RefreshGridLists)
    self.scrollList:SetOnTargetDataChangedCallback(RefreshGridLists)

    ZO_VETERANCY_MANAGER:RefreshRankData()
    self:RefreshScrollListRankData()
end

function ZO_Veterancy_Shared:RefreshHorizontalScrollList(newData, oldData, reselectingDuringRebuild)
    self.scrollList:RefreshGridLists()
end

function ZO_Veterancy_Shared:RefreshScrollListRankData()
    if self:IsShowing() then
        self.scrollList:Clear()
        local numRewardPages = self.GetNumRewardPages()
        for i = 1, numRewardPages do
            local data =
            {
                pageIndex = i,
                pageStartIndex = (i - 1) * self.GetMaxRanksPerPage() + 1,
                templateData = self.templateData,
                parentObject = self,
            }
            self.scrollList:AddEntry(data)
        end
        self.scrollList:Commit()

        self:RefreshRepeatableRankDisplay()
    end
end

ZO_Veterancy_Shared.ExitVeterancy = ZO_Veterancy_Shared:MUST_IMPLEMENT()

function ZO_Veterancy_Shared:UpdateSeasonInfo()
    self.seasonNameLabel:SetText(GetCurrentVeterancySeasonName())

    self.currentRankLabel:SetText(zo_strformat(SI_VETERANCY_CURRENT_RANK_FORMATTER, ZO_SELECTED_TEXT:Colorize(ZO_VETERANCY_MANAGER:GetCurrentRank())))

    local timeRemainingSeconds = GetCurrentVeterancySeasonTimeRemainingS()
    if timeRemainingSeconds > 0 then
        self.seasonTimeRemainingLabel:SetText(zo_strformat(SI_VETERANCY_TIME_REMAINING_FORMATTER, ZO_SELECTED_TEXT:Colorize(ZO_FormatTimeLargestTwo(timeRemainingSeconds, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS))))
    elseif self:IsShowing() then
        self:ExitVeterancy()
    end
end

function ZO_Veterancy_Shared:GetSeasonInfoNarrationText()
    local narrations = {}
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.seasonNameLabel:GetText()))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.seasonTimeRemainingLabel:GetText()))
    return narrations
end

function ZO_Veterancy_Shared:SetNarrateOnShow(value)
    self.narrateOnShow = value
end

function ZO_Veterancy_Shared:IsNarrateOnShow()
    return self.narrateOnShow
end

function ZO_Veterancy_Shared:RefreshRepeatableRankDisplay()
    if ZO_VETERANCY_MANAGER:HasRepeatableRankReward() and ZO_VETERANCY_MANAGER:IsOnMaxRank() then
        local repeatableRankData = ZO_VETERANCY_MANAGER:GetCurrentRankData()
        local rewardRankData = repeatableRankData
        if not repeatableRankData:IsRepeatableRank() then
            rewardRankData = ZO_VETERANCY_MANAGER:GetRepeatableRankData()
        end
        local repeatableRankRewardData = rewardRankData:GetRankRewardDataByIndex(1)
        self.repeatableRankRewardControl.object:SetRewardableEventData(repeatableRankRewardData)
        self.repeatableRankRewardNameLabel:SetText(GetString(SI_VETERANCY_REPEATABLE_REWARD_TEXT))
        self.repeatableRankRewardProgressControl:SetValue(repeatableRankData:GetProgressPercent())

        self.repeatableRankControl:SetHidden(false)
        self.seasonBottomDivider:ClearAnchors()
        self.seasonBottomDivider:SetAnchor(TOPLEFT, self.repeatableRankControl, BOTTOMLEFT, -70)
        self.seasonBottomDivider:SetAnchor(TOPRIGHT, self.repeatableRankControl, BOTTOMRIGHT, 0, 10)
    else
        self.repeatableRankControl:SetHidden(true)
        self.seasonBottomDivider:ClearAnchors()
        self.seasonBottomDivider:SetAnchor(TOPLEFT, self.currentRankLabel, BOTTOMLEFT, -70)
        self.seasonBottomDivider:SetAnchor(TOPRIGHT, self.currentRankLabel, BOTTOMRIGHT, 0, 10)
    end
end

function ZO_Veterancy_Shared:AreAnyRewardsClaimable()
    return ZO_VETERANCY_MANAGER:HasUnclaimedRankRewards()
end

function ZO_Veterancy_Shared:TryClaimAllRewards()
    ZO_VETERANCY_MANAGER:TryClaimAllRewards()
end

function ZO_Veterancy_Shared.GetMaxRanksPerPage()
    return ZO_VETERANCY_RANKS_PER_PAGE
end

function ZO_Veterancy_Shared.GetNumRewardPages()
    local numRanks = ZO_VETERANCY_MANAGER:GetNumRanks()
    return zo_ceil(numRanks / ZO_VETERANCY_RANKS_PER_PAGE)
end

function ZO_Veterancy_Shared.GetNumRanksForPage(pageIndex)
    local numPages = ZO_Veterancy_Shared.GetNumRewardPages()
    if numPages == pageIndex then
        local numRanks = ZO_VETERANCY_MANAGER:GetNumRanks()
        return numRanks - ((numPages - 1) * ZO_Veterancy_Shared.GetMaxRanksPerPage())
    else
        return ZO_Veterancy_Shared.GetMaxRanksPerPage()
    end
end

function ZO_Veterancy_Shared.GetPageIndexFromRankIndex(rankIndex)
    local pageIndex = zo_mod(rankIndex, ZO_VETERANCY_RANKS_PER_PAGE)
    return pageIndex == 0 and ZO_VETERANCY_RANKS_PER_PAGE or pageIndex
end

function ZO_Veterancy_Shared:OnPageChanged(pageNumber)
    -- ZO_HorizontalScrollList:SetSelectedIndex expects indices 0 through negative n - 1 for indices 1 through n
    local scrollListIndex = -(pageNumber - 1)
    self.scrollList:SetSelectedIndex(scrollListIndex)
end

function ZO_Veterancy_Shared:UpdatePageNavigation()
    local pageNavigation = self.pageNavigation
    local currentPage = pageNavigation:GetCurrentPage()
    local pageToSelect = currentPage
    if pageToSelect == nil or pageToSelect == 0 then
        pageToSelect = 1
    end

    pageNavigation:Clear()
    pageNavigation:AddPages(self.GetNumRewardPages())
    pageNavigation:Commit(pageToSelect)
end

function ZO_Veterancy_Shared:OnShowing()
    TriggerTutorial(TUTORIAL_TRIGGER_VETERANCY_OPENED)

    self:UpdatePageNavigation()
    self.scrollList:RefreshVisible()
    self:RefreshRepeatableRankDisplay()
    PlaySound(SOUNDS.VETERANCY_RANK_SCREEN_OPEN)
    self:SetNarrateOnShow(true)
    self:UpdateKeybinds()
end

function ZO_Veterancy_Shared:OnShown()
    -- Can be overridden
end

function ZO_Veterancy_Shared:OnHidden()
    -- Can be overridden
end

function ZO_Veterancy_Shared:OnRewardsClaimed(rankIndex, suppressSounds)
    if self:IsShowing() then
        local pageIndex = self.GetPageIndexFromRankIndex(rankIndex)
        local rankInfoData = self.scrollList:GetRankInfoDataByIndex(pageIndex)
        -- rankInfoData could be nil if the claimed rank is now shown in current view which can happen on claim all.
        if rankInfoData then
            local selectedData = self.scrollList:GetSelectedData()
            local gridList = self.scrollList:GetGridListByPageIndex(selectedData.pageIndex)
            for i, reward in ipairs(rankInfoData.rewardDataList) do
                local rewardTile = gridList:GetControlFromData(reward)
                local rewardableEventData = rewardTile.object:GetRewardableEventData()
                if rewardTile.object.OnRewardClaimed and not rewardableEventData:GetRewardData():IsInstanceOf(ZO_VeterancyPerkData) then
                    rewardTile.object:OnRewardClaimed()
                    if not suppressSounds then
                        PlaySound(SOUNDS.VETERANCY_RANK_REWARD_CLAIM)
                    end
                end
            end
            if not suppressSounds then
                if rankIndex == ZO_VETERANCY_RANK_GROUP_INDEX_UPPER_BOUND_HIGH then
                    PlaySound(SOUNDS.VETERANCY_RANK_REWARD_MAX_CLAIM)
                else
                    PlaySound(SOUNDS.VETERANCY_RANK_REWARD_CLAIM_RANK)
                end
            end
            local rankTile = gridList:GetControlFromData(rankInfoData)
            rankTile.object:UpdateKeybinds()
        end
    end
end

function ZO_Veterancy_Shared:OnRankProgressed(rankIndex, newProgress)
    if self:IsShowing() then
        self.scrollList:RefreshVisible()
        self:RefreshRepeatableRankDisplay()
        self:UpdateKeybinds()
    end
end

function ZO_Veterancy_Shared:OnRepeatableRankRewardClaimed()
    if self:IsShowing() then
        if self.repeatableRankRewardControl.object.OnRewardClaimed then
            self.repeatableRankRewardControl.object:OnRewardClaimed()
            self:RefreshRepeatableRankDisplay()
            PlaySound(SOUNDS.VETERANCY_RANK_REWARD_CLAIM_REPEATABLE)
        end
        self.repeatableRankRewardControl.object:UpdateKeybinds()
        self:UpdateKeybinds()
    end
end

function ZO_Veterancy_Shared:InitializeKeybindStripDescriptor()
    -- Can be overridden
end

function ZO_Veterancy_Shared:GetControlByPreviewableRewardData(previewableRewardData)
    if previewableRewardData then
        local selectedData = self.scrollList:GetSelectedData()
        local gridList = self.scrollList:GetGridListByPageIndex(selectedData.pageIndex)
        return gridList:GetControlFromData(previewableRewardData)
    end

    return nil
end

function ZO_Veterancy_Shared:PreviewRewardList(rewardId, control)
    -- Can be overridden
end

function ZO_Veterancy_Shared:EndPreviewRewardList()
    -- Can be overridden
end