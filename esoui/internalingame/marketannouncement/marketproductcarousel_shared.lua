--
-- ZO_MarketProductCarousel_Shared
--

ZO_MarketProductCarousel_Shared = ZO_HorizontalScrollList_Gamepad:Subclass()

function ZO_MarketProductCarousel_Shared:New(...)
    return ZO_HorizontalScrollList_Gamepad.New(self, ...)
end

function ZO_MarketProductCarousel_Shared:SetNumProductAnnouncements(numProducts)
    self.selectionIndicator:SetCount(numProducts)
end

function ZO_MarketProductCarousel_Shared:ResetScrollToTop()
    -- To be overridden
end

function ZO_MarketProductCarousel_Shared:UpdateSelection(index)
    self.selectionIndicator:SetSelectionByIndex(index)
    self:ResetScrollToTop()
end

function ZO_MarketProductCarousel_Shared:EntrySetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    if control.canSelect == nil then
        control.canSelect = true
    end

    control.object:Layout(data.marketProduct, selected)

    local function resetAutoScroll()
        self.lastScrollTime = GetFrameTimeSeconds()
        self.lastInteractionAutomatic = false
    end

    control.object.marketProduct:SetOnInteractWithScrollCallback(resetAutoScroll)
end

function ZO_MarketProductCarousel_Shared:Initialize(control, template)
    local function OnSelectionChanged(newData)
        if newData.callback then
            newData.callback(newData)
        end
    end

    local NUM_VISIBLE_CATEGORIES = 1
    
    ZO_HorizontalScrollList_Gamepad.Initialize(self, control, template, NUM_VISIBLE_CATEGORIES, function(...) self:EntrySetup(...) end, MenuEntryTemplateEquality)
    self:SetOnTargetDataChangedCallback(OnSelectionChanged)
    self:SetAllowWrapping(false)
    self:SetDisplayEntryType(ZO_HORIZONTAL_SCROLL_LIST_DISPLAY_FIXED_NUMBER_OF_ENTRIES)

    local MOVEMENT_DIRECTION = ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES.MOVE_LEFT
    local AUTO_SCROLL_DURATION_SECONDS = 5
    local POST_INTERACTION_DURATION_SECONDS = 10
    local ENABLE_CAROUSEL_WRAP = true
    self:SetAutoScroll(MOVEMENT_DIRECTION, AUTO_SCROLL_DURATION_SECONDS, POST_INTERACTION_DURATION_SECONDS)
    self:SetAllowWrapping(ENABLE_CAROUSEL_WRAP)

    local function SelectionIndicatorClickedCallback()
        local selectedIndex = self.selectionIndicator:GetSelectionIndex()

        -- ZO_HorizontalScrollList:SetSelectedIndex expects indicies 0 through negative n - 1 for indices 1 through n
        local scrollListIndex = -(selectedIndex - 1)
        self:SetSelectedIndex(scrollListIndex)
    end

    self.selectionIndicatorControl = self.control:GetNamedChild("SelectionIndicator")
    self.selectionIndicator = self.selectionIndicatorControl.object
    self.selectionIndicator:SetGrowthPadding(10)
    self.selectionIndicator:SetButtonClickedCallback(SelectionIndicatorClickedCallback)
end