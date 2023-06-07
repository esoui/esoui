ZO_PEGIAgreement_Gamepad = ZO_InitializingObject:Subclass()

function ZO_PEGIAgreement_Gamepad:Initialize(control)
    ZO_Dialogs_RegisterCustomDialog("PEGI_COUNTRY_SELECT_GAMEPAD",
    {
        mustChoose = true,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        title =
        {
            text = SI_PEGI_COUNTRY_SELECT_TITLE,
        },
        setup = function(dialog)
            local parametricListEntries = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)
            dialog.dropdowns = {}
            local countrySelectDropdown =
            {
                template = "ZO_GamepadDropdownItem",
                entryData = self:GetOrCreateCountrySelectDropdownEntryData(),
            }

            table.insert(parametricListEntries, countrySelectDropdown)

            local submitButton =
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                entryData = self:AddSubmitEntry(),
            }

            table.insert(parametricListEntries, submitButton)

            SCENE_MANAGER:AddFragment(KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT)
            SCENE_MANAGER:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)

            dialog:setupFunc()
        end,
        parametricList = {}, -- Generated dynamically
        blockDialogReleaseOnPress = true, -- We need to manually control when we release so we can use the select keybind to activate entries
        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            if not newSelectedData.isSubmit then
                ZO_GenericGamepadDialog_HideTooltip(dialog)
            end
        end,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end 
                end,
            },
            {
                keyind = "DIALOG_NEGATIVE",
                text = SI_PEGI_COUNTRY_SELECT_BACK,
                callback = function(dialog)
                    ZO_Disconnect()
                end,
            }
        }
    })

    self.countryToRatingsBoard = {}
    self.countriesPopulated = false
end

do
    local countrySelectDropdownEntryData
    function ZO_PEGIAgreement_Gamepad:GetOrCreateCountrySelectDropdownEntryData()
        if countrySelectDropdownEntryData == nil then
            countrySelectDropdownEntryData = ZO_GamepadEntryData:New()
            countrySelectDropdownEntryData.dropdownEntry = true
            countrySelectDropdownEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                local dropdown = control.dropdown
                dropdown:SetSortsItems(false)
                dropdown:ClearItems()

                table.insert(data.dialog.dropdowns, dropdown)
                countrySelectDropdownEntryData.callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.dropdownEntry then
                        local dropdown = targetControl.dropdown
                        dropdown:Activate()
                    end
                end

                local entries = {}
                do
                    local function OnItemSelected()
                        self.currentSelectedCountry = nil
                        self.currentSelectedIndex = 0
                    end
                    entries[0] = dropdown:CreateItemEntry(GetString(SI_PEGI_COUNTRY_SELECT_TITLE), OnItemSelected)
                    dropdown:AddItem(entries[0])
                end
                for i = 1, GetNumCountries() do
                    local countryName, ratingsBoard = GetCountryDataForIndex(i)
                    local function OnItemSelected()
                        self.currentSelectedCountry = countryName
                        self.currentSelectedIndex = i
                    end
                    self.countryToRatingsBoard[countryName] = ratingsBoard
                    entries[i] = dropdown:CreateItemEntry(countryName or "", OnItemSelected)
                    dropdown:AddItem(entries[i])
                end

                SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)

                dropdown:UpdateItems()

                local IGNORE_CALLBACK = true
                dropdown:TrySelectItemByData(entries[self.currentSelectedIndex or 0], IGNORE_CALLBACK)
            end
            countrySelectDropdownEntryData.narrationText = ZO_GetDefaultParametricListDropdownNarrationText
        end
        return countrySelectDropdownEntryData
    end
end

function ZO_PEGIAgreement_Gamepad:AddSubmitEntry()
    local submitEntryData = ZO_GamepadEntryData:New(GetString(SI_PEGI_COUNTRY_SELECT_SUBMIT_GAMEPAD))
    submitEntryData.isSubmit = true
    submitEntryData.callback = function(dialog)
        if self.currentSelectedCountry then
            self:OnCountrySelectionConfirmed()
        else
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, GetString(SI_PEGI_COUNTRY_SELECT_NO_SELECTION_GAMEPAD))
            ZO_GenericGamepadDialog_ShowTooltip(dialog)
            SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
        end
    end

    submitEntryData.setup = ZO_SharedGamepadEntry_OnSetup

    submitEntryData.narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP
    return submitEntryData
end

function ZO_PEGIAgreement_Gamepad:OnCountrySelectionConfirmed()
    local selectedCountry = self.currentSelectedCountry

    if self.countryToRatingsBoard[selectedCountry] == RATINGS_BOARD_PEGI then
        ZO_Dialogs_ShowGamepadDialog("PEGI_AGREEMENT_GAMEPAD")
        ZO_Dialogs_ReleaseDialogOnButtonPress("PEGI_COUNTRY_SELECT_GAMEPAD")
    else
        AgreeToPEGI()
        ZO_Dialogs_ReleaseDialogOnButtonPress("PEGI_COUNTRY_SELECT_GAMEPAD")
        if PregameStateManager_GetCurrentState() == "CharacterSelect" then
            Pregame_ShowScene("gamepadCharacterSelect")
        elseif PregameStateManager_GetCurrentState() == "CharacterCreate" then
            Pregame_ShowScene("gamepadCharacterCreate")
        end
    end
end

function ZO_PEGI_AgreementDialog_Gamepad_OnInitialized(control)
    ZO_GenericGamepadDialog_OnInitialized(control)
    ZO_Dialogs_RegisterCustomDialog("PEGI_AGREEMENT_GAMEPAD",
    {
        customControl = control,
        mustChoose = true,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
        },
        title =
        {
            text = SI_PEGI_AGREEMENT_TITLE,
        },
        mainText =
        {
            text = SI_PEGI_AGREEMENT_TEXT,
        },
        buttons =
        {
            {
                text = SI_DIALOG_ACCEPT,
                callback = function(dialog)
                    AgreeToPEGI()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("PEGI_AGREEMENT_GAMEPAD")
                    if PregameStateManager_GetCurrentState() == "CharacterSelect" then
                        Pregame_ShowScene("gamepadCharacterSelect")
                    elseif PregameStateManager_GetCurrentState() == "CharacterCreate" then
                        Pregame_ShowScene("gamepadCharacterCreate")
                    end
                end,
            },
            {
                text = SI_DIALOG_DECLINE,
                callback = function(dialog)
                    ZO_Dialogs_ShowGamepadDialog("PEGI_AGREEMENT_DECLINED_GAMEPAD")
                    ZO_Dialogs_ReleaseDialogOnButtonPress("PEGI_AGREEMENT_GAMEPAD")
                end,
            },
        },
    })
end

function ZO_PEGI_AgreementDeclinedDialog_Gamepad_OnInitialized(control)
    ZO_GenericGamepadDialog_OnInitialized(control)
    ZO_Dialogs_RegisterCustomDialog("PEGI_AGREEMENT_DECLINED_GAMEPAD",
    {
        customControl = control,
        mustChoose = true,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
        },
        title =
        {
            text = SI_PEGI_AGREEMENT_DECLINE_TITLE,
        },
        mainText =
        {
            text = SI_PEGI_AGREEMENT_DECLINE_TEXT_GAMEPAD,
        },
        baseNarrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
        OnShownCallback = function(dialog)
            local colorizedLinkText = ZO_URL_LINK_COLOR:Colorize(GetString("SI_APPROVEDURLTYPE", APPROVED_URL_ESO_HELP))
            GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, GetString(SI_PEGI_AGREEMENT_CUSTOMER_SERVICE), colorizedLinkText)
            ZO_GenericGamepadDialog_ShowTooltip(dialog)
        end,
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_BACK_UP_ONE_MENU,
                callback = function(dialog)
                    ZO_Dialogs_ShowGamepadDialog("PEGI_AGREEMENT_GAMEPAD")
                    ZO_GenericGamepadDialog_HideTooltip(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("PEGI_AGREEMENT_DECLINED_GAMEPAD")
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_PEGI_AGREEMENT_OPEN_URL,
                callback = function(dialog)
                    OpenURLByType(APPROVED_URL_ESO_HELP)
                    ZO_Dialogs_ShowGamepadDialog("PEGI_COUNTRY_SELECT_GAMEPAD")
                    ZO_GenericGamepadDialog_HideTooltip(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("PEGI_AGREEMENT_DECLINED_GAMEPAD")
                end,
            },
        },
    })
end

PEGI_AGREEMENT_GAMEPAD = ZO_PEGIAgreement_Gamepad:New()