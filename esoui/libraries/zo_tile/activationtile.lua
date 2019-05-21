----
-- ZO_ActivationTile
----

ZO_ActivationTile = ZO_Tile:Subclass()

function ZO_ActivationTile:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_ActivationTile:Initialize(control)
    ZO_Tile.Initialize(self, control)

    self.titleLabel = control:GetNamedChild("Title")
end

function ZO_ActivationTile:SetTitle(titleText)
    self.titleLabel:SetText(titleText)
end

function ZO_ActivationTile:SetTitleColor(titleColor)
    self.titleLabel:SetColor(titleColor:UnpackRGB())
end

function ZO_ActivationTile:Activate()
    assert(false) -- must be overridden in derived classes
end

function ZO_ActivationTile:SetDeactivateCallback(deactivateCallback)
    self.deactivateCallback = deactivateCallback
end