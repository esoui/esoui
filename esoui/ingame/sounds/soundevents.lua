local g_soundHandlers = {
    [EVENT_JUSTICE_GOLD_REMOVED] = function()
        return SOUNDS.JUSTICE_GOLD_REMOVED
    end,

    [EVENT_JUSTICE_STOLEN_ITEMS_REMOVED] = function()
        return SOUNDS.JUSTICE_ITEM_REMOVED
    end,

    [EVENT_MEDAL_AWARDED] = function()
        return SOUNDS.BATTLEGROUND_MEDAL_RECEIVED
    end,
}

function ZO_SoundEvents_GetHandlers()
    return g_soundHandlers
end

local function OnSoundEvent(eventId, ...)
    if g_soundHandlers[eventId] then
        local soundId = g_soundHandlers[eventId](...)
        if soundId then
            PlaySound(soundId)
        end
    end
end

function ZO_SoundEvent(eventId, ...)
    OnSoundEvent(eventId, ...)
end

function ZO_SoundEvents_OnInitialized()
    for event in pairs(g_soundHandlers) do
        EVENT_MANAGER:RegisterForEvent("ZO_SoundEvents", event, OnSoundEvent)
    end
end

ZO_SoundEvents_OnInitialized()
