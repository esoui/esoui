--[[
This file and its accompanying XML file exist for when we decide to rename/refactor 
a system and want ensure backward compatibility for addons.  Just alias the old functions
and inherit any controls you change in a newly commented section. This file is for any aliases we want to exist on both PC and Console
--]]

-- Adds aliases to source object for the specified methods of target object.
local function AddMethodAliases(sourceObject, targetObject, methodNameList)
    for _, methodName in ipairs(methodNameList) do
        internalassert(sourceObject[methodName] == nil, string.format("Method '%s' of sourceObject already exists.", methodName))
        internalassert(type(targetObject[methodName]) == "function", string.format("Method '%s' of targetObject does not exist.", methodName))

        sourceObject[methodName] = function(originalSelf, ...)
            return targetObject[methodName](targetObject, ...)
        end
    end
end