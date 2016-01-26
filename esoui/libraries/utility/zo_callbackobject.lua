ZO_CallbackObject = ZO_Object:Subclass()

function ZO_CallbackObject:New()
    local newObject = ZO_Object.New(self)

    newObject.fireCallbackDepth = 0
    newObject.dirtyEvents = {}

    return newObject
end

local CALLBACK_INDEX = 1
local ARGUMENT_INDEX = 2
local DELETED_INDEX = 3

--Registers a callback to be executed when eventName is triggered. 
--You may optionally specify an argument to be passed to the callback.
function ZO_CallbackObject:RegisterCallback(eventName, callback, arg)    
    if(not eventName or not callback) then
        return
    end
    
    --if this is the first callback then create the registry
    if(not self.callbackRegistry) then
        self.callbackRegistry = {}
    end
    
    --create a list to hold callbacks of this type if it doesn't exist
    local registry = self.callbackRegistry[eventName]
    if(not registry) then
        registry = {}
        self.callbackRegistry[eventName] = registry
    end
    
    --make sure this callback wasn't already registered
    for _, registration in ipairs(registry) do
        if registration[CALLBACK_INDEX] == callback and registration[ARGUMENT_INDEX] == arg then
            return
        end
    end

    --store the callback with an optional argument
    --note: the order of the arguments to the table constructor must match the order of the *_INDEX locals above
    table.insert(registry, {callback, arg, false})
end

function ZO_CallbackObject:UnregisterCallback(eventName, callback)    
    if(not self.callbackRegistry) then
        return
    end
    
    local registry = self.callbackRegistry[eventName]
    
    if(registry) then
        --find the entry
        for i = 1,#registry do
            local callbackInfo = registry[i]
            if(callbackInfo[CALLBACK_INDEX] == callback) then
                callbackInfo[DELETED_INDEX] = true
                self:Clean(eventName)
                return
            end
        end
    end    
end

function ZO_CallbackObject:UnregisterAllCallbacks(eventName)
    if(not self.callbackRegistry) then
        return
    end
    
    local registry = self.callbackRegistry[eventName]
    
    if(registry) then
        --find the entry
        for i = 1,#registry do
            local callbackInfo = registry[i]
            callbackInfo[DELETED_INDEX] = true
        end

        self:Clean(eventName)
    end    
end

--Executes all callbacks registered on this object with this event name
--Accepts the event name, and a list of arguments to be passed to the callbacks
--The return value is from the callbacks, the most recently registered non-nil non-false callback return value is returned
function ZO_CallbackObject:FireCallbacks(eventName, ...)
    local result = nil
    
    if(not self.callbackRegistry or not eventName) then
        return result
    end
    
    local registry = self.callbackRegistry[eventName]
    if(registry) then    
        self.fireCallbackDepth = self.fireCallbackDepth + 1

        local callbackInfoIndex = 1
        while callbackInfoIndex <= #registry do
            --pass the arg as the first parameter if it exists
            local callbackInfo = registry[callbackInfoIndex]
            local argument = callbackInfo[ARGUMENT_INDEX]
            local callback = callbackInfo[CALLBACK_INDEX]
            local deleted = callbackInfo[DELETED_INDEX]
            
            if(not deleted) then
                if(argument) then
                    result = callback(argument, ...) or result
                else
                    result = callback(...) or result
                end
            end

            callbackInfoIndex = callbackInfoIndex + 1
        end

        self.fireCallbackDepth = self.fireCallbackDepth - 1

        self:Clean()
    end
    
    return result
end

function ZO_CallbackObject:Clean(eventName)
    if(eventName) then
        self.dirtyEvents[#self.dirtyEvents + 1] = eventName
    end

    if(self.fireCallbackDepth == 0) then
        while #self.dirtyEvents > 0 do
            local eventName = self.dirtyEvents[#self.dirtyEvents]
            local registry = self.callbackRegistry[eventName]
            if(registry) then    
                local callbackInfoIndex = 1
                while callbackInfoIndex <= #registry do
                    local callbackTable = registry[callbackInfoIndex]
                    if(callbackTable[DELETED_INDEX]) then
                        table.remove(registry, callbackInfoIndex)
                    else
                        callbackInfoIndex = callbackInfoIndex + 1
                    end
                end
                if(#registry == 0) then
                    self.callbackRegistry[eventName] = nil
                end
            end
            self.dirtyEvents[#self.dirtyEvents] = nil
        end
    end
end
