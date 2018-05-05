--Layout consts, defining the widths of the list's columns as provided by design--
ZO_GAMEPAD_LEADERBOARD_LIST_RANK_WIDTH = 116 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_LEADERBOARD_LIST_USER_FACING_NAME_WIDTH = 340 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_LEADERBOARD_LIST_HOUSE_NAME_WIDTH = 580 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_LEADERBOARD_LIST_CHARACTER_NAME_WIDTH = 340 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_LEADERBOARD_LIST_CLASS_WIDTH = 120 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_LEADERBOARD_LIST_ALLIANCE_WIDTH = 120 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_LEADERBOARD_LIST_POINTS_WIDTH = 170 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X

local LEADERBOARD_LIST_TEMPLATE = "ZO_LeaderboardsPlayerRow_Gamepad"

local PLAYER_NAME_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_LEADERBOARD_COLORS, LEADERBOARD_COLORS_PLAYER_NAME))
local NAME_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_LEADERBOARD_COLORS, LEADERBOARD_COLORS_NAME))

local LEADERBOARD_LIST_ENTRY_SORT_KEYS =
{
    ["rank"] = { isNumeric = true },
    ["displayName"] = { },
    ["house"] = { tiebreaker = "rank" },
    ["characterName"]  = { },
    ["class"] = { tiebreaker = "rank" },
    ["alliance"] = { tiebreaker = "rank", isNumeric = true },
    ["points"] = { tiebreaker = "rank", isNumeric = true},
}

local LEADERBOARD_TYPE_HIDDEN_COLUMNS =
{
    [LEADERBOARD_TYPE_OVERALL] =
    {
        ["house"] = true,
    },
    [LEADERBOARD_TYPE_CLASS] =
    {
        ["house"] = true,
    },
    [LEADERBOARD_TYPE_ALLIANCE] =
    {
        ["house"] = true,
    },
    [LEADERBOARD_TYPE_HOUSE] = 
    {
        ["characterName"] = true,
        ["class"] = true,
        ["alliance"] = true,
    },
    [LEADERBOARD_TYPE_BATTLEGROUND] = 
    {
        ["house"] = true,
        ["class"] = true,
        ["alliance"] = true,
    },
}

local LeaderboardList_Gamepad = ZO_Object.MultiSubclass(ZO_GamepadInteractiveSortFilterList, ZO_SocialOptionsDialogGamepad)

function LeaderboardList_Gamepad:New(...)
    return ZO_GamepadInteractiveSortFilterList.New(self, ...)
end

function LeaderboardList_Gamepad:Initialize(control)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)
    ZO_SocialOptionsDialogGamepad.Initialize(self)
    self:SetEmptyText(GetString(SI_LEADERBOARDS_NO_RANKINGS_FOUND))
    ZO_ScrollList_AddDataType(self.list, ZO_LEADERBOARD_PLAYER_DATA, LEADERBOARD_LIST_TEMPLATE, ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT, function(control, data) self:SetupLeaderboardPlayerEntry(control, data) end)
    self:SetMasterList(LEADERBOARD_LIST_MANAGER:GetMasterList())
    self:SetupSort(LEADERBOARD_LIST_ENTRY_SORT_KEYS, "rank", ZO_SORT_ORDER_UP)
end

function LeaderboardList_Gamepad:InitializeHeader()
    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_TYPE_OVERALL)
    local contentHeaderData = 
    {
        titleText = "",
        data1HeaderText = "",
        data2HeaderText = zo_strformat(SI_GAMEPAD_LEADERBOARDS_CURRENT_RANK_LABEL, rankingTypeText),
        data3HeaderText = "",
    }
    ZO_GamepadInteractiveSortFilterList.InitializeHeader(self, contentHeaderData)
end

function LeaderboardList_Gamepad:InitializeKeybinds()
    local keybindDescriptor = {}
    self:AddSocialOptionsKeybind(keybindDescriptor)
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(keybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())
    self:SetKeybindStripDescriptor(keybindDescriptor)
    ZO_GamepadInteractiveSortFilterList.InitializeKeybinds(self)
end

function LeaderboardList_Gamepad:InitializeSearchFilter()
    ZO_GamepadInteractiveSortFilterList.InitializeSearchFilter(self)

    ZO_EditDefaultText_Initialize(self.searchEdit, ZO_GetPlatformAccountLabel())
end

function LeaderboardList_Gamepad:RefreshLeaderboardType(leaderboardType)
    local hiddenColumns = LEADERBOARD_TYPE_HIDDEN_COLUMNS[leaderboardType]
    if hiddenColumns then
        local HIDDEN = true
        self.sortHeaderGroup:SetHeadersHiddenFromKeyList(hiddenColumns, HIDDEN)

        if hiddenColumns[self.currentSortKey] then
            -- Table was sorted by a column that is gone now: fallback to rank
            self.currentSortKey = "rank"
            self.currentSortOrder = ZO_SORT_ORDER_UP
            self.sortHeaderGroup:SelectHeaderByKey(self.currentSortKey, false, true)
        end
    end
end

function LeaderboardList_Gamepad:GetBackKeybindCallback()
    return function()
        self:Deactivate()
        GAMEPAD_LEADERBOARDS:ActivateCategories()
    end
end

function LeaderboardList_Gamepad:FilterScrollList()
    local playerName = GetUnitName("player")
    local filteredClass = self.filterDropdown:GetSelectedItemData().classId
    local searchTerm = self:GetCurrentSearch()

    local function SearchCallback(data)
        return searchTerm == "" or self:IsMatch(searchTerm, data)
    end
    
    local function PreAddCallback(data)
        data.recolorName = data.characterName == playerName
    end

    LEADERBOARD_LIST_MANAGER:FilterScrollList(self.list, filteredClass, PreAddCallback, SearchCallback)
end

function LeaderboardList_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_GamepadInteractiveSortFilterList.OnSelectionChanged(self, oldData, newData)
    self:SetupOptions(newData)
end

function LeaderboardList_Gamepad:SetupLeaderboardPlayerEntry(control, data)
    ZO_LeaderboardsManager_Shared.SetupLeaderboardPlayerEntry(GAMEPAD_LEADERBOARDS, control, data)
    
    local leaderboardData = GAMEPAD_LEADERBOARDS:GetSelectedLeaderboardData()
    control.characterNameLabel:SetHidden(leaderboardData.leaderboardRankType == LEADERBOARD_TYPE_HOUSE)
    control.characterNameLabel:SetText(ZO_FormatUserFacingCharacterName(data.characterName))

    local nameColor = data.recolorName and PLAYER_NAME_COLOR or NAME_COLOR

    self:ColorName(control, data, nameColor)

    local r, g, b, a = ZO_SELECTED_TEXT:UnpackRGBA()
    control.rankLabel:SetColor(r, g, b, a)
    control.houseLabel:SetColor(r, g, b, a)
    control.characterNameLabel:SetColor(r, g, b, a)
    control.classIcon:SetColor(r, g, b, a)
    control.allianceIcon:SetColor(r, g, b, a)
    control.pointsLabel:SetColor(r, g, b, a)
end

function LeaderboardList_Gamepad:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildAddFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddFriendOption)
end

function LeaderboardList_Gamepad:ColorName(control, data, textColor)
    local textColor = textColor or GAMEPAD_LEADERBOARDS:GetRowColors(self, data)
    local nameControl = GetControl(control, "Name")
    nameControl:SetColor(textColor:UnpackRGBA())
end

function LeaderboardList_Gamepad:RepopulateFilterDropdown()
    ZO_Leaderboards_PopulateDropdownFilter(self.filterDropdown, nil, LEADERBOARD_LIST_MANAGER.leaderboardRankType)
end

function ZO_LeaderboardList_Gamepad_OnInitialized(control)
    GAMEPAD_LEADERBOARD_LIST = LeaderboardList_Gamepad:New(control)
end