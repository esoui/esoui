-------------------------
-- Tribute Patron Tile --
-------------------------

ZO_TRIBUTE_PATRON_BOOK_TILE_WIDTH_GAMEPAD = 238
ZO_TRIBUTE_PATRON_BOOK_TILE_HEIGHT_GAMEPAD = 366
ZO_TRIBUTE_PATRON_SELECTION_TILE_WIDTH_GAMEPAD = 232
ZO_TRIBUTE_PATRON_SELECTION_TILE_HEIGHT_GAMEPAD = 326

ZO_TRIBUTE_PATRON_BOOK_TILE_ICON_DIMENSIONS_GAMEPAD = ZO_TRIBUTE_PATRON_BOOK_TILE_WIDTH_GAMEPAD + 20
ZO_TRIBUTE_PATRON_SELECTION_TILE_ICON_DIMENSIONS_GAMEPAD = ZO_TRIBUTE_PATRON_SELECTION_TILE_WIDTH_GAMEPAD + 20

ZO_TributePatronTile_Gamepad = ZO_ContextualActionsTile_Gamepad:New(...)

function ZO_TributePatronTile_Gamepad:New(...)
    return ZO_ContextualActionsTile_Gamepad.New(self, ...)
end

function ZO_TributePatronTile_Gamepad:InitializePlatform(...)
    ZO_ContextualActionsTile_Gamepad.InitializePlatform(self, ...)
end

function ZO_TributePatronTile_Gamepad:LayoutPlatform(patronData)
    ZO_ContextualActionsTile_Gamepad.LayoutPlatform(self, patronData)
end

-------------------------
-- Tribute Patron Book Tile --
-------------------------

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributePatronBookTile_Gamepad = ZO_Object.MultiSubclass(ZO_TributePatronTile_Gamepad, ZO_TributePatronTile_Shared)

function ZO_TributePatronBookTile_Gamepad:New(...)
    return ZO_TributePatronTile_Shared.New(self, ...)
end

function ZO_TributePatronBookTile_Gamepad:InitializePlatform(...)
    ZO_TributePatronTile_Gamepad.InitializePlatform(self, ...)
end

function ZO_TributePatronBookTile_Gamepad:LayoutPlatform(patronData)
    ZO_TributePatronTile_Gamepad.LayoutPlatform(self, patronData)
    local isLocked = self.patronData:IsPatronLocked()
    ZO_SetDefaultIconSilhouette(self.iconTexture, isLocked)
end

-- Begin ZO_ContextualActionsTile_Gamepad Overrides --

function ZO_TributePatronBookTile_Gamepad:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)
    if isFocused then
        local optionalArgs =
        {
            highlightActivePatronState = false,
            suppressNotCollectibleWarning = false,
            showAcquireHint = true,
            showLore = true,
        }
        GAMEPAD_TOOLTIPS:LayoutTributePatron(GAMEPAD_RIGHT_TOOLTIP, self.patronData, optionalArgs)
    end
end

-- End ZO_ContextualActionsTile_Gamepad Overrides --

-----------------------------------
-- Tribute Patron Selection Tile --
-----------------------------------
ZO_TRIBUTE_PATRON_SELECTION_TILE_GAMEPAD_GLOW_ANIMATION_PROVIDER = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")
--TODO Tribute: Determine if any of this logic can be moved to shared
ZO_TributePatronSelectionTile_Gamepad = ZO_Object.MultiSubclass(ZO_TributePatronTile_Gamepad, ZO_TributePatronSelectionTile_Shared)

function ZO_TributePatronSelectionTile_Gamepad:New(...)
    return ZO_TributePatronSelectionTile_Shared.New(self, ...)
end

function ZO_TributePatronSelectionTile_Gamepad:InitializePlatform(...)
    ZO_TributePatronTile_Gamepad.InitializePlatform(self, ...)
    self.draftedIcon = self.control:GetNamedChild("DraftedIcon")
    self.glow = self.control:GetNamedChild("Glow")
end

function ZO_TributePatronSelectionTile_Gamepad:PostInitializePlatform(...)
    ZO_TributePatronTile_Gamepad.PostInitializePlatform(self, ...)
    local toggleTooltipDescriptor =
    {
        name = GetString(SI_TRIBUTE_DECK_SELECTION_GAMEPAD_TOGGLE_TOOLTIPS_ACTION),
        order = 3,
        keybind = "UI_SHORTCUT_TERTIARY",
        callback = function()
            ZO_TRIBUTE_PATRON_SELECTION_MANAGER:ToggleShowGamepadTooltips()
            self:RefreshTooltip()
        end,
    }
    table.insert(self.keybindStripDescriptor, toggleTooltipDescriptor)
    --This needs to be done manually to override logic in ZO_ContextualActionsTile_Gamepad
    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_CENTER
end

function ZO_TributePatronSelectionTile_Gamepad:LayoutPlatform(patronData)
    ZO_TributePatronTile_Gamepad.LayoutPlatform(self, patronData)
    self.titleLabel:SetText(patronData:GetFormattedColorizedName())
    local isDrafted = false
    local isSelected = false
    local isLocked = self.patronData:IsPatronLocked() 

    if ZO_TRIBUTE_PATRON_SELECTION_MANAGER then
        local patronId = patronData:GetId()
        local currentSelectedPatronId = ZO_TRIBUTE_PATRON_SELECTION_MANAGER:GetSelectedPatron()
        isSelected = currentSelectedPatronId == patronId
        isDrafted = ZO_TRIBUTE_PATRON_SELECTION_MANAGER:IsPatronDrafted(patronId)
    end

    self:RefreshGlow(isSelected, isDrafted, isLocked)
    self.draftedIcon:SetHidden(not isDrafted)
    ZO_SetDefaultIconSilhouette(self.iconTexture, isLocked)
    local iconDesaturation = isLocked and 1 or 0
    self.iconTexture:SetDesaturation(iconDesaturation)
end

function ZO_TributePatronSelectionTile_Gamepad:RefreshGlow(isSelected, isDrafted, isLocked)
    local showGlow = isSelected or isDrafted
    if self.isGlowShowing ~= showGlow then
        self.isGlowShowing = showGlow
        if showGlow then
            ZO_TRIBUTE_PATRON_SELECTION_TILE_GAMEPAD_GLOW_ANIMATION_PROVIDER:PlayForward(self.glow, self.patronData.animateInstantly)
        else
            ZO_TRIBUTE_PATRON_SELECTION_TILE_GAMEPAD_GLOW_ANIMATION_PROVIDER:PlayBackward(self.glow, self.patronData.animateInstantly)
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

function ZO_TributePatronSelectionTile_Gamepad:RefreshTooltip()
    ZO_TributePatronTooltip_Gamepad_Hide()
    if self:IsSelected() and ZO_TRIBUTE_PATRON_SELECTION_MANAGER:ShouldShowGamepadTooltips() then
        local DONT_HIGHLIGHT_ACTIVE_FAVOR_STATE = false
        local ALLOW_NOT_COLLECTIBLE_WARNING = false
        local optionalArgs =
        {
            highlightActivePatronState = DONT_HIGHLIGHT_ACTIVE_FAVOR_STATE,
            suppressNotCollectibleWarning = ALLOW_NOT_COLLECTIBLE_WARNING,
            showAcquireHint = self.patronData:IsPatronLocked(),
        }
        ZO_TributePatronTooltip_Gamepad_Show(self.patronData, optionalArgs, LEFT, self.control, RIGHT, 25, 0)
    end
end

-- Begin ZO_ContextualActionsTile_Gamepad Overrides --

function ZO_TributePatronSelectionTile_Gamepad:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)
    self:RefreshTooltip()
end

-- End ZO_ContextualActionsTile_Gamepad Overrides --

-- XML functions
----------------

function ZO_TributePatronBookTile_Gamepad_OnInitialized(control)
    ZO_TributePatronBookTile_Gamepad:New(control)
end

function ZO_TributePatronSelectionTile_Gamepad_OnInitialized(control)
    ZO_TributePatronSelectionTile_Gamepad:New(control)
end