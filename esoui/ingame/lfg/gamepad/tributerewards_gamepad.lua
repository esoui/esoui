---------------------
-- Tribute Rewards --
---------------------

ZO_TRIBUTE_REWARDS_ROW_HEIGHT_GAMEPAD = 100

ZO_TributeRewards_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_TributeRewards_Gamepad:Initialize(control)
    self.isShowScryableQueued = false
    self.queuedBrowseToAntiquityOrSetData = nil

    self:InitializeControl(control)
    self:InitializeLists()
    self:InitializeEvents()
end

function ZO_TributeRewards_Gamepad:InitializeControl(control)
    GAMEPAD_TRIBUTE_REWARDS_SCENE = ZO_Scene:New("tribute_rewards_gamepad", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, ACTIVATE_ON_SHOW, GAMEPAD_TRIBUTE_REWARDS_SCENE)

    self.fragment = ZO_SimpleSceneFragment:New(control)
    ZO_TRIBUTE_REWARDS_GAMEPAD_FRAGMENT = self.fragment
    self.fragment:SetHideOnSceneHidden(true)
    self.scene:AddFragment(ZO_TRIBUTE_REWARDS_GAMEPAD_FRAGMENT)

    self.currentRewardsType = ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS
end

function ZO_TributeRewards_Gamepad:InitializeLists()
    local list = self:GetMainList()
    list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    local USE_DEFAULT_COMPARISON = nil
    list:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, USE_DEFAULT_COMPARISON, "ZO_GamepadMenuEntryHeaderTemplate")
    list:SetNoItemText(GetString(SI_TRIBUTE_FINDER_REWARDS_EMPTY))

     -- Initialize each lists' keybinds.
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                self:DeactivateList()
                TRIBUTE_REWARDS_LIST_GAMEPAD:Activate()
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self:SetListsUseTriggerKeybinds(true)
    self:RefreshCategories()
    self:RefreshRewardsList()
end

function ZO_TributeRewards_Gamepad:InitializeEvents()
    -- TODO Tribute: Add events here
end

------------------------------------------------
-- Overrides ZO_Gamepad_ParametricList_Screen --
------------------------------------------------

function ZO_TributeRewards_Gamepad:PerformUpdate()
    self:RefreshRewardsList()
end

function ZO_TributeRewards_Gamepad:RefreshKeybinds()
    if self.keybindStripDescriptor and self:IsShowing() then
        if not KEYBIND_STRIP:HasKeybindButtonGroup(self.keybindStripDescriptor) then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        else
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end
end

---------------------------------------------------
-- End Override ZO_Gamepad_ParametricList_Screen --
---------------------------------------------------

function ZO_TributeRewards_Gamepad:ActivateList()
    self:GetMainList():Activate()
    self:RefreshKeybinds()
end

function ZO_TributeRewards_Gamepad:DeactivateList()
    self:GetMainList():Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TributeRewards_Gamepad:RefreshHeader(title)
    self.headerData =
    {
        titleText = title or GetString(SI_TRIBUTE_FINDER_REWARDS_TITLE),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_TributeRewards_Gamepad:RefreshCategories(resetSelectionToTop)
    self:RefreshHeader()

    -- Add the category entries.
    local list = self:GetMainList()
    list:Clear()

    for i, type in ipairs(ZO_TRIBUTE_REWARD_TYPE_LIST) do
        local rewardsTypeData = TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(type)
        if rewardsTypeData then
            local entryData = ZO_GamepadEntryData:New(rewardsTypeData:GetTierHeader())
            entryData:SetDataSource(rewardsTypeData)
            list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
        end
    end

    list:Commit(resetSelectionToTop)
end

function ZO_TributeRewards_Gamepad:OnTargetChanged(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex)
    if targetData then
        self.currentRewardsType = targetData.dataSource:GetRewardsTypeId()
        self:RefreshRewardsList()
    end
end

function ZO_TributeRewards_Gamepad:RefreshRewardsList()
    if TRIBUTE_REWARDS_LIST_GAMEPAD then
        TRIBUTE_REWARDS_LIST_GAMEPAD:SetRewardsType(self.currentRewardsType)
        TRIBUTE_REWARDS_LIST_GAMEPAD:RefreshRewards()

        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
        if self:GetMainList():IsActive() then
            local rewardsTypeData = TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(self.currentRewardsType)
            GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, nil, rewardsTypeData:GetDescription())
        end
    end
end

--------------------------
-- Tribute Rewards List --
--------------------------

ZO_TributeRewardsList_Gamepad = ZO_SortFilterList_Gamepad:Subclass()

function ZO_TributeRewardsList_Gamepad:Initialize(control)
    self:InitializeControl(control)
    self:InitializeLists()
end

function ZO_TributeRewardsList_Gamepad:InitializeControl(control)
    self.control = control
    ZO_SortFilterList_Gamepad.Initialize(self, self.control)
    ZO_SortFilterList_Gamepad.InitializeSortFilterList(self, self.control)

    self.titleLabel = self.control:GetNamedChild("Label")
    self.emptyLabel = self.control:GetNamedChild("EmptyLabel")

    local function OnStateChanged(...)
        self:OnStateChanged(...)
    end

    self.fragment = ZO_SimpleSceneFragment:New(self.control)
    ZO_TRIBUTE_REWARDS_LIST_GAMEPAD_FRAGMENT = self.fragment
    self.fragment:RegisterCallback("StateChange", OnStateChanged)

    self.currentRewardsType = ZO_TRIBUTE_REWARD_TYPES.SEASON_REWARDS
end

function ZO_TributeRewardsList_Gamepad:SetRewardsType(rewardsType)
    self.currentRewardsType = rewardsType
end

function ZO_TributeRewardsList_Gamepad:InitializeLists()
    local listControl = self:GetListControl()

    local function SetupTributeRewardsRow(control, data)
        control.iconTexture:SetTexture(data:GetTierIcon())
        control.tierLabel:SetText(data:GetTierName())
        control.rewardsNameLabel:SetText(data:GetRewardListName())
        control.rewardsNameLabel:SetColor(data:GetRewardsTierColor())

        control.status:ClearIcons()
        if data:IsAttained() then
            control.status:AddIcon(ZO_CHECK_ICON)
            control.status:Show()
        end
    end
    ZO_ScrollList_AddDataType(listControl, 1, "ZO_TributeRewards_Row_Gamepad", ZO_TRIBUTE_REWARDS_ROW_HEIGHT_GAMEPAD, SetupTributeRewardsRow)

     -- Initialize keybinds
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:Deactivate()
        TRIBUTE_REWARDS_GAMEPAD:ActivateList()
        TRIBUTE_REWARDS_GAMEPAD:RefreshRewardsList()
    end)
end

-----------------------------------------
-- Overrides ZO_SortFilterList_Gamepad --
-----------------------------------------

function ZO_TributeRewardsList_Gamepad:Activate(animateInstantly, scrollAutoSelectedDataIntoView)
    ZO_SortFilterList_Gamepad.Activate(self, animateInstantly, scrollAutoSelectedDataIntoView)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TributeRewardsList_Gamepad:Deactivate()
    ZO_SortFilterList_Gamepad.Deactivate(self)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TributeRewardsList_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, oldData, newData)

    if newData then
        local rewardListEntryColor = ZO_ColorDef:New(newData:GetRewardsTierColor())
        local colorizedRewardListName = rewardListEntryColor:Colorize(newData:GetRewardListName())
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, colorizedRewardListName, newData:GetRewardListDescription())
    end
end

--------------------------------------------
-- End Override ZO_SortFilterList_Gamepad --
--------------------------------------------

function ZO_TributeRewardsList_Gamepad:RefreshRewards()
    -- Refresh the header
    local rewardsTypeData = TRIBUTE_REWARDS_DATA_MANAGER:GetTributeRewardsTypeData(self.currentRewardsType)
    self.titleLabel:SetText(rewardsTypeData:GetTierHeader())

    -- Build list content
    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    for _, tributeRewardsData in TRIBUTE_REWARDS_DATA_MANAGER:TributeRewardsTypeIterator(self.currentRewardsType) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, tributeRewardsData))
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_TributeRewardsList_Gamepad:OnStateChanged(state)
    if state == SCENE_FRAGMENT_HIDING then
        self:OnHiding()
    end
end

function ZO_TributeRewardsList_Gamepad:OnHiding()
    self:ClearRewardsTooltip()
    self:Deactivate()
end

function ZO_TributeRewardsList_Gamepad:ClearRewardsTooltip()
    local DO_NOT_RETAIN_FRAGMENT = false
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, DO_NOT_RETAIN_FRAGMENT)
end

--------------
-- Global XML
--------------

function ZO_TributeRewards_Row_Gamepad_OnInitialized(control)
    control.iconTexture = control:GetNamedChild("IconTexture")
    control.status = control:GetNamedChild("Status")
    control.tierLabel = control:GetNamedChild("TierLabel")
    control.rewardsNameLabel = control:GetNamedChild("RewardsNameLabel")
    control.goldLabel = control:GetNamedChild("GoldLabel")
end

function ZO_TributeRewards_Gamepad_OnInitialized(control)
    TRIBUTE_REWARDS_GAMEPAD = ZO_TributeRewards_Gamepad:New(control)
end

function ZO_TributeRewardsList_Gamepad_OnInitialized(control)
    TRIBUTE_REWARDS_LIST_GAMEPAD = ZO_TributeRewardsList_Gamepad:New(control)
end