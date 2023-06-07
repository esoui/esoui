local ZO_ItemSetCollectionsManager = ZO_CallbackObject:Subclass()

function ZO_ItemSetCollectionsManager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_ItemSetCollectionsManager:Initialize()
    self:InitializeOptionsDialog()
end

-- Dialog cannot be created until the managers exists, so it can't be added in InGameDialogs.lua
function ZO_ItemSetCollectionsManager:InitializeOptionsDialog()
    local function BuildFilterTypesDropdownData(equipmentFilterTypes)
        local dropdownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
        for _, equipmentFilterType in ipairs(equipmentFilterTypes) do
            local newEntry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_EQUIPMENTFILTERTYPE", equipmentFilterType))
            newEntry.equipmentFilterType = equipmentFilterType
            dropdownData:AddItem(newEntry)
        end
        return dropdownData
    end

    local apparelFilterTypesData = BuildFilterTypesDropdownData(ZO_ItemSetCollectionsDataManager.GetApparelFilterTypes())
    local weaponFilterTypesData = BuildFilterTypesDropdownData(ZO_ItemSetCollectionsDataManager.GetWeaponFilterTypes())

    local function CreateEquipmentFilterTypesDropdownEntry(noSelectionText, multiSelectionFormatter, dropdownData)
        return
        {
            template = "ZO_GamepadMultiSelectionDropdownItem",

            templateData = 
            {
                setup = function(control, data, selected)
                    local dropdown = control.dropdown
                    dropdownData.dropdownInstance = dropdown

                    dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                    dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                    dropdown:SetSelectedItemTextColor(selected)

                    dropdown:SetSortsItems(false)
                    dropdown:SetNoSelectionText(noSelectionText)
                    dropdown:SetMultiSelectionTextFormatter(multiSelectionFormatter)
                    dropdown:LoadData(dropdownData)
                    SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)
                end,

                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    targetControl.dropdown:Activate()
                end,

                narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
            },
        }
    end

    local apparelFilterTypesDropdownEntry = CreateEquipmentFilterTypesDropdownEntry(GetString(SI_ITEM_SETS_BOOK_APPAREL_TYPES_DROPDOWN_TEXT_DEFAULT), SI_ITEM_SETS_BOOK_APPAREL_TYPES_DROPDOWN_TEXT, apparelFilterTypesData)
    local weaponFilterTypesDropdownEntry = CreateEquipmentFilterTypesDropdownEntry(GetString(SI_ITEM_SETS_BOOK_WEAPON_TYPES_DROPDOWN_TEXT_DEFAULT), SI_ITEM_SETS_BOOK_WEAPON_TYPES_DROPDOWN_TEXT, weaponFilterTypesData)

    function OnEquipmentFilterTypesChanged(equipmentFilterTypes)
        apparelFilterTypesData:ClearAllSelections()
        weaponFilterTypesData:ClearAllSelections()

        for _, item in ipairs(apparelFilterTypesData:GetAllItems()) do
            if ZO_IsElementInNumericallyIndexedTable(equipmentFilterTypes, item.equipmentFilterType) then
                apparelFilterTypesData:SetItemSelected(item, true)
            end
        end

        for _, item in ipairs(weaponFilterTypesData:GetAllItems()) do
            if ZO_IsElementInNumericallyIndexedTable(equipmentFilterTypes, item.equipmentFilterType) then
                weaponFilterTypesData:SetItemSelected(item, true)
            end
        end
    end

    ITEM_SET_COLLECTIONS_DATA_MANAGER:RegisterCallback("EquipmentFilterTypesChanged", OnEquipmentFilterTypesChanged)

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_ITEM_SETS_BOOK_OPTIONS_DIALOG",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_GAMEPAD_ITEM_SETS_BOOK_OPTIONS))
            -- Get the last saved state once when the dialog opens, but then only modify it locally until the dialog closes
            dialog.showLocked = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetShowLocked()
            dialog:setupFunc()
        end,

        parametricList =
        {
            -- Show Locked
            {
                template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",

                text = GetString(SI_ITEM_SETS_BOOK_SHOW_LOCKED),

                templateData =
                {
                    -- Called when the checkbox is toggled
                    setChecked = function(checkBox, checked)
                        checkBox.dialog.showLocked = checked
                        SCREEN_NARRATION_MANAGER:QueueDialog(checkBox.dialog)
                    end,

                    -- Used during setup to determine if the data should be setup checked or unchecked
                    checked = function(data)
                        return data.dialog.showLocked
                    end,

                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.checkBox.dialog = data.dialog
                        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    end,

                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    end,

                    narrationText = function(entryData, entryControl)
                        local isChecked = entryData.checked(entryData)
                        return ZO_FormatToggleNarrationText(entryData.text, isChecked)
                    end,
                },

                header = GetString(SI_GAMEPAD_ITEM_SETS_BOOK_OPTIONS_FILTERS),
            },

            -- Equipment Filter Types
            apparelFilterTypesDropdownEntry,

            weaponFilterTypesDropdownEntry,

            -- Link in Chat
            {
                template = "ZO_GamepadFullWidthLeftLabelEntryTemplate",

                templateData =
                {
                    text = GetString(SI_ITEM_ACTION_LINK_TO_CHAT),

                    setup = ZO_SharedGamepadEntry_OnSetup,

                    callback = function(dialog)
                        local itemSetCollectionPieceData = dialog.data.selectedItemSetCollectionPieceData
                        ZO_LinkHandler_InsertLinkAndSubmit(zo_strformat(SI_TOOLTIP_ITEM_NAME, itemSetCollectionPieceData:GetItemLink()))
                        ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_ITEM_SETS_BOOK_OPTIONS_DIALOG")
                    end,

                    visible = function(dialog)
                        if IsChatSystemAvailableForCurrentPlatform() then
                            return dialog.data.selectedItemSetCollectionPieceData ~= nil
                        end
                        return false
                    end,
                },

                header = GetString(SI_GAMEPAD_ITEM_SETS_BOOK_OPTIONS_ACTIONS),
            },
        },

        blockDialogReleaseOnPress = true,

        buttons =
        {
            -- Select
            {
                keybind = "DIALOG_PRIMARY",

                text = SI_GAMEPAD_SELECT_OPTION,

                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
            },

            -- Back
            {
                keybind = "DIALOG_NEGATIVE",

                text = SI_DIALOG_CANCEL,

                callback = function()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_ITEM_SETS_BOOK_OPTIONS_DIALOG")
                end,
            },

            -- Reset Filters
            {
                keybind = "DIALOG_RESET",

                text = SI_GUILD_BROWSER_RESET_FILTERS_KEYBIND,

                enabled = function(dialog)
                    return not dialog.showLocked or
                        apparelFilterTypesData:GetNumSelectedItems() > 0 or
                        weaponFilterTypesData:GetNumSelectedItems() > 0
                end,

                callback = function(dialog)
                    dialog.showLocked = true
                    apparelFilterTypesData:ClearAllSelections()
                    weaponFilterTypesData:ClearAllSelections()
                    dialog:setupFunc()
                    --Re-narrate the selection when the filters are reset
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end,
            },
        },

        onHidingCallback = function(dialog)
            ITEM_SET_COLLECTIONS_DATA_MANAGER:SetShowLocked(dialog.showLocked)

            local equipmentFilterTypes = {}

            apparelFilterTypesData.dropdownInstance:Deactivate()
            for _, item in ipairs(apparelFilterTypesData:GetSelectedItems()) do
                table.insert(equipmentFilterTypes, item.equipmentFilterType)
            end

            weaponFilterTypesData.dropdownInstance:Deactivate()
            for _, item in ipairs(weaponFilterTypesData:GetSelectedItems()) do
                table.insert(equipmentFilterTypes, item.equipmentFilterType)
            end

            ITEM_SET_COLLECTIONS_DATA_MANAGER:SetEquipmentFilterTypes(equipmentFilterTypes)
        end,
    })
end

ITEM_SET_COLLECTIONS_MANAGER = ZO_ItemSetCollectionsManager:New()