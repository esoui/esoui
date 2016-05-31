-- Shared Resources
--------------------

local CURRENCY_OPTIONS =
{
    font = "ZoFontGame",
    iconSide = RIGHT,
}

--Select Guest Campaign
------------------------

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

    local hideJoinOptions = GetAssignedCampaignId() == 0
    self.setNowButton:SetHidden(hideJoinOptions)
    self.setNowLabel:SetHidden(hideJoinOptions)
    self.setOnEndButton:SetHidden(hideJoinOptions)
    self.setOnEndLabel:SetHidden(hideJoinOptions)

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

--Abandon Guest Campaign
-------------------------

local AbandonGuestCampaign = ZO_TimeLockedDialog:Subclass()

function AbandonGuestCampaign:New(control)
    local timeLockedDialog = ZO_TimeLockedDialog.New(self, "ABANDON_GUEST_CAMPAIGN", 
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
                                UnassignCampaignForPlayer(CAMPAIGN_UNASSIGN_TYPE_GUEST)
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

    return timeLockedDialog
end

function AbandonGuestCampaign:SetupUnlocked(data)
    self.title:SetText(GetString(SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN))
    self.unlockedQuery:SetText(zo_strformat(SI_ABANDON_GUEST_CAMPAIGN_QUERY, GetCampaignName(data.id)))
end

function AbandonGuestCampaign:SetupLocked(data)
    self.title:SetText(GetString(SI_SELECT_GUEST_CAMPAIGN_LOCKED_DIALOG_TITLE))
    local timeUntilUnlock = ZO_FormatTime(self:GetSecondsUntilUnlocked(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING)
    self.lockedMessage:SetText(zo_strformat(SI_ABANDON_GUEST_CAMPAIGN_LOCKED_MESSAGE, timeUntilUnlock))
end

--Global XML

function ZO_AbandonGuestCampaignDialog_OnInitialized(self)
    ABANDON_GUEST_CAMPAIGN_DIALOG = AbandonGuestCampaign:New(self)
end

--Abandon Home Campaign Dialog
-------------------------------

local AbandonHomeCampaign = ZO_TimeLockedDialog:Subclass()

function AbandonHomeCampaign:New(control)
    local timeLockedDialog = ZO_TimeLockedDialog.New(self, "ABANDON_HOME_CAMPAIGN",
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
                                if(timeLockedDialog.radioButtonGroup:GetClickedButton() == timeLockedDialog.useAlliancePointsButton) then
                                    UnassignCampaignForPlayer(CAMPAIGN_UNASSIGN_TYPE_HOME_USE_ALLIANCE_POINTS)
                                else
                                    UnassignCampaignForPlayer(CAMPAIGN_UNASSIGN_TYPE_HOME_USE_GOLD)
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
    ,GetCampaignUnassignCooldown)

    control.timeLockedDialog = timeLockedDialog
    timeLockedDialog.title = GetControl(control, "Title")
    timeLockedDialog.lockedMessage = GetControl(control, "LockedMessage")
    timeLockedDialog.unlockedQuery = GetControl(control, "UnlockedQuery")
    timeLockedDialog.useAlliancePointsButton = GetControl(control, "UnlockedUseAlliancePointsButton")
    timeLockedDialog.useAlliancePointsLabel = GetControl(control, "UnlockedUseAlliancePointsLabel")
    timeLockedDialog.useGoldButton = GetControl(control, "UnlockedUseGoldButton")
    timeLockedDialog.useGoldLabel = GetControl(control, "UnlockedUseGoldLabel")
    timeLockedDialog.free = GetControl(control, "UnlockedCostFree")
    timeLockedDialog.alliancePoints = GetControl(control, "UnlockedCostAlliancePoints")
    timeLockedDialog.balance = GetControl(timeLockedDialog.alliancePoints, "Balance")
    timeLockedDialog.price = GetControl(timeLockedDialog.alliancePoints, "Price")
    timeLockedDialog.accept = GetControl(control, "UnlockedAccept")

    timeLockedDialog.radioButtonGroup = ZO_RadioButtonGroup:New()    
    timeLockedDialog.radioButtonGroup:Add(timeLockedDialog.useAlliancePointsButton)
    timeLockedDialog.radioButtonGroup:Add(timeLockedDialog.useGoldButton)

    control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, function() timeLockedDialog:SetupCost() end)
    control:RegisterForEvent(EVENT_MONEY_UPDATE, function() timeLockedDialog:SetupCost() end)

    return timeLockedDialog
end

function AbandonHomeCampaign:SetupUnlocked(data)
    self.title:SetText(GetString(SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN))
    self.unlockedQuery:SetText(zo_strformat(SI_ABANDON_HOME_CAMPAIGN_QUERY, GetCampaignName(data.id)))
    self.radioButtonGroup:SetClickedButton(self.useAlliancePointsButton)
end

function AbandonHomeCampaign:SetupLocked(data)
    self.title:SetText(GetString(SI_SELECT_HOME_CAMPAIGN_LOCKED_DIALOG_TITLE))
    local timeUntilUnlock = ZO_FormatTime(self:GetSecondsUntilUnlocked(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING)
    self.lockedMessage:SetText(zo_strformat(SI_ABANDON_HOME_CAMPAIGN_LOCKED_MESSAGE, timeUntilUnlock))
end

function AbandonHomeCampaign:DialogUseAlliancePoints_OnClicked(control)
    self:SetupCost()
end

function AbandonHomeCampaign:DialogUseGold_OnClicked(control)
    self:SetupCost()
end

function AbandonHomeCampaign:SetupCost()
    local useAlliancePoints = self.radioButtonGroup:GetClickedButton() == self.useAlliancePointsButton
    local free, cost

    local alliancePointCost, goldCost = ZO_AbandonHomeCampaign_GetCost()

    if(useAlliancePoints) then
        cost = alliancePointCost
        free = alliancePointCost == 0
    else
        cost = goldCost
        free = goldCost == 0
    end

    local hideCostOptions = goldCost == 0 or alliancePointCost == 0
    self.useAlliancePointsButton:SetHidden(hideCostOptions)
    self.useAlliancePointsLabel:SetHidden(hideCostOptions)
    self.useGoldButton:SetHidden(hideCostOptions)
    self.useGoldLabel:SetHidden(hideCostOptions)

    self.free:SetHidden(not free)
    self.alliancePoints:SetHidden(free)
    self.accept:SetState(BSTATE_NORMAL, false)

    if(not free) then
        local notEnough

        if (useAlliancePoints) then
            local numAlliancePoints = GetAlliancePoints()
            ZO_CurrencyControl_SetSimpleCurrency(self.balance, CURT_ALLIANCE_POINTS, numAlliancePoints, CURRENCY_OPTIONS)

            notEnough = cost > numAlliancePoints
            ZO_CurrencyControl_SetSimpleCurrency(self.price, CURT_ALLIANCE_POINTS, cost, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnough)
        else
            local numMoney = GetCurrentMoney()
            ZO_CurrencyControl_SetSimpleCurrency(self.balance, CURT_MONEY, numMoney, CURRENCY_OPTIONS)

            notEnough = cost > numMoney
            ZO_CurrencyControl_SetSimpleCurrency(self.price, CURT_MONEY, cost, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnough)
        end

        if(notEnough) then
            self.accept:SetState(BSTATE_DISABLED, true)
        end
    end
end

--Global XML

function ZO_AbandonHomeCampaignDialogUseAlliancePoints_OnClicked(control)
    ABANDON_HOME_CAMPAIGN_DIALOG:DialogUseAlliancePoints_OnClicked(control)
end

function ZO_AbandonHomeCampaignDialogUseGold_OnClicked(control)
    ABANDON_HOME_CAMPAIGN_DIALOG:DialogUseGold_OnClicked(control)
end

function ZO_AbandonHomeCampaignDialog_OnInitialized(self)
   ABANDON_HOME_CAMPAIGN_DIALOG = AbandonHomeCampaign:New(self)
end