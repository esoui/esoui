local g_VeterancyKeyboard = nil

----------------------------
-- Veterancy Rank
----------------------------

ZO_Veterancy_RankTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_Veterancy_RankTile_Shared)

function ZO_Veterancy_RankTile_Keyboard:New(...)
    return ZO_Veterancy_RankTile_Shared.New(self, ...)
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_Veterancy_RankTile_Keyboard:PostInitializePlatform()
    -- keybindStripDescriptor and canFocus need to be set after initialize, because ZO_ContextualActionsTile
    -- won't have finished initializing those until after InitializePlatform is called
    ZO_ContextualActionsTile_Keyboard.PostInitializePlatform(self)

    self:SetCanFocus(false)
end

function ZO_Veterancy_RankTile_Keyboard:LayoutPlatform(data)
    self:SetCanFocus(true)
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_Veterancy_RankTile_Keyboard:OnMouseUp(button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
        if self.rankData:CanClaimRank() then
            self.rankData:TryClaimRankRewards()
        end
    end
end

function ZO_Veterancy_RankTile_Keyboard.OnControlInitialized(control)
    ZO_Veterancy_RankTile_Keyboard:New(control)
end

----------------------------------
-- Veterancy Empty Rank
----------------------------------

ZO_Veterancy_RankTile_Empty_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_Veterancy_RankTile_Empty_Shared)

function ZO_Veterancy_RankTile_Empty_Keyboard:New(...)
    return ZO_Veterancy_RankTile_Empty_Shared.New(self, ...)
end

function ZO_Veterancy_RankTile_Empty_Keyboard:InitializePlatform()
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self)

    self:SetHighlightAnimationProvider(nil)
end

function ZO_Veterancy_RankTile_Empty_Shared.OnControlInitialized(control)
    ZO_Veterancy_RankTile_Empty_Keyboard:New(control)
end

-------------------------------
-- Veterancy Reward
-------------------------------

ZO_VeterancyReward_Keyboard = ZO_VeterancyReward_Shared:Subclass()

function ZO_VeterancyReward_Keyboard:Initialize(control)
    ZO_VeterancyReward_Shared.Initialize(self, control)

    table.insert(self.keybindStripDescriptor,
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_PRIMARY",
        name = GetString(SI_VETERANCY_CLAIM_ACTION_TEXT),
        callback = function()
            self:GetRewardableEventData():TryClaimReward()
        end,
        visible = function()
            return g_VeterancyKeyboard:IsMouseOverObject(self) and self:GetRewardableEventData():CanClaimReward()
        end,
    })

    table.insert(self.keybindStripDescriptor,
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        keybind = "UI_SHORTCUT_SECONDARY",
        name = GetString(SI_VETERANCY_PREVIEW_ACTION_TEXT),
        callback = function(control)
            self:OnMouseExit()
            g_VeterancyKeyboard:BeginPreview(ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW, self:GetMousedOverPreviewableRewardListEntry() or self:GetRewardableEventData())
        end,
        visible = function()
            return not ITEM_PREVIEW_KEYBOARD:IsWaitingForPreviewBegin()
                and ((g_VeterancyKeyboard:IsMouseOverObject(self) and self:GetRewardableEventData():CanPreviewReward())
                or self:IsMousedOverPreviewableRewardListEntry())
        end,
    })
end

do
    local REWARD_FRAME_TEXTURE =
    {
        NORMAL = "EsoUI/Art/Veterancy/itemreward_frame.dds",
        HIGHLIGHT = "EsoUI/Art/Veterancy/itemreward_frame_highlight.dds",
    }

    function ZO_VeterancyReward_Keyboard:OnMouseEnter()
        local rewardData = self.control.GetRewardData and self.control.GetRewardData() or self.control.data
        if rewardData:IsInstanceOf(ZO_VeterancyPerkData) then
            local rewardableEventData = rewardData:GetVeterancyRankPerkRewardData()
            local rankData = rewardableEventData:GetRankData()
            local pageIndex = zo_mod(rankData:GetIndex(), ZO_VETERANCY_RANKS_PER_PAGE)
            if pageIndex == 4 or pageIndex == 5 or (pageIndex ~= 7 and rankData:IsLeftTooltip()) then
                InitializeTooltip(SkillTooltip, self.control, RIGHT, -5, 0, LEFT)
            else
                InitializeTooltip(SkillTooltip, self.control, LEFT, 5, 0, RIGHT)
            end
            SkillTooltip:SetVengeancePerkId(rewardData.rewardId, rewardableEventData:GetSlotFlags())
            self.perkHighlightControl:SetTexture(rewardableEventData:GetHighlightTexture())
            self.perkHighlightControl:SetAlpha(1)
        else
            local rankRewardData = self.control.object:GetRewardableEventData()
            if rankRewardData then
                local rankData = rankRewardData:GetRankData()
                if rankRewardData:IsRepeatableRank() then
                    ZO_Rewards_Shared_OnMouseEnter(self.control, LEFT, RIGHT, 400)
                else
                    local point = LEFT
                    local relativePoint = RIGHT
                    local offsetX = 5
                    local useRelativeAnchors = false
                    local pageIndex = zo_mod(rankData:GetIndex(), ZO_VETERANCY_RANKS_PER_PAGE)
                    if pageIndex == 0 then
                        pageIndex = ZO_VETERANCY_RANKS_PER_PAGE
                    end
                    if pageIndex == 4 or pageIndex == 5 then
                        useRelativeAnchors = true
                        point = RIGHT
                        relativePoint = LEFT
                        offsetX = -5
                    elseif pageIndex == 6 or pageIndex == 7 then
                        useRelativeAnchors = true
                    elseif rankData:IsLeftTooltip() then
                        point = RIGHT
                        relativePoint = LEFT
                        offsetX = -5
                    end
                    ZO_Rewards_Shared_OnMouseEnter(self.control, point, relativePoint, offsetX, 0, useRelativeAnchors)
                end
            else
                ZO_Rewards_Shared_OnMouseEnter(self.control, LEFT, RIGHT, 5)
            end

            if not self.rewardableEventData:IsRewardClaimed() then
                ZO_GridEntry_SetIconScaledUp(self.control, true)
            end
            self.rewardBorderTexture:SetTexture(REWARD_FRAME_TEXTURE.HIGHLIGHT)

            if CanPreviewReward(self.displayRewardData:GetRewardId()) and not self.rewardableEventData:CanClaimReward() then
                WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PREVIEW)
            end
        end

        g_VeterancyKeyboard:SetMouseOverObject(self)
        self:AddKeybinds()
    end

    function ZO_VeterancyReward_Keyboard:OnMouseExit()
        ClearTooltip(SkillTooltip)
        self.perkHighlightControl:SetAlpha(0)
        ZO_Rewards_Shared_OnMouseExit(self.control)
        ZO_GridEntry_SetIconScaledUp(self.control, false)
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
        self.rewardBorderTexture:SetTexture(REWARD_FRAME_TEXTURE.NORMAL)
        self:RemoveKeybinds()
        g_VeterancyKeyboard:SetMouseOverObject(nil)
    end
end

function ZO_VeterancyReward_Keyboard:OnMouseUp(button, upInside)
    if upInside then
        if button == MOUSE_BUTTON_INDEX_LEFT then
            if self.rewardableEventData:CanClaimReward() then
                self.rewardableEventData:TryClaimReward()
            elseif not ITEM_PREVIEW_KEYBOARD:IsWaitingForPreviewBegin() and g_VeterancyKeyboard.CanPreviewReward(self.rewardableEventData:GetRewardData()) then
                g_VeterancyKeyboard:BeginPreview(ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW, self.rewardableEventData)
                self:UpdateKeybinds()
            end
        elseif button == MOUSE_BUTTON_INDEX_RIGHT then
            ClearMenu()
            local showMenu = false

            if self.rewardableEventData:CanClaimReward() then
                AddMenuItem(GetString(SI_VETERANCY_CLAIM_ACTION_TEXT), function()
                    self.rewardableEventData:TryClaimReward()
                end)
                showMenu = true
            end

            local canPreviewReward = not ITEM_PREVIEW_KEYBOARD:IsWaitingForPreviewBegin() and CanPreviewReward(rewardId)
            if canPreviewReward then
                AddMenuItem(GetString(SI_REWARD_PREVIEW_ACTION), function()
                    g_VeterancyKeyboard:BeginPreview(rewardId, self.control)
                    g_VeterancyKeyboard:UpdateKeybinds()
                end)
                showMenu = true
            end

            if showMenu then
                ShowMenu(self.control)
            end
        end
    end
end

function ZO_VeterancyReward_Keyboard:Refresh()
    ZO_VeterancyReward_Shared.Refresh(self)
    self.rewardListObject = nil
    POPUP_LIST:Hide()
end

function ZO_VeterancyReward_Keyboard:PreviewRewardList(rewardId, anchorControl)
    local function OnMouseEnter(control)
        local rewardListRewardData = ZO_VeterancyRewardListRewardData:New(control.dataEntry.data)
        self.activeRewardListRewardData = rewardListRewardData
        self:SetMouseOverObject(control.dataEntry.data)
    end

    local function OnMouseExit(control)
        self.activeRewardListRewardData = nil
        self:SetMouseOverObject(nil)
    end

    local function OnMouseUp(control)
        self:OnMouseExit()
        g_VeterancyKeyboard:BeginPreview(ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW, self:GetMousedOverPreviewableRewardListEntry())
    end

    self.rewardListObject = self.mouseOverObject
    local anchorControl = anchorControl or self.mouseOverObject.control
    POPUP_LIST:ShowRewardList(rewardId, OnMouseEnter, OnMouseExit, BOTTOMRIGHT, anchorControl, BOTTOMLEFT)
    POPUP_LIST:SetOnMouseUpCallback(OnMouseUp)
end

function ZO_VeterancyReward_Keyboard:SetMouseOverObject(mouseOverObject)
    self.mouseOverObject = mouseOverObject
    if mouseOverObject then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    else
        self.rewardListObject = nil
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_VeterancyReward_Keyboard:IsMousedOverPreviewableRewardListEntry()
    if self.activeRewardListRewardData then
        return self.activeRewardListRewardData:CanPreviewReward()
    end
    return false
end

function ZO_VeterancyReward_Keyboard:GetMousedOverPreviewableRewardListEntry()
    return self.activeRewardListRewardData
end

function ZO_VeterancyReward_Keyboard.OnControlInitialized(control)
    ZO_VeterancyReward_Keyboard:New(control)
end

------------------------------------
-- Veterancy Reward Tile
------------------------------------

ZO_Veterancy_RewardTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_Veterancy_RewardTile_Shared)

function ZO_Veterancy_RewardTile_Keyboard:New(...)
    return ZO_Veterancy_RankTile_Shared.New(self, ...)
end

function ZO_Veterancy_RewardTile_Keyboard.OnControlInitialized(control)
    ZO_Veterancy_RewardTile_Keyboard:New(control)
end

---------------------------------------
-- Veterancy No Reward Tile
---------------------------------------

ZO_Veterancy_NoRewardTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_Veterancy_NoRewardTile_Shared)

function ZO_Veterancy_NoRewardTile_Keyboard:New(...)
    return ZO_Veterancy_NoRewardTile_Shared.New(self, ...)
end

function ZO_Veterancy_NoRewardTile_Keyboard.OnControlInitialized(control)
    ZO_Veterancy_NoRewardTile_Keyboard:New(control)
end

--------------------------
-- Veterancy
--------------------------

ZO_Veterancy_Keyboard = ZO_Veterancy_Shared:Subclass()

function ZO_Veterancy_Keyboard:Initialize(control)
    VETERANCY_SCENE_KEYBOARD = ZO_Scene:New("VeterancySceneKeyboard", SCENE_MANAGER)

    self.previousCampaignScene = "campaignBrowser"

    local function RewardTileSetupFunction(tileControl, data)
        ZO_DefaultGridTileEntrySetup(tileControl, data)
        tileControl.object:SetRewardFxPools(self.rewardPendingLoopPool, self.blastParticleSystemPool)
    end

    local ATTRIBUTE = ZO_VETERANCY.ATTRIBUTE
    local templateData =
    {
        [ZO_VETERANCY.GRID_DATA.SCROLL_CLASS] = ZO_Veterancy_HorizontalScrollList_Shared,
        [ZO_VETERANCY.GRID_DATA.SCROLL_TEMPLATE] = "ZO_Veterancy_GridList_Keyboard",
        [ZO_VETERANCY.GRID_DATA.CLASS] = ZO_GridScrollList_Keyboard,
        [ZO_VETERANCY.TEMPLATE_TYPE.RANK] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RankTile_Template_Keyboard",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RANK_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_RANK_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = ZO_DefaultGridTileEntrySetup,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.EMPTY_RANK] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RankTile_Empty_Template_Keyboard",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RANK_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_RANK_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = ZO_DefaultGridTileEntrySetup,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.CENTERED_REWARD] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RewardTile_CenteredReward_Keyboard",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RANK_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_REWARD_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = RewardTileSetupFunction,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.LEFT_REWARD] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RewardTile_LeftReward_Keyboard",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_LEFT_REWARD_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_REWARD_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = RewardTileSetupFunction,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.RIGHT_REWARD] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RewardTile_RightReward_Keyboard",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RIGHT_REWARD_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_REWARD_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = RewardTileSetupFunction,
        },
        [ZO_VETERANCY.TEMPLATE_TYPE.NO_REWARD] =
        {
            [ATTRIBUTE.ENTRY_TEMPLATE] = "ZO_Veterancy_RewardTile_NoReward_Keyboard",
            [ATTRIBUTE.DIMENSION_X] = ZO_VETERANCY_TEMPLATE_RANK_X,
            [ATTRIBUTE.DIMENSION_Y] = ZO_VETERANCY_TEMPLATE_REWARD_Y,
            [ATTRIBUTE.SETUP_FUNCTION] = ZO_DefaultGridTileEntrySetup,
        },
    }

    ZO_Veterancy_Shared.Initialize(self, control, VETERANCY_SCENE_KEYBOARD, templateData)
end

function ZO_Veterancy_Keyboard:OnDeferredInitialize()
    ZO_Veterancy_Shared.OnDeferredInitialize(self)

    ZO_StatusBar_SetGradientColor(self.repeatableRankRewardProgressControl, ZO_XP_BAR_GRADIENT_COLORS)

    self.pageNavigation:SetDefaultIndicatorFont("ZoFontCallout")

    self:InitializeKeybindStripDescriptor()
end

function ZO_Veterancy_Keyboard:BeginPreview(previewType, previewableRewardData)
    ZO_PreviewScreen_Shared.BeginPreview(self, previewType, previewableRewardData)
    POPUP_LIST:Hide()
end

function ZO_Veterancy_Keyboard:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_VETERANCY_CLAIM_ALL_ACTION_TEXT),
            callback = function()
                self:TryClaimAllRewards()
            end,
            visible = function()
                return self:AreAnyRewardsClaimable()
            end,
        },
        {
            name = GetString(SI_VETERANCY_BACK_ACTION_TEXT),
            keybind = "UI_SHORTCUT_NEGATIVE",
            order = -10000,
            callback = function()
                if self:GetCurrentPreviewType() == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
                    self:EndPreview()
                    self:UpdateSceneFragments()
                else
                    self:ExitVeterancy()
                end
            end,
        },
    }
end

function ZO_Veterancy_Keyboard:SetPreviousCampaignScene(previousCampaignScene)
    self.previousCampaignScene = previousCampaignScene
end

function ZO_Veterancy_Keyboard:GetPreviousCampaignScene()
    return self.previousCampaignScene
end

function ZO_Veterancy_Keyboard:SetIsFromActivityFinder(isFromActivityFinder)
    self.isFromActivityFinder = isFromActivityFinder
end

function ZO_Veterancy_Keyboard:SetIsFromNotifications(isFromNotifications)
    self.isFromNotifications = isFromNotifications
end

function ZO_Veterancy_Keyboard:IsFromNotifications()
    return self.isFromNotifications
end

function ZO_Veterancy_Keyboard:ExitVeterancy()
    if self:GetCurrentPreviewType() == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        self:EndPreview()
        self:UpdateSceneFragments()
    end
    if self.isFromActivityFinder then
        GROUP_MENU_KEYBOARD:ShowCategory(BATTLEGROUND_FINDER_KEYBOARD:GetFragment())
    else
        SCENE_MANAGER:Show(self.previousCampaignScene)
    end
end

function ZO_Veterancy_Keyboard:OnShowing()
    ZO_Veterancy_Shared.OnShowing(self)

    self:UpdateSceneFragments()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Veterancy_Keyboard:OnHiding()
    ZO_Veterancy_Shared.OnHiding(self)

    self:UpdateSceneFragments()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    if self.mouseOverObject then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mouseOverObject.keybindStripDescriptor)
    end

    -- Just in case we're leaving for any reason other than back (popping the stack),
    -- ensure the previously selected campaign tab is the tas selected in the campaign screen
    ZO_ALLIANCE_WAR_SCENE_GROUP_KEYBOARD:SetActiveScene(self.previousCampaignScene)

    self.isFromActivityFinder = false
    self:SetIsFromNotifications(false)
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("allianceWarSceneGroup")
    POPUP_LIST:Hide()
end

function ZO_Veterancy_Keyboard:SetMouseOverObject(mouseOverObject)
    self.mouseOverObject = mouseOverObject
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Veterancy_Keyboard:IsMouseOverObject(mouseOverObject)
    return self.mouseOverObject == mouseOverObject
end

function ZO_Veterancy_Keyboard:OnRewardsClaimed(...)
    ZO_Veterancy_Shared.OnRewardsClaimed(self, ...)

    if self:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Veterancy_Keyboard:EndPreviewInternal()
    ZO_Veterancy_Shared.EndPreviewInternal(self)

    self:UpdateSceneFragments()
end

function ZO_Veterancy_Keyboard:EndPreviewRewardList()
    -- TODO Veterancy: Implement
end

function ZO_Veterancy_Keyboard:PreviewRewardList(rewardId, control)
    -- TODO Veterancy: Implement
end

function ZO_Veterancy_Keyboard:UpdateSceneFragments()
    if self:GetCurrentPreviewType() == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        self.scene:RemoveFragment(self.fragment)
    else
        self.scene:AddFragment(self.fragment)
    end
end

function ZO_Veterancy_Keyboard:OnPreviewedPreviewableRewardDataChanged(previousPreviewableRewardData, newPreviewableRewardData)
    ZO_Veterancy_Shared.OnPreviewedPreviewableRewardDataChanged(self, previousPreviewableRewardData, newPreviewableRewardData)

    self:UpdateSceneFragments()
end

--------------------------
-- Global Functions
--------------------------

function ZO_Veterancy_Keyboard.OnControlInitialized(control)
    g_VeterancyKeyboard = ZO_Veterancy_Keyboard:New(control)
    VETERANCY_KEYBOARD = g_VeterancyKeyboard
end