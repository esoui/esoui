--Guild Rank
----------------

ZO_GUILD_RANKS_PERMISSIONS =
{
    {   GUILD_PERMISSION_CHAT,                  GUILD_PERMISSION_SET_MOTD           },
    {   GUILD_PERMISSION_OFFICER_CHAT_WRITE,    GUILD_PERMISSION_DESCRIPTION_EDIT   },
    {   GUILD_PERMISSION_OFFICER_CHAT_READ,     GUILD_PERMISSION_INVITE             },
    {   nil,                                    nil                                 },
    {   GUILD_PERMISSION_CLAIM_AVA_RESOURCE,    GUILD_PERMISSION_NOTE_READ          },
    {   GUILD_PERMISSION_RELEASE_AVA_RESOURCE,  GUILD_PERMISSION_NOTE_EDIT          },
    {   nil,                                    GUILD_PERMISSION_PROMOTE            },
    {   GUILD_PERMISSION_BANK_DEPOSIT,          GUILD_PERMISSION_DEMOTE             },
    {   GUILD_PERMISSION_BANK_WITHDRAW,         GUILD_PERMISSION_REMOVE             },
    {   nil,                                    nil                                 },
    {   GUILD_PERMISSION_BANK_WITHDRAW_GOLD,    nil                                 },
    {   GUILD_PERMISSION_STORE_SELL,            GUILD_PERMISSION_GUILD_KIOSK_BID    },
}

ZO_GuildRank_Shared = ZO_Object:Subclass()

function ZO_GuildRank_Shared:New(guildRanksObject, guildId, index, customName)
    local rank = ZO_Object.New(self)

    rank.guildId = guildId
    rank.index = index

    rank.permissionSet = {}
    if(rank:IsNewRank()) then
        rank.id = guildRanksObject:GetUniqueRankId()
        rank.name = customName
        rank.hasCustomName = true
        rank.iconIndex = guildRanksObject:GetUnusedIconIndex()
        for i = 1, GetNumGuildPermissions() do
            rank.permissionSet[i] = false
        end
    else
        rank.id = GetGuildRankId(guildId, index)
        rank.name = GetFinalGuildRankName(guildId, index)
        rank.hasCustomName = GetGuildRankCustomName(guildId, index) ~= ""
        rank.iconIndex = GetGuildRankIconIndex(guildId, index)
        for i = 1, GetNumGuildPermissions() do
            rank.permissionSet[i] = DoesGuildRankHavePermission(guildId, index, i)
        end
    end

    rank.lastGoodName = rank.name

    return rank
end

function ZO_GuildRank_Shared:SetName(name)
    if name ~= self.name then
        self.name = name
        local defaultName = GetDefaultGuildRankName(self.guildId, self.index)
        if(defaultName ~= "") then
            if(defaultName == name) then
                self.hasCustomName = false
            else
                self.hasCustomName = true
            end
        else
            self.hasCustomName = true
        end
    end
end

function ZO_GuildRank_Shared:GetName()
    return self.name
end

function ZO_GuildRank_Shared:GetRankId()
    return self.id
end

function ZO_GuildRank_Shared:GetIconIndex()
    return self.iconIndex
end

function ZO_GuildRank_Shared:SetIconIndex(index)
    self.iconIndex = index
end

function ZO_GuildRank_Shared:GetSmallIcon()
    return GetGuildRankSmallIcon(self.iconIndex)
end

function ZO_GuildRank_Shared:GetLargeIcon()
    return GetGuildRankLargeIcon(self.iconIndex)
end

function ZO_GuildRank_Shared:IsPermissionSet(permission)
    return self.permissionSet[permission]
end

function ZO_GuildRank_Shared:SetPermission(permission, enabled)
    self.permissionSet[permission] = enabled
end

function ZO_GuildRank_Shared:GetPermissions()
    local permissions = 0
    for i = 1, #self.permissionSet do
        permissions = ComposeGuildRankPermissions(permissions, i, self.permissionSet[i])
    end
    return permissions
end

function ZO_GuildRank_Shared:GetSaveName()
    --we only save custom names
    if(self.hasCustomName) then
        return self.name
    else
        return ""
    end
end

function ZO_GuildRank_Shared:IsNewRank()
    if(self.index == nil) then
        return true
    end
end

function ZO_GuildRank_Shared:NeedsSave()
    if(self:IsNewRank()) then
        return true
    end

    if(self.iconIndex ~= GetGuildRankIconIndex(self.guildId, self.index)) then
        return true
    end

    for i = 1, GetNumGuildPermissions() do
        if(self.permissionSet[i] ~= DoesGuildRankHavePermission(self.guildId, self.index, i)) then
            return true
        end
    end

    if(self.hasCustomName) then
        if(self.name ~= GetGuildRankCustomName(self.guildId, self.index)) then
            return true
        end
    else
        if(GetGuildRankCustomName(self.guildId, self.index) ~= "") then
            return true
        end
    end

    return false
end

function ZO_GuildRank_Shared:CopyPermissionsFrom(copyRank)
    ZO_ClearNumericallyIndexedTable(self.permissionSet)
    for i = 1, GetNumGuildPermissions() do
        self.permissionSet[i] = copyRank.permissionSet[i]
    end
end

function ZO_GuildRank_Shared:Save()
    AddPendingGuildRank(self.id, self:GetSaveName(), self:GetPermissions(), self.iconIndex)
end

---------------
--Guild Ranks--
---------------

ZO_GuildRanks_Shared = ZO_Object:Subclass()

function ZO_GuildRanks_Shared:New(...)
    local object = ZO_Object.New(self)
    ZO_GuildRanks_Shared.Initialize(object, ...)
    return object
end

function ZO_GuildRanks_Shared:Initialize(control)
    self.control = control
    self.ranks = {}
end

function ZO_GuildRanks_Shared:SetGuildId(guildId)
    self.guildId = guildId
end

function ZO_GuildRanks_Shared:CancelDialog()
end

function ZO_GuildRanks_Shared:ShowAddRankDialog(dialogName)
    ZO_Dialogs_ShowDialog(dialogName)
end

function ZO_GuildRanks_Shared:InitializeAddRankDialog(dialogName)
    local control = ZO_GuildAddRankDialog

    ZO_Dialogs_RegisterCustomDialog(dialogName,   
    {
        setup = function(dialog)
            dialog:GetNamedChild("NameEdit"):SetText("")
            dialog.copyComboBox:ClearItems()
            local noneEntry = dialog.copyComboBox:CreateItemEntry(GetString(SI_GUILD_RANKS_COPY_NONE), dialog.copyComboBox.OnRankSelected)
            dialog.copyComboBox:AddItem(noneEntry)
            --Skip Guild Master
            for i = 2, #self.ranks do
                local entry = dialog.copyComboBox:CreateItemEntry(self.ranks[i].name, dialog.copyComboBox.OnRankSelected)
                entry.rankIndex = i
                dialog.copyComboBox:AddItem(entry)
            end
            dialog.copyComboBox:SetSelectedItemText(GetString(SI_GUILD_RANKS_COPY_NONE))
            dialog.copyComboBox.selectedRankIndex = nil
        end,
        customControl = control,
        title =
        {
            text = SI_GUILD_RANKS_ADD_RANK,
        },        
        buttons =
        {
            [1] =
            {
                control =   GetControl(control, "Add"),
                text =      SI_DIALOG_CREATE,
                callback =  function(dialog)
                                local rankName = dialog:GetNamedChild("NameEdit"):GetText()
                                self:AddRank(rankName, dialog.copyComboBox.selectedRankIndex)
                            end,
            },
        
            [2] =
            {
                control =   GetControl(control, "Cancel"),
                callback =  function()
                                self:CancelDialog()
                            end,
                text =      SI_DIALOG_CANCEL,
            }
        }
    })

    local nameEdit = control:GetNamedChild("NameEdit")
    nameEdit:SetMaxInputChars(MAX_GUILD_RANK_NAME_LENGTH)
    local addRankFields = ZO_RequiredTextFields:New()
    addRankFields:AddButton(control:GetNamedChild("Add"))
    addRankFields:AddTextField(nameEdit)

    control.copyComboBox = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("CopyPermissions"))
    control.copyComboBox:SetSortsItems(false)
    control.copyComboBox.OnRankSelected = function(comboBox, entryText, entry)
        comboBox.selectedRankIndex = entry.rankIndex
    end
end

function ZO_GuildRanks_Shared:Save()
    if(self.ranks ~= nil and self.guildId ~= nil and #self.ranks > 0) then
        InitializePendingGuildRanks(self.guildId)

        for i = 1, #self.ranks do
            local rank = self.ranks[i]
            rank:Save()
        end

        return SavePendingGuildRanks()
    end

    return false
end

local MAX_RANK_IDS = 255

function ZO_GuildRanks_Shared:GetUniqueRankId()
    for rankId = 1, MAX_RANK_IDS do
        local idExists = false
        for i = 1, #self.ranks do
            if(rankId == self.ranks[i].id) then
                idExists = true
                break
            end
        end
        if(not idExists) then
            return rankId
        end
    end
end

function ZO_GuildRanks_Shared:GetUnusedIconIndex()
    local iconIndex = 0
    local foundUnusedIconIndex = false
    while(not foundUnusedIconIndex and iconIndex < GetNumGuildRankIcons()) do
        iconIndex = iconIndex + 1
        for i = 1, #self.ranks do
            local rank = self.ranks[i]
            if(rank.iconIndex == iconIndex) then
                break
            end
        end
    end
    return iconIndex
end

function ZO_GuildRanks_Shared:IsRankOccupied(selectedRank)
    local rankOccupied = false
    if(not selectedRank:IsNewRank()) then
        for guildMemberIndex = 1, GetNumGuildMembers(self.guildId) do
            local _, _, rankIndex = GetGuildMemberInfo(self.guildId, guildMemberIndex)
            if(rankIndex == selectedRank.index) then
                rankOccupied = true
                break
            end
        end
    end

    return rankOccupied
end


function ZO_GuildRanks_Shared:MatchesGuild(guildId)
    return (guildId == self.guildId)
end

function ZO_GuildRanks_Shared:NeedsSave()
    local needsSave = false
    local numRanks = #self.ranks
    local numPrevRanks = GetNumGuildRanks(self.guildId)

    if(numRanks ~= numPrevRanks) then
        return true
    end

    for i = 1, numRanks do
        local rank = self.ranks[i]
        if(rank:NeedsSave()) then
            needsSave = true
            break
        end
        if(i ~= rank.index) then
            needsSave = true
            break
        end
    end

    return needsSave
end

function ZO_GuildRanks_Shared_RefreshIcon(control, index, selectedIconIndex)
    local frame = control:GetNamedChild("Frame")
    if(index == selectedIconIndex) then
        frame:SetTexture("EsoUI/Art/Guild/guildRanks_iconFrame_selected.dds")
    else
        frame:SetTexture("EsoUI/Art/Guild/guildRanks_iconFrame_normal.dds")
    end
end

function ZO_GuildRanks_Shared:InsertRank(newRank, copyPermissionsFromRankIndex)
    local insertionPoint = #self.ranks + 1
    if(copyPermissionsFromRankIndex ~= nil) then
        local copyRank = self.ranks[copyPermissionsFromRankIndex]
        newRank:CopyPermissionsFrom(copyRank)
        insertionPoint = copyPermissionsFromRankIndex + 1
    end
    table.insert(self.ranks, insertionPoint, newRank)
	PlaySound(SOUNDS.GUILD_RANK_CREATED)

    return insertionPoint
end

function ZO_GuildRanks_Shared:GetRankById(rankId)
    if(rankId ~= nil) then
        for i = 1, #self.ranks do
            local rank = self.ranks[i]
            if(rank.id == rankId) then
                return rank, i
            end
        end
    end
end


function ZO_GuildRanks_Shared:GetRankIndexById(rankId)
    local rank, index = self:GetRankById(rankId)
    return index
end