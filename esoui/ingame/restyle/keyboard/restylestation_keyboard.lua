---------------------
-- Restyle Station --
---------------------

local ALLOWS_DYEING = true
local DISALLOW_DYEING = false
local SPECIALIZED_COLLECTIBLE_CATEGORY_ENABLED = true
local SPECIALIZED_COLLECTIBLE_CATEGORY_DISABLED = false
local DERIVES_COLLECTIBLE_CATEGORIES_FROM_SLOTS = true

local RESTYLE_MODE_CATEGORY_DATA =
{
    [RESTYLE_MODE_EQUIPMENT] = ZO_RestyleCategoryData:New(RESTYLE_MODE_EQUIPMENT, ALLOWS_DYEING, COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES, SPECIALIZED_COLLECTIBLE_CATEGORY_DISABLED, DERIVES_COLLECTIBLE_CATEGORIES_FROM_SLOTS),
    [RESTYLE_MODE_COLLECTIBLE] = ZO_RestyleCategoryData:New(RESTYLE_MODE_COLLECTIBLE, ALLOWS_DYEING),
    [RESTYLE_MODE_OUTFIT] = ZO_RestyleCategoryData:New(RESTYLE_MODE_OUTFIT, ALLOWS_DYEING, COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES, SPECIALIZED_COLLECTIBLE_CATEGORY_ENABLED, DERIVES_COLLECTIBLE_CATEGORIES_FROM_SLOTS),
    [RESTYLE_MODE_COMPANION_EQUIPMENT] = ZO_RestyleCategoryData:New(RESTYLE_MODE_COMPANION_EQUIPMENT, DISALLOW_DYEING, COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES, SPECIALIZED_COLLECTIBLE_CATEGORY_DISABLED, DERIVES_COLLECTIBLE_CATEGORIES_FROM_SLOTS, { EQUIP_SLOT_HEAD }),
    [RESTYLE_MODE_COMPANION_OUTFIT] = ZO_RestyleCategoryData:New(RESTYLE_MODE_COMPANION_OUTFIT, ALLOWS_DYEING, COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES, SPECIALIZED_COLLECTIBLE_CATEGORY_ENABLED, DERIVES_COLLECTIBLE_CATEGORIES_FROM_SLOTS, { EQUIP_SLOT_HEAD }),
    [RESTYLE_MODE_COMPANION_COLLECTIBLE] = ZO_RestyleCategoryData:New(RESTYLE_MODE_COMPANION_COLLECTIBLE, ALLOWS_DYEING),
}

ZO_RestyleStation_Keyboard = ZO_RestyleCommon_Keyboard:Subclass()

function ZO_RestyleStation_Keyboard:New(...)
    return ZO_RestyleCommon_Keyboard.New(self, ...)
end

function ZO_RestyleStation_Keyboard:Initialize(control)
    ZO_RestyleCommon_Keyboard.Initialize(self, control)

    ZO_RESTYLE_SCENE = ZO_InteractScene:New("restyle_station_keyboard", SCENE_MANAGER, ZO_DYEING_STATION_INTERACTION)
    SYSTEMS:RegisterKeyboardRootScene("restyle", ZO_RESTYLE_SCENE)
    RESTYLE_FRAGMENT = self:GetFragment()

    self.noContentLabel = self.control:GetNamedChild("NoStylesLabel")

    self:InitializeTabs()

    self.updateKeybindCallback = function()
        if self.currentTabDescriptor == self.equipmentTabDescriptor then
            if self.currentSubTabDescriptor == self.playerSubTabDescriptor then
                self.noContentLabel:SetHidden(true)
            elseif self.currentSubTabDescriptor == self.companionSubTabDescriptor then
                local currentSheet = self:GetCurrentSheet()
                self.noContentLabel:SetHidden(currentSheet:GetRestyleMode() ~= RESTYLE_MODE_COMPANION_EQUIPMENT)
            end
        end
        self:UpdateKeybind()
    end

    self.onBlockingSceneActivatedCallback = function()
        self:AttemptExit()
    end

    self.onSheetChangedCallback = function(...)
        self:OnSheetChanged(...)
    end

    self.onDyeSlotClickedCallback = function(...)
        ZO_DYEING_KEYBOARD:OnDyeSlotClicked(...)
    end
end

function ZO_RestyleStation_Keyboard:OnShowing()
    MAIN_MENU_MANAGER:SetBlockingScene("restyle_station_keyboard", self.onBlockingSceneActivatedCallback)

    ZO_RestyleCommon_Keyboard.OnShowing(self)

    ZO_MenuBar_UpdateButtons(self.subTabs)

    if not ZO_HasActiveOrBlockedCompanion() and self.currentSubTabDescriptor == self.companionSubTabDescriptor then
        local RESELECT_IF_SELECTED = true
        self:SelectSubTabDescriptor(self.playerSubTabDescriptor, RESELECT_IF_SELECTED)
        if self.currentTabDescriptor == self.equipmentTabDescriptor then
            ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:PopulateEquipmentModeDropdown()
        elseif self.currentTabDescriptor == self.collectiblesTabDescriptor then
            ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:PopulateCollectiblesModeDropdown()
        end
    end
end

function ZO_RestyleStation_Keyboard:OnShown()
    local currentMode = self:GetRestyleMode()
    if currentMode == RESTYLE_MODE_EQUIPMENT or
        currentMode == RESTYLE_MODE_OUTFIT or
        currentMode == RESTYLE_MODE_COMPANION_EQUIPMENT or
        currentMode == RESTYLE_MODE_COMPANION_OUTFIT then
        TriggerTutorial(TUTORIAL_TRIGGER_OUTFIT_SELECTOR_SHOWN_POINTER_BOX)
    end

    if currentMode == RESTYLE_MODE_OUTFIT or currentMode == RESTYLE_MODE_COMPANION_OUTFIT then
        local outfitManipulator = self:GetCurrentSheet():GetCurrentOutfitManipulator()
        outfitManipulator:UpdatePreviews()
    end
end

function ZO_RestyleStation_Keyboard:OnHidden()
    ZO_RestyleCommon_Keyboard.OnHidden(self)

    MAIN_MENU_MANAGER:ClearBlockingScene(self.onBlockingSceneActivatedCallback)
end

function ZO_RestyleStation_Keyboard:OnTabFilterChanged(tabData)
    if tabData.descriptor.isSubTab then
        self.currentSubTabDescriptor = tabData.descriptor
        self.activeSubTab:SetText(GetString(tabData.activeTabText))
    else
        self.currentTabDescriptor = tabData.descriptor
        self.activeTab:SetText(GetString(tabData.activeTabText))
    end
    tabData.descriptor.modeDropdownPopulationCallback()

    if not tabData.descriptor.isSubTab then
        self.currentSubTabDescriptor.modeDropdownPopulationCallback()
    end
end

function ZO_RestyleStation_Keyboard:OnSheetChanged(newSheet, oldSheet)
    self:InitializeSearch()
    self:BuildCategories()
    self:UpdateKeybind()
end

function ZO_RestyleStation_Keyboard:HandleTabChange(tabData)
    if ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:AreChangesPending() then
        self.pendingTabData = tabData
        local function Confirm()
            self:ConfirmSwitchMode()
        end

        local function Decline()
            ZO_MenuBar_SelectDescriptor(self.tabs, self.currentTabDescriptor)
            ZO_MenuBar_SelectDescriptor(self.subTabs, self.currentSubTabDescriptor)
            self.pendingTabData = nil
        end

        ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:ShowRevertRestyleChangesDialog("CONFIRM_REVERT_CHANGES", Confirm, Decline)
    else
        self:OnTabFilterChanged(tabData)
    end
end

function ZO_RestyleStation_Keyboard:InitializeTabs()
    self.tabs = self.control:GetNamedChild("Tabs")
    self.activeTab = self.control:GetNamedChild("TabsLabel")
    self.currentTabDescriptor = nil
    self.currentSubTabDescriptor = nil

    local DEFAULT_TOOLTIP_FUNCTION = nil
    local ALWAYS_SHOW_TOOLTIP = true

    local function PlayerDrivenCallback(tabData)
        self:HandleTabChange(tabData)
    end

    local function ResetSubTab()
        local RESELECT_IF_SELECTED = true
        self:SelectSubTabDescriptor(self.currentSubTabDescriptor, RESELECT_IF_SELECTED)
    end

    self.equipmentTabDescriptor =
    {
        modeDropdownPopulationCallback = ResetSubTab,
        activeTabText = GetString(SI_DYEING_DYE_EQUIPMENT_TAB),
    }
    local equipmentTabData = ZO_MenuBar_GenerateButtonTabData(SI_DYEING_DYE_EQUIPMENT_TAB, self.equipmentTabDescriptor, "EsoUI/Art/Dye/dyes_tabIcon_dye_up.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_down.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_over.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_disabled.dds", function(...) self:LayoutEquipmentAppearanceTooltip(...) end, ALWAYS_SHOW_TOOLTIP, PlayerDrivenCallback)

    self.collectiblesTabDescriptor =
    {
        modeDropdownPopulationCallback = ResetSubTab,
        activeTabText = GetString(SI_DYEING_DYE_COLLECTIBLE_TAB),
    }
    local collectiblesTabData = ZO_MenuBar_GenerateButtonTabData(SI_DYEING_DYE_COLLECTIBLE_TAB, self.collectiblesTabDescriptor, "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_up.dds", "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_down.dds", "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_over.dds", "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_disabled.dds", function(...) self:LayoutCollectionAppearanceTooltip(...) end, ALWAYS_SHOW_TOOLTIP, PlayerDrivenCallback)

    ZO_MenuBar_AddButton(self.tabs, equipmentTabData)
    ZO_MenuBar_AddButton(self.tabs, collectiblesTabData)

    self:SelectTabDescriptor(self.equipmentTabDescriptor)

    -- Sub Tabs
    self.subTabs = self.control:GetNamedChild("SubTabs")
    self.activeSubTab = self.control:GetNamedChild("SubTabsLabel")

    local function OnSubTabSelected()
        if self.currentTabDescriptor == self.equipmentTabDescriptor then
            if self.currentSubTabDescriptor == self.playerSubTabDescriptor then
                self.noContentLabel:SetHidden(true)
                ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:PopulateEquipmentModeDropdown()
            elseif self.currentSubTabDescriptor == self.companionSubTabDescriptor then
                local currentSheet = self:GetCurrentSheet()
                self.noContentLabel:SetHidden(currentSheet:GetRestyleMode() ~= RESTYLE_MODE_COMPANION_EQUIPMENT)
                ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:PopulateCompanionOutfitsModeDropdown()
            end
        elseif self.currentTabDescriptor == self.collectiblesTabDescriptor then
            self.noContentLabel:SetHidden(true)
            if self.currentSubTabDescriptor == self.playerSubTabDescriptor then
                ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:PopulateCollectiblesModeDropdown()
            elseif self.currentSubTabDescriptor == self.companionSubTabDescriptor then
                ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:PopulateCompanionCollectiblesModeDropdown()
            end
        end
    end

    self.playerSubTabDescriptor =
    {
        modeDropdownPopulationCallback = OnSubTabSelected,
        activeTabText = GetString(SI_OUTFIT_PLAYER_SUB_TAB),
        actorCategory = GAMEPLAY_ACTOR_CATEGORY_PLAYER,
        isSubTab = true,
    }
    local playerSubTabData = ZO_MenuBar_GenerateButtonTabData(SI_OUTFIT_PLAYER_SUB_TAB, self.playerSubTabDescriptor, "EsoUI/Art/Dye/dyes_tabIcon_player_up.dds", "EsoUI/Art/Dye/dyes_tabIcon_player_down.dds", "EsoUI/Art/Dye/dyes_tabIcon_player_over.dds", "EsoUI/Art/Dye/dyes_tabIcon_player_disabled.dds", DEFAULT_TOOLTIP_FUNCTION, ALWAYS_SHOW_TOOLTIP, PlayerDrivenCallback)

    self.companionSubTabDescriptor =
    {
        modeDropdownPopulationCallback = OnSubTabSelected,
        activeTabText = GetString(SI_OUTFIT_COMPANION_SUB_TAB),
        actorCategory = GAMEPLAY_ACTOR_CATEGORY_COMPANION,
        isSubTab = true,
    }


    local companionSubTabData = ZO_MenuBar_GenerateButtonTabData(SI_OUTFIT_COMPANION_SUB_TAB, self.companionSubTabDescriptor, "EsoUI/Art/Dye/dyes_tabIcon_companion_up.dds", "EsoUI/Art/Dye/dyes_tabIcon_companion_down.dds", "EsoUI/Art/Dye/dyes_tabIcon_companion_over.dds", "EsoUI/Art/Dye/dyes_tabIcon_companion_disabled.dds", function(...) self:LayoutCompanionTabTooltip(...) end, ALWAYS_SHOW_TOOLTIP, PlayerDrivenCallback)
    companionSubTabData.enabled = function()
        return ZO_HasActiveOrBlockedCompanion()
    end

    ZO_MenuBar_AddButton(self.subTabs, playerSubTabData)
    ZO_MenuBar_AddButton(self.subTabs, companionSubTabData)

    self:SelectSubTabDescriptor(self.playerSubTabDescriptor)
end

function ZO_RestyleStation_Keyboard:RegisterForEvents()
    ZO_RestyleCommon_Keyboard.RegisterForEvents(self)

    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:RegisterCallback("SheetChanged", self.onSheetChangedCallback)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:RegisterCallback("DyeSlotClicked", self.onDyeSlotClickedCallback)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:RegisterCallback("ModeSelectorDropdownChanged", self.updateKeybindCallback)

    EVENT_MANAGER:RegisterForEvent("ZO_RestyleStation", EVENT_ACTIVE_COMPANION_STATE_CHANGED, function() ZO_MenuBar_UpdateButtons(self.subTabs) end)
end

function ZO_RestyleStation_Keyboard:UnregisterForEvents()
    ZO_RestyleCommon_Keyboard.UnregisterForEvents(self)

    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:UnregisterCallback("SheetChanged", self.onSheetChangedCallback)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:UnregisterCallback("DyeSlotClicked", self.onDyeSlotClickedCallback)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:UnregisterCallback("ModeSelectorDropdownChanged", self.updateKeybindCallback)
end

function ZO_RestyleStation_Keyboard:AddKeybinds()
    KEYBIND_STRIP:RemoveDefaultExit()

    ZO_RestyleCommon_Keyboard.AddKeybinds(self)
end

function ZO_RestyleStation_Keyboard:RemoveKeybinds()
    ZO_RestyleCommon_Keyboard.RemoveKeybinds(self)

    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_RestyleStation_Keyboard:InitializeModeData()
    local selectedTabDescriptor = ZO_MenuBar_GetSelectedDescriptor(self.tabs)

    local IS_ENABLED = true
    if CanUseCollectibleDyeing() then
        ZO_MenuBar_SetDescriptorEnabled(self.tabs, self.collectiblesTabDescriptor, IS_ENABLED)
    else
        -- if we have the collectible tab selected, switch tabs it before disabling it
        -- so the highlights setup correctly
        if self.currentTabDescriptor == self.collectiblesTabDescriptor then
            self:SelectTabDescriptor(self.equipmentTabDescriptor)
        end
        ZO_MenuBar_SetDescriptorEnabled(self.tabs, self.collectiblesTabDescriptor, not IS_ENABLED)
    end

    self.currentTabDescriptor.modeDropdownPopulationCallback()
    self.currentSubTabDescriptor.modeDropdownPopulationCallback()
end

function ZO_RestyleStation_Keyboard:SelectTabDescriptor(tabDescriptor)
    if tabDescriptor ~= self.currentTabDescriptor then
        ZO_MenuBar_SelectDescriptor(self.tabs, tabDescriptor)
        self.activeTab:SetText(tabDescriptor.activeTabText)
        self.currentTabDescriptor = tabDescriptor
    end
end

function ZO_RestyleStation_Keyboard:SelectSubTabDescriptor(subTabDescriptor, reselectIfSelected)
    if reselectIfSelected or subTabDescriptor ~= self.currentSubTabDescriptor then
        local DONT_SKIP_ANIMATION = false
        ZO_MenuBar_SelectDescriptor(self.subTabs, subTabDescriptor, DONT_SKIP_ANIMATION, reselectIfSelected)
        self.activeSubTab:SetText(subTabDescriptor.activeTabText)
        self.currentSubTabDescriptor = subTabDescriptor
    end
end

function ZO_RestyleStation_Keyboard:LayoutEquipmentAppearanceTooltip(tooltip)
    local title = GetString(SI_DYEING_DYE_EQUIPMENT_TAB)
    local description = GetString(SI_DYEING_EQUIPMENT_TAB_DESCRIPTION)

    SetTooltipText(tooltip, title)
    local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    tooltip:AddLine(description, "", r, g, b)

    if not ZO_HasActiveOrBlockedCompanion() then
        local requirements = GetString(SI_DYEING_EQUIPMENT_TAB_REQUIREMENTS)
        tooltip:AddLine(requirement, "", r, g, b)
    end
end

function ZO_RestyleStation_Keyboard:LayoutCollectionAppearanceTooltip(tooltip)
    local description
    local title
    if CanUseCollectibleDyeing() then
        title = zo_strformat(SI_DYEING_COLLECTIBLE_STATUS, ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_UNLOCKED)))
        description = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_UNLOCKED)
    else
        title = zo_strformat(SI_DYEING_COLLECTIBLE_STATUS, ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_LOCKED)))
        description = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_LOCKED)
    end

    SetTooltipText(tooltip, title)
    local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    tooltip:AddLine(description, "", r, g, b)
end

function ZO_RestyleStation_Keyboard:LayoutCompanionTabTooltip(tooltip)
    local title = GetString(SI_OUTFIT_COMPANION_SUB_TAB)

    SetTooltipText(tooltip, title)
    if not ZO_HasActiveOrBlockedCompanion() then
        local description = GetString(SI_OUTFIT_COMPANION_DISABLED_DESCRIPTION)
        local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
        tooltip:AddLine(description, "", r, g, b)
    end
end

function ZO_RestyleStation_Keyboard:InitializeKeybindStripDescriptors()
    local INITIAL_CONTEXT_MENU_REF_COUNT = 1

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Apply dye
        {
            name = GetString(SI_DYEING_COMMIT),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                return ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:AreChangesPending()
            end,
            enabled = function()
                return ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:CanApplyChanges()
            end,
            callback = function() self:CommitSelection() end,
        },

        -- Uniform Randomize
        {
            name = function()
                return self:GetCurrentSheet():GetRandomizeKeybindText()
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                return self:GetRestyleMode() ~= RESTYLE_MODE_COMPANION_EQUIPMENT
            end,
            callback = function()
                self:GetCurrentSheet():UniformRandomize()
            end,
        },

        -- Undo
        {
            name = GetString(SI_DYEING_UNDO),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = function() 
                return ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:AreChangesPending()
            end,
            callback = function() ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:ShowUndoPendingChangesDialog() end,
        },

        -- Special exit button
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_EXIT_BUTTON),
            keybind = "UI_SHORTCUT_EXIT",
            callback = function()
                local exitDestinationData =
                {
                    showBaseScene = true,
                }
                self:AttemptExit(exitDestinationData) 
            end,
        },

        -- Equip/Unequip
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = function()
                if ZO_OUTFIT_STYLES_PANEL_KEYBOARD:GetMouseOverEntryData() then
                    return GetString(SI_OUTFIT_STYLE_EQUIP_BIND)
                else
                    return GetString(SI_OUTFIT_SLOT_UNDO_ACTION)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                if ZO_OUTFIT_STYLES_PANEL_KEYBOARD:GetMouseOverEntryData() then
                    return true
                end
                local restyleMode = self:GetRestyleMode()
                if restyleMode == RESTYLE_MODE_OUTFIT or restyleMode == RESTYLE_MODE_COMPANION_OUTFIT then
                    local restyleSlotData = self:GetCurrentSheet():GetMouseOverData()
                    if restyleSlotData then
                        local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)
                        return slotManipulator:IsSlotDataChangePending()
                    end
                end
                return false
            end,
            callback = function()
                if ZO_OUTFIT_STYLES_PANEL_KEYBOARD:GetMouseOverEntryData() then
                    ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnRestyleOutfitStyleEntrySelected(ZO_OUTFIT_STYLES_PANEL_KEYBOARD:GetMouseOverEntryData(), INITIAL_CONTEXT_MENU_REF_COUNT)
                else
                    local restyleSlotData = self:GetCurrentSheet():GetMouseOverData()
                    local slotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)
                    slotManipulator:ClearPendingChanges()
                end
            end,
        },

        -- Change outfit name
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            keybind = "UI_SHORTCUT_QUATERNARY",
            name = GetString(SI_OUTFIT_CHANGE_NAME),
            visible = function()
                local restyleMode = self:GetRestyleMode()
                return restyleMode == RESTYLE_MODE_OUTFIT
            end,
            callback = function()
                local currentSheet = self:GetCurrentSheet()
                local outfitManipulator = currentSheet:GetCurrentOutfitManipulator()
                ZO_Dialogs_ShowDialog("RENAME_OUFIT", { actorCategory = outfitManipulator:GetActorCategory(), outfitIndex = outfitManipulator:GetOutfitIndex() }, { initialEditText = outfitManipulator:GetOutfitName() })
            end,
        },
    }
end

function ZO_RestyleStation_Keyboard:OnPendingDyesChanged(restyleSlotData)
    --Do anything dye specific here
    self:OnPendingDataChanged(restyleSlotData)
    if not restyleSlotData then
        local restyleMode = self:GetRestyleMode()
        if restyleMode == RESTYLE_MODE_OUTFIT or restyleMode == RESTYLE_MODE_COMPANION_OUTFIT then
            local outfitManipulator = self:GetCurrentSheet():GetCurrentOutfitManipulator()
            outfitManipulator:UpdatePreviews()
        else
            ApplyChangesToPreviewCollectionShown()
        end
    elseif restyleSlotData:IsOutfitSlot() then
        local outfitSlotManipulator = ZO_OUTFIT_MANAGER:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)
        local DONT_REFRESH_IMMEDIATELY = false
        outfitSlotManipulator:UpdatePreview(DONT_REFRESH_IMMEDIATELY)
    end
end

function ZO_RestyleStation_Keyboard:OnPendingDataChanged(restyleSlotData)
    local currentSheet = self:GetCurrentSheet()
    currentSheet:MarkViewDirty(restyleSlotData)

    if currentSheet:GetRestyleMode() == RESTYLE_MODE_COLLECTIBLE then
        local companionSheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetSheetByMode(RESTYLE_MODE_COMPANION_COLLECTIBLE)
        companionSheet:MarkViewDirty()
    elseif currentSheet:GetRestyleMode() == RESTYLE_MODE_COMPANION_COLLECTIBLE then
        local collectibleSheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetSheetByMode(RESTYLE_MODE_COLLECTIBLE)
        collectibleSheet:MarkViewDirty()
    end
end

-- Optionally pass in a table with destination data
-- Currently supported:
-- showBaseScene (bool)
-- achievementId (uint)
-- crownStoreSearch (string)
-- crownStoreOpenOperation (MARKET_OPEN_OPERATION enum)
-- preservePendingChanges (bool)
function ZO_RestyleStation_Keyboard:AttemptExit(exitDestinationData)
    self.exitDestinationData = exitDestinationData
    local preservePendingChanges = exitDestinationData and exitDestinationData.preservePendingChanges or false

    if ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:AreChangesPending() and not preservePendingChanges then
        local function Confirm()
            self:ConfirmExit()
        end

        local function Decline()
            self.exitDestinationData = nil
        end
        ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:ShowRevertRestyleChangesDialog("CONFIRM_REVERT_CHANGES", Confirm, Decline)
    else
        self:ConfirmExit()
    end
end

function ZO_RestyleStation_Keyboard:ConfirmExit()
    local exitDestinationData = self.exitDestinationData
    local preservePendingChanges = exitDestinationData and exitDestinationData.preservePendingChanges or false

    local restyleMode = self:GetRestyleMode()
    if restyleMode == RESTYLE_MODE_OUTFIT or restyleMode == RESTYLE_MODE_COMPANION_OUTFIT then
       local outfitManipulator = self:GetCurrentSheet():GetCurrentOutfitManipulator()
       outfitManipulator:SetMarkedForPreservation(preservePendingChanges)
    end

    if exitDestinationData then
        if exitDestinationData.achievementId then
            SYSTEMS:GetObject("achievements"):ShowAchievement(exitDestinationData.achievementId)
        elseif exitDestinationData.crownStoreSearch then
            assert(exitDestinationData.crownStoreOpenOperation ~= nil) -- Must always include an explicit open operation
            ShowMarketAndSearch(exitDestinationData.crownStoreSearch, exitDestinationData.crownStoreOpenOperation)
        elseif exitDestinationData.showBaseScene then
            SCENE_MANAGER:ShowBaseScene()
        end
        self.exitDestinationData = nil
    elseif not MAIN_MENU_MANAGER:HasBlockingSceneNextScene() then
        SCENE_MANAGER:HideCurrentScene()
    end

    MAIN_MENU_MANAGER:ClearBlockingScene(self.onBlockingSceneActivatedCallback)
end

function ZO_RestyleStation_Keyboard:ConfirmSwitchMode()
    self:OnTabFilterChanged(self.pendingTabData)

    self.pendingTabData = nil
end

function ZO_RestyleStation_Keyboard:CommitSelection()
    local currentSheet = self:GetCurrentSheet()
    if ZO_Dyeing_AreAllItemsBound(currentSheet:GetRestyleMode(), currentSheet:GetRestyleSetIndex()) then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES)
    else
        ZO_Dialogs_ShowDialog("CONFIRM_APPLY_DYE")
    end
end

function ZO_RestyleStation_Keyboard:ConfirmCommitSelection()
    if not self:GetCurrentSheet():HandleCommitSelection() then
        ApplyPendingDyes(self:GetCurrentSheet():GetRestyleMode())
        InitializePendingDyes()
        self:OnPendingDyesChanged()
    end
end

function ZO_RestyleStation_Keyboard:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
end

function ZO_RestyleStation_Keyboard:GetCurrentSheet()
    return ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()
end

function ZO_RestyleStation_Keyboard:GetRestyleMode()
    return self:GetCurrentSheet():GetRestyleMode()
end

function ZO_RestyleStation_Keyboard:GetRestyleCategoryData()
    return RESTYLE_MODE_CATEGORY_DATA[self:GetRestyleMode()]
end

function ZO_RestyleStation_Keyboard_OnSearchTextChanged(editBox)
    ZO_RESTYLE_STATION_KEYBOARD:OnSearchTextChanged()
end

function ZO_RestyleStation_Keyboard_OnInitialized(control)
    ZO_RESTYLE_STATION_KEYBOARD = ZO_RestyleStation_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("restyle", ZO_RESTYLE_STATION_KEYBOARD)
end

-----------------------------------------
-- Restyle Changes Cost Confirm Dialog --
-----------------------------------------

local OutfitConfirmCostDialog_Keyboard = ZO_Object:Subclass()

function OutfitConfirmCostDialog_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

do
    local IS_PLURAL = false
    local IS_UPPER = false

    local function SetupRadioButton(radioButton, currencyType)
        local label = radioButton:GetNamedChild("Label")
        label:SetText(zo_strformat(SI_CURRENCY_NAME_FORMAT, GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER)))
        radioButton.currencyType = currencyType
    end

    function OutfitConfirmCostDialog_Keyboard:Initialize(control)
        self.control = control

        local contentsControl = control:GetNamedChild("Contents")
        self.perSlotRadioButton = contentsControl:GetNamedChild("PerSlotRadioButton")
        SetupRadioButton(self.perSlotRadioButton, CURT_MONEY)
        self.flatRadioButton = contentsControl:GetNamedChild("FlatRadioButton")
        SetupRadioButton(self.flatRadioButton, CURT_STYLE_STONES)
        self.flatRadioButtonLabel = self.flatRadioButton:GetNamedChild("Label")
        self.costValueLabel = contentsControl:GetNamedChild("CostValue")
        self.balanceValueLabel = contentsControl:GetNamedChild("BalanceValue")
        self.confirmButton = contentsControl:GetNamedChild("Confirm")

        self.radioButtonGroup = ZO_RadioButtonGroup:New()
        self.radioButtonGroup:Add(self.perSlotRadioButton)
        self.radioButtonGroup:Add(self.flatRadioButton)
        self.radioButtonGroup:SetSelectionChangedCallback(function(radioButtonGroup, newControl, previousControl)
            if self.outfitManipulator then
                self:RefreshValues()
            end
        end)
        self.radioButtonGroup:SetClickedButton(self.perSlotRadioButton)

        ZO_Dialogs_RegisterCustomDialog("OUTFIT_CONFIRM_COST_KEYBOARD",
        {
            customControl = control,
            title =
            {
                text = SI_OUTFIT_CONFIRM_COMMIT_TITLE,
            },
            setup = function(dialog, data)
                self:SetupDialog(data.outfitManipulator)
            end,
            buttons =
            {
                {
                    control =   self.confirmButton,
                    text =      function() self:GetConfirmButtonText() end,
                    keybind =   "DIALOG_PRIMARY",
                    callback =  function() self:Confirm() end,
                },
                {
                    control =   contentsControl:GetNamedChild("Cancel"),
                    text =      SI_DIALOG_CANCEL,
                    keybind =   "DIALOG_NEGATIVE",
                },
            }
        })
    end
end

function OutfitConfirmCostDialog_Keyboard:SetupDialog(outfitManipulator)
    self.outfitManipulator = outfitManipulator
    local cost = outfitManipulator:GetTotalSlotCostsForPendingChanges()
    local canSelectFlatCurrency = cost > 0
    self.radioButtonGroup:SetButtonIsValidOption(self.flatRadioButton, canSelectFlatCurrency)

    if self.radioButtonGroup:GetClickedButton() ~= self.perSlotRadioButton then
        self.radioButtonGroup:SetClickedButton(self.perSlotRadioButton)
    else
        self:RefreshValues()
    end
end

function OutfitConfirmCostDialog_Keyboard:RefreshValues()
    local clickedButton = self.radioButtonGroup:GetClickedButton()
    local currencyType = clickedButton.currencyType
    local currencyLocation = GetCurrencyPlayerStoredLocation(currencyType)
    local balance = GetCurrencyAmount(currencyType, currencyLocation)
    local slotsCost, flatCost = self.outfitManipulator:GetAllCostsForPendingChanges()
    displayedCost = clickedButton == self.perSlotRadioButton and slotsCost or flatCost
    self.notEnoughCurrency = displayedCost > balance
    local currencyFormat = self.notEnoughCurrency and ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON or ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON
    self.costValueLabel:SetText(ZO_Currency_FormatKeyboard(currencyType, displayedCost, currencyFormat))
    self.balanceValueLabel:SetText(ZO_Currency_FormatKeyboard(currencyType, balance, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON))
    self.confirmButton:SetText(self:GetConfirmButtonText())
    self.confirmButton:SetEnabled(clickedButton == self.flatRadioButton or not self.notEnoughCurrency)
end

do
    local IS_PLURAL = false
    local IS_UPPER = false

    function OutfitConfirmCostDialog_Keyboard:GetConfirmButtonText()
        if self.radioButtonGroup:GetClickedButton() == self.flatRadioButton and self.notEnoughCurrency then
            return zo_strformat(SI_BUY_CURRENCY, GetCurrencyName(self.flatRadioButton.currencyType, IS_PLURAL, IS_UPPER))
        end
        return GetString(SI_DIALOG_CONFIRM)
    end
end

function OutfitConfirmCostDialog_Keyboard:Confirm()
    if self.outfitManipulator then
        if self.radioButtonGroup:GetClickedButton() == self.flatRadioButton and self.notEnoughCurrency then
            local exitDestinationData =
            {
                crownStoreSearch = GetString(SI_CROWN_STORE_SEARCH_OUTFIT_CURRENCY),
                crownStoreOpenOperation = MARKET_OPEN_OPERATION_OUTFIT_CURRENCY,
                preservePendingChanges = true,
            }
            ZO_RESTYLE_STATION_KEYBOARD:AttemptExit(exitDestinationData)
        else
            local useFlatCurrency = self.radioButtonGroup:GetClickedButton() == self.flatRadioButton
            self.outfitManipulator:SendOutfitChangeRequest(useFlatCurrency)
        end
    end
end

function ZO_OutfitConfirmCostDialog_Keyboard_OnInitialized(control)
    ZO_OUTFIT_CONFIRM_COST_DIALOG_KEYBOARD = OutfitConfirmCostDialog_Keyboard:New(control)
end