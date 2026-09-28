local DEFAULT_KEYBOARD_ALERT_TEMPLATE = "ZO_AlertLine"

local ZO_AlertText_Keyboard = ZO_AlertText_Base:Subclass()

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

function ZO_AlertText_Keyboard:Initialize(control)
    ZO_AlertText_Base.Initialize(self)

    control:RegisterForEvent(EVENT_SCRIPT_ACCESS_VIOLATION, OnScriptAccessViolation)

    local function SetupFunction(entryControl, data)
        local compassHUDElement = HUD_MANAGER:GetKeyboardElementForControl(ZO_CompassFrame)
        if self.hudElement:IsUsingDefaultAnchor() and compassHUDElement:IsUsingDefaultAnchor() then
            --If both alerts and the compass are in their default position, take the position of the compass into account to prevent overlap when determining the width
            entryControl:SetWidth(GuiRoot:GetRight() - ZO_Compass:GetRight() - 40)
        else
            --If either the compass or alerts have been moved, allow the element to grow up to its maximum width
            entryControl:SetWidth(0)
        end
        entryControl:SetText(data.text)
        entryControl:SetColor(data.color:UnpackRGBA())

        ZO_SoundAlert(data.category, data.soundId)
    end

    local MAX_DISPLAYED_ENTRIES_KEYBOARD = 3
    self.alerts = ZO_FadingControlBuffer:New(control, MAX_DISPLAYED_ENTRIES_KEYBOARD, nil, nil, "AlertFade", "AlertTranslate", ZO_Anchor:New(TOPRIGHT, ZO_AlertTextNotification))
    self.alerts:AddTemplate(DEFAULT_KEYBOARD_ALERT_TEMPLATE, {setup = SetupFunction})

    local function OnAppGuiHiddenStateChanged(_, hidden)
        self.alerts:SetHoldDisplayingEntries(not hidden)
    end

    EVENT_MANAGER:RegisterForEvent("AlertText_Keyboard", EVENT_APP_GUI_HIDDEN_STATE_CHANGED, OnAppGuiHiddenStateChanged)

    if not GetGuiHidden("App") then
        self.alerts:SetHoldDisplayingEntries(true)
    end

    self.hudElement = HUD_MANAGER:RegisterKeyboardElement(control, GetString(SI_HUD_EDITOR_ALERTS))
end

function ZO_AlertTextKeyboard_OnInitialized(control)
    ALERT_MESSAGES = ZO_AlertText_Keyboard:New(control)
end