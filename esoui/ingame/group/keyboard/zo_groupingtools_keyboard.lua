----------------------------------
--Grouping Tools Keyboard
----------------------------------

local LFM_MODE = 1
local LFG_MODE = 2

local MODE_STRINGS =
{
    [LFM_MODE] = GetString(SI_GROUPING_TOOLS_PANEL_FIND_MEMBERS), 
    [LFG_MODE] = GetString(SI_GROUPING_TOOLS_PANEL_JOIN_A_GROUP),
}

local function GetLFGEntryString(name, levelMin, levelMax, veteranRankMin, veteranRankMax)
    local minString
    local maxString

    if levelMin < GetMaxLevel() then
        minString = tostring(levelMin)
    else
        minString = GetLevelOrVeteranRankString(levelMin, veteranRankMin, 28)
    end

    if veteranRankMax > 0 then
        local maxRank = GetMaxVeteranRank()
        local rank = veteranRankMax < maxRank and veteranRankMax or maxRank
        maxString = GetLevelOrVeteranRankString(levelMax, rank, 28)
    else
        maxString = tostring(levelMax)
    end

    if minString and maxString then
        if minString == maxString then
            return zo_strformat(SI_GROUPING_TOOLS_PANEL_LOCATION_FORMAT_NO_RANGE_STRING, maxString, name)
        else
            return zo_strformat(SI_GROUPING_TOOLS_PANEL_LOCATION_FORMAT_STRING, minString, maxString, name)
        end
    else
        return name
    end
end


local ZO_GroupingToolsManager_Keyboard = ZO_Object:Subclass()

function ZO_GroupingToolsManager_Keyboard:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

--Initialization
function ZO_GroupingToolsManager_Keyboard:Initialize(control)
    self.control = control
    self.notLeaderLabel = control:GetNamedChild("NotLeader")

    local leaderSectionControl = control:GetNamedChild("LeaderSection")
    self.leaderSectionControl = leaderSectionControl
    self.activityTypeMenuControl = leaderSectionControl:GetNamedChild("ActivityTypeMenu")
    self.locationMenuControl = leaderSectionControl:GetNamedChild("LocationMenu")

    self.modeLabel = leaderSectionControl:GetNamedChild("ModeLabel")
    self.activityTypeHeaderLabel = self.activityTypeMenuControl:GetNamedChild("Text")
    self.loactionHeaderLabel = self.locationMenuControl:GetNamedChild("Text")
    self.groupSizeLabel = leaderSectionControl:GetNamedChild("GroupSize")

    self:InitializeKeybindDescriptors()
    self:InitializeMenus()
    self:InitializeEvents()
    self:InitializeScene()

    self.activityTypeMenu:SelectFirstItem()
end

function ZO_GroupingToolsManager_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Invite to Group
        {
            name = GetString(SI_GROUP_WINDOW_INVITE_PLAYER),
            keybind = "UI_SHORTCUT_PRIMARY",
        
            callback = function()
                ZO_Dialogs_ShowDialog("GROUP_INVITE")
            end,

            visible = function()
                local playerIsLeader = IsUnitGroupLeader("player")
                return not self.playerIsGrouped or (playerIsLeader and GetGroupSize() < GROUP_SIZE_MAX)
            end
        },

        -- Start Search
        {
            name = GetString(SI_GROUPING_TOOLS_PANEL_START_SEARCH),
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function()
                local entry = self.locationsMenu:GetSelectedItemData()
                local data = entry.data

                if self.currentMode == LFG_MODE then
                    StartLFGSearch(data.activityType, data.activityIndex, data.groupType)
                else
                    ClearGroupFinderSearch()
                    AddGroupFinderSearchEntry(data.activityType, data.activityIndex)
                    StartGroupFinderSearch()
                end
            end,

            visible = function()
                local entry = self.locationsMenu:GetSelectedItemData()
                local data = entry and entry.data
                if not data then
                    return false
                end

                if data.isEmptyEntry then
                    return false
                end

                local groupFull = GetGroupSize() >= ZO_GROUP_TYPE_TO_SIZE[data.groupType]
                local playerIsLeader = IsUnitGroupLeader("player")

                return not IsCurrentlySearchingForGroup() and not groupFull and (not self.playerIsGrouped or playerIsLeader)
            end
        },

        -- Cancel Search
        {
            name = GetString(SI_GROUP_WINDOW_CANCEL_SEARCH),
            keybind = "UI_SHORTCUT_NEGATIVE",
        
            callback = function()
                ZO_Dialogs_ShowDialog("LFG_LEAVE_QUEUE_CONFIRMATION")
            end,

            visible = function()
                local playerIsLeader = IsUnitGroupLeader("player")
                return IsCurrentlySearchingForGroup() and (not self.playerIsGrouped or playerIsLeader)
            end
        },
    }
end

function ZO_GroupingToolsManager_Keyboard:InitializeMenus()
    --Activity Types
    local function OnActivityTypeChanged(comboBox, name, entry)
        self.previouslySelectedLocation = nil
        self:UpdateLocationMenu()
    end

    local activityTypeMenu = ZO_ComboBox:New(self.activityTypeMenuControl:GetNamedChild("Dropdown"))
    self.activityTypeMenu = activityTypeMenu
    activityTypeMenu:SetSortsItems(false)

    local function AddActivityTypeEntry(activityType)
        local text = GetString("SI_LFGACTIVITY", activityType)
        local entry = activityTypeMenu:CreateItemEntry(text, OnActivityTypeChanged)

        entry.data = {activityType = activityType}
        activityTypeMenu:AddItem(entry)
    end
    AddActivityTypeEntry(LFG_ACTIVITY_CYRODIIL)
    AddActivityTypeEntry(LFG_ACTIVITY_IMPERIAL_CITY)
    AddActivityTypeEntry(LFG_ACTIVITY_DUNGEON)
    AddActivityTypeEntry(LFG_ACTIVITY_MASTER_DUNGEON)

    --Activities
    self.locationsMenu = ZO_ComboBox:New(self.locationMenuControl:GetNamedChild("Dropdown"))
    self.locationsMenu:SetSortsItems(false)
end

function ZO_GroupingToolsManager_Keyboard:InitializeEvents()
    local function Update()
        self:Update()
    end

    local function OnGroupChanged()
        local isGrouped = IsUnitGrouped("player")
        local groupedStateChanged = self.playerIsGrouped ~= isGrouped

        if groupedStateChanged and isGrouped and GROUPING_TOOLS_SCENE:IsShowing() then
            MAIN_MENU_KEYBOARD:ShowScene("groupList")
        else
            Update()
        end
    end

    local function OnGroupMemberJoined(event, rawCharacterName)
        if GetRawUnitName("player") == rawCharacterName then
            --Set selected location to the one the LFG group just formed for.
            if IsInLFGGroup() then
                local activityType, activityIndex = GetCurrentLFGActivity()
                self.previouslySelectedLocation = {activityType = activityType, activityIndex = activityIndex}
            end
        end

        OnGroupChanged()
    end

    local control = self.control
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, Update)
    control:RegisterForEvent(EVENT_UNIT_CREATED, OnGroupChanged)
    control:RegisterForEvent(EVENT_UNIT_DESTROYED, Update)
    control:RegisterForEvent(EVENT_GROUP_UPDATE, OnGroupChanged)
    control:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
    control:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, Update)
    control:RegisterForEvent(EVENT_LEADER_UPDATE, Update)
    control:RegisterForEvent(EVENT_GROUPING_TOOLS_STATUS_UPDATE, Update)
end

function ZO_GroupingToolsManager_Keyboard:InitializeScene()
    local function OnStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self:Update()
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    GROUPING_TOOLS_SCENE = ZO_Scene:New("groupingToolsKeyboard", SCENE_MANAGER)
    GROUPING_TOOLS_SCENE:RegisterCallback("StateChange", OnStateChange)
end

--Updates
function ZO_GroupingToolsManager_Keyboard:Update()
    if not GROUPING_TOOLS_SCENE:IsShowing() then
        return
    end

    self.playerIsGrouped = IsUnitGrouped("player")

    self:UpdateMode()
    self:UpdateEnabledState()
    self:UpdateVisibileState()

    self:UpdateActivityTypeMenu()
    self:UpdateLocationMenu()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GroupingToolsManager_Keyboard:UpdateMode()
    local mode = self.playerIsGrouped and LFM_MODE or LFG_MODE
    self.currentMode = mode
    self.modeLabel:SetText(MODE_STRINGS[mode])
end

function ZO_GroupingToolsManager_Keyboard:UpdateEnabledState()
    local enabled = not IsCurrentlySearchingForGroup()

    self.activityTypeMenu:SetEnabled(enabled)
    self.locationsMenu:SetEnabled(enabled)

    local color = enabled and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT

    self.activityTypeMenu:SetSelectedColor(color:UnpackRGBA())
    self.locationsMenu:SetSelectedColor(color:UnpackRGBA())

    self.modeLabel:SetColor(color:UnpackRGBA())
    self.activityTypeHeaderLabel:SetColor(color:UnpackRGBA())
    self.loactionHeaderLabel:SetColor(color:UnpackRGBA())


    if PREFERRED_ROLES then
        PREFERRED_ROLES:DisableRoleButtons(not enabled)
    end
end

function ZO_GroupingToolsManager_Keyboard:UpdateVisibileState()
    local playerIsLeader = IsUnitGroupLeader("player")
    local visible = not self.playerIsGrouped or playerIsLeader

    self.notLeaderLabel:SetHidden(visible)
    self.leaderSectionControl:SetHidden(not visible)
end

function ZO_GroupingToolsManager_Keyboard:UpdateActivityTypeMenu()
    --Select activity type from current search
    if GetNumLFGRequests() > 0 then
        local activityType = GetLFGRequestInfo(1) -- assumes all requests are for the same activity

        local function IsActivityByEval(entry)
            return entry.data.activityType == activityType
        end
        self.activityTypeMenu:SetSelectedItemByEval(IsActivityByEval)
    end
end

function ZO_GroupingToolsManager_Keyboard:UpdateLocationData()
    self.lfgOptions = {}
    local activityType = self.activityTypeMenu:GetSelectedItemData().data.activityType
    local activityIsAvA = activityType == LFG_ACTIVITY_CYRODIIL or activityType == LFG_ACTIVITY_IMPERIAL_CITY
    if IsInAvAZone() then
        if IsInLFGGroup() or not activityIsAvA then
            return
        end
    elseif activityIsAvA then
        return
    end

    local playerLevel = GetUnitLevel("player")
    local playerVeteranRank = GetUnitVeteranRank("player")

    for i = 1, GetNumLFGOptions(activityType) do
        local name, levelMin, levelMax, veteranRankMin, veteranRankMax, groupType, passedReqs = GetLFGOption(activityType, i)
        if passedReqs then
            local passesLevelorRankCheck = false
            if playerVeteranRank == 0 then
                passesLevelorRankCheck = playerLevel >= levelMin and playerLevel <= levelMax
            else
                passesLevelorRankCheck = playerVeteranRank >= veteranRankMin and playerVeteranRank <= veteranRankMax
            end

            local requiredCollectible = GetRequiredLFGCollectibleId(activityType, i)
            local passesCollectibleRequirement = requiredCollectible == 0 or IsCollectibleUnlocked(requiredCollectible)
            local passesAVAZoneCheck = (not activityIsAvA) or IsInLFGAVAZone(activityType, i)

            if passesLevelorRankCheck and passesCollectibleRequirement and passesAVAZoneCheck then
                local data = {
                    activityType = activityType,
                    activityIndex = i,
                    name = name,
                    levelMin = levelMin,
                    levelMax = levelMax,
                    veteranRankMin = veteranRankMin,
                    veteranRankMax = veteranRankMax,
                    groupType = groupType,
                    displayText = GetLFGEntryString(name, levelMin, levelMax, veteranRankMin, veteranRankMax),
                }
                table.insert(self.lfgOptions, data)
            end
        end
    end

    table.sort(self.lfgOptions, LFGLevelSort)
end

function ZO_GroupingToolsManager_Keyboard:OnLocationChanged(comboBox, name, entry)
    local data = entry.data

    local text
    if data then
        local groupSize = ZO_GROUP_TYPE_TO_SIZE[data.groupType]
        text = zo_strformat(SI_LFG_LOCATION_GROUP_SIZE, groupSize)
    end
    self.groupSizeLabel:SetText(text)
    
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self.previouslySelectedLocation = data
end

function ZO_GroupingToolsManager_Keyboard:AddLocationEntry(data)
    local entry = self.locationsMenu:CreateItemEntry(data.displayText, function(...) self:OnLocationChanged(...) end)
    entry.data = data
    self.locationsMenu:AddItem(entry)
    return entry
end

function ZO_GroupingToolsManager_Keyboard:UpdateLocationMenu()
    self:UpdateLocationData()

    self.locationsMenu:ClearItems()

    local lfgMode = self.currentMode == LFG_MODE
    local activityType = self.activityTypeMenu:GetSelectedItemData().data.activityType
    local numLfgOptions = GetNumLFGOptions(activityType)

    if #self.lfgOptions > 0 then
        -- Addition of entry for the fake 'all' option to cause the c++ to queue for all entries in that activity type
        if lfgMode and DoesLFGActivityHasAllOption(activityType) then
            local allString = ""
            if activityType == LFG_ACTIVITY_DUNGEON then
                allString = GetString(SI_LFG_ANY_DUNGEON)
            elseif activityType == LFG_ACTIVITY_MASTER_DUNGEON then
                allString = GetString(SI_LFG_ANY_VETERAN_DUNGEON)
            end
            local allIndex = numLfgOptions + 1
            local entry = self:AddLocationEntry({activityType = activityType, activityIndex = allIndex, groupType = LFG_GROUP_TYPE_REGULAR, displayText = allString})
        end

        for i = 1, #self.lfgOptions do
            local data = self.lfgOptions[i]
            local entry = self:AddLocationEntry(data)
        end

        local numRequests = GetNumLFGRequests()
        if numRequests > 1 then --all is the only option that searches on multiple locations
            self.locationsMenu:SelectFirstItem()
        elseif numRequests > 0 then
            local activityType, activityIndex = GetLFGRequestInfo(1)
            local function IsLocationByEval(entry)
                local data = entry.data
                return data.activityType == activityType and data.activityIndex == activityIndex
            end
            self.locationsMenu:SetSelectedItemByEval(IsLocationByEval)
        else
            local previouslySelectedLocation = self.previouslySelectedLocation
            if previouslySelectedLocation then
                local function IsLocationByEval(entry)
                    local data = entry.data
                    return data.activityType == previouslySelectedLocation.activityType and data.activityIndex == previouslySelectedLocation.activityIndex
                end
                if not self.locationsMenu:SetSelectedItemByEval(IsLocationByEval) then
                    self.locationsMenu:SelectFirstItem()
                end
            else
                self.locationsMenu:SelectFirstItem()
            end
        end
    else
        self:AddLocationEntry({displayText = GetString(SI_GROUPING_TOOLS_PANEL_NONE_AVAILABLE), isEmptyEntry = true})
        self.locationsMenu:SelectFirstItem()
    end
end

--Global XML
function ZO_GroupingToolsKeyboard_OnInitialized(control)
    GROUPING_TOOLS_KEYBOARD = ZO_GroupingToolsManager_Keyboard:New(control)
end
