--[[
    Hooking API (holding off on generalization until we see everything that needs to use it...
--]]

-- Install a handler that will be called before the original function and whose return value will decide if the original even needs to be called.
-- If the hook returns true it means that the hook handled the call entirely, and the original doesn't need calling.
-- ZO_PreHook can be called with or without an objectTable; if the argument is a string (the function name), it just uses _G
function ZO_PreHook(objectTable, existingFunctionName, hookFunction)
    if(type(objectTable) == "string") then
        hookFunction = existingFunctionName
        existingFunctionName = objectTable
        objectTable = _G
    end
     
    local existingFn = objectTable[existingFunctionName]
    if((existingFn ~= nil) and (type(existingFn) == "function"))
    then    
        local newFn =   function(...)
                            if(not hookFunction(...)) then
                                return existingFn(...)
                            end
                        end

        objectTable[existingFunctionName] = newFn
    end
end

function ZO_PreHookHandler(control, handlerName, hookFunction)
    local existingHandlerFunction = control:GetHandler(handlerName)
    local newHandlerFunction
    if(existingHandlerFunction) then
        newHandlerFunction = function(...)
            if(not hookFunction(...)) then
                return existingHandlerFunction(...)
            end
        end
    else
        newHandlerFunction = hookFunction
    end
    control:SetHandler(handlerName, newHandlerFunction)
end
