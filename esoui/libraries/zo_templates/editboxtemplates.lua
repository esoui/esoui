local DEFAULT_EDIT_BOX_ENABLED_COLOR = ZO_ColorDef:New(1,1,1,1)
local DEFAULT_EDIT_BOX_DISABLED_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))

function ZO_DefaultEdit_SetEnabled(editBox, enabled)
    if(enabled) then
        editBox:SetHandler("OnMouseDown", function() editBox:TakeFocus() end)
        editBox:SetColor(DEFAULT_EDIT_BOX_ENABLED_COLOR:UnpackRGBA())
    else
        editBox:LoseFocus()
        editBox:SetColor(DEFAULT_EDIT_BOX_DISABLED_COLOR:UnpackRGBA())
        editBox:SetHandler("OnMouseDown", nil)
    end
end