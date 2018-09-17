ZO_AbstractGridScrollList = ZO_CallbackObject:Subclass()

function ZO_AbstractGridScrollList:New(...)
    local list = ZO_CallbackObject.New(self)
    list:Initialize(...)
    return list
end

function ZO_AbstractGridScrollList:Initialize(control)
    self.control = control
    self.container = control:GetNamedChild("Container")
    self.list = self.container:GetNamedChild("List")
    ZO_ScrollList_AddResizeOnScreenResize(self.list)
    self.scrollbar = self.list:GetNamedChild("ScrollBar")
    self.currentHeaderName = nil
    self.nextOperationId = 1
    self.templateOperationIds = {}
end

function ZO_AbstractGridScrollList:SetLineBreakAmount(lineBreakAmount)
    self.lineBreakAmount = lineBreakAmount
end

function ZO_AbstractGridScrollList:SetYDistanceFromEdgeWhereSelectionCausesScroll(yDistanceFromEdgeWhereSelectionCausesScroll)
    ZO_ScrollList_SetYDistanceFromEdgeWhereSelectionCausesScroll(self.list, yDistanceFromEdgeWhereSelectionCausesScroll)
end

function ZO_AbstractGridScrollList:AddHeaderTemplate(templateName, height, setupFunc, onHideFunc, resetControlFunc)
    if self.templateOperationIds[templateName] == nil then
        local operationId = self.nextOperationId
        local SPACING_XY = 0
        local NOT_SELECTABLE = false
        local WIDTH = nil

        ZO_ScrollList_AddControlOperation(self.list, operationId, templateName, WIDTH, height, resetControlFunc, setupFunc, onHideFunc, SPACING_XY, SPACING_XY, NOT_SELECTABLE)
        ZO_ScrollList_SetTypeCategoryHeader(self.list, operationId, true)

        self.nextOperationId = self.nextOperationId + 1
        self.templateOperationIds[templateName] = operationId
        return operationId
    end

    return nil
end

function ZO_AbstractGridScrollList:AddEntryTemplate(templateName, width, height, setupFunc, onHideFunc, resetControlFunc, spacingX, spacingY, centerEntries)
    if self.templateOperationIds[templateName] == nil then
        local operationId = self.nextOperationId
        local IS_SELECTABLE = true
        ZO_ScrollList_AddControlOperation(self.list, operationId, templateName, width, height, resetControlFunc, setupFunc, onHideFunc, spacingX, spacingY, IS_SELECTABLE, centerEntries)

        self.nextOperationId = self.nextOperationId + 1
        self.templateOperationIds[templateName] = operationId
        return operationId
    end

    return nil
end

function ZO_AbstractGridScrollList:AddEntry(data, templateName)
    local operationId = self.templateOperationIds[templateName]
    if operationId then
        local gridHeaderName = data.gridHeaderName
        if self.currentHeaderName ~= gridHeaderName then
            local scrollData = ZO_ScrollList_GetDataList(self.list)
            if self.currentHeaderName or #scrollData > 0 then
                ZO_ScrollList_AddOperation(self.list, ZO_SCROLL_LIST_OPERATION_LINE_BREAK, { lineBreakAmount = self.lineBreakAmount })
            end
            self.currentHeaderName = gridHeaderName
            if self.currentHeaderName and self.currentHeaderName ~= "" then
                local headerOperationId = self.templateOperationIds[data.gridHeaderTemplate]
                ZO_ScrollList_AddOperation(self.list, headerOperationId, { header = gridHeaderName, data = data })
            end
        end
        ZO_ScrollList_AddOperation(self.list, operationId, data)
    end
end

function ZO_AbstractGridScrollList:CommitGridList()
    ZO_ScrollList_Commit(self.list)
end

function ZO_AbstractGridScrollList:IsSelectionOfTemplateType(templateName)
    local operationId = self.templateOperationIds[templateName]
    if operationId then
        local selectedData = ZO_ScrollList_GetSelectedData(self.list)
        if selectedData.dataEntry.typeId == operationId then
            return true
        end
    end
    return false
end

function ZO_AbstractGridScrollList:RefreshGridList()
    ZO_ScrollList_RefreshVisible(self.list)
end

function ZO_AbstractGridScrollList:RefreshGridListEntryData(entryData, overrideSetupCallback)
    ZO_ScrollList_RefreshVisible(self.list, entryData, overrideSetupCallback)
end

function ZO_AbstractGridScrollList:ClearGridList(retainScrollPosition)
    ZO_ScrollList_Clear(self.list)
    self.currentHeaderName = nil
    if not retainScrollPosition then
        ZO_Scroll_ResetToTop(self.list)
    end
end

function ZO_AbstractGridScrollList:HasEntries()
    local dataList = ZO_ScrollList_GetDataList(self.list)
    return #dataList > 0
end

function ZO_AbstractGridScrollList:AtTopOfGrid()
    return ZO_ScrollList_AtTopOfList(self.list)
end

function ZO_AbstractGridScrollList:GetData()
    return ZO_ScrollList_GetDataList(self.list)
end

function ZO_AbstractGridScrollList:GetControlFromData(data)
    return ZO_ScrollList_GetDataControl(self.list, data)
end

do
    local ANIMATE_INSTANTLY = true

    function ZO_AbstractGridScrollList:ScrollDataToCenter(data, onScrollCompleteCallback)
        local dataIndex = ZO_ScrollList_GetDataIndex(self.list, data.dataEntry)
        if internalassert(dataIndex ~= nil) then
            ZO_ScrollList_SelectData(self.list, data)
            ZO_ScrollList_ScrollDataToCenter(self.list, dataIndex, onScrollCompleteCallback, ANIMATE_INSTANTLY)
        end
    end
end

function ZO_AbstractGridScrollList:ResetToTop()
    ZO_Scroll_ResetToTop(self.list)
end

----------------------
-- Global functions --
----------------------

function ZO_DefaultGridHeaderSetup(control, data, selected)
    control:SetText(data.header)
end

function ZO_DefaultGridEntrySetup(control, data, list)
    if not control.icon then
        control.icon = control:GetNamedChild("Icon")
    end

    local icon = control.icon

    if data.iconDesaturation then
        icon:SetDesaturation(data.iconDesaturation)
    end

    if data.textureSampleProcessingWeights then
        for type, weight in pairs(data.textureSampleProcessingWeights) do
            icon:SetTextureSampleProcessingWeight(type, weight)
        end
    end

    local iconFile = data.iconFile or data.icon
    if iconFile then
        icon:SetTexture(iconFile)
        icon:SetHidden(false)
    else
        icon:SetHidden(true)
    end
end

do
    local g_gridEntryScaleAnimationProvider = ZO_ReversibleAnimationProvider:New("ZO_GridEntry_IconSelectedAnimation")

    function ZO_GridEntry_SetIconScaledUp(control, scaledUp, instant)
        if control.icon then
            if scaledUp then
                g_gridEntryScaleAnimationProvider:PlayForward(control.icon, instant)
            else
                g_gridEntryScaleAnimationProvider:PlayBackward(control.icon, instant)
            end
        end
    end

    function ZO_GridEntry_SetIconScaledUpInstantly(control, scaledUp)
        ZO_GridEntry_SetIconScaledUp(control, scaledUp, true)
    end
end