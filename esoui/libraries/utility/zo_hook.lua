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
        -- TODO: Determine whether handlers of any namespace should be called;
        --       new Control methods - GetNumHandlers and GetHandlerByIndex - would be required to do so.
        local handler = propagateTo:GetHandler(handlerName)
        if handler then
            handler(propagateTo, ...)
            return true
        end
    end
    return false
end

-- Propagates a call to the specified handler name from a control to each ancestor control
-- that defines a corresponding handler function until and excluding the owning window.
-- ZO_PropagateHandlerToAllAncestors("OnMouseUp", ...)
function ZO_PropagateHandlerToAllAncestors(handlerName, propagateFromControl, ...)
    local owningWindow = propagateFromControl:GetOwningWindow()
    local ancestorControl = propagateFromControl:GetParent()
    -- No semaphore mechanism is currently required to suppress reentrant calls when
    -- ancestor controls also inherit ZO_PropagateMouseOverBehaviorToAllAncestors
    -- because, at present, ZO_PropagateHandler only propagates events to handlers
    -- that have no namespace. A gating mechanism would be required should this
    -- paradigm ever change.
    while ancestorControl and ancestorControl ~= owningWindow do
        ZO_PropagateHandler(ancestorControl, handlerName, ...)
        ancestorControl = ancestorControl:GetParent()
    end
end

-- Propagates a call to the specified handler name from a control to the nearest ancestor control
-- that defines a corresponding handler function until and excluding the owning window.
-- ZO_PropagateHandlerToNearestAncestor("OnMouseUp", ...)
function ZO_PropagateHandlerToNearestAncestor(handlerName, propagateFromControl, ...)
    local owningWindow = propagateFromControl:GetOwningWindow()
    local ancestorControl = propagateFromControl:GetParent()
    while ancestorControl and ancestorControl ~= owningWindow and not ZO_PropagateHandler(ancestorControl, handlerName, ...) do
        ancestorControl = ancestorControl:GetParent()
    end
end

-- For when you want to propagate to the control's parent without breaking self out of the args
-- ZO_PropagateHandlerToParent("OnMouseUp", ...)
function ZO_PropagateHandlerToParent(handlerName, propagateFromControl, ...)
    ZO_PropagateHandler(propagateFromControl:GetParent(), handlerName, ...)
end

-- For when you want to propagate without breaking self out of the args
-- ZO_PropagateHandlerFromControl(self:GetParent():GetParent(), "OnMouseUp", ...)
function ZO_PropagateHandlerFromControl(propagateToControl, handlerName, propagateFromControl, ...)
    ZO_PropagateHandler(propagateToControl, handlerName, ...)
end

--[[
  Updates the metatable of the specified control to forward calls to any umimplemented
  methods to any of the specified control(s) that have a corresponding implementation.

  Invocation of a relayed method will return the return value of each target objects'
  implementation in the order that the target objects were specified.

  For example:

  -- Forward unimplemented method calls to the container control's child label control.
  local containerControl = self.control:GetNamedChild("PlayerContainer")
  local labelControl = containerControl:GetNamedChild("Name")
  ZO_ForwardUnimplementedMethodsForControl(containerControl, labelControl)

  -- Call label control-specific methods of the child label control via its parent container control.
  containerControl:SetFont("ZoFontGameBold")
  containerControl:SetText(playerName)
]]
do
    local UNIMPLEMENTED_METHOD_SENTINEL = {}

    local function GetOrCreateMethodRelayOrUnimplementedSentinel(key, targetObjects)
        -- Identify any target objects with a corresponding method implementation for this key.
        local objectsWithImplementations = {}
        for _, targetObject in ipairs(targetObjects) do
            local targetMethod = targetObject[key]
            if targetMethod and type(targetMethod) == "function" then
                table.insert(objectsWithImplementations, targetObject)
            end
        end

        if not next(objectsWithImplementations) then
            -- No target objects have a corresponding method implementation for this key.
            return UNIMPLEMENTED_METHOD_SENTINEL
        end

        -- Create a relay method that will forward the invocation of this method to
        -- the supporting target objects and return the first non-nil return value.
        return function(...)
            local returnValues = {}
            for index, targetObject in ipairs(objectsWithImplementations) do
                -- Relay the call to the target object with a reference to the
                -- target object substituted in place of the 'self' parameter.
                local targetMethod = targetObject[key]
                returnValues[index] = targetMethod(targetObject, select(2, ...))
            end
            return unpack(returnValues)
        end
    end

    function ZO_ForwardUnimplementedMethodsForControl(sourceControl, ...)
        -- Wrap the source control's existing metatable indexer method so that keys not found
        -- in the source control are subsequently searched for within the target object(s).
        -- A relay method is created, cached, and returned for any target objects that have a
        -- method implementation for a given key; if no method implementations are found,
        -- a sentinel value is cached to prevent unnecessary lookups for that key.
        local targetObjects = {...}
        local relayMethods = {}
        local metaTable = getmetatable(sourceControl)
        local originalIndex = rawget(metaTable, "__index")
        local indexWrapper = function(tbl, key)
            if originalIndex then
                local value = originalIndex[key]
                if value ~= nil then
                    -- Return the corresponding value for existing keys.
                    return value
                end
            end

            local relayMethod = relayMethods[key]
            if relayMethod == nil then
                -- Create either a relay method that forwards this invocation to
                -- supporting target objects or a sentinel value that signals that
                -- no target objects have a corresponding implementation.
                relayMethod = GetOrCreateMethodRelayOrUnimplementedSentinel(key, targetObjects)
                relayMethods[key] = relayMethod
            end

            if relayMethod == UNIMPLEMENTED_METHOD_SENTINEL then
                -- An attempt was already made to index this key but no
                -- implementation was found. Suppress further attempts.
                return nil
            end

            return relayMethod
        end
        rawset(metaTable, "__index", indexWrapper)
    end
end