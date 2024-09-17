--
-- ZO_MarketProductCarousel_Gamepad
--

ZO_MarketProductCarousel_Gamepad = ZO_Carousel_Shared:Subclass()

function ZO_MarketProductCarousel_Gamepad:New(...)
    return ZO_Carousel_Shared.New(self, ...)
end

function ZO_MarketProductCarousel_Gamepad:Initialize(...)
    ZO_Carousel_Shared.Initialize(self, ...)
    self.leftArrow.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowScaleAnimation_Gamepad", self.leftArrow)
    self.rightArrow.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowScaleAnimation_Gamepad", self.rightArrow)

    self.leftArrow.downAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowDownScaleAnimation_Gamepad", self.leftArrow)
    self.rightArrow.downAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowDownScaleAnimation_Gamepad", self.rightArrow)

    self.selection = self.control:GetNamedChild("Selection")

    self.actionKeybindDescriptor =
    {
        name = function()
            local data = self:GetSelectedData()
            if data then
                local marketProductId = data.marketProduct and data.marketProduct.productData and data.marketProduct.productData.marketProductId
                if marketProductId then
                    local openBehavior = GetMarketProductOpenMarketBehavior(marketProductId)
                    if openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_CHAPTER_UPGRADE then
                        keybindStringId = SI_MARKET_ANNOUNCEMENT_VIEW_CHAPTER_UPGRADE
                    else
                        keybindStringId = SI_MARKET_ANNOUNCEMENT_VIEW_CROWN_STORE
                    end
                    return GetString(keybindStringId)
                end
            end
            return GetString(SI_GAMEPAD_SELECT_OPTION)
        end,
        keybind = "UI_SHORTCUT_PRIMARY",
        sound = function()
             if self.active then
                return SOUNDS.DIALOG_ACCEPT
            else
                return SOUNDS.DIALOG_DECLINE
            end
        end,
        visible = function()
            return self.active
        end,
        callback = function()
            if self.active then
                ZO_GAMEPAD_MARKET_ANNOUNCEMENT:OnMarketAnnouncementViewCrownStoreKeybind()
            end
        end
    }

    self.helpButtonKeybindDescriptor =
    {
        name = GetString(SI_MARKET_ANNOUNCEMENT_HELP_BUTTON),
        keybind = "UI_SHORTCUT_SECONDARY",
        sound = function()
             if self.active then
                return SOUNDS.DIALOG_ACCEPT
            else
                return SOUNDS.DIALOG_DECLINE
            end
        end,
        visible = function()
            local data = self:GetSelectedData()
            return self:IsHelpButtonKeybindVisible(data.marketProduct)
        end,
        callback = function()
            local data = self:GetSelectedData()
            if data.marketProduct then
                local helpCategoryIndex, helpIndex = GetMarketAnnouncementHelpLinkIndices(data.marketProduct:GetId())
                RequestShowSpecificHelp(helpCategoryIndex, helpIndex)
            end
        end
    }

    local function SetCenterControlActive(self, active)
        local control = self:GetCenterControl()
        if control then
            control.object:SetSelected(active)
        end
    end

    local function OnSelectedDataChanged(newData, oldData)
        SetCenterControlActive(self, self.active)
        if self.active then
            self:UpdateKeybinds(newData)
        end
    end

    self:SetOnActivatedChangedFunction(SetCenterControlActive)
    self:SetOnSelectedDataChangedCallback(OnSelectedDataChanged)

    self.focusData =
    {
        activate = function()
            self:Activate()
            local data = self:GetSelectedData()
            self:UpdateKeybinds(data)
        end,
        deactivate = function()
            self:Deactivate()
            local data = self:GetSelectedData()
            self:UpdateKeybinds(data)
        end,
        narrationText = function()
            local narrations = {}
            local data = self:GetSelectedData()
            if data then
                local marketProduct = data.marketProduct
                if marketProduct then
                    ZO_AppendNarration(narrations, marketProduct:GetNarrationText())
                end
            end
            return narrations
        end,
        highlight = self.selection
    }
end

function ZO_MarketProductCarousel_Gamepad:IsHelpButtonKeybindVisible(marketProduct)
    local helpCategoryIndex, helpIndex = GetMarketAnnouncementHelpLinkIndices(marketProduct:GetId())
    local hasHelpLink = helpCategoryIndex and helpIndex
    return marketProduct:IsPromo() and hasHelpLink
end

function ZO_MarketProductCarousel_Gamepad:UpdateKeybinds(newData)
    if self.scrollKeybindButton then
        local marketProduct = newData and newData.marketProduct
        if self.active and marketProduct then
            local descriptionControl = marketProduct:GetDescriptionControl()
            local descriptionTextControl = marketProduct:GetDescriptionTextControl()
            local shouldScroll = descriptionTextControl and descriptionTextControl:GetHeight() > descriptionControl:GetHeight()
            self.scrollKeybindButton:SetHidden(not shouldScroll)
            descriptionControl:SetDisabled(not self.active)
            self.selectKeybindButton:SetKeybindButtonDescriptor(self.actionKeybindDescriptor)
            self.selectKeybindButton:SetHidden(not self.active)
            if self:IsHelpButtonKeybindVisible(marketProduct) then
                self.selectKeybindButton:SetAnchor(TOPRIGHT, self.helpKeybindButton, TOPLEFT)
                self.helpKeybindButton:SetAnchor(TOPRIGHT, self.keybindAnchorControl, TOPLEFT)
                self.helpKeybindButton:SetHidden(false)
            else
                self.selectKeybindButton:SetAnchor(TOPRIGHT, self.keybindAnchorControl, TOPLEFT)
                self.helpKeybindButton:SetHidden(true)
            end
        else
            self.scrollKeybindButton:SetHidden(true)
            self.selectKeybindButton:SetAnchor(TOPRIGHT, self.keybindAnchorControl, TOPLEFT)
            self.selectKeybindButton:SetHidden(not self.active)
            self.helpKeybindButton:SetHidden(true)
        end
    end
end

function ZO_MarketProductCarousel_Gamepad:ResetScrollToTop()
    local data = self:GetSelectedData()
    local marketProduct = data and data.marketProduct
    if marketProduct then
        local descriptionControl = marketProduct:GetDescriptionControl()
        if descriptionControl then
            descriptionControl:ResetToTop()
        end
    end
end

function ZO_MarketProductCarousel_Gamepad:GetFocusEntryData()
    return self.focusData
end

function ZO_MarketProductCarousel_Gamepad:SetSelectKeybindButton(selectKeybindButton)
    self.selectKeybindButton = selectKeybindButton

    self.selectKeybindButton:SetKeybindButtonDescriptor(self.actionKeybindDescriptor)
end

function ZO_MarketProductCarousel_Gamepad:SetHelpKeybindButton(helpKeybindButton)
    self.helpKeybindButton = helpKeybindButton

    self.helpKeybindButton:SetKeybindButtonDescriptor(self.helpButtonKeybindDescriptor)
end

function ZO_MarketProductCarousel_Gamepad:SetScrollKeybindButton(scrollKeybindButton)
    self.scrollKeybindButton = scrollKeybindButton
end

function ZO_MarketProductCarousel_Gamepad:SetKeybindAnchorControl(keybindAnchorControl)
    self.keybindAnchorControl = keybindAnchorControl
end

function ZO_MarketProductCarousel_Gamepad:EntrySetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    ZO_Carousel_Shared.EntrySetup(self, control, data, self.active and selected, reselectingDuringRebuild, enabled, activated)
end

function ZO_MarketProductCarousel_Gamepad:SetAdditionalInputNarrationFunction(additionalInputNarrationFunction)
    self.focusData.additionalInputNarrationFunction = additionalInputNarrationFunction
end

function ZO_MarketProductCarousel_Gamepad:SetHeaderNarrationFunction(headerNarrationFunction)
    self.focusData.headerNarrationFunction = headerNarrationFunction
end

do
    local function EndArrowAnimationIfDisabled(control)
        local currentState = control:GetState()
        if currentState == BSTATE_DISABLED or currentState == BSTATE_DISABLED_PRESSED then
            if control.animation then
                control.animation:PlayInstantlyToStart()
            end
        end
    end

    -- Overriding ZO_HorizontalScrollList_Gamepad:UpdateArrows
    function ZO_MarketProductCarousel_Gamepad:UpdateArrows()
        ZO_HorizontalScrollList_Gamepad.UpdateArrows(self)

        EndArrowAnimationIfDisabled(self.leftArrow)
        EndArrowAnimationIfDisabled(self.rightArrow)
    end

    -- Overriding ZO_HorizontalScrollList_Gamepad:UpdateAnchors
    function ZO_MarketProductCarousel_Gamepad:UpdateAnchors(...)
        ZO_HorizontalScrollList.UpdateAnchors(self, ...)

        EndArrowAnimationIfDisabled(self.leftArrow)
        EndArrowAnimationIfDisabled(self.rightArrow)
    end
end