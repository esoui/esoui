ZO_Outfit_Selector_Header_Focus_Gamepad = ZO_InitializingCallbackObject:Subclass()

function ZO_Outfit_Selector_Header_Focus_Gamepad:Initialize(control)
    self.control = control
    self.title = control:GetNamedChild("Title")
    self.label = control:GetNamedChild("OutfitName")
    self.dropdownChevron = control:GetNamedChild("OpenDropdown")
    self.active = false
    self.enabled = true
end

function ZO_Outfit_Selector_Header_Focus_Gamepad:Activate()
    self.active = true
    self:Update()
    self:FireCallbacks("FocusActivated")
end

function ZO_Outfit_Selector_Header_Focus_Gamepad:Enable()
    self.enabled = true
    self:Update()
end

function ZO_Outfit_Selector_Header_Focus_Gamepad:Deactivate()
    self.active = false
    self:Update()
    self:FireCallbacks("FocusDeactivated")
end

function ZO_Outfit_Selector_Header_Focus_Gamepad:Disable()
    self.enabled = false
    self:Update()
end

function ZO_Outfit_Selector_Header_Focus_Gamepad:Update()
    if self.active then
        if self.enabled then
            self.label:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        else
            self.label:SetColor(ZO_GAMEPAD_DISABLED_SELECTED_COLOR:UnpackRGBA())
        end
    else
        if self.enabled then
            self.label:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        else
            self.label:SetColor(ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR:UnpackRGBA())
        end
    end
end

function ZO_Outfit_Selector_Header_Focus_Gamepad:GetNarrationText()
    local narrations = {}
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.title:GetText()))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.label:GetText()))
    return narrations
end

function ZO_Outfit_Selector_Header_Focus_Gamepad:GetAdditionalInputNarrationFunction()
end

function ZO_Outfit_Selector_Header_Focus_Gamepad:GetFooterNarration()
end

function ZO_Outfit_Selector_Header_Focus_Gamepad:IsActive()
    return self.active
end

-- ZO_Outfit_Selector_Gamepad --

ZO_Outfit_Selector_Gamepad = ZO_InitializingObject:Subclass()

function ZO_Outfit_Selector_Gamepad:Initialize(control)
    self.control = control

    local function OnRefreshOutfitName(actorCategory, outfitIndex)
        self:UpdateOutfitList()
    end

    GAMEPAD_OUTFITS_SELECTION_SCENE = ZO_InteractScene:New("gamepad_outfits_selection", SCENE_MANAGER, ZO_DYEING_STATION_INTERACTION)
    GAMEPAD_OUTFITS_SELECTION_SCENE:SetInputPreferredMode(INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)

    GAMEPAD_OUTFITS_SELECTOR_FRAGMENT = ZO_FadeSceneFragment:New(ZO_Outfits_Selector_Gamepad)
    GAMEPAD_OUTFITS_SELECTOR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            ITEM_PREVIEW_GAMEPAD:ResetOutfitPreview()
            self:UpdateOutfitList()
            self:RefreshHeader()
            self.outfitSelectorList:Activate()

            local dataIndex = 1
            if self.currentOutfitIndex then
                dataIndex = dataIndex + self.currentOutfitIndex
            end
            self.outfitSelectorList:SetSelectedIndexWithoutAnimation(dataIndex)

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            ZO_OUTFIT_MANAGER:RegisterCallback("RefreshOutfitName", OnRefreshOutfitName)
            self:PreviewOutfit(self.currentActorCategory, self.currentOutfitIndex)
        elseif newState == SCENE_HIDDEN then
            ZO_OUTFIT_MANAGER:UnregisterCallback("RefreshOutfitName", OnRefreshOutfitName)
            self.outfitSelectorList:Deactivate()
            GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()

            if self.currentOutfitIndex then
                ZO_OUTFIT_MANAGER:EquipOutfit(self.currentActorCategory, self.currentOutfitIndex)
            else
                ZO_OUTFIT_MANAGER:UnequipOutfit(self.currentActorCategory)
            end
        end
    end)

    self.currentActorCategory = GAMEPLAY_ACTOR_CATEGORY_PLAYER
    self.currentOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(self.currentActorCategory)
    ZO_OUTFIT_MANAGER:RegisterCallback("RefreshEquippedOutfitIndex", function() self:UpdateCurrentOutfitIndex() end)
    EVENT_MANAGER:RegisterForEvent("gamepad_outfits_selection", EVENT_CURRENCY_UPDATE, function(eventId, ...) self:OnCurrencyChanged(...) end)
end

function ZO_Outfit_Selector_Gamepad:PerformDeferredInitialization()
    if self.initialized then return end
    self.initialized = true

    self:InitializeKeybindDescriptors()
    self:InitializeRenameDialog()

    local function SetupCheckBoxEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.statusIcon:ClearIcons()
        if data.outfitIndex == self.currentOutfitIndex then
            ZO_CheckButton_SetChecked(control.checkBox)
            if data.isHiddenByVisualLayer then
                control.statusIcon:AddIcon("EsoUI/Art/Inventory/inventory_icon_hiddenBy.dds")
                control.statusIcon:Show()
            end
        else
            ZO_CheckButton_SetUnchecked(control.checkBox)
        end
    end

    local EQUALITY_FUNCTION = nil

    self.outfitSelectorList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("Mask"):GetNamedChild("Container"):GetNamedChild("RootList"))
    self.outfitSelectorList:SetAlignToScreenCenter(true)
    self.outfitSelectorList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.outfitSelectorList:AddDataTemplate("ZO_OutfitSelector_CheckBoxTemplate_Gamepad", SetupCheckBoxEntry, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.outfitSelectorList:AddDataTemplateWithHeader("ZO_OutfitSelector_CheckBoxTemplate_Gamepad", SetupCheckBoxEntry, ZO_GamepadMenuEntryTemplateParametricListFunction, EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate")
    self.outfitSelectorList:SetOnSelectedDataChangedCallback(function(list, selectedData) self:OnListDataChanged(selectedData) end)

    local narrationInfo =
    {
        canNarrate = function()
            return GAMEPAD_OUTFITS_SELECTOR_FRAGMENT:IsShowing()
        end,
        headerNarrationFunction = function()
            return ZO_GamepadGenericHeader_GetNarrationText(self.header, self.headerData)
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.outfitSelectorList, narrationInfo)

    self.header = self.control:GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    local function UpdateCarriedCurrencyControl(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_STYLE_STONES, GetCurrencyAmount(CURT_STYLE_STONES, CURRENCY_LOCATION_ACCOUNT), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
        return true
    end

    local IS_PLURAL = false
    local IS_UPPER = false
    self.headerData =
    {
        titleText = GetString(SI_GAMEPAD_OUTFITS_SELECTOR_HEADER),

        data1HeaderText = zo_strformat(SI_CURRENCY_NAME_FORMAT, GetCurrencyName(CURT_STYLE_STONES, IS_PLURAL, IS_UPPER)),
        data1Text = UpdateCarriedCurrencyControl,
        data1TextNarration = function()
            return ZO_Currency_FormatGamepad(CURT_STYLE_STONES, GetCurrencyAmount(CURT_STYLE_STONES, CURRENCY_LOCATION_ACCOUNT), ZO_CURRENCY_FORMAT_AMOUNT_ICON)
        end,
    }
end

function ZO_Outfit_Selector_Gamepad:InitializeRenameDialog()
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local function UpdateSelectedName(name)
        if self.selectedName ~= name or not self.noViolations then
            self.selectedName = name
            self.nameViolations = { IsValidOutfitName(self.selectedName) }
            self.noViolations = #self.nameViolations == 0

            if not self.noViolations then
                local HIDE_UNVIOLATED_RULES = true
                local violationString = ZO_ValidNameInstructions_GetViolationString(self.selectedName, self.nameViolations, HIDE_UNVIOLATED_RULES)
            
                local headerData =
                {
                    titleText = GetString(SI_INVALID_NAME_DIALOG_TITLE),
                    messageText = violationString,
                    messageTextAlignment = TEXT_ALIGN_LEFT,
                }
                GAMEPAD_TOOLTIPS:ShowGenericHeader(GAMEPAD_LEFT_DIALOG_TOOLTIP, headerData)
                ZO_GenericGamepadDialog_ShowTooltip(parametricDialog)
            else
                ZO_GenericGamepadDialog_HideTooltip(parametricDialog)
            end
        end

        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_RENAME_OUFIT",
    {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            dialog:setupFunc()
        end,

        title =
        {
            text = SI_OUTFIT_RENAME_TITLE,
        },
        mainText =
        {
            text = SI_OUTFIT_RENAME_DESCRIPTION,
        },
        parametricList =
        {
            -- user name
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData =
                {
                    nameField = true,
                    textChangedCallback = function(control)
                        local inputText = control:GetText()
                        if parametricDialog.data then
                            parametricDialog.data.name = inputText
                        end
                        UpdateSelectedName(inputText)
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        control.editBoxControl:SetMaxInputChars(OUTFIT_NAME_MAX_LENGTH)
                        data.control = control

                        if parametricDialog.data then
                            control.editBoxControl:SetText(parametricDialog.data.name)
                        end
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText,
                },
            },
        },
        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    data.control.editBoxControl:TakeFocus()
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_GAMEPAD_COLLECTIONS_SAVE_NAME_OPTION,
                callback =  function(dialog)
                    local outfitIndex = dialog.data.outfitIndex
                    local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(GAMEPLAY_ACTOR_CATEGORY_PLAYER, outfitIndex)
                    outfitManipulator:SetOutfitName(self.selectedName)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RENAME_OUFIT")
                end,
                visible = function()
                    return self.noViolations
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_RENAME_OUFIT")
                end,
            },
        }
    })
end

function ZO_Outfit_Selector_Gamepad:InitializeKeybindDescriptors()
    -- Main list.
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() SCENE_MANAGER:HideCurrentScene() end),

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function() self:UseCurrentSelection() end,
        },

        -- Change Name
        {
            name = GetString(SI_OUTFIT_CHANGE_NAME),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local currentlySelectedData = self.outfitSelectorList:GetTargetData()
                local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(GAMEPLAY_ACTOR_CATEGORY_PLAYER, currentlySelectedData.outfitIndex)
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_RENAME_OUFIT", { outfitIndex = currentlySelectedData.outfitIndex, name = outfitManipulator:GetOutfitName() }) 
            end,
            visible = function()
                local currentlySelectedData = self.outfitSelectorList:GetTargetData()
                return not (self.currentActorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION or currentlySelectedData.noOutfitEntry or currentlySelectedData.newOutfitEntry)
            end,
        },
    }
end

function ZO_Outfit_Selector_Gamepad:UseCurrentSelection()
    local currentlySelectedData = self.outfitSelectorList:GetTargetData()
    if currentlySelectedData.newOutfitEntry then
        ShowMarketAndSearch("", MARKET_OPEN_OPERATION_UNLOCK_NEW_OUTFIT)
    elseif currentlySelectedData.outfitIndex ~= self.currentOutfitIndex then
        self:PreviewOutfit(currentlySelectedData.actorCategory, currentlySelectedData.outfitIndex)
        self.currentActorCategory = currentlySelectedData.actorCategory
        self.currentOutfitIndex = currentlySelectedData.outfitIndex
        self:UpdateOutfitList()
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.outfitSelectorList)
    end
end

function ZO_Outfit_Selector_Gamepad:PreviewOutfit(actorCategory, outfitIndex)
    if outfitIndex then
        ITEM_PREVIEW_GAMEPAD:PreviewOutfit(actorCategory, outfitIndex)
    else
        ITEM_PREVIEW_GAMEPAD:PreviewUnequipOutfit(actorCategory)
    end
end

function ZO_Outfit_Selector_Gamepad:UpdateOutfitList()
    self.outfitSelectorList:Clear()

    -- No Outfit Entry
    local noOutfitData = ZO_GamepadEntryData:New(GetString(SI_NO_OUTFIT_EQUIP_ENTRY))
    noOutfitData.noOutfitEntry = true
    noOutfitData.actorCategory = self.currentActorCategory
    noOutfitData.narrationText = ZO_GetDefaultParametricListToggleNarrationText
    self.outfitSelectorList:AddEntry("ZO_OutfitSelector_CheckBoxTemplate_Gamepad", noOutfitData)

    local numOutfits = ZO_OUTFIT_MANAGER:GetNumOutfits(self.currentActorCategory)
    for i = 1, numOutfits do
        local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(self.currentActorCategory, i)

        local data = ZO_GamepadEntryData:New(outfitManipulator:GetOutfitName())
        data.actorCategory = self.currentActorCategory
        data.outfitIndex = i
        local isHidden, highestPriorityVisualLayerThatIsShowing = WouldOutfitBeHidden(i, data.actorCategory)
        data.isHiddenByVisualLayer = isHidden
        data.hiddenVisualLayer = highestPriorityVisualLayerThatIsShowing
        data.narrationText = ZO_GetDefaultParametricListToggleNarrationText
        if i == 1 then
            local maxOutfits = self.currentActorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION and MAX_COMPANION_OUTFITS or MAX_OUTFIT_UNLOCKS 
            data:SetHeader(zo_strformat(SI_GAMEPAD_OUTFITS_SELECTOR_ENTRY_HEADER, numOutfits, maxOutfits))
            self.outfitSelectorList:AddEntryWithHeader("ZO_OutfitSelector_CheckBoxTemplate_Gamepad", data)
        else
            self.outfitSelectorList:AddEntry("ZO_OutfitSelector_CheckBoxTemplate_Gamepad", data)
        end
    end

    -- Unlock New Outfit Entry only if in player outfit mode
    if self.currentActorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER and numOutfits < MAX_OUTFIT_UNLOCKS then
        local data = ZO_GamepadEntryData:New(GetString(SI_UNLOCK_NEW_OUTFIT_EQUIP_ENTRY), "EsoUI/Art/currency/gamepad/gp_crowns.dds")
        data.newOutfitEntry = true
        self.outfitSelectorList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    end

    self.outfitSelectorList:Commit()
end

function ZO_Outfit_Selector_Gamepad:OnListDataChanged(newSelectedData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    if newSelectedData.isHiddenByVisualLayer and newSelectedData.outfitIndex == self.currentOutfitIndex then
        GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_OUTFITS_OUTFIT_HIDDEN_TITLE), GetHiddenByStringForVisualLayer(newSelectedData.hiddenVisualLayer))
    end
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Outfit_Selector_Gamepad:OnCurrencyChanged(currencyType, currencyLocation, newAmount, oldAmount, reason)
    if currencyType == CURT_STYLE_STONES then
        if SCENE_MANAGER:IsShowing("gamepad_outfits_selection") then
            self:RefreshHeader()
        end
    end
end

function ZO_Outfit_Selector_Gamepad:UpdateCurrentOutfitIndex()
    self.currentOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex(self.currentActorCategory)
end

function ZO_Outfit_Selector_Gamepad:RefreshHeader()
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_Outfit_Selector_Gamepad:SetCurrentActorCategory(actorCategory)
    if self.currentActorCategory ~= actorCategory then
        self.currentActorCategory = actorCategory
        self:UpdateCurrentOutfitIndex()
    end
end

function ZO_Outfit_Selector_Gamepad:GetCurrentActorCategoryAndIndex()
    return self.currentActorCategory, self.currentOutfitIndex
end

-- XML functions --

function ZO_OutfitSlot_Selector_OnInitialize(control)
    ZO_OUTFITS_SELECTOR_GAMEPAD = ZO_Outfit_Selector_Gamepad:New(control)
end
