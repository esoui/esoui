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
    return newClass
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
