
ZO_TRIBUTE_CARD_TILE_WIDTH_KEYBOARD = 180
ZO_TRIBUTE_CARD_TILE_HEIGHT_KEYBOARD = 300
ZO_TRIBUTE_CARD_TILE_TALL_HEIGHT_KEYBOARD = 330

ZO_TRIBUTE_PATRON_BOOK_TILE_WIDE_WIDTH_KEYBOARD = 275
ZO_TRIBUTE_PATRON_BOOK_TILE_WIDTH_KEYBOARD = 180
ZO_TRIBUTE_PATRON_BOOK_TILE_HEIGHT_KEYBOARD = 330

local TRIBUTE_CARD_UPGRADE_TO_ICON = "EsoUI/Art/Tribute/tribute_icon_upgradeAvailable.dds"
local TRIBUTE_CARD_UPGRADED_ICON = "EsoUI/Art/Tribute/tribute_icon_upgraded.dds"

-----------------------
-- Tribute Card Tile --
-----------------------

ZO_TributeCardTile_Keyboard = ZO_ContextualActionsTile_Keyboard:Subclass()

function ZO_TributeCardTile_Keyboard:New(...)
    return ZO_ContextualActionsTile_Keyboard.New(self, ...)
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_TributeCardTile_Keyboard:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)
    if isFocused then
        local data = self.data
        ClearTooltip(ItemTooltip)
        InitializeTooltip(ItemTooltip)
        ZO_Tooltips_SetupDynamicTooltipAnchors(ItemTooltip, self.control)
        ItemTooltip:SetTributeCard(data.patronId, data.cardId)
    elseif not self.togglingTooltip then
        ClearTooltip(ItemTooltip)
    end
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_TributeCardTile_Keyboard:LayoutPlatform(data)
    self.cardData.control:SetAnchor(CENTER, nil, CENTER, 0, 0)
    self.cardData.control:SetScale(0.60)
    self:SetCanFocus(true)
end

-----------------------------------
-- Tribute Patron Book Card Tile --
-----------------------------------

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributePatronBookCardTile_Keyboard = ZO_Object.MultiSubclass(ZO_TributeCardTile_Keyboard, ZO_TributePatronBookCardTile_Shared)

function ZO_TributePatronBookCardTile_Keyboard:New(...)
    return ZO_TributePatronBookCardTile_Shared.New(self, ...)
end

function ZO_TributePatronBookCardTile_Keyboard:InitializePlatform(...)
    ZO_TributeCardTile_Keyboard.InitializePlatform(self, ...)

    self.upgradeToIcon = TRIBUTE_CARD_UPGRADE_TO_ICON
    self.upgradedIcon = TRIBUTE_CARD_UPGRADED_ICON
end

function ZO_TributePatronBookCardTile_Keyboard:ToggleCardTooltipCallback()
    self.togglingTooltip = true
    local data = self.data
    ClearTooltip(ItemTooltip)
    local offsetX = self.control:GetParent():GetLeft() - self.control:GetLeft() - 5
    InitializeTooltip(ItemTooltip, self.control, RIGHT, offsetX, 0, LEFT)
    if self.showBaseTooltip then
        local SHOW_UPGRADE = true
        ItemTooltip:SetTributePatronDockCard(data.patronId, data.cardIndex, SHOW_UPGRADE)
    else
        ItemTooltip:SetTributePatronDockCard(data.patronId, data.cardIndex, data.upgradesFrom ~= nil)
    end
    self.showBaseTooltip = not self.showBaseTooltip
    self.togglingTooltip = false
end

-- Begin ZO_TributeCardTile_Keyboard Overrides --

function ZO_TributePatronBookCardTile_Keyboard:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)

    if isFocused and not self.togglingTooltip then
        local data = self.data
        ClearTooltip(ItemTooltip)
        local offsetX = self.control:GetParent():GetLeft() - self.control:GetLeft() - 5
        InitializeTooltip(ItemTooltip, self.control, RIGHT, offsetX, 0, LEFT)
        if data.isStarter then
            ItemTooltip:HideComparativeTooltips()
            ItemTooltip:SetTributePatronStarterCard(data.patronId, data.cardIndex)
        else
            local USE_RELATIVE_ANCHORS = true
            ItemTooltip:SetTributePatronDockCard(data.patronId, data.cardIndex, data.upgradesFrom ~= nil)
            ItemTooltip:HideComparativeTooltips()
            ItemTooltip:ShowComparativeTooltips()
            ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip1)
            ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip2)
            ZO_Tooltips_SetupDynamicTooltipAnchors(ItemTooltip, self.control, ComparativeTooltip1, ComparativeTooltip2, USE_RELATIVE_ANCHORS)
            self.showBaseTooltip = true
        end
    elseif not self.togglingTooltip then
        ClearTooltip(ItemTooltip)
    end
end

function ZO_TributePatronBookCardTile_Keyboard:LayoutPlatform(data)
    self.cardData.control:SetAnchor(CENTER, nil, CENTER, 0, 10)
    self.cardData.control:SetScale(0.60)

    self.lockOverlay:ClearAnchors()
    self.lockOverlay:SetAnchor(CENTER, nil, CENTER, 0, 10)
    self.lockOverlay:SetScale(0.60)

    local desaturation = self.isCardLocked and 1 or 0
    self:GetHighlightControl():SetDesaturation(desaturation)
    self:SetCanFocus(true)
end

-- End ZO_TributeCardTile_Keyboard Overrides --

-- XML functions
----------------

function ZO_TributePatronBookCardTile_Keyboard_OnInitialized(control)
    ZO_TributePatronBookCardTile_Keyboard:New(control)
end

-----------------------------------
-- Tribute Pile Viewer Card Tile --
-----------------------------------

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributePileViewerCardTile_Keyboard = ZO_Object.MultiSubclass(ZO_TributeCardTile_Keyboard, ZO_TributePileViewerCardTile_Shared)

function ZO_TributePileViewerCardTile_Keyboard:New(...)
    return ZO_TributePileViewerCardTile_Shared.New(self, ...)
end

function ZO_TributePileViewerCardTile_Keyboard:InitializePlatform(...)
    ZO_TributeCardTile_Keyboard.InitializePlatform(self, ...)
end

function ZO_TributePileViewerCardTile_Keyboard:PostInitializePlatform(...)
    ZO_TributeCardTile_Keyboard.PostInitializePlatform(self, ...)
    --This needs to be done manually to override logic in ZO_ContextualActionsTile_Keyboard
    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_CENTER
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_TributePileViewerCardTile_Keyboard:OnMouseUp(button, upInside)
    if upInside and self.cardData:IsPlayable() then
        local FROM_PILE_VIEWER = true
        InteractWithTributeCard(self.data.cardInstanceId, FROM_PILE_VIEWER)
    end
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

-- XML functions
----------------

function ZO_TributePileViewerCardTile_Keyboard_OnInitialized(control)
    ZO_TributePileViewerCardTile_Keyboard:New(control)
end

-----------------------------------
-- Tribute Target Viewer Card Tile --
-----------------------------------

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributeTargetViewerCardTile_Keyboard = ZO_Object.MultiSubclass(ZO_TributeCardTile_Keyboard, ZO_TributeTargetViewerCardTile_Shared)

function ZO_TributeTargetViewerCardTile_Keyboard:New(...)
    return ZO_TributeTargetViewerCardTile_Shared.New(self, ...)
end

function ZO_TributeTargetViewerCardTile_Keyboard:InitializePlatform(...)
    ZO_TributeCardTile_Keyboard.InitializePlatform(self, ...)
end

function ZO_TributeTargetViewerCardTile_Keyboard:PostInitializePlatform(...)
    ZO_TributeCardTile_Keyboard.PostInitializePlatform(self, ...)
    --This needs to be done manually to override logic in ZO_ContextualActionsTile_Keyboard
    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_CENTER
end

-- Begin ZO_ContextualActionsTile_Keyboard Overrides --

function ZO_TributeTargetViewerCardTile_Keyboard:OnMouseUp(button, upInside)
    if upInside then
        local FROM_TARGET_VIEWER = true
        InteractWithTributeCard(self.data.cardInstanceId, FROM_TARGET_VIEWER)
    end
end

-- End ZO_ContextualActionsTile_Keyboard Overrides --

-- XML functions
----------------

function ZO_TributeTargetViewerCardTile_Keyboard_OnInitialized(control)
    ZO_TributeTargetViewerCardTile_Keyboard:New(control)
end

------------------------------------------
-- Tribute Confinement Viewer Card Tile --
------------------------------------------

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributeConfinementViewerCardTile_Keyboard = ZO_Object.MultiSubclass(ZO_TributeCardTile_Keyboard, ZO_TributeConfinementViewerCardTile_Shared)

function ZO_TributeConfinementViewerCardTile_Keyboard:New(...)
    return ZO_TributeConfinementViewerCardTile_Shared.New(self, ...)
end

function ZO_TributeConfinementViewerCardTile_Keyboard:PostInitializePlatform(...)
    ZO_TributeCardTile_Keyboard.PostInitializePlatform(self, ...)
    --This needs to be done manually to override logic in ZO_ContextualActionsTile_Keyboard
    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_CENTER
end

-- XML functions
----------------

function ZO_TributeConfinementViewerCardTile_Keyboard_OnInitialized(control)
    ZO_TributeConfinementViewerCardTile_Keyboard:New(control)
end