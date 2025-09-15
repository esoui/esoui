--------------------------------------------
-- Vengeance Perks Gamepad
--------------------------------------------

ZO_Vengeance_Perks_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_Vengeance_Perks_Gamepad:Initialize(control)
    GAMEPAD_VENGEANCE_PERKS_SCENE = ZO_Scene:New("gamepad_vengeance_perks", SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW, GAMEPAD_VENGEANCE_PERKS_SCENE)

    local vengeancePerksFragment = ZO_FadeSceneFragment:New(control)
    GAMEPAD_VENGEANCE_PERKS_SCENE:AddFragment(vengeancePerksFragment)

    self.headerData =
    {
        titleText = GetString(SI_CAMPAIGN_OVERVIEW_SUBCATEGORY_PERKS),

        messageText = function()
            if self:IsShowing() then
                local loadout = ZO_VENGEANCE_MANAGER:GetEquippedLoadoutData()
                return zo_strformat(SI_CAMPAIGN_VENGEANCE_PERKS_LOADOUT_HEADER, loadout:GetName())
            end
        end,
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self:InitializeLists()
end

function ZO_Vengeance_Perks_Gamepad:InitializeLists()
    local function PerkGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        control.icon:SetHidden(true)
        if self:GetCurrentList() == self.perksList then
            local NO_SLOT = nil
            control.perkIcon:SetPerkSlot(NO_SLOT)
        elseif self:GetCurrentList() == self.categoryList then
            control.perkIcon:SetPerkSlot(data.slot)
        end
        control.perkIcon:SetPerkData(data.dataSource)
        control.perkIconControl:SetHidden(false)
    end

    local function ApplyParametricScaling(control, parametricValue)
        local PERK_LIST_MAX_CONTROL_SCALE = 0.9
        local PERK_LIST_MIN_CONTROL_SCALE = 0.525
        control:SetScale(zo_lerp(PERK_LIST_MAX_CONTROL_SCALE, PERK_LIST_MIN_CONTROL_SCALE, parametricValue))
    end

    function PerkGamepadMenuEntryTemplateParametricListFunction(control, distanceFromCenter, continousParametricOffset)
        if control.perkIconControl then
            local parametricValue = zo_abs(zo_clamp(distanceFromCenter - continousParametricOffset, -1, 1))
            ApplyParametricScaling(control.perkIconControl, parametricValue)
        end
    end

    local USE_DEFAULT_COMPARISON = nil
    local NO_HEADER_SETUP_FUNCTION = nil
    self.categoryList = self:GetMainList()
    self.categoryList:AddDataTemplate("ZO_GamepadPerkSubMenuEntryWithStatusTemplate", PerkGamepadEntry_OnSetup, PerkGamepadMenuEntryTemplateParametricListFunction, USE_DEFAULT_COMPARISON, "ZO_PerkEntryWithStatus")
    self.categoryList:AddDataTemplateWithHeader("ZO_GamepadPerkSubMenuEntryWithStatusTemplate", PerkGamepadEntry_OnSetup, PerkGamepadMenuEntryTemplateParametricListFunction, USE_DEFAULT_COMPARISON, "ZO_GamepadMenuEntryHeaderTemplate", NO_HEADER_SETUP_FUNCTION, "ZO_PerkEntryWithStatus")
    self.categoryList.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedCategory = self.categoryList:GetTargetData()
                if selectedCategory then
                    local RESET_TO_TOP = true
                    self.currentlySelectedPerkSlot = selectedCategory.slot
                    self:ShowPerksList(self.currentlySelectedPerkSlot, RESET_TO_TOP)
                end
            end,
            enabled = function()
                return ZO_VENGEANCE_MANAGER:IsEquippedLoadoutEditableForCurrentZone()
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }

    local function CategoryListBackNavigationCallback()
        GAMEPAD_AVA_BROWSER:SetFromVengeanceScreenIndex(ZO_VENGEANCE_SCREEN_GAMEPAD_INDEX.PERKS)
        SCENE_MANAGER:HideCurrentScene()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryList.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, CategoryListBackNavigationCallback)

    self.perksList = self:AddList("perks")
    self.perksList:AddDataTemplate("ZO_GamepadPerkSubMenuEntryWithStatusTemplate", PerkGamepadEntry_OnSetup, PerkGamepadMenuEntryTemplateParametricListFunction, USE_DEFAULT_COMPARISON, "ZO_PerkEntryWithStatus")
    self.perksList:AddDataTemplateWithHeader("ZO_GamepadPerkSubMenuEntryWithStatusTemplate", PerkGamepadEntry_OnSetup, PerkGamepadMenuEntryTemplateParametricListFunction, USE_DEFAULT_COMPARISON, "ZO_GamepadMenuEntryHeaderTemplate", NO_HEADER_SETUP_FUNCTION, "ZO_PerkEntryWithStatus")
    self.perksList.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Equip/Unequip
        {
            name = function()
                local selectedPerk = self.perksList:GetTargetData()
                if selectedPerk:IsPerkEquipped() then
                    return GetString(SI_CAMPAIGN_VENGEANCE_PERK_DESELECT)
                else
                    return GetString(SI_CAMPAIGN_VENGEANCE_PERK_SELECT)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedPerk = self.perksList:GetTargetData()
                if selectedPerk:IsPerkEquipped() then
                    ZO_VENGEANCE_MANAGER:ClearEquippedPerk(selectedPerk)
                else
                    ZO_VENGEANCE_MANAGER:SetEquippedPerk(selectedPerk)
                end
            end,
            enabled = function()
                local selectedPerk = self.perksList:GetTargetData()
                local canEquip, result = selectedPerk:CanEquipPerk()
                return canEquip or result == VENGEANCE_ACTION_RESULT_PERK_ALREADY_EQUIPPED, GetString("SI_VENGEANCEACTIONRESULT", result)
            end,
            visible = function()
                local selectedPerk = self.perksList:GetTargetData()
                return selectedPerk ~= nil
            end,
        },
    }

    local function PerksListBackNavigationCallback()
        -- Order matters
        self:ShowCategoryList()
        self:RefreshTooltips()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.perksList.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, PerksListBackNavigationCallback)

    local function OnPerkSelectionChanged()
        if self:IsShowing() then
            self:RefreshCategories()
            if self:GetCurrentList() == self.perksList and self.currentlySelectedPerkSlot then
                self:RefreshPerks(self.currentlySelectedPerkSlot)
            end
        end
    end

    ZO_VENGEANCE_MANAGER:RegisterCallback("OnPerkSelectionChanged", OnPerkSelectionChanged)

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_Vengeance_Perks_Gamepad:RefreshCategories(resetSelectionToTop)
    -- Add the category entries.
    self.categoryList:Clear()

    local SLOTS =
    {
        VENGEANCE_PERK_SLOT_RED,
        VENGEANCE_PERK_SLOT_YELLOW,
        VENGEANCE_PERK_SLOT_BLUE,
    }

    local loadoutData = ZO_VENGEANCE_MANAGER:GetEquippedLoadoutData()
    for _, slot in ipairs(SLOTS) do
        local perkData = ZO_VENGEANCE_MANAGER:GetEquippedPerkDataBySlot(slot)
        local perkName
        local perkIcon
        if perkData then
            perkName = perkData:GetName()
            perkIcon = perkData:GetIcon()
        else
            perkName = ZO_VENGEANCE_MANAGER:GetEmptyPerkName()
            perkIcon = ZO_VENGEANCE_MANAGER:GetEmptyPerkIconBySlot(slot)
        end
        local entryData = ZO_GamepadEntryData:New(perkName, perkIcon)
        entryData:SetDataSource(perkData)
        entryData.slot = slot

        self.categoryList:AddEntry("ZO_GamepadPerkSubMenuEntryWithStatusTemplate", entryData)
    end

    self.categoryList:Commit(resetSelectionToTop)
end

function ZO_Vengeance_Perks_Gamepad:RefreshPerks(slot, resetSelectionToTop)
    -- Add the perk entries.
    self.perksList:Clear()

    local filterFunction = function(data)
        return data:GetSlot() == slot
    end

    for _, perkData in ZO_VENGEANCE_MANAGER:PerkDataIterator({ filterFunction }) do
        local perkName = perkData:GetName()
        local perkIcon = perkData:GetIcon()
        local entryData = ZO_GamepadEntryData:New(perkName, perkIcon)
        entryData:SetDataSource(perkData)
        entryData.disabled = perkData:IsPerkDisabled()
        entryData.isSelected = perkData:IsPerkEquipped()
        if perkData:GetSlotIndex() == 1 then
            entryData:SetHeader(ZO_VENGEANCE_MANAGER:GetPerkSlotName(perkData:GetSlot()))
            self.perksList:AddEntryWithHeader("ZO_GamepadPerkSubMenuEntryWithStatusTemplate", entryData)
        else
            self.perksList:AddEntry("ZO_GamepadPerkSubMenuEntryWithStatusTemplate", entryData)
        end
    end

    self.perksList:Commit(resetSelectionToTop)
end

function ZO_Vengeance_Perks_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    TriggerTutorial(TUTORIAL_TRIGGER_VENGEANCE_PERKS_OPENED)

    self:ShowCategoryList()
end

function ZO_Vengeance_Perks_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Screen.OnHiding(self)

    self.currentlySelectedPerkSlot = nil
    self:HideTooltips()
    self:RemoveCurrentListKeybinds()
end

function ZO_Vengeance_Perks_Gamepad:RefreshKeybinds()
    ZO_Gamepad_ParametricList_Screen.RefreshKeybinds(self)
    local currentList = self:GetCurrentList()
    if currentList and currentList.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(currentList.keybindStripDescriptor)
    end
end

-- Static
function ZO_Vengeance_Perks_Gamepad.ShowEquippedPerkTooltipForSlot(tooltip, slot)
    local equippedPerkData = ZO_VENGEANCE_MANAGER:GetEquippedPerkDataBySlot(slot)
    if equippedPerkData then
        GAMEPAD_TOOLTIPS:LayoutPerkTooltip(tooltip, equippedPerkData, slot)
        GAMEPAD_TOOLTIPS:SetStatusLabelText(tooltip, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER))
    else
        GAMEPAD_TOOLTIPS:ClearLines(tooltip)
    end
end

function ZO_Vengeance_Perks_Gamepad:RefreshTooltips()
    if self:GetCurrentList() == self.perksList and self.currentlySelectedPerkSlot then
        local slot = self.currentlySelectedPerkSlot

        local selectedPerkData = self.perksList:GetTargetData()
        if selectedPerkData then
            GAMEPAD_TOOLTIPS:LayoutPerkTooltip(GAMEPAD_LEFT_TOOLTIP, selectedPerkData, slot)

            if selectedPerkData:IsPerkEquipped() then
                GAMEPAD_TOOLTIPS:SetStatusLabelText(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER))
            else
                GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_TOOLTIP)
            end
        end

        ZO_Vengeance_Perks_Gamepad.ShowEquippedPerkTooltipForSlot(GAMEPAD_RIGHT_TOOLTIP, slot)
    elseif self:GetCurrentList() == self.categoryList then
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)

        local selectedCategory = self.categoryList:GetTargetData()
        if selectedCategory then
            local slot = selectedCategory.slot
            ZO_Vengeance_Perks_Gamepad.ShowEquippedPerkTooltipForSlot(GAMEPAD_LEFT_TOOLTIP, slot)
            ZO_Vengeance_Perks_Gamepad.ShowEquippedPerkTooltipForSlot(GAMEPAD_RIGHT_TOOLTIP, slot)
        end
    else
        self:HideTooltips()
    end
end

function ZO_Vengeance_Perks_Gamepad:HideTooltips()
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_Vengeance_Perks_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    self:RefreshTooltips()
end

function ZO_Vengeance_Perks_Gamepad:RemoveCurrentListKeybinds()
    local currentList = self:GetCurrentList()
    if currentList and currentList.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(currentList.keybindStripDescriptor)
    end
end

function ZO_Vengeance_Perks_Gamepad:ShowCategoryList()
    self:RemoveCurrentListKeybinds()
    self:RefreshCategories()
    self.currentlySelectedPerkSlot = nil
    self:SetCurrentList(self.categoryList)
    self.categoryList:RefreshVisible()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.categoryList.keybindStripDescriptor)
end

function ZO_Vengeance_Perks_Gamepad:ShowPerksList(slot, resetToTop)
    self:RemoveCurrentListKeybinds()
    self:RefreshPerks(slot, resetToTop)
    self.currentlySelectedPerkSlot = slot
    self:SetCurrentList(self.perksList)
    self.perksList:RefreshVisible()
    self:RefreshTooltips()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.perksList.keybindStripDescriptor)
end

function ZO_Vengeance_Perks_Gamepad:PerformUpdate()
    -- Required override
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_Vengeance_Perks_Gamepad.OnControlInitialized(control)
    VENGEANCE_PERKS_GAMEPAD = ZO_Vengeance_Perks_Gamepad:New(control)
end

function ZO_Vengeance_Perks_Gamepad.OnMenuEntryInitialized(control)
    control.perkIconControl = control:GetNamedChild("FramedIcon")
    control.perkIcon = control.perkIconControl.object
end