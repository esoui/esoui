local DEFAULT_EXPIRATION_INTERVAL_MS = 5000
local DEFAULT_EXTENSION_INTERVAL_MS = 5000

-- Tracks the number of occurrences of each value within an indeterminate set using a sliding time window.

ZO_RecurrenceTrackerValue = ZO_InitializingObject:Subclass()

function ZO_RecurrenceTrackerValue:Initialize(value, expirationMS)
    local currentFrameTimeMS = GetFrameTimeMilliseconds()
    self.m_expirationMS = expirationMS
    self.m_numOccurrences = 1
    self.m_value = value
end

function ZO_RecurrenceTrackerValue:GetExpirationMS()
    return self.m_expirationMS
end

function ZO_RecurrenceTrackerValue:GetNumOccurrences()
    return self.m_numOccurrences
end

function ZO_RecurrenceTrackerValue:GetValue()
    return self.m_value
end

function ZO_RecurrenceTrackerValue:HasExpired()
    return self.m_expirationTimeMS and self.m_expirationTimeMS <= GetFrameTimeMilliseconds() or false
end

function ZO_RecurrenceTrackerValue:SetExpirationMS(expirationMS)
    self.m_expirationMS = expirationMS
end

function ZO_RecurrenceTrackerValue:SetNumOccurrences(numOccurrences)
    self.m_numOccurrences = numOccurrences
end

ZO_RecurrenceTracker = ZO_InitializingObject:Subclass()

-- expirationIntervalMS = the initial lifetime for new values.
-- extensionIntervalMS = how long an existing value's lifetime should be extended for subsequent occurrences.
function ZO_RecurrenceTracker:Initialize(expirationIntervalMS, extensionIntervalMS)
    self:Reset()
    self.m_expirationIntervalMS = tonumber(expirationIntervalMS) or DEFAULT_EXPIRATION_INTERVAL_MS
    self.m_extensionIntervalMS = tonumber(extensionIntervalMS) or DEFAULT_EXTENSION_INTERVAL_MS
end

function ZO_RecurrenceTracker:AddValue(value)
    if value == nil then
        -- Ignore nil values.
        return
    end

    -- Performs clean up only when necessary.
    self:RemoveExpiredValues()

    local currentTimeMS = GetFrameTimeMilliseconds()
    local expirationMS = nil
    local valueEntry = self:GetValue(value)
    if valueEntry then
        -- Increment the number of occurrences.
        local numOccurrences = valueEntry:GetNumOccurrences()
        numOccurrences = numOccurrences + 1
        valueEntry:SetNumOccurrences(numOccurrences)

        -- Extend the expiration time to the maximum of either the current expiration time or now + m_extensionIntervalMS.
        expirationMS = valueEntry:GetExpirationMS()
        expirationMS = zo_max(expirationMS, currentTimeMS + self.m_extensionIntervalMS)
        valueEntry:SetExpirationMS(expirationMS)
    else
        -- Add the new value entry.
        expirationMS = currentTimeMS + self.m_expirationIntervalMS
        valueEntry = ZO_RecurrenceTrackerValue:New(value, expirationMS)
        self.m_values[value] = valueEntry
    end

    if not self.m_nextExpirationMS or expirationMS < self.m_nextExpirationMS then
        -- Update the next expiration to this expiration.
        self.m_nextExpirationMS = expirationMS
    end

    return valueEntry:GetNumOccurrences()
end

function ZO_RecurrenceTracker:GetValue(value)
    local valueEntry = self.m_values[value]
    if valueEntry and valueEntry:HasExpired() then
        -- This entry has already expired.
        valueEntry = nil
        self.m_values[value] = nil
    end
    return valueEntry
end

function ZO_RecurrenceTracker:Reset()
    self.m_nextExpirationMS = nil
    self.m_values = {}
end

function ZO_RecurrenceTracker:RemoveExpiredValues()
    if not self.m_nextExpirationMS then
        -- There are no values pending expiration.
        return
    end

    local currentTimeMS = GetFrameTimeMilliseconds()
    if currentTimeMS < self.m_nextExpirationMS then
        -- There are no values that have expired.
        return
    end

    local expiredValues = nil
    local nextExpirationMS = nil
    local values = self.m_values

    -- Identify expired values.
    for value, valueEntry in pairs(values) do
        local expirationMS = valueEntry:GetExpirationMS()
        if expirationMS <= currentTimeMS then
            if not expiredValues then
                expiredValues = {}
            end

            -- Queue this value for removal.
            table.insert(expiredValues, value)
        else
            if not nextExpirationMS or expirationMS < nextExpirationMS then
                -- Track the next upcoming expiration time.
                nextExpirationMS = expirationMS
            end
        end
    end

    if expiredValues then
        -- Remove expired values.
        for _, value in ipairs(expiredValues) do
            values[value] = nil
        end
    end

    self.m_nextExpirationMS = nextExpirationMS
end