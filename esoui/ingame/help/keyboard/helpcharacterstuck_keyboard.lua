local HelpCharacterStuck_Keyboard = ZO_HelpScreenTemplate_Keyboard:Subclass()

function HelpCharacterStuck_Keyboard:New(...)
    return ZO_HelpScreenTemplate_Keyboard.New(self, ...)
end

function HelpCharacterStuck_Keyboard:Initialize(control)
	HELP_CUSTOMER_SERVICE_CHARACTER_STUCK_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
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
	local cost = GetRecallCost()
    local telvarLossPercentage = zo_floor(GetTelvarStonePercentLossOnNonPvpDeath() * 100)
    local mainText = DoesCurrentZoneHaveTelvarStoneBehavior() and SI_CUSTOMER_SERVICE_UNSTUCK_COST_PROMPT_TELVAR or SI_CUSTOMER_SERVICE_UNSTUCK_COST_PROMPT
    local playerMoney = GetCarriedCurrencyAmount(CURT_MONEY)
                
    if cost > playerMoney then
        cost = playerMoney
    end

	local DONT_USE_SHORT_FORMAT = false
	local costText = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(cost, DONT_USE_SHORT_FORMAT, CURT_MONEY)

    local text = zo_strformat(mainText, costText, telvarLossPercentage)

	self.helpStuckCost:SetText(text)
end

--Global XML

function ZO_HelpCharacterStuck_Keyboard_OnInitialized(self)
    HELP_CUSTOMER_SERVICE_CHARACTER_STUCK_KEYBOARD = HelpCharacterStuck_Keyboard:New(self)
end

function ZO_HelpCharacterStuck_Keyboard_UnstuckPlayer(self)
	SendPlayerStuck()
end