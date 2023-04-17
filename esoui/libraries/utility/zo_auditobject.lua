-- NOTE: This audit functionality can be circumvented and is not intended for enforcing security or access control.

local AFTER_UPDATE_CALLBACK_SENTINEL_KEY = {}
local BEFORE_UPDATE_CALLBACK_SENTINEL_KEY = {}
local ORIGINAL_NEWINDEX_SENTINEL_KEY = {}
local PROCESSING_UPDATE_SENTINEL_KEY = {}

-- Forward declaration for self-reference.
function NewIndexHandler(object, key, value)
    -- Check and set the processing flag.
    -- Order matters:
    local mt = getmetatable(object)
    if not internalassert(not mt[PROCESSING_UPDATE_SENTINEL_KEY], "An update callback has caused a recursive update: Use 'rawget' and 'rawset' to access and modify table values in update callbacks.") then
        -- Terminate early to avoid infinite recursion caused by one or more update callbacks.
        return
    end
    mt[PROCESSING_UPDATE_SENTINEL_KEY] = true

    -- Call each beforeUpdateCallback and, if requested, terminate early to cancel the update operation.
    local beforeUpdateCallbackList = mt[BEFORE_UPDATE_CALLBACK_SENTINEL_KEY]
    if beforeUpdateCallbackList then
        for index, beforeUpdateCallback in ipairs(beforeUpdateCallbackList) do
            local cancelUpdate, newValue = beforeUpdateCallback(object, key, value)
            if cancelUpdate then
                -- Callback requested to cancel the update operation.
                -- Clear the processing flag.
                mt[PROCESSING_UPDATE_SENTINEL_KEY] = nil
                return
            elseif newValue ~= nil then
                -- Callback requested to override the value.
                value = newValue
            end
        end
    end

    local originalNewIndexHandler = mt[ORIGINAL_NEWINDEX_SENTINEL_KEY]
    if originalNewIndexHandler then
        -- Forward the update operation to the metatable's original __newindex handler.
        originalNewIndexHandler(object, key, value)
    else
        -- Manually process the update operation.
        rawset(object, key, value)
    end

    -- Call each afterUpdateCallback.
    local afterUpdateCallbackList = mt[AFTER_UPDATE_CALLBACK_SENTINEL_KEY]
    if afterUpdateCallbackList then
        for index, afterUpdateCallback in ipairs(afterUpdateCallbackList) do
            afterUpdateCallback(object, key, value)
        end
    end

    -- Clear the processing flag.
    mt[PROCESSING_UPDATE_SENTINEL_KEY] = nil
end

-- Sample Usage for conditionally redirecting or preventing inserts/updates to a table:
--  local myList = {}
--
--  local function OnBeforeUpdate(object, key, value)
--      if key == "Hello" then
--          local CANCEL_UPDATE = true
--          return CANCEL_UPDATE
--      elseif key == "Fizz" then
--          local CONTINUE_UPDATE = false
--          local NEW_VALUE = "Soda"
--          return CONTINUE_UPDATE, NEW_VALUE
--      end
--  end
--
--  ZO_AuditObject(myList, OnBeforeUpdate)
--  myList["Hello"] = "World"
--  myList["Fizz"] = "Buzz"
--  d(myList)
--
-- Sample Output:
--  .(string): Fizz = Soda

-- Sample Usage for receiving notification of inserts/updates to a table:
--  local myList = {}
--
--  local function OnAfterUpdate(object, key, value)
--      df("myList updated: key=%s value=%s", tostring(key), tostring(value))
--  end
--
--  local NO_BEFORE_UPDATE_CALLBACK = nil
--  ZO_AuditObject(myList, NO_BEFORE_UPDATE_CALLBACK, OnAfterUpdate)
--  myList["Hello"] = "World"
--
-- Sample Output:
--  Update: key=Hello value=World

-- NOTE: This audit functionality can be circumvented and is not intended for enforcing security or access control.
function ZO_AuditObject(object, beforeUpdateCallback, afterUpdateCallback)
    if not internalassert(type(object) == "table", "object must be a table.") then
        return
    end

    local registerObjectMetatable = false
    local mt = getmetatable(object)
    if not mt then
        -- Create a new metatable for this object.
        mt = {}
        registerObjectMetatable = true
    end

    if mt[ORIGINAL_NEWINDEX_SENTINEL_KEY] == nil then
        -- Initial auditing setup for this object.
        -- Order matters:
        mt[ORIGINAL_NEWINDEX_SENTINEL_KEY] = mt.__newindex
        mt.__newindex = NewIndexHandler
    end

    if beforeUpdateCallback then
        if not internalassert(type(beforeUpdateCallback) == "function", "beforeUpdateCallback must be a function or nil.") then
            return
        end

        -- Create or update the beforeUpdateCallbackList for this object.
        -- Order matters:
        local beforeUpdateCallbackList = mt[BEFORE_UPDATE_CALLBACK_SENTINEL_KEY]
        if not beforeUpdateCallbackList then
            beforeUpdateCallbackList = {}
            mt[BEFORE_UPDATE_CALLBACK_SENTINEL_KEY] = beforeUpdateCallbackList
        end
        table.insert(beforeUpdateCallbackList, beforeUpdateCallback)
    end

    if afterUpdateCallback then
        if not internalassert(type(afterUpdateCallback) == "function", "afterUpdateCallback must be a function or nil.") then
            return
        end

        -- Create or update the afterUpdateCallbackList for this object.
        -- Order matters:
        local afterUpdateCallbackList = mt[AFTER_UPDATE_CALLBACK_SENTINEL_KEY]
        if not afterUpdateCallbackList then
            afterUpdateCallbackList = {}
            mt[AFTER_UPDATE_CALLBACK_SENTINEL_KEY] = afterUpdateCallbackList
        end
        table.insert(afterUpdateCallbackList, afterUpdateCallback)
    end

    if registerObjectMetatable then
        -- Apply the new metatable to this object.
        setmetatable(object, mt)
    end
end