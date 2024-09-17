local IGNORE_CALLBACK = true

ZO_RestyleSheetWindow_Keyboard = ZO_InitializingCallbackObject:Subclass()

function ZO_RestyleSheetWindow_Keyboard:Initialize(control)
    self.control = control

    ZO_RESTYLE_SHEET_WINDOW_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ZO_RESTYLE_SHEET_WINDOW_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:PerformDeferredInitialize()
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_RestyleSheetWindow_Keyboard:PerformDeferredInitialize()
    if not self.initialized then
        self.initialized = true
        self:OnDeferredInitialize()
    end
end

function ZO_RestyleSheetWindow_Keyboard:OnDeferredInitialize()
    self.isPreviewAvailable = true
    self.sheetsContainer = self.control:GetNamedChild("Containers")
    self.sheetsByMode = {}

    self:InitializeModeSelector()
    self:InitializeEquipmentSheet()
    self:InitializeCollectibleSheet()
    self:InitializeOutfitStylesSheet()
    self:InitializeCompanionEquipmentSheet()
    self:InitializeCompanionCollectibleSheet()
    self:InitializeCompanionOutfitStylesSheet()

    self.currentSheet = self.equipmentSheet

    self.outfitSelectorTutorialAnchor = ZO_Anchor:New(LEFT, self.modeSelectorDropdownControl, RIGHT, 10, 0)

    self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)

    self.onRefreshOutfitName = function(actorCategory, outfitIndex)
        local KEEP_CURRENT_SELECTION = true
        if self.currentSheet == self.equipmentSheet or self.currentSheet == self.outfitStylesSheet then
            self:PopulateEquipmentModeDropdown(KEEP_CURRENT_SELECTION)
        end
    end

    self.onUpdateEquippedOutfit = function()
        if self.currentSheet ~= self.collectiblesSheet and self.currentSheet ~= self.companionCollectiblesSheet then
            if self.currentSheet == self.equipmentSheet or self.currentSheet == self.outfitStylesSheet then
                self:PopulateEquipmentModeDropdown()
            elseif self.currentSheet == self.companionEquipmentSheet or self.currentSheet == self.companionOutfitStylesSheet then
                self:PopulateCompanionOutfitsModeDropdown()
            end
        end
    end
end

function ZO_RestyleSheetWindow_Keyboard:InitializeModeSelector()
    local modeSelector = self.control:GetNamedChild("ModeSelector")
    self.modeSelectorHeader = modeSelector:GetNamedChild("Header")
    self.modeSelectorDropdownControl = modeSelector:GetNamedChild("Dropdown")
    self.modeSelectorDropdown = ZO_ComboBox_ObjectFromContainer(self.modeSelectorDropdownControl)
    self.modeSelectorDropdown:SetSortsItems(false)

    self.modeSelectorDropdown:SetPreshowDropdownCallback(function()
        TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_OUTFIT_SELECTOR_SHOWN_POINTER_BOX)
    end)

    local UNEQUIP_OUTFIT = nil

    self.setEquipmentGearSelectedFunction = function()
        self:DisplaySheet(self.equipmentSheet)
        ZO_OUTFIT_STYLES_PANEL_KEYBOARD:SetCurrentOutfitManipulator(UNEQUIP_OUTFIT)
        self.pendingEquipOutfitManipulator = UNEQUIP_OUTFIT
        ITEM_PREVIEW_KEYBOARD:PreviewUnequipOutfit(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
        self:FireCallbacks("ModeSelectorDropdownChanged")
    end

    self.setCompanionEquipmentGearSelectedFunction = function()
        self:DisplaySheet(self.companionEquipmentSheet)
        ZO_OUTFIT_STYLES_PANEL_KEYBOARD:SetCurrentOutfitManipulator(UNEQUIP_OUTFIT)
        self.pendingEquipOutfitManipulator = UNEQUIP_OUTFIT
        ITEM_PREVIEW_KEYBOARD:PreviewUnequipOutfit(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
        self:FireCallbacks("ModeSelectorDropdownChanged")
    end

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

    local function TrySetCompanionEquipmentGearSelected(_, _, entry, selectionChanged, oldEntry)
        if selectionChanged then
            if self:AreChangesPending() then
                local function Decline()
                    self.modeSelectorDropdown:SelectItem(oldEntry, IGNORE_CALLBACK)
                end

                self:ShowRevertRestyleChangesDialog("CONFIRM_REVERT_OUTFIT_ON_CHANGE", self.setCompanionEquipmentGearSelectedFunction, Decline)
            else
                self.setCompanionEquipmentGearSelectedFunction()
            end
        end
    end

    self.equipmentGearModeEntry = self.modeSelectorDropdown:CreateItemEntry(GetString(SI_NO_OUTFIT_EQUIP_ENTRY), TrySetEquipmentGearSelected)
    self.equipmentGearModeEntry.selectFunction = self.setEquipmentGearSelectedFunction
    self.collectiblesModeEntry = self.modeSelectorDropdown:CreateItemEntry("", function()
        self:DisplaySheet(self.collectiblesSheet)
    end)

    self.companionEquipmentGearModeEntry = self.modeSelectorDropdown:CreateItemEntry(GetString(SI_NO_OUTFIT_EQUIP_ENTRY), TrySetCompanionEquipmentGearSelected)
    self.companionEquipmentGearModeEntry.selectFunction = self.setCompanionEquipmentGearSelectedFunction
    self.companionCollectiblesModeEntry = self.modeSelectorDropdown:CreateItemEntry("", function()
        self:DisplaySheet(self.companionCollectiblesSheet)
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

    self.purchaseAdditionalOutfitsEntry = self.modeSelectorDropdown:CreateItemEntry(GetString(SI_OUTFIT_PURCHASE_MORE_ENTRY), OnPurchaseAdditionalOutfitsEntry)
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

function ZO_RestyleSheetWindow_Keyboard:InitializeCompanionEquipmentSheet()
    local slotGridData =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] =
        {
            [EQUIP_SLOT_SHOULDERS] = { row = 2, column = 1, controlName = "Shoulders" }, [EQUIP_SLOT_CHEST] = { row = 2, column = 2, controlName = "Chest" },
            [EQUIP_SLOT_HAND] = { row = 3, column = 1, controlName = "Hand" }, [EQUIP_SLOT_WAIST] = { row = 3, column = 2, controlName = "Waist" },
            [EQUIP_SLOT_LEGS] = { row = 4, column = 1, controlName = "Legs" }, [EQUIP_SLOT_FEET] = { row = 4, column = 2, controlName = "Feet" },
        },
        [ZO_RESTYLE_SHEET_CONTAINER.SECONDARY] =
        {
            -- Switches with Shield on show based on ActiveWeaponPair
            [EQUIP_SLOT_OFF_HAND] = { row = 1, column = 2, controlName = "Shield" },
        }
    }
    self.companionEquipmentSheet = self:InitializeSheet(ZO_RestyleCompanionEquipmentSlotsSheet, slotGridData)
end

function ZO_RestyleSheetWindow_Keyboard:InitializeCompanionCollectibleSheet()
    local slotGridData =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] =
        {
            [COLLECTIBLE_CATEGORY_TYPE_COSTUME] = { row = 1, column = 2, controlName = "Costume" },
        },
    }
    self.companionCollectiblesSheet = self:InitializeSheet(ZO_RestyleCompanionCollectibleSlotsSheet, slotGridData)
end

function ZO_RestyleSheetWindow_Keyboard:InitializeCompanionOutfitStylesSheet()
    local slotGridData =
    {
        [ZO_RESTYLE_SHEET_CONTAINER.PRIMARY] =
        {
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
        },
    }
    self.companionOutfitStylesSheet = self:InitializeSheet(ZO_RestyleCompanionOutfitSlotsSheet, slotGridData)
end

function ZO_RestyleSheetWindow_Keyboard:OnShowing()
    TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_OUTFIT_SELECTOR_SHOWN_POINTER_BOX, self.control, ZO_RESTYLE_SHEET_WINDOW_FRAGMENT, self.outfitSelectorTutorialAnchor)
    ZO_OUTFIT_MANAGER:RegisterCallback("RefreshOutfitName", self.onRefreshOutfitName)
    ZO_OUTFIT_MANAGER:RegisterCallback("RefreshEquippedOutfitIndex", self.onUpdateEquippedOutfit)
end

function ZO_RestyleSheetWindow_Keyboard:BeginRestyling()
    BeginRestyling(self:GetCurrentSheet():GetRestyleMode())
end

function ZO_RestyleSheetWindow_Keyboard:OnHiding()
    ZO_OUTFIT_MANAGER:UnregisterCallback("RefreshOutfitName", self.onRefreshOutfitName)
    ZO_OUTFIT_MANAGER:UnregisterCallback("RefreshEquippedOutfitIndex", self.onUpdateEquippedOutfit)
    local currentEquippedIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(self:GetCurrentSheet():GetRestyleMode()))
    if (not self.pendingEquipOutfitManipulator and currentEquippedIndex) or (self.pendingEquipOutfitManipulator and self.pendingEquipOutfitManipulator:GetOutfitIndex() ~= currentEquippedIndex) then
        self:EquipSelectedOutfit()
    end
end

function ZO_RestyleSheetWindow_Keyboard:OnHidden()
    EndRestyling()
end

function ZO_RestyleSheetWindow_Keyboard:PopulateEquipmentModeDropdown(keepCurrentSelection)
    local currentSheet = self:GetCurrentSheet()
    if currentSheet ~= self.equipmentSheet and currentSheet ~= self.outfitStylesSheet then
        self:EquipSelectedOutfit()
        ITEM_PREVIEW_KEYBOARD:ResetOutfitPreview()
    end

    self.modeSelectorHeader:SetText(GetString(SI_RESTYLE_SHEET_SELECT_OUTFIT_HEADER))

    local actorCategory = GAMEPLAY_ACTOR_CATEGORY_PLAYER
    local reselectOutfitIndex = nil
    if keepCurrentSelection then
        local selectedData = self.modeSelectorDropdown:GetSelectedItemData()
        if selectedData and selectedData.outfitManipulator then
            reselectOutfitIndex = selectedData.outfitManipulator:GetOutfitIndex()
            actorCategory = selectedData.outfitManipulator:GetActorCategory()
        end
    end

    self.modeSelectorDropdown:ClearItems()

    self.modeSelectorDropdown:AddItem(self.equipmentGearModeEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)

    local function SetSelectedOutfit(entry)
        local outfitManipulator = entry.outfitManipulator
        self.outfitStylesSheet:SetOutfitManipulator(outfitManipulator)
        ZO_OUTFIT_STYLES_PANEL_KEYBOARD:SetCurrentOutfitManipulator(outfitManipulator)
        self.pendingEquipOutfitManipulator = outfitManipulator
        self:DisplaySheet(self.outfitStylesSheet)
        ITEM_PREVIEW_KEYBOARD:PreviewOutfit(outfitManipulator:GetActorCategory(), outfitManipulator:GetOutfitIndex())
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

    local equippedOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(actorCategory)
    local defaultEntry = self.equipmentGearModeEntry

    local autoSelectIndex = keepCurrentSelection and reselectOutfitIndex or equippedOutfitIndex
    local numOutfits = ZO_OUTFIT_MANAGER:GetNumOutfits(actorCategory)
    for outfitIndex = 1, numOutfits do
        local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(actorCategory, outfitIndex)
        local entry = self.modeSelectorDropdown:CreateItemEntry(outfitManipulator:GetOutfitName(), TrySetSelectedOutfit)
        entry.outfitManipulator = outfitManipulator
        entry.selectFunction = SetSelectedOutfit
        self.modeSelectorDropdown:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
        if autoSelectIndex == outfitIndex then
            defaultEntry = entry
        end
    end

    if numOutfits < MAX_OUTFIT_UNLOCKS then
        self.modeSelectorDropdown:AddItem(self.purchaseAdditionalOutfitsEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end

    self.modeSelectorDropdown:UpdateItems()
    self.modeSelectorDropdown:SelectItem(defaultEntry, true)
    defaultEntry.selectFunction(defaultEntry)

    self:OnUpdateModeSelectorDropdown()
end

function ZO_RestyleSheetWindow_Keyboard:PopulateCollectiblesModeDropdown()
    local currentSheet = self:GetCurrentSheet()
    if currentSheet ~= self.collectiblesSheet or currentSheet ~= self.companionCollectiblesSheet then
        self:EquipSelectedOutfit()
        ITEM_PREVIEW_KEYBOARD:ResetOutfitPreview()
    end

    self.modeSelectorDropdown:ClearItems()

    self.modeSelectorDropdown:AddItem(self.collectiblesModeEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)

    self.modeSelectorDropdown:UpdateItems()
    self.modeSelectorDropdown:SelectFirstItem()

    ITEM_PREVIEW_KEYBOARD:ClearPreviewCollection();
    ApplyChangesToPreviewCollectionShown();

    self:OnUpdateModeSelectorDropdown()
end

function ZO_RestyleSheetWindow_Keyboard:PopulateCompanionOutfitsModeDropdown(keepCurrentSelection)
    local currentSheet = self:GetCurrentSheet()
    if currentSheet ~= self.companionEquipmentSheet and currentSheet ~= self.companionOutfitStylesSheet then
        self:EquipSelectedOutfit()
        ITEM_PREVIEW_KEYBOARD:ResetOutfitPreview()
    end

    self.modeSelectorHeader:SetText(GetString(SI_RESTYLE_SHEET_SELECT_OUTFIT_HEADER))

    local actorCategory = GAMEPLAY_ACTOR_CATEGORY_COMPANION
    local reselectOutfitIndex = nil
    if keepCurrentSelection then
        local selectedData = self.modeSelectorDropdown:GetSelectedItemData()
        if selectedData and selectedData.outfitManipulator then
            reselectOutfitIndex = selectedData.outfitManipulator:GetOutfitIndex()
            actorCategory = selectedData.outfitManipulator:GetActorCategory()
        end
    end

    self.modeSelectorDropdown:ClearItems()

    self.modeSelectorDropdown:AddItem(self.companionEquipmentGearModeEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)

    local function SetSelectedOutfit(entry)
        local outfitManipulator = entry.outfitManipulator
        self.companionOutfitStylesSheet:SetOutfitManipulator(outfitManipulator)
        ZO_OUTFIT_STYLES_PANEL_KEYBOARD:SetCurrentOutfitManipulator(outfitManipulator)
        self.pendingEquipOutfitManipulator = outfitManipulator
        self:DisplaySheet(self.companionOutfitStylesSheet)
        ITEM_PREVIEW_KEYBOARD:PreviewOutfit(outfitManipulator:GetActorCategory(), outfitManipulator:GetOutfitIndex())
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
    local equippedOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(actorCategory)
    local defaultEntry = self.companionEquipmentGearModeEntry

    local autoSelectIndex = keepCurrentSelection and reselectOutfitIndex or equippedOutfitIndex
    local numOutfits = ZO_OUTFIT_MANAGER:GetNumOutfits(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    for outfitIndex = 1, numOutfits do
        local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(actorCategory, outfitIndex)
        local entry = self.modeSelectorDropdown:CreateItemEntry(outfitManipulator:GetOutfitName(), TrySetSelectedOutfit)
        entry.outfitManipulator = outfitManipulator
        entry.selectFunction = SetSelectedOutfit
        self.modeSelectorDropdown:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
        if autoSelectIndex == outfitIndex then
            defaultEntry = entry
        end
    end

    self.modeSelectorDropdown:UpdateItems()
    self.modeSelectorDropdown:SelectItem(defaultEntry, true)
    defaultEntry.selectFunction(defaultEntry)

    self:OnUpdateModeSelectorDropdown()
end

function ZO_RestyleSheetWindow_Keyboard:PopulateCompanionCollectiblesModeDropdown()
    local currentSheet = self:GetCurrentSheet()
    if currentSheet ~= self.collectiblesSheet or currentSheet ~= self.companionCollectiblesSheet then
        self:EquipSelectedOutfit()
        ITEM_PREVIEW_KEYBOARD:ResetOutfitPreview()
    end

    self.modeSelectorDropdown:ClearItems()

    self.modeSelectorDropdown:AddItem(self.companionCollectiblesModeEntry, ZO_COMBOBOX_SUPPRESS_UPDATE)

    self.modeSelectorDropdown:UpdateItems()
    self.modeSelectorDropdown:SelectFirstItem()

    ITEM_PREVIEW_KEYBOARD:ClearPreviewCollection();
    ApplyChangesToPreviewCollectionShown();

    self:OnUpdateModeSelectorDropdown()
end

function ZO_RestyleSheetWindow_Keyboard:OnUpdate()
    local isPreviewingAvailable = IsCharacterPreviewingAvailable()
    if self.isPreviewAvailable ~= isPreviewingAvailable then
        self.isPreviewAvailable = isPreviewingAvailable
        self.modeSelectorDropdown:SetEnabled(self.isPreviewAvailable)
    end
end

function ZO_RestyleSheetWindow_Keyboard:OnUpdateModeSelectorDropdown()
    local isEthereal = self.modeSelectorDropdown:GetNumItems() == 1
    self.modeSelectorHeader:SetHidden(isEthereal)
    self.modeSelectorDropdownControl:SetHidden(isEthereal)
end

function ZO_RestyleSheetWindow_Keyboard:DisplaySheet(newSheet)
    local isPreviewUpdated = false
    local currentSheet = self:GetCurrentSheet()
    if currentSheet ~= newSheet then
        if currentSheet then
            SCENE_MANAGER:RemoveFragment(currentSheet:GetFragment())
        end

        local oldSheet = currentSheet
        self.currentSheet = newSheet

        if newSheet then
            -- make sure the current sheet has the latest dye data for its slots
            SetRestylePreviewMode(newSheet:GetRestyleMode())
            isPreviewUpdated = true
        end

        self:FireCallbacks("SheetChanged", newSheet, oldSheet)
    end

    if newSheet then
        if not isPreviewUpdated then
            -- make sure the current sheet has the latest dye data for its slots
            SetRestylePreviewMode(newSheet:GetRestyleMode())
        end

        SCENE_MANAGER:AddFragment(newSheet:GetFragment())

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
    self:PerformDeferredInitialize()
    return self.currentSheet
end

function ZO_RestyleSheetWindow_Keyboard:GetSheetByMode(restyleMode)
    self:PerformDeferredInitialize()
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
                self:GetCurrentSheet():ToggleDyeableSlotHightlight(highlightSlot, true, highlightDyeChannel)
                WINDOW_MANAGER:SetMouseCursor(activeTool:GetCursorType())
            end

            local dyeId = select(dyeChannel, restyleSlotData:GetPendingDyes())
            if dyeId ~= 0 then
                local playerDyeInfo = ZO_DYEING_MANAGER:GetPlayerDyeInfoById(dyeId)
                if playerDyeInfo then
                    local anchoringControl = dyeControl
                    local isRightAnchored = false
                    ZO_Dyeing_CreateTooltipOnMouseEnter(anchoringControl, playerDyeInfo.dyeName, playerDyeInfo.known, playerDyeInfo.achievementId, IS_PLAYER_DYE, isRightAnchored)
                else
                    local nonPlayerDye = ZO_DYEING_MANAGER:GetOrCreateNonPlayerDyeInfoById(dyeId)
                    if nonPlayerDye.dyeName ~= "" then
                        ZO_Dyeing_CreateTooltipOnMouseEnter(dyeControl, nonPlayerDye.dyeName, UNKNOWN_DYE, nonPlayerDye.achievementId, IS_NON_PLAYER_DYE, IS_LEFT_ANCHORED)
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
            self:GetCurrentSheet():ToggleDyeableSlotHightlight(NO_SLOT, false, NO_CHANNEL)
            WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
            ZO_Dyeing_ClearTooltipOnMouseExit()
        end
    end
end

function ZO_RestyleSheetWindow_Keyboard:EquipSelectedOutfit()
    if self.pendingEquipOutfitManipulator then
        ZO_OUTFIT_MANAGER:EquipOutfit(self.pendingEquipOutfitManipulator:GetActorCategory(), self.pendingEquipOutfitManipulator:GetOutfitIndex())
    else
        local actorCategory = ZO_OUTFIT_MANAGER.GetActorCategoryByRestyleMode(self:GetCurrentSheet():GetRestyleMode())
        if actorCategory then
            ZO_OUTFIT_MANAGER:UnequipOutfit(actorCategory)
        end
    end
end

function ZO_RestyleSheetWindow_Keyboard:ShowUndoPendingChangesDialog()
    ZO_Dialogs_ShowDialog("CONFIRM_REVERT_OUTFIT_CHANGES", { confirmCallback = function() self:GetCurrentSheet():UndoPendingChanges() end})
end

function ZO_RestyleSheetWindow_Keyboard:UndoPendingChanges()
    self:GetCurrentSheet():UndoPendingChanges()
end

function ZO_RestyleSheetWindow_Keyboard:AreChangesPending()
    return self:GetCurrentSheet():AreChangesPending()
end

function ZO_RestyleSheetWindow_Keyboard:CanApplyChanges()
    return self:GetCurrentSheet():CanApplyChanges()
end

function ZO_RestyleSheetWindow_Keyboard_OnInitialized(control)
    ZO_RESTYLE_SHEET_WINDOW_KEYBOARD = ZO_RestyleSheetWindow_Keyboard:New(control)
end