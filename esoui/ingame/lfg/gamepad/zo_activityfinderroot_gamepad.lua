ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME = "gamepad_activity_finder_root"

--------------
--Initialize--
--------------

local ActivityFinderRoot_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ActivityFinderRoot_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ActivityFinderRoot_Gamepad:Initialize(control)
    local ACTIVATE_LIST_ON_SHOW = true
    GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE = ZO_Scene:New(ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME, SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW, GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE)
    self:SetListsUseTriggerKeybinds(true)
    self:AddRolesMenuEntry()

    self.hiddenEntries = {}

    local function RefreshCategories()
        self:RefreshCategories()
    end

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnLevelUpdate", RefreshCategories)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", RefreshCategories)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, RefreshCategories)
    self.control:RegisterForEvent(EVENT_PROMOTIONAL_EVENTS_ACTIVITY_PROGRESS_UPDATED, RefreshCategories)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", RefreshCategories)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignSeenStateChanged", RefreshCategories)

    local function RefreshList()
        self:RefreshList()
    end
    self.control:RegisterForEvent(EVENT_GROUP_FINDER_STATUS_UPDATED, RefreshList)
    self.control:RegisterForEvent(EVENT_HOUSE_TOURS_STATUS_UPDATED, RefreshList)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", RefreshList)
end

function ActivityFinderRoot_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                    local targetData = self:GetMainList():GetTargetData()
                    if targetData then
                        local entryData = targetData.data
                        if entryData.isRoleSelector then
                            GAMEPAD_GROUP_ROLES_BAR:ToggleSelected()
                        else
                            if entryData.sceneName then
                                if entryData.onSceneShowingCallback then
                                    entryData:onSceneShowingCallback()
                                end
                                SCENE_MANAGER:Push(entryData.sceneName)
                            elseif entryData.categoryFragment then
                                self:DeactivateCurrentList()
                                entryData:activateCategory()
                            end
                        end
                    end
                end,
            enabled = function()
                local targetData = self:GetMainList():GetTargetData()
                if targetData and targetData.enabled then
                    if targetData.categoryFragment then
                        return targetData.activateCategory ~= nil
                    else
                        return true
                    end
                end
                return false
            end
        },
        -- More Info
        {
            name = GetString(SI_ACTIVITY_FINDER_MORE_INFO_KEYBIND),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            visible = function()
                local targetData = self:GetMainList():GetTargetData()
                if targetData then
                    local entryData = targetData.data
                    if entryData.GetHelpIndices then
                        local helpCategoryIndex, helpIndex = entryData.GetHelpIndices()
                        return helpCategoryIndex ~= nil
                    end
                end

                return false
            end,
            callback = function()
                local targetData = self:GetMainList():GetTargetData()
                local entryData = targetData.data
                local helpCategoryIndex, helpIndex = entryData.GetHelpIndices()
                HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(helpCategoryIndex, helpIndex)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ActivityFinderRoot_Gamepad:OnDeferredInitialize()
    self.headerData =
    {
        titleText = GetString(SI_MAIN_MENU_ACTIVITY_FINDER),
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ActivityFinderRoot_Gamepad:SetupList(list)
    local function CategoryEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        local categoryData = data.data
        local isLocked = self:IsCategoryLocked(categoryData)
        enabled = enabled and not isLocked
        data.enabled = enabled
        data.iconUpdateFn = function()
            local categoryData = data.data
            data:ClearIcons()
            if data.enabled then
                data:AddIcon(data.data.menuIcon)
            else
                data:AddIcon(data.data.disabledMenuIcon)
            end

            if categoryData.isGroupFinder and ZO_HasGroupFinderNewApplication() then
                data:AddIcon(ZO_GAMEPAD_NEW_ICON_64)
            end

            if categoryData.isPromotionalEvent and not IsPromotionalEventSystemLocked() then
                local currentCampaignData = PROMOTIONAL_EVENT_MANAGER:GetCurrentCampaignData()
                if currentCampaignData and (not currentCampaignData:HasBeenSeen() or currentCampaignData:IsAnyRewardClaimable()) then
                    data:AddIcon(ZO_GAMEPAD_NEW_ICON_64)
                end
            end
        end

        if categoryData.isPromotionalEvent and enabled then
            data:SetNameColors(ZO_PROMOTIONAL_EVENT_SELECTED_COLOR, ZO_PROMOTIONAL_EVENT_UNSELECTED_COLOR)
            data:SetIconTint(ZO_PROMOTIONAL_EVENT_SELECTED_COLOR, ZO_PROMOTIONAL_EVENT_UNSELECTED_COLOR)
        end

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    local function OnSelectedMenuEntry(_, selectedData, oldSelectedData)
        if GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:GetState() ~= SCENE_HIDDEN then
            if oldSelectedData and oldSelectedData.data and oldSelectedData.data.categoryFragment then
                SCENE_MANAGER:RemoveFragment(oldSelectedData.data.categoryFragment)
            end

            if selectedData.data.isRoleSelector then
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                GAMEPAD_GROUP_ROLES_BAR:Activate()
            elseif selectedData.data.categoryFragment then
                GAMEPAD_GROUP_ROLES_BAR:Deactivate()
                if self:IsCategoryLocked(selectedData.data) then
                    self:RefreshTooltip(selectedData.data)
                else
                    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                    SCENE_MANAGER:AddFragment(selectedData.data.categoryFragment)
                end
            else
                GAMEPAD_GROUP_ROLES_BAR:Deactivate()
                self:RefreshTooltip(selectedData.data)
            end

            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    list:SetOnSelectedDataChangedCallback(OnSelectedMenuEntry)

    GAMEPAD_GROUP_ROLES_BAR:SetupListAnchorsBelowGroupBar(list.control)

    list:SetDefaultSelectedIndex(2) --Don't select roles by default
end

----------
--Update--
----------

function ActivityFinderRoot_Gamepad:PerformUpdate()
    --We must override this
end

function ActivityFinderRoot_Gamepad:OnShowing()
    self:RefreshList()
end

function ActivityFinderRoot_Gamepad:RefreshList()
    if self.scene:IsShowing() then
        local list = self:GetMainList()
        local commitList = false
        for i = 1, list:GetNumEntries() do
            local entryData = list:GetEntryData(i)
            local data = entryData and entryData.data
            if data then
                if data.categoryFragment then
                    -- We'll re-add this below if it should stick around. Triggers a hide/show to mirror keyboard group menu behavior.
                    SCENE_MANAGER:RemoveFragment(data.categoryFragment)
                end
                if data.visible and not data.visible() then
                    table.insert(self.hiddenEntries, entryData)
                    list:RemoveEntry("ZO_GamepadMenuEntryTemplate", entryData)
                    commitList = true
                end
            end
        end

        for i = #self.hiddenEntries, 1, -1 do
            local entryData = self.hiddenEntries[i]
            if entryData.data.visible() then
                list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
                table.remove(self.hiddenEntries, i)
                commitList = true
            end
        end

        if commitList then
            local DONT_RESELECT_SELECTED_INDEX = true
            list:Commit(DONT_RESELECT_SELECTED_INDEX)
        end

        --Make sure we aren't interacting with the roles bar when we get there
        local targetData = list:GetTargetData()
        if targetData and targetData.data.isRoleSelector then
            local DONT_ANIMATE = false
            local ALLOW_EVEN_IF_DISABLED = true
            list:SetDefaultIndexSelected(DONT_ANIMATE, ALLOW_EVEN_IF_DISABLED)
            targetData = list:GetTargetData()
        elseif targetData.data.categoryFragment then
            if not self:IsCategoryLocked(targetData.data) then
                SCENE_MANAGER:AddFragment(targetData.data.categoryFragment)
            end
        else
            GAMEPAD_GROUP_ROLES_BAR:Deactivate()
        end
        list:RefreshVisible()
        self:RefreshTooltip(targetData.data)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

do
    local LOCK_TEXTURE = zo_iconFormat(ZO_GAMEPAD_LOCKED_ICON_32, "100%", "100%")
    local CHAMPION_ICON = zo_iconFormat(ZO_GetGamepadChampionPointsIcon(), "100%", "100%")

    function ActivityFinderRoot_Gamepad:RefreshTooltip(data)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        if self.scene:IsShowing() and not data.isRoleSelector then
            local lockedText = nil
            if data.activityFinderObject then
                local isLevelLocked, lowestLevelLimit, lowestPointsLimit = data.activityFinderObject:GetLevelLockInfo()
                if isLevelLocked then
                    if lowestLevelLimit then
                        lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_LEVEL_LOCK, LOCK_TEXTURE, lowestLevelLimit)
                    elseif lowestPointsLimit then
                        lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_CHAMPION_LOCK, LOCK_TEXTURE, CHAMPION_ICON, lowestPointsLimit)
                    end
                else
                    local numLocations = data.activityFinderObject:GetNumLocations()
                    if numLocations == 0 then
                        lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_NO_ACTIVITIES_LOCK, LOCK_TEXTURE)
                    end
                end
            end

            if data.isZoneStories then
                local isLocked = ZONE_STORIES_MANAGER:GetZoneData(ZONE_STORIES_MANAGER.GetDefaultZoneSelection()) == nil
                if isLocked then
                    lockedText = zo_strformat(SI_ZONE_STORY_TOOLTIP_UNAVAILABLE_IN_ZONE, LOCK_TEXTURE)
                end
            end

            if data.isGroupFinder then
                local statusResult = GetGroupFinderStatusReason()
                if statusResult ~= GROUP_FINDER_ACTION_RESULT_SUCCESS and statusResult ~= GROUP_FINDER_ACTION_RESULT_FAILED_ACCOUNT_TYPE_BLOCKS_CREATION then
                    if statusResult == GROUP_FINDER_ACTION_RESULT_FAILED_LEVEL_REQUIREMENT then
                        local formatter = GetString("SI_GROUPFINDERACTIONRESULT", statusResult)
                        lockedText = zo_strformat(formatter, LOCK_TEXTURE, GROUP_FINDER_UNLOCK_LEVEL)
                    else
                        lockedText = GetString("SI_GROUPFINDERACTIONRESULT", statusResult)
                    end
                end
            end

            if data.isHouseTours then
                local isEnabled, houseToursLockedText = ZO_IsHouseToursEnabled()
                if not isEnabled then
                    lockedText = houseToursLockedText
                end
            end

            if data.isPromotionalEvent then
                if IsPromotionalEventSystemLocked() then
                    lockedText = GetString(SI_ACTIVITY_FINDER_TOOLTIP_PROMOTIONAL_EVENT_LOCK)
                end
            end

            if not data.categoryFragment or lockedText then
                GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, data.name, data.tooltipDescription, lockedText)
            end
        end
    end
end

--Add an ethereal entry to interact with the roles
function ActivityFinderRoot_Gamepad:AddRolesMenuEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.data =
    {
        isRoleSelector = true,
    }

    local list = self:GetMainList()
    list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
end

function ActivityFinderRoot_Gamepad:AddCategory(categoryData, categoryPriority)
    local function PrioritySort(item1, item2)
        local item1Data = item1.data
        local item2Data = item2.data
        if item1Data.isRoleSelector then
            return true
        end

        if item2Data.isRoleSelector then
            return false
        end

        if not item1Data.priority and not item2Data.priority then
            return item1Data.name < item2Data.name
        end

        if item1Data.priority and not item2Data.priority then
            return true
        end

        if not item1Data.priority and item2Data.priority then
            return false
        end

        return item1Data.priority < item2Data.priority
    end

    if categoryData.onShowingCallback then
        -- onShowingCallback is now deprecated
        -- Maintaining backwards compatibility
        categoryData.onSceneShowingCallback = categoryData.onShowingCallback
    end

    local entryData = ZO_GamepadEntryData:New(categoryData.name, categoryData.menuIcon)
    entryData.data = categoryData
    entryData.data.priority = categoryPriority
    entryData:SetIconTintOnSelection(true)

    local list = self:GetMainList()
    list:SetSortFunction(PrioritySort)
    list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)

    local DONT_RESELECT_SELECTED_INDEX = true
    list:Commit(DONT_RESELECT_SELECTED_INDEX)
end

function ActivityFinderRoot_Gamepad:RefreshCategories()
    local list = self:GetMainList()
    list:RefreshVisible()
    list:Commit()
end

function ActivityFinderRoot_Gamepad:SelectCategory(categoryData)
    local list = self:GetMainList()
    for i = 1, list:GetNumEntries() do
        if categoryData.gamepadData.name == list:GetEntryData(i).data.name then
            list:SetSelectedIndex(i)
            break
        end
    end
end

function ActivityFinderRoot_Gamepad:IsCategoryLocked(gamepadCategoryData)
    local activityFinderObject = gamepadCategoryData.activityFinderObject
    if activityFinderObject then
        return activityFinderObject:GetLevelLockInfo() or activityFinderObject:GetNumLocations() == 0
    elseif gamepadCategoryData.isZoneStories then
        return ZONE_STORIES_MANAGER:GetZoneData(ZONE_STORIES_MANAGER.GetDefaultZoneSelection()) == nil
    elseif gamepadCategoryData.isGroupFinder then
        local statusResult = GetGroupFinderStatusReason()
        return statusResult ~= GROUP_FINDER_ACTION_RESULT_SUCCESS and statusResult ~= GROUP_FINDER_ACTION_RESULT_FAILED_ACCOUNT_TYPE_BLOCKS_CREATION
    elseif gamepadCategoryData.isHouseTours then
        local houseToursEnabled = ZO_IsHouseToursEnabled()
        return not houseToursEnabled
    elseif gamepadCategoryData.isPromotionalEvent then
        return IsPromotionalEventSystemLocked()
    end
    return false
end

function ActivityFinderRoot_Gamepad:ShowCategory(categoryData)
    local gamepadCategoryData = categoryData.gamepadData
    assert(gamepadCategoryData.sceneName or gamepadCategoryData.categoryFragment, "A gamepad Activity Finder entry must have a scene or a fragment")

    local locked = self:IsCategoryLocked(gamepadCategoryData)
    -- TODO Promotional Events: Add check for if there's more than one campaign to control drill in
    local canShowScene = gamepadCategoryData.sceneName and not locked
    if canShowScene then
        if not SCENE_MANAGER:IsShowing(gamepadCategoryData.sceneName) then
            -- Order matters:
            if gamepadCategoryData.onSceneShowingCallback then
                gamepadCategoryData:onSceneShowingCallback()
            end
            MAIN_MENU_GAMEPAD:SelectMenuEntry(ZO_MENU_MAIN_ENTRIES.ACTIVITY_FINDER)
            SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME, gamepadCategoryData.sceneName)
        end
    else
        if not SCENE_MANAGER:IsShowing(ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME) then
            MAIN_MENU_GAMEPAD:SelectMenuEntry(ZO_MENU_MAIN_ENTRIES.ACTIVITY_FINDER)
            SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME)
        end
        self:SelectCategory(categoryData)
    end
end

----------------------------------------------
--ZO_Gamepad_ParametricList_Screen Overrides--
----------------------------------------------

function ActivityFinderRoot_Gamepad:GetFooterNarration()
    if GAMEPAD_ACTIVITY_QUEUE_DATA:IsShowing() then
        return GAMEPAD_GENERIC_FOOTER:GetNarrationText(GAMEPAD_ACTIVITY_QUEUE_DATA:GetFooterData())
    end
end

function ZO_ActivityFinderRoot_Gamepad_OnInitialize(control)
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD = ActivityFinderRoot_Gamepad:New(control)
end