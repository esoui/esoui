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

    self.HideRewardListHandler = function()
        self:EndPreviewRewardList()
    end
end

function ZO_TamrielTomesScreen_Keyboard:InitializeControls()
    ZO_TamrielTomesScreen_Shared.InitializeControls(self)

    self.pageNavigation:SetDefaultIndicatorFont("ZoFontCallout")
    self.challengesButton:SetHandler("OnClicked", ZO_ShowTimedActivities)
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
                local selectedData = self:GetSelectedTamrielTomesRewardData()
                self:BeginPreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW, selectedData)
            end,

            visible = function()
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
                return self:GetCurrentPreviewType() ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW
            end,
        },

        {
            keybind = "UI_SHORTCUT_NEGATIVE",

            name = GetString(SI_TAMRIEL_TOMES_END_PREVIEW_ACTION),

            callback = function()
                self:EndPreview()
            end,

            visible = function()
                return self:GetCurrentPreviewType() == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW
            end,
        },
    }
end

function ZO_TamrielTomesScreen_Keyboard:EndPreviewInternal()
    ZO_TamrielTomesScreen_Shared.EndPreviewInternal(self)

    self:UpdateSceneFragments()
end

function ZO_TamrielTomesScreen_Keyboard:EndPreviewRewardList()
    EVENT_MANAGER:UnregisterForUpdate("ZO_TamrielTomesScreen_Keyboard_HideRewardList")

    if self.currentPreviewRewardListId then
        POPUP_LIST:Hide()
        ZO_Rewards_Shared_OnMouseExit()
        self.currentPreviewRewardListId = nil
    end
end

function ZO_TamrielTomesScreen_Keyboard:PreviewRewardList(rewardId, tileControl)
    POPUP_LIST:ClearList()

    local rewardListId = GetRewardListIdFromReward(rewardId)
    self.currentPreviewRewardListId = rewardListId

    local rewards = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
    for _, reward in ipairs(rewards) do
        POPUP_LIST:AddItem(ZO_POPUP_LIST_DATA_TYPE_ITEM, reward)
    end

    POPUP_LIST:UpdateList()
    POPUP_LIST:SetOnMouseEnterCallback(self.RewardListEntryMouseEnterHandler)
    POPUP_LIST:SetOnMouseExitCallback(self.RewardListEntryMouseExitHandler)
    POPUP_LIST.control:SetAnchor(RIGHT, tileControl or self.control, LEFT, -10)
    POPUP_LIST.control:SetHidden(false)
end

function ZO_TamrielTomesScreen_Keyboard:OnRewardListEntryMouseEnter(control)
    EVENT_MANAGER:UnregisterForUpdate("ZO_TamrielTomesScreen_Keyboard_HideRewardList")

    ZO_GridEntry_SetIconScaledUp(control, true)
    ZO_Rewards_Shared_OnMouseEnter(control, LEFT, RIGHT, 5)
    local rewardId = control.dataEntry.data.rewardId
    self:QuickPreviewRewardInternal(rewardId)
end

function ZO_TamrielTomesScreen_Keyboard:OnRewardListEntryMouseExit(control)
    ZO_GridEntry_SetIconScaledUp(control, false)

    EVENT_MANAGER:RegisterForUpdate("ZO_TamrielTomesScreen_Keyboard_HideRewardList", 600, self.HideRewardListHandler)
end

function ZO_TamrielTomesScreen_Keyboard:OnBeginActivePreview()
    self:EndPreviewRewardList()

    ZO_TamrielTomesScreen_Shared.OnBeginActivePreview(self)

    SCENE_MANAGER:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_CENTERED_NO_BLUR)
end

function ZO_TamrielTomesScreen_Keyboard:OnBeginQuickPreview()
    self:EndPreviewRewardList()

    ZO_TamrielTomesScreen_Shared.OnBeginQuickPreview(self)
end

function ZO_TamrielTomesScreen_Keyboard:OnEndActivePreview()
    ZO_TamrielTomesScreen_Shared.OnEndActivePreview(self)

    SCENE_MANAGER:RemoveFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_CENTERED_NO_BLUR)
    FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT.UpdateTarget()
end

function ZO_TamrielTomesScreen_Keyboard:OnShowing()
    ZO_TamrielTomesScreen_Shared.OnShowing(self)

    self:UpdateSceneFragments()
end

function ZO_TamrielTomesScreen_Keyboard:OnHiding()
    self:SetSelectedTamrielTomesRewardData(nil)

    ZO_TamrielTomesScreen_Shared.OnHiding(self)
end

function ZO_TamrielTomesScreen_Keyboard:OnPreviewedTamrielTomesRewardDataChanged(previousTamrielTomesRewardData, newTamrielTomesRewardData)
    ZO_TamrielTomesScreen_Shared.OnPreviewedTamrielTomesRewardDataChanged(self, previousTamrielTomesRewardData, newTamrielTomesRewardData)

    self:UpdateSceneFragments()
end

function ZO_TamrielTomesScreen_Keyboard:ShowIntroScreen()
    SCENE_MANAGER:Show("TamrielTomesIntroSceneKeyboard")
end

function ZO_TamrielTomesScreen_Keyboard:ShowPurchaseScreen()
    SCENE_MANAGER:Push("TamrielTomesPurchaseSceneKeyboard")
end

function ZO_TamrielTomesScreen_Keyboard:UpdateSceneFragments()
    if self:GetCurrentPreviewType() == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        self.scene:RemoveFragment(self.fragment)
    else
        self.scene:AddFragment(self.fragment)
    end
end

function ZO_TamrielTomesScreen_Keyboard.OnControlInitialized(control)
    TAMRIEL_TOMES_SCREEN_KEYBOARD = ZO_TamrielTomesScreen_Keyboard:New(control)
end