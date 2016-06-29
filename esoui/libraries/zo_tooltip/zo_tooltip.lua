--Tooltip Style
------------------------------

local DEFAULT_TEXTURE_SIZE = 24

function ZO_Tooltip_CopyStyle(style)
    return ZO_ShallowTableCopy(style)
end

--Tooltips Properties
--layoutPrimaryDirection - The direction the controls are laid out in: "up", "down", "left", "right."
--layoutPrimaryDirectionCentered - If true, and the primary direction is fixed (for example, you're laying out controls to the left and the width is fixed) the controls are centered in the space.
--layoutSecondaryDirection - The direction the layout moves when the primary direction is filled. For example, after you fill a horizontal line it will advance vertically. "up", "down", "left", "right."
--width - Fixed width. "auto" sets the width to 0 for auto sizing labels.
--widthPercent - Fixed width as a percent of it's parent's inner width.
--height - Fixed height.
--heightPercent - Fixed height as a percent of it's parent's inner height.
--childSpacing - Space between each control that is added to a section.
--customSpacing - Custom space above the control.
--fontFace - Font face.
--fontSize - Font size.
--horizontalAlignment - The horizontal alignment of a label
--fontColorField, fontColorType - Interface color to set on the label
--padding, paddingLeft, paddingRight, paddingTop, paddingBottom - Extra unused space in a section. Consumes the fixed dimension space. For example, if width was 100 and padding 10, then there are
--                                                                80 UI units of space (100 - 10 * 2) to add controls.
--uppercase - Renders the text in uppercase if set to true.
--statValuePairSpacing - Spacing between the stat name and the value in a stat value pair.
--statusBarTemplate - Template used to create a status bar.
--desaturation - Sets the desaturation of textures.
--tint - Sets a tint color that is used with textures.
--dimensionConstraints - provides restrictions on the minimum or maximum width or height of a sections. This should be a table with
-- some combination of minHeight, maxHeight, minWidth, and maxWidth set. Any combination may be nil. This property is not inherited
-- by children.

--Tooltip Styled Object
------------------------------

ZO_TooltipStyledObject = {}

function ZO_TooltipStyledObject:Initialize(parent)
    self.parent = parent
end

function ZO_TooltipStyledObject:GetParent()
    return self.parent
end

function ZO_TooltipStyledObject:GetProperty(propertyName, ...)
    local propertyValue = self:GetPropertyNoChain(propertyName, ...)
    if(propertyValue ~= nil) then
        return propertyValue
    end

    local section = self
    while(section ~= nil) do
        local styles = section:GetStyles()
        if(styles) then
            propertyValue = self:GetPropertyNoChain(propertyName, unpack(styles))
            if(propertyValue ~= nil) then
                return propertyValue
            end
        end
        section = section:GetParent()
    end
end

function ZO_TooltipStyledObject:GetPropertyNoChain(propertyName, ...)
    for i = 1, select("#", ...) do
        local style = select(i, ...)
        if(style) then
            local propertyValue = style[propertyName]
            if(propertyValue ~= nil) then
                return propertyValue
            end
        end
    end
end

--where ... is the list of styles
function ZO_TooltipStyledObject:GetFontString(...)
    local fontFace = self:GetProperty("fontFace", ...)
    local fontSize = self:GetProperty("fontSize", ...)
    local fontStyle = self:GetProperty("fontStyle", ...)
    if(fontFace and fontSize) then
        if type(fontSize) == "number" then
            fontSize = tostring(fontSize)
        end
        if(fontStyle) then
            return string.format("%s|%s|%s", fontFace, fontSize, fontStyle)
        else
            return string.format("%s|%s", fontFace, fontSize)
        end
    else
        return "ZoFontGame"
    end
end

--where ... is the list of styles
function ZO_TooltipStyledObject:FormatLabel(label, text, ...)
    local fontString = self:GetFontString(...)
    if(fontString ~= label.fontString) then
        label:SetFont(fontString)
        label.fontString = fontString
    end
    local uppercase = self:GetProperty("uppercase", ...)
    label:SetModifyTextType(uppercase and MODIFY_TEXT_TYPE_UPPERCASE or MODIFY_TEXT_TYPE_NONE)
    label:SetText(text)
    local interfaceColor = self:GetProperty("fontColor", ...)
    if interfaceColor then
        label:SetColor(interfaceColor:UnpackRGBA())
    else
        local interfaceColorField = self:GetProperty("fontColorField", ...)
        if(interfaceColorField ~= nil) then
            local interfaceColorType = self:GetProperty("fontColorType", ...)
            if(interfaceColorType ~= nil) then        
                label:SetColor(GetInterfaceColor(interfaceColorType, interfaceColorField))
            end
        end
    end
    local interfaceHorizontalAlignmentField = self:GetProperty("horizontalAlignment", ...)
    if(interfaceHorizontalAlignmentField ~= nil) then
        label:SetHorizontalAlignment(interfaceHorizontalAlignmentField)
    else
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    end
end

--where ... is the list of styles
function ZO_TooltipStyledObject:FormatTexture(texture, path, ...)
    texture:SetTexture(path)
end

--where ... is the list of styles
function ZO_TooltipStyledObject:GetWidthProperty(...)
    local width = self:GetPropertyNoChain("width", ...)
    if(width == nil) then
        local widthPercent = self:GetPropertyNoChain("widthPercent", ...)
        if(widthPercent) then
            if(self.parent) then
                if(self.parent:IsVertical()) then
                    width = self.parent:GetInnerSecondaryDimension()
                else
                    width = self.parent:GetInnerPrimaryDimension()
                end
                width = width * (widthPercent / 100)
            end
        end
    end
    return width
end

--where ... is the list of styles
function ZO_TooltipStyledObject:GetHeightProperty(...)
    local height = self:GetPropertyNoChain("height", ...)
    if(height == nil) then
        local heightPercent = self:GetPropertyNoChain("heightPercent", unpack(self.styles))
        if(heightPercent) then
            if(self.parent) then
                if(self.parent:IsVertical()) then
                    height = self.parent:GetInnerPrimaryDimension()
                else
                    height = self.parent:GetInnerSecondaryDimension()
                end
                height = height * (heightPercent / 100)
            end
        end
    end
    return height
end

function ZO_TooltipStyledObject:GetStyles()
    return self.styles
end

function ZO_TooltipStyledObject:SetStyles(...)    
    self.styles = {...}
    self:ApplyStyles()    
end

function ZO_TooltipStyledObject:ApplyStyles()

end

--Tooltip Stat Value Pair
------------------------------

local ZO_TooltipStatValuePair = {}

function ZO_TooltipStatValuePair:Initialize(parent)
    ZO_TooltipStyledObject.Initialize(self, parent)
    self.statLabel = self:GetNamedChild("Stat")
    self.valueLabel = self:GetNamedChild("Value")
    -- in case the width was set in ComputeDimensions, reset it so it can dynamically resize again
    self.valueLabel:SetWidth(0)
end

--where ... is a list of styles
function ZO_TooltipStatValuePair:SetStat(statText, ...)
    self:FormatLabel(self.statLabel, statText, ...)
    self:SetDimensions(self:ComputeDimensions())
end

--where ... is a list of styles
function ZO_TooltipStatValuePair:SetValue(valueText, ...)
    self:FormatLabel(self.valueLabel, valueText, ...)
    local spacing = self:GetProperty("statValuePairSpacing") or 5
    self.valueLabel:ClearAnchors()
    self.valueLabel:AnchorToBaseline(self:GetNamedChild("Stat"), spacing, RIGHT)
    self:SetDimensions(self:ComputeDimensions())
end

function ZO_TooltipStatValuePair:ComputeDimensions()
    local spacing = self:GetProperty("statValuePairSpacing") or 5
    local statWidth, statHeight = self.statLabel:GetTextDimensions()
    local valueWidth, valueHeight = self.valueLabel:GetTextDimensions()
    local height = self:GetHeightProperty(unpack(self.styles))
    
    local width = self:GetWidthProperty(unpack(self.styles))
    if(width == nil) then
        width = statWidth + spacing + valueWidth
    else
        self.valueLabel:SetWidth(width - spacing - statWidth)
        valueWidth, valueHeight = self.valueLabel:GetTextDimensions() -- Recompute because line wrapping could cause the height to change
    end

    if(height == nil) or (valueHeight > height) then
        height = zo_max(statHeight, valueHeight)
    end

    return width, height
end

function ZO_TooltipStatValuePair:UpdateFontOffset()
    local statTop = self.statLabel:GetTop()
    local valueTop = self.valueLabel:GetTop()

    if statTop ~= valueTop then
        local heightDifference = statTop - valueTop
        local isValid, point, relTo, relPoint, offsetX = self.statLabel:GetAnchor()
        self.statLabel:SetAnchor(point, relTo, relPoint, offsetX, heightDifference)
    end
end

--Tooltip Stat Value Slider
------------------------------

local ZO_TooltipStatValueSlider = {}

function ZO_TooltipStatValueSlider:Initialize(parent)
    ZO_TooltipStyledObject.Initialize(self, parent)
    self.nameLabel = self:GetNamedChild("Stat")
    self.valueLabel = self:GetNamedChild("Value")
    self.slider = self:GetNamedChild("Slider")
    self.sliderBar = self.slider:GetNamedChild("Bar")
end

--where ... is a list of styles
function ZO_TooltipStatValueSlider:SetStat(statText, ...)
    self:FormatLabel(self.nameLabel, statText, ...)
    self:SetDimensions(self:ComputeDimensions())
end

--where ... is a list of styles
function ZO_TooltipStatValueSlider:SetValue(value, maxValue, valueText, ...)
    local spacing = self:GetProperty("statValuePairSpacing") or 5
    local gradientColors = self:GetProperty("gradientColors")

    -- Setup the slider.
    local FORCE_VALUE = true
    ZO_StatusBar_SmoothTransition(self.sliderBar, value, maxValue, FORCE_VALUE)
    if gradientColors then
        ZO_StatusBar_SetGradientColor(self.sliderBar, gradientColors)
    end

    -- Setup the label.
    self:FormatLabel(self.valueLabel, valueText, ...)
    self.valueLabel:ClearAnchors()
    self.valueLabel:SetAnchor(TOP, self.nameLabel, TOP)
    self.valueLabel:SetAnchor(LEFT, self.slider, RIGHT, spacing)

    self:SetDimensions(self:ComputeDimensions())
end

function ZO_TooltipStatValueSlider:ComputeDimensions()
    local spacing = self:GetProperty("statValuePairSpacing") or 5
    local statWidth, statHeight = self.nameLabel:GetTextDimensions()
    local valueWidth, valueHeight = self.valueLabel:GetTextDimensions()
    local sliderWidth, sliderHeight = self.slider:GetDimensions()
    local height = self:GetHeightProperty(unpack(self.styles))
    if(height == nil) then
        height = zo_max(statHeight, valueHeight, sliderHeight)
    end
    local width = self:GetWidthProperty(unpack(self.styles))
    if(width == nil) then
        width = statWidth + spacing + valueWidth + spacing + sliderWidth
    end
    return width, height
end

--Tooltip Status Bar

ZO_TooltipStatusBar = {}

function ZO_TooltipStatusBar:ApplyStyles()
    local width = self:GetWidthProperty(unpack(self.styles))
    if(width) then
        self:SetWidth(width)
    end
    local gradientColors = self:GetProperty("statusBarGradientColors")
    if(gradientColors) then
        ZO_StatusBar_SetGradientColor(self, gradientColors)
    end
end

--Tooltip Section
------------------------------

ZO_TooltipSection = {}

function ZO_TooltipSection.InitializeStaticPools(class)
    class.labelPool = ZO_ControlPool:New("ZO_TooltipLabel", GuiRoot, "Label")

    class.texturePool = ZO_ControlPool:New("ZO_TooltipTexture", GuiRoot, "Texture")
    class.colorPool = ZO_ControlPool:New("ZO_TooltipColorSwatch", GuiRoot, "Color")
    class.colorPool:SetCustomFactoryBehavior(function(control)
        control.label = control:GetNamedChild("Label")
        control.backdrop = control:GetNamedChild("Backdrop")
        control.Reset = function()
            control.label:SetText("")
            control:SetColor(1, 1, 1, 1)
        end
    end)
    class.colorPool:SetCustomResetBehavior(function(control)
        control:Reset()
    end)

    class.statValuePairPool = ZO_ControlPool:New("ZO_TooltipStatValuePair", GuiRoot, "StatValuePair")
    class.statValuePairPool:SetCustomFactoryBehavior(function(control)
        zo_mixin(control, ZO_TooltipStyledObject, ZO_TooltipStatValuePair)
    end)

    class.statValueSliderPool = ZO_ControlPool:New("ZO_TooltipStatValueSlider", GuiRoot, "StatValueSlider")
    class.statValueSliderPool:SetCustomFactoryBehavior(function(control)
        zo_mixin(control, ZO_TooltipStyledObject, ZO_TooltipStatValueSlider)
    end)

    class.sectionPool = ZO_ControlPool:New("ZO_TooltipSection", GuiRoot, "Section")
    class.sectionPool:SetCustomFactoryBehavior(function(control)
        zo_mixin(control, ZO_TooltipStyledObject, ZO_TooltipSection)
    end)
    class.sectionPool:SetCustomResetBehavior(function(control)
        control:Reset()
    end)
end

ZO_TooltipSection.InitializeStaticPools(ZO_TooltipSection)

function ZO_TooltipSection:CreateMetaControlPool(sourcePool)
    local metaPool = ZO_MetaPool:New(sourcePool)
    metaPool:SetCustomAcquireBehavior(function(control)
        if control.Initialize then
            control:Initialize(self)
        end
        control:SetParent(self.contentsControl)
    end)
    return metaPool
end

function ZO_TooltipSection:Initialize(parent)
    ZO_TooltipStyledObject.Initialize(self, parent)
    self.contentsControl = self:GetNamedChild("Contents")

    self.labelPool = self:CreateMetaControlPool(ZO_TooltipSection.labelPool)
    self.texturePool = self:CreateMetaControlPool(ZO_TooltipSection.texturePool)
    self.colorPool = self:CreateMetaControlPool(ZO_TooltipSection.colorPool)
    self.statValuePairPool = self:CreateMetaControlPool(ZO_TooltipSection.statValuePairPool)
    self.statValueSliderPool = self:CreateMetaControlPool(ZO_TooltipSection.statValueSliderPool)
    self.sectionPool = self:CreateMetaControlPool(ZO_TooltipSection.sectionPool)

    self.statusBarPools = {}
end

--Style Application

function ZO_TooltipSection:ApplyPadding()
    local padding = self:GetPropertyNoChain("padding", unpack(self.styles))
    self.paddingLeft = self:GetPropertyNoChain("paddingLeft", unpack(self.styles)) or padding or 0
    self.paddingRight = self:GetPropertyNoChain("paddingRight", unpack(self.styles)) or padding or 0
    self.paddingTop = self:GetPropertyNoChain("paddingTop", unpack(self.styles)) or padding or 0
    self.paddingBottom = self:GetPropertyNoChain("paddingBottom", unpack(self.styles)) or padding or 0
    self.contentsControl:ClearAnchors()
    self.contentsControl:SetAnchor(TOPLEFT, nil, TOPLEFT, self.paddingLeft, self.paddingTop)
    self.contentsControl:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -self.paddingRight, -self.paddingBottom)
end

function ZO_TooltipSection:ApplyLayoutVariables()
    local layoutPrimaryDirection =  self:GetPropertyNoChain("layoutPrimaryDirection", unpack(self.styles)) or "down"
    local layoutSecondaryDirection = self:GetPropertyNoChain("layoutSecondaryDirection", unpack(self.styles)) or "right"

    self.primaryCursorDirection = (layoutPrimaryDirection == "down" or layoutPrimaryDirection == "right") and 1 or -1
    self.secondaryCursorDirection = (layoutSecondaryDirection == "down" or layoutSecondaryDirection == "right") and 1 or -1
    self.vertical = (layoutPrimaryDirection == "up" or layoutPrimaryDirection == "down")
    
    local combinedDirection = layoutPrimaryDirection .. layoutSecondaryDirection
    if(combinedDirection == "upleft" or combinedDirection == "leftup") then
        self.layoutRootAnchor = BOTTOMRIGHT
    elseif(combinedDirection == "downleft" or combinedDirection == "leftdown") then
        self.layoutRootAnchor = TOPRIGHT
    elseif(combinedDirection == "upright" or combinedDirection == "rightup") then
        self.layoutRootAnchor = BOTTOMLEFT
    else
        self.layoutRootAnchor = TOPLEFT
    end
end

function ZO_TooltipSection:ApplyStyles()
    self:ApplyLayoutVariables()
    self:ApplyPadding()
    self:Reset()
end

--Reset

function ZO_TooltipSection:SetupPrimaryDimension()
    if(self:IsVertical()) then
        local fixedHeight = self:GetHeightProperty(unpack(self.styles))
        if(fixedHeight ~= nil) then
            self:SetPrimaryDimension(fixedHeight)
            self.innerPrimaryDimension = fixedHeight - self.paddingTop - self.paddingBottom
            self.isPrimaryDimensionFixed = true
        else
            self:SetPrimaryDimension(self.paddingTop + self.paddingBottom)
            self.innerPrimaryDimension = nil
            self.isPrimaryDimensionFixed = false
        end
    else
        local fixedWidth = self:GetWidthProperty(unpack(self.styles))
        if(fixedWidth ~= nil) then
            self:SetPrimaryDimension(fixedWidth)
            self.innerPrimaryDimension = fixedWidth - self.paddingLeft - self.paddingRight
            self.isPrimaryDimensionFixed = true
        else
            self:SetPrimaryDimension(self.paddingLeft + self.paddingRight)
            self.innerPrimaryDimension = nil
            self.isPrimaryDimensionFixed = nil
        end
    end

    if self.isPrimaryDimensionFixed then
        self.isPrimaryDimensionCentered = self:GetPropertyNoChain("layoutPrimaryDirectionCentered", unpack(self.styles)) or false
    else
        self.isPrimaryDimensionCentered = false
    end
end

function ZO_TooltipSection:SetupSecondaryDimension()
    if(self:IsVertical()) then
        local fixedWidth = self:GetWidthProperty(unpack(self.styles))
        if(fixedWidth ~= nil) then
            self:SetSecondaryDimension(fixedWidth)
            self.innerSecondaryDimension = fixedWidth - self.paddingLeft - self.paddingRight
            self.isSecondaryDimensionFixed = true
        else
            self:SetSecondaryDimension(self.paddingLeft + self.paddingRight)
            self.innerSecondaryDimension = nil
            self.isSecondaryDimensionFixed = false
        end
    else
        local fixedHeight = self:GetHeightProperty(unpack(self.styles))
        if(fixedHeight ~= nil) then
            self:SetSecondaryDimension(fixedHeight)
            self.innerSecondaryDimension = fixedHeight - self.paddingTop - self.paddingBottom
            self.isSecondaryDimensionFixed = true
        else
            self:SetSecondaryDimension(self.paddingTop + self.paddingBottom)
            self.innerSecondaryDimension = nil
            self.isSecondaryDimensionFixed = false
        end
    end
end

function ZO_TooltipSection:Reset()
    self.primaryCursor = 0
    self.secondaryCursor = 0
    self.numControls = 0
    self.firstInLine = true
    self.maxSecondarySizeOnLine = 0
    self.customNextSpacing = nil
    self:SetupPrimaryDimension()
    self:SetupSecondaryDimension()
    self.labelPool:ReleaseAllObjects()
    self.texturePool:ReleaseAllObjects()
    self.colorPool:ReleaseAllObjects()
    self.sectionPool:ReleaseAllObjects()
    self.statValuePairPool:ReleaseAllObjects()
    self.statValueSliderPool:ReleaseAllObjects()
    for _, pool in pairs(self.statusBarPools) do
        pool:ReleaseAllObjects()
    end
end

--Layout Variables

function ZO_TooltipSection:IsVertical()
    return self.vertical
end

function ZO_TooltipSection:IsPrimaryDimensionFixed()
    return self.isPrimaryDimensionFixed
end

function ZO_TooltipSection:IsSecondaryDimensionFixed()
    return self.isSecondaryDimensionFixed
end

function ZO_TooltipSection:SetNextSpacing(spacing)
    self.customNextSpacing = spacing
end

--where ... is the list of styles
function ZO_TooltipSection:GetNextSpacing(...)
    local customNextSpacing = self.customNextSpacing
    if(customNextSpacing == nil) then
        customNextSpacing = self:GetPropertyNoChain("customSpacing", ...)
    end
    self.customNextSpacing = nil

    if(self.firstInLine) then       
       return customNextSpacing or 0
    else       
        local nextSpacing = customNextSpacing or self:GetProperty("childSpacing") or 0
        return nextSpacing
    end
end

function ZO_TooltipSection:GetDimensionWithContraints(base, useHeightContraint)
    local constraints = self:GetPropertyNoChain("dimensionConstraints", unpack(self.styles))
    if not constraints then
        return base
    end

    local min, max
    if useHeightContraint then
        min = constraints.minHeight
        max = constraints.maxHeight
    else
        min = constraints.minWidth
        max = constraints.maxWidth
    end

    min = min or base
    max = max or base
    return zo_clamp(base, min, max)
end

function ZO_TooltipSection:GetPrimaryDimension()
    return self:GetDimensionWithContraints(self.primaryDimension, self:IsVertical())
end

function ZO_TooltipSection:GetInnerPrimaryDimension()
    return self.innerPrimaryDimension
end

function ZO_TooltipSection:SetPrimaryDimension(size)
    if(self:IsVertical()) then
        self:SetHeight(size)
    else
        self:SetWidth(size)
    end
    self.primaryDimension = size
end

function ZO_TooltipSection:AddToPrimaryDimension(amount)
    self:SetPrimaryDimension(self.primaryDimension + amount)
end

function ZO_TooltipSection:GetSecondaryDimension()
    return self:GetDimensionWithContraints(self.secondaryDimension, not self:IsVertical())
end

function ZO_TooltipSection:GetInnerSecondaryDimension()
    return self.innerSecondaryDimension
end

function ZO_TooltipSection:SetSecondaryDimension(size)
    if(self:IsVertical()) then
        self:SetWidth(size)
    else
        self:SetHeight(size)
    end
    self.secondaryDimension = size
end

function ZO_TooltipSection:AddToSecondaryDimension(amount)
    self:SetSecondaryDimension(self.secondaryDimension + amount)
end

function ZO_TooltipSection:GetNumControls()
    return self.numControls
end

function ZO_TooltipSection:HasControls()
    return self.numControls > 0
end

function ZO_TooltipSection:SetPoolKey(poolKey)
    self.poolKey = poolKey
end

function ZO_TooltipSection:GetPoolKey()
    return self.poolKey
end

--Layout

--where ... is the list of styles
function ZO_TooltipSection:ShouldAdvanceSecondaryCursor(primarySize, spacingSize)
    if(self:IsPrimaryDimensionFixed()) then
        return self.primaryCursor + spacingSize + primarySize > self.innerPrimaryDimension
    end
    return false
end

function ZO_TooltipSection:AddControl(control, primarySize, secondarySize, ...)
    control:SetParent(self.contentsControl)
    local spacing = self:GetNextSpacing(...)
    control:ClearAnchors()
    if(self:ShouldAdvanceSecondaryCursor(primarySize, spacing)) then
        local advanceAmount = self.maxSecondarySizeOnLine + (self:GetProperty("childSecondarySpacing") or 0)
        self.secondaryCursor = self.secondaryCursor + advanceAmount
        if(not self:IsSecondaryDimensionFixed()) then
            self:AddToSecondaryDimension(advanceAmount)
        end
        self.maxSecondarySizeOnLine = 0
        self.primaryCursor = 0
        self.firstInLine = true
        spacing = self:GetNextSpacing(...)
    end
    self.primaryCursor = self.primaryCursor + spacing
    self.maxSecondarySizeOnLine = zo_max(self.maxSecondarySizeOnLine, secondarySize)
    if(not self:IsSecondaryDimensionFixed()) then
        if(self:IsVertical()) then
            self:SetSecondaryDimension(self.maxSecondarySizeOnLine + self.secondaryCursor + self.paddingLeft + self.paddingRight)
        else
            self:SetSecondaryDimension(self.maxSecondarySizeOnLine + self.secondaryCursor + self.paddingTop + self.paddingBottom)
        end
    end
    local offsetX = self:IsVertical() and self.secondaryCursor * self.secondaryCursorDirection or self.primaryCursor * self.primaryCursorDirection
    local offsetY = self:IsVertical() and self.primaryCursor * self.primaryCursorDirection or self.secondaryCursor * self.secondaryCursorDirection
    control.offsetX = offsetX
    control.offsetY = offsetY
    if(not self.isPrimaryDimensionCentered) then
        control:SetAnchor(self.layoutRootAnchor, nil, self.layoutRootAnchor, offsetX, offsetY)
    end

    if(not self:IsPrimaryDimensionFixed()) then
        self:AddToPrimaryDimension(primarySize + spacing)
    end
    self.primaryCursor = self.primaryCursor + primarySize
    self.numControls = self.numControls + 1
    self.firstInLine = false

    if(self.isPrimaryDimensionCentered) then
        local centerOffsetPrimary = ((self.innerPrimaryDimension - self.primaryCursor) / 2) * self.primaryCursorDirection
        for i = 1, self.contentsControl:GetNumChildren() do
            local childControl = self.contentsControl:GetChild(i)
			local childSecondaryOffset = self:IsVertical() and childControl.offsetX or childControl.offsetY
            if childSecondaryOffset == self.secondaryCursor then
                local modifiedOffsetX = childControl.offsetX + (self:IsVertical() and 0 or centerOffsetPrimary)
                local modifiedOffsetY = childControl.offsetY + (self:IsVertical() and centerOffsetPrimary or 0)
                childControl:SetAnchor(self.layoutRootAnchor, nil, self.layoutRootAnchor, modifiedOffsetX, modifiedOffsetY)
            end
        end
    end
end

function ZO_TooltipSection:AddDimensionedControl(control)
    local width, height = control:GetDimensions()
    if(self:IsVertical()) then
        self:AddControl(control, height, width, unpack(control:GetStyles()))
    else
        self:AddControl(control, width, height, unpack(control:GetStyles()))
    end
end

--where ... is the list of styles
function ZO_TooltipSection:AddLine(text, ...)

    local customFunction =
        function(label, ...)
            self:FormatLabel(label, text, ...)
        end

    self:AddCustom(customFunction, ...)
end

function ZO_TooltipSection:AddCustom(customFunction, ...)
    local label = self.labelPool:AcquireObject()

    customFunction(label, ...)

    local widthProperty = self:GetWidthProperty(...)
    local width = widthProperty
    if(width == "auto" or (width == nil and not self:IsVertical())) then
        width = 0
    elseif(width == nil and self:IsVertical()) then
        width = self:GetInnerSecondaryDimension()
    end
    label:SetWidth(width)

    -- If the width of height property is set to a non-zero size, use that rather than the actual size
    --  of the text. This allows for fixed-width labels to be used in tooltips.
    local heightProperty = self:GetHeightProperty(...)
    local controlWidth, controlHeight = label:GetTextDimensions()
    if (type(widthProperty) == "number") and (widthProperty ~= 0) then
        controlWidth = widthProperty
    end
    if (type(heightProperty) == "number") and (heightProperty ~= 0)  then
        controlHeight = heightProperty
    end

    if(self:IsVertical()) then
        self:AddControl(label, controlHeight, controlWidth, ...)
    else
        self:AddControl(label, controlWidth, controlHeight, ...)
    end
end

function ZO_TooltipSection:AddSimpleCurrency(currencyType, amount, options, showAll, notEnough, ...)
    local customFunction =
        function(label, ...)
            self:FormatLabel(label, "", ...)        -- This is so it uses the correct styling
            ZO_CurrencyControl_SetSimpleCurrency(label, currencyType, amount, options, showAll, notEnough)
        end

    self:AddCustom(customFunction, ...)
end

function ZO_TooltipSection:BasicTextureSetup(texture, ...)
    local width = self:GetWidthProperty(...)
    if(width == nil or width == 0) then
        -- Set default width
        width = DEFAULT_TEXTURE_SIZE
    end
    texture:SetWidth(width)

    local height = self:GetHeightProperty(...)
    if(height == nil or height == 0) then
        -- Set default height
        height = DEFAULT_TEXTURE_SIZE
    end
    texture:SetHeight(height)

    if(self:IsVertical()) then
        self:AddControl(texture, height, width, ...)
    else
        self:AddControl(texture, width, height, ...)
    end
end

--where ... is the list of styles
function ZO_TooltipSection:AddTexture(path, ...)
    local texture = self.texturePool:AcquireObject()
    self:FormatTexture(texture, path, ...)

    local desaturation = self:GetProperty("desaturation", ...) or 0
    texture:SetDesaturation(desaturation)

    local color = self:GetProperty("color", ...)
    if color then
        texture:SetColor(color:UnpackRGBA())
    else
        texture:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    end

    local left = self:GetProperty("textureCoordinateLeft", ...) or 0
    local right = self:GetProperty("textureCoordinateRight", ...) or 1
    local top = self:GetProperty("textureCoordinateTop", ...) or 0
    local bottom = self:GetProperty("textureCoordinateBottom", ...) or 1
    texture:SetTextureCoords(left, right, top, bottom)

    self:BasicTextureSetup(texture, ...)
end

--where ... is the list of styles
function ZO_TooltipSection:AddColorSwatch(r, g, b, a, ...)
   self:AddColorAndTextSwatch(r, g, b, a, "", ...)
end

--where ... is the list of styles
function ZO_TooltipSection:AddColorAndTextSwatch(r, g, b, a, text, ...)
    local control = self.colorPool:AcquireObject()

    control:SetColor(r, g, b, a)

    local edgeTextureFile = self:GetProperty("edgeTextureFile", ...)
    local edgeTextureWidth = self:GetProperty("edgeTextureWidth", ...)
    local edgeTextureHeight = self:GetProperty("edgeTextureHeight", ...)
    if edgeTextureFile and edgeTextureWidth and edgeTextureHeight then
        control.backdrop:SetHidden(false)
        control.backdrop:SetEdgeTexture(edgeTextureFile, edgeTextureWidth, edgeTextureHeight)
    else
        control.backdrop:SetHidden(true)
    end

    self:FormatLabel(control.label, zo_strformat(SI_ITEM_FORMAT_STR_COLOR_NAME, text), ...)

    self:BasicTextureSetup(control, ...)
end

function ZO_TooltipSection:AddSectionEvenIfEmpty(section)
    if(self:IsVertical()) then
        if(section:IsVertical()) then
            self:AddControl(section, section:GetPrimaryDimension(), section:GetSecondaryDimension(), unpack(section:GetStyles()))
        else
            self:AddControl(section, section:GetSecondaryDimension(), section:GetPrimaryDimension(), unpack(section:GetStyles()))
        end
    else
        if(section:IsVertical()) then
            self:AddControl(section, section:GetSecondaryDimension(), section:GetPrimaryDimension(), unpack(section:GetStyles()))
        else
            self:AddControl(section, section:GetPrimaryDimension(), section:GetSecondaryDimension(), unpack(section:GetStyles()))
        end
    end
end

function ZO_TooltipSection:AddSection(section)
    if(not section:HasControls()) then
        self:ReleaseSection(section)
        return
    end

    self:AddSectionEvenIfEmpty(section)
end

--where ... is the list of styles
function ZO_TooltipSection:AcquireSection(...)
    local section, key = self.sectionPool:AcquireObject()
    section:SetPoolKey(key)
    section:SetStyles(...)
    return section
end

function ZO_TooltipSection:ReleaseSection(section)
    self.sectionPool:ReleaseObject(section:GetPoolKey())
end

--where ... is the list of styles
function ZO_TooltipSection:AcquireStatValuePair(...)
    local statValuePair = self.statValuePairPool:AcquireObject()
    statValuePair:SetStyles(...)
    return statValuePair
end

function ZO_TooltipSection:AcquireStatValueSlider(...)
    local statValueSlider = self.statValueSliderPool:AcquireObject()
    statValueSlider:SetStyles(...)
    return statValueSlider
end

function ZO_TooltipSection:AddStatValuePair(statValuePair)    
    self:AddDimensionedControl(statValuePair)
    statValuePair:UpdateFontOffset()
end

function ZO_TooltipSection:AcquireStatusBar(...)
    local template = self:GetProperty("statusBarTemplate", ...)
    local pool = self.statusBarPools[template]
    if(not pool) then
        pool = ZO_ControlPool:New(template, self.contentsControl, self:GetProperty("statusBarTemplateOverrideName", ...))
        pool:SetCustomFactoryBehavior(function(control)
            zo_mixin(control, ZO_TooltipStyledObject, ZO_TooltipStatusBar)
            control:Initialize(self)
        end)
        self.statusBarPools[template] = pool
    end
    local bar = pool:AcquireObject()
    bar:SetStyles(...)
    return bar
end

function ZO_TooltipSection:AddStatusBar(statusBar)
    self:AddDimensionedControl(statusBar)
end

--Tooltip
------------------------------

ZO_Tooltip = {}

function ZO_Tooltip:Initialize(control, styleNamespace, style)
    zo_mixin(control, ZO_TooltipStyledObject, ZO_TooltipSection, self)    
    ZO_TooltipSection.Initialize(control)
    control.styleNamespace = styleNamespace
    control:SetStyles(control:GetStyle(style or "tooltip"))
    control:SetClearOnHidden(true)
end

function ZO_Tooltip:SetClearOnHidden(clearOnHidden)
    if clearOnHidden then
        self:SetHandler("OnEffectivelyHidden", function()
            self:Reset()
        end)
    else
        self:SetHandler("OnEffectivelyHidden", nil)
    end
end

local RELATIVE_POINT_FROM_POINT =
{
    [TOP] = BOTTOM,
    [TOPRIGHT] = TOPLEFT,
    [RIGHT] = LEFT,
    [BOTTOMRIGHT] = BOTTOMLEFT,
    [BOTTOM] = TOP,
    [BOTTOMLEFT] = BOTTOMRIGHT,
    [LEFT] = RIGHT,
    [TOPLEFT] = TOPRIGHT,
}

function ZO_Tooltip:SetOwner(owner, point, offsetX, offsetY, relativePoint)
    self.owner = owner
    if(owner) then
        self:ClearAnchors()
        if(relativePoint == nil) then
            relativePoint = RELATIVE_POINT_FROM_POINT[point]
        end
        self:SetAnchor(point, owner, relativePoint, offsetX or 0, offsetY or 0)
    end
end

function ZO_Tooltip:ClearLines()
    self:Reset()
end

function ZO_Tooltip:GetStyle(styleName)
    return self.styleNamespace[styleName]
end