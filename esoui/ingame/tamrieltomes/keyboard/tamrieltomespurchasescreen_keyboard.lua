ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_KEYBOARD = 116
ZO_TAMRIEL_TOMES_PURCHASE_VERTICAL_DIVIDER_WIDTH_KEYBOARD = 52
ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_KEYBOARD = 5
ZO_TAMRIEL_TOMES_PURCHASE_GRID_WIDTH_KEYBOARD = ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_KEYBOARD * 4 + ZO_TAMRIEL_TOMES_PURCHASE_VERTICAL_DIVIDER_WIDTH_KEYBOARD + ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_KEYBOARD * 4 + ZO_SCROLL_BAR_WIDTH
ZO_TAMRIEL_TOMES_PURCHASE_GRID_HEIGHT_KEYBOARD = ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_KEYBOARD + 2

ZO_TamrielTomesPurchaseScreen_Keyboard = ZO_TamrielTomesPurchaseScreen_Shared:Subclass()

function ZO_TamrielTomesPurchaseScreen_Keyboard:Initialize(control)
    TAMRIEL_TOMES_PURCHASE_SCENE_KEYBOARD = ZO_Scene:New("TamrielTomesPurchaseSceneKeyboard", SCENE_MANAGER)

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
        {
            -- Pop the scene to go back
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

----
-- XML Functions
----

function ZO_TamrielTomesPurchaseScreen_Keyboard.OnControlInitialized(control)
    TAMRIEL_TOMES_PURCHASE_SCREEN_KEYBOARD = ZO_TamrielTomesPurchaseScreen_Keyboard:New(control)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard.Reward_OnMouseEnter(control)
    ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -5)

    --TAMRIEL_TOMES_PURCHASE_SCREEN_KEYBOARD:OnMouseEnterReward(control)
end

function ZO_TamrielTomesPurchaseScreen_Keyboard.Reward_OnMouseExit(control)
    ZO_Rewards_Shared_OnMouseExit(control)

    --TAMRIEL_TOMES_PURCHASE_SCREEN_KEYBOARD:OnMouseExitReward(control)
end
