------------------------------------------
--Group Finder Applications List Keyboard
------------------------------------------

ZO_KEYBOARD_GROUP_FINDER_APPLICATIONS_LIST_EXPIRES_WIDTH = 85

local APPLICATION_DATA = 1

--------------------------------------------------------------
-- ZO_GroupFinder_ApplicationsManagementPanel_Keyboard
--------------------------------------------------------------

ZO_GroupFinder_ApplicationsManagementPanel_Keyboard = ZO_GroupFinder_BasePanel_Keyboard:Subclass()

function ZO_GroupFinder_ApplicationsManagementPanel_Keyboard:Initialize(control)
    ZO_GroupFinder_BasePanel_Keyboard.Initialize(self, control)
    self.list = ZO_GroupFinder_ApplicationsList_Keyboard:New(control:GetNamedChild("List"), self:GetFragment())
    self.editButton = control:GetNamedChild("ButtonContainerEditGroupButton")
    self.myListingControl = control:GetNamedChild("GroupListing")
    self.myListingData = ZO_GroupListingUserTypeData:New(GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING)
    self.myListingControl:SetHandler("OnMouseEnter", function()
        InitializeTooltip(GroupFinderGroupListingTooltip, self.myListingControl, RIGHT, -15, 0, LEFT)
        ZO_GroupFinderGroupListingTooltip_SetGroupFinderListing(GroupFinderGroupListingTooltip, self.myListingData)
    end)
    self.myListingControl:SetHandler("OnMouseExit", function()
        ClearTooltip(GroupFinderGroupListingTooltip)
    end)

    self.roleControlPool = ZO_ControlPool:New("ZO_GroupFinder_RoleIconTemplate_Keyboard", control)

    local function OnUpdateGroupListing(result)
        if result == GROUP_FINDER_ACTION_RESULT_SUCCESS then
            self:RefreshListing()
        end
    end

    EVENT_MANAGER:RegisterForEvent("GroupFinder_ApplicationsManagementPanel", EVENT_GROUP_FINDER_UPDATE_GROUP_LISTING_RESULT, OnUpdateGroupListing)

    local function OnRefreshApplication()
        if self:GetFragment():IsShowing() then
            self.editButton:SetEnabled(ZO_GroupFinder_CanDoCreateEdit(self.myListingData))
        end
    end

    GROUP_FINDER_APPLICATIONS_LIST_MANAGER:RegisterCallback("ApplicationsListUpdated", OnRefreshApplication)

   self.editButton:SetHandler("OnMouseEnter", function()
        local canDoCreateEdit, disabledString = ZO_GroupFinder_CanDoCreateEdit(self.myListingData)
        if not canDoCreateEdit then
            InitializeTooltip(InformationTooltip, self.editButton, BOTTOMLEFT, 0, 0, TOPLEFT)
            SetTooltipText(InformationTooltip, ZO_ERROR_COLOR:Colorize(disabledString))
        end
    end)

    self.editButton:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)
end

function ZO_GroupFinder_ApplicationsManagementPanel_Keyboard:Show()
    ZO_GroupFinder_BasePanel_Keyboard.Show(self)
    self:RefreshListing()
end

function ZO_GroupFinder_ApplicationsManagementPanel_Keyboard:RefreshListing()
    self.roleControlPool:ReleaseAllObjects()
    ZO_GroupFinder_Shared.SetUpGroupListingFromData(self.myListingControl, self.roleControlPool, self.myListingData, ZO_GROUP_LISTING_ROLE_CONTROL_PADDING)

    if self.myListingData:DoesGroupAutoAcceptRequests() then
        self.list:SetNoApplicationsText(GetString(SI_GROUP_FINDER_APPLICATIONS_AUTO_ACCEPT_EMPTY_TEXT))
    else
        self.list:SetNoApplicationsText(GetString(SI_GROUP_FINDER_APPLICATIONS_EMPTY_TEXT))
    end
    self.editButton:SetEnabled(ZO_GroupFinder_CanDoCreateEdit(self.myListingData))
end

--------------------------------------------------------------
-- ZO_GroupFinder_ApplicationsList_Keyboard
--------------------------------------------------------------

ZO_GroupFinder_ApplicationsList_Keyboard = ZO_SortFilterList:Subclass()

function ZO_GroupFinder_ApplicationsList_Keyboard:Initialize(control, fragment)
    ZO_SortFilterList.Initialize(self, control)
    self.fragment = fragment

    self:InitializeKeybindDescriptors()
    self:RegisterForEvents()
end

function ZO_GroupFinder_ApplicationsList_Keyboard:RegisterForEvents()
    GROUP_FINDER_APPLICATIONS_LIST_MANAGER:RegisterCallback("ApplicationsListUpdated", function() self:RefreshData() end)
    self.fragment:RegisterCallback("StateChange", function(...) self:OnStateChange(...) end)
end

function ZO_GroupFinder_ApplicationsList_Keyboard:InitializeSortFilterList(control)
    ZO_SortFilterList.InitializeSortFilterList(self, control)

    self:SetAlternateRowBackgrounds(true)

    self.noApplicationsRow = control:GetNamedChild("NoApplicationsRow")
    self.noApplicationsRowMessage = self.noApplicationsRow:GetNamedChild("Message")

    self.masterList = {}
    ZO_ScrollList_Initialize(self.list)
    local ROW_HEIGHT = 30
    ZO_ScrollList_AddDataType(self.list, APPLICATION_DATA, "ZO_GroupFinder_ApplicationsListRow_Keyboard", ROW_HEIGHT, function(entryControl, data) self:SetupGroupApplicationEntry(entryControl, data) end)

    self.sortFunction = function(listEntry1, listEntry2) return self:CompareApplications(listEntry1, listEntry2) end
    self.sortHeaderGroup:SelectHeaderByKey("GetEndTimeSeconds")

    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
end

function ZO_GroupFinder_ApplicationsList_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        -- Reject Application
        {
            name = GetString(SI_GROUP_FINDER_REJECT_APPLICATION),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = function()
                return self.mouseOverRow ~= nil
            end,
            enabled = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                if data then
                    return not data:IsInPendingState()
                end
                return false
            end,
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                if data then
                    RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_REJECT, data:GetCharacterId())
                end
            end,
        },
        -- Accept Application
        {
            name = GetString(SI_GROUP_FINDER_ACCEPT_APPLICATION),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self.mouseOverRow ~= nil
            end,
            enabled = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                if data then
                    return not data:IsInPendingState()
                end
                return false
            end,
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                if data then
                    RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_APPROVE, data:GetCharacterId())
                end
            end,
        },
    }
end

function ZO_GroupFinder_ApplicationsList_Keyboard:OnStateChange(oldState, newState)
    if newState == SCENE_FRAGMENT_SHOWING then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    elseif newState == SCENE_FRAGMENT_SHOWN then
        self:RefreshData()
        GROUP_FINDER_APPLICATIONS_LIST_MANAGER:SetHasNewApplication(false)
    elseif newState == SCENE_FRAGMENT_HIDDEN then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GroupFinder_ApplicationsList_Keyboard:SetupGroupApplicationEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    --Order matters: AttachToList should be called before AssignApplicationData
    control.object:AttachToList(self)
    control.object:AssignApplicationData(data)
end

--ZO_SortFilterList overrides
function ZO_GroupFinder_ApplicationsList_Keyboard:BuildMasterList()
    self.masterList = GROUP_FINDER_APPLICATIONS_LIST_MANAGER:GetApplicationsData()

    --If the master list is empty, show the empty row
    local hasEntries = #self.masterList > 0
    self.noApplicationsRow:SetHidden(hasEntries)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GroupFinder_ApplicationsList_Keyboard:FilterScrollList()
    -- No real filtering...just show everything in the master list
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, data in ipairs(self.masterList) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(APPLICATION_DATA, ZO_EntryData:New(data)))
    end
end

function ZO_GroupFinder_ApplicationsList_Keyboard:SortScrollList()
    if self.currentSortKey ~= nil and self.currentSortOrder ~= nil then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end

    self:RefreshVisible()
end

function ZO_GroupFinder_ApplicationsList_Keyboard:RefreshData()
    if self.fragment:IsShowing() then
        ZO_SortFilterList.RefreshData(self)
    end
end

function ZO_GroupFinder_ApplicationsList_Keyboard:CompareApplications(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, GROUP_FINDER_APPLICATIONS_LIST_ENTRY_SORT_KEYS, self.currentSortOrder)
end

function ZO_GroupFinder_ApplicationsList_Keyboard:SetNoApplicationsText(text)
    self.noApplicationsRowMessage:SetText(text)
end

function ZO_GroupFinder_ApplicationsList_Keyboard:Row_OnMouseDoubleClick(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT and self.mouseOverRow then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if data then
            RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_APPROVE, data:GetCharacterId())
        end
    end
end

-------------------------------------
--Group Finder Applications List Row
-------------------------------------

ZO_GroupFinder_ApplicationsListRow = ZO_InitializingObject:Subclass()

function ZO_GroupFinder_ApplicationsListRow:Initialize(control)
    control.object = self
    self.control = control
    self.background = control:GetNamedChild("BG")
    self.characterNameLabel = control:GetNamedChild("CharacterName")

    local roleControls =
    {
        [LFG_ROLE_DPS] = control:GetNamedChild("RoleDPS"),
        [LFG_ROLE_TANK] = control:GetNamedChild("RoleTank"),
        [LFG_ROLE_HEAL] = control:GetNamedChild("RoleHeal"),
    }
    self.roleControls = roleControls

    self.classIcon = control:GetNamedChild("ClassIcon")
    self.levelLabel = control:GetNamedChild("Level")
    self.championIcon = control:GetNamedChild("Champion")
    self.expiresLabel = control:GetNamedChild("Expires")
    self.noteControl = control:GetNamedChild("Note")

    --Create the shared input group
    self.inputGroup = ZO_MouseInputGroup:New(control)

    local function OnRowChildMouseExit()
        ClearTooltip(InformationTooltip)
    end

    --Set up the mouse over behavior for the character name
    local function OnCharacterNameMouseEnter(nameControl)
        if self.data then
            InitializeTooltip(InformationTooltip, nameControl, BOTTOMLEFT, 0, 0, TOPLEFT)
            SetTooltipText(InformationTooltip, self.data:GetDisplayName())
        end
    end
    self.characterNameLabel:SetHandler("OnMouseEnter", OnCharacterNameMouseEnter)
    self.characterNameLabel:SetHandler("OnMouseExit", OnRowChildMouseExit)
    self.inputGroup:Add(self.characterNameLabel, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)

    --Set up the mouse over behavior for the class icon
    local function OnClassIconMouseEnter(iconControl)
        if self.data then
            InitializeTooltip(InformationTooltip, iconControl, BOTTOM, 0, 0)
            SetTooltipText(InformationTooltip, self.data:GetClassName())
        end
    end
    self.classIcon:SetHandler("OnMouseEnter", OnClassIconMouseEnter)
    self.classIcon:SetHandler("OnMouseExit", OnRowChildMouseExit)
    self.inputGroup:Add(self.classIcon, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    
    --Set up the mouse over behavior for the role controls
    for roleType, roleControl in pairs(self.roleControls) do
        roleControl:SetHandler("OnMouseEnter", function()
            InitializeTooltip(InformationTooltip, roleControl, BOTTOM)
            SetTooltipText(InformationTooltip, GetString("SI_LFGROLE", roleType))
        end)
        roleControl:SetHandler("OnMouseExit", OnRowChildMouseExit)
        self.inputGroup:Add(roleControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
    end

    --Set up the mouse over behavior for the note button
    local function OnNoteControlMouseEnter(noteControl)
        if self.data then
            InitializeTooltip(InformationTooltip, noteControl, BOTTOM, 0, 0)
            SetTooltipText(InformationTooltip, self.data:GetNote())
        end
    end
    self.noteControl:SetHandler("OnMouseEnter", OnNoteControlMouseEnter)
    self.noteControl:SetHandler("OnMouseExit", OnRowChildMouseExit)
    self.inputGroup:Add(self.noteControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)

    self.control:SetHandler("OnUpdate", function(_, currentTime) self:OnUpdate(currentTime) end)
end

function ZO_GroupFinder_ApplicationsListRow:OnUpdate(currentTime)
    if self.data then
        if self.data:IsInPendingState() then
            self.expiresLabel:SetText(GetString(SI_GROUP_FINDER_APPLICATION_PENDING))
        else
            self.expiresLabel:SetText(ZO_FormatTimeLargestTwo(self.data:GetTimeRemainingSeconds(), TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL))
        end
    end
end

function ZO_GroupFinder_ApplicationsListRow:AttachToList(list)
    self.list = list
end

function ZO_GroupFinder_ApplicationsListRow:AssignApplicationData(data)
    self.data = data
    self.characterNameLabel:SetText(ZO_FormatUserFacingCharacterName(data:GetCharacterName()))

    self.classIcon:SetTexture(data:GetClassIcon())

    local level = data:GetLevel()
    local championPoints = data:GetChampionPoints()
    self.levelLabel:SetText(ZO_GetLevelOrChampionPointsStringNoIcon(level, championPoints))
    self.championIcon:SetHidden(championPoints == 0)

    self:SetupRoleControl(LFG_ROLE_DPS)
    self:SetupRoleControl(LFG_ROLE_HEAL)
    self:SetupRoleControl(LFG_ROLE_TANK)

    --Only show the note if there is one
    local note = data:GetNote()
    self.noteControl:SetHidden(note == "")
end

do
    local ROLE_SELECTION_TO_ICON = 
    {
        [LFG_ROLE_TANK] =
        {
            [true] = "EsoUI/Art/LFG/LFG_tank_down.dds",
            [false] = "EsoUI/Art/LFG/LFG_tank_disabled.dds",
        },
        [LFG_ROLE_HEAL] =
        {
            [true] = "EsoUI/Art/LFG/LFG_healer_down.dds",
            [false] = "EsoUI/Art/LFG/LFG_healer_disabled.dds",
        },
        [LFG_ROLE_DPS] =
        {
            [true] = "EsoUI/Art/LFG/LFG_dps_down.dds",
            [false] = "EsoUI/Art/LFG/LFG_dps_disabled.dds",
        },
    }

    function ZO_GroupFinder_ApplicationsListRow:SetupRoleControl(roleType)
        local assignedRole = self.data:GetRole()
        local enabled = roleType == assignedRole
        self.roleControls[roleType]:SetTexture(ROLE_SELECTION_TO_ICON[roleType][enabled])
    end
end

function ZO_GroupFinder_ApplicationsListRow:EnterRow()
    self.list:Row_OnMouseEnter(self.control)
end

function ZO_GroupFinder_ApplicationsListRow:ExitRow()
    self.list:Row_OnMouseExit(self.control)
end

function ZO_GroupFinder_ApplicationsListRow:OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        ClearMenu()
        if self.data then
            if not self.data:IsInPendingState() then
                AddMenuItem(GetString(SI_GROUP_FINDER_ACCEPT_APPLICATION), function() RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_APPROVE, self.data:GetCharacterId()) end)
                AddMenuItem(GetString(SI_GROUP_FINDER_REJECT_APPLICATION), function() RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_REJECT, self.data:GetCharacterId()) end)
            end
            if IsChatSystemAvailableForCurrentPlatform() then
                AddMenuItem(GetString(SI_SOCIAL_LIST_SEND_MESSAGE), function() StartChatInput("", CHAT_CHANNEL_WHISPER, self.data:GetDisplayName()) end)
            end
            AddMenuItem(GetString(SI_FRIEND_MENU_IGNORE), function() AddIgnore(self.data:GetDisplayName()) end)
            self.list:ShowMenu(control)
        end
    end
end

function ZO_GroupFinder_ApplicationsListRow:OnMouseDoubleClick(control, button)
    self.list:Row_OnMouseDoubleClick(self.control, button)
end

--------------
--Global XML
---------------

function ZO_GroupFinder_ApplicationsListRow_Keyboard_OnInitialized(control)
    ZO_GroupFinder_ApplicationsListRow:New(control)
end

function ZO_RemoveGroupListingButton_OnClicked(control)
    RequestRemoveGroupListing()
end