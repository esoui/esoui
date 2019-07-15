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
    local control = CreateControlFromVirtual(dataManager:GetName() .. "_Gamepad", GuiRoot, "ZO_ActivityFinderTemplateTopLevel_Gamepad")
    ZO_ActivityFinderTemplate_Shared.Initialize(self, control, dataManager, categoryData, categoryPriority)
    local ACTIVATE_LIST_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, ACTIVATE_LIST_ON_SHOW, self.scene)
    self:SetListsUseTriggerKeybinds(true)
    self:InitializeLists()
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
        self:AddRolesMenuEntry(self.categoryList)
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

        --Back
        {
            name = GetString(SI_GAMEPAD_BACK_OPTION),

            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                if self.navigationMode == NAVIGATION_MODES.CATEGORIES or not self.hasCategories then
                    SCENE_MANAGER:HideCurrentScene()
                else
                    self:SetNavigationMode(NAVIGATION_MODES.CATEGORIES)
                end
            end,
        },

        --Toggle Queue
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
                end
            end,

            visible = function()
                local anySelected = ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsAnyLocationSelected()
                local currentlySearching = IsCurrentlySearchingForGroup()
                local playerCanToggleQueue = not ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsLockedByNotLeader()
                return playerCanToggleQueue and (anySelected or currentlySearching)
            end,
        }
    }
end

function ZO_ActivityFinderTemplate_Gamepad:FilterByActivity(activityType)
    self.currentSpecificActivityType = activityType
    self:RefreshView()
end

function ZO_ActivityFinderTemplate_Gamepad:PerformUpdate()
    --Must be overriden
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
    self:AddRolesMenuEntry(self.entryList)
    local isSearching = IsCurrentlySearchingForGroup()
    local lockReasonTextOverride = self:GetGlobalLockText()
    local modes = self.dataManager:GetFilterModeData()

    local function AddLocationEntry(location)
        local entryData = ZO_GamepadEntryData:New(location:GetNameGamepad(), self.categoryData.menuIcon)
        entryData.data = location
        entryData.data:SetLockReasonTextOverride(lockReasonTextOverride)
        entryData:SetEnabled(not location:IsLocked() and not isSearching)
        entryData:SetSelected(location:IsSelected())
        self.entryList:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
    end

    if self.navigationMode == NAVIGATION_MODES.RANDOM_ENTRIES then
        local modeActivityTypes = modes:GetActivityTypes()
        ZO_ACTIVITY_FINDER_ROOT_MANAGER:RebuildSelections(modeActivityTypes)
        for _, activityType in ipairs(modeActivityTypes) do
            local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(activityType)
            for _, location in ipairs(locationData) do
                if modes:IsEntryTypeVisible(location:GetEntryType()) and location:HasRewardData() and location:DoesPlayerMeetLevelRequirements() then
                    AddLocationEntry(location)
                end
            end
        end
    else
        ZO_ACTIVITY_FINDER_ROOT_MANAGER:RebuildSelections( {self.currentSpecificActivityType } )
        local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(self.currentSpecificActivityType)

        for _, location in ipairs(locationData) do
            if modes:IsEntryTypeVisible(location:GetEntryType()) and not location:HasRewardData() then
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
                callback = function() self:FilterByActivity(activityData.activityType) end,
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
    end

    self.specificHeaderData = specificHeaderData
end

function ZO_ActivityFinderTemplate_Gamepad:RefreshFilters()
    self:RefreshSpecificFilters()
    if self.navigationMode == NAVIGATION_MODES.SPECIFIC_ENTRIES then
        self:RefreshHeaderAndView(self.specificHeaderData)
    end
end

function ZO_ActivityFinderTemplate_Gamepad:OnActivityFinderStatusUpdate()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:RefreshView()
end

function ZO_ActivityFinderTemplate_Gamepad:OnShowing()
    local navigationMode = self.hasCategories and NAVIGATION_MODES.CATEGORIES or self.defaultNavigationMode
    self.isShowingSingularPanel = false
    self:SetNavigationMode(navigationMode)
    --If we have no categories we go straight into the default view, which means navigation mode never technically changes, so the header never gets reactivated
    if not self.hasCategories then
        self:RefreshHeaderAndView(self.specificHeaderData)
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
                        
                        ZO_ActivityFinderTemplate_Shared.AppendSetDataToControl(self.setTypesSectionControl, entryData)
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

function ZO_ActivityFinderTemplate_Gamepad:GetScene()
    return self.scene
end

function ZO_ActivityFinderTemplate_Gamepad:IsShowing()
    return self.scene:IsShowing()
end