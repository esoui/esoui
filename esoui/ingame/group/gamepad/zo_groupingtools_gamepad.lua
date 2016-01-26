local LFG_BACKGROUND_TEXTURE_SQUARE_DIMENSION = 1024
local LFG_BACKGROUND_TEXTURE_USED_WIDTH = 940
ZO_LFG_BACKGROUND_TEXTURE_COORD_RIGHT = LFG_BACKGROUND_TEXTURE_USED_WIDTH / LFG_BACKGROUND_TEXTURE_SQUARE_DIMENSION
ZO_LFG_BACKGROUND_PADDING = 8
ZO_LFG_BACKGROUND_X = ZO_GAMEPAD_QUADRANT_2_3_WIDTH - 2 * ZO_LFG_BACKGROUND_PADDING
ZO_LFG_BACKGROUND_Y = ZO_LFG_BACKGROUND_X * LFG_BACKGROUND_TEXTURE_SQUARE_DIMENSION / LFG_BACKGROUND_TEXTURE_USED_WIDTH

--------------------------------------------
-- Grouping Tools Manager Gamepad
--------------------------------------------

local ENTRY_TYPE_ROLES = 1
local ENTRY_TYPE_LOCATION = 2

local ACTIVITY_TYPE_TO_LOCATION_ICON = {
    [LFG_ACTIVITY_CYRODIIL]         = "EsoUI/Art/LFG/Gamepad/LFG_activityIcon_cyrodiil.dds",
    [LFG_ACTIVITY_IMPERIAL_CITY]    = "EsoUI/Art/LFG/Gamepad/LFG_activityIcon_imperialCity.dds",
    [LFG_ACTIVITY_DUNGEON]          = "EsoUI/Art/LFG/Gamepad/LFG_activityIcon_normalDungeon.dds",
    [LFG_ACTIVITY_MASTER_DUNGEON]   = "EsoUI/Art/LFG/Gamepad/LFG_activityIcon_veteranDungeon.dds",
    [LFG_ACTIVITY_TRIAL]            = "EsoUI/Art/LFG/Gamepad/LFG_activityIcon_trial.dds",
}


local function CreateListEntry(data, entryType)
    local text = data.name
    local icon = ACTIVITY_TYPE_TO_LOCATION_ICON[data.activityType]
    
    local newEntry = ZO_GamepadEntryData:New(text, icon)
    newEntry:SetLocked(data.isLocked)
    newEntry:SetSelected(data.isSelected)
    newEntry.data = {
        data = data,
        entryType = entryType
    }

    newEntry:SetEnabled(not data.isLocked)
    newEntry:SetIconTintOnSelection(true)

    return newEntry
end

local ZO_GroupingToolsManager_Gamepad = ZO_Object.MultiSubclass(ZO_GroupingToolsManager_Shared, ZO_Gamepad_ParametricList_Screen)


function ZO_GroupingToolsManager_Gamepad:New(control)
    local manager = ZO_Object.New(self)
    manager:Initialize(control)
    return manager
end

function ZO_GroupingToolsManager_Gamepad:Initialize(control)
    ZO_GroupingToolsManager_Shared.Initialize(self, control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    self.selectedActivityIndex = 1
    self.listIndexMemory = {}
    self.locationInfoControl = self.control:GetNamedChild("LocationInfo")

    GAMEPAD_GROUPING_TOOLS_SCENE = ZO_Scene:New("groupingToolsGamepad", SCENE_MANAGER)
    GAMEPAD_GROUPING_TOOLS_SCENE:RegisterCallback("StateChange",    function(oldState, newState)
                                                                if(newState == SCENE_SHOWING) then
                                                                    self:ClearUpdate()
                                                                    ZO_GamepadGenericHeader_Activate(self.header)
                                                                    self:SetActivitySelectorInQueueMode(IsCurrentlySearchingForGroup())

                                                                    SCENE_MANAGER:AddFragment(GAMEPAD_GROUP_ROLES_FRAGMENT)
                                                                elseif(newState == SCENE_HIDDEN) then
                                                                    self.mainList:Deactivate()
                                                                    ZO_GamepadGenericHeader_Deactivate(self.header)

                                                                    SCENE_MANAGER:RemoveFragment(GAMEPAD_GROUP_ROLES_FRAGMENT)
                                                                end

                                                                ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
                                                            end)

    self:InitializeHeader()

    CALLBACK_MANAGER:RegisterCallback("OnGroupStatusChange", function() self:RefreshHeader(self.activeHeaderData) end)
end

function ZO_GroupingToolsManager_Gamepad:InitializeHeader()
    local function OnActivityChanged(newActivityIndex)
        if self.selectedActivityIndex ~= newActivityIndex then
            self.selectedActivityIndex = newActivityIndex
            self:RefreshLocationsList()
        end
    end

    local tabsTable = {}
    for i = 1, #self.activitiesData do
        local data = {
            text = self.activitiesData[i].name,
            callback = function() OnActivityChanged(i) end,
        }
        table.insert(tabsTable, data)
    end

    self.mainHeaderData = {
        tabBarEntries = tabsTable
    }

    self.queueHeaderData = {
        titleText = GetString(SI_GAMEPAD_LFG_QUEUED_ACTIVITIES),
    }

    ZO_GamepadGenericHeader_SetDataLayout(self.header, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)
    ZO_GamepadGenericHeader_Refresh(self.header, self.mainHeaderData)
    self.activeHeaderData = self.mainHeaderData
end

function ZO_GroupingToolsManager_Gamepad:RefreshHeader(headerData)
    ZO_GamepadGenericHeader_Refresh(self.header, headerData)
    GAMEPAD_GENERIC_FOOTER:Refresh(GAMEPAD_GROUP_DATA:GetFooterData())
end

function ZO_GroupingToolsManager_Gamepad:RefreshQueuedActivities()
    self.mainList:Clear()


    --Get the number of requests. For LFM searches, this actually returns the number of separate role requests.
    local numRequests = GetNumLFGRequests()

    --If searching for members, avoid showing an entry for every position we're looking to fill
    if IsUnitGrouped("player") then
        numRequests = 1
    end

    local requestsByActivity = {
        [LFG_ACTIVITY_CYRODIIL] = {},
        [LFG_ACTIVITY_IMPERIAL_CITY] = {},
        [LFG_ACTIVITY_DUNGEON] = {},
        [LFG_ACTIVITY_MASTER_DUNGEON] = {},
        [LFG_ACTIVITY_TRIAL] = {},
    }
    for i = 1, numRequests do
        local activityType, lfgIndex = GetLFGRequestInfo(i)
        table.insert(requestsByActivity[activityType], lfgIndex)
    end

    for activityIndex = 1, #self.activitiesData do
        local activityType = self.activitiesData[activityIndex].type

        if self:IsAllOptionSelected(activityType) then
            local location = self.locationsData[activityType][LFG_LOCATIONS_ALL_INDEX]
            local entryData = CreateListEntry(location, ENTRY_TYPE_LOCATION)
            entryData.header = self.activitiesData[activityIndex].name
            self.mainList:AddEntryWithHeader("ZO_GroupingToolsGamepadLocationEntry", entryData)
        else
            local lfgIndices = requestsByActivity[activityType]
            local isFirstEntry = true

            for index = 1, #lfgIndices do
                local location = self:GetLocationFromLFGIndex(activityType, lfgIndices[index])
                local entryData = CreateListEntry(location, ENTRY_TYPE_LOCATION)

                if isFirstEntry then
                    isFirstEntry = false
                    entryData.header = self.activitiesData[activityIndex].name
                    self.mainList:AddEntryWithHeader("ZO_GroupingToolsGamepadLocationEntry", entryData)
                else
                    self.mainList:AddEntry("ZO_GroupingToolsGamepadLocationEntry", entryData)
                end
            end
        end
    end

    self.mainList:Commit()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GroupingToolsManager_Gamepad:SetActivitySelectorInQueueMode(isSearching)
    if isSearching then
        ZO_GamepadGenericHeader_Deactivate(self.header)
        self:RefreshHeader(self.queueHeaderData)
        self.activeHeaderData = self.queueHeaderData
    else
        ZO_GamepadGenericHeader_Activate(self.header)
        self:RefreshHeader(self.mainHeaderData)
        self.activeHeaderData = self.mainHeaderData
    end
end

local function SetupCustomControlAnchors(control, anchorControl, offsetY)
    control:ClearAnchors()
    local anchor1 = ZO_Anchor:New(TOPLEFT, anchorControl, BOTTOMLEFT)
    local anchor2 = ZO_Anchor:New(TOPRIGHT, anchorControl, BOTTOMRIGHT, 0, offsetY)
    anchor1:AddToControl(control)
    anchor2:AddToControl(control)
end

function ZO_GroupingToolsManager_Gamepad:RefreshLocationInfo(location)
    local isNotAvALocation = location.activityType ~= LFG_ACTIVITY_CYRODIIL and location.activityType ~= LFG_ACTIVITY_IMPERIAL_CITY

    local locationInfoControl = self.locationInfoControl
    locationInfoControl:GetNamedChild("Name"):SetText(location.name)
    locationInfoControl:GetNamedChild("Background"):SetTexture(location.descriptionTextureGamepad)

    local scrollableSection = locationInfoControl:GetNamedChild("ScrollSection"):GetNamedChild("ScrollChild")

    local descriptionControl = scrollableSection:GetNamedChild("Description")
    descriptionControl:SetText(location.description)

    local groupSizeControl = scrollableSection:GetNamedChild("GroupSize")
    if location.groupType then
        groupSizeControl:SetText(zo_strformat(SI_LFG_LOCATION_GROUP_SIZE, ZO_GROUP_TYPE_TO_SIZE[location.groupType]))
    else
        groupSizeControl:SetText("")
    end

    local campaignControl = scrollableSection:GetNamedChild("Campaign")
    campaignControl:SetHidden(isNotAvALocation)

    if not isNotAvALocation then
        campaignControl:GetNamedChild("Text"):SetText(self.currentCampaignName)

        local indicator = campaignControl:GetNamedChild("Indicator")
        local text = campaignControl:GetNamedChild("Text")

        local offsetX = select(5, text:GetAnchor(0))
        text:SetWidth(campaignControl:GetWidth() - indicator:GetTextWidth() - offsetX)

        campaignControl:SetHeight(zo_max(indicator:GetTextHeight(), text:GetTextHeight()))
    end

    local anchorControl = isNotAvALocation and groupSizeControl or campaignControl

    local lockControl = scrollableSection:GetNamedChild("Lock")
    lockControl:SetHidden(not location.isLocked)
    if location.isLocked then
        lockControl:GetNamedChild("Reason"):SetText(location.lockReasonText)

        SetupCustomControlAnchors(lockControl, anchorControl, 48)

        local icon = lockControl:GetNamedChild("Icon")
        local text = lockControl:GetNamedChild("Reason")

        local offsetX = select(5, text:GetAnchor(0))
        text:SetWidth(lockControl:GetWidth() - icon:GetWidth() - offsetX)

        lockControl:SetHeight(zo_max(icon:GetHeight(), text:GetTextHeight()))
    end
end


--ZO_Gamepad_ParametricList_Screen overrides
function ZO_GroupingToolsManager_Gamepad:SetupList(list)
    local function OnSelectionChanged(list, entry, oldData, reachedTarget, index)
        if entry then
            local entryData = entry.data
            local entryType = entryData.entryType

            if entryType == ENTRY_TYPE_ROLES then
                SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
                SCENE_MANAGER:RemoveFragment(GAMEPAD_GROUPING_TOOLS_LOCATION_INFO_FRAGMENT)
                
                SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
                GAMEPAD_GROUP_ROLES_BAR:Activate()

                local activityType = self.activitiesData[self.selectedActivityIndex].type
                self.listIndexMemory[activityType] = index
            else
                GAMEPAD_GROUP_ROLES_BAR:Deactivate()
                SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
                
                SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
                SCENE_MANAGER:AddFragment(GAMEPAD_GROUPING_TOOLS_LOCATION_INFO_FRAGMENT)

                if entryType == ENTRY_TYPE_LOCATION then
                    local locationData = entryData.data
                    self:RefreshLocationInfo(locationData)

                    if not IsCurrentlySearchingForGroup() then
                        self.listIndexMemory[locationData.activityType] = index
                    end
                end
            end

            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    list:AddDataTemplate("ZO_GroupingToolsGamepadLocationEntry", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GroupingToolsGamepadLocationEntry", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    list:SetOnSelectedDataChangedCallback(OnSelectionChanged)

    local listControl = list.control
    local _, point1, relativeTo1, relativePoint1, offsetX1, offsetY1 = listControl:GetAnchor(0)
    local _, point2, relativeTo2, relativePoint2, offsetX2, offsetY2 = listControl:GetAnchor(1)
    listControl:ClearAnchors()
    listControl:SetAnchor(point1, relativeTo1, relativePoint1, offsetX1, offsetY1 + ZO_ROLES_BAR_ADDITIONAL_HEADER_SPACE)
    listControl:SetAnchor(point2, relativeTo2, relativePoint2, offsetX2, offsetY2)

    self.mainList = list
end

function ZO_GroupingToolsManager_Gamepad:InitializeKeybindStripDescriptors()
    local function IsCurrentLocationEditable()
        if IsCurrentlySearchingForGroup() then
            return false
        end

        local data = self.mainList:GetTargetData().data
        local type = data.entryType

        if type == ENTRY_TYPE_ROLES then
            return true
        elseif type == ENTRY_TYPE_LOCATION then
            local locationData = data.data
            return (locationData.isAllOption or not self:IsAllOptionSelected(locationData.activityType)) and not locationData.isLocked
        end

        return false
    end

    local function OnEntryInputSelected()
        local data = self.mainList:GetTargetData().data
        local locationData = data.data
        local type = data.entryType

        if type == ENTRY_TYPE_ROLES then
            local wasRoleSelected = GAMEPAD_GROUP_ROLES_BAR:IsRoleSelected()
            GAMEPAD_GROUP_ROLES_BAR:ToggleSelected()
            local isRoleSelected = GAMEPAD_GROUP_ROLES_BAR:IsRoleSelected()

            if wasRoleSelected ~= isRoleSelected then
                self:ClearUpdate() --no events for updated roles, so update here for locking on no roles selected
            end
        elseif type == ENTRY_TYPE_LOCATION then
            self:ToggleLocationSelected(locationData)
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
    end

    local selectDescriptor = {
        name = GetString(SI_GAMEPAD_SELECT_OPTION),
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = OnEntryInputSelected,
        visible = IsCurrentLocationEditable,
    }
    local toggleQueueDescriptor = {
        name = 
            function()
                local textEnum = (IsCurrentlySearchingForGroup() and SI_LFG_LEAVE_QUEUE) or SI_LFG_JOIN_QUEUE
                return GetString(textEnum)
            end,
        keybind = "UI_SHORTCUT_SECONDARY",
        callback =
            function()
                if IsCurrentlySearchingForGroup() then
                    ZO_Dialogs_ShowGamepadDialog("LFG_LEAVE_QUEUE_CONFIRMATION")
                else
                    self:StartSearch()
                    PlaySound(SOUNDS.DIALOG_ACCEPT)
                end
            end,
        visible =
            function()
                local queueCanBeToggled = IsCurrentlySearchingForGroup() or self:IsAnyLocationSelected()
                local playerCanToggleQueue = IsUnitGroupLeader("player") or not IsUnitGrouped("player")
                return queueCanBeToggled and playerCanToggleQueue
            end,
    }

    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        selectDescriptor,
        toggleQueueDescriptor,
        editRolesDescriptor,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.mainList)
end

function ZO_GroupingToolsManager_Gamepad:PerformUpdate()
    self:RefreshLocationsList()
    self.dirty = false
end


--ZO_GroupingToolsManager_Shared overrides
function ZO_GroupingToolsManager_Gamepad:OnGroupingToolsStatusUpdate(isSearching)
    ZO_GroupingToolsManager_Shared.OnGroupingToolsStatusUpdate(self, isSearching)

    if not self.control:IsControlHidden() then
        self:SetActivitySelectorInQueueMode(isSearching)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GroupingToolsManager_Gamepad:OnLevelUpdate(unitTag)
    ZO_GroupingToolsManager_Shared.OnLevelUpdate(self, unitTag)
end

function ZO_GroupingToolsManager_Gamepad:RefreshLocationsList()
    if not SCENE_MANAGER:IsShowing("groupingToolsGamepad") then
        return
    end

    if IsCurrentlySearchingForGroup() then
        self:RefreshQueuedActivities()
        return
    end

    self.mainList:Clear()

    self.mainList:AddEntry("ZO_GroupingToolsGamepadLocationEntry", CreateListEntry({}, ENTRY_TYPE_ROLES))

    local selectedActivity = self.activitiesData[self.selectedActivityIndex]
    local activityType = selectedActivity.type
    local locationsByActivity = self.locationsData[activityType]

    for i = 1, #locationsByActivity do
        local location = locationsByActivity[i]
        self.mainList:AddEntry("ZO_GroupingToolsGamepadLocationEntry", CreateListEntry(location, ENTRY_TYPE_LOCATION))

        --Don't continue to add individual locations when the all option is selected
        if location.isSelected and location.isAllOption then
            break
        end
    end

    self.mainList:SetSelectedIndex(self.listIndexMemory[activityType] or 2) --don't select roles by default
    self.mainList:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end


--XML Callbacks
function ZO_GroupingToolsGamepad_OnInitialized(self)
    GROUPING_TOOLS_GAMEPAD = ZO_GroupingToolsManager_Gamepad:New(self)
end
