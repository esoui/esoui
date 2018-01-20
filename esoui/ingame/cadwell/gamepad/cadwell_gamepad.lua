local ZO_CadwellManager_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_CadwellManager_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_CadwellManager_Gamepad:Initialize(control)
    CADWELLS_ALMANAC_GAMEPAD_SCENE = ZO_Scene:New("cadwellGamepad", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, nil, CADWELLS_ALMANAC_GAMEPAD_SCENE)
    self.itemList = self:GetMainList()

    self.headerData = {
        titleText = GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_CADWELL),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_CadwellManager_Gamepad:OnDeferredInitialize()
    ZO_Gamepad_ParametricList_Screen.OnDeferredInitialize(self)

    local middleSection = self.control:GetNamedChild("Middle")
    self.entryHeader = middleSection:GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.entryHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
    self.entryBody = middleSection:GetNamedChild("Body")

    self.entryHeaderData = {
        titleText = "",
    }

    local function OnCadwellProgressionLevelChanged()
        self:Update()
    end

    local function OnPOIUpdated()
        if GetCadwellProgressionLevel() > CADWELL_PROGRESSION_LEVEL_BRONZE then
            self:Update()
            -- NOTE: self:Update() will implicitly call self:RefreshEntryHeaderDescriptionAndObjectives() when it rebuilds the list,
            --  as such, there is no need to refresh the details directly here, which simplifies the logic.
        end
    end

    self.control:RegisterForEvent(EVENT_POI_UPDATED, OnPOIUpdated)
    self.control:RegisterForEvent(EVENT_CADWELL_PROGRESSION_LEVEL_CHANGED, OnCadwellProgressionLevelChanged)
end

function ZO_CadwellManager_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetMainList())
end

function ZO_CadwellManager_Gamepad:OnShowing()
    self:PerformUpdate()
end

function ZO_CadwellManager_Gamepad:OnHide(...)
    ZO_Gamepad_ParametricList_Screen.OnHide(self, ...)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_CadwellManager_Gamepad:PerformUpdate()
    self.itemList:Clear()

    for progressionLevel = CADWELL_PROGRESSION_LEVEL_SILVER, CADWELL_PROGRESSION_LEVEL_GOLD do
        if GetCadwellProgressionLevel() < progressionLevel then
            break
        end

        local zones = {}
        for zoneIndex = 1, GetNumZonesForCadwellProgressionLevel(progressionLevel) do
            local zoneName, zoneDescription, zoneOrder = GetCadwellZoneInfo(progressionLevel, zoneIndex)
            local numObjectives = GetNumPOIsForCadwellProgressionLevelAndZone(progressionLevel, zoneIndex)
            local numCompletedObjectives = 0

            for objectiveIndex = 1, GetNumPOIsForCadwellProgressionLevelAndZone(progressionLevel, zoneIndex) do
                local completed = select(6, GetCadwellZonePOIInfo(progressionLevel, zoneIndex, objectiveIndex))
                if completed then
                    numCompletedObjectives = numCompletedObjectives + 1
                end
            end

            table.insert(zones, {progressionLevel = progressionLevel, name = zoneName, description = zoneDescription, order = zoneOrder, numObjectives = numObjectives, numCompletedObjectives = numCompletedObjectives, index = zoneIndex})
        end

        table.sort(zones, ZO_CadwellSort)

        for zoneIndex = 1, #zones do
            local zoneInfo = zones[zoneIndex]
            
            local entryData = ZO_GamepadEntryData:New(zo_strformat(SI_CADWELL_ZONE_NAME_FORMAT, zoneInfo.name))
            entryData.zoneInfo = zoneInfo

            local template
            if zoneIndex == 1 then
                -- TODO: Do they want the icons in here somehow?
                --local down, up, over = GetIconsForCadwellProgressionLevel(progressionLevel)
                entryData:SetHeader(GetString("SI_CADWELLPROGRESSIONLEVEL", progressionLevel))
                template = "ZO_GamepadMenuEntryTemplateWithHeader"
            else
                template = "ZO_GamepadMenuEntryTemplate"
            end

            self.itemList:AddEntry(template, entryData)
        end
    end

    self.itemList:Commit()
end

function ZO_CadwellManager_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    self:RefreshEntryHeaderDescriptionAndObjectives()
end

function ZO_CadwellManager_Gamepad:RefreshEntryHeaderDescriptionAndObjectives()
    local targetData = self.itemList:GetTargetData()

    if not targetData then
        self.entryName:SetText("")
        return
    end

    local zoneInfo = targetData.zoneInfo

    local progressionLevel = zoneInfo.progressionLevel
    local zoneIndex = zoneInfo.index
    local numObjectives = zoneInfo.numObjectives
    local numCompletedObjectives = zoneInfo.numCompletedObjectives

    local zoneName, zoneDescription = GetCadwellZoneInfo(progressionLevel, zoneIndex)
    self.entryBody:SetText(zo_strformat(SI_CADWELL_ZONE_DESC_FORMAT, zoneDescription))
    
    self.entryHeaderData.titleText = zo_strformat(SI_CADWELL_ZONE_NAME_FORMAT, zoneName)

    ZO_GamepadGenericHeader_Refresh(self.entryHeader, self.entryHeaderData)

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:LayoutCadwells(GAMEPAD_RIGHT_TOOLTIP, progressionLevel, zoneIndex)
end

function ZO_Cadwell_Gamepad_OnInitialize(control)
    CADWELLS_ALMANAC_GAMEPAD = ZO_CadwellManager_Gamepad:New(control)
end
