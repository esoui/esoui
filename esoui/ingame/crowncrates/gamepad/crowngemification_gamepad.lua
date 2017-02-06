ZO_CrownGemification_Gamepad = ZO_CrownGemification_Shared:Subclass()

function ZO_CrownGemification_Gamepad:New(...)
    return ZO_CrownGemification_Shared.New(self, ...)
end

function ZO_CrownGemification_Gamepad:Initialize(owner, gemificationSlot)
    self.owner = owner
    self.gemificationSlot = gemificationSlot
    local control = ZO_CrownGemification_GamepadTopLevel
    self.control = control
    self.fragment = ZO_SimpleSceneFragment:New(control)
    self:InitializeKeybindStrip()

    local backKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_BACK_OPTION),
        keybind = "UI_SHORTCUT_NEGATIVE",
        callback = function()
            self:RemoveFromScene()
        end,
    }
    ZO_CrownGemification_Shared.Initialize(self, self.fragment, gemificationSlot, backKeybindStripDescriptor)

    self.formattedGemIcon = ZO_Currency_GetGamepadFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(MKCT_CROWN_GEMS), "100%")

    self:InitializeHeader()
    self:InitializeList()
    self:InitializeKeybindStrip()
end

function ZO_CrownGemification_Gamepad:OnShowing()
    ZO_CrownGemification_Shared.OnShowing(self)
    self.list:Activate()
    local selectedData = self.list:GetSelectedData()
    if selectedData then
        self.gemificationSlot:SetGemifiable(selectedData.gemifiable)
        selectedData.gemifiable:LayoutGamepadTooltip()
    end
    KEYBIND_STRIP:AddKeybindButtonGroup(self.listKeybindStripDescriptor, self.keybindStripId)
end

function ZO_CrownGemification_Gamepad:OnHidden()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.listKeybindStripDescriptor, self.keybindStripId)
    ZO_CrownGemification_Shared.OnHidden(self)
    self.list:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_CrownGemification_Gamepad:InitializeHeader()
    self.headerControl = self.control:GetNamedChild("MaskContainerHeaderContainerHeader")
    ZO_GamepadGenericHeader_Initialize(self.headerControl, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    local headerData =
    {
        titleText = GetString(SI_GEMIFICATION_TITLE),
    }
    ZO_GamepadGenericHeader_RefreshData(self.headerControl, headerData)
end

function ZO_CrownGemification_Gamepad:InitializeKeybindStrip()
    self.listKeybindStripDescriptor =
    {
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.listKeybindStripDescriptor, self.list)
end

function ZO_CrownGemification_Gamepad:InitializeList()
    self.listControl = self.control:GetNamedChild("MaskContainerGemifiablesList")
    self.list = ZO_GamepadVerticalItemParametricScrollList:New(self.listControl)
    local function EntryEquality(a, b)
        return a.name == b.name
    end
    self.list:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, EntryEquality)
    self.list:SetOnTargetDataChangedCallback(function(...) self:OnTargetDataChanged(...) end)
    self.list:SetAlignToScreenCenter(true)
    self.emptyTextLabel = self.control:GetNamedChild("MaskContainerGemifiablesEmptyText")
end

function ZO_CrownGemification_Gamepad:OnTargetDataChanged(list, targetData)
    if targetData then
        local gemifiable = targetData.gemifiable
        gemifiable:LayoutGamepadTooltip()
        self.gemificationSlot:SetGemifiable(gemifiable)
    else
        self.gemificationSlot:SetGemifiable(nil)
    end
end

--Crown Gemification Shared Overrides

function ZO_CrownGemification_Gamepad:InsertIntoScene()
    SCENE_MANAGER:AddFragment(self.fragment)
    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_1_INSTANT_BACKGROUND_FRAGMENT)
    SCENE_MANAGER:AddFragment(CROWN_CRATES_GEMIFICATION_WINDOW_SOUNDS)
end

function ZO_CrownGemification_Gamepad:RemoveFromScene()
    SCENE_MANAGER:RemoveFragment(self.fragment)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_1_INSTANT_BACKGROUND_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(CROWN_CRATES_GEMIFICATION_WINDOW_SOUNDS)
end

function ZO_CrownGemification_Gamepad:RefreshEntryFromGemifiable(dataEntry, gemifiable)
    dataEntry.gemifiable = gemifiable
    dataEntry:SetStackCount(gemifiable.count)
    dataEntry:ClearSubLabels()
    if gemifiable.maxGemifies > 0 then
        dataEntry:SetIconTint(ZO_WHITE, ZO_WHITE)
        dataEntry:AddSubLabel(zo_strformat(SI_GAMEPAD_GEMIFICATION_GEM_TOTAL_LABEL, gemifiable.gemTotal, self.formattedGemIcon))
        dataEntry:SetSubLabelColors(ZO_WHITE, ZO_WHITE)
    else
        dataEntry:SetIconTint(ZO_ERROR_COLOR, ZO_ERROR_COLOR)
        dataEntry:AddSubLabel(zo_strformat(SI_GEMIFICATION_TOO_FEW_TO_EXTRACT, gemifiable.requiredPerConversion, gemifiable.name))
        dataEntry:SetSubLabelColors(ZO_ERROR_COLOR, ZO_ERROR_COLOR)
    end
end

function ZO_CrownGemification_Gamepad:RefreshList()
    ZO_CrownGemification_Shared.RefreshList(self)

    self.list:Clear()
    local masterList = CROWN_GEMIFICATION_MANAGER:GetGemifiableList()
    for _, gemifiable in ipairs(masterList) do
        local dataEntry = ZO_GamepadEntryData:New(gemifiable.name, gemifiable.icon)
        self:RefreshEntryFromGemifiable(dataEntry, gemifiable)
        self.list:AddEntry("ZO_GamepadItemSubEntryTemplate", dataEntry)
    end
    self.list:Commit()

    local numEntries = #masterList
    self.emptyTextLabel:SetHidden(numEntries > 0)
    if numEntries == 0 then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end 
end

function ZO_CrownGemification_Gamepad:RefreshGemifiable(gemifiable)
    ZO_CrownGemification_Shared.RefreshGemifiable(self, gemifiable)

    for i = 1, self.list:GetNumEntries() do
        local dataEntry = self.list:GetEntryData(i)
        if dataEntry.gemifiable == gemifiable then
            self:RefreshEntryFromGemifiable(dataEntry, gemifiable)
            break
        end
    end

    self.list:RefreshVisible()
end

--End Crown Gemification Shared Overrides