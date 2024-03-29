--[[

    A generic pool to contain "active" and "free" objects.  Active objects
    are typically objects which:
        1. Have a relatively high construction cost
        2. Are not lightweight enough to create many of them at once
        3. Tend to be reused as dynamic elements of a larger container.
        
    The pool should "rapidly" reach a high-water mark of contained objects
    which should flow between active and free states on a regular basis.
    
    Ideal uses of the ZO_ObjectPool would be to contain objects such as:
        1. Scrolling combat text
        2. Tracked quests
        3. Buff icons
        
    The pools are not intended to be used to track a dynamic set of 
    contained objects whose membership grows to a predetermined size.
    As such, do NOT use the pool to track:
        1. Chat filters
        2. Inventory slots
        3. Action buttons (unless creating something like AutoBar)
        
    A common usage pattern is instantiating templated controls.  To facilitate this
    without bloating your own code you should use ZO_ObjectPool_CreateControl which has
    been written here as a convenience.  It creates a control named "template"..id where
    id is an arbitrary value that will not conflict with other generated id's.
    
    If your system depends on having well-known names for controls, you should not use the
    convenience function.    
--]]

ZO_ObjectPool = ZO_InitializingObject:Subclass()

function ZO_ObjectPool:Initialize(factoryFunctionOrObjectClass, resetFunction)
    assert(factoryFunctionOrObjectClass ~= nil)

    self.m_Active = {}
    self.m_Free = {}

    self:SetFactory(factoryFunctionOrObjectClass)
    self:SetResetFunction(resetFunction)
    
    self.m_NextFree = 1 -- Just in case the user would like the pool to generate object keys.
    self.m_NextControlId = 0 -- Just in case the user would like the pool to generate id-based control suffixes
end

-- Define the primary factory behavior
function ZO_ObjectPool:SetFactory(factoryFunctionOrObjectClass)
    if type(factoryFunctionOrObjectClass) == "function" then
        self.m_Factory = factoryFunctionOrObjectClass -- Signature: function(ZO_ObjectPool, objectKey)
    else
        self.m_Factory = function(pool, objectKey) return factoryFunctionOrObjectClass:New(pool, objectKey) end
    end
end

-- Define the primary reset behavior
function ZO_ObjectPool:SetResetFunction(resetFunction)
    self.m_Reset = resetFunction -- Signature: function(objectBeingReset, ZO_ObjectPool)
end

function ZO_ObjectPool:GetNextFree()
    local freeKey, object = next(self.m_Free)
    if freeKey == nil or object == nil then
        local nextPotentialFree = self.m_NextFree
        self.m_NextFree = self.m_NextFree + 1
        return nextPotentialFree, nil
    end

    return freeKey, object
end

function ZO_ObjectPool:GetNextControlId()
    self.m_NextControlId = self.m_NextControlId + 1
    return self.m_NextControlId
end

function ZO_ObjectPool:GetTotalObjectCount()
    return self:GetActiveObjectCount() + self:GetFreeObjectCount()
end

function ZO_ObjectPool:GetActiveObjectCount()
    return NonContiguousCount(self.m_Active)
end

function ZO_ObjectPool:HasActiveObjects()
    return next(self.m_Active) ~= nil
end

function ZO_ObjectPool:GetActiveObjects()
    return self.m_Active
end

function ZO_ObjectPool:GetActiveObject(objectKey)
    return self.m_Active[objectKey]
end

function ZO_ObjectPool:ActiveObjectIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.m_Active, filterFunctions)
end

function ZO_ObjectPool:GetFreeObjectCount()
    return NonContiguousCount(self.m_Free)
end

function ZO_ObjectPool:ActiveAndFreeObjectIterator(filterFunctions)
    local objects = {}
    ZO_CombineNonContiguousTables(objects, self.m_Active, self.m_Free)
    return ZO_FilteredNonContiguousTableIterator(objects, filterFunctions)
end

function ZO_ObjectPool:SetCustomAcquireBehavior(customAcquireBehavior)
    self.customAcquireBehavior = customAcquireBehavior -- Signature: function(objectBeingAcquired, objectKey)
end

-- Optional supplementary behavior that can be run after the factory has created the object
-- Often used in conjunction with extension pool classes (e.g.: ZO_ControlPool) when you want all the default factory behavior, plus something extra
function ZO_ObjectPool:SetCustomFactoryBehavior(customFactoryBehavior)
    self.customFactoryBehavior = customFactoryBehavior -- Signature: function(objectBeingCreated, objectKey, ZO_ObjectPool)
end

-- Optional supplementary behavior that can be run after the primary reset function has been run on the object
-- Often used in conjunction with extension pool classes (e.g.: ZO_ControlPool) when you want all the default reset behavior, plus something extra
function ZO_ObjectPool:SetCustomResetBehavior(customResetBehavior)
    self.customResetBehavior = customResetBehavior -- Signature: function(objectBeingReset)
end

function ZO_ObjectPool:AcquireObject(objectKey)
    -- If the object referred to by this key is already
    -- active there is very little work to do...just return it.
    local object = objectKey and self.m_Active[objectKey] or nil
    if object then
        return object, objectKey
    end
    
    -- If we know the key that we want, use that object first, otherwise just return the first object from the free pool
    -- A nil objectKey means that the caller doesn't care about tracking unique keys for these objects, or that the keys
    -- the system uses can't directly be used to look up the data.  Just manage them with pool-generated id's
    if objectKey == nil then
        objectKey, object = self:GetNextFree()
    else
        object = self.m_Free[objectKey]
    end

    --
    -- If the object is valid it was reclaimed from the free list, otherwise it needs to be created.
    -- Creation uses the m_Factory member which receives this pool as its only argument.
    -- Either way, after this, object must be non-nil
    --
    if object then
        self.m_Free[objectKey] = nil
    else        
        object = self:CreateObject(objectKey)
    end
           
    self.m_Active[objectKey] = object

    if self.customAcquireBehavior then
        self.customAcquireBehavior(object, objectKey)
    end
        
    return object, objectKey
end

function ZO_ObjectPool:CreateObject(objectKey)
    local object = self:m_Factory(objectKey)

    if self.customFactoryBehavior then
        self.customFactoryBehavior(object, objectKey, self)
    end

    return object
end

function ZO_ObjectPool:ReleaseObject(objectKey)
    local object = self.m_Active[objectKey]
    
    if object then
        self:ResetObject(object)
        
        self.m_Active[objectKey] = nil
        self.m_Free[objectKey] = object
    end
end

function ZO_ObjectPool:ReleaseAllObjects()
    for k, v in pairs(self.m_Active) do
        self:ResetObject(v)
        
        self.m_Free[k] = v
    end
    
    ZO_ClearTable(self.m_Active)
end

function ZO_ObjectPool:ResetObject(object)
    if self.m_Reset then
        self.m_Reset(object, self)
    end

    if self.customResetBehavior then
        self.customResetBehavior(object)
    end
end

function ZO_ObjectPool:DestroyFreeObject(objectKey, destroyFunction)
    local object = self.m_Free[objectKey]
    destroyFunction(object)
    self.m_Free[objectKey] = nil
end

function ZO_ObjectPool:DestroyAllFreeObjects(destroyFunction)
    for _, object in pairs(self.m_Free) do
        destroyFunction(object)
    end
    ZO_ClearTable(self.m_Free)
end

function ZO_ObjectPool_CreateControl(templateName, objectPool, parentControl)
    return CreateControlFromVirtual(templateName, parentControl, templateName, objectPool:GetNextControlId())
end

function ZO_ObjectPool_CreateNamedControl(name, templateName, objectPool, parentControl)
    return CreateControlFromVirtual(name, parentControl, templateName, objectPool:GetNextControlId())
end

function ZO_ObjectPool_DefaultResetObject(object)
    object:Reset()
end

function ZO_ObjectPool_DefaultResetControl(control)
    control:SetHidden(true)
end