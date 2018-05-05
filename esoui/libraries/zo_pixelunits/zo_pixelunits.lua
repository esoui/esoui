--Pixel Unit Control
-----------------------

PIXEL_SOURCE_PIXELS = 1
PIXEL_SOURCE_UI_UNITS = 2
PIXEL_SOURCE_UNSCALED_UI_UNITS = 3

ZO_PixelUnitControl = ZO_Object:Subclass()

function ZO_PixelUnitControl:New(control, pixelSource, baseObject)
    local obj = baseObject.New(self)
    obj:Initialize(control, pixelSource, baseObject)
    return obj
end

function ZO_PixelUnitControl:Initialize(control, pixelSource)
    self.control = control
    self.pixelSource = pixelSource
    self.dirty = false
    self.applyLocked = false
    self.anchors = { }
    self.scale = 1
end

ZO_PixelUnitControl.PIXEL_CONVERTERS =
{
    [PIXEL_SOURCE_PIXELS] = function(measurement)
        return measurement
    end,

    [PIXEL_SOURCE_UI_UNITS] = function(measurement)
        local globalScale = GetUIGlobalScale()
        local pixels = measurement * globalScale
        return pixels
    end,

    [PIXEL_SOURCE_UNSCALED_UI_UNITS] = function(measurement)
        local unscaledUIUnits = measurement / GetUICustomScale()
        local globalScale = GetUIGlobalScale()
        local pixels = unscaledUIUnits * globalScale
        return pixels
    end,
}

function ZO_PixelUnitControl:ConvertToUIUnits(measurement)
    local pixels = ZO_PixelUnitControl.PIXEL_CONVERTERS[self.pixelSource](measurement)
    
    --If the measurement wasn't zero, return at least one pixel's worth. We don't want it to decay to no spacing.
    if pixels == 0 then
        if measurement > 0 then
            pixels = 1
        elseif measurement < 0 then
            pixels = -1
        end
    end

    local globalScale = GetUIGlobalScale()
    return pixels / globalScale    
end

function ZO_PixelUnitControl:OnScreenResized()
    if self.width then
        self.widthUIUnits = self:ConvertToUIUnits(self.width)
    end
    if self.height then
        self.heightUIUnits = self:ConvertToUIUnits(self.height)
    end
    if self.minWidth then
        self.minWidthUIUnits = self:ConvertToUIUnits(self.minWidth)
    end
    if self.minHeight then
        self.minHeightUIUnits = self:ConvertToUIUnits(self.minHeight)
    end
    if self.maxWidth then
        self.maxWidthUIUnits = self:ConvertToUIUnits(self.maxWidth)
    end
    if self.maxHeight then
        self.maxHeightUIUnits = self:ConvertToUIUnits(self.maxHeight)
    end
    for _, anchor in ipairs(self.anchors) do
        anchor.offsetXUIUnits = self:ConvertToUIUnits(anchor.offsetX)
        anchor.offsetYUIUnits = self:ConvertToUIUnits(anchor.offsetY)
    end
    self:ApplyToControl()
end

function ZO_PixelUnitControl:ClearAnchors()
    ZO_ClearNumericallyIndexedTable(self.anchors)
    self:ApplyToControl()
end

function ZO_PixelUnitControl:AddAnchor(point, anchorTo, relativePoint, offsetX, offsetY, anchorConstrains)
    local anchor = 
    {
        point = point,
        anchorTo = anchorTo,
        relativePoint = relativePoint,
        offsetX = offsetX,
        offsetXUIUnits = self:ConvertToUIUnits(offsetX),
        offsetY = offsetY,
        offsetYUIUnits = self:ConvertToUIUnits(offsetY),
        anchorConstrains = anchorConstrains,
    }
    table.insert(self.anchors, anchor)
    self:ApplyToControl()
end

function ZO_PixelUnitControl:SetWidth(width)
    self.width = width
    self.widthUIUnits = self:ConvertToUIUnits(self.width)
    self:ApplyToControl()
end

function ZO_PixelUnitControl:SetHeight(height)
    self.height = height
    self.heightUIUnits = self:ConvertToUIUnits(self.height)
    self:ApplyToControl()
end

function ZO_PixelUnitControl:SetDimensions(width, height)
    self.width = width
    self.widthUIUnits = self:ConvertToUIUnits(self.width)
    self.height = height
    self.heightUIUnits = self:ConvertToUIUnits(self.height)
    self:ApplyToControl()
end

function ZO_PixelUnitControl:SetDimensionConstraints(minWidth, minHeight, maxWidth, maxHeight)
    if minWidth then
        self.minWidth = minWidth
        self.minWidthUIUnits = self:ConvertToUIUnits(minWidth)
    else
        self.minWidth = nil
        self.maxWidthUIUnits = nil
    end
    if minHeight then
        self.minHeight = minHeight
        self.minHeightUIUnits = self:ConvertToUIUnits(minHeight)
    else
        self.minHeight = nil
        self.minHeightUIUnits = nil
    end
    if maxWidth then
        self.maxWidth = maxWidth
        self.maxWidthUIUnits = self:ConvertToUIUnits(maxWidth)
    else
        self.maxWidth = nil
        self.maxWidthUIUnits = nil
    end
    if maxHeight then
        self.maxHeight = maxHeight
        self.maxHeightUIUnits = self:ConvertToUIUnits(maxHeight)
    else
        self.maxHeight = nil
        self.maxHeightUIUnits = nil
    end
    self:ApplyToControl()
end

function ZO_PixelUnitControl:SetScale(scale)
    if zo_abs(self.scale - scale) > 0.01 then
        self.scale = scale
        self:ApplyToControl()
    end
end

function ZO_PixelUnitControl:IsDimensionConstrainedByAnchors(side1, side2, checkDirection1, checkDirection2)
    if #self.anchors == MAX_ANCHORS and not self.control:GetResizeToFitDescendents() then
        for i = 1, MAX_ANCHORS do
            local anchorPoint1 = self.anchors[i].point
            local anchorPoint2 = self.anchors[(i % MAX_ANCHORS) + 1].point

            if side1 == anchorPoint1 or (side1 + checkDirection1) == anchorPoint1 or (side1 + checkDirection2) == anchorPoint1 then
                 if side2 == anchorPoint2 or (side2 + checkDirection2) == anchorPoint2 or (side2 + checkDirection2) == anchorPoint2 then
                    return true
                 end
            end 
        end
    end
    return false
end

function ZO_PixelUnitControl:ScrapeFromXML()
    self:LockApply()
    for i = 0, MAX_ANCHORS - 1 do
        local isValid, point, anchorTo, relPoint, offsetX, offsetY = self.control:GetAnchor(i)
        if isValid then
            self:AddAnchor(point, anchorTo, relPoint, offsetX, offsetY)
        end
    end
    
    if not self:IsDimensionConstrainedByAnchors(LEFT, RIGHT, TOP, BOTTOM) then
        self:SetWidth(self.control:GetWidth())
    end

    if not self:IsDimensionConstrainedByAnchors(TOP, BOTTOM, LEFT, RIGHT) then
        self:SetHeight(self.control:GetHeight())
    end
    self:UnlockApply()
end

function ZO_PixelUnitControl:LockApply()
    self.applyLocked = true
end

function ZO_PixelUnitControl:UnlockApply()
    self.applyLocked = false
    self:ApplyToControl()
end

function ZO_PixelUnitControl:ApplyToControl()
    if self.applyLocked then
        self.dirty = true
    else
        self.dirty = false

        local scale = self.scale

        if #self.anchors > 0 then
            self.control:ClearAnchors()
            for i = 1, #self.anchors do
                local anchor = self.anchors[i]
                self.control:SetAnchor(anchor.point, anchor.anchorTo, anchor.relativePoint, anchor.offsetXUIUnits * scale, anchor.offsetYUIUnits * scale, anchor.anchorConstrains)
            end
        end

        local minWidthUIUnits = self.minWidthUIUnits
        local minHeightUIUnits = self.minHeightUIUnits
        local maxWidthUIUnits = self.maxWidthUIUnits
        local maxHeightUIUnits = self.maxHeightUIUnits
        if minWidthUIUnits or minHeightUIUnits or maxWidthUIUnits or maxHeightUIUnits then
            minWidthUIUnits = minWidthUIUnits and minWidthUIUnits * scale or -1
            minHeightUIUnits = minHeightUIUnits and minHeightUIUnits * scale or -1
            maxWidthUIUnits = maxWidthUIUnits and maxWidthUIUnits * scale or -1
            maxHeightUIUnits = maxHeightUIUnits and maxHeightUIUnits * scale or -1
            self.control:SetDimensionConstraints(minWidthUIUnits, minHeightUIUnits, maxWidthUIUnits, maxHeightUIUnits)
        end

        if self.widthUIUnits then
            self.control:SetWidth(self.widthUIUnits * scale)
        end

        if self.heightUIUnits then
            self.control:SetHeight(self.heightUIUnits * scale)
        end
    end
end

--Pixel Units
-------------------

ZO_PixelUnits = ZO_Object:Subclass()

function ZO_PixelUnits:New(namespace, baseObject)
    local obj = baseObject.New(self)
    obj:Initialize(namespace, baseObject)
    return obj
end

function ZO_PixelUnits:Initialize(namespace, baseObject)
    self.baseObject = baseObject
    self.pixelUnitControls = { }
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_SCREEN_RESIZED, function() self:OnScreenResized() end)
end

function ZO_PixelUnits:OnScreenResized()
    for _, pixelUnitControl in pairs(self.pixelUnitControls) do
        pixelUnitControl:OnScreenResized()
    end
end

function ZO_PixelUnits:Get(control)
    return self.pixelUnitControls[control]
end

function ZO_PixelUnits:Add(control, pixelSource)
    local pixelUnitControl = ZO_PixelUnitControl:New(control, pixelSource, self.baseObject)
    self.pixelUnitControls[control] = pixelUnitControl
    return pixelUnitControl
end

function ZO_PixelUnits:Remove(...)
    for i = 1, select("#", ...) do
        self.pixelUnitControls[select(i, ...)] = nil
    end
end

function ZO_PixelUnits:AddControlAndAllChildren(control)
    self:Add(control, PIXEL_SOURCE_PIXELS)
    for i = 1, control:GetNumChildren() do
        self:AddControlAndAllChildren(control:GetChild(i))
    end
end

function ZO_PixelUnits:AddAnchor(control, point, relativeTo, relativePoint, offsetX, offsetY, anchorConstrains)
    local pixelUnitControl = self:Get(control)
    if pixelUnitControl then
        pixelUnitControl:AddAnchor(point, relativeTo, relativePoint, offsetX, offsetY, anchorConstrains)
    end
end

function ZO_PixelUnits:SetDimensionConstraints(control, minWidth, minHeight, maxWidth, maxHeight)
    local pixelUnitControl = self:Get(control)
    if pixelUnitControl then
        pixelUnitControl:SetDimensionConstraints(minWidth, minHeight, maxWidth, maxHeight)
    end
end

function ZO_PixelUnits:SetDimensions(control, width, height)
    local pixelUnitControl = self:Get(control)
    if pixelUnitControl then
        pixelUnitControl:SetDimensions(width, height)
    end
end

function ZO_PixelUnits:SetWidth(control, width)
    local pixelUnitControl = self:Get(control)
    if pixelUnitControl then
        pixelUnitControl:SetWidth(width)
    end
end

function ZO_PixelUnits:SetHeight(control, height)
    local pixelUnitControl = self:Get(control)
    if pixelUnitControl then
        pixelUnitControl:SetHeight(height)
    end
end

function ZO_PixelUnits:SetScale(control, scale)
    local pixelUnitControl = self:Get(control)
    if pixelUnitControl then
        pixelUnitControl:SetScale(scale)
    end
end

PIXEL_UNITS = ZO_PixelUnits:New("ZO_PixelUnits", ZO_Object)

--Global XML

function ZO_PixelUnitsControl_OnInitialized(self)
    local pixelControl = PIXEL_UNITS:Add(self, PIXEL_SOURCE_PIXELS)
    pixelControl:ScrapeFromXML()
end