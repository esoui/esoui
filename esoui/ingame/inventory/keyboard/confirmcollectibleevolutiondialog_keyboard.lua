local COLLECTIBLE_TEXTURE_SPACING = 5

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
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    dialog.data.acceptCallback()
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                control = control:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
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

function ZO_ConfirmAdvancedCombinationDialog_Keyboard_OnInitialized(control)
    local container = control:GetNamedChild("Container")
    local componentsContainer = container:GetNamedChild("ComponentsContainer")
    local unlocksContainer = container:GetNamedChild("UnlocksContainer")
    local arrowTexture = container:GetNamedChild("Arrow")

    local textureControlPool = ZO_ControlPool:New("ZO_CollectibleEvolutionTexture", control)

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_COLLECTIBLE_ADVANCED_COMBINATION_PROMPT_KEYBOARD",
    {
        customControl = control,
        setup = function(dialog)
            local data = dialog.data
            local combinationId = data.combinationId

            local numNonFragmentCollectibleComponents = 0
            local previousComponentTextureControl = nil

            local nonFragmentComponentCollectibleIds = { GetCombinationNonFragmentComponentCollectibleIds(combinationId) }
            for i, collectibleId in ipairs(nonFragmentComponentCollectibleIds) do
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                if collectibleData then
                    numNonFragmentCollectibleComponents = numNonFragmentCollectibleComponents + 1

                    local textureControl = textureControlPool:AcquireObject()
                    textureControl:SetParent(componentsContainer)
                    if previousComponentTextureControl then
                        textureControl:SetAnchor(TOP, previousComponentTextureControl, BOTTOM, 0, COLLECTIBLE_TEXTURE_SPACING)
                    else
                        textureControl:SetAnchor(TOPLEFT, componentsContainer)
                    end
                    textureControl:SetTexture(collectibleData:GetIcon())

                    previousComponentTextureControl = textureControl
                end
            end


            local numCollectibleUnlocks = GetCombinationNumUnlockedCollectibles(combinationId)
            local previousUnlockTextureControl = nil
            for i = 1, numCollectibleUnlocks do
                local collectibleId = GetCombinationUnlockedCollectibleId(combinationId, i)
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
                if collectibleData then
                    local textureControl = textureControlPool:AcquireObject()
                    textureControl:SetParent(unlocksContainer)
                    if previousUnlockTextureControl then
                        textureControl:SetAnchor(TOP, previousUnlockTextureControl, BOTTOM, 0, COLLECTIBLE_TEXTURE_SPACING)
                    else
                        textureControl:SetAnchor(TOPLEFT, unlocksContainer)
                    end
                    textureControl:SetTexture(collectibleData:GetIcon())

                    previousUnlockTextureControl = textureControl
                end
            end

            componentsContainer:ClearAnchors()
            unlocksContainer:ClearAnchors()
            arrowTexture:ClearAnchors()
            if numCollectibleUnlocks > numNonFragmentCollectibleComponents then
                unlocksContainer:SetAnchor(TOPLEFT, nil, TOP, 42, 0)
                arrowTexture:SetAnchor(RIGHT, unlocksContainer, LEFT, -10, 0)
                componentsContainer:SetAnchor(RIGHT, arrowTexture, LEFT, -10, 0)
            else
                componentsContainer:SetAnchor(TOPRIGHT, nil, TOP, -42, 0)
                arrowTexture:SetAnchor(LEFT, componentsContainer, RIGHT, 10, 0)
                unlocksContainer:SetAnchor(LEFT, arrowTexture, RIGHT, 10, 0)
            end
        end,
        finishedCallback = function(dialog)
            textureControlPool:ReleaseAllObjects()
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
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    dialog.data.acceptCallback()
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                control = control:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
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
