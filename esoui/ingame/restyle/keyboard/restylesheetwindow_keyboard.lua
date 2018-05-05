ZO_RestyleSheetWindow_Keyboard = ZO_CallbackObject:Subclass()

function ZO_RestyleSheetWindow_Keyboard:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_RestyleSheetWindow_Keyboard:Initialize(control)
    self.control = control
    self.sheetsContainer = control:GetNamedChild("Containers")
    self.sheetsByMode = {}

    self:InitializeModeSelector()
    self:InitializeEquipmentSheet()
    self:InitializeCollectibleSheet()
    self:InitializeOutfitStylesSheet()

    self.currentSheet = self.equipmentSheet
    
    self.outfitSelectorTutorialAnchor = ZO_Anchor:New(LEFT, self.modeSelectorDropdownControl, RIGHT, 10, 0)

	local function OnRefreshOutfitName(outfitIndex)
        if self.currentSheet ~= self.collectiblesSheet then
            local KEEP_CURRENT_SELECTION = true
            self:PopulateEquipmentModeDropdown(KEEP_CURRENT_SELECTION)
        end
    end

    local function UpdateEquippedOutfit()
        if self.currentSheet ~= self.collectiblesSheet then
            self:PopulateEquipmentModeDropdown()
        end
    end

    ZO_RESTYLE_SHEET_WINDOW_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ZO_RESTYLE_SHEET_WINDOW_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
            ZO_OUTFIT_MANAGER:RegisterCallback("RefreshOutfitName", OnRefreshOutfitName)
            ZO_OUTFIT_MANAGER:RegisterCallback("RefreshEquippedOutfitIndex", UpdateEquippedOutfit)
        elseif newState == SCENE_FRAGMENT_HIDING then
            ZO_OUTFIT_MANAGER:UnregisterCallback("RefreshOutfitName", OnRefreshOutfitName)
            ZO_OUTFIT_MANAGER:UnregisterCallback("RefreshEquippedOutfitIndex", UpdateEquippedOutfit)
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_RestyleSheetWindow_Keyboard:InitializeModeSelector()
    local modeSelector = self.control:GetNamedChild("ModeSelector")
    self.modeSelectorHeader= modeSelector:GetNamedChild("Header")
    self.modeSelectorDropdownControl = modeSelector:GetNamedChild("Dropdown")
    self.modeSelectorDropdown = ZO_ComboBox_ObjectFromContainer(self.modeSelectorDropdownControl)
    self.modeSelectorDropdown:SetSortsItems(false)
    
    self.modeSelectorDropdown:SetPreshowDropdownCallback(function()
        TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_OUTFIT_SELECTOR_SHOWN)
    end)

    local UNEQUIP_OUTFIT = nil

    self.setEquipmentGearSelectedFunction = function()
        self:DisplaySheet(self.equipmentSheet)
        ZO_OUTFIT_STYLES_PANEL_KEYBOARD:SetCurrentOutfitManipulator(UNEQUIP_OUTFIT)
        self.pendingEquipOutfitManipulator = UNEQUIP_OUTFIT
        ITEM_PREVIEW_KEYBOARD:PreviewUnequipOutfit()
        self:FireCallbacks("ModeSelectorDropdownChanged")
    end

    local IGNORE_CALLBACK = true

    local function TrySetEquipmentGearSelected(_, _, entry, selectionChanged, oldEntry)
        if selectionChanged then
            if self:AreChangesPending() then
                local function Decline()
                    self.modeSelectorDropdown:SelectItem(oldEntry, IGNORE_CALLBACK)
                end

                self:ShowRevertRestyleChangesDialog("CONFIRM_REVERT_OUTFIT_ON_CHANGE", self.setEquipmentGearSelectedFunction, Decline)
            else
                self.setEquipmentGearSelectedFunction()
            end
        end
    end

    self.equipmentGearModeEntry = ZO_ComboBox:CreateItemEntry(GetString(SI_NO_OUTFIT_EQUIP_ENTRY), TrySetEquipmentGearSelected)
    self.equipmentGearModeEntry.selectFunction = self.setEquipmentGearSelectedFunction
    self.collectiblesModeEntry = ZO_ComboBox:CreateItemEntry("", function()
        if self.currentSheet ~= self.collectiblesSheet then
            self:EquipSelectedOutfit()
            ITEM_PREVIEW_KEYBOARD:ResetOutfitPreview()
        end
        self:DisplaySheet(self.collectiblesSheet)
    end)

    local function OnPurchaseAdditionalOutfitsEntry(_, _, entry, selectionChanged, oldEntry)
        local exitDestinationData =
        {
            crownStoreSearch = GetString(SI_CROWN_STORE_SEARCH_ADDITIONAL_OUTFITS),
            crownStoreOpenOperation = MARKET_OPEN_OPERATION_UNLOCK_NEW_OUTFIT,
        }
        ZO_RESTYLE_STATION_KEYBOARD:AttemptExit(exitDestinationData)
        self.modeSelectorDropdown:SelectItem(oldEntry, true)
    end

    self.purchaseAdditionalOutfitsEntry = ZO_ComboBox:CreateItemEntry(GetString(SI_OUTFIT_PURCHASE_MORE_ENTRY), OnPurchaseAdditionalOutfitsEntry)
end

function ZO_RestyleSheetWindow_Keyboard:InitializeSheet(sheetClassTemplate, slotGridData)
    local function OnDyeSlotClicked(...)
        self:OnDyeSlotClicked(...)
    end

    local function OnDyeSlotEnter(...)
        self:OnDyeSlotEnter(...)
    end

    local function OnDyeSlotExit(...)
        self:OnDyeSlotExit(...)
    end

    local sheet = sheetClassTemplate:New(self.sheetsContainer, slotGridData)
    sheet:InitializeOnDyeSlotCallbacks(OnDyeSlotClicked, OnDyeSlotEnter, OnDyeSlotExit)
    self.sheetsByMode[sheet:GetRestyleMode()] = sheet
    return sheet
end

function ZO_RestyleSheetWindow_Keyboard:InitializeEquipmentSheet()
    local slotGridData =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = 
        {
            [EQUIP_SLOT_HEAD] = { row = 1, column = 1, controlName = "Head" },
            [EQUIP_SLOT_SHOULDERS] = { row = 2, column = 1, controlName = "Shoulders" }, [EQUIP_SLOT_CHEST] = { row = 2, column = 2, controlName = "Chest" },
            [EQUIP_SLOT_HAND] = { row = 3, column = 1, controlName = "Hand" }, [EQUIP_SLOT_WAIST] = { row = 3, column = 2, controlName = "Waist" },
            [EQUIP_SLOT_LEGS] = { row = 4, column = 1, controlName = "Legs" }, [EQUIP_SLOT_FEET] = { row = 4, column = 2, controlName = "Feet" },
        },
        [ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = 
        {
            -- Switches with Shield on show based on ActiveWeaponPair
            [EQUIP_SLOT_OFF_HAND] = { row = 1, column = 2, controlName = "Shield" },
            [EQUIP_SLOT_BACKUP_OFF] = { row = 1, column = 2, controlName = "ShieldB" },
        }
    }
    self.equipmentSheet = self:InitializeSheet(ZO_RestyleEquipmentSlotsSheet, slotGridData)
end

function ZO_RestyleSheetWindow_Keyboard:InitializeCollectibleSheet()
    local slotGridData =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = 
        {
            [COLLECTIBLE_CATEGORY_TYPE_HAT] = { row = 1, column = 1, controlName = "Hat" }, [COLLECTIBLE_CATEGORY_TYPE_COSTUME] = { row = 1, column = 2, controlName = "Costume" },
        },
    }
    self.collectiblesSheet = self:InitializeSheet(ZO_RestyleCollectibleSlotsSheet, slotGridData)
end

function ZO_RestyleSheetWindow_Keyboard:InitializeOutfitStylesSheet()
    local slotGridData =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] = 
        {
            [OUTFIT_SLOT_HEAD] = { row = 1, column = 1, controlName = "Head" },
            [OUTFIT_SLOT_SHOULDERS] = { row = 2, column = 1, controlName = "Shoulders" }, [OUTFIT_SLOT_CHEST] = { row = 2, column = 2, controlName = "Chest" },
            [OUTFIT_SLOT_HANDS] = { row = 3, column = 1, controlName = "Hands" }, [OUTFIT_SLOT_WAIST] = { row = 3, column = 2, controlName = "Waist" },
            [OUTFIT_SLOT_LEGS] = { row = 4, column = 1, controlName = "Legs" }, [OUTFIT_SLOT_FEET] = { row = 4, column = 2, controlName = "Feet" },
        },
        [ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] = 
        {
            -- Switches with Shield on show based on ActiveWeaponPair and equipped weapon type
            [OUTFIT_SLOT_WEAPON_TWO_HANDED] = { row = 1, column = 1, controlName = "TwoHanded" }, [OUTFIT_SLOT_SHIELD] = { row = 1, column = 2, controlName = "Shield" },
            [OUTFIT_SLOT_WEAPON_MAIN_HAND] = { row = 1, column = 1, controlName = "MainHand" }, [OUTFIT_SLOT_WEAPON_OFF_HAND] = { row = 1, column = 2, controlName = "OffHand" },
            [OUTFIT_SLOT_WEAPON_BOW] = { row = 1, column = 1, controlName = "Bow" },
            [OUTFIT_SLOT_WEAPON_STAFF] = { row = 1, column = 1, controlName = "Staff" },

            [OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP] = { row = 1, column = 1, controlName = "TwoHandedB" }, [OUTFIT_SLOT_SHIELD_BACKUP] = { row = 1, column = 2, controlName = "ShieldB" },
            [OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP] = { row = 1, column = 1, controlName = "MainHandB" }, [OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = { row = 1, column = 2, controlName = "OffHandB" },
            [OUTFIT_SLOT_WEAPON_BOW_BACKUP] = { row = 1, column = 1, controlName = "BowB" },
            [OUTFIT_SLOT_WEAPON_STAFF_BACKUP] = { row = 1, column = 1, controlName = "StaffB" },
        },
    }
    self.outfitStylesSheet = self:InitializeSheet(ZO_RestyleOutfitSlotsSheet, slotGridData)
end

function ZO_RestyleSheetWindow_Keyboard:OnShowing()
    TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_OUTFIT_SELECTOR_SHOWN, self.control, ZO_RESTYLE_SHEET_WINDOW_FRAGMENT, self.outfitSelectorTutorialAnchor)

    self:BeginRestyling()
end

function ZO_RestyleSheetWindow_Keyboard:BeginRestyling()
    BeginRestyling(self.currentSheet:GetRestyleMode())
end

function ZO_RestyleSheetWindow_Keyboard:OnHiding()
    local currentEquippedIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex()
    if (not self.pendingEquipOutfitManipulator and currentEquippedIndex) or (self.pendingEquipOutfitManipulator and self.pendingEquipOutfitManipulator:GetOutfitIndex() ~= currentEquippedIndex) then
        self:EquipSelectedOutfit()
    end
end

function ZO_RestyleSheetWindow_Keyboard:OnHidden()
    EndRestyling()
end

do
    local IGNORE_CALLBACK = true

    function ZO_RestyleSheetWindow_Keyboard:PopulateEquipmentModeDropdown(keepCurrentSelection)
        self.modeSelectorHeader:SetText(GetString(SI_RESTYLE_SHEET_SELECT_OUTFIT_HEADER))

        local reselectOutfitIndex = nil
        if keepCurrentSelection then
            local selectedData = self.modeSelectorDropdown:GetSelectedItemData()
            if selectedData and selectedData.outfitManipulator then
                reselectOutfitIndex = selectedData.outfitManipulator:GetOutfitIndex()
            end
        end

        self.modeSelectorDropdown:ClearItems()

        self.modeSelectorDropdown:AddItem(self.equipmentGearModeEntry, ZO_COMBOBOX_SUPRESS_UPDATE)

        local function SetSelectedOutfit(entry)
            local outfitManipulator = entry.outfitManipulator
            self.outfitStylesSheet:SetOutfitManipulator(outfitManipulator)
            ZO_OUTFIT_STYLES_PANEL_KEYBOARD:SetCurrentOutfitManipulator(outfitManipulator)
            self.pendingEquipOutfitManipulator = outfitManipulator
            self:DisplaySheet(self.outfitStylesSheet)
            ITEM_PREVIEW_KEYBOARD:PreviewOutfit(outfitManipulator:GetOutfitIndex())
            self:FireCallbacks("ModeSelectorDropdownChanged")
        end

        local function TrySetSelectedOutfit(_, _, entry, selectionChanged, oldEntry)
            if selectionChanged then
                if self:AreChangesPending() then
                    local function Confirm()
                        SetSelectedOutfit(entry)
                    end

                    local function Decline()
                        self.modeSelectorDropdown:SelectItem(oldEntry, IGNORE_CALLBACK)
                    end

                    self:ShowRevertRestyleChangesDialog("CONFIRM_REVERT_OUTFIT_ON_CHANGE", Confirm, Decline)
                else
                    SetSelectedOutfit(entry)
                end
            end
        end

        local equippedOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex()
        local defaultEntry = self.equipmentGearModeEntry

        local autoSelectIndex = keepCurrentSelection and reselectOutfitIndex or equippedOutfitIndex
        local numOutfits = ZO_OUTFIT_MANAGER:GetNumOutfits()
        for outfitIndex = 1, numOutfits do
            local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(outfitIndex)
            local entry = ZO_ComboBox:CreateItemEntry(outfitManipulator:GetOutfitName(), TrySetSelectedOutfit)
            entry.outfitManipulator = outfitManipulator
            entry.selectFunction = SetSelectedOutfit
            self.modeSelectorDropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
            if autoSelectIndex == outfitIndex then
                defaultEntry = entry
            end
        end

        if numOutfits < MAX_OUTFIT_UNLOCKS then
            self.modeSelectorDropdown:AddItem(self.purchaseAdditionalOutfitsEntry, ZO_COMBOBOX_SUPRESS_UPDATE)
        end

        self.modeSelectorDropdown:UpdateItems()
        self.modeSelectorDropdown:SelectItem(defaultEntry, true)
        defaultEntry.selectFunction(defaultEntry)

        self:OnUpdateModeSelectorDropdown()
    end
end

function ZO_RestyleSheetWindow_Keyboard:PopulateCollectiblesModeDropdown()
    self.modeSelectorDropdown:ClearItems()

    self.modeSelectorDropdown:AddItem(self.collectiblesModeEntry, ZO_COMBOBOX_SUPRESS_UPDATE)
    
    self.modeSelectorDropdown:UpdateItems()
    self.modeSelectorDropdown:SelectFirstItem()

    self:OnUpdateModeSelectorDropdown()
end

function ZO_RestyleSheetWindow_Keyboard:OnUpdateModeSelectorDropdown()
    local isEthereal = self.modeSelectorDropdown:GetNumItems() == 1
    self.modeSelectorHeader:SetHidden(isEthereal)
    self.modeSelectorDropdownControl:SetHidden(isEthereal)
end

function ZO_RestyleSheetWindow_Keyboard:DisplaySheet(newSheet)
    if self.currentSheet ~= newSheet then
        if self.currentSheet then
            SCENE_MANAGER:RemoveFragment(self.currentSheet:GetFragment())
        end

        local oldSheet = self.currentSheet
        self.currentSheet = newSheet

        self:FireCallbacks("SheetChanged", newSheet, oldSheet)
    end

    if newSheet then
        SCENE_MANAGER:AddFragment(newSheet:GetFragment())
        -- make sure the current sheet has the latest dye data for its slots
        SetRestylePreviewMode(newSheet:GetRestyleMode())

        if self.pendingEquipOutfitManipulator and self.pendingEquipOutfitManipulator:IsMarkedForPreservation() then
            local interactType = GetInteractionType()
            if interactType == INTERACTION_DYE_STATION then
                self.pendingEquipOutfitManipulator:RestorePreservedDyeData()
                self.pendingEquipOutfitManipulator:UpdatePreviews()
            else
                self.pendingEquipOutfitManipulator:SetMarkedForPreservation(false)
                self.pendingEquipOutfitManipulator:ClearPendingChanges(true)
            end
        end
    end
end

function ZO_RestyleSheetWindow_Keyboard:OnSheetSlotRefreshed(restyleSlotData)
    self:FireCallbacks("SheetSlotRefreshed", restyleSlotData)
end

function ZO_RestyleSheetWindow_Keyboard:OnSheetMouseoverDataChanged(newData)
    self:FireCallbacks("SheetMouseoverDataChanged", newData)
end

function ZO_RestyleSheetWindow_Keyboard:NavigateToCollectibleCategoryFromRestyleSlotData(restyleSlotData)
    self:FireCallbacks("NavigateToCollectibleCategoryFromRestyleSlotData", restyleSlotData)
end

function ZO_RestyleSheetWindow_Keyboard:ShowRevertRestyleChangesDialog(dialogName, confirmCallback, declineCallback)
    local function Confirm()
        self:UndoPendingChanges()

        if confirmCallback then
            confirmCallback()
        end
    end

    ZO_Dialogs_ShowDialog(dialogName, { confirmCallback = Confirm, declineCallback = declineCallback })
end

function ZO_RestyleSheetWindow_Keyboard:GetCurrentSheet()
    return self.currentSheet
end

function ZO_RestyleSheetWindow_Keyboard:GetSheetByMode(restyleMode)
    return self.sheetsByMode[restyleMode]
end

function ZO_RestyleSheetWindow_Keyboard:OnDyeSlotClicked(restyleSlotData, dyeChannel, button)
    self:FireCallbacks("DyeSlotClicked", restyleSlotData, dyeChannel, button)
end

do
    local UNKNOWN_DYE = false
    local IS_PLAYER_DYE = false
    local IS_NON_PLAYER_DYE = true
    local IS_LEFT_ANCHORED = false

    function ZO_RestyleSheetWindow_Keyboard:OnDyeSlotEnter(restyleSlotData, dyeChannel, dyeControl)
        if not self:FireCallbacks("DyeSlotEnter", restyleSlotData, dyeChannel, dyeControl) then
            local activeTool = ZO_DYEING_KEYBOARD:GetActiveTool()
            if activeTool then
                local highlightSlot, highlightDyeChannel = activeTool:GetHighlightRules(restyleSlotData:GetRestyleSlotType(), dyeChannel)
                self.currentSheet:ToggleDyeableSlotHightlight(highlightSlot, true, highlightDyeChannel)
                WINDOW_MANAGER:SetMouseCursor(activeTool:GetCursorType())
            end

            local dyeId = select(dyeChannel, restyleSlotData:GetPendingDyes())
            if dyeId ~= 0 then
                local playerDyeInfo = ZO_DYEING_MANAGER:GetPlayerDyeInfoById(dyeId)
                if playerDyeInfo then
                    local anchoringControl = dyeControl
                    local isRightAnchored = false
                    if KEYBOARD_DYEING_FRAGMENT:IsShowing() then
                        local swatch = ZO_DYEING_KEYBOARD:GetSwatchControlFromDyeId(dyeId)
                        if swatch then
                            anchoringControl = swatch
                            isRightAnchored = true
                        end
                    end
                    ZO_Dyeing_CreateTooltipOnMouseEnter(anchoringControl, playerDyeInfo.dyeName, playerDyeInfo.known, playerDyeInfo.achievementId, IS_PLAYER_DYE, isRightAnchored)
                else
                    local dyeName, _, _, _, achievementId = GetDyeInfoById(dyeId)
                    if dyeName ~= "" then
                        ZO_Dyeing_CreateTooltipOnMouseEnter(dyeControl, dyeName, UNKNOWN_DYE, achievementId, IS_NON_PLAYER_DYE, IS_LEFT_ANCHORED)
                    end
                end
            end
        end
    end
end

do
    local NO_SLOT = nil
    local NO_CHANNEL = nil

    function ZO_RestyleSheetWindow_Keyboard:OnDyeSlotExit(restyleSlotData, dyeChannel)
        if not self:FireCallbacks("DyeSlotExit", restyleSlotData, dyeChannel) then
            self.currentSheet:ToggleDyeableSlotHightlight(NO_SLOT, false, NO_CHANNEL)
            WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
            ZO_Dyeing_ClearTooltipOnMouseExit()
        end
    end
end

function ZO_RestyleSheetWindow_Keyboard:EquipSelectedOutfit()
    if self.pendingEquipOutfitManipulator then
        ZO_OUTFIT_MANAGER:EquipOutfit(self.pendingEquipOutfitManipulator:GetOutfitIndex())
    else
        UnequipOutfit()
    end
end

function ZO_RestyleSheetWindow_Keyboard:ShowUndoPendingChangesDialog()
    ZO_Dialogs_ShowDialog("CONFIRM_REVERT_OUTFIT_CHANGES", { confirmCallback = function() self.currentSheet:UndoPendingChanges() end})
end

function ZO_RestyleSheetWindow_Keyboard:UndoPendingChanges()
    self.currentSheet:UndoPendingChanges()
end

function ZO_RestyleSheetWindow_Keyboard:AreChangesPending()
    return self.currentSheet:AreChangesPending()
end

function ZO_RestyleSheetWindow_Keyboard:CanApplyChanges()
    return self.currentSheet:CanApplyChanges()
end

function ZO_RestyleSheetWindow_Keyboard_OnInitialized(control)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD = ZO_RestyleSheetWindow_Keyboard:New(control)
end