--Vetical Scrollbar Base
------------------------

local OFF_ALPHA = 0.5
local SCROLL_AREA_ALPHA = 0.8
local ON_ALPHA = 1
local STATE_CHANGE_DURATION = 250
local MIN_SCROLL_VALUE = 0
local MAX_SCROLL_VALUE = 100

local NO_SELECTED_DATA = nil
local NO_DATA_CONTROL = nil
local RESELECTING_DURING_REBUILD = true
local NOT_RESELECTING_DURING_REBUILD = false
local ANIMATE_INSTANTLY = true

function ZO_VerticalScrollbarBase_OnInitialized(self)
    self:SetMinMax(MIN_SCROLL_VALUE, MAX_SCROLL_VALUE)
    self:SetValue(MIN_SCROLL_VALUE)
    self:SetAlpha(OFF_ALPHA)
    self.alphaAnimation, self.timeline = CreateSimpleAnimation(ANIMATION_ALPHA, self)
    self.alphaAnimation:SetDuration(STATE_CHANGE_DURATION)
end

local function UpdateAlpha(self)
    local newAlpha = OFF_ALPHA

    if(self.areaOver) then
        newAlpha = SCROLL_AREA_ALPHA
    end
    
    if(self.thumbHeld or self.over) then
        newAlpha = ON_ALPHA
    end
    
    if(newAlpha ~= self:GetAlpha()) then
        self.targetAlpha = newAlpha
        if(self:IsHidden()) then
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
    if(MouseIsOver(thumb)) then
        self.thumbHeld = true
        UpdateAlpha(self)
    end
end

function ZO_VerticalScrollbarBase_OnMouseUp(self)
    self.thumbHeld = false
    UpdateAlpha(self)
end

function ZO_VerticalScrollbarBase_OnEffectivelyHidden(self)    
    if(self.timeline) then
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

local function CheckMouseInScrollArea(self)
    local inScrollArea = MouseIsOver(self)
    if(inScrollArea ~= self.inScrollArea) then
        self.inScrollArea = inScrollArea
        if(inScrollArea) then
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

local function SetSliderValueAnimated(self, targetValue)
    if self.scrollbar then
        self.timeline:Stop()
        local scrollMin, scrollMax = self.scrollbar:GetMinMax()
        targetValue = zo_clamp(targetValue, scrollMin, scrollMax)
        self.animationStart = self.scrollbar:GetValue()
        self.animationTarget = targetValue
        self.timeline:PlayFromStart()
    end
end

local function OnAnimationStop(animationObject, control)
    local scrollObject = animationObject.scrollObject
    scrollObject.animationStart = nil
    scrollObject.animationTarget = nil
end

local function OnAnimationUpdate(animationObject, progress)
    local scrollObject = animationObject.scrollObject
    local value = scrollObject.animationStart + (scrollObject.animationTarget - scrollObject.animationStart) * progress
    scrollObject.scrollbar:SetValue(value)
end

local function CreateScrollAnimation(scrollObject)
    local animation, timeline = CreateSimpleAnimation(ANIMATION_CUSTOM)
    animation.scrollObject = scrollObject
    animation:SetEasingFunction(ZO_BezierInEase)
    animation:SetUpdateFunction(OnAnimationUpdate)
    animation:SetDuration(400)
    animation:SetHandler("OnStop", OnAnimationStop)

    return animation, timeline
end

--Shared Scroll Edge Fades
-----------------------------------------------------------------
local function UpdateScrollFade(useFadeGradient, scroll, slider, sliderValue)
    if(useFadeGradient) then
        local sliderMin, sliderMax = slider:GetMinMax()
        sliderValue = sliderValue or slider:GetValue()

        if(sliderValue > sliderMin) then
            scroll:SetFadeGradient(1, 0, 1, zo_min(sliderValue - sliderMin, 64))
        else
            scroll:SetFadeGradient(1, 0, 0, 0)
        end
        
        if(sliderValue < sliderMax) then
            scroll:SetFadeGradient(2, 0, -1, zo_min(sliderMax - sliderValue, 64))
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

function ZO_Scroll_Initialize(self)
    self.scroll = GetControl(self, "Scroll")
    self.scrollbar = GetControl(self, "ScrollBar")
    
    if self.scrollbar then
        self.scrollUpButton = GetControl(self.scrollbar, "Up")
        self.scrollUpButton:SetHandler("OnMouseDown", ZO_ScrollUp_OnMouseDown)
        self.scrollDownButton = GetControl(self.scrollbar, "Down")
        self.scrollDownButton:SetHandler("OnMouseDown", ZO_ScrollDown_OnMouseDown)
    end
    
    self.hideScrollBarOnDisabled = true
    self.useFadeGradient = true

    self.animation, self.timeline = CreateScrollAnimation(self)
    
    ZO_Scroll_UpdateScrollBar(self)    
end

--Scrolling functions
function ZO_Scroll_ResetToTop(self)
    self.timeline:Stop()
    if self.scrollbar then
        self.scrollbar:SetValue(MIN_SCROLL_VALUE)
    end
end

function ZO_Scroll_ScrollAbsolute(self, value)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()

    if(verticalExtents > 0) then
        SetSliderValueAnimated(self, (value / verticalExtents) * MAX_SCROLL_VALUE)
    end
end

function ZO_Scroll_ScrollAbsoluteInstantly(self, value)
    local scroll = self.scroll
    local scrollbar = self.scrollbar
    local _, verticalExtents = scroll:GetScrollExtents()
    local targetValue = (value / verticalExtents) * MAX_SCROLL_VALUE
    local scrollMin, scrollMax = scrollbar:GetMinMax()
    targetValue = zo_clamp(targetValue, scrollMin, scrollMax)
    self.timeline:Stop()
    self.animationStart = scrollbar:GetValue()
    self.animationTarget = targetValue
    self.timeline:PlayInstantlyToEnd()
end

function ZO_Scroll_ScrollRelative(self, verticalDelta)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()   
    
    if(verticalExtents > 0) then
        if(self.animationTarget) then
            local oldVerticalOffset = (self.animationTarget * verticalExtents) / MAX_SCROLL_VALUE
            local newVerticalOffset = oldVerticalOffset + verticalDelta
            SetSliderValueAnimated(self, (newVerticalOffset / verticalExtents) * MAX_SCROLL_VALUE)
        else
            local _, currentVerticalOffset = scroll:GetScrollOffsets()
            local newVerticalOffset = currentVerticalOffset + verticalDelta
            SetSliderValueAnimated(self, (newVerticalOffset / verticalExtents) * MAX_SCROLL_VALUE)
        end
    end
end

function ZO_Scroll_MoveWindow(self, value)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()
    
    scroll:SetVerticalScroll((value/MAX_SCROLL_VALUE) * verticalExtents)
    ZO_Scroll_UpdateScrollBar(self)    
end

function ZO_Scroll_GetScrollDistanceToControl(self, otherControl)
    -- self is a ScrollControl.  
    --
    -- NOTE: This doesn't check the lineage of the otherControl, so please don't pass in controls which aren't descended
    -- from self.
    
    local scrollTop         = self:GetTop()
    local scrollBottom      = self:GetBottom()
    local _, scrollHeight   = self:GetDimensions()
    local controlTop        = otherControl:GetTop()
    local controlBottom     = otherControl:GetBottom()   
 
    if(controlTop < scrollTop) -- The control's top is above the top edge of the scroll, must scroll up to fully contain the control.
    then
        return controlTop - scrollTop 
    elseif(controlBottom > scrollBottom) -- The control's bottom is below the bottom edge of the scroll, must scroll down to fully contain the control.
    then
        return controlBottom - scrollBottom
    end
    
    return 0
end

function ZO_Scroll_ScrollToControl(self, otherControl)    
    local scrollDistance = ZO_Scroll_GetScrollDistanceToControl(self.scroll, otherControl)
    
    if(scrollDistance ~= 0) then    
         ZO_Scroll_ScrollRelative(self, scrollDistance)
    end
end

function ZO_Scroll_ScrollControlToTop(self, otherControl)
    local scrollTop         = self.scroll:GetTop()
    local controlTop        = otherControl:GetTop()
   
    ZO_Scroll_ScrollRelative(self, controlTop - scrollTop)
end

function ZO_Scroll_ScrollControlIntoView(self, otherControl)
    local scroll = self.scroll
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    local controlTop = otherControl:GetTop()
    local controlBottom = otherControl:GetBottom()
    
    if(controlTop < scrollTop) then
        ZO_Scroll_ScrollRelative(self, controlTop - scrollTop)
    elseif(controlBottom > scrollBottom) then
        ZO_Scroll_ScrollRelative(self, controlBottom - scrollBottom)
    end
end

function ZO_Scroll_ScrollControlIntoCentralView(self, otherControl, scrollInstantly)
    local scroll = self.scroll
    local scrollbar = self.scrollbar
    local scrollTop = scroll:GetTop()
    local scrollBottom = scroll:GetBottom()
    local controlTop = otherControl:GetTop()
    local controlBottom = otherControl:GetBottom()

    local heightDelta = scroll:GetHeight() - otherControl:GetHeight()
    local halfHeightDelta = heightDelta * .5

    local value
    if controlTop < scrollTop then
        value = (controlTop - scrollTop) - halfHeightDelta
    elseif controlBottom > scrollBottom then
        value = (controlBottom - scrollBottom) + halfHeightDelta
    end
    
    if value then
        if scrollInstantly then
            ZO_Scroll_ResetToTop(self)

            local _, verticalExtents = scroll:GetScrollExtents()
            local targetValue = (value / verticalExtents) * MAX_SCROLL_VALUE
            local scrollMin, scrollMax = scrollbar:GetMinMax()

            self.timeline:Stop()
            self.animationStart = scrollbar:GetValue()
            self.animationTarget = targetValue
            self.timeline:PlayInstantlyToEnd()
        else
            ZO_Scroll_ScrollRelative(self,  value)
        end
    end
end

--Scroll update functions

function ZO_Scroll_OnExtentsChanged(self)
    if self and self.scroll then
        ZO_Scroll_UpdateScrollBar(self)
    end
end

function ZO_Scroll_UpdateScrollBar(self)
    local scroll = self.scroll
    local _, verticalOffset = scroll:GetScrollOffsets()  
    local _, verticalExtents   = scroll:GetScrollExtents()
    local scrollEnabled = (verticalExtents > 0 or verticalOffset > 0)
    local scrollbar  = self.scrollbar
    local scrollIndicator = self.scrollIndicator
    local scrollbarHidden = (self.hideScrollBarOnDisabled and not scrollEnabled)

    if scrollbar then
        --thumb resizing
        local scrollBarHeight = scrollbar:GetHeight()
        local scrollAreaHeight = scroll:GetHeight()
        if(verticalExtents > 0 and scrollBarHeight >= 0 and scrollAreaHeight >= 0) then
            local thumbHeight = scrollBarHeight * scrollAreaHeight /(verticalExtents + scrollAreaHeight)
            scrollbar:SetThumbTextureHeight(thumbHeight)
        else
            scrollbar:SetThumbTextureHeight(scrollBarHeight)
        end
    
        --auto scroll bar hiding
        local wasHidden = scrollbar:IsHidden()
        scrollbar:SetHidden(scrollbarHidden)
        scrollbar:SetMinMax(MIN_SCROLL_VALUE, not scrollbarHidden and MAX_SCROLL_VALUE or MIN_SCROLL_VALUE)
        if wasHidden and not scrollbarHidden and scrollbar.resetScrollbarOnShow then
            ZO_Scroll_ResetToTop(self)
            self.scrollValue = MIN_SCROLL_VALUE
        end

        --extents updating
        local verticalExtentsChanged = self.verticalExtents ~= nil and not zo_floatsAreEqual(self.verticalExtents, verticalExtents)
        self.verticalExtents = verticalExtents
        if verticalExtentsChanged then
            if verticalExtents > 0 then
                self.scrollbar:SetValue(MAX_SCROLL_VALUE * (verticalOffset / verticalExtents))
            else
                ZO_Scroll_ResetToTop(self)
            end
        end

        UpdateScrollFade(self.useFadeGradient, scroll, scrollbar)
    elseif scrollIndicator then
        --auto scroll indicator hiding
        local wasHidden = scrollIndicator:IsHidden()
        scrollIndicator:SetHidden(scrollbarHidden)
        if wasHidden and not scrollbarHidden then
            ZO_Scroll_ResetToTop(self)
            self.scrollValue = 0
        end

        --extents updating
        local verticalExtentsChanged = self.verticalExtents ~= nil and not zo_floatsAreEqual(self.verticalExtents, verticalExtents)
        self.verticalExtents = verticalExtents
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

function ZO_Scroll_SetHideScrollbarOnDisable(self, hide)
    self.hideScrollBarOnDisabled = hide    
    ZO_Scroll_UpdateScrollBar(self)
end

function ZO_Scroll_SetUseFadeGradient(self, useFadeGradient)
    self.useFadeGradient = useFadeGradient
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
    self.activeControls = {}
    self.visibleData = {}
    self.categories = {}
    self.mode = SCROLL_LIST_UNIFORM
    self.controlHeight = NO_HEIGHT_SET
    
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

    self.hideScrollBarOnDisabled = true
    self.useFadeGradient = true

    ZO_ScrollList_Commit(self)
end

function ZO_ScrollList_SetHeight(self, height)
    self:SetHeight(height)
end

function ZO_ScrollList_GetHeight(self)
    return self:GetHeight()
end

local function AreSelectionsEnabled(self)
    return self.selectionTemplate or self.selectionCallback
end

function ZO_ScrollList_AddResizeOnScreenResize(self)
    local function OnScreenResized()
        ZO_ScrollList_SetHeight(self, self:GetHeight())
        ZO_ScrollList_Commit(self)    
    end
    self:RegisterForEvent(EVENT_SCREEN_RESIZED, OnScreenResized)
end

local function UpdateModeFromHeight(self, height)
    if self.mode == SCROLL_LIST_UNIFORM then
        if self.controlHeight == NO_HEIGHT_SET then
            self.controlHeight = height
        elseif height ~= self.controlHeight then
            self.controlHeight = nil
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
    if(not self.dataTypes[typeId]) then
        local factoryFunction = function(objectPool) return ZO_ObjectPool_CreateNamedControl(string.format("%s%dRow", self:GetName(), tostring(typeId)), templateName, objectPool, self.contents) end
        local pool = ZO_ObjectPool:New(factoryFunction, resetControlCallback or ZO_ObjectPool_DefaultResetControl)
        self.dataTypes[typeId] = 
        {
            height = height,
            setupCallback = setupCallback,
            hideCallback = hideCallback,
            equalityFunction = equalityFunction,
            pool = pool,
            selectSound = dataTypeSelectSound,
            selectable = true,
        }
        
        --automatically choose the scrolling logic based on if the controls are all the same height or not
        UpdateModeFromHeight(self, height)
    end
end

function ZO_ScrollList_GetDataTypeTable(self, typeId)
    return self.dataTypes and self.dataTypes[typeId] or nil
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

function ZO_ScrollList_SetEqualityFunction(self, typeId, equalityFunction)
    self.dataTypes[typeId].equalityFunction = equalityFunction
end

function ZO_ScrollList_SetDeselectOnReselect(self, deselectOnReselect)
    self.deselectOnReselect = deselectOnReselect
end

function ZO_ScrollList_SetAutoSelect(self, autoSelect)
    self.autoSelect = autoSelect
end

function ZO_ScrollList_SetScrollBarHiddenCallback(self, callback)
    self.ScrollBarHiddenCallback = callback
end

function ZO_ScrollList_AddCategory(self, categoryId, parentId)
    if(self.categories[categoryId]) then
        return
    end    
    
    --if a parent id is given and it doesn't exist, give up
    local parent = nil
    if(parentId) then
        parent = self.categories[parentId]
        if(not parent) then
            return
        end        
    end
    
    local category = {id = categoryId, parent = parent, children = {}, hidden = false}
    self.categories[categoryId] = category
    if(parent) then
        table.insert(parent.children, category)
    end
end

function ZO_ScrollList_Clear(self)
    ZO_ClearNumericallyIndexedTable(self.data)
    self.categories = {}
    if AreSelectionsEnabled(self) then
        ZO_ScrollList_SelectData(self, NO_SELECTED_DATA, NO_DATA_CONTROL, RESELECTING_DURING_REBUILD, ANIMATE_INSTANTLY)
        self.lastSelectedDataIndex = nil
    end
end

function ZO_ScrollList_GetCategoryHidden(self, categoryId)
    local category = self.categories[categoryId]
    if(category) then
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

function ZO_ScrollList_GetDataEntryData(entry)
    return entry.data
end

function ZO_ScrollList_GetData(control)
    if(control.dataEntry) then
        return control.dataEntry.data
    end
end

function ZO_ScrollList_GetDataList(self)
    return self.data
end

function ZO_ScrollList_HasVisibleData(self)
    return #self.visibleData > 0
end

function ZO_ScrollList_GetSelectedData(self)
    if(AreSelectionsEnabled(self)) then
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
        if(MouseIsOver(control)) then
            return control
        end
    end
end

local function PlayAnimationOnControl(control, controlTemplate, animationFieldName, animateInstantly)
    if controlTemplate then
        if not control[animationFieldName] then
            local highlight = CreateControlFromVirtual("$(parent)Scroll", control, controlTemplate, animationFieldName)
            control[animationFieldName] = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
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
    PlayAnimationOnControl(control, self.highlightTemplate, "HighlightAnimation")

    self.highlightedControl = control
    
    if(self.highlightCallback) then
        self.highlightCallback(control, true)
    end   
end

local function UnhighlightControl(self, control) 
    RemoveAnimationOnControl(control, "HighlightAnimation")

    self.highlightedControl = nil

    if(self.highlightCallback) then
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
    if(not self.highlightTemplate or (self.highlightLocked == lock)) then
        return
    end
   
    self.highlightLocked = lock
    
    if(lock) then
        self.pendingHighlightControl = self.highlightedControl
    else
        if(self.highlightedControl) then
            UnhighlightControl(self, self.highlightedControl)
        end
        if(self.pendingHighlightControl) then
            HighlightControl(self, self.pendingHighlightControl)
        end
    end
end

--Reinitializes the highlight (used mostly when a mouse enter would have been missed)
local function RefreshHighlight(self)
    if(not self.highlightTemplate) then
        return
    end

    self.highlightLocked = false
    if(self.highlightedControl) then
        UnhighlightControl(self, self.highlightedControl)
    end
    
    --find the control to highlight if any
    for i = 0, #self.activeControls do
        local control = self.activeControls[i]
        if(MouseIsOver(control)) then
            HighlightControl(self, control)
            return
        end
    end
end

function ZO_ScrollList_MouseEnter(self, control)
    if(not self.highlightTemplate) then
        return
    end
    
    --allows us to place the highlight correctly when we unlock
    if(self.highlightLocked) then
        self.pendingHighlightControl = control
        return
    end
    
    HighlightControl(self, control)
end

function ZO_ScrollList_MouseExit(self, control)
    if(not self.highlightTemplate) then
        return
    end
    
    if(self.highlightLocked) then
        self.pendingHighlightControl = nil
        return
    end
    
    UnhighlightControl(self, control)
end

function ZO_ScrollList_MouseClick(self, control)
    if(AreSelectionsEnabled(self)) then
        if(control == self.selectedControl) then
            if(self.deselectOnReselect) then
                ZO_ScrollList_SelectData(self, nil)
            end
        else
            local data = ZO_ScrollList_GetData(control)
            local typeId = control.dataEntry.typeId
            local selectSound = self.dataTypes[typeId].selectSound

            ZO_ScrollList_SelectData(self, data, control)

            if(selectSound) then
                PlaySound(selectSound)
            end
        end		
    end
end

function ZO_ScrollList_EnableHighlight(self, highlightTemplate, highlightCallback)
    if not self.highlightTemplate then
        self.highlightTemplate = highlightTemplate
        
        self.highlightLocked = false
        self.pendingHighlightControl = nil
        self.highlightCallback = highlightCallback
        
        RefreshHighlight(self)
    end
end

function ZO_ScrollList_SetHideScrollbarOnDisable(self, hideOnDisable)
    -- Not updating state here, you should call this when the list is being created.
    -- The bar will update state properly when the list has data committed.
    self.hideScrollBarOnDisabled = hideOnDisable
end

function ZO_ScrollList_SetUseFadeGradient(self, useFadeGradient)
    self.useFadeGradient = useFadeGradient
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
    if(data1 == data2) then
        return true
    end

    if(data1 == nil or data2 == nil) then
        return false
    end        

    local dataEntry1 = data1.dataEntry
    local dataEntry2 = data2.dataEntry
    if(dataEntry1.typeId == dataEntry2.typeId) then
        local equalityFunction = self.dataTypes[dataEntry1.typeId].equalityFunction
        if(equalityFunction) then
            return equalityFunction(data1, data2)
        end
    end

    return false
end

function ZO_ScrollList_IsDataSelected(self, data)
    if(AreSelectionsEnabled(self) and AreDataEqualSelections(self, self.selectedData, data)) then
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
            if(currentDataEntry.data == data) then
                return currentControl
            end
        end
    end
    return nil
end

function ZO_ScrollList_SelectData(self, data, control, reselectingDuringRebuild, animateInstantly)
    if AreSelectionsEnabled(self) and self.selectedData ~= data then
        if reselectingDuringRebuild == nil then
            reselectingDuringRebuild = false
        end

        if animateInstantly == nil then
            animateInstantly = false
        end

        local dataIndex
        if data ~= nil then
            for i = 1, #self.data do
                if self.data[i].data == data then
                    dataIndex = i
                    break
                end
            end

            --this data we tried to select isn't in the scroll list at all, just abort
            if dataIndex == nil then
                return
            end
        end

        local previouslySelectedData = self.selectedData
        if self.selectedData then
            self.selectedData = nil
            self.selectedDataIndex = nil
            if self.selectedControl then
                UnselectControl(self, self.selectedControl, animateInstantly)
            end
        end
        
        if data ~= nil then
            self.selectedDataIndex = dataIndex
            self.lastSelectedDataIndex = dataIndex
            self.selectedData = data

            if not control then
                control = ZO_ScrollList_GetDataControl(self, data)
            end

            if control then
                SelectControl(self, control, animateInstantly)
            end
        end
        
        if self.selectionCallback then
            self.selectionCallback(previouslySelectedData, self.selectedData, reselectingDuringRebuild)
        end
    end
end

local function OnContentsUpdate(self)
    local _, windowHeight = self:GetDimensions()
    
    if(windowHeight > 0) then
        self:SetHandler("OnUpdate", nil)
        ZO_ScrollList_SetHeight(self, windowHeight)
        ZO_ScrollList_Commit(self:GetParent())        
    end
end

local function FreeActiveScrollListControl(self, i)
    local currentControl = self.activeControls[i]
    local currentDataEntry = currentControl.dataEntry
    local dataType = self.dataTypes[currentDataEntry.typeId]
    
    if(self.highlightTemplate and currentControl == self.highlightedControl) then
        UnhighlightControl(self, currentControl)
        if(self.highlightLocked) then
            self.highlightLocked = false
        end
    end

    if(currentControl == self.pendingHighlightControl) then
        self.pendingHighlightControl = nil
    end
    
    if AreSelectionsEnabled(self) and currentControl == self.selectedControl then
        UnselectControl(self, currentControl, ANIMATE_INSTANTLY)
    end
    
    if(dataType.hideCallback) then
        dataType.hideCallback(currentControl, currentControl.dataEntry.data)
    end
    
    dataType.pool:ReleaseObject(currentControl.key)
    currentControl.key = nil
    currentControl.dataEntry = nil
    self.activeControls[i] = self.activeControls[#self.activeControls]
    self.activeControls[#self.activeControls] = nil
end

local HIDE_SCROLLBAR = true
local function ResizeScrollBar(self, scrollableDistance)
    local scrollBarHeight = self.scrollbar:GetHeight()
    local scrollListHeight = ZO_ScrollList_GetHeight(self)
    if(scrollableDistance > 0) then
        self.scrollbar:SetEnabled(true)

        if self.ScrollBarHiddenCallback then
            self.ScrollBarHiddenCallback(self, not HIDE_SCROLLBAR)
        else
            self.scrollbar:SetHidden(false)
        end

        self.scrollbar:SetThumbTextureHeight(scrollBarHeight * scrollListHeight /(scrollableDistance + scrollListHeight))
        if(self.offset > scrollableDistance) then
            self.offset = scrollableDistance
        end
        self.scrollbar:SetMinMax(0, scrollableDistance)
    else
        self.offset = 0
        self.scrollbar:SetThumbTextureHeight(scrollBarHeight)
        self.scrollbar:SetMinMax(0, 0)
        self.scrollbar:SetEnabled(false)

        if(self.hideScrollBarOnDisabled) then
            if self.ScrollBarHiddenCallback then
                self.ScrollBarHiddenCallback(self, HIDE_SCROLLBAR)
            else
                self.scrollbar:SetHidden(true)
            end
        end
    end
end

local function CheckRunHandler(self, handlerName)
    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
    if(mouseOverControl and not mouseOverControl:IsHidden() and mouseOverControl:IsChildOf(self)) then
        local handler = mouseOverControl:GetHandler(handlerName)
        if(handler) then
            handler(mouseOverControl)
        end
    end
end

local function CanSelectData(self, index)
    local dataEntry = self.data[index]
    return self.dataTypes[dataEntry.typeId].selectable
end

local function AutoSelect(self, animateInstantly)
    if(#self.data > 0) then
        local recalledIndex = self.selectedDataIndex or self.lastSelectedDataIndex
        if(recalledIndex) then
            for i = zo_min(recalledIndex, #self.data), 1, -1 do
                if CanSelectData(self, i) then
                    ZO_ScrollList_SelectData(self, self.data[i].data, NO_DATA_CONTROL, NOT_RESELECTING_DURING_REBUILD, animateInstantly)
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

function ZO_ScrollList_ScrollDataIntoView(self, dataIndex)
    local scrollTop = self.scrollbar:GetValue()
    local scrollBottom = self.scrollbar:GetValue() + ZO_ScrollList_GetHeight(self)
    local controlTop = (dataIndex-1) * self.controlHeight
    local controlBottom = dataIndex * self.controlHeight

    if(controlTop < scrollTop) then
        ZO_ScrollList_ScrollRelative(self, controlTop - scrollTop)
    elseif(controlBottom > scrollBottom) then
        ZO_ScrollList_ScrollRelative(self, controlBottom - scrollBottom)
    end
end

function ZO_ScrollList_ScrollDataToCenter(self, dataIndex)
    local scrollCenter = self.scrollbar:GetValue() + ZO_ScrollList_GetHeight(self) / 2
    local controlTop = (dataIndex-1) * self.controlHeight
    local controlCenter  = controlTop + self.controlHeight / 2

    ZO_ScrollList_ScrollRelative(self, controlCenter - scrollCenter)
end

function ZO_ScrollList_SelectNextData(self)
    if not self.selectedDataIndex then
        return
    end
    for i = 1, #self.data do
        -- Allow Wraping
        local newIndex = ((self.selectedDataIndex + i - 1) % #self.data) + 1
        if CanSelectData(self, newIndex) then
            ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[newIndex].data)
            break
        end
    end
end

function ZO_ScrollList_SelectPreviousData(self)
     if not self.selectedDataIndex then
        return
    end
     for i = 1, #self.data do
        -- Allow Wraping
        local newIndex = ((self.selectedDataIndex + #self.data - i - 1) % #self.data) + 1
        if CanSelectData(self, newIndex) then
            ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[newIndex].data)
            break
        end
    end
end

function ZO_ScrollList_TrySelectFirstData(self)
    for i = 1, #self.data do
        if(CanSelectData(self, i)) then
            ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[i].data)
            return true
        end
    end
    return false
end

function ZO_ScrollList_TrySelectLastData(self)
    for i = #self.data, 1, -1 do
        if(CanSelectData(self, i)) then
            ZO_ScrollList_SelectDataAndScrollIntoView(self, self.data[i].data)
            return true
        end
    end
    return false
end

function ZO_ScrollList_AutoSelectData(self, animateInstantly)
    AutoSelect(self, animateInstantly)
end

function ZO_ScrollList_ResetAutoSelectIndex(self)
    self.lastSelectedDataIndex = nil
end

--Updates the scroll control with new data. Call this when you modify the data list by adding or removing entries.
function ZO_ScrollList_Commit(self)
    local windowHeight = ZO_ScrollList_GetHeight(self)
    local selectionsEnabled = AreSelectionsEnabled(self)
        
    --the window isn't big enough to show anything (its anchors probably haven't been processed yet), so delay the commit until that happens
    if(windowHeight <= 0) then
        self.contents:SetHandler("OnUpdate", OnContentsUpdate)
        return
    end

    CheckRunHandler(self, "OnMouseExit")
    
    self.visibleData = {}
    
    local scrollableDistance = 0
    local foundSelected = false
    if(self.mode == SCROLL_LIST_NON_UNIFORM) then
        local currentY = 0
        for i = 1,#self.data do
            local currentData = self.data[i]
            currentData.top = currentY
            currentY = currentY + self.dataTypes[currentData.typeId].height
            currentData.bottom = currentY
            table.insert(self.visibleData, i)
            
            if selectionsEnabled and AreDataEqualSelections(self, currentData.data, self.selectedData) then
                foundSelected = true
                ZO_ScrollList_SelectData(self, currentData.data, NO_DATA_CONTROL, RESELECTING_DURING_REBUILD, ANIMATE_INSTANTLY)
            end
        end
        scrollableDistance = currentY - windowHeight
    else
        for i = 1,#self.data do
            table.insert(self.visibleData, i)
            
            if selectionsEnabled and AreDataEqualSelections(self, self.data[i].data, self.selectedData) then
               foundSelected = true
               ZO_ScrollList_SelectData(self, self.data[i].data, NO_DATA_CONTROL, RESELECTING_DURING_REBUILD, ANIMATE_INSTANTLY)
            end
        end
        scrollableDistance = (#self.data) * self.controlHeight - windowHeight
    end
    
    ResizeScrollBar(self, scrollableDistance)
    
    --nuke the active list since things may have left it
    local i = #self.activeControls
    while(i >= 1) do
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

--updates the layout of visible controls
--data: optionally allows you to only update the control backed by the specified data table
--overrideSetupCallback: optionally allows you to call this function instead of the normal setup function if you only need to do a very specific update
function ZO_ScrollList_RefreshVisible(self, data, overrideSetupCallback)
    for i = 1, #self.activeControls do
        local control = self.activeControls[i]
        local dataEntry = control.dataEntry
        if(not data or data == dataEntry.data) then
            local dataType = self.dataTypes[dataEntry.typeId]
            if(overrideSetupCallback) then
                overrideSetupCallback(control, dataEntry.data, self)
            elseif(dataType.setupCallback) then
                dataType.setupCallback(control, dataEntry.data, self)
            end
        end
    end
end

local function UpdateAfterDataVisibilityChange(self)
    if(self.mode == SCROLL_LIST_UNIFORM) then
        --nuke the active list since things may have left it
        local i = #self.activeControls
        while(i >= 1) do
            FreeActiveScrollListControl(self, i)
            i = i - 1
        end
        
        --update scroll distance
        local windowHeight = ZO_ScrollList_GetHeight(self)
        local scrollSize = self.controlHeight * #self.visibleData       
        ResizeScrollBar(self, math.max(0, scrollSize-windowHeight))        
        ZO_ScrollList_UpdateScroll(self)
    end
end

function ZO_ScrollList_HideData(self, index)
    if(self.mode == SCROLL_LIST_UNIFORM) then
        for i = 1, #self.visibleData do
            if(self.visibleData[i] == index) then
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

    if(self.mode == SCROLL_LIST_UNIFORM) then
        local category = self.categories[categoryId]
        if(category) then
            category.hidden = true    
            local numRemoved = 0
            
            local i = 1
            while(i <= #self.visibleData) do
                local curCategoryId = data[visibleData[i]].categoryId
                local curCategory = categories[curCategoryId]
                local found = false
                
                --climb the hierarchy to see if this piece of data is under this category
                while(curCategory) do
                    curCategoryId = curCategory.id
                    if(curCategoryId == categoryId) then
                        table.remove(visibleData, i)
                        found = true
                        numRemoved = numRemoved + 1
                        break
                    end
                    curCategory = curCategory.parent
                end 
                
                if(not found) then
                    i = i + 1
                end          
            end
        
            if(numRemoved > 0) then
                UpdateAfterDataVisibilityChange(self)
            end
        end
    end
end

function ZO_ScrollList_ShowData(self, index)
    if(self.mode == SCROLL_LIST_UNIFORM) then
        local inserted = false
        for i = 1, #self.visibleData do
            if(self.visibleData[i] == index) then
                return
            elseif(self.visibleData[i] > index) then
                table.insert(self.visibleData, index, i)   
                inserted = true         
                break
            end
        end
        
        if(not inserted) then
            table.insert(self.visibleData, index)
        end
        
        UpdateAfterDataVisibilityChange(self)
    end
end

local function CompareIndices(search, compare)
    return search - compare
end

function ZO_ScrollList_HideAllCategories(self)
    if(self.mode == SCROLL_LIST_UNIFORM) then
        for categoryId in pairs(self.categories) do
            ZO_ScrollList_HideCategory(self, categoryId)
        end
    end
end

function ZO_ScrollList_ShowCategory(self, categoryId)
    if(self.mode == SCROLL_LIST_UNIFORM) then
        local category = self.categories[categoryId]
        if(category) then			
            category.hidden = false    
        
            local numShown = 0
            local i = 1
            while(i <= #self.data) do
                local curCategoryId = self.data[i].categoryId
                local curCategory = self.categories[curCategoryId]
                
                local shouldInsert = true
                while(curCategory) do
                    if(curCategory.hidden) then
                        shouldInsert = false
                        break
                    end				
                    curCategory = curCategory.parent
                end
                
                if(shouldInsert) then					
                    local found, insertionPoint = zo_binarysearch(i, self.visibleData, CompareIndices)        
                    if(not found) then
                        numShown = numShown + 1
                        table.insert(self.visibleData, insertionPoint, i)
                    end
                end

                i = i + 1          
            end
        
            if(numShown > 0) then
                UpdateAfterDataVisibilityChange(self)
            end
        end
    end
end

local function CompareEntries(topEdge, compareData)
    return topEdge - compareData.bottom
end

--Used to locate the point in the data list where we should start looking for in view controls
local function FindStartPoint(self, topEdge)
    if(self.mode == SCROLL_LIST_UNIFORM) then
        return zo_floor(topEdge / self.controlHeight)+1
    else
        local found, insertPoint = zo_binarysearch(topEdge, self.data, CompareEntries)
        return insertPoint
    end
end

--holds controls that have already been evaluated and do not need to be looked at again this update scroll call
local consideredMap = {}

function ZO_ScrollList_UpdateScroll(self)
    local windowHeight = ZO_ScrollList_GetHeight(self)
    local controlHeight = self.controlHeight
    local activeControls = self.activeControls
    local offset = self.offset

    UpdateScrollFade(self.useFadeGradient, self.contents, self.scrollbar, offset)
    
    --remove active controls that are now hidden
    local i = 1
    local numActive = #activeControls
    while(i <= numActive) do
        local currentDataEntry = activeControls[i].dataEntry
        
        if(currentDataEntry.bottom < offset or currentDataEntry.top > offset + windowHeight) then
            FreeActiveScrollListControl(self, i)
            numActive = numActive - 1
        else
            i = i + 1
        end
        
        consideredMap[currentDataEntry] = true
    end
        
    --add revealed controls
    local firstInViewIndex = FindStartPoint(self, offset)
   
    local data = self.data
    local dataTypes = self.dataTypes
    local visibleData = self.visibleData
    local mode = self.mode
    
    local i = firstInViewIndex
    local visibleDataIndex = visibleData[i]
    local dataEntry = data[visibleDataIndex]
    local bottomEdge = offset + windowHeight
    
    local controlTop
    
    if(dataEntry) then
        if(mode == SCROLL_LIST_UNIFORM) then
            controlTop = (i-1) * controlHeight 
        else
            controlTop = dataEntry.top
        end
    end
    while(dataEntry and controlTop <= bottomEdge) do
        if(not consideredMap[dataEntry]) then
            local dataType = dataTypes[dataEntry.typeId]
            local controlPool = dataType.pool
            local control, key = controlPool:AcquireObject()
            
            control:SetHidden(false)
            control.dataEntry = dataEntry
            control.key = key
            control.index = visibleDataIndex
            if(dataType.setupCallback) then
                dataType.setupCallback(control, dataEntry.data, self)
            end
            table.insert(activeControls, control)
            consideredMap[dataEntry] = true
            
            if AreDataEqualSelections(self, dataEntry.data, self.selectedData) then
                SelectControl(self, control, ANIMATE_INSTANTLY)
            end
            
            --even uniform active controls need to know their position to determine if they are still active
            if(self.mode == SCROLL_LIST_UNIFORM) then
                dataEntry.top = controlTop
                dataEntry.bottom = controlTop + controlHeight
            end
        end
        i = i + 1
        visibleDataIndex = visibleData[i]
        dataEntry = data[visibleDataIndex]
        if(dataEntry) then
            if(mode == SCROLL_LIST_UNIFORM) then
                controlTop = (i-1) * controlHeight
            else
                controlTop = dataEntry.top
            end
        end
    end
    
    --update positions
    local contents = self.contents
    local numActive = #activeControls
    
    for i = 1, numActive do
        local currentControl = activeControls[i]
        local currentData = currentControl.dataEntry
        local controlOffset = currentData.top - offset

        currentControl:ClearAnchors()
        currentControl:SetAnchor(TOPLEFT, contents, TOPLEFT, 0, controlOffset)
        currentControl:SetAnchor(TOPRIGHT, contents, TOPRIGHT, 0, controlOffset)
    end  
    
    --reset considered
    for k,v in pairs(consideredMap) do
        consideredMap[k] = nil
    end
end

function ZO_ScrollList_ResetToTop(self)
    self.timeline:Stop()
    self.scrollbar:SetValue(0)
end

function ZO_ScrollList_ScrollRelative(self, delta)
    if(not self.lock) then
        if(self.animationTarget) then
            SetSliderValueAnimated(self, self.animationTarget + delta)
        else
            SetSliderValueAnimated(self, self.scrollbar:GetValue() + delta)
        end
    end
end

function ZO_ScrollList_ScrollAbsolute(self, value)
    if(not self.lock) then
        SetSliderValueAnimated(self, value)
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
    return self.selectedDataIndex == 1
end

function ZO_ScrollList_AtBottomOfList(self)
    return self.selectedDataIndex == #self.data
end

function ZO_ScrollList_SelectDataAndScrollIntoView(self, data)
    ZO_ScrollList_SelectData(self, data)
    ZO_ScrollList_ScrollDataIntoView(self, self.selectedDataIndex)
end

function ZO_ScrollList_EnoughEntriesToScroll(self)
    local _, scrollableDistance  = self.scrollbar:GetMinMax()
    return scrollableDistance > 0
end