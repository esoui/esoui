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
    }

    local INSTANCE_KICK_GAMEPAD_STYLE =
    {
        font = "ZoFontGamepad34",
    }

    function ZO_InstanceKickWarning:ApplyPlatformStyle(style)
        self.kickLabel:SetFont(style.font)
    end

    function ZO_InstanceKickWarning:Initialize(control)
        self.control = control

        local function OnPlayerActivated()
            local timeRemaining, totalTime = GetInstanceKickTime()
            self:OnInstanceKickTimeUpdate(timeRemaining, totalTime)
        end

        local function OnInstanceKickTimeUpdate(event, timeRemaining, totalTime)
            if not timeRemaining then
                timeRemaining, totalTime = GetInstanceKickTime()
            elseif not totalTime then
                totalTime = timeRemaining
            end

            self:OnInstanceKickTimeUpdate(timeRemaining, totalTime)
        end

        local function OnGroupInviteUpdate()
            self:UpdateVisibility()
        end

        self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
        self.control:RegisterForEvent(EVENT_INSTANCE_KICK_TIME_UPDATE, OnInstanceKickTimeUpdate)
        self.control:RegisterForEvent(EVENT_GROUP_INVITE_RECEIVED, OnGroupInviteUpdate)
        self.control:RegisterForEvent(EVENT_GROUP_INVITE_REMOVED, OnGroupInviteUpdate)

        local container = self.control:GetNamedChild("Container")
        self.timerCooldown = container:GetNamedChild("Timer")
        self.timerCooldown:SetNumWarningSounds(5)
        self.kickLabel = container:GetNamedChild("Text")
        ZO_PlatformStyle:New(function(...) self:ApplyPlatformStyle(...) end, INSTANCE_KICK_KEYBOARD_STYLE, INSTANCE_KICK_GAMEPAD_STYLE)

        if IsPlayerActivated() then
            OnInstanceKickTimeUpdate()
        end
    end
end

function ZO_InstanceKickWarning:OnInstanceKickTimeUpdate(timeRemaining, totalTime)
    if timeRemaining and totalTime and timeRemaining > 0 and totalTime > 0 then
        self.timerCooldown:Start(timeRemaining)
        self.kickPending = true
        self:UpdateVisibility()
        
        -- give an alert text to explain why being removed from the instance
        if(IsUnitGrouped("player")) then
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, GetString(SI_INSTANCE_KICK_WARNING_GROUPED))
        else
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GENERAL_ALERT_ERROR, GetString(SI_INSTANCE_KICK_WARNING_UNGROUPED))
        end
    else
        self.timerCooldown:Stop()
        self.kickPending = false
        self:UpdateVisibility()
    end
end

function ZO_InstanceKickWarning:SetHidden(hidden)
    self.control:SetHidden(hidden)
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
