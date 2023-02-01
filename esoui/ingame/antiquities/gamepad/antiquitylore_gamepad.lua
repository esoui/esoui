ZO_AntiquityLoreGamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_AntiquityLoreGamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_AntiquityLoreGamepad:Initialize(control)
    self:InitializeControls(control)
    self:InitializeList()
    self:InitializeHeader()
    self:InitializeEvents()
end

function ZO_AntiquityLoreGamepad:InitializeControls(control)
    self.loreEntryControlData = {}

    ANTIQUITY_LORE_SCENE_GAMEPAD = ZO_Scene:New("gamepad_antiquity_lore", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, ACTIVATE_ON_SHOW, ANTIQUITY_LORE_SCENE_GAMEPAD)

    self.fragment = ZO_SimpleSceneFragment:New(self.control)
    ZO_ANTIQUITY_LORE_GAMEPAD_FRAGMENT = self.fragment
    self.fragment:SetHideOnSceneHidden(true)
    self.scene:AddFragment(self.fragment)

    self.loreEntries = self.control:GetNamedChild("LoreEntries")
    self.loreEntryScroll = self.loreEntries:GetNamedChild("Scroll")
    self.loreEntryScroll:SetScrollBounding(SCROLL_BOUNDING_UNBOUND)
    self.loreEntryScrollChild = self.loreEntryScroll:GetNamedChild("ScrollChild")
end

function ZO_AntiquityLoreGamepad:InitializeList()
    self.loreList = self:GetMainList()
    self.loreList:SetPlaySoundFunction(function() PlaySound(SOUNDS.BOOK_PAGE_TURN) end)
end

function ZO_AntiquityLoreGamepad:InitializeHeader()
    self.headerData =
    {
        titleText = GetString(SI_JOURNAL_MENU_ANTIQUITIES),
        messageText = "",
    }
    ZO_GamepadGenericHeader_SetDataLayout(self.header, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE)
end

function ZO_AntiquityLoreGamepad:InitializeKeybindStripDescriptors()
    local function OnClickCallback()
        if self.fromFanfare then
            SYSTEMS:GetObject("mainMenu"):ShowAntiquityInJournal(self.currentAntiquityOrSetData)
            self.fromFanfare = false
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end

    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnClickCallback)
    self:SetListsUseTriggerKeybinds(true)
end

function ZO_AntiquityLoreGamepad:InitializeEvents()
    local function OnAntiquitiesUpdated()
        self:Refresh()
    end

    ANTIQUITY_DATA_MANAGER:RegisterCallback("AntiquitiesUpdated", OnAntiquitiesUpdated)
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityUpdated", OnAntiquitiesUpdated)
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityDigSitesUpdated", OnAntiquitiesUpdated)
end

function ZO_AntiquityLoreGamepad:SetFromFanfare(value)
    self.fromFanfare = value
end

function ZO_AntiquityLoreGamepad:PerformUpdate()
    self:RefreshLoreList()
    self:EnableCurrentList()
    self.dirty = false
end

function ZO_AntiquityLoreGamepad:OnTargetChanged(list, targetData, oldTargetData, reachedTarget, targetSelectedIndex)
    self:RefreshLoreEntries()
end

function ZO_AntiquityLoreGamepad:ShowAntiquityOrSet(antiquityOrSetData, pushScene)
    self.dirty = true
    self.currentAntiquityOrSetData = antiquityOrSetData

    if pushScene then
        SCENE_MANAGER:Push("gamepad_antiquity_lore")
    else
        SCENE_MANAGER:Show("gamepad_antiquity_lore")
    end
end

function ZO_AntiquityLoreGamepad:Refresh()
    -- Because the data manager might need to cpompletely rebuild, we need to get the new reference for the data (our old reference might be outdated)
    if self.currentAntiquityOrSetData and not self.fragment:IsHidden() then
        if self.currentAntiquityOrSetData:GetType() == ZO_ANTIQUITY_TYPE_INDIVIDUAL then
            self.currentAntiquityOrSetData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(self.currentAntiquityOrSetData:GetId())
        else
            self.currentAntiquityOrSetData = ANTIQUITY_DATA_MANAGER:GetAntiquitySetData(self.currentAntiquityOrSetData:GetId())
        end

        if self.currentAntiquityOrSetData then
            self:RefreshLoreList()
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end
end

function ZO_AntiquityLoreGamepad:ReleaseAllLoreEntryControls()
    ZO_ClearNumericallyIndexedTable(self.loreEntryControlData)
    ANTIQUITY_LORE_DOCUMENT_MANAGER:ReleaseAllObjects(self.loreEntryScrollChild)
    self.currentLoreEntryControl = nil
end

function ZO_AntiquityLoreGamepad:RefreshHeader()
    local antiquityOrSetData = self.currentAntiquityOrSetData
    self.headerData.titleText = antiquityOrSetData:GetColorizedFormattedName()
    self.headerData.messageText = zo_strformat(SI_ANTIQUITY_CODEX_ENTRIES_FOUND, antiquityOrSetData:GetNumUnlockedLoreEntries(), antiquityOrSetData:GetNumLoreEntries())
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

do
    local function GetLoreEntryNarrationText(entryData, entryControl)
        local narrations = {}
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        --If the entry is unlocked, get the narration for the lore
        if entryData.unlocked then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.description))
        end
        return narrations
    end

    function ZO_AntiquityLoreGamepad:RefreshLoreList()
        local antiquityOrSetData = self.currentAntiquityOrSetData
        self.loreList:Clear()
        self:ReleaseAllLoreEntryControls()

        if antiquityOrSetData then
            local numEntries = antiquityOrSetData:GetNumLoreEntries()
            local numUnlockedEntries = antiquityOrSetData:GetNumUnlockedLoreEntries()
            local controlIndex = 1
            local previousControl

            for _, loreEntryData in ipairs(antiquityOrSetData:GetLoreEntries()) do
                local entryTitle = loreEntryData.displayName
                local iconTexture = loreEntryData.unlocked and ZO_CHECK_ICON or nil
                local entryData = ZO_GamepadEntryData:New(entryTitle, iconTexture)

                if loreEntryData.fragmentName then
                    entryData:AddSubLabels({ ZO_CachedStrFormat(SI_ANTIQUITY_NAME_FORMATTER, loreEntryData.fragmentName) })
                    entryData:SetSubLabelColors(ZO_NORMAL_TEXT)
                end

                entryData.narrationText = GetLoreEntryNarrationText
                entryData:SetDataSource(loreEntryData)
                entryData:SetIconTintOnSelection(true)
                self.loreList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)

                previousControl = self:AddLoreEntry(previousControl, controlIndex, entryData)
                controlIndex = controlIndex + 1
            end

            self:RefreshHeader()
        end

        self.loreList:Commit()
        self:RefreshLoreEntries()
    end
end

function ZO_AntiquityLoreGamepad:RefreshLoreEntries()
    local targetData = self:GetCurrentList():GetTargetData()
    if targetData then
        local currentControl = self.currentLoreEntryControl
        local scrollControl = self.loreEntryScroll
        local scrollHeight = scrollControl:GetHeight()
        local currentHorizonalScrollOffset, currentVerticalScrollOffset = scrollControl:GetScrollOffsets()
        local targetControl

        if currentControl then
            currentControl.highlightAnimation:PlayBackward()
        end

        local loreEntryControl = self.loreEntryControlData[targetData]
        if loreEntryControl then
            -- Scroll the selected lore entry to the center of the scroll control's view.
            local controlOffset = loreEntryControl:GetTop()
            local controlHeight = loreEntryControl:GetHeight()
            local targetOffset = currentVerticalScrollOffset + controlOffset - 0.5 * (scrollHeight - controlHeight)
            scrollControl:SetVerticalScroll(targetOffset)
            targetControl = loreEntryControl
        end

        self.currentLoreEntryControl = targetControl
        if targetControl then
            targetControl.highlightAnimation:PlayForward()
        end
    end
end

function ZO_AntiquityLoreGamepad:AddLoreEntry(previousControl, controlIndex, entryData)
    local loreEntryControl = ANTIQUITY_LORE_DOCUMENT_MANAGER:AcquireWideDocumentForLoreEntry(self.loreEntryScrollChild, entryData.antiquityId, entryData.loreEntryIndex)

    self.loreEntryControlData[entryData] = loreEntryControl

    -- Anchor lore entries back-and-forth (left, right, left, etc.) pattern.
    loreEntryControl:ClearAnchors()
    if controlIndex == 1 then
        loreEntryControl:SetAnchor(TOP, nil, nil, -20)
    else
        local offsetX
        if controlIndex % 2 == 0 then
            offsetX = 50
        else
            offsetX = -50
        end
        loreEntryControl:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, offsetX, -64)
    end
    loreEntryControl:SetHidden(false)
    loreEntryControl.highlightAnimation:PlayBackward()

    return loreEntryControl
end

-- Global UI

function ZO_AntiquityLoreTopLevel_Gamepad_OnInitialized(control)
    ANTIQUITY_LORE_GAMEPAD = ZO_AntiquityLoreGamepad:New(control)
end
