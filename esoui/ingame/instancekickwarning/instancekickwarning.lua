-- ZO_InstanceKickWarning Base Object

local ZO_InstanceKickWarning = ZO_Object:Subclass()

function ZO_InstanceKickWarning:New(control)
    local instanceKickWarning = ZO_Object.New(self)
    instanceKickWarning:Initialize(control)
    return instanceKickWarning
end

do
    local INSTANCE_KICK_KEYBOARD_STYLE =
    {
        font = "ZoFontWinH2",
        anchorOffsetY = ZO_COMMON_INFO_DEFAULT_KEYBOARD_BOTTOM_OFFSET_Y,
    }

    local INSTANCE_KICK_GAMEPAD_STYLE =
    {
        font = "ZoFontGamepad34",
        anchorOffsetY = ZO_COMMON_INFO_DEFAULT_GAMEPAD_BOTTOM_OFFSET_Y,
    }

    function ZO_InstanceKickWarning:ApplyPlatformStyle(style)
        self.kickLabel:SetFont(style.font)

        self.container:ClearAnchors()
        self.container:SetAnchor(BOTTOM, nil, BOTTOM, 0, style.anchorOffsetY)
        ApplyTemplateToControl(self.keybindButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    end

    function ZO_InstanceKickWarning:Initialize(control)
        self.control = control

        local function OnPlayerActivated()
            local timeRemaining, totalTime = GetInstanceKickTime()
            self:OnInstanceKickTimeUpdate(timeRemaining, totalTime)
        end

        local function OnInstanceKickTimeUpdate(event, timeRemaining)
            local totalTime = timeRemaining
            self:OnInstanceKickTimeUpdate(timeRemaining, totalTime)
        end

        local function OnGroupInviteUpdate()
            self:UpdateVisibility()
        end

        self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
        self.control:RegisterForEvent(EVENT_INSTANCE_KICK_TIME_UPDATE, OnInstanceKickTimeUpdate)
        self.control:RegisterForEvent(EVENT_GROUP_INVITE_RECEIVED, OnGroupInviteUpdate)
        self.control:RegisterForEvent(EVENT_GROUP_INVITE_REMOVED, OnGroupInviteUpdate)

        self.container = self.control:GetNamedChild("Container")
        self.keybindButton = self.container:GetNamedChild("KeybindButton")
        self.keybindButton:SetKeybind("INSTANCE_KICK_LEAVE_INSTANCE")
        self.keybindButton:SetText(GetString(SI_INSTANCE_KICK_LEAVE_NOW_KEYBIND))

        self.timerCooldown = self.container:GetNamedChild("Timer")
        self.timerCooldown:SetNumWarningSounds(5)
        self.kickLabel = self.container:GetNamedChild("Text")
        ZO_PlatformStyle:New(function(...) self:ApplyPlatformStyle(...) end, INSTANCE_KICK_KEYBOARD_STYLE, INSTANCE_KICK_GAMEPAD_STYLE)

        if IsPlayerActivated() then
            OnInstanceKickTimeUpdate()
        end
    end
end

function ZO_InstanceKickWarning:OnInstanceKickTimeUpdate(timeRemaining, totalTime)
    if timeRemaining and totalTime and timeRemaining > 0 and totalTime > 0 then
        if not self.kickPending then
            self.timerCooldown:Start(timeRemaining)
            self.kickPending = true
        end
        self:UpdateVisibility()
        
        -- give an alert text to explain why being removed from the instance
        local kickReason = GetInstanceKickReason()
        if GetInstanceKickReason() == INSTANCE_KICK_REASON_NOT_IN_REQUIRED_GROUP then
            if IsUnitGrouped("player") then
                ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, GetString(SI_INSTANCE_KICK_WARNING_GROUPED))
            else
                ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, GetString(SI_INSTANCE_KICK_WARNING_UNGROUPED))
            end
        else
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.INSTANCE_SHUTDOWN, GetString(SI_INSTANCE_KICK_WARNING_SHUTDOWN))
        end
    else
        self.timerCooldown:Stop()
        self.kickPending = false
        self:UpdateVisibility()
    end
end

-- There are two instance kick controls, and the order they update their visibility may be arbitrary
-- Starting value is set to 1 due to Dead using Hidden Reasons, and therefore being set to shown by default to force a RefreshVisibility
local g_showingCount = 1

function ZO_InstanceKickWarning:SetHidden(hidden)
    if hidden ~= self.control:IsHidden() then
        self.control:SetHidden(hidden)

        local showKeybind = not hidden and CanExitInstanceImmediately()
        if showKeybind then
            self.keybindButton:SetHidden(false)
            if g_showingCount == 0 then
                PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_INSTANCE_KICK_WARNING))
            end
            g_showingCount = g_showingCount + 1
        else
            self.keybindButton:SetHidden(true)
            g_showingCount = g_showingCount - 1
            if g_showingCount == 0 then
                RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_INSTANCE_KICK_WARNING))
            end
        end
    end
end


-- ZO_InstanceKickWarning_Alive...Used when the player is alive (in shared info area)

local ZO_InstanceKickWarning_Alive = ZO_InstanceKickWarning:Subclass()

function ZO_InstanceKickWarning_Alive:Initialize(control)
    ZO_InstanceKickWarning.Initialize(self, control)
    SHARED_INFORMATION_AREA:AddInstanceKick(self)
end

function ZO_InstanceKickWarning_Alive:UpdateVisibility()
    local groupInviterName = GetGroupInviteInfo()
    local hasInvitePending = groupInviterName ~= ""

    local hideKickWarning = hasInvitePending or not self.kickPending
    SHARED_INFORMATION_AREA:SetHidden(self, hideKickWarning)
end

-- ZO_InstanceKickWarning_Dead...Used when the player is dead
local ZO_InstanceKickWarning_Dead = ZO_InstanceKickWarning:Subclass()

function ZO_InstanceKickWarning_Dead:Initialize(control)
    self.hiddenReasons = ZO_HiddenReasons:New()
    ZO_InstanceKickWarning.Initialize(self, control)
end

function ZO_InstanceKickWarning_Dead:UpdateVisibility()
    self:SetHiddenForReason("kickPending", not self.kickPending)
end

function ZO_InstanceKickWarning_Dead:RefreshVisible()
    self:SetHidden(self.hiddenReasons:IsHidden())
end

function ZO_InstanceKickWarning_Dead:SetHiddenForReason(reason, hidden)
    if self.hiddenReasons:SetHiddenForReason(reason, hidden) then
        self:RefreshVisible()
    end
end

-- Global functions

function ZO_InstanceKickWarning_Alive_OnInitialized(control)
    INSTANCE_KICK_WARNING_ALIVE = ZO_InstanceKickWarning_Alive:New(control)
end

function ZO_InstanceKickWarning_Dead_OnInitialized(control)
    INSTANCE_KICK_WARNING_DEAD = ZO_InstanceKickWarning_Dead:New(control)
end
