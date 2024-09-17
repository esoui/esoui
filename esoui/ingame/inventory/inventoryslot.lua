local slotTypeIndex = 0
local function CreateSlotType(slotType)
    slotTypeIndex = slotTypeIndex + 1
    _G[slotType] = slotTypeIndex
end

CreateSlotType("SLOT_TYPE_QUEST_ITEM")
CreateSlotType("SLOT_TYPE_ITEM")
CreateSlotType("SLOT_TYPE_EQUIPMENT")
CreateSlotType("SLOT_TYPE_MY_TRADE")
CreateSlotType("SLOT_TYPE_THEIR_TRADE")
CreateSlotType("SLOT_TYPE_STORE_BUY")
CreateSlotType("SLOT_TYPE_STORE_BUYBACK")
CreateSlotType("SLOT_TYPE_BUY_MULTIPLE")
CreateSlotType("SLOT_TYPE_BANK_ITEM")
CreateSlotType("SLOT_TYPE_GUILD_BANK_ITEM")
CreateSlotType("SLOT_TYPE_MAIL_QUEUED_ATTACHMENT")
CreateSlotType("SLOT_TYPE_MAIL_ATTACHMENT")
CreateSlotType("SLOT_TYPE_LOOT")
CreateSlotType("SLOT_TYPE_ACHIEVEMENT_REWARD")
CreateSlotType("SLOT_TYPE_PENDING_CHARGE")
CreateSlotType("SLOT_TYPE_ENCHANTMENT")
CreateSlotType("SLOT_TYPE_ENCHANTMENT_RESULT")
CreateSlotType("SLOT_TYPE_TRADING_HOUSE_POST_ITEM")
CreateSlotType("SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT")
CreateSlotType("SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING")
CreateSlotType("SLOT_TYPE_REPAIR")
CreateSlotType("SLOT_TYPE_PENDING_REPAIR")
CreateSlotType("SLOT_TYPE_STACK_SPLIT")
CreateSlotType("SLOT_TYPE_CRAFTING_COMPONENT")
CreateSlotType("SLOT_TYPE_PENDING_CRAFTING_COMPONENT")
CreateSlotType("SLOT_TYPE_MULTIPLE_PENDING_CRAFTING_COMPONENTS")
CreateSlotType("SLOT_TYPE_SMITHING_MATERIAL")
CreateSlotType("SLOT_TYPE_SMITHING_STYLE")
CreateSlotType("SLOT_TYPE_SMITHING_TRAIT")
CreateSlotType("SLOT_TYPE_SMITHING_BOOSTER")
CreateSlotType("SLOT_TYPE_LIST_DIALOG_ITEM")
CreateSlotType("SLOT_TYPE_DYEABLE_EQUIPMENT")
CreateSlotType("SLOT_TYPE_GUILD_SPECIFIC_ITEM")
CreateSlotType("SLOT_TYPE_LAUNDER")
CreateSlotType("SLOT_TYPE_GAMEPAD_INVENTORY_ITEM")
CreateSlotType("SLOT_TYPE_COLLECTIONS_INVENTORY")
CreateSlotType("SLOT_TYPE_CRAFT_BAG_ITEM")
CreateSlotType("SLOT_TYPE_PENDING_RETRAIT_ITEM")

local UpdateMouseoverCommand

--
-- Setup
--

function ZO_InventorySlot_SetType(slotControl, slotType)
    slotControl.slotType = slotType
end

function ZO_InventorySlot_GetType(slotControl)
    return slotControl.slotType
end

function ZO_InventorySlot_GetStackCount(slotControl)
    return slotControl.stackCount or 0
end

local splittableTypes =
{
    [SLOT_TYPE_BANK_ITEM] = true,
    [SLOT_TYPE_ITEM] = true,
    [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM] = true,
}

function ZO_InventorySlot_IsSplittableType(slotControl)
    return splittableTypes[slotControl.slotType]
end

function ZO_ItemSlot_SetupIconUsableAndLockedColor(control, meetsUsageRequirement, locked)
    if meetsUsageRequirement == nil then
        meetsUsageRequirement = true
    end

    if locked == nil then
        locked = false
    end

    if control then
        if meetsUsageRequirement then
            control:SetColor(1, 1, 1)
        else 
            control:SetColor(1, 0, 0)
        end

        if locked then
            control:SetAlpha(0.5)
        else
            control:SetAlpha(1)
        end
    end
end

function ZO_ItemSlot_SetupTextUsableAndLockedColor(control, meetsUsageRequirement, locked)
    if locked == nil then
        locked = false
    end

    if control then
        if locked then
            control:SetAlpha(0.3)
        else
            control:SetAlpha(1)
        end
    end
end

function ZO_ItemSlot_SetupUsableAndLockedColor(slotControl, meetsUsageRequirement, locked)
    local iconControl = GetControl(slotControl, "Icon")
    ZO_ItemSlot_SetupIconUsableAndLockedColor(iconControl, meetsUsageRequirement, locked)
end

local USE_LOWERCASE_NUMBER_SUFFIXES = false

function ZO_ItemSlot_SetupSlotBase(slotControl, stackCount, iconFile, meetsUsageRequirement, locked, visible)
    local showSlot = true
    if type(visible) == "function" then
        showSlot = visible()
    elseif visible ~= nil then
        showSlot = visible
    end

    slotControl:SetHidden(not showSlot)

    local iconControl = GetControl(slotControl, "Icon")
    if iconControl then
        if iconFile == nil or iconFile == "" then
            iconControl:SetHidden(true)
        else
            iconControl:SetTexture(iconFile)
            iconControl:SetHidden(false)
        end
    end

    slotControl.stackCount = stackCount
    local stackCountLabel = GetControl(slotControl, "StackCount")
    if stackCount > 1 or slotControl.alwaysShowStackCount then
        stackCountLabel:SetText(ZO_AbbreviateAndLocalizeNumber(stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
    else
        stackCountLabel:SetText("")
    end
end

function ZO_ItemSlot_SetupSlot(slotControl, stackCount, iconFile, meetsUsageRequirement, locked, visible)
    ZO_ItemSlot_SetupSlotBase(slotControl, stackCount, iconFile, meetsUsageRequirement, locked, visible)

    -- Looks like this can be combined with the logic above, but certain animations (crafting) cannot
    -- call ZO_ItemSlot_SetupUsableAndLockedColor, so keep that in mind if refactoring.
    if stackCount > 1 or slotControl.alwaysShowStackCount then
        local stackCountLabel = GetControl(slotControl, "StackCount")
        if slotControl.minStackCount and stackCount < slotControl.minStackCount then
            stackCountLabel:SetColor(1, 0, 0)
        else
            stackCountLabel:SetColor(1, 1, 1)
        end
    end

    ZO_ItemSlot_SetupUsableAndLockedColor(slotControl, meetsUsageRequirement, locked)
end

function ZO_ItemSlot_SetAlwaysShowStackCount(slotControl, alwaysShowStackCount, minStackCount)
    slotControl.alwaysShowStackCount = alwaysShowStackCount
    slotControl.minStackCount = minStackCount or 1
end

function ZO_ItemSlot_GetAlwaysShowStackCount(slotControl)
    return slotControl.alwaysShowStackCount
end

-- Bind a slot control to a specific type/bag/slot
-- This should be called for all item slots (trade, mail, store, backpack, bank, crafting, etc...)
-- The meaning of slotIndex/bagId are specific to those systems, but this is the API to bind the
-- data to the UI control.
function ZO_Inventory_BindSlot(slotControl, slotType, slotIndex, bagId)
    ZO_InventorySlot_SetType(slotControl, slotType)
    slotControl.slotIndex = slotIndex
    slotControl.bagId = bagId
end

function ZO_Inventory_GetBagAndIndex(slotControl)
    return slotControl.bagId, ZO_Inventory_GetSlotIndex(slotControl)
end

function ZO_Inventory_GetSlotIndex(slotControl)
    return slotControl.slotIndex
end

function ZO_Inventory_GetSlotDataForInventoryControl(slotControl)
    local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(slotControl)
    return SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
end

function ZO_Inventory_SetupSlot(slotControl, stackCount, iconFile, meetsUsageRequirement, locked)
    ZO_ItemSlot_SetupSlot(slotControl, stackCount, iconFile, meetsUsageRequirement, locked)

    slotControl.inCooldown = false
    slotControl.cooldown = GetControl(slotControl, "Cooldown")
    slotControl.cooldown:SetTexture(iconFile)

    ZO_InventorySlot_UpdateCooldowns(slotControl)
end

function ZO_Inventory_SetupQuestSlot(slotControl, questIndex, toolIndex, stepIndex, conditionIndex)
    slotControl.questIndex = questIndex
    slotControl.toolIndex = toolIndex
    slotControl.stepIndex = stepIndex
    slotControl.conditionIndex = conditionIndex
end

--Player Inventory Row

function ZO_PlayerInventorySlot_SetupUsableAndLockedColor(slotControl, meetsUsageRequirement, locked)
    ZO_ItemSlot_SetupTextUsableAndLockedColor(slotControl:GetNamedChild("Name"), meetsUsageRequirement, locked)
    ZO_ItemSlot_SetupTextUsableAndLockedColor(slotControl:GetNamedChild("SellPriceText"), meetsUsageRequirement, locked)
    ZO_ItemSlot_SetupUsableAndLockedColor(slotControl:GetNamedChild("Button"), meetsUsageRequirement, locked)
end

function ZO_PlayerInventorySlot_SetupSlot(slotControl, stackCount, iconFile, meetsUsageRequirement, locked)
    ZO_Inventory_SetupSlot(slotControl:GetNamedChild("Button"), stackCount, iconFile, meetsUsageRequirement, locked)
    ZO_PlayerInventorySlot_SetupUsableAndLockedColor(slotControl, meetsUsageRequirement, locked)
end

--
-- Control Utils
--

function ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
    -- Figure out what got passed in...inventorySlot could be a list or button type...
    local buttonPart = inventorySlot
    local listPart
    local multiIconPart

    local controlType = inventorySlot:GetType()
    if controlType == CT_CONTROL and buttonPart.slotControlType and buttonPart.slotControlType == "listSlot" then
        listPart = inventorySlot
        buttonPart = inventorySlot:GetNamedChild("Button")
        multiIconPart = inventorySlot:GetNamedChild("MultiIcon")
    elseif controlType == CT_BUTTON then
        listPart = buttonPart:GetParent()
    end

    return buttonPart, listPart, multiIconPart
end

local g_highlightAnimationProvider = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")
local g_controlScaleAnimationProvider = ZO_ReversibleAnimationProvider:New("IconSlotMouseOverAnimation")

function ZO_InventorySlot_SetHighlightHidden(listPart, hidden, instant)
    if listPart then
        local highlight = listPart:GetNamedChild("Highlight")
        if highlight and highlight:GetType() == CT_TEXTURE then
            if hidden then
                g_highlightAnimationProvider:PlayBackward(highlight, instant)
            else
                g_highlightAnimationProvider:PlayForward(highlight, instant)
            end
        end
    end
end

function ZO_InventorySlot_SetControlScaledUp(control, scaledUp, instant)
    if control then
        if scaledUp then
            g_controlScaleAnimationProvider:PlayForward(control, instant)
        else
            g_controlScaleAnimationProvider:PlayBackward(control, instant)
        end                
    end
end

function ZO_InventorySlot_OnPoolReset(inventorySlot)
    local buttonPart, listPart, multiIconPart = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
    local INSTANT = true
    ZO_InventorySlot_SetHighlightHidden(listPart, true, INSTANT)
    ZO_InventorySlot_SetControlScaledUp(buttonPart, false, INSTANT)
    ZO_InventorySlot_SetControlScaledUp(multiIconPart, false, INSTANT)
    ZO_ObjectPool_DefaultResetControl(inventorySlot)
end

--
-- Cooldowns
--

local NO_LEADING_EDGE = false
local function UpdateCooldown(inventorySlot, remaining, duration)
    inventorySlot.inCooldown = (remaining > 0) and (duration > 0)

    if inventorySlot.inCooldown then
        inventorySlot.cooldown:StartCooldown(remaining, duration, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_UNTIL, NO_LEADING_EDGE)
    else
        inventorySlot.cooldown:ResetCooldown()
    end

    inventorySlot.cooldown:SetHidden(not inventorySlot.inCooldown)
end

local function QuestItemUpdateCooldown(inventorySlot)
    if(inventorySlot) then
        local remaining, duration = GetQuestToolCooldownInfo(inventorySlot.questIndex, inventorySlot.toolIndex)
        UpdateCooldown(inventorySlot, remaining, duration)
    end
    return true
end

local function ItemUpdateCooldown(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local remaining, duration = GetItemCooldownInfo(bag, index)
    UpdateCooldown(inventorySlot, remaining, duration)
    return true
end

local function CollectibleItemUpdateCooldown(inventorySlot)
    local remaining, duration = GetCollectibleCooldownAndDuration(inventorySlot.collectibleId)
    UpdateCooldown(inventorySlot, remaining, duration)
    return true
end

local InventoryUpdateCooldown =
{
    [SLOT_TYPE_ITEM] =
    {
        function(inventorySlot)
            return ItemUpdateCooldown(inventorySlot)
        end
    },
    [SLOT_TYPE_QUEST_ITEM] =
    {
        function(inventorySlot)
            return QuestItemUpdateCooldown(inventorySlot)
        end
    },
    [SLOT_TYPE_COLLECTIONS_INVENTORY] = 
    {
        function(inventorySlot)
            return CollectibleItemUpdateCooldown(inventorySlot)
        end
    }
}

function ZO_InventorySlot_UpdateCooldowns(inventorySlot)
    local inventorySlotButton = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
    RunHandlers(InventoryUpdateCooldown, inventorySlotButton)
end

function ZO_GamepadItemSlot_UpdateCooldowns(inventorySlot, remaining, duration)
    UpdateCooldown(inventorySlot, remaining, duration)
end


--
-- Actions that can be performed on InventorySlots (via various clicks and context menus)
--

-- Determines whether the specified item furnishing can be placed in the current house.
function ZO_CanPlaceItemInCurrentHouse(bagId, slotIndex)
    return HasItemInSlot(bagId, slotIndex) and IsItemPlaceableFurniture(bagId, slotIndex) and (not IsItemStolen(bagId, slotIndex)) and ZO_CanPlaceFurnitureInCurrentHouse()
end

-- Attempts to begin placement of the specified item furnishing in the current house.
function ZO_TryPlaceFurnitureFromInventorySlot(bagId, slotIndex)
    if not ZO_CanPlaceItemInCurrentHouse(bagId, slotIndex) then
        return false
    end

    if GetHousingEditorMode() ~= HOUSING_EDITOR_MODE_SELECTION then
        SCENE_MANAGER:ShowBaseScene()

        if HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION) ~= HOUSING_REQUEST_RESULT_SUCCESS then
            return false
        end
    end

    local success = HousingEditorCreateItemFurnitureForPlacement(bagId, slotIndex)
    return success
end

local function IsSendingMail()
    if MAIL_SEND and not MAIL_SEND:IsHidden() then
        return true
    elseif MAIL_GAMEPAD and MAIL_GAMEPAD:GetSend():IsAttachingItems() then
        return true
    end
    return false
end

local function CanUseSecondaryActionOnSlot(inventorySlot)
    if not inventorySlot then
        return false
    end

    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    return not (QUICKSLOT_KEYBOARD and QUICKSLOT_KEYBOARD:AreQuickSlotsShowing())
           and not (TRADING_HOUSE_SEARCH and TRADING_HOUSE_SEARCH:IsAtTradingHouse())
           and not (ZO_Store_IsShopping and ZO_Store_IsShopping())
           and not IsSendingMail()
           and not (TRADE_WINDOW and TRADE_WINDOW:IsTrading())
           and not IsBankOpen()
           and not IsGuildBankOpen()
           and not (GetItemActorCategory(bag, index) == GAMEPLAY_ACTOR_CATEGORY_COMPANION)
end

local function CanUseItemQuestItem(inventorySlot)
    if inventorySlot then
        if inventorySlot.toolIndex then
            return CanUseQuestTool(inventorySlot.questIndex, inventorySlot.toolIndex)
        elseif inventorySlot.conditionIndex then
            return CanUseQuestItem(inventorySlot.questIndex, inventorySlot.stepIndex, inventorySlot.conditionIndex)
        end
    end
    return false
end

local function TryUseQuestItem(inventorySlot)
    if inventorySlot then
        if inventorySlot.toolIndex then
            UseQuestTool(inventorySlot.questIndex, inventorySlot.toolIndex)
        elseif inventorySlot.conditionIndex then
            UseQuestItem(inventorySlot.questIndex, inventorySlot.stepIndex, inventorySlot.conditionIndex)
        end
    end
end

function ZO_InventorySlot_CanQuickslotItem(inventorySlot)
    if inventorySlot.filterData then
        if ZO_IsElementInNumericallyIndexedTable(inventorySlot.filterData, ITEMFILTERTYPE_QUICKSLOT) then
            return true
        elseif ZO_IsElementInNumericallyIndexedTable(inventorySlot.filterData, ITEMFILTERTYPE_QUEST_QUICKSLOT) then
            return true
        end
    end
    return false
end

function ZO_InventorySlot_CanSplitItemStack(inventorySlot)
    if ZO_InventorySlot_GetStackCount(inventorySlot) > 1 then
        local hasFreeSlot = FindFirstEmptySlotInBag(inventorySlot.bagId) ~= nil
        if not hasFreeSlot then
            if inventorySlot.bagId == BAG_BANK then
                hasFreeSlot = FindFirstEmptySlotInBag(BAG_SUBSCRIBER_BANK)
            elseif inventorySlot.bagId == BAG_SUBSCRIBER_BANK then
                hasFreeSlot = FindFirstEmptySlotInBag(BAG_BANK)
            end
        end
        return hasFreeSlot        
    end
end

function ZO_InventorySlot_TrySplitStack(inventorySlot)
    if GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        return ZO_StackSplit_SplitItem(inventorySlot)
    end
end

do
    local g_listDialog
    function ZO_InventorySlot_GetItemListDialog()
        if not g_listDialog then
            local function SetupItemRow(rowControl, slotInfo)
                local bag, index = slotInfo.bag, slotInfo.index

                local icon, _, _, _, _, _, _, _, displayQuality = GetItemInfo(bag, index)

                local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality)
                local nameControl = rowControl:GetNamedChild("Name")
                nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bag, index)))
                nameControl:SetColor(r, g, b, 1)

                local inventorySlot = rowControl:GetNamedChild("Button")
                ZO_Inventory_BindSlot(inventorySlot, SLOT_TYPE_LIST_DIALOG_ITEM, index, bag)
                ZO_Inventory_SetupSlot(inventorySlot, slotInfo.stack, icon)

                rowControl:GetNamedChild("Selected"):SetHidden(g_listDialog:GetSelectedItem() ~= slotInfo)

                local statusTextureControl = rowControl:GetNamedChild("StatusTexture")
                if IsItemInArmory(bag, index) then
                    statusTextureControl:SetTexture(ZO_IN_ARMORY_BUILD_ICON)
                    statusTextureControl:SetHidden(false)
                else
                    statusTextureControl:SetHidden(true)
                end

                if g_listDialog:GetSelectedItem() then
                    g_listDialog:SetFirstButtonEnabled(true)
                end
            end
            g_listDialog = ZO_ListDialog:New("ZO_ListDialogInventorySlot", 52, SetupItemRow)
        end

        g_listDialog:SetFirstButtonEnabled(false)
        return g_listDialog
    end

    local g_multiSelectListDialog
    function ZO_InventorySlot_GetMultiSelectItemListDialog()
        if not g_multiSelectListDialog then
            local function SetupItemRow(rowControl, slotInfo)
                local bag, index = slotInfo.bag, slotInfo.index

                local icon, _, _, _, _, _, _, _, displayQuality = GetItemInfo(bag, index)

                local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality)
                local nameControl = rowControl:GetNamedChild("Name")
                nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bag, index)))
                nameControl:SetColor(r, g, b, 1)

                local inventorySlot = rowControl:GetNamedChild("Button")
                ZO_Inventory_BindSlot(inventorySlot, SLOT_TYPE_LIST_DIALOG_ITEM, index, bag)
                ZO_Inventory_SetupSlot(inventorySlot, slotInfo.stack, icon)

                rowControl:GetNamedChild("Selected"):SetHidden(not g_multiSelectListDialog:IsItemSelected(slotInfo))

                local statusTextureControl = rowControl:GetNamedChild("StatusTexture")
                if IsItemInArmory(bag, index) then
                    statusTextureControl:SetTexture(ZO_IN_ARMORY_BUILD_ICON)
                    statusTextureControl:SetHidden(false)
                else
                    statusTextureControl:SetHidden(true)
                end

                if #g_multiSelectListDialog:GetSelectedItems() > 0 then
                    g_multiSelectListDialog:SetFirstButtonEnabled(true)
                else
                    g_multiSelectListDialog:SetFirstButtonEnabled(false)
                end
            end
            g_multiSelectListDialog = ZO_MultiSelectListDialog:New("ZO_ListDialogInventorySlot", 52, SetupItemRow)
        end

        g_multiSelectListDialog:SetFirstButtonEnabled(false)
        return g_multiSelectListDialog
    end
end

local function CanEnchantItem(inventorySlot)
    if CanUseSecondaryActionOnSlot(inventorySlot) then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        return IsItemEnchantable(bag, index)
    end
end

local function TryEnchantItem(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local function DoEnchant()
        SYSTEMS:GetObject("enchant"):BeginItemImprovement(bag, index)
    end

    if IsItemBoPAndTradeable(bag, index) then
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_MODIFY_TRADE_BOP", {onAcceptCallback = DoEnchant}, {mainTextParams={GetItemName(bag, index)}})
    else
        DoEnchant()
    end
    
end

local function CanConvertToStyle(inventorySlot, toStyle)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if CanUseSecondaryActionOnSlot(inventorySlot) and not IsItemPlayerLocked(bag, index) then
        return CanConvertItemStyle(bag, index, toStyle)
    end
end

local function IsSlotLocked(inventorySlot)
    local slotData = ZO_Inventory_GetSlotDataForInventoryControl(inventorySlot)

    if slotData then
        return slotData.locked
    end
end

local function CanChargeItem(inventorySlot)
    if CanUseSecondaryActionOnSlot(inventorySlot) then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        return IsItemChargeable(bag, index)
    end
end

local function TryChargingItem(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)

    local charges, maxCharges = GetChargeInfoForItem(bag, index)
    if charges == maxCharges then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_SOULGEMITEMCHARGINGREASON", SOUL_GEM_ITEM_CHARGING_ALREADY_CHARGED))
    else
        SYSTEMS:GetObject("soulgem"):BeginItemImprovement(bag, index)
    end
end

local function CanKitRepairItem(inventorySlot)
    if CanUseSecondaryActionOnSlot(inventorySlot) then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        return DoesItemHaveDurability(bag, index)
    end
end

local function TryKitRepairItem(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)

    local condition = GetItemCondition(bag, index)
    if condition == 100 then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_ITEMREPAIRREASON", ITEM_REPAIR_ALREADY_REPAIRED))
    else
        SYSTEMS:GetObject("repair"):BeginItemImprovement(bag, index)
    end
end

local function PlaceInventoryItem(inventorySlot)
    local cursorType = GetCursorContentType()

    if cursorType ~= MOUSE_CONTENT_EMPTY then
        local sourceBag = GetCursorBagId()
        local sourceSlot = GetCursorSlotIndex()
        local destBag, destSlot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        ClearCursor()
        if ZO_InventorySlot_WillItemBecomeBoundOnEquip(sourceBag, sourceSlot) then
            local itemDisplayQuality = GetItemDisplayQuality(sourceBag, sourceSlot)
            local itemQualityColor = GetItemQualityColor(itemDisplayQuality)
            ZO_Dialogs_ShowPlatformDialog("CONFIRM_EQUIP_ITEM", { onAcceptCallback = function() RequestMoveItem(sourceBag, sourceSlot, destBag, destSlot) end }, { mainTextParams = { itemQualityColor:Colorize(GetItemName(sourceBag, sourceSlot)) } })
        else
            RequestMoveItem(sourceBag, sourceSlot, destBag, destSlot)
        end
        return true
    end
end

function TryPlaceInventoryItemInEmptySlot(targetBag)
    local emptySlotIndex = FindFirstEmptySlotInBag(targetBag)

    if not emptySlotIndex and IsESOPlusSubscriber() then
        -- The player may be trying to split a stack. If they're transacting on the bank or 
        -- subscriber bank, then the other bag is also a valid target for the split item.
        if targetBag == BAG_BANK then
            targetBag = BAG_SUBSCRIBER_BANK
            emptySlotIndex = FindFirstEmptySlotInBag(targetBag)
        elseif targetBag == BAG_SUBSCRIBER_BANK then
            targetBag = BAG_BANK
            emptySlotIndex = FindFirstEmptySlotInBag(targetBag)
        end
    end

    if emptySlotIndex ~= nil then
        PlaceInInventory(targetBag, emptySlotIndex)
    else
        local errorStringId = (targetBag == BAG_BACKPACK) and SI_INVENTORY_ERROR_INVENTORY_FULL or SI_INVENTORY_ERROR_BANK_FULL
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, errorStringId)
    end
end

local function TryGuildBankDepositItem(sourceBag, sourceSlot)
    local guildId = GetSelectedGuildBankId()
    if guildId then
        if not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_DEPOSIT) then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_NO_DEPOSIT_PERMISSION)
            return
        end

        if not DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_BANK_DEPOSIT) then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_GUILD_TOO_SMALL)
            return
        end

        if IsItemStolen(sourceBag, sourceSlot) then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_NO_DEPOSIT_STOLEN_ITEM)
            return
        end

        if GetNumBagFreeSlots(BAG_GUILDBANK) == 0 then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_NO_SPACE_LEFT)
            return
        end

        local soundCategory = GetItemSoundCategory(sourceBag, sourceSlot)
        PlayItemSound(soundCategory, ITEM_SOUND_ACTION_PICKUP)

        TransferToGuildBank(sourceBag, sourceSlot)
    end
    ClearCursor()
end

local function TryGuildBankWithdrawItem(sourceSlotIndex)
    local guildId = GetSelectedGuildBankId()
    if guildId then
        if not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_WITHDRAW) then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_NO_WITHDRAW_PERMISSION)
            return
        end

        if not DoesBagHaveSpaceFor(BAG_BACKPACK, BAG_GUILDBANK, sourceSlotIndex) then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
            return
        end

        local soundCategory = GetItemSoundCategory(BAG_GUILDBANK, sourceSlotIndex)
        PlayItemSound(soundCategory, ITEM_SOUND_ACTION_PICKUP)

        TransferFromGuildBank(sourceSlotIndex)
    end
    ClearCursor()
end

function ZO_TryMoveToInventoryFromBagAndSlot(bag, slotIndex)
    if DoesBagHaveSpaceFor(BAG_BACKPACK, bag, slotIndex) then
        local transferDialog = SYSTEMS:GetObject("ItemTransferDialog")
        transferDialog:StartTransfer(bag, slotIndex, BAG_BACKPACK)
    else
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
    end
     ClearCursor()
end

local function TryMoveToInventory(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    ZO_TryMoveToInventoryFromBagAndSlot(bag, index)
end

local function PlaceInventoryItemInStorage(targetInventorySlot)
    -- When moving your items between bags/slots there are special-cased rules
    -- that need to apply...instead of using the landing area for the empty slot
    -- and trying to swap/stack items each dropped item will only try to stack.
    -- If it can't stack on what it was dropped on, then it will attempt to place itself in an empty slot.
    -- Swapping is only allowed when dragging from backpack to an equip slot, never the other way around.

    local targetType = ZO_InventorySlot_GetType(targetInventorySlot)
    local targetBag, targetSlotIndex = ZO_Inventory_GetBagAndIndex(targetInventorySlot)
    local targetItemId = GetItemInstanceId(targetBag, targetSlotIndex)

    local sourceType = GetCursorContentType()
    local sourceBag, sourceSlotIndex = GetCursorBagId(), GetCursorSlotIndex()
    local sourceItemId = GetItemInstanceId(sourceBag, sourceSlotIndex)

    -- Transferring from Craft Bag is going to be handled independently here because it has special needs
    if sourceBag == BAG_VIRTUAL then
        -- We can really only transfer from the Craft Bag to the BACKPACK and when we transfer
        -- we want to prompt the option to choose a quantity (up to 200)
        if sourceType == MOUSE_CONTENT_INVENTORY_ITEM then
            if targetType == SLOT_TYPE_ITEM and targetBag == BAG_BACKPACK then
                ZO_TryMoveToInventoryFromBagAndSlot(sourceBag, sourceSlotIndex)
                return true
            end
        end
        return false
    elseif targetType == SLOT_TYPE_ITEM or targetType == SLOT_TYPE_BANK_ITEM then
        if sourceType == MOUSE_CONTENT_EQUIPPED_ITEM then
            TryPlaceInventoryItemInEmptySlot(targetBag)
            return true
        elseif sourceType == MOUSE_CONTENT_INVENTORY_ITEM then
            -- if the items can stack, move the source to the clicked slot, otherwise try to move to an empty slot.
            -- never swap!
            if sourceBag == BAG_GUILDBANK then
                TryGuildBankWithdrawItem(sourceSlotIndex)
                return true
            else
                if sourceItemId == targetItemId then
                    PlaceInInventory(targetBag, targetSlotIndex)
                    return true
                else
                    if sourceBag == targetBag then
                        ClearCursor()
                    else
                        TryPlaceInventoryItemInEmptySlot(targetBag)
                    end
                    return true
                end
            end
        elseif sourceType == MOUSE_CONTENT_QUEST_ITEM then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_INVENTORY_ERROR_NO_QUEST_ITEMS_IN_BANK))
            return false
        end
    elseif targetType == SLOT_TYPE_GUILD_BANK_ITEM then
        if sourceType == MOUSE_CONTENT_QUEST_ITEM then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_INVENTORY_ERROR_NO_QUEST_ITEMS_IN_BANK))
            return false
        elseif sourceBag == BAG_GUILDBANK then
             ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_INVENTORY_ERROR_CANNOT_STACK_GUILD_BANK))
             ClearCursor()
            return false
        else
            TryGuildBankDepositItem(sourceBag, sourceSlotIndex)
            return true
        end
    end

    -- No special behavior...
    return PlaceInventoryItem(targetInventorySlot)
end

local function TryBankItem(inventorySlot)
    if IsBankOpen() then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if bag == BAG_BANK or bag == BAG_SUBSCRIBER_BANK or IsHouseBankBag(bag) then
            --Withdraw
            if DoesBagHaveSpaceFor(BAG_BACKPACK, bag, index) then
                PickupInventoryItem(bag, index)
                PlaceInTransfer()
            else
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
            end
        else
            --Deposit
            if IsItemStolen(bag, index) then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_STOLEN_ITEM_CANNOT_DEPOSIT_MESSAGE)
            else
                local bankingBag = GetBankingBag()
                local canAlsoBePlacedInSubscriberBank = bankingBag == BAG_BANK

                if DoesBagHaveSpaceFor(bankingBag, bag, index) or (canAlsoBePlacedInSubscriberBank and DoesBagHaveSpaceFor(BAG_SUBSCRIBER_BANK, bag, index)) then
                    PickupInventoryItem(bag, index)
                    PlaceInTransfer()
                else
                    if canAlsoBePlacedInSubscriberBank and not IsESOPlusSubscriber() then
                        if GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK) > 0 then
                            TriggerTutorial(TUTORIAL_TRIGGER_BANK_OVERFULL)
                        else
                            TriggerTutorial(TUTORIAL_TRIGGER_BANK_FULL_NO_ESO_PLUS)
                        end
                    end
                    ZO_AlertEvent(EVENT_BANK_IS_FULL)
                end                
             end
        end
        return true
    end
end

local function CanMoveToCraftBag(bagId, slotIndex)
    return HasCraftBagAccess() and CanItemBeVirtual(bagId, slotIndex) and not IsItemStolen(bagId, slotIndex)
end

local function TryMoveToCraftBag(bagId, slotIndex)
    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(bagId, slotIndex)
    if slotData then
        if slotData.isGemmable then
            ZO_Dialogs_ShowPlatformDialog("CONFIRM_STOW_GEMIFIABLE", { sourceBagId = bagId, sourceSlotIndex = slotIndex })
        else
            local transferDialog = SYSTEMS:GetObject("ItemTransferDialog")
            transferDialog:StartTransfer(bagId, slotIndex, BAG_VIRTUAL)
            return true
        end
    end
end

local function TryPreviewDyeStamp(inventorySlot)
    -- get item info and pass it to the preview dye stamp view
    -- there, the player can spin the model and confirm or deny using the stamp
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local itemLink = GetItemLink(bag, index)
    local dyeStampId = GetItemLinkDyeStampId(itemLink)
    local onUseType = GetItemLinkItemUseType(itemLink)

    if onUseType == ITEM_USE_TYPE_ITEM_DYE_STAMP then
        local dyeStampUseResult = CanPlayerUseItemDyeStamp(dyeStampId)
        if dyeStampUseResult ~= DYE_STAMP_USE_RESULT_NONE then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_DYESTAMPUSERESULT", dyeStampUseResult))
            return
        end
    elseif onUseType == ITEM_USE_TYPE_COSTUME_DYE_STAMP then
        local dyeStampUseResult = CanPlayerUseCostumeDyeStamp(dyeStampId)
        if dyeStampUseResult ~= DYE_STAMP_USE_RESULT_NONE then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString("SI_DYESTAMPUSERESULT", dyeStampUseResult))
            return
        end
    end

    SYSTEMS:GetObject("dyeStamp_Confirmation"):SetTargetItem(bag, index)
    SYSTEMS:PushScene("dyeStampConfirmation")
end

local function TryPreviewItem(bag, slot)
    SYSTEMS:GetObject("itemPreview"):PreviewInventoryItem(bag, slot)
    if not IsInGamepadPreferredMode() then
        INVENTORY_MENU_BAR:UpdateInventoryKeybinds()
    end
end

-- If called on an item inventory slot, returns the index of the attachment slot that's holding it, or nil if it's not attached.
local function GetQueuedItemAttachmentSlotIndex(inventorySlot)
    local bag, attachmentIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if bag then
        for i = 1, MAIL_MAX_ATTACHED_ITEMS do
            local bagId, slotIndex = GetQueuedItemAttachmentInfo(i)
            if bagId == bag and attachmentIndex == slotIndex then
                return i
            end
        end
    end
end

local function IsItemAlreadyAttachedToMail(inventorySlot)
    local index = GetQueuedItemAttachmentSlotIndex(inventorySlot)
    if index then
        return GetQueuedItemAttachmentInfo(index) ~= 0
    end
end

local function TryMailItem(inventorySlot)
    if IsSendingMail() then
        for i = 1, MAIL_MAX_ATTACHED_ITEMS do
            local queuedFromBag = GetQueuedItemAttachmentInfo(i)

            if queuedFromBag == 0 then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                local result = QueueItemAttachment(bag, index, i)

                if result == MAIL_ATTACHMENT_RESULT_ALREADY_ATTACHED then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_ALREADY_ATTACHED))
                elseif result == MAIL_ATTACHMENT_RESULT_BOUND then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_BOUND))
                elseif result == MAIL_ATTACHMENT_RESULT_ITEM_NOT_FOUND then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_ITEM_NOT_FOUND))
                elseif result == MAIL_ATTACHMENT_RESULT_LOCKED then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_LOCKED))
                elseif result == MAIL_ATTACHMENT_RESULT_STOLEN then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_STOLEN_ITEM_CANNOT_MAIL_MESSAGE))
                else
                    UpdateMouseoverCommand(inventorySlot)
                end

                return true
            end
        end

        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_ATTACHMENTS_FULL))
        return true
    end
end

local function RemoveQueuedAttachment(inventorySlot)
    local index = GetQueuedItemAttachmentSlotIndex(inventorySlot)
    RemoveQueuedItemAttachment(index)

    UpdateMouseoverCommand(inventorySlot)
end

local function CanTradeItem(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    return TRADE_WINDOW:IsTrading() and not IsItemBound(bag, index)
end

local function IsItemAlreadyBeingTraded(inventorySlot)
    if ZO_InventorySlot_GetType(inventorySlot) == SLOT_TYPE_MY_TRADE then
        local _, _, stackCount = GetTradeItemInfo(TRADE_ME, ZO_Inventory_GetSlotIndex(inventorySlot))
        if stackCount > 0 then
            return true
        end
    else
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        return ZO_IsItemCurrentlyOfferedForTrade(bag, index)
    end
    return false
end

local function TryTradeItem(inventorySlot)
    if TRADE_WINDOW:IsTrading() then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        TRADE_WINDOW:AddItemToTrade(bag, index)
        return true
    end
end

local function TryRemoveFromTrade(inventorySlot)
    if TRADE_WINDOW:IsTrading() then
        if ZO_InventorySlot_GetType(inventorySlot) == SLOT_TYPE_MY_TRADE then
            local tradeIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
            local bagId, slotId = GetTradeItemBagAndSlot(TRADE_ME, tradeIndex)
            if bagId and slotId then
                local soundCategory = GetItemSoundCategory(bagId, slotId)
                PlayItemSound(soundCategory, ITEM_SOUND_ACTION_PICKUP)
                TradeRemoveItem(tradeIndex)
            end
        else
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            for i = 1, TRADE_NUM_SLOTS do
                local bagId, slotIndex = GetTradeItemBagAndSlot(TRADE_ME, i)
                if bagId and slotIndex and bagId == bag and slotIndex == index then
                    local soundCategory = GetItemSoundCategory(bagId, slotIndex)
                    PlayItemSound(soundCategory, ITEM_SOUND_ACTION_PICKUP)
                    TradeRemoveItem(i)
                    break
                end
            end
        end

        UpdateMouseoverCommand(inventorySlot)
    end
end

-- To prevent double-click attempting to equip items when at a store, this should just return whether or not the player is shopping.
-- We always want to try to sell when the user does the "primary" action at a store so that they don't mistakenly equip a 0-cost
-- item which replaces their existing gear...and then when the user continues to hit "E" or double-clicks they end up selling gear
-- they don't want to.
local function CanSellItem(inventorySlot)
    return ZO_Store_IsShopping() and not SYSTEMS:GetObject("fence"):IsLaundering()
end

local function CanLaunderItem(inventorySlot)
    return ZO_Store_IsShopping() and SYSTEMS:GetObject("fence"):IsLaundering()
end

local function TrySellItem(inventorySlot)
    local itemData = {}
    if CanSellItem() then
        itemData.stackCount = ZO_InventorySlot_GetStackCount(inventorySlot)
        if itemData.stackCount > 0 then
            itemData.bag, itemData.slot = ZO_Inventory_GetBagAndIndex(inventorySlot)

            if IsItemStolen(itemData.bag, itemData.slot) then
                local totalSells, sellsUsed = GetFenceSellTransactionInfo()
                if sellsUsed == totalSells then
                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString("SI_STOREFAILURE", STORE_FAILURE_AT_FENCE_LIMIT))
                    return
                end
            end

            itemData.itemName = GetItemName(itemData.bag, itemData.slot)
            itemData.functionalQuality = GetItemFunctionalQuality(itemData.bag, itemData.slot)
            itemData.displayQuality = GetItemDisplayQuality(itemData.bag, itemData.slot)
            -- itemData.quality is deprecated, included here for addon backwards compatibility
            itemData.quality = itemData.functionalQuality

            if SCENE_MANAGER:IsShowing("fence_keyboard") and itemData.functionalQuality >= ITEM_FUNCTIONAL_QUALITY_ARTIFACT then
                ZO_Dialogs_ShowDialog("CANT_BUYBACK_FROM_FENCE", itemData)
            elseif IsItemInArmory(itemData.bag, itemData.slot) then
                local armoryBuildList = { GetItemArmoryBuildList(itemData.bag, itemData.slot) }
                local buildListString = ZO_GenerateCommaSeparatedListWithAnd(armoryBuildList)
                ZO_Dialogs_ShowDialog("CONFIRM_SELL_ARMORY_ITEM_PROMPT", itemData, { mainTextParams = { ZO_SELECTED_TEXT:Colorize(buildListString), #armoryBuildList }})
            else
                SellInventoryItem(itemData.bag, itemData.slot, itemData.stackCount)
            end
            return true
        end
    end
end

local function TryLaunderItem(inventorySlot)
    local totalLaunders, laundersUsed = GetFenceLaunderTransactionInfo()
    if laundersUsed == totalLaunders then
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString("SI_ITEMLAUNDERRESULT", ITEM_LAUNDER_RESULT_AT_LIMIT))
        return
    end

    if CanLaunderItem() then
        local stackCount = ZO_InventorySlot_GetStackCount(inventorySlot)
        if stackCount > 0 then
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            LaunderItem(bag, index, stackCount)
            return true
        end
    end
end

local function CanBuyMultiple(inventorySlot)
    return not (inventorySlot.isCollectible or inventorySlot.isUnique)
end

local function CanEquipItem(inventorySlot)
    if not IsSlotLocked(inventorySlot) then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if bag ~= BAG_WORN and bag ~= BAG_COMPANION_WORN then
            local itemActorCategory = GetItemActorCategory(bag, index)
            if itemActorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION and GetInteractionType() ~= INTERACTION_COMPANION_MENU then
                return false
            end
            local equipType = GetItemEquipType(bag, index)
            return equipType ~= EQUIP_TYPE_INVALID
        end
    end
    return false
end

local function TryEquipItem(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local function DoEquip()
        local equipSucceeds, possibleError = IsEquipable(bag, index)
        if equipSucceeds then
            ClearCursor()
            local wornBag = GetItemActorCategory(bag, index) == GAMEPLAY_ACTOR_CATEGORY_PLAYER and BAG_WORN or BAG_COMPANION_WORN
            RequestEquipItem(bag, index, wornBag)
            return true
        end

        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, possibleError)
    end

    if ZO_InventorySlot_WillItemBecomeBoundOnEquip(bag, index) then
        local itemDisplayQuality = GetItemDisplayQuality(bag, index)
        local itemDisplayQualityColor = GetItemQualityColor(itemDisplayQuality)
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_EQUIP_ITEM", { onAcceptCallback = DoEquip }, { mainTextParams = { itemDisplayQualityColor:Colorize(GetItemName(bag, index)) } })
    else
        DoEquip()
    end
end

local function CanUnequipItem(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if bag == BAG_WORN or bag == BAG_COMPANION_WORN then
        local _, stackCount = GetItemInfo(bag, slot)
        return stackCount > 0
    end
    return false
end

local function TryUnequipItem(inventorySlot)
    local bag, equipSlot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    RequestUnequipItem(bag, equipSlot)
end

local function TryPickupQuestItem(inventorySlot)
    if inventorySlot.questIndex then
        if inventorySlot.toolIndex then
            PickupQuestTool(inventorySlot.questIndex, inventorySlot.toolIndex)
        else
            PickupQuestItem(inventorySlot.questIndex, inventorySlot.stepIndex, inventorySlot.conditionIndex)
        end

        return true
    end
end

local destroyableItems =
{
    [SLOT_TYPE_ITEM] = true,
    [SLOT_TYPE_EQUIPMENT] = true,
    [SLOT_TYPE_BANK_ITEM] = true,
    [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM] = true,
    [SLOT_TYPE_CRAFT_BAG_ITEM] = false, -- There's no good reason to destroy from the Craft Bag
}

function ZO_InventorySlot_CanDestroyItem(inventorySlot)
    local slotType = ZO_InventorySlot_GetType(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if destroyableItems[slotType] and not IsItemPlayerLocked(bag, index) then
        if slotType == SLOT_TYPE_EQUIPMENT then
            return CanUnequipItem(inventorySlot) -- if you can unequip it, it can be destroyed.
        else
            return true
        end
    end
end

function ZO_InventorySlot_InitiateDestroyItem(inventorySlot)
    if IsSlotLocked(inventorySlot) then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_ERROR_ITEM_LOCKED))
        return false
    end

    SetCursorItemSoundsEnabled(false)

    -- Attempt to pick it up as a quest item, if that fails, attempt to pick it up as an inventory item
    if(not TryPickupQuestItem(inventorySlot)) then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        PickupInventoryItem(bag, index)
    end

    SetCursorItemSoundsEnabled(true)

    -- Initiates the destruction request...(could either abandon quest or destroy the item)
    PlaceInWorldLeftClick()

    return true
end

local function CanUseItemWithOnUseType(onUseType)
    if onUseType == ITEM_USE_TYPE_ITEM_DYE_STAMP
       or onUseType == ITEM_USE_TYPE_COSTUME_DYE_STAMP
       or onUseType == ITEM_USE_TYPE_KEEP_RECALL_STONE
       or onUseType == ITEM_USE_TYPE_SKILL_RESPEC
       or onUseType == ITEM_USE_TYPE_MORPH_RESPEC
       or onUseType == ITEM_USE_TYPE_ATTRIBUTE_RESPEC
    then
        return false
    end

    return true
end

local function CanUseItem(inventorySlot)
    local hasCooldown = inventorySlot.IsOnCooldown and inventorySlot:IsOnCooldown()
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local usable, onlyFromActionSlot = IsItemUsable(bag, index)
    local canInteractWithItem = CanInteractWithItem(bag, index)
    local onUseType = GetItemUseType(bag, index)
    local canUseItemWithOnUseType = CanUseItemWithOnUseType(onUseType)
    return usable and not onlyFromActionSlot and canInteractWithItem and not hasCooldown and canUseItemWithOnUseType
end

local function TryUseItem(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local usable, onlyFromActionSlot = IsItemUsable(bag, index)
    if usable and not onlyFromActionSlot then
        ClearCursor()
        UseItem(bag, index)
        return true
    end
end

function ZO_InventorySlot_InitiateConfirmUseItem(inventorySlot)
    if IsSlotLocked(inventorySlot) then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_ERROR_ITEM_LOCKED))
        return false
    end

    local bag, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
    InitiateConfirmUseInventoryItem(bag, slotIndex)
    return true
end

local function TryShowRecallMap(inventorySlot)
    TryUseItem(inventorySlot)
end

local function TryStartSkillRespec(inventorySlot)
    TryUseItem(inventorySlot)
end

local function TryStartAttributeRespec(inventorySlot)
    TryUseItem(inventorySlot)
end

local function TryBindItem(bagId, slotIndex)
    local function OnAcceptCallback()
        BindItem(bagId, slotIndex)
    end

    if ZO_InventorySlot_WillItemBecomeBoundOnEquip(bagId, slotIndex) then
        local itemDisplayQuality = GetItemDisplayQuality(bagId, slotIndex)
        local itemDisplayQualityColor = GetItemQualityColor(itemDisplayQuality)
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_BIND_ITEM", { onAcceptCallback = OnAcceptCallback }, { mainTextParams = { itemDisplayQualityColor:Colorize(GetItemName(bagId, slotIndex)) } })
    end
end

local function TryBuyMultiple(inventorySlot)
    ZO_BuyMultiple_OpenBuyMultiple(inventorySlot.index)
end

local function BuyItemFromStore(inventorySlot)
    local storeItemId = inventorySlot.index

    local itemData = {
        currencyType1 = inventorySlot.specialCurrencyType1,
        currencyType2 = inventorySlot.specialCurrencyType2,
        price = inventorySlot.moneyCost,
        currencyQuantity1 = inventorySlot.specialCurrencyQuantity1,
        currencyQuantity2 = inventorySlot.specialCurrencyQuantity2,
        meetsRequirementsToBuy = inventorySlot.meetsRequirements
    }
    if not ZO_Currency_TryShowThresholdDialog(storeItemId, inventorySlot.stackCount, itemData) then
        BuyStoreItem(storeItemId, 1)
    end
    return true
end

function TakeLoot(slot)
    if slot.lootEntry.currencyType then
        LootCurrency(slot.lootEntry.currencyType)
    else
        LootItemById(slot.lootEntry.lootId)
    end
end

local function IsItemAlreadyBeingPosted(inventorySlot)
    local postedBag, postedSlot, postedQuantity = GetPendingItemPost()
    if ZO_InventorySlot_GetType(inventorySlot) == SLOT_TYPE_TRADING_HOUSE_POST_ITEM then
        return postedQuantity > 0
    end

    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    return postedQuantity > 0 and bag == postedBag and slot == postedSlot
end

local function TryInitiatingItemPost(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local _, stackCount = GetItemInfo(bag, slot)
    if(stackCount > 0) then
        if (IsItemStolen(bag, slot)) then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_STOLEN_ITEM_CANNOT_LIST_MESSAGE))
        else
            SetPendingItemPost(bag, slot, stackCount)
            UpdateMouseoverCommand(inventorySlot)
        end
    end
end

local function ClearItemPost(inventorySlot)
    SetPendingItemPost(BAG_BACKPACK, 0, 0) 
    UpdateMouseoverCommand(inventorySlot)
end

local function TryBuyingGuildSpecificItem(inventorySlot)
    if TRADING_HOUSE:VerifyBuyItemAndShowErrors(inventorySlot) then
        local guildSpecificItemIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
        TRADING_HOUSE:ConfirmPendingGuildSpecificPurchase(guildSpecificItemIndex)
    end
end

local function TryBuyingTradingHouseItem(inventorySlot)
    if TRADING_HOUSE:VerifyBuyItemAndShowErrors(inventorySlot) then
        local tradingHouseIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
        SetPendingItemPurchase(tradingHouseIndex)
    end
end

local function TryCancellingTradingHouseListing(inventorySlot)
    local listingIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
    TRADING_HOUSE:ShowCancelListingConfirmation(listingIndex)
end

local function TryVendorRepairItem(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    RepairItem(bag, slot)
    PlaySound(SOUNDS.INVENTORY_ITEM_REPAIR)
end

local function CanItemBeAddedToCraft(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)

    if SYSTEMS:IsShowing(ZO_ALCHEMY_SYSTEM_NAME) then
        return SYSTEMS:GetObject(ZO_ALCHEMY_SYSTEM_NAME):CanItemBeAddedToCraft(bag, slot)
    elseif ZO_Enchanting_IsSceneShowing() then
        return ZO_Enchanting_GetVisibleEnchanting():CanItemBeAddedToCraft(bag, slot)
    elseif ZO_FishFillet_IsSceneShowing() then
        return ZO_FishFillet_GetVisibleFishFillet():CanItemBeAddedToCraft(bag, slot)
    elseif ZO_Smithing_IsSceneShowing() then
        return ZO_Smithing_GetActiveObject():CanItemBeAddedToCraft(bag, slot)
    elseif ZO_RETRAIT_STATION_MANAGER:IsRetraitSceneShowing() then
        return SYSTEMS:GetObject("retrait"):CanItemBeAddedToCraft(bag, slot)
    end

    return false
end

local function IsItemAlreadySlottedToCraft(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if SYSTEMS:IsShowing(ZO_ALCHEMY_SYSTEM_NAME) then
        return SYSTEMS:GetObject(ZO_ALCHEMY_SYSTEM_NAME):IsItemAlreadySlottedToCraft(bag, slot)
    elseif ZO_Enchanting_IsSceneShowing() then
        return ZO_Enchanting_GetVisibleEnchanting():IsItemAlreadySlottedToCraft(bag, slot)
    elseif ZO_FishFillet_IsSceneShowing() then
        return ZO_FishFillet_GetVisibleFishFillet():IsItemAlreadySlottedToCraft(bag, slot)
    elseif ZO_Smithing_IsSceneShowing() then
        return ZO_Smithing_GetActiveObject():IsItemAlreadySlottedToCraft(bag, slot)
    elseif ZO_RETRAIT_STATION_MANAGER:IsRetraitSceneShowing() then
        return SYSTEMS:GetObject("retrait"):IsItemAlreadySlottedToCraft(bag, slot)
    end
    return false
end

local function TryAddItemToCraft(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if SYSTEMS:IsShowing(ZO_ALCHEMY_SYSTEM_NAME) then
        SYSTEMS:GetObject(ZO_ALCHEMY_SYSTEM_NAME):AddItemToCraft(bag, slot)
    elseif ZO_Enchanting_IsSceneShowing() then
        ZO_Enchanting_GetVisibleEnchanting():AddItemToCraft(bag, slot)
    elseif ZO_FishFillet_IsSceneShowing() then
        ZO_FishFillet_GetVisibleFishFillet():AddItemToCraft(bag, slot)
    elseif ZO_Smithing_IsSceneShowing() then
        ZO_Smithing_GetActiveObject():AddItemToCraft(bag, slot)
    elseif ZO_RETRAIT_STATION_MANAGER:IsRetraitSceneShowing() then
        SYSTEMS:GetObject("retrait"):AddItemToCraft(bag, slot)
    end
    UpdateMouseoverCommand(inventorySlot)
end

local function TryRemoveItemFromCraft(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if SYSTEMS:IsShowing(ZO_ALCHEMY_SYSTEM_NAME) then
        SYSTEMS:GetObject(ZO_ALCHEMY_SYSTEM_NAME):RemoveItemFromCraft(bag, slot)
    elseif ZO_Enchanting_IsSceneShowing() then
       ZO_Enchanting_GetVisibleEnchanting():RemoveItemFromCraft(bag, slot)
    elseif ZO_Smithing_IsSceneShowing() then
        ZO_Smithing_GetActiveObject():RemoveItemFromCraft(bag, slot)
    elseif ZO_RETRAIT_STATION_MANAGER:IsRetraitSceneShowing() then
        SYSTEMS:GetObject("retrait"):RemoveItemFromCraft(bag, slot)
    elseif ZO_FishFillet_IsSceneShowing() then
        ZO_FishFillet_GetActiveObject():RemoveItemFromCraft(bag, slot)
    end
    UpdateMouseoverCommand(inventorySlot)
end

local function TryRemoveAllFromCraft()
    if ZO_Enchanting_IsSceneShowing() then
       ZO_Enchanting_GetVisibleEnchanting():ClearSelections()
    elseif ZO_Smithing_IsSceneShowing() then
        ZO_Smithing_GetActiveObject():ClearSelections()
    end
end

local function IsCraftingSlotType(slotType)
    return slotType == SLOT_TYPE_CRAFTING_COMPONENT
        or slotType == SLOT_TYPE_PENDING_CRAFTING_COMPONENT
        or slotType == SLOT_TYPE_MULTIPLE_PENDING_CRAFTING_COMPONENTS
        or slotType == SLOT_TYPE_SMITHING_MATERIAL
        or slotType == SLOT_TYPE_SMITHING_STYLE
        or slotType == SLOT_TYPE_SMITHING_TRAIT
        or slotType == SLOT_TYPE_SMITHING_BOOSTER
        or slotType == SLOT_TYPE_PENDING_RETRAIT_ITEM
end

local function ShouldHandleClick(inventorySlot)
    local slotType = ZO_InventorySlot_GetType(inventorySlot)

    -- TODO: Really just needs to check if a slot has something in it and isn't locked.
    -- Needs to support all types.  Also, bag/bank slots always have something because
    -- inventory is a list...only occupied rows are shown.

    if slotType == SLOT_TYPE_ITEM or slotType == SLOT_TYPE_BANK_ITEM then
        -- TODO: Check locked state here...locked slots do nothing?
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if PLAYER_INVENTORY:IsSlotOccupied(bag, index) then
            return true
        end

        return false
    elseif IsCraftingSlotType(slotType) then
        return not ZO_CraftingUtils_IsPerformingCraftProcess()
    end

    return true
end

local g_slotActions = ZO_InventorySlotActions:New()

local function DiscoverSlotActionFromType(actionContainer, inventorySlot, ...)
    local slotType = ZO_InventorySlot_GetType(inventorySlot)
    local action = actionContainer[slotType]
    if action then
        action(inventorySlot, ...)
    end
end

local function DefaultUseItemFunction(inventorySlot, slotActions)
    if CanUseItem(inventorySlot) then
        local bag, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local onUseType = GetItemUseType(bag, slotIndex)
        if onUseType == ITEM_USE_TYPE_COMBINATION then
            slotActions:AddSlotAction(SI_ITEM_ACTION_USE, function() ZO_InventorySlot_InitiateConfirmUseItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
        else
            slotActions:AddSlotAction(SI_ITEM_ACTION_USE, function() TryUseItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
        end
    end
end

local useActions =
{
    [SLOT_TYPE_QUEST_ITEM] = function(inventorySlot, slotActions)
        if CanUseItemQuestItem(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_USE, function() TryUseQuestItem(inventorySlot) end, "primary", nil, {visibleWhenDead = true})
        end
    end,
    [SLOT_TYPE_ITEM] = DefaultUseItemFunction,
    [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM] = DefaultUseItemFunction,
    [SLOT_TYPE_CRAFT_BAG_ITEM] = DefaultUseItemFunction,
    [SLOT_TYPE_COLLECTIONS_INVENTORY] = function(inventorySlot, slotActions)
        local textEnum
        local category = inventorySlot.categoryType
        if category == COLLECTIBLE_CATEGORY_TYPE_MEMENTO then
            textEnum = SI_COLLECTIBLE_ACTION_USE
        elseif inventorySlot.active then
            if category == COLLECTIBLE_CATEGORY_TYPE_ASSISTANT or category == COLLECTIBLE_CATEGORY_TYPE_VANITY_PET or category == COLLECTIBLE_CATEGORY_TYPE_COMPANION then
                textEnum = SI_COLLECTIBLE_ACTION_DISMISS
            else
                textEnum = SI_COLLECTIBLE_ACTION_PUT_AWAY
            end
        else
            textEnum = SI_COLLECTIBLE_ACTION_SET_ACTIVE
        end

        local useCollectibleCallback = function()
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(inventorySlot.collectibleId)
            collectibleData:Use(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
        end

        slotActions:AddSlotAction(textEnum, useCollectibleCallback, "primary", nil, {visibleWhenDead = false})
    end,
}

local function MarkAsPlayerLockedHelper(bag, index, isPlayerLocked)
    SetItemIsPlayerLocked(bag, index, isPlayerLocked)
    PlaySound(isPlayerLocked and SOUNDS.INVENTORY_ITEM_LOCKED or SOUNDS.INVENTORY_ITEM_UNLOCKED)
end

local function MarkAsJunkHelper(bag, index, isJunk)
    SetItemIsJunk(bag, index, isJunk)
    PlaySound(isJunk and SOUNDS.INVENTORY_ITEM_JUNKED or SOUNDS.INVENTORY_ITEM_UNJUNKED)
end

local function GetBagItemLink(inventorySlot, linkStyle)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local slotType = ZO_InventorySlot_GetType(inventorySlot)

    if(slotType == SLOT_TYPE_EQUIPMENT or slotType == SLOT_TYPE_DYEABLE_EQUIPMENT) then
        local _, stackCount = GetItemInfo(bag, index)
        if(stackCount == 0) then
            return -- nothing here, can't link
        end
    end

    return GetItemLink(bag, index, linkStyle)
end

local function GetQuestItemSlotLink(inventorySlot, linkStyle)
    if(inventorySlot.toolIndex) then
        return GetQuestToolLink(inventorySlot.questIndex, inventorySlot.toolIndex, linkStyle)
    else
        return GetQuestItemLink(inventorySlot.questIndex, inventorySlot.stepIndex, inventorySlot.conditionIndex, linkStyle)
    end
end

local function GetInventoryCollectibleLink(slot, linkStyle)
    return GetCollectibleLink(slot.collectibleId, linkStyle)
end

local function GetLootLink(lootSlot, linkStyle)
    if not lootSlot.lootEntry.currencyType then
        return GetLootItemLink(lootSlot.lootEntry.lootId, linkStyle)
    end
end

local function GetAchievementRewardLink(achievementRewardItem, linkStyle)
    local achievementId = ZO_Inventory_GetBagAndIndex(achievementRewardItem)

    local hasRewardItem = GetAchievementRewardItem(achievementId)
    if hasRewardItem then
        return GetAchievementItemLink(achievementId, linkStyle)
    end
end

local function GetSmithingBoosterLink(inventorySlot, linkStyle)
    return GetSmithingImprovementItemLink(inventorySlot.craftingType, inventorySlot.index, linkStyle)
end

local function GetTradingHouseSearchResultLink(inventorySlot, linkStyle)
    return GetTradingHouseSearchResultItemLink(ZO_Inventory_GetSlotIndex(inventorySlot), linkStyle)
end

local function GetTradingHouseListingLink(inventorySlot, linkStyle)
    return GetTradingHouseListingItemLink(ZO_Inventory_GetSlotIndex(inventorySlot), linkStyle)
end

local function GetGuildSpecificLink(inventorySlot, linkStyle)
    return GetGuildSpecificItemLink(ZO_Inventory_GetSlotIndex(inventorySlot), linkStyle)
end

local function IsCraftingActionVisible()
    return not ZO_CraftingUtils_IsPerformingCraftProcess()
end

local function LinkHelper(slotActions, actionName, link)
    if link and link ~= "" then
        if actionName == "link_to_chat" and IsChatSystemAvailableForCurrentPlatform() then
            local linkFn = function()
                local formattedLink = zo_strformat(SI_TOOLTIP_ITEM_NAME, link)
                if IsInGamepadPreferredMode() then
                    ZO_LinkHandler_InsertLinkAndSubmit(formattedLink)
                else
                    ZO_LinkHandler_InsertLink(formattedLink)
                end
            end

            slotActions:AddSlotAction(SI_ITEM_ACTION_LINK_TO_CHAT, linkFn, "secondary", nil, {visibleWhenDead = true})
        elseif actionName == "report_item" and GetLinkType(link) == LINK_TYPE_ITEM then
            slotActions:AddSlotAction(SI_ITEM_ACTION_REPORT_ITEM, 
                                        function()
                                            if IsInGamepadPreferredMode() then
                                                KEYBIND_STRIP:RemoveAllKeyButtonGroups()
                                                HELP_ITEM_ASSISTANCE_GAMEPAD:InitWithDetails(link)
                                                -- if we open up the help menu while interacting, we want to make sure that we are not
                                                -- just pushing the previous scene onto the stack since it will end the interaction
                                                -- and make the scene invalid when coming back to it after the help scene is closed
                                                local sceneName = HELP_ITEM_ASSISTANCE_GAMEPAD:GetSceneName()
                                                if INTERACT_WINDOW:IsInteracting() then
                                                    SCENE_MANAGER:Show(sceneName)
                                                else
                                                    SCENE_MANAGER:Push(sceneName)
                                                end
                                            else
                                                HELP_CUSTOMER_SUPPORT_KEYBOARD:OpenScreen(HELP_CUSTOMER_SERVICE_ITEM_ASSISTANCE_KEYBOARD:GetFragment())
                                                HELP_CUSTOMER_SERVICE_ITEM_ASSISTANCE_KEYBOARD:SetDetailsFromItemLink(link)
                                            end
                                        end,
                                        "secondary")
        end
    end
end

-- TODO: Remove implementation dependencies by writing objects that encapsulate all the fields like .componentId, or .lootEntry.lootId, etc...)
-- The need for this table would be removed by allowing a single construct like: slotActions:AddSlotAction(str_id, function() inventorySlot:LinkToChat() end, ...)
local linkHelperActions =
{
    [SLOT_TYPE_QUEST_ITEM] =                    function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetQuestItemSlotLink, inventorySlot)) end,
    [SLOT_TYPE_ITEM] =                          function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_EQUIPMENT] =                     function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_BANK_ITEM] =                     function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_GUILD_BANK_ITEM] =               function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_MY_TRADE] =                      function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetTradeItemLink, TRADE_ME, inventorySlot.index)) end,
    [SLOT_TYPE_THEIR_TRADE] =                   function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetTradeItemLink, TRADE_THEM, inventorySlot.index)) end,
    [SLOT_TYPE_STORE_BUY] =                     function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetStoreItemLink, inventorySlot.index)) end,
    [SLOT_TYPE_BUY_MULTIPLE] =                  function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetStoreItemLink, inventorySlot.index)) end,
    [SLOT_TYPE_STORE_BUYBACK] =                 function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBuybackItemLink, inventorySlot.index)) end,
    [SLOT_TYPE_MAIL_QUEUED_ATTACHMENT] =        function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetMailQueuedAttachmentLink, GetQueuedItemAttachmentSlotIndex(inventorySlot))) end,

    [SLOT_TYPE_MAIL_ATTACHMENT] =               function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetAttachedItemLink, MAIL_INBOX:GetOpenMailId(), ZO_Inventory_GetSlotIndex(inventorySlot))) end,

    [SLOT_TYPE_ACHIEVEMENT_REWARD] =            function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetAchievementRewardLink, inventorySlot)) end,
    [SLOT_TYPE_LOOT] =                          function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetLootLink, inventorySlot)) end,

    [SLOT_TYPE_TRADING_HOUSE_POST_ITEM] =       function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_REPAIR] =                        function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_CRAFTING_COMPONENT] =            function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_PENDING_CRAFTING_COMPONENT] =    function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_SMITHING_MATERIAL] =             function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetSmithingPatternMaterialItemLink, inventorySlot.patternIndex, inventorySlot.materialIndex)) end,
    [SLOT_TYPE_SMITHING_STYLE] =                function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetItemStyleMaterialLink, inventorySlot.styleIndex)) end,
    [SLOT_TYPE_SMITHING_TRAIT] =                function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, inventorySlot.traitType ~= ITEM_TRAIT_TYPE_NONE and ZO_LinkHandler_CreateChatLink(GetSmithingTraitItemLink, inventorySlot.traitIndex)) end,
    [SLOT_TYPE_SMITHING_BOOSTER] =              function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetSmithingBoosterLink, inventorySlot)) end,
    [SLOT_TYPE_DYEABLE_EQUIPMENT] =             function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT] =     function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetTradingHouseSearchResultLink, inventorySlot)) end,
    [SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING] =    function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetTradingHouseListingLink, inventorySlot)) end,
    [SLOT_TYPE_GUILD_SPECIFIC_ITEM] =           function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetGuildSpecificLink, inventorySlot)) end,
    [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM] =        function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_COLLECTIONS_INVENTORY] =         function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetInventoryCollectibleLink, inventorySlot)) end,
    [SLOT_TYPE_CRAFT_BAG_ITEM] =                function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_PENDING_RETRAIT_ITEM] =          function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
}

---- Quickslot Action Handlers ----
local QUICKSLOT_SHARED_OPTIONS = {visibleWhenDead = true}

local function AddQuickslotRemoveAction(slotActions, slot)
    slotActions:AddSlotAction(SI_ITEM_ACTION_REMOVE_FROM_QUICKSLOT, function() ClearSlot(slot, HOTBAR_CATEGORY_QUICKSLOT_WHEEL) end, "primary", nil, QUICKSLOT_SHARED_OPTIONS)
end

local function AddQuickslotAddAction(callback, slotActions)
    slotActions:AddSlotAction(SI_ITEM_ACTION_MAP_TO_QUICKSLOT, callback, "primary", nil, QUICKSLOT_SHARED_OPTIONS)
end

local function ItemQuickslotAction(inventorySlot, slotActions)
    if QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local currentSlot = FindActionSlotMatchingItem(bag, index, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
        if currentSlot then
            AddQuickslotRemoveAction(slotActions, currentSlot)
        else
            local validSlot = GetFirstFreeValidSlotForItem(bag, index, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
            if validSlot then
                AddQuickslotAddAction(function()
                     SelectSlotItem(bag, index, validSlot, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
                 end, slotActions)
            end
        end
    end
end

local function ApplySimpleQuickslotAction(slotActions, actionType, actionId)
    if QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() then
        local currentSlot = FindActionSlotMatchingSimpleAction(actionType, actionId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
        if currentSlot then
            AddQuickslotRemoveAction(slotActions, currentSlot)
        else
            local validSlot = GetFirstFreeValidSlotForSimpleAction(actionType, actionId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
            if validSlot then
                AddQuickslotAddAction(function()
                    SelectSlotSimpleAction(actionType, actionId, validSlot, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
                end, slotActions)
            end
        end
    end
end

local function CollectibleQuickslotAction(slot, slotActions)
    ApplySimpleQuickslotAction(slotActions, ACTION_TYPE_COLLECTIBLE, slot.collectibleId)
end

local function QuestItemQuickslotAction(slot, slotActions)
    local questItemId
    if slot.toolIndex then
        questItemId = GetQuestToolQuestItemId(slot.questIndex, slot.toolIndex)
    else
        questItemId = GetQuestConditionQuestItemId(slot.questIndex, slot.stepIndex, slot.conditionIndex)
    end
    ApplySimpleQuickslotAction(slotActions, ACTION_TYPE_QUEST_ITEM, questItemId)
end

internalassert(ACTION_TYPE_MAX_VALUE == 10, "Update quickslot actions")
local quickslotActions =
{
    [SLOT_TYPE_ITEM] = ItemQuickslotAction,
    [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM] = ItemQuickslotAction,
    [SLOT_TYPE_COLLECTIONS_INVENTORY] = CollectibleQuickslotAction,
    [SLOT_TYPE_QUEST_ITEM] = QuestItemQuickslotAction,
}

---- Rename Action Handlers ----
local renameActions = 
{
    [SLOT_TYPE_COLLECTIONS_INVENTORY] = function(slot, slotActions)
        local collectibleId = slot.collectibleId
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData and collectibleData:IsRenameable() then
            slotActions:AddSlotAction(SI_COLLECTIBLE_ACTION_RENAME, ZO_CollectionsBook.GetShowRenameDialogClosure(collectibleId), "keybind1")
        end
    end
}

local actionHandlers =
{
    ["use"] = function(inventorySlot, slotActions)
        DiscoverSlotActionFromType(useActions, inventorySlot, slotActions)
    end,

    ["mail_attach"] = function(inventorySlot, slotActions)
        if IsSendingMail() and not IsItemAlreadyAttachedToMail(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_MAIL_ATTACH, function() TryMailItem(inventorySlot) end, "primary")
        end
    end,

    ["mail_detach"] = function(inventorySlot, slotActions)
        if IsSendingMail() and IsItemAlreadyAttachedToMail(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_MAIL_DETACH, function() RemoveQueuedAttachment(inventorySlot) end, "primary")
        end
    end,

    ["bank_deposit"] = function(inventorySlot, slotActions)
        if IsBankOpen() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_BANK_DEPOSIT, function() TryBankItem(inventorySlot) end, "primary")
        end
    end,

    ["bank_withdraw"] = function(inventorySlot, slotActions)
        if IsBankOpen() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_BANK_WITHDRAW, function() TryBankItem(inventorySlot) end, "primary")
        end
    end,

    ["guild_bank_deposit"] = function(inventorySlot, slotActions)
        if GetSelectedGuildBankId() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_BANK_DEPOSIT,  function()
                local bag, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
                TryGuildBankDepositItem(bag, slotIndex)
            end, "primary")
        end
    end,

    ["guild_bank_withdraw"] = function(inventorySlot, slotActions)
        if GetSelectedGuildBankId() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_BANK_WITHDRAW, function()
                local _, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
                TryGuildBankWithdrawItem(slotIndex)
            end, "primary")
        end
    end,

    ["trade_add"] = function(inventorySlot, slotActions)
        if TRADE_WINDOW:IsTrading() and CanTradeItem(inventorySlot) and not IsItemAlreadyBeingTraded(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_TRADE_ADD, function() TryTradeItem(inventorySlot) end, "primary")
        end
    end,

    ["trade_remove"] = function(inventorySlot, slotActions)
        if TRADE_WINDOW:IsTrading() and IsItemAlreadyBeingTraded(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_TRADE_REMOVE, function() TryRemoveFromTrade(inventorySlot) end, "primary")
        end
    end,

    ["sell"] = function(inventorySlot, slotActions)
        if CanSellItem(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_SELL, function() TrySellItem(inventorySlot) end, "primary")
        end
    end,

    ["launder"] = function(inventorySlot, slotActions)
        if CanLaunderItem() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_LAUNDER, function() TryLaunderItem(inventorySlot) end, "primary")
        end
    end,

    ["buy"] = function(inventorySlot, slotActions)
        if not inventorySlot.locked then
            slotActions:AddSlotAction(SI_ITEM_ACTION_BUY, function() BuyItemFromStore(inventorySlot) end, "primary")
        end
    end,

    ["buy_multiple"] = function(inventorySlot, slotActions)
        if CanBuyMultiple(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_BUY_MULTIPLE, function() TryBuyMultiple(inventorySlot) end, "secondary")
        end
    end,

    ["buyback"] = function(inventorySlot, slotActions)
        slotActions:AddSlotAction(SI_ITEM_ACTION_BUYBACK, function() BuybackItem(inventorySlot.index) end, "primary")
    end,

    ["equip"] = function(inventorySlot, slotActions)
        if CanEquipItem(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_EQUIP, function() TryEquipItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
        end
    end,

    ["gamepad_equip"] = function(inventorySlot, slotActions)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local itemActorCategory = GetItemActorCategory(bag, index)
        local playerSceneShown = itemActorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER and GAMEPAD_INVENTORY_ROOT_SCENE:IsShowing()
        local companionSceneShown = itemActorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION and COMPANION_EQUIPMENT_GAMEPAD_SCENE:IsShowing()
        if (playerSceneShown or companionSceneShown) and IsEquipable(bag, index) and CanEquipItem(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_EQUIP, function()
                if playerSceneShown then
                    GAMEPAD_INVENTORY:TryEquipItem(inventorySlot)
                else
                    COMPANION_EQUIPMENT_GAMEPAD:TryEquipItem(inventorySlot)
                end
            end, "primary")
        end
    end,

    ["unequip"] = function(inventorySlot, slotActions)
        if CanUnequipItem(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_UNEQUIP, function() TryUnequipItem(inventorySlot) end, "primary")
        end
    end,

    ["take_loot"] = function(inventorySlot, slotActions)
        slotActions:AddSlotAction(SI_ITEM_ACTION_LOOT_TAKE, function() TakeLoot(inventorySlot) end, "primary", function() return false end)
    end,

    ["destroy"] = function(inventorySlot, slotActions)
        if not IsSlotLocked(inventorySlot) and ZO_InventorySlot_CanDestroyItem(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_DESTROY, function() ZO_InventorySlot_InitiateDestroyItem(inventorySlot) end, "secondary")
        end
    end,

    ["split_stack"] = function(inventorySlot, slotActions)
        if ZO_InventorySlot_CanSplitItemStack(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_SPLIT_STACK, function() ZO_InventorySlot_TrySplitStack(inventorySlot) end, "secondary")
        end
    end,

    ["enchant"] = function(inventorySlot, slotActions)
        if CanEnchantItem(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_ENCHANT, function() TryEnchantItem(inventorySlot) end, "keybind1")
        end
    end,

    ["charge"] = function(inventorySlot, slotActions)
        if CanChargeItem(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_CHARGE, function() TryChargingItem(inventorySlot) end, "keybind2")
        end
    end,

    ["kit_repair"] = function(inventorySlot, slotActions)
        if CanKitRepairItem(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_REPAIR, function() TryKitRepairItem(inventorySlot) end, "keybind2")
        end
    end,

    ["link_to_chat"] = function(inventorySlot, slotActions)
        if ZO_InventorySlot_GetStackCount(inventorySlot) > 0 or ZO_ItemSlot_GetAlwaysShowStackCount(inventorySlot) then
            DiscoverSlotActionFromType(linkHelperActions, inventorySlot, slotActions, "link_to_chat")
        end
    end,

    ["link_to_quest"] = function(inventorySlot, slotActions)
        slotActions:AddSlotAction(SI_ITEM_ACTION_SHOW_QUEST, function()  
            SYSTEMS:GetObject("questJournal"):OpenQuestJournalToQuest(inventorySlot.questIndex)
        end, "link_to_quest")
    end,

    ["report_item"] = function(inventorySlot, slotActions)
        if ZO_InventorySlot_GetStackCount(inventorySlot) > 0 or ZO_ItemSlot_GetAlwaysShowStackCount(inventorySlot) then
            DiscoverSlotActionFromType(linkHelperActions, inventorySlot, slotActions, "report_item")
        end
    end,

    ["mark_as_locked"] = function(inventorySlot, slotActions)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if not IsSlotLocked(inventorySlot) and CanItemBePlayerLocked(bag, index) and not IsItemPlayerLocked(bag, index) and not (QUICKSLOT_KEYBOARD and QUICKSLOT_KEYBOARD:AreQuickSlotsShowing()) and not IsItemAlreadySlottedToCraft(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_MARK_AS_LOCKED, function() MarkAsPlayerLockedHelper(bag, index, true) end, "secondary")
        end
    end,

    ["unmark_as_locked"] = function(inventorySlot, slotActions)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if not IsSlotLocked(inventorySlot) and CanItemBePlayerLocked(bag, index) and IsItemPlayerLocked(bag, index) and not (QUICKSLOT_KEYBOARD and QUICKSLOT_KEYBOARD:AreQuickSlotsShowing()) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_UNMARK_AS_LOCKED, function() MarkAsPlayerLockedHelper(bag, index, false) end, "secondary")
        end
    end,

    ["mark_as_junk"] = function(inventorySlot, slotActions)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local actorCategory = GetItemActorCategory(bag, index)
        if not IsInGamepadPreferredMode() and actorCategory ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION and not IsSlotLocked(inventorySlot) and CanItemBeMarkedAsJunk(bag, index) and not IsItemJunk(bag, index) and not QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_MARK_AS_JUNK, function() MarkAsJunkHelper(bag, index, true) end, "secondary")
        end
    end,

    ["unmark_as_junk"] = function(inventorySlot, slotActions)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if not IsInGamepadPreferredMode() and not IsSlotLocked(inventorySlot) and CanItemBeMarkedAsJunk(bag, index) and IsItemJunk(bag, index) and not QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_UNMARK_AS_JUNK, function() MarkAsJunkHelper(bag, index, false) end, "secondary")
        end
    end,

    ["quickslot"] = function(inventorySlot, slotActions)
        if not IsInGamepadPreferredMode() then
            DiscoverSlotActionFromType(quickslotActions, inventorySlot, slotActions)
        end
    end,

    ["trading_house_post"] = function(inventorySlot, slotActions)
        if TRADING_HOUSE_SEARCH:IsAtTradingHouse() and not IsItemAlreadyBeingPosted(inventorySlot) then
            slotActions:AddSlotAction(SI_TRADING_HOUSE_ADD_ITEM_TO_LISTING, function() TryInitiatingItemPost(inventorySlot) end, "primary")
        end
    end,

    ["trading_house_search_from_sell"] = function(inventorySlot, slotActions)
        if TRADING_HOUSE_SEARCH:IsAtTradingHouse() then
            slotActions:AddSlotAction(SI_TRADING_HOUSE_SEARCH_FROM_ITEM, function()
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                local itemLink = GetItemLink(bag, index)
                TRADING_HOUSE:SearchForItemLink(itemLink)
            end, "keybind3")
        end
    end,

    ["trading_house_search_from_results"] = function(inventorySlot, slotActions)
        if TRADING_HOUSE_SEARCH:IsAtTradingHouse() then
            slotActions:AddSlotAction(SI_TRADING_HOUSE_SEARCH_FROM_ITEM, function()
                local resultIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
                local itemLink = GetTradingHouseSearchResultItemLink(resultIndex)
                TRADING_HOUSE:SearchForItemLink(itemLink)
            end, "primary")
        end
    end,

    ["trading_house_search_from_listings"] = function(inventorySlot, slotActions)
        if TRADING_HOUSE_SEARCH:IsAtTradingHouse() then
            slotActions:AddSlotAction(SI_TRADING_HOUSE_SEARCH_FROM_ITEM, function()
                local listingIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
                local itemLink = GetTradingHouseListingItemLink(listingIndex)
                TRADING_HOUSE:SearchForItemLink(itemLink)
            end, "primary")
        end
    end,

    ["trading_house_remove_pending_post"] = function(inventorySlot, slotActions)
        if TRADING_HOUSE_SEARCH:IsAtTradingHouse() and IsItemAlreadyBeingPosted(inventorySlot) then
            slotActions:AddSlotAction(SI_TRADING_HOUSE_REMOVE_PENDING_POST, function() ClearItemPost(inventorySlot) end, "primary")
        end
    end,

    ["trading_house_buy_item"] = function(inventorySlot, slotActions)
        if TRADING_HOUSE:CanBuyItem(inventorySlot) then
            slotActions:AddSlotAction(SI_TRADING_HOUSE_BUY_ITEM, function() TryBuyingTradingHouseItem(inventorySlot) end, "primary")
        end
    end,

    ["trading_house_cancel_listing"] = function(inventorySlot, slotActions)
        slotActions:AddSlotAction(SI_TRADING_HOUSE_CANCEL_LISTING, function() TryCancellingTradingHouseListing(inventorySlot) end, "secondary")
    end,

    ["convert_to_imperial_style"] = function(inventorySlot, slotActions)
        local imperialStyleId = GetImperialStyleId()
        if CanConvertToStyle(inventorySlot, imperialStyleId) then
            local imperialStyleName = GetItemStyleName(imperialStyleId)
            slotActions:AddSlotAction(SI_ITEM_ACTION_CONVERT_TO_IMPERIAL_STYLE, function() ZO_Dialogs_ShowPlatformDialog("CONVERT_STYLE_MOVED", nil, { mainTextParams = { imperialStyleName }, titleParams = { imperialStyleName } }) end, "secondary")
        end
    end,

    ["convert_to_morag_tong_style"] = function(inventorySlot, slotActions)
        local moragTongStyleId = GetMoragTongStyleId()
        if CanConvertToStyle(inventorySlot, moragTongStyleId) then
            local moragStyleName = GetItemStyleName(moragTongStyleId)
            slotActions:AddSlotAction(SI_ITEM_ACTION_CONVERT_TO_MORAG_TONG_STYLE, function() ZO_Dialogs_ShowPlatformDialog("CONVERT_STYLE_MOVED", nil, { mainTextParams = { moragStyleName }, titleParams = { moragStyleName } }) end, "secondary")
        end
    end,

    ["vendor_repair"] = function(inventorySlot, slotActions)
        slotActions:AddSlotAction(SI_ITEM_ACTION_REPAIR, function() TryVendorRepairItem(inventorySlot) end, "primary")
    end,
                                
    ["add_to_craft"] = function(inventorySlot, slotActions)
        if not IsItemAlreadySlottedToCraft(inventorySlot) and CanItemBeAddedToCraft(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_ADD_TO_CRAFT, function() TryAddItemToCraft(inventorySlot) end, "primary", IsCraftingActionVisible)
        end
    end,
                            
    ["remove_from_craft"] = function(inventorySlot, slotActions)
        local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if bag and slot and IsItemAlreadySlottedToCraft(inventorySlot) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_REMOVE_FROM_CRAFT, function() TryRemoveItemFromCraft(inventorySlot) end, "primary", IsCraftingActionVisible)
        end
    end,

    ["remove_all_from_craft"] = function(inventorySlot, slotActions)
        slotActions:AddSlotAction(SI_ITEM_ACTION_REMOVE_FROM_CRAFT, TryRemoveAllFromCraft, "primary")
    end,

    ["buy_guild_specific_item"] = function(inventorySlot, slotActions)
        if TRADING_HOUSE:CanBuyItem(inventorySlot) then
            slotActions:AddSlotAction(SI_TRADING_HOUSE_BUY_ITEM, function() TryBuyingGuildSpecificItem(inventorySlot) end, "primary")
        end
    end,

    ["rename"] = function(inventorySlot, slotActions)
        DiscoverSlotActionFromType(renameActions, inventorySlot, slotActions)
    end,

    ["move_to_inventory"] = function(inventorySlot, slotActions)
        slotActions:AddSlotAction(SI_ITEM_ACTION_REMOVE_ITEMS_FROM_CRAFT_BAG, function() TryMoveToInventory(inventorySlot) end, "primary")
    end,

    ["move_to_craft_bag"] = function(inventorySlot, slotActions)
        local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if CanMoveToCraftBag(bagId, slotIndex) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_ADD_ITEMS_TO_CRAFT_BAG, function() TryMoveToCraftBag(bagId, slotIndex) end, "secondary")
        end
    end,

    ["preview_dye_stamp"] = function(inventorySlot, slotActions)
        local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if GetItemType(bag, slot) == ITEMTYPE_DYE_STAMP and IsCharacterPreviewingAvailable() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_PREVIEW_DYE_STAMP, function() TryPreviewDyeStamp(inventorySlot) end, "primary")
        end
    end,

    ["show_map_keep_recall"] = function(inventorySlot, slotActions)
        local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if GetItemUseType(bag, slot) == ITEM_USE_TYPE_KEEP_RECALL_STONE then
            slotActions:AddSlotAction(SI_ITEM_ACTION_SHOW_MAP, function() TryShowRecallMap(inventorySlot) end, "primary")
        end
    end,

    ["start_skill_respec"] = function(inventorySlot, slotActions)
        local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local itemUseType = GetItemUseType(bag, slot)
        if itemUseType == ITEM_USE_TYPE_SKILL_RESPEC or itemUseType == ITEM_USE_TYPE_MORPH_RESPEC then
            slotActions:AddSlotAction(SI_ITEM_ACTION_START_SKILL_RESPEC, function() TryStartSkillRespec(inventorySlot) end, "primary")
        end
    end,

    ["start_attribute_respec"] = function(inventorySlot, slotActions)
        local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local itemUseType = GetItemUseType(bag, slot)
        if itemUseType == ITEM_USE_TYPE_ATTRIBUTE_RESPEC then
            slotActions:AddSlotAction(SI_ITEM_ACTION_START_ATTRIBUTE_RESPEC, function() TryStartAttributeRespec(inventorySlot) end, "primary")
        end
    end,

    ["bind"] = function(inventorySlot, slotActions)
        if not IsSlotLocked(inventorySlot) then
            local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
            if ZO_InventorySlot_WillItemBecomeBoundOnEquip(bagId, slotIndex) then
                slotActions:AddSlotAction(SI_ITEM_ACTION_BIND, function() TryBindItem(bagId, slotIndex) end, "secondary", nil, {visibleWhenDead = false})
            end
        end
    end,

    ["preview"] = function(inventorySlot, slotActions)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local itemActorCategory = GetItemActorCategory(bag, index)
        -- Companion preview is not yet supported
         if itemActorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
            return false
        end
        local itemPreview = SYSTEMS:GetObject("itemPreview")
        if itemPreview:GetFragment():IsShowing() and not IsInGamepadPreferredMode() and CanInventoryItemBePreviewed(bag, index) and IsCharacterPreviewingAvailable() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_PREVIEW, function() TryPreviewItem(bag, index) end, "keybind1")
        end
    end,

    ["place_furniture"] = function(inventorySlot, slotActions)
        local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if ZO_CanPlaceItemInCurrentHouse(bagId, slotIndex) then
            slotActions:AddSlotAction(SI_ITEM_ACTION_PLACE_FURNITURE, function() ZO_TryPlaceFurnitureFromInventorySlot(bagId, slotIndex) end)
        end
    end,
}

local NON_INTERACTABLE_ITEM_ACTIONS = { "link_to_chat", "report_item" }

-- Order the possible action types in priority order, actions are marked as primary/secondary in the functions above
-- The order of the rest of the secondary actions in the table determines the order they appear on the context menu
local potentialActionsForSlotType =
{
    [SLOT_TYPE_QUEST_ITEM] =                           { "quickslot", "use", "link_to_chat", "link_to_quest" },
    [SLOT_TYPE_ITEM] =                                 { "quickslot", "mail_attach", "mail_detach", "trade_add", "trade_remove", "trading_house_post", "trading_house_remove_pending_post", "trading_house_search_from_sell", "bank_deposit", "guild_bank_deposit", "sell", "launder", "place_furniture", "equip", "use", "preview_dye_stamp", "show_map_keep_recall", "start_skill_respec", "start_attribute_respec", "split_stack", "enchant", "preview", "mark_as_locked", "unmark_as_locked", "bind", "charge", "kit_repair", "move_to_craft_bag", "link_to_chat", "mark_as_junk", "unmark_as_junk", "convert_to_imperial_style", "convert_to_morag_tong_style", "destroy", "report_item" },
    [SLOT_TYPE_EQUIPMENT] =                            { "unequip", "enchant", "mark_as_locked", "unmark_as_locked", "bind", "charge", "kit_repair", "link_to_chat", "convert_to_imperial_style", "convert_to_morag_tong_style", "destroy", "report_item" },
    [SLOT_TYPE_MY_TRADE] =                             { "trade_remove", "link_to_chat", "report_item" },
    [SLOT_TYPE_THEIR_TRADE] =                          NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_STORE_BUY] =                            { "buy", "buy_multiple", "link_to_chat", "report_item" },
    [SLOT_TYPE_STORE_BUYBACK] =                        { "buyback", "link_to_chat", "report_item" },
    [SLOT_TYPE_BUY_MULTIPLE] =                         NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_BANK_ITEM] =                            { "bank_withdraw", "place_furniture", "split_stack", "mark_as_locked", "unmark_as_locked", "bind", "link_to_chat", "mark_as_junk", "unmark_as_junk", "report_item" },
    [SLOT_TYPE_GUILD_BANK_ITEM] =                      { "guild_bank_withdraw", "link_to_chat", "report_item" },
    [SLOT_TYPE_MAIL_QUEUED_ATTACHMENT] =               { "mail_detach", "link_to_chat", "report_item" },
    [SLOT_TYPE_MAIL_ATTACHMENT] =                      NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_LOOT] =                                 { "take_loot", "link_to_chat", "report_item" },
    [SLOT_TYPE_ACHIEVEMENT_REWARD] =                   NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_TRADING_HOUSE_POST_ITEM] =              { "trading_house_remove_pending_post", "link_to_chat", "report_item" },
    [SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT] =            { "trading_house_buy_item", "link_to_chat", "trading_house_search_from_results" },
    [SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING] =           { "trading_house_cancel_listing", "link_to_chat", "trading_house_search_from_listings" },
    [SLOT_TYPE_REPAIR] =                               { "vendor_repair", "link_to_chat", "destroy", "report_item" },
    [SLOT_TYPE_PENDING_REPAIR] =                       NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_CRAFTING_COMPONENT] =                   { "add_to_craft", "remove_from_craft", "mark_as_locked", "unmark_as_locked", "link_to_chat", "report_item" },
    [SLOT_TYPE_PENDING_CRAFTING_COMPONENT] =           { "remove_from_craft", "link_to_chat", "report_item" },
    [SLOT_TYPE_MULTIPLE_PENDING_CRAFTING_COMPONENTS] = { "remove_all_from_craft", },
    [SLOT_TYPE_SMITHING_MATERIAL] =                    NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_SMITHING_STYLE] =                       NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_SMITHING_TRAIT] =                       NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_SMITHING_BOOSTER] =                     NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_DYEABLE_EQUIPMENT] =                    NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_GUILD_SPECIFIC_ITEM] =                  { "buy_guild_specific_item", "link_to_chat" },
    [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM] =               { "quickslot", "mail_attach", "mail_detach", "bank_deposit", "guild_bank_deposit", "place_furniture", "gamepad_equip", "unequip", "use", "preview_dye_stamp", "start_skill_respec", "start_attribute_respec", "show_map_keep_recall", "split_stack", "enchant", "mark_as_locked", "unmark_as_locked", "bind", "charge", "kit_repair", "move_to_craft_bag", "link_to_chat", "convert_to_imperial_style", "convert_to_morag_tong_style", "destroy", "report_item" },
    [SLOT_TYPE_COLLECTIONS_INVENTORY] =                { "quickslot", "use", "rename", "link_to_chat" },
    [SLOT_TYPE_CRAFT_BAG_ITEM] =                       { "move_to_inventory", "use", "link_to_chat", "report_item" },
    [SLOT_TYPE_PENDING_RETRAIT_ITEM] =                 { "remove_from_craft", "link_to_chat", "report_item" },
}

-- Checks to see if a certain slot type should completely disable all actions
local blanketDisableActionsForSlotType =
{
    [SLOT_TYPE_EQUIPMENT] = function(inventorySlot)
        return ZO_Character_IsReadOnly()
    end,
}

function ZO_InventorySlot_DiscoverSlotActionsFromActionList(inventorySlot, slotActions)
    local slotType = ZO_InventorySlot_GetType(inventorySlot)
    local potentialActions = potentialActionsForSlotType[slotType]
    if potentialActions then
        if not blanketDisableActionsForSlotType[slotType] or not blanketDisableActionsForSlotType[slotType]() then
            for _, action in ipairs(potentialActions) do
                local actionHandler = actionHandlers[action]
                actionHandler(inventorySlot, slotActions)
            end
        end
    end
end

local function PerClickInitializeActions(inventorySlot, useContextMenu)
    g_slotActions:Clear()
    g_slotActions:SetInventorySlot(inventorySlot)
    g_slotActions:SetContextMenuMode(useContextMenu)

    ZO_InventorySlot_DiscoverSlotActionsFromActionList(inventorySlot, g_slotActions)
end

function ZO_InventorySlot_ShowContextMenu(inventorySlot)
    PerClickInitializeActions(inventorySlot, INVENTORY_SLOT_ACTIONS_USE_CONTEXT_MENU)
    g_slotActions:Show()
end

function ZO_InventorySlot_DoPrimaryAction(inventorySlot)
    inventorySlot = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
    PerClickInitializeActions(inventorySlot, INVENTORY_SLOT_ACTIONS_PREVENT_CONTEXT_MENU)
    local actionPerformed = g_slotActions:DoPrimaryAction()

    --If no action was performed, check to see if the item used can only be used from the quickslot menu.
    if actionPerformed == false then
        local itemLink = GetItemLink(inventorySlot.bagId, inventorySlot.slotIndex)

        if IsItemLinkOnlyUsableFromQuickslot(itemLink) then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_ITEM_FORMAT_STR_ONLY_USABLE_FROM_ACTION_SLOT)
        end
    end
end

function ItemSlotHasFilterType(slotFilterData, itemFilterType)
    local hasFilterType = false

    if slotFilterData ~= nil and itemFilterType ~= nil then
        for i = 1, #slotFilterData do
            if slotFilterData[i] == itemFilterType then
                hasFilterType = true
                break
            end
        end
    end

    return hasFilterType
end

function ZO_InventorySlot_OnSlotClicked(inventorySlot, button)
    inventorySlot = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        -- Left clicks are only used as drops at the moment, use the receive drag handlers
        ZO_InventorySlot_OnReceiveDrag(inventorySlot)
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        -- Right clicks only open the context menu
        if ShouldHandleClick(inventorySlot) then
            ZO_InventorySlot_ShowContextMenu(inventorySlot)
        end
    end
end

--
-- Mouse Over
--
local SHOW_COLLECTIBLE_NICKNAME, SHOW_COLLECTIBLE_PURCHASABLE_HINT, SHOW_COLLECTIBLE_BLOCK_REASON = true, true, true

local InventoryEnter =
{
    [SLOT_TYPE_QUEST_ITEM] =
    {
        function(inventorySlot)
            if(inventorySlot) then
                if inventorySlot.toolIndex then
                    ItemTooltip:SetQuestTool(inventorySlot.questIndex, inventorySlot.toolIndex)
                else
                    ItemTooltip:SetQuestItem(inventorySlot.questIndex, inventorySlot.stepIndex, inventorySlot.conditionIndex)
                end
            end

            return true, ItemTooltip
        end,
    },
    [SLOT_TYPE_ITEM] =
    {
        function(inventorySlot)
            local data = ZO_Inventory_GetSlotDataForInventoryControl(inventorySlot)
            if data then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                ItemTooltip:SetBagItem(bag, index)
                return true, ItemTooltip
            else
                return false, ItemTooltip
            end
        end
    },
    [SLOT_TYPE_BANK_ITEM] =
    {
        function(inventorySlot)
            local data = ZO_Inventory_GetSlotDataForInventoryControl(inventorySlot)
            if data then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                ItemTooltip:SetBagItem(bag, index)
                return true, ItemTooltip
            else
                return false, ItemTooltip
            end
        end
    },
    [SLOT_TYPE_GUILD_BANK_ITEM] =
    {
        function(inventorySlot)
            local data = ZO_Inventory_GetSlotDataForInventoryControl(inventorySlot)
            if data then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                ItemTooltip:SetBagItem(bag, index)
                return true, ItemTooltip
            else
                return false, ItemTooltip
            end
        end
    },
    [SLOT_TYPE_EQUIPMENT] =
    {
        function(inventorySlot)
            local wornBag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            local isEquipped = GetWornItemInfo(wornBag, index)

            if isEquipped then
                ItemTooltip:SetWornItem(index, wornBag)
                return true, ItemTooltip
            else
                SetTooltipText(InformationTooltip, zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_EQUIPSLOT", index)))
                return true, InformationTooltip
            end
        end
    },
    [SLOT_TYPE_MY_TRADE] =
    {
        function(inventorySlot)
            local _, _, stackCount = GetTradeItemInfo(TRADE_ME, ZO_Inventory_GetSlotIndex(inventorySlot))
            if(stackCount > 0) then
                ItemTooltip:SetTradeItem(TRADE_ME, ZO_Inventory_GetSlotIndex(inventorySlot))
                return true, ItemTooltip
            end
        end
    },
    [SLOT_TYPE_THEIR_TRADE] =
    {
        function(inventorySlot)
            local _, _, stackCount = GetTradeItemInfo(TRADE_THEM, ZO_Inventory_GetSlotIndex(inventorySlot))
            if(stackCount > 0) then
                ItemTooltip:SetTradeItem(TRADE_THEM, ZO_Inventory_GetSlotIndex(inventorySlot))
                return true, ItemTooltip
            end
        end
    },
    [SLOT_TYPE_STORE_BUYBACK] =
    {
        function(inventorySlot)
            ItemTooltip:SetBuybackItem(inventorySlot.index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_STORE_BUY] =
    {
        function(inventorySlot)
            ItemTooltip:SetStoreItem(inventorySlot.index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_BUY_MULTIPLE] =
    {
        function(inventorySlot)
            ItemTooltip:SetStoreItem(inventorySlot.index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_MAIL_QUEUED_ATTACHMENT] =
    {
        function(inventorySlot)
            if inventorySlot.bagId then -- If this is because money looks like a queued attachment, we should probably split it out into its own fields in the compose mail pane...
                ItemTooltip:SetBagItem(inventorySlot.bagId, inventorySlot.slotIndex)
                return true, ItemTooltip
            end
        end
    },
    [SLOT_TYPE_MAIL_ATTACHMENT] =
    {
        function(inventorySlot)
            local attachmentIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
            if(attachmentIndex) then
                if inventorySlot.money then
                    if inventorySlot.money > 0 then
                        ZO_ItemTooltip_SetMoney(ItemTooltip, inventorySlot.money)
                        return true, ItemTooltip
                    end
                elseif(inventorySlot.stackCount > 0) then
                    ItemTooltip:SetAttachedMailItem(MAIL_INBOX:GetOpenMailId(), attachmentIndex)
                    return true, ItemTooltip
                end
            end
        end
    },
    [SLOT_TYPE_LOOT] =
    {
        function(inventorySlot)
            local entry = inventorySlot.lootEntry
            if entry then
                if entry.currencyType then
                    ItemTooltip:SetCurrency(entry.currencyType, entry.currencyAmount)
                    return true, ItemTooltip
                else
                    ItemTooltip:SetLootItem(entry.lootId)
                    return true, ItemTooltip
                end
            end
        end
    },
    [SLOT_TYPE_ACHIEVEMENT_REWARD] =
    {
        function(inventorySlot)
            ItemTooltip:SetAchievementRewardItem(inventorySlot.achievement.achievementId, inventorySlot.rewardIndex)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_PENDING_CHARGE] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_ENCHANTMENT] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_ENCHANTMENT_RESULT] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetItemUsingEnchantment(bag, index, inventorySlot.enchantmentBagId, inventorySlot.enchantmentSlotIndex)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_TRADING_HOUSE_POST_ITEM] =
    {
        function(inventorySlot)
            if(ZO_InventorySlot_GetStackCount(inventorySlot) > 0) then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                ItemTooltip:SetBagItem(bag, index)
                return true, ItemTooltip
            end
        end,
    },
    [SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT] =
    {
        function(inventorySlot)
            local tradingHouseIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
            ItemTooltip:SetTradingHouseItem(tradingHouseIndex)
            return true, ItemTooltip
        end,
    },
    [SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING] =
    {
        function(inventorySlot)
            local tradingHouseListingIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
            ItemTooltip:SetTradingHouseListing(tradingHouseListingIndex)
            return true, ItemTooltip
        end,
    },
    [SLOT_TYPE_REPAIR] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_PENDING_REPAIR] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_STACK_SPLIT] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_CRAFTING_COMPONENT] =
    {
        function(inventorySlot)
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                if SYSTEMS:IsShowing(ZO_ALCHEMY_SYSTEM_NAME) then
                    return true, nil -- no tooltip, but keep mouseover behavior
                end

                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                ItemTooltip:SetBagItem(bag, index)
                if SCENE_MANAGER:IsShowing("enchanting") then
                    ENCHANTING:OnMouseEnterCraftingComponent(bag, index)
                end
                return true, ItemTooltip
            end
        end
    },
    [SLOT_TYPE_PENDING_CRAFTING_COMPONENT] =
    {
        function(inventorySlot)
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                if SYSTEMS:IsShowing(ZO_ALCHEMY_SYSTEM_NAME) then
                    return true, nil -- no tooltip, but keep mouseover behavior
                end

                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                if bag and index then
                    ItemTooltip:SetBagItem(bag, index)
                    return true, ItemTooltip
                end
            end
        end
    },
    [SLOT_TYPE_SMITHING_BOOSTER] =
    {
        function(inventorySlot)
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                ItemTooltip:SetSmithingImprovementItem(inventorySlot.craftingType, inventorySlot.index)
                return true, ItemTooltip
            end
        end
    },
    [SLOT_TYPE_LIST_DIALOG_ITEM] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_DYEABLE_EQUIPMENT] =
    {
        function(inventorySlot)
            local wornBag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            local isEquipped = GetWornItemInfo(wornBag, index)

            if isEquipped then
                ItemTooltip:SetWornItem(index, wornBag)
                return true, ItemTooltip
            else
                SetTooltipText(InformationTooltip, zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_EQUIPSLOT", index)))
                return true, InformationTooltip
            end
        end
    },
    [SLOT_TYPE_GUILD_SPECIFIC_ITEM] =
    {
        function(inventorySlot)
            local guildSpecificItemIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
            ItemTooltip:SetGuildSpecificItem(guildSpecificItemIndex)
            return true, ItemTooltip
        end,
    },
    [SLOT_TYPE_COLLECTIONS_INVENTORY] =
    {
        function(inventorySlot)
            ItemTooltip:SetCollectible(inventorySlot.collectibleId, SHOW_COLLECTIBLE_NICKNAME, SHOW_COLLECTIBLE_PURCHASABLE_HINT, SHOW_COLLECTIBLE_BLOCK_REASON)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_CRAFT_BAG_ITEM] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_PENDING_RETRAIT_ITEM] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            if bag and index then
                ItemTooltip:SetBagItem(bag, index)
                return true, ItemTooltip
            end
            return false
        end
    },
}

local g_mouseoverCommand = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_RIGHT, { "UI_SHORTCUT_SECONDARY", "UI_SHORTCUT_TERTIARY", "UI_SHORTCUT_QUATERNARY" })
local g_updateCallback

-- defined local above
function UpdateMouseoverCommand(inventorySlot)
    -- we check if inventorySlot == nil here to ensure that slot keybinds are removed, even if we have switched from keyboard to gamepad.
    if not IsInGamepadPreferredMode() or inventorySlot == nil then
        g_mouseoverCommand:SetInventorySlot(inventorySlot)
    end

    if g_updateCallback then
        g_updateCallback(inventorySlot)
    end
end

function ZO_InventorySlot_SetUpdateCallback(callback)
    g_updateCallback = callback
end

function ZO_PlayShowAnimationOnComparisonTooltip(tooltip)
    if not tooltip:IsControlHidden() then
        if not tooltip.showAnimation then
            tooltip.showAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("DelayedTooltipFadeAnimation", tooltip)
        end
        tooltip:SetAlpha(0)
        tooltip.showAnimation:PlayFromStart()
    end
end

local NO_COMPARISON_TOOLTIPS_FOR_SLOT_TYPE =
{
    [SLOT_TYPE_PENDING_CHARGE] = true,
    [SLOT_TYPE_ENCHANTMENT] = true,
    [SLOT_TYPE_ENCHANTMENT_RESULT] = true,
    [SLOT_TYPE_REPAIR] = true,
    [SLOT_TYPE_PENDING_REPAIR] = true,
    [SLOT_TYPE_CRAFTING_COMPONENT] = true,
    [SLOT_TYPE_PENDING_CRAFTING_COMPONENT] = true,
    [SLOT_TYPE_SMITHING_MATERIAL] = true,
    [SLOT_TYPE_SMITHING_STYLE] = true,
    [SLOT_TYPE_SMITHING_TRAIT] = true,
    [SLOT_TYPE_SMITHING_BOOSTER] = true,
    [SLOT_TYPE_LIST_DIALOG_ITEM] = true,
    [SLOT_TYPE_PENDING_RETRAIT_ITEM] = true,
    [SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING] = true,
}

function ZO_InventorySlot_OnUpdate(control)
    if not control:IsHidden() and control.currencyControl then
        local currencyControls = { control.currencyControl }
        if type(control.currencyControl) == "table" then
            currencyControls = control.currencyControl
        end

        local cursorPositionX, cursorPositionY = GetUIMousePosition()
        for _, currencyControl in ipairs(currencyControls) do
            if not currencyControl:IsHidden() and currencyControl:IsPointInside(cursorPositionX, cursorPositionY) then
                ZO_CurrencyTemplate_OnMouseEnter(currencyControl)
            else
                ZO_CurrencyTemplate_OnMouseExit(currencyControl)
            end
        end
    end
end

function ZO_InventorySlot_OnMouseEnter(inventorySlot)
    local buttonPart, listPart, multiIconPart = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)

    if inventorySlot.slotControlType == "listSlot" then
        if ZO_InventorySlot_GetStackCount(buttonPart) > 0 or ZO_InventorySlot_GetStackCount(listPart) > 0 then
            ZO_InventorySlot_SetControlScaledUp(buttonPart, true)
            ZO_InventorySlot_SetControlScaledUp(multiIconPart, true)
        end
    end

    InitializeTooltip(ItemTooltip)
    InitializeTooltip(InformationTooltip)

    ZO_InventorySlot_SetHighlightHidden(listPart, false)

    if inventorySlot.currencyControl then
        inventorySlot:SetHandler("OnUpdate", function() ZO_InventorySlot_OnUpdate(inventorySlot) end)
    end

    -- ESO-747254: This function will be called recursively in RunHandlers. Since
    -- we only want the tooltip build once, we only call RunHandlers on the initial
    -- call and not on the recursive calls. InitializeTooltips nees to be called regardless
    -- recursion since the recursive process will also call MouseExit and clear the tooltip.
    if inventorySlot.isBuildingTooltip then
        return false
    end

    inventorySlot.isBuildingTooltip = true

    local success, tooltipUsed = RunHandlers(InventoryEnter, buttonPart)

    inventorySlot.isBuildingTooltip = nil

    if success then
        if tooltipUsed == ItemTooltip and not NO_COMPARISON_TOOLTIPS_FOR_SLOT_TYPE[ZO_InventorySlot_GetType(buttonPart)] then
            tooltipUsed:HideComparativeTooltips()
            tooltipUsed:ShowComparativeTooltips()
            ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip1)
            ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip2)
            
            if inventorySlot.dataEntry then
                local bagId = inventorySlot.dataEntry.data.bagId
                local slotId = inventorySlot.dataEntry.data.slotIndex
                ZO_CharacterWindowStats_ShowComparisonValues(bagId, slotId)
            end
        end

        ItemTooltip:SetHidden(tooltipUsed ~= ItemTooltip)
        InformationTooltip:SetHidden(tooltipUsed ~= InformationTooltip)

        if tooltipUsed then
            if buttonPart.customTooltipAnchor then
                buttonPart.customTooltipAnchor(tooltipUsed, buttonPart, ComparativeTooltip1, ComparativeTooltip2)
            else
                ZO_Tooltips_SetupDynamicTooltipAnchors(tooltipUsed, buttonPart.tooltipAnchor or buttonPart, ComparativeTooltip1, ComparativeTooltip2)
            end
        end

        UpdateMouseoverCommand(buttonPart)
        return true
    else
        ItemTooltip:SetHidden(true)
        InformationTooltip:SetHidden(true)
        return false
    end
end

--
-- When the slot that the user is currently moused over changes (e.g. you equipped an item...)
-- this handler will force update the tooltip again.
--
function ZO_InventorySlot_HandleInventoryUpdate(slotControl)
    if slotControl then 
        if ItemTooltip:GetOwner() == slotControl or InformationTooltip:GetOwner() == slotControl or WINDOW_MANAGER:GetMouseOverControl() == slotControl then
            ZO_InventorySlot_OnMouseEnter(slotControl)
        end
    end
end

local function OnActiveWeaponPairChanged(event, activeWeaponPair)
    if(not ComparativeTooltip1:IsHidden() or not ComparativeTooltip2:IsHidden()) then
        local tooltipAttachedTo = ComparativeTooltip1:GetOwner()
        if tooltipAttachedTo then
            local tooltipAttachedToOwner = tooltipAttachedTo:GetOwner()
            if tooltipAttachedToOwner then
                ZO_InventorySlot_OnMouseEnter(tooltipAttachedToOwner)
            end
        end
    end
end

local function RefreshMouseOverCommandIfActive()
    if g_mouseoverCommand and g_mouseoverCommand.inventorySlot then
        UpdateMouseoverCommand(g_mouseoverCommand.inventorySlot) 
    end
end

CALLBACK_MANAGER:RegisterCallback("WornSlotUpdate", ZO_InventorySlot_HandleInventoryUpdate)
CALLBACK_MANAGER:RegisterCallback("InventorySlotUpdate", ZO_InventorySlot_HandleInventoryUpdate)
EVENT_MANAGER:RegisterForEvent("InventorySlot", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnActiveWeaponPairChanged)
EVENT_MANAGER:RegisterForEvent("InventorySlot", EVENT_ACTION_SLOT_UPDATED, RefreshMouseOverCommandIfActive)
EVENT_MANAGER:RegisterForEvent("InventorySlot", EVENT_PLAYER_DEAD, RefreshMouseOverCommandIfActive)
EVENT_MANAGER:RegisterForEvent("InventorySlot", EVENT_PLAYER_REINCARNATED, RefreshMouseOverCommandIfActive)
EVENT_MANAGER:RegisterForEvent("InventorySlot", EVENT_VISUAL_LAYER_CHANGED, RefreshMouseOverCommandIfActive)

local function OnTradeSlotChanged(eventCode, who)
    if who == TRADE_ME then
        RefreshMouseOverCommandIfActive()
    end
end

EVENT_MANAGER:RegisterForEvent("InventorySlot", EVENT_TRADE_ITEM_ADDED, OnTradeSlotChanged)
EVENT_MANAGER:RegisterForEvent("InventorySlot", EVENT_TRADE_ITEM_REMOVED, OnTradeSlotChanged)
EVENT_MANAGER:RegisterForEvent("InventorySlot", EVENT_TRADE_ITEM_UPDATED, OnTradeSlotChanged)

EVENT_MANAGER:RegisterForEvent("InventorySlot", EVENT_CRAFT_STARTED, function() g_slotActions:Clear() end)

--
-- Mouse Exit
--

function ZO_PlayHideAnimationOnComparisonTooltip(tooltip)
    if not tooltip:IsControlHidden() then
        if tooltip.showAnimation then
            tooltip.showAnimation:PlayBackward()
        end
    end
end

function ZO_InventorySlot_OnMouseExit(inventorySlot)
    local buttonPart, listPart, multiIconPart = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
    ClearTooltip(ItemTooltip)
    ClearTooltip(InformationTooltip)
    ZO_PlayHideAnimationOnComparisonTooltip(ComparativeTooltip1)
    ZO_PlayHideAnimationOnComparisonTooltip(ComparativeTooltip2)

    ZO_CharacterWindowStats_HideComparisonValues()

    ZO_InventorySlot_SetControlScaledUp(buttonPart, false)
    ZO_InventorySlot_SetControlScaledUp(multiIconPart, false)

    UpdateMouseoverCommand(nil)

    ZO_InventorySlot_SetHighlightHidden(listPart, true)

    --Perform any additional MouseExit actions
    if ZO_Enchanting_IsSceneShowing() then
        ZO_Enchanting_GetVisibleEnchanting():OnMouseExitCraftingComponent()
    end

    if inventorySlot.currencyControl then
        inventorySlot:SetHandler("OnUpdate", nil)
    end
end

--
-- Drag Start
--

local InventoryDragStart =
{
    [SLOT_TYPE_ITEM] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            PickupInventoryItem(bag, index)
            return true
        end
    },    
    [SLOT_TYPE_BANK_ITEM] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            PickupInventoryItem(bag, index)
            return true
        end
    },
    [SLOT_TYPE_GUILD_BANK_ITEM] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            PickupInventoryItem(bag, index)
            return true
        end
    },
    [SLOT_TYPE_EQUIPMENT] =
    {
        function(inventorySlot)
            if not ZO_Character_IsReadOnly() then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                PickupEquippedItem(index, bag)
                return true
            end
        end
    },
    [SLOT_TYPE_MY_TRADE] =
    {
        function(inventorySlot)
            local index = ZO_Inventory_GetSlotIndex(inventorySlot)
            PickupTradeItem(index)
            return true
        end
    },
    [SLOT_TYPE_QUEST_ITEM] =
    {
        function(inventorySlot)
            TryPickupQuestItem(inventorySlot)
            return true
        end
    },
    [SLOT_TYPE_MAIL_QUEUED_ATTACHMENT] =
    {
        function(inventorySlot)
            -- Mail case shouldn't use ZO_Inventory_GetBagAndIndex, it's a good reason to actually wrap this stuff in a real object
            local bagId, slotIndex = inventorySlot.bagId, inventorySlot.slotIndex
            if bagId and slotIndex then
                RemoveQueuedItemAttachment(inventorySlot.slotIndex)
                PickupInventoryItem(bagId, slotIndex)
                return true
            end
        end
    },
    [SLOT_TYPE_STORE_BUY] =
    {
        function(inventorySlot)
            PickupStoreItem(inventorySlot.index)
            return true
        end
    },
    [SLOT_TYPE_STORE_BUYBACK] =
    {
        function(inventorySlot)
            PickupStoreBuybackItem(inventorySlot.index)
            return true
        end
    },
    [SLOT_TYPE_TRADING_HOUSE_POST_ITEM] =
    {
        function(inventorySlot)
            if(ZO_InventorySlot_GetStackCount(inventorySlot) > 0) then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                if IsItemStolen(bag, index) then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_STOLEN_ITEM_CANNOT_LIST_MESSAGE))
                    return false
                else
                    SetPendingItemPost(BAG_BACKPACK, 0, 0)
                    PickupInventoryItem(bag, index)
                    return true
                end
            end
        end
    },
    [SLOT_TYPE_REPAIR] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            PickupInventoryItem(bag, index)
            return true
        end
    },
    [SLOT_TYPE_CRAFTING_COMPONENT] =
    {
        function(inventorySlot)
            if not (ZO_CraftingUtils_IsPerformingCraftProcess() or IsItemAlreadySlottedToCraft(inventorySlot)) then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                PickupInventoryItem(bag, index)
                return true
            end
        end
    },
    [SLOT_TYPE_PENDING_CRAFTING_COMPONENT] =
    {
        function(inventorySlot)
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                if bag and index then
                    if SYSTEMS:IsShowing(ZO_ALCHEMY_SYSTEM_NAME) then
                        SYSTEMS:GetObject(ZO_ALCHEMY_SYSTEM_NAME):RemoveItemFromCraft(bag, index)
                    elseif ZO_Enchanting_IsSceneShowing() then
                        ZO_Enchanting_GetVisibleEnchanting():RemoveItemFromCraft(bag, index)
                    elseif ZO_Smithing_IsSceneShowing() then
                        ZO_Smithing_GetActiveObject():RemoveItemFromCraft(bag, index)
                   elseif ZO_FishFillet_IsSceneShowing() then
                        ZO_FishFillet_GetActiveObject():RemoveItemFromCraft(bag, index)
                    end
                    PickupInventoryItem(bag, index)
                end
                return true
            end
        end
    },
    [SLOT_TYPE_COLLECTIONS_INVENTORY] =
    {
        function(inventorySlot)
            PickupCollectible(inventorySlot.collectibleId)
            return true
        end
    },
    [SLOT_TYPE_CRAFT_BAG_ITEM] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            PickupInventoryItem(bag, index)
            return true
        end
    },
    [SLOT_TYPE_PENDING_RETRAIT_ITEM] =
    {
        function(inventorySlot)
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                if bag and index then
                    if ZO_RETRAIT_KEYBOARD then
                        local keyboardRetraitSceneName = SYSTEMS:GetKeyboardRootScene("retrait"):GetName()
                        if SCENE_MANAGER:IsShowing(keyboardRetraitSceneName) then
                            ZO_RETRAIT_KEYBOARD:RemoveItemFromCraft(bag, index)
                            PickupInventoryItem(bag, index)
                        end
                    end
                end
            end
            return true
        end
    },
}

function ZO_InventorySlot_OnDragStart(inventorySlot)
    if not IsInGamepadPreferredMode() then
        if IsUnitDead("player") then
            if not QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() then
                ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
                return
            end
        end

        if GetCursorContentType() == MOUSE_CONTENT_EMPTY then
            inventorySlot = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
            return RunHandlers(InventoryDragStart, inventorySlot)
        end
    end
end

--
-- Drag End
--

local InventoryReceiveDrag =
{
    [SLOT_TYPE_ITEM] =
    {
        function(inventorySlot)
            return PlaceInventoryItemInStorage(inventorySlot)
        end
    },
    [SLOT_TYPE_EQUIPMENT] =
    {
        function(inventorySlot)
            if not ZO_Character_IsReadOnly() then
                return PlaceInventoryItem(inventorySlot)
            end
        end
    },
    [SLOT_TYPE_BANK_ITEM] =
    {
        function(inventorySlot)
            return PlaceInventoryItemInStorage(inventorySlot)
        end
    },
    [SLOT_TYPE_GUILD_BANK_ITEM] =
    {
        function(inventorySlot)
            return PlaceInventoryItemInStorage(inventorySlot)
        end
    },
    [SLOT_TYPE_MY_TRADE] =
    {
        function(inventorySlot)
            PlaceInTradeWindow(inventorySlot.index)
            return true
        end
    },
    [SLOT_TYPE_MAIL_QUEUED_ATTACHMENT] =
    {
        function(inventorySlot)
            local attachmentIndex = inventorySlot.slotIndex
            if attachmentIndex then
                PlaceInAttachmentSlot(attachmentIndex)
            end
            return true
        end
    },
    [SLOT_TYPE_STORE_BUY] =
    {
        function(inventorySlot)
            PlaceInStoreWindow()
            return true
        end
    },
    [SLOT_TYPE_TRADING_HOUSE_POST_ITEM] =
    {
        function(inventorySlot)
            local bag, index = GetCursorBagId(), GetCursorSlotIndex()
            if index and bag == BAG_BACKPACK then
                PlaceInTradingHouse()
                return true
            end
        end
    },
    [SLOT_TYPE_CRAFTING_COMPONENT] =
    {
        function(inventorySlot)
            ClearCursor()
            return true
        end
    },
    [SLOT_TYPE_PENDING_CRAFTING_COMPONENT] =
    {
        function(inventorySlot)
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                local bagId, slotIndex = GetCursorBagId(), GetCursorSlotIndex()
                if bagId and slotIndex then
                    ClearCursor()
                    if SYSTEMS:IsShowing(ZO_ALCHEMY_SYSTEM_NAME) then
                        SYSTEMS:GetObject(ZO_ALCHEMY_SYSTEM_NAME):OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                    elseif SCENE_MANAGER:IsShowing("enchanting") then
                        ENCHANTING:OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                    elseif SCENE_MANAGER:IsShowing("provisioner") then
                        PROVISIONER.filletPanel:OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                    elseif ZO_Smithing_IsSceneShowing() then
                        ZO_Smithing_GetActiveObject():OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                    end
                    return true
                end
            end
        end
    },
    [SLOT_TYPE_MULTIPLE_PENDING_CRAFTING_COMPONENTS] =
    {
        function(inventorySlot)
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                local bagId, slotIndex = GetCursorBagId(), GetCursorSlotIndex()
                if bagId and slotIndex then
                    ClearCursor()
                    if SCENE_MANAGER:IsShowing("enchanting") then
                        ENCHANTING:OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                    elseif ZO_Smithing_IsSceneShowing() then
                        ZO_Smithing_GetActiveObject():OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                    end
                    return true
                end
            end
        end
    },
    [SLOT_TYPE_CRAFT_BAG_ITEM] =
    {
        function(inventorySlot)
            local bagId, slotIndex = GetCursorBagId(), GetCursorSlotIndex()
            if CanMoveToCraftBag(bagId, slotIndex) then
                ClearCursor()
                return TryMoveToCraftBag(bagId, slotIndex)
            end
        end
    },
    [SLOT_TYPE_PENDING_RETRAIT_ITEM] =
    {
        function(inventorySlot)
            if not ZO_CraftingUtils_IsPerformingCraftProcess() then
                local bagId, slotIndex = GetCursorBagId(), GetCursorSlotIndex()
                if bagId and slotIndex then
                    ClearCursor()
                    if ZO_RETRAIT_KEYBOARD then
                        local keyboardRetraitSceneName = SYSTEMS:GetKeyboardRootScene("retrait"):GetName()
                        if SCENE_MANAGER:IsShowing(keyboardRetraitSceneName) then
                            ZO_RETRAIT_KEYBOARD:OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                        end
                    end
                    return true
                end
            end
            return false
        end
    },
}

function ZO_InventorySlot_OnReceiveDrag(inventorySlot)
    if GetCursorContentType() ~= MOUSE_CONTENT_EMPTY then
        local inventorySlotButton = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
        RunHandlers(InventoryReceiveDrag, inventorySlotButton)
    end
end

function ZO_InventorySlot_RemoveMouseOverKeybinds()
    UpdateMouseoverCommand(nil)
end

function ZO_InventorySlot_WillItemBecomeBoundOnEquip(bagId, slotIndex)
    if GetItemBindType(bagId, slotIndex) == BIND_TYPE_ON_EQUIP or IsItemBoPAndTradeable(bagId, slotIndex) then
        return not IsItemBound(bagId, slotIndex)
    end
    return false
end

function ZO_InventorySlot_TraitInfo_OnMouseEnter(control)
    local _, listPart = ZO_InventorySlot_GetInventorySlotComponents(control:GetParent())
    ZO_InventorySlot_SetHighlightHidden(listPart, false)

    local slotData = control:GetParent().dataEntry.data
    local traitInformation = slotData.traitInformation

    if traitInformation and traitInformation ~= ITEM_TRAIT_INFORMATION_NONE then
        local itemTrait = slotData.itemTrait or GetItemTrait(slotData.bagId, slotData.slotIndex)
        local traitName = GetString("SI_ITEMTRAITTYPE", itemTrait)
        local traitInformationString = GetString("SI_ITEMTRAITINFORMATION", traitInformation)
        InitializeTooltip(InformationTooltip, control, TOPRIGHT, -10, 0, TOPLEFT)
        InformationTooltip:AddLine(zo_strformat(SI_INVENTORY_TRAIT_STATUS_TOOLTIP, traitName, ZO_SELECTED_TEXT:Colorize(traitInformationString)), "", ZO_NORMAL_TEXT:UnpackRGB())
        if traitInformation == ITEM_TRAIT_INFORMATION_RETRAITED then
            InformationTooltip:AddLine(GetString(SI_INVENTORY_TRAIT_STATUS_RETRAITED_NOT_RESEARCHABLE), "", ZO_NORMAL_TEXT:UnpackRGB())
        elseif traitInformation == ITEM_TRAIT_INFORMATION_RECONSTRUCTED then
            InformationTooltip:AddLine(GetString(SI_INVENTORY_TRAIT_STATUS_RECONSTRUCTED_NOT_RESEARCHABLE), "", ZO_NORMAL_TEXT:UnpackRGB())
        end
    end
end

function ZO_InventorySlot_TraitInfo_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    local _, listPart = ZO_InventorySlot_GetInventorySlotComponents(control:GetParent())
    ZO_InventorySlot_SetHighlightHidden(listPart, true)
end

function ZO_InventorySlot_SellInformation_OnMouseEnter(control)
    local _, listPart = ZO_InventorySlot_GetInventorySlotComponents(control:GetParent())
    ZO_InventorySlot_SetHighlightHidden(listPart, false)

    local slotData = control:GetParent().dataEntry.data
    if slotData.sellInformation ~= ITEM_SELL_INFORMATION_NONE then
        InitializeTooltip(InformationTooltip, control, TOPRIGHT, -10, 0, TOPLEFT)
        InformationTooltip:AddLine(GetString("SI_ITEMSELLINFORMATION", slotData.sellInformation), "", ZO_NORMAL_TEXT:UnpackRGB())
    end
end

function ZO_InventorySlot_SellInformation_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    local _, listPart = ZO_InventorySlot_GetInventorySlotComponents(control:GetParent())
    ZO_InventorySlot_SetHighlightHidden(listPart, true)
end

do
    local g_tooltipLines = {}

    function ZO_InventorySlot_Status_OnMouseEnter(control)
        local slotData = control:GetParent():GetParent().dataEntry.data

        ZO_ClearNumericallyIndexedTable(g_tooltipLines)

        if slotData.isPlayerLocked then
            table.insert(g_tooltipLines, GetString(SI_INVENTORY_PLAYER_LOCKED_ITEM_TOOLTIP))
        end
        if slotData.brandNew then
            table.insert(g_tooltipLines, GetString(SI_INVENTORY_NEW_ITEM_TOOLTIP))
        end
        if slotData.stolen then
            table.insert(g_tooltipLines, GetString(SI_INVENTORY_STOLEN_ITEM_TOOLTIP))
        end
        if slotData.isBoPTradeable then
            table.insert(g_tooltipLines, GetString(SI_INVENTORY_TRADE_BOP_ITEM_TOOLTIP))
        end
        if slotData.isGemmable then
            table.insert(g_tooltipLines, GetString(SI_INVENTORY_GEMMABLE_ITEM_TOOLTIP))
        end
        if slotData.bagId == BAG_WORN then
            table.insert(g_tooltipLines, GetString(SI_INVENTORY_EQUIPPED_ITEM_TOOLTIP))
        end
        if slotData.isInArmory then
            table.insert(g_tooltipLines, GetString(SI_INVENTORY_ARMORY_BUILD_ITEM_TOOLTIP))
        end

        if #g_tooltipLines > 0 then
            InitializeTooltip(InformationTooltip, control, TOPRIGHT, -10, 0, TOPLEFT)
            for _, lineText in ipairs(g_tooltipLines) do
                InformationTooltip:AddLine(lineText, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
            end
        end
    end
end