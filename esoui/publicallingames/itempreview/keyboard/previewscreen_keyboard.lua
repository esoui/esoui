ZO_PreviewScreen_Keyboard = ZO_PreviewScreen_Shared:Subclass()

function ZO_PreviewScreen_Keyboard:Initialize(control, scene)
    ZO_PreviewScreen_Shared.Initialize(self, control, scene)

    -- These functions are given vars on self to make it easier to pass them into POPUP_LIST
    self.RewardListEntryMouseEnterHandler = function(control)
        self:OnRewardListEntryMouseEnter(control)
    end

    self.RewardListEntryMouseExitHandler = function(control)
        self:OnRewardListEntryMouseExit(control)
    end

    self.RewardListEntryMouseUpHandler = function(...)
        self:OnRewardListEntryMouseUp(...)
    end

    self.RewardListCloseHandler = function(...)
        self:OnRewardListClose(...)
    end
end

function ZO_PreviewScreen_Keyboard:BeginPreviewInternal()
    local previewType, rewardData, previewKey = self:GetActivePreviewInfo()
    local rewardId = rewardData:GetRewardId()
    local rewardType = rewardData:GetRewardType()
    self:UpdateSceneFragments()

    if previewKey then
        if rewardType == REWARD_ENTRY_TYPE_REWARD_LIST then
            -- This preview originated from a reward list tile.
            self:SetActiveRewardListData(rewardData)
            return
        end

        -- This preview originated from a non-reward list tile.
        self:ClearActiveRewardListData()
    end

    local previewSystem = self.GetPreviewSystem()
    previewSystem:PreviewReward(rewardId)

    self:UpdatePopupListPosition()
    self:RefreshPreviewControls()
    self:UpdateKeybinds()
    return true
end

function ZO_PreviewScreen_Keyboard:EndPreviewInternal()
    ZO_PreviewScreen_Shared.EndPreviewInternal(self)

    self:UpdateSceneFragments()

    if not self:GetActiveRewardListData() then
        POPUP_LIST:Hide()
    end

    self:UpdateKeybinds()
end

function ZO_PreviewScreen_Keyboard:InitializeKeybindStripDescriptors()
    -- Can be overridden
end

function ZO_PreviewScreen_Keyboard:GetControlByPreviewableRewardData(previewableRewardData)
    -- Can be overridden
end

function ZO_PreviewScreen_Keyboard:OnRewardListEntryMouseEnter(control)
    ZO_GridEntry_SetIconScaledUp(control, true)
    ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -15)

    local rewardId = control.dataEntry.data.rewardId
    if rewardId == 0 then
        self:UpdateKeybinds()
        return
    end

    local rewardQuantity = control.dataEntry.data.quantity or 1
    local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, rewardQuantity)
    self:SetActiveRewardListRewardData(rewardData)
    self:BeginPreview(ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW, rewardData)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PREVIEW)

    if self.rewardListKeybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.rewardListKeybindStripDescriptor)
    end
end

function ZO_PreviewScreen_Keyboard:OnRewardListEntryMouseExit(control)
    ZO_GridEntry_SetIconScaledUp(control, false)
    self:ClearActiveRewardListRewardData()
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)

    if self.rewardListKeybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.rewardListKeybindStripDescriptor)
    end
end

function ZO_PreviewScreen_Keyboard:OnRewardListEntryMouseUp(control, button, upInside, ctrl, alt, shift, command)
    if not (upInside and button == MOUSE_BUTTON_INDEX_LEFT) then
        return
    end

    local rewardId = control.dataEntry.data.rewardId
    if rewardId == 0 then
        return
    end

    local rewardQuantity = control.dataEntry.data.quantity or 1
    local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, rewardQuantity)
    self:SetActiveRewardListRewardData(rewardData)
    self:BeginPreview(ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW, rewardData)

    self:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.rewardListKeybindStripDescriptor)
end

function ZO_PreviewScreen_Keyboard:OnRewardListClose(control, button, upInside, ctrl, alt, shift, command)
    self:ClearActiveRewardListData()
    self:EndPreview()
end

function ZO_PreviewScreen_Keyboard:SetFocusedControl(control)
    self.focusedControl = control
end

function ZO_PreviewScreen_Keyboard:GetFocusedControl()
    return self.focusedControl
end

function ZO_PreviewScreen_Keyboard:UpdateSceneFragments()
    local scene = self.scene
    local showFullPreview = self:ShouldActivePreviewShowFullPreview()
    if showFullPreview then
        scene:RemoveFragment(self.fragment)
    else
        scene:AddFragment(self.fragment)
    end
end

function ZO_PreviewScreen_Keyboard:UpdatePopupList()
    ZO_Rewards_Shared_OnMouseExit()

    local rewardListData = self:GetActiveRewardListData()
    if not (rewardListData and self:IsShowing()) then
        self.activeRewardListData = nil
        self.activeRewardListRewardData = nil
        POPUP_LIST:Hide()
        return
    end

    local focusedControl = self:GetFocusedControl()
    if focusedControl then
        POPUP_LIST:ShowRewardList(rewardListData:GetRewardId(), self.RewardListEntryMouseEnterHandler, self.RewardListEntryMouseExitHandler, BOTTOMRIGHT, focusedControl, BOTTOMLEFT, -5)
    else
        POPUP_LIST:ShowRewardList(rewardListData:GetRewardId(), self.RewardListEntryMouseEnterHandler, self.RewardListEntryMouseExitHandler, BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -50, -100)
    end

    POPUP_LIST:SetOnMouseUpCallback(self.RewardListEntryMouseUpHandler)
    POPUP_LIST:SetOnCloseCallback(self.RewardListCloseHandler)
end

function ZO_PreviewScreen_Keyboard:UpdatePopupListPosition()
    if self.control:IsHidden() then
        POPUP_LIST:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -50, -100)
    end
end

function ZO_PreviewScreen_Keyboard:ClearActiveRewardListData()
    if not self.activeRewardListData then
        return
    end

    self.activeRewardListData = nil
    self:ClearActiveRewardListRewardData()
    self:UpdatePopupList()
    self:UpdateKeybinds()

    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_PreviewScreen_Keyboard:GetActiveRewardListData()
    return self.activeRewardListData
end

function ZO_PreviewScreen_Keyboard:SetActiveRewardListData(rewardData)
    if self.AreRewardsEqual(rewardData, self.activeRewardListData) then
        self:UpdatePopupListPosition()
        self:UpdateKeybinds()
        return
    end

    self.activeRewardListData = rewardData
    self:ClearActiveRewardListRewardData()
    self:UpdatePopupList()
    self:UpdateKeybinds()
end

function ZO_PreviewScreen_Keyboard:ClearActiveRewardListRewardData()
    self.activeRewardListRewardData = nil
    self:UpdateKeybinds()
end

function ZO_PreviewScreen_Keyboard:GetActiveRewardListRewardData()
    return self.activeRewardListRewardData
end

function ZO_PreviewScreen_Keyboard:SetActiveRewardListRewardData(rewardData)
    self.activeRewardListRewardData = rewardData
    self:UpdateKeybinds()
end

function ZO_PreviewScreen_Keyboard:IsShowingRewardList()
    return self:GetActiveRewardListData() ~= nil
end