local g_soundHandlers = {
    [EVENT_CROWN_UPDATE] = function(crownAmount, difference)
        if difference < 0 then
            return SOUNDS.MARKET_CROWNS_SPENT
        end
    end,
    [EVENT_CROWN_GEM_UPDATE] = function(crownGemAmount, difference)
        if difference < 0 then
            return SOUNDS.MARKET_CROWN_GEMS_SPENT
        end
    end,
}

function ZO_SoundEvents_GetHandlers()
    return g_soundHandlers
end

local function OnSoundEvent(eventCode, ...)
    if g_soundHandlers[eventCode] then
        local soundId = g_soundHandlers[eventCode](...)
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