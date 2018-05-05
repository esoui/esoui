----
-- ZO_ActionTile_Keyboard
----

-----------
-- This class should be dual inherited after an ZO_ActionTile to create a complete tile. This class should NOT subclass a ZO_ActionTile
--
-- Note: Since this is expected to be the second class of a dual inheritance it does not have it's own New function
-----------

ZO_ActionTile_Keyboard = ZO_Tile_Keyboard:Subclass()

function ZO_ActionTile_Keyboard:PostInitializePlatform()
    ZO_Tile_Keyboard.PostInitializePlatform(self)

    self.actionButton = self.container:GetNamedChild("ActionButton")
    self:SetActionSound(SOUNDS.DIALOG_ACCEPT)

    local onClick = function()
        if self.actionCallback and self:IsActionAvailable() then
            self.actionCallback()
        end
    end

    self.actionButton:SetHandler("OnClicked", onClick)
end

function ZO_ActionTile_Keyboard:OnMouseEnter()
    ZO_Tile_Keyboard.OnMouseEnter(self)

    local IS_FOCUSED = true
    self:OnFocusChanged(IS_FOCUSED)
end

function ZO_ActionTile_Keyboard:OnMouseExit()
    ZO_Tile_Keyboard.OnMouseExit(self)

    local IS_NOT_FOCUSED = false
    self:OnFocusChanged(IS_NOT_FOCUSED)
end


function ZO_ActionTile_Keyboard:SetActionAvailable(available)
    ZO_ActionTile.SetActionAvailable(self, available)
    self.actionButton:SetHidden(not self:IsActionAvailable())
end

function ZO_ActionTile_Keyboard:SetActionText(actionText)
    ZO_ActionTile.SetActionText(self, actionText)
    self.actionButton:SetText(actionText)
end

function ZO_ActionTile_Keyboard:SetActionSound(actionSound)
    ZO_ActionTile.SetActionSound(self, actionSound)
    self.actionButton:SetClickSound(actionSound)
end