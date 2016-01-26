local NotificationIcons_Console = ZO_Object:Subclass()

function NotificationIcons_Console:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function NotificationIcons_Console:Initialize(control)
    self.control = control
    self.numUnread = 0
    self.numNotifications = 0
    self.animToPlay = nil
    self.waitingToTrigger = false
    self.fadingOut = false
    self.notificationFrameTimeMS = 0
    self.fadeStartTimeMS = 0
    self.fadeTimeMS = 10000
    self.reshowTimeMS = 150000

    EVENT_MANAGER:RegisterForEvent("NotificationIcons_Console", EVENT_MAIL_NUM_UNREAD_CHANGED, function(_, numUnread) self:OnNumUnreadMailChanged(numUnread) end)
    control:SetHandler("OnUpdate", function() self:OnUpdate() end)

    --setup the animation for the control as a whole
    local function FadeStop() 
        if(self.fadingOut) then
            ALERT_MESSAGES_GAMEPAD:SetHoldDisplayingEntries(false)
            self.fadingOut = false
            self.notificationFrameTimeMS = GetFrameTimeMilliseconds()
        else
            if(self.animToPlay) then 
                self.animToPlay:PlayFromStart() 
            else
                self.fadeStartTimeMS = GetFrameTimeMilliseconds()
            end
        end
    end

    self.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ConsoleNotificationIconsFade", control)
    self.fadeTimeline:SetHandler("OnStop", FadeStop)

    --setup the animation on the mail and notification icons
    local function StartFadeTimer()
        self.animToPlay = nil
        self.fadeStartTimeMS = GetFrameTimeMilliseconds()
    end    

    self.mailIcon = control:GetNamedChild("Mail")
    self.mailPulseTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ConsoleNotificationPulse", self.mailIcon)
    self.mailPulseTimeline:SetHandler("OnStop", StartFadeTimer)

    --setup the animation on the notifications icon
    self.notificationsIcon = control:GetNamedChild("Notifications")
    self.notificationPulseTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ConsoleNotificationPulse", self.notificationsIcon)
    self.notificationPulseTimeline:SetHandler("OnStop", StartFadeTimer)

end

function NotificationIcons_Console:OnNumUnreadMailChanged(numUnread)
    if(numUnread > self.numUnread and IsPlayerActivated()) then
        self.animToPlay = self.mailPulseTimeline
        self.notificationFrameTimeMS = GetFrameTimeMilliseconds()
        self.waitingToTrigger = true
    end

    self.numUnread = numUnread
end

function NotificationIcons_Console:OnNumNotificationsChanged(numNotifications)
    if(numNotifications > self.numNotifications and IsPlayerActivated()) then
        self.animToPlay = self.notificationPulseTimeline
        self.notificationFrameTimeMS = GetFrameTimeMilliseconds()
        self.waitingToTrigger = true
    end

    self.numNotifications = numNotifications
end

function NotificationIcons_Console:OnUpdate()
    local time = GetFrameTimeMilliseconds()

    if(self.fadeStartTimeMS > 0) then
        -- trigger fade out at the end of fadeStartTimeMS or if a new alert text comes in
        if(ALERT_MESSAGES_GAMEPAD:HasActiveEntries() or
        (time > self.fadeStartTimeMS + self.fadeTimeMS)) then
            self.fadeStartTimeMS = 0
            self.fadeTimeline:PlayFromEnd()
            self.fadingOut = true
        end

    -- trigger fade in of the icons when the alert text queue empties
    elseif(self.waitingToTrigger) then
        if(self.notificationFrameTimeMS < time) and (not ALERT_MESSAGES_GAMEPAD:HasActiveEntries()) then
            self.fadeTimeline:PlayFromStart()
            self.waitingToTrigger = false
            self.notificationFrameTimeMS = time
            ALERT_MESSAGES_GAMEPAD:SetHoldDisplayingEntries(true)
        end

    -- retrigger the icons to show every reshowTimeMS if there are unread messages or notifications
    elseif((self.numUnread > 0 or self.numNotifications > 0) and (time > self.notificationFrameTimeMS + self.reshowTimeMS)) then
        self.notificationFrameTimeMS = time
        self.waitingToTrigger = true
    end
end

function ZO_NotificationIcons_Gamepad_Initialize(control)
    NOTIFICATION_ICONS_CONSOLE = NotificationIcons_Console:New(control)
end