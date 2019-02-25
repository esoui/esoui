ZO_ItemPreviewListHelper_Keyboard = ZO_ItemPreviewListHelper_Shared:Subclass()

function ZO_ItemPreviewListHelper_Keyboard:New(...)
    return ZO_ItemPreviewListHelper_Shared.New(self, ...)
end

function ZO_ItemPreviewListHelper_Keyboard:Initialize(...)
    ZO_ItemPreviewListHelper_Shared.Initialize(self, ...)

    self.previewPreviousArrowButton = self.control:GetNamedChild("PreviewPreviousArrow")
    self.previewNextArrowButton = self.control:GetNamedChild("PreviewNextArrow")
    self.previewPreviousArrowButton:SetHandler("OnClicked", function() self:PreviewPrevious() end)
    self.previewNextArrowButton:SetHandler("OnClicked", function() self:PreviewNext() end)
end

do
    local function SetButtonStateEnabled(button, enabled)
        if enabled then
            button:SetState(BSTATE_NORMAL, false)
        else
            button:SetState(BSTATE_DISABLED, true)
        end
    end

    function ZO_ItemPreviewListHelper_Keyboard:RefreshActions()
        ZO_ItemPreviewListHelper_Shared.RefreshActions(self)

        local areButtonsVisible = self:HasMultiplePreviewDatas()

        self.previewPreviousArrowButton:SetHidden(not areButtonsVisible)
        self.previewNextArrowButton:SetHidden(not areButtonsVisible)
        if areButtonsVisible then
            local canChangePreview = ITEM_PREVIEW_KEYBOARD:CanChangePreview()
            SetButtonStateEnabled(self.previewPreviousArrowButton, canChangePreview and self:CanPreviewPrevious())
            SetButtonStateEnabled(self.previewNextArrowButton, canChangePreview and self:CanPreviewNext())
        end
    end
end

function ZO_ItemPreviewListHelper_Keyboard:GetPreviewObject()
    return ITEM_PREVIEW_KEYBOARD
end

function ZO_ItemPreviewListHelper_Keyboard_OnInitialize(control)
    ITEM_PREVIEW_LIST_HELPER_KEYBOARD = ZO_ItemPreviewListHelper_Keyboard:New(control)
end