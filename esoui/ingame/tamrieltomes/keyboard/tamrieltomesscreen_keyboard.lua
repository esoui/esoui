ZO_TAMRIEL_TOME_SEASON_ENTRY_BORDER_KEYBOARD_WIDTH = 6
ZO_TAMRIEL_TOME_SEASON_ENTRY_IMAGE_KEYBOARD_WIDTH = 614
ZO_TAMRIEL_TOME_SEASON_ENTRY_IMAGE_KEYBOARD_HEIGHT = 307
ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_PADDING = 8
ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_WIDTH = ZO_TAMRIEL_TOME_SEASON_ENTRY_IMAGE_KEYBOARD_WIDTH + ZO_TAMRIEL_TOME_SEASON_ENTRY_BORDER_KEYBOARD_WIDTH
ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_HEIGHT = ZO_TAMRIEL_TOME_SEASON_ENTRY_IMAGE_KEYBOARD_HEIGHT + ZO_TAMRIEL_TOME_SEASON_ENTRY_BORDER_KEYBOARD_WIDTH
ZO_TAMRIEL_TOME_SEASON_GRID_KEYBOARD_WIDTH = ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_WIDTH + 24
ZO_TAMRIEL_TOME_SEASON_DIALOG_KEYBOARD_WIDTH = ZO_TAMRIEL_TOME_SEASON_GRID_KEYBOARD_WIDTH + 40
ZO_TAMRIEL_TOME_SEASON_DIALOG_KEYBOARD_MAX_HEIGHT = ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_HEIGHT * 2.1

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

    SYSTEMS:RegisterKeyboardObject("tamrielTomes", self)
    SYSTEMS:RegisterKeyboardRootScene("tamrielTomes", self.scene)

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

function ZO_TamrielTomesScreen_Keyboard:InitializeControls()
    ZO_TamrielTomesScreen_Shared.InitializeControls(self)

    self.pageNavigation:SetDefaultIndicatorFont("ZoFontCallout")
    self.challengesButton:SetHandler("OnClicked", function() TIMED_ACTIVITIES_MANAGER:ShowTimedActivitiesScene() end)
    self.upgradeButton:SetHandler("OnClicked", function() self:ShowPurchaseScreen() end)
    self.selectTomeButton:SetHandler("OnClicked", function() self:ShowSelectTomeDialog() end)
end

function ZO_TamrielTomesScreen_Keyboard:OnDeferredInitialize()
    ZO_TamrielTomesScreen_Shared.OnDeferredInitialize(self)

    self:RebuildGridList()
end

function ZO_TamrielTomesScreen_Keyboard:InitializeCurrencyRollingMeter()
    ZO_TamrielTomesScreen_Shared.InitializeCurrencyRollingMeter(self)

    self.currencyAmountRollingMeter:SetFont("ZoFontHeader2")

    local currencyIcon = GetCurrencyKeyboardIcon(CURT_TOME_POINTS)
    self.currencyIconControl:SetTexture(currencyIcon)
end

function ZO_TamrielTomesScreen_Keyboard:InitializeKeybindStripDescriptors()
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
                if rewardListRewardData then
                    return CanPreviewReward(rewardListRewardData:GetRewardId()) and
                        (self:GetActivePreviewType() ~= ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW or
                         not self.AreRewardsEqual(rewardListRewardData, self.activePreviewRewardData))
                end

                local selectedData = self:GetSelectedTamrielTomesRewardData()
                if selectedData and selectedData:GetRewardData() == self:GetActiveRewardListData() then
                    return false
                end

                return not ITEM_PREVIEW_KEYBOARD:IsWaitingForPreviewBegin()
                    and selectedData and selectedData:CanPreviewReward()
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

    local _, screenCenterY = GuiRoot:GetCenter()
    local controlTopY = control:GetTop()
    local controlBottomY = control:GetBottom()
    local anchorFrom = BOTTOM
    local anchorTo = TOP
    local offsetY
    if zo_abs(screenCenterY - controlTopY) > zo_abs(screenCenterY - controlBottomY) then
        anchorFrom = TOP
        anchorTo = BOTTOM
        offsetY = POPUP_LIST:GetControl():GetBottom() - controlBottomY + 20
    else
        offsetY = POPUP_LIST:GetControl():GetTop() - controlTopY - 10
    end
    ZO_Rewards_Shared_OnMouseEnter(control, anchorFrom, anchorTo, 0, offsetY)

    local rewardId = control.dataEntry.data.rewardId
    if rewardId == 0 then
        self:UpdateKeybinds()
        return
    end

    local rewardQuantity = control.dataEntry.data.quantity or 1
    local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, rewardQuantity)
    self:SetActiveRewardListRewardData(rewardData)
    self:BeginPreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW, rewardData)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PREVIEW)
end

function ZO_TamrielTomesScreen_Keyboard:OnRewardListEntryMouseExit(control)
    ZO_GridEntry_SetIconScaledUp(control, false)
    self:ClearActiveRewardListRewardData()
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_TamrielTomesScreen_Keyboard:OnRewardListEntryMouseUp(control, button, upInside, ctrl, alt, shift, command)
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
    self:BeginPreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW, rewardData)

    self:UpdateKeybinds()
end

function ZO_TamrielTomesScreen_Keyboard:OnRewardListClose(control, button, upInside, ctrl, alt, shift, command)
    self:ClearActiveRewardListData()
    self:EndPreview()
end

function ZO_TamrielTomesScreen_Keyboard:ClearActiveRewardListData()
    if not self.activeRewardListData then
        return
    end

    self.activeRewardListData = nil
    self:ClearActiveRewardListRewardData()
    self:UpdatePopupList()
    self:UpdateKeybinds()

    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_TamrielTomesScreen_Keyboard:GetActiveRewardListData()
    return self.activeRewardListData
end

function ZO_TamrielTomesScreen_Keyboard:SetActiveRewardListData(rewardData)
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

function ZO_TamrielTomesScreen_Keyboard:ShowSelectTomeDialog()
    if self:CanSelectTome() then
        SCENE_MANAGER:HideCurrentScene()
        ZO_Dialogs_ShowPlatformDialog("TamrielTomesSelectSeasonDialogKeyboard", {})
    end
end

function ZO_TamrielTomesScreen_Keyboard:HideSelectTomeDialog()
    ZO_Dialogs_ReleaseDialog("TamrielTomesSelectSeasonDialogKeyboard")
end

function ZO_TamrielTomesScreen_Keyboard:UpdateSceneFragments()
    local scene = self.scene
    local showFullPreview = self:ShouldActivePreviewShowFullPreview()
    if showFullPreview then
        scene:RemoveFragment(self.fragment)
        scene:RemoveFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
        scene:AddFragment(FRAME_TARGET_CENTERED_FRAGMENT)
    else
        scene:RemoveFragment(FRAME_TARGET_CENTERED_FRAGMENT)
        scene:AddFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
        scene:AddFragment(self.fragment)
    end
end

function ZO_TamrielTomesScreen_Keyboard:OnShowing()
    ZO_TamrielTomesScreen_Shared.OnShowing(self)

    self:UpdateSceneFragments()
end

function ZO_TamrielTomesScreen_Keyboard:OnHiding(...)
    ZO_TamrielTomesScreen_Shared.OnHiding(self, ...)

    -- Order matters
    self:SetSelectedTamrielTomesRewardData(nil)
    self:ClearActiveRewardListData()
end

function ZO_TamrielTomesScreen_Keyboard:OnPageChanged(...)
    ZO_TamrielTomesScreen_Shared.OnPageChanged(self, ...)

    self:ClearActiveRewardListData()
    POPUP_LIST:Hide()
end

function ZO_TamrielTomesScreen_Keyboard:UpdatePopupList()
    ZO_Rewards_Shared_OnMouseExit()

    local rewardListData = self:GetActiveRewardListData()
    if not (rewardListData and self:IsShowing()) then
        self.activeRewardListData = nil
        self.activeRewardListRewardData = nil
        POPUP_LIST:Hide()
        return
    end

    local selectedTile = self:GetSelectedTile()
    local selectedTileRewardControl = selectedTile and selectedTile:GetNamedChild("Reward") or nil
    if selectedTileRewardControl then
        POPUP_LIST:SetShowTooltipCallback(function(control)
            ZO_Rewards_Shared_OnMouseEnter(control, BOTTOM, TOP, 0, -5)
        end)
        POPUP_LIST:ShowRewardList(rewardListData:GetRewardId(), self.RewardListEntryMouseEnterHandler, self.RewardListEntryMouseExitHandler, BOTTOM, selectedTileRewardControl, TOP, 0, -5)
    else
        POPUP_LIST:ShowRewardList(rewardListData:GetRewardId(), self.RewardListEntryMouseEnterHandler, self.RewardListEntryMouseExitHandler, BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -50, -100)
    end

    POPUP_LIST:SetOnMouseUpCallback(self.RewardListEntryMouseUpHandler)
    POPUP_LIST:SetOnCloseCallback(self.RewardListCloseHandler)
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
    self:UpdateKeybinds()
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

    self:UpdateKeybinds()
end

-- Static methods

function ZO_TamrielTomesScreen_Keyboard.OnControlInitialized(control)
    TAMRIEL_TOMES_SCREEN_KEYBOARD = ZO_TamrielTomesScreen_Keyboard:New(control)
end


ZO_SelectTamrielTomeSeasonDialog_Keyboard = ZO_InitializingObject:Subclass()

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:Initialize(control)
    self.control = control
    self.templateData =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        entryTemplate = "ZO_TamrielTomeSeasonEntry_Keyboard",
        entryWidth = ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_WIDTH,
        entryHeight = ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_HEIGHT,
    }

    self:InitializeControls()
    self:InitializeGridList()
    self:InitializeDialog()
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:InitializeControls()
    self.contentControl = self.control:GetNamedChild("ContentContainer")
    self.gridControl = self.contentControl:GetNamedChild("TomesGrid")
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:InitializeDialog()
    self.dialogName = "TamrielTomesSelectSeasonDialogKeyboard"

    local tomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    local control = self.control
    ZO_Dialogs_RegisterCustomDialog(self.dialogName,
    {
        title =
        {
            text = SI_TAMRIEL_TOMES_SELECT_TOME_DIALOG_NAME_LABEL,
        },

        mainText =
        {
            text = "",
        },

        finishedCallback = function(dialog)
            if not ZO_TamrielTomeSeasonGridEntry_Shared.IsSelectionPending() then
                -- No selection was made; return to this Tome.
                TAMRIEL_TOMES_MANAGER:OpenTamrielTome(tomeId)
            end
        end,

        setup = function(dialog, data)
            CHAT_SYSTEM:Minimize()
            dialog.object = self
            self:BuildGridList()
            self:UpdateButtonStates()
        end,

        customControl = control,

        buttons =
        {
            {
                control = control:GetNamedChild("Select"),
                text = SI_DIALOG_CONFIRM,
                requiresTextInput = false,
                noReleaseOnClick = true,
                callback = function(dialog)
                    if self.targetGridEntry then
                        self.targetGridEntry:Select()
                    end
                end,
                enabled = function()
                    return self.targetGridEntry and not self.targetGridEntry:IsSelected()
                end,
            },

            {
                control = control:GetNamedChild("Close"),
                text = SI_DIALOG_CLOSE,
                requiresTextInput = false,
                noReleaseOnClick = false,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialog(self.dialogName)
                end
            },
        },
    })
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:InitializeGridList()
    local templateData = self.templateData
    self.gridList = templateData.gridListClass:New(self.gridControl, templateData.highlightTemplate)

    local function SetupGridEntry(...)
        self:SetupGridEntry(...)
    end

    local NO_HIDE_CALLBACK = nil
    local NO_RESET_CALLBACK = nil
    local GRID_PADDING = ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_PADDING
    self.gridList:AddEntryTemplate(templateData.entryTemplate, templateData.entryWidth, templateData.entryHeight, SetupGridEntry, NO_HIDE_CALLBACK, NO_RESET_CALLBACK, GRID_PADDING, GRID_PADDING)
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:BuildGridList()
    self.gridList:ClearGridList()
    self:PopulateGridList()
    self.gridList:CommitGridList()
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:PopulateGridList()
    local entryTemplate = self.templateData.entryTemplate
    local tomeIds = TAMRIEL_TOMES_MANAGER:GetAvailableTomeIds()
    for tomeIndex, tomeId in ipairs(tomeIds) do
        local entryData = self:CreateGridEntryData(tomeId)
        self.gridList:AddEntry(entryData, entryTemplate)
    end

    local numVisibleTomes = zo_max(1, #tomeIds)
    local minGridHeight = numVisibleTomes * (ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_HEIGHT + ZO_TAMRIEL_TOME_SEASON_ENTRY_KEYBOARD_PADDING)
    minGridHeight = zo_min(minGridHeight, ZO_TAMRIEL_TOME_SEASON_DIALOG_KEYBOARD_MAX_HEIGHT)
    local MIN_X = nil
    self.gridControl:SetDimensionConstraints(MIN_X, minGridHeight)
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:CreateGridEntryData(tomeId)
    local tomeData = ZO_TamrielTomeData:New(tomeId)
    local entryData =
    {
        tomeData = tomeData,
        text = tomeData:GetDisplayName(),
        clickSound = SOUNDS.TAMRIEL_TOMES_BOOK_OPENED,
        narrationText = self.templateData.narrationText,
    }

    return entryData
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:SetTargetGridEntry(entry)
    self.targetGridEntry = entry
    self:UpdateButtonStates()
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:SetupGridEntry(control, data)
    control.object:Setup(data, self)
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard:UpdateButtonStates()
    ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(self.control)
end

function ZO_SelectTamrielTomeSeasonDialog_Keyboard.OnInitialized(control)
    control.object = ZO_SelectTamrielTomeSeasonDialog_Keyboard:New(control)
end


ZO_TamrielTomeSeasonEndDialog_Keyboard = ZO_TamrielTomeSeasonEndDialog_Shared:Subclass()

function ZO_TamrielTomeSeasonEndDialog_Keyboard:Initialize(control)
    -- Order matters:
    TAMRIEL_TOME_SEASON_END_DIALOG_KEYBOARD = self
    self.dialogName = "TamrielTomesSeasonEndDialogKeyboard"
    self.templateData =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        entryTemplate = "ZO_TamrielTomeSeasonEndEntry_Keyboard",
        entryWidth = ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_WIDTH,
        entryHeight = ZO_TAMRIEL_TOME_SEASON_END_REWARD_ENTRY_HEIGHT,
    }
    ZO_TamrielTomeSeasonEndDialog_Shared.Initialize(self, control)
end

function ZO_TamrielTomeSeasonEndDialog_Keyboard.OnInitialized(control)
    control.object = ZO_TamrielTomeSeasonEndDialog_Keyboard:New(control)
end