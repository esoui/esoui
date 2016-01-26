local g_nextUpdate = nil

local function UpdateTitle(titleLabel)
    titleLabel:SetText(ZO_WorldMap_GetMapTitle())
end

function ZO_WorldMapCorner_OnInitialized(self)
    local titleLabel = self:GetNamedChild("Title")
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function()
        UpdateTitle(titleLabel)
    end)
    UpdateTitle(titleLabel)
end

function ZO_WorldMapCorner_OnUpdate(self, time)
    if(g_nextUpdate == nil or time > g_nextUpdate) then
        local formattedTime, nextUpdateIn = ZO_FormatClockTime()
        self:GetNamedChild("Time"):SetText(formattedTime)
        g_nextUpdate = time + nextUpdateIn
    end
end