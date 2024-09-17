ZO_CHAPTER_UPGRADE_KEYBOARD_BACKGROUND_TEXTURE_LEVEL = 2
ZO_CHAPTER_UPGRADE_KEYBOARD_TEXT_CALLOUT_BACKGROUND_TEXTURE_LEVEL = 3
ZO_CHAPTER_UPGRADE_KEYBOARD_REWARD_ENTRY_HEADER_HEIGHT = 35
ZO_CHAPTER_UPGRADE_KEYBOARD_REWARD_ENTRY_HEIGHT = 50

ZO_ChapterUpgradePane_Keyboard = ZO_ChapterUpgradePane_Shared:Subclass()

function ZO_ChapterUpgradePane_Keyboard:New(...)
    return ZO_ChapterUpgradePane_Shared.New(self, ...)
end

function ZO_ChapterUpgradePane_Keyboard:Initialize(control, owner)
    ZO_ChapterUpgradePane_Shared.Initialize(self, control)

    self.owner = owner
    self.descriptionLabel = control:GetNamedChild("Description")
    self.prepurchaseRewardsSection = control:GetNamedChild("PrePurchaseRewards")
    self.prepurchaseRewardsHeader = self.prepurchaseRewardsSection:GetNamedChild("Header")
    self.editionRewardsSection = control:GetNamedChild("EditionRewards")
    self.editionRewardsHeader = self.editionRewardsSection:GetNamedChild("Header")
    self.editionRewardsHeaderCollectorsLabel = self.editionRewardsHeader:GetNamedChild("CollectorsLabel")
    self.prepurchaseRewardPool = ZO_ControlPool:New("ZO_ChapterUpgrade_Keyboard_RewardsEntry", self.prepurchaseRewardsSection, "Reward")
    self.editionRewardPool = ZO_ControlPool:New("ZO_ChapterUpgrade_Keyboard_RewardsEntry", self.editionRewardsSection, "Reward")

    local function OnRewardEntryCreated(control)
        control:SetHandler("OnMouseEnter", function(...) self:OnRewardEntryMouseEnter(...) end)
        control:SetHandler("OnMouseExit", function(...) self:OnRewardEntryMouseExit(...) end)
        control:SetHandler("OnMouseUp", function(...) self:OnRewardEntryMouseUp(...) end)
    end

    self.prepurchaseRewardPool:SetCustomFactoryBehavior(OnRewardEntryCreated)
    self.editionRewardPool:SetCustomFactoryBehavior(OnRewardEntryCreated)
end

function ZO_ChapterUpgradePane_Keyboard:OnRewardEntryMouseEnter(control)
    local highlight = control.highlight
    if not highlight.animation then
        highlight.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
    end

    local icon = control.icon
    if not icon.animation then
        icon.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ChapterUpgradeRewardEntry_Keyboard_IconMouseOverAnimation", icon)
    end

    highlight.animation:PlayForward()
    icon.animation:PlayForward()

    local offsetX = -15
    local offsetY = 0
    InitializeTooltip(ItemTooltip, control, RIGHT, offsetX, offsetY, LEFT)
    local SHOW_COLLECTIBLE_PURCHASABLE_HINT = true
    ItemTooltip:SetMarketProduct(control.rewardData.marketProductId, SHOW_COLLECTIBLE_PURCHASABLE_HINT)

    self.selectedRow = control

    self.owner:RefreshActions()
end

function ZO_ChapterUpgradePane_Keyboard:OnRewardEntryMouseExit(control)
    control.highlight.animation:PlayBackward()
    control.icon.animation:PlayBackward()

    ClearTooltip(ItemTooltip)

    self.selectedRow = nil

    self.owner:RefreshActions()
end

function ZO_ChapterUpgradePane_Keyboard:OnRewardEntryMouseUp(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT and self:IsReadyToPreview() then
        self:PreviewSelection()
    end
end

function ZO_ChapterUpgradePane_Keyboard:IsActivelyPreviewing()
    local productId = self:GetSelectedProductId()
    if productId ~= 0 then
        return IsPreviewingMarketProduct(productId)
    end

    return false
end

function ZO_ChapterUpgradePane_Keyboard:GetPreviewState()
    local isPreviewing = IsCurrentlyPreviewing()
    local canPreview = false
    local isActivePreview = false

    if self.selectedRow ~= nil then
        canPreview = IsCharacterPreviewingAvailable() and self:CanPreviewSelection()

        if isPreviewing and self:IsActivelyPreviewing() then
            isActivePreview = true
        end
    end

    return isPreviewing, canPreview, isActivePreview
end

function ZO_ChapterUpgradePane_Keyboard:IsReadyToPreview()
    local _, canPreview, isActivePreview = self:GetPreviewState()
    return canPreview and not isActivePreview
end

-- Begin ZO_ChapterUpgradePane_Keyboard Overrides --

do
    local function AddRewards(rewards, controlPool, initialAnchorControl)
        local anchorTo = initialAnchorControl
        for _, rewardData in ipairs(rewards) do
            local rewardControl = controlPool:AcquireObject()
            rewardControl.icon:SetTexture(rewardData.icon)
            rewardControl.displayName:SetText(rewardData.displayName)
            rewardControl.standardCheckMark:SetHidden(not rewardData.isStandardReward)
            rewardControl.collectorsCheckMark:SetHidden(not rewardData.isCollectorsReward)
            rewardControl:SetAnchor(TOPLEFT, anchorTo, BOTTOMLEFT)
            rewardControl:SetAnchor(TOPRIGHT, anchorTo, BOTTOMRIGHT)
            rewardControl.rewardData = rewardData
            anchorTo = rewardControl
        end
    end

    function ZO_ChapterUpgradePane_Keyboard:SetChapterUpgradeData(chapterUpgradeData)
        ZO_ChapterUpgradePane_Shared.SetChapterUpgradeData(self, chapterUpgradeData)
    
        self.descriptionLabel:SetText(chapterUpgradeData:GetSummary())
        self.prepurchaseRewardPool:ReleaseAllObjects()
        self.editionRewardPool:ReleaseAllObjects()

        local hidePrePurchaseRewardsHeader = true
        local hideEditionRewardsHeader = true

        if chapterUpgradeData:IsPreRelease() then
            local prePurchaseRewards = chapterUpgradeData:GetPrePurchaseRewards()
            if #prePurchaseRewards > 0 then
                hidePrePurchaseRewardsHeader = false
                AddRewards(prePurchaseRewards, self.prepurchaseRewardPool, self.prepurchaseRewardsHeader)
            end
        end
        
        local editionRewards = chapterUpgradeData:GetEditionRewards()
        if #editionRewards > 0 then
            hideEditionRewardsHeader = false
            AddRewards(editionRewards, self.editionRewardPool, self.editionRewardsHeader)
        end

        self.prepurchaseRewardsHeader:SetHidden(hidePrePurchaseRewardsHeader)
        self.editionRewardsHeader:SetHidden(hideEditionRewardsHeader)
        if not hideEditionRewardsHeader then
            local isContentPass = chapterUpgradeData:IsContentPass()
            local collectorsHeaderLabelText = isContentPass and GetString(SI_CHAPTER_UPGRADE_CONTENT_PASS_COLLECTORS_REWARDS_HEADER) or GetString(SI_CHAPTER_UPGRADE_COLLECTORS_REWARDS_HEADER)
            self.editionRewardsHeaderCollectorsLabel:SetText(collectorsHeaderLabelText)
        end
    end
end

function ZO_ChapterUpgradePane_Keyboard:GetSelectedProductId()
    if self.selectedRow then
        return self.selectedRow.rewardData.marketProductId
    end
    return 0
end

function ZO_ChapterUpgradePane_Keyboard:GetItemPreviewListHelper()
    return ITEM_PREVIEW_LIST_HELPER_KEYBOARD
end

-- End ZO_ChapterUpgradePane_Keyboard Overrides --

-- Begin Global XML Functions --

function ZO_ChapterUpgradeRewardEntry_Keyboard_OnInitialized(control)
    ZO_ChapterUpgradeRewardEntry_Shared_OnInitialized(control)

    control.highlight = control:GetNamedChild("Highlight")
end

-- End Global XML Functions --