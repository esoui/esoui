GAMEPAD_WORLD_MAP_KEY_COLUMN_WIDTH = 420

local SYMBOL_PARAMS = {
    TARGET_SYMBOLS_PER_COLUMN = 6,
    MAX_SYMBOLS_PER_COLUMN = 7,
    TARGET_SECTIONS_PER_COLUMN = 2,
    
    SYMBOL_OFFSET_Y = 25,
    HEADER_OFFSET_X = 69,
    HEADER_OFFSET_Y = 70,
}

local WorldMapKey_Gamepad = ZO_WorldMapKey_Shared:Subclass()

function WorldMapKey_Gamepad:New(...)
    local object = ZO_WorldMapKey_Shared.New(self, ...)
    return object
end

local NUM_COLUMNS = 4

function WorldMapKey_Gamepad:Initialize(control)
    ZO_GamepadGrid.Initialize(self, control)
    ZO_WorldMapKey_Shared.Initialize(self, control)

    self.symbolParams = SYMBOL_PARAMS

    local mainControl = control:GetNamedChild("Main")
    self.columns = {}
    local anchorTo = mainControl
    local relativePoint1, relativePoint2 = TOPLEFT, BOTTOMLEFT
    for i = 1, NUM_COLUMNS do
        local newColumn = CreateControlFromVirtual("$(parent)Container", mainControl, "ZO_WorldMapKeySymbolContainer_Gamepad", i)
        newColumn:SetAnchor(TOPLEFT, anchorTo, relativePoint1)
        newColumn:SetAnchor(BOTTOMLEFT, anchorTo, relativePoint2)
        table.insert(self.columns, newColumn)

        anchorTo = newColumn
        relativePoint1, relativePoint2 = TOPRIGHT, BOTTOMRIGHT
    end

    self.noKeyLabel = mainControl:GetNamedChild("NoKey")

    local function Reset(control)
        control:SetParent(mainControl)
    end

    self.symbolPool = ZO_ControlPool:New("ZO_WorldMapKeySymbol_Gamepad", mainControl, "Symbol")
    self.headerPool = ZO_ControlPool:New("ZO_GamepadMenuEntryHeaderTemplate", mainControl, "Header")
    self.symbolPool:SetCustomResetBehavior(Reset)
    self.headerPool:SetCustomResetBehavior(Reset)

    self:InitializeKeybindStripDescriptor()

    GAMEPAD_WORLD_MAP_KEY_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAMEPAD_WORLD_MAP_KEY_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            ZO_WorldMap_SetGamepadKeybindsShown(false)
            self:RefreshKey()
            self.m_keybindState = KEYBIND_STRIP:PushKeybindGroupState()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.m_keybindState)
            ZO_WorldMap_UpdateInteractKeybind_Gamepad()
        elseif(newState == SCENE_HIDING) then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.m_keybindState)
            KEYBIND_STRIP:PopKeybindGroupState()
            ZO_WorldMap_UpdateInteractKeybind_Gamepad()
            ZO_WorldMap_SetGamepadKeybindsShown(true)
        end
    end)
    self.fragment = GAMEPAD_WORLD_MAP_KEY_FRAGMENT

    self.scrollTargetPos = 0
end

local function ExitMapKey()
    SCENE_MANAGER:RemoveFragment(GAMEPAD_WORLD_MAP_KEY_FRAGMENT)
end

function WorldMapKey_Gamepad:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_WORLD_MAP_LEGEND_CLOSE_KEYBIND),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function() ExitMapKey() end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad World Map Exit Key",
            ethereal = true,
            keybind = "UI_SHORTCUT_LEFT_STICK",
            callback = function() ExitMapKey() end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        }, 
    }
end

function WorldMapKey_Gamepad:RefreshKey()
    if(not self.fragment:IsShowing()) then
        return
    end

    if(self.dirty) then
        self.dirty = false

        self.symbolPool:ReleaseAllObjects()
        self.headerPool:ReleaseAllObjects()

        local numKeySections = GetNumMapKeySections()
        self.noKeyLabel:SetHidden(numKeySections > 0)

        self.symbols = {}

        local params = self.symbolParams
        local numSymbolsInColumn = 0
        local numSectionsInColumn = 1
        local columnIndex = 1
        local column = self.columns[columnIndex]
        local previousAnchor = column
        local headerRelativePoint = TOPLEFT
        local allFilledOnce = false
        local symbolList

        for sectionIndex = 1, numKeySections do
            local numSectionSymbols = GetNumMapKeySectionSymbols(sectionIndex)

            local newNumSymbolsInColumn = numSymbolsInColumn + numSectionSymbols
            local moveToNextColumn = newNumSymbolsInColumn > params.MAX_SYMBOLS_PER_COLUMN or (newNumSymbolsInColumn > params.TARGET_SYMBOLS_PER_COLUMN and numSectionsInColumn > params.TARGET_SECTIONS_PER_COLUMN)
            if moveToNextColumn then
                if columnIndex == NUM_COLUMNS or allFilledOnce then
                    -- If all columns have symbols, add to the shortest column
                    local minSymbols = #self.symbols[1]
                    local columnIndex = 1
                    for i = 2, NUM_COLUMNS do
                        local columnSymbols = #self.symbols[i]
                        if columnSymbols < minSymbols then
                            minSymbols = columnSymbols
                            columnIndex = i
                        end
                    end
                    
                    column = self.columns[columnIndex]
                    local symbolsInColumn = self.symbols[columnIndex]
                    numSymbolsInColumn = #symbolsInColumn
                    previousAnchor = symbolsInColumn[numSymbolsInColumn]

                    -- There are at least two sections in the column and there will be more than the max number of symbols in the column so this count is not necessary
                    numSectionsInColumn = 2

                    allFilledOnce = true
                else
                    columnIndex = columnIndex + 1
                    column = self.columns[columnIndex]
                    previousAnchor = column
                    headerRelativePoint = TOPLEFT

                    numSymbolsInColumn = 0
                    numSectionsInColumn = 1
                end
            end
            
            local sectionName = GetMapKeySectionName(sectionIndex)
            local header = self.headerPool:AcquireObject()
            header:SetText(sectionName)

            header:SetParent(column)
            header:ClearAnchors()
            header:SetAnchor(LEFT, column, LEFT)
            header:SetAnchor(TOPLEFT, previousAnchor, headerRelativePoint, params.HEADER_OFFSET_X, params.HEADER_OFFSET_Y)
            headerRelativePoint = BOTTOMLEFT

            local offsetX = -params.HEADER_OFFSET_X
            previousAnchor = header

            for symbolIndex = 1, numSectionSymbols do
                numSymbolsInColumn = numSymbolsInColumn + 1
                local symbol = self.symbolPool:AcquireObject()
                local name, icon, tooltip = GetMapKeySectionSymbolInfo(sectionIndex, symbolIndex)
                symbol:GetNamedChild("Symbol"):SetTexture(icon)
                symbol:GetNamedChild("Name"):SetText(name)
                symbol.tooltip = tooltip

                symbol:SetParent(column)
                symbol:SetAnchor(LEFT, column, LEFT)
                symbol:SetAnchor(TOPLEFT, previousAnchor, BOTTOMLEFT, offsetX, params.SYMBOL_OFFSET_Y)
                offsetX = 0

                if numSymbolsInColumn == 1 then
                    symbolList = {}
                    table.insert(self.symbols, symbolList)
                end

                table.insert(symbolList, symbol)
                previousAnchor = symbol
            end

            numSectionsInColumn = numSectionsInColumn + 1
        end
    end
end

--Global XML

function ZO_WorldMapKey_Gamepad_OnInitialized(self)
    GAMEPAD_WORLD_MAP_KEY = WorldMapKey_Gamepad:New(self)
end