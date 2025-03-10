local PerformanceMeters = ZO_Object:Subclass()

local HIGH_LATENCY = 300
local MEDIUM_LATENCY = 150
local LOW_LATENCY = 0
local MAX_FRAMERATE = 999
local MAX_LATENCY = 999

local LATENCY_ICONS =
{
    [HIGH_LATENCY] = { image = "EsoUI/Art/Campaign/campaignBrowser_lowPop.dds", color = ZO_ERROR_COLOR },
    [MEDIUM_LATENCY] = { image = "EsoUI/Art/Campaign/campaignBrowser_medPop.dds", color = ZO_SELECTED_TEXT },
    [LOW_LATENCY] = { image = "EsoUI/Art/Campaign/campaignBrowser_hiPop.dds", color = ZO_SELECTED_TEXT }
}

local POSITION_DEFAULTS = 
{
    point = BOTTOMLEFT,
    relPoint = BOTTOMLEFT,
    x = -20,
    y = 20,
}

function PerformanceMeters:New(...)
    local container = ZO_Object.New(self)
    container:Initialize(...)
    return container
end

function PerformanceMeters:Initialize(control)
    self.control = control
    self.framerateControl = GetControl(control, "FramerateMeter")
    self.framerateLabel = GetControl(self.framerateControl, "Label")
    self.latencyControl = GetControl(control, "LatencyMeter")
    self.latencyLabel = GetControl(self.latencyControl, "Label")
    self.latencyBars = GetControl(self.latencyControl, "Bars")

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            self.sv = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "PerformanceMeters", POSITION_DEFAULTS)
            self.control:ClearAnchors()
            self.control:SetAnchor(self.sv.point, nil, self.sv.relPoint, self.sv.x, self.sv.y)
            self:UpdateVisibility()
            self:UpdateMovable()
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end

    local function OnInterfaceSettingChanged(eventCode, settingType, settingId)
        if settingType == SETTING_TYPE_UI then
            if settingId == UI_SETTING_SHOW_FRAMERATE or settingId == UI_SETTING_SHOW_LATENCY then
                self:UpdateVisibility()
            elseif settingId == UI_SETTING_FRAMERATE_LATENCY_LOCK then
                self:UpdateMovable()
            end
        end
    end

    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    self.control:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)
    EVENT_MANAGER:RegisterForUpdate("ZO_PerformanceMeters", 1000, function() self:OnUpdate() end)
    
    PERFORMANCE_METER_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)
end

function PerformanceMeters:OnUpdate()
    if not PERFORMANCE_METER_FRAGMENT:IsHiddenForReason("AnyOn") then
        if not self.framerateControl:IsHidden() then
            self:SetFramerate(GetFramerate())
        end
        if not self.latencyControl:IsHidden() then
            self:SetLatency(GetLatency())
        end
    end
end

function PerformanceMeters:SetFramerate(framerate)
    if framerate then
        local addPlus = false
        if framerate > MAX_FRAMERATE then
            framerate = MAX_FRAMERATE
            addPlus = true
        end
        self.framerateLabel:SetText(zo_strformat(SI_FRAMERATE_METER_FORMAT, zo_round(framerate)))
    end
end

function PerformanceMeters:SetLatency(latency)
    if latency then
        local overMaxLabel
        if latency > MAX_LATENCY then
            latency = MAX_LATENCY
            overMaxLabel = zo_strformat(SI_LATENCY_EXTREME_FORMAT, latency)
        end
        if overMaxLabel then
            self.latencyLabel:SetText(overMaxLabel)
        else
            self.latencyLabel:SetText(latency)
        end
        --Determine if we need to update the icon and color
        local threshold = LOW_LATENCY
        if latency >= MEDIUM_LATENCY then
            threshold = latency >= HIGH_LATENCY and HIGH_LATENCY or MEDIUM_LATENCY
        end
        if self.previousLatencyThreshold and self.previousLatencyThreshold == threshold then
            return
        end
        local icon = LATENCY_ICONS[threshold]
        self.latencyBars:SetTexture(icon.image)
        self.latencyBars:SetColor(icon.color:UnpackRGBA())
        self.latencyLabel:SetColor(icon.color:UnpackRGBA())
        self.previousLatencyThreshold = threshold
    end
end

function PerformanceMeters:UpdateMovable()
    self.control:SetMovable(not GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_FRAMERATE_LATENCY_LOCK))
end

function PerformanceMeters:UpdateVisibility()
    local isPC = ZO_IsPCUI()
    local framerateOn = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_FRAMERATE)
    local latencyOn = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_LATENCY)
    local anyOn = (framerateOn or latencyOn) and isPC
    if anyOn then
        self.framerateControl:ClearAnchors()
        self.latencyControl:ClearAnchors()
        if framerateOn and latencyOn then
            self.framerateControl:SetAnchor(RIGHT, self.control, CENTER, 0, 0)
            self.latencyControl:SetAnchor(LEFT, self.control, CENTER, 0, 0)
        else
            self.framerateControl:SetAnchor(CENTER, self.control, CENTER, 0, 0)
            self.latencyControl:SetAnchor(CENTER, self.control, CENTER, 0, 0)
        end
        self.framerateControl:SetHidden(not framerateOn)
        self.latencyControl:SetHidden(not latencyOn)
    end
    PERFORMANCE_METER_FRAGMENT:SetHiddenForReason("AnyOn", not anyOn, 0, 0)
    self:OnUpdate()
end

function PerformanceMeters:ResetPosition()
    self.control:ClearAnchors()
    self.control:SetAnchor(POSITION_DEFAULTS.point, nil, POSITION_DEFAULTS.relPoint, POSITION_DEFAULTS.x, POSITION_DEFAULTS.y)
    self:OnMoveStop()
end

function PerformanceMeters:OnMoveStop()
    local _
    _, self.sv.point, _, self.sv.relPoint, self.sv.x, self.sv.y = self.control:GetAnchor(0)
end

function PerformanceMeters:Meter_OnMouseEnter(control)
    local tooltipText
    if control == self.framerateControl then
        tooltipText = GetString(SI_FRAMERATE_METER_TOOLTIP)
    elseif control == self.latencyControl then
        tooltipText = GetString(SI_LATENCY_METER_TOOLTIP)
    end
    
    if tooltipText then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
        SetTooltipText(InformationTooltip, tooltipText)
    end
end

function PerformanceMeters:Meter_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_PerformanceMeters_OnMouseEnter(control)
    PERFORMANCE_METERS:Meter_OnMouseEnter(control)
end

function ZO_PerformanceMeters_OnMouseExit(control)
    PERFORMANCE_METERS:Meter_OnMouseExit(control)
end

function ZO_PerformanceMeters_OnMoveStop(control)
    PERFORMANCE_METERS:OnMoveStop()
end

function ZO_PerformanceMeters_OnInitialized(control)
    PERFORMANCE_METERS = PerformanceMeters:New(control)
end