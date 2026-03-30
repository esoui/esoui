ZO_TamrielTomesScreen_Keyboard = ZO_TamrielTomesScreen_Shared:Subclass()

function ZO_TamrielTomesScreen_Keyboard:Initialize(control)
    TAMRIEL_TOMES_SCENE_KEYBOARD = ZO_Scene:New("TamrielTomesSceneKeyboard", SCENE_MANAGER)

    local templateData =
    {
        gridClass = ZO_GridScrollList_Keyboard,

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_TOP_MARGIN] =
        {
            entryTemplate = "ZO_TamrielTomes_TopMargin_FullWidth_Shared",
            width = ZO_TAMRIEL_TOMES_REWARD_TOP_MARGIN_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TOP_MARGIN_HEIGHT,
            resetCallback = ZO_ObjectPool_DefaultResetControl,
            setupCallback = ZO_ObjectPool_DefaultAcquireControl,
            isSelectable = false,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_DIVIDER] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardDivider_FullWidth_Keyboard",
            width = ZO_TAMRIEL_TOMES_REWARD_DIVIDER_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_DIVIDER_HEIGHT,
            resetCallback = ZO_ObjectPool_DefaultResetControl,
            setupCallback = ZO_ObjectPool_DefaultAcquireControl,
            isSelectable = false,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_1X_WIDTH] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_1xWidth_Keyboard",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2X_WIDTH_LEFT] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_2xWidth_Left_Keyboard",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_2_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2X_WIDTH_RIGHT] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_2xWidth_Right_Keyboard",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_2_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2_5X_WIDTH_LEFT] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_2_5xWidth_Left_Keyboard",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_2_5_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2_5X_WIDTH_RIGHT] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_2_5xWidth_Right_Keyboard",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_2_5_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },
    }

    ZO_TamrielTomesScreen_Shared.Initialize(self, control, TAMRIEL_TOMES_SCENE_KEYBOARD, templateData)

    SYSTEMS:RegisterKeyboardRootScene("tamrielTomes", self.scene)

    self.RewardListEntryMouseEnterHandler = function(control)
        self:OnRewardListEntryMouseEnter(control)
    end

    self.RewardListEntryMouseExitHandler = function(control)
        self:OnRewardListEntryMouseExit(control)
    end
end

function ZO_TamrielTomesScreen_Keyboard:InitializeControls()
    ZO_TamrielTomesScreen_Shared.InitializeControls(self)

    self.pageNavigation:SetDefaultIndicatorFont("ZoFontCallout")
    self.challengesButton:SetHandler("OnClicked", function() TIMED_ACTIVITIES_MANAGER:ShowTimedActivitiesScene() end)
    self.upgradeButton:SetHandler("OnClicked", function() self:ShowPurchaseScreen() end)
end

function ZO_TamrielTomesScreen_Keyboard:OnDeferredInitialize()
    ZO_TamrielTomesScreen_Shared.OnDeferredInitialize(self)

    self:RebuildGridList()
end

function ZO_TamrielTomesScreen_Keyboard:InitializeCurrencyRollingMeter()
    ZO_TamrielTomesScreen_Shared.InitializeCurrencyRollingMeter(self)

    self.currencyAmountRollingMeter:SetFont("ZoFontHeader")

    local currencyIcon = GetCurrencyKeyboardIcon(CURT_TOME_POINTS)
    self.currencyIconControl:SetTexture(currencyIcon)
end

function ZO_TamrielTomesScreen_Keyboard:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = function()
                local selectedData = self:GetSelectedTamrielTomesRewardData()
                if selectedData then
                    local rewardObject = self:GetTamrielTomesRewardObject(selectedData)
                    if rewardObject then
                        local timeRemainingSeconds = rewardObject:GetClaimRewardTimeRemainingSeconds()
                        if timeRemainingSeconds then
                            return zo_strformat(SI_TAMRIEL_TOMES_CLAIM_ACTION_HELD, ZO_FormatTimeAsDecimalWhenBelowThreshold(timeRemainingSeconds))
                        end
                    end
                end
                return GetString(SI_TAMRIEL_TOMES_CLAIM_ACTION_HOLD)
            end,

            handlesKeyUp = true,

            callback = function(isKeyUp)
                local selectedData = self:GetSelectedTamrielTomesRewardData()
                if not selectedData then
                    return
                end

                if isKeyUp then
                    self:EndClaimReward(selectedData)
                else
                    self:BeginClaimReward(selectedData)
                end
            end,

            enabled = function()
                local selectedData = self:GetSelectedTamrielTomesRewardData()
                return selectedData and selectedData:CanAffordReward()
            end,

            visible = function()
                local selectedData = self:GetSelectedTamrielTomesRewardData()
                return selectedData and selectedData:CanClaimReward()
            end,
        },

        {
            keybind = "UI_SHORTCUT_SECONDARY",

            name = GetString(SI_TAMRIEL_TOMES_PREVIEW_ACTION),

            callback = function()
                local rewardListRewardData = self:GetActiveRewardListRewardData()
                if rewardListRewardData then
                    self:BeginPreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW, rewardListRewardData)
                    return
                end

                local selectedData = self:GetSelectedTamrielTomesRewardData()
                self:BeginPreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW, selectedData:GetRewardData(), selectedData)
            end,

            visible = function()
                local rewardListRewardData = self:GetActiveRewardListRewardData()
                if rewardListRewardData and CanPreviewReward(rewardListRewardData:GetRewardId()) then
                    return true
                end

                local selectedData = self:GetSelectedTamrielTomesRewardData()
                return selectedData and selectedData:CanPreviewReward()
            end,
        },

        {
            keybind = "UI_SHORTCUT_TERTIARY",

            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            enabled = function()
                return GetPlayerStoredCurrencyAmount(CURT_TOME_POINT_CACHES) > 0
            end,

            name = function()
                return zo_strformat(SI_TAMRIEL_TOMES_ADD_CURRENCY_ACTION, ZO_SELECTED_TEXT:Colorize(GetPlayerStoredCurrencyAmount(CURT_TOME_POINT_CACHES)))
            end,

            callback = function()
                local dialogData = {}
                ZO_Dialogs_ShowDialog("TAMRIEL_TOME_CURRENCY_REDEMPTION_KEYBOARD", dialogData)
            end,

            visible = function()
                return self:GetActivePreviewType() ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW
            end,
        },

        {
            keybind = "UI_SHORTCUT_EXIT",

            order = -1000,

            name = function()
                if self:GetActivePreviewType() == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
                    return GetString(SI_TAMRIEL_TOMES_END_PREVIEW_ACTION)
                end

                return GetString(SI_EXIT_BUTTON)
            end,

            callback = function()
                self:ClearActiveRewardListData()

                if self:GetActivePreviewType() == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
                    self:QueueEndPreview(ZO_DEFAULT_QUEUED_END_PREVIEW_DELAY_SECONDS)
                    self:UpdateSceneFragments()
                    return
                end

                SCENE_MANAGER:HideCurrentScene()
            end,
        },
    }
end

function ZO_TamrielTomesScreen_Keyboard:OnRewardListEntryMouseEnter(control)
    ZO_GridEntry_SetIconScaledUp(control, true)
    ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -15)

    local rewardId = control.dataEntry.data.rewardId
    if rewardId == 0 then
        return
    end

    local rewardQuantity = control.dataEntry.data.quantity or 1
    local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, rewardQuantity)
    self:SetActiveRewardListRewardData(rewardData)
    self:BeginPreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW, rewardData)
end

function ZO_TamrielTomesScreen_Keyboard:OnRewardListEntryMouseExit(control)
    ZO_GridEntry_SetIconScaledUp(control, false)
    self:ClearActiveRewardListRewardData()
end

function ZO_TamrielTomesScreen_Keyboard:ClearActiveRewardListData()
    if not self.activeRewardListData then
        return
    end

    self.activeRewardListData = nil
    self:ClearActiveRewardListRewardData()
    self:UpdatePopupList()
end

function ZO_TamrielTomesScreen_Keyboard:GetActiveRewardListData()
    return self.activeRewardListData
end

function ZO_TamrielTomesScreen_Keyboard:SetActiveRewardListData(rewardData)
    if rewardData == self.activeRewardListData then
        self:UpdatePopupListPosition()
        return
    end

    self.activeRewardListData = rewardData
    self:ClearActiveRewardListRewardData()
    self:UpdatePopupList()
end

function ZO_TamrielTomesScreen_Keyboard:ClearActiveRewardListRewardData()
    self.activeRewardListRewardData = nil
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Keyboard:GetActiveRewardListRewardData()
    return self.activeRewardListRewardData
end

function ZO_TamrielTomesScreen_Keyboard:SetActiveRewardListRewardData(rewardData)
    self.activeRewardListRewardData = rewardData
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Keyboard:ShowIntroScreen()
    SCENE_MANAGER:Show("TamrielTomesIntroSceneKeyboard")
end

function ZO_TamrielTomesScreen_Keyboard:ShowPurchaseScreen()
    SCENE_MANAGER:Push("TamrielTomesPurchaseSceneKeyboard")
end

function ZO_TamrielTomesScreen_Keyboard:UpdateSceneFragments()
    local scene = self.scene
    local showFullPreview = self:ShouldActivePreviewShowFullPreview()
    if showFullPreview then
        scene:RemoveFragment(self.fragment)
        scene:RemoveFragment(FRAME_PLAYER_FRAGMENT)
        scene:RemoveFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
        scene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_CENTERED_NO_BLUR)
    else
        scene:RemoveFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_CENTERED_NO_BLUR)
        scene:AddFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
        scene:AddFragment(FRAME_PLAYER_FRAGMENT)
        scene:AddFragment(self.fragment)
    end
end

function ZO_TamrielTomesScreen_Keyboard:OnShowing()
    ZO_TamrielTomesScreen_Shared.OnShowing(self)

    self:UpdateSceneFragments()
end

function ZO_TamrielTomesScreen_Keyboard:OnHiding(...)
    -- Order matters
    ZO_TamrielTomesScreen_Shared.OnHiding(self, ...)
    self:SetSelectedTamrielTomesRewardData(nil)
    ZO_Rewards_Shared_OnMouseExit()
    self:UpdatePopupListPosition()
end

function ZO_TamrielTomesScreen_Keyboard:OnPageChanged(...)
    ZO_TamrielTomesScreen_Shared.OnPageChanged(self, ...)

    self:ClearActiveRewardListData()
    POPUP_LIST:Hide()
end

function ZO_TamrielTomesScreen_Keyboard:UpdatePopupList()
    local rewardListData = self:GetActiveRewardListData()
    if not (rewardListData and self:IsShowing()) then
        self.activeRewardListData = nil
        self.activeRewardListRewardData = nil
        POPUP_LIST:Hide()
        return
    end

    ZO_Rewards_Shared_OnMouseExit()

    local selectedTile = self:GetSelectedTile()
    if selectedTile then
        POPUP_LIST:ShowRewardList(rewardListData:GetRewardId(), self.RewardListEntryMouseEnterHandler, self.RewardListEntryMouseExitHandler, BOTTOMRIGHT, selectedTile, BOTTOMLEFT, -5)
        return
    end

    POPUP_LIST:ShowRewardList(rewardListData:GetRewardId(), self.RewardListEntryMouseEnterHandler, self.RewardListEntryMouseExitHandler, BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -50, -100)
end

function ZO_TamrielTomesScreen_Keyboard:UpdatePopupListPosition()
    if self.control:IsHidden() then
        POPUP_LIST:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -50, -100)
    end
end

function ZO_TamrielTomesScreen_Keyboard:BeginPreviewInternal()
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
    return true
end

function ZO_TamrielTomesScreen_Keyboard:EndPreviewInternal()
    local previewSystem = self.GetPreviewSystem()
    previewSystem:EndCurrentPreview()

    self:RefreshPreviewControls()
    self:UpdateSceneFragments()

    if not self:GetActiveRewardListData() then
        POPUP_LIST:Hide()
    end
end

-- Static methods

function ZO_TamrielTomesScreen_Keyboard.OnControlInitialized(control)
    TAMRIEL_TOMES_SCREEN_KEYBOARD = ZO_TamrielTomesScreen_Keyboard:New(control)
end