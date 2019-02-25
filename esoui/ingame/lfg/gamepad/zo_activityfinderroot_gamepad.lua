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

    local function RefreshCategories()
        self:RefreshCategories()
    end

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnLevelUpdate", RefreshCategories)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, RefreshCategories)
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
                            SCENE_MANAGER:Push(entryData.sceneName)
                        end
                    end
                end,
            enabled = function()
                local targetData = self:GetMainList():GetTargetData()
                return targetData and targetData.enabled
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
        local activityFinderObject = data.data.activityFinderObject
        local isLocked = activityFinderObject and (activityFinderObject:GetLevelLockInfo() or activityFinderObject:GetNumLocations() == 0)
        isLocked = isLocked or (data.data.isZoneStories and ZONE_STORIES_MANAGER:GetZoneData(ZONE_STORIES_MANAGER.GetDefaultZoneSelection()) == nil)
        enabled = enabled and not isLocked
        data.enabled = enabled
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    local function OnSelectedMenuEntry(_, selectedData)
        if GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:GetState() ~= SCENE_HIDDEN then
            if selectedData.data.isRoleSelector then
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
                GAMEPAD_GROUP_ROLES_BAR:Activate()
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
    local list = self:GetMainList()
    --Make sure we aren't interacting with the roles bar when we get there
    local targetData = list:GetTargetData()
    if targetData and targetData.data.isRoleSelector then
        local DONT_ANIMATE = false
        local ALLOW_EVEN_IF_DISABLED = true
        list:SetDefaultIndexSelected(DONT_ANIMATE, ALLOW_EVEN_IF_DISABLED)
        targetData = list:GetTargetData()
    else
        GAMEPAD_GROUP_ROLES_BAR:Deactivate()
    end
    list:RefreshVisible()
    self:RefreshTooltip(targetData.data)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

do
    local LOCK_TEXTURE = zo_iconFormat(ZO_GAMEPAD_LOCKED_ICON_32, "100%", "100%")
    local CHAMPION_ICON = zo_iconFormat(GetGamepadChampionPointsIcon(), "100%", "100%")

    function ActivityFinderRoot_Gamepad:RefreshTooltip(data)
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

            GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, data.name, data.tooltipDescription, lockedText)
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

function ZO_ActivityFinderRoot_Gamepad_OnInitialize(control)
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD = ActivityFinderRoot_Gamepad:New(control)
end