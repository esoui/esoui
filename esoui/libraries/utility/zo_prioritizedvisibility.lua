ZO_PrioritizedVisibility = ZO_Object:Subclass()

function ZO_PrioritizedVisibility:New(...)
    local prioritizedVisibility = ZO_Object.New(self)
    prioritizedVisibility:Initialize(...)
    return prioritizedVisibility
end

function ZO_PrioritizedVisibility:Initialize()
    self.prioritizedObjectsToShow = {}
    self.objectToPriority = {}
    self.supressed = false

    self.searchComparator = function(left, right)
        return self.objectToPriority[left] - self.objectToPriority[right]
    end
end

-- These can be controls or objects with a SetHidden method
function ZO_PrioritizedVisibility:Add(objectToControl, priority)
    self.objectToPriority[objectToControl] = priority
end

function ZO_PrioritizedVisibility:SetHidden(objectToControl, hidden)
    local found, index = zo_binarysearch(objectToControl, self.prioritizedObjectsToShow, self.searchComparator)
    if found then
        if hidden then
            table.remove(self.prioritizedObjectsToShow, index)
            
            if index == 1 then
                objectToControl:SetHidden(true)
                if #self.prioritizedObjectsToShow > 0 then
                    self.prioritizedObjectsToShow[1]:SetHidden(self.supressed)
                end
            end
        end
    else
        if not hidden then
            if index == 1 and #self.prioritizedObjectsToShow > 0 then
                self.prioritizedObjectsToShow[1]:SetHidden(true)
            end
            table.insert(self.prioritizedObjectsToShow, index, objectToControl)
            objectToControl:SetHidden(self.supressed or index ~= 1)
        end
    end
end

function ZO_PrioritizedVisibility:IsHidden(objectToControl)
    return self.prioritizedObjectsToShow[1] ~= objectToControl
end

function ZO_PrioritizedVisibility:SetSupressed(supressed)
    if self.supressed ~= supressed then
        self.supressed = supressed
        if #self.prioritizedObjectsToShow > 0 then
            self.prioritizedObjectsToShow[1]:SetHidden(supressed)
        end
    end
end

function ZO_PrioritizedVisibility:IsSuppressed()
    return self.supressed
end
