local SYMBOL_PARAMS = {
    NUM_SYMBOLS_PER_ROW = 4,
    HEADER_SECTION_OFFSET_X = 0,
    SYMBOL_PADDING = 16,
    SYMBOL_SECTION_OFFSET_X = 25,
    SYMBOL_SECTION_OFFSET_Y = 3,
    SYMBOL_SIZE = 40,
    BETWEEN_SECTION_PADDING_Y = 20,
}

local WorldMapKey = ZO_WorldMapKey_Shared:Subclass()

function WorldMapKey:New(...)
    local object = ZO_WorldMapKey_Shared.New(self, ...)
    return object
end

function WorldMapKey:Initialize(control)
    ZO_WorldMapKey_Shared.Initialize(self, control)

    self.symbolParams = SYMBOL_PARAMS

    self.scrollChild = GetControl(control, "PaneScrollChild")
    self.noKeyLabel = control:GetNamedChild("NoKey")

    self.headerPool = ZO_ControlPool:New("ZO_WorldMapKeyHeader", self.scrollChild, "Header")
    self.symbolPool = ZO_ControlPool:New("ZO_WorldMapKeySymbol", self.scrollChild, "Symbol")

    WORLD_MAP_KEY_FRAGMENT = ZO_FadeSceneFragment:New(control)
    WORLD_MAP_KEY_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_SHOWING) then
            self:RefreshKey()
        end
    end)

    self.fragment = WORLD_MAP_KEY_FRAGMENT
end

--Local XML

function WorldMapKey:Symbol_OnMouseEnter(symbol)
    InitializeTooltip(InformationTooltip, symbol, BOTTOM, 0, -10)
    InformationTooltip:AddLine(symbol.name, "ZoFontHeader")
    if(symbol.tooltip ~= "") then
        InformationTooltip:AddLine(symbol.tooltip, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
    end
end

function WorldMapKey:Symbol_OnMouseExit(symbol)
    ClearTooltip(InformationTooltip)
end

--Global XML

function ZO_WorldMapKeySymbol_OnMouseEnter(self)
    WORLD_MAP_KEY:Symbol_OnMouseEnter(self)
end

function ZO_WorldMapKeySymbol_OnMouseExit(self)
    WORLD_MAP_KEY:Symbol_OnMouseExit(self)
end

function ZO_WorldMapKey_OnInitialized(self)
    WORLD_MAP_KEY = WorldMapKey:New(self)
end