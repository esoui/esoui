ZO_TamrielTomesScreen_Keyboard = ZO_TamrielTomesScreen_Shared:Subclass()

function ZO_TamrielTomesScreen_Keyboard:Initialize(control)
    TAMRIEL_TOMES_SCENE_KEYBOARD = ZO_Scene:New("TamrielTomesSceneKeyboard", SCENE_MANAGER)

    local templateData =
    {
        gridClass = ZO_GridScrollList_Keyboard,

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

    self.currencyAmountRollingMeter:SetFont("ZoFontHeader3")

    local currencyIcon = GetCurrencyKeyboardIcon(CURT_TOME_POINTS)
    self.currencyIconControl:SetTexture(currencyIcon)
end

function ZO_TamrielTomesScreen_Keyboard:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = GetString(SI_TAMRIEL_TOMES_CLAIM_ACTION),

            callback = function()
                local selectedData = self:GetSelectedTamrielTomesRewardData()
                if selectedData then
                    selectedData:TryClaimReward()
                end
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

            name = function()
                local IS_PLURAL = false
                local currencyName = GetCurrencyName(CURT_TOME_POINTS, IS_PLURAL)
                return zo_strformat(SI_TAMRIEL_TOMES_ADD_CURRENCY_ACTION, currencyName)
            end,

            callback = function()
                local dialogData = {}
                ZO_Dialogs_ShowDialog("TAMRIEL_TOME_CURRENCY_REDEMPTION_KEYBOARD", dialogData)
            end,

            visible = function()
                return GetPlayerStoredCurrencyAmount(CURT_TOME_POINT_CACHES) > 0
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

function ZO_TamrielTomesScreen_Keyboard:PreviewRewardList(rewardId)
    -- TODO Tamriel Tomes: Clean up this method.

    POPUP_LIST:ClearList()

    local rewardListId = GetRewardListIdFromReward(rewardId)
    local rewards = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
    for _, reward in ipairs(rewards) do
        POPUP_LIST:AddItem(ZO_POPUP_LIST_DATA_TYPE_ITEM, reward)
    end

    POPUP_LIST:UpdateList()

    POPUP_LIST:SetOnMouseEnterCallback(function(control)
        ZO_GridEntry_SetIconScaledUp(control, true)
        ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -5)
        TAMRIEL_TOMES_SCREEN_KEYBOARD:SetSelectedTamrielTomesRewardData(control.dataEntry.data)
    end)

    POPUP_LIST:SetOnMouseExitCallback(function(control)
        ZO_GridEntry_SetIconScaledUp(control, false)
        ZO_Rewards_Shared_OnMouseExit(control)
        TAMRIEL_TOMES_SCREEN_KEYBOARD:SetSelectedTamrielTomesRewardData(nil)
    end)

    POPUP_LIST.control:SetAnchor(RIGHT, self.control, LEFT, -100)
    POPUP_LIST.control:SetHidden(false)
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

function ZO_TamrielTomesScreen_Keyboard:OnSelectedTamrielTomesRewardDataChanged(previousData, newData, previousTileControl, newTileControl)
    ZO_TamrielTomesScreen_Shared.OnSelectedTamrielTomesRewardDataChanged(self, previousData, newData, previousTileControl, newTileControl)

    if newData and newTileControl then
        local rewardControl = newTileControl.object:GetRewardControl()
        ZO_Rewards_Shared_OnMouseEnter(rewardControl, RIGHT, LEFT, -50, 0)
    else
        ClearTooltip(InformationTooltip)
    end
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