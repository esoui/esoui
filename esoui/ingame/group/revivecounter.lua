local RaidReviveCounterManager = ZO_Object:Subclass()

function RaidReviveCounterManager:New(control)
    local manager = ZO_Object.New(self)
    manager.control = control
    manager.countControl = GetControl(control, "Count")

    local function OnRaidLifeUpdate(event, currentCounter)
        if not IsRaidInProgress() and not HasRaidEnded() then
            currentCounter = nil
        else
            currentCounter = currentCounter or GetRaidReviveCounterInfo()
        end
        manager:Update(currentCounter)
    end

    control:RegisterForEvent(EVENT_RAID_REVIVE_COUNTER_UPDATE, OnRaidLifeUpdate)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnRaidLifeUpdate)
    control:RegisterForEvent(EVENT_RAID_TIMER_STATE_UPDATE, OnRaidLifeUpdate)

    return manager
end

function RaidReviveCounterManager:Update(currentCounter)
    if currentCounter then
        self.countControl:SetText(currentCounter)
        self.control:SetHidden(false)
    else
        self.control:SetHidden(true)
    end
end

function ZO_GroupReviveCounter_ShowHelpTooltip(self)
    InitializeTooltip(InformationTooltip, self, BOTTOM, 0, -5)
    SetTooltipText(InformationTooltip, GetString(SI_GROUP_LIST_PANEL_REVIVE_COUNTER_TOOLTIP))
end

function ZO_GroupReviveCounter_HideHelpTooltip()
    ClearTooltip(InformationTooltip)
end

function ZO_GroupReviveCounter_OnInitialized(self)
    RAID_REVIVE_COUNTER = RaidReviveCounterManager:New(self)
end
