
ZO_GAMEPAD_GROUP_FINDER_APPLICATIONS_LIST_LEVEL_WIDTH = 210 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GROUP_FINDER_APPLICATIONS_LIST_ROLES_WIDTH = 140 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GROUP_FINDER_APPLICATIONS_LIST_EXPIRES_WIDTH = 125 - ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X
ZO_GAMEPAD_GROUP_FINDER_APPLICATIONS_LIST_CHAMPION_POINTS_ICON_OFFSET_X = 55

---------------------------------
-- Application List Focus Area --
---------------------------------

ZO_GroupFinder_ApplicationListScreen_Gamepad_FocusArea_ApplicationList = ZO_GamepadMultiFocusArea_Base:Subclass()

function ZO_GroupFinder_ApplicationListScreen_Gamepad_FocusArea_ApplicationList:HandleMovement(horizontalResult, verticalResult)
    --Pipe directional input through to the interactive sort filter list
    self.applicationList:HandleMoveCurrentFocus(horizontalResult, verticalResult)
    return true
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad_FocusArea_ApplicationList:HandleMovePrevious()
    local consumed = false
    if self.applicationList:IsHeaderFocused() then
        consumed = ZO_GamepadMultiFocusArea_Base.HandleMovePrevious(self)
    end
    return consumed
end

-----------------------------
-- Application List Screen --
-----------------------------

ZO_GroupFinder_ApplicationListScreen_Gamepad = ZO_GamepadMultiFocusArea_Manager:Subclass()

function ZO_GroupFinder_ApplicationListScreen_Gamepad:Initialize(control)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self)

    self.control = control
    self.applicationListControl = control:GetNamedChild("ApplicationList")
    self.applicationList = ZO_GroupFinder_ApplicationList_Gamepad:New(self.applicationListControl)

    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        end
    end)

    self:InitializeMyListing()
    self:InitializeKeybindStripDescriptors()
    self:InitializeMultiFocusAreas()
    self:RegisterForEvents()
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:InitializeMyListing()
    self.myListingControl = self.control:GetNamedChild("GroupListingContainerGroupListing")

    --Create the control pools for the listing
    self.roleControlPool = ZO_ControlPool:New("ZO_GroupFinder_RoleIconTemplate_Gamepad", self.control)

    --Create the data object
    self.myListingData = ZO_GroupListingUserTypeData:New(GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING)

    --Use MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL instead of vertical so it doesn't interfere with the directional input for the screen as a whole
    self.myListingFocus = ZO_GamepadFocus:New(self.myListingControl, ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL))
    local myListingFocusEntry = 
    {
        activate = function()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD1_TOOLTIP)
            GAMEPAD_TOOLTIPS:LayoutGroupFinderGroupListingTooltip(GAMEPAD_QUAD1_TOOLTIP, self.myListingData)
            SCREEN_NARRATION_MANAGER:QueueFocus(self.myListingFocus)
        end,
        deactivate = function()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD1_TOOLTIP)
        end,
        canFocus = function() return not self.myListingControl:IsHidden() end,
        highlight = self.myListingControl:GetNamedChild("Highlight")
    }
    self.myListingFocus:AddEntry(myListingFocusEntry)
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:InitializeKeybindStripDescriptors()
    self.myListingDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Open Group Menu
        {
            keybind = "UI_SHORTCUT_QUATERNARY",
            name = GetString(SI_PLAYER_MENU_GROUP),
            callback = function()
                SYSTEMS:GetObject("mainMenu"):ShowGroupMenu()
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.myListingDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() GROUP_FINDER_GAMEPAD:ExitApplicationList() end)
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:InitializeMultiFocusAreas()
    local function MyListingActivateCallback()
        self.myListingFocus:Activate()
    end

    local function MyListingDeactivateCallback()
        self.myListingFocus:Deactivate()
    end

    self.myListingArea = ZO_GamepadMultiFocusArea_Base:New(self, MyListingActivateCallback, MyListingDeactivateCallback)
    self.myListingArea:SetKeybindDescriptor(self.myListingDescriptor)

    --Directional input is managed in this class instead of in the interactive sort filter list
    local FOREGO_DIRECTIONAL_INPUT = true
    local function ListActivateCallback()
        self.applicationList:Activate(FOREGO_DIRECTIONAL_INPUT)
    end

    local function ListDeactivateCallback()
        self.applicationList:Deactivate(FOREGO_DIRECTIONAL_INPUT)
    end

    self.applicationListArea = ZO_GroupFinder_ApplicationListScreen_Gamepad_FocusArea_ApplicationList:New(self, ListActivateCallback, ListDeactivateCallback)
    self.applicationListArea.applicationList = self.applicationList

    self:AddNextFocusArea(self.myListingArea)
    self:AddNextFocusArea(self.applicationListArea)

    local DONT_ACTIVATE_FOCUS_AREA = false
    self:SelectFocusArea(self.applicationListArea, DONT_ACTIVATE_FOCUS_AREA)
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:RegisterForEvents()
    local function OnUpdateGroupListingResult(_, result)
        if self.fragment:IsShowing() and result == GROUP_FINDER_ACTION_RESULT_SUCCESS then
            self:RefreshListing()
        end
    end
    EVENT_MANAGER:RegisterForEvent("GroupFinder_ApplicationListScreen_Gamepad", EVENT_GROUP_FINDER_UPDATE_GROUP_LISTING_RESULT, OnUpdateGroupListingResult)

    GROUP_FINDER_APPLICATIONS_LIST_MANAGER:RegisterCallback("ApplicationsListUpdated", function() self:RefreshApplications() end)
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:GetFragment()
    return self.fragment
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:RefreshListing()
    self.roleControlPool:ReleaseAllObjects()
    ZO_GroupFinder_Shared.SetUpGroupListingFromData(self.myListingControl, self.roleControlPool, self.myListingData, ZO_GROUP_LISTING_ROLE_CONTROL_PADDING_GAMEPAD)

    if self.myListingData:DoesGroupAutoAcceptRequests() then
        self.applicationList:SetEmptyText(GetString(SI_GROUP_FINDER_APPLICATIONS_AUTO_ACCEPT_EMPTY_TEXT))
    else
        self.applicationList:SetEmptyText(GetString(SI_GROUP_FINDER_APPLICATIONS_EMPTY_TEXT))
    end
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:RefreshApplications()
    if self.fragment:IsShowing() then
        self.applicationList:RefreshData()
    end
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:Activate()
    --If the listing auto accepts requests, select the listing by default, otherwise select the application list
    if self.myListingData:DoesGroupAutoAcceptRequests() then
        self:ActivateFocusArea(self.myListingArea)
    else
        self:ActivateFocusArea(self.applicationListArea)
    end
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:Deactivate()
    self:DeactivateCurrentFocus()
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:OnShowing()
    self:RefreshListing()
    self:RefreshApplications()
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad:OnHiding()
    self:Deactivate()
end

function ZO_GroupFinder_ApplicationListScreen_Gamepad.OnControlInitialized(control)
    GROUP_FINDER_APPLICATION_LIST_SCREEN_GAMEPAD = ZO_GroupFinder_ApplicationListScreen_Gamepad:New(control)
end

----------------------
-- Application List --
----------------------

local APPLICATION_DATA = 1

ZO_GroupFinder_ApplicationList_Gamepad = ZO_Object.MultiSubclass(ZO_GamepadInteractiveSortFilterList, ZO_SocialOptionsDialogGamepad)

function ZO_GroupFinder_ApplicationList_Gamepad:Initialize(control)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)
    ZO_SocialOptionsDialogGamepad.Initialize(self)
    self.masterList = {}
    ZO_ScrollList_AddDataType(self.list, APPLICATION_DATA, "ZO_GroupFinder_ApplicationListRow_Gamepad", ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT, function(entryControl, entryData) self:SetupRow(entryControl, entryData) end)
    self:SetEmptyText(GetString(SI_GROUP_FINDER_APPLICATIONS_EMPTY_TEXT))
    self:SetupSort(GROUP_FINDER_APPLICATIONS_LIST_ENTRY_SORT_KEYS, "GetEndTimeSeconds", ZO_SORT_ORDER_UP)
end

function ZO_GroupFinder_ApplicationList_Gamepad:SetupRow(control, data)
    control.displayNameLabel:SetText(data:GetFormattedDisplayName())
    control.characterNameLabel:SetText(ZO_FormatUserFacingCharacterName(data:GetCharacterName()))
    control.classIconControl:SetTexture(data:GetClassIcon())

    local level = data:GetLevel()
    local championPoints = data:GetChampionPoints()
    control.levelLabel:SetText(ZO_GetLevelOrChampionPointsStringNoIcon(level, championPoints))
    control.championIconControl:SetHidden(championPoints == 0)

    local assignedRole = data:GetRole()
    for role, roleControl in pairs(control.roleControls) do
        roleControl:SetAlpha(role == assignedRole and ZO_GAMEPAD_ICON_SELECTED_ALPHA or ZO_GAMEPAD_ICON_UNSELECTED_ALPHA)
    end

    control:SetHandler("OnUpdate", function()
        if data:IsInPendingState() then
            control.expiresLabel:SetText(GetString(SI_GROUP_FINDER_APPLICATION_PENDING))
        else
            control.expiresLabel:SetText(ZO_FormatTimeLargestTwo(data:GetTimeRemainingSeconds(), TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL))
        end
    end)
end

function ZO_GroupFinder_ApplicationList_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GROUP_FINDER_ACCEPT_APPLICATION),
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_APPROVE, selectedData:GetCharacterId())
                end
            end,
        },
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_GROUP_FINDER_REJECT_APPLICATION),
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_REJECT, selectedData:GetCharacterId())
                end
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())
    local DEFAULT_CALLBACK = nil
    self:AddSocialOptionsKeybind(self.keybindStripDescriptor, DEFAULT_CALLBACK, "UI_SHORTCUT_TERTIARY", GetString(SI_GAMEPAD_OPTIONS_MENU))
    ZO_GamepadInteractiveSortFilterList.InitializeKeybinds(self)

    -- Open Group Menu
    local groupMenuKeybind =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_QUATERNARY",
        name = GetString(SI_PLAYER_MENU_GROUP),
        callback = function()
            SYSTEMS:GetObject("mainMenu"):ShowGroupMenu()
        end,
    }
    self:AddUniversalKeybind(groupMenuKeybind)
end

--Overridden from base
function ZO_GroupFinder_ApplicationList_Gamepad:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildIgnoreOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsNotPlayer)
end

--Overridden from base
function ZO_GroupFinder_ApplicationList_Gamepad:SetupOptions(entryData)
    if entryData then
        local socialData =
        {
            displayName = entryData:GetDisplayName(),
        }
        ZO_SocialOptionsDialogGamepad.SetupOptions(self, socialData)
    end
end

--Overridden from base
function ZO_GroupFinder_ApplicationList_Gamepad:FilterScrollList()
    -- No real filtering...just show everything in the master list
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, data in ipairs(self.masterList) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(APPLICATION_DATA, ZO_EntryData:New(data)))
    end
end

--Overridden from base
function ZO_GroupFinder_ApplicationList_Gamepad:BuildMasterList()
    self.masterList = GROUP_FINDER_APPLICATIONS_LIST_MANAGER:GetApplicationsData()
end

--Overridden from base
function ZO_GroupFinder_ApplicationList_Gamepad:OnSelectionChanged(previousData, selectedData)
    ZO_GamepadInteractiveSortFilterList.OnSelectionChanged(self, previousData, selectedData)
    self:SetupOptions(selectedData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD1_TOOLTIP)
    if selectedData then
        GAMEPAD_TOOLTIPS:LayoutGroupFinderApplicationDetails(GAMEPAD_QUAD1_TOOLTIP, selectedData)
    end
end

--Overridden from base
function ZO_GroupFinder_ApplicationList_Gamepad:GetBackKeybindCallback()
    return function() GROUP_FINDER_GAMEPAD:ExitApplicationList() end
end

--Overridden from base
function ZO_GroupFinder_ApplicationList_Gamepad:GetHeaderNarration()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GROUP_FINDER_APPLICATIONS_HEADER))
end

--Overridden from base
function ZO_GroupFinder_ApplicationList_Gamepad:GetNarrationText()
    local narrations = {}
    local entryData = self:GetSelectedData()
    if entryData then
        --Generate the user ID narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_GetPlatformAccountLabel()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetFormattedDisplayName()))

        --Generate the character name narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SOCIAL_LIST_PANEL_HEADER_CHARACTER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetCharacterName()))

        --Generate the class narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GROUP_LIST_PANEL_CLASS_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetClassName()))

        --Generate the level narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_GROUP_FINDER_APPLICATION_LIST_HEADER_LEVEL)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_GetLevelOrChampionPointsNarrationString(entryData:GetLevel(), entryData:GetChampionPoints())))

        --Generate the role narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GROUP_LIST_PANEL_ROLES_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_LFGROLE", entryData:GetRole())))

        --Generate the expire time narration
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GROUP_FINDER_APPLICATIONS_SORT_HEADER_EXPIRATION)))
        if entryData:IsInPendingState() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GROUP_FINDER_APPLICATION_PENDING)))
        else
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_FormatTimeLargestTwo(entryData:GetTimeRemainingSeconds(), TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)))
        end
        
    end

    return narrations
end

--------------
--Global XML
---------------

function ZO_GroupFinder_ApplicationListRow_Gamepad_OnInitialized(control)
    control.displayNameLabel = control:GetNamedChild("DisplayName")
    control.characterNameLabel = control:GetNamedChild("CharacterName")
    control.classIconControl = control:GetNamedChild("ClassIcon")
    control.levelLabel = control:GetNamedChild("Level")
    control.championIconControl = control:GetNamedChild("Champion")

    local roleControls =
    {
        [LFG_ROLE_DPS] = control:GetNamedChild("RolesDPS"),
        [LFG_ROLE_TANK] = control:GetNamedChild("RolesTank"),
        [LFG_ROLE_HEAL] = control:GetNamedChild("RolesHeal"),
    }
    control.roleControls = roleControls
    control.expiresLabel = control:GetNamedChild("Expires")
end