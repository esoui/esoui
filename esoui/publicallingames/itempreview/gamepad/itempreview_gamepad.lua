ZO_ItemPreview_Gamepad = ZO_ItemPreview_Shared:Subclass()

function ZO_ItemPreview_Gamepad:New(...)
    return ZO_ItemPreview_Shared.New(self, ...)
end

function ZO_ItemPreview_Gamepad:Initialize(control)
    ZO_ItemPreview_Shared.Initialize(self, control)

    control.owner = self
    self.control = control

    local function CreateIconLabel(name, parent, actionName)
        local iconLabel = CreateControlFromVirtual(name, parent, "ZO_ClickableKeybindLabel_Gamepad")
        iconLabel:SetKeybind(actionName)
        iconLabel:SetHidden(true)
        return iconLabel
    end

    self.variationLabel = control:GetNamedChild("VariationLabel")
    self.previewVariationLeftIcon = CreateIconLabel("$(parent)PreviewLeftIcon", control, "UI_SHORTCUT_INPUT_LEFT")
    self.previewVariationRightIcon = CreateIconLabel("$(parent)PreviewRightIcon", control, "UI_SHORTCUT_INPUT_RIGHT")

    self.previewVariationLeftIcon:SetAnchor(RIGHT, self.variationLabel, LEFT, -32)
    self.previewVariationRightIcon:SetAnchor(LEFT, self.variationLabel, RIGHT, 32)

    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
end

function ZO_ItemPreview_Gamepad:GetPreviewSpinnerNarrationText()
    if self:HasVariations() then
        return ZO_FormatSpinnerNarrationText(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_TITLE), self.currentPreviewTypeObject:GetVariationName(self.previewVariationIndex))
    end
    return nil
end

function ZO_ItemPreview_Gamepad:SetCanChangePreview(canChangePreview)
    ZO_ItemPreview_Shared.SetCanChangePreview(self, canChangePreview)

    if canChangePreview then
        self.variationLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    else
        self.variationLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
    end

    self:FireCallbacks("RefreshActions")
end

function ZO_ItemPreview_Gamepad:Apply()
    ZO_ItemPreview_Shared.Apply(self)
    self:FireCallbacks("RefreshActions")
end

function ZO_ItemPreview_Gamepad:UpdateDirectionalInput(deltaS)
    if self.currentPreviewTypeObject and self.numPreviewVariations > 1 and self.canChangePreview then
        local result = self.movementController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            self:PreviewNextVariation()
        elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            self:PreviewPreviousVariation()
        end
    end
end

function ZO_ItemPreview_Gamepad:OnPreviewShowing()
    ZO_ItemPreview_Shared.OnPreviewShowing(self)
    self:Activate()
end

function ZO_ItemPreview_Gamepad:OnPreviewHidden()
    ZO_ItemPreview_Shared.OnPreviewHidden(self)
    self:Deactivate()
end

function ZO_ItemPreview_Gamepad:Activate()
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function ZO_ItemPreview_Gamepad:Deactivate()
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_ItemPreview_Gamepad:SetVariationControlsHidden(shouldHide)
    self.variationLabel:SetHidden(shouldHide)
    self.previewVariationLeftIcon:SetHidden(shouldHide)
    self.previewVariationRightIcon:SetHidden(shouldHide)
end

function ZO_ItemPreview_Gamepad:SetVariationLabel(variationName)
    self.variationLabel:SetText(variationName)
end

function ZO_ItemPreview_Gamepad:SetHorizontalPaddings(paddingLeft, paddingRight)
    self.control:ClearAnchors()
    self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, paddingLeft, ZO_GAMEPAD_SAFE_ZONE_INSET_Y)
    self.control:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -paddingRight, ZO_GAMEPAD_QUADRANT_BOTTOM_OFFSET)
end

function ZO_ItemPreview_Gamepad_OnInitialize(control)
    ITEM_PREVIEW_GAMEPAD = ZO_ItemPreview_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("itemPreview", ITEM_PREVIEW_GAMEPAD)
end