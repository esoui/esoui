----------------------------------
--Group List Keyboard
----------------------------------

local ZO_GroupList_Keyboard = ZO_Object.MultiSubclass(ZO_GroupList_Base, ZO_SortFilterList)

local GROUP_DATA = 1

function ZO_GroupList_Keyboard:New(control)
    local manager = ZO_Object.New(self)
    manager:Initialize(control)
    return manager
end

function ZO_GroupList_Keyboard:Initialize(control)
    self.noGroupRow = control:GetNamedChild("NoGroupRow")

    ZO_SortFilterList.InitializeSortFilterList(self, control)
    ZO_GroupList_Base.Initialize(self, control)

    self:InitializeKeybindDescriptors()

    control:SetHandler("OnEffectivelyHidden", function() self:OnEffectivelyHidden() end)

    self.memberCount = GetControl(control, "GroupMembersCount")

    ZO_ScrollList_Initialize(self.list)
    ZO_ScrollList_AddDataType(self.list, GROUP_DATA, "ZO_GroupListRow", 30, function(control, data) self:SetupGroupEntry(control, data) end)

    self.headers = {}
    local headersParent = GetControl(control, "Headers")
    local numHeaders = headersParent:GetNumChildren()
    for i = 1, numHeaders do
        self.headers[i] = headersParent:GetChild(i)
    end

    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
    
    GROUP_LIST_SCENE = ZO_Scene:New("groupList", SCENE_MANAGER)
    GROUP_LIST_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
                                                            if(newState == SCENE_SHOWING) then
                                                                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
                                                            elseif(newState == SCENE_SHOWN) then
                                                                self:RefreshData()
                                                            elseif(newState == SCENE_HIDDEN) then
                                                                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                                                            end
                                                        end)

    self.activeColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    self.inactiveColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
    GROUP_LIST_MANAGER:AddList(self)

    self:InitializeEvents()
end

function ZO_GroupList_Keyboard:InitializeEvents()
    local function OnGroupSharedUpdate()
        local isGrouped = IsUnitGrouped("player")

        if self.isGrouped ~= isGrouped then
            self.isGrouped = isGrouped

            if not isGrouped and GROUP_LIST_SCENE:IsShowing() then
                MAIN_MENU_KEYBOARD:ShowScene("groupingToolsKeyboard")
            end
        end
    end

    local function OnGroupMemberJoined()
        PlaySound(SOUNDS.GROUP_JOIN)
        OnGroupSharedUpdate()
    end

    local control = self.control
    control:RegisterForEvent(EVENT_GROUP_UPDATE, OnGroupSharedUpdate)
    control:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
    control:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, OnGroupSharedUpdate)
end

function ZO_GroupList_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        -- Invite to Group
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            name = GetString(SI_GROUP_WINDOW_INVITE_PLAYER),
            keybind = "UI_SHORTCUT_PRIMARY",
        
            callback = function()
                ZO_Dialogs_ShowDialog("GROUP_INVITE")
            end,

            visible = function()
                return self.groupSize == 0 or (self.playerIsLeader and self.groupSize < GROUP_SIZE_MAX)
            end
        },

        -- Whisper
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            name = GetString(SI_SOCIAL_LIST_PANEL_WHISPER),
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                StartChatInput("", CHAT_CHANNEL_WHISPER, data.characterName)
            end,

            visible = function()
                if(self.mouseOverRow and IsChatSystemAvailableForCurrentPlatform()) then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    return not data.isPlayer and data.characterName and data.online
                end
                return false
            end
        },

        -- Leave Group
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            name = GetString(SI_GROUP_LEAVE),
            keybind = "UI_SHORTCUT_NEGATIVE",
        
            callback = function()
                ZO_Dialogs_ShowDialog("GROUP_LEAVE_DIALOG")
            end,

            visible = function()
                return self.groupSize and self.groupSize > 0
            end
        },
    }
end

function ZO_GroupList_Keyboard:OnEffectivelyHidden()
    ZO_Dialogs_ReleaseDialog("GROUP_INVITE")
end

function ZO_GroupList_Keyboard:GroupListRow_OnMouseUp(control, button, upInside)
    if(button == MOUSE_BUTTON_INDEX_RIGHT and upInside) then
        ClearMenu()

        local data = ZO_ScrollList_GetData(control)
        if data then
            if data.isPlayer then
                AddMenuItem(GetString(SI_GROUP_LIST_MENU_LEAVE_GROUP), function() GroupLeave() end)
            elseif data.online then
                if IsChatSystemAvailableForCurrentPlatform() then
                    AddMenuItem(GetString(SI_SOCIAL_LIST_PANEL_WHISPER), function() StartChatInput("", CHAT_CHANNEL_WHISPER, data.characterName) end)
                end
                AddMenuItem(GetString(SI_SOCIAL_MENU_JUMP_TO_PLAYER), function() JumpToGroupMember(data.characterName) end)
            end

            if(self.playerIsLeader) then
                if data.isPlayer then
                    AddMenuItem(GetString(SI_GROUP_LIST_MENU_DISBAND_GROUP), function() ZO_Dialogs_ShowDialog("GROUP_DISBAND_DIALOG") end)
                else
                    if data.online then
                        AddMenuItem(GetString(SI_GROUP_LIST_MENU_PROMOTE_TO_LEADER), function() GroupPromote(data.unitTag) end)
                    end
                    AddMenuItem(GetString(SI_GROUP_LIST_MENU_KICK_FROM_GROUP), function() GroupKick(data.unitTag) end)
                end
            end

            self:ShowMenu(control)
        end
    end
end

function ZO_GroupList_Keyboard:Status_OnMouseEnter(control)
    local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)

    if(data.leader) then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
        SetTooltipText(InformationTooltip, GetString(SI_GROUP_LIST_PANEL_LEADER_TOOLTIP))
    end

    self:EnterRow(row)
end

function ZO_GroupList_Keyboard:Status_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

function ZO_GroupList_Keyboard:Role_OnMouseEnter(control)
    local row = control:GetParent()

    if(control.role) then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
        SetTooltipText(InformationTooltip, GetString("SI_LFGROLE", control.role))
    end

    self:EnterRow(row)
end

function ZO_GroupList_Keyboard:Role_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

function ZO_GroupList_Keyboard:UpdateHeaders(active)
    local color = active and self.activeColor or self.inactiveColor
    for i = 1, #self.headers do
        local header = self.headers[i]
        header:SetColor(color:UnpackRGBA())
    end
end

--ZO_GroupList_Base overrides
local ROLE_SELECTION_TO_ICON = {
    [LFG_ROLE_TANK] = {
        [true] = "EsoUI/Art/LFG/LFG_tank_down.dds",
        [false] = "EsoUI/Art/LFG/LFG_tank_disabled.dds",
    },
    [LFG_ROLE_HEAL] = {
        [true] = "EsoUI/Art/LFG/LFG_healer_down.dds",
        [false] = "EsoUI/Art/LFG/LFG_healer_disabled.dds",
    },
    [LFG_ROLE_DPS] = {
        [true] = "EsoUI/Art/LFG/LFG_dps_down.dds",
        [false] = "EsoUI/Art/LFG/LFG_dps_disabled.dds",
    },
}

function ZO_GroupList_Keyboard:SetupGroupEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)
    ZO_SocialList_SharedSocialSetup(control, data)

    local hidden = (data.index % 2) == 0
    control.bg:SetHidden(hidden)

    data.control = control

    control.leaderIcon:SetHidden(not data.leader)
    control.characterNameLabel:SetText(zo_strformat(SI_GROUP_LIST_PANEL_CHARACTER_NAME, data.index, data.rawCharacterName))

    control.roleDPS:SetTexture(ROLE_SELECTION_TO_ICON[LFG_ROLE_DPS][data.isDps])
    control.roleHeal:SetTexture(ROLE_SELECTION_TO_ICON[LFG_ROLE_HEAL][data.isHeal])
    control.roleTank:SetTexture(ROLE_SELECTION_TO_ICON[LFG_ROLE_TANK][data.isTank])
end

--ZO_SortFilterList overrides
function ZO_GroupList_Keyboard:BuildMasterList()
    --Actual master list is managed by GROUP_LIST_MANAGER, but we have some other things we want to update when appropriate

    self.playerIsLeader = IsUnitGroupLeader("player")
    self.groupSize = GetGroupSize()

    self.noGroupRow:SetHidden(self.groupSize > 0)
    self:UpdateHeaders(self.groupSize > 0)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GroupList_Keyboard:FilterScrollList()
    -- No real filtering...just show everything in the master list
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, data in ipairs(GROUP_LIST_MANAGER:GetMasterList()) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(GROUP_DATA, data))
    end
end

function ZO_GroupList_Keyboard:GetRowColors(data, mouseIsOver)
    return ZO_SocialList_GetRowColors(data, mouseIsOver)
end

function ZO_GroupList_Keyboard:RefreshData()
    if not self.control:IsHidden() then
        ZO_SortFilterList.RefreshData(self)
    end
end


--Global XML
---------------

function ZO_GroupListRow_OnMouseEnter(control)
    GROUP_LIST:Row_OnMouseEnter(control)
end

function ZO_GroupListRow_OnMouseExit(control)
    GROUP_LIST:Row_OnMouseExit(control)
end

function ZO_GroupListRow_OnMouseUp(control, button, upInside)
    GROUP_LIST:GroupListRow_OnMouseUp(control, button, upInside)
end

function ZO_GroupListRowClass_OnMouseEnter(control)
    ZO_SocialListKeyboard.Class_OnMouseEnter(GROUP_LIST, control)
end

function ZO_GroupListRowClass_OnMouseExit(control)
    ZO_SocialListKeyboard.Class_OnMouseExit(GROUP_LIST, control)
end

function ZO_GroupListRowVeteran_OnMouseEnter(control)
    ZO_SocialListKeyboard.Veteran_OnMouseEnter(GROUP_LIST, control)
end

function ZO_GroupListRowVeteran_OnMouseExit(control)
    ZO_SocialListKeyboard.Veteran_OnMouseExit(GROUP_LIST, control)
end

function ZO_GroupListRowStatus_OnMouseEnter(control)
    GROUP_LIST:Status_OnMouseEnter(control)
end

function ZO_GroupListRowStatus_OnMouseExit(control)
    GROUP_LIST:Status_OnMouseExit(control)
end

function ZO_GroupListRole_OnMouseEnter(control)
    GROUP_LIST:Role_OnMouseEnter(control)
end

function ZO_GroupListRole_OnMouseExit(control)
    GROUP_LIST:Role_OnMouseExit(control)
end

function ZO_GroupList_OnInitialized(self)
    GROUP_LIST = ZO_GroupList_Keyboard:New(self)
end
