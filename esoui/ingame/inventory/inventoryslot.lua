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

local BUTTON_LEFT = 1
local BUTTON_RIGHT = 2

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

function ZO_ItemSlot_SetupSlotBase(slotControl, stackCount, iconFile, meetsUsageRequirement, locked)
    slotControl:SetHidden(false)

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
        stackCountLabel:SetText(ZO_AbbreviateNumber(stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
    else
        stackCountLabel:SetText("")
    end
end

function ZO_ItemSlot_SetupSlot(slotControl, stackCount, iconFile, meetsUsageRequirement, locked)
    ZO_ItemSlot_SetupSlotBase(slotControl, stackCount, iconFile, meetsUsageRequirement, locked)

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

function ZO_Inventory_SlotReset(slotControl)
    slotControl:SetHidden(true)
    slotControl:ClearAnchors()

    slotControl.slotIndex = nil
    slotControl.bagIndex = nil
    slotControl.bagId = nil
    slotControl.slotType = nil
    slotControl.questIndex = nil
    slotControl.toolIndex = nil
    slotControl.stepIndex = nil

    slotControl:SetNormalTexture(regularBorder)
    slotControl:SetPressedTexture(regularBorder)

    GetControl(slotControl,"Icon"):SetColor(1,1,1,1)
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
    ZO_ItemSlot_SetupTextUsableAndLockedColor(GetControl(slotControl, "Name"), meetsUsageRequirement, locked)
    ZO_ItemSlot_SetupTextUsableAndLockedColor(GetControl(slotControl, "SellPrice"), meetsUsageRequirement, locked)
    ZO_ItemSlot_SetupUsableAndLockedColor(GetControl(slotControl, "Button"), meetsUsageRequirement, locked)
end

function ZO_PlayerInventorySlot_SetupSlot(slotControl, stackCount, iconFile, meetsUsageRequirement, locked)
    ZO_Inventory_SetupSlot(GetControl(slotControl, "Button"), stackCount, iconFile, meetsUsageRequirement, locked)
    ZO_PlayerInventorySlot_SetupUsableAndLockedColor(slotControl, meetsUsageRequirement, locked)
end

--
-- Control Utils
--

local function GetInventorySlotComponents(inventorySlot)
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

local function SetListHighlightHidden(listPart, hidden)
    if(listPart) then
        local highlight = listPart:GetNamedChild("Highlight")
        if(highlight and (highlight:GetType() == CT_TEXTURE)) then
            if not highlight.animation then
                highlight.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
            end
            if hidden then
                highlight.animation:PlayBackward()
            else
                highlight.animation:PlayForward()
            end
        end
    end
end

function ZO_InventorySlot_OnPoolReset(inventorySlot)
    local buttonPart, listPart = GetInventorySlotComponents(inventorySlot)
    if listPart then
        local highlight = listPart:GetNamedChild("Highlight")
        if highlight and highlight.animation then
            highlight.animation:PlayFromEnd(highlight.animation:GetDuration())
        end
    end
    if buttonPart then
        if buttonPart and buttonPart.animation then
            buttonPart.animation:PlayInstantlyToStart()
        end
    end

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
        [1] =   function(inventorySlot)
                    return ItemUpdateCooldown(inventorySlot)
                end,
    },
    [SLOT_TYPE_QUEST_ITEM] =
    {
        [1] =   function(inventorySlot)
                    return QuestItemUpdateCooldown(inventorySlot)
                end,
    },
    [SLOT_TYPE_COLLECTIONS_INVENTORY] = 
    {
        [1] =   function(inventorySlot)
                    return CollectibleItemUpdateCooldown(inventorySlot)
                end,
    }
}

function ZO_InventorySlot_UpdateCooldowns(inventorySlot)
    local inventorySlot = GetInventorySlotComponents(inventorySlot)
    RunHandlers(InventoryUpdateCooldown, inventorySlot)
end

function ZO_GamepadItemSlot_UpdateCooldowns(inventorySlot, remaining, duration)
    UpdateCooldown(inventorySlot, remaining, duration)
end


--
-- Actions that can be performed on InventorySlots (via various clicks and context menus)
--

local function IsSendingMail()
    if MAIL_SEND and not MAIL_SEND:IsHidden() then
        return true
    elseif MAIL_MANAGER_GAMEPAD and MAIL_MANAGER_GAMEPAD:GetSend():IsAttachingItems() then
        return true
    end
    return false
end

local function CanUseSecondaryActionOnSlot(inventorySlot)
    return not QUICKSLOT_WINDOW:AreQuickSlotsShowing() 
           and not (TRADING_HOUSE and TRADING_HOUSE:IsAtTradingHouse())
           and not (ZO_Store_IsShopping and ZO_Store_IsShopping())
           and not IsSendingMail() 
           and not (TRADE_WINDOW and TRADE_WINDOW:IsTrading())
           and not PLAYER_INVENTORY:IsBanking()
           and not PLAYER_INVENTORY:IsGuildBanking()
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

local function TryUseQuestItem(inventorySlot, buttonId)
    if inventorySlot then
        if inventorySlot.toolIndex then
            UseQuestTool(inventorySlot.questIndex, inventorySlot.toolIndex)
        elseif inventorySlot.conditionIndex then
            UseQuestItem(inventorySlot.questIndex, inventorySlot.stepIndex, inventorySlot.conditionIndex)
        end
    end
end

function ZO_InventorySlot_CanSplitItemStack(inventorySlot)
    if(PLAYER_INVENTORY:DoesBagHaveEmptySlot(inventorySlot.bagId)) then
        return ZO_InventorySlot_GetStackCount(inventorySlot) > 1
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

                local icon, _, _, _, _, _, _, quality = GetItemInfo(bag, index)

                local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
                local nameControl = GetControl(rowControl, "Name")
                nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bag, index)))
                nameControl:SetColor(r, g, b, 1)

                local inventorySlot = GetControl(rowControl, "Button")
                ZO_Inventory_BindSlot(inventorySlot, SLOT_TYPE_LIST_DIALOG_ITEM, index, bag)
                ZO_Inventory_SetupSlot(inventorySlot, slotInfo.stack, icon)

                GetControl(rowControl, "Selected"):SetHidden(g_listDialog:GetSelectedItem() ~= slotInfo)

                if g_listDialog:GetSelectedItem() then
                    g_listDialog:SetFirstButtonEnabled(true)
                end
            end
            g_listDialog = ZO_ListDialog:New("ZO_ListDialogInventorySlot", 52, SetupItemRow)
        end

        g_listDialog:SetFirstButtonEnabled(false)
        return g_listDialog
    end
end

local function CanEnchantItem(inventorySlot)
    if(CanUseSecondaryActionOnSlot(inventorySlot)) then
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

local function CanConvertItemStyle(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if(CanUseSecondaryActionOnSlot(inventorySlot)) and not IsItemPlayerLocked(bag, index) then
        return CanConvertItemStyleToImperial(bag, index)
    end
end

local function IsSlotLocked(inventorySlot)
    local slot = PLAYER_INVENTORY:SlotForInventoryControl(inventorySlot)

    if slot then
        return slot.locked
    end
end

local function TryConvertItemStyle(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local itemName = GetItemLink(bag, index)
    if(not IsSlotLocked(inventorySlot)) then
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_CONVERT_IMPERIAL_STYLE", { bagId = bag, slotIndex = index }, {mainTextParams = { itemName }})
    else
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_ERROR_ITEM_LOCKED))
    end
end

local function CanChargeItem(inventorySlot)
    if(CanUseSecondaryActionOnSlot(inventorySlot)) then
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
    if(CanUseSecondaryActionOnSlot(inventorySlot)) then
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

    if(cursorType ~= MOUSE_CONTENT_EMPTY) then
        local destBag, destSlot = ZO_Inventory_GetBagAndIndex(inventorySlot)
        PlaceInInventory(destBag, destSlot)
        return true
    end
end

function TryPlaceInventoryItemInEmptySlot(targetBag)
    local emptySlotIndex = FindFirstEmptySlotInBag(targetBag)
    if emptySlotIndex ~= nil then
        PlaceInInventory(targetBag, emptySlotIndex)
    else
        local errorStringId = (targetBag == BAG_BACKPACK) and SI_INVENTORY_ERROR_INVENTORY_FULL or SI_INVENTORY_ERROR_BANK_FULL
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, errorStringId)
    end
end

local function TryGuildBankDepositItem(sourceBag, sourceSlot)
    local guildId = GetSelectedGuildBankId()
    if(guildId) then
        if(not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_DEPOSIT)) then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_NO_DEPOSIT_PERMISSION)
            return
        end

        if(not DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_BANK_DEPOSIT)) then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_GUILD_TOO_SMALL)
            return
        end

        if(IsItemStolen(sourceBag, sourceSlot)) then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_NO_DEPOSIT_STOLEN_ITEM)
            return
        end

        if(GetNumBagFreeSlots(BAG_GUILDBANK) == 0) then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_NO_SPACE_LEFT)
            return
        end

        TransferToGuildBank(sourceBag, sourceSlot)
    end
    ClearCursor()
end

local function TryGuildBankWithdrawItem(sourceSlotId)
    local guildId = GetSelectedGuildBankId()
    if(guildId) then
        if(not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_BANK_WITHDRAW)) then
            ZO_AlertEvent(EVENT_GUILD_BANK_TRANSFER_ERROR, GUILD_BANK_NO_WITHDRAW_PERMISSION)
            return
        end

        if(not DoesBagHaveSpaceFor(BAG_BACKPACK, sourceBag, sourceSlot)) then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
            return
        end

        TransferFromGuildBank(sourceSlotId)
    end
    ClearCursor()
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

    if(targetType == SLOT_TYPE_ITEM or targetType == SLOT_TYPE_BANK_ITEM) then
        if(sourceType == MOUSE_CONTENT_EQUIPPED_ITEM) then
            TryPlaceInventoryItemInEmptySlot(targetBag)
            return true
        elseif(sourceType == MOUSE_CONTENT_INVENTORY_ITEM) then
            -- if the items can stack, move the source to the clicked slot, otherwise try to move to an empty slot.
            -- never swap!
            if(sourceBag == BAG_GUILDBANK) then
                TryGuildBankWithdrawItem(sourceSlotIndex)
                return true
            else
                if(sourceItemId == targetItemId) then
                    PlaceInInventory(targetBag, targetSlotIndex)
                    return true
                else
                    if(sourceBag == targetBag) then
                        ClearCursor()
                    else
                        TryPlaceInventoryItemInEmptySlot(targetBag)
                    end
                    return true
                end
            end
        elseif(sourceType == MOUSE_CONTENT_QUEST_ITEM) then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_INVENTORY_ERROR_NO_QUEST_ITEMS_IN_BANK))
            return false
        end
    elseif(targetType == SLOT_TYPE_GUILD_BANK_ITEM) then
        if(sourceType == MOUSE_CONTENT_QUEST_ITEM) then
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
    if(PLAYER_INVENTORY:IsBanking()) then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if(bag == BAG_BANK) then
            --Withdraw
            if(DoesBagHaveSpaceFor(BAG_BACKPACK, bag, index)) then
                PickupInventoryItem(bag, index)
                PlaceInTransfer()
            else
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
            end
        else
            --Deposit
            if(IsItemStolen(bag, index)) then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_STOLEN_ITEM_CANNOT_DEPOSIT_MESSAGE)
            elseif(not DoesBagHaveSpaceFor(BAG_BANK, bag, index)) then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_BANK_FULL)
            else
                PickupInventoryItem(bag, index)
                PlaceInTransfer()
            end
        end
        return true
    end
end

local function TryMoveToInventory(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if DoesBagHaveSpaceFor(BAG_BACKPACK, bag, index) then
        local transferDialog = SYSTEMS:GetObject("ItemTransferDialog")
        transferDialog:StartTransfer(bag, index, BAG_BACKPACK)
        return true
    else
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
    end
end

local function TryMoveToCraftBag(inventorySlot)
    local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
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

-- If called on an item inventory slot, returns the index of the attachment slot that's holding it, or nil if it's not attached.
local function GetQueuedItemAttachmentSlotIndex(inventorySlot)
    local bag, attachmentIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if (bag) then
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
    if(IsSendingMail()) then
        for i = 1, MAIL_MAX_ATTACHED_ITEMS do
            local queuedFromBag = GetQueuedItemAttachmentInfo(i)

            if(queuedFromBag == 0) then
                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                local result = QueueItemAttachment(bag, index, i)

                if(result == MAIL_ATTACHMENT_RESULT_ALREADY_ATTACHED) then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_ALREADY_ATTACHED))
                elseif(result == MAIL_ATTACHMENT_RESULT_BOUND) then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_BOUND))
                elseif(result == MAIL_ATTACHMENT_RESULT_ITEM_NOT_FOUND) then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_ITEM_NOT_FOUND))
                elseif(result == MAIL_ATTACHMENT_RESULT_LOCKED) then
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MAIL_LOCKED))
                elseif(result == MAIL_ATTACHMENT_RESULT_STOLEN) then
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
    if(CanSellItem()) then
        itemData.stackCount = ZO_InventorySlot_GetStackCount(inventorySlot)
        if(itemData.stackCount > 0) then
            itemData.bag, itemData.slot = ZO_Inventory_GetBagAndIndex(inventorySlot)

            if (IsItemStolen(itemData.bag, itemData.slot)) then
                local totalSells, sellsUsed = GetFenceSellTransactionInfo()
                if sellsUsed == totalSells then
                    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, GetString("SI_STOREFAILURE", STORE_FAILURE_AT_FENCE_LIMIT))
                    return
                end
            end

            itemData.itemName = GetItemName(itemData.bag, itemData.slot)
            itemData.quality = select(8, GetItemInfo(itemData.bag, itemData.slot))

            if SCENE_MANAGER:IsShowing("fence_keyboard") and itemData.quality >= ITEM_QUALITY_ARCANE then
                ZO_Dialogs_ShowDialog("CANT_BUYBACK_FROM_FENCE", itemData)
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

    if(CanLaunderItem()) then
        local stackCount = ZO_InventorySlot_GetStackCount(inventorySlot)
        if(stackCount > 0) then
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
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if bag ~= BAG_WORN then
        local equipType = select(6, GetItemInfo(bag, index))
        return equipType ~= EQUIP_TYPE_INVALID
    end

    return false
end

local function TryEquipItem(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local function DoEquip() 
        local equipSucceeds, possibleError = IsEquipable(bag, index)
        if(equipSucceeds) then
            ClearCursor()
            EquipItem(bag, index)
            return true
        end

        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, possibleError)    
    end
    
    if IsItemBoPAndTradeable(bag, index) then
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_EQUIP_TRADE_BOP", {onAcceptCallback = DoEquip}, {mainTextParams = {GetItemName(bag, index)}})
    else
        DoEquip()
    end
end

local function CanUnequipItem(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if bag == BAG_WORN then
        local _, stackCount = GetItemInfo(bag, slot)
        return stackCount > 0
    end
    return false
end

local function TryUnequipItem(inventorySlot)
    local equipSlot = ZO_Inventory_GetSlotIndex(inventorySlot)
    UnequipItem(equipSlot)
end

local function TryPickupQuestItem(inventorySlot)
    if(inventorySlot.questIndex) then
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
    [SLOT_TYPE_CRAFT_BAG_ITEM] = true,
}

function ZO_InventorySlot_CanDestroyItem(inventorySlot)
    local slotType = ZO_InventorySlot_GetType(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if(destroyableItems[slotType]) and not IsItemPlayerLocked(bag, index) then
        if(slotType == SLOT_TYPE_EQUIPMENT) then
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

local function CanUseItem(inventorySlot)
    local hasCooldown = inventorySlot.IsOnCooldown and inventorySlot:IsOnCooldown()
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local usable, onlyFromActionSlot = IsItemUsable(bag, index)
    local canInteractWithItem = CanInteractWithItem(bag, index)
    local isDyeStamp = GetItemType(bag, index) == ITEMTYPE_DYE_STAMP -- dye stamps are "usable" but we do not want the player to use them directly from their inventory
    return usable and not onlyFromActionSlot and canInteractWithItem and not hasCooldown and not isDyeStamp
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

-- TODO: This function is currently unused but when character worn slots are converted back to inventorySlots and integrated into the backpack window the call
-- to PlaceInEquipSlot will need to happen.
local function PlaceEquippedItem(inventorySlot)
    if(GetCursorContentType() ~= MOUSE_CONTENT_EMPTY) then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        PlaceInEquipSlot(index)
        return true
    end
end

local function TryBuyMultiple(inventorySlot)
    ZO_BuyMultiple_OpenBuyMultiple(inventorySlot.index)
end

local function BuyItemFromStore(inventorySlot)
    local storeItemId = inventorySlot.index
    BuyStoreItem(storeItemId, 1)

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

    if SYSTEMS:IsShowing("alchemy") then
        return SYSTEMS:GetObject("alchemy"):CanItemBeAddedToCraft(bag, slot)
    elseif ZO_Enchanting_IsSceneShowing() then
        return ZO_Enchanting_GetVisibleEnchanting():CanItemBeAddedToCraft(bag, slot)
    elseif ZO_Smithing_IsSceneShowing() then
        return ZO_Smithing_GetActiveObject():CanItemBeAddedToCraft(bag, slot)
    end

    return false
end

local function IsItemAlreadySlottedToCraft(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if SYSTEMS:IsShowing("alchemy") then
        return SYSTEMS:GetObject("alchemy"):IsItemAlreadySlottedToCraft(bag, slot)
    elseif ZO_Enchanting_IsSceneShowing() then
        return ZO_Enchanting_GetVisibleEnchanting():IsItemAlreadySlottedToCraft(bag, slot)
    elseif ZO_Smithing_IsSceneShowing() then
        return ZO_Smithing_GetActiveObject():IsItemAlreadySlottedToCraft(bag, slot)
    end
    return false
end

local function TryAddItemToCraft(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if SYSTEMS:IsShowing("alchemy") then
        SYSTEMS:GetObject("alchemy"):AddItemToCraft(bag, slot)
    elseif ZO_Enchanting_IsSceneShowing() then
        ZO_Enchanting_GetVisibleEnchanting():AddItemToCraft(bag, slot)
    elseif ZO_Smithing_IsSceneShowing() then
        ZO_Smithing_GetActiveObject():AddItemToCraft(bag, slot)
    end
    UpdateMouseoverCommand(inventorySlot)
end

local function TryRemoveItemFromCraft(inventorySlot)
    local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if SYSTEMS:IsShowing("alchemy") then
        SYSTEMS:GetObject("alchemy"):RemoveItemFromCraft(bag, slot)
    elseif ZO_Enchanting_IsSceneShowing() then
       ZO_Enchanting_GetVisibleEnchanting():RemoveItemFromCraft(bag, slot)
    elseif ZO_Smithing_IsSceneShowing() then
        ZO_Smithing_GetActiveObject():RemoveItemFromCraft(bag, slot)
    end
    UpdateMouseoverCommand(inventorySlot)
end

local function IsCraftingSlotType(slotType)
    return slotType == SLOT_TYPE_CRAFTING_COMPONENT
        or slotType == SLOT_TYPE_PENDING_CRAFTING_COMPONENT
        or slotType == SLOT_TYPE_SMITHING_MATERIAL
        or slotType == SLOT_TYPE_SMITHING_STYLE
        or slotType == SLOT_TYPE_SMITHING_TRAIT
        or slotType == SLOT_TYPE_SMITHING_BOOSTER
end

local function ShouldHandleClick(inventorySlot)
    local slotType = ZO_InventorySlot_GetType(inventorySlot)

    -- TODO: Really just needs to check if a slot has something in it and isn't locked.
    -- Needs to support all types.  Also, bag/bank slots always have something because
    -- inventory is a list...only occupied rows are shown.

    if slotType == SLOT_TYPE_ITEM or slotType == SLOT_TYPE_BANK_ITEM then
        -- TODO: Check locked state here...locked slots do nothing?
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if(PLAYER_INVENTORY:IsSlotOccupied(bag, index)) then
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
    if(action) then
        action(inventorySlot, ...)
    end
end

local function DefaultUseItemFunction(inventorySlot, slotActions)
    if(CanUseItem(inventorySlot)) then
        -- TODO: Localization will involve determining the correct name of the action that will be performed on the item (eat, drink, open, etc...)
        slotActions:AddSlotAction(SI_ITEM_ACTION_USE, function() TryUseItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
    end
end

local useActions =
{
    [SLOT_TYPE_QUEST_ITEM] =    function(inventorySlot, slotActions)
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
                                                if category == COLLECTIBLE_CATEGORY_TYPE_ASSISTANT or category == COLLECTIBLE_CATEGORY_TYPE_VANITY_PET then
                                                    textEnum = SI_COLLECTIBLE_ACTION_DISMISS
                                                else
                                                    textEnum = SI_COLLECTIBLE_ACTION_PUT_AWAY
                                                end
                                            else
                                                textEnum = SI_COLLECTIBLE_ACTION_SET_ACTIVE
                                            end
                                            slotActions:AddSlotAction(textEnum, function() UseCollectible(inventorySlot.collectibleId) end, "primary", nil, {visibleWhenDead = false})
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
    if link then
        if actionName == "link_to_chat" and IsChatSystemAvailableForCurrentPlatform() then
            local linkFn = function()
                ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))

                if IsInGamepadPreferredMode() then
                    CHAT_SYSTEM:SubmitTextEntry()
                end
            end

            slotActions:AddSlotAction(SI_ITEM_ACTION_LINK_TO_CHAT, linkFn, "secondary", nil, {visibleWhenDead = true})
        elseif actionName == "report_item" then
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
    [SLOT_TYPE_SMITHING_STYLE] =                function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetSmithingStyleItemLink, inventorySlot.styleIndex)) end,
    [SLOT_TYPE_SMITHING_TRAIT] =                function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, inventorySlot.traitType ~= ITEM_TRAIT_TYPE_NONE and ZO_LinkHandler_CreateChatLink(GetSmithingTraitItemLink, inventorySlot.traitIndex)) end,
    [SLOT_TYPE_SMITHING_BOOSTER] =              function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetSmithingBoosterLink, inventorySlot)) end,
    [SLOT_TYPE_DYEABLE_EQUIPMENT] =             function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT] =     function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetTradingHouseSearchResultLink, inventorySlot)) end,
    [SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING] =    function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetTradingHouseListingLink, inventorySlot)) end,
    [SLOT_TYPE_GUILD_SPECIFIC_ITEM] =           function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetGuildSpecificLink, inventorySlot)) end,
    [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM] =        function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
    [SLOT_TYPE_COLLECTIONS_INVENTORY] =         function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetInventoryCollectibleLink, inventorySlot)) end,
    [SLOT_TYPE_CRAFT_BAG_ITEM] =                function(inventorySlot, slotActions, actionName) LinkHelper(slotActions, actionName, ZO_LinkHandler_CreateChatLink(GetBagItemLink, inventorySlot)) end,
}

---- Quickslot Action Handlers ----
local QUICKSLOT_SHARED_OPTIONS = {visibleWhenDead = true}

local function AddQuickslotRemoveAction(slotActions, slot)
    slotActions:AddSlotAction(SI_ITEM_ACTION_REMOVE_FROM_QUICKSLOT, function() ClearSlot(slot) end, "primary", nil, QUICKSLOT_SHARED_OPTIONS)
end

local function AddQuickslotAddAction(callback, slotActions)
    slotActions:AddSlotAction(SI_ITEM_ACTION_MAP_TO_QUICKSLOT, callback, "primary", nil, QUICKSLOT_SHARED_OPTIONS)
end

local function DefaultQuickslotAction(inventorySlot, slotActions)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    if(QUICKSLOT_WINDOW:AreQuickSlotsShowing()) then
        local currentSlot = GetItemCurrentActionBarSlot(bag, index)
        if currentSlot then
            AddQuickslotRemoveAction(slotActions, currentSlot)
        else
            local validSlot = GetFirstFreeValidSlotForItem(bag, index)
            if validSlot then
                AddQuickslotAddAction(function() SelectSlotItem(bag, index, validSlot) end, slotActions)
            end
        end
    end
end

local function CollectionsQuickslotAction(slot, slotActions)
    if(QUICKSLOT_WINDOW:AreQuickSlotsShowing()) then
        local collectibleId = slot.collectibleId
        local currentSlot = GetCollectibleCurrentActionBarSlot(collectibleId)
        if currentSlot then
            AddQuickslotRemoveAction(slotActions, currentSlot)
        else
            local validSlot = GetFirstFreeValidSlotForCollectible(collectibleId)
            if validSlot then
                AddQuickslotAddAction(function() SelectSlotCollectible(collectibleId, validSlot) end, slotActions)
            end
        end
    end
end

local quickslotActions =
{
    [SLOT_TYPE_ITEM] = DefaultQuickslotAction,
    [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM] = DefaultQuickslotAction,
    [SLOT_TYPE_COLLECTIONS_INVENTORY] = CollectionsQuickslotAction,
}

---- Rename Action Handlers ----
local renameActions = 
{
    [SLOT_TYPE_COLLECTIONS_INVENTORY] = function(slot, slotActions)
                                                local collectibleId = slot.collectibleId
                                                if IsCollectibleRenameable(collectibleId) then
                                                    slotActions:AddSlotAction(SI_COLLECTIBLE_ACTION_RENAME, function() ZO_Dialogs_ShowDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE", { collectibleId = collectibleId }) end, "keybind1")
                                                end
                                            end
}

local actionHandlers =
{
    ["use"] =   function(inventorySlot, slotActions)
                    DiscoverSlotActionFromType(useActions, inventorySlot, slotActions)
                end,

    ["mail_attach"] =   function(inventorySlot, slotActions)
                            if IsSendingMail() and not IsItemAlreadyAttachedToMail(inventorySlot) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_MAIL_ATTACH, function() TryMailItem(inventorySlot) end, "primary")
                            end
                        end,

    ["mail_detach"] =   function(inventorySlot, slotActions)
                            if IsSendingMail() and IsItemAlreadyAttachedToMail(inventorySlot) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_MAIL_DETACH, function() RemoveQueuedAttachment(inventorySlot) end, "primary")
                            end
                        end,

    ["bank_deposit"]=   function(inventorySlot, slotActions)
                            if(PLAYER_INVENTORY:IsBanking()) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_BANK_DEPOSIT, function() TryBankItem(inventorySlot) end, "primary")
                            end
                        end,

    ["bank_withdraw"] = function(inventorySlot, slotActions)
                            if(PLAYER_INVENTORY:IsBanking()) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_BANK_WITHDRAW, function() TryBankItem(inventorySlot) end, "primary")
                            end
                        end,

    ["guild_bank_deposit"] =    function(inventorySlot, slotActions)
                                    if(GetSelectedGuildBankId()) then
                                        slotActions:AddSlotAction(SI_ITEM_ACTION_BANK_DEPOSIT,  function()
                                                                                                    local bag, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
                                                                                                    TryGuildBankDepositItem(bag, slotIndex)
                                                                                                end, "primary")
                                    end
                                end,

    ["guild_bank_withdraw"] =   function(inventorySlot, slotActions)
                                    if(GetSelectedGuildBankId()) then
                                        slotActions:AddSlotAction(SI_ITEM_ACTION_BANK_WITHDRAW, function()
                                                                                                    local bag, slotId = ZO_Inventory_GetBagAndIndex(inventorySlot)
                                                                                                    TryGuildBankWithdrawItem(slotId)
                                                                                                end, "primary")
                                    end
                                end,

    ["trade_add"] = function(inventorySlot, slotActions)
                        if TRADE_WINDOW:IsTrading() and CanTradeItem(inventorySlot) and not IsItemAlreadyBeingTraded(inventorySlot) then
                            slotActions:AddSlotAction(SI_ITEM_ACTION_TRADE_ADD, function() TryTradeItem(inventorySlot) end, "primary")
                        end
                    end,

    ["trade_remove"] =  function(inventorySlot, slotActions)
                            if TRADE_WINDOW:IsTrading() and IsItemAlreadyBeingTraded(inventorySlot) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_TRADE_REMOVE, function() TryRemoveFromTrade(inventorySlot) end, "primary")
                            end
                        end,

    ["sell"] =  function(inventorySlot, slotActions)
                    if(CanSellItem(inventorySlot)) then
                        slotActions:AddSlotAction(SI_ITEM_ACTION_SELL, function() TrySellItem(inventorySlot) end, "primary")
                    end
                end,

    ["launder"] =  function(inventorySlot, slotActions)
                    if(CanLaunderItem()) then
                        slotActions:AddSlotAction(SI_ITEM_ACTION_LAUNDER, function() TryLaunderItem(inventorySlot) end, "primary")
                    end
                end,

    ["buy"] =   function(inventorySlot, slotActions)
                    if not inventorySlot.locked then
                        slotActions:AddSlotAction(SI_ITEM_ACTION_BUY, function() BuyItemFromStore(inventorySlot) end, "primary")
                    end
                end,

    ["buy_multiple"] =  function(inventorySlot, slotActions)
                            if CanBuyMultiple(inventorySlot) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_BUY_MULTIPLE, function() TryBuyMultiple(inventorySlot) end, "secondary")
                            end
                        end,

    ["buyback"] =   function(inventorySlot, slotActions)
                        slotActions:AddSlotAction(SI_ITEM_ACTION_BUYBACK, function() BuybackItem(inventorySlot.index) end, "primary")
                    end,

    ["equip"] = function(inventorySlot, slotActions)
                    if(CanEquipItem(inventorySlot)) then
                        slotActions:AddSlotAction(SI_ITEM_ACTION_EQUIP, function() TryEquipItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
                    end
                end,

    ["gamepad_equip"] = function(inventorySlot, slotActions)
                            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                            if GAMEPAD_INVENTORY_ROOT_SCENE:IsShowing() and IsEquipable(bag, index) and CanEquipItem(inventorySlot) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_EQUIP, function() GAMEPAD_INVENTORY:TryEquipItem(inventorySlot) end, "primary")
                            end
                        end,

    ["unequip"] =   function(inventorySlot, slotActions)
                        if(CanUnequipItem(inventorySlot)) then
                            slotActions:AddSlotAction(SI_ITEM_ACTION_UNEQUIP, function() TryUnequipItem(inventorySlot) end, "primary")
                        end
                    end,

    ["take_loot"] = function(inventorySlot, slotActions)
                        slotActions:AddSlotAction(SI_ITEM_ACTION_LOOT_TAKE, function() TakeLoot(inventorySlot) end, "primary", function() return false end)
                    end,

    ["destroy"] =   function(inventorySlot, slotActions)
                        if(ZO_InventorySlot_CanDestroyItem(inventorySlot)) then
                            slotActions:AddSlotAction(SI_ITEM_ACTION_DESTROY, function() ZO_InventorySlot_InitiateDestroyItem(inventorySlot) end, "secondary")
                        end
                    end,

    ["split_stack"] =   function(inventorySlot, slotActions)
                            if(ZO_InventorySlot_CanSplitItemStack(inventorySlot)) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_SPLIT_STACK, function() ZO_InventorySlot_TrySplitStack(inventorySlot) end, "secondary")
                            end
                        end,

    ["enchant"] =   function(inventorySlot, slotActions)
                            if(CanEnchantItem(inventorySlot)) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_ENCHANT, function() TryEnchantItem(inventorySlot) end, "keybind1")
                            end
                        end,

    ["charge"] =   function(inventorySlot, slotActions)
                            if(CanChargeItem(inventorySlot)) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_CHARGE, function() TryChargingItem(inventorySlot) end, "keybind2")
                            end
                        end,

    ["kit_repair"] =   function(inventorySlot, slotActions)
                            if(CanKitRepairItem(inventorySlot)) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_REPAIR, function() TryKitRepairItem(inventorySlot) end, "keybind2")
                            end
                        end,
    ["link_to_chat"] =  function(inventorySlot, slotActions)
                            if ZO_InventorySlot_GetStackCount(inventorySlot) > 0 or ZO_ItemSlot_GetAlwaysShowStackCount(inventorySlot) then
                                DiscoverSlotActionFromType(linkHelperActions, inventorySlot, slotActions, "link_to_chat")
                            end
                        end,
    ["report_item"] =  function(inventorySlot, slotActions)
                            if ZO_InventorySlot_GetStackCount(inventorySlot) > 0 or ZO_ItemSlot_GetAlwaysShowStackCount(inventorySlot) then
                                DiscoverSlotActionFromType(linkHelperActions, inventorySlot, slotActions, "report_item")
                            end
                        end,
    ["mark_as_locked"] =  function(inventorySlot, slotActions)
                            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                            if not IsSlotLocked(inventorySlot) and CanItemBePlayerLocked(bag, index) and not IsItemPlayerLocked(bag, index) and not QUICKSLOT_WINDOW:AreQuickSlotsShowing() then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_MARK_AS_LOCKED, function() MarkAsPlayerLockedHelper(bag, index, true) end, "secondary")
                            end
                        end,

    ["unmark_as_locked"] =  function(inventorySlot, slotActions)
                                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                                if not IsSlotLocked(inventorySlot) and CanItemBePlayerLocked(bag, index) and IsItemPlayerLocked(bag, index) and not QUICKSLOT_WINDOW:AreQuickSlotsShowing() then
                                    slotActions:AddSlotAction(SI_ITEM_ACTION_UNMARK_AS_LOCKED, function() MarkAsPlayerLockedHelper(bag, index, false) end, "secondary")
                                end
                            end,

    ["mark_as_junk"] =  function(inventorySlot, slotActions)
                            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                            if(not IsSlotLocked(inventorySlot) and CanItemBeMarkedAsJunk(bag, index) and not IsItemJunk(bag, index) and not QUICKSLOT_WINDOW:AreQuickSlotsShowing()) then
                                slotActions:AddSlotAction(SI_ITEM_ACTION_MARK_AS_JUNK, function() MarkAsJunkHelper(bag, index, true) end, "secondary")
                            end
                        end,

    ["unmark_as_junk"] =    function(inventorySlot, slotActions)
                                local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
                                if(not IsSlotLocked(inventorySlot) and CanItemBeMarkedAsJunk(bag, index) and IsItemJunk(bag, index) and not QUICKSLOT_WINDOW:AreQuickSlotsShowing()) then
                                    slotActions:AddSlotAction(SI_ITEM_ACTION_UNMARK_AS_JUNK, function() MarkAsJunkHelper(bag, index, false) end, "secondary")
                                end
                            end,

    ["quickslot"] =     function(inventorySlot, slotActions)
                            DiscoverSlotActionFromType(quickslotActions, inventorySlot, slotActions)
                        end,

    ["trading_house_post"] = function(inventorySlot, slotActions)
                                if(TRADING_HOUSE:IsAtTradingHouse() and not IsItemAlreadyBeingPosted(inventorySlot)) then
                                    slotActions:AddSlotAction(SI_TRADING_HOUSE_ADD_ITEM_TO_LISTING, function() TryInitiatingItemPost(inventorySlot) end, "primary")
                                end
                            end,

    ["trading_house_remove_pending_post"] = function(inventorySlot, slotActions)
                                                if(TRADING_HOUSE:IsAtTradingHouse() and IsItemAlreadyBeingPosted(inventorySlot)) then
                                                    slotActions:AddSlotAction(SI_TRADING_HOUSE_REMOVE_PENDING_POST, function() ClearItemPost(inventorySlot) end, "primary")
                                                end
                                            end,

    ["trading_house_buy_item"] =    function(inventorySlot, slotActions)
                                        if(TRADING_HOUSE:CanBuyItem(inventorySlot)) then
                                            slotActions:AddSlotAction(SI_TRADING_HOUSE_BUY_ITEM, function() TryBuyingTradingHouseItem(inventorySlot) end, "primary")
                                        end
                                    end,

    ["trading_house_cancel_listing"] =  function(inventorySlot, slotActions)
                                            slotActions:AddSlotAction(SI_TRADING_HOUSE_CANCEL_LISTING, function() TryCancellingTradingHouseListing(inventorySlot) end, "secondary")
                                        end,

    ["convert_to_imperial_style"] =     function(inventorySlot, slotActions)
                                           if(CanConvertItemStyle(inventorySlot)) then
                                                slotActions:AddSlotAction(SI_ITEM_ACTION_CONVERT_TO_IMPERIAL_STYLE, function() TryConvertItemStyle(inventorySlot) end, "secondary")
                                            end
                                        end,

    ["vendor_repair"] =     function(inventorySlot, slotActions)
                                slotActions:AddSlotAction(SI_ITEM_ACTION_REPAIR, function() TryVendorRepairItem(inventorySlot) end, "primary")
                            end,
                                
    ["add_to_craft"] =      function(inventorySlot, slotActions)
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

    ["buy_guild_specific_item"] = function(inventorySlot, slotActions)
                                if(TRADING_HOUSE:CanBuyItem(inventorySlot)) then
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
                                local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
                                if HasCraftBagAccess() and CanItemBeVirtual(bag, slot) and not IsItemStolen(bag, slot) then
                                    slotActions:AddSlotAction(SI_ITEM_ACTION_ADD_ITEMS_TO_CRAFT_BAG, function() TryMoveToCraftBag(inventorySlot) end, "secondary")
                                end
                            end,
    ["preview_dye_stamp"] = function(inventorySlot, slotActions)
                                local bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot)
                                if GetItemType(bag, slot) == ITEMTYPE_DYE_STAMP and IsCharacterPreviewingAvailable() then
                                    slotActions:AddSlotAction(SI_ITEM_ACTION_PREVIEW_DYE_STAMP, function() TryPreviewDyeStamp(inventorySlot) end, "primary")
                                end
                            end,
}

local NON_INTERACTABLE_ITEM_ACTIONS = { "link_to_chat", "report_item" }

-- Order the possible action types in priority order, actions are marked as primary/secondary in the functions above
-- The order of the rest of the secondary actions in the table determines the order they appear on the context menu
local potentialActionsForSlotType =
{
    [SLOT_TYPE_QUEST_ITEM] =                    { "use", "link_to_chat" },
    [SLOT_TYPE_ITEM] =                          { "quickslot", "mail_attach", "mail_detach", "trade_add", "trade_remove", "trading_house_post", "trading_house_remove_pending_post", "bank_deposit", "guild_bank_deposit", "sell", "launder", "equip", "use", "preview_dye_stamp", "split_stack", "enchant", "charge", "mark_as_locked", "unmark_as_locked", "kit_repair", "move_to_craft_bag", "link_to_chat", "mark_as_junk", "unmark_as_junk", "convert_to_imperial_style", "destroy", "report_item" },
    [SLOT_TYPE_EQUIPMENT] =                     { "unequip", "enchant", "charge", "mark_as_locked", "unmark_as_locked", "kit_repair", "link_to_chat", "convert_to_imperial_style", "destroy", "report_item" },
    [SLOT_TYPE_MY_TRADE] =                      { "trade_remove", "link_to_chat", "report_item" },
    [SLOT_TYPE_THEIR_TRADE] =                   NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_STORE_BUY] =                     { "buy", "buy_multiple", "link_to_chat", "report_item" },
    [SLOT_TYPE_STORE_BUYBACK] =                 { "buyback", "link_to_chat", "report_item" },
    [SLOT_TYPE_BUY_MULTIPLE] =                  NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_BANK_ITEM] =                     { "bank_withdraw", "split_stack", "link_to_chat", "mark_as_locked", "unmark_as_locked", "mark_as_junk", "unmark_as_junk", "report_item" },
    [SLOT_TYPE_GUILD_BANK_ITEM] =               { "guild_bank_withdraw", "link_to_chat", "report_item" },
    [SLOT_TYPE_MAIL_QUEUED_ATTACHMENT] =        { "mail_detach", "link_to_chat", "report_item" },
    [SLOT_TYPE_MAIL_ATTACHMENT] =               NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_LOOT] =                          { "take_loot", "link_to_chat", "report_item" },
    [SLOT_TYPE_ACHIEVEMENT_REWARD] =            NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_TRADING_HOUSE_POST_ITEM] =       { "trading_house_remove_pending_post", "link_to_chat", "report_item" },
    [SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT] =     { "trading_house_buy_item", "link_to_chat" },
    [SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING] =    { "trading_house_cancel_listing", "link_to_chat" },
    [SLOT_TYPE_REPAIR] =                        { "vendor_repair", "link_to_chat", "destroy", "report_item" },
    [SLOT_TYPE_PENDING_REPAIR] =                NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_CRAFTING_COMPONENT] =            { "add_to_craft", "remove_from_craft", "mark_as_locked", "link_to_chat", "report_item" },
    [SLOT_TYPE_PENDING_CRAFTING_COMPONENT] =    { "remove_from_craft", "link_to_chat", "report_item" },
    [SLOT_TYPE_SMITHING_MATERIAL] =             NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_SMITHING_STYLE] =                NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_SMITHING_TRAIT] =                NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_SMITHING_BOOSTER] =              NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_DYEABLE_EQUIPMENT] =             NON_INTERACTABLE_ITEM_ACTIONS,
    [SLOT_TYPE_GUILD_SPECIFIC_ITEM] =           { "buy_guild_specific_item", "link_to_chat" },
    [SLOT_TYPE_GAMEPAD_INVENTORY_ITEM] =        { "quickslot", "mail_attach", "mail_detach", "bank_deposit", "guild_bank_deposit", "gamepad_equip", "unequip", "use", "preview_dye_stamp", "split_stack", "enchant", "charge", "mark_as_locked", "unmark_as_locked", "kit_repair", "move_to_craft_bag", "link_to_chat", "convert_to_imperial_style", "destroy", "report_item" },
    [SLOT_TYPE_COLLECTIONS_INVENTORY] =         { "quickslot", "use", "rename", "link_to_chat" },
    [SLOT_TYPE_CRAFT_BAG_ITEM] =                { "move_to_inventory", "use", "link_to_chat", "report_item" },
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
    inventorySlot = GetInventorySlotComponents(inventorySlot)
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
        for i=1, #slotFilterData do
            if slotFilterData[i] == itemFilterType then
                hasFilterType = true
                break
            end
        end
    end

    return hasFilterType
end

function ZO_InventorySlot_OnSlotClicked(inventorySlot, button)
    inventorySlot = GetInventorySlotComponents(inventorySlot)
    if(button == BUTTON_LEFT) then
        -- Left clicks are only used as drops at the moment, use the receive drag handlers
        ZO_InventorySlot_OnReceiveDrag(inventorySlot)
    elseif(button == BUTTON_RIGHT) then
        -- Right clicks only open the context menu
        if(ShouldHandleClick(inventorySlot)) then
            ZO_InventorySlot_ShowContextMenu(inventorySlot)
        end
    end
end

--
-- Mouse Over
--
local SHOW_COLLECTIBLE_NICKNAME, SHOW_COLLECTIBLE_HINT, SHOW_COLLECTIBLE_BLOCK_REASON = true, true, true

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
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_BANK_ITEM] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_GUILD_BANK_ITEM] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            ItemTooltip:SetBagItem(bag, index)
            return true, ItemTooltip
        end
    },
    [SLOT_TYPE_EQUIPMENT] =
    {
        function(inventorySlot)
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            local _, isEquipped = GetEquippedItemInfo(index)

            if isEquipped then
                ItemTooltip:SetWornItem(index)
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

            if entry and not entry.currencyType then
                ItemTooltip:SetLootItem(entry.lootId)
                return true, ItemTooltip
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
                if SYSTEMS:IsShowing("alchemy") then
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
                if SYSTEMS:IsShowing("alchemy") then
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
            local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
            local _, isEquipped = GetEquippedItemInfo(index)

            if isEquipped then
                ItemTooltip:SetWornItem(index)
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
            ItemTooltip:SetCollectible(inventorySlot.collectibleId, SHOW_COLLECTIBLE_NICKNAME, SHOW_COLLECTIBLE_HINT, SHOW_COLLECTIBLE_BLOCK_REASON)
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
}

local g_mouseoverCommand
local g_updateCallback

-- defined local above
function UpdateMouseoverCommand(inventorySlot)
    if not IsInGamepadPreferredMode() then
        if(not g_mouseoverCommand) then
            g_mouseoverCommand = ZO_ItemSlotActionsController:New(KEYBIND_STRIP_ALIGN_RIGHT, { "UI_SHORTCUT_SECONDARY", "UI_SHORTCUT_TERTIARY", })
        end

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

local NoComparisionTooltip =
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
}

function ZO_InventorySlot_OnMouseEnter(inventorySlot)
    local buttonPart, listPart, multiIconPart = GetInventorySlotComponents(inventorySlot)

    if inventorySlot.slotControlType == "listSlot" then
        if((ZO_InventorySlot_GetStackCount(buttonPart) > 0) or (ZO_InventorySlot_GetStackCount(listPart) > 0)) then
            if not buttonPart.animation then
                buttonPart.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IconSlotMouseOverAnimation", buttonPart)
            end

            buttonPart.animation:PlayForward()

            if multiIconPart then
                if not multiIconPart.animation then
                    multiIconPart.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IconSlotMouseOverAnimation", multiIconPart)
                end

                multiIconPart.animation:PlayForward()
            end
        end
    end

    InitializeTooltip(ItemTooltip)
    InitializeTooltip(InformationTooltip)

    SetListHighlightHidden(listPart, false)

    local success, tooltipUsed = RunHandlers(InventoryEnter, buttonPart)
    if success then
        if tooltipUsed == ItemTooltip and not NoComparisionTooltip[ZO_InventorySlot_GetType(buttonPart)] then
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
    local buttonPart, listPart, multiIconPart = GetInventorySlotComponents(inventorySlot)
    ClearTooltip(ItemTooltip)
    ClearTooltip(InformationTooltip)
    ZO_PlayHideAnimationOnComparisonTooltip(ComparativeTooltip1)
    ZO_PlayHideAnimationOnComparisonTooltip(ComparativeTooltip2)

    ZO_CharacterWindowStats_HideComparisonValues()

    if buttonPart.animation then
        buttonPart.animation:PlayBackward()
    end

    if multiIconPart and multiIconPart.animation then
        multiIconPart.animation:PlayBackward()
    end

    UpdateMouseoverCommand(nil)

    SetListHighlightHidden(listPart, true)

    --Perform any additional MouseExit actions
    if ZO_Enchanting_IsSceneShowing() then
        ZO_Enchanting_GetVisibleEnchanting():OnMouseExitCraftingComponent()
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
        function(inventorySlot, button)
            if not ZO_Character_IsReadOnly() then
                local index = ZO_Inventory_GetSlotIndex(inventorySlot)
                PickupEquippedItem(index)
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
                    if SYSTEMS:IsShowing("alchemy") then
                        SYSTEMS:GetObject("alchemy"):RemoveItemFromCraft(bag, index)
                    elseif ZO_Enchanting_IsSceneShowing() then
                        ZO_Enchanting_GetVisibleEnchanting():RemoveItemFromCraft(bag, index)
                    elseif ZO_Smithing_IsSceneShowing() then
                        ZO_Smithing_GetActiveObject():RemoveItemFromCraft(bag, index)
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
}

function ZO_InventorySlot_OnDragStart(inventorySlot)
    if IsUnitDead("player") then
        if not QUICKSLOT_WINDOW:AreQuickSlotsShowing() then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
            return
        end
    end

    if(GetCursorContentType() == MOUSE_CONTENT_EMPTY) then
        inventorySlot = GetInventorySlotComponents(inventorySlot)
        return RunHandlers(InventoryDragStart, inventorySlot)
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
            if(index and bag == BAG_BACKPACK) then
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
                    if SYSTEMS:IsShowing("alchemy") then
                        SYSTEMS:GetObject("alchemy"):OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                    elseif SCENE_MANAGER:IsShowing("enchanting") then
                        ENCHANTING:OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                    elseif ZO_Smithing_IsSceneShowing() then
                        ZO_Smithing_GetActiveObject():OnItemReceiveDrag(inventorySlot, bagId, slotIndex)
                    end
                    return true
                end
            end
        end
    },
}

function ZO_InventorySlot_OnReceiveDrag(inventorySlot)
    if(GetCursorContentType() ~= MOUSE_CONTENT_EMPTY) then
        local inventorySlot = GetInventorySlotComponents(inventorySlot)
        RunHandlers(InventoryReceiveDrag, inventorySlot)
    end
end

function ZO_InventorySlot_RemoveMouseOverKeybinds()
    UpdateMouseoverCommand(nil)
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

        if #g_tooltipLines > 0 then
            InitializeTooltip(InformationTooltip, control, TOPRIGHT, -10, 0, TOPLEFT)
            for _, lineText in ipairs(g_tooltipLines) do
                InformationTooltip:AddLine(lineText, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
            end
        end
    end
end