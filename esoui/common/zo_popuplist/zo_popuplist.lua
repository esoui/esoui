ZO_POPUP_LIST_ENTRY_HEIGHT = 52

ZO_POPUP_LIST_DATA_TYPE_BLANK = 1
ZO_POPUP_LIST_DATA_TYPE_ITEM = 2

local NUM_VISIBLE_LIST_SLOTS = 5

ZO_PopupList = ZO_InitializingObject:Subclass()

function ZO_PopupList:Initialize(control)
    self.control = control
    control.object = self

    self.list = control:GetNamedChild("List")
    ZO_ScrollList_AddDataType(self.list, ZO_POPUP_LIST_DATA_TYPE_BLANK, "ZO_PopupListBlankItemSlot", ZO_POPUP_LIST_ENTRY_HEIGHT, function(control, data) self:SetUpListBlankItem(control, data) end)
    ZO_ScrollList_AddDataType(self.list, ZO_POPUP_LIST_DATA_TYPE_ITEM, "ZO_PopupListItemSlot", ZO_POPUP_LIST_ENTRY_HEIGHT, function(control, data) self:SetUpListRewardItem(control, data) end)
end

function ZO_PopupList:GetControl()
    return self.control
end

function ZO_PopupList:SetUpListRewardItem(control, data)
    control.data = data

    local nameControl = control:GetNamedChild("Name")

    if data.currencyType and data.currencyType ~= CURT_NONE then
        nameControl:SetText(data.formattedName)
        nameControl:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    else
        if data.rewardType == REWARD_ENTRY_TYPE_COLLECTIBLE then
            nameControl:SetColor(ZO_WHITE:UnpackRGBA())
        else
            if data.displayQuality then
                nameControl:SetColor(GetItemQualityColor(data.displayQuality):UnpackRGBA())
            end
        end

        nameControl:SetText(data.formattedName)
    end

    control.icon = control:GetNamedChild("Icon")
    local iconControl = control.icon
    if data.icon then
        iconControl:SetTexture(data.icon)
        iconControl:SetHidden(false)
    else
        iconControl:SetHidden(true)
    end

    local stackCount = data.quantity
    local stackCountLabel = iconControl:GetNamedChild("StackCount")
    if stackCount and stackCount > 1 then
        stackCountLabel:SetText(ZO_AbbreviateAndLocalizeNumber(stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
    else
        stackCountLabel:SetText("")
    end

    control:SetHidden(false)
end

function ZO_PopupList:SetUpListBlankItem(control, data)
    control:SetHidden(false)
end

function ZO_PopupList:AddItem(dataType, data)
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    local scrollEntryData = ZO_ScrollList_CreateDataEntry(dataType, data)
    table.insert(scrollData, scrollEntryData)
end

function ZO_PopupList:ClearList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)
end

function ZO_PopupList:UpdateList(listData)
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    self.itemCount = #scrollData

    local BLANK_DATA = {}
    for i = #scrollData + 1, NUM_VISIBLE_LIST_SLOTS do
        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ZO_POPUP_LIST_DATA_TYPE_BLANK, BLANK_DATA)
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_PopupList:Hide()
    -- Order matters
    if self.control:IsHidden() then
        return
    end

    local mouseOverControl = ZO_ScrollList_GetMouseOverControl(self.list)
    if mouseOverControl and self.onMouseExitCallback then
        self.onMouseExitCallback(mouseOverControl)
    end

    self.control:SetHidden(true)

    if self.onCloseCallback then
        self.onCloseCallback(mouseOverControl)
    end

    self.onMouseEnterCallback = nil
    self.onMouseExitCallback = nil
    self.onMouseUpCallback = nil
    self.onCloseCallback = nil
    self.hideTooltipCallback = nil
    self.showTooltipCallback = nil
end

function ZO_PopupList:Show(...)
    self:SetAnchor(...)
    self.control:SetHidden(false)
end

do
    local g_highlightAnimationProvider = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")

    function ZO_PopupList:ShowRewardList(rewardId, onMouseEnterCallback, onMouseExitCallback, ...)
        local rewardListId = GetRewardListIdFromReward(rewardId)
        local rewards = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
        self:ClearList()
        for _, reward in ipairs(rewards) do
            self:AddItem(ZO_POPUP_LIST_DATA_TYPE_ITEM, reward)
        end
        self:UpdateList()
        self:SetOnMouseEnterCallback(function(control)
            ZO_GridEntry_SetIconScaledUp(control, true)
            local highlight = control:GetNamedChild("Highlight")
            if highlight and highlight:GetType() == CT_TEXTURE then
                g_highlightAnimationProvider:PlayForward(highlight)
            end

            if self.showTooltipCallback then
                self.showTooltipCallback(control)
            else
                ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -5)
            end

            if onMouseEnterCallback then
                onMouseEnterCallback(control)
            end
        end)
        self:SetOnMouseExitCallback(function(control)
            ZO_GridEntry_SetIconScaledUp(control, false)
            local highlight = control:GetNamedChild("Highlight")
            if highlight and highlight:GetType() == CT_TEXTURE then
                g_highlightAnimationProvider:PlayBackward(highlight)
            end

            if self.hideTooltipCallback then
                self.hideTooltipCallback(control)
            else
                ZO_Rewards_Shared_OnMouseExit()
            end

            if onMouseExitCallback then
                onMouseExitCallback(control)
            end
        end)

        self:Show(...)
    end
end

function ZO_PopupList:SetAnchor(anchorFromPoint, anchorToControl, anchorToPoint, offsetX, offsetY)
    if not anchorFromPoint then
        return
    end

    self.control:ClearAnchors()
    self.control:SetAnchor(anchorFromPoint, anchorToControl, anchorToPoint, offsetX, offsetY)
end

function ZO_PopupList:SetOnMouseEnterCallback(onMouseEnterCallback)
    self.onMouseEnterCallback = onMouseEnterCallback
end

function ZO_PopupList:SetOnMouseExitCallback(onMouseExitCallback)
    self.onMouseExitCallback = onMouseExitCallback
end

function ZO_PopupList:SetOnMouseUpCallback(onMouseUpCallback)
    self.onMouseUpCallback = onMouseUpCallback
end

function ZO_PopupList:SetOnCloseCallback(onCloseCallback)
    self.onCloseCallback = onCloseCallback
end

function ZO_PopupList:SetHideTooltipCallback(callback)
    self.hideTooltipCallback = callback
end

function ZO_PopupList:SetShowTooltipCallback(callback)
    self.showTooltipCallback = callback
end

function ZO_PopupList.OnControlInitialized(control)
    POPUP_LIST = ZO_PopupList:New(control)
end

function ZO_PopupList:OnCloseButtonClicked(control)
    self:Hide()
end

function ZO_PopupList.OnMouseEnter(control)
    if POPUP_LIST.onMouseEnterCallback then
        POPUP_LIST.onMouseEnterCallback(control)
    end
end

function ZO_PopupList.OnMouseExit(control)
    if POPUP_LIST.onMouseExitCallback then
        POPUP_LIST.onMouseExitCallback(control)
    end
end

function ZO_PopupList.OnMouseUp(...)
    if POPUP_LIST.onMouseUpCallback then
        POPUP_LIST.onMouseUpCallback(...)
    end
end