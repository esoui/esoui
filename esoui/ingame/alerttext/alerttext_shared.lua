-- Singleton that registers for the alert events
local ZO_AlertText_Manager = ZO_Object:Subclass()

function ZO_AlertText_Manager:New()
    local manager = ZO_Object.New(self)
    manager:Initialize()
    return manager
end

local function OnAlertEvent(eventCode, ...)
	local alertHandlers = ZO_AlertText_GetHandlers()
	if alertHandlers[eventCode] then
		local category, message, soundId, noSuppression = alertHandlers[eventCode](...)
		if category then
			if message and message ~= "" then
				if noSuppression then
					ZO_AlertNoSuppression(category, soundId, message)
				else
					ZO_Alert(category, soundId, message)
				end
			else
				ZO_SoundAlert(category, soundId)
			end
		end
	end
end

function ZO_AlertEvent(eventId, ...)
	OnAlertEvent(eventId, ...)
end

function ZO_AlertText_Manager:Initialize()
    local alertHandlers = ZO_AlertText_GetHandlers()
    for event in pairs(alertHandlers) do
        EVENT_MANAGER:RegisterForEvent("AlertTextManager", event, OnAlertEvent)
    end
    EVENT_MANAGER:AddFilterForEvent("AlertTextManager", EVENT_COMBAT_EVENT, REGISTER_FILTER_IS_ERROR, true)

    self.recentMessages = ZO_RecentMessages:New()
end

function ZO_AlertText_Manager:ShouldDisplayMessage(soundId)
    return self.recentMessages:ShouldDisplayMessage(soundId)
end

function ZO_AlertText_Manager:AddRecent(soundId)
    return self.recentMessages:AddRecent(soundId)
end

ALERT_EVENT_MANAGER = ZO_AlertText_Manager:New()


-- Base Class
ZO_AlertText_Base = ZO_Object:Subclass()

function ZO_AlertText_Base:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_AlertText_Base:Initialize(control)
    -- Should be overridden
end

--add customization for message categories here
-- Previous colors: error = INTERFACE_GENERAL_COLOR_ERROR, alert = INTERFACE_GENERAL_COLOR_ALERT, colorType = INTERFACE_COLOR_TYPE_GENERAL
local AlertParams =
{
	[UI_ALERT_CATEGORY_ERROR] =
	{
		color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)),
	},
	[UI_ALERT_CATEGORY_ALERT] =
	{
		color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)),
	},
}

function ZO_AlertText_Base:GetAlertColor(category)
	local color = AlertParams[UI_ALERT_CATEGORY_ALERT].color
	local params = AlertParams[category]
	if(params) then
		color = params.color or color
	end

    return color
end

local function InternalPerformAlert(category, soundId, message)
    if IsInGamepadPreferredMode() then
        ALERT_MESSAGES_GAMEPAD:InternalPerformAlert(category, soundId, message)
    else
        ALERT_MESSAGES:InternalPerformAlert(category, soundId, message)
    end
end

--[[ Global Alert Functions ]]--
function ZO_Alert(category, soundId, message, ...)
    if(not message) then return end
    message = zo_strformat(message, ...)
    if(message == "") then return end

	if(ALERT_EVENT_MANAGER:ShouldDisplayMessage(message)) then
		InternalPerformAlert(category, soundId, message)
    else
        ZO_SoundAlert(category, soundId)
    end
end

function ZO_AlertNoSuppression(category, soundId, message, ...)
	if(not message) then return end
    message = zo_strformat(message, ...)
    if(message == "") then return end

	InternalPerformAlert(category, soundId, message)
end

function ZO_SoundAlert(category, soundId)
	if(soundId and soundId ~= "" and ALERT_EVENT_MANAGER:ShouldDisplayMessage(soundId)) then
		PlaySound(soundId)
        ALERT_EVENT_MANAGER:AddRecent(soundId)
	end
end
