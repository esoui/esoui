ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_KEYBOARD = 90
ZO_TAMRIEL_TOMES_PURCHASE_VERTICAL_DIVIDER_WIDTH_KEYBOARD = 52
ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_KEYBOARD = 5
ZO_TAMRIEL_TOMES_PURCHASE_GRID_WIDTH_KEYBOARD = ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_KEYBOARD * 4 + ZO_TAMRIEL_TOMES_PURCHASE_VERTICAL_DIVIDER_WIDTH_KEYBOARD + ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_KEYBOARD * 4 + ZO_SCROLL_BAR_WIDTH
ZO_TAMRIEL_TOMES_PURCHASE_GRID_HEIGHT_KEYBOARD = ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_KEYBOARD + 2

ZO_TamrielTomesPurchaseScreen_Keyboard = ZO_TamrielTomesPurchaseScreen_Shared:Subclass()

function ZO_TamrielTomesPurchaseScreen_Keyboard:Initialize(control)
    TAMRIEL_TOMES_PURCHASE_SCENE_KEYBOARD = ZO_Scene:New("TamrielTomesPurchaseSceneKeyboard", SCENE_MANAGER)
    SYSTEMS:RegisterKeyboardRootScene("tamrielTomesPurchase", TAMRIEL_TOMES_PURCHASE_SCENE_KEYBOARD)

    ZO_TamrielTomesPurchaseScreen_Shared.Initialize(self, control, TAMRIEL_TOMES_PURCHASE_SCENE_KEYBOARD)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:OnDeferredInitialize()
    ZO_TamrielTomesPurchaseScreen_Shared.OnDeferredInitialize(self)

    --self.premiumButton:SetClickSound() -- TODO TAMRIEL TOMES
    self.premiumButton:SetHandler("OnClicked", function()
        self:RequestPurchasePremiumTome()
    end)

    self.premiumButton:SetHandler("OnMouseEnter", function()
        if self.premiumButton.productData and self.premiumButton.productData:IsOwned() then
            InitializeTooltip(InformationTooltip, self.premiumButton, RIGHT, 0, 0)
            SetTooltipText(InformationTooltip, GetString(SI_TAMRIEL_TOMES_PREMIUM_UPGRADE_ALREADY_OWNED_TOOLTIP))
        end
    end)

    self.premiumButton:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)

    --self.premiumPlusButton:SetClickSound() -- TODO TAMRIEL TOMES
    self.premiumPlusButton:SetHandler("OnClicked", function()
        self:RequestPurchasePremiumPlusTome()
    end)

    --self.tokenButton:SetClickSound() -- TODO TAMRIEL TOMES
    self.tokenButton:SetHandler("OnClicked", function()
        self:RequestRedeemTomeTokens()
    end)

    self.tokenButton:SetHandler("OnMouseEnter", function()
        -- If premium is owned, you can't use tokens. If both are owned, you can't even be in this screen.
        if self.premiumButton.productData and self.premiumButton.productData:IsOwned() then
            InitializeTooltip(InformationTooltip, self.tokenButton, RIGHT, 0, 0)
            SetTooltipText(InformationTooltip, GetString(SI_TAMRIEL_TOMES_PREMIUM_PLUS_UPGRADE_TOKENS_ALREADY_OWNED_TOOLTIP))
        end
    end)

    self.tokenButton:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:GetRewardEntryTemplate()
    return "ZO_TamrielTomesPurchaseReward_Keyboard"
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:GetVerticalDividerEntryTemplate()
    return "ZO_TamrielTomesPurchaseVerticalDivider_Keyboard"
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:InitializeGridList()
    local DEFAULT_SETUP_FUNCTION = nil
    local DEFAULT_HIDE_CALLBACK = nil
    local DEFAULT_RESET_FUNCTION = nil
    local DEFAULT_CENTER_ENTRIES = nil
    local NOT_SELECTABLE = false

    self.gridList = ZO_GridScrollList_Keyboard:New(self.gridListControl, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)
    local rewardTemplate = self:GetRewardEntryTemplate()
    self.gridList:AddEntryTemplate(rewardTemplate, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_KEYBOARD, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_KEYBOARD, self.RewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, self.RewardGridEntryReset, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_KEYBOARD, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_KEYBOARD)
    local dividerTemplate = self:GetVerticalDividerEntryTemplate()
    self.gridList:AddEntryTemplate(dividerTemplate, ZO_TAMRIEL_TOMES_PURCHASE_VERTICAL_DIVIDER_WIDTH_KEYBOARD, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_KEYBOARD, DEFAULT_SETUP_FUNCTION, DEFAULT_HIDE_CALLBACK, DEFAULT_RESET_FUNCTION, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_KEYBOARD, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_KEYBOARD, DEFAULT_CENTER_ENTRIES, NOT_SELECTABLE)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        -- Start Preview
        {
            name = function()
                return self:GetPreviewFocusedRewardKeybindName()
            end,

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                self:BeginPreviewFocusedReward()
            end,

            visible = function()
                return self:CanPreviewFocusedReward()
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,
        },

        -- End Preview
        {
            name = GetString(SI_TAMRIEL_TOMES_END_PREVIEW_ACTION),

            keybind = "UI_SHORTCUT_NEGATIVE",

            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            callback = function()
                self:EndPreviewFocusedReward()
            end,

            visible = IsCurrentlyPreviewing
        },

        -- Pop the scene to go back
        {
            name = GetString(SI_TAMRIEL_TOMES_BACK_KEYBIND),

            keybind = "UI_SHORTCUT_EXIT",

            order = -10000,

            callback = function()
                SCENE_MANAGER:HideCurrentScene()
            end,
        }
    }
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:OnShowing()
    KEYBIND_STRIP:RemoveDefaultExit()

    ZO_TamrielTomesPurchaseScreen_Shared.OnShowing(self)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:OnHiding()
    ZO_TamrielTomesPurchaseScreen_Shared.OnHiding(self)
    
    -- Just in case we're leaving for any reason other than back (popping the stack), ensure next time we enter back in through the main screen and not purchase
    -- e.g.: ShowBaseScene, or hitting the bind for another menu like Inventory
    TAMRIEL_TOMES_SCENE_GROUP_KEYBOARD:SetActiveScene("TamrielTomesSceneKeyboard")
    POPUP_LIST:Hide()
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:ShowTokenRedemptionDialog()
    local dialogData =
    {
        tomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId(),
    }
    ZO_Dialogs_ShowDialog("TAMRIEL_TOME_TOKEN_REDEMPTION_KEYBOARD", dialogData)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:ShowInsufficientTokenRedemptionDialog()
    local dialogData = {}
    ZO_Dialogs_ShowDialog("TAMRIEL_TOME_INSUFFICIENT_TOKEN_REDEMPTION_KEYBOARD", dialogData)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:OnMouseEnterReward(control)
    ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -5)

    self:SetFocusedRewardControl(control)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:OnMouseExitReward(control)
    ZO_Rewards_Shared_OnMouseExit()
    
    self:SetFocusedRewardControl(nil)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard:BeginPreviewFocusedReward()
    local rewardId = self.focusedRewardData:GetRewardId()
    local rewardType = self.focusedRewardData:GetRewardType()
    if rewardType == REWARD_ENTRY_TYPE_REWARD_LIST then
        ZO_Rewards_Shared_OnMouseExit()

        local function OnMouseEnter(control)
            local IS_POP_UP_REWARD = true
            self:SetFocusedRewardControl(control, IS_POP_UP_REWARD)
        end

        local function OnMouseExit(control)
            self:SetFocusedRewardControl(nil)
        end

        POPUP_LIST:ShowRewardList(rewardId, OnMouseEnter, OnMouseExit, BOTTOMRIGHT, self.focusedRewardControl, BOTTOMLEFT, -5)

        return
    end

    if not self.isFocusedRewardDataPopUp then
        POPUP_LIST:Hide()
    end
    SYSTEMS:GetObject("itemPreview"):PreviewReward(rewardId)
    self:UpdateKeybinds()
end

----
-- XML Functions
----

function ZO_TamrielTomesPurchaseScreen_Keyboard.OnControlInitialized(control)
    TAMRIEL_TOMES_PURCHASE_SCREEN_KEYBOARD = ZO_TamrielTomesPurchaseScreen_Keyboard:New(control)
end
