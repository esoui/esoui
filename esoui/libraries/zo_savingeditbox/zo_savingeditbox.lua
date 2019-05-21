ZO_SavingEditBox = ZO_CallbackObject:Subclass()

function ZO_SavingEditBox:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_SavingEditBox:Initialize(control)
    self.control = control

    self.editBackdrop = control:GetNamedChild("Saving")

    self.edit = control:GetNamedChild("SavingEdit")
    self.edit:SetHandler("OnTextChanged", function() self:OnTextChanged() end)
    self.edit:SetHandler("OnEnter", function() self:OnEnter() end)

    self.modifyButton = control:GetNamedChild("Modify")
    self.modifyButton:SetHandler("OnClicked", function() self:OnModifyClicked() end)

    self.saveButton = control:GetNamedChild("Save")
    self.saveButton:SetHandler("OnClicked", function() self:OnSaveClicked() end)

    self.cancelButton = control:GetNamedChild("Cancel")
    self.cancelButton:SetHandler("OnClicked", function() self:OnCancelClicked() end)    

    self.display = control:GetNamedChild("Display")
    self.empty = control:GetNamedChild("Empty")

    self.modified = false
    self.enabled = true
    self.editing = false
    self.putTextInQuotes = true
    self.shouldEscapeMarkup = false

    self:RefreshButtons()
end

function ZO_SavingEditBox:SetDefaultText(defaultText)
    ZO_EditDefaultText_Initialize(self.edit, defaultText)
end

function ZO_SavingEditBox:SetEmptyText(emptyText)
    self.empty:SetText(emptyText)
end

function ZO_SavingEditBox:SetEditing(editing, forceUpdate)
    if forceUpdate or self.editing ~= editing then
        self.editing = editing
        self.editBackdrop:SetHidden(not editing)
        self:RefreshButtons()

        if editing then
            self.edit:TakeFocus()
            self.display:SetHidden(true)
            self.empty:SetHidden(true)
        else
            self.edit:LoseFocus()
            if self.resetText == "" then
                self.empty:SetHidden(false)
            else
                self.display:SetHidden(false)
            end
        end

        self:FireCallbacks("SetEditing", self, editing)
    end
end

function ZO_SavingEditBox:IsEditing()
    return self.editing
end

function ZO_SavingEditBox:SetShouldEscapeNonColorMarkup(shouldEscapeMarkup)
    self.shouldEscapeMarkup = shouldEscapeMarkup
end

function ZO_SavingEditBox:SetEnabled(enabled)
    if enabled ~= self.enabled then
        self.enabled = enabled
        if not self.enabled then
            self:SetEditing(false)
            self:ResetText()
        end
        self:RefreshButtons()
    end
end

function ZO_SavingEditBox:SetHidden(hidden)
    if hidden then
        self:Cancel()
        self.modifyButton:SetHidden(true)
    else
        self.modifyButton:SetHidden(false)
    end
end

function ZO_SavingEditBox:SetCustomTextValidator(validator)
    self.validator = validator
end

function ZO_SavingEditBox:SetPutTextInQuotes(putTextInQuotes)
    self.putTextInQuotes = putTextInQuotes
end

function ZO_SavingEditBox:GetText()
    return self.edit:GetText()
end

function ZO_SavingEditBox:SetText(text, dontSetResetText)
    if not self.editing then
        if text == "" then
            self.display:SetHidden(true)
            self.empty:SetHidden(false)
        else
            self.empty:SetHidden(true)
            self.display:SetHidden(false)
            local displayText = self.shouldEscapeMarkup and EscapeMarkup(text, ALLOW_MARKUP_TYPE_COLOR_ONLY) or text
            if self.putTextInQuotes then
                self.display:SetText(zo_strformat(SI_SAVING_EDIT_BOX_QUOTES, displayText))
            else
                self.display:SetText(displayText)
            end
        end
    end

    self.edit:SetText(text)
    if not dontSetResetText then
        self.resetText = text
        self.modified = false
    end

    self:RefreshButtons()
end

function ZO_SavingEditBox:GetControl()
    return self.control
end

function ZO_SavingEditBox:GetEditControl()
    return self.edit
end

function ZO_SavingEditBox:ResetText()
    self.edit:SetText(self.resetText)
    self.modified = false
    self:RefreshButtons()
end

function ZO_SavingEditBox:OnTextChanged()
    if not self.modified or self.validator then
        if self.validator then
            local text = self.edit:GetText()
            self.validText = self.validator(text)
        else
            self.validText = true
        end
        self.modified = true
        self:RefreshButtons()
    end
    ZO_EditDefaultText_OnTextChanged(self.edit)
end

function ZO_SavingEditBox:OnEnter()
    if not self.edit:IsMultiLine() then
        if self.validText then
            self:OnSaveClicked()
        else
            self:Cancel()
        end
    end
end

function ZO_SavingEditBox:OnSaveClicked()
    local newText = self:GetText()
    self:FireCallbacks("Save", newText)
    self:SetEditing(false)
    self:SetText(newText)
end

function ZO_SavingEditBox:Cancel()
    if self.editing then
        self:SetEditing(false)
        self:ResetText()
    end
end

function ZO_SavingEditBox:OnCancelClicked()
    self:Cancel()
end

function ZO_SavingEditBox:OnModifyClicked()
    self:SetEditing(true)
end

function ZO_SavingEditBox:RefreshButtons()
    if self.enabled then
        if self.editing then
            self.modifyButton:SetHidden(true)
            self.saveButton:SetHidden(false)
            self.cancelButton:SetHidden(false)
            if self.modified and self.validText then
                self.saveButton:SetState(BSTATE_NORMAL, false)
            else
                self.saveButton:SetState(BSTATE_DISABLED, true)
            end

            if self.validText then
                self.edit:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
            else
                self.edit:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_FAILED))
            end
        else
            self.modifyButton:SetHidden(false)
            self.modifyButton:SetState(BSTATE_NORMAL, false)
            self.saveButton:SetHidden(true)
            self.cancelButton:SetHidden(true)
        end
    else
        self.modifyButton:SetHidden(false)
        self.modifyButton:SetState(BSTATE_DISABLED, true)
        self.saveButton:SetHidden(true)
        self.cancelButton:SetHidden(true)
    end
end

--Saving Edit Box Group

ZO_SavingEditBoxGroup = ZO_Object:Subclass()

function ZO_SavingEditBoxGroup:New()
    local group = ZO_Object.New(self)
    group.savingEditBoxes = {}
    group.setEditingCallback =  function(savingEditBox, isEditing)
                                    if isEditing then
                                        for i = 1, #group.savingEditBoxes do
                                            if group.savingEditBoxes[i] ~= savingEditBox then
                                                group.savingEditBoxes[i]:Cancel()
                                            end
                                        end
                                    end
                                end
    return group
end

function ZO_SavingEditBoxGroup:Add(savingEditBox)
    table.insert(self.savingEditBoxes, savingEditBox)
    savingEditBox:RegisterCallback("SetEditing", self.setEditingCallback)
end

-- Scrolling Saving Edit Box

ZO_ScrollingSavingEditBox = ZO_SavingEditBox:Subclass()

function ZO_ScrollingSavingEditBox:New(...)
    return ZO_SavingEditBox.New(self, ...)
end

function ZO_ScrollingSavingEditBox:Initialize(control)
    ZO_SavingEditBox.Initialize(self, control)

    self.pane = control:GetNamedChild("Pane")
    self.paneScroll = self.pane:GetNamedChild("Scroll")

    self.display:ClearAnchors()
    self.display:SetParent(self.pane:GetNamedChild("ScrollChild"))
    self.display:SetAnchor(TOPLEFT)
    self.display:SetWidth(self.control:GetWidth() - 34)
end

function ZO_ScrollingSavingEditBox:SetEditing(editing, forceUpdate)
    ZO_SavingEditBox.SetEditing(self, editing, forceUpdate)

    self.paneScroll:SetMouseEnabled(editing)
end