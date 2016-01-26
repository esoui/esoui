--[[

This combines a set of edit controls into a group that can be navigated using the TAB key. Shift+TAB can be used to navigate the group in reverse.

--]]
ZO_EditControlGroup = ZO_Object:Subclass()

function ZO_EditControlGroup:New()
    local group = ZO_Object.New(self)

    group:Initialize()

    return group
end

function ZO_EditControlGroup:Initialize()
    self.editControls = {}
end

function ZO_EditControlGroup:OnTabPressed(control)
    local index = control.editControlGroupIndex
    local newIndex = index + (IsShiftKeyDown() and -1 or 1)
    if newIndex < 1 then
        newIndex = #self.editControls
    elseif newIndex > #self.editControls then
        newIndex = 1
    end

    self.editControls[newIndex]:TakeFocus()
end

function ZO_EditControlGroup:AddEditControl(control, autoCompleteObject)
    self.editControls[#self.editControls + 1] = control
    control.editControlGroupIndex = #self.editControls

    if autoCompleteObject then
        local autoCompleteTabHandler = control:GetHandler("OnTab")

        control:SetHandler("OnTab", function (control, ...)
            if autoCompleteObject:IsOpen() then
                autoCompleteTabHandler(control, ...)
            else
                self:OnTabPressed(control)
            end
        end)
    else
        control:SetHandler("OnTab", function(control)
            self:OnTabPressed(control)
        end)
    end
end