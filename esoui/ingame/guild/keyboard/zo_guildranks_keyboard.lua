local PLAY_SELECT_RANK_SOUND = true
local ADD_RANK_DIALOG_NAME = "GUILD_ADD_RANK"

ZO_GUILD_RANK_HEADER_TEMPLATE_KEYBOARD_HEIGHT = 35

--Guild Rank
----------------

local PLAY_SELECT_RANK_SOUND = true
ZO_GuildRank_Keyboard = ZO_GuildRank_Shared:Subclass()

function ZO_GuildRank_Keyboard:New(control, poolKey, guildId, index, customName)
    local rank = ZO_GuildRank_Shared.New(self, GUILD_RANKS, guildId, index, customName)

    rank.control = control
    rank.poolKey = poolKey

    control.rank = rank
    rank.nameLabel = GetControl(control, "Text")
    rank.nameLabel:SetText(rank.name)
    rank:SetSelected(false)

    return rank
end

function ZO_GuildRank_Keyboard:SetIconIndex(iconIndex)
    if self:GetIconIndex() ~= iconIndex then
        ZO_GuildRank_Shared.SetIconIndex(self, iconIndex)
        self:SetSelected(GUILD_RANKS:GetSelectedRankId() == self.id)
    end
end

function ZO_GuildRank_Keyboard:GetHeaderControl()
    return self.control
end

function ZO_GuildRank_Keyboard:RefreshAnchor(prevRank)
    if prevRank then
        self.control:SetAnchor(TOPLEFT, prevRank:GetHeaderControl(), BOTTOMLEFT, 0, -10)
    else
        self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    end
end

function ZO_GuildRank_Keyboard:SetSelected(selected)
    if selected then
        GetControl(self.control, "Icon"):SetTexture(GetGuildRankListDownIcon(self.iconIndex))
    else
        GetControl(self.control, "Icon"):SetTexture(GetGuildRankListUpIcon(self.iconIndex))
    end
    GetControl(self.control, "IconHighlight"):SetTexture(GetGuildRankListHighlightIcon(self.iconIndex))

    ZO_IconHeader_Setup(self.control, selected)
end

function ZO_GuildRank_Keyboard:SetName(name)
    self.nameLabel:SetText(name)
    ZO_GuildRank_Shared.SetName(self, name)
    GUILD_RANKS:RefreshSaveEnabled()
    ZO_IconHeader_UpdateSize(self.control)
end

--Guild Ranks
---------------

local ZO_GuildRanks_Keyboard = ZO_GuildRanks_Shared:Subclass()

function ZO_GuildRanks_Keyboard:New(...)
    local guildRanks = ZO_GuildRanks_Shared.New(self, ...)
    guildRanks:Initialize(...)
    return guildRanks
end

local function OnBlockingSceneActivated()
    GUILD_RANKS:SaveAndExit()
end

function ZO_GuildRanks_Keyboard:Initialize(control)
    ZO_GuildRanks_Shared.Initialize(self, control)

    self.rankIconButtonContainer = self.control:GetNamedChild("RankIconButtonIconContainer")
    self.rankIconDisplayControl = self.control:GetNamedChild("RankIcon")

    -- Initialize grid list object
    local ALWAYS_ANIMATE = true
    self.permissionsContainer = self.control:GetNamedChild("PermissionsContainer")
    local permissionsGridListControl = self.permissionsContainer:GetNamedChild("PermissionsPanel")
    self.permissionsGridListControl = permissionsGridListControl

    self.rankIconPickerButton = self.rankIconButtonContainer:GetNamedChild("Frame")
    self.rankIconIconControl = self.rankIconButtonContainer:GetNamedChild("Icon")

    local function OnRankIconPickerClicked()
        self:OnRankIconPickerClicked()
    end

    ZO_CheckButton_SetCheckState(self.rankIconPickerButton, true)
    ZO_CheckButton_Enable(self.rankIconPickerButton)
    self.rankIconPickerButton:SetHandler("OnClicked", OnRankIconPickerClicked)

    self.templateData =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        entryTemplate = "ZO_GuildRank_PermissionCheckboxTile_Keyboard_Control",
        entryWidth = ZO_GUILD_RANK_PERMISSON_CHECKBOX_KEYBOARD_WIDTH,
        entryHeight = ZO_GUILD_RANK_PERMISSON_CHECKBOX_KEYBOARD_HEIGHT,
        headerTemplate = "ZO_GuildRanks_Keyboard_Header_Template",
        headerHeight = ZO_GUILD_RANK_HEADER_TEMPLATE_KEYBOARD_HEIGHT,
    }

    self:InitializePermissionsGridList()

    self.rankNameEditBG = GetControl(control, "RankNameEditBG")
    self.rankNameDisplay = GetControl(control, "RankNameDisplay")
    self.rankNameEdit = GetControl(control, "RankNameEdit")
    self.rankNameEdit:SetMaxInputChars(MAX_GUILD_RANK_NAME_LENGTH)

    self.headerPool = ZO_ControlPool:New("ZO_RankHeader", control:GetNamedChild("List"), "Header")
    self.headerPool:SetCustomFactoryBehavior(function(header)
                                                    for i = 1, header:GetNumChildren() do
                                                        local child = header:GetChild(i)
                                                        child:SetHandler("OnDragStart", ZO_GuildRankHeaderChild_OnDragStart)
                                                    end
                                                    header.OnMouseEnter = ZO_GuildRankHeader_OnMouseEnter
                                                    header.OnMouseExit = ZO_GuildRankHeader_OnMouseExit
                                                    header.OnMouseUp = ZO_GuildRankHeader_OnMouseUp
                                                    header.OnMouseDown = ZO_GuildRankHeader_OnMouseDown
                                                    ZO_IconHeader_SetMaxLines(header, 1)
                                                    ZO_IconHeader_SetAnimation(header, "RankHeaderAnimation")
                                                end)

    self.addRankHeader = GetControl(control, "AddRank")
    self.addRankHeader:GetNamedChild("Text"):SetText(GetString(SI_GUILD_RANKS_ADD_RANK))
    self.addRankHeader:GetNamedChild("Icon"):SetTexture("EsoUI/Art/Progression/addPoints_up.dds")
    self.addRankHeader:GetNamedChild("IconHighlight"):SetTexture("EsoUI/Art/Progression/addPoints_over.dds")
    ZO_IconHeader_Setup(self.addRankHeader, false)
    self.addRankHeader.OnMouseUp = function()
        self:ShowAddRankDialog(ADD_RANK_DIALOG_NAME)
    end
        
    self.updateRankOrderCallback = function() self:UpdateRankOrder() end

    control:RegisterForEvent(EVENT_GUILD_DATA_LOADED, function() self:OnGuildDataLoaded() end)
    control:RegisterForEvent(EVENT_GUILD_RANKS_CHANGED, function(_, guildId) self:OnGuildRanksChanged(guildId) end)
    control:RegisterForEvent(EVENT_GUILD_RANK_CHANGED, function(_, guildId, rankIndex) self:OnGuildRankChanged(rankIndex, guildId) end)
    control:RegisterForEvent(EVENT_GUILD_MEMBER_RANK_CHANGED, function(_, guildId, displayName) if(self:MatchesGuild(guildId)) then self:OnGuildMemberRankChanged(displayName) end end)
    control:RegisterForEvent(EVENT_SAVE_GUILD_RANKS_RESPONSE, function(_, guildId, result) self:OnSaveGuildRanksResponse(result, guildId) end)

    self:InitializeKeybindDescriptor()
    self:InitializeAddRankDialog(ADD_RANK_DIALOG_NAME)

    GUILD_RANKS_SCENE = ZO_Scene:New("guildRanks", SCENE_MANAGER)
    GUILD_RANKS_SCENE:RegisterCallback("StateChange",   function(oldState, newState)
                                                            if(newState == SCENE_SHOWING) then
                                                                MAIN_MENU_MANAGER:SetBlockingScene("guildRanks", OnBlockingSceneActivated)
                                                                KEYBIND_STRIP:RemoveDefaultExit()
                                                                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
                                                            elseif(newState == SCENE_HIDING) then
                                                                self:StopDragging()
                                                            elseif(newState == SCENE_HIDDEN) then
                                                                self:Save()
                                                                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                                                                KEYBIND_STRIP:RestoreDefaultExit()
                                                                -- Blocking scene is cleared in SaveAndExit() to prevent the scene manager from exiting then re-entering the main menu
                                                            end
                                                        end)
end

function ZO_GuildRanks_Keyboard:OnRankIconPickerClicked()
    ZO_Dialogs_ShowDialog("RankIconPicker")
end

function ZO_GuildRanks_Keyboard:InitializeKeybindDescriptor()
    self.keybindStripDescriptor =
    {
        --Add Rank
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_GUILD_RANKS_ADD_RANK),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                self:ShowAddRankDialog(ADD_RANK_DIALOG_NAME)
            end,

            visible = function()
                return self.addRankEnabled
            end,
        },

        --Remove Rank
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_GUILD_RANKS_REMOVE_RANK),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                local selectedRank = self:GetRankById(self.selectedRankId)
                if self:IsRankOccupied(selectedRank) then
                    ZO_Dialogs_ShowDialog("GUILD_REMOVE_RANK_WARNING", { rankId = self.selectedRankId })
                else
                    self:RemoveRank(self.selectedRankId)
                end
            end,

            visible = function()
                return self.removeRankEnabled
            end,
        },

        -- Custom Exit
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_EXIT_BUTTON),
            keybind = "UI_SHORTCUT_EXIT",
            callback = function()
                self:SaveAndExit()
            end,
        },
    }
end

function ZO_GuildRanks_Keyboard:Save()
    if self.canSave then
        if ZO_GuildRanks_Shared.Save(self) then
            self.savePending = true
            self.savePendingGuildId = self.guildId
            self:RefreshSaveEnabled()
            PlaySound(SOUNDS.GUILD_RANK_SAVED)
        end
    end
end

function ZO_GuildRanks_Keyboard:OnPermissionGridListEntryToggle(...)
    self:GetRankById(self.selectedRankId):SetPermission(...)
    self.permissionsGridList:RefreshGridList()
end

function ZO_GuildRanks_Keyboard:GetSelectedRank()
    return self:GetRankById(self.selectedRankId)
end

function ZO_GuildRanks_Keyboard:CreatePermissionDataObject(index, permission)
    local data = ZO_GuildRanks_Shared.CreatePermissionDataObject(self, index, permission)

    data.mousedOverRank = function()
        return self.mousedOverRank
    end

    return data
end

function ZO_GuildRanks_Keyboard:SetGuildId(guildId)
    ZO_GuildRanks_Shared.SetGuildId(self, guildId)

    self:RefreshRanksFromGuildData()
    self:RefreshEditPermissions()
end

function ZO_GuildRanks_Keyboard:RefreshRanksFromGuildData()
    if self.guildId then
        self.headerPool:ReleaseAllObjects()
        self.ranks = {}

        local firstRankId
        for i = 1, GetNumGuildRanks(self.guildId) do
            local header, key = self.headerPool:AcquireObject()
            local rank = ZO_GuildRank_Keyboard:New(header, key, self.guildId, i)
            self.ranks[i] = rank
            rank:SetSelected(false)

            if not firstRankId then
                firstRankId = rank.id
            end
        end

        self:RefreshRankHeaderLayout()
        self:RefreshAddRank()

        local lastSelectedRankId = self.selectedRankId
        self.selectedRankId = nil
        if not lastSelectedRankId or not self:SelectRank(lastSelectedRankId) then
            self:SelectRank(firstRankId)
        end

        self.permissionsGridList:RefreshGridList()
    end
end

function ZO_GuildRanks_Keyboard:RefreshRankIndices()
    for i = 1, #self.ranks do
        local rank = self.ranks[i]
        for j = 1, GetNumGuildRanks(self.guildId) do
            local rankId = GetGuildRankId(self.guildId, j)
            if rank.id == rankId then
                rank.index = j
                break
            end
        end
    end
end

function ZO_GuildRanks_Keyboard:AddRank(rankName, copyPermissionsFromRankIndex)
    local header, key = self.headerPool:AcquireObject()
    local rank = ZO_GuildRank_Keyboard:New(header, key, self.guildId, nil, rankName)

    self:InsertRank(rank, copyPermissionsFromRankIndex)

    self:RefreshRankHeaderLayout()
    self:RefreshAddRank()
    self:RefreshSaveEnabled()
    self:SelectRank(rank.id)
end

function ZO_GuildRanks_Keyboard:RemoveRank(rankId)
    local rank, rankIndex = self:GetRankById(rankId)
    if rank then
        if self.selectedRankId == rankId then
            self:SelectRank(nil)
        end
        self.headerPool:ReleaseObject(rank.poolKey)
        table.remove(self.ranks, rankIndex)
        local selectNextIndex = zo_clamp(rankIndex, 1, #self.ranks)
        self:SelectRank(self.ranks[selectNextIndex].id)
        self:RefreshRankHeaderLayout()
        self:RefreshAddRank()
        self:RefreshSaveEnabled()
        PlaySound(SOUNDS.GUILD_RANK_DELETED)
    end
end

function ZO_GuildRanks_Keyboard:StartDragging(rank)
    if DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT) then
        if rank:IsNewRank() or not IsGuildRankGuildMaster(self.guildId, rank.index) then
            self.draggingRankId = rank.id
            WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_RESIZE_NS)
            self.control:SetHandler("OnUpdate", self.updateRankOrderCallback)
        end
    end
end

function ZO_GuildRanks_Keyboard:UpdateRankOrder()
    local nX, nY = NormalizeMousePositionToControl(self.control:GetNamedChild("List"))
    local numRanks = #self.ranks
    local targetIndex = zo_floor(nY * numRanks) + 1
    targetIndex = zo_clamp(targetIndex, 2, numRanks)
    local rank, rankIndex = self:GetRankById(self.draggingRankId)
    if rank and rankIndex and targetIndex ~= rankIndex then
        local tempRank = self.ranks[targetIndex]
        self.ranks[targetIndex] = rank
        self.ranks[rankIndex] = tempRank
        self:RefreshRankHeaderLayout()
        self:RefreshSaveEnabled()
        PlaySound(SOUNDS.GUILD_RANK_REORDERED)
    end
end

function ZO_GuildRanks_Keyboard:StopDragging()
    if self.draggingRankId then
        self.control:SetHandler("OnUpdate", nil)
        self.draggingRankId = nil
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    end
end

function ZO_GuildRanks_Keyboard:RefreshRankHeaderLayout()
    local prevRank
    for i = 1, #self.ranks do
        local rank = self.ranks[i]
        rank:RefreshAnchor(prevRank)
        prevRank = rank
    end
end

function ZO_GuildRanks_Keyboard:SelectRank(rankId, playSound)
    if self.selectedRankId ~= rankId then
        if self.selectedRankId then
            local unselectRank = self:GetRankById(self.selectedRankId)
            if unselectRank then
                unselectRank:SetSelected(false)
                if unselectRank.name == "" then
                    unselectRank:SetName(unselectRank.lastGoodName)
                end
            end
        end

        self.selectedRankId = rankId

        local selectRank = self:GetRankById(rankId)
        if selectRank then
            selectRank:SetSelected(true)

            -- Play sound if as a result of a click
            if playSound then
                PlaySound(SOUNDS.GUILD_RANK_SELECTED)
            end

            self:RefreshRankInfo()
            self:RefreshRemoveRank()

            self.permissionsGridList:RefreshGridList()

            return true
        end
    end

    return false
end

function ZO_GuildRanks_Keyboard:RefreshEditPermissions()
    local enabled = DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT)
    self:RefreshAddRank()
    self:RefreshRemoveRank()
    self.rankNameEditBG:SetHidden(not enabled)
    self.rankNameDisplay:SetHidden(enabled)

    if enabled then
        self.rankIconButtonContainer:SetHidden(false)
        self.rankIconDisplayControl:SetHidden(true)
    else
        self.rankIconButtonContainer:SetHidden(true)
        self.rankIconDisplayControl:SetHidden(false)
        if self:NeedsSave() then
            self:Reset()
        end
        ZO_Dialogs_ReleaseDialog("GUILD_ADD_RANK")
    end
    self:RefreshSaveEnabled()
    self.permissionsGridList:CommitGridList()
end

function ZO_GuildRanks_Keyboard:RefreshAddRank()
    self.addRankEnabled = #self.ranks < MAX_GUILD_RANKS and DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT)
    self.addRankHeader:SetHidden(not self.addRankEnabled)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRanks_Keyboard:RefreshRemoveRank()
    self.removeRankEnabled = false
    if DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT) then
        local selectedRank = self:GetRankById(self.selectedRankId)
        --cant remove the guild rank
        self.removeRankEnabled = not (selectedRank.index ~= nil and IsGuildRankGuildMaster(self.guildId, selectedRank.index))
        --cant drop below 2 ranks
        self.removeRankEnabled = self.removeRankEnabled and #self.ranks > 2
    end
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRanks_Keyboard:RefreshRankInfo()
    self:RefreshRankIcon()
    local rank = self:GetRankById(self.selectedRankId)
    self.rankNameDisplay:SetText(rank.name)
    self.rankNameEdit:SetText(rank.name)
end

function ZO_GuildRanks_Keyboard:RefreshRankIcon()
    local rank = self:GetRankById(self.selectedRankId)
    local texture = GetGuildRankLargeIcon(rank.iconIndex)
    self.rankIconIconControl:SetTexture(texture)
    self.rankIconDisplayControl:SetTexture(texture)
end

function ZO_GuildRanks_Keyboard:GetSelectedRankId()
    return self.selectedRankId
end

function ZO_GuildRanks_Keyboard:DoAllRanksHaveAName()
    for i = 1, #self.ranks do
        local rank = self.ranks[i]
        if rank.name == "" then
            return false
        end
    end

    return true
end

function ZO_GuildRanks_Keyboard:Reset()
    self:ClearSavePending()
    self:RefreshRanksFromGuildData()
end

function ZO_GuildRanks_Keyboard:CanSave()
    return not self.savePending and DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT) and self:DoAllRanksHaveAName() and self:NeedsSave()
end

function ZO_GuildRanks_Keyboard:IsCurrentBlockingScene()
    return MAIN_MENU_MANAGER:GetBlockingSceneName() == "guildRanks"
end

function ZO_GuildRanks_Keyboard:SaveIfBlocking()
    if self:IsCurrentBlockingScene() then
        self:SaveAndExit()
    end
end

function ZO_GuildRanks_Keyboard:SaveAndExit()
    self:Save()

    if not MAIN_MENU_MANAGER:HasBlockingSceneNextScene() and not self.pendingGuildChange then
        SCENE_MANAGER:HideCurrentScene()
    end
    self.pendingGuildChange = nil
    MAIN_MENU_MANAGER:ClearBlockingScene(OnBlockingSceneActivated)
end

function ZO_GuildRanks_Keyboard:RefreshSaveEnabled()
    self.canSave = self:CanSave()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRanks_Keyboard:ChangeSelectedGuild(dialogCallback, dialogParams)
    local guildEntry = dialogParams.entry

    self.pendingGuildChange = self.guildId ~= guildEntry.guildId

    if self.pendingGuildChange then
        self:SaveAndExit()
        if dialogCallback then
            dialogCallback(dialogParams)
        end
    end
end

function ZO_GuildRanks_Keyboard:IsGuildPendingChanges(guildId)
    return guildId == self.savePendingGuildId
end

function ZO_GuildRanks_Keyboard:ClearSavePending()
    self.savePending = false
    self.savePendingGuildId = nil
end

--Events

function ZO_GuildRanks_Keyboard:OnGuildDataLoaded()
    self:RefreshRanksFromGuildData()
end

function ZO_GuildRanks_Keyboard:OnSaveGuildRanksResponse(result, guildId)
    if self:IsGuildPendingChanges(guildId) then
        if result ~= SOCIAL_RESULT_NO_ERROR then
            self:Reset()
        end
    end
end

function ZO_GuildRanks_Keyboard:OnGuildRanksChanged(guildId)
    if self:IsGuildPendingChanges(guildId) and self.savePending then
        self:ClearSavePending()
        self:RefreshRankIndices()
        self:RefreshSaveEnabled()
    elseif self:MatchesGuild(guildId) then
        self:RefreshRanksFromGuildData()
    end
end

function ZO_GuildRanks_Keyboard:OnGuildRankChanged(rankIndex, guildId)
    if self:IsGuildPendingChanges(guildId) and self.savePending then
        self:ClearSavePending()
        self:RefreshSaveEnabled()
    elseif self:MatchesGuild(guildId) then
        self:RefreshRanksFromGuildData()
    end
end

function ZO_GuildRanks_Keyboard:OnGuildMemberRankChanged(displayName)
    if displayName == GetDisplayName() then
        self:RefreshRankInfo()
    end
end

function ZO_GuildRanks_Keyboard:OnRankNameEdited(name)
    local rank = self:GetRankById(self.selectedRankId)
    rank:SetName(name)
end

--Local XML

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnMouseEnter(header)
    ZO_IconHeader_OnMouseEnter(header)

    self.mousedOverRank = header.rank
    self.permissionsGridList:RefreshGridList()
end

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnMouseExit(header)
    self.mousedOverRank = nil
    self.permissionsGridList:RefreshGridList()

    ZO_IconHeader_OnMouseExit(header)
end

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnMouseDown(header)
    local rankId = header.rank.id
    self:RefreshSaveEnabled()
    self:Save()
    self:SelectRank(rankId, PLAY_SELECT_RANK_SOUND)
end

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnMouseUp(header)
    self:StopDragging()
end

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnDragStart(header)
    self:StartDragging(header.rank)
end

function ZO_GuildRanks_Keyboard:GuildRankNameEdit_OnTextChanged(control)
    local selectedRank = self:GetRankById(self.selectedRankId)
    if selectedRank then
        selectedRank:SetName(control:GetText())
    end
end

--Global XML

function ZO_GuildRankNameEdit_OnTextChanged(self)
    GUILD_RANKS:GuildRankNameEdit_OnTextChanged(self)
end

function ZO_GuildRank_RankIconPickerIcon_Keyboard_OnMouseEnter(self)
    if ZO_CheckButton_IsEnabled(self:GetNamedChild("IconContainerFrame")) then
        self:GetNamedChild("Highlight"):SetHidden(false)
    end
end

function ZO_GuildRank_RankIconPickerIcon_Keyboard_OnMouseExit(self)
    self:GetNamedChild("Highlight"):SetHidden(true)
end

function ZO_GuildRankHeaderChild_OnDragStart(self)
    local header = self:GetParent()
    GUILD_RANKS:GuildRankHeader_OnDragStart(header)
end

function ZO_GuildRankHeader_OnMouseDown(self)
    GUILD_RANKS:GuildRankHeader_OnMouseDown(self)
end

function ZO_GuildRankHeader_OnMouseUp(self, upInside)
    GUILD_RANKS:GuildRankHeader_OnMouseUp(self)
end

function ZO_GuildRankHeader_OnMouseEnter(self)
    GUILD_RANKS:GuildRankHeader_OnMouseEnter(self)
end

function ZO_GuildRankHeader_OnMouseExit(self)
    GUILD_RANKS:GuildRankHeader_OnMouseExit(self)
end

function ZO_GuildRanks_OnInitialized(self)
    GUILD_RANKS = ZO_GuildRanks_Keyboard:New(self)
end

function ZO_RankIconPickerDialog_OnInitialized(self)
    self.rankIconPickerGridListControl = self:GetNamedChild("RankIconPickerContainerPanel")

    local function OnRankIconPickedCallback(newIconIndex)
        local selectedRank = GUILD_RANKS:GetRankById(GUILD_RANKS.selectedRankId)
        if selectedRank then
            selectedRank:SetIconIndex(newIconIndex)
            GUILD_RANKS:RefreshSaveEnabled()
            self.rankIconPicker:RefreshGridList()
            GUILD_RANKS:RefreshRankIcon()
            PlaySound(SOUNDS.GUILD_RANK_LOGO_SELECTED)
        end
    end

    self.rankIconPicker = ZO_GuildRankIconPicker_Keyboard:New(self.rankIconPickerGridListControl)
    self.rankIconPicker:SetGetSelectedRankFunction(function() return GUILD_RANKS:GetRankById(GUILD_RANKS.selectedRankId) end)
    self.rankIconPicker:SetRankIconPickedCallback(OnRankIconPickedCallback)

    ZO_Dialogs_RegisterCustomDialog("RankIconPicker",
    {
        title =
        {
            text = SI_GUILD_RANK_ICONS_DIALOG_HEADER,
        },
        mainText =
        {
            text = "",
        },
        setup = function()
            self.rankIconPicker:RefreshGridList()
        end,
        customControl = self,
        buttons =
        {
            [1] =
            {
                control = self:GetNamedChild("Close"),
                text = SI_DIALOG_CLOSE,
            },
        }
    })
end
    