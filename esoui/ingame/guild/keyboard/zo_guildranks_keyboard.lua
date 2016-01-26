local PLAY_SELECT_RANK_SOUND = true
local ADD_RANK_DIALOG_NAME = "GUILD_ADD_RANK"

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
    if(self:GetIconIndex() ~= iconIndex) then
        ZO_GuildRank_Shared.SetIconIndex(self, iconIndex)
        self:SetSelected(GUILD_RANKS:GetSelectedRankId() == self.id)
    end
end

function ZO_GuildRank_Keyboard:GetHeaderControl()
    return self.control
end

function ZO_GuildRank_Keyboard:RefreshAnchor(prevRank)
    if(prevRank) then
        self.control:SetAnchor(TOPLEFT, prevRank:GetHeaderControl(), BOTTOMLEFT, 0, -10)
    else
        self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    end
end

function ZO_GuildRank_Keyboard:SetSelected(selected)
    if(selected) then
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

local SET_CHECK = 1
local SET_ICON = 2

local ROW_HEIGHT = 30
local COLUMN_WIDTH = 300

function ZO_GuildRanks_Keyboard:New(...)
    local guildRanks = ZO_GuildRanks_Shared.New(self, ...)
    guildRanks:Initialize(...)
    return guildRanks
end

local function OnBlockingSceneActivated()
    GUILD_RANKS:AttemptSaveAndExit()
end

function ZO_GuildRanks_Keyboard:Initialize(control)
    self.rankNameEditBG = GetControl(control, "RankNameEditBG")
    self.rankNameDisplay = GetControl(control, "RankNameDisplay")
    self.rankNameEdit = GetControl(control, "RankNameEdit")
    self.rankNameEdit:SetMaxInputChars(MAX_GUILD_RANK_NAME_LENGTH)

    self.permissionsContainer = GetControl(control, "Permissions")
    self.iconsContainer = GetControl(control, "Icons")
    local paneScrollChild = GetControl(control, "PaneScrollChild")
    self.permissionsContainer:SetParent(paneScrollChild)
    self.iconsContainer:SetParent(paneScrollChild)
    self.iconsContainer:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)

    self.iconHighlight = self.iconsContainer:GetNamedChild("Highlight")
    self.headerPool = ZO_ControlPool:New("ZO_RankHeader", GetControl(control, "List"), "Header")
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
    self:CreatePermissions()
    self:CreateIconSelectors()

    GUILD_RANKS_SCENE = ZO_Scene:New("guildRanks", SCENE_MANAGER)
    GUILD_RANKS_SCENE:RegisterCallback("StateChange",   function(oldState, newState)
                                                            if(newState == SCENE_SHOWING) then
                                                                MAIN_MENU_MANAGER:SetBlockingScene("guildRanks", OnBlockingSceneActivated)      
                                                                KEYBIND_STRIP:RemoveDefaultExit()                                                          
                                                                KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
                                                            elseif(newState == SCENE_HIDING) then
                                                                self:StopDragging()
                                                            elseif(newState == SCENE_HIDDEN) then
                                                                self:Cancel()                                                                
                                                                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
                                                                KEYBIND_STRIP:RestoreDefaultExit()
                                                                -- Blocking scene is cleared in ConfirmExit() to prevent the scene manager from exiting then re-entering the main menu
                                                            end
                                                        end)
end

function ZO_GuildRanks_Keyboard:InitializeKeybindDescriptor()
    self.keybindStripDescriptor =
    {
        --Cancel
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_GUILD_RANKS_CANCEL),
            keybind = "UI_SHORTCUT_NEGATIVE",
        
            callback = function()
                self:Cancel()
            end,

            visible = function()                
                return self.canSave
            end,
        },

        -- Save
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_GUILD_RANKS_SAVE),
            keybind = "UI_SHORTCUT_PRIMARY",
        
            callback = function()
                self:Save()
            end,

            visible = function()                
                return self.canSave
            end,
        },

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
                if(self:IsRankOccupied(selectedRank)) then
                    ZO_Dialogs_ShowDialog("GUILD_REMOVE_RANK_WARNING", {rankId = self.selectedRankId})
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
            ethereal = true,
            callback = function()
                self:AttemptSaveAndExit()
            end,
        },
    }
end

function ZO_GuildRanks_Keyboard:Save()
    if(self.canSave) then
        if(ZO_GuildRanks_Shared.Save(self)) then
            self.savePending = true
            self.savePendingGuildId = self.guildId
            self:RefreshSaveEnabled()
		    PlaySound(SOUNDS.GUILD_RANK_SAVED)
        end
    end
end

local HEADER_SPACING_OFFSET_Y = 30

function ZO_GuildRanks_Keyboard:CreatePermissions()
    local prevRow
    local permissionId = 0

    self.permissionControls = {}

    for rowIndex = 1, #ZO_GUILD_RANKS_PERMISSIONS do
        local rowInfo = ZO_GUILD_RANKS_PERMISSIONS[rowIndex]
        for columnIndex = 1, 2 do
            if(rowInfo[columnIndex] ~= nil) then
                permissionId = permissionId + 1
                local permission = rowInfo[columnIndex]
                local permissionControl = CreateControlFromVirtual("ZO_GuildRanksPermission", self.permissionsContainer, "ZO_GuildPermission", permissionId)
                permissionControl.permission = permission
                permissionControl:SetAnchor(TOPLEFT, nil, TOPLEFT, (columnIndex - 1) * COLUMN_WIDTH, (rowIndex - 1) * ROW_HEIGHT + HEADER_SPACING_OFFSET_Y)
                table.insert(self.permissionControls, permissionControl)

                local check = GetControl(permissionControl, "Check")
                ZO_CheckButton_SetLabelText(check, GetString("SI_GUILDPERMISSION", permission))
            end
        end
    end
end

local ICON_SELECTORS_PER_ROW = 10
local ICON_SELECTORS_PADDING = 8
local ICON_SELECTOR_SIZE = 48
local ICONS_OFFSET_X = 10
local ICONS_OFFSET_Y = 35

function ZO_GuildRanks_Keyboard:CreateIconSelectors()
    self.iconSelectorControls = {}
    local iconSelectorId = 0
    for i = 1, GetNumGuildRankIcons() do
        local iconSelector = CreateControlFromVirtual("ZO_GuildRanksIconSelector", self.iconsContainer, "ZO_GuildRankIconSelector", iconSelectorId)
        iconSelector.iconIndex = i
        local row = zo_floor((i - 1) / ICON_SELECTORS_PER_ROW)
        local col = (i - 1) % ICON_SELECTORS_PER_ROW
        iconSelector:SetAnchor(TOPLEFT, nil, TOPLEFT, col * (ICON_SELECTOR_SIZE + ICON_SELECTORS_PADDING) + ICONS_OFFSET_X, row * (ICON_SELECTOR_SIZE + ICON_SELECTORS_PADDING) + ICONS_OFFSET_Y)
        iconSelector:GetNamedChild("Icon"):SetTexture(GetGuildRankLargeIcon(i))
        iconSelectorId = iconSelectorId + 1
        table.insert(self.iconSelectorControls, iconSelector)
    end
end

function ZO_GuildRanks_Keyboard:SetGuildId(guildId)
    ZO_GuildRanks_Shared.SetGuildId(self, guildId)

    self:RefreshRanksFromGuildData()
end

function ZO_GuildRanks_Keyboard:RefreshRanksFromGuildData()
    if(self.guildId) then
        self.headerPool:ReleaseAllObjects()
        self.ranks = {}
    
        local firstRankId
        for i = 1, GetNumGuildRanks(self.guildId) do
            local header, key = self.headerPool:AcquireObject()
            local rank = ZO_GuildRank_Keyboard:New(header, key, self.guildId, i)
            self.ranks[i] = rank
            rank:SetSelected(false)

            if(not firstRankId) then
                firstRankId = rank.id
            end
        end

        self:RefreshRankHeaderLayout()
        self:RefreshAddRank()

        local lastSelectedRankId = self.selectedRankId
        self.selectedRankId = nil
        if(not lastSelectedRankId or not self:SelectRank(lastSelectedRankId)) then
            self:SelectRank(firstRankId)
        end
    end
end

function ZO_GuildRanks_Keyboard:RefreshRankIndices()
    for i = 1, #self.ranks do
        local rank = self.ranks[i]
        for j = 1, GetNumGuildRanks(self.guildId) do
            local rankId = GetGuildRankId(self.guildId, j)
            if(rank.id == rankId) then
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
    if(rank) then
        if(self.selectedRankId == rankId) then
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
    if(DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT)) then
        if(rank:IsNewRank() or not IsGuildRankGuildMaster(self.guildId, rank.index)) then
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
    if(rank and rankIndex and targetIndex ~= rankIndex) then
        local tempRank = self.ranks[targetIndex]
        self.ranks[targetIndex] = rank
        self.ranks[rankIndex] = tempRank
        self:RefreshRankHeaderLayout()
        self:RefreshSaveEnabled()
		PlaySound(SOUNDS.GUILD_RANK_REORDERED)
    end
end

function ZO_GuildRanks_Keyboard:StopDragging()
    if(self.draggingRankId) then
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
    if(self.selectedRankId ~= rankId) then
        if(self.selectedRankId) then
            local unselectRank = self:GetRankById(self.selectedRankId)
            if(unselectRank) then
                unselectRank:SetSelected(false)
                if(unselectRank.name == "") then
                    unselectRank:SetName(unselectRank.lastGoodName)
                end
            end
        end

        self.selectedRankId = rankId

        local selectRank = self:GetRankById(rankId)
        if(selectRank) then
            selectRank:SetSelected(true)

            -- Play sound if as a result of a click
            if(playSound) then
                PlaySound(SOUNDS.GUILD_RANK_SELECTED)
            end

            self:ClearPermissionIcons()
            self:RefreshRankInfo()
            self:RefreshRemoveRank()

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

    if(enabled) then
        self.iconsContainer:SetHidden(false)
        self.permissionsContainer:SetAnchor(TOPLEFT, self.iconsContainer, BOTTOMLEFT, 0, 19)
    else
        self.iconsContainer:SetHidden(true)
        self.permissionsContainer:SetAnchor(TOPLEFT, self.iconsContainer, TOPLEFT, 0, 0)
        if(self:NeedsSave()) then
            self:Cancel()
        end
        ZO_Dialogs_ReleaseDialog("GUILD_ADD_RANK")
    end
    self:RefreshSaveEnabled()
end

function ZO_GuildRanks_Keyboard:RefreshAddRank()
    self.addRankEnabled = #self.ranks < MAX_GUILD_RANKS and DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT)
    self.addRankHeader:SetHidden(not self.addRankEnabled)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRanks_Keyboard:RefreshRemoveRank()
    self.removeRankEnabled = false
    if(DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT)) then
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
    self:RefreshPermissions(rank, SET_CHECK)
    self:RefreshEditPermissions()
    self:RefreshIconSelectors()
end

function ZO_GuildRanks_Keyboard:RefreshRankIcon()
    local rank = self:GetRankById(self.selectedRankId)
    GetControl(self.control, "RankIcon"):SetTexture(GetGuildRankLargeIcon(rank.iconIndex))
end

function ZO_GuildRanks_Keyboard:RefreshPermissions(rank, setType)
    local canPlayerEditPermissions = DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT)
    for i = 1, #self.permissionControls do
        local permissionControl = self.permissionControls[i]
        local permissionEnabled = rank:IsPermissionSet(permissionControl.permission)
        if(setType == SET_CHECK) then
            local checkBox = GetControl(permissionControl, "Check")
            ZO_CheckButton_SetCheckState(checkBox, permissionEnabled)
            local enabled = canPlayerEditPermissions and CanEditGuildRankPermission(rank.id, permissionControl.permission)
            ZO_CheckButton_SetEnableState(checkBox, enabled)
        elseif(setType == SET_ICON) then
            if(permissionEnabled) then
                local iconTexture = GetControl(permissionControl, "Icon")
                iconTexture:SetHidden(false)
                iconTexture:SetTexture(GetGuildRankSmallIcon(rank.iconIndex))
            end
        end
    end
end

function ZO_GuildRanks_Keyboard:ClearPermissionIcons()
    for i = 1, #self.permissionControls do
        local permissionControl = self.permissionControls[i]
        local iconTexture = GetControl(permissionControl, "Icon")
        iconTexture:SetHidden(true)
    end
end

function ZO_GuildRanks_Keyboard:RefreshIconSelectors()
    local selectedRank = self:GetRankById(self.selectedRankId)
    local selectedIconIndex = selectedRank ~= nil and selectedRank.iconIndex or nil
    for i = 1, #self.iconSelectorControls do
        ZO_GuildRanks_Shared_RefreshIcon(self.iconSelectorControls[i], i, selectedIconIndex)
    end
end

function ZO_GuildRanks_Keyboard:GetSelectedRankId()
    return self.selectedRankId
end

function ZO_GuildRanks_Keyboard:DoAllRanksHaveAName()
    for i = 1, #self.ranks do
        local rank = self.ranks[i]
        if(rank.name == "") then
            return false
        end
    end

    return true
end

function ZO_GuildRanks_Keyboard:Cancel()
    self:ClearSavePending()
    self:RefreshRanksFromGuildData()
end

function ZO_GuildRanks_Keyboard:CanSave()
    return not self.savePending and DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_PERMISSION_EDIT) and self:DoAllRanksHaveAName() and self:NeedsSave() 
end

function ZO_GuildRanks_Keyboard:IsCurrentBlockingScene()
    return MAIN_MENU_MANAGER:GetBlockingSceneName() == "guildRanks"
end

function ZO_GuildRanks_Keyboard:AttemptSaveIfBlocking()
    local attemptedSave = false
    
    if self:IsCurrentBlockingScene() then
        self:AttemptSaveAndExit()
        attemptedSave = true
    end
    return attemptedSave
end

function ZO_GuildRanks_Keyboard:AttemptSaveAndExit()
    if (self.canSave) then
        self:ShowRankSaveChangesDialog()
    else
        self:ConfirmExit(false)
    end
end

function ZO_GuildRanks_Keyboard:ConfirmExit(applyChanges)
    if applyChanges then
        self:Save()
    else
        self:Cancel()
    end

    if not MAIN_MENU_MANAGER:HasBlockingSceneNextScene() and not self.pendingGuildChange then
        SCENE_MANAGER:HideCurrentScene()
    end
    self.pendingGuildChange = nil
    MAIN_MENU_MANAGER:ClearBlockingScene(OnBlockingSceneActivated)
end

function ZO_GuildRanks_Keyboard:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
end

function ZO_GuildRanks_Keyboard:RefreshSaveEnabled()
    self.canSave = self:CanSave()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRanks_Keyboard:ShowRankSaveChangesDialog(dialogCallback, dialogParams)
    ZO_Dialogs_ShowDialog("GUILD_RANK_SAVE_CHANGES", { callback = dialogCallback, params = dialogParams })
end

function ZO_GuildRanks_Keyboard:ChangeSelectedGuild(dialogCallback, dialogParams)
    local guildEntry = dialogParams.entry

    self.pendingGuildChange = self.guildId ~= guildEntry.guildId

    if self.pendingGuildChange then
        self:ShowRankSaveChangesDialog(dialogCallback, dialogParams)
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
        if(result ~= SOCIAL_RESULT_NO_ERROR) then
            self:ClearSavePending()
            self:Cancel()
        end
    end
end

function ZO_GuildRanks_Keyboard:OnGuildRanksChanged(guildId)
    if(self:IsGuildPendingChanges(guildId) and self.savePending) then
        self:ClearSavePending()
        self:RefreshRankIndices()
        self:RefreshSaveEnabled()
    elseif (self:MatchesGuild(guildId)) then
        self:RefreshRanksFromGuildData()
    end
end

function ZO_GuildRanks_Keyboard:OnGuildRankChanged(rankIndex, guildId)
    if(self:IsGuildPendingChanges(guildId) and self.savePending) then
        self:ClearSavePending()
        self:RefreshSaveEnabled()
    elseif (self:MatchesGuild(guildId)) then
        self:RefreshRanksFromGuildData()
    end
end

function ZO_GuildRanks_Keyboard:OnGuildMemberRankChanged(displayName)
    if(displayName == GetDisplayName()) then
        self:RefreshRankInfo()
    end
end

function ZO_GuildRanks_Keyboard:OnRankNameEdited(name)
    local rank = self:GetRankById(self.selectedRankId)
    rank:SetName(name)
end

--Local XML

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnMouseEnter(header)
    local rankId = header.rank.id
    if(self.selectedRankId ~= rankId) then
        self:RefreshPermissions(header.rank, SET_ICON)
    end
    ZO_IconHeader_OnMouseEnter(header)
end

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnMouseExit(header)
    self:ClearPermissionIcons()
    ZO_IconHeader_OnMouseExit(header)
end

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnMouseDown(header)
    local rankId = header.rank.id
    self:SelectRank(rankId, PLAY_SELECT_RANK_SOUND)
end

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnMouseUp(header)
    self:StopDragging()
end

function ZO_GuildRanks_Keyboard:GuildRankHeader_OnDragStart(header)
    self:StartDragging(header.rank)
end

function ZO_GuildRanks_Keyboard:GuildPermission_OnToggled(permission, checked)
    local rank = self:GetRankById(self.selectedRankId)
    rank:SetPermission(permission , checked)
    GUILD_RANKS:RefreshSaveEnabled()
end

function ZO_GuildRanks_Keyboard:GuildRankIconSelector_OnMouseEnter(control)
    self.iconHighlight:ClearAnchors()
    self.iconHighlight:SetAnchor(CENTER, control, CENTER, 0, 0)
    self.iconHighlight:SetHidden(false)
end

function ZO_GuildRanks_Keyboard:GuildRankIconSelector_OnMouseExit(control)
    self.iconHighlight:SetHidden(true)
end

function ZO_GuildRanks_Keyboard:GuildRankIconSelector_OnMouseClicked(control)
    local selectedRank = self:GetRankById(self.selectedRankId)
    if(selectedRank) then
        selectedRank:SetIconIndex(control.iconIndex)
        self:RefreshSaveEnabled()
        self:RefreshIconSelectors()
        self:RefreshRankIcon()
		PlaySound(SOUNDS.GUILD_RANK_LOGO_SELECTED)
    end
end

function ZO_GuildRanks_Keyboard:GuildRankNameEdit_OnTextChanged(control)
    local selectedRank = self:GetRankById(self.selectedRankId)
    if(selectedRank) then
        selectedRank:SetName(control:GetText())
    end
end

--Global XML

function ZO_GuildRankNameEdit_OnTextChanged(self)
    GUILD_RANKS:GuildRankNameEdit_OnTextChanged(self)
end

function ZO_GuildRankIconSelector_OnMouseEnter(self)
    GUILD_RANKS:GuildRankIconSelector_OnMouseEnter(self)
end

function ZO_GuildRankIconSelector_OnMouseExit(self)
    GUILD_RANKS:GuildRankIconSelector_OnMouseExit(self)
end

function ZO_GuildRankIconSelector_OnMouseClicked(self)
    GUILD_RANKS:GuildRankIconSelector_OnMouseClicked(self)
end

function ZO_GuildPermissionCheck_OnToggled(self, checked)
    GUILD_RANKS:GuildPermission_OnToggled(self:GetParent().permission, checked)
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