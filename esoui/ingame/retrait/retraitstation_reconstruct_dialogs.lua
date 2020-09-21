-- Keyboard Dialogs

function ZO_ConfirmItemReconstructionDialog_Keyboard_OnInitialized(control)
    local function SetupCostLineItem(control, icon, name, quantity)
        local nameLabel = control:GetNamedChild("NameLabel")
        nameLabel:SetText(name)

        local iconTexture = control:GetNamedChild("IconTexture")
        iconTexture:SetTexture(icon)

        local quantityLabel = iconTexture:GetNamedChild("QuantityLabel")
        quantityLabel:SetText(quantity)

        control:SetHidden(false)
    end

    local function SetupDialog(dialog, itemSetPieceData)
        local currencyOptions, materialCosts = itemSetPieceData:GetCostInfo()

        -- Item description

        local itemTexture = dialog:GetNamedChild("ItemTexture")
        itemTexture:SetTexture(itemSetPieceData:GetIcon())

        local itemLabel = dialog:GetNamedChild("ItemLabel")
        itemLabel:SetText(itemSetPieceData:GetItemLink())

        -- Currency cost

        local currencyOption = currencyOptions[1]
        local costContainer = dialog:GetNamedChild("CostContainer")
        local lineItemContainer = costContainer:GetNamedChild("LineItemContainer")
        local currencyCostLineItem = lineItemContainer:GetNamedChild("CurrencyCostLineItem")
        SetupCostLineItem(currencyCostLineItem, currencyOption.currencyIcon, currencyOption.currencyName, currencyOption.currencyRequired)

        -- Material cost

        for upgradeIndex = 1, GetNumSmithingImprovementItems() do
            local costLineItem = lineItemContainer:GetNamedChild(string.format("CostLineItem%d", upgradeIndex))
            local materialCost = materialCosts[upgradeIndex]
            if materialCost then
                SetupCostLineItem(costLineItem, materialCost.reagentIcon, materialCost.reagentItemLink, materialCost.reagentsRequired)
                costLineItem:SetHidden(false)
            else
                costLineItem:SetHidden(true)
            end
        end
    end

    -- Dialog registration

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_ITEM_RECONSTRUCTION",
    {
        customControl = control,
        setup = SetupDialog,
        title =
        {
            text = SI_RETRAIT_STATION_CONFIRM_ITEM_RECONSTRUCTION_TITLE,
        },
        buttons =
        {
            -- Confirm Button
            {
                control = control:GetNamedChild("Confirm"),
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_RETRAIT_STATION_RECONSTRUCT_ACTION),
                callback = function(dialog)
                    ZO_RECONSTRUCT_KEYBOARD:RequestReconstruction()
                end,
            },
            -- Cancel Button
            {
                control = control:GetNamedChild("Cancel"),
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            },
        },
    })
end

-- Gamepad Dialogs

function ZO_ConfirmItemReconstruction_Gamepad_OnInitialized(control)
    ZO_GenericGamepadDialog_OnInitialized(control)

    local container = control:GetNamedChild("ContainerScrollChild")
    local summaryDescriptionLabel = container:GetNamedChild("SummaryDescriptionLabel")
    local itemName = control:GetNamedChild("ItemLabel")
    local itemIcon = control:GetNamedChild("ItemIcon")

    local costLinePool = ZO_ControlPool:New("ZO_GamepadDisplayEntryTemplateLowercase34", container)
    local function SetupCostLineControl(costLineControl)
        costLineControl.nameLabel = costLineControl:GetNamedChild("Label")
        -- Order matters:
        costLineControl.iconTexture = costLineControl:GetNamedChild("Icon")
        costLineControl.stackCountLabel = costLineControl.iconTexture:GetNamedChild("StackCount")
    end
    costLinePool:SetCustomFactoryBehavior(SetupCostLineControl)

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_CONFIRM_ITEM_RECONSTRUCTION",
    {
        canQueue = true,
        customControl = control,
        setup = function(dialog)
            local data = dialog.data
            local itemSetPieceData = data.itemSetPieceData
            itemName:SetText(itemSetPieceData:GetItemLink())
            itemIcon:SetTexture(itemSetPieceData:GetIcon())

            costLinePool:ReleaseAllObjects()
            local previousControl
            local currencyCosts, materialCosts = itemSetPieceData:GetCostInfo()
            local currencyCost = currencyCosts[1]
            if currencyCost then
                local costLine = costLinePool:AcquireObject()
                costLine.stackCountLabel:SetText(currencyCost.currencyRequired)
                costLine.iconTexture:SetTexture(currencyCost.currencyIcon)
                costLine.nameLabel:SetText(currencyCost.currencyName)
                costLine:ClearAnchors()
                costLine:SetAnchor(TOPLEFT, summaryDescriptionLabel, BOTTOMLEFT, 0, 20)
                previousControl = costLine
            end

            for index, materialCost in ipairs(materialCosts) do
                local costLine = costLinePool:AcquireObject()
                costLine.stackCountLabel:SetText(materialCost.reagentsRequired)
                costLine.iconTexture:SetTexture(materialCost.reagentIcon)
                costLine.nameLabel:SetText(materialCost.reagentItemLink)
                costLine:ClearAnchors()
                if previousControl then
                    costLine:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT)
                else
                    costLine:SetAnchor(TOPLEFT, summaryDescriptionLabel, BOTTOMLEFT, 0, 20)
                end
                previousControl = costLine
            end

            local NO_ENTRY_LIMIT = nil
            dialog:setupFunc(NO_ENTRY_LIMIT, data)
        end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
        },
        title =
        {
            text = SI_RETRAIT_STATION_CONFIRM_ITEM_RECONSTRUCTION_HEADER,
        },
        mainText = 
        {
            text = "",
        },
        buttons =
        {
            -- Reconstruct Button
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_RETRAIT_STATION_RECONSTRUCT_ACTION,
                callback = function(dialog)
                    ZO_RETRAIT_STATION_RECONSTRUCT_GAMEPAD:RequestReconstruction()
                end,
            },
            -- Back
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end