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

function ZO_ActivityFinderTemplate_Gamepad:Initialize(dataManager, categoryData)
    local control = CreateControlFromVirtual(dataManager:GetName() .. "_Gamepad", GuiRoot, "ZO_ActivityFinderTemplateTopLevel_Gamepad")
    ZO_ActivityFinderTemplate_Shared.Initialize(self, control, dataManager, categoryData)
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
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddCategory(categoryData)
end

function ZO_ActivityFinderTemplate_Gamepad:InitializeFilters()
    self.categoryHeaderData =
    {
        titleText = self.categoryData.name,
    }

    local modes = self.dataManager:GetFilterModeData()
    local randomEntryDatas = {}

    --Init potential randoms
    for _, activityType in ipairs(modes:GetActivityTypes()) do
        local randomInfo = modes:GetRandomInfo(activityType)
        if randomInfo and DoesLFGActivityHasAllOption(activityType) then
            local activityName = zo_strformat(SI_ACTIVITY_FINDER_RANDOM_TITLE_FORMAT, GetString("SI_LFGACTIVITY", activityType))
            local minGroupSize, maxGroupSize = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetGroupSizeRangeForActivityType(activityType)
            local entryData = ZO_GamepadEntryData:New(activityName, RANDOM_CATEGORY_ICON)
            entryData.data =
            {
                activityType = activityType,
                nameGamepad = activityName,
                description = randomInfo.description,
                descriptionTextureGamepad = randomInfo.gamepadBackground,
                isRandom = true,
                minGroupSize = minGroupSize,
                maxGroupSize = maxGroupSize,
            }
            entryData:SetIconTintOnSelection(true)
            table.insert(randomEntryDatas, entryData)
        end
    end

    self.randomEntryDatas = randomEntryDatas
    self.randomHeaderData =
    {
        titleText = modes:GetRandomFilterName(),
    }

    self:RefreshSpecificFilters()
end

function ZO_ActivityFinderTemplate_Gamepad:InitializeLists()
    --When we have "random" entries, we have the user drill down into a further subcategory
    --Where they can either select from a list of random activitiy types, or a list of specific activities
    if #self.randomEntryDatas > 0 then
        self.categoryList = self:GetMainList()
        self:AddRolesMenuEntry(self.categoryList)
        local filterModes = self.dataManager:GetFilterModeData()

        local randomEntryData = ZO_GamepadEntryData:New(filterModes:GetRandomFilterName(), RANDOM_CATEGORY_ICON)
        randomEntryData.data =
        {
            isRandom = true,
        }
        randomEntryData:SetIconTintOnSelection(true)
        self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", randomEntryData)

        local specificEntryData = ZO_GamepadEntryData:New(filterModes:GetSpecificFilterName(), self.categoryData.menuIcon)
        specificEntryData.data =
        {
            isRandom = false,
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
    end
    
    self.entryList:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.entryList:AddDataTemplateWithHeader("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    local entryListControl = self.entryList:GetControl()
    entryListControl:SetAnchor(TOPLEFT, self.headerControl, BOTTOMLEFT, 0, ZO_GAMEPAD_ROLES_BAR_ADDITIONAL_HEADER_SPACE)
end

function ZO_ActivityFinderTemplate_Gamepad:InitializeSingularPanelControls(rewardsTemplate)
    ZO_ActivityFinderTemplate_Shared.InitializeSingularPanelControls(self, rewardsTemplate)

    self.lockControl = self.singularSection:GetNamedChild("Lock")
    self.lockReasonLabel = self.lockControl:GetNamedChild("Reason")

    local function OnLockReasonLabelUpdate()
        if self.lockReasonTextFunction then
            self.lockReasonLabel:SetText(self.lockReasonTextFunction())
        end
    end
    self.lockReasonLabel:SetHandler("OnUpdate", OnLockReasonLabelUpdate)
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
                        local navigationMode = entryData.isRandom and NAVIGATION_MODES.RANDOM_ENTRIES or NAVIGATION_MODES.SPECIFIC_ENTRIES
                        self:SetNavigationMode(navigationMode)
                    elseif self.navigationMode == NAVIGATION_MODES.RANDOM_ENTRIES then
                        ZO_ACTIVITY_FINDER_ROOT_MANAGER:ToggleActivityTypeSelected(entryData.activityType)
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
                local lookingAtEntries = self.entryList:IsActive()
                local playerCanToggleQueue = not ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsLockedByNotLeader()
                return playerCanToggleQueue and anySelected and (lookingAtEntries or currentlySearching)
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

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    if self.headerData.tabBarEntries then
        ZO_GamepadGenericHeader_Activate(self.header)
    else
        ZO_GamepadGenericHeader_Deactivate(self.header)
    end
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:ClearSelections()
    self:RefreshView()
end

function ZO_ActivityFinderTemplate_Gamepad:RefreshView()
    if not self.scene:IsShowing() or self.navigationMode == NAVIGATION_MODES.CATEGORIES then
        return
    end

    self.entryList:Clear()
    self:AddRolesMenuEntry(self.entryList)
    local isSearching = IsCurrentlySearchingForGroup()

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RebuildSelections( {self.currentSpecificActivityType } )

    if self.navigationMode == NAVIGATION_MODES.RANDOM_ENTRIES then
        for _, entryData in ipairs(self.randomEntryDatas) do
            local lockReasonText = self:GetLockTextByActivity(entryData.data.activityType)
            if not lockReasonText then
                local reason = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLockReasonForActivityType(entryData.data.activityType)
                if reason then
                    lockReasonText = reason
                end
            end

            entryData.data.isLocked = lockReasonText ~= nil
            entryData.data.lockReasonText = lockReasonText

            entryData:SetEnabled(not entryData.data.isLocked and not isSearching)
            entryData:SetSelected(ZO_ACTIVITY_FINDER_ROOT_MANAGER:IsActivityTypeSelected(entryData.data.activityType))
            self.entryList:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
        end
    else
        local lockReasonTextOverride = self:GetGlobalLockText()
        local locationData = ZO_ACTIVITY_FINDER_ROOT_MANAGER:GetLocationsData(self.currentSpecificActivityType)
        for locationIndex, location in ipairs(locationData) do
            local specificEntryData = ZO_GamepadEntryData:New(location.nameGamepad, self.categoryData.menuIcon)
            specificEntryData.data = location
            specificEntryData.data.lockReasonTextOverride = lockReasonTextOverride
            specificEntryData:SetEnabled(not location.isLocked and not isSearching)
            specificEntryData:SetSelected(location.isSelected)
            self.entryList:AddEntry("ZO_GamepadItemSubEntryTemplate", specificEntryData)
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
    local navigationMode = self.hasCategories and NAVIGATION_MODES.CATEGORIES or NAVIGATION_MODES.SPECIFIC_ENTRIES
    self.isShowingSingularPanel = false
    self:SetNavigationMode(navigationMode)
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
        self.navigationMode = navigationMode
        self:SetCurrentList(targetList)
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
                        self.descriptionLabel:SetText(entryData.description)
                        ZO_ActivityFinderTemplate_Shared.SetGroupSizeRangeText(self.groupSizeRangeLabel, entryData, GROUP_SIZE_ICON_FORMAT)

                        self:RefreshRewards(entryData.isRandom, entryData.activityType)
                        if entryData.isLocked then
                            local lockReasonText = entryData.lockReasonTextOverride or entryData.lockReasonText
                            if type(lockReasonText) == "function" then
                                self.lockReasonTextFunction = lockReasonText
                            else
                                self.lockReasonLabel:SetText(lockReasonText)
                                self.lockReasonTextFunction = nil
                            end
                            self.lockControl:SetHidden(false)
                        else
                            self.lockControl:SetHidden(true)
                        end
                    
                        return
                    end
                end
            end
        end

        if self.isShowingSingularPanel then
            SCENE_MANAGER:RemoveFragmentGroup(self.singularFragmentGroup)
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
                    self:RefreshRewards(entryData.isRandom, entryData.activityType)
                end
            end
        end
    end
end

function ZO_ActivityFinderTemplate_Gamepad:GetScene()
    return self.scene
end