----
-- ZO_Tile_Keyboard
----

-----------
-- This class should be dual inherited after ZO_Tile to create a complete tile. This class should NOT subclass ZO_Tile
--
-- Note: Since this is expected to be the second class of a dual inheritance it does not have it's own New function
-----------

ZO_Tile_Keyboard = ZO_Object:Subclass()

function ZO_Tile_Keyboard:InitializePlatform()
    local control = self:GetControl()

    self.isMousedOver = false
    control:SetHandler("OnMouseEnter", function(...) self:OnMouseEnter(...) end)
    control:SetHandler("OnMouseExit", function(...) self:OnMouseExit(...) end)
    control:SetHandler("OnMouseUp", function(_, ...) self:OnMouseUp(...) end)
end

function ZO_Tile_Keyboard:PostInitializePlatform()
    -- To be overridden
end

function ZO_Tile_Keyboard:OnMouseEnter()
    self.isMousedOver = true
end

function ZO_Tile_Keyboard:OnMouseExit()
    self.isMousedOver = false
end

function ZO_Tile_Keyboard:IsMousedOver()
    return self.isMousedOver
end

function ZO_Tile_Keyboard:OnMouseUp(button, upInside)
    -- Can be overridden
end