ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_TEMPLATE_DIMENSIONS_KEYBOARD = 116
ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_TEMPLATE_ICON_DIMENSIONS_KEYBOARD = 52
ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_KEYBOARD = 5

ZO_DailyLoginRewards_Keyboard = ZO_DailyLoginRewards_Base:Subclass()

function ZO_DailyLoginRewards_Keyboard:New(...)
    return ZO_DailyLoginRewards_Base.New(self, ...)
end

function ZO_DailyLoginRewards_Keyboard:Initialize(control)
    ZO_DailyLoginRewards_Base.Initialize(self, control)
    
    self.changeTimerLabel = control:GetNamedChild("ChangeTimer")
    self.currentMonthLabel = control:GetNamedChild("CurrentMonth")
    self.particleGeneratorPosition = control:GetNamedChild("RewardParticleGeneratorPosition")
    self.lockedLabel = control:GetNamedChild("LockedText")

    self.blastParticleSystem:SetParentControl(self.particleGeneratorPosition)
    
    self:InitializeKeybindStripDescriptors()
    self:InitializeGridListPanel()
    
    DAILY_LOGIN_REWARDS_KEYBOARD_SCENE = ZO_Scene:New("dailyLoginRewards", SCENE_MANAGER)
    DAILY_LOGIN_REWARDS_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    
    DAILY_LOGIN_REWARDS_KEYBOARD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_HIDING then
            self:OnHiding()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_DailyLoginRewards_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Claim
        {
            name = GetString(SI_DAILY_LOGIN_REWARDS_CLAIM_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ClaimCurrentDailyLoginReward()
            end,
            visible = function() 
                return GetDailyLoginClaimableRewardIndex() ~= nil
            end,
        },

        -- Preview
        {
            name = GetString(SI_DAILY_LOGIN_REWARDS_PREVIEW_KEYBIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
                SYSTEMS:GetObject("itemPreview"):PreviewReward(self.mouseOverData:GetRewardId())
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end,
            visible = function()
                if self.mouseOverData then
                    return CanPreviewReward(self.mouseOverData:GetRewardId()) and IsCharacterPreviewingAvailable()
                end

                return false
            end,
        },

        -- End Preview
        {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_DAILY_LOGIN_REWARDS_END_PREVIEW_KEYBIND),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end,
            visible = function() return IsCurrentlyPreviewing() end
        },
    }
end

local function ZO_Daily_Login_Rewards_Keyboard_CleanupAnimationOnControl(control)
    if control.pendingLoop then
        control.pendingLoop:ReleaseObject()
    end
end

function ZO_DailyLoginRewards_Keyboard:InitializeGridListPanel()
    local gridListPanel = self.control:GetNamedChild("Rewards")
    self.gridListPanelControl = gridListPanel
    self.gridListPanelList = ZO_SingleTemplateGridScrollList_Keyboard:New(gridListPanel, ZO_GRID_SCROLL_LIST_AUTOFILL)

    local function DailyLoginRewardsGridEntryReset(control)
        ZO_Daily_Login_Rewards_Keyboard_CleanupAnimationOnControl(control.backdrop)
        self:GridEntryCleanup(control)
        ZO_GridEntry_SetIconScaledUpInstantly(control, false)
    end
    
    local HEADER_HEIGHT = 30
    local HIDE_CALLBACK = nil
    self.gridListPanelList:SetGridEntryTemplate("ZO_DailyLoginRewards_GridEntry_Template_Keyboard", ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_TEMPLATE_DIMENSIONS_KEYBOARD, ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_TEMPLATE_DIMENSIONS_KEYBOARD, self.dailyLoginRewardsGridEntrySetup, HIDE_CALLBACK, DailyLoginRewardsGridEntryReset, ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_KEYBOARD, ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_KEYBOARD)
    self.gridListPanelList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.gridListPanelList:SetHeaderPrePadding(ZO_GRID_SCROLL_LIST_DAILY_LOGIN_REWARDS_SPACING_KEYBOARD * 3)
end

do
    local PENDING_ANIMATION_INSET = 3
    function ZO_DailyLoginRewards_Keyboard:SetupGridEntryBorderAndMilestone(control, data, controlPool)
        if data.isEmptyCell then
            control.isMilestoneTag:SetHidden(true)
        else
            control.isMilestoneTag:SetHidden(not data.isMilestone)

            if GetDailyLoginClaimableRewardIndex() == data.day then
                if not control.backdrop.pendingLoop then
                    ZO_PendingLoop.ApplyToControl(control.backdrop, controlPool, PENDING_ANIMATION_INSET)
                end
            else
                ZO_Daily_Login_Rewards_Keyboard_CleanupAnimationOnControl(control.backdrop)
            end
        end
    end
end

function ZO_DailyLoginRewards_Keyboard:OnShowing()
    ZO_DailyLoginRewards_Base.OnShowing(self)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_DailyLoginRewards_Keyboard:OnHiding()
    ZO_DailyLoginRewards_Base.OnHiding(self)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_DailyLoginRewards_Keyboard:OnHidden()
    
end

function ZO_DailyLoginRewards_Keyboard:OnDailyLoginRewardEntryMouseEnter(control)
    if not control.data.isEmptyCell then
        self.mouseOverData = control.data
    end

    ZO_GridEntry_SetIconScaledUp(control, true)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_DailyLoginRewards_Keyboard:OnDailyLoginRewardEntryMouseExit(control)
    self.mouseOverData = nil

    ZO_GridEntry_SetIconScaledUp(control, false)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_DailyLoginRewards_Keyboard:ClaimCurrentDailyLoginReward(fromClick)
    local claimableRewardIndex = GetDailyLoginClaimableRewardIndex()
    if claimableRewardIndex then
        -- make sure we clicked the correct day
        if fromClick then
            if not self.mouseOverData or self.mouseOverData.day ~= claimableRewardIndex then
                return
            end
            self:SetTargetedClaimData(self.mouseOverData)
        else -- make sure mouseOverData is set so we can show the fanfare
            self:SetTargetedClaimData(self:GetDailyLoginRewardDataByDay(claimableRewardIndex))
        end

        local numSlotsNeeded = GetNumInventorySlotsNeededForDailyLoginRewardInCurrentMonth(claimableRewardIndex)
        if CheckInventorySpaceAndWarn(numSlotsNeeded) then
            PlaySound(SOUNDS.DAILY_LOGIN_REWARDS_ACTION_CLAIM)
            ClaimCurrentDailyLoginReward()
        end
    end
end

function ZO_DailyLoginRewards_Keyboard:GetDailyLoginRewardDataByDay(day)
    local gridData = self.gridListPanelList:GetData()
    for index, entryData in ipairs(gridData) do
        if entryData.data.day == day then
            return entryData.data
        end
    end

    return nil
end

function ZO_DailyLoginRewards_Keyboard:OnNewDailyLoginReward()
    ZO_DailyLoginRewards_Base.OnNewDailyLoginReward(self)
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("marketSceneGroup")
end

function ZO_DailyLoginRewards_Keyboard:OnRewardClaimed(eventId, result)
    ZO_DailyLoginRewards_Base.OnRewardClaimed(self, eventId, result)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("marketSceneGroup")
end

function ZO_DailyLoginRewards_Keyboard:CleanDirty()
    ZO_DailyLoginRewards_Base.CleanDirty(self)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_DailyLoginRewards_Keyboard:UpdateTimeToNextMonthText(formattedTime)
    ZO_DailyLoginRewards_Base.UpdateTimeToNextMonthText(self, formattedTime)

    self.changeTimerLabel:SetText(zo_strformat(SI_DAILY_LOGIN_REWARDS_CHANGES_IN, ZO_WHITE:Colorize(formattedTime)))
end

function ZO_DailyLoginRewards_Keyboard:UpdateTimeToNextMonthVisibility()
    self.changeTimerLabel:SetHidden(self:ShouldChangeTimerBeHidden())
end

function ZO_DailyLoginRewards_Keyboard:IsShowing()
    return DAILY_LOGIN_REWARDS_KEYBOARD_SCENE:IsShowing()
end

function ZO_DailyLoginRewards_Keyboard:ShouldShowNextClaimableRewardBorder()
    return true
end

-------------------
-- XML Functions
-------------------

function ZO_DailyLoginRewards_GridEntry_Template_Keyboard_OnMouseEnter(control)
    local rewardData = control.data
    if rewardData then
        if not rewardData.isEmptyCell then
            local rewardType = rewardData:GetRewardType()
            if rewardType and rewardType ~= REWARD_ENTRY_TYPE_CHOICE then
                InitializeTooltip(ItemTooltip, control, RIGHT, -15, 0, LEFT)
                ItemTooltip:SetDailyLoginRewardEntry(rewardData.day)
            end
        end
    end
    ZO_DAILYLOGINREWARDS_KEYBOARD:OnDailyLoginRewardEntryMouseEnter(control)
end

function ZO_DailyLoginRewards_GridEntry_Template_Keyboard_OnMouseExit(control)
    ClearTooltip(ItemTooltip)
    ZO_DAILYLOGINREWARDS_KEYBOARD:OnDailyLoginRewardEntryMouseExit(control)
end

function ZO_DailyLoginRewards_GridEntry_Template_Keyboard_OnMouseUp(control, button, upInside)
    if upInside then
        local FROM_CLICK = true
        ZO_DAILYLOGINREWARDS_KEYBOARD:ClaimCurrentDailyLoginReward(FROM_CLICK)
    end
end

function ZO_DailyLoginRewards_Keyboard_OnInitialize(control)
    ZO_DAILYLOGINREWARDS_KEYBOARD = ZO_DailyLoginRewards_Keyboard:New(control)
end