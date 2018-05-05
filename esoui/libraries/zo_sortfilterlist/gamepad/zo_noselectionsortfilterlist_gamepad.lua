----------------------
--Sort/Filter List with no selection
----------------------
ZO_NoSelectionSortFilterList_Gamepad = ZO_SortFilterList:Subclass()

function ZO_NoSelectionSortFilterList_Gamepad:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function ZO_NoSelectionSortFilterList_Gamepad:SetDirectionalInputEnabled(enabled)
    if self.directionalInputEnabled ~= enabled then
        self.directionalInputEnabled = enabled
        if enabled then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

function ZO_NoSelectionSortFilterList_Gamepad:UpdateDirectionalInput()
    local magnitude = DIRECTIONAL_INPUT:GetY(ZO_DI_RIGHT_STICK)
    if zo_abs(magnitude) > 0.05 then 
        local ANIMATE_INSTANTLY = true
        local NO_ON_COMPLETE_CALLBACK = nil
        ZO_ScrollList_ScrollRelative(self.list, -magnitude * 1000 * GetFrameDeltaSeconds(), NO_ON_COMPLETE_CALLBACK, ANIMATE_INSTANTLY)
    end
end