local CUSTOMER_SERVICE_CATEGORY_DATA =
{
    name = GetString(SI_CUSTOMER_SERVICE_ITEM_ASSISTANCE),
    up = "EsoUI/Art/Help/help_tabIcon_itemAssistance_up.dds",
    down = "EsoUI/Art/Help/help_tabIcon_itemAssistance_down.dds",
    over = "EsoUI/Art/Help/help_tabIcon_itemAssistance_over.dds",
}

ZO_HelpItemAssistance_Keyboard = ZO_HelpMechanicAssistanceTemplate_Keyboard:Subclass()

function ZO_HelpItemAssistance_Keyboard:New(...)
    return ZO_HelpScreenTemplate_Keyboard.New(self, ...)
end

function ZO_HelpItemAssistance_Keyboard:Initialize(control)
    ZO_HelpMechanicAssistanceTemplate_Keyboard.Initialize(self, control, CUSTOMER_SERVICE_CATEGORY_DATA, ZO_ITEM_ASSISTANCE_CATEGORIES_DATA)
end

function ZO_HelpItemAssistance_Keyboard:GetDetailsInstructions()
    return GetString(SI_CUSTOMER_SERVICE_ITEM_ASSISTANCE_NAME_INSTRUCTIONS)
end

function ZO_HelpItemAssistance_Keyboard:RegisterDetails()
    if self.savedItemLink then
        SetCustomerServiceTicketItemTargetByLink(self.savedItemLink)
    else
        SetCustomerServiceTicketItemTarget(self:GetDetailsText())
    end
end

function ZO_HelpItemAssistance_Keyboard:SetDetailsFromItemLink(itemLink)
    self.savedItemLink = itemLink
    self:SetDetailsText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink)))
end

--Global XML

function ZO_HelpItemAssistance_Keyboard_OnInitialized(self)
    HELP_CUSTOMER_SERVICE_ITEM_ASSISTANCE_KEYBOARD = ZO_HelpItemAssistance_Keyboard:New(self)
end

function ZO_HelpItemAssistance_Keyboard_AttemptToSendTicket()
    HELP_CUSTOMER_SERVICE_ITEM_ASSISTANCE_KEYBOARD:AttemptToSendTicket()
end