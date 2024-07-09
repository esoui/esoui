ZO_ScribingLayout_Gamepad = ZO_Gamepad_ParametricList_Search_Screen:Subclass()

function ZO_ScribingLayout_Gamepad:Initialize(control, createTabBar, activateOnShow, scene)
    self.control = control

    ZO_Gamepad_ParametricList_Search_Screen.Initialize(self, BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_ID, "craftedAbilityTextSearch", control, createTabBar, activateOnShow, scene)
end

function ZO_ScribingLayout_Gamepad:InitializeLists()
    local DEFAULT_EQUALITY_FUNCTION = nil
    local DEFAULT_HEADER_SETUP_FUNCTION = nil

    self.craftedAbilityList = self:AddList("craftedAbilityList")
    self.craftedAbilityList:AddDataTemplate("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.craftedAbilityList:AddDataTemplate("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.craftedAbilityList:AddDataTemplate("ZO_GamepadSubMenuEntryTemplateWithStatus", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "CraftedAbilityEntry")
    self.craftedAbilityList:AddDataTemplateWithHeader("ZO_GamepadSubMenuEntryTemplateWithStatus", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate", DEFAULT_HEADER_SETUP_FUNCTION, "CraftedAbilityEntryWithHeader")

    local function CompareScriptEntries(leftData, rightData)
        local leftScriptData = leftData.data
        local rightScriptData = rightData.data
        if leftScriptData and rightScriptData then
            return leftScriptData:GetId() == rightScriptData:GetId()
        end
        return false
    end

    self.scriptsList = self:AddList("scriptsList")
    self.scriptsList:AddDataTemplate("ZO_GamepadSubMenuEntryTemplateWithStatus", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, CompareScriptEntries, "CraftedAbilityScriptEntry")
    self.scriptsList:AddDataTemplateWithHeader("ZO_GamepadSubMenuEntryTemplateWithStatus", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, CompareScriptEntries, "ZO_GamepadMenuEntryHeaderTemplate", DEFAULT_HEADER_SETUP_FUNCTION, "CraftedAbilityScriptEntryWithHeader")
    self.scriptsList:AddDataTemplateWithHeader("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, CompareScriptEntries, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_ScribingLayout_Gamepad:RefreshHeader()
    -- To be overridden
end

function ZO_ScribingLayout_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Search_Screen.OnHide(self)

    ResetCraftedAbilityScriptSelectionOverride()
end

function ZO_ScribingLayout_Gamepad:ShowCraftedAbilities(resetToTop)
    self:SetSearchCriteria(BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_ID, "craftedAbilityTextSearch")
    SCRIBING_MANAGER:SetScriptSearchCraftedAbility(nil)
    self:SetCurrentList(self.craftedAbilityList)
    -- Default hidden value of search text entry before calling refresh which may update the hidden state
    self:SetTextSearchEntryHidden(false)
    self:RefreshCraftedAbilityList(resetToTop)
    self:RefreshHeader()
end

function ZO_ScribingLayout_Gamepad:GetCraftedAbilityDisabledNameColors()
    return ZO_GAMEPAD_DISABLED_SELECTED_COLOR, ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR
end

function ZO_ScribingLayout_Gamepad:RefreshCraftedAbilityList(resetToTop, appendToList)
    if appendToList ~= true then
        self.craftedAbilityList:Clear()
    end

    local currentHeader = nil
    local craftedAbilities = self:GetCraftedAbilityList()
    local selectedErrorColor, unselectedErrorColor = self:GetCraftedAbilityDisabledNameColors()
    for i, craftedAbilityData in ipairs(craftedAbilities) do
        if self:IsDataInSearchTextResults(craftedAbilityData:GetId()) then
            local headerText = GetString("SI_SKILLTYPE", craftedAbilityData:GetSkillType())
            if not craftedAbilityData:IsDisabled() then
                local entryData = ZO_GamepadEntryData:New(craftedAbilityData:GetFormattedName(), craftedAbilityData:GetIcon())
                entryData.data = craftedAbilityData
                entryData:SetIconTintOnSelection(true)
                entryData:SetIconDisabledTintOnSelection(true)
                entryData:SetDisabledNameColors(selectedErrorColor, unselectedErrorColor)
                entryData:SetEnabled(craftedAbilityData:IsUnlocked())
                if not craftedAbilityData:IsUnlocked() then
                    entryData:SetIconDesaturation(0.8)
                    entryData:SetMaxIconAlpha(0.8)
                else
                    entryData:SetIconDesaturation(0)
                    entryData:SetMaxIconAlpha(1)
                end

                if craftedAbilityData:IsSlottedOnHotBar() then
                    entryData.overrideStatusIndicatorIcons = { ZO_IS_CRAFTED_ABILITY_ON_HOT_BAR_STATUS_ICON_OVERRIDE }
                end
                if currentHeader ~= headerText then
                    entryData:SetHeader(headerText)
                    self.craftedAbilityList:AddEntryWithHeader("ZO_GamepadSubMenuEntryTemplateWithStatus", entryData)
                    currentHeader = headerText
                else
                    self.craftedAbilityList:AddEntry("ZO_GamepadSubMenuEntryTemplateWithStatus", entryData)
                end
            end
        end
    end

    self.craftedAbilityList:Commit(resetToTop)

    if self.craftedAbilityList:GetNumItems() == 0 then
        self.craftedAbilityList:SetNoItemText(GetString(SI_CRAFTED_ABILITIES_ERROR_FILTER_EMPTY))
        self:RequestEnterHeader()
    end
end

function ZO_ScribingLayout_Gamepad:GetCraftedAbilityList()
    return SCRIBING_DATA_MANAGER:GetSortedBySkillTypeUnlockedCraftedAbilityData()
end

function ZO_ScribingLayout_Gamepad:ShowScripts()
    if self:IsCraftedAbilitySelected() then
        self:SetSearchCriteria(BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_SCRIPT_ID, "craftedAbilityScriptsTextSearch")
        SCRIBING_MANAGER:SetScriptSearchCraftedAbility(self:GetSelectedCraftedAbilityData():GetId())
        self:SetCurrentList(self.scriptsList)

        local RESET_TO_TOP = true
        self:RefreshScriptsList(RESET_TO_TOP)
        self:RefreshHeader()
    end
end

function ZO_ScribingLayout_Gamepad:GetScriptLockedNameColors()
    return ZO_GAMEPAD_DISABLED_SELECTED_COLOR, ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR
end

function ZO_ScribingLayout_Gamepad:GetScriptIncompatibleNameColors()
    return ZO_ERROR_COLOR, ZO_ERROR_COLOR:GetDim()
end

function ZO_ScribingLayout_Gamepad:RefreshScriptsList(resetToTop)
    if self:IsCraftedAbilitySelected() then
        self.scriptsList:Clear()
        local craftedAbilityData = self:GetSelectedCraftedAbilityData()
        local currentHeader = nil
        for scribingSlot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
            local isAnyScriptUnderHeader = false
            local headerText = GetString("SI_SCRIBINGSLOT", scribingSlot)
            local scriptIds = self:GetScriptIdsForSlot(scribingSlot)
            for i, scriptId in ipairs(scriptIds) do
                if self:ShouldShowScript(craftedAbilityData:GetId(), scriptId) and self:IsDataInSearchTextResults(scriptId) then
                    local scriptData = self:GetScriptDataById(scriptId)
                    local isScriptSlotted = self:IsScriptDataSelected(scriptData)
                    local isScriptCompatible = self:IsScriptDataCompatible(craftedAbilityData:GetId(), scriptData)
                    local entryData = ZO_GamepadEntryData:New(scriptData:GetFormattedName(), scriptData:GetIcon())
                    entryData.data = scriptData
                    entryData:SetIconTintOnSelection(true)
                    entryData:SetIconDisabledTintOnSelection(true)
                    if not scriptData:IsUnlocked() then
                        entryData:SetIconDesaturation(0.8)
                        entryData:SetMaxIconAlpha(0.8)
                    else
                        entryData:SetIconDesaturation(0)
                        entryData:SetMaxIconAlpha(1)
                    end

                    if not isScriptCompatible then
                        local selectedErrorColor, unselectedErrorColor = self:GetScriptIncompatibleNameColors()
                        entryData:SetDisabledNameColors(selectedErrorColor, unselectedErrorColor)
                    else
                        local selectedErrorColor, unselectedErrorColor = self:GetScriptLockedNameColors()
                        entryData:SetDisabledNameColors(selectedErrorColor, unselectedErrorColor)
                    end
                    entryData:SetSelected(isScriptSlotted)
                    entryData:SetEnabled(isScriptCompatible and scriptData:IsUnlocked())
                    if craftedAbilityData:IsScriptActive(scriptData) then
                        entryData.overrideStatusIndicatorIcons = { ZO_IS_ACTIVELY_SCRIBED_STATUS_ICON_OVERRIDE }
                        if isScriptSlotted then
                            table.insert(entryData.overrideStatusIndicatorIcons, ZO_IS_SLOTTED_STATUS_ICON_OVERRIDE)
                        end
                    end
                    if currentHeader ~= headerText then
                        entryData:SetHeader(headerText)
                        self.scriptsList:AddEntryWithHeader("ZO_GamepadSubMenuEntryTemplateWithStatus", entryData)
                        currentHeader = headerText
                    else
                        self.scriptsList:AddEntry("ZO_GamepadSubMenuEntryTemplateWithStatus", entryData)
                    end
                    isAnyScriptUnderHeader = true
                end
            end

            if not isAnyScriptUnderHeader then
                local unlockedScripts = SCRIBING_DATA_MANAGER:GetUnlockedSortedScriptsForCraftedAbilityAndSlot(craftedAbilityData:GetId(), scribingSlot)
                local message = GetString(SI_SCRIBING_FILTER_NO_SCRIPTS)
                if #unlockedScripts == 0 then
                    message = GetString(SI_SCRIBING_NO_SCRIPTS_UNLOCKED)
                end
                local entryData = ZO_GamepadEntryData:New(message)
                entryData:SetHeader(headerText)
                entryData:SetEnabled(false)
                self.scriptsList:AddEntryWithHeader("ZO_GamepadSubMenuEntryTemplate", entryData)
                currentHeader = headerText
            end
        end

        self.scriptsList:Commit(resetToTop)
    end
end

function ZO_ScribingLayout_Gamepad:ShouldShowScript(craftedAbilityId, scriptId)
    return true
end

function ZO_ScribingLayout_Gamepad:IsScriptDataSelected(scriptData)
    return false
end

function ZO_ScribingLayout_Gamepad:IsScriptDataCompatible(craftedAbilityId, scriptData)
    return true
end

function ZO_ScribingLayout_Gamepad:IsCraftedAbilitySelected()
    return self.selectedCraftedAbility ~= 0
end

function ZO_ScribingLayout_Gamepad:SelectCraftedAbilityId(craftedAbilityId)
    local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
    if craftedAbilityData then
        self:SetSelectedCraftedAbilityId(craftedAbilityId)
        craftedAbilityData:SetScriptIdSelectionOverride(0, 0, 0)

        self:ShowScripts()
    else
        self:SetSelectedCraftedAbilityId(0)
        self:ShowCraftedAbilities()
    end
end

function ZO_ScribingLayout_Gamepad:SetSelectedCraftedAbilityId(craftedAbilityId)
    self.selectedCraftedAbility = craftedAbilityId
end

function ZO_ScribingLayout_Gamepad:GetSelectedCraftedAbilityData()
    return SCRIBING_DATA_MANAGER:GetCraftedAbilityData(self.selectedCraftedAbility)
end

function ZO_ScribingLayout_Gamepad:GetScriptIdsForSlot(scribingSlot)
    local craftedAbilityData = self:GetSelectedCraftedAbilityData()
    return SCRIBING_DATA_MANAGER:GetAllSortedScriptsForCraftedAbilityAndSlot(craftedAbilityData:GetId(), scribingSlot)
end

function ZO_ScribingLayout_Gamepad:GetScriptDataById(scriptId)
    return SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(scriptId)
end

function ZO_ScribingLayout_Gamepad:OnStateChanged(_, newState)
    ZO_Gamepad_ParametricList_Search_Screen.OnStateChanged(self, _, newState)
end

function ZO_ScribingLayout_Gamepad:OnSelectionChanged(list, selectedData, previousData)
    ZO_Gamepad_ParametricList_Search_Screen.OnSelectionChanged(self, list, previousData, selectedData)

    if list:IsActive() then
        if list == self.craftedAbilityList then
            self:LayoutTooltipForCraftedAbilityData(selectedData and selectedData.data)
        elseif list == self.scriptsList then
            self:LayoutTooltipForScriptData(selectedData and selectedData.data)
        end
    end
end

function ZO_ScribingLayout_Gamepad:LayoutTooltipForCraftedAbilityData(craftedAbilityData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    if craftedAbilityData then
        local NO_SELECTED_SCRIPT =  nil
        local OPTIONS = { displayFlags = SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ACQUIRE_HINT }
        GAMEPAD_TOOLTIPS:LayoutCraftedAbility(GAMEPAD_LEFT_TOOLTIP, craftedAbilityData, NO_SELECTED_SCRIPT, NO_SELECTED_SCRIPT, NO_SELECTED_SCRIPT, OPTIONS)

        if craftedAbilityData:IsScribed() then
            local activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId = craftedAbilityData:GetActiveScriptIds()
            GAMEPAD_TOOLTIPS:LayoutCraftedAbilityByIds(GAMEPAD_RIGHT_TOOLTIP, craftedAbilityData:GetId(), activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId, OPTIONS)
        end
    end
end

function ZO_ScribingLayout_Gamepad:LayoutTooltipForScriptData(scriptData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    if scriptData then
        local NO_SELECTED_SCRIPT = nil
        local OPTIONS = { displayFlags = SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ACQUIRE_HINT }
        GAMEPAD_TOOLTIPS:LayoutCraftedAbilityScript(GAMEPAD_LEFT_TOOLTIP, self:GetSelectedCraftedAbilityData(), scriptData, NO_SELECTED_SCRIPT, NO_SELECTED_SCRIPT, NO_SELECTED_SCRIPT, OPTIONS)
    end
end

function ZO_ScribingLayout_Gamepad:PerformUpdate()
    self.dirty = false

    local RESET_TO_TOP = true
    if self:IsCurrentList(self.craftedAbilityList) then
        self:RefreshCraftedAbilityList(RESET_TO_TOP)
    elseif self:IsCurrentList(self.scriptsList) then
        self:RefreshScriptsList(RESET_TO_TOP)
    end
end

function ZO_ScribingLayout_Gamepad:SelectCraftedAbility()
    if self:IsCurrentList(self.craftedAbilityList) then
        local entryData = self:GetCurrentList():GetTargetData()
        if entryData then
            local craftedAbilityId = entryData.data:GetId()
            self:SelectCraftedAbilityId(craftedAbilityId)
        end
    end
end
