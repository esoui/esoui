ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_GAMEPAD = 116
ZO_TAMRIEL_TOMES_PURCHASE_VERTICAL_DIVIDER_WIDTH_GAMEPAD = 52
ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_GAMEPAD = 5
ZO_TAMRIEL_TOMES_PURCHASE_GRID_WIDTH_GAMEPAD = ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_GAMEPAD * 4 + ZO_TAMRIEL_TOMES_PURCHASE_VERTICAL_DIVIDER_WIDTH_GAMEPAD + ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_GAMEPAD * 4 + ZO_SCROLL_BAR_WIDTH
ZO_TAMRIEL_TOMES_PURCHASE_GRID_HEIGHT_GAMEPAD = ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_GAMEPAD + 2

ZO_TamrielTomesPurchaseScreen_Gamepad = ZO_Object.MultiSubclass(ZO_TamrielTomesPurchaseScreen_Shared, ZO_GamepadMultiFocusArea_Manager)

function ZO_TamrielTomesPurchaseScreen_Gamepad:Initialize(control)
    TAMRIEL_TOMES_PURCHASE_SCENE_GAMEPAD = ZO_Scene:New("TamrielTomesPurchaseSceneGamepad", SCENE_MANAGER)

    ZO_TamrielTomesPurchaseScreen_Shared.Initialize(self, control, TAMRIEL_TOMES_PURCHASE_SCENE_GAMEPAD)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self)
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:OnDeferredInitialize()
    ZO_TamrielTomesPurchaseScreen_Shared.OnDeferredInitialize(self)

    self:InitializeMultiFocusAreas()

    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnShown", function()
        if self:IsShowing() then
            self:DeactivateInput()
        end
    end, "TamrielTomesPurchaseSceneGamepad")

    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnHidden", function()
        if self:IsShowing() then
            self:ActivateInput()
        end
    end, "TamrielTomesPurchaseSceneGamepad")
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:GetRewardEntryTemplate()
    return "ZO_TamrielTomesPurchaseReward_Gamepad"
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:GetVerticalDividerEntryTemplate()
    return "ZO_TamrielTomesPurchaseVerticalDivider_Gamepad"
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:InitializeGridList()
    local DEFAULT_SELECTION_TEMPLATE = nil
    local DEFAULT_SETUP_FUNCTION = nil
    local DEFAULT_HIDE_CALLBACK = nil
    local DEFAULT_RESET_FUNCTION = nil
    local DEFAULT_CENTER_ENTRIES = nil
    local NOT_SELECTABLE = false

    self.gridList = ZO_GridScrollList_Gamepad:New(self.gridListControl, DEFAULT_SELECTION_TEMPLATE, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)
    local rewardTemplate = self:GetRewardEntryTemplate()
    self.gridList:AddEntryTemplate(rewardTemplate, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_GAMEPAD, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_GAMEPAD, self.RewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, self.RewardGridEntryReset, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_GAMEPAD, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_GAMEPAD)
    local dividerTemplate = self:GetVerticalDividerEntryTemplate()
    self.gridList:AddEntryTemplate(dividerTemplate, ZO_TAMRIEL_TOMES_PURCHASE_VERTICAL_DIVIDER_WIDTH_GAMEPAD, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_DIMENSIONS_GAMEPAD, DEFAULT_SETUP_FUNCTION, DEFAULT_HIDE_CALLBACK, DEFAULT_RESET_FUNCTION, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_GAMEPAD, ZO_TAMRIEL_TOMES_PURCHASE_REWARD_SPACING_GAMEPAD, DEFAULT_CENTER_ENTRIES, NOT_SELECTABLE)
    self.gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridListSelectedDataChanged(...) end)
    self.gridList:SetYDistanceFromEdgeWhereSelectionCausesScroll(10)
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                if self:IsCurrentFocusArea(self.row1ButtonsFocusArea) then
                    local data = self.row1ButtonsFocus:GetFocusItem()
                    if data then
                        data.callback()
                    end
                elseif self:IsCurrentFocusArea(self.row2ButtonsFocusArea) then
                    local data = self.row2ButtonsFocus:GetFocusItem()
                    if data then
                        data.callback()
                    end
                end
            end,
            enabled = function()
                if self:IsCurrentFocusArea(self.row1ButtonsFocusArea) then
                    local data = self.row1ButtonsFocus:GetFocusItem()
                    if data and data.enabled then
                        return data.enabled()
                    end
                elseif self:IsCurrentFocusArea(self.row2ButtonsFocusArea) then
                    local data = self.row2ButtonsFocus:GetFocusItem()
                    if data and data.enabled then
                        return data.enabled()
                    end
                end

                return true
            end,
            visible = function()
                return self:IsCurrentFocusArea(self.row1ButtonsFocusArea) or self:IsCurrentFocusArea(self.row2ButtonsFocusArea)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:InitializeMultiFocusAreas()
    self.gridFocusArea = ZO_GridScrollList_Gamepad_FocusArea:New(self.gridList, self)
    self:AddNextFocusArea(self.gridFocusArea)

    local function OnButtonFocusChanged()
        self:UpdateKeybinds()

        local tooltipShown = false
        if self:IsCurrentFocusArea(self.row1ButtonsFocusArea) then
            if self.row1ButtonsFocus:IsFocused(self.premiumButton) and (self.premiumButton.productData and self.premiumButton.productData:IsOwned())then
                GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_TAMRIEL_TOMES_PREMIUM_UPGRADE_ALREADY_OWNED_TOOLTIP))
                tooltipShown = true
            end
        end

        if not tooltipShown then
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
    end

    local premiumButtonFocusData =
    {
        highlight = self.premiumButton:GetNamedChild("Highlight"),
        control = self.premiumButton,
        callback = function()
            self:RequestPurchasePremiumTome()
        end,
        enabled = function()
            -- TODO Tamriel Tomes: Error Text?
            return self.premiumButton:GetState() ~= BSTATE_DISABLED
        end,
        narrationText = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.premiumButton.text))
            return narrations
        end,
    }

    local premiumPlusButtonFocusData =
    {
        highlight = self.premiumPlusButton:GetNamedChild("Highlight"),
        control = self.premiumPlusButton,
        callback = function()
            self:RequestPurchasePremiumPlusTome()
        end,
        narrationText = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.premiumPlusButton.text))
            return narrations
        end,
    }

    self.row1ButtonsFocus = ZO_GamepadFocus:New(self.row1ButtonContainer, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.row1ButtonsFocus:AddEntry(premiumButtonFocusData)
    self.row1ButtonsFocus:AddEntry(premiumPlusButtonFocusData)
    self.row1ButtonsFocus:SetFocusChangedCallback(OnButtonFocusChanged)

    local function Row1ButtonsActivateCallback()
        self.row1ButtonsFocus:Activate()
    end

    local function Row1ButtonsDeactivateCallback()
        self.row1ButtonsFocus:Deactivate()
    end

    self.row1ButtonsFocusArea = ZO_GamepadMultiFocusArea_Base:New(self, Row1ButtonsActivateCallback, Row1ButtonsDeactivateCallback)

    self:AddNextFocusArea(self.row1ButtonsFocusArea)

    local tokenButtonFocusData =
    {
        highlight = self.tokenButton:GetNamedChild("Highlight"),
        control = self.tokenButton,
        callback = function()
            self:RequestRedeemTomeTokens()
        end,
        enabled = function()
            -- TODO Tamriel Tomes: Error Text?
            return self.tokenButton:GetState() ~= BSTATE_DISABLED
        end,
        narrationText = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.tokenButton.text))
            return narrations
        end,
    }

    self.row2ButtonsFocus = ZO_GamepadFocus:New(self.row2ButtonContainer, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.row2ButtonsFocus:AddEntry(tokenButtonFocusData)
    self.row2ButtonsFocus:SetFocusChangedCallback(OnButtonFocusChanged)

    local function Row2ButtonsActivateCallback()
        self.row2ButtonsFocus:Activate()
    end

    local function Row2ButtonsDeactivateCallback()
        self.row2ButtonsFocus:Deactivate()
    end

    self.row2ButtonsFocusArea = ZO_GamepadMultiFocusArea_Base:New(self, Row2ButtonsActivateCallback, Row2ButtonsDeactivateCallback)

    self:AddNextFocusArea(self.row2ButtonsFocusArea)
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:ActivateInput()
    self:ActivateCurrentFocus()
    DIRECTIONAL_INPUT:Activate(self, self.control)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:DeactivateInput()
    self:DeactivateCurrentFocus()
    DIRECTIONAL_INPUT:Deactivate(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:OnShowing()
    ZO_TamrielTomesPurchaseScreen_Shared.OnShowing(self)

    TAMRIEL_TOMES_SCENE_GROUP_GAMEPAD:SetActiveScene("TamrielTomesPurchaseSceneGamepad")

    self:SelectFocusArea(self.row1ButtonsFocusArea)
    self:ActivateInput()
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:OnHiding()
    ZO_TamrielTomesPurchaseScreen_Shared.OnHiding(self)

    -- Just in case we're leaving for any reason other than back (popping the stack), ensure next time we enter back in through the main screen and not purchase
    -- e.g.: ShowBaseScene, or hitting the bind for another menu like Inventory

    TAMRIEL_TOMES_SCENE_GROUP_GAMEPAD:SetActiveScene("TamrielTomesSceneGamepad")
    self:DeactivateInput()
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:OnGridListSelectedDataChanged(previousData, newData)
    if not self.gridList:IsActive() then
        return
    end

    if newData then
        GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, newData)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end

    self.selectedGridEntry = newData
    self:UpdateKeybinds()
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:UpdateButtonVisuals(button)
    local buttonBorder = button:GetNamedChild("Border")
    if button:GetState() == BSTATE_DISABLED then
        buttonBorder:SetEdgeColor(ZO_DISABLED_TEXT:UnpackRGB())
    else
        buttonBorder:SetEdgeColor(ZO_NORMAL_TEXT:UnpackRGB())
    end
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:UpdateButtons()
    ZO_TamrielTomesPurchaseScreen_Shared.UpdateButtons(self)

    self:UpdateButtonVisuals(self.premiumButton)
    self:UpdateButtonVisuals(self.premiumPlusButton)
    self:UpdateButtonVisuals(self.tokenButton)
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:ShowTokenRedemptionDialog()
    local dialogData =
    {
        tomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId(),
    }
    ZO_Dialogs_ShowGamepadDialog("TAMRIEL_TOME_TOKEN_REDEMPTION_GAMEPAD", dialogData)
end

function ZO_TamrielTomesPurchaseScreen_Gamepad:ShowInsufficientTokenRedemptionDialog()
    local dialogData = {}
    ZO_Dialogs_ShowGamepadDialog("TAMRIEL_TOME_INSUFFICIENT_TOKEN_REDEMPTION_GAMEPAD", dialogData)
end

----
-- XML Functions
----

function ZO_TamrielTomesPurchaseScreen_Gamepad.OnControlInitialized(control)
    TAMRIEL_TOMES_PURCHASE_SCREEN_GAMEPAD = ZO_TamrielTomesPurchaseScreen_Gamepad:New(control)
end