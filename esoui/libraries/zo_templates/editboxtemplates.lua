function ZO_DefaultEdit_SetEnabled(editBox, enabled)
    if(enabled) then
        editBox:SetHandler("OnMouseDown", ZO_DefaultEdit_OnMouseDown)
        editBox:SetColor(DEFAULT_EDIT_BOX_ENABLED_COLOR:UnpackRGBA())
    else
        editBox:LoseFocus()
        editBox:SetColor(DEFAULT_EDIT_BOX_DISABLED_COLOR:UnpackRGBA())
        editBox:SetHandler("OnMouseDown", nil)
    end
end

do
    local function UpdateVisibility(self)
        local label = GetControl(self, "Text")
        if(self.defaultTextEnabled) then
            if(self:GetText() == "" and not self:IsComposingIMEText()) then
                label:SetHidden(false)
            else
                label:SetHidden(true)
            end
        else
            label:SetHidden(true)
        end
    end

    function ZO_EditDefaultText_Initialize(self, defaultText)
        local label = GetControl(self, "Text")
        label:SetText(defaultText)
        self.defaultTextEnabled = true
        UpdateVisibility(self)
    end

    function ZO_EditDefaultText_Disable(self)
        self.defaultTextEnabled = false
        UpdateVisibility(self)
    end

    function ZO_EditDefaultText_OnTextChanged(self)
        UpdateVisibility(self)
    end

    function ZO_EditDefaultText_OnIMECompositionChanged(self)
        UpdateVisibility(self)
    end
end