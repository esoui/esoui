--[[
    Animation Pool
--]]

ZO_AnimationPool = ZO_ObjectPool:Subclass()

do
    local function AnimationReset(timeline)
        timeline:Stop()
    end

    function ZO_AnimationPool:Initialize(templateName)
        local function AnimationFactory()
            return ANIMATION_MANAGER:CreateTimelineFromVirtual(templateName)
        end

        ZO_ObjectPool.Initialize(self, AnimationFactory, AnimationReset)
    end
end

--[[
    Control Pool
--]]

ZO_ControlPool = ZO_ObjectPool:Subclass()

do
    local function ControlFactory(pool)
        return ZO_ObjectPool_CreateNamedControl(pool.name, pool.templateName, pool, pool.parent)
    end

    local function ControlReset(control)
        control:SetHidden(true)
        control:ClearAnchors()
    end

    function ZO_ControlPool:Initialize(templateName, parent, overrideName)
        ZO_ObjectPool.Initialize(self, ControlFactory, ControlReset)

        local controlName = overrideName or templateName

        parent = parent or GuiRoot
        if parent ~= GuiRoot then
            controlName = parent:GetName() .. controlName
        end

        self.name = controlName
        self.parent = parent
        self.templateName = templateName
    end
end

-- Begin ZO_ObjectPool Overrides --

function ZO_ControlPool:AcquireObject(objectKey)
    local control, key = ZO_ObjectPool.AcquireObject(self, objectKey)
    if control then
        control:SetHidden(false)
    end
    return control, key
end

-- End ZO_ObjectPool Overrides --

--[[
    Entry Data Pool
--]]

ZO_EntryDataPool = ZO_ObjectPool:Subclass()

function ZO_EntryDataPool:Initialize(entryDataObjectClass, factoryFunction, resetFunction)
    factoryFunction = factoryFunction or function()
        -- EntryData classes typically take dataSource in their constructors,
        -- so we can't use ZO_ObjectPool's default factory object behavior, which constructs with the pool and key
        return self.entryDataObjectClass:New()
    end

    resetFunction = resetFunction or function(entryData)
        entryData:SetDataSource(nil)
    end

    ZO_ObjectPool.Initialize(self, factoryFunction, resetFunction)

    self.entryDataObjectClass = entryDataObjectClass
end

-- Begin ZO_ObjectPool Overrides --

function ZO_EntryDataPool:AcquireObject(objectKey, dataSource)
    local entryData, key = ZO_ObjectPool.AcquireObject(self, objectKey)
    if entryData and dataSource then
        entryData:SetDataSource(dataSource)
    end
    return entryData, key
end

-- End ZO_ObjectPool Overrides --

--[[
    Meta Pool
]]--

ZO_MetaPool = ZO_Object:Subclass()

function ZO_MetaPool:New(sourcePool)
    local pool = ZO_Object.New(self)
    pool.sourcePool = sourcePool
    pool.activeObjects = {}
    return pool
end

function ZO_MetaPool:AcquireObject()
    local object, key = self.sourcePool:AcquireObject()
    self.activeObjects[key] = object
    if self.customAcquireBehavior then
        self.customAcquireBehavior(object)
    end
    return object, key
end

function ZO_MetaPool:GetActiveObject(objectKey)
    return self.activeObjects[objectKey]
end

function ZO_MetaPool:GetActiveObjectCount()
    return NonContiguousCount(self.activeObjects)
end

function ZO_MetaPool:HasActiveObjects()
    return next(self.activeObjects) ~= nil
end

function ZO_MetaPool:GetActiveObjects()
    return self.activeObjects
end

function ZO_MetaPool:ActiveObjectIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.activeObjects, filterFunctions)
end

function ZO_MetaPool:ReleaseAllObjects()
    for key, object in pairs(self.activeObjects) do
        if self.customResetBehavior then
            self.customResetBehavior(object)
        end
        self.sourcePool:ReleaseObject(key)
    end

    ZO_ClearTable(self.activeObjects)
end

function ZO_MetaPool:ReleaseObject(objectKey)
    local object = self.activeObjects[objectKey]
    if self.customResetBehavior then
        self.customResetBehavior(object)
    end
    self.sourcePool:ReleaseObject(objectKey)
    self.activeObjects[objectKey] = nil
end

function ZO_MetaPool:SetCustomAcquireBehavior(customAcquireBehavior)
    self.customAcquireBehavior = customAcquireBehavior
end

function ZO_MetaPool:SetCustomResetBehavior(customeResetBehavior)
    self.customResetBehavior = customeResetBehavior
end