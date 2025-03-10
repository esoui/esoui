ZO_GAMEPAD_ACTIVITY_FINDER_BACKGROUND_TEXTURE_SQUARE_DIMENSION = 1024
ZO_GAMEPAD_ACTIVITY_FINDER_BACKGROUND_TEXTURE_COORD_RIGHT = ZO_GAMEPAD_QUADRANT_2_3_CONTENT_BACKGROUND_WIDTH / ZO_GAMEPAD_ACTIVITY_FINDER_BACKGROUND_TEXTURE_SQUARE_DIMENSION

local NAVIGATION_MODES = 
{
    CATEGORIES = 1,
    RANDOM_ENTRIES = 2,
    SPECIFIC_ENTRIES = 3,
}

local RANDOM_CATEGORY_ICON = "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_Random.dds"

ZO_ActivityFinderTemplate_Gamepad = ZO_Object.MultiSubclass(ZO_ActivityFinderTemplate_Shared, ZO_Gamepad_ParametricList_Screen)

function ZO_ActivityFinderTemplate_Gamepad:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_ActivityFinderTemplate_Gamepad:Initialize(dataManager, categoryData, categoryPriority)
    self.tributeProgressSegmentTemplate = "ZO_TributeFinder_ArrowStatusBarTemplate_Gamepad"
    local control = CreateControlFromVirtual(dataManager:GetName() .. "_Gamepad", GuiRoot, "ZO_ActivityFinderTemplateTopLevel_Gamepad")
    ZO_ActivityFinderTemplate_Shared.Initialize(self, control, dataManager, categoryData, categoryPriority)
    local ACTIVATE_LIST_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, ACTIVATE_LIST_ON_SHOW, self.scene)
    self:SetListsUseTriggerKeybinds(true)
    self:InitializeLists()

    self.rewardsOffsetYDefault = 50
    self.rewardsOffsetYTribute = 0
end

function ZO_ActivityFinderTemplate_Gamepad:GetSystemName()
    return "ActivityFinder_Gamepad"
end

function ZO_ActivityFinderTemplate_Gamepad:InitializeControls()
    ZO_ActivityFinderTemplate_Shared.InitializeControls(self, "ZO_ActivityFinderTemplateRewardTemplate_Gamepad")
    self.headerControl = self.control:GetNamedChild("MaskContainerHeaderContainerHeader")
end

function ZO_ActivityFinderTemplate_Gamepad:InitializeFragment()
    local categoryData = self.categoryData
    local scene = ZO_Scene:New(categoryData.sceneName, SCENE_MANAGER)
    local fragment = ZO_SimpleSceneFragment:New(self.control)
    fragment:SetHideOnSceneHidden(true)
    scene:AddFragment(fragment)

    self.scene = scene
    self.fragment = fragment
    self.singularFragment = ZO_FadeSceneFragment:New(self.singularSection)
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddCategory(categoryData, self.categoryPriority)
end

function ZO_ActivityFinderTemplate_Gamepad:InitializeFilters()
    self.categoryHeaderData =
    {
        titleText = self.categoryData.name,
    }

    self.randomHeaderData =
    {
        titleText = self.dataManager:GetFilterModeData():GetRandomFilterName(),
    }

    self:RefreshSpecificFilters()
end

function ZO_ActivityFinderTemplate_Gamepad:InitializeLists()
    --When we have "random" entries and "specific" entries, we have the user drill down into a further subcategory
    --Where they can either select from a list of random activitiy types, or a list of specific activities
    local modes = self.dataManager:GetFilterModeData()
    local activityTypes = modes:GetActivityTypes()
    local hasEntriesWithRewards = false
    local hasEntriesWithoutRewards = false
    for _, activityType in ipairs(activityTypes) do
        local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(activityType)
        for _, location in ipairs(locationData) do
            if modes:IsEntryTypeVisible(location:GetEntryType()) then
                if location:HasRewardData() then
                    hasEntriesWithRewards = true
                else
                    hasEntriesWithoutRewards = true
                end

                if hasEntriesWithRewards and hasEntriesWithoutRewards then
                    break
                end
            end
        end
    end

    if hasEntriesWithRewards and hasEntriesWithoutRewards then
        self.categoryList = self:GetMainList()
        if not self.categoryData.hideGroupRoles then
            self:AddRolesMenuEntry(self.categoryList)
        end
        local filterModes = self.dataManager:GetFilterModeData()

        local randomEntryData = ZO_GamepadEntryData:New(filterModes:GetRandomFilterName(), RANDOM_CATEGORY_ICON)
        randomEntryData.data =
        {
            navigationMode = NAVIGATION_MODES.RANDOM_ENTRIES,
        }
        randomEntryData:SetIconTintOnSelection(true)
        self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", randomEntryData)

        local specificEntryData = ZO_GamepadEntryData:New(filterModes:GetSpecificFilterName(), self.categoryData.menuIcon)
        specificEntryData.data =
        {
            navigationMode = NAVIGATION_MODES.SPECIFIC_ENTRIES,
        }
        specificEntryData:SetIconTintOnSelection(true)

        self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", specificEntryData)
        self.categoryList:Commit()

        self.entryList = self:AddList("Entries")
        self.hasCategories = true

        local categoryListControl = self.categoryList:GetControl()
        categoryListControl:SetAnchor(TOPLEFT, self.headerControl, BOTTOMLEFT, 0, ZO_GAMEPAD_ROLES_BAR_ADDITIONAL_HEADER_SPACE)
    else
        self.entryList = self:GetMainList()
        self.hasCategories = false
        self.defaultNavigationMode = hasEntriesWithRewards and NAVIGATION_MODES.RANDOM_ENTRIES or NAVIGATION_MODES.SPECIFIC_ENTRIES
    end
    
    self.entryList:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.entryList:AddDataTemplateWithHeader("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    local entryListControl = self.entryList:GetControl()
    entryListControl:SetAnchor(TOPLEFT, self.headerControl, BOTTOMLEFT, 0, ZO_GAMEPAD_ROLES_BAR_ADDITIONAL_HEADER_SPACE)
end

function ZO_ActivityFinderTemplate_Gamepad:InitializeSingularPanelControls(rewardsTemplate)
    ZO_ActivityFinderTemplate_Shared.InitializeSingularPanelControls(self, rewardsTemplate)

    local function OnUpdate()
        if self.lockReasonTextFunction then
            local lockedReasonText = self.lockReasonTextFunction() or ""
            self:LayoutLockedTooltip(lockedReasonText)
        end
    end
    self.control:SetHandler("OnUpdate", OnUpdate)
end

function ZO_ActivityFinderTemplate_Gamepad:LayoutLockedTooltip(lockReasonText)
    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_GAMEPAD_ACTIVITY_FINDER_LOCATION_LOCKED_TOOLTIP_TITLE), lockReasonText)
end

function ZO_ActivityFinderTemplate_Gamepad:RegisterEvents()
    ZO_ActivityFinderTemplate_Shared.RegisterEvents(self)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnSelectionsChanged", function(...) self:RefreshSelections(...) end)
end

function ZO_ActivityFinderTemplate_Gamepad:OnDeferredInitialize()
    self.singularFragmentGroup = { self.singularFragment, GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT }
    self.isShowingSingularPanel = false
end

function ZO_ActivityFinderTemplate_Gamepad:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)

    local function OnSelectedEntry(_, selectedData)
        if selectedData.data.isRoleSelector then
            GAMEPAD_GROUP_ROLES_BAR:Activate()
        else
            GAMEPAD_GROUP_ROLES_BAR:Deactivate()
        end

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        self:RefreshSingularSectionPanel()
    end

    list:SetOnSelectedDataChangedCallback(OnSelectedEntry)
    list:SetDefaultSelectedIndex(2) --Don't select roles by default
end

function ZO_ActivityFinderTemplate_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local entryData = self:GetCurrentList():GetTargetData().data
                if entryData.isRoleSelector then
                    GAMEPAD_GROUP_ROLES_BAR:ToggleSelected()
                else
                    if self.navigationMode == NAVIGATION_MODES.CATEGORIES then
                        local navigationMode = entryData.navigationMode
                        self:SetNavigationMode(navigationMode)
                    else
                        ZO_ACTIVITY_FINDER_ROOT_MANAGER:ToggleLocationSelected(entryData)
                        --Re-narrate when toggling selection
                        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList())
                    end
                end
            end,

            enabled = function()
                local currentList = self:GetCurrentList()
                if currentList then
                    local targetData = currentList:GetTargetData()
                    return targetData and targetData:IsEnabled()
                end
                return false
            end,
        },

        -- Back
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),

            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                if self.navigationMode == NAVIGATION_MODES.CATEGORIES or not self.hasCategories then
                    SCENE_MANAGER:HideCurrentScene()
                else
                    ZO_ACTIVITY_FINDER_ROOT_MANAGER:ClearSelections()
                    self:SetNavigationMode(NAVIGATION_MODES.CATEGORIES)
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },

        -- View Rewards
        {
            name = GetString(SI_LFG_VIEW_REWARDS),

            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                SCENE_MANAGER:Push("tribute_rewards_gamepad")
            end,

            enabled = function()
                return HasActiveCampaignStarted()
            end,

            visible = function()
                local currentList = self:GetCurrentList()
                if currentList then
                    local targetData = currentList:GetTargetData()
                    if targetData and targetData.data then
                        return targetData.data.activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE
                    end
                end
                return false
            end,
        },

        -- Ungate
        {
            name = function()
                local filterData = self:GetCurrentList():GetTargetData().data
                local lockingCollectibleId = filterData:GetFirstLockingCollectible()
                if lockingCollectibleId == 0 then
                    return GetString(SI_LFG_ACCEPT_QUEST)
                else
                    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(lockingCollectibleId)
                    local categoryType = collectibleData:GetCategoryType()
                    if categoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
                        return GetString(SI_DLC_BOOK_ACTION_CHAPTER_UPGRADE)
                    else
                        return GetString(SI_GAMEPAD_DLC_BOOK_ACTION_OPEN_CROWN_STORE)
                    end
                end
            end,

            keybind = "UI_SHORTCUT_QUATERNARY",

            callback = function()
                local filterData = self:GetCurrentList():GetTargetData().data
                local lockingCollectibleId = filterData:GetFirstLockingCollectible()
                if lockingCollectibleId == 0 then
                    BestowActivityTypeGatingQuest(self:GetCurrentList():GetTargetData().data:GetActivityType())
                else
                    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(lockingCollectibleId)
                    local categoryType = collectibleData:GetCategoryType()
                    if categoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
                        ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_ACTIVITY_FINDER)
                    else
                        local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                        ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_ACTIVITY_FINDER)
                    end
                end
            end,

            enabled = function()
                local filterData = self:GetCurrentList():GetTargetData().data
                local lockingCollectibleId = filterData:GetFirstLockingCollectible()
                if lockingCollectibleId == 0 then
                    return not HasQuest(filterData:GetQuestToUnlock())
                end
                return true
            end,

            visible = function()
                local currentList = self:GetCurrentList()
                if currentList then
                    local targetData = currentList:GetTargetData()
                    local filterData = targetData and targetData.data
                    if filterData and filterData.IsInstanceOf and filterData:IsInstanceOf(ZO_ActivityFinderLocation_Base) then
                        local lockingCollectibleId = filterData:GetFirstLockingCollectible()
                        if lockingCollectibleId == 0 then
                            local questId = filterData:GetQuestToUnlock()
                            return questId ~= 0
                        else
                            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(lockingCollectibleId)
                            return collectibleData:IsStory()
                        end
                    end
                end
                return false
            end,
        },

        -- Toggle Queue
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            name = function()
                local stringId = IsCurrentlySearchingForGroup() and SI_LFG_LEAVE_QUEUE or SI_LFG_JOIN_QUEUE
                return GetString(stringId)
            end,

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                if IsCurrentlySearchingForGroup() then
                    ZO_Dialogs_ShowGamepadDialog("LFG_LEAVE_QUEUE_CONFIRMATION")
                else
                    ZO_ACTIVITY_FINDER_ROOT_MANAGER:StartSearch()
                    PlaySound(SOUNDS.DIALOG_ACCEPT)
                    --Re-narrate when joining a queue
                    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList())
                end
            end,

            visible = function()
                local anySelected = ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsAnyLocationSelected()
                local currentlySearching = IsCurrentlySearchingForGroup()
                local playerCanToggleQueue = not ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsLockedByNotLeader()
                local isGroupFinderInUse = ZO_GroupFinder_IsGroupFinderInUse()
                return playerCanToggleQueue and (anySelected or currentlySearching) and not isGroupFinderInUse
            end,
        },
    }
end

function ZO_ActivityFinderTemplate_Gamepad:FilterByActivity(activityType)
    self.currentSpecificActivityType = activityType
    self:RefreshView()
end

function ZO_ActivityFinderTemplate_Gamepad:PerformUpdate()
    --Must be overridden
end

--Add an ethereal entry to interact with the roles
function ZO_ActivityFinderTemplate_Gamepad:AddRolesMenuEntry(list)
    local entryData = ZO_GamepadEntryData:New("")
    entryData.data =
    {
        isRoleSelector = true,
    }

    list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
end

function ZO_ActivityFinderTemplate_Gamepad:RefreshSelections()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:RefreshView()
end

function ZO_ActivityFinderTemplate_Gamepad:RefreshHeaderAndView(headerData)
    self.headerData = headerData
    ZO_GamepadGenericHeader_Refresh(self.header, headerData)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:ClearSelections()

    if self:IsShowing() then
        if self.headerData.tabBarEntries then
            ZO_GamepadGenericHeader_Activate(self.header)
        else
            ZO_GamepadGenericHeader_Deactivate(self.header)
        end
        self:RefreshView()
    end
end

function ZO_ActivityFinderTemplate_Gamepad:RefreshView()
    if not self:IsShowing() or self.navigationMode == NAVIGATION_MODES.CATEGORIES then
        return
    end

    self.entryList:Clear()
    if not self.categoryData.hideGroupRoles then
        self:AddRolesMenuEntry(self.entryList)
        self.entryList:SetDefaultSelectedIndex(2)
    else
        self.entryList:SetDefaultSelectedIndex(1)
    end
    local isSearching = IsCurrentlySearchingForGroup()
    local lockReasonTextOverride = self:GetGlobalLockText()
    local modes = self.dataManager:GetFilterModeData()

    if self.categoryData.isTribute then
        TriggerTutorial(TUTORIAL_TRIGGER_TRIBUTE_FINDER_OPENED)
    end

    local function AddLocationEntry(location)
        local name = location:GetNameGamepad()
        local locationEntryData = ZO_GamepadEntryData:New(name, self.categoryData.menuIcon)
        locationEntryData.data = location
        locationEntryData.data:SetLockReasonTextOverride(lockReasonTextOverride)
        locationEntryData:SetEnabled(not location:IsLocked() and not isSearching)
        locationEntryData:SetSelected(location:IsSelected())
        locationEntryData.selectedIconTint = ZO_WHITE
        locationEntryData.unselectedIconTint = ZO_GAMEPAD_UNSELECTED_COLOR

        locationEntryData.narrationText = function(entryData, entryControl)
            local narrations = {}

            ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(name))

            -- Group size indicator
            local TEAM_BASED_ACTIVITY_TYPES =
            {
                [LFG_ACTIVITY_BATTLE_GROUND_CHAMPION] = true,
                [LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION] = true,
                [LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL] = true,
            }
            local activityType = location:GetActivityType()

            if activityType ~= LFG_ACTIVITY_TRIBUTE_COMPETITIVE and activityType ~= LFG_ACTIVITY_TRIBUTE_CASUAL then
                local minGroupSize, maxGroupSize = location:GetGroupSizeRange()
                if TEAM_BASED_ACTIVITY_TYPES[activityType] then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_ACTIVITY_FINDER_GROUP_SIZE_TEAM_FORMAT, maxGroupSize)))
                elseif minGroupSize ~= maxGroupSize then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_GAMEPAD_ACTIVITY_FINDER_GROUP_SIZE_RANGE_NARRATION, minGroupSize, maxGroupSize)))
                else
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_GAMEPAD_ACTIVITY_FINDER_GROUP_SIZE_NARRATION, minGroupSize)))
                end
            end

            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(location:GetDescription()))

            if location:IsSetEntryType() then
                --MMR for Battlegrounds
                if location:HasMMR() then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_BATTLEGROUND_FINDER_MMR_HEADER)))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(location:GetMMR()))
                end

                -- Game type list for Battlegrounds
                local setTypesHeaderText = location:GetSetTypesHeaderText()
                local setTypesListText = location:GetSetTypesListText()
                if setTypesHeaderText ~= "" and setTypesListText ~= "" then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(setTypesHeaderText))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(setTypesListText))
                end
            end

            -- Rewards
            local currentSelectionHasRewardsData = location:HasRewardData()
            if currentSelectionHasRewardsData then
                if location:IsEligibleForDailyReward() then
                    if activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE then
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ACTIVITY_FINDER_FIRST_DAILY_REWARD_HEADER)))
                    else
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ACTIVITY_FINDER_DAILY_REWARD_HEADER)))
                    end
                else
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ACTIVITY_FINDER_STANDARD_REWARD_HEADER)))
                end

                local rewardUIDataId, xpReward = location:GetRewardData()

                if rewardUIDataId ~= 0 then
                    local numShownRewards = GetNumLFGActivityRewardUINodes(rewardUIDataId)
                    for rewardIndex = 1, numShownRewards do
                        local displayName = GetLFGActivityRewardUINodeInfo(rewardUIDataId, rewardIndex)
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_ACTIVITY_FINDER_REWARD_NAME_FORMAT, displayName)))
                    end
                end

                if xpReward > 0 then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_ACTIVITY_FINDER_REWARD_XP_FORMAT, ZO_CommaDelimitNumber(xpReward))))
                end
            end

            -- Tribute ranked match seasonal progression information
            if activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE then
                local tierRank = GetTributePlayerCampaignRank()
                if tierRank ~= TRIBUTE_TIER_INVALID then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString((SI_TRIBUTE_FINDER_SEASON_PROGRESS_HEADER))))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.tributeSeasonTimeRemainingText))

                    if tierRank == TRIBUTE_TIER_UNRANKED then
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.tributeSeasonRankText))
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.tributePlacementMatchNarrationText))
                    elseif tierRank ~= TRIBUTE_TIER_PLATINUM then
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.tributeSeasonRankText))
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.progressValueLabelText))

                        local experience, requiredExperience = GetTributePlayerExperienceInCurrentCampaignRank()
                        ZO_AppendNarration(narrations, ZO_GetProgressBarNarrationText(0, requiredExperience, experience))
                    else
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.leaderboardRankLabelText))
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.tributeSeasonRankText))
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.progressValueLabelText))
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_TRIBUTE_SEASON_EXPERIENCE_LIMIT_REACHED)))
                    end
                end
            end

            return narrations
        end

        self.entryList:AddEntry("ZO_GamepadItemSubEntryTemplate", locationEntryData)
    end

    if self.navigationMode == NAVIGATION_MODES.RANDOM_ENTRIES then
        local modeActivityTypes = modes:GetActivityTypes()
        ZO_ACTIVITY_FINDER_ROOT_MANAGER:RebuildSelections(modeActivityTypes)
        for _, activityType in ipairs(modeActivityTypes) do
            local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(activityType)
            for _, location in ipairs(locationData) do
                if modes:IsEntryTypeVisible(location:GetEntryType()) and location:IsActive() and location:HasRewardData() and location:DoesPlayerMeetLevelRequirements() then
                    AddLocationEntry(location)
                end
            end
        end
    else
        ZO_ACTIVITY_FINDER_ROOT_MANAGER:RebuildSelections( {self.currentSpecificActivityType } )
        local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(self.currentSpecificActivityType)

        for _, location in ipairs(locationData) do
            local isTribute = location.activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE or location.activityType == LFG_ACTIVITY_TRIBUTE_CASUAL
            if modes:IsEntryTypeVisible(location:GetEntryType()) and location:IsActive() and ((isTribute and location:HasRewardData()) or not location:HasRewardData()) then
                AddLocationEntry(location)
            end
        end
    end

    self.entryList:Commit()
end

function ZO_ActivityFinderTemplate_Gamepad:RefreshSpecificFilters()
    --Specific header data

    local specificHeaderData
    local modes = self.dataManager:GetFilterModeData()
    local modeActivityTypes = modes:GetActivityTypes()

    local validActivityTypes = {}
    for _, activityType in ipairs(modeActivityTypes) do
        if ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetNumLocationsByActivity(activityType, modes:GetVisibleEntryTypes()) > 0 then
            local isLocked = self:GetLevelLockInfoByActivity(activityType)
            if not isLocked then
                local data =
                {
                    activityType = activityType,
                    name = GetString("SI_LFGACTIVITY", activityType)
                }
                table.insert(validActivityTypes, data)
            end
        end
    end

    if #validActivityTypes > 1 then
        local tabBarEntries = {}
        for _, activityData in ipairs(validActivityTypes) do
            local tabData =
            {
                text = activityData.name,
                callback = function()
                    self:FilterByActivity(activityData.activityType)
                    -- Re-narrate on tab change
                    local NARRATE_HEADER = true
                    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.entryList, NARRATE_HEADER)
                end,
            }
            table.insert(tabBarEntries, tabData)
        end
        specificHeaderData = { tabBarEntries = tabBarEntries }
    elseif #validActivityTypes == 1 then
        self.currentSpecificActivityType = validActivityTypes[1].activityType
        specificHeaderData =
        {
            titleText = validActivityTypes[1].name,
        }
    else
        -- Shouldn't get here, but if the header data is nil it can cause a UI error
        specificHeaderData = {}
    end

    self.specificHeaderData = specificHeaderData
end

function ZO_ActivityFinderTemplate_Gamepad:RefreshFilters()
    self:RefreshSpecificFilters()
    if self.navigationMode == NAVIGATION_MODES.SPECIFIC_ENTRIES then
        self:RefreshHeaderAndView(self.specificHeaderData)
    elseif self.navigationMode == NAVIGATION_MODES.RANDOM_ENTRIES then
        self:RefreshHeaderAndView(self.randomHeaderData)
    end
end

function ZO_ActivityFinderTemplate_Gamepad:IsShowingTributeFinder()
    return self.categoryData.isTribute and self.categoryData.isTribute or false
end

function ZO_ActivityFinderTemplate_Gamepad:OnActivityFinderStatusUpdate()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:UpdateLocationData()
    self:RefreshView()
end

function ZO_ActivityFinderTemplate_Gamepad:OnShowing()
    local navigationMode = self.hasCategories and NAVIGATION_MODES.CATEGORIES or self.defaultNavigationMode
    self.isShowingSingularPanel = false
    self:SetNavigationMode(navigationMode)
    --If we have no categories we go straight into the default view, which means navigation mode never technically changes, so the header never gets reactivated
    if not self.hasCategories then
        local targetHeader
        if navigationMode == NAVIGATION_MODES.RANDOM_ENTRIES then
            targetHeader = self.randomHeaderData
        else
            targetHeader = self.specificHeaderData
        end
        self:RefreshHeaderAndView(targetHeader)
    end
end

function ZO_ActivityFinderTemplate_Gamepad:OnShow()
    local shouldShowLFMPrompt, lfmPromptActivityName = self:GetLFMPromptInfo()
    if shouldShowLFMPrompt then
        ZO_Dialogs_ShowGamepadDialog("PROMPT_FOR_LFM_REQUEST", nil, {mainTextParams = { lfmPromptActivityName }})
    end
end

function ZO_ActivityFinderTemplate_Gamepad:OnHiding()
    ZO_GamepadGenericHeader_Deactivate(self.header)

    self:HideTributeRank()
end

function ZO_ActivityFinderTemplate_Gamepad:ShowTributeRank()
    if self.isTributeClubDataInitialized then
        SCENE_MANAGER:AddFragment(GAMEPAD_ACTIVITY_TRIBUTE_RANK_FRAGMENT)
        if not self.defaultFooterAnchor then
            local isValid, point, relativeTo, relativePoint, offsetX, offsetY = ZO_GenericFooter_Gamepad:GetAnchor(0)
            if isValid then
                self.defaultFooterAnchor =
                {
                    point = point,
                    relativeTo = relativeTo,
                    relativePoint = relativePoint,
                    offsetX = offsetX,
                    offsetY = offsetY,
                }
            end
        end
        ZO_GenericFooter_Gamepad:ClearAnchors()
        ZO_GenericFooter_Gamepad:SetAnchor(RIGHT, ZO_ActivityTributeRankFooter_Gamepad_TL, LEFT, ZO_GAMEPAD_CONTENT_INSET_X)
    end
end

function ZO_ActivityFinderTemplate_Gamepad:HideTributeRank()
    SCENE_MANAGER:RemoveFragment(GAMEPAD_ACTIVITY_TRIBUTE_RANK_FRAGMENT)
    if self.defaultFooterAnchor then
        local anchor = self.defaultFooterAnchor
        ZO_GenericFooter_Gamepad:ClearAnchors()
        ZO_GenericFooter_Gamepad:SetAnchor(anchor.point, anchor.relativeTo, anchor.relativePoint, anchor.offsetX, anchor.offsetY)
    end
    self.defaultFooterAnchor = nil
end

function ZO_ActivityFinderTemplate_Gamepad:SetNavigationMode(navigationMode)
    --Determine the target list and header
    local targetList, targetHeader
     if navigationMode == NAVIGATION_MODES.CATEGORIES then
        targetList = self.categoryList
        targetHeader = self.categoryHeaderData
    else
        targetList = self.entryList
        if navigationMode == NAVIGATION_MODES.RANDOM_ENTRIES then
            targetHeader = self.randomHeaderData
        else
            targetHeader = self.specificHeaderData
        end
    end

    --Make sure we aren't interacting with the roles bar when we get there
    local targetData = targetList:GetTargetData()
    if targetData and targetData.data.isRoleSelector then
        local DONT_ANIMATE = false
        local ALLOW_EVEN_IF_DISABLED = true
        targetList:SetDefaultIndexSelected(DONT_ANIMATE, ALLOW_EVEN_IF_DISABLED)
    else
        GAMEPAD_GROUP_ROLES_BAR:Deactivate()
    end

    --Refresh only if it's not already the current list
    if self.navigationMode ~= navigationMode then
        --Order is important because SetCurrentList will Deactivate the old list which can make it change selected data to complete its movement (if it is moving). If the mode has changed before
        --this it will react incorrectly to the selected data changed callback.
        self:SetCurrentList(targetList)
        self.navigationMode = navigationMode
        
        self:RefreshHeaderAndView(targetHeader)
    end

    self:RefreshSingularSectionPanel()
end

do
    local GROUP_SIZE_ICON_FORMAT = zo_iconFormat("EsoUI/Art/LFG/Gamepad/gp_LFG_icon_groupSize.dds", 40, 40)

    function ZO_ActivityFinderTemplate_Gamepad:RefreshSingularSectionPanel()
        if self.navigationMode ~= NAVIGATION_MODES.CATEGORIES then
            local currentList = self:GetCurrentList()
            if currentList then
                local targetData = currentList:GetTargetData()
                if targetData then
                    local entryData = targetData.data
                    if not entryData.isRoleSelector then
                        if not self.isShowingSingularPanel then
                            SCENE_MANAGER:AddFragmentGroup(self.singularFragmentGroup)
                            self.isShowingSingularPanel = true
                        end

                        self.backgroundTexture:SetTexture(entryData.descriptionTextureGamepad)
                        self.titleLabel:SetText(entryData.nameGamepad)

                        entryData:SetGroupSizeRangeText(self.groupSizeRangeLabel, GROUP_SIZE_ICON_FORMAT)

                        self:RefreshRewards(entryData)
                        if entryData.isLocked then
                            local lockReasonText = entryData.lockReasonTextOverride or entryData.lockReasonText
                            if type(lockReasonText) == "function" then
                                self.lockReasonTextFunction = lockReasonText
                            else
                                self:LayoutLockedTooltip(lockReasonText)
                                self.lockReasonTextFunction = nil
                            end
                        else
                            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
                        end

                        local isCompetitive = entryData.activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE
                        local HIDE_IF_NOT_COMPETITIVE = not isCompetitive
                        self:RefreshTributeSeasonData(HIDE_IF_NOT_COMPETITIVE)
                        if isCompetitive then
                            if RequestTributeClubData() == TRIBUTE_PLAYER_INITIALIZATION_STATE_SUCCESS then
                                self:OnTributeClubDataInitialized()
                            end

                            if RequestActiveTributeCampaignData() == TRIBUTE_PLAYER_INITIALIZATION_STATE_SUCCESS then
                                self:OnTributeCampaignDataInitialized()
                            end

                            self:ShowTributeRank()
                        elseif entryData.activityType == LFG_ACTIVITY_TRIBUTE_CASUAL then
                            self:ShowTributeRank()
                        else
                            self:HideTributeRank()
                        end

                        ZO_ActivityFinderTemplate_Shared.AppendSetDataToControl(self.setTypesSectionControl, entryData)

                        local showMMR = entryData:IsSetEntryType() and entryData:HasMMR()
                        local mmrHeader = self.ratingSectionControl:GetNamedChild("Header")
                        local mmrList = self.ratingSectionControl:GetNamedChild("List")

                        if showMMR then
                            mmrHeader:SetText(GetString(SI_BATTLEGROUND_FINDER_MMR_HEADER))
                            mmrList:SetText(entryData:GetMMR())
                        end
                        mmrHeader:SetHidden(not showMMR)
                        mmrList:SetHidden(not showMMR)

                        return
                    end
                end
            end
        end

        if self.isShowingSingularPanel then
            SCENE_MANAGER:RemoveFragmentGroup(self.singularFragmentGroup)
            self.lockReasonTextFunction = nil
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
            self.isShowingSingularPanel = false
        end
    end
end

function ZO_ActivityFinderTemplate_Gamepad:OnCooldownsUpdate()
    if self.navigationMode == NAVIGATION_MODES.RANDOM_ENTRIES then
        local currentList = self:GetCurrentList()
        if currentList then
            local targetData = currentList:GetTargetData()
            if targetData then
                local entryData = targetData.data
                if not entryData.isRoleSelector then
                    self:RefreshRewards(entryData)
                end
            end
        end
    end
end

function ZO_ActivityFinderTemplate_Gamepad:OnTributeClubRankDataChanged()
    if self.fragment:IsShowing() then
        GAMEPAD_ACTIVITY_TRIBUTE_RANK:RefreshClubRank()
    end
end

function ZO_ActivityFinderTemplate_Gamepad:GetScene()
    return self.scene
end

function ZO_ActivityFinderTemplate_Gamepad:IsShowing()
    return self.scene:IsShowing()
end

----------------------------------------------
--ZO_Gamepad_ParametricList_Screen Overrides--
----------------------------------------------

function ZO_ActivityFinderTemplate_Gamepad:GetFooterNarration()
    if self:IsShowing() then
        local narrations = {}
        ZO_AppendNarration(narrations, GAMEPAD_GENERIC_FOOTER:GetNarrationText(GAMEPAD_ACTIVITY_QUEUE_DATA:GetFooterData()))

        local activityType = nil
        local currentList = self:GetCurrentList()
        if currentList then
            local targetData = currentList:GetTargetData()
            if targetData and targetData.data then
                activityType = targetData.data.activityType
            end
        end

        if activityType and (activityType == LFG_ACTIVITY_TRIBUTE_COMPETITIVE or activityType == LFG_ACTIVITY_TRIBUTE_CASUAL) then
            local clubRank = GetTributePlayerClubRank()
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_TRIBUTECLUBRANK", clubRank)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(clubRank + 1))

            local currentClubExperienceForRank, maxClubExperienceForRank = GetTributePlayerExperienceInCurrentClubRank()
            if maxClubExperienceForRank == 0 then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_TRIBUTE_CLUB_EXPERIENCE_LIMIT_REACHED)))
            else
                ZO_AppendNarration(narrations, ZO_GetProgressBarNarrationText(0, maxClubExperienceForRank, currentClubExperienceForRank))
            end
        end
        return narrations
    end
end