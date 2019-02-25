function ZO_ConfirmCollectibleEvolution_Keyboard_OnInitialized(control)
    local container = control:GetNamedChild("Container")
    local baseCollectibleTextureControl = container:GetNamedChild("BaseIcon")
    local evolvedCollectibleTextureControl = container:GetNamedChild("EvolvedIcon")

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_COLLECTIBLE_EVOLUTION_PROMPT_KEYBOARD",
    {
        customControl = control,
        setup = function(dialog)
            local data = dialog.data
            local baseCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(data.baseCollectibleId)
            local evolvedCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(data.evolvedCollectibleId)

            baseCollectibleTextureControl:SetTexture(baseCollectibleData:GetIcon())
            evolvedCollectibleTextureControl:SetTexture(evolvedCollectibleData:GetIcon())
        end,
        title =
        {
            text = SI_COLLECTIBLE_EVOLUTION_PROMPT_TITLE,
        },
        mainText = 
        {
            text = SI_COLLECTIBLE_EVOLUTION_PROMPT_CONFIRMATION_TEXT,
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                control = control:GetNamedChild("Confirm"),
                text = SI_DIALOG_YES,
                callback = function(dialog)
                    RespondToConfirmUseInventoryItemRequest(true)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                control = control:GetNamedChild("Cancel"),
                text = SI_DIALOG_NO,
                callback = function(dialog)
                    RespondToConfirmUseInventoryItemRequest(false)
                end,
            }
        },
        noChoiceCallback = function()
            RespondToConfirmUseInventoryItemRequest(false)
        end,
    })
end