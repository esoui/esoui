local PlayerStatusManager = ZO_Object:Subclass()
local PLAYER_STATUS

function PlayerStatusManager:New(control)
    local manager = ZO_Object.New(self)
    manager.control = control

    local comboBoxControl = GetControl(control, "Status")
    manager.comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    manager.comboBox:SetSortsItems(false)
    manager.comboBox:SetDropdownFont("ZoFontHeader")
    manager.comboBox:SetSpacing(8)
    manager.selectedItem = GetControl(comboBoxControl, "SelectedItem")

    manager.OnStatusChanged =   function(_, entryText, entry)
                                    manager:SetSelectedStatus(entry.status)
                                    SelectPlayerStatus(entry.status)
                                end

    manager:Initialize()

    control:RegisterForEvent(EVENT_PLAYER_STATUS_CHANGED, function(_, oldStatus, newStatus) manager:OnPlayerStatusChanged(oldStatus, newStatus) end)
        

    return manager
end

function PlayerStatusManager:Initialize()
    for i = 1, GetNumPlayerStatuses() do
        local statusTexture = GetPlayerStatusIcon(i)
        local statusName = GetString("SI_PLAYERSTATUS", i)
        local entryText = zo_iconTextFormat(statusTexture, 32, 32, statusName)
        local entry = self.comboBox:CreateItemEntry(entryText, self.OnStatusChanged)
        entry.status = i
		self.comboBox:AddItem(entry)
    end

    local status = GetPlayerStatus()
    self:SetSelectedStatus(status)
end

function PlayerStatusManager:SetSelectedStatus(status)
    self.status = status
    local statusTexture = GetPlayerStatusIcon(status)
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

function ZO_DisplayName_OnInitialized(self)
    GetControl(self, "DisplayName"):SetText(GetDisplayName())
    PLAYER_STATUS = PlayerStatusManager:New(self)
end