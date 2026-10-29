local CATEGORY_LIST_TEMPLATE = "ZO_GamepadMenuEntryTemplate"
local CATEGORY_LIST_DROPDOWN_TEMPLATE = "ZO_Leaderboards_Gamepad_DropdownMenuEntry"
local HEADER_TEMPLATE = "ZO_GamepadMenuEntryHeaderTemplate"

local ZO_LeaderboardsManager_Gamepad = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Screen, ZO_LeaderboardsManager_Shared)

function ZO_LeaderboardsManager_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_LeaderboardsManager_Gamepad:Initialize(control)
    local ACTIVATE_ON_SHOW = true
    ZO_LeaderboardsManager_Shared.Initialize(self, control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_LEADERBOARDS_SCENE)

    self:InitializeCategoryList(control)
end

function ZO_LeaderboardsManager_Gamepad:InitializeCategoryList(control)
    self.categoryListData = {}
    self.categoryList = self:GetMainList()
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.categoryList)
end

function ZO_LeaderboardsManager_Gamepad:SetupList(list)
    list:AddDataTemplate(CATEGORY_LIST_TEMPLATE, ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader(CATEGORY_LIST_TEMPLATE, ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, HEADER_TEMPLATE)

    local function OnDropdownDeactivated()
        if self:IsShowing() then
            self:ActivateCategories()
        end
    end

    local function SetupDropdownEntry(control, data, selected, selectedDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)

        local dropdown = control.dropdown
        data.dropdown = dropdown

        dropdown:SetSortsItems(true)
        dropdown:SetDeactivatedCallback(OnDropdownDeactivated)

        data:addDropdownEntriesCallback(dropdown)
    end
    
    list:AddDataTemplate(CATEGORY_LIST_DROPDOWN_TEMPLATE, SetupDropdownEntry, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader(CATEGORY_LIST_DROPDOWN_TEMPLATE, SetupDropdownEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, HEADER_TEMPLATE)
end

function ZO_LeaderboardsManager_Gamepad:OnTargetChanged(list, targetLeaderboard)
    local listWasActivated
    if self.leaderboardObject then
        listWasActivated = GAMEPAD_LEADERBOARD_LIST:IsActivated()
        self:DeactivateLeaderboard()
    end

    self:DeactivateCategoryDropdown()

    self:OnLeaderboardSelected(targetLeaderboard)
    self:ActivateLeaderboard()

    if listWasActivated then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self:ActivateCurrentList()
    end
end

function ZO_LeaderboardsManager_Gamepad:GetSelectedEntry()
    return self.categoryList:GetTargetData()
end

function ZO_LeaderboardsManager_Gamepad:InitializeKeybindStripDescriptors()
    -- Main keybind strip

    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                local selectedEntry = self.categoryList:GetTargetData()
                if selectedEntry and selectedEntry.addDropdownEntriesCallback then
                    return true
                end
                local IGNORE_FILTERS = true
                return GAMEPAD_LEADERBOARD_LIST:HasEntries(IGNORE_FILTERS)
            end,

            callback = function()
                local selectedEntry = self.categoryList:GetTargetData()
                self:ActivateLeaderboardList()
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_LeaderboardsManager_Gamepad:InitializeScenes()
    ZO_LeaderboardsManager_Shared.InitializeScenes(self, "gamepad_leaderboards")
    GAMEPAD_LEADERBOARDS_SCENE = self:GetScene()
end

function ZO_LeaderboardsManager_Gamepad:RefreshLeaderboardType(leaderboardType)
    GAMEPAD_LEADERBOARD_LIST:RefreshLeaderboardType(leaderboardType)
end

function ZO_LeaderboardsManager_Gamepad:PerformUpdate()
    self.dirty = false
end

function ZO_LeaderboardsManager_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self:UpdateCategories()
    self:TryAddLeaderboardObjectKeybind()
end

function ZO_LeaderboardsManager_Gamepad:OnShow()
    TriggerTutorial(TUTORIAL_TRIGGER_LEADERBOARDS_OPENED)
end

function ZO_LeaderboardsManager_Gamepad:OnHiding()
    self:DeactivateLeaderboard()
    self:DeactivateCategoryDropdown()
end

function ZO_LeaderboardsManager_Gamepad:InitializeHeader()
    self.headerData = {
        titleText = GetString(SI_JOURNAL_MENU_LEADERBOARDS),
    }
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_LeaderboardsManager_Gamepad:OnDeferredInitialize()
    self:InitializeHeader()

    for _, systemObject in ipairs(self.leaderboardSystemObjects) do
        if systemObject.PerformDeferredInitialization then
            systemObject:PerformDeferredInitialization()
        end
    end
end

function ZO_LeaderboardsManager_Gamepad:AddCategory(name, normalIcon, pressedIcon, mouseoverIcon)
    -- Gamepad list doesn't need to explicitly add categories, so let's just return the category name
    return name
end

function ZO_LeaderboardsManager_Gamepad:AddEntry(leaderboardObject, name, titleName, parent, subType, countFunction, maxRankFunction, infoFunction, pointsFormatFunction, pointsHeaderString, consoleIdRequestParamsFunction, iconPath, leaderboardRankType, playerInfoUpdateFunction)
    local entryData = ZO_GamepadEntryData:New(name)
    entryData.group = parent
    entryData.leaderboardObject = leaderboardObject
    entryData.name = name
    entryData.titleName = titleName or name
    entryData.subType = subType
    entryData.countFunction = countFunction
    entryData.maxRankFunction = maxRankFunction
    entryData.infoFunction = infoFunction
    entryData.pointsFormatFunction = pointsFormatFunction
    entryData.pointsHeaderString = pointsHeaderString
    entryData.consoleIdRequestParamsFunction = consoleIdRequestParamsFunction
    entryData.leaderboardRankType = leaderboardRankType
    entryData.playerInfoUpdateFunction = playerInfoUpdateFunction
    entryData.narrationText = function(listEntryData, listEntryControl)
        local narrations = {}
        -- Generate the standard parametric list entry narration
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(listEntryData, listEntryControl))
        --Generate the narration for the leaderboard being empty
        ZO_AppendNarration(narrations, GAMEPAD_LEADERBOARD_LIST:GetEmptyRowNarration())
        return narrations
    end

    entryData:AddIcon(iconPath, iconPath)
    entryData:SetIconTintOnSelection(true)
    entryData:SetIconDisabledTintOnSelection(true)

    entryData.index = #self.categoryListData + 1

    self.categoryListData[#self.categoryListData + 1] = entryData
    
    return entryData
end

function ZO_LeaderboardsManager_Gamepad:SetEntryDropdownInfo(entryData, addDropdownEntriesCallback)
    entryData.addDropdownEntriesCallback = addDropdownEntriesCallback
end

local CATEGORY_SORT_KEYS =
{
    group = { tiebreaker = "index" },
    index = { tiebreaker = "titleName", isNumeric = true },
    titleName = { },
}

local function SortFunc(item1, item2)
    return ZO_TableOrderingFunction(item1, item2, "group", CATEGORY_SORT_KEYS, ZO_SORT_ORDER_UP)
end

function ZO_LeaderboardsManager_Gamepad:UpdateCategories()
    QueryCampaignSelectionData()

    self.categoryListData = {}

    for _, systemObject in ipairs(self.leaderboardSystemObjects) do
        if systemObject.AddCategoriesToParentSystem then
            systemObject:AddCategoriesToParentSystem()
        end
    end

    self:RefreshCategoryList()
end

function ZO_LeaderboardsManager_Gamepad:SetSelectedLeaderboardObject(leaderboardObject, subType)
    self.leaderboardObject = leaderboardObject

    if self.leaderboardObject then
        self.leaderboardObject:OnSubtypeSelected(subType)
    end
end

function ZO_LeaderboardsManager_Gamepad:SetActiveLeaderboardTitle(titleName)
    GAMEPAD_LEADERBOARD_LIST:SetTitle(titleName)
end

function ZO_LeaderboardsManager_Gamepad:SetActiveCampaign(campaignName, icon)
    self.campaignName = campaignName
    self.campaignIcon = icon
    self:Update()
end

function ZO_LeaderboardsManager_Gamepad:RefreshData()
    LEADERBOARD_LIST_MANAGER:BuildMasterList()
    GAMEPAD_LEADERBOARD_LIST:RefreshData()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_LeaderboardsManager_Gamepad:TryAddLeaderboardObjectKeybind()
    if self.leaderboardObject then
        local keybind = self.leaderboardObject:GetKeybind()
        if self.currentLeaderboardObjectKeybind ~= keybind then
            self:RemoveLeaderboardObjectKeybind()
            self.currentLeaderboardObjectKeybind = keybind
            if keybind then
                KEYBIND_STRIP:AddKeybindButton(keybind)
            end
        end
    end
end

function ZO_LeaderboardsManager_Gamepad:RemoveLeaderboardObjectKeybind()
    if self.currentLeaderboardObjectKeybind then
        KEYBIND_STRIP:RemoveKeybindButton(self.currentLeaderboardObjectKeybind)
        self.currentLeaderboardObjectKeybind = nil
    end
end

function ZO_LeaderboardsManager_Gamepad:ActivateLeaderboard()
    self.leaderboardObject:OnSelected()
    self:TryAddLeaderboardObjectKeybind()
end

function ZO_LeaderboardsManager_Gamepad:DeactivateLeaderboard()
    self:RemoveLeaderboardObjectKeybind()
    if self.leaderboardObject then
        self.leaderboardObject:OnUnselected()
        GAMEPAD_LEADERBOARD_LIST:Deactivate()
    end
end

function ZO_LeaderboardsManager_Gamepad:ActivateCategories()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self:TryAddLeaderboardObjectKeybind()
    self:ActivateCurrentList()
end

function ZO_LeaderboardsManager_Gamepad:ActivateLeaderboardList()
    self:DeactivateCurrentList()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self:RemoveLeaderboardObjectKeybind()
    GAMEPAD_LEADERBOARD_LIST:Activate()
end

function ZO_LeaderboardsManager_Gamepad:ActivateCategoryDropdown(entryData)
    self:DeactivateCurrentList()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self:RemoveLeaderboardObjectKeybind()
    entryData.dropdown:Activate()
    self.activeDropdown = entryData.dropdown
end

function ZO_LeaderboardsManager_Gamepad:DeactivateCategoryDropdown()
    if self.activeDropdown then
        self.activeDropdown:Deactivate()
    end
end

function ZO_LeaderboardsManager_Gamepad:SelectNode(leaderboardNode)
    self.categoryList:SetSelectedIndex(leaderboardNode.index)
end

function ZO_LeaderboardsManager_Gamepad:GetSelectedLeaderboardData()
    return self.categoryList:GetTargetData()
end

function ZO_LeaderboardsManager_Gamepad:RefreshCategoryList()
    self.categoryList:Clear()

    local lastGroup = nil
    for i, data in ipairs(self.categoryListData) do
        local template = data.addDropdownEntriesCallback and CATEGORY_LIST_DROPDOWN_TEMPLATE or CATEGORY_LIST_TEMPLATE
        if data.group and data.group ~= lastGroup then
            data:SetHeader(data.group)
            self.categoryList:AddEntryWithHeader(template, data)
        else
            self.categoryList:AddEntry(template, data)
        end

        lastGroup = data.group
    end
    
    self.categoryList:Commit()
end

function ZO_LeaderboardsManager_Gamepad:SetKeybindButtonGroup(descriptor)
    if self.currentKeybindButtonGroup then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindButtonGroup)
    end

    if descriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(descriptor)
    end

    self.currentKeybindButtonGroup = descriptor
end

function ZO_LeaderboardsManager_Gamepad:SetLoadingSpinnerVisibility(show)
    GAMEPAD_LEADERBOARD_LIST:SetLoadingSpinnerVisibility(show)
end

function ZO_LeaderboardsManager_Gamepad:RefreshPointsHeader()
    GAMEPAD_LEADERBOARD_LIST:SetHeaderNameForKey("points", self.headerPointsText)
end

--Global XML Handlers
-----------------------

function ZO_Leaderboards_Gamepad_OnInitialized(self)
    GAMEPAD_LEADERBOARDS = ZO_LeaderboardsManager_Gamepad:New(self)
end