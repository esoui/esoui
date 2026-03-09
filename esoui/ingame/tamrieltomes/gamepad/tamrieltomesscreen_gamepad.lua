ZO_TamrielTomesScreen_Gamepad = ZO_Object.MultiSubclass(ZO_TamrielTomesScreen_Shared, ZO_GamepadMultiFocusArea_Manager)

function ZO_TamrielTomesScreen_Gamepad:Initialize(control)
    TAMRIEL_TOMES_SCENE_GAMEPAD = ZO_Scene:New("TamrielTomesSceneGamepad", SCENE_MANAGER)

    self.isShowingFullPreview = false

    local templateData =
    {
        gridClass = ZO_GridScrollList_Gamepad,
        gamepadHighlightTemplate = "ZO_TamrielTomes_Reward_Gamepad_Highlight_Template",

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
            entryTemplate = "ZO_TamrielTomes_RewardDivider_FullWidth_Gamepad",
            width = ZO_TAMRIEL_TOMES_REWARD_DIVIDER_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_DIVIDER_HEIGHT,
            resetCallback = ZO_ObjectPool_DefaultResetControl,
            setupCallback = ZO_ObjectPool_DefaultAcquireControl,
            isSelectable = false,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_1X_WIDTH] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_1xWidth_Gamepad",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2X_WIDTH_LEFT] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_2xWidth_Left_Gamepad",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_2_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2X_WIDTH_RIGHT] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_2xWidth_Right_Gamepad",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_2_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2_5X_WIDTH_LEFT] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_2_5xWidth_Left_Gamepad",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_2_5_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },

        [ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_TYPES.TEMPLATE_2_5X_WIDTH_RIGHT] =
        {
            entryTemplate = "ZO_TamrielTomes_RewardTile_2_5xWidth_Right_Gamepad",
            width = ZO_TAMRIEL_TOMES_REWARD_TILE_2_5_X_WIDTH,
            height = ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT,
            isSelectable = true,
        },
    }

    ZO_TamrielTomesScreen_Shared.Initialize(self, control, TAMRIEL_TOMES_SCENE_GAMEPAD, templateData)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self)

    SYSTEMS:RegisterGamepadRootScene("tamrielTomes", self.scene)
end

function ZO_TamrielTomesScreen_Gamepad:InitializeControls()
    ZO_TamrielTomesScreen_Shared.InitializeControls(self)

    self.pageNavigation:SetDefaultIndicatorFont("ZoFontGamepad42")
    self.gridList:SetHeaderPrePadding(0)
    self.gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)
    self:InitializeMultiFocusAreas()
end

function ZO_TamrielTomesScreen_Gamepad:InitializeGridList()
    ZO_TamrielTomesScreen_Shared.InitializeGridList(self)

    local gridList = self.gridList
    gridList:SetNavigateDownSound(SOUNDS.TAMRIEL_TOMES_MENU_DOWN)
    gridList:SetNavigateLeftSound(SOUNDS.TAMRIEL_TOMES_MENU_LEFT)
    gridList:SetNavigateRightSound(SOUNDS.TAMRIEL_TOMES_MENU_RIGHT)
    gridList:SetNavigateUpSound(SOUNDS.TAMRIEL_TOMES_MENU_UP)
end

function ZO_TamrielTomesScreen_Gamepad:OnDeferredInitialize()
    ZO_TamrielTomesScreen_Shared.OnDeferredInitialize(self)
    self:RebuildGridList()
end

function ZO_TamrielTomesScreen_Gamepad:InitializeCurrencyRollingMeter()
    ZO_TamrielTomesScreen_Shared.InitializeCurrencyRollingMeter(self)

    self.currencyAmountRollingMeter:SetFont("ZoFontGamepad25")

    local currencyIcon = GetCurrencyGamepadIcon(CURT_TOME_POINTS)
    self.currencyIconControl:SetTexture(currencyIcon)
end

function ZO_TamrielTomesScreen_Gamepad:InitializeKeybindStripDescriptor()
    local previousKeybind = self.pageNavigation:GetPreviousPageKeybindDescriptor()
    local nextKeybind = self.pageNavigation:GetNextPageKeybindDescriptor()

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            keybind = "UI_SHORTCUT_PRIMARY",

            name = function()
                if self:IsCurrentFocusArea(self.rewardsFocusArea) then
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
                end
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,

            handlesKeyUp = true,

            callback = function(isKeyUp)
                if self:IsCurrentFocusArea(self.rewardsFocusArea) then
                    local selectedData = self:GetSelectedTamrielTomesRewardData()
                    if not selectedData then
                        return
                    end

                    if isKeyUp then
                        self:EndClaimReward(selectedData)
                    else
                        self:BeginClaimReward(selectedData)
                    end
                elseif self:IsCurrentFocusArea(self.buttonsFocusArea) then
                    local data = self.buttonsFocus:GetFocusItem()
                    if data then
                        data.callback()
                    end
                end
            end,

            enabled = function()
                if self:IsCurrentFocusArea(self.rewardsFocusArea) then
                    local selectedData = self:GetSelectedTamrielTomesRewardData()
                    return selectedData and selectedData:CanAffordReward()
                end

                -- If we're not in rewards, we're in buttons
                local data = self.buttonsFocus:GetFocusItem()
                return data and data.enabled and data.enabled()
            end,

            visible = function()
                if self:GetActivePreviewType() == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
                    return false
                end

                if self:IsCurrentFocusArea(self.rewardsFocusArea) then
                    local selectedData = self:GetSelectedTamrielTomesRewardData()
                    return selectedData and selectedData:CanClaimReward()
                end

                return self:IsCurrentFocusArea(self.buttonsFocusArea)
            end,
        },

        {
            keybind = "UI_SHORTCUT_SECONDARY",

            name = GetString(SI_TAMRIEL_TOMES_PREVIEW_ACTION),

            callback = function()
                local selectedData = self:GetSelectedTamrielTomesRewardData()
                self:BeginPreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW, selectedData:GetRewardData(), selectedData)
            end,

            visible = function()
                if self:GetActivePreviewType() ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
                    local selectedData = self:GetSelectedTamrielTomesRewardData()
                    return selectedData and selectedData:CanPreviewReward()
                end

                return false
            end,
        },

        {
            keybind = "UI_SHORTCUT_TERTIARY",

            enabled = function()
                return GetPlayerStoredCurrencyAmount(CURT_TOME_POINT_CACHES) > 0
            end,

            name = function()
                return zo_strformat(SI_TAMRIEL_TOMES_ADD_CURRENCY_ACTION, ZO_SELECTED_TEXT:Colorize(GetPlayerStoredCurrencyAmount(CURT_TOME_POINT_CACHES)))
            end,

            callback = function()
                local dialogData = {}
                ZO_Dialogs_ShowGamepadDialog("TAMRIEL_TOME_CURRENCY_REDEMPTION_GAMEPAD", dialogData)
            end,

            visible = function()
                return self:GetActivePreviewType() ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW
            end,
        },

        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            keybind = "UI_SHORTCUT_NEGATIVE",

            order = -1500,

            name = GetString(SI_GAMEPAD_BACK_OPTION),

            callback = function()
                SCENE_MANAGER:HideCurrentScene()
            end,
        },

        previousKeybind,
        nextKeybind,
    }
end

function ZO_TamrielTomesScreen_Gamepad:InitializeMultiFocusAreas()
    local function OnButtonFocusChanged()
        self:UpdateKeybinds()
    end

    local viewChallengesButtonFocusData =
    {
        highlight = self.challengesButton:GetNamedChild("Highlight"),
        control = self.challengesButton,
        callback = function()
            PlaySound(SOUNDS.TAMRIEL_TOMES_NAVIGATE_FORWARD)
            ZO_ShowTimedActivities()
        end,
        narrationText = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.challengesButton.text))
            return narrations
        end,
    }

    local upgradeTomeButtonFocusData =
    {
        highlight = self.upgradeButton:GetNamedChild("Highlight"),

        control = self.upgradeButton,

        callback = function()
            PlaySound(SOUNDS.TAMRIEL_TOMES_NAVIGATE_FORWARD)
            self:ShowPurchaseScreen()
        end,

        enabled = function()
            -- TODO Tamriel Tomes: Error Text?
            return self.upgradeButton:GetState() ~= BSTATE_DISABLED
        end,

        narrationText = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.upgradeButton.text))
            return narrations
        end,
    }

    self.buttonsFocus = ZO_GamepadFocus:New(self.buttonContainer, DEFAULT_MOVEMENT_CONTROLLER, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.buttonsFocus:AddEntry(viewChallengesButtonFocusData)
    self.buttonsFocus:AddEntry(upgradeTomeButtonFocusData)
    self.buttonsFocus:SetFocusChangedCallback(OnButtonFocusChanged)

    local function ButtonsActivateCallback()
        self.buttonsFocus:Activate()
    end

    local function ButtonsDeactivateCallback()
        self.buttonsFocus:Deactivate()
    end

    self.buttonsFocusArea = ZO_GamepadMultiFocusArea_Base:New(self, ButtonsActivateCallback, ButtonsDeactivateCallback)
    self:AddNextFocusArea(self.buttonsFocusArea)

    self.rewardsFocusArea = ZO_GridScrollList_Gamepad_FocusArea:New(self.gridList, self)
    self:AddNextFocusArea(self.rewardsFocusArea)
end

function ZO_TamrielTomesScreen_Gamepad:UpdateButtons()
    ZO_TamrielTomesScreen_Shared.UpdateButtons(self)

    local upgradeButtonBorder = self.upgradeButton:GetNamedChild("Border")
    if self.upgradeButton:GetState() == BSTATE_DISABLED then
        upgradeButtonBorder:SetEdgeColor(ZO_DISABLED_TEXT:UnpackRGB())
    else
        upgradeButtonBorder:SetEdgeColor(ZO_NORMAL_TEXT:UnpackRGB())
    end
end

function ZO_TamrielTomesScreen_Gamepad:OnGridSelectionChanged(previousData, newData)
    if newData and self:IsShowing() then
        self:SetSelectedTamrielTomesRewardData(newData)
    end
end

function ZO_TamrielTomesScreen_Gamepad:OnHiding()
    ZO_TamrielTomesScreen_Shared.OnHiding(self)

    self:DeactivateCurrentFocus()
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_TamrielTomesScreen_Gamepad:OnSelectedTamrielTomesRewardDataChanged(previousData, newData, previousTileControl, newTileControl)
    ZO_TamrielTomesScreen_Shared.OnSelectedTamrielTomesRewardDataChanged(self, previousData, newData, previousTileControl, newTileControl)

    local hideTooltip = true
    if newData then
        local rewardData = newData:GetRewardData()
        if rewardData then
            GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, rewardData)
            hideTooltip = false
        end
    end

    if hideTooltip then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_TamrielTomesScreen_Gamepad:OnShowing()
    ZO_TamrielTomesScreen_Shared.OnShowing(self)

    ITEM_PREVIEW_GAMEPAD:GetFragment():SetHideOnSceneHidden(true)
    TAMRIEL_TOMES_SCENE_GROUP_GAMEPAD:SetActiveScene("TamrielTomesSceneGamepad")

    if self:GetCurrentFocus() then
        self:ActivateCurrentFocus()
    else
        self:SelectFocusArea(self.buttonsFocusArea)
        self:ActivateFocusArea(self.buttonsFocusArea)
    end

    DIRECTIONAL_INPUT:Activate(self, self.control)
    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Gamepad:ShouldHideKeybinds()
    local isShowing = self.scene:IsShowing()
    local isFullPreviewing = self:GetActivePreviewType() == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW
    return (not isShowing) or isFullPreviewing
end

function ZO_TamrielTomesScreen_Gamepad:SetSelectedTamrielTomesRewardData(newData)
    if not newData and self:ShouldRetainPreview() then
        -- Suppress clearing the selection while transitioning to a Full Preview.
        return
    end

    ZO_TamrielTomesScreen_Shared.SetSelectedTamrielTomesRewardData(self, newData)
end

function ZO_TamrielTomesScreen_Gamepad:ShowIntroScreen()
    SCENE_MANAGER:SwapCurrentScene("TamrielTomesIntroSceneGamepad")
end

function ZO_TamrielTomesScreen_Gamepad:ShowPurchaseScreen()
    SCENE_MANAGER:Push("TamrielTomesPurchaseSceneGamepad")
end

-- Indicates whether this scene should retain the current preview when hidden.
function ZO_TamrielTomesScreen_Gamepad:ShouldRetainPreview()
    local nextScene = SCENE_MANAGER:GetNextScene()
    return nextScene == TAMRIEL_TOMES_PREVIEW_REWARD_SCENE_GAMEPAD
end

function ZO_TamrielTomesScreen_Gamepad:BeginPreviewInternal()
    local previewType, rewardData, previewKey = self:GetActivePreviewInfo()
    local rewardId = rewardData:GetRewardId()
    local rewardType = rewardData:GetRewardType()

    if rewardType == REWARD_ENTRY_TYPE_REWARD_LIST then
        local rewardListId = GetRewardListIdFromReward(rewardId)
        PREVIEW_REWARD_LIST_SCREEN_GAMEPAD:SetRewardList(rewardListId)
        SCENE_MANAGER:Push("previewRewardList_Gamepad")

        return true
    end

    local previewSystem = self.GetPreviewSystem()
    previewSystem:PreviewReward(rewardId)
    self:RefreshPreviewControls()

    if previewType == ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
        ITEM_PREVIEW_GAMEPAD:GetFragment():SetHideOnSceneHidden(false)
        TAMRIEL_TOMES_REWARD_PREVIEW_SCREEN_GAMEPAD:SetRewardId(rewardId)
        SCENE_MANAGER:Push(TAMRIEL_TOMES_PREVIEW_REWARD_SCENE_GAMEPAD:GetName())
    end

    return true
end

function ZO_TamrielTomesScreen_Gamepad:EndPreviewInternal()
    local previewSystem = self.GetPreviewSystem()
    previewSystem:EndCurrentPreview()
    self:RefreshPreviewControls()
end

-- Static Methods

function ZO_TamrielTomesScreen_Gamepad.OnControlInitialized(control)
    TAMRIEL_TOMES_SCREEN_GAMEPAD = ZO_TamrielTomesScreen_Gamepad:New(control)
end