local MapLocations_Gamepad = ZO_MapLocations_Shared:Subclass()

local LOCATION_DATA = 1

function MapLocations_Gamepad:New(...)
    local object = ZO_MapLocations_Shared.New(self,...)
    return object
end

function MapLocations_Gamepad:Initialize(control)
    self.sideContent = control:GetNamedChild("SideContent")

    local SHOWINGTOOLTIP = true
    local NOT_SHOWINGTOOLTIP = false
    CALLBACK_MANAGER:RegisterCallback("OnShowWorldMapTooltip", function() self:UpdateSideContentVisibility(SHOWINGTOOLTIP) end)
    CALLBACK_MANAGER:RegisterCallback("OnHideWorldMapTooltip", function() self:UpdateSideContentVisibility(NOT_SHOWINGTOOLTIP) end)

    ZO_MapLocations_Shared.Initialize(self, control)

    self:InitializeKeybindDescriptor()

    GAMEPAD_WORLD_MAP_LOCATIONS_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    GAMEPAD_WORLD_MAP_LOCATIONS_FRAGMENT:RegisterCallback("StateChange",  function(oldState, newState)
        if(newState == SCENE_SHOWING) then
            if not self.listDisabled then
                self.list:Activate()
            end
            self.list:RefreshVisible()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif(newState == SCENE_HIDDEN) then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self.list:Deactivate()
        end
    end)
end

function MapLocations_Gamepad:UpdateSideContentVisibility(showingTooltips)
    if (showingTooltips ~= nil) then
        self.showingTooltips = showingTooltips
    end

    self.sideContent:SetHidden(self.showingTooltips or not self.hasLocationInfo)
end

function MapLocations_Gamepad:InitializeList(control)
    self.list = ZO_GamepadVerticalParametricScrollList:New(control:GetNamedChild("Main"):GetNamedChild("List"))
    self.list:AddDataTemplate("ZO_GamepadMenuEntryTemplateLowercase42", function(...) self:SetupLocation(...) end, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.list:SetAlignToScreenCenter(true)
end

function MapLocations_Gamepad:UpdateSelectedMap()
    self.selectedMapIndex = GetCurrentMapIndex()
    self.list:RefreshVisible()
end

function MapLocations_Gamepad:SetListDisabled(disabled)
    self.listDisabled = disabled
    if not self.listDisabled then
        if GAMEPAD_WORLD_MAP_LOCATIONS_FRAGMENT:IsShowing() then
            self.list:Activate()
        end
        self.list:RefreshVisible()
    else
        self.list:Deactivate()
    end
end

function MapLocations_Gamepad:BuildLocationList()
    self.list:Clear()

    local mapData = self.data:GetLocationList()

    for i, mapEntry in ipairs(mapData) do
        local entryData = ZO_GamepadEntryData:New(mapEntry.locationName)
        entryData:SetDataSource(mapEntry)
        self.list:AddEntry("ZO_GamepadMenuEntryTemplateLowercase42", entryData)
    end

    self.list:Commit()
end

function MapLocations_Gamepad:SetupLocation(control, data, selected, selectedDuringRebuild, enable, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enable, activated)
    if selected then
        self.selectedData = data
        self:SetupLocationDetails(data)
    end
end

function MapLocations_Gamepad:SetupLocationDetails(data)
    if data.description and data.description ~= "" then
        self.sideContent:GetNamedChild("Info"):SetText(data.description)
        self.hasLocationInfo = true

        if ZO_WorldMap_HideAllTooltips then     -- This isn't declared yet during initialisation
            ZO_WorldMap_HideAllTooltips()
        end
    else
        self.hasLocationInfo = false
    end
    self:UpdateSideContentVisibility()
end

function MapLocations_Gamepad:RefreshKeybind()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function MapLocations_Gamepad:InitializeKeybindDescriptor()

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            callback = function()
                if self.selectedData then
                    ZO_WorldMap_SetMapByIndex(self.selectedData.index)
                    PlaySound(SOUNDS.MAP_LOCATION_CLICKED)
                end
            end,

            visible = function()
                return self.selectedData ~= nil
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, ZO_WorldMapInfo_OnBackPressed)
end

--Global XML

function ZO_WorldMapLocations_Gamepad_OnInitialized(self)
    GAMEPAD_WORLD_MAP_LOCATIONS = MapLocations_Gamepad:New(self)
end