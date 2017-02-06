local ItemTransferDialog_Keyboard = ZO_ItemTransferDialog_Base:Subclass()

function ItemTransferDialog_Keyboard:New(...)
    return ZO_ItemTransferDialog_Base.New(self, ...)
end

function ItemTransferDialog_Keyboard:Initialize(control)
    ZO_ItemTransferDialog_Base.Initialize(self)
    self.dialogControl = control

    local spinnerControl = control:GetNamedChild("Spinner")
    self.spinner = ZO_Spinner:New(spinnerControl, 1, function() return self:GetTransferMaximum() end)

    self.slotControl = control:GetNamedChild("Slot")
    self.iconControl = control:GetNamedChild("SlotIcon")
    self.quantityControl = control:GetNamedChild("SlotStackCount")

    local setupFunc = function(dialog, data)
                          self:Refresh()
                      end

    local callbackFunc = function(dialog)
                            local quantity = self:GetSpinnerValue()
                            self:Transfer(quantity)
                        end

    ZO_Dialogs_RegisterCustomDialog("ITEM_TRANSFER_ADD_TO_CRAFT_BAG_KEYBOARD",
    {
        canQueue = true,
        customControl = control,
        setup = setupFunc,
        title =
        {

            text = SI_PROMPT_TITLE_ADD_ITEMS_TO_CRAFT_BAG,
        },
        buttons =
        {
            {
                control = control:GetNamedChild("Transfer"),
                text =  SI_ITEM_ACTION_ADD_ITEMS_TO_CRAFT_BAG,
                callback = callbackFunc,
            },
            {
                control =   control:GetNamedChild("Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })

    ZO_Dialogs_RegisterCustomDialog("ITEM_TRANSFER_REMOVE_FROM_CRAFT_BAG_KEYBOARD",
    {
        customControl = control,
        setup = setupFunc,
        title =
        {
            text = SI_PROMPT_TITLE_REMOVE_ITEMS_FROM_CRAFT_BAG 
        },
        buttons =
        {
            {
                control = control:GetNamedChild("Transfer"),
                text =  SI_ITEM_ACTION_REMOVE_ITEMS_FROM_CRAFT_BAG,
                callback = callbackFunc,
            },
            {
                control =   control:GetNamedChild("Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })
end

function ItemTransferDialog_Keyboard:ShowDialog()
    local maxStack = self:GetTransferMaximum()
    self.spinner:SetValue(maxStack, true)

    if self.targetBag == BAG_VIRTUAL then
        ZO_Dialogs_ShowDialog("ITEM_TRANSFER_ADD_TO_CRAFT_BAG_KEYBOARD")
    else
        ZO_Dialogs_ShowDialog("ITEM_TRANSFER_REMOVE_FROM_CRAFT_BAG_KEYBOARD")
    end
    
end

function ItemTransferDialog_Keyboard:Refresh()
    local icon, stackCount, sellPrice, meetsUsageRequirement, locked = GetItemInfo(self.bag, self.slotIndex)
    ZO_Inventory_BindSlot(self.slotControl, SLOT_TYPE_STACK_SPLIT, self.slotIndex, self.bag)

    self.iconControl:SetTexture(icon)

    local USE_LOWERCASE_NUMBER_SUFFIXES = false
    self.quantityControl:SetText(ZO_AbbreviateNumber(stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
    self.quantityControl:SetHidden(stackCount <= 1)

    ZO_ItemSlot_SetupUsableAndLockedColor(self.slotControl, meetsUsageRequirement, locked)
end

function ItemTransferDialog_Keyboard:GetSpinnerValue()
    return self.spinner:GetValue()
end

-------------------
-- Global functions
-------------------

function ZO_ItemTransferDialog_OpenTransferDialog(bag, slotIndex, targetBag)
    ITEM_TRANSFER_DIALOG:Show(bag, slotIndex, targetBag)
end

function ZO_ItemTransferDialog_OnInitialize(control)
    local dialog = ItemTransferDialog_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("ItemTransferDialog", dialog)
end
