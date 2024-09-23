--Vetical Scrollbar Base
------------------------

local OFF_ALPHA = 0.5
local SCROLL_AREA_ALPHA = 0.8
local ON_ALPHA = 1
local STATE_CHANGE_DURATION = 250
local MIN_SCROLL_VALUE = 0
local MAX_SCROLL_VALUE = 100
local MAX_FADE_DISTANCE_UI = 64
local DEFAULT_Y_DISTANCE_FROM_EDGE_WHERE_SELECTION_CAUSES_SCROLL = 150

local NO_SELECTED_DATA = nil
local NO_DATA_CONTROL = nil
local RESELECTING_DURING_REBUILD = true
local NOT_RESELECTING_DURING_REBUILD = false
local ANIMATE_INSTANTLY = true
local DONT_ANIMATE_INSTANTLY = false

ZO_SCROLL_LIST_OPERATION_ADVANCE_CURSOR = "advance_cursor"
ZO_SCROLL_LIST_OPERATION_LINE_BREAK = "line_break"

ZO_SCROLL_MOVEMENT_DIRECTION_NEGATIVE = -1
ZO_SCROLL_MOVEMENT_DIRECTION_NONE = 0
ZO_SCROLL_MOVEMENT_DIRECTION_POSITIVE = 1

ZO_SCROLL_BUILD_DIRECTION_LEFT_TO_RIGHT = 1
ZO_SCROLL_BUILD_DIRECTION_RIGHT_TO_LEFT = -1

ZO_SCROLL_SELECT_CATEGORY_PREVIOUS = -1
ZO_SCROLL_SELECT_CATEGORY_NEXT = 1

ZO_SCROLL_BAR_WIDTH = 16

-- Used by both ZO_VerticalScrollbarBase and ZO_Scroll
local function OnInteractWithScrollBar(self)
    if self.onInteractWithScrollbarCallback then
        self.onInteractWithScrollbarCallback()
    end
end

----
-- Start of VerticalScrollbarBase functions
----

local function VerticalScrollbarBase_SetOnInteractWithScrollbarCallback(self, onInteractWithScrollbarCallback)
    self.onInteractWithScrollbarCallback = onInteractWithScrollbarCallback
end

function ZO_VerticalScrollbarBase_OnInitialized(self)
    self:SetMinMax(MIN_SCROLL_VALUE, MAX_SCROLL_VALUE)
    self:SetValue(MIN_SCROLL_VALUE)
    self.targetAlpha = OFF_ALPHA
    self:SetAlpha(self.targetAlpha)
    self.alphaAnimation, self.timeline = CreateSimpleAnimation(ANIMATION_ALPHA, self)
    self.alphaAnimation:SetDuration(STATE_CHANGE_DURATION)

    local function OnUpdate()
        if self.thumbHeld then
            OnInteractWithScrollBar(self)
        end
    end

    self:SetHandler("OnUpdate", OnUpdate)
end

local function UpdateAlpha(self)
    local newAlpha = OFF_ALPHA

    if self.areaOver then
        newAlpha = SCROLL_AREA_ALPHA
    end
    
    if self.thumbHeld or self.over then
        newAlpha = ON_ALPHA
    end
    
    if newAlpha ~= self:GetAlpha() then
        self.targetAlpha = newAlpha
        if self:IsHidden() then
            self:SetAlpha(newAlpha)
        else
            self.timeline:Stop()
            self.alphaAnimation:SetAlphaValues(self:GetAlpha(), newAlpha)
            self.timeline:PlayFromStart()
        end
    end
end

function ZO_VerticalScrollbarBase_OnMouseEnter(self)
    self.over = true
    UpdateAlpha(self)
end

function ZO_VerticalScrollbarBase_OnMouseExit(self)
    self.over = false
    UpdateAlpha(self)
end

function ZO_VerticalScrollbarBase_OnMouseDown(self)
    local thumb = self:GetThumbTextureControl()
    if MouseIsOver(thumb) then
        self.thumbHeld = true
        UpdateAlpha(self)
    end
end

function ZO_VerticalScrollbarBase_OnScrollBarArrowClicked(self)
    OnInteractWithScrollBar(self)
end

function ZO_VerticalScrollbarBase_OnMouseUp(self)
    self.thumbHeld = false
    UpdateAlpha(self)
end

function ZO_VerticalScrollbarBase_OnEffectivelyHidden(self)    
    if self.timeline then
        self.timeline:Stop()
    end
    self:SetAlpha(self.targetAlpha)
end

function ZO_VerticalScrollbarBase_OnScrollAreaEnter(self)
    self.areaOver = true
    UpdateAlpha(self)
end

function ZO_VerticalScrollbarBase_OnScrollAreaExit(self)
    self.areaOver = false
    UpdateAlpha(self)
end

----
-- End of VerticalScrollbarBase functions
----

local function CheckMouseInScrollArea(self)
    local inScrollArea = MouseIsOver(self)
    if inScrollArea ~= self.inScrollArea then
        self.inScrollArea = inScrollArea
        if inScrollArea then
            ZO_VerticalScrollbarBase_OnScrollAreaEnter(GetControl(self, "ScrollBar"))
        else
            ZO_VerticalScrollbarBase_OnScrollAreaExit(GetControl(self, "ScrollBar"))
        end
    end
end

function ZO_ScrollAreaBarBehavior_OnEffectivelyShown(self)
    self.inScrollArea = nil
    self:SetHandler("OnUpdate", CheckMouseInScrollArea)
end

function ZO_ScrollAreaBarBehavior_OnEffectivelyHidden(self)
    self:SetHandler("OnUpdate", nil)
    ZO_VerticalScrollbarBase_OnScrollAreaExit(GetControl(self, "ScrollBar"))
end

--Shared Scroll Animation Functions
---------------------------------------

local SCROLL_ANIMATION_UNITS_PERCENT = 1
local SCROLL_ANIMATION_UNITS_REAL = 2

local SCROLL_ANIMATION_DEFAULT_DURATION_MS = 400

local function OnScrollAnimationUpdate(animationObject, progress)
    local scrollObject = animationObject.scrollObject
    local value = scrollObject.animationStart + (scrollObject.animationTarget - scrollObject.animationStart) * progress
    if scrollObject.animationUnits == SCROLL_ANIMATION_UNITS_REAL then
        local _, verticalExtents = scrollObject.scroll:GetScrollExtents()
        if verticalExtents > 0 then
            -- Store off raw offset if the value is out of the bounds of the extents
            -- and extents have not yet updated and animation progress is complete.
            if progress == 1 and verticalExtents < value then
                scrollObject.scrollRawOffset = value
            end
            value = MAX_SCROLL_VALUE * (value / verticalExtents)
        else
            value = 0
        end
    end
    scrollObject.scrollbar:SetValue(value)
end

local function SetScrollOffset(self, targetOffset, animateInstantly, overrideDurationMS)
    local scroll = self.scroll
    local _, currentOffset = scroll:GetScrollOffsets()
    if zo_abs(targetOffset - currentOffset) > 0.001 then
        self.timeline:Stop()
        self.animationStart = currentOffset
        self.animationTarget = targetOffset
        self.animationUnits = SCROLL_ANIMATION_UNITS_REAL
        self.animation:SetDuration(overrideDurationMS or SCROLL_ANIMATION_DEFAULT_DURATION_MS)
        if animateInstantly then
            self.timeline:PlayInstantlyToEnd()
        else
            self.timeline:PlayFromStart()
        end
    elseif self.onScrollCompleteCallback then 
        local SCROLL_ANIMATION_COMPLETE = true
        self.onScrollCompleteCallback(SCROLL_ANIMATION_COMPLETE) 
        self.onScrollCompleteCallback = nil
    end
end

local function SetSliderValue(self, targetValue, animateInstantly, overrideDurationMS)
    if self.scrollbar then
        local startValue = self.scrollbar:GetValue()
        local scrollMin, scrollMax = self.scrollbar:GetMinMax()
        targetValue = zo_clamp(targetValue, scrollMin, scrollMax)
        if zo_abs(startValue - targetValue) > 0.001 then 
            self.timeline:Stop()
            self.animationStart = startValue
            self.animationTarget = targetValue
            self.animationUnits = SCROLL_ANIMATION_UNITS_PERCENT
            self.animation:SetDuration(overrideDurationMS or SCROLL_ANIMATION_DEFAULT_DURATION_MS)
            if animateInstantly then
                self.timeline:PlayInstantlyToEnd()
            else
                self.timeline:PlayFromStart()
            end
        elseif self.onScrollCompleteCallback then 
            local SCROLL_ANIMATION_COMPLETE = true
            self.onScrollCompleteCallback(SCROLL_ANIMATION_COMPLETE) 
            self.onScrollCompleteCallback = nil 
        end
    end
end

local function OnAnimationStop(animationObject, control, completedPlaying)
    local scrollObject = animationObject.scrollObject
    scrollObject.animationStart = nil
    scrollObject.animationTarget = nil

    if scrollObject.onScrollCompleteCallback then
        scrollObject.onScrollCompleteCallback(completedPlaying)
        scrollObject.onScrollCompleteCallback = nil
    end
end

local function CreateScrollAnimation(scrollObject)
    local animation, timeline = CreateSimpleAnimation(ANIMATION_CUSTOM)
    animation.scrollObject = scrollObject
    animation:SetEasingFunction(ZO_BezierInEase)
    animation:SetUpdateFunction(OnScrollAnimationUpdate)
    animation:SetHandler("OnStop", OnAnimationStop)

    return animation, timeline
end

--Shared Scroll Edge Fades
-----------------------------------------------------------------

local function ComputeScrollFadeDistancesFromRealValues(sliderValue, sliderMin, sliderMax, maxFadeDistance)
    local topFadeDistance = zo_max(0, zo_min(sliderValue - sliderMin, maxFadeDistance))
    local bottomFadeDistance = zo_max(0, zo_min(sliderMax - sliderValue, maxFadeDistance))
    return topFadeDistance, bottomFadeDistance    
end

local function ComputeScrollFadeDistancesFromPercentValues(sliderValue, verticalExtents, maxFadeDistance)
    local realSliderMin = 0
    local realSliderMax = verticalExtents
    local realSliderValue = (sliderValue / MAX_SCROLL_VALUE) * verticalExtents
    return ComputeScrollFadeDistancesFromRealValues(realSliderValue, realSliderMin, realSliderMax, maxFadeDistance)
end

local function UpdateScrollFade(self, scroll, isPercent, sliderValue)
    if self.useFadeGradient then
        local slider = self.scrollbar
        sliderValue = sliderValue or slider:GetValue()
        local maxFadeDistance = ZO_Scroll_GetMaxFadeDistance(self)
        local topFadeDistance, bottomFadeDistance
        if isPercent then
            local _, verticalExtents = scroll:GetScrollExtents()
            topFadeDistance, bottomFadeDistance = ComputeScrollFadeDistancesFromPercentValues(sliderValue, verticalExtents, maxFadeDistance)
        else
            local sliderMin, sliderMax = slider:GetMinMax()
            topFadeDistance, bottomFadeDistance = ComputeScrollFadeDistancesFromRealValues(sliderValue, sliderMin, sliderMax, maxFadeDistance)
        end

        if topFadeDistance > 0 then
            scroll:SetFadeGradient(1, 0, 1, topFadeDistance * scroll:GetScale())
        else
            scroll:SetFadeGradient(1, 0, 0, 0)
        end
        
        if bottomFadeDistance > 0 then
            scroll:SetFadeGradient(2, 0, -1, bottomFadeDistance * scroll:GetScale())
        else
            scroll:SetFadeGradient(2, 0, 0, 0);
        end
    else
        scroll:SetFadeGradient(1, 0, 0, 0)
        scroll:SetFadeGradient(2, 0, 0, 0)
    end
end


--Scroll Control - Encapsulates a scroll control with a scrollbar
-----------------------------------------------------------------

--Init

local function ZO_ScrollUp_OnMouseDown(self)
    ZO_Scroll_ScrollRelative(self:GetParent():GetParent(), -40)
end

local function ZO_ScrollDown_OnMouseDown(self)
    ZO_Scroll_ScrollRelative(self:GetParent():GetParent(), 40)
end

local function ZO_Scroll_ScrollOrBarOnHeightChanged(scrollOrBarControl, newHeight)
    local scrollPane = scrollOrBarControl:GetParent()
    ZO_Scroll_UpdateScrollBar(scrollPane)
end

function ZO_Scroll_Initialize(self)
    self.scroll = GetControl(self, "Scroll")
    self.scroll:SetHandler("OnRectHeightChanged", ZO_Scroll_ScrollOrBarOnHeightChanged)
    self.scrollbar = GetControl(self, "ScrollBar")
    
    if self.scrollbar then
        self.scrollUpButton = GetControl(self.scrollbar, "Up")
        self.scrollUpButton:SetHandler("OnMouseDown", ZO_ScrollUp_OnMouseDown)
        self.scrollDownButton = GetControl(self.scrollbar, "Down")
        self.scrollDownButton:SetHandler("OnMouseDown", ZO_ScrollDown_OnMouseDown)
        self.scrollbar:SetHandler("OnRectHeightChanged", ZO_Scroll_ScrollOrBarOnHeightChanged)
    end
    
    self.isScrollBarEthereal = false
    self.useScrollbar = true
    self.hideScrollBarOnDisabled = true
    self.useFadeGradient = true

    self.animation, self.timeline = CreateScrollAnimation(self)
    
    ZO_Scroll_UpdateScrollBar(self)
end

--Scrolling functions
function ZO_Scroll_ResetToTop(self)
    if self.timeline then
        self.timeline:Stop()
    end
    if self.scrollbar then
        self.scrollbar:SetValue(MIN_SCROLL_VALUE)
    end
end

function ZO_Scroll_ScrollAbsolute(self, value)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()

    if verticalExtents > 0 then
        SetSliderValue(self, (value / verticalExtents) * MAX_SCROLL_VALUE)
    end
end

function ZO_Scroll_ScrollAbsoluteInstantly(self, value)
    local scroll = self.scroll
    local scrollbar = self.scrollbar
    local _, verticalExtents = scroll:GetScrollExtents()
    local targetValue = (value / verticalExtents) * MAX_SCROLL_VALUE
    local scrollMin, scrollMax = scrollbar:GetMinMax()
    targetValue = zo_clamp(targetValue, scrollMin, scrollMax)
    SetSliderValue(self, targetValue, ANIMATE_INSTANTLY)
end

function ZO_Scroll_ScrollRelative(self, verticalDelta)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()
    
    if verticalExtents > 0 then
        if self.animationTarget then
            local oldVerticalOffset
            if self.animationUnits == SCROLL_ANIMATION_UNITS_PERCENT then
                oldVerticalOffset = (self.animationTarget * verticalExtents) / MAX_SCROLL_VALUE
            else
                oldVerticalOffset = self.animationTarget
            end
            local newVerticalOffset = oldVerticalOffset + verticalDelta
            SetSliderValue(self, (newVerticalOffset / verticalExtents) * MAX_SCROLL_VALUE)
        else
            local _, currentVerticalOffset = scroll:GetScrollOffsets()
            local newVerticalOffset = currentVerticalOffset + verticalDelta
            SetSliderValue(self, (newVerticalOffset / verticalExtents) * MAX_SCROLL_VALUE)
        end
    end
end

function ZO_Scroll_MoveWindow(self, value)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()

    scroll:SetVerticalScroll((value/MAX_SCROLL_VALUE) * verticalExtents)
    ZO_Scroll_UpdateScrollBar(self)
end

local SCROLL_TO_SIDE_TOP = 1
local SCROLL_TO_SIDE_BOTTOM = 2

function ZO_Scroll_GetScrollDistanceToControl(self, otherControl, scrollToSide)
    local scroll = self.scroll
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    local controlTop = otherControl:GetTop()
    local controlBottom = otherControl:GetBottom()   
 
    local scrollDistance = 0
    if scrollToSide == SCROLL_TO_SIDE_TOP then -- The control's top is above the top edge of the scroll, must scroll up to fully contain the control.
        scrollDistance = controlTop - scrollTop
    elseif scrollToSide == SCROLL_TO_SIDE_BOTTOM  then -- The control's bottom is below the bottom edge of the scroll, must scroll down to fully contain the control.
        scrollDistance = controlBottom - scrollBottom
    end

    if scrollDistance ~= 0 and self.useFadeGradient then
        local _, verticalOffset = scroll:GetScrollOffsets()
        local _, verticalExtents = scroll:GetScrollExtents()
        local verticalOffsetAfterScroll = zo_clamp(verticalOffset + scrollDistance, 0, verticalExtents)
        local topFadeDistance, bottomFadeDistance = ComputeScrollFadeDistancesFromRealValues(verticalOffsetAfterScroll, 0, verticalExtents, ZO_Scroll_GetMaxFadeDistance(self))
        if scrollToSide == SCROLL_TO_SIDE_TOP then
            -- divide by 2 for effect
            scrollDistance = scrollDistance - topFadeDistance * 0.5
        else
            -- divide by 2 for effect
            scrollDistance = scrollDistance + bottomFadeDistance * 0.5
        end
    end
    
    return scrollDistance
end

function ZO_Scroll_ScrollToControl(self, otherControl)
    local scroll = self.scroll
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    local controlTop = otherControl:GetTop()
    local controlBottom = otherControl:GetBottom()   
 
    local scrollToSide
    if controlTop < scrollTop then -- The control's top is above the top edge of the scroll, must scroll up to fully contain the control.
        scrollToSide = SCROLL_TO_SIDE_TOP
    elseif controlBottom > scrollBottom then -- The control's bottom is below the bottom edge of the scroll, must scroll down to fully contain the control.
        scrollToSide = SCROLL_TO_SIDE_BOTTOM
    end
  
    local scrollDistance = ZO_Scroll_GetScrollDistanceToControl(self, otherControl, scrollToSide)
    if scrollDistance ~= 0 then    
         ZO_Scroll_ScrollRelative(self, scrollDistance)
    end
end

function ZO_Scroll_ScrollControlToTop(self, otherControl)
    local scrollDistance = ZO_Scroll_GetScrollDistanceToControl(self, otherControl, SCROLL_TO_SIDE_TOP)
    if scrollDistance ~= 0 then    
         ZO_Scroll_ScrollRelative(self, scrollDistance)
    end
end

function ZO_Scroll_ScrollControlToBottom(self, otherControl)
    local scrollDistance = ZO_Scroll_GetScrollDistanceToControl(self, otherControl, SCROLL_TO_SIDE_BOTTOM)
    if scrollDistance ~= 0 then    
         ZO_Scroll_ScrollRelative(self, scrollDistance)
    end
end

function ZO_Scroll_IsControlFullyInView(self, control)
    local scroll = self.scroll
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    local controlTop = control:GetTop()
    local controlBottom = control:GetBottom()
    
    return controlTop >= scrollTop and controlBottom <= scrollBottom
end

function ZO_Scroll_ScrollControlIntoView(self, otherControl)
    local scroll = self.scroll
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    local controlTop = otherControl:GetTop()
    local controlBottom = otherControl:GetBottom()
    
    if controlTop < scrollTop then
        ZO_Scroll_ScrollRelative(self, controlTop - scrollTop)
    elseif controlBottom > scrollBottom then
        ZO_Scroll_ScrollRelative(self, controlBottom - scrollBottom)
    end
end

function ZO_Scroll_ScrollControlIntoCentralView(self, otherControl, scrollInstantly)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()
    local _, verticalOffset = scroll:GetScrollOffsets()
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    local controlTop = otherControl:GetTop()
    local controlBottom = otherControl:GetBottom()

    local halfControlHeight = (controlBottom - controlTop) * 0.5
    local halfScrollHeight = (scrollBottom - scrollTop) * 0.5
    local scrollDistance = controlTop + halfControlHeight - scrollTop - halfScrollHeight

    local scrollToValue = zo_clamp(verticalOffset + scrollDistance, 0, verticalExtents)

    if scrollInstantly then
        ZO_Scroll_ResetToTop(self)

        local targetValue = (scrollToValue / verticalExtents) * MAX_SCROLL_VALUE

        SetSliderValue(self, targetValue, scrollInstantly)
    else
        ZO_Scroll_ScrollAbsolute(self, scrollToValue)
    end
end

function ZO_Scroll_SetScrollToRealOffsetAccountingForGradients(self, finalTotalHeight, controlFinalTopOffset, durationMS)
    local scroll = self.scroll
    local scrollHeight = scroll:GetHeight()
    local finalVerticalExtents = zo_max(finalTotalHeight - scrollHeight, 0)
    local finalVerticalOffset = controlFinalTopOffset
    if self.useFadeGradient then            
        local topGradientHeight = ComputeScrollFadeDistancesFromRealValues(finalVerticalOffset, 0, finalVerticalExtents, ZO_Scroll_GetMaxFadeDistance(self))
            -- divide by 2 for effect
        finalVerticalOffset = finalVerticalOffset - topGradientHeight * 0.5
    end
    finalVerticalOffset = zo_clamp(finalVerticalOffset, 0, finalVerticalExtents)
    if durationMS == 0 then
        SetScrollOffset(self, finalVerticalOffset, ANIMATE_INSTANTLY)
    else
        SetScrollOffset(self, finalVerticalOffset, DONT_ANIMATE_INSTANTLY, durationMS)
    end
end

--Scroll update functions

function ZO_Scroll_OnExtentsChanged(self)
    if self and self.scroll and not self.targetControl then
        ZO_Scroll_UpdateScrollBar(self)
    end
end

function ZO_Scroll_OnMouseWheel(self, delta)
    ZO_Scroll_ScrollRelative(self, -delta * 40)
    OnInteractWithScrollBar(self)
end

function ZO_Scroll_SetOnInteractWithScrollbarCallback(self, onInteractWithScrollbarCallback)
    self.onInteractWithScrollbarCallback = onInteractWithScrollbarCallback

    if self.scrollbar then
        VerticalScrollbarBase_SetOnInteractWithScrollbarCallback(self.scrollbar, onInteractWithScrollbarCallback)
    end
end

function ZO_Scroll_UpdateScrollBar(self, forceUpdateBarValue)
    local scroll = self.scroll
    local _, verticalOffset = scroll:GetScrollOffsets()
    local _, verticalExtents   = scroll:GetScrollExtents()
    local scrollEnabled = verticalExtents > 0 or verticalOffset > 0
    local scrollbar  = self.scrollbar
    local scrollIndicator = self.scrollIndicator
    local scrollbarHidden = not self.useScrollbar or (self.hideScrollBarOnDisabled and not scrollEnabled) or self.isScrollBarEthereal
    local verticalExtentsChanged = self.verticalExtents ~= nil and not zo_floatsAreEqual(self.verticalExtents, verticalExtents)
    self.verticalExtents = verticalExtents

    if scrollbar then
        --thumb resizing
        local scale = scroll:GetScale()
        local scrollBarHeight = scrollbar:GetHeight() / scale
        local scrollAreaHeight = scroll:GetHeight() / scale
        if verticalExtents > 0 and scrollBarHeight >= 0 and scrollAreaHeight >= 0 then
            local thumbHeight = scrollBarHeight * scrollAreaHeight /(verticalExtents + scrollAreaHeight)
            scrollbar:SetThumbTextureHeight(thumbHeight)
        else
            scrollbar:SetThumbTextureHeight(scrollBarHeight)
        end

        --set mouse input enabled based on scrollability
        scroll:SetMouseEnabled(scrollEnabled)

        --auto scroll bar hiding
        local wasHidden = scrollbar:IsHidden()
        scrollbar:SetHidden(scrollbarHidden)
        local maxScrollValue = (not scrollbarHidden or self.isScrollBarEthereal) and MAX_SCROLL_VALUE or MIN_SCROLL_VALUE
        scrollbar:SetMinMax(MIN_SCROLL_VALUE, maxScrollValue)
        if wasHidden and not scrollbarHidden and scrollbar.resetScrollbarOnShow then
            ZO_Scroll_ResetToTop(self)
            self.scrollValue = MIN_SCROLL_VALUE
        end

        --update the scrollBar value when the extents changes or explicitly ask to
        if verticalExtentsChanged or forceUpdateBarValue then
            if verticalExtents > 0 then
                local previousScrollBarValue = scrollbar:GetValue()
                verticalOffset = self.scrollRawOffset and self.scrollRawOffset or verticalOffset
                local finalValue = MAX_SCROLL_VALUE * (verticalOffset / verticalExtents)
                if not zo_floatsAreEqual(previousScrollBarValue, finalValue) then
                    scrollbar:SetValue(finalValue)
                end

                -- If the previous and current scrollBar values are the same, 
                -- the onValueChanged function will not be invoked to update the scroll child position.
                -- We need to explicitly call to recalculate our scroll child position since our extents changed.
                if previousScrollBarValue == scrollbar:GetValue() then
                    scroll:SetVerticalScroll(verticalOffset)
                end
            else
                ZO_Scroll_ResetToTop(self)
            end
        end
        self.scrollRawOffset = nil

        local IS_PERCENT = true
        UpdateScrollFade(self, scroll, IS_PERCENT)
    elseif scrollIndicator then
        --auto scroll indicator hiding
        local wasHidden = scrollIndicator:IsHidden()
        scrollIndicator:SetHidden(scrollbarHidden)
        if wasHidden and not scrollbarHidden then
            ZO_Scroll_ResetToTop(self)
            self.scrollValue = 0
        end

        --extents updating
        if verticalExtentsChanged then
            if verticalExtents <= 0 then
                ZO_Scroll_ResetToTop(self)
            end
        end

        ZO_UpdateScrollFade(self.useFadeGradient, scroll, ZO_SCROLL_DIRECTION_VERTICAL)
    end
end

--Visual Config

function ZO_Scroll_GetScrollIndicator(self)
    return self.scrollIndicator
end

function ZO_Scroll_SetScrollbarEthereal(self, isEthereal)
    if self.isScrollBarEthereal ~= isEthereal then
        self.isScrollBarEthereal = isEthereal
        ZO_Scroll_UpdateScrollBar(self)
    end
end

function ZO_Scroll_SetHideScrollbarOnDisable(self, hide)
    self.hideScrollBarOnDisabled = hide
    ZO_Scroll_UpdateScrollBar(self)
end

function ZO_Scroll_SetUseScrollbar(self, useScrollbar)
    self.useScrollbar = useScrollbar
    ZO_Scroll_UpdateScrollBar(self)
end

function ZO_Scroll_SetUseFadeGradient(self, useFadeGradient)
    self.useFadeGradient = useFadeGradient
end

function ZO_Scroll_SetMaxFadeDistance(self, maxFadeDistance)
    self.maxFadeDistanceUI = maxFadeDistance
end

function ZO_Scroll_GetMaxFadeDistance(self)
    return self.maxFadeDistanceUI or MAX_FADE_DISTANCE_UI
end

function ZO_Scroll_SetupGutterTexture(self, textureControl)
    textureControl:ClearAnchors()
    textureControl:SetAnchor(TOPLEFT, self.scrollUpButton, BOTTOMLEFT, 0, 0)
    textureControl:SetAnchor(BOTTOMRIGHT, self.scrollDownButton, TOPRIGHT, 0, 0)
    textureControl:SetParent(self.scrollbar)
    
    self.gutter = textureControl
    
    ZO_Scroll_UpdateScrollBar(self)
end

function ZO_Scroll_SetResetScrollbarOnShow(self, resetOnShow)
    self.resetScrollbarOnShow = resetOnShow
end

--Scroll List Control
--A scrollable list of controls that reuses controls as they scroll out of view. 
--Use this control when you have a very large number of a couple different types of controls to display.
--To use:
--(1) Add a scroll list to your XML.
--(2) Add data types to the scroll list, one for each type of control. A data type includes an XML control template, a height, and a callback that can setup the control given data.
--(3) Add data to the scroll list. First, use GetDataList to get the table holding the data. Next, use CreateDataEntry to create a list element of a certain data type. You may pass
--    in an arbitrary piece of data that will be given to the setup callback when the control is shown. Once you have made as many data entries as you need, add them to the data
--    list in any way you want. Finally, call Commit to update the scroll list with your data.
-- Note: The scroll list can use faster update logic if all controls are the same height.
-------------------------------------------------------------------------------------------------------------

local SCROLL_LIST_UNIFORM = 1
local SCROLL_LIST_NON_UNIFORM = 2
local SCROLL_LIST_OPERATIONS = 3
local NO_HEIGHT_SET = -1

local function ZO_ScrollListUp_OnMouseDown(self)
    ZO_ScrollList_ScrollRelative(self:GetParent():GetParent(), -40)
end

local function ZO_ScrollListDown_OnMouseDown(self)
    ZO_ScrollList_ScrollRelative(self:GetParent():GetParent(), 40)
end

function ZO_ScrollList_Initialize(self)
    self.dataTypes = {}
    self.data = {}
    self.offset = 0
    self.yDistanceFromEdgeWhereSelectionCausesScroll = DEFAULT_Y_DISTANCE_FROM_EDGE_WHERE_SELECTION_CAUSES_SCROLL
    self.activeControls = {}
    self.visibleData = {}
    self.categories = {}
    self.mode = SCROLL_LIST_UNIFORM
    self.buildDirection = ZO_SCROLL_BUILD_DIRECTION_LEFT_TO_RIGHT
    self.uniformControlHeight = NO_HEIGHT_SET
    
    self.highlightLocked = false
    self.highlightedControl = nil
    self.highlightCallback = nil
    self.pendingHighlightControl = nil
    
    self.selectedControl = nil
    self.selectedData = nil
    self.selectedDataIndex = nil
    self.lastSelectedDataIndex = nil
    self.selectionDataTypes = nil
    self.deselectOnReselect = true
    self.autoSelect = false
    
    self.contents = GetControl(self, "Contents")
    self.scrollbar = GetControl(self, "ScrollBar")
    self.upButton = GetControl(self.scrollbar, "Up")
    self.upButton:SetHandler("OnMouseDown", ZO_ScrollListUp_OnMouseDown)
    self.downButton = GetControl(self.scrollbar, "Down")
    self.downButton:SetHandler("OnMouseDown", ZO_ScrollListDown_OnMouseDown)
    
    self.scrollbar:SetEnabled(false)

    self.animation, self.timeline = CreateScrollAnimation(self)

    self.isScrollBarEthereal = false
    self.hideScrollBarOnDisabled = true
    self.useScrollbar = true
    self.useFadeGradient = true

    ZO_ScrollList_Commit(self)
end

function ZO_ScrollList_SetYDistanceFromEdgeWhereSelectionCausesScroll(self, yDistanceFromEdgeWhereSelectionCausesScroll)
    self.yDistanceFromEdgeWhereSelectionCausesScroll = yDistanceFromEdgeWhereSelectionCausesScroll
end

function ZO_ScrollList_SetHeight(self, height)
    self:SetHeight(height)
end

function ZO_ScrollList_GetHeight(self)
    return self:GetHeight()
end

local function AreSelectionsEnabled(self)
    if self.selectionTemplate or self.selectionCallback then
        return true
    else
        return false
    end
end

function ZO_ScrollList_AddResizeOnScreenResize(self)
    local function OnScreenResized()
        ZO_ScrollList_SetHeight(self, self:GetHeight())
        ZO_ScrollList_Commit(self)    
    end
    self:RegisterForEvent(EVENT_SCREEN_RESIZED, OnScreenResized)
end

do
    local function OnRectHeightChanged(self, newHeight)
        if self:IsHidden() then
            self:SetHandler("OnUpdate", function()
                self:SetHandler("OnUpdate", nil, "HeightChanged")
                ZO_ScrollList_Commit(self)
            end, "HeightChanged")
        else
            ZO_ScrollList_Commit(self)
        end
    end

    function ZO_ScrollList_AddCommitOnHeightChange(self)
        self:SetHandler("OnRectHeightChanged", OnRectHeightChanged)
    end
end

local function UpdateModeFromHeight(self, height)
    if self.mode == SCROLL_LIST_UNIFORM then
        if self.uniformControlHeight == NO_HEIGHT_SET then
            self.uniformControlHeight = height
        elseif height ~= self.uniformControlHeight then
            self.uniformControlHeight = nil
            self.mode = SCROLL_LIST_NON_UNIFORM
            ZO_ScrollList_Commit(self)
        end
    end
end

--Adds a new control type for the list to handle. It must maintain a consistent size.
--@typeId - A unique identifier to give to CreateDataEntry when you want to add an element of this type.
--@templateName - The name of the virtual control template that will be used to hold this data
--@height - The control height
--@setupCallback - The function that will be called when a control of this type becomes visible. Signature: setupCallback(control, data)
--@dataTypeSelectSound - An optional sound to play when a row of this data type is selected.
--@resetControlCallback - An optional callback when the datatype control gets reset.
function ZO_ScrollList_AddDataType(self, typeId, templateName, height, setupCallback, hideCallback, dataTypeSelectSound, resetControlCallback)
    if internalassert(not self.dataTypes[typeId], "Data type already registered to scroll list") then
        local factoryFunction = function(objectPool) return ZO_ObjectPool_CreateNamedControl(string.format("%s%dRow", self:GetName(), typeId), templateName, objectPool, self.contents) end
        local pool = ZO_ObjectPool:New(factoryFunction, resetControlCallback or ZO_ObjectPool_DefaultResetControl)
        self.dataTypes[typeId] = 
        {
            height = height,
            setupCallback = setupCallback,
            hideCallback = hideCallback,
            pool = pool,
            selectSound = dataTypeSelectSound,
            selectable = true,
        }
        
        --automatically choose the scrolling logic based on if the controls are all the same height or not
        UpdateModeFromHeight(self, height)
    end
end

-- Scroll List Construction Operations --

local function GetLineBreakPositions(layoutInfo, currentX, currentY, lineBreakAmount, indentX)
    indentX = indentX or 0
    currentX = layoutInfo.startPos + indentX * layoutInfo.direction
    currentY = currentY + lineBreakAmount + layoutInfo.lineBreakModifier
    layoutInfo.lineBreakModifier = 0

    return currentX, currentY
end

-- ZO_ScrollListOperation --

ZO_ScrollListOperation = ZO_Object:Subclass()

function ZO_ScrollListOperation:New()
    local operation = ZO_Object.New(self)
    operation:Initialize()
    return operation
end

function ZO_ScrollListOperation:Initialize()
    self.selectable = false
end

function ZO_ScrollListOperation:IsDataVisible(data)
    return true -- Can be overridden in derived classes
end

function ZO_ScrollListOperation:GetControlWidth()
    return nil  -- Can be overridden in derived classes
end

function ZO_ScrollListOperation:GetControlHeight()
    return nil  -- Can be overridden in derived classes
end

function ZO_ScrollListOperation:GetHeaderTextWidth(data, headerText)
    return 0 -- Can be overridden in derived classes
end

function ZO_ScrollListOperation:GetPositionsAndAdvance(layoutInfo, currentX, currentY, data)
    assert(false) -- Override in derived classes
end

function ZO_ScrollListOperation:AddToScrollContents(contents, control, offset)
    assert(false) -- Override in derived classes
end

-- ZO_ScrollList_AdvanceCursor_Operation --

ZO_ScrollList_AdvanceCursor_Operation = ZO_ScrollListOperation:Subclass()

function ZO_ScrollList_AdvanceCursor_Operation:New()
    return ZO_ScrollListOperation.New(self)
end

function ZO_ScrollList_AdvanceCursor_Operation:GetPositionsAndAdvance(layoutInfo, currentX, currentY, data)
    local instanceData = data.data
    data.top = currentY
    data.bottom = currentY + instanceData.moveY
    data.left = currentX
    data.right = currentX + instanceData.moveX * layoutInfo.direction

    currentX = data.right
    currentY = currentY + instanceData.moveY

    return currentX, currentY
end

function ZO_ScrollList_AdvanceCursor_Operation:AddToScrollContents(contents, control, offset)
    assert(false) -- Cannot add this operation to contents
end

-- ZO_ScrollList_LineBreak_Operation --

ZO_ScrollList_LineBreak_Operation = ZO_ScrollListOperation:Subclass()

function ZO_ScrollList_LineBreak_Operation:New()
    return ZO_ScrollListOperation.New(self)
end

function ZO_ScrollList_LineBreak_Operation:GetPositionsAndAdvance(layoutInfo, currentX, currentY, data)
    local instanceData = data.data
    data.top = currentY
    data.bottom = currentY + instanceData.lineBreakAmount + layoutInfo.lineBreakModifier
    if layoutInfo.startPos < layoutInfo.endPos then
        data.left = layoutInfo.startPos
        data.right = layoutInfo.endPos
    else
        data.left = layoutInfo.endPos
        data.right = layoutInfo.startPos
    end

    local indentX = instanceData.indentX or 0
    currentX, currentY = GetLineBreakPositions(layoutInfo, currentX, currentY, instanceData.lineBreakAmount, indentX)

    return currentX, currentY
end

function ZO_ScrollList_LineBreak_Operation:AddToScrollContents(contents, control, offset)
    assert(false) -- Cannot add a line break to contents
end

-- ZO_ScrollList_AddControl_Operation --

ZO_ScrollList_AddControl_Operation = ZO_ScrollListOperation:Subclass()

function ZO_ScrollList_AddControl_Operation:New()
    return ZO_ScrollListOperation.New(self)
end

function ZO_ScrollList_AddControl_Operation:Initialize()
    ZO_ScrollListOperation.Initialize(self)

    -- Defined set of actions this operation can use
    self.controlWidth = 0
    self.controlHeight = 0
    self.spacingX = 0
    self.spacingY = 0

    self.selectable = true
    self.templateName = nil
    self.pool = nil

    self.showCallback = nil
    self.hideCallback = nil
    self.onSelectSound = nil
end

function ZO_ScrollList_AddControl_Operation:SetSpacingValues(spacingX, spacingY)
    self.spacingX = spacingX
    self.spacingY = spacingY
end

-- A controlWidth of nil will cause controls to be added Anchor TOPLEFT Anchor TOPRIGHT to fill the horizontal space of the parent control
function ZO_ScrollList_AddControl_Operation:SetControlTemplate(templateName, parentControl, operationId, controlWidth, controlHeight, resetControlCallback)
    if self.templateName then
        return
    end

    self.controlWidth = controlWidth
    self.controlHeight = controlHeight
    self.templateName = templateName
    local factoryFunction = function(objectPool)
        local controlName = string.format("%s%dControl", parentControl:GetName(), operationId)
        return ZO_ObjectPool_CreateNamedControl(controlName, templateName, objectPool, parentControl)
    end
    self.pool = ZO_ObjectPool:New(factoryFunction, resetControlCallback or ZO_ObjectPool_DefaultResetControl)
end

function ZO_ScrollList_AddControl_Operation:SetSelectable(isSelectable)
    self.selectable = isSelectable
end

function ZO_ScrollList_AddControl_Operation:SetIndentAmount(indentX)
    self.indentX = indentX
end

function ZO_ScrollList_AddControl_Operation:SetOnSelectedSound(onSelectSound)
    self.onSelectSound = onSelectSound
end

function ZO_ScrollList_AddControl_Operation:IsDataVisible(data)
    if self.visibilityFunction then
        return self.visibilityFunction(data)
    end
    return true
end

function ZO_ScrollList_AddControl_Operation:GetHeaderTextWidth(headerText)
    local headerStringWidth = 0
    if self.considerHeaderWidth and self.categoryHeader then
        local controlPool = self.pool
        if controlPool then
            local control, key = controlPool:AcquireObject()
            local labelControl = control
            if not labelControl.SetText then
                if type(labelControl.GetTextLabel) == "function" then
                    labelControl = labelControl:GetTextLabel()
                else
                    labelControl = labelControl:GetNamedChild("Text")
                end
            end
            if labelControl and labelControl.SetText then
                labelControl:SetText(headerText)
                headerStringWidth = labelControl:GetTextWidth()
            end
            controlPool:ReleaseObject(control)
        end
    end
    return headerStringWidth
end

function ZO_ScrollList_AddControl_Operation:SetScrollUpdateCallbacks(setupCallback, hideCallback)
    self.setupCallback = setupCallback
    self.hideCallback = hideCallback
end

function ZO_ScrollList_AddControl_Operation:GetPositionsAndAdvance(layoutInfo, currentX, currentY, dataEntry)
    local instanceData = dataEntry.data
    local controlWidth = self:GetControlWidth(instanceData, layoutInfo)
    local controlHeight = self:GetControlHeight(instanceData)

    local controlEndPos = currentX * layoutInfo.direction + controlWidth
    local lineBreakAfterControl = false
    if controlEndPos > layoutInfo.endPos then
        currentX, currentY = GetLineBreakPositions(layoutInfo, currentX, currentY, self.spacingY, self.indentX)
    elseif zo_floatsAreEqual(controlEndPos, layoutInfo.endPos) then
        lineBreakAfterControl = true
    end

    -- Calculate left and right based on the direction we are told to advance
    -- Since we want Left to always be less than Right, and having Right_To_Left
    -- build direction will cause Left to be greater than Right
    -- we need to compensate for that fact in this case, but keep the calculation the same
    -- when we are in the direction of Left_To_Right
    local halfControlWidth = controlWidth / 2 
    dataEntry.left = currentX - halfControlWidth + halfControlWidth * layoutInfo.direction
    dataEntry.right = currentX + halfControlWidth + halfControlWidth * layoutInfo.direction
    dataEntry.top = currentY
    dataEntry.bottom = currentY + controlHeight

    currentX = currentX + (controlWidth + self.spacingX) * layoutInfo.direction

    layoutInfo.lineBreakModifier = zo_max(layoutInfo.lineBreakModifier, controlHeight)

    if lineBreakAfterControl then
        currentX, currentY = GetLineBreakPositions(layoutInfo, currentX, currentY, self.spacingY, self.indentX)
    end

    return currentX, currentY
end

function ZO_ScrollList_AddControl_Operation:AddToScrollContents(contents, control, currentX, currentY, offset)
    control:ClearAnchors()

    local xOffset = currentX
    local yOffset = currentY - offset
    if self.controlWidth then
        control:SetAnchor(TOPLEFT, contents, TOPLEFT, xOffset, yOffset)
    else
        control:SetAnchor(TOPLEFT, contents, TOPLEFT, xOffset, yOffset)
        control:SetAnchor(TOPRIGHT, contents, TOPRIGHT, xOffset, yOffset)
    end
end

function ZO_ScrollList_AddControl_Operation:GetControlWidth(instanceData, layoutInfo)
    if self.controlWidth then
        if type(self.controlWidth) == "function" then
            return self.controlWidth(instanceData)
        else
            return self.controlWidth
        end
    else
        if layoutInfo then
            return zo_abs(layoutInfo.endPos - layoutInfo.startPos)
        else
            -- Nil width (i.e.: fill) requires derivitive layoutInfo to calculate.
            -- If we're not calling this from a place to knows that information,
            -- just return nil to denote that the size is "fill" but we can't calculate it in this context
            return nil
        end
    end
end

function ZO_ScrollList_AddControl_Operation:GetControlHeight(instanceData)
    if type(self.controlHeight) == "function" then
        return self.controlHeight(instanceData)
    else
        return self.controlHeight
    end
end

-- ZO_ScrollList_AddControl_Centered_Operation --

ZO_ScrollList_AddControl_Centered_Operation = ZO_ScrollList_AddControl_Operation:Subclass()

function ZO_ScrollList_AddControl_Centered_Operation:New()
    return ZO_ScrollList_AddControl_Operation.New(self)
end

function ZO_ScrollList_AddControl_Centered_Operation:AddToScrollContents(contents, control, currentX, currentY, offset)
    assert(self.controlWidth) -- Nil width not supported for centered operations

    control:ClearAnchors()

    local xOffset = currentX
    local yOffset = currentY - offset
    if self.controlWidth then
        local instanceData = ZO_ScrollList_GetData(control)
        control:SetAnchor(CENTER, contents, TOPLEFT, xOffset + self:GetControlWidth(instanceData) / 2, yOffset + self:GetControlHeight(instanceData) / 2)
    else
        control:SetAnchor(TOPLEFT, contents, TOPLEFT, xOffset, yOffset)
        control:SetAnchor(TOPRIGHT, contents, TOPRIGHT, xOffset, yOffset)
    end
end

local GetDataTypeInfo
do
    local advanceCursorOperation = ZO_ScrollList_AdvanceCursor_Operation:New()
    local lineBreakOperation = ZO_ScrollList_LineBreak_Operation:New()

    function GetDataTypeInfo(self, typeId)
        if typeId == ZO_SCROLL_LIST_OPERATION_ADVANCE_CURSOR then
            return advanceCursorOperation
        elseif typeId == ZO_SCROLL_LIST_OPERATION_LINE_BREAK then
            return lineBreakOperation
        end

        return self.dataTypes[typeId]
    end
end

function ZO_ScrollList_SetBuildDirection(self, buildDirection)
    self.buildDirection = buildDirection
end

-- If items at the end of the scroll are not selectable, max out the scroll in that direction.
function ZO_ScrollList_SetScrollToExtent(self, scrollToExtent)
    self.scrollToExtent = scrollToExtent
end

-- A controlWidth of nil will cause controls to be added Anchor TOPLEFT Anchor TOPRIGHT to fill the horizontal space of the parent control
function ZO_ScrollList_AddControlOperation(self, operationId, templateName, controlWidth, controlHeight, resetControlCallback, showCallback, hideCallback, spacingX, spacingY, indentX, selectable, centerEntries)
    if not self.dataTypes[operationId] then
        local operation = centerEntries and ZO_ScrollList_AddControl_Centered_Operation:New() or ZO_ScrollList_AddControl_Operation:New()
        operation:SetSpacingValues(spacingX, spacingY)
        operation:SetControlTemplate(templateName, self.contents, operationId, controlWidth, controlHeight, resetControlCallback)
        operation:SetScrollUpdateCallbacks(showCallback, hideCallback)
        operation:SetSelectable(selectable)
        operation:SetIndentAmount(indentX)

        self.dataTypes[operationId] = operation

        self.mode = SCROLL_LIST_OPERATIONS
    end
end

function ZO_ScrollList_GetDataTypeTable(self, typeId)
    return self.dataTypes[typeId]
end

function ZO_ScrollList_UpdateDataTypeHeight(self, typeId, newHeight)
    local dataTable = ZO_ScrollList_GetDataTypeTable(self, typeId)
    if dataTable and dataTable.height ~= newHeight then
        dataTable.height = newHeight
        UpdateModeFromHeight(self, newHeight)
    end
end

function ZO_ScrollList_SetTypeSelectable(self, typeId, selectable)
    self.dataTypes[typeId].selectable = selectable
end

function ZO_ScrollList_SetTypeCategoryHeader(self, typeId, isHeader)
    self.dataTypes[typeId].categoryHeader = isHeader
end

function ZO_ScrollList_SetConsiderHeaderWidth(self, typeId, considerHeaderWidth)
    self.dataTypes[typeId].considerHeaderWidth = considerHeaderWidth
end

function ZO_ScrollList_SetEqualityFunction(self, typeId, equalityFunction)
    self.dataTypes[typeId].equalityFunction = equalityFunction
end

function ZO_ScrollList_SetVisibilityFunction(self, typeId, visibilityFunction)
    self.dataTypes[typeId].visibilityFunction = visibilityFunction
end

function ZO_ScrollList_SetDeselectOnReselect(self, deselectOnReselect)
    self.deselectOnReselect = deselectOnReselect
end

function ZO_ScrollList_SetAutoSelect(self, autoSelect)
    self.autoSelect = autoSelect
end

function ZO_ScrollList_SetScrollBarVisibilityCallback(self, callback)
    self.ScrollBarVisibilityCallback = callback
    --ScrollBarHiddenCallback is deprecated. Included here for addon backwards compatibility
     self.ScrollBarHiddenCallback = callback
end

function ZO_ScrollList_AddCategory(self, categoryId, parentId)
    if self.categories[categoryId] then
        return
    end

    --if a parent id is given and it doesn't exist, give up
    local parent = nil
    if parentId then
        parent = self.categories[parentId]
        if not parent then
            return
        end
    end

    local category = {id = categoryId, parent = parent, children = {}, hidden = false}
    self.categories[categoryId] = category
    if parent then
        table.insert(parent.children, category)
    end
end

function ZO_ScrollList_Clear(self)
    ZO_ClearNumericallyIndexedTable(self.data)
    ZO_ClearNumericallyIndexedTable(self.visibleData)
    self.categories = {}
    if AreSelectionsEnabled(self) then
        ZO_ScrollList_SelectData(self, NO_SELECTED_DATA, NO_DATA_CONTROL, RESELECTING_DURING_REBUILD, ANIMATE_INSTANTLY)
        self.lastSelectedDataIndex = nil
    end
end

function ZO_ScrollList_GetCategoryHidden(self, categoryId)
    local category = self.categories[categoryId]
    if category then
        return category.hidden
    end
end

--Creates a data entry for use in the scroll list. Add it to the data list then commit it.
function ZO_ScrollList_CreateDataEntry(typeId, data, categoryId)
    local entry =
    {
        typeId = typeId,
        categoryId = categoryId,
        data = data,
    }
    data.dataEntry = entry
    return entry
end

function ZO_ScrollList_AddOperation(self, operationId, data)
    local operation =
    {
        typeId = operationId,
        data = data
    }

    if data then
        data.dataEntry = operation -- Used in the comparison function
    end
    local scrollData = ZO_ScrollList_GetDataList(self)
    table.insert(scrollData, operation)
end

function ZO_ScrollList_GetDataEntryData(entry)
    return entry.data
end

function ZO_ScrollList_GetData(control)
    if control.dataEntry then
        return control.dataEntry.data
    end
end

function ZO_ScrollList_GetDataList(self)
    return self.data
end

function ZO_ScrollList_HasVisibleData(self)
    return #self.visibleData > 0
end

function ZO_ScrollList_GetSelectedDataIndex(self)
    if AreSelectionsEnabled(self) then
        return self.selectedDataIndex
    end

    return nil
end

function ZO_ScrollList_GetSelectedData(self)
    if AreSelectionsEnabled(self) then
        return self.selectedData
    end

    return nil
end

function ZO_ScrollList_GetSelectedControl(self)
    local data = ZO_ScrollList_GetSelectedData(self)
    return ZO_ScrollList_GetDataControl(self, data)
end

--Allows you to prevent the list from scrolling
function ZO_ScrollList_SetLockScrolling(self, lock)
    self.lock = lock
end

function ZO_ScrollList_GetMouseOverControl(self)
    for i = 0, #self.activeControls do
        local control = self.activeControls[i]
        if MouseIsOver(control) then
            return control
        end
    end
end

local function PlayAnimationOnControl(control, controlTemplate, animationFieldName, animateInstantly, overrideEndAlpha)
    if controlTemplate then
        if not control[animationFieldName] then
            local highlight = CreateControlFromVirtual("$(parent)Scroll", control, controlTemplate, animationFieldName)
            control[animationFieldName] = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
            if overrideEndAlpha then
                control[animationFieldName]:GetAnimation(1):SetAlphaValues(0, overrideEndAlpha)
            end
        end

        if animateInstantly then
            control[animationFieldName]:PlayInstantlyToEnd()
        else
            control[animationFieldName]:PlayForward()
        end
    end
end

local function RemoveAnimationOnControl(control, animationFieldName, animateInstantly)
    if control[animationFieldName] then
        if animateInstantly then
            control[animationFieldName]:PlayInstantlyToStart()
        else
            control[animationFieldName]:PlayBackward()
        end
    end
end

local function HighlightControl(self, control)
    local highlightTemplate, animationFieldName
    if type(self.highlightTemplateOrFunction) == "function" then
        highlightTemplate, animationFieldName = self.highlightTemplateOrFunction(control)
    else
        highlightTemplate = self.highlightTemplateOrFunction
    end
    control.highlightAnimationFieldName = animationFieldName or "HighlightAnimation"
    PlayAnimationOnControl(control, highlightTemplate, control.highlightAnimationFieldName, DONT_ANIMATE_INSTANTLY, self.overrideHighlightEndAlpha)

    self.highlightedControl = control

    if self.highlightCallback then
        self.highlightCallback(control, true)
    end
end

local function UnhighlightControl(self, control) 
    RemoveAnimationOnControl(control, control.highlightAnimationFieldName)
    control.highlightAnimationFieldName = nil

    self.highlightedControl = nil

    if self.highlightCallback then
        self.highlightCallback(control, false)
    end
end

local function SelectControl(self, control, animateInstantly)
    PlayAnimationOnControl(control, self.selectionTemplate, "SelectionAnimation", animateInstantly)

    self.selectedControl = control
end

local function UnselectControl(self, control, animateInstantly)
    RemoveAnimationOnControl(control, "SelectionAnimation", animateInstantly)

    self.selectedControl = nil
end

--Allows you to lock the highlight in place. The highlight will automatically unlock if the list is recommitted.
function ZO_ScrollList_SetLockHighlight(self, lock)
    if not self.highlightTemplateOrFunction or (self.highlightLocked == lock) then
        return
    end

    self.highlightLocked = lock

    if lock then
        self.pendingHighlightControl = self.highlightedControl
    else
        if self.highlightedControl then
            UnhighlightControl(self, self.highlightedControl)
        end
        if self.pendingHighlightControl then
            HighlightControl(self, self.pendingHighlightControl)
        end
    end
end

--Reinitializes the highlight (used mostly when a mouse enter would have been missed)
local function RefreshHighlight(self)
    if not self.highlightTemplateOrFunction then
        return
    end

    self.highlightLocked = false
    if self.highlightedControl then
        UnhighlightControl(self, self.highlightedControl)
    end

    --find the control to highlight if any
    for i = 0, #self.activeControls do
        local control = self.activeControls[i]
        if MouseIsOver(control) then
            HighlightControl(self, control)
            return
        end
    end
end

function ZO_ScrollList_MouseEnter(self, control)
    if not self.highlightTemplateOrFunction then
        return
    end

    --allows us to place the highlight correctly when we unlock
    if self.highlightLocked then
        self.pendingHighlightControl = control
        return
    end

    HighlightControl(self, control)
end

function ZO_ScrollList_MouseExit(self, control)
    if not self.highlightTemplateOrFunction then
        return
    end

    if self.highlightLocked then
        self.pendingHighlightControl = nil
        return
    end

    UnhighlightControl(self, control)
end

function ZO_ScrollList_MouseClick(self, control)
    if AreSelectionsEnabled(self) then
        if control == self.selectedControl then
            if self.deselectOnReselect then
                ZO_ScrollList_SelectData(self, nil)
            end
        else
            local data = ZO_ScrollList_GetData(control)
            local typeId = control.dataEntry.typeId
            local selectSound = GetDataTypeInfo(self, typeId).selectSound

            ZO_ScrollList_SelectData(self, data, control)

            if selectSound then
                PlaySound(selectSound)
            end
        end
    end
end

-- highlightTemplateOrFunction can be the name of a template control, or it can be a function that returns the name of a control.
-- If a function, it can optionally have an additional return for an animation field name. Highlight templates and
-- animation field names are one-to-one, so a unique animation field name is required if and only if the scroll list
-- needs to display multiple different highlights.
function ZO_ScrollList_EnableHighlight(self, highlightTemplateOrFunction, highlightCallback, overrideEndAlpha)
    if not self.highlightTemplateOrFunction then
        self.highlightTemplateOrFunction = highlightTemplateOrFunction

        self.highlightLocked = false
        self.pendingHighlightControl = nil
        self.highlightCallback = highlightCallback
        self.overrideHighlightEndAlpha = overrideEndAlpha

        RefreshHighlight(self)
    end
end

function ZO_ScrollList_SetScrollbarEthereal(self, isEthereal)
    self.isScrollBarEthereal = isEthereal
end

function ZO_ScrollList_SetHideScrollbarOnDisable(self, hideOnDisable)
    -- Not updating state here, you should call this when the list is being created.
    -- The bar will update state properly when the list has data committed.
    self.hideScrollBarOnDisabled = hideOnDisable
end

function ZO_ScrollList_SetUseScrollbar(self, useScrollbar)
    -- Not updating state here, you should call this when the list is being created.
    -- The bar will update state properly when the list has data committed.
    self.useScrollbar = useScrollbar
end

function ZO_ScrollList_SetUseFadeGradient(self, useFadeGradient)
    self.useFadeGradient = useFadeGradient
end

function ZO_ScrollList_IgnoreMouseDownEditFocusLoss(self)
    ZO_PreHookHandler(self.scrollbar, "OnMouseDown", IgnoreMouseDownEditFocusLoss)
    ZO_PreHookHandler(self.upButton, "OnMouseDown", IgnoreMouseDownEditFocusLoss)
    ZO_PreHookHandler(self.downButton, "OnMouseDown", IgnoreMouseDownEditFocusLoss)
end

function ZO_ScrollList_EnableSelection(self, selectionTemplate, selectionCallback)
    if not self.selectionTemplate then
        self.selectionTemplate = selectionTemplate
        self.selectionCallback = selectionCallback
    end
end

--Determines if one piece of selected data is the "same" as the other. Used mainly to
--keep an item selected even when the data for the list is updated if they share some
--property determined by the equality function. For example, if you have an item with
--id=1 and state=up and replace it with id=1 and state=down, the selection will be maintained
--if the equality function only compares ids.  
local function AreDataEqualSelections(self, data1, data2)
    if data1 == data2 then
        return true
    end

    if data1 == nil or data2 == nil then
        return false
    end

    local dataEntry1 = data1.dataEntry
    local dataEntry2 = data2.dataEntry

    if dataEntry1 == nil or dataEntry2 == nil then
        return false
    end

    if dataEntry1.typeId == dataEntry2.typeId then
        local dataTypeInfo = GetDataTypeInfo(self, dataEntry1.typeId)
        local equalityFunction = dataTypeInfo.equalityFunction
        if equalityFunction then
            return equalityFunction(data1, data2)
        end
    end

    return false
end

function ZO_ScrollList_IsDataSelected(self, data)
    if AreSelectionsEnabled(self) and AreDataEqualSelections(self, self.selectedData, data) then
        return true
    end
    return false
end

function ZO_ScrollList_GetDataControl(self, data)
    if data then
        local numActive = #self.activeControls
        for i = 1, numActive do
            local currentControl = self.activeControls[i]
            local currentDataEntry = currentControl.dataEntry
            if AreDataEqualSelections(self, currentDataEntry.data, data) then
                return currentControl
            end
        end
    end
    return nil
end

function ZO_ScrollList_GetDataIndex(self, data)
    if data then
        for i, entryData in ipairs(self.data) do
            if entryData == data then
                return i
            end
        end
    end
    return nil
end

function ZO_ScrollList_FindDataIndexByDataEntry(self, dataEntry, optionalTypeId)
    if dataEntry then
        for i, data in ipairs(self.data) do
            if data.data == dataEntry then
                return i
            end

            if not optionalTypeId or data.typeId == optionalTypeId then
                local dataTypeInfo = GetDataTypeInfo(self, data.typeId)
                local equalityFunction = dataTypeInfo.equalityFunction
                if equalityFunction and equalityFunction(data.data, dataEntry) then
                    return i
                end
            end
        end
    end
    return nil
end

function ZO_ScrollList_FindDataByQuery(self, query, optionalTypeId)
    if query then
        for i, data in ipairs(self.data) do
            if not optionalTypeId or data.typeId == optionalTypeId then
                if query(data.data) then
                    return data, i
                end
            end
        end
    end
    return nil
end

function ZO_ScrollList_SelectData(self, data, control, reselectingDuringRebuild, animateInstantly)
    if not AreSelectionsEnabled(self) then
        return
    end

    if reselectingDuringRebuild == nil then
        reselectingDuringRebuild = false
    end

    -- Update the current selection to the new data
    -- If it's already the selected entry then we still need to do some cleanup if this is a rebuild
    -- Specifically we need to make sure the selected index is still valid and correct
    local notAlreadySelected = self.selectedData ~= data
    if notAlreadySelected or reselectingDuringRebuild then
        if animateInstantly == nil then
            animateInstantly = false
        end

        -- Find the data index for the data in the scroll list
        local dataIndex
        if data ~= nil then
            for i = 1, #self.data do
                if AreDataEqualSelections(self, self.data[i].data, data) then
                    dataIndex = i
                    break
                end
            end

            --this data we tried to select isn't in the scroll list at all, just abort
            if dataIndex == nil then
                return
            end
        end

        -- if this is a new selection, unselect the old control and save off any necessary info
        local previouslySelectedData = nil
        if notAlreadySelected then
            previouslySelectedData = self.selectedData
            if self.selectedData then
                self.selectedData = nil
                self.selectedDataIndex = nil
                if self.selectedControl then
                    UnselectControl(self, self.selectedControl, animateInstantly)
                end
            end
        end

        -- if we have a selected data then update the selected control and any necessary info
        if data ~= nil then
            self.selectedDataIndex = dataIndex
            self.lastSelectedDataIndex = dataIndex
            self.selectedData = data

            -- don't need to select the control if it's already the selected data
            if notAlreadySelected then
                if not control then
                    control = ZO_ScrollList_GetDataControl(self, data)
                end

                if control then
                    SelectControl(self, control, animateInstantly)
                end
            end
        end

        if self.selectionCallback and notAlreadySelected then
            self.selectionCallback(previouslySelectedData, self.selectedData, reselectingDuringRebuild)
        end
    end
end

local function OnContentsUpdate(self)
    local _, windowHeight = self:GetDimensions()

    if windowHeight > 0 then
        self:SetHandler("OnUpdate", nil)
        ZO_ScrollList_SetHeight(self, windowHeight)
        ZO_ScrollList_Commit(self:GetParent())
    end
end

local function FreeActiveScrollListControl(self, i)
    local currentControl = self.activeControls[i]
    local currentDataEntry = currentControl.dataEntry
    local dataType = GetDataTypeInfo(self, currentDataEntry.typeId)

    if self.highlightTemplateOrFunction then
        if currentControl == self.highlightedControl then
            UnhighlightControl(self, currentControl)
            if self.highlightLocked then
                self.highlightLocked = false
            end
        else
            RemoveAnimationOnControl(currentControl, "HighlightAnimation", ANIMATE_INSTANTLY)
        end
    end

    if currentControl == self.pendingHighlightControl then
        self.pendingHighlightControl = nil
    end

    if AreSelectionsEnabled(self) then
        if currentControl == self.selectedControl then
            UnselectControl(self, currentControl, ANIMATE_INSTANTLY)
        else
            RemoveAnimationOnControl(currentControl, "SelectionAnimation", ANIMATE_INSTANTLY)
        end
    end

    local controlPool = dataType.pool
    local hideCallback = dataType.hideCallback

    if hideCallback then
        hideCallback(currentControl, currentControl.dataEntry.data)
    end

    controlPool:ReleaseObject(currentControl.key)
    currentControl.key = nil
    currentControl.dataEntry = nil
    currentDataEntry.control = nil
    currentControl.index = nil
    self.activeControls[i] = self.activeControls[#self.activeControls]
    self.activeControls[#self.activeControls] = nil
end

local function ResizeScrollBar(self, scrollableDistance)
    local shouldHideScrollbar = self.isScrollBarEthereal
    local scrollBarHeight = self.scrollbar:GetHeight()
    local scrollListHeight = ZO_ScrollList_GetHeight(self)

    if scrollableDistance > 0 then
        if self.offset > scrollableDistance then
            self.offset = scrollableDistance
        end
        self.scrollbar:SetThumbTextureHeight(scrollBarHeight * scrollListHeight / (scrollableDistance + scrollListHeight))
        self.scrollbar:SetMinMax(0, scrollableDistance)
        self.scrollbar:SetEnabled(true)
    else
        self.offset = 0
        self.scrollbar:SetThumbTextureHeight(scrollBarHeight)
        self.scrollbar:SetMinMax(0, 0)
        self.scrollbar:SetEnabled(false)
        shouldHideScrollbar = shouldHideScrollbar or self.hideScrollBarOnDisabled
    end

    shouldHideScrollbar = shouldHideScrollbar or not self.useScrollbar

    if self.ScrollBarVisibilityCallback then
        self.ScrollBarVisibilityCallback(self, shouldHideScrollbar)
    else
        if self.scrollbar:IsControlHidden() ~= shouldHideScrollbar then
            self.scrollbar:SetHidden(shouldHideScrollbar)
        end
    end
end

local function CheckRunHandler(self, handlerName)
    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
    if mouseOverControl and not mouseOverControl:IsHidden() and mouseOverControl:IsChildOf(self) then
        local handler = mouseOverControl:GetHandler(handlerName)
        if handler then
            handler(mouseOverControl)
        end
    end
end

local function CanSelectData(self, index)
    local dataEntry = self.data[index]
    if dataEntry == nil then
        return false
    end

    local dataTypeInfo = GetDataTypeInfo(self, dataEntry.typeId)
    return dataTypeInfo.selectable
end

local function IsCategoryHeader(self, index)
    local dataEntry = self.data[index]
    local dataTypeInfo = GetDataTypeInfo(self, dataEntry.typeId)
    return dataTypeInfo.categoryHeader
end

local function GetClampedSelectedIndex(self)
    local selectedIndex = self.selectedDataIndex or self.lastSelectedDataIndex
    if selectedIndex then
        return zo_clamp(selectedIndex, 1, #self.data)
    end
    return nil
end

local function AutoSelect(self, animateInstantly, scrollIntoView)
    if #self.data > 0 then
        local selectedIndex = GetClampedSelectedIndex(self)
        if selectedIndex then
            for i = selectedIndex, 1, -1 do
                if CanSelectData(self, i) then
                    if scrollIntoView then
                        local NO_CALLBACK = nil
                        ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[i].data, NO_CALLBACK, animateInstantly)
                    else
                        ZO_ScrollList_SelectData(self, self.data[i].data, NO_DATA_CONTROL, NOT_RESELECTING_DURING_REBUILD, animateInstantly)
                    end
                    return
                end
            end
        end

        if ZO_ScrollList_TrySelectFirstData(self) then
            return
        end
    end

    ZO_ScrollList_SelectData(self, NO_SELECTED_DATA, NO_DATA_CONTROL, NOT_RESELECTING_DURING_REBUILD, animateInstantly)
end

local function GetDataControlPositions(self, dataEntry, dataIndex)
    local controlTop
    local controlBottom
    if self.mode == SCROLL_LIST_UNIFORM then
        controlTop = (dataIndex - 1) * self.uniformControlHeight
        controlBottom = controlTop + self.uniformControlHeight
    else
        controlTop = dataEntry.top
        controlBottom = dataEntry.bottom
    end

    return controlTop, controlBottom
end

local function GetDataControlDimensions(self, dataEntry)
    local controlWidth
    local controlHeight
    local dataTypeInfo = ZO_ScrollList_GetDataTypeTable(self, dataEntry.typeId)
    if self.mode == SCROLL_LIST_OPERATIONS then
        local instanceData = dataEntry.data
        controlWidth = dataTypeInfo:GetControlWidth(instanceData)
        controlHeight = dataTypeInfo:GetControlHeight(instanceData)
    else
        controlHeight = dataTypeInfo.height
    end

    return controlWidth, controlHeight
end

-- If an animation is in progress and we call to change the scrollBar's value, 
-- we must account for the distance left to travel in our calculations
-- of the new scrollBar value so we do not over/under shoot the target
local function CalculateScrollAnimationOffset(self)
    local animationOffset = 0

    if self.animationTarget then
       animationOffset = self.animationTarget - self.scrollbar:GetValue()
    end

    return animationOffset
end

function ZO_ScrollList_ScrollDataIntoView(self, dataIndex, onScrollCompleteCallback, animateInstantly)
    local data = self.data[dataIndex]
    local scrollTop = self.scrollbar:GetValue()
    local scrollBottom = self.scrollbar:GetValue() + ZO_ScrollList_GetHeight(self)
    local controlTop, controlBottom = GetDataControlPositions(self, data, dataIndex)

    local scrollAnimationOffset = CalculateScrollAnimationOffset(self)
    local calculatedControlTop = controlTop - self.yDistanceFromEdgeWhereSelectionCausesScroll - scrollAnimationOffset
    local calculatedControlBottom = controlBottom + self.yDistanceFromEdgeWhereSelectionCausesScroll - scrollAnimationOffset

    if calculatedControlTop < scrollTop then
        ZO_ScrollList_ScrollRelative(self, calculatedControlTop - scrollTop, onScrollCompleteCallback, animateInstantly)
    elseif calculatedControlBottom > scrollBottom then
        ZO_ScrollList_ScrollRelative(self, calculatedControlBottom - scrollBottom, onScrollCompleteCallback, animateInstantly)
    elseif onScrollCompleteCallback then
        onScrollCompleteCallback(true)
    end
end

function ZO_ScrollList_GetScrollValue(self)
    return self.scrollbar:GetValue()
end

function ZO_ScrollList_ScrollDataToCenter(self, dataIndex, onScrollCompleteCallback, animateInstantly)
    local data = self.data[dataIndex]
    local scrollCenter = self.scrollbar:GetValue() + ZO_ScrollList_GetHeight(self) / 2
    local controlTop = GetDataControlPositions(self, data, dataIndex)
    local _, controlHeight = GetDataControlDimensions(self, data)
    local controlCenter  = controlTop + controlHeight / 2
    local scrollAnimationOffset = CalculateScrollAnimationOffset(self)

    ZO_ScrollList_ScrollRelative(self, controlCenter - scrollCenter - scrollAnimationOffset, onScrollCompleteCallback, animateInstantly)
end

function ZO_ScrollList_SelectNextData(self, onScrollCompleteCallback, shouldAnimateInstantly)
    if not self.selectedDataIndex then
        return
    end
    for i = 1, #self.data do
        -- Allow Wrapping
        local newIndex = ((self.selectedDataIndex + i - 1) % #self.data) + 1
        local hasWrapped = newIndex < self.selectedDataIndex
        if CanSelectData(self, newIndex) then
            ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[newIndex].data, onScrollCompleteCallback, hasWrapped or shouldAnimateInstantly)
            return
        end
    end
end

function ZO_ScrollList_SelectPreviousData(self, onScrollCompleteCallback, shouldAnimateInstantly)
    if not self.selectedDataIndex then
        return
    end
    for i = 1, #self.data do
        -- Allow Wrapping
        local newIndex = ((self.selectedDataIndex + #self.data - i - 1) % #self.data) + 1
        local hasWrapped = newIndex > self.selectedDataIndex
        if CanSelectData(self, newIndex) then
            ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[newIndex].data, onScrollCompleteCallback, hasWrapped or shouldAnimateInstantly)
            return
        end
    end
end

-- x and y direction must use the values for directions described at the top of this file
function ZO_ScrollList_SelectNextDataInDirection(self, xDirection, yDirection)
    if not self.selectedDataIndex then
        return
    end
    local numDataEntries = #self.data

    -- Move Y Direction
    if yDirection ~= ZO_SCROLL_MOVEMENT_DIRECTION_NONE then
        local currentData = self.data[self.selectedDataIndex]
        local holdXPos = self.lastHoldXPos or 0

        local nextIndex = self.selectedDataIndex + yDirection
        local currentTopValue = currentData.top * yDirection
        local bestDistance = math.huge
        local bestIndex = nil
        while nextIndex <= numDataEntries and nextIndex > 0 do
            if CanSelectData(self, nextIndex) then
                local nextData = self.data[nextIndex]
                local nextDataTopValue = nextData.top * yDirection
                -- check and see if the next data is within the y direction we are searching, 
                -- and has an x direction greater than or equal to our current data's x
                if nextDataTopValue > currentTopValue then
                    local deltaDistance = zo_abs(nextData.left - holdXPos)
                    if deltaDistance < bestDistance then
                        bestIndex = nextIndex
                        bestDistance = deltaDistance
                    end
                end

                -- we only want to select an entry that is only one y delta away. 
                -- We must look ahead and see if the next data after current next data has an even greater y
                local lookAheadIndex = nextIndex + yDirection
                local nextSelectableData
                local noFurtherDataToExplore = false
                while not nextSelectableData do
                    -- we can't look ahead anymore, bail out
                    if lookAheadIndex > numDataEntries or lookAheadIndex < 1 then
                        break
                    end

                    if CanSelectData(self, lookAheadIndex) then
                        nextSelectableData = self.data[lookAheadIndex]
                        if currentTopValue < nextDataTopValue and nextDataTopValue < nextSelectableData.top * yDirection then
                            noFurtherDataToExplore = true
                            break
                        end
                    end
                    lookAheadIndex = lookAheadIndex + yDirection
                end

                -- we found that there is no other data to look at
                -- and we no longer need to look any further
                if noFurtherDataToExplore then
                    break
                end
            end
            nextIndex = nextIndex + yDirection
        end

        if bestIndex then
            ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[bestIndex].data)
            if self.scrollToExtent then
                if yDirection == ZO_SCROLL_MOVEMENT_DIRECTION_NEGATIVE and nextIndex == 0 and ZO_ScrollList_CanScrollUp(self) then
                    ZO_ScrollList_ScrollDataIntoView(self, 1)
                elseif yDirection == ZO_SCROLL_MOVEMENT_DIRECTION_POSITIVE and nextIndex >= numDataEntries and ZO_ScrollList_CanScrollDown(self) then
                    ZO_ScrollList_ScrollDataIntoView(self, numDataEntries)
                end
            end
        end
    end

    -- Move X Direction
    -- Since data is given in X direction order, simply pick the next selectable data
    -- in the correct layout direction in contigious order
    -- we also save this X position for use in calculating Y direction
    -- since this emulates how people already expect this form of selection to work (see text editors)
    local nextIndex = self.selectedDataIndex + xDirection
    if xDirection == ZO_SCROLL_MOVEMENT_DIRECTION_POSITIVE then
        while nextIndex <= numDataEntries do
            if CanSelectData(self, nextIndex) then
                ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[nextIndex].data)
                break
            end
            nextIndex = nextIndex + xDirection
        end
        self.lastHoldXPos = self.data[self.selectedDataIndex].left
    elseif xDirection == ZO_SCROLL_MOVEMENT_DIRECTION_NEGATIVE then
        while nextIndex > 0 do
            if CanSelectData(self, nextIndex) then
                ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[nextIndex].data)
                break
            end
            nextIndex = nextIndex + xDirection
        end
        self.lastHoldXPos = self.data[self.selectedDataIndex].left
    end
end

function ZO_ScrollList_ResetLastHoldPosition(self)
    self.lastHoldXPos = nil
end

function ZO_ScrollList_RefreshLastHoldPosition(self)
    if self.selectedDataIndex then
        self.lastHoldXPos = self.data[self.selectedDataIndex].left
    end
end

function ZO_ScrollList_TrySelectFirstData(self, onScrollCompleteCallback, shouldAnimateInstantly)
    for i = 1, #self.data do
        if CanSelectData(self, i) then
            ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[i].data, onScrollCompleteCallback, shouldAnimateInstantly)
            return true
        end
    end
    return false
end

function ZO_ScrollList_TrySelectLastData(self, onScrollCompleteCallback, shouldAnimateInstantly)
    for i = #self.data, 1, -1 do
        if CanSelectData(self, i) then
            ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[i].data, onScrollCompleteCallback, shouldAnimateInstantly)
            return true
        end
    end
    return false
end

function ZO_ScrollList_AutoSelectData(self, animateInstantly, scrollIntoView)
    AutoSelect(self, animateInstantly, scrollIntoView)
end

--When the list in inactive, you can't get selected data.  Auto select is a mechanic of lists that will reselect the last thing that was selected
-- Assuming it wasn't reset, or manually set to something else.  If another party needs to know what data would be selected if the list were active, this is how
function ZO_ScrollList_GetAutoSelectIndex(self)
    if #self.data > 0 then
        local selectedIndex = GetClampedSelectedIndex(self)
        if selectedIndex and CanSelectData(self, selectedIndex) then
            return selectedIndex
        end
    end
    return nil
end

function ZO_ScrollList_GetAutoSelectData(self)
    local recalledIndex = ZO_ScrollList_GetAutoSelectIndex(self)
    if recalledIndex then
        return self.data[recalledIndex].data
    end
    return nil
end

function ZO_ScrollList_ResetAutoSelectIndex(self)
    self.lastSelectedDataIndex = nil
end

-- This should be used before a commit/activate. It won't affect an already commited/activated list.
function ZO_ScrollList_SetAutoSelectToMatchingDataEntry(self, dataEntry, optionalTypeId)
    self.lastSelectedDataIndex = ZO_ScrollList_FindDataIndexByDataEntry(self, dataEntry, optionalTypeId)
end

-- direction: ZO_SCROLL_SELECT_CATEGORY_PREVIOUS or ZO_SCROLL_SELECT_CATEGORY_NEXT
function ZO_ScrollList_SelectFirstIndexInCategory(self, direction)
    local currentlySelectedData = ZO_ScrollList_GetSelectedData(self)
    if not currentlySelectedData then
        return
    end

    local listData = ZO_ScrollList_GetDataList(self)
    local nextDataIndex = ZO_ScrollList_GetDataIndex(self, currentlySelectedData.dataEntry) + direction

    if nextDataIndex < 1 or nextDataIndex > #listData then
        -- we are already at the end of our list
        return
    end

    -- if we are going backwards and hit a non-selectable entry, we need to keep going until we find a selectable entry so we don't just select the same value
    if direction == ZO_SCROLL_SELECT_CATEGORY_PREVIOUS then
        while not CanSelectData(self, nextDataIndex) do
            nextDataIndex = nextDataIndex + direction
            if nextDataIndex == 0 or nextDataIndex == #listData then
                -- could not find an acceptable target, we are at the selectable end of our list
                return
            end
        end
    end


    while nextDataIndex > 0 and nextDataIndex <= #listData do
        if IsCategoryHeader(self, nextDataIndex) then
            -- we found header data, select the first selectable entry under it
            local lookAheadIndex = nextDataIndex + 1
            ZO_ScrollList_SelectData(self, listData[lookAheadIndex].data)
            ZO_ScrollList_ScrollDataToCenter(self, lookAheadIndex)
            ZO_ScrollList_RefreshLastHoldPosition(self)
            return
        end

        nextDataIndex = nextDataIndex + direction
    end

    -- could not find another header data, so just pick the last selectable value we found
    ZO_ScrollList_SelectData(self, listData[nextDataIndex - direction].data)
    ZO_ScrollList_ScrollDataToCenter(self, nextDataIndex - direction)
    ZO_ScrollList_RefreshLastHoldPosition(self)
end

--Updates the scroll control with new data. Call this when you modify the data list by adding or removing entries.
function ZO_ScrollList_Commit(self)
    local windowHeight = ZO_ScrollList_GetHeight(self)
    local selectionsEnabled = AreSelectionsEnabled(self)

    --the window isn't big enough to show anything (its anchors probably haven't been processed yet), so delay the commit until that happens
    if windowHeight <= 0 then
        self.contents:SetHandler("OnUpdate", OnContentsUpdate)
        return
    end

    self.contents:SetHandler("OnUpdate", nil)

    CheckRunHandler(self, "OnMouseExit")

    ZO_ClearNumericallyIndexedTable(self.visibleData)

    local scrollableDistance = 0
    local foundSelected = false
    if self.mode == SCROLL_LIST_UNIFORM then
        for i, currentData in ipairs(self.data) do
            table.insert(self.visibleData, i)
            
            if selectionsEnabled and AreDataEqualSelections(self, currentData.data, self.selectedData) then
               foundSelected = true
               ZO_ScrollList_SelectData(self, currentData.data, NO_DATA_CONTROL, RESELECTING_DURING_REBUILD, ANIMATE_INSTANTLY)
            end
        end

        scrollableDistance = #self.data * self.uniformControlHeight - windowHeight
    elseif self.mode == SCROLL_LIST_NON_UNIFORM then
        local currentY = 0
        for i, currentData in ipairs(self.data) do
            currentData.top = currentY
            currentY = currentY + GetDataTypeInfo(self, currentData.typeId).height
            currentData.bottom = currentY
            table.insert(self.visibleData, i)

            if selectionsEnabled and AreDataEqualSelections(self, currentData.data, self.selectedData) then
                foundSelected = true
                ZO_ScrollList_SelectData(self, currentData.data, NO_DATA_CONTROL, RESELECTING_DURING_REBUILD, ANIMATE_INSTANTLY)
            end
        end
        scrollableDistance = currentY - windowHeight
    elseif self.mode == SCROLL_LIST_OPERATIONS then
        local layoutInfo = {}
        layoutInfo.lineBreakModifier = 0
        layoutInfo.direction = self.buildDirection
        if self.buildDirection == ZO_SCROLL_BUILD_DIRECTION_LEFT_TO_RIGHT then
            layoutInfo.startPos = 0
            layoutInfo.endPos = self.contents:GetWidth()
        else
            layoutInfo.startPos = self.contents:GetWidth()
            layoutInfo.endPos = 0
        end
        local currentX = layoutInfo.startPos
        local currentY = 0
        self.maxDimensionX = 0
        self.maxDimensionY = 0
        for i, currentData in ipairs(self.data) do
            local currentOperation = GetDataTypeInfo(self, currentData.typeId)
            if currentOperation:IsDataVisible(currentData.data) then
                local headerStringWidth = currentOperation:GetHeaderTextWidth(currentData.data.header)
                if headerStringWidth > self.maxDimensionX then
                    self.maxDimensionX = headerStringWidth
                end
                currentX, currentY = currentOperation:GetPositionsAndAdvance(layoutInfo, currentX, currentY, currentData)
                if currentX > self.maxDimensionX then
                    self.maxDimensionX = currentX
                end
                if currentY > self.maxDimensionY then
                    self.maxDimensionY = currentY
                end
                if currentY < currentData.bottom then
                    self.maxDimensionY = currentData.bottom
                end
                table.insert(self.visibleData, i)

                if selectionsEnabled and AreDataEqualSelections(self, currentData.data, self.selectedData) then
                    foundSelected = true
                    ZO_ScrollList_SelectData(self, currentData.data, NO_DATA_CONTROL, RESELECTING_DURING_REBUILD, ANIMATE_INSTANTLY)
                end
            end
        end

        if #self.visibleData > 0 then
            local lastVisibleDataIndex = self.visibleData[#self.visibleData]
            scrollableDistance = self.data[lastVisibleDataIndex].bottom - windowHeight
        else
            scrollableDistance = 0
        end
    end

    ResizeScrollBar(self, scrollableDistance)

    --nuke the active list since things may have left it
    local i = #self.activeControls
    while i >= 1 do
        FreeActiveScrollListControl(self, i)
        i = i - 1
    end

    if selectionsEnabled then
        if not foundSelected then
            if self.autoSelect then
                AutoSelect(self, ANIMATE_INSTANTLY)
            else
                ZO_ScrollList_SelectData(self, NO_SELECTED_DATA, NO_DATA_CONTROL, RESELECTING_DURING_REBUILD, ANIMATE_INSTANTLY)
            end
        end
    end

    ZO_ScrollList_UpdateScroll(self)

    CheckRunHandler(self, "OnMouseEnter")
end

do
    local function RefreshScrollListControl(self, control, overrideSetupCallback)
        local dataEntry = control.dataEntry
        local dataEntryData = dataEntry.data
        if overrideSetupCallback then
            overrideSetupCallback(control, dataEntryData, self)
        else
            local dataTypeInfo = GetDataTypeInfo(self, dataEntry.typeId)
            if dataTypeInfo.setupCallback then
                dataTypeInfo.setupCallback(control, dataEntryData, self)
            end
        end
    end

    --updates the layout of visible controls
    --optionalFilterData: optionally allows you to only update the control backed by a single specified data table
    --overrideSetupCallback: optionally allows you to call this function instead of the normal setup function if you only need to do a very specific update
    function ZO_ScrollList_RefreshVisible(self, optionalFilterData, overrideSetupCallback)
        if optionalFilterData then
            for _, control in ipairs(self.activeControls) do
                if AreDataEqualSelections(self, control.dataEntry.data, optionalFilterData) then
                    RefreshScrollListControl(self, control, overrideSetupCallback)
                    return
                end
            end
        else
            for _, control in ipairs(self.activeControls) do
                RefreshScrollListControl(self, control, overrideSetupCallback)
            end
        end
    end

    --updates the layout of visible controls at the specified indices
    --indices: only update the control at the specified table of indices (can also just pass a single index if desired)
    --overrideSetupCallback: optionally allows you to call this function instead of the normal setup function if you only need to do a very specific update
    function ZO_ScrollList_RefreshVisibleByIndices(self, indices, overrideSetupCallback)
        local typeOfIndices = type(indices)
        assert(typeOfIndices == "number" or typeOfIndices == "table", "indices must be either a number or an array of numbers")
        if type(indices) == "number" then
            indices = { indices }
        end

        for _, index in ipairs(indices) do
            local control = self.activeControls[index]
            if control then
                RefreshScrollListControl(self, control, overrideSetupCallback)
            end
        end
    end

    --updates the layout of visible controls at the specified data
    --filterDataList: only update the control if backed by data that matches one of the data tables in the provided list of data (should be key value lookup with data as the key)
    --overrideSetupCallback: optionally allows you to call this function instead of the normal setup function if you only need to do a very specific update
    function ZO_ScrollList_RefreshVisibleByDataList(self, filterDataList, overrideSetupCallback)
        local filterDataListCopy = ZO_ShallowNumericallyIndexedTableCopy(filterDataList)
        for _, control in ipairs(self.activeControls) do
            for i, filterData in ipairs(filterDataListCopy) do
                if AreDataEqualSelections(self, control.dataEntry.data, filterData) then
                    RefreshScrollListControl(self, control, overrideSetupCallback)
                    table.remove(filterDataListCopy, i)
                    break
                end
            end
            if #filterDataListCopy == 0 then
                return
            end
        end
    end
end

local function UpdateAfterDataVisibilityChange(self)
    if self.mode == SCROLL_LIST_UNIFORM then
        --nuke the active list since things may have left it
        local i = #self.activeControls
        while i >= 1 do
            FreeActiveScrollListControl(self, i)
            i = i - 1
        end
        
        --update scroll distance
        local windowHeight = ZO_ScrollList_GetHeight(self)
        local scrollSize = self.uniformControlHeight * #self.visibleData       
        ResizeScrollBar(self, math.max(0, scrollSize-windowHeight))        
        ZO_ScrollList_UpdateScroll(self)
    end
end

function ZO_ScrollList_HideData(self, index)
    if self.mode == SCROLL_LIST_UNIFORM then
        for i = 1, #self.visibleData do
            if self.visibleData[i] == index then
                table.remove(self.visibleData, i)            
                break
            end
        end
        
        UpdateAfterDataVisibilityChange(self)
    end
end

function ZO_ScrollList_HideCategory(self, categoryId)
    local data = self.data
    local visibleData = self.visibleData
    local categories = self.categories

    if self.mode == SCROLL_LIST_UNIFORM then
        local category = self.categories[categoryId]
        if category then
            category.hidden = true    
            local numRemoved = 0
            
            local i = 1
            while i <= #self.visibleData do
                local curCategoryId = data[visibleData[i]].categoryId
                local curCategory = categories[curCategoryId]
                local found = false
                
                --climb the hierarchy to see if this piece of data is under this category
                while curCategory do
                    curCategoryId = curCategory.id
                    if curCategoryId == categoryId then
                        table.remove(visibleData, i)
                        found = true
                        numRemoved = numRemoved + 1
                        break
                    end
                    curCategory = curCategory.parent
                end 
                
                if not found then
                    i = i + 1
                end          
            end
        
            if numRemoved > 0 then
                UpdateAfterDataVisibilityChange(self)
            end
        end
    end
end

function ZO_ScrollList_ShowData(self, index)
    if self.mode == SCROLL_LIST_UNIFORM then
        local inserted = false
        for i = 1, #self.visibleData do
            if self.visibleData[i] == index then
                return
            elseif self.visibleData[i] > index then
                table.insert(self.visibleData, index, i)   
                inserted = true         
                break
            end
        end
        
        if not inserted then
            table.insert(self.visibleData, index)
        end
        
        UpdateAfterDataVisibilityChange(self)
    end
end

local function CompareIndices(search, compare)
    return search - compare
end

function ZO_ScrollList_HideAllCategories(self)
    if self.mode == SCROLL_LIST_UNIFORM then
        for categoryId in pairs(self.categories) do
            ZO_ScrollList_HideCategory(self, categoryId)
        end
    end
end

function ZO_ScrollList_ShowCategory(self, categoryId)
    if self.mode == SCROLL_LIST_UNIFORM then
        local category = self.categories[categoryId]
        if category then
            category.hidden = false

            local numShown = 0
            local i = 1
            while i <= #self.data do
                local curCategoryId = self.data[i].categoryId
                local curCategory = self.categories[curCategoryId]

                local shouldInsert = true
                while curCategory do
                    if curCategory.hidden then
                        shouldInsert = false
                        break
                    end
                    curCategory = curCategory.parent
                end

                if shouldInsert then
                    local found, insertionPoint = zo_binarysearch(i, self.visibleData, CompareIndices)        
                    if not found then
                        numShown = numShown + 1
                        table.insert(self.visibleData, insertionPoint, i)
                    end
                end

                i = i + 1
            end
        
            if numShown > 0 then
                UpdateAfterDataVisibilityChange(self)
            end
        end
    end
end

--Used to locate the point in the data list where we should start looking for in view controls
local function FindStartPoint(self, topEdge)
    if self.mode == SCROLL_LIST_UNIFORM then
        return zo_floor(topEdge / self.uniformControlHeight) + 1
    else
        local function CompareEntries(topEdge, compareDataIndex)
            local compareData = self.data[compareDataIndex]
            return topEdge - compareData.bottom
        end

        local _, insertPoint = zo_binarysearch(topEdge, self.visibleData, CompareEntries)
        return insertPoint
    end
end

--holds controls that have already been evaluated and do not need to be looked at again this update scroll call
local consideredMap = {}

function ZO_ScrollList_UpdateScroll(self)
    local windowHeight = ZO_ScrollList_GetHeight(self)
    local activeControls = self.activeControls
    local offset = self.offset

    local IS_REAL_NUMBER = false
    UpdateScrollFade(self, self.contents, IS_REAL_NUMBER, offset)
    
    --remove active controls that are now hidden
    local activeIndex = 1
    local numActive = #activeControls
    while activeIndex <= numActive do
        local currentDataEntry = activeControls[activeIndex].dataEntry

        if currentDataEntry.bottom < offset or currentDataEntry.top > offset + windowHeight then
            FreeActiveScrollListControl(self, activeIndex)
            numActive = numActive - 1
        else
            activeIndex = activeIndex + 1
        end
        consideredMap[currentDataEntry] = true
    end

    local allData = self.data
    local visibleDataIndices = self.visibleData
    local mode = self.mode

    --add revealed controls
    local firstInViewVisibleIndex = FindStartPoint(self, offset)
    local nextCandidateVisibleIndex = firstInViewVisibleIndex
    local currentDataIndex = visibleDataIndices[nextCandidateVisibleIndex]
    local dataEntry = allData[currentDataIndex]
    local bottomEdge = offset + windowHeight
    
    local controlTop
    local uniformControlHeight = self.uniformControlHeight

    if dataEntry then
        if mode == SCROLL_LIST_UNIFORM then
            controlTop = (nextCandidateVisibleIndex - 1) * uniformControlHeight 
        else
            controlTop = dataEntry.top
        end
    end

    while dataEntry and controlTop <= bottomEdge do
        if not consideredMap[dataEntry] then
            local dataType = GetDataTypeInfo(self, dataEntry.typeId)
            local controlPool = dataType.pool

            if controlPool then
                local control, key = controlPool:AcquireObject()
                local setupCallback = dataType.setupCallback
            
                control:SetHidden(false)
                control.dataEntry = dataEntry
                dataEntry.control = control
                control.key = key
                control.index = currentDataIndex
                if setupCallback then
                    setupCallback(control, dataEntry.data, self)
                end
                table.insert(activeControls, control)
                consideredMap[dataEntry] = true
            
                if AreDataEqualSelections(self, dataEntry.data, self.selectedData) then
                    SelectControl(self, control, ANIMATE_INSTANTLY)
                end
            end
            
            --even uniform active controls need to know their position to determine if they are still active
            if self.mode == SCROLL_LIST_UNIFORM then
                dataEntry.top = controlTop
                dataEntry.bottom = controlTop + uniformControlHeight
            end
        end
        nextCandidateVisibleIndex = nextCandidateVisibleIndex + 1
        currentDataIndex = visibleDataIndices[nextCandidateVisibleIndex]
        dataEntry = allData[currentDataIndex]
        if dataEntry then
            if mode == SCROLL_LIST_UNIFORM then
                controlTop = (nextCandidateVisibleIndex - 1) * uniformControlHeight 
            else
                controlTop = dataEntry.top
            end
        end
    end

    --update positions
    local contents = self.contents
    local numNowActive = #activeControls
    for activeControlIndex = 1, numNowActive do
        local currentControl = activeControls[activeControlIndex]
        local currentData = currentControl.dataEntry
        if self.mode == SCROLL_LIST_OPERATIONS then
            local currentOperation = GetDataTypeInfo(self, currentData.typeId)
            currentOperation:AddToScrollContents(contents, currentControl, currentData.left, currentData.top, offset)
        else
            local yOffset = currentData.top - offset
            local xOffset = currentData.left
            currentControl:ClearAnchors()

            currentControl:SetAnchor(TOPLEFT, contents, TOPLEFT, xOffset, yOffset)
            currentControl:SetAnchor(TOPRIGHT, contents, TOPRIGHT, xOffset, yOffset)
        end
    end
    
    --reset considered
    for k,v in pairs(consideredMap) do
        consideredMap[k] = nil
    end
end

function ZO_ScrollList_ResetToTop(self)
    self.timeline:Stop()
    self.scrollbar:SetValue(MIN_SCROLL_VALUE)
end

function ZO_ScrollList_ScrollRelative(self, delta, onScrollCompleteCallback, animateInstantly)
    if not self.lock then
        local scrollValue
        if self.animationTarget then
            scrollValue = self.animationTarget + delta
        else
            scrollValue = self.scrollbar:GetValue() + delta
        end

        self.onScrollCompleteCallback = onScrollCompleteCallback
        SetSliderValue(self, scrollValue, animateInstantly)
    elseif onScrollCompleteCallback then
        onScrollCompleteCallback(true)
    end
end

function ZO_ScrollList_ScrollAbsolute(self, value)
    if not self.lock then
        SetSliderValue(self, value)
    end
end

--This function actually moves the scroll window. The only thing that should ever call it is the slider's value changed handler.
--All other scrolling behavior should call scroll absolute or scroll relative which moves the slider and activates the value changed handler.
function ZO_ScrollList_MoveWindow(self, value)
    self.offset = value
    ZO_ScrollList_UpdateScroll(self)
end


-- These functions are used for scrolling through the scroll list as a block of text instead of scrolling though each entry.
function ZO_ScrollList_CanScrollUp(self)
    return self.selectedDataIndex and self.selectedDataIndex ~= 1
end

function ZO_ScrollList_CanScrollDown(self)
    return self.selectedDataIndex and self.selectedDataIndex ~= #self.data
end

function ZO_ScrollList_AtTopOfVisible(self)
    local minIndex = #self.data
    local minIndexData = nil
    
    for i = 1, #self.activeControls do
        local currentControl = self.activeControls[i]
        local currentData = currentControl.dataEntry.data
        local currentIndex = currentControl.index
        if currentIndex < minIndex then
            minIndex = currentIndex
            minIndexData = currentData
        end
    end

    return self.selectedDataIndex == minIndex, minIndexData
end

function ZO_ScrollList_AtBottomOfVisible(self)
    local maxIndex = 1
    local maxIndexData = nil
    
    for i = 1, #self.activeControls do
        local currentControl = self.activeControls[i]
        local currentData = currentControl.dataEntry.data
        local currentIndex = currentControl.index
        if currentIndex > maxIndex then
            maxIndex = currentIndex
            maxIndexData = currentData
        end
    end

    return self.selectedDataIndex == maxIndex, maxIndexData
end

function ZO_ScrollList_AtTopOfList(self)
    if AreSelectionsEnabled(self) then
        if self.selectedDataIndex then
            local selectedData = self.data[self.selectedDataIndex]
            local checkIndex = self.selectedDataIndex - 1
            while checkIndex >= 1 do
                local checkData = self.data[checkIndex]
                if self.mode ~= SCROLL_LIST_OPERATIONS or checkData.top < selectedData.top then
                    if CanSelectData(self, checkIndex) then
                        return false
                    end
                end
                checkIndex = checkIndex - 1
            end

            return true
        end
    else
        return false
    end
end

function ZO_ScrollList_AtBottomOfList(self)
    if AreSelectionsEnabled(self) then
        if self.selectedDataIndex then
            local selectedData = self.data[self.selectedDataIndex]
            local checkIndex = self.selectedDataIndex + 1
            local numData = #self.data
            while checkIndex <= numData do
                local checkData = self.data[checkIndex]
                if self.mode ~= SCROLL_LIST_OPERATIONS or checkData.top > selectedData.top then
                    if CanSelectData(self, checkIndex) then
                        return false
                    end
                end
                checkIndex = checkIndex + 1
            end

            return true
        end
    else
        return false
    end
end

function ZO_ScrollList_SelectDataAndScrollIntoView(self, data, onScrollCompleteCallback, shouldAnimateInstantly)
    ZO_ScrollList_SelectData(self, data, NO_DATA_CONTROL, NOT_RESELECTING_DURING_REBUILD, shouldAnimateInstantly)
    ZO_ScrollList_ScrollDataIntoView(self, self.selectedDataIndex, onScrollCompleteCallback, shouldAnimateInstantly)
end

function ZO_ScrollList_EnoughEntriesToScroll(self)
    local _, scrollableDistance  = self.scrollbar:GetMinMax()
    return scrollableDistance > 0
end
