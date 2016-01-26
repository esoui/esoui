--Select Guest Campaign
-----------------------

local SelectGuestCampaign = ZO_TimeLockedDialog:Subclass()

function SelectGuestCampaign:New(control)
    local timeLockedDialog = ZO_TimeLockedDialog.New(self, "SELECT_GUEST_CAMPAIGN", 
    {
        customControl = control,
        buttons =
        {
            [1] =
            {
                control =   GetControl(control, "UnlockedAccept"),
                text =      SI_DIALOG_ACCEPT,
                keybind =   "DIALOG_PRIMARY",
                callback =  function(dialogControl)
                                AssignCampaignToPlayer(dialogControl.timeLockedDialog:GetData().id, CAMPAIGN_REASSIGN_TYPE_GUEST)
                            end,
            },
        
            [2] =
            {
                control =   GetControl(control, "UnlockedExit"),
                text =      SI_DIALOG_EXIT,
                keybind =   "DIALOG_NEGATIVE",

            },

            [3] =
            {
                control =   GetControl(control, "LockedExit"),
                text =      SI_DIALOG_EXIT,
                keybind =   "DIALOG_NEGATIVE",
            },
        },
    }
    ,GetCampaignGuestCooldown)

    control.timeLockedDialog = timeLockedDialog
    timeLockedDialog.title = GetControl(control, "Title")
    timeLockedDialog.lockedMessage = GetControl(control, "LockedMessage")
    timeLockedDialog.unlockedQuery = GetControl(control, "UnlockedQuery")
    
    timeLockedDialog.bulletList = ZO_BulletList:New(GetControl(control, "UnlockedBulletList"))
    timeLockedDialog.bulletList:AddLine(GetString(SI_SELECT_GUEST_CAMPAIGN_BULLET1))
    timeLockedDialog.bulletList:AddLine(GetString(SI_SELECT_GUEST_CAMPAIGN_BULLET2))
    timeLockedDialog.bulletList:AddLine(GetString(SI_SELECT_GUEST_CAMPAIGN_BULLET3))

    return timeLockedDialog
end

function SelectGuestCampaign:SetupUnlocked(data)
    self.title:SetText(GetString(SI_SELECT_GUEST_CAMPAIGN_DIALOG_TITLE))
    self.unlockedQuery:SetText(zo_strformat(SI_SELECT_GUEST_CAMPAIGN_QUERY, GetCampaignName(data.id)))
end

function SelectGuestCampaign:SetupLocked(data)
    self.title:SetText(GetString(SI_SELECT_GUEST_CAMPAIGN_LOCKED_DIALOG_TITLE))
    local timeUntilUnlock = ZO_FormatTime(self:GetSecondsUntilUnlocked(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING)
    self.lockedMessage:SetText(zo_strformat(SI_SELECT_GUEST_CAMPAIGN_LOCKED_MESSAGE, timeUntilUnlock))
end

--Global XML

function ZO_SelectGuestCampaignDialog_OnInitialized(self)
    SELECT_GUEST_CAMPAIGN_DIALOG = SelectGuestCampaign:New(self)
end


--Select Home Campaign Dialog
-----------------------------

local SelectHomeCampaign = ZO_TimeLockedDialog:Subclass()

function SelectHomeCampaign:New(control)
    local timeLockedDialog = ZO_TimeLockedDialog.New(self, "SELECT_HOME_CAMPAIGN",
    {
        customControl = control,
        buttons =
        {
            [1] =
            {
                control =   GetControl(control, "UnlockedAccept"),
                text =      SI_DIALOG_ACCEPT,
                keybind =   "DIALOG_PRIMARY",
                callback =  function(dialogControl)
                                local timeLockedDialog = dialogControl.timeLockedDialog
                                local forceImmediate = GetAssignedCampaignId() == 0
                                if(timeLockedDialog.radioButtonGroup:GetClickedButton() == timeLockedDialog.setNowButton or forceImmediate) then
                                    AssignCampaignToPlayer(timeLockedDialog:GetData().id, CAMPAIGN_REASSIGN_TYPE_IMMEDIATE)
                                else
                                    AssignCampaignToPlayer(timeLockedDialog:GetData().id, CAMPAIGN_REASSIGN_TYPE_ON_END)
                                end
                            end,
            },
        
            [2] =
            {
                control =   GetControl(control, "UnlockedExit"),
                text =      SI_DIALOG_EXIT,
                keybind =   "DIALOG_NEGATIVE",

            },

            [3] =
            {
                control =   GetControl(control, "LockedExit"),
                text =      SI_DIALOG_EXIT,
                keybind =   "DIALOG_NEGATIVE",
            },
        }
    }
    ,GetCampaignReassignCooldown)

    control.timeLockedDialog = timeLockedDialog
    timeLockedDialog.title = GetControl(control, "Title")
    timeLockedDialog.lockedMessage = GetControl(control, "LockedMessage")
    timeLockedDialog.unlockedQuery = GetControl(control, "UnlockedQuery")
    timeLockedDialog.setNowButton = GetControl(control, "UnlockedSetNow")
    timeLockedDialog.setNowLabel = GetControl(control, "UnlockedSetNowLabel")
    timeLockedDialog.setOnEndButton = GetControl(control, "UnlockedSetOnEnd")
    timeLockedDialog.setOnEndLabel = GetControl(control, "UnlockedSetOnEndLabel")
    timeLockedDialog.free = GetControl(control, "UnlockedCostFree")
    timeLockedDialog.alliancePoints = GetControl(control, "UnlockedCostAlliancePoints")
    timeLockedDialog.balance = GetControl(timeLockedDialog.alliancePoints, "Balance")
    timeLockedDialog.price = GetControl(timeLockedDialog.alliancePoints, "Price")
    timeLockedDialog.accept = GetControl(control, "UnlockedAccept")

    timeLockedDialog.radioButtonGroup = ZO_RadioButtonGroup:New()    
    timeLockedDialog.radioButtonGroup:Add(timeLockedDialog.setNowButton)
    timeLockedDialog.radioButtonGroup:Add(timeLockedDialog.setOnEndButton)

    control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, function() timeLockedDialog:SetupCost() end)

    return timeLockedDialog
end

function SelectHomeCampaign:SetupUnlocked(data)
    self.title:SetText(GetString(SI_SELECT_HOME_CAMPAIGN_DIALOG_TITLE))
    self.unlockedQuery:SetText(zo_strformat(SI_SELECT_HOME_CAMPAIGN_QUERY, GetCampaignName(data.id)))
    self.radioButtonGroup:SetClickedButton(self.setNowButton)
end

function SelectHomeCampaign:SetupLocked(data)
    self.title:SetText(GetString(SI_SELECT_HOME_CAMPAIGN_LOCKED_DIALOG_TITLE))
    local timeUntilUnlock = ZO_FormatTime(self:GetSecondsUntilUnlocked(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING)
    self.lockedMessage:SetText(zo_strformat(SI_SELECT_HOME_CAMPAIGN_LOCKED_MESSAGE, timeUntilUnlock))
end

local CURRENCY_OPTIONS =
{
    font = "ZoFontGame",
    iconSide = RIGHT,
}

function ZO_SelectHomeCampaign_GetCost()
    local endCampaignNowCost = 0
    local endCampaignAfterEndCost = 0

    if(GetNumFreeAnytimeCampaignReassigns() == 0) then
        endCampaignNowCost = GetCampaignReassignCost(CAMPAIGN_REASSIGN_TYPE_IMMEDIATE)
    end
    if(GetNumFreeEndCampaignReassigns() == 0) then
        endCampaignAfterEndCost = GetCampaignReassignCost(CAMPAIGN_REASSIGN_TYPE_ON_END)
    end

    return endCampaignNowCost, endCampaignAfterEndCost

end

function SelectHomeCampaign:SetupCost()
    local now = self.radioButtonGroup:GetClickedButton() == self.setNowButton or GetAssignedCampaignId() == 0
    local free, cost

    local nowCost, endCost = ZO_SelectHomeCampaign_GetCost()

    if(now) then
        cost = nowCost
        free = nowCost == 0
    else
        cost = endCost
        free = endCost == 0
    end

    self.free:SetHidden(not free)
    self.alliancePoints:SetHidden(free)
    self.accept:SetState(BSTATE_NORMAL, false)

    if(not free) then
        local numAlliancePoints = GetAlliancePoints()
        ZO_CurrencyControl_SetSimpleCurrency(self.balance, CURT_ALLIANCE_POINTS, numAlliancePoints, CURRENCY_OPTIONS)

        local notEnough = cost > numAlliancePoints
        ZO_CurrencyControl_SetSimpleCurrency(self.price, CURT_ALLIANCE_POINTS, cost, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnough)

        if(notEnough) then
            self.accept:SetState(BSTATE_DISABLED, true)
        end
    end
end

function SelectHomeCampaign:DialogSetNow_OnClicked(control)
    self:SetupCost()
end

function SelectHomeCampaign:DialogSetOnEnd_OnClicked(control)
    self:SetupCost()
end

--Global XML

function ZO_SelectHomeCampaignDialogSetNow_OnClicked(control)
    SELECT_HOME_CAMPAIGN_DIALOG:DialogSetNow_OnClicked(control)
end

function ZO_SelectHomeCampaignDialogSetOnEnd_OnClicked(control)
    SELECT_HOME_CAMPAIGN_DIALOG:DialogSetOnEnd_OnClicked(control)
end

function ZO_SelectHomeCampaignDialog_OnInitialized(self)
    SELECT_HOME_CAMPAIGN_DIALOG = SelectHomeCampaign:New(self)
end

function ZO_SelectHomeCampaignDialog_OnShow()
    local forceImmediate = GetAssignedCampaignId() == 0

    if forceImmediate then
        SELECT_HOME_CAMPAIGN_DIALOG.setNowButton:SetHidden(true)
        SELECT_HOME_CAMPAIGN_DIALOG.setNowLabel:SetHidden(true)
        SELECT_HOME_CAMPAIGN_DIALOG.setOnEndButton:SetHidden(true)
        SELECT_HOME_CAMPAIGN_DIALOG.setOnEndLabel:SetHidden(true)
        SELECT_HOME_CAMPAIGN_DIALOG.radioButtonGroup:SetClickedButton(SELECT_HOME_CAMPAIGN_DIALOG.setNowButton)
    else
        SELECT_HOME_CAMPAIGN_DIALOG.setNowButton:SetHidden(false)
        SELECT_HOME_CAMPAIGN_DIALOG.setNowLabel:SetHidden(false)
        SELECT_HOME_CAMPAIGN_DIALOG.setOnEndButton:SetHidden(false)
        SELECT_HOME_CAMPAIGN_DIALOG.setOnEndLabel:SetHidden(false)
    end
end
