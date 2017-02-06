ZO_HouseInformation_Keyboard = ZO_HouseInformation_Shared:Subclass()

local VERTICAL_PADDING = 5

function ZO_HouseInformation_Keyboard:New(...)
    return ZO_HouseInformation_Shared.New(self, ...)
end

function ZO_HouseInformation_Keyboard:Initialize(control)
    HOUSE_INFORMATION_FRAGMENT = ZO_FadeSceneFragment:New(control)
    
    ZO_HouseInformation_Shared.Initialize(self, control, HOUSE_INFORMATION_FRAGMENT, "ZO_HouseInformation_Keyboard_Row", VERTICAL_PADDING)
end

-- XML functions --
-------------------

function ZO_HousingOverpopulationMessage_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control:GetParent(), LEFT, 15, 0)
    local SET_TO_FULL_SIZE = true
    local r, g, b = ZO_NORMAL_TEXT:UnpackRGB()
    InformationTooltip:AddLine(GetString(SI_HOUSING_CURRENT_RESIDENTS_OVER_POPULATION_TEXT), "", r, g, b, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, SET_TO_FULL_SIZE)
end

function ZO_HousingOverpopulationMessage_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_HouseInformation_Keyboard_OnInitialize(control)
    HOUSE_INFORMATION_KEYBOARD = ZO_HouseInformation_Keyboard:New(control)
end