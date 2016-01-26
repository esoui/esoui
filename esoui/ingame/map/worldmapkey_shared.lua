ZO_WorldMapKey_Shared = ZO_Object:Subclass()

function ZO_WorldMapKey_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapKey_Shared:Initialize(control)
    self.control = control
    self.dirty = true

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function()
        self.dirty = true
        self:RefreshKey()
    end)
end

function ZO_WorldMapKey_Shared:RefreshKey()
    if(not self.fragment:IsShowing()) then
        return
    end

    if(self.dirty) then
        self.dirty = false

        self.headerPool:ReleaseAllObjects()
        self.symbolPool:ReleaseAllObjects()

        local numKeySections = GetNumMapKeySections()
        self.noKeyLabel:SetHidden(numKeySections > 0)

        self.symbols = {}

        local params = self.symbolParams
        local lastLeftMostSymbol
        for sectionIndex = 1, GetNumMapKeySections() do
            local header = self.headerPool:AcquireObject()
            header:SetText(GetMapKeySectionName(sectionIndex))
            if(lastLeftMostSymbol) then
                header:SetAnchor(TOPLEFT, lastLeftMostSymbol, BOTTOMLEFT, -params.SYMBOL_SECTION_OFFSET_X + params.HEADER_SECTION_OFFSET_X, params.BETWEEN_SECTION_PADDING_Y)
            else
                header:SetAnchor(TOPLEFT, nil, TOPLEFT, params.HEADER_SECTION_OFFSET_X)
            end

            local symbolList

            for symbolIndex = 1, GetNumMapKeySectionSymbols(sectionIndex) do
                local symbol = self.symbolPool:AcquireObject()
                symbol:SetDimensions(params.SYMBOL_SIZE, params.SYMBOL_SIZE)
                local name, icon, tooltip = GetMapKeySectionSymbolInfo(sectionIndex, symbolIndex)
                symbol:SetTexture(icon)
                symbol.name = name
                symbol.tooltip = tooltip

                local symbolRow = zo_floor((symbolIndex - 1) / params.NUM_SYMBOLS_PER_ROW) + 1
                local symbolCol = (symbolIndex - 1) % params.NUM_SYMBOLS_PER_ROW + 1

                if(symbolCol == 1) then
                    lastLeftMostSymbol = symbol
                    symbolList = {}
                    self.symbols[#self.symbols + 1] = symbolList
                end

                local offsetX = params.SYMBOL_SECTION_OFFSET_X + (params.SYMBOL_SIZE + params.SYMBOL_PADDING) * (symbolCol - 1)
                local offsetY = params.SYMBOL_SECTION_OFFSET_Y + (params.SYMBOL_SIZE + params.SYMBOL_PADDING) * (symbolRow - 1)
                symbol:SetAnchor(TOPLEFT, header, BOTTOMLEFT, offsetX - params.HEADER_SECTION_OFFSET_X, offsetY)

                symbolList[#symbolList + 1] = symbol
            end
        end
    end
end
