ZO_ItemPreview_Gamepad = ZO_ItemPreview_Shared:Subclass()

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

    PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("PreviewStateNavigation")

    self.variationLabel = control:GetNamedChild("VariationLabel")
    self.previewVariationLeftIcon = CreateIconLabel("$(parent)PreviewLeftIcon", control, "PREVIEW_PREVIOUS_VARIATION")
    self.previewVariationRightIcon = CreateIconLabel("$(parent)PreviewRightIcon", control, "PREVIEW_NEXT_VARIATION")

    self.previewVariationLeftIcon:SetAnchor(RIGHT, self.variationLabel, LEFT, -32)
    self.previewVariationRightIcon:SetAnchor(LEFT, self.variationLabel, RIGHT, 32)

    self.actionLabel = control:GetNamedChild("ActionLabel")
    self.previewActionLeftIcon = CreateIconLabel("$(parent)PreviewActionLeftIcon", control, "PREVIEW_PREVIOUS_ACTION")
    self.previewActionRightIcon = CreateIconLabel("$(parent)PreviewActionRightIcon", control, "PREVIEW_NEXT_ACTION")

    self.previewActionLeftIcon:SetAnchor(RIGHT, self.actionLabel, LEFT, -32)
    self.previewActionRightIcon:SetAnchor(LEFT, self.actionLabel, RIGHT, 32)
end

function ZO_ItemPreview_Gamepad:GetPreviewSpinnerNarrationText()
    local ENABLED = true
    local narrations = {}
    if self:HasActions() then
        ZO_AppendNarration(narrations, ZO_FormatSpinnerNarrationText(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_ACTION_TITLE), self.currentPreviewTypeObject:GetActionName(self.previewVariationIndex, self.previewActionIndex)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetKeybindNarrationFromData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_PREVIOUS), "PREVIEW_PREVIOUS_ACTION", ENABLED))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetKeybindNarrationFromData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_NEXT), "PREVIEW_NEXT_ACTION", ENABLED))
    end
    if self:HasVariations() then
        ZO_AppendNarration(narrations, ZO_FormatSpinnerNarrationText(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_TITLE), self.currentPreviewTypeObject:GetVariationName(self.previewVariationIndex)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetKeybindNarrationFromData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_PREVIOUS), "PREVIEW_PREVIOUS_VARIATION", ENABLED))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetKeybindNarrationFromData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_NEXT), "PREVIEW_NEXT_VARIATION", ENABLED))
    end
    return narrations
end

function ZO_ItemPreview_Gamepad:GetPreviewActionSpinnerNarrationText()
    if self:HasActions() then
        return ZO_FormatSpinnerNarrationText(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_TITLE), self.currentPreviewTypeObject:GetActionName(self.previewVariationIndex, self.previewActionIndex))
    end
    return nil
end

function ZO_ItemPreview_Gamepad:SetCanChangePreview(canChangePreview)
    ZO_ItemPreview_Shared.SetCanChangePreview(self, canChangePreview)

    if canChangePreview then
        self.variationLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
        self.actionLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    else
        self.variationLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
        self.actionLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
    end

    self:FireCallbacks("RefreshActions")
end

function ZO_ItemPreview_Gamepad:Apply()
    ZO_ItemPreview_Shared.Apply(self)
    self:FireCallbacks("RefreshActions")
end

function ZO_ItemPreview_Gamepad:OnPreviewShowing()
    ZO_ItemPreview_Shared.OnPreviewShowing(self)
    SCENE_MANAGER:AddFragment(PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT)
end

function ZO_ItemPreview_Gamepad:OnPreviewHidden()
    ZO_ItemPreview_Shared.OnPreviewHidden(self)
    SCENE_MANAGER:RemoveFragment(PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT)
end

function ZO_ItemPreview_Gamepad:TryPreviewNextVariation(playClickSound)
    if self.currentPreviewTypeObject and self.numPreviewVariations > 1 and self.canChangePreview then
        self:PreviewNextVariation()
        if playClickSound then
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
        return true
    end
    return false
end

function ZO_ItemPreview_Gamepad:TryPreviewPreviousVariation(playClickSound)
    if self.currentPreviewTypeObject and self.numPreviewVariations > 1 and self.canChangePreview then
        self:PreviewPreviousVariation()
        if playClickSound then
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
        return true
    end
    return false
end

function ZO_ItemPreview_Gamepad:TryPreviewNextAction(playClickSound)
    if self.currentPreviewTypeObject and self.numPreviewActions > 1 and self.canChangePreview then
        self:PreviewNextAction()
        if playClickSound then
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
        return true
    end
    return false
end

function ZO_ItemPreview_Gamepad:TryPreviewPreviousAction(playClickSound)
    if self.currentPreviewTypeObject and self.numPreviewActions > 1 and self.canChangePreview then
        self:PreviewPreviousAction()
        if playClickSound then
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
        return true
    end
    return false
end

function ZO_ItemPreview_Gamepad:SetVariationControlsHidden(shouldHide)
    self.variationLabel:SetHidden(shouldHide)
    self.previewVariationLeftIcon:SetHidden(shouldHide)
    self.previewVariationRightIcon:SetHidden(shouldHide)
end

function ZO_ItemPreview_Gamepad:SetVariationLabel(variationName)
    self.variationLabel:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, variationName))
end

function ZO_ItemPreview_Gamepad:SetActionControlsHidden(shouldHide)
    self.actionLabel:SetHidden(shouldHide)
    self.previewActionLeftIcon:SetHidden(shouldHide)
    self.previewActionRightIcon:SetHidden(shouldHide)
end

function ZO_ItemPreview_Gamepad:SetActionLabel(actionName)
    self.actionLabel:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, actionName))
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