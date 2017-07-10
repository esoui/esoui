local ITEM_PREVIEW_DIRECTION_PREVIOUS = "previous"
local ITEM_PREVIEW_DIRECTION_NEXT = "next"

ZO_ItemPreview_Keyboard = ZO_ItemPreview_Shared:Subclass()

function ZO_ItemPreview_Keyboard:New(...)
    return ZO_ItemPreview_Shared.New(self, ...)
end

function ZO_ItemPreview_Keyboard:Initialize(control)
    ZO_ItemPreview_Shared.Initialize(self, control)

    self.variationLabel = control:GetNamedChild("VariationLabel")

    self.previewVariationLeftArrow = control:GetNamedChild("PreviewVariationLeftArrow")
    self.previewVariationRightArrow = control:GetNamedChild("PreviewVariationRightArrow")
    self:InitializeArrowButton(self.previewVariationLeftArrow, ITEM_PREVIEW_DIRECTION_PREVIOUS)
    self:InitializeArrowButton(self.previewVariationRightArrow, ITEM_PREVIEW_DIRECTION_NEXT)

    self:InitializeRotationControl()
end

function ZO_ItemPreview_Keyboard:InitializeRotationControl()
    local rotationControl = self.control:GetNamedChild("RotationArea")
    rotationControl:SetHandler("OnMouseEnter", function(control) control.mouseInside = true end)
    rotationControl:SetHandler("OnMouseExit", function(control) control.mouseInside = false end)
    rotationControl:SetHandler("OnMouseDown",
                                function(control, button)
                                    if button == MOUSE_BUTTON_INDEX_LEFT then
                                        if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
                                            PlaceInWorldLeftClick()
                                        else
                                            if control.canRotate then
                                                control.isRotating = true
                                                BeginItemPreviewSpin()
                                            end
                                        end
                                    end
                                end)
    rotationControl:SetHandler("OnMouseUp",
                                function(control, button)
                                    if button == MOUSE_BUTTON_INDEX_LEFT then
                                        if control.isRotating then
                                            control.isRotating = false
                                            EndItemPreviewSpin()
                                        end
                                    end
                                end)
    rotationControl:SetHandler("OnEffectivelyHidden",
                                function(control)
                                    if control.isRotating then
                                        control.isRotating = false
                                        EndItemPreviewSpin()
                                    end
                                end)
    rotationControl:SetHandler("OnUpdate",
                                function(control)
                                    if control.mouseInside and CanSpinPreviewCharacter() and GetCursorContentType() == MOUSE_CONTENT_EMPTY then
                                        control.canRotate = true
                                        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_ROTATE)
                                    else
                                        if control.canRotate then
                                            WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
                                        end
                                        control.canRotate = false
                                    end
                                end)

    self.rotationControl = rotationControl
end

function ZO_ItemPreview_Keyboard:OnPreviewHidden()
    ZO_ItemPreview_Shared.OnPreviewHidden(self)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_ItemPreview_Keyboard:InitializeArrowButton(control, direction)
    control:SetHandler("OnClicked", function(control) self:CyclePreviewVariations(direction) end)
end

function ZO_ItemPreview_Keyboard:SetVariationControlsHidden(hidden)
    self.previewVariationLeftArrow:SetHidden(hidden)
    self.previewVariationRightArrow:SetHidden(hidden)
    self.variationLabel:SetHidden(hidden)
end

function ZO_ItemPreview_Keyboard:SetVariationLabel(variationName)
    self.variationLabel:SetText(variationName)
end

function ZO_ItemPreview_Keyboard:SetCanChangePreview(canChangePreview)
    ZO_ItemPreview_Shared.SetCanChangePreview(self, canChangePreview)
    self:FireCallbacks("RefreshActions")
end

function ZO_ItemPreview_Keyboard:Apply()
    ZO_ItemPreview_Shared.Apply(self)
    self:FireCallbacks("RefreshActions")
end

function ZO_ItemPreview_Keyboard:CyclePreviewVariations(direction)
    if self:CanChangePreview() then
        if direction == ITEM_PREVIEW_DIRECTION_PREVIOUS then
            self:PreviewPreviousVariation()
        else
            self:PreviewNextVariation()
        end
    end
end

function ZO_ItemPreview_Keyboard:SetEnabled(isEnabled)
    local hideControls = not isEnabled
    self.rotationControl:SetHidden(hideControls)
    
    --SetEnabled can't cause the variation controls to be shown. This is to protect against showing the variation
    --controls if the target doesn't have variations.
    if hideControls then
        self:SetVariationControlsHidden(hideControls)
    end
end

function ZO_ItemPreview_Keyboard:SetHorizontalPaddings(paddingLeft, paddingRight)
    self.control:ClearAnchors()
    self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, paddingLeft, 120)
    self.control:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -paddingRight, -88)
end

function ZO_ItemPreview_Keyboard_OnInitialize(control)
     ITEM_PREVIEW_KEYBOARD = ZO_ItemPreview_Keyboard:New(control)
     SYSTEMS:RegisterKeyboardObject("itemPreview", ITEM_PREVIEW_KEYBOARD)
end