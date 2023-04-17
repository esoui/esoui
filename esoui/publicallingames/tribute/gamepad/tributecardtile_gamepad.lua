-----------------------
-- Tribute Card Tile --
-----------------------

ZO_TRIBUTE_TILE_WIDTH_GAMEPAD = 238
ZO_TRIBUTE_TILE_HEIGHT_GAMEPAD = 350

local TRIBUTE_CARD_UPGRADE_TO_ICON = "EsoUI/Art/Tribute/gamepad/gp_tribute_icon_upgradeAvailable.dds"
local TRIBUTE_CARD_UPGRADED_ICON = "EsoUI/Art/Tribute/gamepad/gp_tribute_icon_upgraded.dds"

local TRIBUTE_CARD_DEFAULT_OFFSET_X = 0
local TRIBUTE_CARD_DEFAULT_OFFSET_Y = 0
local TRIBUTE_CARD_DEFAULT_SCALE = 0.65

ZO_TributeCardTile_Gamepad = ZO_ContextualActionsTile_Gamepad:Subclass()

function ZO_TributeCardTile_Gamepad:New(...)
    return ZO_ContextualActionsTile_Gamepad.New(self, ...)
end

function ZO_TributeCardTile_Gamepad:InitializePlatform(...)
    ZO_ContextualActionsTile_Gamepad.InitializePlatform(self, ...)
    self.cardOffsetX = TRIBUTE_CARD_DEFAULT_OFFSET_X
    self.cardOffsetY = TRIBUTE_CARD_DEFAULT_OFFSET_Y
    self.cardScale = TRIBUTE_CARD_DEFAULT_SCALE
end

function ZO_TributeCardTile_Gamepad:LayoutPlatform(data)
    ZO_Tile_Gamepad.LayoutPlatform(self, data)
    self.cardData.control:SetAnchor(CENTER, nil, CENTER, self.cardOffsetX, self.cardOffsetY)
    self.cardData.control:SetScale(self.cardScale)
end

-- Begin ZO_Tile_Gamepad Overrides --

function ZO_TributeCardTile_Gamepad:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)
    if isFocused then
        local upgradeContext = (not self.data.isStarter) and self.data or nil
        GAMEPAD_TOOLTIPS:LayoutTributeCard(GAMEPAD_RIGHT_TOOLTIP, self.cardData, upgradeContext)
    end
end

-----------------------------------
-- Tribute Patron Book Card Tile --
-----------------------------------

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributePatronBookCardTile_Gamepad = ZO_Object.MultiSubclass(ZO_TributeCardTile_Gamepad, ZO_TributePatronBookCardTile_Shared)

function ZO_TributePatronBookCardTile_Gamepad:New(...)
    return ZO_TributePatronBookCardTile_Shared.New(self, ...)
end

function ZO_TributePatronBookCardTile_Gamepad:InitializePlatform(...)
    ZO_TributeCardTile_Gamepad.InitializePlatform(self, ...)

    self.upgradeToIcon = TRIBUTE_CARD_UPGRADE_TO_ICON
    self.upgradedIcon = TRIBUTE_CARD_UPGRADED_ICON
    self.cardOffsetY = -20
end

function ZO_TributePatronBookCardTile_Gamepad:ToggleCardTooltipCallback()
    local data = self.data
    if self.showBaseTooltip then
        local upgradeContext = (not data.isStarter) and data or nil
        GAMEPAD_TOOLTIPS:LayoutTributeCard(GAMEPAD_RIGHT_TOOLTIP, self.cardData, upgradeContext)
    elseif data then
        local isUpgradableBaseCard = data.upgradesTo ~= nil
        local isCardAvailableUpgrade = data.upgradesFrom and not data.hasUpgrade
        if isUpgradableBaseCard then
            local upgradesToCardData = ZO_TributeCardData:New(data.patronId, data.upgradesTo)
            GAMEPAD_TOOLTIPS:LayoutTributeCard(GAMEPAD_RIGHT_TOOLTIP, upgradesToCardData)
        elseif isCardAvailableUpgrade then
            local upgradeFromCardData = ZO_TributeCardData:New(data.patronId, data.upgradesFrom)
            GAMEPAD_TOOLTIPS:LayoutTributeCard(GAMEPAD_RIGHT_TOOLTIP, upgradeFromCardData)
        end
    end
    self.showBaseTooltip = not self.showBaseTooltip
end

function ZO_TributePatronBookCardTile_Gamepad:LayoutPlatform(data)
    ZO_TributeCardTile_Gamepad.LayoutPlatform(self, data)

    self.lockOverlay:ClearAnchors()
    self.lockOverlay:SetAnchor(CENTER, nil, CENTER, self.cardOffsetX, self.cardOffsetY)
    self.lockOverlay:SetScale(0.65)
end

-- Begin ZO_Tile_Gamepad Overrides --

function ZO_TributePatronBookCardTile_Gamepad:OnFocusChanged(isFocused)
    ZO_ContextualActionsTile.OnFocusChanged(self, isFocused)
    if isFocused then
        local upgradeContext = (not self.data.isStarter) and self.data or nil
        GAMEPAD_TOOLTIPS:LayoutTributeCard(GAMEPAD_RIGHT_TOOLTIP, self.cardData, upgradeContext)
    end
end

-- XML functions
----------------

function ZO_TributePatronBookCardTile_Gamepad_OnInitialized(control)
    ZO_TributePatronBookCardTile_Gamepad:New(control)
end

-----------------------------------
-- Tribute Pile Viewer Card Tile --
-----------------------------------

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributePileViewerCardTile_Gamepad = ZO_Object.MultiSubclass(ZO_TributeCardTile_Gamepad, ZO_TributePileViewerCardTile_Shared)

function ZO_TributePileViewerCardTile_Gamepad:New(...)
    return ZO_TributePileViewerCardTile_Shared.New(self, ...)
end

function ZO_TributePileViewerCardTile_Gamepad:InitializePlatform(...)
    ZO_TributeCardTile_Gamepad.InitializePlatform(self, ...)
end

function ZO_TributePileViewerCardTile_Gamepad:PostInitializePlatform(...)
    ZO_TributeCardTile_Gamepad.PostInitializePlatform(self, ...)
    --This needs to be done manually to override logic in ZO_ContextualActionsTile_Gamepad
    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_CENTER
end

function ZO_TributePileViewerCardTile_Gamepad:SetHighlightHidden(hidden, instant)
    ZO_ContextualActionsTile.SetHighlightHidden(self, hidden, instant)
    ZO_TributePileViewerCardTile_Shared.SetHighlightHidden(self, hidden, instant)
end

-- XML functions
----------------

function ZO_TributePileViewerCardTile_Gamepad_OnInitialized(control)
    ZO_TributePileViewerCardTile_Gamepad:New(control)
end

-------------------------------------
-- Tribute Target Viewer Card Tile --
-------------------------------------

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributeTargetViewerCardTile_Gamepad = ZO_Object.MultiSubclass(ZO_TributeCardTile_Gamepad, ZO_TributeTargetViewerCardTile_Shared)

function ZO_TributeTargetViewerCardTile_Gamepad:New(...)
    return ZO_TributeTargetViewerCardTile_Shared.New(self, ...)
end

function ZO_TributeTargetViewerCardTile_Gamepad:InitializePlatform(...)
    ZO_TributeCardTile_Gamepad.InitializePlatform(self, ...)
end

function ZO_TributeTargetViewerCardTile_Gamepad:PostInitializePlatform(...)
    ZO_TributeCardTile_Gamepad.PostInitializePlatform(self, ...)
    --This needs to be done manually to override logic in ZO_ContextualActionsTile_Gamepad
    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_CENTER
end

function ZO_TributeTargetViewerCardTile_Gamepad:SetHighlightHidden(hidden, instant)
    ZO_ContextualActionsTile.SetHighlightHidden(self, hidden, instant)
    ZO_TributeTargetViewerCardTile_Shared.SetHighlightHidden(self, hidden, instant)
end

-- XML functions
----------------

function ZO_TributeTargetViewerCardTile_Gamepad_OnInitialized(control)
    ZO_TributeTargetViewerCardTile_Gamepad:New(control)
end

------------------------------------------
-- Tribute Confinement Viewer Card Tile --
------------------------------------------

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_TributeConfinementViewerCardTile_Gamepad = ZO_Object.MultiSubclass(ZO_TributeCardTile_Gamepad, ZO_TributeConfinementViewerCardTile_Shared)

function ZO_TributeConfinementViewerCardTile_Gamepad:New(...)
    return ZO_TributeConfinementViewerCardTile_Shared.New(self, ...)
end

function ZO_TributeConfinementViewerCardTile_Gamepad:PostInitializePlatform(...)
    ZO_TributeCardTile_Gamepad.PostInitializePlatform(self, ...)
    --This needs to be done manually to override logic in ZO_ContextualActionsTile_Gamepad
    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_CENTER
end

function ZO_TributeConfinementViewerCardTile_Gamepad:SetHighlightHidden(hidden, instant)
    ZO_ContextualActionsTile.SetHighlightHidden(self, hidden, instant)
    ZO_TributeConfinementViewerCardTile_Shared.SetHighlightHidden(self, hidden, instant)
end

-- XML functions
----------------

function ZO_TributeConfinementViewerCardTile_Gamepad_OnInitialized(control)
    ZO_TributeConfinementViewerCardTile_Gamepad:New(control)
end