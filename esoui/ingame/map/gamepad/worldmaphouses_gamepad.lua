ZO_MapHouses_Gamepad = ZO_MapHouses_Shared:Subclass()

function ZO_MapHouses_Gamepad:New(...)
    return ZO_MapHouses_Shared.New(self,...)
end

function ZO_MapHouses_Gamepad:Initialize(control)
    ZO_MapHouses_Shared.Initialize(self, control)
    self:SetNoHousesLabelControl(control:GetNamedChild("Main"):GetNamedChild("NoHouses"))
    self:InitializeKeybindDescriptor()
end

function ZO_MapHouses_Gamepad:InitializeList(control)
    self.list = ZO_GamepadVerticalParametricScrollList:New(control:GetNamedChild("Main"):GetNamedChild("List"))

    self.list:AddDataTemplate("ZO_GamepadMenuEntryTemplateLowercase42", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplateLowercase42", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    self.list:SetAlignToScreenCenter(true)
end

function ZO_MapHouses_Gamepad:SetListEnabled(enabled)
    ZO_MapHouses_Shared.SetListEnabled(self, enabled)

    if enabled then
        if self:GetFragment():IsShowing() then
            self.list:Activate()
        end
        self.list:RefreshVisible()
    else
        self.list:Deactivate()
    end
end

function ZO_MapHouses_Gamepad:RefreshHouseList()
    ZO_MapHouses_Shared.RefreshHouseList(self)

    self.list:Clear()

    local houseList = WORLD_MAP_HOUSES_DATA:GetHouseList()

    local firstUnlocked = true
    local firstLocked = true
    for i, houseEntry in ipairs(houseList) do
        local headerText = nil
        if houseEntry.unlocked and firstUnlocked then
            headerText = GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED)
            firstUnlocked = false
        elseif not houseEntry.unlocked and firstLocked then
            headerText = GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_LOCKED)
            firstLocked = false
        end

        local entryData = ZO_GamepadEntryData:New(houseEntry.houseName)
        entryData:SetDataSource(houseEntry)
        entryData:AddSubLabel(houseEntry.foundInZoneName)
        if headerText then
            entryData:SetHeader(headerText)
            self.list:AddEntry("ZO_GamepadMenuEntryTemplateLowercase42WithHeader", entryData)
        else
            self.list:AddEntry("ZO_GamepadMenuEntryTemplateLowercase42", entryData)
        end
    end

    self.list:Commit()
end

function ZO_MapHouses_Gamepad:RefreshKeybind()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_MapHouses_Gamepad:InitializeKeybindDescriptor()

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            callback = function()
                local targetData = self.list:GetTargetData()
                ZO_WorldMap_SetMapByIndex(targetData.mapIndex)
                ZO_WorldMap_PanToWayshrine(targetData.nodeIndex)
                PlaySound(SOUNDS.MAP_LOCATION_CLICKED)
            end,

            visible = function()
                local targetData = self.list:GetTargetData()
                return targetData ~= nil
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, ZO_WorldMapInfo_OnBackPressed)
end

function ZO_MapHouses_Gamepad:OnShowing()
    ZO_MapHouses_Shared.OnShowing(self)

    if self:IsListEnabled() then
        self.list:Activate()
    end
    self.list:RefreshVisible()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_MapHouses_Gamepad:OnHidden()
    ZO_MapHouses_Shared.OnHidden(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.list:Deactivate()
end

--Global XML

function ZO_WorldMapHouses_Gamepad_OnInitialized(self)
    GAMEPAD_WORLD_MAP_HOUSES = ZO_MapHouses_Gamepad:New(self)
end