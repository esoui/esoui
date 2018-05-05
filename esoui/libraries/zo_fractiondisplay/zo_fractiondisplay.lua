ZO_FractionDisplay = ZO_Object:Subclass()

function ZO_FractionDisplay:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_FractionDisplay:Initialize(control, font, dividerThickness)
    self.control = control
    self.numeratorLabel = control:GetNamedChild("Numerator")
    self.denominatorLabel = control:GetNamedChild("Denominator")
    self.dividerTexture = control:GetNamedChild("Divider")
    
    self.numeratorLabel:SetFont(font)
    self.denominatorLabel:SetFont(font)
    self.dividerTexture:SetHeight(dividerThickness)
    self.control:SetHeight(self.numeratorLabel:GetFontHeight() + dividerThickness + self.denominatorLabel:GetFontHeight())
end

function ZO_FractionDisplay:SetHorizontalAlignment(alignment)
    self.numeratorLabel:SetHorizontalAlignment(alignment)
    self.denominatorLabel:SetHorizontalAlignment(alignment)
end

function ZO_FractionDisplay:SetValues(numerator, denominator)
    --Give the label enough space so that it won't wrap on initial layout
    self.numeratorLabel:SetWidth(500)
    self.denominatorLabel:SetWidth(500)

    self.numeratorLabel:SetText(numerator)
    self.denominatorLabel:SetText(denominator)

    local numeratorWidth = self.numeratorLabel:GetTextWidth()
    local denominatorWidth = self.denominatorLabel:GetTextWidth()
    local maxWidth = zo_max(numeratorWidth, denominatorWidth)
    self.control:SetWidth(maxWidth)
    self.numeratorLabel:SetWidth(maxWidth)
    self.dividerTexture:SetWidth(maxWidth)
    self.denominatorLabel:SetWidth(maxWidth)
end