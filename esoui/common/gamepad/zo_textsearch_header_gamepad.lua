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

function ZO_TextSearch_Header_Gamepad:GetText()
    return self.headerTextFilterEditBox:GetText()
end