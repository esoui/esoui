--
--[[ ZO_ErrorFrame ]]--
--

local ZO_ErrorFrame = ZO_Object:Subclass()

function ZO_ErrorFrame:New(...)
    local errorFrame = ZO_Object.New(self)
    errorFrame:Initialize(...)
    return errorFrame
end

function ZO_ErrorFrame:Initialize(control)
    self.control = control
    self.textEditControl = control:GetNamedChild("TextEdit")
    self.titleControl = control:GetNamedChild("Title")
    self.dismissControl = control:GetNamedChild("Dismiss")
    self.dismissIcon = self.dismissControl:GetNamedChild("GamepadIcon")
    self.moreInfoButton = control:GetNamedChild("MoreInfo")
    ZO_CheckButton_SetToggleFunction(self.moreInfoButton, function()
        self.moreInfo = not self.moreInfo
        SetCVar("UIErrorShowMoreInfo", self.moreInfo and "1" or "0")
        self:RefreshErrorText()
    end)

    self.queuedErrors = {}
    self.suppressErrorDialog = false
    self.displayingError = false

    self.moreInfo = GetCVar("UIErrorShowMoreInfo") == "1"
    ZO_CheckButton_SetCheckState(self.moreInfoButton, self.moreInfo)

    self:InitializePlatformStyles()

    EVENT_MANAGER:RegisterForEvent("ErrorFrame", EVENT_LUA_ERROR, function(eventCode, ...) self:OnUIError(...) end)
end

local KEYBOARD_STYLES = {
                            textEditTemplate = "ZO_ErrorFrameTextEdit_Keyboard_Template",
                            titleTemplate = "ZO_ErrorFrameTitle_Keyboard_Template",
                            dismissTemplate = "ZO_ErrorFrameDismiss_Keyboard_Template",
                            hideDismissIcon = true,
                        }

local GAMEPAD_STYLES =  {
                            textEditTemplate = "ZO_ErrorFrameTextEdit_Gamepad_Template",
                            titleTemplate = "ZO_ErrorFrameTitle_Gamepad_Template",
                            dismissTemplate = "ZO_ErrorFrameDismiss_Gamepad_Template",
                            hideDismissIcon = false,
                        }

function ZO_ErrorFrame:UpdatePlatformStyles(styleTable)
    ApplyTemplateToControl(self.textEditControl, styleTable.textEditTemplate)
    ApplyTemplateToControl(self.titleControl, styleTable.titleTemplate)
    ApplyTemplateToControl(self.dismissControl, styleTable.dismissTemplate)

    self.dismissIcon:SetHidden(styleTable.hideDismissIcon)
end

function ZO_ErrorFrame:InitializePlatformStyles()
    ZO_PlatformStyle:New(function(...) self:UpdatePlatformStyles(...) end, KEYBOARD_STYLES, GAMEPAD_STYLES)
end

function ZO_ErrorFrame:GetNextQueuedError()
    if #self.queuedErrors > 0 then
        return table.remove(self.queuedErrors, 1)
    end
end

function ZO_ErrorFrame:OnUIError(errorString)
    if not self.suppressErrorDialog and errorString then
        table.insert(self.queuedErrors, errorString)

        if not self.displayingError then
            self.displayingError = true
            self.control:SetHidden(false)
            local fullError = self:GetNextQueuedError()

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

            self:RefreshErrorText()
        end
    end
end

function ZO_ErrorFrame:CopyErrorToClipboard()
    if self.copyError then
        CopyToClipboard(self.copyError)
    end
end

function ZO_ErrorFrame:RefreshErrorText()
    if self.simpleError then
        self.textEditControl:SetText(self.moreInfo and self.coloredFullError or self.simpleError)
    else
        self.textEditControl:SetText("")
    end
    self.textEditControl:SetTopLineIndex(1)
end

function ZO_ErrorFrame:HideCurrentError()
    if not self.suppressErrorDialog then
        if self.displayingError then
            self.displayingError = false
            self.control:SetHidden(true)
            self.textEditControl:SetText("")
        end
        
        self:OnUIError(self:GetNextQueuedError())
    end
end

function ZO_ErrorFrame:HideAllErrors()
    if not self.suppressErrorDialog then
        self.queuedErrors = {}
        self:HideCurrentError()
    end
end

function ZO_ErrorFrame:ToggleSupressDialog()
    if not self.suppressErrorDialog then
        self:HideAllErrors()
    end

    self.suppressErrorDialog = not self.suppressErrorDialog
end

-- XML Handlers

function ZO_UIErrors_Init(control)
    ZO_ERROR_FRAME = ZO_ErrorFrame:New(control)
end

function ZO_UIErrors_HideCurrent()
    ZO_ERROR_FRAME:HideCurrentError()
end

function ZO_UIErrors_HideAll()
    ZO_ERROR_FRAME:HideAllErrors()
end

function ZO_UIErrors_ToggleSupressDialog()
    ZO_ERROR_FRAME:ToggleSupressDialog()
end
