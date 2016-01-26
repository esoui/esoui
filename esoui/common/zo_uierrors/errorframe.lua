--
--[[ ZO_ErrorFrame ]]--
--

local ZO_ErrorFrame = ZO_Object:Subclass()

function ZO_ErrorFrame:New(...)
    local errorFrame = ZO_Object.New(self)
    errorFrame:Initialize(...)
    return errorFrame
end

local LOW_MEMORY_STRING = GetString(SI_LUA_LOW_MEMORY)
function ZO_ErrorFrame:Initialize(control)
    self.control = control
    self.textEditControl = control:GetNamedChild("TextEdit")
    self.titleControl = control:GetNamedChild("Title")
    self.dismissControl = control:GetNamedChild("Dismiss")
    self.dismissIcon = self.dismissControl:GetNamedChild("GamepadIcon")

    self.queuedErrors = {}
    self.suppressErrorDialog = false
    self.displayingError = false

    self:InitializePlatformStyles()

    EVENT_MANAGER:RegisterForEvent("ErrorFrame", EVENT_LUA_ERROR, function(eventCode, ...) self:OnUIError(...) end)
    EVENT_MANAGER:RegisterForEvent("ErrorFrame", EVENT_LUA_LOW_MEMORY, function() self:OnUIError(LOW_MEMORY_STRING) end)
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
            self.textEditControl:SetText(self:GetNextQueuedError())
            self.textEditControl:SetTopLineIndex(1)
        end
    end
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
