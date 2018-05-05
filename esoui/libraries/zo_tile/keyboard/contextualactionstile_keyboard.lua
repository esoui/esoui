-----------
-- This class should be dual inherited after an ZO_ContextualActionsTile to create a complete tile. This class should NOT subclass a ZO_ContextualActionsTile
--
-- Note: Since this is expected to be the second class of a dual inheritance it does not have it's own New function
-----------

ZO_CONTEXTUAL_ACTIONS_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")

ZO_ContextualActionsTile_Keyboard = ZO_Tile_Keyboard:Subclass()

-- Begin ZO_Tile_Keyboard Overrides --

function ZO_ContextualActionsTile_Keyboard:InitializePlatform()
    ZO_Tile_Keyboard.InitializePlatform(self)

    self:SetHighlightAnimationProvider(ZO_CONTEXTUAL_ACTIONS_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER)
    local control = self:GetControl()
    control:SetHandler("OnMouseDoubleClick", function(_, ...) self:OnMouseDoubleClick(...) end)
end

function ZO_ContextualActionsTile_Keyboard:PostInitializePlatform()
    ZO_Tile_Keyboard.PostInitializePlatform(self)

    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_RIGHT
end

function ZO_ContextualActionsTile_Keyboard:OnMouseEnter()
    ZO_Tile_Keyboard.OnMouseEnter(self)

    local IS_FOCUSED = true
    self:OnFocusChanged(IS_FOCUSED)
end

function ZO_ContextualActionsTile_Keyboard:OnMouseExit()
    ZO_Tile_Keyboard.OnMouseExit(self)

    local IS_NOT_FOCUSED = false
    self:OnFocusChanged(IS_NOT_FOCUSED)
end

-- End ZO_Tile_Keyboard Overrides --

function ZO_ContextualActionsTile_Keyboard:OnMouseDoubleClick(button)
    -- Can be overridden
end