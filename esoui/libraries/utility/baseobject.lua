local MUST_IMPLEMENT_SENTINEL = function()
    error(2, "Attempted to call unimplemented method!")
end

function ZO_VerifyClassImplementation(finalClass, classTraceback)
    -- detect any instances of ZO_MUST_IMPLEMENT that are not implemented.
    local function VisitClass(currentClass)
        for fieldName, fieldValue in pairs(currentClass) do
            if fieldValue == MUST_IMPLEMENT_SENTINEL and finalClass[fieldName] == MUST_IMPLEMENT_SENTINEL then
                local NO_STACK_TRACE = 0
                error("Class has unimplemented method: " .. fieldName .. "\n" .. classTraceback, NO_STACK_TRACE)
            end
        end

        if currentClass.__parentClasses then
            for _, parentClass in ipairs(currentClass.__parentClasses) do
                VisitClass(parentClass)
            end
        end
    end
    VisitClass(finalClass)
end

local RegisterConcreteClass, RemoveConcreteClass
local SHOULD_VERIFY_CLASSES = GetCVar("EnableLuaClassVerification") == "1"
if SHOULD_VERIFY_CLASSES then
    local g_concreteClassSet = {}
    function RegisterConcreteClass(concreteClass, stackLevel)
        g_concreteClassSet[concreteClass] = debug.traceback(nil, stackLevel + 1)
    end

    function RemoveConcreteClass(concreteClass)
        g_concreteClassSet[concreteClass] = nil
    end

    function ZO_VerifyConcreteClasses()
        for concreteClass, classTraceback in pairs(g_concreteClassSet) do
            ZO_VerifyClassImplementation(concreteClass, classTraceback)
            g_concreteClassSet[concreteClass] = nil
        end
    end

    GetEventManager():RegisterForEvent("BaseObject", EVENT_ADD_ON_LOADED, function()
        ZO_VerifyConcreteClasses()
    end)
else
    -- do nothing instead of tracking and automatically verifying classes
    function RegisterConcreteClass()
    end
    function RemoveConcreteClass()
    end
    function ZO_VerifyConcreteClasses()
    end
end

ZO_Object = {}
ZO_Object.__index = ZO_Object

function ZO_Object:New(template)
    local class = template or self
    local newObject = setmetatable({}, class)
    return newObject
end

---
-- Call ZO_Object:Subclass() to create a new class that inherits from this one.
--
function ZO_Object:Subclass()
    local newClass = setmetatable({}, self)
    newClass.__index = newClass
    newClass.__parentClasses = { self }
    newClass.__isAbstractClass = false
    if self.__isAbstractClass then
        local PARENT_STACK = 2
        RegisterConcreteClass(newClass, PARENT_STACK) 
    end
    return newClass
end

---
-- Call ZO_Object:MultiSubclass() to create a new class that
-- inherits from multiple parent classes. In situations where the same method is
-- defined on multiple classes, the leftmost class in the argument list takes
-- priority. It is recommended that you override to avoid this!
--
function ZO_Object:MultiSubclass(...)
    local parentClasses = { self, ... }
    local newClass = setmetatable({}, {
        __index = function(table, key)
            for _, parentClassTable in ipairs(parentClasses) do
                local value = parentClassTable[key]
                if value ~= nil then
                    return value
                end
            end
        end
    })
    newClass.__index = newClass
    newClass.__parentClasses = parentClasses
    newClass.__isAbstractClass = false
    for _, parentClass in ipairs(parentClasses) do
        if parentClass.__isAbstractClass then
            local PARENT_STACK = 2
            RegisterConcreteClass(newClass, PARENT_STACK) 
            break
        end
    end
    return newClass
end

--- Use MUST_IMPLEMENT to create a field that must be implemented by
-- subclasses. If a concrete class does not implement a field that contains a
-- MUST_IMPLEMENT, it will cause an error after the entire addon has been loaded.
-- Example A: ZO_MyAbstractClass.MyAbstractFunction = ZO_MyAbstractClass:MUST_IMPLEMENT()
-- Example B: ZO_MyAbstractClass:MUST_IMPLEMENT("MyAbstractFunction")
function ZO_Object:MUST_IMPLEMENT(fieldName)
    self.__isAbstractClass = true
    RemoveConcreteClass(self)
    if fieldName then
        self[fieldName] = MUST_IMPLEMENT_SENTINEL
    end
    return MUST_IMPLEMENT_SENTINEL
end

function ZO_Object:IsInstanceOf(checkClass)
    local function VisitClass(currentClass)
        if currentClass == checkClass then
            return true
        end

        if currentClass.__parentClasses then
            for _, parentClass in ipairs(currentClass.__parentClasses) do
                if VisitClass(parentClass) then
                    return true
                end
            end
        end

        return false
    end
    return VisitClass(self.__index)
end

--[[
Here is a simple multiple inheritence example:

local A = ZO_Object:Subclass()

function A:InitializeA()
    self.name = "A"
end

local B = ZO_Object:Subclass()

function B:InitializeB()
    self.text = "B"
end

C = ZO_Object.MultiSubclass(A, B)

function C:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function C:Initialize()
    self:InitializeA()
    self:InitializeB()
end
]]--

function ZO_GenerateDataSourceMetaTableIndexFunction(template)
    return function(tbl, key)
        local value = template[key]
        if value == nil then
            local dataSource = rawget(tbl, "dataSource")
            if dataSource then
                value = dataSource[key]
            end
        end
        return value
    end
end

ZO_DataSourceObject = {}

function ZO_DataSourceObject:New(template)
    template = template or self

    local newObject = setmetatable({}, template.instanceMetaTable)

    local mt = getmetatable(newObject)
    mt.__index = ZO_GenerateDataSourceMetaTableIndexFunction(template)

    return newObject
end

function ZO_DataSourceObject:GetDataSource()
    return self.dataSource
end

function ZO_DataSourceObject:SetDataSource(dataSource)
    self.dataSource = dataSource
end

function ZO_DataSourceObject:Subclass()
    local newTemplate = setmetatable({}, { __index = self })
    newTemplate.instanceMetaTable = { __index = ZO_GenerateDataSourceMetaTableIndexFunction(newTemplate) }
    newTemplate.__parentClasses = { self }
    newTemplate.__isAbstractClass = false
    return newTemplate
end

---
-- ZO_InitializingObject is a new Object definition that more directly encodes
-- the practices most current ZO_Objects are actually using. in most cases, you
-- can directly replace a ZO_Object with a ZO_InitializingObject, and delete the
-- redundant :New() definition that most ZO_Object classes create.
--
ZO_InitializingObject = {}
zo_mixin(ZO_InitializingObject, ZO_Object)
ZO_InitializingObject.__index = ZO_InitializingObject

---
-- This is the external constructor for each object. should be called like so:
--     myObject = MyClass:New([arguments])
--
function ZO_InitializingObject:New(...)
    local newObject = setmetatable({}, self)
    newObject:Initialize(...)
    return newObject
end

---
-- Override this initialization function to define how your object should be constructed. example:
--     function MyClass:Initialize(argument1, argument2)
--         self.myField = argument1
--     end
-- You can still create an InitializingObject that doesn't have an Initialize
-- definition, it will just call this empty method instead.
function ZO_InitializingObject:Initialize()
    -- To be overridden
end

--
-- ZO_DeferredInitializingObject is a ZO_InitializingObject wrapper that standardizes the logic around deferring some of the initialization until later.
-- Use of this abstract class requires passing in a fragment and implementing OnDeferredInitialize
-- OnDeferredInitialize will be called when the fragment is showing before calling self:OnShowing()

ZO_DeferredInitializingObject = {}
zo_mixin(ZO_DeferredInitializingObject, ZO_InitializingObject)
ZO_DeferredInitializingObject.__index = ZO_DeferredInitializingObject

---
-- Override this initialization function to define how your object should be constructed. 
-- You must create a fragment, scene, or scene group and call this base Initialize function, passing the fragment, scene, or scene group. example:
--     function MyClass:Initialize(control, argument1, argument2)
--         ZO_DeferredInitializingObject:Initialize(self, ZO_FadeSceneFragment:New(control))
--         self.myField = argument1
--     end
function ZO_DeferredInitializingObject:Initialize(sceneStateObject)
    assert(sceneStateObject)
    self.sceneStateObject = sceneStateObject
    self.sceneStateObject:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
    if self.sceneStateObject:IsInstanceOf(ZO_Scene) then
        self.scene = sceneStateObject
    elseif self.sceneStateObject:IsInstanceOf(ZO_SceneFragment) then
        self.fragment = sceneStateObject
    elseif self.sceneStateObject:IsInstanceOf(ZO_SceneGroup) then
        self.sceneGroup = sceneStateObject
    end
end

function ZO_DeferredInitializingObject:OnStateChanged(_, newState)
    if newState == ZO_STATE.SHOWING then
        if not self.initialized then
            self.initialized = true
            self:OnDeferredInitialize()
        end
        self:OnShowing()
    elseif newState == ZO_STATE.SHOWN then
        self:OnShown()
    elseif newState == ZO_STATE.HIDING then
        self:OnHiding()
    elseif newState == ZO_STATE.HIDDEN then
        self:OnHidden()
    end
end

function ZO_DeferredInitializingObject:OnShowing()
    -- To be overridden
end

function ZO_DeferredInitializingObject:OnShown()
    -- To be overridden
end

function ZO_DeferredInitializingObject:OnHiding()
    -- To be overridden
end

function ZO_DeferredInitializingObject:OnHidden()
    -- To be overridden
end

function ZO_DeferredInitializingObject:GetScene()
    return self.scene
end

function ZO_DeferredInitializingObject:GetFragment()
    return self.fragment
end

function ZO_DeferredInitializingObject:GetSceneGroup()
    return self.sceneGroup
end

function ZO_DeferredInitializingObject:IsShowing()
    return self.sceneStateObject:IsShowing()
end

ZO_DeferredInitializingObject:MUST_IMPLEMENT("OnDeferredInitialize")
