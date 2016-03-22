local function OnTooltipHidden(tooltip)
    if tooltip.ClearLines then
        tooltip:ClearLines()
    end
    tooltip:SetHidden(true)
    if tooltip == ItemTooltip then
        tooltip:HideComparativeTooltips()
    end
end

-- Yes, all controls that want to clear tooltips could just call Tooltip:ClearLines.
-- This function is here in case we want to have custom behavior for clearing tooltips.
function ClearTooltip(tooltip)
    if tooltip.SetOwner then
        tooltip:SetOwner(nil)
    end

    if not tooltip:IsControlHidden() then
        if not tooltip.animation then
            tooltip.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("TooltipFadeOutAnimation", tooltip)
            tooltip.animation:SetHandler("OnStop", function(animation, completedPlaying)
                if completedPlaying then
                    OnTooltipHidden(tooltip)
                end
            end)
        end

        if not tooltip.animation:IsPlaying() then
            tooltip.animation:PlayFromStart()
        end
    end
end

function ClearTooltipImmediately(tooltip)
    if tooltip.animation and tooltip.animation:IsPlaying() then
        tooltip.animation:Stop()
    end

    if tooltip.SetOwner then
        tooltip:SetOwner(nil)
    end
    OnTooltipHidden(tooltip)
end

function SetTooltipText(tooltip, text, color, colorG, colorB)
    if text and #text > 0 then
        local r, g, b
        if(type(color) == "number")
        then
            r = color
            g = colorG
            b = colorB
        else
            color = color or ZO_TOOLTIP_DEFAULT_COLOR
            r, g, b = color:UnpackRGB()
        end
        tooltip:AddLine(text, "", r, g, b)
    else
        ClearTooltip(tooltip)
    end
end

-- Pass nil for relativePoint to have the control choose a good relativePoint
function InitializeTooltip(tooltip, owner, point, offsetX, offsetY, relativePoint)
    if tooltip.ClearLines then
        tooltip:ClearLines()
    end
    tooltip:SetHidden(false)
    if owner then
        if tooltip.SetOwner then
            tooltip:SetOwner(owner, point, offsetX, offsetY, relativePoint)
        else
            tooltip:ClearAnchors()
            tooltip:SetAnchor(point, owner, relativePoint, offsetX, offsetY)
        end
    end
    if tooltip.animation then
        tooltip.animation:Stop()
    end
    tooltip:SetAlpha(1)
end

local QUAD_TOPLEFT      = 1
local QUAD_TOPRIGHT     = 2
local QUAD_BOTTOMRIGHT  = 3
local QUAD_BOTTOMLEFT   = 4

local OFFSET_FROM_OWNER = 4
local BETWEEN_TOOLTIP_OFFSET_X = 20
local BETWEEN_TOOLTIP_OFFSET_Y = 40

local function CalculateQuandrant(ownerMiddleX, ownerMiddleY, middleScreenX, middleScreenY)
    if ownerMiddleX >= middleScreenX and ownerMiddleY < middleScreenY then
        return QUAD_TOPRIGHT
    elseif ownerMiddleX >= middleScreenX and ownerMiddleY >= middleScreenY then
        return QUAD_BOTTOMRIGHT
    elseif ownerMiddleX < middleScreenX and ownerMiddleY >= middleScreenY then
        return QUAD_BOTTOMLEFT
    end

    return QUAD_TOPLEFT
end

local function ValidateComparativeTooltip(comparativeTooltip)
    if comparativeTooltip and not comparativeTooltip:IsHidden() then
        return comparativeTooltip
    end
    return nil
end

local StartWatchingComparisonDynamicAnchor
do
    local g_comparisonDynamicAnchors = {}

    local function DynamicAnchorLayout(tooltip, owner, quadrant, comparativeTooltip1, comparativeTooltip2)
        if comparativeTooltip1 and comparativeTooltip2 then
            if quadrant == QUAD_TOPLEFT or quadrant == QUAD_BOTTOMLEFT then
                comparativeTooltip1:SetOwner(tooltip, TOPLEFT, BETWEEN_TOOLTIP_OFFSET_X, 0)
                comparativeTooltip2:SetOwner(comparativeTooltip1, TOPLEFT, 0, BETWEEN_TOOLTIP_OFFSET_Y, BOTTOMLEFT)
            else
                comparativeTooltip1:SetOwner(tooltip, TOPRIGHT, -BETWEEN_TOOLTIP_OFFSET_X, 0)
                comparativeTooltip2:SetOwner(comparativeTooltip1, TOPLEFT, 0, BETWEEN_TOOLTIP_OFFSET_Y, BOTTOMLEFT)
            end

            comparativeTooltip1:SetClampedToScreenInsets(0, comparativeTooltip1.topClampedToScreenInset, 0, comparativeTooltip2:GetHeight() + BETWEEN_TOOLTIP_OFFSET_Y)
            comparativeTooltip2:SetClampedToScreenInsets(0, comparativeTooltip2.topClampedToScreenInset, 0, 0)
        elseif comparativeTooltip1 then
            if quadrant == QUAD_TOPLEFT or quadrant == QUAD_BOTTOMLEFT then
                comparativeTooltip1:SetOwner(tooltip, TOPLEFT, BETWEEN_TOOLTIP_OFFSET_X, 0)
                comparativeTooltip1:SetClampedToScreenInsets(0, comparativeTooltip1.topClampedToScreenInset, 0, 0)
            else
                comparativeTooltip1:SetOwner(tooltip, TOPRIGHT, -BETWEEN_TOOLTIP_OFFSET_X, 0)
                comparativeTooltip1:SetClampedToScreenInsets(0, comparativeTooltip1.topClampedToScreenInset, 0, 0)
            end
        end
    end

    local function UpdateComparisonDynamicAnchors()
        for tooltip, anchorInfo in pairs(g_comparisonDynamicAnchors) do
            if tooltip:IsControlHidden() then
                g_comparisonDynamicAnchors[tooltip] = nil
            else
                DynamicAnchorLayout(tooltip, unpack(anchorInfo))
            end
        end
    end
    EVENT_MANAGER:RegisterForUpdate("UpdateComparisonDynamicAnchors", 0, UpdateComparisonDynamicAnchors)

    function StartWatchingComparisonDynamicAnchor(tooltip, owner, quadrant, comparativeTooltip1, comparativeTooltip2)
        if comparativeTooltip1 then
            g_comparisonDynamicAnchors[tooltip] = { owner, quadrant, comparativeTooltip1, comparativeTooltip2 }
        else
            g_comparisonDynamicAnchors[tooltip] = nil
        end
    end
end

function ZO_Tooltips_SetupDynamicTooltipAnchors(tooltip, owner, comparativeTooltip1, comparativeTooltip2)
    if tooltip and owner then
        local left, top, right, bottom = owner:GetScreenRect()
        local ownerScale = owner:GetScale()
        local ownerMiddleX = (left + right) / (2 * ownerScale)
        local ownerMiddleY = (top + bottom) / (2 * ownerScale)
        
        local screenWidth, screenHeight = GuiRoot:GetDimensions()
        local middleScreenX = screenWidth / 2
        local middleScreenY = screenHeight / 2
        
        local quadrant = CalculateQuandrant(ownerMiddleX, ownerMiddleY, middleScreenX, middleScreenY)

        tooltip:ClearAnchors()
        
        if quadrant == QUAD_TOPLEFT or quadrant == QUAD_BOTTOMLEFT then
            tooltip:SetOwner(owner, LEFT, OFFSET_FROM_OWNER, 0)
        else
            tooltip:SetOwner(owner, RIGHT, -OFFSET_FROM_OWNER, 0)
        end

        comparativeTooltip1 = ValidateComparativeTooltip(comparativeTooltip1)
        comparativeTooltip2 = ValidateComparativeTooltip(comparativeTooltip2)
        
        if comparativeTooltip2 and not comparativeTooltip1 then
            comparativeTooltip1 = comparativeTooltip2
            comparativeTooltip2 = nil
        end

        StartWatchingComparisonDynamicAnchor(tooltip, owner, quadrant, comparativeTooltip1, comparativeTooltip2)
    end
end

function ZO_Tooltips_ShowTruncatedTextTooltip(labelControl)
    if(labelControl:WasTruncated()) then
        local buttonText = labelControl:GetText()

        InitializeTooltip(InformationTooltip, labelControl, BOTTOM, 0, -3)
        InformationTooltip:AddLine(buttonText)
    end
end

function ZO_Tooltips_HideTruncatedTextTooltip()
    ClearTooltip(InformationTooltip)
end

local OFFSET_DISTANCE = 5

local OFFSETS_X =
{
    [TOP] = 0,
    [BOTTOM] = 0,
    [LEFT] = -OFFSET_DISTANCE,
    [RIGHT] = OFFSET_DISTANCE,
}

local OFFSETS_Y =
{
    [TOP] = -OFFSET_DISTANCE,
    [BOTTOM] = OFFSET_DISTANCE,
    [LEFT] = 0,
    [RIGHT] = 0,
}

local SIDE_TO_TOOLTIP_SIDE =
{
    [TOP] = BOTTOM,
    [BOTTOM] = TOP,
    [LEFT] = RIGHT,
    [RIGHT] = LEFT,
}

function ZO_Tooltips_ShowTextTooltip(control, side, ...)
    if side == nil then
        InitializeTooltip(InformationTooltip)
        ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, control)
    else
        InitializeTooltip(InformationTooltip, control, SIDE_TO_TOOLTIP_SIDE[side], OFFSETS_X[side], OFFSETS_Y[side])
    end

    for i = 1, select("#", ...) do
        local line = select(i, ...)
        InformationTooltip:AddLine(line, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
    end
end

function ZO_Tooltips_HideTextTooltip()
    ClearTooltip(InformationTooltip)
end

function ZO_Tooltip_AddDivider(tooltipControl)
    if not tooltipControl.dividerPool then
        tooltipControl.dividerPool = ZO_ControlPool:New("ZO_BaseTooltipDivider", tooltipControl, "Divider")
    end

    local divider = tooltipControl.dividerPool:AcquireObject()

    if divider then
        tooltipControl:AddControl(divider)
        divider:SetAnchor(CENTER)
    end
end

function ZO_Tooltip_OnAddGameData(tooltipControl, gameDataType)
    if gameDataType == TOOLTIP_GAME_DATA_DIVIDER then
        ZO_Tooltip_AddDivider(tooltipControl)
    end
end

function ZO_Tooltip_OnCleared(tooltipControl)
    if tooltipControl.dividerPool then
        tooltipControl.dividerPool:ReleaseAllObjects()
    end
end
