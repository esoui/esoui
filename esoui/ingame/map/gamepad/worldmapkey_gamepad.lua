GAMEPAD_WORLD_MAP_KEY_COLUMN_WIDTH = 420

local SYMBOL_PARAMS =
{
    TARGET_SYMBOLS_PER_COLUMN = 6,
    MAX_SYMBOLS_PER_COLUMN = 7,
    TARGET_SECTIONS_PER_COLUMN = 2,

    SYMBOL_OFFSET_Y = 25,
    HEADER_OFFSET_X = 69,
    HEADER_OFFSET_Y = 70,
}

local WorldMapKey_Gamepad = ZO_WorldMapKey_Shared:Subclass()

local NUM_COLUMNS = 4

function WorldMapKey_Gamepad:Initialize(control)
    ZO_WorldMapKey_Shared.Initialize(self, control)

    self.symbolParams = SYMBOL_PARAMS

    local mainControl = control:GetNamedChild("Main")
    self.mainControl = mainControl
    self.scrollControl = mainControl:GetNamedChild("Scroll")
    self.scrollChildControl = mainControl:GetNamedChild("ScrollChild")
    self.scrollIndicator = mainControl:GetNamedChild("ScrollIndicator")

    self.columns = {}
    local anchorTo = self.scrollChildControl
    local relativePoint1, relativePoint2 = TOPLEFT, BOTTOMLEFT
    for i = 1, NUM_COLUMNS do
        local newColumn = CreateControlFromVirtual("$(parent)Container", self.scrollChildControl, "ZO_WorldMapKeySymbolContainer_Gamepad", i)
        newColumn:SetAnchor(TOPLEFT, anchorTo, relativePoint1)
        newColumn:SetAnchor(BOTTOMLEFT, anchorTo, relativePoint2)
        table.insert(self.columns, newColumn)

        anchorTo = newColumn
        relativePoint1, relativePoint2 = TOPRIGHT, BOTTOMRIGHT
    end

    self.noKeyLabel = mainControl:GetNamedChild("NoKey")

    local function Reset(control)
        control:SetParent(self.mainControl)
    end

    self.symbolPool = ZO_ControlPool:New("ZO_WorldMapKeySymbol_Gamepad", mainControl, "Symbol")
    self.headerPool = ZO_ControlPool:New("ZO_GamepadMenuEntryHeaderTemplate", mainControl, "Header")
    self.symbolPool:SetCustomResetBehavior(Reset)
    self.headerPool:SetCustomResetBehavior(Reset)

    self:InitializeKeybindStripDescriptor()

    GAMEPAD_WORLD_MAP_KEY_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAMEPAD_WORLD_MAP_KEY_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.inputEnabled = true
            ZO_WorldMap_SetGamepadKeybindsShown(false)
            self:RefreshKey()
            self.m_keybindState = KEYBIND_STRIP:PushKeybindGroupState()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.m_keybindState)
            ZO_WorldMap_UpdateInteractKeybind_Gamepad()
        elseif newState == SCENE_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.m_keybindState)
            KEYBIND_STRIP:PopKeybindGroupState()
            ZO_WorldMap_UpdateInteractKeybind_Gamepad()
            ZO_WorldMap_SetGamepadKeybindsShown(true)
            self.inputEnabled = false
            self:RefreshDirectionalInputActivation()
        end
    end)
    self.fragment = GAMEPAD_WORLD_MAP_KEY_FRAGMENT

    self.scrollTargetPos = 0
end

local function ExitMapKey()
    SCENE_MANAGER:RemoveFragment(GAMEPAD_WORLD_MAP_KEY_FRAGMENT)
end

function WorldMapKey_Gamepad:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
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
    if not self.fragment:IsShowing() then
        return
    end

    if self.dirty then
        self.dirty = false

        self.symbolPool:ReleaseAllObjects()
        self.headerPool:ReleaseAllObjects()

        local numKeySections = GetNumMapKeySections()
        self.noKeyLabel:SetHidden(numKeySections > 0)

        self.symbols = {}

        local params = self.symbolParams
        local numSymbolsInColumn = 0
        local columnIndex = 1
        local column = self.columns[columnIndex]
        local previousAnchor = column
        local headerRelativePoint = TOPLEFT
        local allFilledOnce = false
        local numSectionsPerColumn = {}

        local totalNumSymbols = 0
        local numSymbolsBySection = {}
        for sectionIndex = 1, numKeySections do
            numSymbolsBySection[sectionIndex] = GetNumMapKeySectionSymbols(sectionIndex)
            totalNumSymbols = totalNumSymbols + numSymbolsBySection[sectionIndex]
        end
        local averageSymbolsPerColumn = totalNumSymbols / NUM_COLUMNS

        for sectionIndex = 1, numKeySections do
            local newNumSymbolsInColumn = numSymbolsInColumn + numSymbolsBySection[sectionIndex]
            local moveToNextColumn = newNumSymbolsInColumn > averageSymbolsPerColumn
            if moveToNextColumn then
                if columnIndex == NUM_COLUMNS or allFilledOnce then
                    -- If all columns have symbols, add to the shortest column
                    columnIndex = 1
                    local minSymbols = #self.symbols[columnIndex] + numSectionsPerColumn[columnIndex]
                    for i = 2, NUM_COLUMNS do
                        local columnSymbols = #self.symbols[i] + numSectionsPerColumn[i]
                        if columnSymbols < minSymbols then
                            minSymbols = columnSymbols
                            columnIndex = i
                        end
                    end

                    column = self.columns[columnIndex]
                    local symbolsInColumn = self.symbols[columnIndex]
                    numSymbolsInColumn = #symbolsInColumn
                    previousAnchor = symbolsInColumn[numSymbolsInColumn]

                    allFilledOnce = true
                else
                    columnIndex = columnIndex + 1
                    column = self.columns[columnIndex]
                    previousAnchor = column
                    headerRelativePoint = TOPLEFT

                    numSymbolsInColumn = 0
                end
            end

            if numSectionsPerColumn[columnIndex] == nil then
                numSectionsPerColumn[columnIndex] = 1
            else
                numSectionsPerColumn[columnIndex] = numSectionsPerColumn[columnIndex] + 1
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

            for symbolIndex = 1, numSymbolsBySection[sectionIndex] do
                numSymbolsInColumn = numSymbolsInColumn + 1
                local symbol = self.symbolPool:AcquireObject()
                local name, icon, tooltip = GetMapKeySectionSymbolInfo(sectionIndex, symbolIndex)
                symbol:GetNamedChild("Symbol"):SetTexture(icon)
                symbol:GetNamedChild("Name"):SetText(name)
                symbol.tooltip = tooltip

                symbol:SetParent(column)
                symbol:SetAnchor(TOPLEFT, previousAnchor, BOTTOMLEFT, offsetX, params.SYMBOL_OFFSET_Y)
                offsetX = 0

                if self.symbols[columnIndex] == nil then
                    self.symbols[columnIndex] = {}
                end

                table.insert(self.symbols[columnIndex], symbol)
                previousAnchor = symbol
            end
        end

        local ANCHORS_TO_BACKGROUND = true
        self:RefreshDirectionalInputActivation()
    end
end

function WorldMapKey_Gamepad:RefreshDirectionalInputActivation()
    local _, verticalExtents = self.scrollControl:GetScrollExtents()
    local canScroll = verticalExtents > 0 and self.inputEnabled
    if self.fragment:IsShowing() and canScroll then
        if not self.directionalInputActivated then
            self.directionalInputActivated = true
            ZO_SCROLL_SHARED_INPUT:Activate(self.mainControl)
        end
        self.scrollIndicator:SetHidden(false)
    else
        if self.directionalInputActivated then
            self.directionalInputActivated = false
            ZO_SCROLL_SHARED_INPUT:Deactivate()
        end
        self.scrollIndicator:SetHidden(true)
    end
end

--Global XML

function ZO_WorldMapKey_Gamepad_OnInitialized(self)
    GAMEPAD_WORLD_MAP_KEY = WorldMapKey_Gamepad:New(self)
end