-----------------------
-- ZO_EditBox
-----------------------

ZO_EditBox = ZO_CallbackObject:Subclass()

function ZO_EditBox:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_EditBox:Initialize(control)
    self.control = control

    self.edit = control:GetNamedChild("Edit")
    self.empty = control:GetNamedChild("Empty")

    self.edit:SetHandler("OnTextChanged", function() self:Refresh() end)
end

function ZO_EditBox:SetDefaultText(defaultText)
    self.edit:SetDefaultText(defaultText)
end

function ZO_EditBox:SetEmptyText(emptyText)
    self.empty:SetText(emptyText)
end

function ZO_EditBox:GetText()
    return self.edit:GetText()
end

function ZO_EditBox:SetText(text)
    local hideEmptyText = text ~= ""
    self.empty:SetHidden(hideEmptyText)

    self.edit:SetText(text)
end

function ZO_EditBox:Refresh()
    local hideEmptyText = self:GetText() ~= ""
    self.empty:SetHidden(hideEmptyText)
end

function ZO_EditBox:GetControl()
    return self.control
end

function ZO_EditBox:GetEditControl()
    return self.edit
end

function ZO_EditBox:TakeFocus()
    return self.edit:TakeFocus()
end

function ZO_EditBox:LoseFocus()
    return self.edit:LoseFocus()
end