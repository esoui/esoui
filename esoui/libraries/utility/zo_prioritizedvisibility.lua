-- Sentinel category values applicable to any ZO_PrioritizedVisibility instance.
ZO_PRIORITIZED_VISIBILITY_CATEGORIES =
{
    NONE = 0,
    ALL = 2 ^ (ZO_INTEGER_53_MAX_BITS - 1), -- Highest order bit that can be combined with lower bits without an overflow condition.
}

local PrioritizedVisibilityObjectInfo = ZO_InitializingObject:Subclass()

function PrioritizedVisibilityObjectInfo:Initialize(object, priority, categoryFlags, descriptor)
    self.object = object
    self.priority = priority
    self.categoryFlags = categoryFlags
    self.descriptor = descriptor

    self:SetHidden(true)
    self:SetRequestedHidden(true)
end

-- Returns true if this object info is neither hidden by request nor a member of any of the specified suppressed categories.
function PrioritizedVisibilityObjectInfo:CanShow(suppressedCategoriesMask)
    return not (self.requestedHidden or ZO_FlagHelpers.MasksShareAnyFlag(self.categoryFlags, suppressedCategoriesMask))
end

-- Returns true if this object info has a higher priority than the specified object info.
function PrioritizedVisibilityObjectInfo:ComparePriority(objectInfo)
    return self.priority - objectInfo.priority
end

function PrioritizedVisibilityObjectInfo:GetDescriptor()
    return self.descriptor
end

function PrioritizedVisibilityObjectInfo:GetCategoryFlags()
    return self.categoryFlags
end

function PrioritizedVisibilityObjectInfo:GetPriority()
    return self.priority
end

function PrioritizedVisibilityObjectInfo:GetObject()
    return self.object
end

-- Returns true if this object info has requested to be hidden.
function PrioritizedVisibilityObjectInfo:IsRequestedHidden()
    return self.requestedHidden
end

-- Shows or hides the underlying object or control.
function PrioritizedVisibilityObjectInfo:SetHidden(hidden)
    self.object:SetHidden(hidden)
end

-- Sets or clears the request to hide flag.
function PrioritizedVisibilityObjectInfo:SetRequestedHidden(hidden)
    self.requestedHidden = hidden
end

ZO_PrioritizedVisibility = ZO_InitializingCallbackObject:Subclass()

function ZO_PrioritizedVisibility:Initialize()
    self.prioritizedObjects = {}
    self.registeredObjects = {}
    self.suppressedCategories = {}
    self.suppressedCategoriesMask = 0

    local function PriorityComparator(left, right)
        local leftObject = self.registeredObjects[left]
        local rightObject = self.registeredObjects[right]
        return rightObject:ComparePriority(leftObject) > 0
    end
    self.priorityComparator = PriorityComparator
end

-- 'object' can be a control or an object that implements a 'SetHidden' method.
-- Note that objects are immediately hidden when added.
function ZO_PrioritizedVisibility:Add(object, priority, categoryFlags, descriptor)
    -- Add all objects to the sentinel "All" category.
    categoryFlags = ZO_FlagHelpers.SetMaskFlag(categoryFlags or ZO_PRIORITIZED_VISIBILITY_CATEGORIES.NONE, ZO_PRIORITIZED_VISIBILITY_CATEGORIES.ALL)

    self.arePrioritizedObjectsDirty = true
    self.registeredObjects[object] = PrioritizedVisibilityObjectInfo:New(object, priority, categoryFlags, descriptor)

    -- Create any suppressed category descriptor tables for this object's category
    -- flag(s) that do not already exist.
    for categoryFlag in ZO_FlagHelpers.MaskHasFlagsIterator(categoryFlags) do
        if not self.suppressedCategories[categoryFlag] then
            self.suppressedCategories[categoryFlag] = {}
        end
    end
end

-- Returns the object info associated with the specified object.
function ZO_PrioritizedVisibility:GetObjectInfo(object)
    local objectInfo = self.registeredObjects[object]
    return objectInfo
end

-- Returns true if any of the specified category or categories is/are suppressed.
function ZO_PrioritizedVisibility:IsCategorySuppressed(categoriesMask)
    return ZO_FlagHelpers.MasksShareAnyFlag(self.suppressedCategoriesMask, categoriesMask)
end

-- Returns true if the specified object is the highest priority object that has
-- requested to be shown and is not a member of any suppressed categories.
function ZO_PrioritizedVisibility:IsHidden(object)
    return not self:IsHighestPriorityVisibleObject(object)
end

-- Returns true if the specified object is the highest priority object that has
-- requested to show and which is not a member of any suppressed categories.
function ZO_PrioritizedVisibility:IsHighestPriorityVisibleObject(object)
    return self.highestPriorityVisibleObject and object == self.highestPriorityVisibleObject:GetObject()
end

-- Sets or clears the specified category as suppressed.
-- Note that 'descriptor' should be a globally unique identifier of the system issuing the request.
function ZO_PrioritizedVisibility:SetCategorySuppressed(suppressed, categoryFlag, descriptor)
    if not internalassert(descriptor, "Parameter 'descriptor' is required.") then
        return false
    end

    local previousSuppressedCategoriesMask = self.suppressedCategoriesMask

    -- Add or remove descriptor for this suppressed category.
    local suppressedCategoryDescriptors = self.suppressedCategories[categoryFlag]
    if suppressed then
        suppressedCategoryDescriptors[descriptor] = true
    else
        suppressedCategoryDescriptors[descriptor] = nil
    end

    -- Update the suppressed category mask.
    if next(suppressedCategoryDescriptors) then
        self.suppressedCategoriesMask = ZO_FlagHelpers.SetMaskFlag(self.suppressedCategoriesMask, categoryFlag)
    else
        self.suppressedCategoriesMask = ZO_FlagHelpers.ClearMaskFlag(self.suppressedCategoriesMask, categoryFlag)
    end

    if previousSuppressedCategoriesMask ~= self.suppressedCategoriesMask then
        -- The suppressed categories changed; evaluate the new, highest priority visible object.
        self:UpdateHighestPriorityVisibleObject()
    end

    return true
end

-- Suppresses or unsuppresses the specified categories.
-- Note that 'descriptor' should be a globally unique identifier of the system issuing the request.
function ZO_PrioritizedVisibility:SetCategoriesSuppressed(suppressed, categoryMask, descriptor)
    -- Iterate over all registered categories.
    for categoryFlag in ZO_FlagHelpers.MaskHasFlagsIterator(categoryMask) do
        self:SetCategorySuppressed(suppressed, categoryFlag, descriptor)
    end

    return true
end

-- If 'suppressed' is true, suppresses the specified categories and unsuppresses all other categories;
-- otherwise this unsuppresses the specified categories and suppresses all other categories.
-- Note that 'descriptor' should be a globally unique identifier of the system issuing the request.
function ZO_PrioritizedVisibility:SetSuppressedCategoriesMask(suppressed, categoryMask, descriptor)
    -- Iterate over all registered categories.
    for categoryFlag in pairs(self.suppressedCategories) do
        local suppressCategory
        if suppressed then
            -- Suppress the category if specified in the mask; otherwise unsuppress the category.
            suppressCategory = BitAnd(categoryFlag, categoryMask) ~= 0
        else
            -- Unsuppress the category if specified in the mask; otherwise suppress the category.
            suppressCategory = BitAnd(categoryFlag, categoryMask) == 0
        end
        self:SetCategorySuppressed(suppressCategory, categoryFlag, descriptor)
    end

    return true
end

-- Requests to show or hide the specified object or control.
-- Note that a request to show is granted once the object is
-- the highest priority object that requested to show and is
-- not a member of any suppressed category.
function ZO_PrioritizedVisibility:SetHidden(object, hidden)
    local objectInfo = self.registeredObjects[object]
    if objectInfo:IsRequestedHidden() == hidden then
        return
    end

    -- Update the requested hidden flag for this object.
    objectInfo:SetRequestedHidden(hidden)

    -- Choose the new, highest priority, visible and unsuppressed object.
    self:UpdateHighestPriorityVisibleObject()
end

-- Rebuilds the prioritized objects array in order of highest to lowest priority.
function ZO_PrioritizedVisibility:UpdatePrioritizedObjects()
    ZO_ClearNumericallyIndexedTable(self.prioritizedObjects)

    for _, objectInfo in pairs(self.registeredObjects) do
        table.insert(self.prioritizedObjects, objectInfo:GetObject())
    end

    table.sort(self.prioritizedObjects, self.priorityComparator)
end

function ZO_PrioritizedVisibility:UpdateHighestPriorityVisibleObject()
    if self.arePrioritizedObjectsDirty then
        -- New objects have been registered; update the prioritized object array.
        self:UpdatePrioritizedObjects()
        self.arePrioritizedObjectsDirty = nil
    end

    -- Evaluate objects in order of highest to lowest priority
    -- until an object that is valid for showing is found.
    local highestPriorityVisibleObject = nil
    local suppressedCategoriesMask = self.suppressedCategoriesMask
    for _, object in ipairs(self.prioritizedObjects) do
        local objectInfo = self.registeredObjects[object]
        if objectInfo:CanShow(suppressedCategoriesMask) then
            -- This object has requested to show and is not a
            -- member of any suppressed categories.
            highestPriorityVisibleObject = objectInfo
            break
        end
    end

    local highestPriorityVisibleObjectChanged = self.highestPriorityVisibleObject ~= highestPriorityVisibleObject
    if highestPriorityVisibleObjectChanged then
        local previousObjectInfo = self.highestPriorityVisibleObject
        local newObjectInfo = highestPriorityVisibleObject
        self:FireCallbacks("VisibleObjectChanged", newObjectInfo, previousObjectInfo)

        if self.highestPriorityVisibleObject then
            -- Hide the previously highest priority visible object.
            self.highestPriorityVisibleObject:SetHidden(true)
        end

        -- Assign the new highest priority visible object.
        self.highestPriorityVisibleObject = highestPriorityVisibleObject

        if self.highestPriorityVisibleObject then
            -- Show the new highest priority visible object.
            self.highestPriorityVisibleObject:SetHidden(false)
        end
    end
end