ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_X = 3
ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_Y = 4

ZO_DYEING_OUTFIT_SWATCH_CHANGED_COLOR = ZO_ColorDef:New("58a7a7")

function ZO_Dyeing_Gamepad_Highlight(control, dyeControl, offsetX, offsetY)
    local sharedHighlight = control.highlight
    offsetX = offsetX or ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_X
    offsetY = offsetY or ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_Y

    local selected = false
    if dyeControl then
        sharedHighlight:ClearAnchors()
        sharedHighlight:SetParent(dyeControl)
        sharedHighlight:SetAnchor(TOPLEFT, dyeControl, TOPLEFT, -offsetX, -offsetY)
        sharedHighlight:SetAnchor(BOTTOMRIGHT, dyeControl, BOTTOMRIGHT, offsetX, offsetY)
        selected = true
    end

    sharedHighlight:SetHidden(not selected)
end

function ZO_Dyeing_Gamepad_SavedSet_Highlight(control, savedSetControl)
    ZO_Dyeing_Gamepad_Highlight(control, savedSetControl, ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_X * 3, ZO_DYEING_HIGHLIGHT_OFFSET_GAMEPAD_Y * 2)
end

function ZO_Dyeing_Gamepad_SwatchSlot_Highlight_All(control)
    for _, highlight in ipairs(control.dyeHighlightControls) do
        highlight:SetHidden(false)
    end
end

function ZO_Dyeing_Gamepad_SwatchSlot_Highlight_Only(control, dyeChannel)
    for channel, highlight in ipairs(control.dyeHighlightControls) do
        highlight:SetHidden(channel ~= dyeChannel)
    end
end

function ZO_Dyeing_Gamepad_SwatchSlot_Reset_Highlight(control)
    for _, highlight in ipairs(control.dyeHighlightControls) do
        highlight:SetHidden(true)
    end
end

function ZO_Dyeing_Gamepad_OutfitSwatchSlot_Highlight_Only(control, dyeChannel)
    for channel, swatchControl in ipairs(control.dyeControls) do
        if swatchControl.dyeChangedControl then 
            if channel == dyeChannel then
                swatchControl.dyeChangedControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
            else
                swatchControl.dyeChangedControl:SetColor(ZO_DYEING_OUTFIT_SWATCH_CHANGED_COLOR:UnpackRGB())
            end
        end
    end

    ZO_Dyeing_Gamepad_SwatchSlot_Highlight_Only(control, dyeChannel)
end

function ZO_Dyeing_Gamepad_OutfitSwatchSlot_Reset_Highlight(control)
    for channel, swatchControl in ipairs(control.dyeControls) do
        if swatchControl.dyeChangedControl then 
            swatchControl.dyeChangedControl:SetColor(ZO_DYEING_OUTFIT_SWATCH_CHANGED_COLOR:UnpackRGB())
        end
    end

    ZO_Dyeing_Gamepad_SwatchSlot_Reset_Highlight(control)
end

function ZO_Dyeing_Gamepad_OutfitSwatchSlot_Highlight_All(control)
    for channel, swatchControl in ipairs(control.dyeControls) do
        if swatchControl.dyeChangedControl then 
            swatchControl.dyeChangedControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGB())
        end
    end

    ZO_Dyeing_Gamepad_SwatchSlot_Highlight_All(control)
end

-- XML functions --

function ZO_SwatchSlotDyes_WithHighlight_Gamepad_OnInitialize(control)
    ZO_SwatchSlotDyes_OnInitialize(control)

    control.dyeHighlightControls =
    {
        control:GetNamedChild("PrimaryHighlight"),
        control:GetNamedChild("SecondaryHighlight"),
        control:GetNamedChild("AccentHighlight"),
    }
end