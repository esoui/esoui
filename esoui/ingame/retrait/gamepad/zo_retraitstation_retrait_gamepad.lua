ZO_RetraitStation_Retrait_Gamepad = ZO_RetraitStation_Retrait_Base:Subclass()

function ZO_RetraitStation_Retrait_Gamepad:Initialize(control, interactScene)
    ZO_RetraitStation_Retrait_Base.Initialize(self, control, "retrait_gamepad")

    GAMEPAD_RETRAIT_FRAGMENT = ZO_FadeSceneFragment:New(control)
    interactScene:AddFragment(GAMEPAD_RETRAIT_FRAGMENT)

    interactScene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_HIDING then
            self:OnHiding()
        end
    end)

    self.sourceTooltip = self.control:GetNamedChild("SourceTooltip")
    self.sourceTooltip.tip:SetClearOnHidden(false)
    self.qualityBridge = self.control:GetNamedChild("QualityBridge")
    self.resultTooltip = self.control:GetNamedChild("ResultTooltip")

    --Register the source tooltip for narration
    local sourceTooltipNarrationInfo = 
    {
        canNarrate = function()
            return not self.sourceTooltip:IsHidden()
        end,
        tooltipNarrationFunction = function()
            local narration = self.sourceTooltip.tip:GetNarrationText()
            --If the result tooltip is showing, add an additional bit of narration to the front that tells us this is the current item
            if not self.resultTooltip:IsHidden() then
                narration = { GetString(SI_GAMEPAD_RETRAIT_CURRENT_ITEM_NARRATION), narration }
            end
            return narration
        end,
    }
    GAMEPAD_TOOLTIPS:RegisterCustomTooltipNarration(sourceTooltipNarrationInfo)

    --Register the result tooltip for narration
    local resultTooltipNarrationInfo = 
    {
        canNarrate = function()
            return not self.resultTooltip:IsHidden()
        end,
        tooltipNarrationFunction = function()
            return { GetString(SI_GAMEPAD_RETRAIT_UPDATED_ITEM_NARRATION), self.resultTooltip.tip:GetNarrationText()}
        end,
    }
    GAMEPAD_TOOLTIPS:RegisterCustomTooltipNarration(resultTooltipNarrationInfo)

    --Register the list of inventory items for narration
    --Order matters, do this before we initialize the header
    local narrationInfo = 
    {
        canNarrate = function()
            return self:IsShowing()
        end,
        headerNarrationFunction = function()
            return ZO_GamepadGenericHeader_GetNarrationText(self.header, self.headerData)
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.inventory.list, narrationInfo)

    self:InitializeHeader()

    self.currentFilter = SMITHING_FILTER_TYPE_WEAPONS
    self:InitializeTraitList()
end

function ZO_RetraitStation_Retrait_Gamepad:InitializeInventory()
    self.inventoryControl = self.control:GetNamedChild("MaskInventory")
    self.inventory = ZO_Retrait_Inventory_Gamepad:New(self, self.inventoryControl, SLOT_TYPE_CRAFTING_COMPONENT)

    self.itemActions = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_LEFT, ADDITIONAL_OVERBINDS, DONT_USE_KEYBIND_STRIP)
    self.itemActions:SetUseKeybindStrip(false)

    self.inventory.list:SetOnTargetDataChangedCallback(function(list, targetData)
        self:SetSourceItem(targetData)
    end)
end

function ZO_RetraitStation_Retrait_Gamepad:InitializeTraitList()
    self.traitListContainer = self.control:GetNamedChild("MaskTraitContainer")
    local traitListControl = self.traitListContainer:GetNamedChild("List")
    self.traitList = ZO_GamepadVerticalItemParametricScrollList:New(traitListControl)
    self.traitList:SetAlignToScreenCenter(true)

    self.traitList:AddDataTemplate("ZO_GamepadMenuEntryTemplateLowercase42", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    self.traitList:SetOnTargetDataChangedCallback(function(list, targetData)
        self:ShowRetraitResult(true)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end)

    --Register the trait list for narration
    local narrationInfo = 
    {
        canNarrate = function()
            return self:IsShowing()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.traitList, narrationInfo)
end

function ZO_RetraitStation_Retrait_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- need to have special exits for this scene
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Retrait Exit",
            keybind = "UI_SHORTCUT_EXIT",
            callback = function()
                SCENE_MANAGER:ShowBaseScene()
            end,
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            ethereal = true,
        },

        {
            name = function()
                if self.traitList:IsActive() then
                    return GetString(SI_ITEM_ACTION_REMOVE_FROM_CRAFT)
                else
                    return GetString(SI_GAMEPAD_BACK_OPTION)
                end
            end,
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                if self.traitList:IsActive() then
                    self:RemoveItemFromRetrait()
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
                else
                    SCENE_MANAGER:HideCurrentScene()
                end
            end,
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end
        },

        -- Select
        {
            name = function()
                if self.traitList:IsActive() then
                    local retraitCost, retraitCurrency, retraitCurrencyLocation = GetItemRetraitCost()
                    local currencyFormat = ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON
                    if retraitCost > GetCurrencyAmount(retraitCurrency, retraitCurrencyLocation) then
                        currencyFormat = ZO_CURRENCY_FORMAT_ERROR_AMOUNT_ICON
                    end

                    local formattedRetraitCost = ZO_Currency_FormatPlatform(retraitCurrency, retraitCost, currencyFormat)
                    return zo_strformat(SI_RETRAIT_STATION_PERFORM_RETRAIT_WITH_COST, formattedRetraitCost)
                else
                    return GetString(SI_ITEM_ACTION_ADD_TO_CRAFT)
                end
            end,
            narrationOverrideName = function()
                if self.traitList:IsActive() then
                    local retraitCost, retraitCurrency, retraitCurrencyLocation = GetItemRetraitCost()
                    local formattedRetraitCost = ZO_Currency_FormatPlatform(retraitCurrency, retraitCost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
                    return zo_strformat(SI_RETRAIT_STATION_PERFORM_RETRAIT_WITH_COST, formattedRetraitCost)
                else
                    return GetString(SI_ITEM_ACTION_ADD_TO_CRAFT)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible =  function()
                return self.inventory:CurrentSelection() and not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            enabled = function()
                if self.traitList:IsActive() then
                    local targetTrait = self.traitList:GetTargetData()
                    if targetTrait then
                        if not targetTrait:IsEnabled() then
                            return false
                        end
                        local retraitCost, retraitCurrency, retraitCurrencyLocation = GetItemRetraitCost()
                        local hasEnoughCurrency = retraitCost <= GetCurrencyAmount(retraitCurrency, retraitCurrencyLocation)
                        if not hasEnoughCurrency then
                            return false, GetString("SI_RETRAITRESPONSE", RETRAIT_RESPONSE_INSUFFICIENT_FUNDS)
                        end
                    else
                        return false
                    end
                end

                return true
            end,
            callback = function()
                if self.traitList:IsActive() then
                    self:PerformRetrait()
                else
                    self:AddItemToRetrait()
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
                end
            end,
        },

        -- Item Options
        {
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                self:ShowItemActions()
            end,
            visible = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess() and self.inventory:CurrentSelection() ~= nil and not self.traitList:IsActive()
            end
        },
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.inventory.list)
end

function ZO_RetraitStation_Retrait_Gamepad:InitializeHeader()
    self.header = self.control:GetNamedChild("HeaderContainerHeader")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    local function OnInventoryUpdate()
        if not self.control:IsHidden() then
            self:RefreshHeader()
        end
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryUpdate)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventoryUpdate)

    local function OnCurrencyUpdate(currencyType, currencyLocation, newAmount, oldAMount, reason)
        if not self.control:IsHidden() and currencyType == CURT_CHAOTIC_CREATIA then
            self:RefreshHeader()
        end
    end

    self.control:RegisterForEvent(EVENT_CURRENCY_UPDATE, OnCurrencyUpdate)

    local function CreateTabEntryForFilter(smithingFilter)
        return 
        {
            text = GetString("SI_SMITHINGFILTERTYPE", smithingFilter),
            callback =  function()
                self:OnFilterChanged(smithingFilter)
                --Re-narrate on tab change
                local NARRATE_HEADER = true
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.inventory.list, NARRATE_HEADER)
            end,
            mode = smithingFilter,
        }
    end

    local tabBarEntries = 
    {
        CreateTabEntryForFilter(SMITHING_FILTER_TYPE_WEAPONS),
        CreateTabEntryForFilter(SMITHING_FILTER_TYPE_ARMOR),
        CreateTabEntryForFilter(SMITHING_FILTER_TYPE_JEWELRY),
    }

    local function GetCapacity()
        return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
    end

    local HAS_ENOUGH = false
    local displayOptions =
    {
        currencyCapAmount = GetMaxPossibleCurrency(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT),
    }
    local function SetChaoticCreatiaAmount(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_CHAOTIC_CREATIA, GetCurrencyAmount(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT, CURRENCY_SHOW_ALL, HAS_ENOUGH, displayOptions)
        -- must return a non-nil value so that the control isn't auto-hidden
        return true
    end

    local CURRENCY_NARRATION_OPTIONS = 
    {
        showCap = true,
        currencyLocation = CURRENCY_LOCATION_ACCOUNT,
    }
    local function GetChaoticCreatiaAmountNarration()
        return ZO_Currency_FormatGamepad(CURT_CHAOTIC_CREATIA, GetCurrencyAmount(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT), ZO_CURRENCY_FORMAT_AMOUNT_ICON, CURRENCY_NARRATION_OPTIONS)
    end

    local IS_PLURAL = false
    local IS_LOWER = true
    local retraitCurrencyName = GetCurrencyName(CURT_CHAOTIC_CREATIA, IS_PLURAL, IS_LOWER)

    self.headerData = 
    {
        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data1Text = GetCapacity,
        data2HeaderText = retraitCurrencyName,
        data2Text = SetChaoticCreatiaAmount,
        data2TextNarration = GetChaoticCreatiaAmountNarration,
        tabBarEntries = tabBarEntries,
    }

    self:RefreshHeader()
end

function ZO_RetraitStation_Retrait_Gamepad:RefreshHeader()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_RetraitStation_Retrait_Gamepad:OnShowing()
    self:AddKeybinds()
    self:SetInventoryActive(true)

    self:Refresh()

    self:RefreshHeader()
    ZO_GamepadGenericHeader_Activate(self.header)
end

function ZO_RetraitStation_Retrait_Gamepad:OnHiding()
    self.itemActions:SetInventorySlot(nil)
    self:RemoveKeybinds()
    self:SetInventoryActive(false)
    self:SetTraitListActive(false)

    ZO_GamepadGenericHeader_Deactivate(self.header)
    self:LayoutSourceItemTooltip()
    self:ShowRetraitResult(false)
    GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(nil)
end

function ZO_RetraitStation_Retrait_Gamepad:OnFilterChanged(filterType)
    self.filterType = filterType

    self.inventory:SetFilter(filterType)
    self:SetSourceItem(self.inventory:CurrentSelection())
end

function ZO_RetraitStation_Retrait_Gamepad:SetSourceItem(itemData)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self.itemActions:SetInventorySlot(itemData)

    self:LayoutSourceItemTooltip(itemData)
end

function ZO_RetraitStation_Retrait_Gamepad:AddKeybinds()
    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_RetraitStation_Retrait_Gamepad:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_RetraitStation_Retrait_Gamepad:Refresh()
    self.inventory:HandleDirtyEvent()
    ZO_RetraitStation_Retrait_Base.Refresh(self)
end

function ZO_RetraitStation_Retrait_Gamepad:ShowItemActions()
    local dialogData = 
    {
        targetData = self.inventory:CurrentSelection(),
        itemActions = self.itemActions,
    }

    ZO_Dialogs_ShowPlatformDialog(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG, dialogData)
end

function ZO_RetraitStation_Retrait_Gamepad:SetupTraitListEntryData(entryData, trait, bag, slot)
    entryData.trait = trait
    entryData.knownTrait = IsItemTraitKnownForRetraitResult(bag, slot, trait)

    entryData:SetEnabled(entryData.knownTrait)
    entryData:SetIconDisabledTintOnSelection(true)
end

function ZO_RetraitStation_Retrait_Gamepad:SetTraitListActive(active)
    if active then
        self.traitList:Activate()
    else
        self.traitList:Deactivate()
    end

    self.traitListContainer:SetHidden(not active)
end

function ZO_RetraitStation_Retrait_Gamepad:SetInventoryActive(active)
    if active then
        self.inventory:Activate()
        local targetData = self.inventory:CurrentSelection()
        self:LayoutSourceItemTooltip(targetData)
    else
        self.inventory:Deactivate()
    end

    self.inventoryControl:SetHidden(not active)
end

function ZO_RetraitStation_Retrait_Gamepad:RefreshTraitList()
    self.traitList:Clear()

    local bag, slot = self.inventory:CurrentSelectionBagAndSlot()
    local selectedItemTrait = GetItemTrait(bag, slot)
    local traitData = ZO_RETRAIT_STATION_MANAGER:GetTraitInfoForCategory(GetItemTraitCategory(bag, slot))
    internalassert(traitData)

    for index, traitRowData in ipairs(traitData) do
        if selectedItemTrait ~= traitRowData.traitType then
            local entryData = ZO_GamepadEntryData:New(traitRowData.traitName, traitRowData.traitItemIcon)
            self:SetupTraitListEntryData(entryData, traitRowData.traitType, bag, slot)

            self.traitList:AddEntry("ZO_GamepadMenuEntryTemplateLowercase42", entryData)
        end
    end

    self.traitList:Commit()
end

function ZO_RetraitStation_Retrait_Gamepad:AddItemToRetrait()
    -- rediscover inventory actions since they have changed
    self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    -- create the tooltip string for what research is required for this item now,
    -- so we don't have to create it every time we mouse over an unknown trait
    local bag, slot = self.inventory:CurrentSelectionBagAndSlot()
    self:UpdateRequireResearchTooltipString(bag, slot)

    self:RefreshTraitList()

    self:SetInventoryActive(false)
    self:SetTraitListActive(true)

    ZO_GamepadGenericHeader_Deactivate(self.header)

    self:ShowRetraitResult(true)
end

function ZO_RetraitStation_Retrait_Gamepad:RemoveItemFromRetrait()
    self:SetTraitListActive(false)
    self:SetInventoryActive(true)

    -- rediscover inventory actions since they have changed
    -- do this after setting the lists active/inactive since some of the actions/keybinds check that
    self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    ZO_GamepadGenericHeader_Activate(self.header)
    self:ShowRetraitResult(false)
end

function ZO_RetraitStation_Retrait_Gamepad:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    if self.traitList:IsActive() then
        local selectedBag, selectedSlot = self.inventory:CurrentSelectionBagAndSlot()
        return bagId == selectedBag and slotIndex == selectedSlot
    end

    return false
end

function ZO_RetraitStation_Retrait_Gamepad:AddItemToCraft(bagId, slotIndex)
    -- we just add the selected item to the craft, so make sure this matches
    local selectedBag, selectedSlot = self.inventory:CurrentSelectionBagAndSlot()
    if bagId == selectedBag and slotIndex == selectedSlot then
        self:AddItemToRetrait()
    end
end

function ZO_RetraitStation_Retrait_Gamepad:RemoveItemFromCraft(bagId, slotIndex)
    self:RemoveItemFromRetrait()
end

function ZO_RetraitStation_Retrait_Gamepad:PerformRetrait()
    if self.traitList:IsActive() then
        local bag, slot = self.inventory:CurrentSelectionBagAndSlot()
        local selectedTrait = self.traitList:GetTargetData().trait
        self:ShowRetraitDialog(bag, slot, selectedTrait)
    end
end

function ZO_RetraitStation_Retrait_Gamepad:OnRetraitAnimationsStopped(result)
    if self:IsShowing() then
        self:SetTraitListActive(false)
        self:SetInventoryActive(true)

        self.itemActions:SetInventorySlot(self.inventory:CurrentSelection())
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

        ZO_GamepadGenericHeader_Activate(self.header)
        self:ShowRetraitResult(false)
    end
end

do
    local CUSTOM_STACK_COUNT = 1
    local DONT_FORCE_FULL_DURABILITY = false
    local NO_PREVIEW_VALUE = nil
    local NO_TRADE_BOP_DATA = nil

    function ZO_RetraitStation_Retrait_Gamepad:LayoutSourceItemTooltip(itemData)
        self.sourceTooltip.tip:ClearLines()
        if itemData then
            local bagId = itemData.bagId
            local slotIndex = itemData.slotIndex
            local itemLink = GetItemLink(itemData.bagId, itemData.slotIndex)
            local equipped = bagId == BAG_WORN
            local equipSlot = equipped and slotIndex or EQUIP_SLOT_NONE
            local creatorName = GetItemCreatorName(bagId, slotIndex)
            local showPlayerLocked = IsItemPlayerLocked(bagId, slotIndex)

            local extraData =
            {
                bagId = bagId,
                slotIndex = slotIndex
            }

            self.sourceTooltip.tip:LayoutItemWithStackCount(itemLink, equipped, creatorName, DONT_FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, CUSTOM_STACK_COUNT, equipSlot, showPlayerLocked, NO_TRADE_BOP_DATA, extraData)
            self.sourceTooltip.icon:SetTexture(itemData.pressedIcon)
        end
        self.sourceTooltip:SetHidden(not itemData)
    end

    function ZO_RetraitStation_Retrait_Gamepad:LayoutResultItemTooltip(traitData)
        local itemData = self.inventory:CurrentSelection()
        self.resultTooltip.tip:ClearLines()
        if itemData and traitData then
            local bagId = itemData.bagId
            local slotIndex = itemData.slotIndex
            local resultItemLink = GetResultingItemLinkAfterRetrait(bagId, slotIndex, traitData.trait)
            local equipped = bagId == BAG_WORN
            local equipSlot = equipped and slotIndex or EQUIP_SLOT_NONE
            local creatorName = GetItemCreatorName(bagId, slotIndex)
            local showPlayerLocked = IsItemPlayerLocked(bagId, slotIndex)
            local extraData =
            {
                showTraitAsNew = true,
                bagId = bagId,
                slotIndex = slotIndex,
            }
            self.resultTooltip.tip:LayoutItemWithStackCount(resultItemLink, equipped, creatorName, DONT_FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, CUSTOM_STACK_COUNT, equipSlot, showPlayerLocked, NO_TRADE_BOP_DATA, extraData)
            self.resultTooltip.icon:SetTexture(itemData.pressedIcon)

            GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
            -- there's no chance of failure on the craft, so we'll fill out the fail sound with a sound that already exists instead of making a new one
            GAMEPAD_CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.RETRAITING_RETRAIT_TOOLTIP_GLOW_SUCCESS, SOUNDS.BLACKSMITH_IMPROVE_TOOLTIP_GLOW_FAIL)

            GAMEPAD_CRAFTING_RESULTS:ClearSecondaryTooltipAnimationControls()
            GAMEPAD_CRAFTING_RESULTS:AddSecondaryTooltipAnimationControl(self.sourceTooltip)
            GAMEPAD_CRAFTING_RESULTS:AddSecondaryTooltipAnimationControl(self.qualityBridge)
        end
    end
end

function ZO_RetraitStation_Retrait_Gamepad:ShowRetraitResult(show)
    local targetTraitData = self.traitList:GetTargetData()

    if not self.traitList:IsActive() or targetTraitData:IsEnabled() then
        self.sourceTooltip:SetHidden(false)
        self.sourceTooltip.scrollTooltip:ResetToTop()
        self.sourceTooltip:ClearAnchors()
        if show then
            local offsetX = 21
            self.sourceTooltip:SetAnchor(RIGHT, self.qualityBridge, LEFT, offsetX)
        else
            self.sourceTooltip:SetAnchor(CENTER, self.qualityBridge, CENTER)
        end

        self.qualityBridge:SetHidden(not show)

        if show then
            self:LayoutResultItemTooltip(targetTraitData)
        end
        self.resultTooltip:SetHidden(not show)

        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    else
        self.sourceTooltip:SetHidden(true)
        self.qualityBridge:SetHidden(true)
        self.resultTooltip:SetHidden(true)

        GAMEPAD_TOOLTIPS:LayoutUnknownRetraitTrait(GAMEPAD_LEFT_TOOLTIP, targetTraitData:GetText(), self.requiredResearchTooltipString)
    end
end

-----
-- ZO_Retrait_Inventory_Gamepad
-----

ZO_Retrait_Inventory_Gamepad = ZO_GamepadCraftingInventory:Subclass()

function ZO_Retrait_Inventory_Gamepad:New(...)
    return ZO_GamepadCraftingInventory.New(self, ...)
end

function ZO_Retrait_Inventory_Gamepad:Initialize(owner, control, ...)
    ZO_GamepadCraftingInventory.Initialize(self, control, ...)

    self.owner = owner
    self.filterType = SMITHING_FILTER_TYPE_WEAPONS
    self:SetCustomSort(function(bagId, slotIndex)
        --Sort equipped items to the top of the list
        --but items from other bags will be equal so they sort by category name
        if bagId == BAG_WORN then
            return 0
        else
            return 1
        end
    end)

    self:SetCustomBestItemCategoryNameFunction(function(slotData)
        if slotData.bagId == BAG_WORN then
            local equipSlot = GetItemComparisonEquipSlots(slotData.bagId, slotData.slotIndex)
            local visualCategory = ZO_Character_GetEquipSlotVisualCategory(equipSlot)
            slotData.bestItemCategoryName = zo_strformat(SI_GAMEPAD_SECTION_HEADER_EQUIPPED_ITEM, GetString("SI_EQUIPSLOTVISUALCATEGORY", visualCategory))
        else
            slotData.bestItemCategoryName = ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(slotData)
        end
    end)

    self:SetCustomExtraData(function(bagId, slotIndex, data)
        data:SetIgnoreTraitInformation(true)
    end)
end

function ZO_Retrait_Inventory_Gamepad:GetCurrentFilterType()
    return self.filterType
end

function ZO_Retrait_Inventory_Gamepad:Refresh(data)
    local USE_WORN_BAG = true
    self:GetIndividualInventorySlotsAndAddToScrollData(ZO_RetraitStation_CanItemBeRetraited, ZO_RetraitStation_DoesItemPassFilter, self.filterType, data, USE_WORN_BAG)
end

function ZO_Retrait_Inventory_Gamepad:SetFilter(filterType)
    self.filterType = filterType

    self:SetNoItemLabelText(GetString("SI_SMITHINGFILTERTYPE_IMPROVENONE", self.filterType))

    self:HandleDirtyEvent()
end
