ZO_Help_ItemAssistance_Gamepad = ZO_Help_MechanicAssistance_Gamepad:Subclass()

function ZO_Help_ItemAssistance_Gamepad:New(...)
    return ZO_Help_MechanicAssistance_Gamepad.New(self, ...)
end

function ZO_Help_ItemAssistance_Gamepad:Initialize(control)
    ZO_Help_MechanicAssistance_Gamepad.Initialize(self, control, ZO_ITEM_ASSISTANCE_CATEGORIES_DATA)
    self:SetGoToDetailsSourceKeybindText(GetString(SI_GAMEPAD_HELP_GO_TO_INVENTORY_KEYBIND))
    self:SetDetailsHeader(GetString(SI_CUSTOMER_SERVICE_ITEM_NAME))
    self:SetDetailsInstructions(GetString(SI_CUSTOMER_SERVICE_ITEM_ASSISTANCE_NAME_INSTRUCTIONS))
end

function ZO_Help_ItemAssistance_Gamepad:AddDescriptionEntry()
    --Do nothing, because we don't want item assistance having a description field anymore
end

function ZO_Help_ItemAssistance_Gamepad:GetSceneName()
   return "helpItemAssistanceGamepad"
end

function ZO_Help_ItemAssistance_Gamepad:GoToDetailsSourceScene()
    SCENE_MANAGER:Push("gamepad_inventory_root")
end

function ZO_Help_ItemAssistance_Gamepad:GetFieldEntryTitle()
   return GetString(SI_CUSTOMER_SERVICE_ITEM_ASSISTANCE)
end

function ZO_Help_ItemAssistance_Gamepad:RegisterDetails()
    local savedDetails = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS)
    if savedDetails then
        SetCustomerServiceTicketItemTargetByLink(savedDetails)
    end
end

function ZO_Help_ItemAssistance_Gamepad:GetDisplayedDetails()
    local savedDetails = self:GetSavedField(ZO_HELP_TICKET_FIELD_TYPE.DETAILS)
    if savedDetails then
        return zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(savedDetails))
    else
        return self:GetDetailsInstructions()
    end
end

function ZO_Help_ItemAssistance_Gamepad_OnInitialize(control)
    HELP_ITEM_ASSISTANCE_GAMEPAD = ZO_Help_ItemAssistance_Gamepad:New(control)
end