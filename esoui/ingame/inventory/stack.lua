function ZO_StackSplit_SplitItem(inventorySlotControl)
    local slot = PLAYER_INVENTORY:SlotForInventoryControl(inventorySlotControl)

    if(slot) then
        if(slot.locked) then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_ERROR_ITEM_LOCKED))
            return false
        end
        
        local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlotControl)
        local stackSize = GetSlotStackSize(bagId, slotIndex)
        if(stackSize <= 1 or not ZO_InventorySlot_IsSplittableType(inventorySlotControl)) then
            return false
        end

        if IsInGamepadPreferredMode() then
            local gamepadData =
                {
                    sliderMin = 1,
                    sliderMax = stackSize - 1,
                    sliderStartValue = zo_floor(stackSize / 2),
                    bagId = bagId,
                    slotIndex = slotIndex,
                    stackSize = stackSize,
                }
            ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_SPLIT_STACK_DIALOG, gamepadData)
        else
            ZO_Dialogs_ShowDialog("SPLIT_STACK", inventorySlotControl)
        end
        return true
    end
    
    return false
end

local function RefreshDestinations(stackControl)
    local stackLabel = GetControl(stackControl, "Destination1StackCount")
    stackLabel:SetText(stackControl.stackSize - stackControl.spinner:GetValue())
end

local function SetupStackSplit(stackControl, inventorySlotControl)
    local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlotControl)
    local stackSize = GetSlotStackSize(bagId, slotIndex)

    stackControl.stackSize = stackSize
    stackControl.slotControl = inventorySlotControl

    local itemIcon, _, _, _, _, _, _, quality = GetItemInfo(bagId, slotIndex)
    local itemName = GetItemName(bagId, slotIndex)
    local qualityColor = GetItemQualityColor(quality)
    GetControl(stackControl, "Prompt"):SetText(zo_strformat(SI_INVENTORY_SPLIT_STACK_PROMPT, qualityColor:Colorize(itemName)))

    local sourceSlot = GetControl(stackControl, "Source")
    local destinationSlot1 = GetControl(stackControl, "Destination1")
    local destinationSlot2 = GetControl(stackControl, "Destination2")
    ZO_ItemSlot_SetupSlot(sourceSlot, stackSize, itemIcon)
    ZO_ItemSlot_SetupSlot(destinationSlot1, 0, itemIcon)
    ZO_ItemSlot_SetupSlot(destinationSlot2, 0, itemIcon)

    ZO_Inventory_BindSlot(sourceSlot, SLOT_TYPE_STACK_SPLIT, slotIndex, bagId)
    ZO_Inventory_BindSlot(destinationSlot1, SLOT_TYPE_STACK_SPLIT, slotIndex, bagId)
    ZO_Inventory_BindSlot(destinationSlot2, SLOT_TYPE_STACK_SPLIT, slotIndex, bagId)

    stackControl.spinner:SetMinMax(1, stackSize - 1)
    stackControl.spinner:SetValue(zo_floor(stackSize / 2))
    RefreshDestinations(stackControl)
end

function ZO_Stack_Initialize(self)
    ZO_Dialogs_RegisterCustomDialog("SPLIT_STACK",   
    {
        customControl = self,
        setup = SetupStackSplit,
        title =
        {
            text = SI_INVENTORY_SPLIT_STACK_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(self, "Split"),
                text =      SI_INVENTORY_SPLIT_STACK,
                callback =  function(stackControl)
                                local bag, index = ZO_Inventory_GetBagAndIndex(stackControl.slotControl)
                                PickupInventoryItem(bag, index, stackControl.spinner:GetValue())

                                -- Auto-drop into whatever bag this came from
                                ZO_InventoryLandingArea_DropCursorInBag(bag)
                            end,
            },
        
            [2] =
            {
                control =   GetControl(self, "Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })

    local function HandleCursorPickup(eventId, cursorType)
        if(cursorType == MOUSE_CONTENT_INVENTORY_ITEM) then
            ZO_Dialogs_ReleaseAllDialogsOfName("STACK_SPLIT")
        end
    end

    local function OnSpinnerValueChanged()
        RefreshDestinations(self)
    end

    self.spinner = ZO_Spinner:New(GetControl(self, "Spinner"))
    self.spinner:RegisterCallback("OnValueChanged", OnSpinnerValueChanged)

    EVENT_MANAGER:RegisterForEvent("ZO_Stack", EVENT_CURSOR_PICKUP, HandleCursorPickup)
end
