local DEFAULT_GAMEPAD_ALERT_TEMPLATE = "ZO_AlertLineGamepad"

local ZO_AlertText_Gamepad = ZO_AlertText_Base:Subclass()

function ZO_AlertText_Gamepad:New(...)
    return ZO_AlertText_Base.New(self, ...)
end

function ZO_AlertText_Gamepad:InternalPerformAlert(category, soundId, message, template)
    local color = self:GetAlertColor(category)

    local alertData = message

    if not (type(alertData) == "table") then
        alertData = {
            lines = {
                {text = message, category = category, color = color, soundId = soundId}
            }
        }
    end

    self.alerts:AddEntry(self.alerts:HasTemplate(template) and template or DEFAULT_GAMEPAD_ALERT_TEMPLATE, alertData)
end

function ZO_AlertText_Gamepad:AddTemplate(template, templateData)
    self.alerts:AddTemplate(template, templateData)
end

function ZO_AlertText_Gamepad:ClearAll()
    self.alerts:ClearAll()
end

function ZO_AlertText_Gamepad:FadeAll()
    self.alerts:FadeAll()
end

local function OnScriptAccessViolation(eventCode, functionName)
    ZO_Dialogs_ShowGamepadDialog("SCRIPT_ACCESS_VIOLATION", nil, {mainTextParams = {functionName}})
end

local function SetupFunction(control, data)
    control:SetWidth(GuiRoot:GetRight() - ZO_Compass:GetRight() - ZO_GAMEPAD_CONTENT_INSET_X - ZO_GAMEPAD_SAFE_ZONE_INSET_X)
    control:SetText(data.text)
    control:SetColor(data.color:UnpackRGBA())

    ZO_SoundAlert(data.category, data.soundId)
end

function ZO_AlertText_Gamepad:Initialize(control)
    ZO_AlertText_Base.Initialize(self)

    control:RegisterForEvent(EVENT_SCRIPT_ACCESS_VIOLATION, OnScriptAccessViolation)

    local anchor = ZO_Anchor:New(TOPRIGHT, GuiRoot, TOPRIGHT, -15, 4)

    local MAX_DISPLAYED_ENTRIES_GAMEPAD = 2
    local MAX_HEIGHT_GAMEPAD = 900
    local NO_MAX_LINES_PER_ENTRY_GAMEPAD = nil

    self.alerts = ZO_FadingControlBuffer:New(control, MAX_DISPLAYED_ENTRIES_GAMEPAD, MAX_HEIGHT_GAMEPAD, NO_MAX_LINES_PER_ENTRY_GAMEPAD, "AlertFadeGamepad", "AlertTranslateGamepad", anchor)
    self.alerts:AddTemplate(DEFAULT_GAMEPAD_ALERT_TEMPLATE, {setup = SetupFunction})

    self.alerts:SetTranslateDuration(1500)
    self.alerts:SetHoldTimes(6000)
    self.alerts:SetAdditionalVerticalSpacing(9)
    self.alerts:SetFadesInImmediately(true)
end

function ZO_AlertText_Gamepad:HasActiveEntries()
    return self.alerts:HasQueuedEntry() or self.alerts:HasEntries()
end

function ZO_AlertText_Gamepad:SetHoldDisplayingEntries(holdEntries)
    self.alerts:SetHoldDisplayingEntries(holdEntries)
end

function ZO_AlertTextGamepad_OnInitialized(control)
    ALERT_MESSAGES_GAMEPAD = ZO_AlertText_Gamepad:New(control)
end

--[[ Global Alert Functions ]]--
function ZO_AlertTemplated_Gamepad(category, soundId, message, template, ...)
    if not message then
        return
    end
    if not type(message) == "table" then
        message = zo_strformat(message, ...)
    end
    if message == "" then
        return
    end

    if ALERT_EVENT_MANAGER:ShouldDisplayMessage(message) then
        ALERT_MESSAGES_GAMEPAD:InternalPerformAlert(category, soundId, message, template)
    else
        ZO_SoundAlert(category, soundId)
    end
end

function ZO_AlertNoSuppressionTemplated_Gamepad(category, soundId, message, template, ...)
    if not message then
        return
    end
    if not type(message) == "table" then
        message = zo_strformat(message, ...)
    end
    if message == "" then
        return
    end

    ALERT_MESSAGES_GAMEPAD:InternalPerformAlert(category, soundId, message, template)
end

function ZO_AlertAddTemplate_Gamepad(template, templateData)
    ALERT_MESSAGES_GAMEPAD:AddTemplate(template, templateData)
end

function ZO_AlertFadeAll_Gamepad()
    ALERT_MESSAGES_GAMEPAD:FadeAll()
end

function ZO_AlertClearAll_Gamepad()
    ALERT_MESSAGES_GAMEPAD:ClearAll()
end