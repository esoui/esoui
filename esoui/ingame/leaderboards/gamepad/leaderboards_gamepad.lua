local CATEGORY_LIST_TEMPLATE = "ZO_GamepadMenuEntryTemplate"
local HEADER_TEMPLATE = "ZO_GamepadMenuEntryHeaderTemplate"

local ZO_LeaderboardsManager_Gamepad = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Screen, ZO_LeaderboardsManager_Shared)

function ZO_LeaderboardsManager_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_LeaderboardsManager_Gamepad:Initialize(control)
    local ACTIVATE_ON_SHOW = true
    ZO_LeaderboardsManager_Shared.Initialize(self, control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_LEADERBOARDS_SCENE)

    self.pointsHeaderLabel = GAMEPAD_LEADERBOARD_LIST:GetHeaderControl("PointsName")

    self.leaderboardSystemObjects = {}
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
end

function ZO_LeaderboardsManager_Gamepad:OnTargetChanged(list, targetLeaderboard)
    local listWasActivated
    if self.leaderboardObject then
        listWasActivated = GAMEPAD_LEADERBOARD_LIST:IsActivated()
        self:DeactivateLeaderboard()
    end

    self:OnLeaderboardSelected(targetLeaderboard)
    self:ActivateLeaderboard()

    if listWasActivated then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self:ActivateCurrentList()
    end
end

function ZO_LeaderboardsManager_Gamepad:GetSelectedEntry()
    return ZO_ScrollList_GetSelectedData(self.list)
end

function ZO_LeaderboardsManager_Gamepad:InitializeKeybindStripDescriptors()
    -- Main keybind strip

    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            visible = function()
                local IGNORE_FILTERS = true
                return GAMEPAD_LEADERBOARD_LIST:HasEntries(IGNORE_FILTERS)
            end,

            callback = function()
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
    if self.campaignName then
        self.categoryHeaderData.messageText = zo_strformat(SI_GAMEPAD_CAMPAIGN_LEADERBOARDS_ACTIVE_CAMPAIGN, self.campaignIcon, self.campaignName)
    else
        self.categoryHeaderData.messageText = ""
    end
    ZO_GamepadGenericHeader_RefreshData(self.header, self.categoryHeaderData)
end

function ZO_LeaderboardsManager_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self:UpdateCategories()
    self:RefreshCategoryList()
    self:TryAddLeaderboardObjectKeybind()
end

function ZO_LeaderboardsManager_Gamepad:OnShow()
    TriggerTutorial(TUTORIAL_TRIGGER_LEADERBOARDS_OPENED)
end

function ZO_LeaderboardsManager_Gamepad:OnHiding()
    self:DeactivateLeaderboard()
end

function ZO_LeaderboardsManager_Gamepad:InitializeHeader()
    self.categoryHeaderData = {
        titleText = GetString(SI_JOURNAL_MENU_LEADERBOARDS),
    }
    ZO_GamepadGenericHeader_RefreshData(self.header, self.categoryHeaderData)
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

    entryData:AddIcon(iconPath, iconPath)
    entryData:SetIconTintOnSelection(true)
    entryData:SetIconDisabledTintOnSelection(true)

    entryData.index = #self.categoryListData + 1

    self.categoryListData[#self.categoryListData + 1] = entryData
    
    return entryData
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

function ZO_LeaderboardsManager_Gamepad:RegisterLeaderboardSystemObject(systemObject)
    table.insert(self.leaderboardSystemObjects, systemObject)
end

function ZO_LeaderboardsManager_Gamepad:UpdateCategories()
    self.categoryListData = {}

    for _, systemObject in ipairs(self.leaderboardSystemObjects) do
        if systemObject.AddCategoriesToParentSystem then
            systemObject:AddCategoriesToParentSystem()
        end
    end

    if GAMEPAD_LEADERBOARDS_SCENE:IsShowing() then
        self:RefreshCategoryList()
    end
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
        if data.group and data.group ~= lastGroup then
            data:SetHeader(data.group)
            self.categoryList:AddEntryWithHeader(CATEGORY_LIST_TEMPLATE, data)
        else
            self.categoryList:AddEntry(CATEGORY_LIST_TEMPLATE, data)
        end

        lastGroup = data.group
    end
    
    self.categoryList:Commit()
end

function ZO_LeaderboardsManager_Gamepad:RepopulateFilterDropdown()
    local function OnFilterChanged(comboBox, entryText, entry)
        local leaderboard = self:GetSelectedLeaderboardData()
        if not leaderboard.leaderboardObject:HandleFilterDropdownChanged() then
            GAMEPAD_LEADERBOARD_LIST:RefreshFilters()
        end
    end

    GAMEPAD_LEADERBOARD_LIST:RepopulateFilterDropdown(OnFilterChanged)
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

function ZO_LeaderboardsManager_Gamepad:GetSelectedClassFilter()
    return GAMEPAD_LEADERBOARD_LIST:GetSelectedClassFilter()
end

function ZO_LeaderboardsManager_Gamepad:SetLoadingSpinnerVisibility(show)
    GAMEPAD_LEADERBOARD_LIST:SetLoadingSpinnerVisibility(show)
end

--Global XML Handlers
-----------------------

function ZO_Leaderboards_Gamepad_OnInitialized(self)
    GAMEPAD_LEADERBOARDS = ZO_LeaderboardsManager_Gamepad:New(self)
end