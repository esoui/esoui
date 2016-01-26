----------------------------------
--Group Menu Gamepad
----------------------------------

local ZO_GroupMenu_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

local MENU_ENTRY_TYPE_ROLES = 1
local MENU_ENTRY_TYPE_CURRENT_GROUP = 2
local MENU_ENTRY_TYPE_FIND_GROUP = 3
local MENU_ENTRY_TYPE_DUNGEON_DIFFICULTY = 4
local MENU_ENTRY_TYPE_INVITE_PLAYER = 5
local MENU_ENTRY_TYPE_INVITE_FRIEND = 6
local MENU_ENTRY_TYPE_LEAVE_GROUP = 7
local MENU_ENTRY_TYPE_DISBAND_GROUP = 8

local CATEGORY_HEADER_TEMPLATE = "ZO_GamepadMenuEntryHeaderTemplate"
local MENU_ENTRY_TEMPLATE = "ZO_GamepadMenuEntryTemplate"

local TOOLTIP_INFO_TEXT = 
{
    [MENU_ENTRY_TYPE_DUNGEON_DIFFICULTY] = 
    {
        title = GetString(SI_GAMEPAD_GROUP_DUNGEON_DIFFICULTY),
        text = 
        {
            -- Only one error will display. This table is prioritized from most important to least.
            errors =
            {
                {
                    text = GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_FAILED_REQUIREMENT),
                    canDisplay = function()
                        return GetUnitVeteranRank("player") == 0
                    end,
                },
                {
                    text = GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_LEADER_MUST_CHANGE),
                    canDisplay = function()
                        local isPlayerVeteran = GetUnitVeteranRank("player") > 0
                        return isPlayerVeteran and IsUnitGrouped("player") and not IsUnitGroupLeader("player")
                    end,
                },
                {
                    text = GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_IN_DUNGEON),
                    canDisplay = function() 
                        local isPlayerVeteran = GetUnitVeteranRank("player") > 0
                        local isLeader = IsUnitGrouped("player") and IsUnitGroupLeader("player")
                        local isAnyGroupMemberInDungeon = IsAnyGroupMemberInDungeon()
                        return isPlayerVeteran and isLeader and isAnyGroupMemberInDungeon
                    end,
                },
                {
                    text = GetString(SI_DUNGEON_DIFFICULTY_VETERAN_TOOLTIP_IN_LFG_GROUP),
                    canDisplay = function()
                        return IsInLFGGroup()
                    end,
                },
            },
            bodyText = GetString(SI_DUNGEON_DIFFICULTY_HELP_TOOLTIP),
        }
    },
}

function ZO_GroupMenu_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

--Initialization
function ZO_GroupMenu_Gamepad:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    self:InitializeScene()
    ZO_GamepadGenericHeader_SetDataLayout(self.header, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)
end

function ZO_GroupMenu_Gamepad:InitializeScene()
    local function OnStateChanged(oldState, newState)
        if(newState == SCENE_SHOWING) then
            self:PerformDeferredInitialization()

            self:UpdateMenuList()
            self:SelectMenuList()

            ZO_GamepadGenericHeader_Activate(self.header)
            self:RefreshFooter()

            SCENE_MANAGER:AddFragment(GAMEPAD_GROUP_ROLES_FRAGMENT)
            TriggerTutorial(TUTORIAL_TRIGGER_YOUR_GROUP_OPENED)
        elseif(newState == SCENE_HIDDEN) then
            self:DisableCurrentList()
            if self.currentFragmentGroup then
                SCENE_MANAGER:RemoveFragmentGroup(self.currentFragmentGroup)
            end

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            GROUP_LIST_GAMEPAD:Deactivate()

            ZO_GamepadGenericHeader_Deactivate(self.header)

            SCENE_MANAGER:RemoveFragment(GAMEPAD_GROUP_ROLES_FRAGMENT)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
        end
    end

    GAMEPAD_GROUP_SCENE = ZO_Scene:New("gamepad_groupList", SCENE_MANAGER)
    GAMEPAD_GROUP_SCENE:RegisterCallback("StateChange", OnStateChanged)
end

function ZO_GroupMenu_Gamepad:PerformDeferredInitialization()
    if self.isInitialized then return end

    self:InitializeKeybindDescriptors()
    self:InitializeEvents()

    ZO_GamepadGenericHeader_RefreshData(self.header, GAMEPAD_GROUP_DATA:GetHeaderData())

    self.currentFragmentGroup = nil
    self.menuEntries[MENU_ENTRY_TYPE_CURRENT_GROUP].fragmentGroup = { GROUP_LIST_GAMEPAD:GetListFragment(), GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT }

    self.isInitialized = true
end

function ZO_GroupMenu_Gamepad:InitializeKeybindDescriptors()
    --Main list
    local DIFFICULTY_NORMAL_INDEX = 1
    local DIFFICULTY_VETERAN_INDEX = 2

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function() 
                local data = self:GetMainList():GetTargetData()
                local type = data.type

                if type == MENU_ENTRY_TYPE_DUNGEON_DIFFICULTY then
                    local isPlayerVeteran = GetUnitVeteranRank("player") > 0
                    if not isPlayerVeteran then
                        return false
                    end

                    local isAnyGroupMemberInDungeon = IsAnyGroupMemberInDungeon()
                    local isGrouped = IsUnitGrouped("player")
                    local isLeader = isGrouped and IsUnitGroupLeader("player")

                    return not IsInLFGGroup() and not isAnyGroupMemberInDungeon and (not isGrouped or isLeader)
                elseif type == MENU_ENTRY_TYPE_CURRENT_GROUP then
                    return GetGroupSize() > 0
                end

                return true
            end,
            callback = function() 
                local data = self:GetMainList():GetTargetData()
                local type = data.type

                if type == MENU_ENTRY_TYPE_DUNGEON_DIFFICULTY then
                    self:DeactivateCurrentList()
                    self.dungeonDifficultyDropdown:Activate()
                    self.dungeonDifficultyDropdown:SetHighlightedItem(IsUnitUsingVeteranDifficulty("player") and DIFFICULTY_VETERAN_INDEX or DIFFICULTY_NORMAL_INDEX)

                elseif type == MENU_ENTRY_TYPE_CURRENT_GROUP then
                    self:SelectGroupList(SOUNDS.GAMEPAD_MENU_FORWARD)

                elseif type == MENU_ENTRY_TYPE_FIND_GROUP then
                    SCENE_MANAGER:Push("groupingToolsGamepad")

                elseif type == MENU_ENTRY_TYPE_INVITE_PLAYER then
                    local platform = GetUIPlatform()
                    if platform == UI_PLATFORM_PS4 then
                        ZO_ShowConsoleInviteToGroupFromUserListSelector()
                    else
                        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_GROUP_INVITE_DIALOG")
                    end

                elseif type == MENU_ENTRY_TYPE_INVITE_FRIEND then
                    ZO_ShowConsoleInviteToGroupFromUserListSelector()

                elseif type == MENU_ENTRY_TYPE_DISBAND_GROUP then
                    ZO_Dialogs_ShowGamepadDialog("GROUP_DISBAND_DIALOG")

                elseif type == MENU_ENTRY_TYPE_LEAVE_GROUP then
                    ZO_Dialogs_ShowGamepadDialog("GROUP_LEAVE_DIALOG")

                elseif type == MENU_ENTRY_TYPE_ROLES then
                    GAMEPAD_GROUP_ROLES_BAR:ToggleSelected()
                end
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetMainList())
end

function ZO_GroupMenu_Gamepad:InitializeEvents()

    local function OnGroupMemberJoined()
        if not self.control:IsControlHidden() then
            self:UpdateMenuList()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    local function OnGroupUpdate()
       if not self.control:IsControlHidden() then
            self:UpdateMenuList()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end 
    end

    local function OnGroupMemberLeft(characterName, reason, isLocalPlayer, isLeader)
        if not self.control:IsControlHidden() then
            self:UpdateMenuList()

            if isLocalPlayer then
                self:SelectMenuList()
                ZO_Dialogs_ReleaseAllDialogsOfName("GAMEPAD_SOCIAL_OPTIONS_DIALOG")
            elseif self.selectedGroupMemberData and self.selectedGroupMemberData.rawCharacterName == characterName then
                ZO_Dialogs_ReleaseAllDialogsOfName("GAMEPAD_SOCIAL_OPTIONS_DIALOG")
            end

            if self:IsCurrentList(self:GetMainList()) then
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end
        end
    end

    local function OnLeaderUpdate()
        if not self.control:IsControlHidden() then
            self:UpdateMenuList()
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            ZO_Dialogs_ReleaseAllDialogsOfName("GAMEPAD_SOCIAL_OPTIONS_DIALOG")
        end
    end

    local function OnGroupMemberConnectedStatus(unitTag, isOnline)
        if not self.control:IsControlHidden() then
            if ZO_Group_IsGroupUnitTag(unitTag) then
                if self.selectedGroupMemberData and self.selectedGroupMemberData.unitTag == unitTag then
                    ZO_Dialogs_ReleaseAllDialogsOfName("GAMEPAD_SOCIAL_OPTIONS_DIALOG")
                end
            end
        end
    end

    local function OnGroupingToolsStatusUpdate()
        if not self.control:IsControlHidden() then
            self:UpdateMenuList()
        end
    end

    local function OnVeteranDifficultyChanged()
        if not self.control:IsControlHidden() then
            self:UpdateMenuList()
        end
    end

    local function OnVeteranRankChanged(unitTag, veteranRank)
        if not self.control:IsControlHidden() then
            if ZO_Group_IsGroupUnitTag(unitTag) or unitTag == "player" then
                self:UpdateMenuList()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end
        end
    end

    local function OnZoneUpdate(unitTag, newZone)
        if not self.control:IsControlHidden() then
            if ZO_Group_IsGroupUnitTag(unitTag) or unitTag == "player" then
                self:UpdateMenuList()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end
        end
    end

    local lastUpdateS = 0
    local function OnUpdate(control, currentFrameTimeSeconds)
        --Refresh Grouping Tools tooltip
        if currentFrameTimeSeconds - lastUpdateS > 1 then
            local data = self:GetMainList():GetTargetData()
            if data and data.type == MENU_ENTRY_TYPE_FIND_GROUP then
                GAMEPAD_TOOLTIPS:LayoutGroupFinder(GAMEPAD_LEFT_TOOLTIP)
                lastUpdateS = currentFrameTimeSeconds
            end
        end
    end

    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, function(eventCode, ...) OnGroupMemberJoined(...) end)
    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, function(eventCode, ...) OnGroupMemberLeft(...) end)
    self.control:RegisterForEvent(EVENT_GROUP_UPDATE, function(eventCode, ...) OnGroupUpdate(...) end)
    self.control:RegisterForEvent(EVENT_LEADER_UPDATE, function(eventCode, ...) OnLeaderUpdate(...) end)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_STATUS_UPDATE, function(eventCode, ...) OnGroupingToolsStatusUpdate(...) end)
    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_CONNECTED_STATUS, function(eventCode, ...) OnGroupMemberConnectedStatus(...) end)

    self.control:RegisterForEvent(EVENT_VETERAN_DIFFICULTY_CHANGED, function(eventCode, ...) OnVeteranDifficultyChanged(...) end)
    self.control:RegisterForEvent(EVENT_VETERAN_RANK_UPDATE, function(eventCode, ...) OnVeteranRankChanged(...) end)

    self.control:RegisterForEvent(EVENT_ZONE_UPDATE, function(eventCode, ...) OnZoneUpdate(...) end)

    self.control:SetHandler("OnUpdate", OnUpdate)

    CALLBACK_MANAGER:RegisterCallback("OnGroupStatusChange", function() self:RefreshFooter() end)
end


--List updates
function ZO_GroupMenu_Gamepad:UpdateMenuList()
    if self.dungeonDifficultyDropdown then
        self.dungeonDifficultyDropdown:Deactivate()
    end

    local wasInGroupList = GROUP_LIST_GAMEPAD.isActive
    local list = self:GetMainList()
    list:Clear()
    local playerIsLeader = IsUnitGroupLeader("player")
    local groupSize = GetGroupSize()

    local groupActionEntries = {}

    if not IsCurrentlySearchingForGroup() then
        list:AddEntry(MENU_ENTRY_TEMPLATE, self.menuEntries[MENU_ENTRY_TYPE_ROLES])
    end

    list:AddEntry(MENU_ENTRY_TEMPLATE, self.menuEntries[MENU_ENTRY_TYPE_CURRENT_GROUP])
    list:AddEntry(MENU_ENTRY_TEMPLATE, self.menuEntries[MENU_ENTRY_TYPE_FIND_GROUP])
    list:AddEntryWithHeader("ZO_GroupMenuGamepadDungeonDifficultyEntry", self.menuEntries[MENU_ENTRY_TYPE_DUNGEON_DIFFICULTY])  
    
    if groupSize == 0 or (playerIsLeader and groupSize < GROUP_SIZE_MAX) then
        table.insert(groupActionEntries, self.menuEntries[MENU_ENTRY_TYPE_INVITE_PLAYER])
        local platform = GetUIPlatform()
        if platform == UI_PLATFORM_XBOX and GetNumberConsoleFriends() > 0 then
            table.insert(groupActionEntries, self.menuEntries[MENU_ENTRY_TYPE_INVITE_FRIEND])
        end
    end

    if groupSize > 0 then
        table.insert(groupActionEntries, self.menuEntries[MENU_ENTRY_TYPE_LEAVE_GROUP])
    end
    if playerIsLeader then
        table.insert(groupActionEntries, self.menuEntries[MENU_ENTRY_TYPE_DISBAND_GROUP])
    end

    for i, entry in ipairs(groupActionEntries) do
        if i == 1 then
            entry:SetHeader(GetString(SI_GAMEPAD_GROUP_ACTIONS_MENU_HEADER))
            list:AddEntryWithHeader(MENU_ENTRY_TEMPLATE, entry)
        else
            list:AddEntry(MENU_ENTRY_TEMPLATE, entry)
        end
    end

    list:Commit()
    --Changing the menu deactivates the list fragment, so we'll need to reactivate it
    if wasInGroupList then
        self:SelectGroupList()
    end
end

function ZO_GroupMenu_Gamepad:SelectMenuList()
    GROUP_LIST_GAMEPAD:Deactivate()
    self:SetCurrentList(self:GetMainList())
    self:ActivateCurrentList()
    GAMEPAD_GROUP_ROLES_BAR:SetIsManuallyDimmed(false)
end

function ZO_GroupMenu_Gamepad:SelectGroupList(sound)
    GAMEPAD_GROUP_ROLES_BAR:SetIsManuallyDimmed(true)
    self:DeactivateCurrentList()
    GROUP_LIST_GAMEPAD:Activate()
    PlaySound(sound)
end


--ZO_Gamepad_ParametricList_Screen overrides
function ZO_GroupMenu_Gamepad:SetupList(list)
    local function CreateListEntry(textEnum, type, iconUp, iconDown, iconOver)
        local newEntry = ZO_GamepadEntryData:New(GetString(textEnum), iconUp, iconDown, iconOver)
        newEntry.type = type
        newEntry:SetIconTintOnSelection(true)
        return newEntry
    end
    
    local function CreateDifficultyListEntry(textEnum, type, normalIcon, veteranIcon)
        local entry = CreateListEntry(textEnum, type, normalIcon)
        entry.normalIcon = normalIcon
        entry.veteranIcon = veteranIcon
        return entry
    end

    --Dungeon Difficulty Dropdown Entry
    local function OnDeactivatedDungeonDifficulty()
        self:ActivateCurrentList()
    end

    local function OnSelectedDungeonDifficulty(comboBox, name, entry, selectionChange)
        SetVeteranDifficulty(entry.isVeteran)
    end

    local function SetupDungeonDifficultyEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)

        local isVeteran = IsUnitUsingVeteranDifficulty("player")
        control.icon:ClearIcons()
        control.icon:AddIcon(isVeteran and data.veteranIcon or data.normalIcon)
        control.icon:Show()

        local dropdown = control.dropdown
        self.dungeonDifficultyDropdown = dropdown

        dropdown:SetSortsItems(false)
        dropdown:SetDeactivatedCallback(OnDeactivatedDungeonDifficulty)

        dropdown:ClearItems()
        local normalEntry = ZO_ComboBox:CreateItemEntry(GetString(SI_GAMEPAD_GROUP_DUNGEON_MODE_NORMAL), OnSelectedDungeonDifficulty)
        normalEntry.isVeteran = false
        dropdown:AddItem(normalEntry, ZO_COMBOBOX_SUPRESS_UPDATE)
        
        local veteranEntry = ZO_ComboBox:CreateItemEntry(GetString(SI_GAMEPAD_GROUP_DUNGEON_MODE_VETERAN), OnSelectedDungeonDifficulty)
        veteranEntry.isVeteran = true
        dropdown:AddItem(veteranEntry, ZO_COMBOBOX_SUPRESS_UPDATE)
        
        dropdown:UpdateItems()

        local selectedString = isVeteran and SI_GAMEPAD_GROUP_DUNGEON_MODE_VETERAN or SI_GAMEPAD_GROUP_DUNGEON_MODE_NORMAL
        dropdown:SetSelectedItem(GetString(selectedString))
    end

    --Menu
    local function UpdateTooltipText(menuEntryType)
        local tooltipInfo = TOOLTIP_INFO_TEXT[menuEntryType]
        if tooltipInfo then
            local textEntry = tooltipInfo.text
            local bodyText, errorText
            if type(textEntry) == "string" then
                bodyText = textEntry
            else
                bodyText = textEntry.bodyText
                for _, error in ipairs(textEntry.errors) do
                    if error.canDisplay() then
                        errorText = error.text
                        break
                    end
                end
            end
            GAMEPAD_TOOLTIPS:LayoutGroupTooltip(GAMEPAD_LEFT_TOOLTIP, tooltipInfo.title, bodyText, errorText)
		elseif menuEntryType == MENU_ENTRY_TYPE_FIND_GROUP then
            GAMEPAD_TOOLTIPS:LayoutGroupFinder(GAMEPAD_LEFT_TOOLTIP)
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end

    local function OnSelectedMenuEntry(_, selectedData)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

        if self.currentFragmentGroup then
            SCENE_MANAGER:RemoveFragmentGroup(self.currentFragmentGroup)
        end
        self.currentFragmentGroup = selectedData.fragmentGroup

        if self.currentFragmentGroup then
            SCENE_MANAGER:AddFragmentGroup(self.currentFragmentGroup)
        end
        
        local menuEntryType = selectedData.type
        UpdateTooltipText(menuEntryType)

        if menuEntryType == MENU_ENTRY_TYPE_ROLES then
            GAMEPAD_GROUP_ROLES_BAR:Activate()
        else
            GAMEPAD_GROUP_ROLES_BAR:Deactivate()
        end
    end

    list:AddDataTemplate(MENU_ENTRY_TEMPLATE, ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader(MENU_ENTRY_TEMPLATE, ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, CATEGORY_HEADER_TEMPLATE)
    list:AddDataTemplateWithHeader("ZO_GroupMenuGamepadDungeonDifficultyEntry", SetupDungeonDifficultyEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, CATEGORY_HEADER_TEMPLATE)

    list:SetOnSelectedDataChangedCallback(OnSelectedMenuEntry)

    local listControl = list.control
    local _, point1, relativeTo1, relativePoint1, offsetX1, offsetY1 = listControl:GetAnchor(0)
    local _, point2, relativeTo2, relativePoint2, offsetX2, offsetY2 = listControl:GetAnchor(1)
    listControl:ClearAnchors()
    listControl:SetAnchor(point1, relativeTo1, relativePoint1, offsetX1, offsetY1 + ZO_ROLES_BAR_ADDITIONAL_HEADER_SPACE)
    listControl:SetAnchor(point2, relativeTo2, relativePoint2, offsetX2, offsetY2)

    list:SetDefaultSelectedIndex(2) --don't select MENU_ENTRY_TYPE_ROLES by default

    --Constant entries
    self.menuEntries = {
        [MENU_ENTRY_TYPE_ROLES] = CreateListEntry("", MENU_ENTRY_TYPE_ROLES),
        [MENU_ENTRY_TYPE_CURRENT_GROUP] = CreateListEntry(SI_GAMEPAD_GROUP_CURRENT_GROUP, MENU_ENTRY_TYPE_CURRENT_GROUP, "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_currentGroup.dds"),
        [MENU_ENTRY_TYPE_FIND_GROUP] = CreateListEntry(SI_GAMEPAD_GROUP_FIND_MEMBERS, MENU_ENTRY_TYPE_FIND_GROUP, "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_groupFinder.dds"),
        [MENU_ENTRY_TYPE_DUNGEON_DIFFICULTY] = CreateDifficultyListEntry("", MENU_ENTRY_TYPE_DUNGEON_DIFFICULTY, "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_normalDungeon.dds", "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_veteranDungeon.dds"),
        [MENU_ENTRY_TYPE_INVITE_PLAYER] = CreateListEntry(SI_GROUP_WINDOW_INVITE_PLAYER, MENU_ENTRY_TYPE_INVITE_PLAYER, "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_invitePlayer.dds"),
        [MENU_ENTRY_TYPE_INVITE_FRIEND] = CreateListEntry(SI_GROUP_WINDOW_INVITE_FRIEND, MENU_ENTRY_TYPE_INVITE_FRIEND, "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_invitePlayer.dds"),
        [MENU_ENTRY_TYPE_LEAVE_GROUP] = CreateListEntry(SI_GROUP_LIST_MENU_LEAVE_GROUP, MENU_ENTRY_TYPE_LEAVE_GROUP),
        [MENU_ENTRY_TYPE_DISBAND_GROUP] = CreateListEntry(SI_GROUP_LIST_MENU_DISBAND_GROUP, MENU_ENTRY_TYPE_DISBAND_GROUP),
    }

    self.menuEntries[MENU_ENTRY_TYPE_DUNGEON_DIFFICULTY]:SetHeader(GetString(SI_GAMEPAD_GROUP_DUNGEON_DIFFICULTY))
end

function ZO_GroupMenu_Gamepad:EnableCurrentList()
    ZO_Gamepad_ParametricList_Screen.EnableCurrentList(self)
    
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GroupMenu_Gamepad:DisableCurrentList()
    self.dungeonDifficultyDropdown:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    
    ZO_Gamepad_ParametricList_Screen.DisableCurrentList(self)
end

function ZO_GroupMenu_Gamepad:ActivateCurrentList()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    
    ZO_Gamepad_ParametricList_Screen.ActivateCurrentList(self)
end

function ZO_GroupMenu_Gamepad:DeactivateCurrentList()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

    ZO_Gamepad_ParametricList_Screen.DeactivateCurrentList(self)
end

--Other updates
function ZO_GroupMenu_Gamepad:RefreshFooter()
    GAMEPAD_GENERIC_FOOTER:Refresh(GAMEPAD_GROUP_DATA:GetFooterData())
end


--XML Calls
function ZO_GroupMenuGamepad_OnInitialized(control)
    GAMEPAD_GROUP_MENU = ZO_GroupMenu_Gamepad:New(control)
end
