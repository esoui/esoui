--Death Type
--------------

local DeathType = ZO_Object:Subclass()

function DeathType:New(control)
    local deathType = ZO_Object.New(self)
    deathType.control = control
    deathType.buttons = { GetControl(control, "Button1"), GetControl(control, "Button2"), GetControl(control, "Button3") }
    if(deathType.buttons[1]) then
        deathType.buttons[1]:SetKeybind("DEATH_PRIMARY")
    end
    if(deathType.buttons[2]) then
        deathType.buttons[2]:SetKeybind("DEATH_SECONDARY")
    end
    if(deathType.buttons[3]) then
        deathType.buttons[3]:SetKeybind("DEATH_TERTIARY")
    end
    deathType.deathRecapToggleButton = control:GetNamedChild("DeathRecapToggleButton")
    
    return deathType
end

function DeathType:SetDeathRecapToggleButtonEnabled(enabled)
    self.deathRecapToggleButton:SetEnabled(enabled)
end

function DeathType:ToggleDeathRecap()
    self.deathRecapToggleButton:OnClicked()
end

function DeathType:GetButtonByKeybind(keybind)
    if(keybind == "DEATH_PRIMARY") then
        return self.buttons[1]
    elseif(keybind == "DEATH_SECONDARY") then
        return self.buttons[2]
    else
        return self.buttons[3]
    end
end

function DeathType:GetButton(index)
    return self.buttons[index]
end

function DeathType:SetHidden(hidden)
    if(self.control) then
        self.control:SetHidden(hidden)
    end
end

function DeathType:IsHidden()
    return self.control:IsHidden()
end

function DeathType:SelectOption(keybind)
    local button = self:GetButtonByKeybind(keybind)
    if(button) then
        button:OnClicked()
    end
end

function DeathType:UpdateDisplay()
    
end

local SOUL_GEM_FILLED_TEXT = GetString(SI_SOUL_GEM_FILLED)
local SOUL_GEM_ICON_MARKUP = "|t32:32:%s|t"
local SOUL_GEM_ICON_MARKUP_INHERIT_COLOR = "|t32:32:%s:inheritColor|t"

function ZO_Death_GetResurrectSoulGemText(level)
    local name, soulGemIcon, soulGemStackCount, soulGemQuality = GetSoulGemInfo(SOUL_GEM_TYPE_FILLED, level)
    local coloredFilledText
    local coloredSoulGemIconMarkup
    local success
    if(soulGemStackCount > 0) then
        local qualityColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, soulGemQuality))
        coloredFilledText = qualityColor:Colorize(SOUL_GEM_FILLED_TEXT)
        coloredSoulGemIconMarkup = string.format(SOUL_GEM_ICON_MARKUP, soulGemIcon)
        success = true
    else
        local _, soulGemIcon = GetSoulGemInfo(SOUL_GEM_TYPE_FILLED, level, false)
        coloredFilledText = ZO_ERROR_COLOR:Colorize(SOUL_GEM_FILLED_TEXT)
        coloredSoulGemIconMarkup = ZO_ERROR_COLOR:Colorize(string.format(SOUL_GEM_ICON_MARKUP_INHERIT_COLOR, soulGemIcon))
        success = false
    end

    return success, coloredFilledText, coloredSoulGemIconMarkup
end

function ZO_Death_IsRaidReviveAllowed()
    return IsPlayerInRaid()
end

function ZO_Death_DoesReviveCostRaidLife()
    return IsPlayerInReviveCounterRaid() and not IsPlayerInRaidStagingArea() and not HasRaidEnded()
end

function DeathType:LayoutHereButton(hereButton)
    local soulGemAvailable, freeRevive = select(9, GetDeathInfo())

    local inReviveCounterRaid = IsPlayerInReviveCounterRaid()

    if(freeRevive and not inReviveCounterRaid) then
        hereButton:SetEnabled(true)
        hereButton:SetText(GetString(SI_DEATH_PROMPT_HERE))
        return
    end
    
    local level = GetUnitEffectiveLevel("player")
    local name, soulGemIcon, soulGemStackCount, soulGemQuality = GetSoulGemInfo(SOUL_GEM_TYPE_FILLED, level) 
    hereButton:SetEnabled(soulGemStackCount > 0 or freeRevive)
    
    local soulGemSuccess, coloredFilledText, coloredSoulGemIconMarkup = ZO_Death_GetResurrectSoulGemText(level)
    hereButton:SetText(zo_strformat(soulGemSuccess and SI_DEATH_PROMPT_HERE_GEM or SI_DEATH_PROMPT_HERE_GEM_FAILED, coloredFilledText, coloredSoulGemIconMarkup))

    local reviveTextControl = hereButton:GetNamedChild("ReviveText")
    reviveTextControl:SetText(GetString(SI_DEATH_PROMPT_REVIVE_LABEL))
end

function DeathType:LayoutWayshrineButton(wayshrineButton)
	if IsInImperialCity() then
		wayshrineButton:SetText(GetString(SI_DEATH_PROMPT_RELEASE))
	else
		wayshrineButton:SetText(GetString(SI_DEATH_PROMPT_WAYSHRINE))
    end

    local reviveTextControl = wayshrineButton:GetNamedChild("ReviveText")
    reviveTextControl:SetText(GetString(SI_DEATH_PROMPT_REVIVE_LABEL))
end

function LayoutDeathRecapToggleButton(deathRecapToggleButton)
    if deathRecapToggleButton then
        deathRecapToggleButton:SetText(GetString(SI_DEATH_RECAP_TOGGLE_KEYBIND))
    end
end

--AvA Death Type
-----------------

local AvADeath = DeathType:Subclass()

function AvADeath:New(control)
    local ava = DeathType.New(self, control)
    
    local button1 = ava:GetButton(1)
    button1:SetText(GetString(SI_DEATH_PROMPT_CHOOSE_REVIVE_LOCATION))
    button1:SetCallback(function()
        ZO_WorldMap_ShowAvARespawns()
        ZO_WorldMap_ShowWorldMap()
    end)

    ava.messageLabel = GetControl(control, "Message")
    ava.messageLabel:SetText(GetString(SI_DEATH_PROMPT_AVA))
    ava.messageLabel:SetHidden(true)

    ava.timerCooldown = GetControl(control, "Timer")
    ava.timerCooldown:SetNumWarningSounds(5)
    ava.timerCooldown:SetHidden(true)

    ava.messageHidden = true

    control:SetHandler("OnUpdate", function() ava:UpdateDisplay() end)
    control:SetHandler("OnHide", function() ava.timerCooldown:Stop() end)

    return ava
end

function AvADeath:UpdateDisplay()
    local _, timeUntilAutoReleaseMs = GetDeathInfo()
    if(timeUntilAutoReleaseMs < 60000) then
        if(self.messageHidden) then
            self.messageHidden = false
            self.messageLabel:SetHidden(false)
            self.timerCooldown:Start(timeUntilAutoReleaseMs)
            self.timerCooldown:SetHidden(false)
        end
    else
        if(not self.messageHidden) then
            self.messageHidden = true
            self.messageLabel:SetHidden(true)
            self.timerCooldown:Stop()
            self.timerCooldown:SetHidden(true)
        end
    end
end

--Imperial City PvP Death Type
-----------------

local ImperialPvPDeath = DeathType:Subclass()

function ImperialPvPDeath:New(control)
    local imperialPvP = DeathType.New(self, control)

    imperialPvP.UPDATE_RATE = 1000
    imperialPvP.lastUpdate = 0

    local button1 = imperialPvP:GetButton(1)
    button1:SetText(GetString(SI_DEATH_PROMPT_CHOOSE_REVIVE_LOCATION))
    button1:SetCallback(function()
        ZO_WorldMap_ShowAvARespawns()
        ZO_WorldMap_ShowWorldMap()
    end)

    imperialPvP.messageLabel = GetControl(control, "Message")
    imperialPvP.messageLabel:SetText(GetString(SI_DEATH_PROMPT_AVA))
    imperialPvP.messageLabel:SetHidden(true)

    imperialPvP.timerCooldown = GetControl(control, "Timer")
    imperialPvP.timerCooldown:SetNumWarningSounds(5)
    imperialPvP.timerCooldown:SetHidden(true)

    imperialPvP.messageHidden = true

    local button2 = imperialPvP:GetButton(2)
    button2:SetCallback(Release)
    button2:SetText(GetString(SI_DEATH_PROMPT_RELEASE))

    control:SetHandler("OnUpdate", function() imperialPvP:UpdateDisplay() end)
    control:SetHandler("OnHide", function() imperialPvP.timerCooldown:Stop() end)

    return imperialPvP
end

function ImperialPvPDeath:UpdateDisplay()
    local _, timeUntilAutoReleaseMs = GetDeathInfo()
    if(timeUntilAutoReleaseMs < 60000) then
        if(self.messageHidden) then
            self.messageHidden = false
            self.messageLabel:SetHidden(false)
            self.timerCooldown:Start(timeUntilAutoReleaseMs)
            self.timerCooldown:SetHidden(false)
        end
    else
        if(not self.messageHidden) then
            self.messageHidden = true
            self.messageLabel:SetHidden(true)
            self.timerCooldown:Stop()
            self.timerCooldown:SetHidden(true)
        end
    end
end

--Imperial City PvE Death Type
-----------------

local ImperialPvEDeath = DeathType:Subclass()

function ImperialPvEDeath:New(control)
    local imperialPvE = DeathType.New(self, control)

    imperialPvE.UPDATE_RATE = 1000
    imperialPvE.lastUpdate = 0

    local button1 = imperialPvE:GetButton(1)
    button1:SetCallback(Revive)

    local button2 = imperialPvE:GetButton(2)
    button2:SetCallback(Release)
    button2:SetText(GetString(SI_DEATH_PROMPT_RELEASE))

    control:SetHandler("OnUpdate", function() imperialPvE:UpdateDisplay() end)

    return imperialPvE
end

function ImperialPvEDeath:CheckUpdateTimer()
    local time = GetGameTimeMilliseconds()
    if(time - self.lastUpdate > self.UPDATE_RATE) then
        self.lastUpdate = time
        return true
    end
end

function ImperialPvEDeath:UpdateDisplay()
    if self:CheckUpdateTimer() then
        self:LayoutHereButton(self:GetButton(1))
    end
end

--BG Death Type
-----------------

local BGDeath = DeathType:Subclass()

function BGDeath:New(control)
    local bg = DeathType.New(self, control)

    local button1 = bg:GetButton(1)
    button1:SetText(GetString(SI_DEATH_PROMPT_JOIN))
    button1:SetCallback(function()
        JoinRespawnQueue()
        button1:SetEnabled(false)
        button1:HideKeyIcon()
    end)

    control:SetHandler("OnUpdate", function(control, currentFrameTimeSeconds) bg:UpdateTimer(currentFrameTimeSeconds) end)
    
    bg.respawnCooldown = GetControl(control, "CountdownBar")
    control:SetHandler("OnHide", function() bg:ResetRespawnCountdown() end)
    bg:InitializeRespawnCountdown()

    return bg   
end

function BGDeath:UpdateTimer(currentFrameTimeSeconds)
    local respawnQueueTimeLeft, _, _, _, _, _, _, _, _, _, respawnQueueDuration = select(3, GetDeathInfo())
    if(not self.lastRespawnQueueTimeLeft or respawnQueueTimeLeft > self.lastRespawnQueueTimeLeft) then
        self:StartRespawnCountdown(respawnQueueTimeLeft, respawnQueueDuration)
    elseif currentFrameTimeSeconds then
        self:UpdateRespawnCountdown(currentFrameTimeSeconds)
    end
    self.lastRespawnQueueTimeLeft = respawnQueueTimeLeft
end

function BGDeath:UpdateDisplay()
    self:UpdateTimer()
    self:GetButton(1):SetEnabled(true)
end

function BGDeath:InitializeRespawnCountdown()
    self.respawnCooldown.cooldownStartMS = 0
    self.respawnCooldown.cooldownEndMS = 0
    self.respawnCooldown.cooldownDurationMS = 0
    self.respawnCooldown.loadBar = GetControl(self.respawnCooldown, "LoadBar")
end

function BGDeath:StartRespawnCountdown(timeLeftMS, durationMS)
    local currentFrameTimeMS = GetFrameTimeMilliseconds()
    self.respawnCooldown.cooldownEndMS = currentFrameTimeMS + timeLeftMS
    self.respawnCooldown.cooldownDurationMS = durationMS
    self.respawnCooldown.cooldownStartMS = self.respawnCooldown.cooldownEndMS - durationMS
    self.respawnCooldown:SetHidden(false)
end

function BGDeath:UpdateRespawnCountdown(currentFrameTimeSeconds)
    local currentFrameTimeMS = currentFrameTimeSeconds * 1000
    local screenWidth = GuiRoot:GetWidth()
    local progress = 0
    if self.respawnCooldown.cooldownDurationMS > 0 then
        progress = (currentFrameTimeMS - self.respawnCooldown.cooldownStartMS) / self.respawnCooldown.cooldownDurationMS
    end

    self.respawnCooldown.loadBar:SetWidth(screenWidth * progress)

    if IsQueuedForBattleGroundRespawn() then
        local respawnButton = self:GetButton(1)
        local secondsToWait = zo_floor((self.respawnCooldown.cooldownEndMS - currentFrameTimeMS) / 1000)
        respawnButton:SetText(zo_strformat(SI_DEATH_PROMPT_WAITING_RELEASE, secondsToWait))
    end
end

function BGDeath:ResetRespawnCountdown()
    self.respawnCooldown.cooldownStartMS = 0
    self.respawnCooldown.cooldownEndMS = 0
    self.respawnCooldown.cooldownDurationMS = 0
    self.respawnCooldown:SetHidden(true)

    local respawnButton = self:GetButton(1)
    respawnButton:SetText(GetString(SI_DEATH_PROMPT_JOIN))
    respawnButton:ShowKeyIcon()
end

--Release Only Death
----------------------

local ReleaseOnlyDeath = DeathType:Subclass()

function ReleaseOnlyDeath:New(control)
    local releaseOnly = DeathType.New(self, control)
    
    local button1 = releaseOnly:GetButton(1)
    button1:SetCallback(Release)    
    
    return releaseOnly   
end

function ReleaseOnlyDeath:UpdateDisplay()
	self:LayoutWayshrineButton(self:GetButton(1))
end

--Two Option Death
---------------------

local TwoOptionDeath = DeathType:Subclass()

function TwoOptionDeath:New(control)
    local twoOption = DeathType.New(self, control)

    twoOption.UPDATE_RATE = 1000
    twoOption.lastUpdate = 0

    local button1 = twoOption:GetButton(1)
    button1:SetCallback(Revive)

    local button2 = twoOption:GetButton(2)
    button2:SetCallback(Release)

    control:SetHandler("OnUpdate", function() twoOption:UpdateDisplay() end)
    
    return twoOption
end

function TwoOptionDeath:CheckUpdateTimer()
    local time = GetGameTimeMilliseconds()
    if(time - self.lastUpdate > self.UPDATE_RATE) then
        self.lastUpdate = time
        return true
    end
end

function TwoOptionDeath:UpdateDisplay()
    if self:CheckUpdateTimer() then
        self:LayoutHereButton(self:GetButton(1))
        self:LayoutWayshrineButton(self:GetButton(2))
        LayoutDeathRecapToggleButton(self.deathRecapToggleButton)
    end
end

--Resurrect Pending
-------------------

local ResurrectPending = DeathType:Subclass()

function ResurrectPending:New(control)
    local resurrect = DeathType.New(self, control)
    resurrect.messageLabel = GetControl(control, "Message")
    resurrect.timerCooldown = GetControl(control, "Timer")
    resurrect.timerCooldown:SetNumWarningSounds(5)
    control:SetHandler("OnHide", function()
        resurrect.timerCooldown:Stop()
    end)

    local button1 = resurrect:GetButton(1)
    button1:SetText(GetString(SI_DIALOG_ACCEPT))
    button1:SetCallback(AcceptResurrect)

    local button2 = resurrect:GetButton(2)
    button2:SetText(GetString(SI_DIALOG_DECLINE))
    button2:SetCallback(DeclineResurrect)

    return resurrect
end

function ResurrectPending:UpdateDisplay()
    local resurrectRequesterCharacterName, timeLeftToAcceptMs, resurrectRequesterDisplayName = GetPendingResurrectInfo()
    local text = zo_strformat(SI_DEATH_PROMPT_RESURRECT_TEXT, IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(resurrectRequesterDisplayName) or resurrectRequesterCharacterName)
    self.messageLabel:SetText(text)
    self.timerCooldown:Start(timeLeftToAcceptMs)
end

--In Encounter
---------------

local InEncounter = DeathType:Subclass()

function InEncounter:New(control)
    local inEncounter = DeathType.New(self, control)
    inEncounter.message = GetControl(control, "Message")
    return inEncounter
end

function InEncounter:ApplyTemplateToMessage(template)
    self.message:ApplyTemplateToLabel(template)
end

--Death
-------------

local DEATH_TYPE_TWO_OPTION = "Death"
local DEATH_TYPE_RELEASE_ONLY = "ReleaseOnly"
local DEATH_TYPE_AVA = "AvA"
local DEATH_TYPE_IMPERIAL_PVP = "ImperialPvP"
local DEATH_TYPE_IMPERIAL_PVE = "ImperialPvE"
local DEATH_TYPE_BATTLE_GROUND = "BG"
local DEATH_TYPE_RESURRECT_PENDING = "Resurrect"
local DEATH_TYPE_IN_ENCOUNTER = "InEncounter"

local DEATH_PROMPT_DELAY_MS = 2000

local Death = ZO_CallbackObject:Subclass()

function Death:New(control)
    local death = ZO_CallbackObject.New(self)

    death.control = control
    death.waitingToShowPrompt = false
    death.isPlayerDead = IsUnitDead("player")
    death.types = {}
    death.types[DEATH_TYPE_AVA] = AvADeath:New(GetControl(control, "AvA"))
    death.types[DEATH_TYPE_IMPERIAL_PVP] = ImperialPvPDeath:New(GetControl(control, "ImperialPvP"))
    death.types[DEATH_TYPE_IMPERIAL_PVE] = ImperialPvEDeath:New(GetControl(control, "ImperialPvE"))
    death.types[DEATH_TYPE_BATTLE_GROUND] = BGDeath:New(GetControl(control, "BG"))
    death.types[DEATH_TYPE_RELEASE_ONLY] = ReleaseOnlyDeath:New(GetControl(control, "ReleaseOnly"))
    death.types[DEATH_TYPE_TWO_OPTION] = TwoOptionDeath:New(GetControl(control, "TwoOption"))
    death.types[DEATH_TYPE_RESURRECT_PENDING] = ResurrectPending:New(GetControl(control, "Resurrect"))
    death.types[DEATH_TYPE_IN_ENCOUNTER] = InEncounter:New(GetControl(control, "InEncounter"))

    local function UpdateDisplay()
        death:UpdateDisplay()
    end

    EVENT_MANAGER:RegisterForEvent("Death", EVENT_PLAYER_DEAD, function() death:OnPlayerDead() end)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_PLAYER_ALIVE, function() death:OnPlayerAlive() end)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_RESURRECT_REQUEST, UpdateDisplay)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_RESURRECT_REQUEST_REMOVED, UpdateDisplay)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_GRAVEYARD_USAGE_FAILURE, UpdateDisplay)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_RAID_TRIAL_COMPLETE, UpdateDisplay)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_RAID_TRIAL_FAILED, UpdateDisplay)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_PLAYER_DEATH_REQUEST_FAILURE, UpdateDisplay)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_PLAYER_DEATH_INFO_UPDATE, UpdateDisplay)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_RAID_REVIVE_COUNTER_UPDATE, function() 
		if(self.currentType) then
            self.types[self.currentType]:UpdateDisplay()
        end
	end)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_PLAYER_ACTIVATED, function()
        death:UpdateDisplay()
    end)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_RAID_TIMER_STATE_UPDATE, function()
        death:UpdateDisplay()
    end)

    DEATH_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)
    DEATH_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        death:UpdateBindingLayer()
    end)
    DEATH_FRAGMENT:SetHiddenForReason("NotShowingAsDead", true)

    death:UpdateDisplay()

    death:ApplyStyle() -- Setup initial visual style based on current mode.
    control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() death:OnGamepadPreferredModeChanged() end)
    return death
end

function Death:GetDeathType()
    if(IsResurrectPending()) then
        return DEATH_TYPE_RESURRECT_PENDING
    else
        local isEncounterInProgress, isAVADeath, isBattleGroundDeath, isReleaseOnly, _, _, isRaidDeath = select(5, GetDeathInfo())
        if IsInImperialCity() then -- Special snowflake scenario
			if isReleaseOnly then
				return DEATH_TYPE_RELEASE_ONLY
			else
				return isAVADeath and DEATH_TYPE_IMPERIAL_PVP or DEATH_TYPE_IMPERIAL_PVE
			end
        elseif isBattleGroundDeath then
            return DEATH_TYPE_BATTLE_GROUND
        elseif isAVADeath then 
            return DEATH_TYPE_AVA
        elseif isEncounterInProgress then
            return DEATH_TYPE_IN_ENCOUNTER
        elseif isRaidDeath then
            if isReleaseOnly then
                return DEATH_TYPE_RELEASE_ONLY
            else
                return DEATH_TYPE_TWO_OPTION
            end
        elseif isReleaseOnly then 
            return DEATH_TYPE_RELEASE_ONLY
        else
            return DEATH_TYPE_TWO_OPTION
        end
    end
end

function Death:SetDeathRecapToggleButtonsEnabled(enabled)
    for _, deathType in pairs(self.types) do
        deathType:SetDeathRecapToggleButtonEnabled(enabled)
    end
end

function Death:UpdateDisplay()
    if(self.waitingToShowPrompt) then
        return
    end

    DEATH_FRAGMENT:SetHiddenForReason("NotShowingAsDead", not self.isPlayerDead)
    
    local nextType
    if(self.isPlayerDead) then
        nextType = self:GetDeathType()
    end    

    local deathTypeChanged = false
    if(self.currentType ~= nextType) then
        if(self.currentType) then
            self.types[self.currentType]:SetHidden(true)
        end

        if(nextType) then
            self.types[nextType]:SetHidden(false)
        end

        self.currentType = nextType
        deathTypeChanged = true
    end

    if(self.currentType) then
        self.types[self.currentType]:UpdateDisplay()
        INSTANCE_KICK_WARNING_DEAD:SetHiddenForReason("deathHidden", false)
    else
        INSTANCE_KICK_WARNING_DEAD:SetHiddenForReason("deathHidden", true)
    end

    self:UpdateBindingLayer()

    if(deathTypeChanged) then
        self:FireCallbacks("OnDeathTypeChanged", nextType)
    end
end

function Death:UpdateBindingLayer()
    if(not self.control:IsHidden() and self.currentType ~= nil) then
        InsertNamedActionLayerAbove("Death", GetString(SI_KEYBINDINGS_LAYER_GENERAL))
    else
        RemoveActionLayerByName("Death")
    end
end

do
    local function ApplyNormalColorToKeybind(keybind, color)
        keybind:SetNormalTextColor(color)
    end

    local function ApplyNormalColorToOneButton(buttons, color)
        ApplyNormalColorToKeybind(GetControl(buttons, "Button1"), color)
        ApplyNormalColorToKeybind(GetControl(buttons, "DeathRecapToggleButton"), color)
    end

    local function ApplyNormalColorToTwoButton(buttons, color)
        ApplyNormalColorToOneButton(buttons, color)
        ApplyNormalColorToKeybind(GetControl(buttons, "Button2"), color)
    end

    local function ApplyNormalColorToThreeButton(buttons, color)
        ApplyNormalColorToTwoButton(buttons, color)
        ApplyNormalColorToKeybind(GetControl(buttons, "Button3"), color)
    end

    local function ApplyNormalColorToDeath(control, color)
        ApplyNormalColorToOneButton(control:GetNamedChild("AvA"), color)
        ApplyNormalColorToOneButton(control:GetNamedChild("BG"), color)
        ApplyNormalColorToOneButton(control:GetNamedChild("ReleaseOnly"), color)
        ApplyNormalColorToTwoButton(control:GetNamedChild("TwoOption"), color)
        ApplyNormalColorToTwoButton(control:GetNamedChild("Resurrect"), color)
        ApplyNormalColorToTwoButton(control:GetNamedChild("ImperialPvP"), color)
        ApplyNormalColorToTwoButton(control:GetNamedChild("ImperialPvE"), color)
    end

    function Death:ApplyStyle()
        local isGamepad = IsInGamepadPreferredMode()
        ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_Death"))
        ApplyNormalColorToDeath(self.control, isGamepad and ZO_SELECTED_TEXT or ZO_NORMAL_TEXT)
        self.types[DEATH_TYPE_IN_ENCOUNTER]:ApplyTemplateToMessage(ZO_GetPlatformTemplate("ZO_DeathInEncouterLoadingLabel"))
    end
end

--bindings

function Death:SelectOption(keybind)
    if(self.currentType) then
        self.types[self.currentType]:SelectOption(keybind)
    end
end

function ZO_Death_ToggleDeathRecapCallback()
    DEATH_RECAP:SetWindowOpen(not DEATH_RECAP:IsWindowOpen())
end

function Death:ToggleDeathRecap()
    if(self.currentType) then
        self.types[self.currentType]:ToggleDeathRecap()
    end
end

--Events

function Death:OnPlayerAlive()
    self.isPlayerDead = false
    self.waitingToShowPrompt = false
    EVENT_MANAGER:UnregisterForUpdate("WaitToShowDeath")
    self:UpdateDisplay()
end

function Death:OnPlayerDead()
    self.isPlayerDead = true
    if(not self.waitingToShowPrompt) then
        self.waitingToShowPrompt = true
        EVENT_MANAGER:RegisterForUpdate("WaitToShowDeath", DEATH_PROMPT_DELAY_MS, function()
            self.waitingToShowPrompt = false
            EVENT_MANAGER:UnregisterForUpdate("WaitToShowDeath")
            self:UpdateDisplay()
        end)
    end
end

function Death:OnGamepadPreferredModeChanged()
    self:ApplyStyle()
end

--Global XML

function ZO_Death_OnInitialized(self)
    DEATH = Death:New(self)
end

function ZO_Death_OnEffectivelyHidden(self)
    if (DEATH) then
        DEATH:UpdateBindingLayer()        
    end
end

function ZO_Death_OnEffectivelyShown(self)
    if (DEATH) then
        DEATH:UpdateBindingLayer()        
    end
end