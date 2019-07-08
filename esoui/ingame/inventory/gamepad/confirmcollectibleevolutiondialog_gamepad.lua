function ZO_ConfirmCollectibleEvolution_Gamepad_OnInitialized(control)
    ZO_GenericGamepadDialog_OnInitialized(control)

    local container = control:GetNamedChild("Container")
    local baseCollectibleTextureControl = container:GetNamedChild("BaseIcon")
    local evolvedCollectibleTextureControl = container:GetNamedChild("EvolvedIcon")

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_COLLECTIBLE_EVOLUTION_PROMPT_GAMEPAD",
    {
        customControl = control,
        setup = function(dialog)
            local data = dialog.data
            local baseCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(data.baseCollectibleId)
            local evolvedCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(data.evolvedCollectibleId)

            baseCollectibleTextureControl:SetTexture(baseCollectibleData:GetIcon())
            evolvedCollectibleTextureControl:SetTexture(evolvedCollectibleData:GetIcon())

            dialog:setupFunc()
        end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
        },
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
                text = SI_DIALOG_YES,
                callback = function(dialog)
                    dialog.data.acceptCallback()
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_NO,
                callback = function(dialog)
                    dialog.data.declineCallback()
                end,
            }
        },
        noChoiceCallback = function(dialog)
            dialog.data.declineCallback()
        end,
    })
end