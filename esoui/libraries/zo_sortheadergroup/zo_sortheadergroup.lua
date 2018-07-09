ZO_SortHeaderGroup = ZO_CallbackObject:Subclass()
ZO_SortHeaderGroup.HEADER_CLICKED = "HeaderClicked"
ZO_SortHeaderGroup.SUPPRESS_CALLBACKS = true
ZO_SortHeaderGroup.FORCE_RESELECT = true

local SORT_ARROW_UP = "EsoUI/Art/Miscellaneous/list_sortUp.dds"
local SORT_ARROW_DOWN = "EsoUI/Art/Miscellaneous/list_sortDown.dds"
local SORT_ARROW_OFFSET_X = 2

function ZO_SortHeaderGroup:New(headerContainer, showArrows)
    local group = ZO_CallbackObject.New(self)

    group.headerContainer = headerContainer
    group.selectedSortHeader= nil
    group.sortDirection = ZO_SORT_ORDER_DOWN
    group.sortHeaders = {}
    group.enabled = true

    group.showArrows = showArrows or false
    if(group.showArrows) then
        group.arrowTexture = CreateControlFromVirtual(headerContainer:GetName().."Arrow", headerContainer, "ZO_SortHeaderArrow")
    end

    group.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    -- Default Colors
    group:SetColors(ZO_SELECTED_TEXT, ZO_NORMAL_TEXT, ZO_HIGHLIGHT_TEXT, ZO_DISABLED_TEXT)

    return group
end

function ZO_SortHeaderGroup:AddHeader(header)
    -- Header containers may have other elements like backgrounds/textures.  
    -- Only add controls that have a sort key on them.
    if header.key then
        header.sortHeaderGroup = self
        table.insert(self.sortHeaders, header)
    end
end

function ZO_SortHeaderGroup:AddHeadersFromContainer()
    local headerContainer = self.headerContainer
    for i = 1, headerContainer:GetNumChildren() do
        self:AddHeader(headerContainer:GetChild(i))
    end
end

function ZO_SortHeaderGroup:SetColors(selected, normal, highlight, disabled)
    self.selectedColor = selected
    self.normalColor = normal
    self.highlightColor = highlight
    self.disabledColor = disabled
end

local sortArrowAlignments =
{
    [TEXT_ALIGN_LEFT] = function(arrow, header, textWidth) 
                            arrow:SetAnchor(LEFT, header, LEFT, textWidth + SORT_ARROW_OFFSET_X, 0)
                        end,
    [TEXT_ALIGN_RIGHT] =    function(arrow, header, textWidth) 
                                arrow:SetAnchor(LEFT, header, RIGHT, SORT_ARROW_OFFSET_X, 0)
                            end,
    [TEXT_ALIGN_CENTER] =   function(arrow, header, textWidth) 
                                arrow:SetAnchor(LEFT, header, CENTER, textWidth * 0.5 + SORT_ARROW_OFFSET_X, 0)
                            end,
}

local function UpdateArrowTexture(arrow, sortOrder)
    arrow:SetHidden(false)

    if sortOrder == ZO_SORT_ORDER_UP then
        arrow:SetTexture(SORT_ARROW_UP)
    else
        arrow:SetTexture(SORT_ARROW_DOWN)
    end
end

local function UpdateTextOrderingTextures(header, arrow, sortOrder)
    UpdateArrowTexture(arrow, sortOrder)

    local nameControl = GetControl(header, "Name")
    local textWidth = nameControl:GetTextDimensions()
    local alignmentFn = sortArrowAlignments[nameControl:GetHorizontalAlignment()]
    if alignmentFn then
        arrow:ClearAnchors()
        alignmentFn(arrow, nameControl, textWidth)
    end
end

local function UpdateIconOrderingTextures(header, arrow, sortOrder)
    arrow:SetHidden(true)

    if sortOrder == ZO_SORT_ORDER_UP then
        header:GetNamedChild("Icon"):SetTexture(header.sortUpIcon)
    else
        header:GetNamedChild("Icon"):SetTexture(header.sortDownIcon)
    end
end

local function UpdateIconWithArrowOrderingTextures(header, arrow, sortOrder)
    UpdateArrowTexture(arrow, sortOrder)
    arrow:ClearAnchors()
    arrow:SetAnchor(LEFT, header:GetNamedChild("Icon"), RIGHT, header.arrowOffset)
end

local function ResetIconOrderingTexture(header)
    header:GetNamedChild("Icon"):SetTexture(header.icon)
end

function ZO_SortHeaderGroup:SelectHeader(header)
    header.selected = true
    self.selectedSortHeader = header

    if header.isIconHeader then
        if self.showArrows then
            if header.usesArrow then
                UpdateIconWithArrowOrderingTextures(header, self.arrowTexture, self.sortDirection)
            else
                UpdateIconOrderingTextures(header, self.arrowTexture, self.sortDirection)
            end
        end
    else
        if self.showArrows then
            UpdateTextOrderingTextures(header, self.arrowTexture, self.sortDirection)
        end
        header:GetNamedChild("Name"):SetColor(self.selectedColor:UnpackRGBA())
    end
end

function ZO_SortHeaderGroup:DeselectHeader()
    local oldSelectedHeader = self.selectedSortHeader
    if oldSelectedHeader then
        if oldSelectedHeader.isIconHeader then
            if not oldSelectedHeader.usesArrow then
                ResetIconOrderingTexture(oldSelectedHeader)
            end
        else
            oldSelectedHeader:GetNamedChild("Name"):SetColor(self.normalColor:UnpackRGBA())
        end

        oldSelectedHeader.selected = nil
        self.selectedSortHeader = nil
    end
end

function ZO_SortHeaderGroup:IsCurrentSelectedHeader(header)
    return self.selectedSortHeader == header
end

function ZO_SortHeaderGroup:OnHeaderClicked(header, suppressCallbacks, forceReselect, forceSortDirection)
    if self:IsEnabled() then
        local resetSortDir = false
        if forceReselect or not self:IsCurrentSelectedHeader(header) then
            self:DeselectHeader()
            resetSortDir = true
        end

        if forceSortDirection ~= nil then
            self.sortDirection = forceSortDirection
        elseif resetSortDir then
            self.sortDirection = header.initialDirection
        else
            self.sortDirection = not self.sortDirection
        end

        self:SelectHeader(header)

        if not suppressCallbacks then
            self:FireCallbacks(self.HEADER_CLICKED, header.key, self.sortDirection)
        end
    end
end

function ZO_SortHeaderGroup:HeaderForKey(key)
    for _, header in ipairs(self.sortHeaders) do
        if header.key == key then
            return header
        end
    end
end

function ZO_SortHeaderGroup:SelectHeaderByKey(key, suppressCallbacks, forceReselect, forceSortDirection)
    local header = self:HeaderForKey(key)
    if header then
        self:OnHeaderClicked(header, suppressCallbacks, forceReselect, forceSortDirection)
    end
end

function ZO_SortHeaderGroup:SetHeaderHiddenForKey(key, hidden)
    local header = self:HeaderForKey(key)
    if header then
        header:SetHidden(hidden)
    end
end

function ZO_SortHeaderGroup:ReplaceKey(curKey, newKey, newText, selectNewKey)
    local header = self:HeaderForKey(curKey)

    if header then
        header.key = newKey
        if newText then
            self:SetHeaderNameForKey(newKey, newText)
        end

        if selectNewKey or self.selectedSortHeader == header then
            self:SelectAndResetSortForKey(newKey)
            self:MakeSelectedSortHeaderSelectedIndex()
        end
    end
end

-- selects the sort header for the key passed in and will use the initial sort direction for that key instead
-- of toggling the current sort direction
function ZO_SortHeaderGroup:SelectAndResetSortForKey(key)
    local header = self:HeaderForKey(key)
    if header then
        local DONT_SUPPRESS_CALLBACKS = false
        local FORCE_RESELECT = true
        self:SelectHeaderByKey(key, DONT_SUPPRESS_CALLBACKS, FORCE_RESELECT)
    end
end

-- Sets the headers in keyList to whatever the value of "hidden" is, sets the rest to "not hidden"
-- keyList is indexed by key.
function ZO_SortHeaderGroup:SetHeadersHiddenFromKeyList(keyList, hidden)
    for _, header in ipairs(self.sortHeaders) do
        local shouldHide = keyList[header.key]
        if shouldHide and type(shouldHide) == "function" then
            shouldHide = shouldHide()
        end
        local hideHeader = shouldHide and hidden
        header:SetHidden(hideHeader)
    end
end

function ZO_SortHeaderGroup:SetHeaderNameForKey(key, name)
    local header = self:HeaderForKey(key)
    if header then
        header:GetNamedChild("Name"):SetText(name)
    end
end

function ZO_SortHeader_Initialize(control, name, key, initialDirection, alignment, font, highlightTemplate)
    local nameControl = GetControl(control, "Name")

    if font then
        nameControl:SetFont(font)
    end

    nameControl:SetText(name)
    nameControl:SetHorizontalAlignment(alignment or TEXT_ALIGN_CENTER)
    control.key = key
    control.initialDirection = initialDirection or ZO_SORT_ORDER_DOWN
    control.usesArrow = true
    control.highlightTemplate = highlightTemplate
end

function ZO_SortHeader_InitializeIconHeader(control, icon, sortUpIcon, sortDownIcon, mouseoverIcon, key, initialDirection)
    control:GetNamedChild("Icon"):SetTexture(icon)
    local mouseOver = control:GetNamedChild("Mouseover")
    mouseOver:SetTexture(mouseoverIcon)
    mouseOver:SetHidden(true)

    control.icon = icon
    control.sortUpIcon = sortUpIcon
    control.sortDownIcon = sortDownIcon

    control.key = key
    control.initialDirection = initialDirection or ZO_SORT_ORDER_DOWN
    control.isIconHeader = true
end

function ZO_SortHeader_InitializeIconWithArrowHeader(control, icon, mouseoverIcon, arrowOffset, key, initialDirection)
    ZO_SortHeader_InitializeIconHeader(control, icon, nil, nil, mouseoverIcon, key, initialDirection)
    control.usesArrow = true
    control.arrowOffset = arrowOffset
end

function ZO_SortHeader_InitializeArrowHeader(control, key, initialDirection)
    ZO_SortHeader_InitializeIconHeader(control, "EsoUI/Art/Miscellaneous/list_sortHeader_icon_neutral.dds", 
                                                "EsoUI/Art/Miscellaneous/list_sortHeader_icon_sortUp.dds", 
                                                "EsoUI/Art/Miscellaneous/list_sortHeader_icon_sortDown.dds", 
                                                "EsoUI/Art/Miscellaneous/list_sortHeader_icon_over.dds", key, initialDirection)
end

function ZO_SortHeader_SetTooltip(control, tooltipText, point, offsetX, offsetY)
    control.tooltipText = tooltipText
    control.tooltipPoint = point or BOTTOM
    control.tooltipOffsetX = offsetX or 0
    control.tooltipOffsetY = offsetY or -5
end

local function UpdateMouseoverState(group, control, isGroupEnabled)
    local mouseIsOver = control.mouseIsOver

    if control.isIconHeader then
        control:GetNamedChild("Mouseover"):SetHidden(not mouseIsOver)
    else
        local color = group.disabledColor

        if isGroupEnabled then
            if mouseIsOver then
                color = group.highlightColor
            else
                color = control.selected and group.highlightColor or group.normalColor
            end
        end

        control:GetNamedChild("Name"):SetColor(color:UnpackRGBA())
    end

    if control.tooltipText then
        if mouseIsOver then
            InitializeTooltip(InformationTooltip, control, control.tooltipPoint, control.tooltipOffsetX, control.tooltipOffsetY)
            SetTooltipText(InformationTooltip, control.tooltipText)
        else
            ClearTooltip(InformationTooltip)
        end
    end
end

function ZO_SortHeader_OnMouseEnter(control)
    control.mouseIsOver = true
    UpdateMouseoverState(control.sortHeaderGroup, control, control.sortHeaderGroup:IsEnabled())
end

function ZO_SortHeader_OnMouseExit(control)
    control.mouseIsOver = false
    UpdateMouseoverState(control.sortHeaderGroup, control, control.sortHeaderGroup:IsEnabled())
end

function ZO_SortHeader_OnMouseUp(control, upInside)
    if upInside and control.sortHeaderGroup then
        control.sortHeaderGroup:OnHeaderClicked(control)
    end
end

function ZO_SortHeaderGroup:SetEnabled(enabled)
    self.enabled = enabled

    for _, control in ipairs(self.sortHeaders) do
        UpdateMouseoverState(self, control, enabled)
    end
end

function ZO_SortHeaderGroup:IsEnabled()
    return self.enabled
end

local function PlayAnimationOnControl(control, controlTemplate, animationFieldName)
    if controlTemplate then
        if not control[animationFieldName] then
            local highlight = CreateControlFromVirtual("$(parent)Scroll", control, controlTemplate, animationFieldName)
            control[animationFieldName] = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
        end
        control[animationFieldName]:PlayForward()
    end
end

local function RemoveAnimationOnControl(control, animationFieldName)
    if control[animationFieldName] then
        control[animationFieldName]:PlayBackward()
    end
end

local function HighlightControl(self, control)
    local highlightTemplate = control.highlightTemplate or self.highlightTemplate
    PlayAnimationOnControl(control, highlightTemplate, "HighlightAnimation")

    if self.highlightCallback then
        self.highlightCallback(control, true)
    end
end

local function UnhighlightControl(self, control) 
    RemoveAnimationOnControl(control, "HighlightAnimation")

    if self.highlightCallback then
        self.highlightCallback(control, false)
    end
end

function ZO_SortHeaderGroup:EnableSelection(enabled)
    self.selectionEnabled = enabled
    if enabled then
        self:SetSelectedIndex(self.selectedIndex or 1)
    else
        self:SetSelectedIndex(nil)
    end
    
end

function ZO_SortHeaderGroup:EnableHighlight(highlightTemplate, highlightCallback)
    if not self.highlightTemplate then
        self.highlightTemplate = highlightTemplate
        self.highlightCallback = highlightCallback
    end
end

function ZO_SortHeaderGroup:SetDirectionalInputEnabled(enabled)
    self.directionalInputEnabled = enabled
    if enabled then
        DIRECTIONAL_INPUT:Activate(self, self.headerContainer)
    else
        DIRECTIONAL_INPUT:Deactivate(self)
    end
end

function ZO_SortHeaderGroup:UpdateDirectionalInput()
    -- No need to check the directional input (and consume it so no one else can use it)
    -- if we don't have multiple headers to switch between
    if #self.sortHeaders > 1 then
        local result = self.movementController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            self:MoveNext()
        elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            self:MovePrevious()
        end
    end
end

function ZO_SortHeaderGroup:SetSelectedIndex(selectedIndex)
    if self.selectedIndex then
        local previousSelectedControl = self.sortHeaders[self.selectedIndex]
        UnhighlightControl(self, previousSelectedControl)
    end

    if not selectedIndex then
        return
    end

    if #self.sortHeaders <= 0 then
        return
    end

    selectedIndex = zo_clamp(selectedIndex, 1, #self.sortHeaders)
    local selectedControl = self.sortHeaders[selectedIndex]
    HighlightControl(self, selectedControl)
    self.selectedIndex = selectedIndex
end

function ZO_SortHeaderGroup:MakeSelectedSortHeaderSelectedIndex()
    if self.selectedSortHeader then
        for index, header in ipairs(self.sortHeaders) do
            if header == self.selectedSortHeader then
                self:SetSelectedIndex(index)
                break
            end
        end
    end
end

do
    local CHECK_FORWARD = 1
    local CHECK_BACKWARD = -1

    --On Gamepad, we need to check for and ignore hidden headers
    function ZO_SortHeaderGroup:FindNextActiveHeaderIndex(checkDirection)
        local checkIndex = self.selectedIndex
        local activeHeaderFound = false
        while not activeHeaderFound do
            checkIndex = checkIndex + checkDirection
            local checkControl = self.sortHeaders[checkIndex]
            if checkControl then
                activeHeaderFound = not checkControl:IsHidden()
            else
                break
            end
        end
        return activeHeaderFound and checkIndex or self.selectedIndex
    end

    function ZO_SortHeaderGroup:MovePrevious()
        local previousActiveIndex = self:FindNextActiveHeaderIndex(CHECK_BACKWARD)
        self:SetSelectedIndex(self.selectedIndex and previousActiveIndex)
    end

    function ZO_SortHeaderGroup:MoveNext()
        local nextActiveIndex = self:FindNextActiveHeaderIndex(CHECK_FORWARD)
        self:SetSelectedIndex(self.selectedIndex and nextActiveIndex)
    end
end

function ZO_SortHeaderGroup:GetSelectedData()
end

function ZO_SortHeaderGroup:GetCurrentSortKey()
    return self.selectedSortHeader and self.selectedSortHeader.key
end

function ZO_SortHeaderGroup:GetSortDirection()
    return self.sortDirection
end

function ZO_SortHeaderGroup:SortBySelected()
    if not self.selectedIndex then return end
    local selectedControl = self.sortHeaders[self.selectedIndex]

    self:OnHeaderClicked(selectedControl)
end