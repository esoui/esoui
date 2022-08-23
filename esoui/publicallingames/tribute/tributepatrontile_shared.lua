-------------------------
-- Tribute Patron Tile --
-------------------------

ZO_TributePatronTile_Shared = ZO_ContextualActionsTile:Subclass()

function ZO_TributePatronTile_Shared:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

function ZO_TributePatronTile_Shared:Initialize(...)
    ZO_ContextualActionsTile.Initialize(self, ...)

    self.iconTexture = self.control:GetNamedChild("Icon")
end

-- Begin ZO_Tile Overrides --

function ZO_TributePatronTile_Shared:Layout(patronData)
    self.patronData = patronData
    self.iconTexture:SetTexture(patronData:GetPatronLargeIcon())

    ZO_ContextualActionsTile.Layout(self, patronData)
end

-- End ZO_Tile Overrides --

-----------------------------------
-- Tribute Patron Selection Tile --
-----------------------------------

ZO_TributePatronSelectionTile_Shared = ZO_TributePatronTile_Shared:Subclass()

function ZO_TributePatronSelectionTile_Shared:Initialize(...)
    ZO_TributePatronTile_Shared.Initialize(self, ...)

    self.keybindStripDescriptor =
    {
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_TRIBUTE_DECK_SELECTION_SELECT_PATRON),
            order = 1,
            callback = function()
                if self.patronData and ZO_TRIBUTE_PATRON_SELECTION_MANAGER then
                    ZO_TRIBUTE_PATRON_SELECTION_MANAGER:SelectPatron(self.patronData:GetId())
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
                end
            end,
            visible = function()
                return self:CanSelect()
            end,
        }
    }
end

function ZO_TributePatronSelectionTile_Shared:CanSelect()
    if self.patronData and ZO_TRIBUTE_PATRON_SELECTION_MANAGER then
        local patronId = self.patronData:GetId()
        if self.patronData:IsPatronLocked() then
            return false
        elseif ZO_TRIBUTE_PATRON_SELECTION_MANAGER:IsPatronDrafted(patronId) then
            return false
        elseif patronId == ZO_TRIBUTE_PATRON_SELECTION_MANAGER:GetSelectedPatron() then
            return false
        elseif ZO_TRIBUTE_PATRON_SELECTION_MANAGER:IsDraftAnimating() then
            return false
        else
            return GetActiveTributePlayerPerspective() == TRIBUTE_PLAYER_PERSPECTIVE_SELF
        end
    end
    return false
end