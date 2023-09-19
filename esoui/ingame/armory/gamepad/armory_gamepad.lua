-------------------------
-- Armory Gamepad
-------------------------
local ARMORY_OVERVIEW_MODE = 1
local ARMORY_VIEW_BUILD_MODE = 2

local ARMORY_BUILD_NAME_ICON_GAMEPAD_DIALOG = "ARMORY_BUILD_NAME_ICON_GAMEPAD_DIALOG"

ZO_Armory_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_Armory_Gamepad:Initialize(control)
    self.control = control

    ARMORY_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ARMORY_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self.mode = ARMORY_OVERVIEW_MODE
            self.selectedBuildData = nil
            self:SetCurrentList(self.buildList)
            self:RefreshList()
            self:SetActiveKeybinds(self.buildKeybindStripDescriptor)

            -- Since always defaulting to the overview mode, refresh the list before getting the target data.
            local targetData = self.buildList:GetTargetData()
            self:RefreshTargetTooltip(self.buildList, targetData)
        elseif newState == SCENE_FRAGMENT_SHOWN then
            TriggerTutorial(TUTORIAL_TRIGGER_ARMORY_OPENED)
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:ResetTooltips()
        end
    end)

    ARMORY_ROOT_GAMEPAD_SCENE = ZO_InteractScene:New("armoryRootGamepad", SCENE_MANAGER, ZO_ARMORY_MANAGER:GetInteraction())
    ARMORY_ROOT_GAMEPAD_SCENE:AddFragment(ARMORY_GAMEPAD_FRAGMENT)
    ARMORY_ROOT_GAMEPAD_SCENE:SetHideSceneConfirmationCallback(function(scene, nextSceneName, bypassHideSceneConfirmationReason)
        if ZO_ARMORY_MANAGER:IsBuildOperationInProgress() then
            ARMORY_ROOT_GAMEPAD_SCENE:RejectHideScene()
            --If we tried to hide the scene because the gamepad preferred mode changed, close the armory when the build operation completes to prevent the user from getting stuck in a bad state
            if bypassHideSceneConfirmationReason == ZO_BHSCR_GAMEPAD_MODE_CHANGED then
                ZO_ARMORY_MANAGER:SetHideOnBuildOperationComplete(true)
            end
        else
            ARMORY_ROOT_GAMEPAD_SCENE:AcceptHideScene()
        end
    end)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, ARMORY_ROOT_GAMEPAD_SCENE)

     -- Initialize grid list object
    local ALWAYS_ANIMATE = true
    self.armoryBuildIconPickerGridListControl = self.control:GetNamedChild("RightPaneBuildIconPicker")
    ARMORY_BUILD_ICON_PICKER_FRAGMENT = ZO_FadeSceneFragment:New(self.armoryBuildIconPickerGridListControl, ALWAYS_ANIMATE)

    self.armoryBuildIconPicker = ZO_ArmoryBuildIconPicker_Gamepad:New(self.armoryBuildIconPickerGridListControl)

    self:InitializeBuildOptionsDialog()

    local function OnOpenArmoryMenu()
        if IsInGamepadPreferredMode() then
            SCENE_MANAGER:Show("armoryRootGamepad")
        end
    end

    control:RegisterForEvent(EVENT_OPEN_ARMORY_MENU, OnOpenArmoryMenu)

    ZO_ARMORY_MANAGER:RegisterCallback("BuildOperationCompleted", function()
        if ARMORY_GAMEPAD_FRAGMENT:IsShowing() then
            self:RefreshList()
        end
    end)

    ZO_ARMORY_MANAGER:RegisterCallback("BuildListUpdated", function()
        if ARMORY_GAMEPAD_FRAGMENT:IsShowing() then
            self:RefreshList()
        end
    end)
end

function ZO_Armory_Gamepad:OnDeferredInitialize()
    self:RefreshHeader()
    self:InitializeLists()
end

function ZO_Armory_Gamepad:PerformUpdate()
   self.dirty = false
end

do
    local function UpdateCapacityString()
        return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
    end

    function ZO_Armory_Gamepad:RefreshHeader()
        --First, set up the header data that never changes
        if not self.headerData then
            self.headerData =
            {
                titleText = GetString(SI_ARMORY_TITLE),
                data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
                data1Text = UpdateCapacityString,
            }
        end

        if self.mode == ARMORY_VIEW_BUILD_MODE and self.selectedBuildData then
            self.headerData.subtitleText = self.selectedBuildData:GetName()
            self.headerData.data2HeaderText = GetString(SI_GAMEPAD_ARMORY_CURSE_HEADER)
            self.headerData.data2Text = GetString("SI_CURSETYPE", self.selectedBuildData:GetCurseType())
        else
            --If we are not in the view build mode, clear out the build name and curse text
            self.headerData.subtitleText = nil
            self.headerData.data2HeaderText = nil
            self.headerData.data2Text = nil
        end

        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end
end

function ZO_Armory_Gamepad:InitializeKeybindStripDescriptors()
    self.buildKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            callback = function()
                local targetData = self.buildList:GetTargetData()
                if targetData.isNewBuildSlot then
                    ShowMarketAndSearch(GetString(SI_CROWN_STORE_SEARCH_ADDITIONAL_ARMORY_SLOTS), MARKET_OPEN_OPERATION_UNLOCK_ARMORY_BUILD_SLOT)
                else
                    self.mode = ARMORY_VIEW_BUILD_MODE
                    self.selectedBuildData = targetData.data
                    self:SetCurrentList(self.buildDetailsList)
                    ARMORY_BUILD_SKILLS_GAMEPAD:SetSelectedArmoryBuildData(self.selectedBuildData)
                    ARMORY_BUILD_CHAMPION_GAMEPAD:SetSelectedArmoryBuildData(self.selectedBuildData)
                    self.buildDetailsList:SetFirstIndexSelected()
                    self:RefreshList()
                    self:SetActiveKeybinds(self.buildDetailsKeybindStripDescriptor)
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = function()
                return GetString(SI_GAMEPAD_BACK_OPTION)
            end,
            callback = function()
                SCENE_MANAGER:HideCurrentScene()
            end,
        },
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_ARMORY_RESTORE_BUILD_ACTION),
            onShowCooldown = function()
                return GetArmoryOperationsCooldownRemaining() / 1000
            end,
            callback = function()
                local targetData = self.buildList:GetTargetData()
                ZO_ARMORY_MANAGER:ShowBuildOperationConfirmationDialog(ARMORY_BUILD_OPERATION_TYPE_RESTORE, targetData.data.buildIndex)
            end,
            visible = function()
                local targetData = self.buildList:GetTargetData()
                return not targetData.isNewBuildSlot
            end,
            enabled = function()
                local function disabledAlertText()
                    return zo_strformat(SI_ARMORY_BUILD_OPERATION_COOLDOWN_ALERT, ZO_FormatTimeMilliseconds(GetArmoryOperationsCooldownDurationMs(), TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
                end
                return not ZO_ARMORY_MANAGER:IsBuildOperationInProgress(), disabledAlertText
            end,
        },
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_ARMORY_SAVE_BUILD_ACTION),
            onShowCooldown = function()
                return GetArmoryOperationsCooldownRemaining() / 1000
            end,
            callback = function()
                local targetData = self.buildList:GetTargetData()
                ZO_ARMORY_MANAGER:ShowBuildOperationConfirmationDialog(ARMORY_BUILD_OPERATION_TYPE_SAVE, targetData.data.buildIndex)
            end,
            visible = function()
                local targetData = self.buildList:GetTargetData()
                return not targetData.isNewBuildSlot
            end,
            enabled = function()
                local function disabledAlertText()
                    return zo_strformat(SI_ARMORY_BUILD_OPERATION_COOLDOWN_ALERT, ZO_FormatTimeMilliseconds(GetArmoryOperationsCooldownDurationMs(), TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
                end
                return not ZO_ARMORY_MANAGER:IsBuildOperationInProgress(), disabledAlertText
            end,
        },
        {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = GetString(SI_ARMORY_OPEN_BUILD_DIALOG_ACTION),
            callback = function()
                self:ResetTooltips()
                ZO_Dialogs_ShowGamepadDialog(ARMORY_BUILD_NAME_ICON_GAMEPAD_DIALOG, { currentList = self:GetCurrentList() })
            end,
            visible = function()
                local targetData = self.buildList:GetTargetData()
                return not targetData.isNewBuildSlot
            end,
        },
    }

    self.buildDetailsKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            visible = function()
                local targetData = self.buildDetailsList:GetTargetData()
                if not targetData.isBuildSkillsEntry and not targetData.isBuildChampionEntry then
                    return false
                end
                return true
            end,
            callback = function()
                local targetData = self.buildDetailsList:GetTargetData()
                if targetData.isBuildSkillsEntry then
                    ARMORY_BUILD_SKILLS_GAMEPAD:Activate()
                elseif targetData.isBuildChampionEntry then
                    ARMORY_BUILD_CHAMPION_GAMEPAD:Activate()
                end
            end,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = function()
                return GetString(SI_GAMEPAD_BACK_OPTION)
            end,
            callback = function()
                local targetData = self.buildDetailsList:GetTargetData()
                self.mode = ARMORY_OVERVIEW_MODE
                self:SetCurrentList(self.buildList)
                self.buildList:SetSelectedIndex(self.selectedBuildData.buildIndex)
                self:RefreshList()
                self:SetActiveKeybinds(self.buildKeybindStripDescriptor)
            end,
            sound = SOUNDS.GAMEPAD_MENU_BACK,
        },
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_ARMORY_RESTORE_BUILD_ACTION),
            onShowCooldown = function()
                return GetArmoryOperationsCooldownRemaining() / 1000
            end,
            callback = function()
                ZO_ARMORY_MANAGER:ShowBuildOperationConfirmationDialog(ARMORY_BUILD_OPERATION_TYPE_RESTORE, self.selectedBuildData.buildIndex)
            end,
            visible = function()
                local targetData = self.buildDetailsList:GetTargetData()
                return not targetData.isNewBuildSlot
            end,
            enabled = function()
                local function disabledAlertText()
                    return zo_strformat(SI_ARMORY_BUILD_OPERATION_COOLDOWN_ALERT, ZO_FormatTimeMilliseconds(GetArmoryOperationsCooldownDurationMs(), TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
                end
                return not ZO_ARMORY_MANAGER:IsBuildOperationInProgress(), disabledAlertText
            end,
        },
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_ARMORY_SAVE_BUILD_ACTION),
            onShowCooldown = function()
                return GetArmoryOperationsCooldownRemaining() / 1000
            end,
            callback = function()
                ZO_ARMORY_MANAGER:ShowBuildOperationConfirmationDialog(ARMORY_BUILD_OPERATION_TYPE_SAVE, self.selectedBuildData.buildIndex)
            end,
            visible = function()
                local targetData = self.buildDetailsList:GetTargetData()
                return not targetData.isNewBuildSlot
            end,
            enabled = function()
                local function disabledAlertText()
                    return zo_strformat(SI_ARMORY_BUILD_OPERATION_COOLDOWN_ALERT, ZO_FormatTimeMilliseconds(GetArmoryOperationsCooldownDurationMs(), TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
                end
                return not ZO_ARMORY_MANAGER:IsBuildOperationInProgress(), disabledAlertText
            end,
        },
        {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = GetString(SI_ARMORY_OPEN_BUILD_DIALOG_ACTION),
            callback = function()
                self:ResetTooltips()
                ZO_Dialogs_ShowGamepadDialog(ARMORY_BUILD_NAME_ICON_GAMEPAD_DIALOG, { currentList = self:GetCurrentList() })
            end,
        },
    }
end

function ZO_Armory_Gamepad:InitializeLists()
    local function SetupBuildList(list)
        list:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, NO_EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate")
    end

    local function SetupBuildDetailsList(list)
        list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplate("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadItemSubEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, NO_EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate")
    end

    self.buildList = self:AddList("Builds", SetupBuildList)
    self.buildDetailsList = self:AddList("Details", SetupBuildDetailsList)

    local function OnTargetBuildChanged(list, targetData, oldTargetData)
        self:UpdateKeybinds(self.buildKeybindStripDescriptor)
    end

    self.buildList:SetOnTargetDataChangedCallback(OnTargetBuildChanged)

    local function OnTargetBuildDetailsChanged(list, targetData, oldTargetData)
        self:UpdateKeybinds(self.buildDetailsKeybindStripDescriptor)
    end

    self.buildDetailsList:SetOnTargetDataChangedCallback(OnTargetBuildDetailsChanged)

    self.mode = ARMORY_OVERVIEW_MODE
end

function ZO_Armory_Gamepad:RemoveKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Armory_Gamepad:AddKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Armory_Gamepad:UpdateKeybinds(keybindDescriptor)
    keybindDescriptor = keybindDescriptor or self.keybindStripDescriptor
    KEYBIND_STRIP:UpdateKeybindButtonGroup(keybindDescriptor)

    for _, keybindDesc in ipairs(keybindDescriptor) do
        local onShowCooldown = keybindDesc.onShowCooldown
        if onShowCooldown then
            KEYBIND_STRIP:TriggerCooldown(keybindDesc, onShowCooldown)
        end
    end
end

function ZO_Armory_Gamepad:SetActiveKeybinds(keybindDescriptor)
    self:RemoveKeybinds()
    self.keybindStripDescriptor = keybindDescriptor
    self:AddKeybinds()
end

function ZO_Armory_Gamepad:SetChangeArmoryBuildIconPickerEnabled(state)
    if self.changeArmoryBuildIconPickerEnabled ~= state then
        if state then
            self.armoryBuildIconPicker:Activate()
        elseif self.changeArmoryBuildIconPickerEnabled then
            self.armoryBuildIconPicker:Deactivate()
        end

        self.changeArmoryBuildIconPickerEnabled = state
    end
end

do
    local MAIN_HAND_EQUIP_SLOT =
    {
        [EQUIP_SLOT_MAIN_HAND] = true,
        [EQUIP_SLOT_BACKUP_MAIN] = true,
    }

    local OFF_HAND_TO_MAIN_HAND_MAP =
    {
        [EQUIP_SLOT_OFF_HAND] = EQUIP_SLOT_MAIN_HAND,
        [EQUIP_SLOT_BACKUP_OFF] = EQUIP_SLOT_BACKUP_MAIN,
    }

    local BACKBAR_SLOTS =
    {
        [EQUIP_SLOT_BACKUP_MAIN] = true,
        [EQUIP_SLOT_BACKUP_OFF] = true,
        [EQUIP_SLOT_BACKUP_POISON] = true,
    }

    local function GetBuildEntryNarrationText(entryData, entryControl)
        local narrations = {}
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        ZO_AppendNarration(narrations, GAMEPAD_ARMORY_BUILD_OVERVIEW:GetNarrationText())
        return narrations
    end

    function ZO_Armory_Gamepad:RefreshBuildList()
        local list = self.buildList
        list:Clear()

        local numBuilds = GetNumUnlockedArmoryBuilds()
        for _, buildData in ZO_ARMORY_MANAGER:BuildDataIterator() do
            local entryData = ZO_GamepadEntryData:New(buildData:GetName(), buildData:GetIcon())
            entryData.data = buildData
            entryData:SetIconTintOnSelection(true)
            entryData:SetIconDisabledTintOnSelection(true)
            entryData.narrationText = GetBuildEntryNarrationText
            list:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
        end

        if numBuilds < MAX_NUM_ARMORY_BUILDS then
            local entryData = ZO_GamepadEntryData:New(GetString(SI_ARMORY_UNLOCK_NEW_BUILD_ENTRY_NAME), "EsoUI/Art/Armory/newBuild_Icon.dds")
            entryData.isNewBuildSlot = true
            entryData:SetIconTintOnSelection(true)
            entryData:SetIconDisabledTintOnSelection(true)
            list:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
        end

        list:Commit()
    end

    function ZO_Armory_Gamepad:RefreshBuildDetailsList()
        local list = self.buildDetailsList
        list:Clear()

        local skillsEntryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_ARMORY_SKILLS_CATEGORY), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_skills.dds")
        skillsEntryData:SetIconTintOnSelection(true)
        skillsEntryData:SetIconDisabledTintOnSelection(true)
        skillsEntryData.isBuildSkillsEntry = true
        list:AddEntry("ZO_GamepadMenuEntryTemplate", skillsEntryData)

        local championEntryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_ARMORY_CHAMPION_CATEGORY), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_champion.dds")
        championEntryData:SetIconTintOnSelection(true)
        championEntryData:SetIconDisabledTintOnSelection(true)
        championEntryData.isBuildChampionEntry = true
        list:AddEntry("ZO_GamepadMenuEntryTemplate", championEntryData)

        local attributeEntryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_ARMORY_ATTRIBUTES_CATEGORY), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_character.dds")
        attributeEntryData:SetIconTintOnSelection(true)
        attributeEntryData:SetIconDisabledTintOnSelection(true)
        attributeEntryData.tooltipFunction = function() GAMEPAD_TOOLTIPS:LayoutArmoryBuildAttributes(GAMEPAD_LEFT_TOOLTIP, self.selectedBuildData) end
        list:AddEntry("ZO_GamepadMenuEntryTemplate", attributeEntryData)

        local headersUsed = {}
        local equipmentSlots = {}
        local mainHandLinks = {}
        local equipmentSlotTypes = ZO_ARMORY_MANAGER:GetEquipmentSlotTypes()
        local isWeaponSwapLocked = GetUnitLevel("player") < GetWeaponSwapUnlockedLevel()
        for index, equipType in ipairs(equipmentSlotTypes) do
            local entryData = ZO_GamepadEntryData:New()
            local slotState, itemLink = self.selectedBuildData:GetEquipSlotItemLinkInfo(equipType)
            entryData:SetIconTintOnSelection(true)
            entryData:SetIconDisabledTintOnSelection(true)
            local mainHandEquipType = OFF_HAND_TO_MAIN_HAND_MAP[equipType]
            local shouldHideEquipType = isWeaponSwapLocked and BACKBAR_SLOTS[equipType]
            if mainHandEquipType then
                shouldHideEquipType = shouldHideEquipType or GetItemLinkEquipType(mainHandLinks[mainHandEquipType]) == EQUIP_TYPE_TWO_HAND
            end
            if not shouldHideEquipType then
                if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_VALID then
                    entryData:AddIcon(GetItemLinkIcon(itemLink))
                    entryData:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink)))
                    entryData:SetNameColors(entryData:GetColorsBasedOnQuality(GetItemLinkDisplayQuality(itemLink)))
                    local _, bagId, slotIndex = self.selectedBuildData:GetEquipSlotInfo(equipType)
                    entryData.tooltipFunction = function() GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, bagId, slotIndex) end
                    if MAIN_HAND_EQUIP_SLOT[equipType] then
                        mainHandLinks[equipType] = itemLink
                    end
                elseif slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_MISSING or slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_INACCESSIBLE then
                    local unselectedErrorColor = ZO_ERROR_COLOR:GetDim()
                    entryData:AddIcon(ZO_Character_GetEmptyEquipSlotTexture(equipType))
                    entryData:SetIconTint(ZO_ERROR_COLOR, unselectedErrorColor)
                    entryData:SetText(zo_strformat(SI_GAMEPAD_ARMORY_EQUIPMENT_FORMATTER, GetString("SI_EQUIPSLOT", equipType)))
                    entryData:SetNameColors(ZO_ERROR_COLOR, unselectedErrorColor)
                    local tooltipString
                    if slotState == ARMORY_BUILD_EQUIP_SLOT_STATE_INACCESSIBLE then
                        local bagId = select(2, self.selectedBuildData:GetEquipSlotInfo(equipType))
                        if bagId == BAG_BANK then
                            tooltipString = GetString(SI_ARMORY_BUILD_EQUIPMENT_IN_BANK_TOOLTIP)
                        elseif IsHouseBankBag(bagId) then
                            local collectibleId = GetCollectibleForHouseBankBag(bagId)
                            local nameWithNickname
                            if collectibleId ~= 0 then
                                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                                if collectibleData then
                                    nameWithNickname = collectibleData:GetNameWithNickname()
                                end
                            end

                            if nameWithNickname and nameWithNickname ~= "" then
                                tooltipString = zo_strformat(SI_ARMORY_BUILD_EQUIPMENT_IN_HOUSE_BANK_TOOLTIP, ZO_SELECTED_TEXT:Colorize(nameWithNickname))
                            end
                        end
                    end

                    if not tooltipString or tooltipString == "" then
                        -- If we get here, that means the item is missing
                        tooltipString = GetString(SI_ARMORY_BUILD_EQUIPMENT_MISSING_TOOLTIP)
                    end
                    entryData.tooltipFunction = function() GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, tooltipString) end
                else
                    entryData:AddIcon(ZO_Character_GetEmptyEquipSlotTexture(equipType))
                    entryData:SetText(zo_strformat(SI_GAMEPAD_ARMORY_EQUIPMENT_FORMATTER, GetString("SI_EQUIPSLOT", equipType)))
                end

                --Headers for Equipment Visual Categories (Weapons, Apparel): display header for the first equip slot of a category to be visible
                local visualCategory = ZO_Character_GetEquipSlotVisualCategory(equipType)
                    if headersUsed[visualCategory] == nil then
                    entryData:SetHeader(GetString("SI_EQUIPSLOTVISUALCATEGORY", visualCategory))
                    list:AddEntryWithHeader("ZO_GamepadItemSubEntryTemplate", entryData)
                    headersUsed[visualCategory] = true
                else
                    list:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
                end
            end
        end

        list:Commit()
    end

    function ZO_Armory_Gamepad:RefreshList()
        if self.mode == ARMORY_OVERVIEW_MODE then
            self:RefreshBuildList()
        elseif self.mode == ARMORY_VIEW_BUILD_MODE then
            self:RefreshBuildDetailsList()
        end

        self:RefreshHeader()
        self:SetChangeArmoryBuildIconPickerEnabled(false)
    end
end

function ZO_Armory_Gamepad:OnTargetChanged(list, selectedData)
    self:RefreshTargetTooltip(list, selectedData)
end

function ZO_Armory_Gamepad:ResetTooltips()
    --We need to reset the tooltip instead of clearing so that the generic header will hide
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_QUAD_2_3_TOOLTIP)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)

    SCENE_MANAGER:RemoveFragment(ARMORY_BUILD_SKILLS_GAMEPAD_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(ARMORY_BUILD_CHAMPION_GAMEPAD_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_LEFT_TOOLTIP_BACKGROUND_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(ZO_GAMEPAD_ARMORY_BUILD_OVERVIEW_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
end

function ZO_Armory_Gamepad:RefreshTargetTooltip(list, selectedData)
    self:ResetTooltips()
    if selectedData and not selectedData.isNewBuildSlot then
        if self.mode == ARMORY_OVERVIEW_MODE then
            GAMEPAD_ARMORY_BUILD_OVERVIEW:SetSelectedArmoryBuildData(selectedData.data)
            SCENE_MANAGER:AddFragment(ZO_GAMEPAD_ARMORY_BUILD_OVERVIEW_FRAGMENT)
            SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
        else
            SCENE_MANAGER:RemoveFragment(ZO_GAMEPAD_ARMORY_BUILD_OVERVIEW_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)

            if selectedData.tooltipFunction then
                selectedData.tooltipFunction(selectedData)
            elseif selectedData.isBuildSkillsEntry then
                SCENE_MANAGER:AddFragment(ARMORY_BUILD_SKILLS_GAMEPAD_FRAGMENT)
                SCENE_MANAGER:AddFragment(GAMEPAD_LEFT_TOOLTIP_BACKGROUND_FRAGMENT)
            elseif selectedData.isBuildChampionEntry then
                SCENE_MANAGER:AddFragment(ARMORY_BUILD_CHAMPION_GAMEPAD_FRAGMENT)
                SCENE_MANAGER:AddFragment(GAMEPAD_LEFT_TOOLTIP_BACKGROUND_FRAGMENT)
            end
        end
    end
end

function ZO_Armory_Gamepad:InitializeBuildOptionsDialog()
    local dialogName = ARMORY_BUILD_NAME_ICON_GAMEPAD_DIALOG
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local function UpdateSelectedName(name, forceUpdate)
        if self.selectedName ~= name or forceUpdate then
            self.selectedName = name
            self.violations = { IsValidArmoryBuildName(self.selectedName) }

            if #self.violations > 0 then
                local HIDE_UNVIOLATED_RULES = true
                local violationString = ZO_ValidNameInstructions_GetViolationString(self.selectedName, self.violations, HIDE_UNVIOLATED_RULES)

                local headerData =
                {
                    titleText = GetString(SI_INVALID_NAME_DIALOG_TITLE),
                    messageText = violationString,
                    messageTextAlignment = TEXT_ALIGN_LEFT,
                }
                GAMEPAD_TOOLTIPS:ShowGenericHeader(GAMEPAD_LEFT_DIALOG_TOOLTIP, headerData)
                ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)
            else
                ZO_GenericGamepadDialog_HideTooltip(parametricDialog)
            end
        end

        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog, data)
            self.noViolations = nil
            self.selectedName = nil

            local buildData
            local selectedData
            if self.mode == ARMORY_OVERVIEW_MODE then
                selectedData = self.buildList:GetTargetData()
                buildData = selectedData.data
            elseif self.mode == ARMORY_VIEW_BUILD_MODE then
                buildData = self.selectedBuildData
                selectedData = self.buildDetailsList:GetTargetData()
            end

            if buildData then
                UpdateSelectedName(buildData:GetName())
            end

            dialog.buildData = buildData
            dialog.currentList = data.currentList
            dialog.selectedData = selectedData

            self.armoryBuildIconPicker:SetupIconPickerForArmoryBuild(buildData)

            dialog:setupFunc()
        end,

        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.

        title =
        {
            text = SI_ARMORY_BUILD_DIALOG_TITLE,
        },
        parametricList =
        {
            -- name edit box
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData =
                {
                    nameField = true,
                    textChangedCallback = function(control)
                        local newName = control:GetText()
                        if self.selectedName ~= newName then
                            UpdateSelectedName(newName)
                            ZO_GenericParametricListGamepadDialogTemplate_RefreshVisibleEntries(parametricDialog)
                        end
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.highlight:SetHidden(not selected)

                        control.editBoxControl.textChangedCallback = data.textChangedCallback

                        if self.selectedName == "" then
                            control.editBoxControl:SetDefaultText(GetString(SI_ARMORY_BUILD_DIALOG_NAME_LABEL))
                        end
                        control.editBoxControl:SetMaxInputChars(MAX_ARMORY_BUILD_NAME_LENGTH)
                        control.editBoxControl:SetText(self.selectedName)

                        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        targetControl.editBoxControl:TakeFocus()
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                    narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                },
            },
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData =
                {
                    text = GetString(SI_GAMEPAD_ARMORY_CHANGE_ICON),
                    setup = function(control, data, ...)
                        data:ClearIcons()
                        data:AddIcon("EsoUI/Art/Guild/Gamepad/gp_guild_options_changeIcon.dds")
                        ZO_SharedGamepadEntry_OnSetup(control, data, ...)
                    end,
                    callback = function(dialog)
                        dialog.entryList:Deactivate()
                        dialog:Deactivate()
                        self:SetChangeArmoryBuildIconPickerEnabled(true)
                        ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                    end,
                },
            },
        },

        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            local targetControl = dialog.entryList:GetTargetControl()
            if newSelectedData.nameField and targetControl then
                local FORCE_UPDATE = true
                UpdateSelectedName(targetControl.editBoxControl:GetText(), FORCE_UPDATE)
                SCENE_MANAGER:RemoveFragment(ARMORY_BUILD_ICON_PICKER_FRAGMENT)
                SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
            else
                ZO_GenericGamepadDialog_HideTooltip(parametricDialog)
                SCENE_MANAGER:AddFragment(ARMORY_BUILD_ICON_PICKER_FRAGMENT)
                SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
                self.armoryBuildIconPicker:ScrollToSelectedData()
                self.armoryBuildIconPicker:RefreshGridList()
            end
        end,

        buttons =
        {
            -- Cancel Button
            {
                keybind = "DIALOG_NEGATIVE",
                text = function(dialog)
                    if self.armoryBuildIconPicker:IsActive() then
                        return GetString(SI_GAMEPAD_BACK_OPTION)
                    else
                        return GetString(SI_DIALOG_CLOSE)
                    end
                end,
                callback = function(dialog)
                    if self.armoryBuildIconPicker:IsActive() then
                        self:SetChangeArmoryBuildIconPickerEnabled(false)
                        dialog:Activate()
                        dialog.entryList:Activate()
                        ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                    else
                        if #self.violations == 0 then
                            dialog.buildData:SetName(self.selectedName)
                        end
                        dialog.buildData:SetIconIndex(self.armoryBuildIconPicker:GetSelectedArmoryBuildIconIndex())
                        SCENE_MANAGER:RemoveFragment(ARMORY_BUILD_ICON_PICKER_FRAGMENT)
                        SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
                        self:RefreshTargetTooltip(dialog.currentList, dialog.selectedData)
                        self:RefreshList()
                        ReleaseDialog()
                    end
                end,
            },

            -- Select Button (used for entering name)
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function(dialog)
                    if self.armoryBuildIconPicker:IsActive() then
                        self.armoryBuildIconPicker:OnArmoryBuildIconPickerGridListEntryClicked()
                    else
                        local data = dialog.entryList:GetTargetData()
                        data.callback(dialog)
                    end
                end,
                enabled = function()
                    local targetData = parametricDialog.entryList:GetTargetData()
                    local enabled = true

                    if targetData.finishedSelector then
                        enabled = self.noViolations
                    end

                    return enabled
                end,
            },
        },

        noChoiceCallback = function(dialog)
            if #self.violations == 0 then
                dialog.buildData:SetName(self.selectedName)
            end
            dialog.buildData:SetIconIndex(self.armoryBuildIconPicker:GetSelectedArmoryBuildIconIndex())
            SCENE_MANAGER:RemoveFragment(ARMORY_BUILD_ICON_PICKER_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
            self:RefreshTargetTooltip(dialog.currentList, dialog.selectedData)
            self:RefreshList()
            ReleaseDialog()
        end,
    })
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_Armory_Gamepad_Initialize(control)
    ARMORY_GAMEPAD = ZO_Armory_Gamepad:New(control)
end