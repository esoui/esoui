ZO_ItemPreview_Gamepad = ZO_ItemPreview_Shared:Subclass()

function ZO_ItemPreview_Gamepad:Initialize(control)
    ZO_ItemPreview_Shared.Initialize(self, control)

    control.owner = self
    self.control = control

    local function CreateIconLabel(name, parent, actionName)
        local iconLabel = CreateControlFromVirtual(name, parent, "ZO_ClickableKeybindLabel_Gamepad")
        iconLabel:SetKeybind(actionName)
        iconLabel:SetHidden(true)
        return iconLabel
    end

    PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("PreviewStateNavigation")

    self.variationLabel = control:GetNamedChild("VariationLabel")
    self.previewVariationLeftIcon = CreateIconLabel("$(parent)PreviewLeftIcon", control, "PREVIEW_PREVIOUS_VARIATION")
    self.previewVariationRightIcon = CreateIconLabel("$(parent)PreviewRightIcon", control, "PREVIEW_NEXT_VARIATION")

    self.previewVariationLeftIcon:SetAnchor(RIGHT, self.variationLabel, LEFT, -32)
    self.previewVariationRightIcon:SetAnchor(LEFT, self.variationLabel, RIGHT, 32)

    self.actionLabel = control:GetNamedChild("ActionLabel")
    self.previewActionLeftIcon = CreateIconLabel("$(parent)PreviewActionLeftIcon", control, "PREVIEW_PREVIOUS_ACTION")
    self.previewActionRightIcon = CreateIconLabel("$(parent)PreviewActionRightIcon", control, "PREVIEW_NEXT_ACTION")

    self.previewActionLeftIcon:SetAnchor(RIGHT, self.actionLabel, LEFT, -32)
    self.previewActionRightIcon:SetAnchor(LEFT, self.actionLabel, RIGHT, 32)
end

function ZO_ItemPreview_Gamepad:GetPreviewSpinnerNarrationText()
    local ENABLED = true
    local narrations = {}
    if self:HasActions() then
        ZO_AppendNarration(narrations, ZO_FormatSpinnerNarrationText(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_ACTION_TITLE), self.currentPreviewTypeObject:GetActionName(self.previewVariationIndex, self.previewActionIndex)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetKeybindNarrationFromData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_PREVIOUS), "PREVIEW_PREVIOUS_ACTION", ENABLED))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetKeybindNarrationFromData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_NEXT), "PREVIEW_NEXT_ACTION", ENABLED))
    end
    if self:HasVariations() then
        ZO_AppendNarration(narrations, ZO_FormatSpinnerNarrationText(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_TITLE), self.currentPreviewTypeObject:GetVariationName(self.previewVariationIndex)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetKeybindNarrationFromData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_PREVIOUS), "PREVIEW_PREVIOUS_VARIATION", ENABLED))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetKeybindNarrationFromData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_NEXT), "PREVIEW_NEXT_VARIATION", ENABLED))
    end
    return narrations
end

function ZO_ItemPreview_Gamepad:GetPreviewActionSpinnerNarrationText()
    if self:HasActions() then
        return ZO_FormatSpinnerNarrationText(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_TITLE), self.currentPreviewTypeObject:GetActionName(self.previewVariationIndex, self.previewActionIndex))
    end
    return nil
end

function ZO_ItemPreview_Gamepad:SetCanChangePreview(canChangePreview)
    ZO_ItemPreview_Shared.SetCanChangePreview(self, canChangePreview)

    if canChangePreview then
        self.variationLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
        self.actionLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    else
        self.variationLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
        self.actionLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
    end

    self:FireCallbacks("RefreshActions")
end

function ZO_ItemPreview_Gamepad:Apply()
    ZO_ItemPreview_Shared.Apply(self)
    self:FireCallbacks("RefreshActions")
end

function ZO_ItemPreview_Gamepad:OnPreviewShowing()
    ZO_ItemPreview_Shared.OnPreviewShowing(self)
    SCENE_MANAGER:AddFragment(PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT)
end

function ZO_ItemPreview_Gamepad:OnPreviewHidden()
    ZO_ItemPreview_Shared.OnPreviewHidden(self)
    SCENE_MANAGER:RemoveFragment(PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT)
end

function ZO_ItemPreview_Gamepad:TryPreviewNextVariation(playClickSound)
    if self.currentPreviewTypeObject and self.numPreviewVariations > 1 and self.canChangePreview then
        self:PreviewNextVariation()
        if playClickSound then
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
        return true
    end
    return false
end

function ZO_ItemPreview_Gamepad:TryPreviewPreviousVariation(playClickSound)
    if self.currentPreviewTypeObject and self.numPreviewVariations > 1 and self.canChangePreview then
        self:PreviewPreviousVariation()
        if playClickSound then
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
        return true
    end
    return false
end

function ZO_ItemPreview_Gamepad:TryPreviewNextAction(playClickSound)
    if self.currentPreviewTypeObject and self.numPreviewActions > 1 and self.canChangePreview then
        self:PreviewNextAction()
        if playClickSound then
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
        return true
    end
    return false
end

function ZO_ItemPreview_Gamepad:TryPreviewPreviousAction(playClickSound)
    if self.currentPreviewTypeObject and self.numPreviewActions > 1 and self.canChangePreview then
        self:PreviewPreviousAction()
        if playClickSound then
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end
        return true
    end
    return false
end

function ZO_ItemPreview_Gamepad:SetVariationControlsHidden(shouldHide)
    self.variationLabel:SetHidden(shouldHide)
    self.previewVariationLeftIcon:SetHidden(shouldHide)
    self.previewVariationRightIcon:SetHidden(shouldHide)
end

function ZO_ItemPreview_Gamepad:SetVariationLabel(variationName)
    self.variationLabel:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, variationName))
end

function ZO_ItemPreview_Gamepad:SetActionControlsHidden(shouldHide)
    self.actionLabel:SetHidden(shouldHide)
    self.previewActionLeftIcon:SetHidden(shouldHide)
    self.previewActionRightIcon:SetHidden(shouldHide)
end

function ZO_ItemPreview_Gamepad:SetActionLabel(actionName)
    self.actionLabel:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, actionName))
end

function ZO_ItemPreview_Gamepad:SetHorizontalPaddings(paddingLeft, paddingRight)
    self.control:ClearAnchors()
    self.control:SetAnchor(TOPLEFT, nil, TOPLEFT, paddingLeft, ZO_GAMEPAD_SAFE_ZONE_INSET_Y)
    self.control:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -paddingRight, ZO_GAMEPAD_QUADRANT_BOTTOM_OFFSET)
end

function ZO_ItemPreview_Gamepad_OnInitialize(control)
    ITEM_PREVIEW_GAMEPAD = ZO_ItemPreview_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("itemPreview", ITEM_PREVIEW_GAMEPAD)
end

-- Preview Reward List Screen --

ZO_PreviewRewardList_Screen_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_PreviewRewardList_Screen_Gamepad:Initialize(control)
    function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            PREVIEW_REWARD_LIST_SCENE = ZO_Scene:New("previewRewardList_Gamepad", SCENE_MANAGER)
            local ACTIVATE_ON_SHOW = true
            ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, PREVIEW_REWARD_LIST_SCENE)
            self.list = self:GetMainList()
            self:InitializeHeader()

            self.fragment = ZO_SimpleSceneFragment:New(control)
            self.fragment:SetHideOnSceneHidden(true)

            self.scene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
            self.scene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
            self.scene:AddFragment(self.fragment)
            self.scene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
            self.scene:AddFragment(MINIMIZE_CHAT_FRAGMENT)

            self:SetOptionsFragment(GAMEPAD_NAV_QUADRANT_2_3_4_ITEM_PREVIEW_OPTIONS_FRAGMENT)
        end
        --TODO: Make a scene that works in internal
    end

    control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ZO_PreviewRewardList_Screen_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- "Preview" Keybind
        {
            name =  function()
                if IsCurrentlyPreviewing() then
                    return GetString(SI_REWARD_END_PREVIEW_ACTION)
                else
                    local targetData = self.list:GetTargetData()
                    if targetData then
                        local rewardId = targetData:GetRewardId()
                        if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
                            return GetString(SI_REWARD_LIST_VIEW_ACTION)
                        end
                    end
                    return GetString(SI_REWARD_PREVIEW_ACTION)
                end
            end,

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                self:TogglePreview()
            end,

            enabled = function()
                return IsCharacterPreviewingAvailable(), GetString(SI_PREVIEW_UNAVAILABLE_ERROR)
            end,

            visible = function()
                local targetData = self.list:GetTargetData()
                if targetData then
                    return CanPreviewReward(targetData:GetRewardId())
                end
                return false
            end,
        },

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }
end

function ZO_PreviewRewardList_Screen_Gamepad:InitializeHeader()
    self.headerData =
    {
        titleText = GetString(SI_GAMEPAD_TOOLTIPS_REWARD_LIST_HEADER),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_PreviewRewardList_Screen_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    if self.queuedRewardListId ~= nil then
        self:ShowRewardList(self.queuedRewardListId)
        self.queuedRewardListId = nil
    end
end

function ZO_PreviewRewardList_Screen_Gamepad:OnHiding()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    self:EndPreview()
end

function ZO_PreviewRewardList_Screen_Gamepad:SetRewardList(rewardListId)
    if SCENE_MANAGER:IsShowing(self.scene.name) then
        self:ShowRewardList(rewardListId)
    else
        self.queuedRewardListId = rewardListId
    end
end

function ZO_PreviewRewardList_Screen_Gamepad:SetOptionsFragment(optionsFragment)
    if optionsFragment ~= self.optionsFragment then
        -- The preview options fragment needs to be added before the ITEM_PREVIEW_GAMEPAD fragment
        if self.optionsFragment then
            PREVIEW_REWARD_LIST_SCENE:RemoveFragment(self.optionsFragment)
            PREVIEW_REWARD_LIST_SCENE:RemoveFragment(ITEM_PREVIEW_GAMEPAD:GetFragment())
        end

        self.optionsFragment = optionsFragment

        PREVIEW_REWARD_LIST_SCENE:AddFragment(optionsFragment)
        PREVIEW_REWARD_LIST_SCENE:AddFragment(ITEM_PREVIEW_GAMEPAD:GetFragment())
    end
end

function ZO_PreviewRewardList_Screen_Gamepad:ShowRewardList(rewardListId)
    self.list:Clear()

    local rewards = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)

    for index, reward in ipairs(rewards) do
        local name = reward:GetFormattedName()
        local iconTextureFile = reward:GetGamepadIcon()
        local entryData = ZO_GamepadEntryData:New(name, iconTextureFile)

        entryData:SetDataSource(reward)
        entryData:SetStackCount(reward:GetQuantity())

        local displayQuality = reward:GetItemDisplayQuality()
        entryData.displayQuality = displayQuality or ITEM_DISPLAY_QUALITY_NORMAL
        entryData:SetNameColors(entryData:GetColorsBasedOnQuality(displayQuality))

        entryData.hasPreview = CanPreviewReward(reward:GetRewardId())

        self.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end

    self.list:Commit()
    self.list:SetSelectedIndexWithoutAnimation(1)
end

function ZO_PreviewRewardList_Screen_Gamepad:OnTargetChanged(list, targetData, oldTargetData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    if targetData then
        local rewardId = targetData:GetRewardId()
        if rewardId and rewardId ~= 0 and not IsCurrentlyPreviewing() then
            GAMEPAD_TOOLTIPS:LayoutReward(GAMEPAD_LEFT_TOOLTIP, rewardId, targetData:GetQuantity(), REWARD_DISPLAY_FLAGS_FROM_CROWN_STORE_CONTAINER)
        end
        self:UpdatePreview()
    end
end

function ZO_PreviewRewardList_Screen_Gamepad:TogglePreview()
    local targetData = self.list:GetTargetData()
    if IsCurrentlyPreviewing() then
        self:EndPreview()
        local rewardId = targetData:GetRewardId()
        if rewardId and rewardId ~= 0 then
            GAMEPAD_TOOLTIPS:LayoutReward(GAMEPAD_LEFT_TOOLTIP, rewardId, targetData:GetQuantity(), REWARD_DISPLAY_FLAGS_FROM_CROWN_STORE_CONTAINER)
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        if targetData and targetData.hasPreview then
            local rewardId = targetData:GetRewardId()
            if rewardId then
                local previewInEmptyWorld = targetData:GetRewardType() == REWARD_TYPE_ITEM
                ITEM_PREVIEW_GAMEPAD:SetPreviewInEmptyWorld(previewInEmptyWorld)
                ITEM_PREVIEW_GAMEPAD:PreviewReward(rewardId)
            end
        end
    end
    self:RefreshKeybinds()
    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list)
end

function ZO_PreviewRewardList_Screen_Gamepad:UpdatePreview()
    if IsCurrentlyPreviewing() then
        local targetData = self.list:GetTargetData()
        if targetData and targetData.hasPreview then
            local rewardId = targetData:GetRewardId()
            if rewardId then
                local previewInEmptyWorld = targetData:GetRewardType() == REWARD_TYPE_ITEM
                ITEM_PREVIEW_GAMEPAD:SetPreviewInEmptyWorld(previewInEmptyWorld)
                ITEM_PREVIEW_GAMEPAD:PreviewReward(rewardId)
            end
        else
            self:EndPreview()
        end
    end
    self:RefreshKeybinds()
end

function ZO_PreviewRewardList_Screen_Gamepad:EndPreview()
    ITEM_PREVIEW_GAMEPAD:EndCurrentPreview()
    self:RefreshKeybinds()
end

function ZO_PreviewRewardList_Screen_Gamepad:PerformUpdate()
    -- This function is required but unused
    self.dirty = false
end

function ZO_PreviewRewardList_Screen_Gamepad.OnControlInitialized(control)
    PREVIEW_REWARD_LIST_SCREEN_GAMEPAD = ZO_PreviewRewardList_Screen_Gamepad:New(control)
end