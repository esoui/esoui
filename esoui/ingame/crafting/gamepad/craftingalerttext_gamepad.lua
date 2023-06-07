local DEFAULT_GAMEPAD_ALERT_TEMPLATE = "ZO_CraftingAlertLineGamepad"

local ZO_CraftingAlertText_Gamepad = ZO_AlertText_Base:Subclass()

function ZO_CraftingAlertText_Gamepad:New(...)
    return ZO_AlertText_Base.New(self, ...)
end

function ZO_CraftingAlertText_Gamepad:InternalPerformAlert(category, soundId, message, template)
    local color = self:GetAlertColor(category)

    local alertData = message

    if not (type(alertData) == "table") then
        alertData = 
        {
            lines = 
            {
                {text = message, category = category, color = color, soundId = soundId}
            }
        }
    end

    self.alerts:AddEntry(self.alerts:HasTemplate(template) and template or DEFAULT_GAMEPAD_ALERT_TEMPLATE, alertData)
end

function ZO_CraftingAlertText_Gamepad:AddTemplate(template, templateData)
    self.alerts:AddTemplate(template, templateData)
end

function ZO_CraftingAlertText_Gamepad:ClearAll()
    self.alerts:ClearAll()
end

function ZO_CraftingAlertText_Gamepad:FadeAll()
    self.alerts:FadeAll()
end

function ZO_CraftingAlertText_Gamepad:CondenseMaxHeight(heightToSubtract)
    local newHeight = zo_max(0, self.defaultMaxHeight - heightToSubtract)
    self.alerts:SetMaxHeight(newHeight)
end

local function SetupFunction(control, data)
    control:SetWidth(GuiRoot:GetRight() - ZO_Compass:GetRight() - ZO_GAMEPAD_CONTENT_INSET_X - ZO_GAMEPAD_SAFE_ZONE_INSET_X)
    control:SetText(data.text)
    control:SetColor(data.color:UnpackRGBA())

    ZO_SoundAlert(data.category, data.soundId)
end

function ZO_CraftingAlertText_Gamepad:Initialize(control)
    ZO_AlertText_Base.Initialize(self)

    local anchor = ZO_Anchor:New(TOPRIGHT, ZO_WRIT_ADVISOR_GAMEPAD:GetControl(), BOTTOMRIGHT, 7, 24)

    local MAX_DISPLAYED_ENTRIES_GAMEPAD = 2
    local MAX_HEIGHT_GAMEPAD = 800
    local NO_MAX_LINES_PER_ENTRY_GAMEPAD = nil

    self.defaultMaxHeight = MAX_HEIGHT_GAMEPAD

    local NARRATE_ALL_ENTRIES = true
    self.alerts = ZO_FadingControlBuffer:New(control, MAX_DISPLAYED_ENTRIES_GAMEPAD, MAX_HEIGHT_GAMEPAD, NO_MAX_LINES_PER_ENTRY_GAMEPAD, "AlertFadeGamepad", "AlertTranslateGamepad", anchor, NARRATE_ALL_ENTRIES)
    self.alerts:AddTemplate(DEFAULT_GAMEPAD_ALERT_TEMPLATE, {setup = SetupFunction})

    self.alerts:SetTranslateDuration(1500)
    self.alerts:SetHoldTimes(6000)
    self.alerts:SetAdditionalVerticalSpacing(9)
    self.alerts:SetFadesInImmediately(true)
end

function ZO_CraftingAlertTextGamepad_OnInitialized(control)
    CRAFTING_ALERT_MESSAGES_GAMEPAD = ZO_CraftingAlertText_Gamepad:New(control)
end

--[[ Global Alert Functions ]]--
function ZO_CraftingAlertNoSuppressionTemplated_Gamepad(category, soundId, message, template, ...)
    if not message then
        return
    end
    if not type(message) == "table" then
        message = zo_strformat(message, ...)
    end
    if message == "" then
        return
    end

    CRAFTING_ALERT_MESSAGES_GAMEPAD:InternalPerformAlert(category, soundId, message, template)
end

function ZO_CraftingAlertAddTemplate_Gamepad(template, templateData)
    CRAFTING_ALERT_MESSAGES_GAMEPAD:AddTemplate(template, templateData)
end

function ZO_CraftingAlertFadeAll_Gamepad()
    CRAFTING_ALERT_MESSAGES_GAMEPAD:FadeAll()
end

function ZO_CraftingAlertClearAll_Gamepad()
    CRAFTING_ALERT_MESSAGES_GAMEPAD:ClearAll()
end

function ZO_CraftingAlertCondenseMaxHeight_Gamepad(heightToSubtract)
    CRAFTING_ALERT_MESSAGES_GAMEPAD:CondenseMaxHeight(heightToSubtract)
end