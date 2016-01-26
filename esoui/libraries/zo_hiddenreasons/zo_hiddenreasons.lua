ZO_HiddenReasons = ZO_Object:Subclass()

function ZO_HiddenReasons:New()
    local object = ZO_Object.New(self)
    return object
end

function ZO_HiddenReasons:AddShowReason(reason)
    if(not self.possibleShownReasons) then
        self.possibleShownReasons = {}
    end
    self.possibleShownReasons[reason] = true
end

function ZO_HiddenReasons:RemoveShowReason(reason)
    if(self.possibleShownReasons) then
        self.possibleShownReasons[reason] = nil
        if(self.shownReasons) then
            self.shownReasons[reason] = nil
        end
    end
end

function ZO_HiddenReasons:StoreReason(reasonTable, reason, value)
    local storeValue = value
    if(not value) then
        value = nil
    end

    if(reasonTable[reason] ~= value) then
        reasonTable[reason] = value
        return true
    end

    return false
end

function ZO_HiddenReasons:SetHiddenForReason(reason, hidden)
    if(not self.hiddenReasons) then
        self.hiddenReasons = {}
    end
    return self:StoreReason(self.hiddenReasons, reason, hidden)    
end

function ZO_HiddenReasons:IsHiddenForReason(reason, hidden)
    if(self.hiddenReasons) then
        return self.hiddenReasons[reason] == true
    end
end

function ZO_HiddenReasons:SetShownForReason(reason, shown)
    if(not self.shownReasons) then
        self.shownReasons = {}
    end
    return self:StoreReason(self.shownReasons, reason, shown)
end

function ZO_HiddenReasons:IsHidden()
    if(self.hiddenReasons) then
        if(next(self.hiddenReasons) ~= nil) then
            return true
        end
    end
    if(self.possibleShownReasons and next(self.possibleShownReasons)) then
        if(not self.shownReasons or next(self.shownReasons) == nil) then
            return true
        end
    end

    return false
end