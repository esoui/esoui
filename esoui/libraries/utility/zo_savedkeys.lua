--[[

ZO_SavedKeys stores string and/or numeric keys using the SavedVariables system.
For example, the unique identifiers of Challenges that have already been seen by the player.

Usage:

    local existingChallengeIds = SAVED_KEYS:GetOrCreateSavedKeys("ChallengeIds")

    existingChallengeIds:RegisterCallback("AddedKeys", function(keys)
        for _, key in ipairs(key) do
            -- Do something with each added key.
        end
    end)

    existingChallengeIds:RegisterCallback("RemovedKeys", function(keys)
        for _, key in ipairs(key) do
            -- Do something with each removed key.
        end
    end)

    do
        -- Save one or more challenges that have been seen by the player.
        local challengeId = 12345
        existingChallengeIds:AddKeys(challengeId)
    end

    do
        -- Determine whether a challenge has been seen by the player.
        local challengeId = 12345
        local hasPlayerSeenChallenge = existingChallengeIds:HasKey(challengeId)
    end

    do
        -- Clear one or more seen challenges.
        local challengeId1 = 12345
        local challengeId2 = 54321
        existingChallengeIds:RemoveKeys(challengeId1, challengeId2)
    end

    do
        -- Clear all seen challenges.
        existingChallengeIds:RemoveAllKeys()
    end

  ]]

local SavedKeys = ZO_InitializingCallbackObject:Subclass()

function SavedKeys:__tostring()
    return string.format("SavedKeys(keyTypeName=%q, savedVarsFile=%q, version=%u)", self.keyTypeName or "(nil)", self.savedVarsFile or "(nil)", self.version or 0)
end

function SavedKeys:Initialize(keyTypeName, savedVarsFile, version, ...)
    ZO_InitializingCallbackObject.Initialize(self)

    self.keyTypeName = tostring(keyTypeName)
    if not self.keyTypeName then
        assert(false, "keyTypeName must be a valid string.")
        return
    end

    self.savedVarsFile = savedVarsFile or "ZO_Ingame_SavedVariables"
    self.version = tonumber(version) or 1

    if IsPlayerActivated() then
        -- The saved variables object can be created immediately.
        self:InitializeSavedVars()
    else
        -- Defer saved variables object creation until player activation.
        local eventHandlerDescriptor = string.format("SavedKeys_%s", self.keyTypeName)
        EVENT_MANAGER:RegisterForEvent(eventHandlerDescriptor, EVENT_PLAYER_ACTIVATED, function()
            EVENT_MANAGER:UnregisterForEvent(eventHandlerDescriptor, EVENT_PLAYER_ACTIVATED)
            self:InitializeSavedVars()
        end)
    end
end

function SavedKeys:InitializeSavedVars()
    if self.savedVars then
        return
    end

    local savedVarsKey = self.keyTypeName .. "Keys"
    local defaults = {}
    self.savedVars = ZO_SavedVars:NewAccountWide(self.savedVarsFile, self.version, savedVarsKey, defaults)

    if self:IsInitialized() then
        -- Defer the "Initialized" callback until the subsequent frame so
        -- that the calling code can first register for the callback.
        zo_callLater(function()
            self:FireCallbacks("Initialized")
        end, 1)
    end
end

-- Public Methods

-- Adds the specified keys to the saved keys table.
-- If one or more keys were new and added, fires the "AddedKeys" callback with a numerically indexed table of the added keys.
-- Returns a numerically indexed table of new keys that were added.
function SavedKeys:AddKeys(...)
    local keysTable = self:GetKeys()
    local keys = {...}
    if type(keys[1]) == "table" then
        -- The caller specified a table of keys instead of a series of key arguments.
        -- Note that a copy of the argument is created to prevent unwanted changes to the argument itself.
        keys = {unpack(keys[1])}
    end

    local keyIndex = #keys
    while keyIndex > 0 do
        local key = keys[keyIndex]
        if keysTable[key] then
            -- This key already exists.
            table.remove(keys, keyIndex)
        else
            -- Add this new key.
            keysTable[key] = true
        end
        keyIndex = keyIndex - 1
    end

    if #keys > 0 then
        self:FireCallbacks("AddedKeys", keys)
    end

    return keys
end

-- Returns the saved keys table.
-- Note that the saved keys table is a non-contiguous table containing each key mapped to the Boolean value true.
function SavedKeys:GetKeys()
    local keysTable = self:GetOrCreateSavedTableInternal("keys")
    return keysTable
end

-- Returns the string name for the type of keys saved in the saved keys table.
function SavedKeys:GetKeyTypeName()
    return self.keyTypeName
end

-- Returns the number of keys saved.
function SavedKeys:GetNumKeys()
    local keysTable = self:GetKeys()
    return keysTable and NonContiguousCount(keysTable) or 0
end

-- Returns the SavedVars file name.
function SavedKeys:GetSavedVarsFile()
    return self.savedVarsFile
end

-- Returns the numeric version number of the saved keys table.
function SavedKeys:GetVersion()
    return self.version
end

-- Returns two numerically indexed tables:
--   (1) The specified key(s) that exist in the saved keys table.
--   (2) The specified key(s) that do not exist in the saved keys table.
function SavedKeys:FindKeys(...)
    local keysTable = self:GetKeys()
    local keysMissing = {}
    local keysFound = {...}
    if type(keysFound[1]) == "table" then
        -- The caller specified a table of keys instead of a series of key arguments.
        -- Note that a copy of the argument is created to prevent unwanted changes to the argument itself.
        keysFound = {unpack(keysFound[1])}
    end

    local keyIndex = #keysFound
    while keyIndex > 0 do
        local key = keysFound[keyIndex]
        if keysTable[key] ~= true then
            -- The specified key does not exist in the saved keys table.
            table.remove(keysFound, keyIndex)
            table.insert(keysMissing, key)
        end
        keyIndex = keyIndex - 1
    end

    return keysFound, keysMissing
end

-- Returns true if the specified key exists.
function SavedKeys:HasKey(key)
    local keysTable = self:GetKeys()
    return keysTable[key] == true
end

-- Returns true if all of the specified key(s) exist.
function SavedKeys:HasKeys(...)
    local keysTable = self:GetKeys()
    local keys = {...}
    if type(keys[1]) == "table" then
        -- The caller specified a table of keys instead of a series of key arguments.
        keys = keys[1]
    end

    for _, key in ipairs(keys) do
        if keysTable[key] ~= true then
            return false
        end
    end

    return true
end

-- Returns true if one or more of the specified key(s) exist.
function SavedKeys:HasAnyKey(...)
    local keysTable = self:GetKeys()
    local keys = {...}
    if type(keys[1]) == "table" then
        -- The caller specified a table of keys instead of a series of key arguments.
        keys = keys[1]
    end

    for _, key in ipairs(keys) do
        if keysTable[key] == true then
            return true
        end
    end

    return false
end

-- Returns true if the saved keys table is initialized.
function SavedKeys:IsInitialized()
    return self.savedVars ~= nil
end

-- Removes all keys from the saved keys table.
-- If one or more keys were removed, fires the "RemovedKeys" callback with a numerically indexed table of the removed keys.
-- Returns a numerically indexed table of the removed keys.
function SavedKeys:RemoveAllKeys()
    local keysTable = self:GetKeys()
    local removedKeys = {}
    for key in pairs(keysTable) do
        table.insert(removedKeys, key)
    end

    ZO_ClearTable(keysTable)

    if #removedKeys > 0 then
        self:FireCallbacks("RemovedKeys", removedKeys)
    end

    return removedKeys
end

-- Removes the specified keys from the saved keys table.
-- If one or more existing keys were removed, fires the "RemovedKeys" callback with a numerically indexed table of the removed keys.
-- Returns a numerically indexed table of removed keys.
function SavedKeys:RemoveKeys(...)
    local keysTable = self:GetKeys()
    local keys = {...}
    if type(keys[1]) == "table" then
        -- The caller specified a table of keys instead of a series of key arguments.
        -- Note that a copy of the argument is created to prevent unwanted changes to the argument itself.
        keys = {unpack(keys[1])}
    end

    local keyIndex = #keys
    while keyIndex > 0 do
        local key = keys[keyIndex]
        if keysTable[key] then
            -- Remove this existing key.
            keysTable[key] = nil
        else
            -- This key does not exist.
            table.remove(keys, keyIndex)
        end
        keyIndex = keyIndex - 1
    end

    if #keys > 0 then
        self:FireCallbacks("RemovedKeys", keys)
    end

    return keys
end

-- Private Methods

function SavedKeys:GetSavedVarInternal(savedVarKey)
    local savedVars = self.savedVars
    if not savedVars then
        assert(false, string.format("SavedKeys: %q key table is not ready yet.", self.keyTypeName))
    end
    return savedVars[savedVarKey]
end

function SavedKeys:SetSavedVarInternal(savedVarKey, value)
    local savedVars = self.savedVars
    if not savedVars then
        assert(false, string.format("SavedKeys: %q key table is not ready yet.", self.keyTypeName))
    end
    savedVars[savedVarKey] = value
    return true
end

function SavedKeys:GetOrCreateSavedTableInternal(savedVarKey)
    local savedTable = self:GetSavedVarInternal(savedVarKey)
    if savedTable == nil then
        savedTable = {}
        if not self:SetSavedVarInternal(savedVarKey, savedTable) then
            return nil
        end
    end
    return savedTable
end

-- SAVED_KEYS manages the lifecycle of all SavedKeys instances.

local SavedKeysManager = ZO_InitializingObject:Subclass()

function SavedKeysManager:Initialize()
    self.savedKeysByKeyTypeName = {}
end

-- Public Methods

-- Returns a non-contiguous table containing each key type name mapped to its associated SavedKeys instance.
function SavedKeysManager:GetAllSavedKeys()
    return self.savedKeysByKeyTypeName
end

-- Gets or creates the SavedKeys instance associated with the specified key type name.
function SavedKeysManager:GetOrCreateSavedKeys(keyTypeName, savedVarsFile, version)
    local savedKeys = self.savedKeysByKeyTypeName[keyTypeName]
    if savedKeys then
        return savedKeys
    end

    savedKeys = SavedKeys:New(keyTypeName, savedVarsFile, version)
    self.savedKeysByKeyTypeName[keyTypeName] = savedKeys
    return savedKeys
end

SAVED_KEYS = SavedKeysManager:New()