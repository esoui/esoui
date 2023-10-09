-------------------------
-- Tribute Patron Tile --
-------------------------

ZO_TRIBUTE_PATRON_SELECTION_TILE_WIDTH_KEYBOARD = 220
ZO_TRIBUTE_PATRON_SELECTION_TILE_HEIGHT_KEYBOARD = 310

ZO_TRIBUTE_PATRON_TILE_ICON_WIDE_DIMENSIONS_KEYBOARD = ZO_TRIBUTE_PATRON_BOOK_TILE_WIDE_WIDTH_KEYBOARD - 20
ZO_TRIBUTE_PATRON_TILE_ICON_DIMENSIONS_KEYBOARD = ZO_TRIBUTE_PATRON_BOOK_TILE_WIDTH_KEYBOARD - 20

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributePatronTile_Keyboard = ZO_ContextualActionsTile_Keyboard:Subclass()

function ZO_TributePatronTile_Keyboard:New(...)
    return ZO_ContextualActionsTile_Keyboard.New(self, ...)
end

function ZO_TributePatronTile_Keyboard:InitializePlatform(...)
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self, ...)

    self.titleLabel = self.control:GetNamedChild("Title")
end

function ZO_TributePatronTile_Keyboard:LayoutPlatform(patronData)
    self.titleLabel:SetText(patronData:GetFormattedColorizedName())
end

-------------------------
-- Tribute Patron Book Tile --
-------------------------

ZO_TributePatronBookTile_Keyboard = ZO_Object.MultiSubclass(ZO_TributePatronTile_Keyboard, ZO_TributePatronTile_Shared)

function ZO_TributePatronBookTile_Keyboard:New(...)
    return ZO_TributePatronTile_Shared.New(self, ...)
end

function ZO_TributePatronBookTile_Keyboard:InitializePlatform(...)
    ZO_TributePatronTile_Keyboard.InitializePlatform(self, ...)
end

function ZO_TributePatronBookTile_Keyboard:LayoutPlatform(patronData)
    ZO_TributePatronTile_Keyboard.LayoutPlatform(self, patronData)
    local isLocked = self.patronData:IsPatronLocked()
    ZO_SetDefaultIconSilhouette(self.iconTexture, isLocked)
    local desaturation = isLocked and 1 or 0
    self:GetHighlightControl():SetDesaturation(desaturation)

    if isLocked then
        self.titleLabel:SetText(self.patronData:GetDisabledFormattedColorizedName())
    end
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_TributePatronBookTile_Keyboard:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)
    if isFocused then
        local DONT_HIGHLIGHT_ACTIVE_FAVOR_STATE = false
        local ALLOW_NOT_COLLECTIBLE_WARNING = false
        local SHOW_ACQUIRE_HINT = true
        local SHOW_LORE = true

        ClearTooltip(ItemTooltip)
        InitializeTooltip(ItemTooltip, self.control, RIGHT, 0, 0, LEFT)
        ItemTooltip:SetTributePatron(self.patronData:GetId(), DONT_HIGHLIGHT_ACTIVE_FAVOR_STATE, ALLOW_NOT_COLLECTIBLE_WARNING, SHOW_ACQUIRE_HINT, SHOW_LORE)
    else
        ClearTooltip(ItemTooltip)
    end
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

-------------------------
-- Tribute Patron Selection Tile --
-------------------------
ZO_TRIBUTE_PATRON_SELECTION_TILE_KEYBOARD_GLOW_ANIMATION_PROVIDER = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")

ZO_TributePatronSelectionTile_Keyboard = ZO_Object.MultiSubclass(ZO_TributePatronTile_Keyboard, ZO_TributePatronSelectionTile_Shared)

function ZO_TributePatronSelectionTile_Keyboard:New(...)
    return ZO_TributePatronSelectionTile_Shared.New(self, ...)
end

function ZO_TributePatronSelectionTile_Keyboard:InitializePlatform(...)
    ZO_TributePatronTile_Keyboard.InitializePlatform(self, ...)
    self.draftedIcon = self.control:GetNamedChild("DraftedIcon")
    self.glow = self.control:GetNamedChild("Glow")
end

function ZO_TributePatronSelectionTile_Keyboard:PostInitializePlatform(...)
    ZO_TributePatronTile_Keyboard.PostInitializePlatform(self, ...)
    --This needs to be done manually to override logic in ZO_ContextualActionsTile_Keyboard
    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_CENTER
end

--TODO Tribute: Determine if any of this logic can be moved to shared
function ZO_TributePatronSelectionTile_Keyboard:LayoutPlatform(patronData)
    ZO_TributePatronTile_Keyboard.LayoutPlatform(self, patronData)
    local isDrafted = false
    local isSelected = false
    local isLocked = self.patronData:IsPatronLocked()

    if ZO_TRIBUTE_PATRON_SELECTION_MANAGER then
        local patronId = patronData:GetId()
        local currentSelectedPatronId = ZO_TRIBUTE_PATRON_SELECTION_MANAGER:GetSelectedPatron()
        isSelected = currentSelectedPatronId == patronId
        isDrafted = ZO_TRIBUTE_PATRON_SELECTION_MANAGER:IsPatronDrafted(patronId)
    end
    
    self.draftedIcon:SetHidden(not isDrafted)
    self:RefreshGlow(isSelected, isDrafted, isLocked) 
    ZO_SetDefaultIconSilhouette(self.iconTexture, isLocked)
    local iconDesaturation = isLocked and 1 or 0
    local highlightTexture = isLocked and "EsoUI/Art/Tribute/tributePatronHighlight_Disabled.dds" or "EsoUI/Art/Tribute/tributePatronHighlight_Hover.dds"
    self:GetHighlightControl():SetTexture(highlightTexture)
    self.iconTexture:SetDesaturation(iconDesaturation)
end

function ZO_TributePatronSelectionTile_Keyboard:RefreshGlow(isSelected, isDrafted, isLocked)
    local showGlow = isSelected or isDrafted
    if self.isGlowShowing ~= showGlow then
        self.isGlowShowing = showGlow
        if showGlow then
            ZO_TRIBUTE_PATRON_SELECTION_TILE_KEYBOARD_GLOW_ANIMATION_PROVIDER:PlayForward(self.glow, self.patronData.animateInstantly)
        else
            ZO_TRIBUTE_PATRON_SELECTION_TILE_KEYBOARD_GLOW_ANIMATION_PROVIDER:PlayBackward(self.glow, self.patronData.animateInstantly)
        end
    end

    if showGlow then
        local glowTexture
        if isDrafted then
            glowTexture = isLocked and "EsoUI/Art/Tribute/tributePatronHighlight_DraftedDisabled.dds" or "EsoUI/Art/Tribute/tributePatronHighlight_Drafted.dds"
        else
            glowTexture = "EsoUI/Art/Tribute/tributePatronHighlight_Selected.dds"
        end
        self.glow:SetTexture(glowTexture)
    end
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_TributePatronSelectionTile_Keyboard:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)
    if isFocused then
        local DONT_HIGHLIGHT_ACTIVE_FAVOR_STATE = false
        local ALLOW_NOT_COLLECTIBLE_WARNING = false
        local showAquireHintIfPatronIsLocked = self.patronData:IsPatronLocked()

        ClearTooltip(ItemTooltip)
        InitializeTooltip(ItemTooltip, self.control, LEFT, 0, 0, RIGHT)
        ItemTooltip:SetTributePatron(self.patronData:GetId(), DONT_HIGHLIGHT_ACTIVE_FAVOR_STATE, ALLOW_NOT_COLLECTIBLE_WARNING, showAquireHintIfPatronIsLocked)
    else
        ClearTooltip(ItemTooltip)
    end
end

function ZO_TributePatronSelectionTile_Keyboard:OnMouseUp(button, upInside)
    if upInside and self:CanSelect() then
        ZO_TRIBUTE_PATRON_SELECTION_MANAGER:SelectPatron(self.patronData:GetId())
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_TributePatronSelectionTile_Keyboard:OnMouseDoubleClick(button)
    if button == MOUSE_BUTTON_INDEX_LEFT and self.patronData then
        local patronId = self.patronData:GetId()
        if self:CanSelect() then
            --If the patron is selectable, just draft right away and skip the confirm
            DraftPatron(patronId)
        elseif patronId == ZO_TRIBUTE_PATRON_SELECTION_MANAGER:GetSelectedPatron() then
            --If the patron is already selected, just tell the selection manager to confirm
            ZO_TRIBUTE_PATRON_SELECTION_MANAGER:ConfirmSelection()
        end
    end
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

-- XML functions
----------------

function ZO_TributePatronBookTile_Keyboard_OnInitialized(control)
    ZO_TributePatronBookTile_Keyboard:New(control)
end

function ZO_TributePatronSelectionTile_Keyboard_OnInitialized(control)
    ZO_TributePatronSelectionTile_Keyboard:New(control)
end
