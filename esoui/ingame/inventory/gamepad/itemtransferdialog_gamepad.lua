local ItemTransferDialog_Gamepad = ZO_ItemTransferDialog_Base:Subclass()

function ItemTransferDialog_Gamepad:New(...)
    return ZO_ItemTransferDialog_Base.New(self, ...)
end

function ItemTransferDialog_Gamepad:Initialize()
    ZO_ItemTransferDialog_Base.Initialize(self)

    local setupFunc = function(dialog)
                        dialog:setupFunc()
                        -- hide the left icon as we only want to show the stack that's going to be transferred
                        dialog.icon1:SetHidden(true)
                        dialog.sliderValue1:SetHidden(true)
                      end

    local callbackFunc = function(dialog)
                            local quantity = ZO_GenericGamepadItemSliderDialogTemplate_GetSliderValue(dialog)
                            self:Transfer(quantity)
                        end

    ZO_Dialogs_RegisterCustomDialog("ITEM_TRANSFER_ADD_TO_CRAFT_BAG_GAMEPAD",
    {
        canQueue = true,
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.ITEM_SLIDER,
        },
        setup = setupFunc,
        title =
        {
            text = SI_PROMPT_TITLE_ADD_ITEMS_TO_CRAFT_BAG,
        },
        buttons =
        {
            {
                text =  SI_ITEM_ACTION_ADD_ITEMS_TO_CRAFT_BAG,
                callback =  callbackFunc,
            },
            {
                text = SI_DIALOG_CANCEL,
            }
        }
    })

    ZO_Dialogs_RegisterCustomDialog("ITEM_TRANSFER_REMOVE_FROM_CRAFT_BAG_GAMEPAD",
    {
        canQueue = true,
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.ITEM_SLIDER,
        },
        setup = setupFunc,
        title =
        {
            text = SI_PROMPT_TITLE_REMOVE_ITEMS_FROM_CRAFT_BAG,
        },
        buttons =
        {
            {
                text =  SI_ITEM_ACTION_REMOVE_ITEMS_FROM_CRAFT_BAG,
                callback =  callbackFunc,
            },
            {
                text = SI_DIALOG_CANCEL,
            }
        }
    })
end

function ItemTransferDialog_Gamepad:ShowDialog()
    local maxStack = self:GetTransferMaximum()
    local dialogData =
                {
                    sliderMin = 1,
                    sliderMax = maxStack,
                    sliderStartValue = maxStack,
                    bagId = self.bag,
                    slotIndex = self.slotIndex,
                }
    
    if self.targetBag == BAG_VIRTUAL then
        ZO_Dialogs_ShowGamepadDialog("ITEM_TRANSFER_ADD_TO_CRAFT_BAG_GAMEPAD", dialogData)
    else
        ZO_Dialogs_ShowGamepadDialog("ITEM_TRANSFER_REMOVE_FROM_CRAFT_BAG_GAMEPAD", dialogData)
    end
end

-------------------
-- Global functions
-------------------

function ZO_ItemTransferDialog_OnInitialize()
    local dialog = ItemTransferDialog_Gamepad:New()
    SYSTEMS:RegisterGamepadObject("ItemTransferDialog", dialog)
end

ZO_ItemTransferDialog_OnInitialize()