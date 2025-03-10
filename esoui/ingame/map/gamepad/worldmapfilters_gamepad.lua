--Filter Panel

local WorldMapFilterPanel_Gamepad = ZO_WorldMapFilterPanel_Shared:Subclass()

function WorldMapFilterPanel_Gamepad:Initialize(control, mapFilterType, savedVars)
    ZO_WorldMapFilterPanel_Shared.Initialize(self, control, mapFilterType, savedVars)
    self.list = ZO_GamepadVerticalParametricScrollList:New(control:GetNamedChild("List"))
    self.list:SetAlignToScreenCenter(true)
    self.list:SetOnSelectedDataChangedCallback(function() GAMEPAD_WORLD_MAP_FILTERS:SelectKeybind() end)
    self.list:AddDataTemplate("ZO_GamepadWorldMapFilterCheckboxOptionTemplate", ZO_GamepadCheckboxOptionTemplate_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.list:AddDataTemplateWithHeader("ZO_GamepadWorldMapFilterComboBoxTemplate", function(...) self:SetupDropDown(...) end, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    local narrationInfo = 
    {
        canNarrate = function()
            return GAMEPAD_WORLD_MAP_FILTERS_FRAGMENT:IsShowing()
        end,
        headerNarrationFunction = function()
            return GAMEPAD_WORLD_MAP_INFO:GetHeaderNarration()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.list, narrationInfo)
    self:BuildControls()
end

function WorldMapFilterPanel_Gamepad:SetMapMode(mapMode)
    if mapMode ~= self.mapMode then
        self.mapMode = mapMode
        self.modeVars = self.savedVars[mapMode]
        self:BuildControls()
    end
end

function WorldMapFilterPanel_Gamepad:ShouldShowSelectButton()
    local selectedData = self.list:GetTargetData()
    if selectedData then
        return selectedData.showSelectButton
    end
    return false
end

function WorldMapFilterPanel_Gamepad:OnSelect()
    local selectedData = self.list:GetTargetData()
    if selectedData then
        selectedData.onSelect(selectedData)
    end
end

function WorldMapFilterPanel_Gamepad:AddHeader(header)
    self.currentHeader = header
end

function WorldMapFilterPanel_Gamepad:AddPinFilterCheckBox(mapPinGroup, refreshFunction)
    local function ToggleFunction(data)
        data.currentValue = not data.currentValue
        self:SetPinFilter(mapPinGroup, data.currentValue)
        if refreshFunction then
            refreshFunction()
        end
        self:BuildControls()
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list)
    end

    local info = 
    {
        name = GetString("SI_MAPFILTER", mapPinGroup),
        onSelect = ToggleFunction,
        mapPinGroup = mapPinGroup,
        refreshFunction = refreshFunction,
        showSelectButton = true,
        narrationText = function(entryData, entryControl)
            return ZO_FormatToggleNarrationText(entryData.text, entryData.currentValue)
        end,
    }

    local checkBox = ZO_GamepadEntryData:New(info.name)
    checkBox:SetDataSource(info)
    checkBox.currentValue = (self:GetPinFilter(mapPinGroup) ~= false)

    table.insert(self.pinFilterCheckBoxes, checkBox)

    self.list:AddEntry("ZO_GamepadWorldMapFilterCheckboxOptionTemplate", checkBox)
end

function WorldMapFilterPanel_Gamepad:AddPinFilterComboBox(optionsPinGroup, refreshFunction, header, optionsEnumStringName, ...)

    local checkBox = self:FindDependentCheckBox(optionsPinGroup)
    if checkBox and not checkBox.currentValue then
        return -- Looks neater if it doesn't even appear
    end

    local function ChangedFunction(comboBox, name, item, selectionChanged)
        if selectionChanged then
            self:SetPinFilter(optionsPinGroup, item.index)
            if(refreshFunction) then
                refreshFunction()
            end
            self:BuildControls()
        end
    end

    local info = 
    {
        callback = ChangedFunction,
        onSelect = function(data) self:FocusDropDown(data.dropDown) end,
        mapPinGroup = optionsPinGroup,
        refreshFunction = refreshFunction,
        optionsEnumStringName = optionsEnumStringName,
        showSelectButton = true,
        comboItems = { ... },
        narrationText = function(entryData, entryControl)
            return entryData.dropDown:GetNarrationText()
        end,
    }

    local comboBox = ZO_GamepadEntryData:New(info.name)
    comboBox:SetDataSource(info)

    table.insert(self.pinFilterOptionComboBoxes, comboBox)

    comboBox:SetHeader(header)
    self.list:AddEntry("ZO_GamepadWorldMapFilterComboBoxTemplateWithHeader", comboBox)
end

function WorldMapFilterPanel_Gamepad:SetupDropDown(control, data, selected, reselectingDuringRebuild, enabled, active)
    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))

    local dropDown = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Selector"))
    dropDown:SetSortsItems(false)
    dropDown:SetDeactivatedCallback(function() self:UnfocusDropDown() end)

    local function OnOptionChanged(_, entryText, entry)
        self:SetPinFilter(data.mapPinGroup, entry.index)
        if data.refreshFunction then
            data.refreshFunction()
        end
    end

    local selectedPinIndex = self:GetPinFilter(data.mapPinGroup)
    dropDown:ClearItems()
    for i, optionValue in ipairs(data.comboItems) do
        local entryText = GetString(data.optionsEnumStringName, optionValue)
        local entry = dropDown:CreateItemEntry(entryText, OnOptionChanged)
        entry.optionValue = optionValue
        entry.index = i
        dropDown:AddItem(entry)

        if optionValue == selectedPinIndex then
            dropDown:SelectItemByIndex(selectedPinIndex)
        end
    end
    data.dropDown = dropDown
end

function WorldMapFilterPanel_Gamepad:FocusDropDown(dropDown)
    if not self.dropDown then
        dropDown:Activate()
        self.dropDown = dropDown
    end
end

function WorldMapFilterPanel_Gamepad:UnfocusDropDown()
    if self.dropDown then
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list)
        self.dropDown = nil
    end
end

function WorldMapFilterPanel_Gamepad:HideDropDown()
    if self.dropDown then
        self.dropDown:Deactivate()
        self.dropDown = nil
    end
end

function WorldMapFilterPanel_Gamepad:PreBuildControls()
    self.pinFilterCheckBoxes = {}
    self.pinFilterOptionComboBoxes = {} 

    self.list:Clear()
end

function WorldMapFilterPanel_Gamepad:PostBuildControls()
    self.list:Commit()
end

--Global (Cosmic and World) Filter Panel

local GlobalWorldMapFilterPanel_Gamepad = ZO_Object.MultiSubclass(ZO_GlobalWorldMapFilterPanel_Shared, WorldMapFilterPanel_Gamepad)

function GlobalWorldMapFilterPanel_Gamepad:Initialize(...)
    ZO_GlobalWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel_Gamepad.Initialize(self, ...)
end

--PvE Filter Panel

local PvEWorldMapFilterPanel_Gamepad = ZO_Object.MultiSubclass(ZO_PvEWorldMapFilterPanel_Shared, WorldMapFilterPanel_Gamepad)

function PvEWorldMapFilterPanel_Gamepad:Initialize(...)
    ZO_PvEWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel_Gamepad.Initialize(self, ...)
end

--PvP Filter Panel

local PvPWorldMapFilterPanel_Gamepad = ZO_Object.MultiSubclass(ZO_PvPWorldMapFilterPanel_Shared, WorldMapFilterPanel_Gamepad)

function PvPWorldMapFilterPanel_Gamepad:Initialize(...)
    ZO_PvPWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel_Gamepad.Initialize(self, ...)
end

--Imperial PvP Filter Panel

local ImperialPvPWorldMapFilterPanel_Gamepad = ZO_Object.MultiSubclass(ZO_ImperialPvPWorldMapFilterPanel_Shared, WorldMapFilterPanel_Gamepad)

function ImperialPvPWorldMapFilterPanel_Gamepad:Initialize(...)
    ZO_ImperialPvPWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel_Gamepad.Initialize(self, ...)
end

--Battleground Filter Panel

local BattlegroundWorldMapFilterPanel_Gamepad = ZO_Object.MultiSubclass(ZO_BattlegroundWorldMapFilterPanel_Shared, WorldMapFilterPanel_Gamepad)

function BattlegroundWorldMapFilterPanel_Gamepad:Initialize(...)
    ZO_BattlegroundWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel_Gamepad.Initialize(self, ...)
end

--Filters

local WorldMapFilters_Gamepad = ZO_WorldMapFilters_Shared:Subclass()

function WorldMapFilters_Gamepad:Initialize(control)
    ZO_WorldMapFilters_Shared.Initialize(self, control)

    self:InitializeKeybindDescriptor()

    GAMEPAD_WORLD_MAP_FILTERS_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    GAMEPAD_WORLD_MAP_FILTERS_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.currentPanel.list:Activate()
            self.currentPanel:BuildControls()
            self:SelectKeybind()
        elseif newState == SCENE_HIDDEN then
            self:SwitchToKeybind(nil)
            self.currentPanel:HideDropDown()
            self.currentPanel.list:Deactivate()
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapSavedVarsReady", function(savedVars)
        self.pvePanel = PvEWorldMapFilterPanel_Gamepad:New(self.control:GetNamedChild("Main"):GetNamedChild("PvE"), MAP_FILTER_TYPE_STANDARD, savedVars)
        self.pvpPanel = PvPWorldMapFilterPanel_Gamepad:New(self.control:GetNamedChild("Main"):GetNamedChild("PvP"), MAP_FILTER_TYPE_AVA_CYRODIIL, savedVars)
        self.imperialPvPPanel = ImperialPvPWorldMapFilterPanel_Gamepad:New(self.control:GetNamedChild("Main"):GetNamedChild("ImperialPvP"), MAP_FILTER_TYPE_AVA_IMPERIAL, savedVars)
        self.battlegroundPanel = BattlegroundWorldMapFilterPanel_Gamepad:New(self.control:GetNamedChild("Main"):GetNamedChild("Battleground"), MAP_FILTER_TYPE_BATTLEGROUND, savedVars)
        self.globalPanel = GlobalWorldMapFilterPanel_Gamepad:New(self.control:GetNamedChild("Main"):GetNamedChild("Global"), MAP_FILTER_TYPE_GLOBAL, savedVars)
    end)
end

function WorldMapFilters_Gamepad:SwitchToKeybind(keybindStripDescriptor)
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
    self.keybindStripDescriptor = keybindStripDescriptor
    if keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(keybindStripDescriptor)
    end
end

function WorldMapFilters_Gamepad:RefreshKeybind()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function WorldMapFilters_Gamepad:SelectKeybind()
    if not GAMEPAD_WORLD_MAP_FILTERS_FRAGMENT:IsShowing() then
        return
    end

    if self.currentPanel then
        if self.currentPanel:ShouldShowSelectButton() then
            self:SwitchToKeybind(self.keybindStripDescriptorSelect)
        else
            self:SwitchToKeybind(self.keybindStripDescriptorNoSelect)
        end
    end
end

function WorldMapFilters_Gamepad:InitializeKeybindDescriptor()

    self.keybindStripDescriptorNoSelect =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad World Map Filters Select",
            keybind = "UI_SHORTCUT_PRIMARY",
            ethereal = true,

            callback = function()
                self.currentPanel:OnSelect()
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptorNoSelect, GAME_NAVIGATION_TYPE_BUTTON, ZO_WorldMapInfo_OnBackPressed)

    self.keybindStripDescriptorSelect =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            callback = function()
                self.currentPanel:OnSelect()
            end,
            sound = SOUNDS.DEFAULT_CLICK,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptorSelect, GAME_NAVIGATION_TYPE_BUTTON, ZO_WorldMapInfo_OnBackPressed)
end

--Global XML

function ZO_WorldMapFilters_Gamepad_OnInitialized(self)
    GAMEPAD_WORLD_MAP_FILTERS = WorldMapFilters_Gamepad:New(self)
end