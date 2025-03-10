--Filter Panel

local WorldMapFilterPanel = ZO_WorldMapFilterPanel_Shared:Subclass()

function WorldMapFilterPanel:Initialize(control, mapFilterType, savedVars)
    ZO_WorldMapFilterPanel_Shared.Initialize(self, control, mapFilterType, savedVars)
    self:BuildControls()
end

function WorldMapFilterPanel:SetMapMode(mapMode)
    if(mapMode ~= self.mapMode) then
        self.mapMode = mapMode
        self.modeVars = self.savedVars[mapMode]
        self:LoadInitialState()
    end
end

function WorldMapFilterPanel:RefreshDependentComboBox(checkBox)
    if(checkBox.dependentComboBox) then
        local enabled = ZO_CheckButton_IsChecked(checkBox)
        local dependentComboBox = self:FindComboBox(checkBox.dependentComboBox)
        dependentComboBox:SetEnabled(enabled)
    end
end

function WorldMapFilterPanel:AddPinFilterCheckBox(mapPinGroup, refreshFunction, header)
    if(not self.checkBoxPool) then
        self.checkBoxPool = ZO_ControlPool:New("ZO_CheckButton", self.control, "CheckBox")
    end
    
    local checkBox = self.checkBoxPool:AcquireObject()
    ZO_CheckButton_SetLabelText(checkBox, GetString("SI_MAPFILTER", mapPinGroup))
    ZO_CheckButton_SetToggleFunction(checkBox, function(button, checked)
        self:SetPinFilter(mapPinGroup, checked)
        self:RefreshDependentComboBox(checkBox)
        if(refreshFunction) then
            refreshFunction()
        end
    end)
    checkBox.mapPinGroup = mapPinGroup
    checkBox.refreshFunction = refreshFunction
    table.insert(self.pinFilterCheckBoxes, checkBox)
    self:AnchorControl(checkBox)    
end

function WorldMapFilterPanel:AddPinFilterComboBox(optionsPinGroup, refreshFunction, header, optionsEnumStringName, ...)
    if(not self.comboBoxPool) then
        self.comboBoxPool = ZO_ControlPool:New("ZO_WorldMapFilterComboBox", self.control, "ComboBox")
    end
    
    local comboBoxControl = self.comboBoxPool:AcquireObject()
    local comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    comboBox.mapPinGroup = optionsPinGroup

    local function OnOptionChanged(_, entryText, entry)
        self:SetPinFilter(optionsPinGroup, entry.optionValue)
        if(refreshFunction) then
            refreshFunction()
        end
    end

    for i = 1, select("#", ...) do
        local optionValue = select(i, ...)
        local entryText = GetString(optionsEnumStringName, optionValue)
        local entry = comboBox:CreateItemEntry(entryText, OnOptionChanged)
        entry.optionValue = optionValue
        comboBox:AddItem(entry)
    end

    self:AnchorControl(comboBoxControl, 21)
    table.insert(self.pinFilterOptionComboBoxes, comboBox)
end

function WorldMapFilterPanel:LoadInitialState()
    local filterTable = self.modeVars.filters[self.mapFilterType]
    for i = 1, #self.pinFilterCheckBoxes do
        local checkBox = self.pinFilterCheckBoxes[i]
        ZO_CheckButton_SetCheckState(checkBox, self:GetPinFilter(checkBox.mapPinGroup) ~= false)
        self:RefreshDependentComboBox(checkBox)
    end

    for i = 1, #self.pinFilterOptionComboBoxes do
        local comboBox = self.pinFilterOptionComboBoxes[i]
        local value = self:GetPinFilter(comboBox.mapPinGroup)
        for _, entry in ipairs(comboBox:GetItems()) do
            if(entry.optionValue == value) then
                comboBox:SetSelectedItemText(entry.name)
                break
            end
        end
    end
end

--Global (Cosmic and World) Filter Panel

local GlobalWorldMapFilterPanel = ZO_Object.MultiSubclass(ZO_GlobalWorldMapFilterPanel_Shared, WorldMapFilterPanel)

function GlobalWorldMapFilterPanel:Initialize(...)
    ZO_GlobalWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel.Initialize(self, ...)
end

--PvE Filter Panel

local PvEWorldMapFilterPanel = ZO_Object.MultiSubclass(ZO_PvEWorldMapFilterPanel_Shared, WorldMapFilterPanel)

function PvEWorldMapFilterPanel:Initialize(...)
    ZO_PvEWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel.Initialize(self, ...)
end

--PvP Filter Panel

local PvPWorldMapFilterPanel = ZO_Object.MultiSubclass(ZO_PvPWorldMapFilterPanel_Shared, WorldMapFilterPanel)

function PvPWorldMapFilterPanel:Initialize(...)
    ZO_PvPWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel.Initialize(self, ...)
end

--Imperial PvP Filter Panel

local ImperialPvPWorldMapFilterPanel = ZO_Object.MultiSubclass(ZO_ImperialPvPWorldMapFilterPanel_Shared, WorldMapFilterPanel)

function ImperialPvPWorldMapFilterPanel:Initialize(...)
    ZO_ImperialPvPWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel.Initialize(self, ...)
end

--Battleground Filter Panel

local BattlegroundWorldMapFilterPanel = ZO_Object.MultiSubclass(ZO_BattlegroundWorldMapFilterPanel_Shared, WorldMapFilterPanel)

function BattlegroundWorldMapFilterPanel:Initialize(...)
    ZO_BattlegroundWorldMapFilterPanel_Shared.Initialize(self, ...)
    WorldMapFilterPanel.Initialize(self, ...)
end

--Filters

local WorldMapFilters = ZO_WorldMapFilters_Shared:Subclass()

function WorldMapFilters:Initialize(control)
    ZO_WorldMapFilters_Shared.Initialize(self, control)
    WORLD_MAP_KEY_FILTERS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    WORLD_MAP_KEY_FILTERS_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            self.currentPanel:LoadInitialState()
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapSavedVarsReady", function(savedVars)
        self.pvePanel = PvEWorldMapFilterPanel:New(self.control:GetNamedChild("PvE"), MAP_FILTER_TYPE_STANDARD, savedVars)
        self.pvpPanel = PvPWorldMapFilterPanel:New(self.control:GetNamedChild("PvP"), MAP_FILTER_TYPE_AVA_CYRODIIL, savedVars)
        self.imperialPvPPanel = ImperialPvPWorldMapFilterPanel:New(self.control:GetNamedChild("ImperialPvP"), MAP_FILTER_TYPE_AVA_IMPERIAL, savedVars)
        self.battlegroundPanel = BattlegroundWorldMapFilterPanel:New(self.control:GetNamedChild("Battleground"), MAP_FILTER_TYPE_BATTLEGROUND, savedVars)
        self.globalPanel = GlobalWorldMapFilterPanel:New(self.control:GetNamedChild("Global"), MAP_FILTER_TYPE_GLOBAL, savedVars)
    end)
end

--Global XML

function ZO_WorldMapFilters_OnInitialized(self)
    WORLD_MAP_FILTERS = WorldMapFilters:New(self)
end