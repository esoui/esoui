--Death Type
--------------

local DeathType = ZO_Object:Subclass()

function DeathType:New(...)
    local deathType = ZO_Object.New(self)
    deathType:Initialize(...)
    return deathType
end

do
    local BUTTON_KEYBINDS = { "DEATH_PRIMARY", "DEATH_SECONDARY", "DEATH_TERTIARY" }

    function DeathType:Initialize(control)
        self.control = control

        self.buttons = { control:GetNamedChild("Button1"), control:GetNamedChild("Button2"), control:GetNamedChild("Button3") }
        for i, button in ipairs(self.buttons) do
            self:MixinDeathKeybindButton(button)
            button:SetKeybind(BUTTON_KEYBINDS[i])
        end
    
        local deathRecapToggleButton = control:GetNamedChild("DeathRecapToggleButton")
        if deathRecapToggleButton then
            self:MixinDeathKeybindButton(deathRecapToggleButton)
            deathRecapToggleButton:SetText(GetString(SI_DEATH_RECAP_TOGGLE_KEYBIND))
            deathRecapToggleButton:SetKeybind("DEATH_RECAP_TOGGLE")
            deathRecapToggleButton:SetCallback(function() DEATH_RECAP:SetWindowOpen(not DEATH_RECAP:IsWindowOpen()) end)
            self.deathRecapToggleButton = deathRecapToggleButton
        end
    end
end

do
    local DeathKeybindButtonMixin =
    {     
        SetText = function(control, text)
            control.originalText = text
            ZO_KeybindButtonMixin.SetText(control, text)
        end,
        RefreshText = function(control)
            if control.originalText then
                ZO_KeybindButtonMixin.SetText(control, control.originalText)
            end
        end,
    }

    function DeathType:MixinDeathKeybindButton(button)
        zo_mixin(button, DeathKeybindButtonMixin)
    end
end

function DeathType:SetDeathRecapToggleButtonEnabled(enabled)
    self.deathRecapToggleButton:SetEnabled(enabled)
end

function DeathType:ToggleDeathRecap()
    self.deathRecapToggleButton:OnClicked()
end

function DeathType:GetButtonByKeybind(keybind)
    if keybind == "DEATH_PRIMARY" then
        return self.buttons[1]
    elseif keybind == "DEATH_SECONDARY" then
        return self.buttons[2]
    else
        return self.buttons[3]
    end
end

function DeathType:GetButton(index)
    return self.buttons[index]
end

function DeathType:SetHidden(hidden)
    if self.control then
        self.control:SetHidden(hidden)
    end
end

function DeathType:IsHidden()
    return self.control:IsHidden()
end

function DeathType:SelectOption(keybind)
    local button = self:GetButtonByKeybind(keybind)
    if button then
        button:OnClicked()
    end
end

function DeathType:UpdateDisplay()

end

function DeathType:UpdateCyclicTimer()

end

local SOUL_GEM_FILLED_TEXT = GetString(SI_SOUL_GEM_FILLED)
local SOUL_GEM_ICON_MARKUP = "|t32:32:%s|t"
local SOUL_GEM_ICON_MARKUP_INHERIT_COLOR = "|t32:32:%s:inheritColor|t"

function ZO_Death_GetResurrectSoulGemText(level)
    local _, soulGemIcon, soulGemStackCount, soulGemQuality = GetSoulGemInfo(SOUL_GEM_TYPE_FILLED, level)
    local coloredFilledText
    local coloredSoulGemIconMarkup
    local success
    if soulGemStackCount > 0 then
        local qualityColor = GetItemQualityColor(soulGemQuality)
        coloredFilledText = qualityColor:Colorize(SOUL_GEM_FILLED_TEXT)
        coloredSoulGemIconMarkup = string.format(SOUL_GEM_ICON_MARKUP, soulGemIcon)
        success = true
    else
        soulGemIcon = select(2, GetSoulGemInfo(SOUL_GEM_TYPE_FILLED, level, false))
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

    if freeRevive and not inReviveCounterRaid then
        hereButton:SetEnabled(true)
        hereButton:SetText(GetString(SI_DEATH_PROMPT_HERE))
        return
    end

    local level = GetUnitEffectiveLevel("player")
    local name, soulGemIcon, soulGemStackCount, soulGemQuality = GetSoulGemInfo(SOUL_GEM_TYPE_FILLED, level)
    local enabled = (soulGemStackCount > 0 or freeRevive) and not self:AreButtonsDisabledDueToCyclicRespawn()
    hereButton:SetEnabled(enabled)

    local soulGemSuccess, coloredFilledText, coloredSoulGemIconMarkup = ZO_Death_GetResurrectSoulGemText(level)
    hereButton:SetText(zo_strformat(soulGemSuccess and SI_DEATH_PROMPT_HERE_GEM or SI_DEATH_PROMPT_HERE_GEM_FAILED, coloredFilledText, coloredSoulGemIconMarkup))
end

function DeathType:AreButtonsDisabledDueToCyclicRespawn()
    return IsQueuedForCyclicRespawn() and not IsResurrectPending()
end

function DeathType:LayoutWayshrineButton(wayshrineButton)
    if IsInImperialCity() then
        wayshrineButton:SetText(GetString(SI_DEATH_PROMPT_RELEASE))
    else
        wayshrineButton:SetText(GetString(SI_DEATH_PROMPT_WAYSHRINE))
    end
end

function DeathType:ApplyStyleToKeybindButton(button, isGamepad)
    local reviveTextLabel = button:GetNamedChild("ReviveText")
    local buttonTemplate
    if reviveTextLabel then
        buttonTemplate = ZO_GetPlatformTemplate("ZO_DeathReviveButton")
    else
        buttonTemplate = ZO_GetPlatformTemplate("ZO_DeathKeybindButton")
    end
    ApplyTemplateToControl(button, buttonTemplate)
    button:SetNormalTextColor(isGamepad and ZO_SELECTED_TEXT or ZO_NORMAL_TEXT)
    button:RefreshText()
end

function DeathType:ApplyStyle(isGamepad)
    for i, button in ipairs(self.buttons) do
        self:ApplyStyleToKeybindButton(button, isGamepad)
    end
    if self.deathRecapToggleButton then
        self:ApplyStyleToKeybindButton(self.deathRecapToggleButton, isGamepad)
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

    ava.messageLabel = control:GetNamedChild("Message")
    ava.messageLabel:SetText(GetString(SI_DEATH_PROMPT_AVA))
    ava.messageLabel:SetHidden(true)

    ava.timerCooldown = control:GetNamedChild("Timer")
    ava.timerCooldown:SetNumWarningSounds(5)
    ava.timerCooldown:SetHidden(true)

    ava.messageHidden = true

    control:SetHandler("OnUpdate", function() ava:UpdateDisplay() end)
    control:SetHandler("OnHide", function() ava.timerCooldown:Stop() end)

    return ava
end

function AvADeath:UpdateDisplay()
    local _, timeUntilAutoReleaseMs = GetDeathInfo()
    if timeUntilAutoReleaseMs > 0 and timeUntilAutoReleaseMs < 60000 then
        if self.messageHidden then
            self.messageHidden = false
            self.messageLabel:SetHidden(false)
            self.timerCooldown:Start(timeUntilAutoReleaseMs)
            self.timerCooldown:SetHidden(false)
        end
    else
        if not self.messageHidden then
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

    imperialPvP.messageLabel = control:GetNamedChild("Message")
    imperialPvP.messageLabel:SetText(GetString(SI_DEATH_PROMPT_AVA))
    imperialPvP.messageLabel:SetHidden(true)

    imperialPvP.timerCooldown = control:GetNamedChild("Timer")
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
    if timeUntilAutoReleaseMs > 0 and timeUntilAutoReleaseMs < 60000 then
        if self.messageHidden then
            self.messageHidden = false
            self.messageLabel:SetHidden(false)
            self.timerCooldown:Start(timeUntilAutoReleaseMs)
            self.timerCooldown:SetHidden(false)
        end
    else
        if not self.messageHidden then
            self.messageHidden = true
            self.messageLabel:SetHidden(true)
            self.timerCooldown:Stop()
            self.timerCooldown:SetHidden(true)
        end
    end

    local enabled = not self:AreButtonsDisabledDueToCyclicRespawn()
    self:GetButton(1):SetEnabled(enabled)
    self:GetButton(2):SetEnabled(enabled)
end

--Cyclic Respawn Death Type
-----------------

local CyclicRespawnDeath = DeathType:Subclass()

function CyclicRespawnDeath:New(control)
    local cyclicRespawn = DeathType.New(self, control)

    cyclicRespawn.cyclicRespawnLabel = control:GetNamedChild("RespawnTimerText")

    return cyclicRespawn
end

function CyclicRespawnDeath:UpdateCyclicTimer(timeLeft)
    if timeLeft then
        self.cyclicRespawnLabel:SetText(zo_strformat(SI_DEATH_PROMPT_WAITING_RELEASE, timeLeft))
    else
        self.cyclicRespawnLabel:SetText("")
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

function BGDeath:Initialize(control)
    DeathType.Initialize(self, control)

    local button1 = self:GetButton(1)
    button1:SetText(GetString(SI_DEATH_PROMPT_RELEASE))
    button1:SetCallback(JoinRespawnQueue)
end

function BGDeath:UpdateDisplay()
    self:GetButton(1):SetEnabled(not self:AreButtonsDisabledDueToCyclicRespawn())
end

--BG Spectator Death Type
-----------------

local BGSpectatorDeath = DeathType:Subclass()

function BGSpectatorDeath:Initialize(control)
    DeathType.Initialize(self, control)

    local button1 = self:GetButton(1)
    button1:SetText(GetString(SI_BATTLEGROUND_DEATH_START_SPECTATING_PROMPT))
    button1:SetCallback(function()
        local isSpectatorCameraActive = IsSpectatorCameraActive()
        --Close the death recap if we are activating the spectator camera
        if not isSpectatorCameraActive and DEATH_RECAP:IsWindowOpen() then
            self:ToggleDeathRecap()
        end

        local buttonSound = isSpectatorCameraActive and SOUNDS.BATTLEGROUND_SPECTATOR_CAMERA_CLOSE or SOUNDS.BATTLEGROUND_SPECTATOR_CAMERA_OPEN
        PlaySound(buttonSound)
        SetSpectatorCameraEnabled(not isSpectatorCameraActive)

        self:UpdateDisplay();
    end)
    
    local button2 = self:GetButton(2)
    button2:SetText(GetString(SI_BATTLEGROUND_DEATH_PREVIOUS_SPECTATOR_PROMPT))
    button2:SetCallback(function() 
        SpectatorCameraTargetPrev()
        PlaySound(SOUNDS.BATTLEGROUND_SPECTATOR_CAMERA_PREVIOUS)

        self:UpdateDisplay()
    end)

    local button3 = self:GetButton(3)
    button3:SetText(GetString(SI_BATTLEGROUND_DEATH_NEXT_SPECTATOR_PROMPT))
    button3:SetCallback(function() 
        SpectatorCameraTargetNext()
        PlaySound(SOUNDS.BATTLEGROUND_SPECTATOR_CAMERA_NEXT)

        self:UpdateDisplay()
    end)
end

function BGSpectatorDeath:UpdateDisplay()
    local isSpectatorActive = IsSpectatorCameraActive()
    local button1 = self:GetButton(1)
    button1:SetEnabled(not self:AreButtonsDisabledDueToCyclicRespawn())
    if isSpectatorActive then
        button1:SetText(GetString(SI_BATTLEGROUND_DEATH_STOP_SPECTATING_PROMPT))
    else
        button1:SetText(GetString(SI_BATTLEGROUND_DEATH_START_SPECTATING_PROMPT))
    end
    
    local button2 = self:GetButton(2)
    button2:SetEnabled(isSpectatorActive)
    button2:SetHidden(not isSpectatorActive)

    local button3 = self:GetButton(3)
    button3:SetEnabled(isSpectatorActive)
    button3:SetHidden(not isSpectatorActive)

    --Re-anchor the toggle recap button depending on whether or not the previous/next spectator buttons are visible
    if self.deathRecapToggleButton then
        self.deathRecapToggleButton:ClearAnchors()
        if isSpectatorActive then
            self.deathRecapToggleButton:SetAnchor(LEFT, button3, RIGHT, 20, 0)
        else
            self.deathRecapToggleButton:SetAnchor(LEFT, button1, RIGHT, 20, 0)
        end
    end

    self.control:GetNamedChild("Spectator"):SetHidden(not isSpectatorActive)

    local currentSpectatorIndex = GetSpectatorCameraTargetIndex()
    local spectatedPlayerName = self.control:GetNamedChild("SpectatorPlayerName")
    spectatedPlayerName:SetText(GetSpectatableUnitName(currentSpectatorIndex))

    local bg = self.control:GetNamedChild("SpectatorBackground")

    local SPECTATOR_BACKGROUNDS = {
        "EsoUI/Art/Battlegrounds/battleground_spectate_orange.dds",
        "EsoUI/Art/Battlegrounds/battleground_spectate_purple.dds",
        "EsoUI/Art/Battlegrounds/battleground_spectate_green.dds",
    }
    local SPECTATOR_BG_UNKNOWN = "EsoUI/Art/Battlegrounds/battleground_spectate_grey.dds"

    bg:SetTexture(SPECTATOR_BACKGROUNDS[GetUnitBattlegroundTeam("player")] or SPECTATOR_BG_UNKNOWN)
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
    end
end

--Resurrect Pending
-------------------

local ResurrectPending = DeathType:Subclass()

function ResurrectPending:New(control)
    local resurrect = DeathType.New(self, control)
    resurrect.messageLabel = control:GetNamedChild("Message")
    resurrect.timerCooldown = control:GetNamedChild("Timer")
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
    local text = zo_strformat(SI_DEATH_PROMPT_RESURRECT_TEXT, ZO_GetPrimaryPlayerName(resurrectRequesterDisplayName, resurrectRequesterCharacterName))
    self.messageLabel:SetText(text)
    self.timerCooldown:Start(timeLeftToAcceptMs)
end

--In Encounter
---------------

local InEncounter = DeathType:Subclass()

function InEncounter:New(control)
    local inEncounter = DeathType.New(self, control)
    inEncounter.message = control:GetNamedChild("Message")
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
local DEATH_TYPE_BATTLEGROUND = "BG"
local DEATH_TYPE_BATTLEGROUND_SPECTATOR = "BGSpectator"
local DEATH_TYPE_RESURRECT_PENDING = "Resurrect"
local DEATH_TYPE_IN_ENCOUNTER = "InEncounter"
local DEATH_TYPE_CYCLIC_RESPAWN = "CyclicRespawn"

local DEATH_PROMPT_DELAY_MS = 2000

local Death = ZO_CallbackObject:Subclass()

function Death:New(control)
    local death = ZO_CallbackObject.New(self)

    death.control = control
    death.waitingToShowPrompt = false
    death.isPlayerDead = IsUnitDead("player")

    death.cyclicRespawnTimer = control:GetNamedChild("CyclicRespawnTimer")
    death:InitializeCyclicRespawnTimer()

    death.types = {}
    death.types[DEATH_TYPE_AVA] = AvADeath:New(control:GetNamedChild("AvA"))
    death.types[DEATH_TYPE_IMPERIAL_PVP] = ImperialPvPDeath:New(control:GetNamedChild("ImperialPvP"))
    death.types[DEATH_TYPE_IMPERIAL_PVE] = ImperialPvEDeath:New(control:GetNamedChild("ImperialPvE"))
    death.types[DEATH_TYPE_BATTLEGROUND] = BGDeath:New(control:GetNamedChild("BG"))
    death.types[DEATH_TYPE_BATTLEGROUND_SPECTATOR] = BGSpectatorDeath:New(control:GetNamedChild("BGSpectator"))
    death.types[DEATH_TYPE_RELEASE_ONLY] = ReleaseOnlyDeath:New(control:GetNamedChild("ReleaseOnly"))
    death.types[DEATH_TYPE_TWO_OPTION] = TwoOptionDeath:New(control:GetNamedChild("TwoOption"))
    death.types[DEATH_TYPE_RESURRECT_PENDING] = ResurrectPending:New(control:GetNamedChild("Resurrect"))
    death.types[DEATH_TYPE_IN_ENCOUNTER] = InEncounter:New(control:GetNamedChild("InEncounter"))
    death.types[DEATH_TYPE_CYCLIC_RESPAWN] = CyclicRespawnDeath:New(control:GetNamedChild("CyclicRespawn"))

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
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_PLAYER_QUEUED_FOR_CYCLIC_RESPAWN, UpdateDisplay)
    EVENT_MANAGER:RegisterForEvent("Death", EVENT_RAID_REVIVE_COUNTER_UPDATE, function() 
        if self.currentType then
            self.types[self.currentType]:UpdateDisplay()
        end
    end)
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("StateChanged", function(newState, oldState)
        if self.currentType then
            self:UpdateDisplay()
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
    if IsResurrectPending() then
        return DEATH_TYPE_RESURRECT_PENDING
    else
        local isEncounterInProgress, isAVADeath, isBattleGroundDeath, isReleaseOnly, _, _, isRaidDeath, _, respawnQueueDuration = select(5, GetDeathInfo())
        local useCyclicRespawn = respawnQueueDuration > 0
        local deathType
        if useCyclicRespawn and IsQueuedForCyclicRespawn() then
            deathType = DEATH_TYPE_CYCLIC_RESPAWN
        elseif IsInImperialCity() then -- Special snowflake scenario
            if isReleaseOnly then
                deathType = DEATH_TYPE_RELEASE_ONLY
            else
                deathType = isAVADeath and DEATH_TYPE_IMPERIAL_PVP or DEATH_TYPE_IMPERIAL_PVE
            end
        elseif isBattleGroundDeath then
            if DoesBattlegroundHaveLimitedPlayerLives(GetCurrentBattlegroundId()) and GetLocalPlayerBattlegroundLivesRemaining() == 0 then
                deathType = DEATH_TYPE_BATTLEGROUND_SPECTATOR
            else
                deathType = DEATH_TYPE_BATTLEGROUND
            end
        elseif isAVADeath then 
            deathType = DEATH_TYPE_AVA
        elseif isEncounterInProgress then
            deathType = DEATH_TYPE_IN_ENCOUNTER
        elseif isRaidDeath then
            if isReleaseOnly then
                deathType = DEATH_TYPE_RELEASE_ONLY
            else
                deathType = DEATH_TYPE_TWO_OPTION
            end
        elseif isReleaseOnly then 
            deathType = DEATH_TYPE_RELEASE_ONLY
        else
            deathType = DEATH_TYPE_TWO_OPTION
        end
        return deathType, useCyclicRespawn
    end
end

function Death:SetDeathRecapToggleButtonsEnabled(enabled)
    for _, deathType in pairs(self.types) do
        deathType:SetDeathRecapToggleButtonEnabled(enabled)
    end
end

function Death:UpdateDisplay()
    if self.waitingToShowPrompt then
        return
    end

    if not self.isPlayerDead and self.cyclicRespawnTimer.isRunning then
        self:StopCyclicRespawnTimer()
    end
    DEATH_FRAGMENT:SetHiddenForReason("NotShowingAsDead", not self.isPlayerDead)
    
    local nextType, useCyclicRespawn
    if self.isPlayerDead then
        nextType, useCyclicRespawn = self:GetDeathType()
    end

    local deathTypeChanged = false
    if self.currentType ~= nextType then
        if self.currentType then
            self.types[self.currentType]:SetHidden(true)
        end

        if nextType then
            self.types[nextType]:SetHidden(false)
        end

        self.currentType = nextType
        deathTypeChanged = true
    end

    if useCyclicRespawn and not self.cyclicRespawnTimer.isRunning then
        self:StartCyclicRespawnTimer()
    end

    if self.currentType then
        self.types[self.currentType]:UpdateDisplay()
        INSTANCE_KICK_WARNING_DEAD:SetHiddenForReason("deathHidden", false)
    else
        INSTANCE_KICK_WARNING_DEAD:SetHiddenForReason("deathHidden", true)
    end

    self:UpdateBindingLayer()

    if deathTypeChanged then
        self:FireCallbacks("OnDeathTypeChanged", nextType)
    end
end

function Death:UpdateBindingLayer()
    if not self.control:IsHidden() and self.currentType ~= nil then
        InsertNamedActionLayerAbove("Death", GetString(SI_KEYBINDINGS_LAYER_GENERAL))
    else
        RemoveActionLayerByName("Death")
    end
end

function Death:ApplyStyle()
    local isGamepad = IsInGamepadPreferredMode()
    for _, deathType in pairs(self.types) do
        deathType:ApplyStyle(isGamepad)
    end
    self.types[DEATH_TYPE_IN_ENCOUNTER]:ApplyTemplateToMessage(ZO_GetPlatformTemplate("ZO_DeathInEncouterLoadingLabel"))
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_Death"))
end

--Cyclic Respawn Timer

function Death:InitializeCyclicRespawnTimer()
    self.cyclicRespawnTimer.isRunning = false
    self.cyclicRespawnTimer.loadBar = self.cyclicRespawnTimer:GetNamedChild("LoadBar")
end

function Death:StartCyclicRespawnTimer()
    self.cyclicRespawnTimer.isRunning = true
    self.cyclicRespawnTimer:SetHidden(false)
    self:UpdateCyclicRespawnTimer()
    EVENT_MANAGER:RegisterForUpdate("CyclicRespawnTimer", 0, function() self:UpdateCyclicRespawnTimer() end)
end

function Death:UpdateCyclicRespawnTimer()
    local respawnQueueDuration, respawnQueueTimeLeft = select(13, GetDeathInfo())
    local screenWidth = GuiRoot:GetWidth()
    local progress = 0
    if respawnQueueDuration > 0 then
        progress = (respawnQueueDuration - respawnQueueTimeLeft) / respawnQueueDuration
    end
    self.cyclicRespawnTimer.loadBar:SetWidth(screenWidth * progress)

    if IsQueuedForCyclicRespawn() then
        local secondsToWait = respawnQueueTimeLeft / 1000
        secondsToWait = zo_max(secondsToWait, 0)
        self.types[self.currentType]:UpdateCyclicTimer(ZO_FormatTimeAsDecimalWhenBelowThreshold(secondsToWait))
    else
        self.types[self.currentType]:UpdateCyclicTimer()
    end
end

function Death:StopCyclicRespawnTimer()
    self.cyclicRespawnTimer.isRunning = false
    self.cyclicRespawnTimer:SetHidden(true)
    EVENT_MANAGER:UnregisterForUpdate("CyclicRespawnTimer")
end

--bindings

function Death:SelectOption(keybind)
    if self.currentType then
        self.types[self.currentType]:SelectOption(keybind)
    end
end

function Death:ToggleDeathRecap()
    if self.currentType then
        self.types[self.currentType]:ToggleDeathRecap()
    end
end

--Events

function Death:OnPlayerAlive()
    self.isPlayerDead = false
    self.waitingToShowPrompt = false
    EVENT_MANAGER:UnregisterForUpdate("WaitToShowDeath")
    self:UpdateDisplay()

    --Make sure we take the player out of the spectator camera if they respawn while it's active
    if IsSpectatorCameraActive() then
        SetSpectatorCameraEnabled(false)
    end
end

function Death:OnPlayerDead()
    self.isPlayerDead = true
    if not self.waitingToShowPrompt then
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
    if DEATH then
        DEATH:UpdateBindingLayer()
    end
end

function ZO_Death_OnEffectivelyShown(self)
    if DEATH then
        DEATH:UpdateBindingLayer()
    end
end