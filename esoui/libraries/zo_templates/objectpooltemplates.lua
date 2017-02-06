--[[
    Animation Pool
--]]

ZO_AnimationPool = ZO_ObjectPool:Subclass()

do
    local function Reset(animation, pool)
        animation:Stop()

        if(pool.customResetBehavior) then
            pool.customResetBehavior(animation)
        end
    end    
    
    function ZO_AnimationPool:New(templateName)
        local function AnimationFactory(pool)
            return ANIMATION_MANAGER:CreateTimelineFromVirtual(templateName)
        end

        return ZO_ObjectPool.New(self, AnimationFactory, Reset)
    end
end

function ZO_AnimationPool:SetCustomResetBehavior(customResetBehavior)
    self.customResetBehavior = customResetBehavior
end

--[[
    Control Pool
--]]

ZO_ControlPool = ZO_ObjectPool:Subclass()

local function ControlFactory(pool)
    local control = ZO_ObjectPool_CreateNamedControl(pool.name, pool.templateName, pool, pool.parent)
    if(pool.customFactoryBehavior) then
        pool.customFactoryBehavior(control)
    end
    return control
end

local function ControlReset(control, pool)
    control:SetHidden(true)
    control:ClearAnchors()
    if(pool.customResetBehavior) then
        pool.customResetBehavior(control)
    end
end

function ZO_ControlPool:New(templateName, parent, prefix)
    local pool = ZO_ObjectPool.New(self, ControlFactory, ControlReset)
    
    if(parent) then
        if(prefix) then
            pool.name = parent:GetName()..prefix
        else
            pool.name = parent:GetName()..templateName
        end
        
        pool.parent = parent
    else
        pool.name = templateName
        pool.parent = GuiRoot
    end

    pool.templateName = templateName
    
    return pool 
end

function ZO_ControlPool:SetCustomFactoryBehavior(customFactoryBehavior)
    self.customFactoryBehavior = customFactoryBehavior
end

function ZO_ControlPool:SetCustomResetBehavior(customResetBehavior)
    self.customResetBehavior = customResetBehavior
end

function ZO_ControlPool:SetCustomAcquireBehavior(customAcquireBehavior)
    self.customAcquireBehavior = customAcquireBehavior
end

function ZO_ControlPool:AcquireObject(objectKey)
    local control, key = ZO_ObjectPool.AcquireObject(self, objectKey)
    if(control) then
        control:SetHidden(false)
    end
    if self.customAcquireBehavior then
        self.customAcquireBehavior(control)
    end
    return control, key
end

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

function ZO_MetaPool:GetExistingObject(objectKey)
    return self.activeObjects[key]
end

function ZO_MetaPool:GetActiveObjectCount()
    return NonContiguousCount(self.activeObjects)
end

function ZO_MetaPool:ReleaseAllObjects()
    for key, object in pairs(self.activeObjects) do
        if self.customResetBehavior then
            self.customResetBehavior(object)
        end
        self.sourcePool:ReleaseObject(key)
    end
    self.activeObjects = {}
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