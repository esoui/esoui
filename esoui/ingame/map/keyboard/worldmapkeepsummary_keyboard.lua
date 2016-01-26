--Keep Summary Window
local MapKeepSummary = ZO_MapKeepSummary_Shared:Subclass()

function MapKeepSummary:New(...)
    local object = ZO_MapKeepSummary_Shared.New(self, ...)
    return object
end

function MapKeepSummary:GetKeepUpgradeObject()
    return WORLD_MAP_KEEP_INFO:GetKeepUpgradeObject()
end

function MapKeepSummary:Initialize(control)
    self.rowLayout = "ZO_WorldMapKeepSummaryRow"
    ZO_MapKeepSummary_Shared.Initialize(self, control)
end

--Global XML

function ZO_WorldMapKeepAlliance_OnMouseEnter(self)
    ZO_Tooltips_ShowTextTooltip(self, TOP, zo_strformat(SI_MAP_KEEP_INFO_ALLIANCE_TOOLTIP_FORMAT, GetAllianceName(self.alliance)))
end

function ZO_WorldMapKeepAlliance_OnMouseExit(self)
    ZO_Tooltips_HideTextTooltip()
end

function ZO_WorldMapKeepSummary_OnInitialized(self)
    WORLD_MAP_KEEP_SUMMARY = MapKeepSummary:New(self)
    WORLD_MAP_KEEP_INFO:SetFragment("SUMMARY_FRAGMENT", WORLD_MAP_KEEP_SUMMARY:GetFragment())
end