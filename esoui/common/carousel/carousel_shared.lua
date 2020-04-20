--
-- ZO_Carousel_Shared
--

ZO_Carousel_Shared = ZO_HorizontalScrollList_Gamepad:Subclass()

function ZO_Carousel_Shared:New(...)
    return ZO_HorizontalScrollList_Gamepad.New(self, ...)
end

function ZO_Carousel_Shared:Initialize(control, template, autoScroll)
    local function OnSelectedCallback(newData)
        if newData and newData.callback then
            newData.callback(newData)
        end
    end

    local NUM_VISIBLE_CATEGORIES = 1
    ZO_HorizontalScrollList_Gamepad.Initialize(self, control, template, NUM_VISIBLE_CATEGORIES, function(...) self:EntrySetup(...) end, MenuEntryTemplateEquality)
    self:SetOnTargetDataChangedCallback(OnSelectedCallback)
    self:SetDisplayEntryType(ZO_HORIZONTAL_SCROLL_LIST_DISPLAY_FIXED_NUMBER_OF_ENTRIES)

    if autoScroll then
        local MOVEMENT_DIRECTION = ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES.MOVE_LEFT
        local AUTO_SCROLL_DURATION_SECONDS = 10
        local POST_INTERACTION_DURATION_SECONDS = 10
        self:SetAutoScroll(MOVEMENT_DIRECTION, AUTO_SCROLL_DURATION_SECONDS, POST_INTERACTION_DURATION_SECONDS)
    end

    local ENABLE_CAROUSEL_WRAP = true
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
    self.selectionIndicator:SetButtonControlName("Indicator")
end

function ZO_Carousel_Shared:ResetScrollToTop()
    -- To be overridden
end

function ZO_Carousel_Shared:SetSelectionIndicatorPipStateImages(pipSelectedImage, pipUnselectedImage, pipMouseOverImage)
    self.selectionIndicator:SetButtonSelectedImage(pipSelectedImage)
    self.selectionIndicator:SetButtonUnselectedImage(pipUnselectedImage)
    self.selectionIndicator:SetButtonMouseOverImage(pipMouseOverImage)
end

function ZO_Carousel_Shared:SetSelectionIndicatorPipDimensions(width, height)
    self.selectionIndicator:SetButtonWidth(width)
    self.selectionIndicator:SetButtonHeight(height)
end

function ZO_Carousel_Shared:UpdateSelection(index)
    self.selectionIndicator:SetSelectionByIndex(index)
    self:ResetScrollToTop()
end

function ZO_Carousel_Shared:EntrySetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
    if control.canSelect == nil then
        control.canSelect = true
    end

    data.isSelected = selected
    control.object:Layout(data)

    local function ResetAutoScroll()
        self:ResetAutoScrollTimer()
    end

    if data.setOnInteractCallback then
        data.setOnInteractCallback(ResetAutoScroll)
    end
end

function ZO_Carousel_Shared:Commit()
    self.selectionIndicator:SetCount(self:GetNumItems())
    self.selectionIndicatorControl:SetHidden(not self:CanScroll())

    ZO_HorizontalScrollList_Gamepad.Commit(self)
end