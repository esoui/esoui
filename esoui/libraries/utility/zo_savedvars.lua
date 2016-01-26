ZO_SavedVars = {}
local WILD_CARD_KEY = '*'

local GetNewSavedVars

local currentPlayerName
local currentDisplayName

--[[ Creates an interface around raw saved variable access
    Usage:
    local sv = ZO_SavedVars:New(savedVariableTable, version, [, namespace], defaults [, profile])

    *savedVariableTable - The string name of the saved variable table
    *version            - The current version. If the saved data is a lower version it is destroyed and replaced with the defaults
    *namespace          - An optional string namespace to separate other variables using the same table
    *defaults           - A table describing the default saved variables, see the example below
    *profile            - An optional string to describe the profile, or "Default"

    The defaults table will be used when accessing a key that doesn't exist or hasn't been set yet. There is a special wild card key
    that can be used to make all sibling keys inherit the defaults specified by the wild card. The wild card value can be either a value or a table.

    Example:

    local defaults = {
        firstRun = true

        containers = {
            ["*"] = { --these are defaults all containers inherit
                width = 20,
                height = 50,
            }
        }
    }

    Note: SavedVars must be created in the EVENT_ADD_ON_LOADED function event in order for the settings file to properly save. 
    local sv = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "ExampleNamespace", defaults)

    if sv.firstRun then
        --initialize for first run
        local primaryContainerSettings = sv.container[1] --automatically generates a table based off the wild card key
        local container = self:GetPrimaryContainer()
        container:SetDimensions(primaryContainerSettings.width, primaryContainerSettings.height)
        sv.firstRun = false
    end

    Note: ZO_SavedVars:NewAccountWide provides the same interface as ZO_SavedVars:New, but is used to save account-wide saved vars.
--]]

function ZO_SavedVars:New(savedVariableTable, version, namespace, defaults, profile, displayName, characterName)
    displayName = displayName or GetDisplayName()
    characterName = characterName or GetUnitName("player")
    return GetNewSavedVars(savedVariableTable, version, namespace, defaults, profile, displayName, characterName)
end

function ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
    displayName = displayName or GetDisplayName()
    return GetNewSavedVars(savedVariableTable, version, namespace, defaults, profile, displayName, "$AccountWide")
end

local CreateExposedInterface

function GetNewSavedVars(savedVariableTable, version, namespace, defaults, profile, displayName, characterName)
    if type(savedVariableTable) ~= "table" then
        if _G[savedVariableTable] == nil then
            _G[savedVariableTable] = {}
        end
        savedVariableTable = _G[savedVariableTable]
    end

    if type(savedVariableTable) ~= "table" then
        error("Can only apply saved variables to a table")
    end

    --namespace is an optional argument
    if defaults == nil and type(namespace) == "table" then
        profile = defaults
        defaults = namespace
        namespace = nil
    end
    profile = profile or "Default"
    if type(profile) ~= "string" then
        error("Profile must be a string or nil")
    end

    return CreateExposedInterface(savedVariableTable, version, namespace, defaults, profile, displayName, characterName)
end

local CopyDefaults

local function InitializeWildCardFromDefaults(sv, defaults)
    --Make sure that all existing tables have the appropriate defaults
    --It's possible for a table to exist in the sv table (that was created in response to a wild card table), but only certain values have been set
    --It needs to inherit the rest of the values from the default table
    for savedVarKey, savedVarValue in pairs(sv) do
        if type(savedVarValue) == "table" then
            if not rawget(defaults, savedVarValue) then
                CopyDefaults(savedVarValue, defaults)
            end
        end
    end

    setmetatable(sv, {
        --Indexing this will copy the defaults, assign it to the previously missing key and return it
        --It's almost like it was always there!
        __index = function(t, k)
            if k ~= nil then
                local newValue = CopyDefaults({}, defaults)
                rawset(t, k, newValue)
                return newValue
            end
        end,
    })
end

local function CopyPotentialTable(sv, key, defaults)
    if not rawget(sv, key) then 
        --SVs have nothing, copy and create a new entry
        rawset(sv, key, CopyDefaults({}, defaults))
    elseif type(sv[key]) == "table" then
        --SV has an entry, and it's a table, set it up for defaults
        CopyDefaults(sv[key], defaults)
    end
    --The SV isn't a table, nothing to do
end

function CopyDefaults(sv, defaults)
    for defaultKey, defaultValue in pairs(defaults) do
        if defaultKey == WILD_CARD_KEY then
            if type(defaultValue) == "table" then
                --Wild card value is a subtable, initialize the subtable
                InitializeWildCardFromDefaults(sv, defaultValue)
            else
                --Wild card value is (probably) a primitive, just return a copy when the wild card is indexed
                setmetatable(sv, { __index = function(t, k)
                    if k ~= nil then
                        return defaultValue
                    end
                end,})
            end
        elseif type(defaultValue) == "table" then
            CopyPotentialTable(sv, defaultKey, defaultValue)
        elseif rawget(sv, defaultKey) == nil then
            rawset(sv, defaultKey, defaultValue)
        end
    end

    return sv
end

local function CreatePath(t, ...)
    local current = t
    local container
    local containerKey
    for i=1, select("#", ...) do
        local key = select(i, ...)
        if key ~= nil then
            if not current[key] then
                current[key] = {}
            end
            container = current
            containerKey = key
            current = current[key]
        end
    end

    return current, container, containerKey
end

local function InitializeRawTable(rawSavedTable, profile, namespace, displayName, playerName)
    return CreatePath(rawSavedTable, profile, displayName, playerName, namespace)
end

local function ExposeMethods(interface, namespace, rawSavedTable, defaults, profile, cachedInterfaces)
    --Gets an interface to the same saved variable table, but for a different character and/or world
    interface.GetInterfaceForCharacter = function(self, displayName, playerName)
        if currentDisplayName == displayName and currentPlayerName == playerName then
            return self
        end

        if not cachedInterfaces[displayName] then
            cachedInterfaces[displayName] = {}
        end
        if not cachedInterfaces[displayName][playerName] then
            cachedInterfaces[displayName][playerName] = CreateExposedInterface(rawSavedTable, self.version, namespace, defaults, profile, displayName, playerName, cachedInterfaces)
        end

        return cachedInterfaces[displayName][playerName]
    end
end

function CreateExposedInterface(rawSavedTable, version, namespace, defaults, profile, displayName, playerName, cachedInterfaces)
    local current, container, containerKey = InitializeRawTable(rawSavedTable, profile, namespace, displayName, playerName)

    --if the data is unversioned or out of date, nuke the data first
    if(current.version == nil) then
        --if there is actually data to nuke...      
        if(next(current)) then
            current = {}
            container[containerKey] = current
        end        
    elseif(current.version < version) then
        current = {}
        container[containerKey] = current
    end

    current.version = version

    if defaults then
        CopyDefaults(current, defaults)
    end

    local interfaceMT = { 
        __index = current,

        __newindex = function(t, k, v)
            current[k] = v
        end,
    }

    local interface = {
        default = defaults,
    }

    cachedInterfaces = cachedInterfaces or {}

    ExposeMethods(interface, namespace, rawSavedTable, defaults, cachedInterfaces)

    return setmetatable(interface, interfaceMT)
end