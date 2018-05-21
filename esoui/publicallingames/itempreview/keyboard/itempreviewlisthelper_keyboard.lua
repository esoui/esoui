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

function ZO_ItemPreviewListHelper_Keyboard:RefreshActions()
    ZO_ItemPreviewListHelper_Shared.RefreshActions(self)

    local areButtonsVisible = self:HasMultiplePreviewDatas()

    self.previewPreviousArrowButton:SetHidden(not areButtonsVisible)
    self.previewNextArrowButton:SetHidden(not areButtonsVisible)
    if areButtonsVisible then
        local enabled = ITEM_PREVIEW_KEYBOARD:CanChangePreview()
        if enabled then
            self.previewPreviousArrowButton:SetState(BSTATE_NORMAL, false)
            self.previewNextArrowButton:SetState(BSTATE_NORMAL, false)
        else
            self.previewPreviousArrowButton:SetState(BSTATE_DISABLED, true)
            self.previewNextArrowButton:SetState(BSTATE_DISABLED, true)
        end
    end
end

function ZO_ItemPreviewListHelper_Keyboard:GetPreviewObject()
    return ITEM_PREVIEW_KEYBOARD
end

function ZO_ItemPreviewListHelper_Keyboard_OnInitialize(control)
    ITEM_PREVIEW_LIST_HELPER_KEYBOARD = ZO_ItemPreviewListHelper_Keyboard:New(control)
end