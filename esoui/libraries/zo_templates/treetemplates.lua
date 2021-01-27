function ZO_LabelHeader_Setup(control, open)
    control:SetSelected(open)
end

function ZO_IconHeader_OnMouseEnter(control)
    ZO_SelectableLabel_OnMouseEnter(control.text)
    if not control.text:IsSelected() and control.enabled then
        if control.allowIconScaling then
            control.icon.animation:PlayForward()
        end
        control.iconHighlight:SetHidden(false)
    end
    if(control.text:WasTruncated()) then
        InitializeTooltip(InformationTooltip, control, RIGHT, -10)
        SetTooltipText(InformationTooltip, control.text:GetText())
    end
end

ZO_TREE_ENTRY_ICON_HEADER_ICON_MAX_DIMENSIONS = 48
ZO_TREE_ENTRY_ICON_HEADER_TEXT_OFFSET_X = 55
ZO_TREE_ENTRY_ICON_HEADER_TEXT_PADDING_Y = 9

function ZO_IconHeader_OnMouseExit(control)
    ZO_SelectableLabel_OnMouseExit(control.text)
    if not control.text:IsSelected() and control.allowIconScaling then
        control.icon.animation:PlayBackward()
    end
    control.iconHighlight:SetHidden(true)
    ClearTooltip(InformationTooltip)
end

function ZO_IconHeader_OnMouseUp(control, upInside)
    if control.enabled then
        ZO_TreeHeader_OnMouseUp(control, upInside)
    end
end

function ZO_IconHeader_Setup(control, open, enabled, disableScaling, updateSizeFunction)
    enabled = enabled == nil or enabled
    control.enabled = enabled
    control.allowIconScaling = not disableScaling

    if not control.icon.animation and control.allowIconScaling then
        control.icon.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual(control.animationTemplate, control.icon)
    end

    if enabled and (open or WINDOW_MANAGER:GetMouseOverControl() == control) then
        if control.allowIconScaling then
            control.icon.animation:PlayForward()
        end
        control.iconHighlight:SetHidden(WINDOW_MANAGER:GetMouseOverControl() ~= control)
    else
        if control.allowIconScaling then
            control.icon.animation:PlayBackward()
        end
        control.iconHighlight:SetHidden(true)
    end

    control.text:SetSelected(open)
    control.text:SetEnabled(enabled)

    if updateSizeFunction then
        updateSizeFunction(control)
    else
        ZO_IconHeader_UpdateSize(control)
    end
end

function ZO_IconHeader_UpdateSize(control)
    local textWidth, textHeight = control.text:GetTextDimensions()
    local height = textHeight + ZO_TREE_ENTRY_ICON_HEADER_TEXT_PADDING_Y * 2
    height = zo_max(height, ZO_TREE_ENTRY_ICON_HEADER_ICON_MAX_DIMENSIONS)
    local width = textWidth + ZO_TREE_ENTRY_ICON_HEADER_TEXT_OFFSET_X
    control:SetDimensions(width, height)
end

function ZO_IconHeader_OnInitialized(self)
    self.icon = self:GetNamedChild("Icon")
    self.iconHighlight = self.icon:GetNamedChild("Highlight")
    self.text = self:GetNamedChild("Text")

    self.OnMouseEnter = ZO_IconHeader_OnMouseEnter
    self.OnMouseExit = ZO_IconHeader_OnMouseExit
    self.OnMouseUp = ZO_IconHeader_OnMouseUp

    self.animationTemplate = "IconHeaderAnimation"
end

function ZO_IconHeader_SetAnimation(self, animationTemplate)
    self.animationTemplate = animationTemplate
end

function ZO_IconHeader_SetMaxLines(self, maxLines)
    self.text:SetHeight(self.text:GetFontHeight() * maxLines + 1)
end

-- Simple Arrow Icon Header
do
    local function OnMouseEnter(control)
        ZO_SelectableLabel_OnMouseEnter(control.text)
        control.iconHighlight:SetHidden(false)
    end

    local function OnMouseExit(control)
        ZO_SelectableLabel_OnMouseExit(control.text)
        control.iconHighlight:SetHidden(true)
    end

    local function OnMouseUp(control, upInside)
        ZO_TreeHeader_OnMouseUp(control, upInside)
    end
    
    local OPEN_TEXTURE = "EsoUI/Art/Buttons/tree_open_up.dds"
    local CLOSED_TEXTURE = "EsoUI/Art/Buttons/tree_closed_up.dds"
    local OPEN_OVER_TEXTURE = "EsoUI/Art/Buttons/tree_open_over.dds"
    local CLOSED_OVER_TEXTURE = "EsoUI/Art/Buttons/tree_closed_over.dds"

    local function SimpleArrowSetup(control, name, open)
        control.text:SetText(name)

        control.icon:SetTexture(open and OPEN_TEXTURE or CLOSED_TEXTURE)
        control.iconHighlight:SetTexture(open and OPEN_OVER_TEXTURE or CLOSED_OVER_TEXTURE)

        control.text:SetSelected(open)
    end

    function ZO_SimpleArrowIconHeader_OnInitialized(self)
        self.icon = self:GetNamedChild("Icon")
        self.iconHighlight = self.icon:GetNamedChild("Highlight")
        self.text = self:GetNamedChild("Text")

        self.OnMouseEnter = OnMouseEnter
        self.OnMouseExit = OnMouseExit
        self.OnMouseUp = OnMouseUp
        self.SimpleArrowSetup = SimpleArrowSetup
    end
end