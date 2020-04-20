ZO_LabelRevealAnimation_Mixin = {}

function ZO_LabelRevealAnimation_Mixin:Initialize()
    self.mask = self:GetNamedChild("Mask")
    self.text = self.mask:GetNamedChild("Text")

    self.text:SetHandler("OnRectWidthChanged", function(_, newWidth)
        self:SetWidth(newWidth)
        self.mask:SetWidth(newWidth)
        if self.sizeAnimation then
            self.sizeAnimation:SetEndWidth(newWidth)
        end
    end)

    self.text:SetHandler("OnRectHeightChanged", function(_, newHeight)
        self:SetHeight(newHeight)
        self.mask:SetHeight(newHeight)
        if self.sizeAnimation then
            self.sizeAnimation:SetEndHeight(newHeight)
        end
    end)
end

function ZO_LabelRevealAnimation_Mixin:SetMaskAnchor(primaryAnchor, secondaryAnchor)
    self.mask:ClearAnchors()
    self.mask:SetAnchor(primaryAnchor)
    if secondaryAnchor then
        self.mask:SetAnchor(secondaryAnchor)
    end
end

function ZO_LabelRevealAnimation_Mixin:SetSizeAnimation(sizeAnimation)
    self.sizeAnimation = sizeAnimation
end

function ZO_LabelRevealAnimation_Mixin:SetText(text)
    self.text:SetText(text)
    self.text:GetWidth() -- Force a clean to update the rect
end

function ZO_LabelRevealAnimation_OnInitialized(control)
    zo_mixin(control, ZO_LabelRevealAnimation_Mixin)
    control:Initialize()
end