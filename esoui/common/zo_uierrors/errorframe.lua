--
--[[ ZO_ErrorFrame ]]--
--

local ZO_ErrorFrame = ZO_InitializingObject:Subclass()

function ZO_ErrorFrame:Initialize(control)
    self.control = control
    self.textEditControl = control:GetNamedChild("TextEdit")
    self.titleControl = control:GetNamedChild("HeaderTitle")
    self.footerRow1 = control:GetNamedChild("FooterRow1")
    self.footerRow2 = control:GetNamedChild("FooterRow2")

    self.closeButton = control:GetNamedChild("Close")
    self.copyErrorCodeButton = control:GetNamedChild("CopyCode")

    self.moreInfoContainer = self.footerRow1:GetNamedChild("MoreInfo")
    self.moreInfoCheckButton = self.moreInfoContainer:GetNamedChild("CheckButton")
    ZO_CheckButton_SetToggleFunction(self.moreInfoCheckButton, function()
        self:ToggleMoreInfo()
    end)

    self.pageSpinnerControl = self.footerRow1:GetNamedChild("PageSpinner")
    ZO_KeyControl_OnInitialized(self.pageSpinnerControl:GetNamedChild("Decrease"))
    ZO_KeyControl_OnInitialized(self.pageSpinnerControl:GetNamedChild("Increase"))
    self.pageSpinner = ZO_SpinnerWithLabels:New(self.pageSpinnerControl)
    self.pageSpinner:SetValueFormatFunction(function(value)
        local maxValue = self.pageSpinner:GetMax()
        return zo_strformat(SI_UI_ERROR_PAGE_FORMATTER, value, maxValue)
    end)

    self.pageSpinner:RegisterCallback("OnValueChanged", function(newValue)
        self:RefreshPageSpinner()
        --If we are currently displaying the error frame, set the currently viewed error to the new value
        if self.displayingError then
            self:SetCurrentError(newValue)
        end
    end)

    self.control:SetHandler("OnUpdate", function()
        --If the UI Error action layer is not currently on top, remove and re-add it so it is on top again
        if self.displayingError and not IsActionLayerTopLayerByName("UIError") then
            RemoveActionLayerByName("UIError")
            PushActionLayerByName("UIError")
        end
    end)

    self.currentErrors = {}
    self.suppressedErrors = {}
    self.suppressErrorDialog = false
    self.displayingError = false
    self.advancedMode = ShouldShowAdvancedUIErrors()

    self.moreInfo = GetCVar("UIErrorShowMoreInfo") == "1"
    ZO_CheckButton_SetCheckState(self.moreInfoCheckButton, self.moreInfo)

    self:InitializeKeybinds()
    self:InitializePlatformStyles()
    self:InitializeNarrationInfo()

    EVENT_MANAGER:RegisterForEvent("ErrorFrame", EVENT_LUA_ERROR, function(eventCode, ...) self:OnUIError(...) end)
end

function ZO_ErrorFrame:InitializeKeybinds()
    self.copyKeybind = self.footerRow2:GetNamedChild("Copy")
    self.dismissKeybind = self.footerRow2:GetNamedChild("CenterParentDismiss")
    self.suppressKeybind = self.footerRow2:GetNamedChild("CenterParentSuppress")
    self.reloadKeybind = self.footerRow2:GetNamedChild("Reload")
    self.moreInfoKeybind = self.moreInfoContainer:GetNamedChild("KeybindButton")
    self.decreaseKeyLabel = self.pageSpinnerControl:GetNamedChild("DecreaseKeyLabel")
    self.increaseKeyLabel = self.pageSpinnerControl:GetNamedChild("IncreaseKeyLabel")

    self.dismissKeybindDescriptor =
    {
        keybind = "UI_ERROR_DISMISS",
        name = GetString(SI_DISMISS_UI_ERROR),
        callback = function()
            self:DismissErrors()
        end,
    }
    self.dismissKeybind:SetKeybindButtonDescriptor(self.dismissKeybindDescriptor)

    self.suppressKeybindDescriptor =
    {
        keybind = "UI_ERROR_SUPPRESS",
        name = GetString(SI_UI_ERROR_SUPPRESS),
        callback = function()
            self:SuppressErrors()
        end,
    }
    self.suppressKeybind:SetKeybindButtonDescriptor(self.suppressKeybindDescriptor)

    self.reloadKeybindDescriptor =
    {
        keybind = "UI_ERROR_RELOAD_UI",
        name = GetString(SI_UI_ERROR_RELOAD_UI),
        callback = function()
            if ZO_IsInternalIngameUI() then
                --Passing in "ingame" will reload both ingame *and* internal ingame
                ReloadUI("ingame")
            else
                ReloadUI()
            end
        end,
    }
    self.reloadKeybind:SetKeybindButtonDescriptor(self.reloadKeybindDescriptor)

    self.copyKeybindDescriptor =
    {
        keybind = "UI_ERROR_COPY",
        name = GetString(SI_UI_ERROR_COPY),
        callback = function()
            self:CopyErrorToClipboard()
        end,
    }
    self.copyKeybind:SetKeybindButtonDescriptor(self.copyKeybindDescriptor)

    self.moreInfoKeybindDescriptor =
    {
        keybind = "UI_ERROR_MORE_INFO",
        name = function()
            if self.moreInfo then
                return GetString(SI_UI_ERROR_LESS_INFO)
            else
                return GetString(SI_UI_ERROR_MORE_INFO)
            end
        end,
        callback = function()
            self:ToggleMoreInfo()
        end,
    }
    self.moreInfoKeybind:SetKeybindButtonDescriptor(self.moreInfoKeybindDescriptor)


    --These two are clickable keybind labels, NOT keybind buttons
    self.increaseKeyLabelDescriptor =
    {
        keybind = "UI_ERROR_PAGE_RIGHT",
        callback = function()
            self:CycleRight()
        end,
    }
    self.increaseKeyLabel:SetKeybindButtonDescriptor(self.increaseKeyLabelDescriptor)

    self.decreaseKeyLabelDescriptor =
    {
        keybind = "UI_ERROR_PAGE_LEFT",
        callback = function()
            self:CycleLeft()
        end,
    }
    self.decreaseKeyLabel:SetKeybindButtonDescriptor(self.decreaseKeyLabelDescriptor)
end

function ZO_ErrorFrame:ToggleMoreInfo()
    if self.advancedMode then
        self.moreInfo = not self.moreInfo
        SetCVar("UIErrorShowMoreInfo", self.moreInfo and "1" or "0")
        --Re-apply the descriptor in order to refresh the name
        self.moreInfoKeybind:SetKeybindButtonDescriptor(self.moreInfoKeybindDescriptor)
        ZO_CheckButton_SetCheckState(self.moreInfoCheckButton, self.moreInfo)
        self:RefreshErrorText()
        --Re-narrate when the toggle changes
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("errorFrame")
        return true
    else
        return false
    end
end

function ZO_ErrorFrame:UpdatePlatformStyles()
    local isGamepad = IsInGamepadPreferredMode()
    local normalKeybindTextColor = isGamepad and ZO_SELECTED_TEXT or ZO_NORMAL_TEXT

    ApplyTemplateToControl(self.textEditControl, ZO_GetPlatformTemplate("ZO_ErrorFrameTextEdit"))
    ApplyTemplateToControl(self.titleControl, ZO_GetPlatformTemplate("ZO_ErrorFrameTitle"))

    ApplyTemplateToControl(self.dismissKeybind, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    --Reset the text here to handle the force uppercase on gamepad
    self.dismissKeybind:SetText(GetString(SI_DISMISS_UI_ERROR))
    self.dismissKeybind:SetNormalTextColor(normalKeybindTextColor)

    ApplyTemplateToControl(self.suppressKeybind, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    --Reset the text here to handle the force uppercase on gamepad
    self.suppressKeybind:SetText(GetString(SI_UI_ERROR_SUPPRESS))
    self.suppressKeybind:SetNormalTextColor(normalKeybindTextColor)

    ApplyTemplateToControl(self.reloadKeybind, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    --Reset the text here to handle the force uppercase on gamepad
    self.reloadKeybind:SetText(GetString(SI_UI_ERROR_RELOAD_UI))
    self.reloadKeybind:SetNormalTextColor(normalKeybindTextColor)

    ApplyTemplateToControl(self.copyKeybind, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    --Reset the text here to handle the force uppercase on gamepad
    self.copyKeybind:SetText(GetString(SI_UI_ERROR_COPY))
    self.copyKeybind:SetNormalTextColor(normalKeybindTextColor)

    ApplyTemplateToControl(self.moreInfoContainer, ZO_GetPlatformTemplate("ZO_ErrorFrameMoreInfo"))
    self.moreInfoKeybind:SetNormalTextColor(normalKeybindTextColor)

    local spinnerFont = isGamepad and "ZoFontGamepad34" or "ZoFontWinH2"
    self.pageSpinner:SetFont(spinnerFont)
    self:RefreshPageSpinner()
end

function ZO_ErrorFrame:InitializePlatformStyles()
    ZO_PlatformStyle:New(function(...) self:UpdatePlatformStyles(...) end)
end

function ZO_ErrorFrame:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return self.displayingError
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.titleText))

            if not self.pageSpinnerControl:IsHidden() then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.pageSpinner:GetFormattedValueText()))
            end
            return narrations
        end,
        additionalInputNarrationFunction = function()
            local narrationData = {}

            if not self.moreInfoKeybind:IsHidden() then
                table.insert(narrationData, self.moreInfoKeybind:GetKeybindButtonNarrationData())
            end

            if not self.copyKeybind:IsHidden() then
                table.insert(narrationData, self.copyKeybind:GetKeybindButtonNarrationData())
            end

            if not self.dismissKeybind:IsHidden() then
                table.insert(narrationData, self.dismissKeybind:GetKeybindButtonNarrationData())
            end

            if not self.suppressKeybind:IsHidden() then
                table.insert(narrationData, self.suppressKeybind:GetKeybindButtonNarrationData())
            end

            if not self.reloadKeybind:IsHidden() then
                table.insert(narrationData, self.reloadKeybind:GetKeybindButtonNarrationData())
            end

            if not self.pageSpinnerControl:IsHidden() then
                local pageLeftNarrationData =
                {
                    name = GetString(SI_GAMEPAD_PAGED_LIST_PAGE_LEFT_NARRATION),
                    keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("UI_ERROR_PAGE_LEFT") or GetString(SI_ACTION_IS_NOT_BOUND),
                    enabled = self.pageSpinner:IsDecreaseEnabled(),
                }
                table.insert(narrationData, pageLeftNarrationData)

                local pageRightNarrationData =
                {
                    name = GetString(SI_GAMEPAD_PAGED_LIST_PAGE_RIGHT_NARRATION),
                    keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("UI_ERROR_PAGE_RIGHT") or GetString(SI_ACTION_IS_NOT_BOUND),
                    enabled = self.pageSpinner:IsIncreaseEnabled(),
                }
                table.insert(narrationData, pageRightNarrationData)
            end

            return narrationData
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("errorFrame", narrationInfo)
end

function ZO_ErrorFrame:GetError(errorIndex)
    return self.currentErrors[errorIndex]
end

function ZO_ErrorFrame:AddError(errorString, errorCode)
    --If the error code is nil it should always be unique
    if errorCode ~= nil then
        for _, errorData in ipairs(self.currentErrors) do
            if errorData.errorCode == errorCode then
                errorData.count = errorData.count + 1
                return
            end
        end
    end

    local errorData =
    {
        errorString = errorString,
        errorCode = errorCode,
        count = 1,
    }
    table.insert(self.currentErrors, errorData)

    --If we are in advanced mode and already viewing the error frame, re-narrate when a new error is added
    if self.displayingError and self.advancedMode then
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("errorFrame")
    end
end

function ZO_ErrorFrame:RefreshAdvancedMode()
    local advancedMode = ShouldShowAdvancedUIErrors()
    if advancedMode ~= self.advancedMode then
        --If the advanced mode setting changed, clear all suppressed errors
        ZO_ClearTable(self.suppressedErrors)
        self.advancedMode = advancedMode
    end
end

function ZO_ErrorFrame:RefreshPageSpinner()
    local numErrors = #self.currentErrors
    --Order matters. Set the min and max first so we don't stomp the hidden state of the buttons that we set below
    self.pageSpinner:SetMinMax(1, numErrors)

    local isGamepad = IsInGamepadPreferredMode()
    self.pageSpinner.decreaseButton:SetHidden(isGamepad)
    self.pageSpinner.increaseButton:SetHidden(isGamepad)
    self.pageSpinner.decreaseKeyLabel:SetHidden(not isGamepad)
    self.pageSpinner.increaseKeyLabel:SetHidden(not isGamepad)

    --Show the page spinner if we have at least 2 errors and are in advanced mode
    self.pageSpinnerControl:SetHidden(numErrors <= 1 or not self.advancedMode)

    --Because we include the max as part of the value display, we need to update the display after setting the min and max
    self.pageSpinner:UpdateDisplay()
end

function ZO_ErrorFrame:SetCurrentError(errorIndex)
    local errorData = self:GetError(errorIndex)
    local fullError = errorData.errorString
    local rawErrorCode = errorData.errorCode

    self.currentErrorIndex = errorIndex

    --Colored Full Error: Wrap the <Locals>...</Locals> section with color markup
    self.coloredFullError = string.gsub(fullError, "<Locals>.-</Locals>", function(match)
        return "|caaaaaa"..match.."|r"
    end)
            
    --Copy Error : Tab the <Locals>...</Locals> section for easier reading.
    self.copyError = string.gsub(fullError, "<Locals>.-</Locals>", function(match)
        return "\t"..match
    end)

    --Simple Error: Remove the <Locals>...</Locals> section and any newline after it if there is one
    self.simpleError = string.gsub(fullError, "<Locals>.-</Locals>\n?", "")

    --Convert the error code into a hex value
    --If we don't have an error code for whatever reason, just use an empty string
    if rawErrorCode then
        self.errorHexCode = string.format("%X", rawErrorCode)
    else
        self.errorHexCode = ""
    end

    self:RefreshErrorText()
    self:RefreshTitleText()
    self:RefreshButtons()
    --Re-narrate whenever the current error changes
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("errorFrame")
end

function ZO_ErrorFrame:OnUIError(errorString, errorCode)
    --First, refresh whether or not we are in advanced mode
    self:RefreshAdvancedMode()

    if not self.suppressErrorDialog and not self.suppressedErrors[errorCode] and errorString then
        self:AddError(errorString, errorCode)

        if not self.displayingError then
            PushActionLayerByName("UIError")
            self.displayingError = true
            self.control:SetHidden(false)
            self:SetCurrentError(1)
        else
            --If we are already displaying the error, we only need to refresh the page spinner in case the max value changed and the title text in case the count changed
            self:RefreshPageSpinner()
            self:RefreshTitleText()
        end
    end
end

function ZO_ErrorFrame:CopyErrorToClipboard()
    if not IsConsoleUI() and self.advancedMode and self.copyError then
        CopyToClipboard(self.copyError)
        return true
    end

    return false
end

function ZO_ErrorFrame:CopyErrorCodeToClipboard()
    if not IsConsoleUI() and self.errorHexCode then
        CopyToClipboard(self.errorHexCode)
        return true
    end

    return false
end

function ZO_ErrorFrame:RefreshButtons()
    self:RefreshPageSpinner()

    --Only show the suppress button in advanced mode
    self.suppressKeybind:SetHidden(not self.advancedMode)

    --Only show the more info button in advanced mode
    self.moreInfoContainer:SetHidden(not self.advancedMode)

    --Do not show the reload button in pregame
    self.reloadKeybind:SetHidden(ZO_IsPregameUI())

    --Only show the copy button in advanced mode (and not on consoles)
    self.copyKeybind:SetHidden(IsConsoleUI() or not self.advancedMode)

    --Do not show the close button on consoles
    self.closeButton:SetHidden(IsConsoleUI())

    --Do not show the copy error code button on consoles
    self.copyErrorCodeButton:SetHidden(IsConsoleUI())
end

do
    local MAX_DISPLAYED_ERROR_COUNT = 99
    function ZO_ErrorFrame:RefreshTitleText()
        local errorData = self:GetError(self.currentErrorIndex)
        local colorizedErrorHexCode = ZO_SELECTED_TEXT:Colorize(self.errorHexCode)
        if self.advancedMode and errorData.count > 1 then
            if errorData.count > MAX_DISPLAYED_ERROR_COUNT then
                self.titleText = zo_strformat(SI_WINDOW_TITLE_UI_ERROR_MULTIPLE_MAX, MAX_DISPLAYED_ERROR_COUNT, colorizedErrorHexCode)
            else
                self.titleText = zo_strformat(SI_WINDOW_TITLE_UI_ERROR_MULTIPLE, errorData.count, colorizedErrorHexCode)
            end
        else
            self.titleText = zo_strformat(SI_WINDOW_TITLE_UI_ERROR, colorizedErrorHexCode)
        end

        self.titleControl:SetText(self.titleText)
    end
end

function ZO_ErrorFrame:RefreshErrorText()
    if self.simpleError then
        local showFullError = self.moreInfo and self.advancedMode
        self.textEditControl:SetText(showFullError and self.coloredFullError or self.simpleError)
        self.textEditControl:SetCursorPosition(0)
    else
        self.textEditControl:SetText("")
    end
    self.textEditControl:SetTopLineIndex(1)
end

function ZO_ErrorFrame:HideErrorFrame(suppressCurrent)
    local errorHidden = false
    if not self.suppressErrorDialog then
        if self.displayingError then
            RemoveActionLayerByName("UIError")
            self.displayingError = false
            self.control:SetHidden(true)
            self.textEditControl:SetText("")
            errorHidden = true

            if suppressCurrent then
                for _, errorData in ipairs(self.currentErrors) do
                    --If we don't have an error code for this error, it cannot be suppressed
                    if errorData.errorCode ~= nil then
                        self.suppressedErrors[errorData.errorCode] = true
                    end
                end
            end

            ZO_ClearTable(self.currentErrors)
        end
    end

    return errorHidden
end

function ZO_ErrorFrame:ToggleSuppressDialog()
    if not self.suppressErrorDialog then
        self:HideErrorFrame()
    end

    self.suppressErrorDialog = not self.suppressErrorDialog
end

function ZO_ErrorFrame:DismissErrors(suppressCurrent)
    if self.advancedMode then
        --In advanced mode, we will either suppress all current errors or dismiss without suppressing
        return self:HideErrorFrame(suppressCurrent)
    else
        --In simplified mode, we always suppress current errors
        local SUPPRESS_CURRENT = true
        return self:HideErrorFrame(SUPPRESS_CURRENT)
    end
end

function ZO_ErrorFrame:SuppressErrors()
    --Only do something if we are in advanced mode
    if self.advancedMode then
        local SUPPRESS_CURRENT = true
        return self:DismissErrors(SUPPRESS_CURRENT)
    else
        return false
    end
end

function ZO_ErrorFrame:CycleLeft()
    if not self.pageSpinnerControl:IsHidden() then
        self.pageSpinner:ModifyValue(-1)
        return true
    end

    return false
end

function ZO_ErrorFrame:CycleRight()
    if not self.pageSpinnerControl:IsHidden() then
        self.pageSpinner:ModifyValue(1)
        return true
    end

    return false
end

-- XML Handlers

function ZO_UIErrors_Init(control)
    ZO_ERROR_FRAME = ZO_ErrorFrame:New(control)
end

function ZO_UIErrors_CopyError()
    return ZO_ERROR_FRAME:CopyErrorToClipboard()
end

function ZO_UIErrors_CopyCode()
    return ZO_ERROR_FRAME:CopyErrorCodeToClipboard()
end

function ZO_UIErrors_ToggleMoreInfo()
    return ZO_ERROR_FRAME:ToggleMoreInfo()
end

function ZO_UIErrors_Dismiss()
    return ZO_ERROR_FRAME:DismissErrors()
end

function ZO_UIErrors_PageLeft()
    return ZO_ERROR_FRAME:CycleLeft()
end

function ZO_UIErrors_PageRight()
    return ZO_ERROR_FRAME:CycleRight()
end

function ZO_UIErrors_Suppress()
    return ZO_ERROR_FRAME:SuppressErrors()
end

function ZO_UIErrors_ToggleSuppressDialog()
    ZO_ERROR_FRAME:ToggleSuppressDialog()
end

function ZO_UIErrors_OnCopyCodeEnter(control)
    InitializeTooltip(InformationTooltip, control, LEFT, 0, 0, RIGHT)
    SetTooltipText(InformationTooltip, GetString(SI_UI_ERROR_COPY_ERROR_CODE_TOOLTIP))
end

function ZO_UIErrors_OnCopyCodeExit(control)
    ClearTooltip(InformationTooltip)
end
