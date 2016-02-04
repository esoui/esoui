local g_nextUpdate = nil

local function UpdateTitle(titleLabel)
    titleLabel:SetText(ZO_WorldMap_GetMapTitle())
end

function ZO_WorldMapCorner_OnInitialized(self)
    local titleLabel = self:GetNamedChild("Title")
    local function UpdateTitleEventCallback()
        UpdateTitle(titleLabel)
    end

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", UpdateTitleEventCallback)
    self:RegisterForEvent(EVENT_PLAYER_ACTIVATED, UpdateTitleEventCallback)

    UpdateTitle(titleLabel)
end

function ZO_WorldMapCorner_OnUpdate(self, time)
    if(g_nextUpdate == nil or time > g_nextUpdate) then
        local formattedTime, nextUpdateIn = ZO_FormatClockTime()
        self:GetNamedChild("Time"):SetText(formattedTime)
        g_nextUpdate = time + nextUpdateIn
    end
end