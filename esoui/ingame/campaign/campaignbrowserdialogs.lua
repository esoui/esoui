-- Shared Resources
--------------------

local CURRENCY_OPTIONS =
{
    font = "ZoFontGame",
    iconSide = RIGHT,
}

ZO_CampaignDialogBase = ZO_Object:Subclass()

function ZO_CampaignDialogBase:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

do
    local function DefaultUnlockedCooldownFunction()
        return 0
    end

    function ZO_CampaignDialogBase:Initialize(dialogName, dialogInfo, lockedCooldownFunction, unlockedCooldownFunction)
        self.control = dialogInfo.customControl
        self.locked = GetControl(self.control, "Locked")
        self.unlocked = GetControl(self.control, "Unlocked")
        self.dialogName = dialogName

        self.lockedCooldownFunction = lockedCooldownFunction
        self.unlockedCooldownFunction = unlockedCooldownFunction or DefaultUnlockedCooldownFunction

        local function SetupTimeLockedDialog(dialog, data)
            self:InitializeDialog(data)
        end

        local function UpdateTimeLockedDialog(dialog, time)
            self:RefreshTimerState()
        end

        dialogInfo.setup = SetupTimeLockedDialog
        dialogInfo.updateFn = UpdateTimeLockedDialog

        ZO_Dialogs_RegisterCustomDialog(dialogName, dialogInfo)
    end
end

function ZO_CampaignDialogBase:GetData()
    return self.data
end

function ZO_CampaignDialogBase:GetControl()
    return self.control
end

function ZO_CampaignDialogBase:Show(data)
    ZO_Dialogs_ShowDialog(self.dialogName, data)
end

function ZO_CampaignDialogBase:Hide()
    self.data = nil
    ZO_Dialogs_ReleaseDialogOnButtonPress(self.dialogName)
end

function ZO_CampaignDialogBase:InitializeDialog(data)
    self.data = data

    self:RefreshTimerState()
end

function ZO_CampaignDialogBase:RefreshTimerState()
    local lastLockedCooldownSeconds = self.lockedCooldownSeconds
    local lastUnlockedCooldownSeconds = self.unlockedCooldownSeconds
    local wasLocked = self.isLocked

    self.lockedCooldownSeconds = self.lockedCooldownFunction()
    self.unlockedCooldownSeconds = self.unlockedCooldownFunction()
    self.isLocked = self.lockedCooldownSeconds > 0

    if self.isLocked ~= wasLocked then
        self:SetupDialog()
    elseif self.isLocked and self.lockedCooldownSeconds ~= lastLockedCooldownSeconds then
        self:SetupLockedTimer(self.data)
    elseif not self.isLocked and self.unlockedCooldownSeconds ~= lastUnlockedCooldownSeconds then
        self:SetupUnlockedTimer(self.data)
    end
end

function ZO_CampaignDialogBase:IsLocked()
    return self.isLocked
end

function ZO_CampaignDialogBase:GetLockedCooldownSeconds()
    return self.lockedCooldownSeconds
end

function ZO_CampaignDialogBase:GetUnlockedCooldownSeconds()
    return self.unlockedCooldownSeconds
end

function ZO_CampaignDialogBase:SetupDialog()
    local isLocked = self:IsLocked()
    if isLocked then
        self:SetupLockedDialog(self.data)
    else
        self:SetupUnlockedDialog(self.data)
    end

    self.locked:SetHidden(not isLocked)
    self.unlocked:SetHidden(isLocked)
end

function ZO_CampaignDialogBase:SetupUnlockedDialog(data)
    -- override me
end

function ZO_CampaignDialogBase:SetupUnlockedTimer(data)
    -- override me
end

function ZO_CampaignDialogBase:SetupLockedDialog(data)
    -- override me
end

function ZO_CampaignDialogBase:SetupLockedTimer(data)
    -- override me
end

--Select Home Campaign Dialog
-----------------------------

local SelectHomeCampaign = ZO_CampaignDialogBase:Subclass()

function SelectHomeCampaign:New(...)
    return ZO_CampaignDialogBase.New(self, ...)
end

-- Override, and also change function params too
function SelectHomeCampaign:Initialize(control)
    local dialogInfo =
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
                                if timeLockedDialog.radioButtonGroup:GetClickedButton() == timeLockedDialog.setNowButton or forceImmediate then
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
    local function GetDialogCampaignEndCooldown()
        local selectionIndex = self:GetData().selectionIndex
        local _, secondsUntilCampaignEnd = GetSelectionCampaignTimes(selectionIndex)
        return secondsUntilCampaignEnd
    end

    ZO_CampaignDialogBase.Initialize(self, "SELECT_HOME_CAMPAIGN", dialogInfo, GetCampaignReassignCooldown, GetDialogCampaignEndCooldown)

    control.timeLockedDialog = self
    self.title = GetControl(control, "Title")
    self.lockedMessage = GetControl(control, "LockedMessage")
    self.unlockedQuery = GetControl(control, "UnlockedQuery")
    self.allianceLockWarningLabel = GetControl(control, "UnlockedAllianceLockWarning")
    self.setNowButton = GetControl(control, "UnlockedSetNow")
    self.setNowLabel = GetControl(control, "UnlockedSetNowLabel")
    self.setOnEndButton = GetControl(control, "UnlockedSetOnEnd")
    self.setOnEndLabel = GetControl(control, "UnlockedSetOnEndLabel")
    self.cost = GetControl(control, "UnlockedCost")
    self.free = GetControl(control, "UnlockedCostFree")
    self.alliancePoints = GetControl(control, "UnlockedCostAlliancePoints")
    self.balance = GetControl(self.alliancePoints, "Balance")
    self.price = GetControl(self.alliancePoints, "Price")
    self.accept = GetControl(control, "UnlockedAccept")

    self.radioButtonGroup = ZO_RadioButtonGroup:New()
    self.radioButtonGroup:Add(self.setNowButton)
    self.radioButtonGroup:Add(self.setOnEndButton)

    control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, function() self:SetupCost() end)
end

-- Override
function SelectHomeCampaign:InitializeDialog(data)
    ZO_CampaignDialogBase.InitializeDialog(self, data)
    self.radioButtonGroup:SetClickedButton(self.setNowButton)
end

-- Override
function SelectHomeCampaign:SetupUnlockedDialog(data)
    self.title:SetText(GetString(SI_SELECT_HOME_CAMPAIGN_DIALOG_TITLE))

    local campaignId = data.id
    local campaignName = ZO_SELECTED_TEXT:Colorize(data.name)
    local initialCooldownString = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(GetCampaignReassignInitialCooldown(), TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))
    self.unlockedQuery:SetText(zo_strformat(SI_SELECT_HOME_CAMPAIGN_QUERY, campaignName, initialCooldownString))

    self:SetupUnlockedTimer(data)
    self:SetupCost()
end

-- Override
function SelectHomeCampaign:SetupUnlockedTimer(data)
    if ZO_CampaignBrowserDialogs_ShouldShowAllianceLockWarning(data) then
        local playerAlliance = GetUnitAlliance("player")
        local allianceString = ZO_SELECTED_TEXT:Colorize(ZO_CampaignBrowser_FormatPlatformAllianceIconAndName(playerAlliance))
        local campaignEndCooldownString = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(self:GetUnlockedCooldownSeconds(), TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))
        self.allianceLockWarningLabel:SetHidden(false)
        self.allianceLockWarningLabel:SetText(zo_strformat(SI_ABOUT_TO_ALLIANCE_LOCK_CAMPAIGN_WARNING, allianceString, campaignEndCooldownString))

        self.setNowButton:ClearAnchors()
        self.setNowButton:SetAnchor(TOPLEFT, self.allianceLockWarningLabel, BOTTOMLEFT, 20, 15)
    else
        self.allianceLockWarningLabel:SetHidden(true)

        self.setNowButton:ClearAnchors()
        self.setNowButton:SetAnchor(TOPLEFT, self.unlockedQuery, BOTTOMLEFT, 20, 15)
    end
end

-- Override
function SelectHomeCampaign:SetupLockedDialog(data)
    self.title:SetText(GetString(SI_SELECT_HOME_CAMPAIGN_LOCKED_DIALOG_TITLE))
    self:SetupLockedTimer(data)
end

-- Override
function SelectHomeCampaign:SetupLockedTimer(data)
    local timeUntilUnlock = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(self:GetLockedCooldownSeconds(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))
    self.lockedMessage:SetText(zo_strformat(SI_SELECT_HOME_CAMPAIGN_LOCKED_MESSAGE, timeUntilUnlock))
end

function SelectHomeCampaign:SetupCost()
    local now = self.radioButtonGroup:GetClickedButton() == self.setNowButton or GetAssignedCampaignId() == 0
    local free, cost

    local nowCost, endCost = ZO_SelectHomeCampaign_GetCost()

    if now then
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

    if hideJoinOptions then
        -- anchor in place of buttons
        self.cost:ClearAnchors()
        self.cost:SetAnchor(TOPLEFT, self.setNowButton, TOPLEFT, -20, 0)
    else
        -- anchor below buttons
        self.cost:ClearAnchors()
        self.cost:SetAnchor(TOPLEFT, self.setOnEndButton, BOTTOMLEFT, -20, 15)
    end

    if not free then
        local numAlliancePoints = GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
        ZO_CurrencyControl_SetSimpleCurrency(self.balance, CURT_ALLIANCE_POINTS, numAlliancePoints, CURRENCY_OPTIONS)

        local notEnough = cost > numAlliancePoints
        ZO_CurrencyControl_SetSimpleCurrency(self.price, CURT_ALLIANCE_POINTS, cost, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnough)

        if notEnough then
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

--Abandon Home Campaign Dialog
-------------------------------

local AbandonHomeCampaign = ZO_CampaignDialogBase:Subclass()

function AbandonHomeCampaign:New(control)
    local timeLockedDialog = ZO_CampaignDialogBase.New(self, "ABANDON_HOME_CAMPAIGN",
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
                                if timeLockedDialog.radioButtonGroup:GetClickedButton() == timeLockedDialog.useAlliancePointsButton then
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
    timeLockedDialog.useAlliancePointsButton = GetControl(control, "UnlockedUseAlliancePoints")
    timeLockedDialog.useAlliancePointsLabel = GetControl(control, "UnlockedUseAlliancePointsLabel")
    timeLockedDialog.useGoldButton = GetControl(control, "UnlockedUseGold")
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

-- Override
function AbandonHomeCampaign:SetupUnlockedDialog(data)
    self.title:SetText(GetString(SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN))
    self.unlockedQuery:SetText(zo_strformat(SI_ABANDON_HOME_CAMPAIGN_QUERY, GetCampaignName(data.id)))
    self.radioButtonGroup:SetClickedButton(self.useAlliancePointsButton)
end

-- Override
function AbandonHomeCampaign:SetupLockedDialog(data)
    self.title:SetText(GetString(SI_SELECT_HOME_CAMPAIGN_LOCKED_DIALOG_TITLE))
    self:SetupLockedTimer(data)
end

-- Override
function AbandonHomeCampaign:SetupLockedTimer(data)
    local timeUntilUnlock = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(self:GetLockedCooldownSeconds(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))
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

    if useAlliancePoints then
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

    if not free then
        local notEnough

        if useAlliancePoints then
            local numAlliancePoints = GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
            ZO_CurrencyControl_SetSimpleCurrency(self.balance, CURT_ALLIANCE_POINTS, numAlliancePoints, CURRENCY_OPTIONS)

            notEnough = cost > numAlliancePoints
            ZO_CurrencyControl_SetSimpleCurrency(self.price, CURT_ALLIANCE_POINTS, cost, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnough)
        else
            local numMoney = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
            ZO_CurrencyControl_SetSimpleCurrency(self.balance, CURT_MONEY, numMoney, CURRENCY_OPTIONS)

            notEnough = cost > numMoney
            ZO_CurrencyControl_SetSimpleCurrency(self.price, CURT_MONEY, cost, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnough)
        end

        if notEnough then
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

-- Queue for Campaign Dialog

local function SetupRadioButtonWithBasicTextTooltip(radioButtonGroup, radioButton, isButtonEnabled, anchorToControl, anchorDirection, tooltipText)
    local function OnMouseEnter()
        ZO_Tooltips_ShowTextTooltip(anchorToControl, anchorDirection, tooltipText)
    end

    local function OnMouseExit()
        ZO_Tooltips_HideTextTooltip()
    end

    radioButtonGroup:SetButtonIsValidOption(radioButton, isButtonEnabled)
    radioButton.label:SetHandler("OnMouseEnter", OnMouseEnter)
    radioButton.label:SetHandler("OnMouseExit", OnMouseExit)
end

local function SetupRadioButtonAsEnabled(radioButtonGroup, radioButton)
    local BUTTON_ENABLED = true
    local NO_HANDLER = nil
    radioButtonGroup:SetButtonIsValidOption(radioButton, BUTTON_ENABLED)
    radioButton.label:SetHandler("OnMouseEnter", NO_HANDLER)
    radioButton.label:SetHandler("OnMouseExit", NO_HANDLER)
end

local function CampaignQueueDialogSetup(dialog, data)
    local campaignRulesetTypeString = GetString("SI_CAMPAIGNRULESETTYPE", data.campaignData.rulesetType)
    dialog.promptLabel:SetText(zo_strformat(SI_CAMPAIGN_BROWSER_QUEUE_DIALOG_PROMPT, campaignRulesetTypeString, data.campaignData.name))

    local groupQueueResult = GetExpectedGroupQueueResult()
    if groupQueueResult ~= QUEUE_FOR_CAMPAIGN_RESULT_SUCCESS then
        local BUTTON_DISABLED = false
        local anchorTo = dialog.groupQueueButton.label
        local tooltipText = GetString("SI_QUEUEFORCAMPAIGNRESPONSETYPE", groupQueueResult)
        SetupRadioButtonWithBasicTextTooltip(dialog.radioButtonGroup, dialog.groupQueueButton, BUTTON_DISABLED, anchorTo, RIGHT, tooltipText)

        dialog.radioButtonGroup:SetClickedButton(dialog.soloQueueButton)
    else
        SetupRadioButtonAsEnabled(dialog.radioButtonGroup, dialog.groupQueueButton)
        dialog.radioButtonGroup:SetClickedButton(dialog.groupQueueButton)
    end
end

function ZO_CampaignQueueDialog_OnInitialized(control)
    -- Label
    local promptLabel = control:GetNamedChild("Prompt")

    -- Radio buttons
    local radioButtonContainer = control:GetNamedChild("RadioButtons")

    local groupQueueButton = radioButtonContainer:GetNamedChild("GroupQueue")
    groupQueueButton.label = groupQueueButton:GetNamedChild("Label")
    groupQueueButton.queueType = CAMPAIGN_QUEUE_TYPE_GROUP

    local soloQueueButton = radioButtonContainer:GetNamedChild("SoloQueue")
    soloQueueButton.label = soloQueueButton:GetNamedChild("Label")
    soloQueueButton.queueType = CAMPAIGN_QUEUE_TYPE_INDIVIDUAL

    local radioButtonGroup = ZO_RadioButtonGroup:New()
    radioButtonGroup:Add(soloQueueButton)
    radioButtonGroup:Add(groupQueueButton)

    control.promptLabel = promptLabel
    control.radioButtonContainer = radioButtonContainer
    control.radioButtonGroup = radioButtonGroup
    control.groupQueueButton = groupQueueButton
    control.soloQueueButton = soloQueueButton

    ZO_Dialogs_RegisterCustomDialog(
        "CAMPAIGN_QUEUE",
        {
            customControl = control,
            setup = CampaignQueueDialogSetup,
            title =
            {
                text = SI_CAMPAIGN_BROWSER_QUEUE_DIALOG_TITLE,
            },
            canQueue = true,
            buttons =
            {
                {
                    control = control:GetNamedChild("Confirm"),
                    text = SI_DIALOG_ACCEPT,
                    callback = function(dialog)
                        local queueType = dialog.radioButtonGroup:GetClickedButton().queueType
                        CAMPAIGN_BROWSER_MANAGER:ContinueQueueForCampaignFlow(dialog.data.campaignData, ZO_CAMPAIGN_QUEUE_STEP_SELECT_QUEUE_TYPE, queueType)
                    end,
                },

                {
                    control = control:GetNamedChild("Cancel"),
                    text = SI_DIALOG_CANCEL,
                },
            },
        }
    )
end
