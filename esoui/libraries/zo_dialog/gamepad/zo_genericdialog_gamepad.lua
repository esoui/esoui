GAMEPAD_DIALOGS = {
    BASIC = 1,
    PARAMETRIC = 2,
    COOLDOWN = 3,
    CENTERED = 4,
    STATIC_LIST = 5,
    ITEM_SLIDER = 6,
    CUSTOM = 7,
}

local GAMEPAD_DIALOG_SHOWING = false

local DEFAULT_WARNING_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_FAILED))

----------------------
-- Helper Functions --
----------------------

local DialogKeybindStripDescriptor = ZO_InitializingObject:Subclass()

function DialogKeybindStripDescriptor:Initialize(control)
    -- dialog buttons expect the dialog to be the callbackArg
    self.callback = function(pressState)
        if self.buttonCallback then
            self.buttonCallback(self.dialog, pressState)
        end

        -- it's possible for the callback to remove the dialog and clean it up
        -- but most don't, so we need to make sure we close them all without error
        if(self.dialog and not self.dialog.info.blockDialogReleaseOnPress) then
            ZO_Dialogs_ReleaseDialogOnButtonPress(self.dialog.name)
        end
    end

    self.visible = function()
        if self.buttonVisible then
            if type(self.buttonVisible) == "function" then
                return self.buttonVisible(self.dialog)
            else
                return self.buttonVisible
            end
        else 
            return true
        end
    end

    self.enabled = function()
        if self.buttonEnabled then
            if type(self.buttonEnabled) == "function" then
                return self.buttonEnabled(self.dialog)
            else
                return self.buttonEnabled
            end
        else 
            return true
        end 
    end

    self.name = function()
        if self.buttonText then
            if type(self.buttonText) == "function" then
                return self.buttonText(self.dialog)
            elseif type(self.buttonText) == "number" then
                return GetString(self.buttonText)
            else
                return self.buttonText
            end
        end
    end

    self.narrationOverrideName = function()
        if self.narrationOverrideText then
            if type(self.narrationOverrideText) == "function" then
                return self.narrationOverrideText(self.dialog)
            elseif type(self.narrationOverrideText) == "number" then
                return GetString(self.narrationOverrideText)
            else
                return self.narrationOverrideText
            end
        else
            return self.name()
        end
    end

    self:Reset()
end

function DialogKeybindStripDescriptor:Reset()
    self.buttonVisible = nil
    self.buttonCallback = nil
    self.buttonEnabled = nil
    self.buttonText = nil
    self.narrationOverrideText = nil
    self.dialog = nil
    self.keybind = nil
    self.sound = nil
    self.alignment = KEYBIND_STRIP_ALIGN_LEFT
    self.handlesKeyUp = nil
    self.onShowCooldown = nil
    self.cooldown = nil
end

function DialogKeybindStripDescriptor:SetAlignment(alignment)
    if alignment then
        self.alignment = alignment
    end
end

function DialogKeybindStripDescriptor:SetDialog(dialog)
    self.dialog = dialog
end

function DialogKeybindStripDescriptor:SetButtonCallback(callback)
    self.buttonCallback = callback
end

function DialogKeybindStripDescriptor:SetVisible(visible)
    self.buttonVisible = visible
end

function DialogKeybindStripDescriptor:SetEnabled(enabled)
    self.buttonEnabled = enabled
end

function DialogKeybindStripDescriptor:SetText(text)
    self.buttonText = text
end

function DialogKeybindStripDescriptor:SetEthereal(ethereal)
    self.ethereal = ethereal
end

function DialogKeybindStripDescriptor:SetNarrateEthereal(narrateEthereal)
    self.narrateEthereal = narrateEthereal
end

function DialogKeybindStripDescriptor:SetNarrationOverrideText(narrationOverrideText)
    self.narrationOverrideText = narrationOverrideText
end

function DialogKeybindStripDescriptor:SetEtherealNarrationOrder(etherealNarrationOrder)
    self.etherealNarrationOrder = etherealNarrationOrder
end

function DialogKeybindStripDescriptor:SetHandlesKeyUp(handlesKeyUp)
    self.handlesKeyUp = handlesKeyUp
end

function DialogKeybindStripDescriptor:SetKeybind(keybind, index)
    if keybind then
        self.keybind = keybind
    else
        if index == 1 then
            self.keybind = "DIALOG_PRIMARY"
        elseif index == 2 then
            self.keybind = "DIALOG_NEGATIVE"
        end
    end
end

function DialogKeybindStripDescriptor:SetSound(sound)
    self.sound = sound
end

function DialogKeybindStripDescriptor:SetOnShowCooldown(timeMs)
    self.onShowCooldown = timeMs
end

function DialogKeybindStripDescriptor:GetOnShowCooldown()
    return self.onShowCooldown
end

function DialogKeybindStripDescriptor:SetDefaultSoundFromKeybind(twoOrMoreButtons)
    if twoOrMoreButtons then
        if self.keybind == "DIALOG_PRIMARY" then
            self.sound = SOUNDS.DIALOG_ACCEPT
        elseif self.keybind == "DIALOG_NEGATIVE" then
            self.sound = SOUNDS.DIALOG_DECLINE
        end
    end
end

local g_keybindStripDescriptors = ZO_ObjectPool:New(DialogKeybindStripDescriptor, ZO_ObjectPool_DefaultResetObject)
local g_keybindGroupDesc = {}
local g_keybindState = nil

local function TryRefreshKeybind(dialog, keybindDesc, buttonData, twoOrMoreButtons, index)
    if(dialog.textParams ~= nil and dialog.textParams.buttonTextOverrides ~= nil and dialog.textParams.buttonTextOverrides[index] ~= nil) then
        keybindDesc:SetText(dialog.textParams.buttonTextOverrides[index])
    else
        keybindDesc:SetText(buttonData.text or buttonData.name)
    end

    if(dialog.textParams ~= nil and dialog.textParams.buttonKeybindOverrides ~= nil and dialog.textParams.buttonKeybindOverrides[index] ~= nil) then
        keybindDesc:SetKeybind(dialog.textParams.buttonKeybindOverrides[index], index)
    else
        local keybind
        if IsInGamepadPreferredMode() and buttonData.gamepadPreferredKeybind then
            keybind = buttonData.gamepadPreferredKeybind
        else
            keybind = buttonData.keybind
        end
        keybindDesc:SetKeybind(keybind, index)
    end

    keybindDesc:SetDialog(dialog)
    keybindDesc:SetAlignment(buttonData.alignment)
    keybindDesc:SetButtonCallback(buttonData.callback)
    keybindDesc:SetVisible(buttonData.visible)
    keybindDesc:SetEthereal(buttonData.ethereal)
    keybindDesc:SetNarrateEthereal(buttonData.narrateEthereal)
    keybindDesc:SetEtherealNarrationOrder(buttonData.etherealNarrationOrder)
    keybindDesc:SetNarrationOverrideText(buttonData.narrationOverrideText)
    keybindDesc:SetEnabled(buttonData.enabled)
    keybindDesc:SetOnShowCooldown(buttonData.onShowCooldown)
    keybindDesc:SetHandlesKeyUp(buttonData.handlesKeyUp)

    if buttonData.clickSound then
        keybindDesc:SetSound(buttonData.clickSound)
    else
        keybindDesc:SetDefaultSoundFromKeybind(twoOrMoreButtons)
    end
end

local function TryShowKeybinds(dialog)
    ZO_ClearNumericallyIndexedTable(g_keybindGroupDesc)

    local buttons = dialog.info.buttons
    local numButtons = buttons and #buttons or 0
    if numButtons > 0 then
        for index, value in ipairs(buttons) do
            if(type(value) == "table") then
                local keybindDesc = g_keybindStripDescriptors:AcquireObject()

                TryRefreshKeybind(dialog, keybindDesc, value, (numButtons > 1), index)

                table.insert(g_keybindGroupDesc, keybindDesc)
            end
        end
    end

    if(#g_keybindGroupDesc > 0) then
        KEYBIND_STRIP:AddKeybindButtonGroup(g_keybindGroupDesc, g_keybindState)

        for _, keybindDesc in ipairs(g_keybindGroupDesc) do
            local onShowCooldown = keybindDesc:GetOnShowCooldown()
            if onShowCooldown then
                KEYBIND_STRIP:TriggerCooldown(keybindDesc, onShowCooldown, g_keybindState)
            end
        end
    end
end

local function TryRefreshKeybinds(dialog)
    local buttons = dialog.info.buttons
    local numButtons = buttons and #buttons or 0
    if numButtons > 0 then
        for index, value in ipairs(buttons) do
            if(type(value) == "table") then
                local keybindDesc = g_keybindGroupDesc[index]
                if keybindDesc then
                    TryRefreshKeybind(dialog, keybindDesc, value, (numButtons > 1), index)
                end
            end
        end
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(g_keybindGroupDesc, g_keybindState)
end

local function TryRemoveKeybinds()
    if(#g_keybindGroupDesc > 0) then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(g_keybindGroupDesc, g_keybindState)
    end
end

function ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
    TryRefreshKeybinds(dialog)
end

function ZO_GenericGamepadDialog_UpdateDirectionalInput(dialog)
    --[[Different dialogs have different needs for input blocking. Most will want to eat all input so you don't end up scrolling lists
    below the dialog or moving characters. Some want the right stick to pass through to control tooltip scrolling on the scene below. In that case
    add allowRightStickPassThrough = true to the dialog's gamepadInfo table.]]--
    DIRECTIONAL_INPUT:Consume(unpack(dialog.directionalInputEaters))
    if not dialog.info.gamepadInfo.allowRightStickPassThrough then
        ZO_SCROLL_SHARED_INPUT:Consume()
    end
end

do
    local ALLOW_RIGHT_STICK = { ZO_DI_LEFT_STICK, ZO_DI_DPAD }
    local CONSUME_ALL = { ZO_DI_LEFT_STICK, ZO_DI_RIGHT_STICK, ZO_DI_DPAD }

    function ZO_GenericGamepadDialog_SetupDirectionalInput(dialog)
        if dialog.info.gamepadInfo.allowRightStickPassThrough then
            dialog.directionalInputEaters = ALLOW_RIGHT_STICK
        else
            dialog.directionalInputEaters = CONSUME_ALL
        end
    end
end

----------------------------
-- Global Gamepad Dialogs --
----------------------------

function ZO_GenericGamepadDialog_GetControl(dialogType)
    if dialogType == GAMEPAD_DIALOGS.BASIC then
        return ZO_GamepadDialogBase
    elseif dialogType == GAMEPAD_DIALOGS.PARAMETRIC then
        return ZO_GamepadDialogPara
    elseif dialogType == GAMEPAD_DIALOGS.COOLDOWN then
        return ZO_GamepadDialogCool
    elseif dialogType == GAMEPAD_DIALOGS.CENTERED then
        return ZO_GamepadDialogCentered
    elseif dialogType == GAMEPAD_DIALOGS.STATIC_LIST then
        return ZO_GamepadDialogStaticList
    elseif dialogType == GAMEPAD_DIALOGS.ITEM_SLIDER then
        return ZO_GamepadDialogItemSlider
    end

    return nil
end

-----------------------
-- Dialog Management --
-----------------------

local function OnDialogShowing(dialog)
    GAMEPAD_DIALOG_SHOWING = true
    CALLBACK_MANAGER:FireCallbacks("OnGamepadDialogShowing")
    PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_DIALOG))
    dialog:Activate()
    g_keybindState = KEYBIND_STRIP:PushKeybindGroupState()

    if dialog.shouldShowTooltip then
        ZO_GenericGamepadDialog_ShowTooltip(dialog)
    end

    dialog.hideSceneOnClose = false
end

local function OnDialogShown(dialog)
    TryShowKeybinds(dialog)

    if dialog.isShowingOnBase then
        PlaySound(SOUNDS.GAMEPAD_OPEN_WINDOW)
    else
        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    end

    if dialog.info.OnShownCallback then
        dialog.info.OnShownCallback(dialog)
    end

    local NARRATE_BASE_TEXT = true
    SCREEN_NARRATION_MANAGER:QueueDialog(dialog, NARRATE_BASE_TEXT)
end

local function OnDialogHiding(dialog)
    ZO_GenericGamepadDialog_HideTooltip(dialog)
    if dialog.entryList then
        dialog.entryList:Deactivate()
    end
    TryRemoveKeybinds()

    if dialog.info.onHidingCallback then
        dialog.info.onHidingCallback(dialog)
    end
end

local function OnDialogHidden(dialog)
    if dialog.info.OnHiddenCallback then
        dialog.info.OnHiddenCallback(dialog)
    end

    if dialog.warningTextControl then
        dialog.warningTextControl:SetColor(DEFAULT_WARNING_COLOR:UnpackRGBA())
    end

    local releasedFromButton = dialog.releasedFromButton
    dialog.releasedFromButton = nil

    RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_DIALOG))
    dialog:Deactivate()
    KEYBIND_STRIP:PopKeybindGroupState()
    g_keybindStripDescriptors:ReleaseAllObjects()

    -- store dialog name in a local here because ZO_CompleteReleaseDialogOnDialogHidden will clear it
    local name = dialog.name
    ZO_CompleteReleaseDialogOnDialogHidden(dialog, releasedFromButton)

    if dialog.isShowingOnBase then
        PlaySound(SOUNDS.GAMEPAD_CLOSE_WINDOW)
    else
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    end

    if dialog.hideSceneOnClose then
        SCENE_MANAGER:HideCurrentScene()
    end
    GAMEPAD_DIALOG_SHOWING = false
    CALLBACK_MANAGER:FireCallbacks("OnGamepadDialogHidden", name)
end

-- this always gets called
function ZO_GenericGamepadDialog_RefreshText(dialog, title, mainText, warningText, subText)
    if dialog.gamepadInfo and dialog.gamepadInfo.RefreshTextOverride then
        dialog.gamepadInfo.RefreshTextOverride(dialog, title, mainText, warningText, subText)
    else
        local headerData = dialog.headerData
        if headerData then
            ZO_ClearTable(headerData) -- make sure we are not bringing over header data from the previous setup.
            headerData.titleText = title
            headerData.titleTextAlignment = TEXT_ALIGN_LEFT
        end

        if dialog.mainTextControl then
            dialog.mainTextControl:SetText(mainText)
        end

        if dialog.warningTextControl then
            local warningTextDisplay = warningText or ""
            dialog.warningTextControl:SetText(warningTextDisplay)
        end

        if dialog.subTextControl then
            local subTextDisplay = subText or ""
            dialog.subTextControl:SetText(subTextDisplay)
        end

        if not ZO_GenericGamepadDialog_RefreshHeaderData(dialog, dialog.data) and headerData then
            -- refresh the header, but only if ZO_GenericGamepadDialog_RefreshHeaderData didn't already
            ZO_GamepadGenericHeader_Refresh(dialog.header, headerData)
        end
    end
end

function ZO_GenericGamepadDialog_RefreshHeaderData(dialog, data)
    local headerData = dialog.headerData
    if headerData and data then
        headerData.headerLineCount = 0
        if data.data1 then
            headerData.data1HeaderText = data.data1.header
            headerData.data1HeaderTextNarration = data.data1.headerNarration
            headerData.data1Text = data.data1.value
            headerData.data1TextNarration = data.data1.valueNarration
            headerData.headerLineCount = headerData.headerLineCount + 1
        else
            headerData.data1HeaderText = nil
            headerData.data1HeaderTextNarration = nil
            headerData.data1Text = nil
            headerData.data1TextNarration = nil
        end

        if data.data2 then
            headerData.data2HeaderText = data.data2.header
            headerData.data2HeaderTextNarration = data.data2.headerNarration
            headerData.data2Text = data.data2.value
            headerData.data2TextNarration = data.data2.valueNarration
            headerData.headerLineCount = headerData.headerLineCount + 1
        else
            headerData.data2HeaderText = nil
            headerData.data2HeaderTextNarration = nil
            headerData.data2Text = nil
            headerData.data2TextNarration = nil
        end

        if data.data3 then
            headerData.data3HeaderText = data.data3.header
            headerData.data3HeaderTextNarration = data.data3.headerNarration
            headerData.data3Text = data.data3.value
            headerData.data3TextNarration = data.data3.valueNarration
            headerData.headerLineCount = headerData.headerLineCount + 1
        else
            headerData.data3HeaderText = nil
            headerData.data3HeaderTextNarration = nil
            headerData.data3Text = nil
            headerData.data3TextNarration = nil
        end

        if data.data4 then
            headerData.data4HeaderText = data.data4.header
            headerData.data4HeaderTextNarration = data.data4.headerNarration
            headerData.data4Text = data.data4.value
            headerData.data4TextNarration = data.data4.valueNarration
            headerData.headerLineCount = headerData.headerLineCount + 1
        else
            headerData.data4HeaderText = nil
            headerData.data4HeaderTextNarration = nil
            headerData.data4Text = nil
            headerData.data4TextNarration = nil
        end

        ZO_GamepadGenericHeader_Refresh(dialog.header, headerData)

        if dialog.onRefreshHeader then
            dialog.onRefreshHeader()
        end

        return true
    end

    return false
end

function ZO_GenericGamepadDialog_GetDialogFragmentGroup(dialog)
    local gamepadInfo = dialog.info.gamepadInfo
    if gamepadInfo.dontEndInWorldInteractions then
        return ZO_GAMEPAD_DIALOG_DONT_END_IN_WORLD_INTERACTIONS_FRAGMENT_GROUP
    elseif gamepadInfo.dialogFragmentGroup then
        return gamepadInfo.dialogFragmentGroup
    else
        return ZO_GAMEPAD_DIALOG_FRAGMENT_GROUP
    end
end

function ZO_GenericGamepadDialog_OnInitialized(dialog)
    dialog.setupFunc = ZO_GenericGamepadDialog_RefreshHeaderData

    -- Management

    dialog.Activate = function(dialog)
        if not dialog.info.blockDirectionalInput then
            DIRECTIONAL_INPUT:Activate(dialog, dialog)
        end
    end

    dialog.Deactivate = function(dialog) DIRECTIONAL_INPUT:Deactivate(dialog) end
    dialog.UpdateDirectionalInput = ZO_GenericGamepadDialog_UpdateDirectionalInput

    dialog.fragment = dialog.fragment or ZO_TranslateFromLeftSceneFragment:New(dialog, true)

    dialog.hideFunction = function(dialog, releasedFromButton)
        dialog.releasedFromButton = releasedFromButton
        TryRemoveKeybinds()

        local dialogFragmentGroup = ZO_GenericGamepadDialog_GetDialogFragmentGroup(dialog)
        if dialogFragmentGroup then -- pregame doesn't have ZO_GAMEPAD_DIALOG_FRAGMENT_GROUP
            SCENE_MANAGER:RemoveFragmentGroup(dialogFragmentGroup)
        end
        SCENE_MANAGER:RemoveFragment(dialog.fragment)
    end

    dialog.OnDialogShowing = OnDialogShowing
    dialog.OnDialogShown = OnDialogShown
    dialog.OnDialogHiding = OnDialogHiding
    dialog.OnDialogHidden = OnDialogHidden

    dialog.fragment:RegisterCallback("StateChange", function(oldState, newState)
                                                        if newState == SCENE_FRAGMENT_SHOWING then
                                                            dialog:OnDialogShowing()
                                                        elseif newState == SCENE_FRAGMENT_SHOWN then
                                                            dialog:OnDialogShown()
                                                        elseif newState == SCENE_FRAGMENT_HIDING then
                                                            dialog:OnDialogHiding()
                                                        elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                            dialog:OnDialogHidden()
                                                        end
                                                    end)

    local headerContainer = dialog:GetNamedChild("HeaderContainer")
    if headerContainer then
        dialog.headerData = {}
        dialog.header = dialog:GetNamedChild("HeaderContainer").header
        ZO_GamepadGenericHeader_Initialize(dialog.header)
    end

    dialog.container = dialog:GetNamedChild("Container")
    if dialog.container then
        dialog.scrollChild = dialog.container:GetNamedChild("ScrollChild")
        dialog.scrollIndicator = dialog.container:GetNamedChild("ScrollIndicator")
        dialog.mainTextControl = dialog.scrollChild:GetNamedChild("MainText")
        dialog.subTextControl = dialog.scrollChild:GetNamedChild("SubText")
        dialog.warningTextControl = dialog.scrollChild:GetNamedChild("WarningText")
    end
end

function ZO_GenericGamepadDialog_SetDialogWarningColor(dialog, warningColor)
    if dialog.warningTextControl then
        dialog.warningTextControl:SetColor(warningColor:UnpackRGBA())
    end
end

function ZO_GenericGamepadDialog_Show(dialog)
    ZO_GenericGamepadDialog_SetupDirectionalInput(dialog)

    --Attach the dialog fragment to whichever scene is currenty showing
    dialog.isShowingOnBase = false

    local dialogFragmentGroup = ZO_GenericGamepadDialog_GetDialogFragmentGroup(dialog)
    if dialogFragmentGroup then
        SCENE_MANAGER:AddFragmentGroup(dialogFragmentGroup)
    end

    if SCENE_MANAGER:IsShowingBaseScene() then
        dialog.isShowingOnBase = true
    end

    if dialog.scrollIndicator then
        dialog.scrollIndicator:ClearAnchors()
        local offsetY = dialog.info.offsetScrollIndictorForArrow and ZO_GAMEPAD_PANEL_BG_SCROLL_INDICATOR_OFFSET_FOR_ARROW
        ZO_Scroll_Gamepad_SetScrollIndicatorSide(dialog.scrollIndicator, dialog, RIGHT, dialog.rightStickScrollIndicatorOffsetX, offsetY)
    end

    SCENE_MANAGER:AddFragment(dialog.fragment)

    if dialog.entryList then
        dialog.entryList:Activate()
    end
end

function ZO_GenericGamepadDialog_IsShowing()
    return GAMEPAD_DIALOG_SHOWING
end

-------------
-- Tooltip --
-------------

function ZO_GenericGamepadDialog_ShowTooltip(dialog)
    dialog.shouldShowTooltip = true

    GAMEPAD_TOOLTIPS:SetBgType(GAMEPAD_LEFT_DIALOG_TOOLTIP, GAMEPAD_TOOLTIP_DARK_BG)
    GAMEPAD_TOOLTIPS:ShowBg(GAMEPAD_LEFT_DIALOG_TOOLTIP)
end

function ZO_GenericGamepadDialog_HideTooltip(dialog)
    if dialog.shouldShowTooltip then

        GAMEPAD_TOOLTIPS:HideBg(GAMEPAD_LEFT_DIALOG_TOOLTIP)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP)
        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_DIALOG_TOOLTIP)

        dialog.shouldShowTooltip = false
    end
end

-------------------------------------
-- Parametric List Dialog Template --
-------------------------------------

local GAMEPAD_DIALOG_MAX_LINE_LIMIT = 4

-- Dialog
local GenericParametricListGamepadDialogTemplate_InitializeEntryList -- forward declare
function ZO_GenericParametricListGamepadDialogTemplate_OnInitialized(dialog)
    ZO_GenericGamepadDialog_OnInitialized(dialog)

    if dialog.container then
        local fonts =
        {
            {
                font = "ZoFontGamepadCondensed42",
                lineLimit = GAMEPAD_DIALOG_MAX_LINE_LIMIT,
            },
            {
                font = "ZoFontGamepadCondensed34",
                lineLimit = GAMEPAD_DIALOG_MAX_LINE_LIMIT,
            },
        }

        local function OnRefreshText()
            local headerData = dialog.headerData

            if headerData and headerData.headerLineCount then
                local lineLimit = GAMEPAD_DIALOG_MAX_LINE_LIMIT - headerData.headerLineCount
                if lineLimit <= 0 then
                    lineLimit = 1
                end

                for i, font in pairs(fonts) do
                    font.lineLimit = lineLimit
                end
            end

            return fonts
        end

        if dialog.mainTextControl then
            ZO_FontAdjustingWrapLabel_OnInitialized(dialog.mainTextControl, OnRefreshText, TEXT_WRAP_MODE_ELLIPSIS)
        end

        if dialog.mainTextControl then
            dialog.onRefreshHeader = function()
                dialog.mainTextControl:MarkDirty()
            end
        end
    end

    dialog.setupFunc = ZO_GenericParametricListGamepadDialogTemplate_Setup
    local baseHideFunction = dialog.hideFunction
    dialog.hideFunction =   function(dialog, releasedFromButton)
                                baseHideFunction(dialog, releasedFromButton)
                                dialog.entryList:RemoveAllOnSelectedDataChangedCallbacks()
                                -- ensure deactivate is called before clear so that the parametricListOnActivatedChangedCallback
                                -- can act on the selected entry (or anything else in the list) as necessary
                                dialog.entryList:Deactivate()
                                dialog.entryList:Clear()
                            end

    GenericParametricListGamepadDialogTemplate_InitializeEntryList(dialog)
end

do
    local function DefaultOnSelectionChangedCallback()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(g_keybindGroupDesc, g_keybindState)
    end

    function ZO_GenericParametricListGamepadDialogTemplate_Setup(dialog, limitNumEntries, data)
        if data then
            ZO_GenericGamepadDialog_RefreshHeaderData(dialog, data)
        end

        local onSelectionChangedCallback
        local dialogOnSelectionChangedCallback = dialog.info.parametricListOnSelectionChangedCallback
        if dialogOnSelectionChangedCallback then
            onSelectionChangedCallback =    function(...)
                                                dialogOnSelectionChangedCallback(dialog, ...)
                                                DefaultOnSelectionChangedCallback()
                                            end
        else
            onSelectionChangedCallback = DefaultOnSelectionChangedCallback
        end

        dialog.entryList:SetOnSelectedDataChangedCallback(onSelectionChangedCallback)

        dialog.entryList:SetOnActivatedChangedFunction(function(...)
            ZO_GamepadOnDefaultScrollListActivatedChanged(...)
            if dialog.info.parametricListOnActivatedChangedCallback then
                dialog.info.parametricListOnActivatedChangedCallback(...)
            end
        end)

        ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog, limitNumEntries)
    end
end

do
    local function ParametricListControlSetupFunc(control, data, selected, reselectingDuringRebuild, enabled, active)
        if control.resetFunction then
            control.resetFunction()
        end
        data.setup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    function GenericParametricListGamepadDialogTemplate_InitializeEntryList(dialog)
        local listControl = dialog:GetNamedChild("EntryList"):GetNamedChild("List")
        dialog.entryList = ZO_GamepadVerticalItemParametricScrollList:New(listControl)
        dialog.entryList:SetAlignToScreenCenter(true)
        dialog.entryList:SetHandleDynamicViewProperties(true)

        -- Unregister all dropdown callbacks since the dialog control may be used for a different dialog
        local function ResetDropdownItem(control)
            control.dropdown:ClearCallbackRegistry()
            control.dropdown:Reset()
            --Re-register for narration after clearing the callback registry
            SCREEN_NARRATION_MANAGER:RegisterComboBox(control.dropdown)
        end

        -- Custom data templates
        dialog.entryList:AddDataTemplateWithHeader("ZO_GamepadDropdownItem", ParametricListControlSetupFunc, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate", nil, nil, ResetDropdownItem)
        dialog.entryList:AddDataTemplate("ZO_GamepadDropdownItem", ParametricListControlSetupFunc, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, nil, ResetDropdownItem)
        dialog.entryList:AddDataTemplateWithHeader("ZO_GamepadMultiSelectionDropdownItem", ParametricListControlSetupFunc, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryFullWidthHeaderTemplate", nil, nil, ResetDropdownItem)
        dialog.entryList:AddDataTemplate("ZO_GamepadMultiSelectionDropdownItem", ParametricListControlSetupFunc, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, nil, ResetDropdownItem)

        SCREEN_NARRATION_MANAGER:RegisterParametricListDialog(dialog)
    end

    function ZO_GenericParametricListGamepadDialogTemplate_RefreshVisibleEntries(dialog)
        dialog.entryList:RefreshVisible()
    end

    -- Valid fields for parametric list entries are:
        --   visible - a bool or function which determines if we show the entry
        --   template - the template for the gamepad entry data in the parametric list
        --   templateData - A table of fields to add to the entry data
        --   text - the text that will appear in the list
        --   icon - an optional icon to show next to the entry in the parametric list
        --   entryData - a premade ZO_GamepadEntryData in place of the one created from templateData, text, and icon
    function ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog, limitNumEntries, reselect)
        dialog.entryList:Clear()

        for i, entryInfoTable in ipairs(dialog.info.parametricList) do
            if limitNumEntries == nil or i <= limitNumEntries then
                local visible = true
                local entryDataOverrides = entryInfoTable.templateData -- this table will be copied on to the entry data that we create
                -- By default all entries are visible
                -- entries will only be hidden if entryDataOverrides.visible is false or is a function that returns false
                if entryDataOverrides and (entryDataOverrides.visible ~= nil) then
                    visible = entryDataOverrides.visible
                    if type(visible) == "function" then
                        visible = visible(dialog)
                    end
                end

                if visible then
                    local entryData = entryInfoTable.entryData
                    if entryData == nil then
                        local entryDataText = entryInfoTable.text or entryDataOverrides.text
                        if entryDataText ~= nil then
                            if type(entryDataText) == "number" then
                                entryDataText = GetString(entryDataText)
                            elseif type(entryDataText) == "function" then
                                entryDataText = entryDataText(dialog)
                            end
                        else -- default entry text
                            entryDataText = "EntryItem" .. tostring(i)
                        end

                        entryData = ZO_GamepadEntryData:New(entryDataText, entryInfoTable.icon)

                        -- TODO: This loop is pretty awful (and we should just pass in entryData see Achievements_Gamepad.lua)
                        if entryDataOverrides then
                            for dataKey, dataValue in pairs(entryDataOverrides) do
                                if dataKey ~= "text" then
                                    entryData[dataKey] = dataValue
                                end
                            end
                        end
                    end

                    entryData.dialog = dialog

                    local entryTemplate = entryInfoTable.template
                    -- BUG: instead of letting you pick the headerTemplate/controlReset on a per-entry basis,
                    -- the first time we see a particular entryTemplate will be the model for ALL future entries using that entryTemplate.
                    -- to work around this you need to create a unique new entryTemplate whenever you want different behavior.
                    if not dialog.entryList:HasDataTemplate(entryTemplate) then
                        dialog.entryList:AddDataTemplateWithHeader(entryTemplate, ParametricListControlSetupFunc, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, entryInfoTable.headerTemplate or "ZO_GamepadMenuEntryHeaderTemplate", nil, nil, entryInfoTable.controlReset)
                        dialog.entryList:AddDataTemplate(entryTemplate, ParametricListControlSetupFunc, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, nil, entryInfoTable.controlReset)
                    end

                    local headerText = entryInfoTable.header
                    if headerText ~= nil then
                        if type(headerText) == "number" then
                            headerText = GetString(headerText)
                        end
                        entryData:SetHeader(headerText)
                        dialog.entryList:AddEntryWithHeader(entryTemplate, entryData)
                    else
                        dialog.entryList:AddEntry(entryTemplate, entryData)
                    end
                end
            end
        end

        if reselect then
            dialog.entryList:Commit()
        else
            dialog.entryList:CommitWithoutReselect()
        end
    end
end

-------------------------------------
-- Cooldown Dialog Template --
-------------------------------------

function ZO_GenericCooldownGamepadDialogTemplate_OnInitialized(dialog)
    ZO_GenericGamepadDialog_OnInitialized(dialog)

    dialog.setupFunc = ZO_GenericCooldownGamepadDialogTemplate_Setup
    dialog.cooldownLabelControl = dialog:GetNamedChild("LoadingContainerCooldownLabel")
    dialog.loadingControl = dialog:GetNamedChild("LoadingContainerLoading")
end

function ZO_GenericCooldownGamepadDialogTemplate_Setup(dialog)
    local loadingMode = dialog.info.loading ~= nil

    dialog.cooldownLabelControl:SetText("")

    dialog.loadingControl:SetHidden(not loadingMode)
    if loadingMode then
        local loadingString = dialog.info.loading.text

        if type(loadingString) == "function" then
            loadingString = loadingString(dialog)
        end

        if loadingString and loadingString ~= "" then
            dialog.cooldownLabelControl:SetText(loadingString)
            dialog.cooldownLabelControl:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        end
    else
        dialog.cooldownLabelControl:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    end
end

-------------------------------------
-- Centered Template --
-------------------------------------

function ZO_GenericCenteredGamepadDialogTemplate_OnInitialized(dialog)
    dialog.fragment = ZO_FadeSceneFragment:New(dialog)

    ZO_GenericGamepadDialog_OnInitialized(dialog)
    dialog.scrollPadding = dialog.scrollChild:GetNamedChild("Padding")
    dialog.setupFunc = ZO_GenericCenteredGamepadDialogTemplate_Setup

    local GENERIC_CENTERED_DIALOG_RIGHT_SCROLL_INDICATOR_X_OFFSET = -1
    dialog.rightStickScrollIndicatorOffsetX = GENERIC_CENTERED_DIALOG_RIGHT_SCROLL_INDICATOR_X_OFFSET

    local interactKeybindControl = dialog:GetNamedChild("InteractKeybind")

    local baseShownFunction = dialog.OnDialogShown
    dialog.OnDialogShown = function(dialog)
        baseShownFunction(dialog)

        for _, descriptor in ipairs(g_keybindGroupDesc) do
            if descriptor.keybind == "DIALOG_PRIMARY" then
                interactKeybindControl:SetKeybindButtonDescriptor(descriptor)
            end
        end
    end
end

local MIN_HEIGHT_SCROLL_WINDOW = 480
local MIN_HEIGHT_SCROLL_CONTAINER = 187
local EXPAND_HEIGHT_SCROLL_WINDOW = 210

function ZO_GenericCenteredGamepadDialogTemplate_Setup(dialog)
    dialog.headerData.titleTextAlignment = TEXT_ALIGN_CENTER
    ZO_GamepadGenericHeader_Refresh(dialog.header, dialog.headerData)

    local height = dialog:GetHeight()
    local scrollContentsHeight = dialog.mainTextControl:GetTextHeight() + dialog.scrollPadding:GetHeight()
    if scrollContentsHeight < MIN_HEIGHT_SCROLL_CONTAINER then
        height = MIN_HEIGHT_SCROLL_WINDOW
    elseif scrollContentsHeight < MIN_HEIGHT_SCROLL_CONTAINER + EXPAND_HEIGHT_SCROLL_WINDOW then
        height = MIN_HEIGHT_SCROLL_WINDOW + (scrollContentsHeight - MIN_HEIGHT_SCROLL_CONTAINER)
    else
        height = MIN_HEIGHT_SCROLL_WINDOW + EXPAND_HEIGHT_SCROLL_WINDOW
    end

    dialog:SetHeight(height)
end

-------------------------------------
-- Custom Centered Template --
-------------------------------------

function ZO_CustomCenteredGamepadDialogTemplate_OnInitialized(dialog)
    dialog.fragment = ZO_FadeSceneFragment:New(dialog)

    ZO_GenericGamepadDialog_OnInitialized(dialog)
end

-------------------------------------
-- Static List Dialog Template --
-------------------------------------

-- Dialog
function ZO_GenericGamepadStaticListDialogTemplate_OnInitialized(dialog)  
    ZO_GenericGamepadDialog_OnInitialized(dialog)
    dialog.setupFunc = ZO_GenericStaticListGamepadDialogTemplate_Setup

    local containerName = dialog.scrollChild:GetName()
    dialog.listHeaderControl = CreateControlFromVirtual(containerName .. "ListHeader", dialog.scrollChild, "ZO_GamepadStaticListHeader")

    dialog.entryPool = ZO_ControlPool:New("ZO_GamepadStaticListIconEntry", dialog.scrollChild, "Entry")
end

function ZO_GenericStaticListGamepadDialogTemplate_Setup(dialog, data)
    if data then
        ZO_GenericGamepadDialog_RefreshHeaderData(dialog, data)
    end

    dialog.entryPool:ReleaseAllObjects()

    local listEntryAnchorControl
    local entryRowSpacing = 11
    local entryContainerOffsetY = 70

    local listHeader = dialog.listHeader
    local listHeaderControl = dialog.listHeaderControl
    if listHeader then
        local listHeaderLabelControl = listHeaderControl.labelControl
        listHeaderLabelControl:SetText(listHeader)
        listHeaderControl:SetHidden(false)
        listHeaderControl:SetAnchor(TOPLEFT, dialog.mainTextControl, BOTTOMLEFT, 0, entryContainerOffsetY)
        listEntryAnchorControl = listHeaderControl
        entryRowSpacing = 24
    else
        listHeaderControl:SetHidden(true)
    end

    local itemInfo = dialog.info.itemInfo
    if type(itemInfo) == "function" then
        itemInfo = dialog.info.itemInfo(dialog)
    end

    for i, itemInfo in ipairs(itemInfo) do
        local entryControl = dialog.entryPool:AcquireObject()
        if listEntryAnchorControl then
            entryControl:SetAnchor(TOPLEFT, listEntryAnchorControl, BOTTOMLEFT, 0, entryRowSpacing) --there is a built in 4 tall spacer
        else
            entryControl:SetAnchor(TOPLEFT, dialog.mainTextControl, BOTTOMLEFT, 0, entryContainerOffsetY)
        end
        
        local iconControl = entryControl.iconControl
        local labelControl = entryControl.labelControl

        iconControl:SetTexture(itemInfo.icon)
        local iconSize = itemInfo.iconSize or 32
        iconControl:SetDimensions(iconSize, iconSize)
        if itemInfo.iconColor then
            iconControl:SetColor(itemInfo.iconColor:UnpackRGB())
        end

        labelControl:SetText(itemInfo.label)
        if itemInfo.labelFont then
            labelControl:SetFont(itemInfo.labelFont)
        end

        entryControl:SetHidden(false)

        listEntryAnchorControl = entryControl
        entryRowSpacing = 11
    end
end

-------------------------------------
-- Item Slider Dialog Template --
-------------------------------------

function ZO_GenericGamepadItemSliderDialogTemplate_OnInitialized(dialog)
    ZO_GenericGamepadDialog_OnInitialized(dialog)
    dialog.setupFunc = ZO_GenericGamepadItemSliderDialogTemplate_Setup

    local itemSliderContainer = dialog:GetNamedChild("ItemSlider")
    dialog.icon1 = itemSliderContainer:GetNamedChild("Icon1")
    dialog.icon2 = itemSliderContainer:GetNamedChild("Icon2")
    dialog.sliderValue1 = itemSliderContainer:GetNamedChild("SliderValue1")
    dialog.sliderValue2 = itemSliderContainer:GetNamedChild("SliderValue2")
    dialog.slider = itemSliderContainer:GetNamedChild("Slider")

    local baseShownFunction = dialog.OnDialogShown
    dialog.OnDialogShown =  function(dialog)
                                baseShownFunction(dialog)
                                dialog.slider:Activate()
                            end

    local baseHiddenFunction = dialog.OnDialogHidden
    dialog.OnDialogHidden =  function(dialog)
                                        baseHiddenFunction(dialog)
                                        dialog.slider:Deactivate()
                                    end
end

do
    local function DefaultOnSliderValueChanged(dialog, sliderControl, value)
        dialog.sliderValue1:SetText(dialog.data.sliderMax - value)
        dialog.sliderValue2:SetText(value)
    end

    function ZO_GenericGamepadItemSliderDialogTemplate_Setup(dialog, headerData)
        if headerData then
            ZO_GenericGamepadDialog_RefreshHeaderData(dialog, headerData)
        end

        local ValueChangedCallback = dialog.info.OnSliderValueChanged or DefaultOnSliderValueChanged

        dialog.slider.valueChangedCallback = function(sliderControl, value)
            SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
            ValueChangedCallback(dialog, sliderControl, value)
        end

        local dialogData = dialog.data

        dialog.slider:SetMinMax(dialogData.sliderMin, dialogData.sliderMax)
        dialog.slider:SetValue(dialogData.sliderStartValue)
        dialog.slider:SetValueStep(1)

        dialog.sliderValue1:SetHidden(false)
        dialog.sliderValue2:SetHidden(false)

        local icon = GetItemInfo(dialogData.bagId, dialogData.slotIndex)
        local hasIcon = icon ~= nil
        if hasIcon then
            dialog.icon1:SetTexture(icon)
            dialog.icon2:SetTexture(icon)
        end
        dialog.icon1:SetHidden(not hasIcon)
        dialog.icon2:SetHidden(not hasIcon)

        ValueChangedCallback(dialog, dialog.slider, dialogData.sliderStartValue)

    end
end

function ZO_GenericGamepadItemSliderDialogTemplate_GetSliderValue(dialog)
    return dialog.slider:GetValue()
end

-------------------------------------
-- Dialog Utility Global Functions --
-------------------------------------

function ZO_GenericGamepadDialog_Parametric_TextFieldFocusLost(control)
    ZO_GamepadEditBox_FocusLost(control)
    local paraDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    paraDialog.entryList:RefreshVisible()
    SCREEN_NARRATION_MANAGER:QueueDialog(paraDialog)
end

function ZO_GamepadTextFieldItem_OnInitialized(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    control.textFieldControl = control:GetNamedChild("TextField")
    control.editBoxControl = control.textFieldControl:GetNamedChild("Edit")
    control.textControl = control.editBoxControl:GetNamedChild("Text")
    control.highlight = control:GetNamedChild("Highlight")

    control.resetFunction = function()
        control.editBoxControl.textChangedCallback = nil
        control.editBoxControl.focusLostCallback = nil
        control.editBoxControl:SetText("")
    end
end