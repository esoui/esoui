ZO_ItemPreviewListHelper_Gamepad = ZO_ItemPreviewListHelper_Shared:Subclass()

function ZO_ItemPreviewListHelper_Gamepad:New(...)
    return ZO_ItemPreviewListHelper_Shared.New(self, ...)
end

function ZO_ItemPreviewListHelper_Gamepad:Initialize(...)
    ZO_ItemPreviewListHelper_Shared.Initialize(self, ...)

    self:InitializeKeybinds()
    self.directionalInputNarrationFunction = function()
        if self:HasVariations() then
            return ZO_GetHorizontalDirectionalInputNarrationData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_PREVIOUS), GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_NEXT))
        end
        return {}
    end
end

function ZO_ItemPreviewListHelper_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        {
            name = GetString(SI_GAMEPAD_PREVIEW_PREVIOUS),
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            callback = function()
                self:PreviewPrevious()
            end,
            visible = function() return self:HasMultiplePreviewDatas() end,
            enabled = function() return ITEM_PREVIEW_GAMEPAD:CanChangePreview() and self:CanPreviewPrevious() end,
        },

        {
            name = GetString(SI_GAMEPAD_PREVIEW_NEXT),
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            callback = function()
                self:PreviewNext()
            end,
            visible = function() return self:HasMultiplePreviewDatas() end,
            enabled = function() return ITEM_PREVIEW_GAMEPAD:CanChangePreview() and self:CanPreviewNext() end,
        },
    }
end

function ZO_ItemPreviewListHelper_Gamepad:RefreshActions()
    ZO_ItemPreviewListHelper_Shared.RefreshActions(self)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_ItemPreviewListHelper_Gamepad:GetPreviewObject()
    return ITEM_PREVIEW_GAMEPAD
end

function ZO_ItemPreviewListHelper_Gamepad:GetPreviewNarrationText()
    if self:HasVariations() then
        return self:GetPreviewObject():GetPreviewSpinnerNarrationText()
    end
end

function ZO_ItemPreviewListHelper_Gamepad:GetAdditionalInputNarrationFunction()
    return self.directionalInputNarrationFunction
end

function ZO_ItemPreviewListHelper_Gamepad:OnShowing()
    ZO_ItemPreviewListHelper_Shared.OnShowing(self)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_ItemPreviewListHelper_Gamepad:OnHidden()
    ZO_ItemPreviewListHelper_Shared.OnHidden(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_ItemPreviewListHelper_Gamepad_OnInitialize(control)
    ITEM_PREVIEW_LIST_HELPER_GAMEPAD = ZO_ItemPreviewListHelper_Gamepad:New(control)
end