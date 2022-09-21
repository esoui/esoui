local ZO_CallbackObjectMixin = {}

local CALLBACK_INDEX = 1
local ARGUMENT_INDEX = 2
local PRIORITY_INDEX = 3
local DELETED_INDEX = 4

do
    local function SortRegistry(left, right)
        local leftPriority = left[PRIORITY_INDEX]
        local rightPriority = right[PRIORITY_INDEX]
        if leftPriority and rightPriority then
            return leftPriority < rightPriority
        elseif leftPriority then
            return true
        else
            return false
        end
    end

    --Registers a callback to be executed when eventName is triggered.
    --You may optionally specify an argument to be passed to the callback.
    function ZO_CallbackObjectMixin:RegisterCallback(eventName, callback, arg, priority)
        if not eventName or not callback then
            return
        end

        --if this is the first callback then create the registry
        if not self.callbackRegistry then
            self.callbackRegistry = {}
        end

        --create a list to hold callbacks of this type if it doesn't exist
        local registry = self.callbackRegistry[eventName]
        if not registry then
            registry = {}
            self.callbackRegistry[eventName] = registry
        end

        --make sure this callback wasn't already registered
        for _, registration in ipairs(registry) do
            if registration[CALLBACK_INDEX] == callback and registration[ARGUMENT_INDEX] == arg then
                -- If the callback is already registered, make sure it hasn't been flagged for delete
                -- so it won't be unregistered in self:Clean later
                -- This can happen if you attempt to unregister and register for a callback
                -- during a callback, since that will delay the clean until after we have tried to re-register
                registration[DELETED_INDEX] = false
                return
            end
        end

        --store the callback with an optional argument
        --note: the order of the arguments to the table constructor must match the order of the *_INDEX locals above
        table.insert(registry, { callback, arg, priority, false })

        if priority then
            -- If this registration has a priorty, we need to determine where it goes in the order
            -- If it does not, we can assume any with priorities were already sorted to the front, and this can stay tacked on the end with the rest of the unprioritized
            table.sort(registry, SortRegistry)
        end
    end
end

function ZO_CallbackObjectMixin:UnregisterCallback(eventName, callback, arg)
    if not self.callbackRegistry then
        return
    end

    local registry = self.callbackRegistry[eventName]

    if registry then
        --find the entry
        for i = 1,#registry do
            local callbackInfo = registry[i]
            if callbackInfo[CALLBACK_INDEX] == callback and callbackInfo[ARGUMENT_INDEX] == arg then
                callbackInfo[DELETED_INDEX] = true
                self:Clean(eventName)
                return
            end
        end
    end
end

function ZO_CallbackObjectMixin:UnregisterAllCallbacks(eventName)
    if not self.callbackRegistry then
        return
    end

    local registry = self.callbackRegistry[eventName]

    if registry then
        --find the entry
        for i = 1, #registry do
            local callbackInfo = registry[i]
            callbackInfo[DELETED_INDEX] = true
        end

        self:Clean(eventName)
    end
end

function ZO_CallbackObjectMixin:SetHandleOnce(handleOnce)
    self.handleOnce = handleOnce
end

--Executes all callbacks registered on this object with this event name
--Accepts the event name, and a list of arguments to be passed to the callbacks
--The return value is from the callbacks, the most recently registered non-nil non-false callback return value is returned
function ZO_CallbackObjectMixin:FireCallbacks(eventName, ...)
    local result = nil

    if not self.callbackRegistry or not eventName then
        return result
    end

    local registry = self.callbackRegistry[eventName]
    if registry then
        self.fireCallbackDepth = self:GetFireCallbackDepth() + 1

        local callbackInfoIndex = 1
        while callbackInfoIndex <= #registry do
            --pass the arg as the first parameter if it exists
            local callbackInfo = registry[callbackInfoIndex]
            local argument = callbackInfo[ARGUMENT_INDEX]
            local callback = callbackInfo[CALLBACK_INDEX]
            local deleted = callbackInfo[DELETED_INDEX]
            
            if not deleted then
                if argument then
                    result = callback(argument, ...) or result
                else
                    result = callback(...) or result
                end

                if result and self.handleOnce then
                    break
                end
            end

            callbackInfoIndex = callbackInfoIndex + 1
        end

        self.fireCallbackDepth = self:GetFireCallbackDepth() - 1

        self:Clean()
    end
    
    return result
end

function ZO_CallbackObjectMixin:Clean(eventName)
    local dirtyEvents = self:GetDirtyEvents()
    if eventName then
        dirtyEvents[#dirtyEvents + 1] = eventName
    end

    if self:GetFireCallbackDepth() == 0 then
        while #dirtyEvents > 0 do
            local eventName = dirtyEvents[#dirtyEvents]
            local registry = self.callbackRegistry[eventName]
            if registry then
                local callbackInfoIndex = 1
                while callbackInfoIndex <= #registry do
                    local callbackTable = registry[callbackInfoIndex]
                    if callbackTable[DELETED_INDEX] then
                        table.remove(registry, callbackInfoIndex)
                    else
                        callbackInfoIndex = callbackInfoIndex + 1
                    end
                end
                if #registry == 0 then
                    self.callbackRegistry[eventName] = nil
                end
            end
            dirtyEvents[#dirtyEvents] = nil
        end
    end
end

function ZO_CallbackObjectMixin:ClearCallbackRegistry()
    if self.callbackRegistry then
        for eventName, _ in pairs(self.callbackRegistry) do
            self:UnregisterAllCallbacks(eventName)
        end
    end
end

function ZO_CallbackObjectMixin:GetFireCallbackDepth()
    return self.fireCallbackDepth or 0
end

function ZO_CallbackObjectMixin:GetDirtyEvents()
    if not self.dirtyEvents then
        self.dirtyEvents = {}
    end
    return self.dirtyEvents
end

ZO_CallbackObject = {}
zo_mixin(ZO_CallbackObject, ZO_Object)
zo_mixin(ZO_CallbackObject, ZO_CallbackObjectMixin)
ZO_CallbackObject.__index = ZO_CallbackObject

ZO_InitializingCallbackObject = {}
zo_mixin(ZO_InitializingCallbackObject, ZO_InitializingObject)
zo_mixin(ZO_InitializingCallbackObject, ZO_CallbackObjectMixin)
ZO_InitializingCallbackObject.__index = ZO_InitializingCallbackObject
