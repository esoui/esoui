ZO_MapAntiquities_Gamepad = ZO_MapAntiquities_Shared:Subclass()

function ZO_MapAntiquities_Gamepad:New(...)
    return ZO_MapAntiquities_Shared.New(self,...)
end

function ZO_MapAntiquities_Gamepad:Initialize(control)
    ZO_MapAntiquities_Shared.Initialize(self, control, ZO_SimpleSceneFragment)
    self:SetNoItemsLabelControl(control:GetNamedChild("MainNoItemsLabel"))
    self:InitializeKeybindDescriptor()

    self.control:RegisterForEvent(EVENT_ANTIQUITY_TRACKING_UPDATE, function()
        if self.fragment:IsShowing() then
            self:RefreshKeybinds()
        end
    end)
end

function ZO_MapAntiquities_Gamepad:InitializeList(control)
    self.list = ZO_GamepadVerticalParametricScrollList:New(control:GetNamedChild("MainList"))

    local function EntrySetup(entryControl, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(entryControl, data, selected, reselectingDuringRebuild, enabled, active)

        if not entryControl.progressIconMetaPool then
            entryControl.progressIconMetaPool = ZO_MetaPool:New(self.progressIconControlPool)
        else
            entryControl.progressIconMetaPool:ReleaseAllObjects()
        end

        local numGoalsAchieved = data:GetNumGoalsAchieved()

        local previousIcon
        local totalNumGoals = data:GetTotalNumGoals()
        for goalIndex = 1, totalNumGoals do
            local iconControl = entryControl.progressIconMetaPool:AcquireObject()
            iconControl:SetParent(entryControl.starsContainer)

            if numGoalsAchieved >= goalIndex then
                iconControl:SetTexture("EsoUI/Art/Antiquities/digsite_complete.dds")
            else
                iconControl:SetTexture("EsoUI/Art/Antiquities/digsite_unknown.dds")
            end
            if previousIcon then
                iconControl:SetAnchor(TOPLEFT, previousIcon, TOPRIGHT, 2)
            else
                iconControl:SetAnchor(LEFT, entryControl.starsContainer, LEFT)
            end
            previousIcon = iconControl
        end
    end

    local function ResetEntry(entryControl)
        entryControl.progressIconMetaPool:ReleaseAllObjects()
    end

    local NO_EQUALITY_FUNCTION = nil
    local NO_CONTROL_POOL_PREFIX = nil
    local NO_HEADER_SETUP_FUNCTION = nil
    self.list:AddDataTemplate("ZO_WorldMapAntiquitiesGamepadEntry", EntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, NO_EQUALITY_FUNCTION, NO_CONTROL_POOL_PREFIX, ResetEntry)
    self.list:AddDataTemplateWithHeader("ZO_WorldMapAntiquitiesGamepadEntry", EntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, NO_EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate", NO_HEADER_SETUP_FUNCTION, NO_CONTROL_POOL_PREFIX, ResetEntry)
    self.list:SetAlignToScreenCenter(true)
    self.list:SetOnSelectedDataChangedCallback(function() self:RefreshKeybinds() end)
end

function ZO_MapAntiquities_Gamepad:SetListEnabled(enabled)
    ZO_MapAntiquities_Shared.SetListEnabled(self, enabled)

    if enabled then
        if self:GetFragment():IsShowing() then
            self.list:Activate()
        end
        self.list:RefreshVisible()
    else
        self.list:Deactivate()
    end
end

function ZO_MapAntiquities_Gamepad:RefreshList()
    ZO_MapAntiquities_Shared.RefreshList(self)

    self.list:Clear()

    local antiquityEntries = self:GetSortedAntiquityEntries()

    local lastAntiquityCategory

    for i, antiquityEntry in ipairs(antiquityEntries) do
        local entryData = ZO_GamepadEntryData:New(antiquityEntry.antiquityData:GetColorizedFormattedName())
        entryData:SetDataSource(antiquityEntry.antiquityData)

        entryData.isTrackedAntiquity = antiquityEntry.isTracked

        if lastAntiquityCategory ~= antiquityEntry.antiquityCategory then
            entryData:SetHeader(GetString(ZO_MAP_ANTIQUITY_CATEGORY_TO_HEADER_STRING[antiquityEntry.antiquityCategory]))
            self.list:AddEntry("ZO_WorldMapAntiquitiesGamepadEntryWithHeader", entryData)
            lastAntiquityCategory = antiquityEntry.antiquityCategory
        else
            self.list:AddEntry("ZO_WorldMapAntiquitiesGamepadEntry", entryData)
        end
    end

    self.list:Commit()
end

function ZO_MapAntiquities_Gamepad:RefreshKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_MapAntiquities_Gamepad:InitializeKeybindDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Track antiquity
        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = GetString(SI_WORLD_MAP_ANTIQUITIES_TRACK),

            callback = function()
                local targetData = self.list:GetTargetData()
                local antiquityId = targetData:GetId()
                SetTrackedAntiquityId(antiquityId)
                WORLD_MAP_MANAGER:ShowAntiquityOnMap(antiquityId)
            end,

            visible = function()
                if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_DIG_SITES) then
                    return false
                end

                local targetData = self.list:GetTargetData()
                return targetData ~= nil and targetData:IsInProgress() and not targetData:IsTracked()
            end
        },
        -- Scry for antiquity
        {
            keybind = "UI_SHORTCUT_SECONDARY",

            name = GetString(SI_ANTIQUITY_SCRY),

            callback = function()
                local targetData = self.list:GetTargetData()
                SCENE_MANAGER:ShowBaseScene()
                ScryForAntiquity(targetData:GetId())
            end,

            visible = function()
                if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_DIG_SITES) then
                    return false
                end

                local targetData = self.list:GetTargetData()
                return targetData ~= nil and targetData:CanScry()
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, ZO_WorldMapInfo_OnBackPressed)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.list)
end

function ZO_MapAntiquities_Gamepad:OnShowing()
    ZO_MapAntiquities_Shared.OnShowing(self)

    if self:IsListEnabled() then
        self.list:Activate()
    end
    self.list:RefreshVisible()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_MapAntiquities_Gamepad:OnHidden()
    ZO_MapAntiquities_Shared.OnHidden(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.list:Deactivate()
end

--Global XML

function ZO_WorldMapAntiquitiesGamepadEntry_OnInitialize(control)
    control.label = control:GetNamedChild("Label")
    control.statusIndicator = control:GetNamedChild("StatusIndicator")
    control.starsContainer = control:GetNamedChild("Stars")
    control.GetHeight = function(control)
        local height = control.label:GetTextHeight() + control.starsContainer:GetHeight()
        return height
    end
end

function ZO_WorldMapAntiquities_Gamepad_OnInitialized(self)
    WORLD_MAP_ANTIQUITIES_GAMEPAD = ZO_MapAntiquities_Gamepad:New(self)
end