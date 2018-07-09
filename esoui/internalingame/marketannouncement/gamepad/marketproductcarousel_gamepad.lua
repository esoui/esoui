--
-- ZO_MarketProductCarousel_Gamepad
--

ZO_MarketProductCarousel_Gamepad = ZO_MarketProductCarousel_Shared:Subclass()

function ZO_MarketProductCarousel_Gamepad:New(...)
    return ZO_MarketProductCarousel_Shared.New(self, ...)
end

function ZO_MarketProductCarousel_Gamepad:Initialize(...)
    ZO_MarketProductCarousel_Shared.Initialize(self, ...)
    self.leftArrow.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowScaleAnimation_Gamepad", self.leftArrow)
    self.rightArrow.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowScaleAnimation_Gamepad", self.rightArrow)

    self.leftArrow.downAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowDownScaleAnimation_Gamepad", self.leftArrow)
    self.rightArrow.downAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_MarketAnnouncement_ArrowDownScaleAnimation_Gamepad", self.rightArrow)

    self.selectionIndicator:SetButtonControlName("MarketProduct_Indicator_Gamepad")
    self.selection = self.control:GetNamedChild("Selection")

    local onActivationChanged = function(self, active)
        local control = self:GetCenterControl()
        if control then
            control.object:SetSelected(active)
        end
    end

    self:SetOnActivatedChangedFunction(onActivationChanged)

    local function UpdateScrollKeybind(newData)
        self:UpdateScrollKeybind(newData)
    end

    self:SetOnSelectedDataChangedCallback(UpdateScrollKeybind)

    self.focusData =
    {
        activate = function()
            self:Activate()
            local data = self:GetSelectedData()
            UpdateScrollKeybind(data)
        end,
        deactivate = function()
            self:Deactivate()
            local data = self:GetSelectedData()
            UpdateScrollKeybind(data)
        end,
        highlight = self.selection
    }
end

function ZO_MarketProductCarousel_Gamepad:UpdateScrollKeybind(newData)
    if self.scrollKeybindButton then
        local marketProduct = newData and newData.marketProduct
        if self.active and marketProduct then
            local shouldScroll = marketProduct.descriptionText and marketProduct.descriptionText:GetHeight() > marketProduct.description:GetHeight()
            self.scrollKeybindButton:SetHidden(not shouldScroll)
            marketProduct.description:SetDisabled(not self.active)
        else
            self.scrollKeybindButton:SetHidden(true)
        end
    end
end

function ZO_MarketProductCarousel_Gamepad:ResetScrollToTop()
    local data = self:GetSelectedData()
    local marketProduct = data and data.marketProduct
    if marketProduct and marketProduct.description then
        marketProduct.description:ResetToTop()
    end
end

function ZO_MarketProductCarousel_Gamepad:GetFocusEntryData()
    return self.focusData
end

function ZO_MarketProductCarousel_Gamepad:SetSelectKeybindButton(selectKeybindButton)
    self.selectKeybindButton = selectKeybindButton
end

function ZO_MarketProductCarousel_Gamepad:SetHelpKeybindButton(helpKeybindButton)
    self.helpKeybindButton = helpKeybindButton
end

function ZO_MarketProductCarousel_Gamepad:SetScrollKeybindButton(scrollKeybindButton)
    self.scrollKeybindButton = scrollKeybindButton
end

function ZO_MarketProductCarousel_Gamepad:SetKeybindAnchorControl(keybindAnchorControl)
    self.keybindAnchorControl = keybindAnchorControl
end

function ZO_MarketProductCarousel_Gamepad:EntrySetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    control.object:SetKeybindButton(self.selectKeybindButton)
    control.object:SetHelpKeybindButton(self.helpKeybindButton)
    control.object:SetKeybindAnchorControl(self.keybindAnchorControl)

    ZO_MarketProductCarousel_Shared.EntrySetup(self, control, data, self.active and selected, reselectingDuringRebuild, enabled, activated)
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