ZO_HouseInformation_Gamepad = ZO_HouseInformation_Shared:Subclass()

local CHILD_VERTICAL_PADDING = 15
local SECTION_VERTICAL_PADDING = 70

function ZO_HouseInformation_Gamepad:Initialize(control)
    HOUSE_INFORMATION_FRAGMENT_GAMEPAD = ZO_FadeSceneFragment:New(control)
    
    ZO_HouseInformation_Shared.Initialize(self, control:GetNamedChild("Container"), HOUSE_INFORMATION_FRAGMENT_GAMEPAD, "ZO_HousingFurnitureBrowser_Gamepad_Row", CHILD_VERTICAL_PADDING, SECTION_VERTICAL_PADDING)
end

function ZO_HouseInformation_Gamepad:GetNarrationForRow(rowControl)
    local narrations = {}

    if not rowControl:IsHidden() then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(rowControl.nameText))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(rowControl.valueText))
    end

    return narrations
end

function ZO_HouseInformation_Gamepad:GetNarrationText()
    local narrations = {}

    --Get the title narration
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_INFORMATION_TITLE)))

    --Get the narration for the name row
    ZO_AppendNarration(narrations, self:GetNarrationForRow(self.nameRow))

    --Get the narration for the location row
    ZO_AppendNarration(narrations, self:GetNarrationForRow(self.locationRow))

    --Get the narration for the owner row
    ZO_AppendNarration(narrations, self:GetNarrationForRow(self.ownerRow))

    --Get the narration for the limit rows
    for i = HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_BEGIN, HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_END do
        ZO_AppendNarration(narrations, self:GetNarrationForRow(self.limitRows[i]))
    end

    --Get the narration for the primary residence
    ZO_AppendNarration(narrations, self:GetNarrationForRow(self.primaryResidenceRow))

    --Get the narration for the population count
    ZO_AppendNarration(narrations, self:GetNarrationForRow(self.currentVisitorsRow))
    if not self.overPopulationWarningLabel:IsHidden() then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSING_CURRENT_RESIDENTS_OVER_POPULATION_TEXT)))
    end

    --Get the narration for the permissions rows
    ZO_AppendNarration(narrations, self:GetNarrationForRow(self.individualPermissionsRow))
    ZO_AppendNarration(narrations, self:GetNarrationForRow(self.guildPermissionsRow))

    return narrations
end

function ZO_HouseInformation_Gamepad_OnInitialize(control)
    HOUSE_INFORMATION_GAMEPAD = ZO_HouseInformation_Gamepad:New(control)
end