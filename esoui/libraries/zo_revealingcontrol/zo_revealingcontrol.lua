ZO_RevealingControl_Mixin = {}

function ZO_RevealingControl_Mixin:Initialize()
    self.shape = SHAPE_BOX
    self.maskSimulator = self:GetNamedChild("MaskSimulator")

    local function RefreshMaskSimulator()
        self:RefreshMaskSimulator()
    end
    self:SetHandler("OnRectWidthChanged", RefreshMaskSimulator)

    self:SetHandler("OnRectHeightChanged", RefreshMaskSimulator)

    self.maskSimulator:SetHandler("OnRectChanged", function(_, newLeft, newTop, newRight, newBottom)
        if self.shape == SHAPE_BOX then
            self:SetRectangularClip(newLeft, newTop, newRight, newBottom)
        elseif self.shape == SHAPE_CIRCLE then
            local radius = zo_distance(newRight, newBottom, newLeft, newTop) / 2
            local centerX, centerY = self.maskSimulator:GetCenter()
            self:SetCircularClip(centerX, centerY, radius)
        end
    end)
end

function ZO_RevealingControl_Mixin:SetMaskAnchor(primaryAnchor, secondaryAnchor)
    if self.primaryAnchor ~= primaryAnchor or self.secondaryAnchor ~= secondaryAnchor then
        assert(primaryAnchor, "Control reveals must set a primary anchor")

        self.primaryAnchor = primaryAnchor
        self.secondaryAnchor = secondaryAnchor

        self:RefreshMaskSimulator()
    end
end

function ZO_RevealingControl_Mixin:SetAnimation(animation)
    assert(animation.SetScaleValues, "Control reveals only support ScaleAnimation.")

    self.animation = animation
    animation:SetScaleValues(0, 1)
    animation:SetAnimatedControl(self.maskSimulator)
end

function ZO_RevealingControl_Mixin:SetMaskShape(shape)
    if self.shape ~= shape then
        self.shape = shape

        self:RefreshMaskSimulator()
    end
end

function ZO_RevealingControl_Mixin:RefreshMaskSimulator()
    self.maskSimulator:ClearAnchors()

    local width, height = self:GetDimensions()
    if self.shape == SHAPE_BOX then
        self.maskSimulator:SetAnchor(self.primaryAnchor)
        if self.secondaryAnchor then
            self.maskSimulator:SetAnchor(self.secondaryAnchor)
        end
    elseif self.shape == SHAPE_CIRCLE then
        assert(not self.secondaryAnchor, "Circle reveals only support one anchor.")
        local primaryAnchor = self.primaryAnchor
        self.maskSimulator:SetAnchor(CENTER, nil, primaryAnchor)
        if primaryAnchor ~= CENTER then
            if primaryAnchor == LEFT or primaryAnchor == RIGHT then
                width = width * 2
            elseif primaryAnchor == TOP or primaryAnchor == BOTTOM then
                height = height * 2
            else
                width = width * 2
                height = height * 2
            end
        end
    end

    self.maskSimulator:SetWidth(width)
    self.maskSimulator:SetHeight(height)
end

function ZO_RevealingControl_OnInitialized(control)
    zo_mixin(control, ZO_RevealingControl_Mixin)
    control:Initialize()
end