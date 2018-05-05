local COUNTDOWN_TIMER_START_MS = 5000
local COUNTDOWN_TIMER_END_BATTLEGROUND_MS = ZO_ONE_MINUTE_IN_MILLISECONDS

--------------------
--Battleground HUD Fragment
--------------------

local BattlegroundHUDFragment = ZO_HUDFadeSceneFragment:Subclass()

function BattlegroundHUDFragment:New(...)
    return ZO_HUDFadeSceneFragment.New(self, ...)
end

function BattlegroundHUDFragment:Initialize(control)
    ZO_HUDFadeSceneFragment.Initialize(self, control)

    self.currentBattlegroundTimeMS = 0

    self.keybindButton = control:GetNamedChild("KeybindButton")
    ZO_KeybindButtonTemplate_OnInitialized(self.keybindButton)
    self.keybindButton:SetKeybind("SHOW_BATTLEGROUND_SCOREBOARD")
    
    self.headerLabel = control:GetNamedChild("Header")

    self.stateLabel = control:GetNamedChild("State")
    
    self.battlegroundScoreHudControl = control:GetNamedChild("BattlegroundScoreHud")

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    control:RegisterForEvent(EVENT_BATTLEGROUND_RULESET_CHANGED, function() self:OnBattlegroundRulesetChanged() end)

    self:InitializePlatformStyle()
end

do
    local KEYBOARD_STYLE = 
    {
        hudTemplate = "ZO_BattlegroundHudTopLevel_Keyboard",
        keybindButtonTemplate = "ZO_KeybindButton_Keyboard_Template",
    }

    local GAMEPAD_STYLE = 
    {
        hudTemplate = "ZO_BattlegroundHudTopLevel_Gamepad",
        keybindButtonTemplate = "ZO_KeybindButton_Gamepad_Template",
    }

    function BattlegroundHUDFragment:InitializePlatformStyle()
        self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end
end

function BattlegroundHUDFragment:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.control, style.hudTemplate)
    ApplyTemplateToControl(self.keybindButton, style.keybindButtonTemplate)
    self.headerLabel:SetText(GetString(SI_BATTLEGROUND_HUD_HEADER))
end

function BattlegroundHUDFragment:OnPlayerActivated()
    self:CheckForBattleground()
end

function BattlegroundHUDFragment:OnBattlegroundRulesetChanged()
    self:CheckForBattleground()
end

function BattlegroundHUDFragment:CheckForBattleground()
    local currentBattlegroundId = GetCurrentBattlegroundId()
    if currentBattlegroundId ~= 0 then
        EVENT_MANAGER:RegisterForUpdate(self.control:GetName(), 10, function() self:OnUpdate() end)
    else
        EVENT_MANAGER:UnregisterForUpdate(self.control:GetName())
    end
end

function BattlegroundHUDFragment:GetFormattedTimer()
    return ZO_FormatTime(zo_ceil(self.currentBattlegroundTimeMS / 1000), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
end

do
    local PRE_SHUTDOWN_WARNING_TIME_MS = 10000
    local PRE_SHUTDOWN_WARNING_TIME_S = zo_round(PRE_SHUTDOWN_WARNING_TIME_MS / 1000)

    function BattlegroundHUDFragment:OnUpdate()
        local battlegroundState = GetCurrentBattlegroundState()
        local previousBattlegroundTime = self.currentBattlegroundTimeMS
        self.currentBattlegroundTimeMS = GetCurrentBattlegroundStateTimeRemaining()
        local previousShutdownTimerMS = self.shutdownTimerMS
        self.shutdownTimerMS = GetCurrentBattlegroundShutdownTimer()
    
        local text
        if battlegroundState == BATTLEGROUND_STATE_PREGAME then
            text = GetString(SI_BATTLEGROUND_STATE_PREGAME)
        elseif battlegroundState == BATTLEGROUND_STATE_STARTING then
            if IsCurrentBattlegroundStateTimed() then
                if self.currentBattlegroundTimeMS <= COUNTDOWN_TIMER_START_MS then
                    text = GetString(SI_BATTLEGROUND_STATE_STARTING_COUNTDOWN)
                    if previousBattlegroundTime > COUNTDOWN_TIMER_START_MS then
                        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_COUNTDOWN_TEXT, SOUNDS.BATTLEGROUND_COUNTDOWN_FINISH )
                        messageParams:SetLifespanMS(COUNTDOWN_TIMER_START_MS)
                        messageParams:SetIconData(GetCountdownBattlegroundAllianceSymbolIcon(GetUnitBattlegroundAlliance("player")))
                        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COUNTDOWN)
                        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
                    end
                else
                    local gameTypeString = GetString("SI_BATTLEGROUNDGAMETYPE", GetBattlegroundGameType(GetCurrentBattlegroundId()))
                    text = zo_strformat(SI_BATTLEGROUND_STATE_STARTING, gameTypeString, self:GetFormattedTimer())
                end
            end
        elseif battlegroundState == BATTLEGROUND_STATE_RUNNING then
            if IsCurrentBattlegroundStateTimed() then
                local gameTypeString = GetString("SI_BATTLEGROUNDGAMETYPE", GetBattlegroundGameType(GetCurrentBattlegroundId()))
                gameTypeString = ZO_NORMAL_TEXT:Colorize(gameTypeString)
                text = zo_strformat(SI_BATTLEGROUND_STATE_RUNNING, gameTypeString, self:GetFormattedTimer())

                if self.currentBattlegroundTimeMS <= COUNTDOWN_TIMER_END_BATTLEGROUND_MS and previousBattlegroundTime > COUNTDOWN_TIMER_END_BATTLEGROUND_MS then
                    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_MAJOR_TEXT, SOUNDS.BATTLEGROUND_ONE_MINUTE_WARNING)
                    messageParams:SetText(GetString(SI_BATTLEGROUND_WARNING_ONE_MINUTE_REMAINING))
                    messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_BATTLEGROUND_MINUTE_WARNING)
                    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
                end
            end
            if previousShutdownTimerMS and self.shutdownTimerMS then                
                if previousShutdownTimerMS >= PRE_SHUTDOWN_WARNING_TIME_MS and self.shutdownTimerMS < PRE_SHUTDOWN_WARNING_TIME_MS then
                    local message = zo_strformat(SI_BATTLEGROUND_SHUTDOWN_IMMINENT, PRE_SHUTDOWN_WARNING_TIME_S)
                    CHAT_SYSTEM:AddMessage(message)
                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, message)
                end
            end
        elseif battlegroundState == BATTLEGROUND_STATE_FINISHED then
            if IsCurrentBattlegroundStateTimed() then
                text = zo_strformat(SI_BATTLEGROUND_STATE_FINISHED, self:GetFormattedTimer())
            end
        end

        if text then
            self.stateLabel:SetHidden(false)
            self.stateLabel:SetText(text)
        else
            self.stateLabel:SetHidden(true)
        end
    end
end

function BattlegroundHUDFragment:GetStateText()
    return self.stateLabel:GetText()
end

--[[ xml functions ]]--

function ZO_BattlegroundHUDFragmentTopLevel_Initialize(control)
    BATTLEGROUND_HUD_FRAGMENT = BattlegroundHUDFragment:New(control)
end
