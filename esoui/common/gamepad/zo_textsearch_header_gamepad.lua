ZO_TextSearch_Header_Gamepad = ZO_InitializingCallbackObject:Subclass()

function ZO_TextSearch_Header_Gamepad:Initialize(control, onTextChangedCallback)
    self.control = control

    self.headerTextFilterControl = control:GetNamedChild("Filter")
    self.headerTextFilterEditBox = self.headerTextFilterControl:GetNamedChild("SearchEdit")
    self.headerTextFilterHighlight = self.headerTextFilterControl:GetNamedChild("Highlight")
    self.headerTextFilterIcon = self.headerTextFilterControl:GetNamedChild("Icon")
    self.headerBGTexture = self.headerTextFilterControl:GetNamedChild("BG")

    self.active = false
    self.enabled = true

    self.headerTextFilterEditBox:SetHandler("OnTextChanged", onTextChangedCallback)
    --When the edit box loses focus, fire off a callback that screen narration will listen for
    self.headerTextFilterEditBox:SetHandler("OnFocusLost", function() self:FireCallbacks("EditBoxFocusLost") end, "TextSearchHeader")
end

function ZO_TextSearch_Header_Gamepad:IsActive()
    return self.active
end

function ZO_TextSearch_Header_Gamepad:Activate()
    self.active = true
    self:Update()
    self:FireCallbacks("FocusActivated")
end

function ZO_TextSearch_Header_Gamepad:Deactivate()
    self.active = false
    self:Update()
    self:FireCallbacks("FocusDeactivated")
end

function ZO_TextSearch_Header_Gamepad:Update()
    self.headerTextFilterHighlight:SetHidden(not self.active)
    self.headerBGTexture:SetHidden(not self.active)

    if self.active then
        self.headerTextFilterIcon:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    else
        self.headerTextFilterIcon:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())

        if self.headerTextFilterEditBox:HasFocus() then
            self.headerTextFilterEditBox:LoseFocus()
        end
    end
end

function ZO_TextSearch_Header_Gamepad:IsActive()
    return self.active
end

function ZO_TextSearch_Header_Gamepad:SetFocused(isFocused)
    if isFocused then
        self.headerTextFilterEditBox:TakeFocus()
    elseif self.headerTextFilterEditBox:HasFocus() then
        self.headerTextFilterEditBox:LoseFocus()
    end
end

function ZO_TextSearch_Header_Gamepad:UpdateTextForContext(context, suppressCallback)
    self.headerTextFilterEditBox:SetText(TEXT_SEARCH_MANAGER:GetSearchText(context), suppressCallback)
end

function ZO_TextSearch_Header_Gamepad:ClearText()
    return self.headerTextFilterEditBox:SetText("")
end

function ZO_TextSearch_Header_Gamepad:GetText()
    return self.headerTextFilterEditBox:GetText()
end

function ZO_TextSearch_Header_Gamepad:GetEditBox()
    return self.headerTextFilterEditBox
end

function ZO_TextSearch_Header_Gamepad:GetNarrationText()
    return ZO_FormatEditBoxNarrationText(self:GetEditBox(), GetString(SI_SCREEN_NARRATION_EDIT_BOX_SEARCH_NAME))
end