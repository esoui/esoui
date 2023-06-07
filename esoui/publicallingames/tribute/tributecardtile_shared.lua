------------------------------
-- Tribute Card Tile --
------------------------------

ZO_TributeCardTile_Shared = ZO_ContextualActionsTile:Subclass()

function ZO_TributeCardTile_Shared:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

function ZO_TributeCardTile_Shared:Initialize(...)
    ZO_ContextualActionsTile.Initialize(self, ...)

    self.keybindStripDescriptor = {}
end

-- Begin ZO_Tile Overrides --

function ZO_TributeCardTile_Shared:Layout(data)
    self.data = data
    self.cardData = TRIBUTE_POOL_MANAGER:AcquireCardByDefIds(data.cardId, data.patronId, self.control, SPACE_INTERFACE)
    self.cardData.control:SetMouseEnabled(false)

    ZO_Tile.Layout(self, data)
end

function ZO_TributeCardTile_Shared:Reset()
    self.cardData.control:SetMouseEnabled(true)
    self.cardData:ReleaseObject()
    self:SetCanFocus(false)

    self.data = nil
    self.cardData = nil
end

-- End ZO_Tile Overrides --

------------------------------
-- Tribute Patron Card Tile --
------------------------------

ZO_TributePatronBookCardTile_Shared = ZO_TributeCardTile_Shared:Subclass()

function ZO_TributePatronBookCardTile_Shared:New(...)
    return ZO_TributeCardTile_Shared.New(self, ...)
end

function ZO_TributePatronBookCardTile_Shared:Initialize(...)
    ZO_TributeCardTile_Shared.Initialize(self, ...)

    self.titleLabel = self.control:GetNamedChild("Title")
    self.countLabel = self.control:GetNamedChild("Count")
    self.statusIcon = self.control:GetNamedChild("StatusIcon")
    self.highlightControl = self.control:GetNamedChild("Highlight")
    self.lockOverlay = self.control:GetNamedChild("LockOverlay")

    self.keybindStripDescriptor =
    {
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_TRIBUTE_CARD_TOGGLE_TOOLTIP_ACTION),
            callback = function()
                self:ToggleCardTooltipCallback()
            end,
            visible = function()
                local data = self.data
                if data then
                    local isUpgradableBaseCard = data.upgradesTo ~= nil
                    local isCardAvailableUpgrade = data.upgradesFrom and not data.hasUpgrade
                    return isUpgradableBaseCard and not isCardAvailableUpgrade
                end
                return false
            end,
        }
    }
end

function ZO_TributePatronBookCardTile_Shared:ToggleCardTooltipCallback()
    -- To be overridden
end

-- Begin ZO_Tile Overrides --

function ZO_TributePatronBookCardTile_Shared:Layout(data)
    self.data = data
    self.cardData = TRIBUTE_POOL_MANAGER:AcquireCardByDefIds(data.cardId, data.patronId, self.control, SPACE_INTERFACE)
    self.cardData.control:SetMouseEnabled(false)

    if data.isStarter then
        self.titleLabel:SetText(GetString(SI_TRIBUTE_PATRON_STARTER_CARD_HEADER))
    else
        local cardTypeString = GetString("SI_TRIBUTECARDTYPE", self.cardData:GetCardType())
        if self.cardData:IsContract() then
            self.titleLabel:SetText(zo_strformat(SI_TRIBUTE_CARD_TYPE_CONTRACT, cardTypeString))
        elseif self.cardData:IsCurse() then
            self.titleLabel:SetText(zo_strformat(SI_TRIBUTE_CARD_TYPE_CURSE, cardTypeString))
        else
            self.titleLabel:SetText(zo_strformat(SI_TRIBUTE_CARD_TYPE_FORMATTER, cardTypeString))
        end
    end

    if data.count > 1 then
        self.countLabel:SetText(zo_strformat(SI_TRIBUTE_PATRON_CARD_TYPE_COUNT, data.count))
        self.countLabel:SetHidden(false)
    else
        self.countLabel:SetHidden(true)
    end

    self:RefreshStatusIcon()

    self.patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(self.cardData:GetPatronDefId())
    self.isCardLocked = self.patronData:IsPatronLocked() or (data.upgradesFrom and not data.hasUpgrade)

    self.lockOverlay:SetColor(0, 0, 0, 0.65)
    self.lockOverlay:SetHidden(not self.isCardLocked)

    ZO_Tile.Layout(self, data)
end

function ZO_TributePatronBookCardTile_Shared:RefreshStatusIcon()
    local statusControl = self.statusIcon
    if not statusControl then
        return
    end

    statusControl:ClearIcons()
    local showMultiIcon = false
    if self.data.upgradesTo then
        statusControl:AddIcon(self.upgradeToIcon)
        showMultiIcon = true
    end

    if self.data.hasUpgrade then
        statusControl:AddIcon(self.upgradedIcon)
        showMultiIcon = true
    end

    if showMultiIcon then
        statusControl:Show()
    end
end

function ZO_TributePatronBookCardTile_Shared:Reset()
    self.cardData.control:SetMouseEnabled(true)
    self.cardData:ReleaseObject()
    self:SetCanFocus(false)

    self.data = nil
    self.cardData = nil
end

-- End ZO_Tile Overrides --

------------------------------
-- Tribute Pile Viewer Card Tile --
------------------------------

ZO_TributePileViewerCardTile_Shared = ZO_TributeCardTile_Shared:Subclass()

function ZO_TributePileViewerCardTile_Shared:New(...)
    return ZO_TributeCardTile_Shared.New(self, ...)
end

function ZO_TributePileViewerCardTile_Shared:Initialize(...)
    ZO_TributeCardTile_Shared.Initialize(self, ...)
    self.keybindStripDescriptor =
    {
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                if self.cardData:IsDamageable() then
                    local resourceType, maxHealth, currentHealth = self.cardData:GetDefeatCost()
                    local resourceAmount = GetTributePlayerPerspectiveResource(TRIBUTE_PLAYER_PERSPECTIVE_SELF, resourceType)
                    return zo_strformat(SI_TRIBUTE_PILE_VIEWER_DEAL_DAMAGE, zo_min(currentHealth, resourceAmount))
                else
                    return GetString(SI_TRIBUTE_PILE_VIEWER_PLAY_CARD)
                end
            end,
            callback = function()
                local FROM_PILE_VIEWER = true
                InteractWithTributeCard(self.data.cardInstanceId, FROM_PILE_VIEWER)
            end,
            visible = function()
                return self.cardData:IsPlayable() or self.cardData:IsDamageable()
            end,
        },
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_TRIBUTE_VIEW_CONFINED_CARDS_ACTION),
            callback = function()
                ZO_TRIBUTE_PILE_VIEWER_MANAGER:OpenConfinementViewer(self.cardData)
            end,
            visible = function()
                return self.cardData:GetNumConfinedCards() > 0
            end,
        }
    }
end

function ZO_TributePileViewerCardTile_Shared:Layout(data)
    self.data = data
    self.cardData = TRIBUTE_POOL_MANAGER:AcquireCardByInstanceId(data.cardInstanceId, self.control, SPACE_INTERFACE)
    self.cardData.control:SetMouseEnabled(false)
    self.cardData:RefreshConfinedStack()

    ZO_Tile.Layout(self, data)
end

-- Begin ZO_ContextualActionsTile Overrides --

function ZO_TributePileViewerCardTile_Shared:SetHighlightHidden(hidden, instant)
    if self.data and self.cardData then
        local cardInstanceId = self.data.cardInstanceId or 0
        if hidden then
            local NO_CARD = 0
            SetHighlightedTributeCard(NO_CARD)
        else
            SetHighlightedTributeCard(cardInstanceId)
        end
    end
end

-- End ZO_ContextualActionsTile Overrides --

-------------------------------------
-- Tribute Target Viewer Card Tile --
-------------------------------------

ZO_TributeTargetViewerCardTile_Shared = ZO_TributeCardTile_Shared:Subclass()

function ZO_TributeTargetViewerCardTile_Shared:New(...)
    return ZO_TributeCardTile_Shared.New(self, ...)
end

function ZO_TributeTargetViewerCardTile_Shared:Initialize(...)
    ZO_TributeCardTile_Shared.Initialize(self, ...)
    self.keybindStripDescriptor =
    {
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                return self.cardData:IsTargeted() and GetString(SI_TRIBUTE_TARGET_VIEWER_DESELECT_ACTION) or GetString(SI_TRIBUTE_TARGET_VIEWER_SELECT_ACTION)
            end,
            callback = function()
                local FROM_TARGET_VIEWER = true
                InteractWithTributeCard(self.data.cardInstanceId, FROM_TARGET_VIEWER)
            end,
            visible = function()
                local targetsRemaining = GetMaxAllowedTributeTargets() - GetNumTargetedTributeCards()
                return self.cardData:IsTargeted() or targetsRemaining > 0
            end,
        },
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_TRIBUTE_VIEW_CONFINED_CARDS_ACTION),
            callback = function()
                ZO_TRIBUTE_TARGET_VIEWER_MANAGER:OpenConfinementViewer(self.cardData)
            end,
            visible = function()
                return self.cardData:GetNumConfinedCards() > 0
            end,
        }
    }
end

function ZO_TributeTargetViewerCardTile_Shared:Layout(data)
    self.data = data
    self.cardData = TRIBUTE_POOL_MANAGER:AcquireCardByInstanceId(data.cardInstanceId, self.control, SPACE_INTERFACE)
    self.cardData.control:SetMouseEnabled(false)
    self.cardData:RefreshConfinedStack()

    ZO_Tile.Layout(self, data)
end

-- Begin ZO_ContextualActionsTile Overrides --

function ZO_TributeTargetViewerCardTile_Shared:SetHighlightHidden(hidden, instant)
    if self.data and self.cardData then
        local cardInstanceId = self.data.cardInstanceId or 0
        if hidden then
            local NO_CARD = 0
            SetHighlightedTributeCard(NO_CARD)
        else
            SetHighlightedTributeCard(cardInstanceId)
        end
    end
end

-- End ZO_ContextualActionsTile Overrides --

------------------------------------------
-- Tribute Confinement Viewer Card Tile --
------------------------------------------

ZO_TributeConfinementViewerCardTile_Shared = ZO_TributeCardTile_Shared:Subclass()

function ZO_TributeConfinementViewerCardTile_Shared:New(...)
    return ZO_TributeCardTile_Shared.New(self, ...)
end

function ZO_TributeConfinementViewerCardTile_Shared:Layout(data)
    self.data = data
    self.cardData = TRIBUTE_POOL_MANAGER:AcquireCardByInstanceId(data.cardInstanceId, self.control, SPACE_INTERFACE)
    self.cardData.control:SetMouseEnabled(false)

    ZO_Tile.Layout(self, data)
end

-- Begin ZO_ContextualActionsTile Overrides --

function ZO_TributeConfinementViewerCardTile_Shared:SetHighlightHidden(hidden, instant)
    if self.data and self.cardData then
        local cardInstanceId = self.data.cardInstanceId or 0
        if hidden then
            local NO_CARD = 0
            SetHighlightedTributeCard(NO_CARD)
        else
            SetHighlightedTributeCard(cardInstanceId)
        end
    end
end

-- End ZO_ContextualActionsTile Overrides --