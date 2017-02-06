--Layout consts, defining the widths of the list's columns as provided by design--
ZO_KEYBOARD_GROUP_LIST_PADDING_X = 5
ZO_KEYBOARD_GROUP_LIST_LEADER_WIDTH = 35
ZO_KEYBOARD_GROUP_LIST_NAME_WIDTH = 210 - ZO_KEYBOARD_GROUP_LIST_PADDING_X
ZO_KEYBOARD_GROUP_LIST_LEADER_AND_NAME_WIDTH = ZO_KEYBOARD_GROUP_LIST_LEADER_WIDTH + ZO_KEYBOARD_GROUP_LIST_NAME_WIDTH
ZO_KEYBOARD_GROUP_LIST_ZONE_WIDTH = 130 - ZO_KEYBOARD_GROUP_LIST_PADDING_X
ZO_KEYBOARD_GROUP_LIST_CLASS_WIDTH = 75 - ZO_KEYBOARD_GROUP_LIST_PADDING_X
ZO_KEYBOARD_GROUP_LIST_LEVEL_WIDTH = 80 - ZO_KEYBOARD_GROUP_LIST_PADDING_X
ZO_KEYBOARD_GROUP_LIST_ROLES_WIDTH = 80 - ZO_KEYBOARD_GROUP_LIST_PADDING_X

----------------------------------
--Group List Keyboard
----------------------------------

local ZO_GroupList_Keyboard = ZO_SortFilterList:Subclass()

local GROUP_DATA = 1

function ZO_GroupList_Keyboard:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_GroupList_Keyboard:Initialize(control)
    ZO_SortFilterList.InitializeSortFilterList(self, control)

    self.noGroupRow = control:GetNamedChild("NoGroupRow")

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
    
    GROUP_LIST_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GROUP_LIST_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
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

    local data = 
    {
        name = GetString(SI_MAIN_MENU_GROUP),
        categoryFragment = GROUP_LIST_FRAGMENT,
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_group_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_group_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_group_over.dds",
    }
    GROUP_MENU_KEYBOARD:AddCategory(data)
end

function ZO_GroupList_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
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

        -- Ready Check
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            name = GetString(SI_GROUP_LIST_READY_CHECK_BIND),
            keybind = "UI_SHORTCUT_TERTIARY",
        
            callback = ZO_SendReadyCheck,

            visible = function()
                return self.groupSize and self.groupSize > 0
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
                AddMenuItem(GetString(SI_SOCIAL_MENU_VISIT_HOUSE), function() JumpToHouse(data.displayName) end)
                AddMenuItem(GetString(SI_SOCIAL_MENU_JUMP_TO_PLAYER), function() JumpToGroupMember(data.characterName) end)
            end

            local modicationRequiresVoting = DoesGroupModificationRequireVote()
            if(self.playerIsLeader) then
                if data.isPlayer then
                    if not modicationRequiresVoting then
                        AddMenuItem(GetString(SI_GROUP_LIST_MENU_DISBAND_GROUP), function() ZO_Dialogs_ShowDialog("GROUP_DISBAND_DIALOG") end)
                    end
                else
                    if data.online then
                        AddMenuItem(GetString(SI_GROUP_LIST_MENU_PROMOTE_TO_LEADER), function() GroupPromote(data.unitTag) end)
                    end
                    if not modicationRequiresVoting then
                        AddMenuItem(GetString(SI_GROUP_LIST_MENU_KICK_FROM_GROUP), function() GroupKick(data.unitTag) end)
                    end
                end
            end

            --Cannot vote for yourself
            if modicationRequiresVoting and not data.isPlayer then
                AddMenuItem(GetString(SI_GROUP_LIST_MENU_VOTE_KICK_FROM_GROUP), function() BeginGroupElection(GROUP_ELECTION_TYPE_KICK_MEMBER, ZO_GROUP_ELECTION_DESCRIPTORS.NONE, data.unitTag) end)
            end

            self:ShowMenu(control)
        end
    end
end

function ZO_GroupList_Keyboard:TooltipIfTruncatedLabel_OnMouseEnter(control)
    if control:WasTruncated() then
        InitializeTooltip(InformationTooltip, control, BOTTOM)
        SetTooltipText(InformationTooltip, control:GetText())
    end

    self:EnterRow(control.row)
end

function ZO_GroupList_Keyboard:Status_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control.row)

    if(data.leader) then
        InitializeTooltip(InformationTooltip, control, BOTTOM)
        SetTooltipText(InformationTooltip, GetString(SI_GROUP_LIST_PANEL_LEADER_TOOLTIP))
    end

    self:EnterRow(control.row)
end

function ZO_GroupList_Keyboard:Role_OnMouseEnter(control)
    if(control.role) then
        InitializeTooltip(InformationTooltip, control, BOTTOM)
        SetTooltipText(InformationTooltip, GetString("SI_LFGROLE", control.role))
    end

    self:EnterRow(control.row)
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
    control.characterNameLabel:SetText(zo_strformat(SI_GROUP_LIST_PANEL_CHARACTER_NAME, data.index, ZO_FormatUserFacingCharacterName(data.rawCharacterName)))

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

function ZO_GroupListRowChild_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    GROUP_LIST:Row_OnMouseExit(control.row)
end

function ZO_GroupListRow_OnMouseUp(control, button, upInside)
    GROUP_LIST:GroupListRow_OnMouseUp(control, button, upInside)
end

function ZO_GroupListRowCharacterName_OnMouseEnter(control)
     ZO_SocialListKeyboard.CharacterName_OnMouseEnter(GROUP_LIST, control)
end

function ZO_GroupListRowCharacterName_OnMouseExit(control)
     ZO_SocialListKeyboard.CharacterName_OnMouseExit(GROUP_LIST, control)
end

function ZO_GroupListRowClass_OnMouseEnter(control)
    ZO_SocialListKeyboard.Class_OnMouseEnter(GROUP_LIST, control)
end

function ZO_GroupListRowClass_OnMouseExit(control)
    ZO_SocialListKeyboard.Class_OnMouseExit(GROUP_LIST, control)
end

function ZO_GroupListRowChampion_OnMouseEnter(control)
    ZO_SocialListKeyboard.Champion_OnMouseEnter(GROUP_LIST, control)
end

function ZO_GroupListRowChampion_OnMouseExit(control)
    ZO_SocialListKeyboard.Champion_OnMouseExit(GROUP_LIST, control)
end

function ZO_GroupListRowTooltipIfTruncatedLabel_OnMouseEnter(control)
    GROUP_LIST:TooltipIfTruncatedLabel_OnMouseEnter(control)
end

function ZO_GroupListRowStatus_OnMouseEnter(control)
    GROUP_LIST:Status_OnMouseEnter(control)
end

function ZO_GroupListRole_OnMouseEnter(control)
    GROUP_LIST:Role_OnMouseEnter(control)
end

function ZO_GroupList_OnInitialized(self)
    GROUP_LIST = ZO_GroupList_Keyboard:New(self)
end
