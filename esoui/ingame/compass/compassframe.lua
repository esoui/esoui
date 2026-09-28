ZO_COMPASS_FRAME_HEIGHT_KEYBOARD = 39
ZO_COMPASS_FRAME_HEIGHT_GAMEPAD = 24
ZO_COMPASS_FRAME_HEIGHT_BOSSBAR_GAMEPAD = 23

local MIN_WIDTH = 400
local MAX_WIDTH = 800

local CompassFrame = ZO_InitializingObject:Subclass()

function CompassFrame:Initialize(control)
    self.control = control
    self.compassHidden = false
    self.bossBarHiddenReasons = ZO_HiddenReasons:New()
    self.compassReady = false
    self.bossBarReady = false  

    COMPASS_FRAME_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:OnPlayerActivated() end)
    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:UpdateWidth() end)
    
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_CompassFrame"))

    local COMPASS_OPTIONS =
    {
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.ENUM,
            name = GetString(SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS_TOOLTIP),
            key = "ActiveQuests",
            valueStringPrefix = "SI_COMPASSACTIVEQUESTSCHOICE",
            values = { COMPASS_ACTIVE_QUESTS_CHOICE_OFF, COMPASS_ACTIVE_QUESTS_CHOICE_ON, COMPASS_ACTIVE_QUESTS_CHOICE_FOCUSED, },
            valueTooltips = { GetString(SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS_OFF_RESTRICTION), "", GetString(SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS_FOCUSED_RESTRICTION) },
            defaultValue = function()
                return tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_ACTIVE_QUESTS))
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_ACTIVE_QUESTS, tostring(value))
                end
            end,
        },
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_INTERFACE_OPTIONS_SHOW_QUEST_BESTOWERS),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_SHOW_QUEST_BESTOWERS_TOOLTIP),
            key = "QuestBestowers",
            defaultValue = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS)
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS, tostring(value))
                end
            end,
        },
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_INTERFACE_OPTIONS_COMPASS_QUEST_GIVERS),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_COMPASS_QUEST_GIVERS_TOOLTIP),
            key = "CompassQuestGivers",
            defaultValue = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_COMPASS_QUEST_GIVERS)
            end,
            enabled = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS)
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_QUEST_GIVERS, tostring(value))
                end
            end,
        },
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_INTERFACE_OPTIONS_COMPASS_COMPANION),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_COMPASS_COMPANION_TOOLTIP),
            key = "Companions",
            defaultValue = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_COMPASS_COMPANION)
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_COMPANION, tostring(value))
                end
            end,
        },
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_INTERFACE_OPTIONS_COMPASS_TARGET_MARKERS),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_COMPASS_TARGET_MARKERS_TOOLTIP),
            key = "TargetMarkers",
            defaultValue = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_COMPASS_TARGET_MARKERS)
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_TARGET_MARKERS, tostring(value))
                end
            end,
        },
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_INTERFACE_OPTIONS_COMPASS_DISTANCE_TRACKING),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_COMPASS_DISTANCE_TRACKING_TOOLTIP),
            key = "DistanceTracking",
            defaultValue = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_COMPASS_DISTANCE_TRACKING)
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_DISTANCE_TRACKING, tostring(value))
                end
            end,
        }
    }

    local elementName = GetString(SI_HUD_EDITOR_COMPASS)
    self.keyboardHUDElement = HUD_MANAGER:RegisterKeyboardElement(self.control, elementName, { defaultAnchor = ZO_Anchor:New(TOP, nil, TOP, 0, 40) }, COMPASS_OPTIONS)
    self.gamepadHUDElement = HUD_MANAGER:RegisterGamepadElement(self.control, elementName, { defaultAnchor = ZO_Anchor:New(TOP, nil, TOP, 0, 58) }, COMPASS_OPTIONS)

    self:ApplyStyle() -- Setup initial visual style based on current mode.
    self.control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:OnGamepadPreferredModeChanged() end)
end

function CompassFrame:ApplyStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ZO_CompassFrame"))

    local gamepadMode = IsInGamepadPreferredMode()
    local center = self.control:GetNamedChild("Center")
    center:GetNamedChild("TopMungeOverlay"):SetHidden(gamepadMode)
    center:GetNamedChild("BottomMungeOverlay"):SetHidden(gamepadMode)

    if gamepadMode then
        if self.bossBarReady and self.bossBarActive then
            local frame = self.control
            frame:SetHeight(ZO_COMPASS_FRAME_HEIGHT_BOSSBAR_GAMEPAD)
            frame:GetNamedChild("Left"):SetHeight(ZO_COMPASS_FRAME_HEIGHT_BOSSBAR_GAMEPAD)
            frame:GetNamedChild("Right"):SetHeight(ZO_COMPASS_FRAME_HEIGHT_BOSSBAR_GAMEPAD)
        end
        self.gamepadHUDElement:RevertOffsetModifications()
    else
        self.keyboardHUDElement:RevertOffsetModifications()
    end
end

function CompassFrame:OnGamepadPreferredModeChanged()
    self:ApplyStyle()
end

function CompassFrame:UpdateWidth()
    local screenWidth = GuiRoot:GetWidth()
    self.control:SetWidth(zo_clamp(screenWidth * .35, MIN_WIDTH, MAX_WIDTH))
end

function CompassFrame:RefreshVisible()
    if(self.compassReady and self.bossBarReady) then
        local bossBarIsHidden = self.bossBarHiddenReasons:IsHidden() or not self.bossBarActive
        local compassIsHidden = self.compassHidden or not bossBarIsHidden
        
        local frameWasHidden = self.control:IsHidden()
        local frameIsHidden = bossBarIsHidden and compassIsHidden
        local frameChanged = frameWasHidden ~= frameIsHidden

        --if the frame is showing or hiding, or the frame isn't even shown, do the transition
        --between the boss bar and compass instantly
        if(frameChanged or frameIsHidden) then
            if(self.crossFadeTimeline) then
                self.crossFadeTimeline:Stop()
            end
            COMPASS_FRAME_FRAGMENT:SetHiddenForReason("contentsHidden", frameIsHidden)
            ZO_BossBar:SetAlpha(1)
            ZO_Compass:SetAlpha(1)
            ZO_BossBar:SetHidden(bossBarIsHidden)
            ZO_Compass:SetHidden(compassIsHidden)
        else
            --otherwise animate it if it changed
            local bossBarWasHidden = ZO_BossBar:IsHidden()
            local compassWasHidden = ZO_Compass:IsHidden()

            if(bossBarWasHidden ~= bossBarIsHidden or compassIsHidden ~= compassWasHidden) then
                if(not self.crossFadeTimeline) then
                    self.crossFadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_CompassFrameCrossFade")
                    self.crossFadeTimeline:GetAnimation(1):SetAnimatedControl(ZO_BossBar)
                    self.crossFadeTimeline:GetAnimation(2):SetAnimatedControl(ZO_Compass)
                end
                if(bossBarIsHidden) then
                    if(self.crossFadeTimeline:IsPlaying()) then
                        self.crossFadeTimeline:PlayForward()
                    else
                        self.crossFadeTimeline:PlayFromStart()
                    end
                else
                    if(self.crossFadeTimeline:IsPlaying()) then
                        self.crossFadeTimeline:PlayBackward()
                    else
                        self.crossFadeTimeline:PlayFromEnd()
                    end
                end
            end
        end        
    end
end

function CompassFrame:SetBossBarHiddenForReason(reason, hidden)
    if(self.bossBarHiddenReasons:SetHiddenForReason(reason, hidden)) then
        self:RefreshVisible()
    end
end

function CompassFrame:SetBossBarActive(active)
    self.bossBarActive = active
    self:ApplyStyle()
    self:RefreshVisible()
end

function CompassFrame:GetBossBarActive()
    return self.bossBarActive
end

function CompassFrame:SetCompassHidden(hidden)
    self.compassHidden = hidden
    self:RefreshVisible()
end

function CompassFrame:SetBossBarReady(ready)
    self.bossBarReady = ready
    ZO_BossBar:SetParent(self.control)
    self:RefreshVisible()
end

function CompassFrame:SetCompassReady(ready)
    self.compassReady = ready
    ZO_Compass:SetParent(self.control)
    self:RefreshVisible()
end

--Events

function CompassFrame:OnPlayerActivated()
    self:UpdateWidth()
    self:RefreshVisible()
end

--Global XML

function ZO_CompassFrame_OnInitialized(self)
    COMPASS_FRAME = CompassFrame:New(self)
end
