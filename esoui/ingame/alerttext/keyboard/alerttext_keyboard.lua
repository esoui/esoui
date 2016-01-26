local DEFAULT_KEYBOARD_ALERT_TEMPLATE = "ZO_AlertLine"

local ZO_AlertText_Keyboard = ZO_AlertText_Base:Subclass()

function ZO_AlertText_Keyboard:New(...)
    return ZO_AlertText_Base.New(self, ...)
end

function ZO_AlertText_Keyboard:InternalPerformAlert(category, soundId, message)
	local color = self:GetAlertColor(category)

    local alertData = {
        lines = {
            {text = message, category = category, color = color, soundId = soundId}
        }
    }

    self.alerts:AddEntry(DEFAULT_KEYBOARD_ALERT_TEMPLATE, alertData)
end

local function OnScriptAccessViolation(eventCode, functionName)
	ZO_Dialogs_ShowDialog("SCRIPT_ACCESS_VIOLATION", nil, {mainTextParams = {functionName}})
end

local function SetupFunction(control, data)
    control:SetWidth(GuiRoot:GetRight() - ZO_Compass:GetRight() - 40)
    control:SetText(data.text)
    control:SetColor(data.color:UnpackRGBA())

    ZO_SoundAlert(data.category, data.soundId)
end

function ZO_AlertText_Keyboard:Initialize(control)
    ZO_AlertText_Base.Initialize(self)

    control:RegisterForEvent(EVENT_SCRIPT_ACCESS_VIOLATION, OnScriptAccessViolation)

    local MAX_DISPLAYED_ENTRIES_KEYBOARD = 3
    self.alerts = ZO_FadingControlBuffer:New(control, MAX_DISPLAYED_ENTRIES_KEYBOARD, nil, nil, "AlertFade", "AlertTranslate", ZO_Anchor:New(TOPRIGHT, GuiRoot))
    self.alerts:AddTemplate(DEFAULT_KEYBOARD_ALERT_TEMPLATE, {setup = SetupFunction})
end

function ZO_AlertTextKeyboard_OnInitialized(control)
    ALERT_MESSAGES = ZO_AlertText_Keyboard:New(control)
end