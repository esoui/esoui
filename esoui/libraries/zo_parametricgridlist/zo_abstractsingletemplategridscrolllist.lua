----------------------
-- ZO_AbstractSingleTemplateGridScrollList
----------------------

ZO_AbstractSingleTemplateGridScrollList = ZO_AbstractGridScrollList:Subclass()

function ZO_AbstractSingleTemplateGridScrollList:SetHeaderTemplate(templateName, height, setupFunc, onHideFunc, resetControlFunc)
    self.headerOperationId = self:AddHeaderTemplate(templateName, height, setupFunc, onHideFunc, resetControlFunc)
    self.headerTemplateName = templateName
end

function ZO_AbstractSingleTemplateGridScrollList:SetGridEntryTemplate(templateName, width, height, setupFunc, onHideFunc, resetControlFunc, spacingX, spacingY, centerEntries)
    self.entryOperationId = self:AddEntryTemplate(templateName, width, height, setupFunc, onHideFunc, resetControlFunc, spacingX, spacingY, centerEntries)
    self.entryTemplateName = templateName
    self:SetAutoFillEntryTemplate(templateName)
end

-- Note: Order matters. When using this function, it must be called after SetGridEntryTemplate
function ZO_AbstractSingleTemplateGridScrollList:SetGridEntryVisibilityFunction(visiblityFunction)
    ZO_ScrollList_SetVisibilityFunction(self.list, self.entryOperationId, visiblityFunction)
end

function ZO_AbstractSingleTemplateGridScrollList:AddEntry(data)
    if not data.gridHeaderTemplate then
        data.gridHeaderTemplate = self.headerTemplateName
    end
    ZO_AbstractGridScrollList.AddEntry(self, data, self.entryTemplateName)
end
