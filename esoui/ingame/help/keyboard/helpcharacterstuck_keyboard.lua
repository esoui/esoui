local HelpCharacterStuck_Keyboard = ZO_HelpScreenTemplate_Keyboard:Subclass()

function HelpCharacterStuck_Keyboard:New(...)
    return ZO_HelpScreenTemplate_Keyboard.New(self, ...)
end

function HelpCharacterStuck_Keyboard:Initialize(control)
	HELP_CUSTOMER_SERVICE_CHARACTER_STUCK_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
	control:RegisterForEvent(EVENT_STUCK_COMPLETE, function() SCENE_MANAGER:Hide("helpCustomerSupport") end)
    HELP_CUSTOMER_SERVICE_CHARACTER_STUCK_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
																if newState == SCENE_SHOWING then
																	self:UpdateCost()
																end
                                                            end)
	local iconData =
	{
		name = GetString(SI_CUSTOMER_SERVICE_CHARACTER_STUCK),
		categoryFragment = HELP_CUSTOMER_SERVICE_CHARACTER_STUCK_KEYBOARD_FRAGMENT,
        up = "EsoUI/Art/Help/help_tabIcon_stuck_up.dds",
        down = "EsoUI/Art/Help/help_tabIcon_stuck_down.dds",
        over = "EsoUI/Art/Help/help_tabIcon_stuck_over.dds",
	}
	ZO_HelpScreenTemplate_Keyboard.Initialize(self, control, iconData)

	self.helpStuckCost = self.control:GetNamedChild("Cost")
end

function HelpCharacterStuck_Keyboard:UpdateCost()
	local cost = zo_min(GetRecallCost(), GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER))
  	local DONT_USE_SHORT_FORMAT = false
	local costText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(cost, DONT_USE_SHORT_FORMAT, CURT_MONEY)

    local text
    if DoesCurrentZoneHaveTelvarStoneBehavior() then
        local telvarLossPercentage = zo_floor(GetTelvarStonePercentLossOnNonPvpDeath() * 100)
        text = zo_strformat(SI_CUSTOMER_SERVICE_UNSTUCK_COST_PROMPT_TELVAR, costText, telvarLossPercentage)
    elseif IsActiveWorldBattleground() then
        text = GetString(SI_CUSTOMER_SERVICE_UNSTUCK_COST_PROMPT_IN_BATTLEGROUND)
    else
        text = zo_strformat(SI_CUSTOMER_SERVICE_UNSTUCK_COST_PROMPT, costText)
    end

	self.helpStuckCost:SetText(text)
end

--Global XML

function ZO_HelpCharacterStuck_Keyboard_OnInitialized(self)
    HELP_CUSTOMER_SERVICE_CHARACTER_STUCK_KEYBOARD = HelpCharacterStuck_Keyboard:New(self)
end

function ZO_HelpCharacterStuck_Keyboard_UnstuckPlayer(self)
	SendPlayerStuck()
end