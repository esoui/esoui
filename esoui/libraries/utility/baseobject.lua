ZO_Object = {}

function ZO_Object:New(template)
    --
    -- The new instance of the object needs an index table.
    -- This next statement prefers to use "template" as the
    -- index table, but will fall back to self.
    -- Without the proper index table, your new object will
    -- not have the proper behavior.
    --
    template = template or self
    
    --
    -- This call to setmetatable does 3 things:
    -- 1. Makes a new table.
    -- 2. Sets its metatable to the "index" table
    -- 3. Returns that table.
    --    
    local newObject = setmetatable ({}, template)
    
    --
    -- Obtain the metatable of the newly instantiated table.
    -- Make sure that if the user attempts to access newObject[key]
    -- and newObject[key] is nil, that it will actually fall
    -- back to looking up template[key]...and so on, because template
    -- should also have a metatable with the correct __index metamethod.
    --
    local mt = getmetatable (newObject)
    mt.__index = template
    
    return newObject
end

function ZO_Object:Subclass()
    --
    -- This is just a convenience function/semantic extension
    -- so that objects which need to inherit from a base object
    -- use a clearer function name to describe what they are doing.
    --
    return setmetatable({}, {__index = self})
end

function ZO_Object.MultiSubclass(...)
    local parentClasses = {...}
    return setmetatable({}, 
    {
        __index = function(table, key)
            for _, parentClassTable in ipairs(parentClasses) do
                local value = parentClassTable[key]
                if value ~= nil then
                    return value
                end
            end
        end
    })
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
    local newTemplate = setmetatable({}, {__index = self})
    newTemplate.instanceMetaTable = {__index = ZO_GenerateDataSourceMetaTableIndexFunction(newTemplate) }
    return newTemplate
end