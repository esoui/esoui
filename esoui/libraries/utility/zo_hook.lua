--[[
    Hooking API (holding off on generalization until we see everything that needs to use it...
--]]

-- Install a handler that will be called before the original function and whose return value will decide if the original even needs to be called.
-- If the hook returns true it means that the hook handled the call entirely, and the original doesn't need calling.
-- ZO_PreHook can be called with or without an objectTable; if the argument is a string (the function name), it just uses _G
function ZO_PreHook(objectTable, existingFunctionName, hookFunction)
    if type(objectTable) == "string" then
        hookFunction = existingFunctionName
        existingFunctionName = objectTable
        objectTable = _G
    end
     
    local existingFn = objectTable[existingFunctionName]
    if existingFn ~= nil and type(existingFn) == "function" then    
        local newFn =   function(...)
                            if not hookFunction(...) then
                                return existingFn(...)
                            end
                        end

        objectTable[existingFunctionName] = newFn
    end
    return existingFn
end

function ZO_PostHook(objectTable, existingFunctionName, hookFunction)
    if type(objectTable) == "string" then
        hookFunction = existingFunctionName
        existingFunctionName = objectTable
        objectTable = _G
    end
     
    local existingFn = objectTable[existingFunctionName]
    if existingFn ~= nil and type(existingFn) == "function" then    
        local newFn =   function(...)
                            local returns = {existingFn(...)}
                            hookFunction(...)
                            return unpack(returns)
                        end

        objectTable[existingFunctionName] = newFn
    end
    return existingFn
end

function ZO_PreHookHandler(control, handlerName, hookFunction)
    local existingHandlerFunction = control:GetHandler(handlerName)
    local newHandlerFunction
    if existingHandlerFunction then
        newHandlerFunction = function(...)
            if not hookFunction(...) then
                return existingHandlerFunction(...)
            end
        end
    else
        newHandlerFunction = hookFunction
    end
    control:SetHandler(handlerName, newHandlerFunction)
    return existingHandlerFunction
end

function ZO_PostHookHandler(control, handlerName, hookFunction)
    local existingHandlerFunction = control:GetHandler(handlerName)
    local newHandlerFunction
    if existingHandlerFunction then
        newHandlerFunction = function(...)
            local returns = {existingHandlerFunction(...)}
            hookFunction(...)
            return unpack(returns)
        end
    else
        newHandlerFunction = hookFunction
    end
    control:SetHandler(handlerName, newHandlerFunction)
    return existingHandlerFunction
end

--where ... are the handler args after self
-- ZO_PropagateHandler(self:GetParent(), "OnMouseUp", button, upInside)
function ZO_PropagateHandler(propagateTo, handlerName, ...)
    if propagateTo then
        local handler = propagateTo:GetHandler(handlerName)
        if handler then
            handler(propagateTo, ...)
        end
    end
end

-- For when you want to propagate to the control's parent without breaking self out of the args
-- ZO_PropagateHandlerToParent("OnMouseUp", ...)
function ZO_PropagateHandlerToParent(handlerName, propagateFrom, ...)
    ZO_PropagateHandler(propagateFrom:GetParent(), handlerName, ...)
end

-- For when you want to propagate without breaking self out of the args
-- ZO_PropagateHandlerFromControl(self:GetParent():GetParent(), "OnMouseUp", ...)
function ZO_PropagateHandlerFromControl(propagateTo, handlerName, propagateFrom, ...)
    ZO_PropagateHandler(propagateTo, handlerName, ...)
end