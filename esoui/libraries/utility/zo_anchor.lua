local POINT     = 1
local TARGET    = 2
local REL_POINT = 3
local OFFS_X    = 4
local OFFS_Y    = 5

ZO_Anchor = ZO_Object:Subclass ()

function ZO_Anchor:New(pointOnMe, target, pointOnTarget, offsetX, offsetY)
    local a = ZO_Object.New(self)
    
    if(type(pointOnMe) == "table")
    then
        local copy = pointOnMe.data
        
        a.data = { copy[POINT], copy[TARGET], copy[REL_POINT], copy[OFFS_X], copy[OFFS_Y] }
    else
        a.data = { pointOnMe or TOPLEFT, target, pointOnTarget or a[POINT], offsetX or 0, offsetY or 0 }
    end
    
    return a
end

function ZO_Anchor:ResetToAnchor(anchorObj)
    self.data[POINT]     = anchorObj.data[POINT] or TOPLEFT
    self.data[TARGET]    = anchorObj.data[TARGET]
    self.data[REL_POINT] = anchorObj.data[REL_POINT] or self.data[POINT]
    self.data[OFFS_X]    = anchorObj.data[OFFS_X] or 0
    self.data[OFFS_Y]    = anchorObj.data[OFFS_Y] or 0
end

function ZO_Anchor:SetFromControlAnchor(control, anchorIndex)
    local isValid, point, relTo, relPoint, offsX, offsY = control:GetAnchor(anchorIndex)
    
    if(isValid)
    then
        local data = self.data
        data[POINT] = point
        data[TARGET] = relTo
        data[REL_POINT] = relPoint
        data[OFFS_X] = offsX
        data[OFFS_Y] = offsY
    end
end

function ZO_Anchor:GetTarget()
    return self.data[TARGET]
end

function ZO_Anchor:SetTarget(control)
    self.data[TARGET] = control
end

function ZO_Anchor:GetMyPoint()
    return self.data[POINT]
end

function ZO_Anchor:SetMyPoint(myPoint)
    self.data[POINT] = myPoint
end

function ZO_Anchor:GetRelativePoint()
    return self.data[REL_POINT]
end

function ZO_Anchor:SetRelativePoint(relPoint)
    self.data[REL_POINT] = relPoint
end

function ZO_Anchor:GetOffsets()
    return self.data[OFFS_X], self.data[OFFS_Y]
end

function ZO_Anchor:GetOffsetX()
    return self.data[OFFS_X]
end

function ZO_Anchor:GetOffsetY()
    return self.data[OFFS_Y]
end

function ZO_Anchor:SetOffsets(offsetX, offsetY)
    self.data[OFFS_X] = offsetX or self.data[OFFS_X]
    self.data[OFFS_Y] = offsetY or self.data[OFFS_Y]
end

function ZO_Anchor:AddOffsets(offsetX, offsetY)
    if(offsetX)
    then
        self.data[OFFS_X] = offsetX + self.data[OFFS_X]
    end
    if(offsetY)
    then
        self.data[OFFS_Y] = offsetY + self.data[OFFS_Y]
    end
end

function ZO_Anchor:Set(control)
    if(control)
    then
        control:ClearAnchors()
        local data = self.data
        control:SetAnchor(data[POINT], data[TARGET], data[REL_POINT], data[OFFS_X], data[OFFS_Y])
    end
end

function ZO_Anchor:AddToControl(control)
    if(control)
    then
        local data = self.data
        control:SetAnchor(data[POINT], data[TARGET], data[REL_POINT], data[OFFS_X], data[OFFS_Y])
    end
end

GROW_DIRECTION_UP_LEFT = 1
GROW_DIRECTION_UP_RIGHT = 2
GROW_DIRECTION_DOWN_LEFT = 3
GROW_DIRECTION_DOWN_RIGHT = 4

local verticalGrowthProduct =
{
    [GROW_DIRECTION_UP_LEFT] = -1,
    [GROW_DIRECTION_UP_RIGHT] = -1,
    [GROW_DIRECTION_DOWN_LEFT] = 1,
    [GROW_DIRECTION_DOWN_RIGHT] = 1,
}

local horizontalGrowthProduct =
{
    [GROW_DIRECTION_UP_LEFT] = -1,
    [GROW_DIRECTION_UP_RIGHT] = 1,
    [GROW_DIRECTION_DOWN_LEFT] = -1,
    [GROW_DIRECTION_DOWN_RIGHT] = 1,
}

function ZO_Anchor_BoxLayout(currentAnchor, control, controlIndex, containerStride, padX, padY, controlWidth, controlHeight, initialX, initialY, growDirection)
    growDirection = growDirection or GROW_DIRECTION_DOWN_RIGHT
    local row = zo_floor(controlIndex / containerStride)
    local col = controlIndex - (row * containerStride)
    
    padX = col * padX
    padY = row * padY

    if(padX < 0) then padX = 0 end
    if(padY < 0) then padY = 0 end

    local offsetX = horizontalGrowthProduct[growDirection] * ((col * controlWidth) + padX + initialX)
    local offsetY = verticalGrowthProduct[growDirection] * ((row * controlHeight) + padY + initialY)

    currentAnchor:SetOffsets(offsetX, offsetY)
    currentAnchor:Set(control)

    return row, col, offsetX, offsetY
end

--[[
    You would like to anchor "control" to "anchorTo".
    anchorTo will not move.
    This function determines the best fit for control so that anchorTo
    is not obscured and so that control fits in the window.
       
    NOTE: anchorTo can't be nil...it MUST be a valid control.
    
    The most common use of this function is to anchor a really big window, like a tooltip,
    to a really small window, like an actionbutton or inventory slot.
--]]
function ZO_Anchor_DynamicAnchorTo(control, anchorTo, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    local anchorToLeft, anchorToTop = anchorTo:GetLeft(), anchorTo:GetTop()
    local anchorToWidth, anchorToHeight = anchorTo:GetDimensions()
    local anchorToCenterX, anchorToCenterY = anchorToLeft + anchorToWidth * 0.5, anchorToTop + anchorToHeight * 0.5
    local UIWidth, UIHeight = GuiRoot:GetDimensions()
    local UICenterX, UICenterY = UIWidth * 0.5, UIHeight * 0.5

    control:ClearAnchors()

    if(anchorToCenterX < UICenterX) then
        if(anchorToCenterY < UICenterY) then
            --TOPLEFT
            control:SetAnchor(TOPLEFT, anchorTo, BOTTOMRIGHT, offsetX, offsetY)
        else
            --BOTTOMLEFT
            control:SetAnchor(BOTTOMLEFT, anchorTo, TOPRIGHT, offsetX, -offsetY)
        end
    else
        if(anchorToCenterY < UICenterY) then
            --TOPRIGHT
            control:SetAnchor(TOPRIGHT, anchorTo, BOTTOMLEFT, -offsetX, offsetY)
        else
            --BOTTOMRIGHT
            control:SetAnchor(BOTTOMRIGHT, anchorTo, TOPLEFT, -offsetX, -offsetY)
        end
    end
end

--anchors a control to the centered text in a larger label
function ZO_Anchor_ToCenteredLabel(control, anchor, labelWidth)
	local label = anchor:GetTarget()
	local textWidth, _ = label:GetTextDimensions()
	local labelWidth = labelWidth or label:GetWidth()
	local offX, offY = anchor:GetOffsets()
	
    control:SetAnchor(anchor:GetMyPoint(), label, anchor:GetRelativePoint(), labelWidth*0.5 - textWidth*0.5 + offX, offY)
end

function ZO_Anchor_OnRing(control, anchorToControl, x, y, radiusArg)
	local radius = radiusArg or anchorToControl:GetWidth() * 0.5
	local anchorCenterX = anchorToControl:GetLeft() + anchorToControl:GetWidth() * 0.5
	local anchorCenterY = anchorToControl:GetTop() + anchorToControl:GetHeight() * 0.5
	
	local vx = x - anchorCenterX
	local vy = y - anchorCenterY
	
	local vMagSq = vx*vx + vy*vy
	local rx, ry
	
	if(vMagSq > 0.001) then
		--scale the vector toward the origin of rotation
		local radiusSq = radius * radius
		local factor = math.sqrt(radiusSq / vMagSq)
		
		rx = vx * factor
		ry = vy * factor
	else
		--just put it at the top, we're so close to the center that it doesn't really matter what side we're on
		rx = 0
		ry = -radius
	end
	
	control:ClearAnchors()
	control:SetAnchor(CENTER, anchorToControl, CENTER, rx, ry)
end

function ZO_Anchor_ByAngle(control, anchorToControl, theta, radiusArg)
	local radius = radiusArg or anchorToControl:GetWidth() * 0.5	
	control:SetAnchor(CENTER, anchorToControl, CENTER, math.cos(theta) * radius, (-math.sin(theta)) * radius)
end

function ZO_Anchor_LineInContainer(line, container, startX, startY, endX, endY)
    line:ClearAnchors()
    line:SetAnchor(TOPLEFT, container, TOPLEFT, startX, startY)
    line:SetAnchor(BOTTOMRIGHT, container, TOPLEFT, endX, endY)
end
