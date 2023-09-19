local PLAYER_STATUS

local PlayerStatusManager = ZO_InitializingObject:Subclass()

function PlayerStatusManager:Initialize(control)
    self.control = control

    local comboBoxControl = control:GetNamedChild("Status")
    self.comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    self.comboBox:SetSortsItems(false)
    self.comboBox:SetDropdownFont("ZoFontHeader")
    self.comboBox:SetSpacing(8)
    self.selectedItem = comboBoxControl:GetNamedChild("SelectedItem")

    control:GetNamedChild("DisplayName"):SetText(GetDisplayName())

    self.OnStatusChanged = function(_, entryText, entry)
        self:SetSelectedStatus(entry.status)
        SelectPlayerStatus(entry.status)
    end

    for i = 1, GetNumPlayerStatuses() do
        local statusTexture = ZO_GetPlayerStatusIcon(i)
        local statusName = GetString("SI_PLAYERSTATUS", i)
        local entryText = zo_iconTextFormat(statusTexture, 32, 32, statusName)
        local entry = self.comboBox:CreateItemEntry(entryText, self.OnStatusChanged)
        entry.status = i
        self.comboBox:AddItem(entry)
    end

    local status = GetPlayerStatus()
    self:SetSelectedStatus(status)

    control:RegisterForEvent(EVENT_PLAYER_STATUS_CHANGED, function(_, oldStatus, newStatus) self:OnPlayerStatusChanged(oldStatus, newStatus) end)
end

function PlayerStatusManager:SetSelectedStatus(status)
    self.status = status
    local statusTexture = ZO_GetPlayerStatusIcon(status)
    self.selectedItem:SetNormalTexture(statusTexture)
    self.selectedItem:SetPressedTexture(statusTexture)
end

--Events

function PlayerStatusManager:OnPlayerStatusChanged(oldStatus, newStatus)
    self:SetSelectedStatus(newStatus)
end

function PlayerStatusManager:Status_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, RIGHT, 0, 0)
    SetTooltipText(InformationTooltip, zo_strformat(SI_PLAYER_STATUS_TOOLTIP, GetString("SI_PLAYERSTATUS", self.status)))
end

function PlayerStatusManager:Status_OnMouseExit()
    ClearTooltip(InformationTooltip)
end

--Global XML

function ZO_PlayerStatus_OnMouseEnter(control)
    PLAYER_STATUS:Status_OnMouseEnter(control)
end

function ZO_PlayerStatus_OnMouseExit(control)
    PLAYER_STATUS:Status_OnMouseExit()
end

function ZO_DisplayName_OnInitialized(control)
    PLAYER_STATUS = PlayerStatusManager:New(control)
end