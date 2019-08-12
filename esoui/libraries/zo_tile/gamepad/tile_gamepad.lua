----
-- ZO_Tile_Gamepad
----

-----------
-- This class should be dual inherited after a ZO_Tile to create a complete tile. This class should NOT subclass a ZO_Tile
--
-- Note: Since this is expected to be the second class of a dual inheritance it does not have it's own New function
-----------

ZO_Tile_Gamepad = ZO_Object:Subclass()

function ZO_Tile_Gamepad:InitializePlatform()
    self.isSelected = false
end

function ZO_Tile_Gamepad:PostInitializePlatform()
    -- To be overridden
end

function ZO_Tile_Gamepad:LayoutPlatform(data)
    if data then
        local isSelected = data.isSelected or false
        self:SetSelected(isSelected)
    end
end

function ZO_Tile_Gamepad:IsSelected()
    return self.isSelected
end

function ZO_Tile_Gamepad:SetSelected(isSelected)
    if self.isSelected ~= isSelected then
        self.isSelected = isSelected
        self:OnSelectionChanged()
    end
end

function ZO_Tile_Gamepad:OnSelectionChanged()
    -- To be overriden
end
