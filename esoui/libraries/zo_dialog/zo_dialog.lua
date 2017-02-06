local MAX_NUM_DIALOGS = 1
local NUM_DIALOG_BUTTONS = 2
local RELEASED_FROM_BUTTON_PRESS = true
local BUTTON_SPACING = 20

local displayedDialogs = {}
local dialogQueue = {}
local g_currencyPool = nil
local g_curInstanceId = 0

local QUEUED_DIALOG_INDEX_NAME = 1
local QUEUED_DIALOG_INDEX_DATA = 2
local QUEUED_DIALOG_INDEX_PARAMS = 3

local function QueueDialog(name, data, params, isGamepad, dialogInfo)
    if name and dialogInfo and dialogInfo.onlyQueueOnce then
        -- If the dialog is already queued and can only be queued once, don't requeue it
        for _, dialog in pairs(dialogQueue) do
            if dialog[QUEUED_DIALOG_INDEX_NAME] == name then
                return
            end
        end
    end

    name = name or ""
    data = data or {}
    params = params or {}
    table.insert(dialogQueue, {name, data, params, isGamepad})
end

local function ContainsName(testName, ...)
    for i = 1, select("#", ...) do
        local name = select(i, ...)
        if(name == testName) then
            return true
        end
    end
end

local function RemoveQueuedDialogs(name)
    local i = 1
    while(i <= #dialogQueue) do
        local dialog = dialogQueue[i]

        if(name == dialog[QUEUED_DIALOG_INDEX_NAME]) then
            table.remove(dialogQueue, i)
        else
            i = i + 1
        end
    end
end

local function RemoveQueuedDialogsExcept(...)
    local i = 1
    while(i <= #dialogQueue) do
        local dialog = dialogQueue[i]

        if(not ContainsName(dialog[QUEUED_DIALOG_INDEX_NAME], ...)) then
            table.remove(dialogQueue, i)
        else
            i = i + 1
        end
    end
end

local function GetDisplayedDialog()
    if(#displayedDialogs > 0) then
        return displayedDialogs[1].dialog
    end
end

local function HandleCallback(clickedButton)
    local dialog = GetDisplayedDialog()
    local instanceId = dialog.instanceId
    if(dialog) then
        if(clickedButton.m_callback) then
            clickedButton.m_callback(dialog)
        end

        --Make sure the dialog wasn't released and then reshown
        if(clickedButton.m_noReleaseOnClick == nil and dialog.instanceId == instanceId) then
            ZO_Dialogs_ReleaseDialog(dialog, RELEASED_FROM_BUTTON_PRESS)
        end
    end   
end

function ZO_Dialogs_SetupCustomButton(button, text, keybind, clickSound, callback)
    button:SetKeybind(keybind)
    button:SetText(text)
    button:SetClickSound(clickSound)
    button.m_callback = callback
end

local function GetDialog(isGamepad)
    local dialogBaseName = "ZO_Dialog"
    if isGamepad then
        dialogBaseName = "ZO_DialogGamepad"
    end

    for i = 1, MAX_NUM_DIALOGS do
        local dialog = GetControl(dialogBaseName..i)
        if(dialog:IsControlHidden()) then
            ZO_Dialogs_InitializeDialog(dialog, isGamepad)
            return dialog
        end
    end
    return nil
end

local function GetFormattedDialogText(text, params)
    if text then
        if params and #params > 0 then
            text = zo_strformat(text, unpack(params))
        elseif type(text) == "number" then
            text = GetString(text)
        end
    else
        text = ""
    end

    return text
end

local function GetFormattedText(dialog, textTable, params)
    if not textTable then
        return
    end

    local timer = textTable.timer
    if params and type(timer) == "number" and type(params[timer]) == "number" then
        local timerParam = params[timer]
        if textTable.verboseTimer then
            timerParam = ZO_FormatTimeMilliseconds(timerParam, TIME_FORMAT_STYLE_DESCRIPTIVE)
        else
            timerParam = ZO_FormatTimeMilliseconds(timerParam, TIME_FORMAT_STYLE_DESCRIPTIVE_SHORT_SHOW_ZERO_SECS)
        end
        params[timer] = timerParam
    end
    
    local textOrCallback = textTable.text
    local finalText
    if type(textOrCallback) == "function" then
        finalText = textOrCallback(dialog)
    else
        finalText = textOrCallback
    end

    local formattedText = GetFormattedDialogText(finalText, params)

    return formattedText
end

local function SetDialogTextFormatted(dialog, textControl, textTable, params)
    local formattedText = GetFormattedText(dialog, textTable, params)

    if not textControl or not formattedText then
        return
    end

    textControl:SetText(formattedText)
    textControl:SetHidden(false)

    if textTable.align then
        textControl:SetHorizontalAlignment(textTable.align)
    end

    return select(2, textControl:GetTextDimensions())
end

function ZO_Dialogs_SetDialogLoadingIcon(loadingIcon, textControl, showLoadingIconData)
    local shouldShowLoadingIcon = false
    local iconAnchor
    local showType = type(showLoadingIconData)
    
    if(showType == "boolean") then
        shouldShowLoadingIcon = showLoadingIconData
    elseif(showType == "table") then
        shouldShowLoadingIcon = true
        iconAnchor = showLoadingIconData
    end

    if(shouldShowLoadingIcon) then
        loadingIcon:Show()

        if(not iconAnchor) then
            local horizontalAlignment = textControl:GetHorizontalAlignment()
            loadingIcon:ClearAnchors()
            if(horizontalAlignment == TEXT_ALIGN_LEFT) then
                loadingIcon:SetAnchor(RIGHT, textControl, LEFT, -5, 0)
            elseif(horizontalAlignment == TEXT_ALIGN_RIGHT) then
                loadingIcon:SetAnchor(LEFT, textControl, RIGHT, 5, 0)
            else
                local textWidth = textControl:GetTextDimensions()            
                loadingIcon:SetAnchor(RIGHT, textControl, CENTER, -textWidth * 0.5 - 5, 0)
            end            
        else
            iconAnchor:Set(loadingIcon)
        end
    else
        loadingIcon:Hide()
    end
end

function ZO_Dialogs_FindDialog(name)
    for _, displayedDialog in ipairs(displayedDialogs) do
        if(displayedDialog.name == name) then
            return displayedDialog.dialog
        end
    end
    return nil
end

local function ReanchorDialog(dialog, isGamepad)
    if(not dialog) then
        return
    end
    
    local dialogNumber = dialog.id

    dialog:ClearAnchors()

    if isGamepad then
        if(dialogNumber == 1) then
            local dialogBackground = dialog:GetNamedChild("Bg")
            local anchor1 = ZO_GamepadGrid_GetNavAnchor(GAMEPAD_GRID_NAV1, 1)
            anchor1:AddToControl(dialogBackground)
            ZO_GamepadGrid_GetNavAnchor(GAMEPAD_GRID_NAV1, 2):AddToControl(dialogBackground)

            dialog:SetAnchor(LEFT, GuiRoot, LEFT, anchor1:GetOffsetX())
        end
    else
        if(dialogNumber == 1)
        then
            dialog:SetAnchor(CENTER, GuiRoot, CENTER, 0, -55)
        elseif(dialogNumber == 2)
        then
            dialog:SetAnchor(TOP, ZO_Dialog1, BOTTOM, 0, 24)
        elseif(dialogNumber == 3)
        then
            dialog:SetAnchor(BOTTOM, ZO_Dialog1, TOP, 0, -24)
        elseif(dialogNumber == 4)
        then
            dialog:SetAnchor(TOP, ZO_Dialog2, BOTTOM, 0, 24)
        end
    end
end

local function GetButtonControl(dialog, index)
    local dialogInfo = dialog.info
    if(index <= dialog.numButtons) then
        if(dialog.buttonControls) then
            return dialog.buttonControls[index]
        end

        if(dialogInfo.customControl and dialogInfo.buttons) then
            return dialogInfo.buttons[index].control
        end
    end
end

function ZO_Dialogs_ShowPlatformDialog(...)
    local dialogFn = IsInGamepadPreferredMode() and ZO_Dialogs_ShowGamepadDialog or ZO_Dialogs_ShowDialog
    dialogFn(...)
end

local function RefreshMainText(dialog, dialogInfo, textParams)
    if not textParams then
        textParams = {}
    end

    local mainText, textControl

    local isGamepadDialog = dialog.isGamepad and dialogInfo.gamepadInfo and dialogInfo.gamepadInfo.dialogType -- There is a legacy gamepad dialog still in use (for now).
    if isGamepadDialog then
        local title = GetFormattedText(dialog, dialogInfo.title, textParams.titleParams)
        mainText = GetFormattedText(dialog, dialogInfo.mainText, textParams.mainTextParams)
        ZO_GenericGamepadDialog_RefreshText(dialog, title, mainText)
    else
        textControl = dialog:GetNamedChild("Text")
        mainText = dialogInfo.mainText
        if textControl then
            if mainText then
                if type(mainText) == "function" then
                    dialog.mainText = mainText(dialog)
                else
                    dialog.mainText = mainText
                end

                if(dialog.mainText.lineSpacing) then
                    textControl:SetLineSpacing(dialog.mainText.lineSpacing)
                else
                    textControl:SetLineSpacing(0)
                end

                SetDialogTextFormatted(dialog, textControl, dialog.mainText, textParams.mainTextParams)
            else
                textControl:SetText(nil)
                textControl:SetHidden(true)
            end 
        end
    end

    return mainText, textControl
end


function ZO_Dialogs_RefreshDialogText(name, dialog, textParams)
    local dialogInfo = ESO_Dialogs[name]
    if(type(dialogInfo) ~= "table") then
        return
    end

    if(ZO_Dialogs_IsShowingDialog()) then
        RefreshMainText(dialog, dialogInfo, textParams)
    end
end 

-- To show a gamepad style sidebar dialog, call this function.
-- See comments about ZO_Dialogs_ShowDialog for more information
function ZO_Dialogs_ShowGamepadDialog(name, data, textParams)
    local IS_GAMEPAD = true
    local currentScene = SCENE_MANAGER:GetCurrentScene()
    local dialog = ESO_Dialogs[name]
    if currentScene and currentScene:IsShowing() then
        ZO_Dialogs_ShowDialog(name, data, textParams, IS_GAMEPAD)
    elseif dialog.gamepadInfo and dialog.gamepadInfo.allowShowOnNextScene and SCENE_MANAGER:GetNextScene() and not dialog.gamepadInfo.nextSceneCallback then
        --Only one of this type of dialog can be registered for the next scene at a time, first come first serve
        dialog.gamepadInfo.nextSceneCallback = function(scene, oldState, newState)
            if newState == SCENE_SHOWING or newState == SCENE_SHOWN then
                SCENE_MANAGER:UnregisterCallback("SceneStateChanged", dialog.gamepadInfo.nextSceneCallback)
                ZO_Dialogs_ShowGamepadDialog(name, data, textParams)
                dialog.gamepadInfo.nextSceneCallback = nil
            end
        end
        SCENE_MANAGER:RegisterCallback("SceneStateChanged", dialog.gamepadInfo.nextSceneCallback)
    else
        if dialog.noChoiceCallback then
            dialog.data = data
            dialog.noChoiceCallback(dialog)
        end
    end
end

-- To show a dialog, call this function. 
-- The first parameter should be the name of the dialog (as definied in either InGameDialogs or PreGameDialogs). 
-- The second parameter should be an array table, containing any data that will be needed in the callback functions in the dialog
--      you want to display. 
-- The third parameter is a table, which contains parameters used when filling out the strings in your dialog.
--
-- If the main text in the dialog has 2 parameters (e.g "Hello <<1>> <<2>>"), then the 3rd parameter should contain a subtable called
-- mainTextParams which itself contains 2 members, the first will go into the <<1>> and the second will go into the <<2>>. The 3rd parameter
-- in ZO_Dialogs_ShowDialog can also contain a titleParams subtable which is used to fill in the parameters in the title, if needed.
--
-- So as an example, let's say you had defined a dialog in InGameDialogs called "TEST_DIALOG" with
--      title = { text = "Dialog <<1>>" } and mainText = { text = "Main <<1>> Text <<2>>" }
-- And you called 
--      ZO_Dialogs_ShowDialog("TEST_DIALOG", {5}, {titleParams={"Test1"}, mainTextParams={"Test2", "Test3"}})
-- The resulting dialog would have a title that read "Dialog Test1" and a main text field that read "Main Test2 Text Test3".
-- The 5 passed in the second parameter could be used by the callback functions to perform various tasks based on this value.

-- Dialogs themselves (see InGameDialogs.lua, etc.) must contain at least a "mainText" table, with at least the "text" member.
-- mainText.text is filled in using the mainTextParams subtable of the table passed in the 3rd parameter to ZO_Dialogs_ShowDialog. 

-- The mainText table can also optionally contain:
-- An "align" member to set the alignment of the text (TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT, or TEXT_ALIGN_CENTER....left is default).
-- A "timer" field, which indicates that a certain parameter should be treated as a sceonds in a timer, and converted to time format
--      (so if mainText contains "timer = 1", the 1st parameter in mainText.text is converted to time format before being placed
--      in the string).
--
-- Dialogs can also optionally contain:
-- 
-- A "title" table, which works the same way as "mainText" ("text", "align" and "title" fields are allowed), no title is shown if "title" is not set.
-- A "noChoiceCallback" field, which is executed when the dialog is closed without making a choice first.
-- A "hideSound" field, which is a sound id to be played when the dialog is closed without selecting an option
-- An "updateFn" field, which should be a function. If present, this function is called on each update when this dialog is showing.
-- An "editBox" field, which adds an edit box to the dialog. It can specify:
--      textType = The type of input the edit box accepts.
--      To get the value in the editbox, use ZO_Dialogs_GetEditBoxText.
-- Finally, the is a "buttons" table, in which each member corresponds to a button. Dialogs support a maximum of 2 buttons.
-- If the buttons table is present, each of it's members in turn MUST contain a "text" field. Also, each button can optionally contain:
--      A "callback" function field (whose first parameter should always be "dialog"....use "dialog.data[i]" to reference the ith data member passed in).
--      A "clickSound" field that defines what sound to play when the button is clicked.
-- An option to show an animated loading icon near the main text, called "showLoadingIcon"
--
-- See the "DESTROY_AUGMENT_PROMPT" and "DEATH_PROMPT" dialogs in InGameDialogs.lua for examples of dialogs that use these various fields.
function ZO_Dialogs_ShowDialog(name, data, textParams, isGamepad)
    -- Get the dialog info from the ESO_Dialogs table
    local dialogInfo = ESO_Dialogs[name]
    if(type(dialogInfo) ~= "table") then
        return nil
    end
    
    if(ZO_Dialogs_IsShowingDialog()) then
        if(dialogInfo.canQueue) then
            QueueDialog(name, data, textParams, isGamepad, dialogInfo)
        end
        return nil
    end

    --Acquire Dialog Control
    ------------------------------
    local dialog

    local isGamepadDialog = isGamepad and dialogInfo.gamepadInfo and dialogInfo.gamepadInfo.dialogType  -- There is a legacy gamepad dialog still in use (for now).
    local isGenericGamepadDialog = isGamepadDialog and dialogInfo.gamepadInfo.dialogType ~= GAMEPAD_DIALOGS.CUSTOM
    if isGenericGamepadDialog then
        dialog = ZO_GenericGamepadDialog_GetControl(dialogInfo.gamepadInfo.dialogType)

        if not dialog then
            return nil
        end
    elseif dialogInfo.customControl then
        if type(dialogInfo.customControl) == "function" then
            dialog = dialogInfo.customControl()
        else
            dialog = dialogInfo.customControl
        end

        if not dialog then
            return nil
        end
    else
        dialog = GetDialog(isGamepad)

        if not dialog then
            -- Dialog can't be created right now, so place it in a queue to be created later
            QueueDialog(name, data, textParams, isGamepad)
            return nil
        end
    end

    dialog.isGamepad = isGamepad

    --Shared Init
    ------------------

    --Clear focus in case the dialog came up when we had an edit control focused.
    WINDOW_MANAGER:SetFocusByName()

    dialog.info = dialogInfo
    dialog.data = data
    dialog.textParams = textParams

    --Title

    local titleControl = dialog:GetNamedChild("Title")
    local divider = dialog:GetNamedChild("Divider")
    local title = dialogInfo.title

    if not textParams then
        textParams = {}
    end

    if title then
        SetDialogTextFormatted(dialog, titleControl, title, textParams.titleParams)
    elseif titleControl and isGamepad then
        SetDialogTextFormatted(dialog, titleControl, "")
    end

    --Buttons

    local buttonInfos = dialogInfo.buttons
    local numButtonInfos = buttonInfos and #buttonInfos or 0
    dialog.numButtons = numButtonInfos
    if(numButtonInfos > 0 and not isGamepadDialog) then
        for i = 1, numButtonInfos do
            local buttonInfo = buttonInfos[i]
            local button = GetButtonControl(dialog, i)

            local buttonVisible = true
            if buttonInfo.visible ~= nil then
                if type(buttonInfo.visible) == "function" then
                    buttonVisible = buttonInfo.visible(dialog)
                else
                    buttonVisible = buttonInfo.visible
                end
            end

            if(not buttonVisible) then
                button:SetHidden(true)
                button:SetKeybindEnabled(false)
            else
                if textParams and textParams.buttonTextOverrides and textParams.buttonTextOverrides[i] then
                    button:SetText(textParams.buttonTextOverrides[i])    
                elseif(type(buttonInfo.text) == "number") then
                    button:SetText(GetString(buttonInfo.text))
                elseif(type(buttonInfo.text) == "function") then
                    button:SetText(buttonInfo.text(dialog))
                else
                    button:SetText(buttonInfo.text)
                end

                button:SetHidden(false)
                button.m_callback = buttonInfo.callback 
                button.m_noReleaseOnClick = buttonInfo.noReleaseOnClick
                
                local keybind
                local hasKeybind = true
                if(buttonInfo.keybind) then
                    keybind = buttonInfo.keybind
                elseif(buttonInfo.keybind == nil) then
                    if(i == 1) then
                        keybind = "DIALOG_PRIMARY"
                    else
                        keybind = "DIALOG_NEGATIVE"
                    end
                else
                    hasKeybind = false
                end

                button:SetKeybindEnabled(hasKeybind)
                button:SetKeybind(keybind)

                if(buttonInfo.clickSound) then
                    button:SetClickSound(buttonInfo.clickSound)
                else
                    if(keybind == "DIALOG_NEGATIVE") then
                        button:SetClickSound(SOUNDS.DIALOG_DECLINE)
                    else
                        button:SetClickSound(SOUNDS.DIALOG_ACCEPT)
                    end
                end

                if(buttonInfo.requiresTextInput) then
                    dialog.requiredTextFields:AddButton(button)
                end 
            end
        end
    end

    --Custom Init
    if dialogInfo.customControl or isGamepadDialog then
        RefreshMainText(dialog, dialogInfo, textParams)
        if dialogInfo.setup then
            dialogInfo.setup(dialog, data)
        end
    else
        local mainText, textControl = RefreshMainText(dialog, dialogInfo, textParams)

        if not mainText then
            return nil
        end   
        
        ZO_Dialogs_SetDialogLoadingIcon(dialog.loadingIcon, textControl, dialogInfo.showLoadingIcon)

        local modalUnderlay = dialog:GetNamedChild("ModalUnderlay")
        if modalUnderlay then
            if dialogInfo.modal == nil or dialogInfo.modal then
                modalUnderlay:SetHidden(false)
            else
                modalUnderlay:SetHidden(true)
            end
        end

        local controlAbove = textControl
        
        if(dialogInfo.editBox) then
            local editControl = dialog:GetNamedChild("EditBox")
            local editContainer = dialog:GetNamedChild("Edit")
            local editBoxInfo = dialogInfo.editBox

            editContainer:SetAnchor(TOPLEFT, controlAbove, BOTTOMLEFT, 0, 10)
            editContainer:SetAnchor(TOPRIGHT, controlAbove, BOTTOMRIGHT, 0, 10)
            editContainer:SetHidden(false)

            if(editBoxInfo.textType) then
                editControl:SetTextType(editBoxInfo.textType)

                if editBoxInfo.specialCharacters then
                    for _, character in pairs(editBoxInfo.specialCharacters) do
                        editControl:AddValidCharacter(character)
                    end
                else
                    editControl:RemoveAllValidCharacters()
                end
            else
                editControl:SetTextType(TEXT_TYPE_ALL)
            end

            if(editBoxInfo.maxInputCharacters) then
                editControl:SetMaxInputChars(editBoxInfo.maxInputCharacters)
            else
                editControl:SetMaxInputChars(128)
            end

            if(editBoxInfo.defaultText) then
                ZO_EditDefaultText_Initialize(editControl, GetString(editBoxInfo.defaultText))
            else
                ZO_EditDefaultText_Disable(editControl)
            end

            if editBoxInfo.autoComplete then
                if editControl.autoComplete then
                    editControl.autoComplete:SetEnabled(true)
                else
                    editControl.autoComplete = ZO_AutoComplete:New(editControl)
                end

                editControl.autoComplete:SetIncludeFlags(editBoxInfo.autoComplete.includeFlags)
                editControl.autoComplete:SetExcludeFlags(editBoxInfo.autoComplete.excludeFlags)
                editControl.autoComplete:SetOnlineOnly(editBoxInfo.autoComplete.onlineOnly)
                editControl.autoComplete:SetMaxResults(editBoxInfo.autoComplete.maxResults)
            else
                if editControl.autoComplete then
                    editControl.autoComplete:SetEnabled(false)
                end
            end

            if not editControl.instructions then
                editControl.instructions = ZO_ValidNameInstructions:New(editContainer:GetNamedChild("Instructions"))
            end
            editControl.instructions:Hide()

            if editBoxInfo.validatesText and editBoxInfo.validator then
                editControl.validator = editBoxInfo.validator
            else
                editControl.validator = nil
            end
            
            if(editBoxInfo.matchingString) then
                dialog.requiredTextFields:SetMatchingString(editBoxInfo.matchingString)
            end

            controlAbove = editControl
        end

        local radioButtonContainer = dialog:GetNamedChild("RadioButtonContainer")
        dialog.radioButtonPool:ReleaseAllObjects()
        dialog.radioButtonGroup:Clear()
        radioButtonContainer:SetHidden(true)

        if(dialogInfo.radioButtons) then
            radioButtonContainer:SetHidden(false)
            radioButtonContainer:SetAnchor(TOPLEFT, controlAbove, BOTTOMLEFT, 0, 15)
            radioButtonContainer:SetAnchor(TOPRIGHT, controlAbove, BOTTOMRIGHT, 0, 15)

            local prev
            for i = 1, #dialogInfo.radioButtons do
                local buttonInfo = dialogInfo.radioButtons[i]
                local radioButton = dialog.radioButtonPool:AcquireObject()
                dialog.radioButtonGroup:Add(radioButton)

                local label = GetControl(radioButton, "Label")
                label:SetText(buttonInfo.text)
                radioButton.data = buttonInfo.data

                if(i == 1) then
                    dialog.radioButtonGroup:SetClickedButton(radioButton)
                    radioButton:SetAnchor(TOPLEFT, nil, TOPLEFT, 15, 0)
                else
                    radioButton:SetAnchor(TOPLEFT, prev, BOTTOMLEFT, 0, 10)
                end

                prev = radioButton
            end

            controlAbove = radioButtonContainer
        end
            
        -- Handle button centering
        local btn1 = dialog:GetNamedChild("Button1")
        local btn2 = dialog:GetNamedChild("Button2")
        
        if(numButtonInfos == 0) then -- Hide both buttons
            btn1:SetHidden(true)
            btn2:SetHidden(true)
        elseif(numButtonInfos == 1) then -- Only show one
            btn2:SetHidden(true)

            btn1:ClearAnchors()
            if isGamepad then
                btn1:SetAnchor(TOPLEFT, controlAbove, BOTTOMLEFT, 0, 23)
            else
                btn1:SetAnchor(TOPRIGHT, controlAbove, BOTTOMRIGHT, 0, 23)
            end
        elseif(numButtonInfos == 2) then -- Show both
            btn2:ClearAnchors()
            btn1:ClearAnchors()
            if isGamepad then
                btn1:SetAnchor(TOPLEFT, controlAbove, BOTTOMLEFT, 0, 23)
                btn2:SetAnchor(TOPLEFT, btn1, TOPRIGHT, BUTTON_SPACING, 0)
            else
                btn2:SetAnchor(TOPRIGHT, controlAbove, BOTTOMRIGHT, 0, 23)
                btn1:SetAnchor(TOPRIGHT, btn2, TOPLEFT, -BUTTON_SPACING, 0)
            end

        end

        if(dialogInfo.callback) then
            -- Pass in the id of the dialog being shown for this purpose.
            -- It can (eventually) be used to track this particular dialog instance.
            dialogInfo.callback(dialog.id)
        end
    end

    dialog:SetHandler("OnUpdate", dialogInfo.updateFn)

    table.insert(displayedDialogs, {name = name, dialog = dialog})
    
    if not isGamepad then
        if(SCENE_MANAGER.RegisterTopLevel) then
            SCENE_MANAGER:RegisterTopLevel(dialog, TOPLEVEL_LOCKS_UI_MODE)        
            SCENE_MANAGER:ShowTopLevel(dialog)
        else
            dialog:SetHidden(false)
        end
    else
        ZO_GenericGamepadDialog_Show(dialog)
    end

    -- Append the keybind state index to the dialog so that it knows where its keybinds sit on the keybind stack
    dialog.keybindStateIndex = KEYBIND_STRIP:GetTopKeybindStateIndex()

    g_hasFocusEdit = nil

    dialog.name = name
    dialog:BringWindowToTop()
    if not isGamepadDialog then
        PlaySound(SOUNDS.DIALOG_SHOW)
    end

    --edit controls cant take focus when hidden
    if(dialogInfo.editBox) then
        dialog:GetNamedChild("EditBox"):TakeFocus()
    end

    return dialog
end

function ZO_TwoButtonDialog_OnInitialized(self, id)
    self.id = id
    self.requiredTextFields = ZO_RequiredTextFields:New()
    self.requiredTextFields:AddTextField(GetControl(self, "EditBox"))
    self.radioButtonGroup = ZO_RadioButtonGroup:New()
    self.radioButtonPool = ZO_ControlPool:New("ZO_DialogRadioButton", self:GetNamedChild("RadioButtonContainer"), "RadioButton")
    self.buttonControls = { GetControl(self, "Button1"), GetControl(self, "Button2") }
    self.loadingIcon = GetControl(self, "Loading")
end

function ZO_Dialogs_InitializeDialog(dialog, isGamepad)
    ReanchorDialog(dialog, isGamepad)

    local textControl = dialog:GetNamedChild("Text")
    local button1Control = dialog:GetNamedChild("Button1")
    local button2Control = dialog:GetNamedChild("Button2")
    local buttonExtraText1Control = dialog:GetNamedChild("ButtonExtraText1")
    local buttonExtraText2Control = dialog:GetNamedChild("ButtonExtraText2")
    local editContainer = dialog:GetNamedChild("Edit")
    local editControl = dialog:GetNamedChild("EditBox")

    textControl:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    buttonExtraText1Control:SetHidden(true)
    buttonExtraText2Control:SetHidden(true)
    button1Control:SetState(BSTATE_NORMAL, false)
    button2Control:SetState(BSTATE_NORMAL, false)
    button1Control:SetKeybindEnabled(true)
    button2Control:SetKeybindEnabled(true)
    editContainer:SetHidden(true)
    editControl:SetText("")
    editControl:LoseFocus()
       
    if(not g_currencyPool) then
        g_currencyPool = ZO_ControlPool:New("ZO_CurrencyTemplate", dialog, "Currency")
    end
    dialog.buttonCostKeys = {}
    dialog.currencyKey = nil
    dialog.requiredTextFields:ClearButtons()
    dialog.requiredTextFields:SetMatchingString(nil)

    dialog.instanceId = g_curInstanceId
    g_curInstanceId = g_curInstanceId + 1
end

function ZO_Dialogs_IsShowingDialog()
    return #displayedDialogs > 0
end

function ZO_Dialogs_ReleaseAllDialogsOfName(name)
    RemoveQueuedDialogs(name)

    local i = 1
    while i <= #displayedDialogs do
        local displayedDialog = displayedDialogs[i]
        local released = false
        if displayedDialog.name == name then
            released = ZO_Dialogs_ReleaseDialog(displayedDialog.dialog)
        end

        -- Gamepad dialogs don't get removed from the table until after they're done hiding, so we can safely advance the index
        if not released or displayedDialog.dialog.isGamepad then
            i = i + 1
        end
    end
end

function ZO_Dialogs_ReleaseAllDialogsExcept(...)
    RemoveQueuedDialogsExcept(...)

    local i = 1
    while(i <= #displayedDialogs) do
        local displayedDialog = displayedDialogs[i]
        local released = false
        if(not ContainsName(displayedDialog.name, ...)) then
            released = ZO_Dialogs_ReleaseDialog(displayedDialog.dialog)
        end

        -- Gamepad dialogs don't get removed from the table until after they're done hiding, so we can safely advance the index
        if not released or displayedDialog.dialog.isGamepad then
            i = i + 1
        end
    end
end

function ZO_Dialogs_ReleaseDialogOnButtonPress(nameOrDialog)
    return ZO_Dialogs_ReleaseDialog(nameOrDialog, RELEASED_FROM_BUTTON_PRESS)
end

function ZO_Dialogs_ReleaseDialog(nameOrDialog, releasedFromButton)
    local dialog
    if type(nameOrDialog) == "string" then
        dialog = ZO_Dialogs_FindDialog(nameOrDialog)
    else
        dialog = nameOrDialog
    end

    if dialog == nil then
        -- This dialog is not currently visible
        return false
    end

    if dialog.hiding then
        return false
    end

    dialog.hiding = true

    if dialog.isGamepad then
        --Gamepad dialog will release when it's finished hiding
        dialog.hideFunction(dialog, releasedFromButton)
    else
        --Keyboard dialogs will hide instantly
        if SCENE_MANAGER.HideTopLevel then
            SCENE_MANAGER:HideTopLevel(dialog)
        else
            dialog:SetHidden(true)
        end
        ZO_CompleteReleaseDialogOnDialogHidden(dialog, releasedFromButton)
    end
    
    return true  
end

function ZO_CompleteReleaseDialogOnDialogHidden(dialog, releasedFromButton)
    dialog.hiding = false
    
    local name = dialog.name
    local dialogInfo = dialog.info

    if(not dialogInfo.customControl) then    
        dialog:SetHandler("OnUpdate", nil)

        for i = 1, NUM_DIALOG_BUTTONS do
            local btn = dialog:GetNamedChild("Button"..i)
            if(btn) then
                btn.m_callback = nil
                btn.m_noReleaseOnClick = nil
            end

            if(dialog.buttonCostKeys and dialog.buttonCostKeys[i]) then
                g_currencyPool:ReleaseObject(dialog.buttonCostKeys[i])
                dialog.buttonCostKeys[i] = nil
            end
        end
    
        if(dialog.currencyKey) then
            g_currencyPool:ReleaseObject(dialog.currencyKey)
            dialog.currencyKey = nil
        end        
    end

    dialog.name = nil

    for _, displayedDialog in ipairs(displayedDialogs) do
        if(displayedDialog.name == name) then
            table.remove(displayedDialogs, i)
            break
        end
    end

    if(dialogInfo.noChoiceCallback and not releasedFromButton) then
        dialogInfo.noChoiceCallback(dialog)
    end

    if next(dialogQueue) then
        local currentScene = SCENE_MANAGER:GetCurrentScene()
        local state = currentScene and currentScene:GetState()
        if state == SCENE_HIDING or state == SCENE_HIDDEN or not state then
            ZO_Dialogs_ReleaseAllDialogs(true)
        end
    end

    if dialogInfo.finishedCallback then
        dialogInfo.finishedCallback(dialog)
    end

    -- Show next dialog in queue
    local queuedDialog = table.remove(dialogQueue, 1)

    if(queuedDialog) then
        ZO_Dialogs_ShowDialog(unpack(queuedDialog))
    else
        if(not ZO_Dialogs_IsShowingDialog()) then
            CALLBACK_MANAGER:FireCallbacks("AllDialogsHidden")
        end
    end
end


function ZO_Dialogs_ReleaseAllDialogs(forceAll)
    for _, dialog in pairs(dialogQueue) do
        local dialogInfo = ESO_Dialogs[dialog[QUEUED_DIALOG_INDEX_NAME]]
        if dialogInfo and dialogInfo.removedFromQueueCallback then
            dialogInfo.removedFromQueueCallback(dialog[QUEUED_DIALOG_INDEX_DATA])
        end
    end

    dialogQueue = {}

    for i = #displayedDialogs, 1, -1 do
        local dialog = displayedDialogs[i].dialog
        if dialog and (forceAll or not dialog.info.mustChoose) then
            ZO_Dialogs_ReleaseDialog(dialog)
        end
    end
end

function ZO_Dialogs_IsDialogHiding(dialog)
    if type(dialog) == "string" then
        dialog = ZO_Dialogs_FindDialog(dialog)
    end

    return dialog and dialog.hiding
end

-- If textTable is nil, the default mainText table (defined in the ESO_Dialogs table) is used
function ZO_Dialogs_UpdateDialogMainText(dialog, textTable, params)
    if dialog then
        if dialog.isGamepad then
            if dialog.info and dialog.headerData then
                textTable = textTable or dialog.info.mainText

                local mainText = GetFormattedText(dialog, textTable, params)
                if mainText and mainText ~= "" then
                    ZO_GenericGamepadDialog_RefreshText(dialog, dialog.headerData.titleText, mainText)
                end
            end
        else
            local textControl = dialog:GetNamedChild("Text")
            if(textTable) then
                dialog.mainText = textTable
            end
        
            SetDialogTextFormatted(dialog, textControl, dialog.mainText, params)
        end
    end
end

function ZO_Dialogs_UpdateDialogTitleText(dialog, textTable, params)
    if dialog then
        local titleControl = dialog:GetNamedChild("Title")
        if titleControl then
            dialog.title = textTable
        end
        
        SetDialogTextFormatted(dialog, titleControl, dialog.title, params)
    end
end

function ZO_Dialogs_GetEditBoxText(dialog)
    if(dialog) then
        local editControl = dialog:GetNamedChild("EditBox")
    
        if(not editControl:IsHidden()) then
            return editControl:GetText()
        end        
    end   
    
    return nil
end

function ZO_Dialogs_GetSelectedRadioButtonData(dialog)
    local clickedButton = dialog.radioButtonGroup:GetClickedButton()
    if(clickedButton) then
        return clickedButton.data
    end
end

-- Activate or deactivate a button...use BSTATE_NORMAL to activate and BSTATE_DISABLED to deactivate
function ZO_Dialogs_UpdateButtonState(dialog, buttonNumber, buttonState)
    if(dialog and buttonNumber) then
        local buttonControl = dialog:GetNamedChild("Button"..buttonNumber)
        local lockButton = false
        if(buttonState == BSTATE_DISABLED) then
            lockButton = true
        end
        buttonControl:SetState(buttonState, lockButton)
    end
end

-- Update the text on a button itself
function ZO_Dialogs_UpdateButtonText(dialog, buttonNumber, text)
    if(dialog and buttonNumber) then
        local buttonControl = dialog:GetNamedChild("Button"..buttonNumber)
        if(text) then
            if(type(text) == "number") then
                text = GetString(text)
            end
            buttonControl:SetText(text)
        end
    end
end

-- Update the text underneath a button...if textTable is nil, this extra text control is hidden
function ZO_Dialogs_UpdateButtonExtraText(dialog, buttonNumber, textTable, params)
    if dialog and buttonNumber then
        local textControl = dialog:GetNamedChild("ButtonExtraText"..buttonNumber)
        if textTable then
            SetDialogTextFormatted(dialog, textControl, textTable, params)
            textControl:SetHidden(false)
        else
            textControl:SetHidden(true)
        end
    end
end

-- Update the currency control underneath a button
function ZO_Dialogs_UpdateButtonCost(dialog, buttonNumber, cost)
    if(dialog)
    then
        local buttonCostsShown = 0
        for i = 1,NUM_DIALOG_BUTTONS do
            if(dialog.buttonCostKeys[i]) then
                buttonCostsShown = buttonCostsShown + 1
            end
        end

        if(cost) then
            local textControl = dialog:GetNamedChild("ButtonExtraText"..buttonNumber)
            local buttonControl = dialog:GetNamedChild("Button"..buttonNumber)
            
            local currencyControl
            local key = dialog.buttonCostKeys[buttonNumber]
            if(key) then
                currencyControl = g_currencyPool:AcquireObject(key)
            else
                local newCurrencyControl, newCurrencyKey = g_currencyPool:AcquireObject()
                newCurrencyControl:SetParent(dialog)
                dialog.buttonCostKeys[buttonNumber] = newCurrencyKey
                currencyControl = newCurrencyControl
            end    
            
            ZO_CurrencyControl_SetSimpleCurrency(currencyControl, CURT_MONEY, cost, nil, CURRENCY_DONT_SHOW_ALL)
            local visibleCurrencyWidth = currencyControl:GetWidth()
            if(textControl:IsHidden()) then
                currencyControl:SetAnchor(TOPLEFT, buttonControl, BOTTOM, -visibleCurrencyWidth / 2, 5)
            else
                currencyControl:SetAnchor(TOPLEFT, textControl, BOTTOM, -visibleCurrencyWidth / 2, 5)
            end

            currencyControl:SetHidden(false)
        else
            local key = dialog.buttonCostKeys[buttonNumber]
            if(key) then
                self:ReleaseObject(key)
                dialog.buttonCostKeys[buttonNumber] = nil
            end
        end
    end
end

function ZO_Dialogs_IsShowing(name)
    for _, displayedDialog in ipairs(displayedDialogs) do
        if(displayedDialog.name == name) then
            return true
        end
    end
    
    return false
end

function ZO_Dialogs_IsDialogRegistered(name)
    local dialogInfo = ESO_Dialogs[name]
    return dialogInfo and (type(dialogInfo) == "table")
end

function ZO_Dialogs_RegisterCustomDialog(name, info)
    ESO_Dialogs[name] = info
end

function ZO_Dialogs_CloseKeybindPressed()
    local dialog = GetDisplayedDialog()
    if(dialog) then
        if not dialog.info.mustChoose then
            if not ZO_Dialogs_ReleaseDialog(dialog.name, not RELEASED_FROM_BUTTON_PRESS) then
                dialog:SetHidden(true)
            end
            if(dialog.info.hideSound) then
                PlaySound(dialog.info.hideSound)
            else
                if not dialog.isGamepad then
                    PlaySound(SOUNDS.DIALOG_HIDE)
                end
            end
            
            if(dialog.isGamepad) then
                ShowRemoteBaseScene()
            end
        end
    end
end

function ZO_Dialogs_HandleButtonForKeybind(dialog, keybind)
    local handledButton = false
    for i = 1, dialog.numButtons do
        local btn = GetButtonControl(dialog, i)
        if(btn ~= nil and btn:IsEnabled() and btn:GetKeybind() == keybind) then
            btn:OnClicked()
            handledButton = true
            break
        end
    end

    return handledButton
end

function ZO_Dialogs_ButtonKeybindPressed(keybind)
    local dialog = GetDisplayedDialog()
    if(dialog) then
        local handledButton = ZO_Dialogs_HandleButtonForKeybind(dialog, keybind)

        if(not handledButton and IsInGamepadPreferredMode()) then
            if(ZO_KeybindStrip_HandleKeybindDown(keybind)) then
                if(not dialog.info.blockDialogReleaseOnPress) then
                    ZO_Dialogs_ReleaseDialogOnButtonPress(dialog.name)
                end
            end
        end
    end
end

function ZO_Dialogs_ButtonKeybindReleased(keybind)
    local dialog = GetDisplayedDialog()
    if(dialog) then
        local handledButton = ZO_Dialogs_HandleButtonForKeybind(dialog, keybind)

        if(not handledButton) then
            ZO_KeybindStrip_HandleKeybindUp(keybind) 
        end
    end
end

function ZO_DialogButton_OnInitialized(self)
    ZO_KeybindButtonTemplate_OnInitialized(self)
    self:SetCallback(HandleCallback)
end

function ZO_CustomDialogButton_OnInitialized(self)
    ZO_DialogButton_OnInitialized(self)

    local parent = self:GetParent()
    local maxButtonIndex
    local maxButton
    for i = 1, parent:GetNumChildren() do
        local child = parent:GetChild(i)
        local customButtonIndex = child.customButtonIndex
        if(customButtonIndex ~= nil) then
            if(maxButtonIndex == nil or customButtonIndex > maxButtonIndex) then
                maxButtonIndex = customButtonIndex
                maxButton = child
            end
        end
    end

    if(maxButton) then
        self:SetAnchor(TOPRIGHT, maxButton, TOPLEFT, -BUTTON_SPACING, 0)
    else
        self:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -25, -15)
    end

    if(maxButtonIndex) then
        self.customButtonIndex = maxButtonIndex + 1
    else
        self.customButtonIndex = 1
    end
end

function ZO_TwoButtonDialogEditBox_OnTextChanged(control)
    ZO_EditDefaultText_OnTextChanged(control)

    if control.instructions then
        if control.validator then
            local violations = {control.validator(control:GetText())}
            local noViolations = #violations == 0
            if noViolations then
                control.instructions:Hide()
            else
                control.instructions:Show(nil, violations)
            end
        else
            control.instructions:Hide()
        end
    end
end
